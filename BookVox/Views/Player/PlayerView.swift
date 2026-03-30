import SwiftUI

// MARK: - Tam ekran ses oynatici

struct PlayerView: View {
    @Bindable var playerVM: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showTonePicker = false
    @State private var showSpeedPicker = false
    @State private var showSleepTimer = false
    @State private var dragOffset: CGFloat = 0

    private let audioService = AudioService.shared
    private let sleepTimer = SleepTimerService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshGradient(mood: playerVM.currentMood)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, DS.Spacing.xl)
                        .padding(.top, DS.Spacing.sm)

                    Spacer()

                    // Waveform
                    AudioWaveformView(
                        isPlaying: playerVM.isPlaying,
                        averagePower: audioService.averagePower,
                        peakPower: audioService.peakPower,
                        barCount: 45,
                        color: .bookVoxAccent
                    )
                    .frame(height: 72)
                    .padding(.horizontal, DS.Spacing.xxxl)

                    Spacer()

                    bookInfo
                        .padding(.horizontal, DS.Spacing.xxl)

                    progressSection
                        .padding(.horizontal, DS.Spacing.xxl)
                        .padding(.top, DS.Spacing.xxl)

                    controlButtons
                        .padding(.top, DS.Spacing.xxl)

                    bottomActions
                        .padding(.top, DS.Spacing.xl)
                        .padding(.bottom, DS.Spacing.lg)

                    ErrorBanner(message: playerVM.errorMessage)
                        .padding(.horizontal, DS.Spacing.xxl)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showTonePicker) {
                TonePickerView(selectedTone: playerVM.selectedTone) { tone in
                    Task { await playerVM.changeTone(to: tone) }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showSpeedPicker) {
                SpeedPickerView(currentSpeed: Binding(
                    get: { audioService.playbackSpeed },
                    set: { audioService.playbackSpeed = $0 }
                ))
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showSleepTimer) {
                SleepTimerView()
                    .presentationDetents([.medium])
            }
            .gesture(
                DragGesture()
                    .onChanged { if $0.translation.height > 0 { dragOffset = $0.translation.height } }
                    .onEnded { if $0.translation.height > 150 { dismiss() }; dragOffset = 0 }
            )
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: DS.minTapSize, minHeight: DS.minTapSize)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("DINLENIYOR")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .tracking(1.2)
                Text("\(playerVM.currentPage) / \(playerVM.book?.totalPages ?? 0)")
                    .font(.caption.weight(.semibold).monospacedDigit())
            }

            Spacer()

            if let mood = playerVM.currentMood {
                Text(mood.emoji)
                    .font(.title3)
                    .frame(minWidth: DS.minTapSize, minHeight: DS.minTapSize)
            } else {
                Color.clear.frame(width: DS.minTapSize, height: DS.minTapSize)
            }
        }
    }

    // MARK: - Book Info

    private var bookInfo: some View {
        VStack(spacing: DS.Spacing.sm) {
            Text(playerVM.book?.title ?? "")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(playerVM.book?.author ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let remaining = playerVM.book?.estimatedRemainingMinutes {
                Text("\(Int(remaining)) dk kaldi")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .padding(.top, DS.Spacing.xs)
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: DS.Spacing.sm) {
            Slider(
                value: Binding(
                    get: { playerVM.currentTime },
                    set: { playerVM.seek(to: $0) }
                ),
                in: 0...max(playerVM.duration, 1)
            )
            .tint(.bookVoxAccent)

            HStack {
                Text(TimeInterval(playerVM.currentTime).mmss)
                Spacer()
                Text("-" + TimeInterval(max(playerVM.duration - playerVM.currentTime, 0)).mmss)
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: DS.Spacing.xxl) {
            controlButton("backward.end.fill") {
                Task { await playerVM.previousPage() }
            }
            .disabled(playerVM.currentPage <= 1)

            controlButton("gobackward.\(Int(audioService.skipBackwardInterval))") {
                playerVM.skipBackward()
            }

            // Play/Pause
            Button {
                Task { await playerVM.togglePlayPause() }
            } label: {
                ZStack {
                    Circle()
                        .fill(.bookVoxAccent)
                        .frame(width: DS.Layout.playButtonSize, height: DS.Layout.playButtonSize)
                        .shadow(color: .bookVoxAccent.opacity(0.3), radius: 12, y: 4)

                    if playerVM.isRendering {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .scaleEffect(playerVM.isPlaying ? 1.0 : 0.94)
                .animation(DS.Anim.springBounce, value: playerVM.isPlaying)
            }

            controlButton("goforward.\(Int(audioService.skipForwardInterval))") {
                playerVM.skipForward()
            }

            controlButton("forward.end.fill") {
                Task { await playerVM.nextPage() }
            }
            .disabled(playerVM.currentPage >= (playerVM.book?.totalPages ?? 1))
        }
    }

    private func controlButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .frame(minWidth: DS.minTapSize, minHeight: DS.minTapSize)
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        HStack(spacing: DS.Spacing.lg) {
            chipButton(audioService.speedDisplayText) { showSpeedPicker = true }

            chipButton(playerVM.selectedTone.displayName, icon: playerVM.selectedTone.icon) {
                showTonePicker = true
            }

            chipButton(
                sleepTimer.isActive ? sleepTimer.formattedRemaining : nil,
                icon: sleepTimer.isActive ? "moon.zzz.fill" : "moon.zzz",
                highlight: sleepTimer.isActive
            ) { showSleepTimer = true }
        }
    }

    private func chipButton(_ text: String? = nil, icon: String? = nil, highlight: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                }
                if let text {
                    Text(text)
                        .monospacedDigit()
                }
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(highlight ? Color.bookVoxAccent.opacity(0.15) : Color(.tertiarySystemFill))
            .foregroundStyle(highlight ? .bookVoxAccent : .primary)
            .clipShape(Capsule())
        }
    }
}

#Preview { PlayerView(playerVM: PlayerViewModel()) }
