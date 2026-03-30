import SwiftUI
import SwiftData

// MARK: - Onboarding ekrani

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    @Query private var preferences: [UserPreferences]
    @State private var currentIndex = 0

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("doc.text.fill", "PDF Yukle",
         "Herhangi bir PDF kitabi kutuphanene ekle. Metin otomatik olarak cikarilir.", .blue),
        ("waveform.circle.fill", "Yapay Zeka Seslendirme",
         "Gelismis TTS ile kitabini canli ve dogal bir sesle dinle.", .purple),
        ("theatermasks.fill", "Tonunu Sec",
         "Storyteller, academic, intimate, dramatic — her kitaba uygun ton.", .orange),
        ("chart.bar.fill", "Ilerlemeni Takip Et",
         "Okuma serisi, istatistikler ve gunluk hedeflerle motivasyonunu koru.", .green),
        ("icloud.fill", "Her Yerde Dinle",
         "Ilerlemen bulutta. Kaldığın yerden devam et.", .cyan)
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: DS.Spacing.xxl) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(page.color.opacity(0.1))
                                .frame(width: 150, height: 150)

                            Image(systemName: page.icon)
                                .font(.system(size: 58))
                                .foregroundStyle(page.color)
                                .symbolEffect(.bounce, value: currentIndex == index)
                        }

                        VStack(spacing: DS.Spacing.md) {
                            Text(page.title)
                                .font(.title.weight(.bold))

                            Text(page.subtitle)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 300)
                        }

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Alt kisim
            VStack(spacing: DS.Spacing.lg) {
                // Noktalar
                HStack(spacing: DS.Spacing.sm) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentIndex ? Color.bookVoxAccent : Color(.tertiarySystemFill))
                            .frame(width: i == currentIndex ? 24 : 8, height: 8)
                    }
                }
                .animation(DS.Anim.spring, value: currentIndex)

                Button {
                    if currentIndex < pages.count - 1 {
                        withAnimation(DS.Anim.spring) { currentIndex += 1 }
                        HapticService.sliderTick()
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentIndex < pages.count - 1 ? "Devam" : "Baslayalim")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.bookVoxAccent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                }

                if currentIndex < pages.count - 1 {
                    Button("Atla") { completeOnboarding() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, DS.Spacing.xxxl)
            .padding(.bottom, DS.Spacing.xxxl)
        }
    }

    private func completeOnboarding() {
        preferences.first?.hasCompletedOnboarding = true
        try? context.save()
        HapticService.importComplete()
        isPresented = false
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
        .modelContainer(for: UserPreferences.self, inMemory: true)
}
