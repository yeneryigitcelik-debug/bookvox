import SwiftUI

// MARK: - Oynatma hizi secici
// 0.5x - 3.0x arasi hiz secimi

struct SpeedPickerView: View {
    @Binding var currentSpeed: Float
    @Environment(\.dismiss) private var dismiss

    private var speeds: [Float] { AudioService.availableSpeeds }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Mevcut hiz gostergesi
                Text(speedText(currentSpeed))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.accent)
                    .padding(.top)

                // Slider
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { Float(speedIndex) },
                            set: { index in
                                let i = Int(index.rounded())
                                if i >= 0, i < speeds.count {
                                    currentSpeed = speeds[i]
                                    HapticService.sliderTick()
                                }
                            }
                        ),
                        in: 0...Float(speeds.count - 1),
                        step: 1
                    )
                    .tint(.accent)

                    HStack {
                        Text("0.5x")
                            .font(.caption2)
                        Spacer()
                        Text("3x")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Hizli secim butonlari
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(speeds, id: \.self) { speed in
                        Button {
                            currentSpeed = speed
                            HapticService.sliderTick()
                        } label: {
                            Text(speedText(speed))
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(speed == currentSpeed ? Color.accentColor : Color(.tertiarySystemFill))
                                .foregroundStyle(speed == currentSpeed ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.horizontal)

                // Aciklama
                Text(speedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                Spacer()
            }
            .navigationTitle("Oynatma Hizi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { dismiss() }
                }
            }
        }
    }

    private var speedIndex: Float {
        Float(speeds.firstIndex(of: currentSpeed) ?? 2)
    }

    private var speedDescription: String {
        switch currentSpeed {
        case 0.5: "Cok yavas — detaylari yakalamak icin ideal"
        case 0.75: "Yavas — rahat ve anlasilir dinleme"
        case 1.0: "Normal — dogal okuma hizi"
        case 1.25: "Biraz hizli — verimli dinleme"
        case 1.5: "Hizli — deneyimli dinleyiciler icin"
        case 1.75: "Cok hizli — odaklanma gerektirir"
        case 2.0: "2 kat — hizli tuketim"
        case 2.5: "Cok hizli — uzman seviyesi"
        case 3.0: "Maksimum — sadece gozden gecirme icin"
        default: ""
        }
    }

    private func speedText(_ speed: Float) -> String {
        AudioService.formatSpeed(speed)
    }
}

#Preview {
    SpeedPickerView(currentSpeed: .constant(1.0))
}
