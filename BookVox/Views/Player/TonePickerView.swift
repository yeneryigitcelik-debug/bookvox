import SwiftUI

// MARK: - Ses tonu secici
// Premium kontrolleri ile kullanilabilir TTS tonlarini listeler

struct TonePickerView: View {
    let selectedTone: TTSService.Tone
    let onSelect: (TTSService.Tone) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    private let subscription = SubscriptionService.shared

    var body: some View {
        NavigationStack {
            let tones: [TTSService.Tone] = TTSService.Tone.allCases.map { $0 }

            List {
                SwiftUI.ForEach(tones, id: \.rawValue) { (tone: TTSService.Tone) in
                    let isPremiumTone = !Constants.App.freeTones.contains(tone.rawValue)
                    let isLocked = isPremiumTone && !subscription.isPremium

                    Button {
                        if isLocked {
                            showPaywall = true
                        } else {
                            onSelect(tone)
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: tone.icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(Color(.tertiarySystemFill).opacity(isLocked ? 0.5 : 1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(tone.displayName)
                                    .font(.subheadline.bold())

                                Text(toneDescription(tone))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if tone == selectedTone {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                            }

                            if isLocked {
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.fill")
                                    Text("PRO")
                                }
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.orange)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .foregroundStyle(isLocked ? .secondary : .primary)
                }
            }
            .navigationTitle("Ses Tonu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func toneDescription(_ tone: TTSService.Tone) -> String {
        switch tone {
        case .standard: "Dogal ve net okuma"
        case .storyteller: "Hikaye anlatici, canli ve etkileyici"
        case .academic: "Akademik, olculu ve ciddi"
        case .intimate: "Yakin, sicak ve samimi"
        case .dramatic: "Dramatik, duygusal ve etkili"
        }
    }
}

#Preview {
    TonePickerView(
        selectedTone: .storyteller,
        onSelect: { _ in }
    )
}
