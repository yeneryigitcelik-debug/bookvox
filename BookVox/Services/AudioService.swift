import Foundation
import AVFoundation
import MediaPlayer

// MARK: - Ses oynatma servisi
// AVAudioPlayer ile playback, hiz kontrolu, sleep timer ve lock screen kontrolleri

@Observable
final class AudioService: NSObject {
    static let shared = AudioService()

    private var player: AVAudioPlayer?
    private var updateTimer: Timer?

    // Oynatma durumu
    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0

    // Hiz kontrolu (0.5x - 3.0x)
    var playbackSpeed: Float = 1.0 {
        didSet {
            player?.rate = playbackSpeed
            updateNowPlayingInfo()
        }
    }

    // Ses seviyesi (0.0 - 1.0)
    var volume: Float = 1.0 {
        didSet {
            player?.volume = volume
        }
    }

    // Audio metering (dalga formu animasyonu icin)
    private(set) var averagePower: Float = 0
    private(set) var peakPower: Float = 0

    // Suanki parca bilgisi (lock screen icin)
    var nowPlayingTitle: String?
    var nowPlayingAuthor: String?
    var nowPlayingPage: String?
    var nowPlayingCoverData: Data?

    // Atlama suresi (kullanici ayarlanabilir)
    var skipForwardInterval: Double = 15
    var skipBackwardInterval: Double = 15

    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
        setupInterruptionHandling()
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {
            print("Audio session hatasi: \(error)")
        }
    }

    // Telefon cagrisi, alarm vb. kesintileri yonet
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue)
            else { return }

            switch type {
            case .began:
                // Kesinti basladi — duraklat
                self.pause()
            case .ended:
                // Kesinti bitti — devam et
                if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        self.resume()
                    }
                }
            @unknown default:
                break
            }
        }

        // Route degisikligini dinle (kulaklik cikarildi vb.)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let info = notification.userInfo,
                  let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
            else { return }

            // Kulaklik cikarildiginda duraklat
            if reason == .oldDeviceUnavailable {
                self?.pause()
            }
        }
    }

    // MARK: - Oynatma

    func play(url: URL) async throws {
        let data: Data
        if url.isFileURL {
            data = try Data(contentsOf: url)
        } else {
            let (downloaded, _) = try await URLSession.shared.data(from: url)
            data = downloaded
        }

        player = try AVAudioPlayer(data: data)
        player?.delegate = self
        player?.enableRate = true
        player?.rate = playbackSpeed
        player?.volume = volume
        player?.isMeteringEnabled = true
        player?.prepareToPlay()
        player?.play()

        isPlaying = true
        duration = player?.duration ?? 0
        startProgressTimer()
        updateNowPlayingInfo()
        HapticService.playPause()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
        updateNowPlayingInfo()
    }

    func resume() {
        player?.play()
        isPlaying = true
        startProgressTimer()
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
        HapticService.playPause()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        averagePower = 0
        peakPower = 0
        stopProgressTimer()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func seek(to time: Double) {
        player?.currentTime = time
        currentTime = time
        updateNowPlayingInfo()
    }

    func skipForward() {
        let target = min(currentTime + skipForwardInterval, duration)
        seek(to: target)
    }

    func skipBackward() {
        let target = max(currentTime - skipBackwardInterval, 0)
        seek(to: target)
    }

    // Yumusak ses kısma (sleep timer fade-out icin)
    func fadeOut(over seconds: Double = 30, completion: @escaping @MainActor () -> Void) {
        let steps = 30
        let interval = seconds / Double(steps)
        let originalVolume = volume

        Task { @MainActor [weak self] in
            for step in 1...steps {
                try? await Task.sleep(for: .seconds(interval))
                guard let self, self.isPlaying else { return }
                self.player?.volume = max(originalVolume - (originalVolume / Float(steps)) * Float(step), 0)
            }
            self?.pause()
            self?.player?.volume = originalVolume
            completion()
        }
    }

    static let availableSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]

    func increaseSpeed() {
        if let currentIndex = Self.availableSpeeds.firstIndex(of: playbackSpeed),
           currentIndex + 1 < Self.availableSpeeds.count {
            playbackSpeed = Self.availableSpeeds[currentIndex + 1]
        }
        HapticService.sliderTick()
    }

    func decreaseSpeed() {
        if let currentIndex = Self.availableSpeeds.firstIndex(of: playbackSpeed),
           currentIndex > 0 {
            playbackSpeed = Self.availableSpeeds[currentIndex - 1]
        }
        HapticService.sliderTick()
    }

    var speedDisplayText: String {
        Self.formatSpeed(playbackSpeed)
    }

    static func formatSpeed(_ speed: Float) -> String {
        if speed == 1.0 { return "1x" }
        if speed == floor(speed) { return "\(Int(speed))x" }
        return String(format: "%.2gx", speed)
    }

    // MARK: - Lock Screen

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        center.skipForwardCommand.preferredIntervals = [NSNumber(value: skipForwardInterval)]
        center.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        }

        center.skipBackwardCommand.preferredIntervals = [NSNumber(value: skipBackwardInterval)]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward()
            return .success
        }

        // Hiz kontrolu
        center.changePlaybackRateCommand.supportedPlaybackRates = Self.availableSpeeds.map { NSNumber(value: $0) }
        center.changePlaybackRateCommand.addTarget { [weak self] event in
            guard let rateEvent = event as? MPChangePlaybackRateCommandEvent else {
                return .commandFailed
            }
            self?.playbackSpeed = rateEvent.playbackRate
            return .success
        }

        // Seek
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let posEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: posEvent.positionTime)
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        var info: [String: Any] = [
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(playbackSpeed) : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: Double(playbackSpeed)
        ]

        if let title = nowPlayingTitle {
            info[MPMediaItemPropertyTitle] = title
        }
        if let author = nowPlayingAuthor {
            info[MPMediaItemPropertyArtist] = author
        }
        if let page = nowPlayingPage {
            info[MPMediaItemPropertyAlbumTitle] = page
        }
        if let coverData = nowPlayingCoverData {
            #if canImport(UIKit)
            if let image = UIImage(data: coverData) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                info[MPMediaItemPropertyArtwork] = artwork
            }
            #endif
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.player else { return }
                self.currentTime = player.currentTime
                player.updateMeters()
                self.averagePower = player.averagePower(forChannel: 0)
                self.peakPower = player.peakPower(forChannel: 0)
            }
        }
    }

    private func stopProgressTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        averagePower = 0
        peakPower = 0
        stopProgressTimer()
        NotificationCenter.default.post(name: .audioDidFinishPlaying, object: nil)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        isPlaying = false
        stopProgressTimer()
        HapticService.error()
        NotificationCenter.default.post(
            name: .audioDecodeError,
            object: nil,
            userInfo: ["error": error?.localizedDescription ?? "Bilinmeyen hata"]
        )
    }
}

extension Notification.Name {
    static let audioDidFinishPlaying = Notification.Name("audioDidFinishPlaying")
    static let audioDecodeError = Notification.Name("audioDecodeError")
}
