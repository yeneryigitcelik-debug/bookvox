import SwiftUI

// MARK: - Mini player bar

struct MiniPlayerView: View {
    @Bindable var playerVM: PlayerViewModel
    @State private var showFullPlayer = false

    private let sleepTimer = SleepTimerService.shared

    var body: some View {
        if playerVM.book != nil {
            VStack(spacing: 0) {
                // Ince ilerleme
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(.bookVoxAccent.opacity(0.08))
                        Rectangle()
                            .fill(.bookVoxAccent)
                            .frame(width: progressWidth(in: geo.size.width))
                            .animation(DS.Anim.smooth, value: playerVM.currentTime)
                    }
                }
                .frame(height: 2.5)

                Button { showFullPlayer = true } label: {
                    HStack(spacing: DS.Spacing.md) {
                        // Kapak
                        bookThumbnail

                        // Bilgi
                        VStack(alignment: .leading, spacing: 2) {
                            Text(playerVM.book?.title ?? "")
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)

                            HStack(spacing: DS.Spacing.sm) {
                                Text("Sayfa \(playerVM.currentPage)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if sleepTimer.isActive {
                                    HStack(spacing: 2) {
                                        Image(systemName: "moon.zzz.fill")
                                        Text(sleepTimer.formattedRemaining)
                                    }
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.bookVoxAccent)
                                }
                            }
                        }

                        Spacer()

                        MiniWaveformView(isPlaying: playerVM.isPlaying)

                        if playerVM.isRendering {
                            ProgressView().scaleEffect(0.8)
                        }

                        // Play/Pause
                        Button {
                            Task { await playerVM.togglePlayPause() }
                            HapticService.playPause()
                        } label: {
                            Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .contentTransition(.symbolEffect(.replace))
                                .frame(minWidth: DS.minTapSize, minHeight: DS.minTapSize)
                        }
                        .buttonStyle(.plain)

                        // Sonraki
                        Button {
                            Task { await playerVM.nextPage() }
                            HapticService.pageFlip()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.subheadline)
                                .frame(minWidth: DS.minTapSize, minHeight: DS.minTapSize)
                        }
                        .buttonStyle(.plain)
                        .disabled(playerVM.currentPage >= (playerVM.book?.totalPages ?? 1))
                    }
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(.ultraThinMaterial)
                }
                .buttonStyle(.plain)
            }
            .fullScreenCover(isPresented: $showFullPlayer) {
                PlayerView(playerVM: playerVM)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var bookThumbnail: some View {
        ZStack {
            if let data = playerVM.book?.coverImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.bookVoxAccent.opacity(0.15)
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundStyle(.bookVoxAccent)
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    private func progressWidth(in total: CGFloat) -> CGFloat {
        guard playerVM.duration > 0 else { return 0 }
        return total * (playerVM.currentTime / playerVM.duration)
    }
}

#Preview {
    VStack { Spacer(); MiniPlayerView(playerVM: PlayerViewModel()) }
}
