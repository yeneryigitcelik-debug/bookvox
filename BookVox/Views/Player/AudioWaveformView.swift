import SwiftUI

// MARK: - Canli dalga formu animasyonu
// Audio metering verisine gore hareket eden gorsel geri bildirim

struct AudioWaveformView: View {
    let isPlaying: Bool
    let averagePower: Float  // -160 to 0 dB
    let peakPower: Float

    let barCount: Int
    let barSpacing: CGFloat
    let color: Color

    @State private var animatedHeights: [CGFloat] = []

    init(
        isPlaying: Bool,
        averagePower: Float = -30,
        peakPower: Float = -10,
        barCount: Int = 40,
        barSpacing: CGFloat = 2,
        color: Color = .accent
    ) {
        self.isPlaying = isPlaying
        self.averagePower = averagePower
        self.peakPower = peakPower
        self.barCount = barCount
        self.barSpacing = barSpacing
        self.color = color
    }

    // dB degerini 0-1 arasina normalize et
    private var normalizedLevel: CGFloat {
        let minDB: Float = -50
        let clamped = max(averagePower, minDB)
        return CGFloat((clamped - minDB) / (0 - minDB))
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: barSpacing)
                        .fill(barColor(for: index))
                        .frame(
                            width: barWidth(in: geometry.size.width),
                            height: barHeight(for: index, maxHeight: geometry.size.height)
                        )
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .onChange(of: averagePower) {
            if isPlaying {
                withAnimation(.easeInOut(duration: 0.15)) {
                    updateHeights()
                }
            }
        }
        .onChange(of: isPlaying) {
            if !isPlaying {
                withAnimation(.easeOut(duration: 0.6)) {
                    resetHeights()
                }
            }
        }
        .onAppear { initializeHeights() }
    }

    private func barWidth(in totalWidth: CGFloat) -> CGFloat {
        (totalWidth - barSpacing * CGFloat(barCount - 1)) / CGFloat(barCount)
    }

    private func barHeight(for index: Int, maxHeight: CGFloat) -> CGFloat {
        guard isPlaying, index < animatedHeights.count else {
            return maxHeight * 0.05  // Minimum yukseklik
        }
        return max(animatedHeights[index] * maxHeight, maxHeight * 0.05)
    }

    private func barColor(for index: Int) -> Color {
        // Merkeze yaklastikca daha parlak
        let center = CGFloat(barCount) / 2.0
        let distance = abs(CGFloat(index) - center) / center
        return color.opacity(1.0 - distance * 0.4)
    }

    private func initializeHeights() {
        animatedHeights = (0..<barCount).map { _ in 0.05 }
    }

    private func resetHeights() {
        animatedHeights = (0..<barCount).map { _ in 0.05 }
    }

    private func updateHeights() {
        let level = normalizedLevel
        animatedHeights = (0..<barCount).map { index in
            let center = CGFloat(barCount) / 2.0
            let distance = abs(CGFloat(index) - center) / center
            let base = level * (1.0 - distance * 0.5)
            let randomness = CGFloat.random(in: -0.1...0.1)
            return max(min(base + randomness, 1.0), 0.05)
        }
    }
}

// MARK: - Minimal dalga formu (mini player icin)

struct MiniWaveformView: View {
    let isPlaying: Bool

    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(.accent)
                    .frame(width: 3, height: barHeight(for: index))
                    .animation(
                        isPlaying
                            ? .easeInOut(duration: 0.4 + Double(index) * 0.1)
                                .repeatForever(autoreverses: true)
                            : .easeOut(duration: 0.3),
                        value: isPlaying
                    )
            }
        }
        .frame(width: 23, height: 16)
    }

    private func barHeight(for index: Int) -> CGFloat {
        if !isPlaying { return 4 }
        let heights: [CGFloat] = [8, 14, 10, 16, 12]
        return heights[index]
    }
}

#Preview {
    VStack(spacing: 40) {
        AudioWaveformView(isPlaying: true, averagePower: -20)
            .frame(height: 100)
            .padding()

        MiniWaveformView(isPlaying: true)
    }
}
