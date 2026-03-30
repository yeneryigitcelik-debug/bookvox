import SwiftUI
import StoreKit

// MARK: - Premium abonelik ekrani

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let subscription = SubscriptionService.shared

    @State private var selectedPlan: SubscriptionService.ProductID = .yearlyPremium
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var appeared = false

    private let features: [(icon: String, title: String, free: String, premium: String)] = [
        ("books.vertical", "Kitap Limiti", "3/ay", "Sinirsiz"),
        ("waveform", "Ses Tonlari", "2 ton", "5 ton"),
        ("arrow.down.circle", "Offline", "—", "Tamam"),
        ("hare", "Oncelik", "Normal", "Yuksek"),
        ("moon.zzz", "Sleep Timer", "Sinirli", "Tam"),
        ("chart.bar", "Istatistik", "Temel", "Detayli")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.xxl) {
                    header
                    featureGrid
                    planSelector
                    purchaseButton
                    footerLinks
                }
                .padding(DS.Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, value: appeared)
            }

            Text("BookVox Premium")
                .font(.title2.weight(.bold))

            Text("Sinirsiz dinleme deneyimi")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Feature grid

    private var featureGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.md) {
            ForEach(Array(features.enumerated()), id: \.offset) { _, feat in
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: feat.icon)
                        .font(.caption)
                        .foregroundStyle(.bookVoxAccent)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feat.title)
                            .font(.caption.weight(.semibold))
                        HStack(spacing: 4) {
                            Text(feat.free)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .strikethrough()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8))
                                .foregroundStyle(.tertiary)
                            Text(feat.premium)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DS.Spacing.md)
                .background(.fill.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
            }
        }
    }

    // MARK: - Plan selector

    private var planSelector: some View {
        VStack(spacing: DS.Spacing.md) {
            SwiftUI.ForEach(SubscriptionService.ProductID.allCases, id: \.rawValue) { (plan: SubscriptionService.ProductID) in
                let product = subscription.products.first { $0.id == plan.rawValue }
                let isSelected = selectedPlan == plan

                Button {
                    selectedPlan = plan
                    HapticService.sliderTick()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            HStack(spacing: DS.Spacing.sm) {
                                Text(plan.displayName)
                                    .font(.subheadline.weight(.semibold))

                                if plan == .yearlyPremium, let savings = subscription.monthlySavingsPercent {
                                    PillBadge("%\(savings) tasarruf", color: .green)
                                }
                            }
                            if let product {
                                Text(product.displayPrice)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? Color.bookVoxAccent : Color.secondary)
                            .font(.title3)
                    }
                    .padding(DS.Spacing.lg)
                    .background(isSelected ? Color.bookVoxAccent.opacity(0.08) : Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .strokeBorder(isSelected ? Color.bookVoxAccent.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
                }
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Purchase

    private var purchaseButton: some View {
        VStack(spacing: DS.Spacing.sm) {
            Button {
                Task { await purchase() }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Premium'a Yukselt")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(.orange.gradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            }
            .disabled(isPurchasing)

            ErrorBanner(message: errorMessage)
        }
    }

    private var footerLinks: some View {
        VStack(spacing: DS.Spacing.sm) {
            Button("Satin Alimlari Geri Yukle") {
                Task { await subscription.restore() }
            }
            .font(.caption)

            HStack(spacing: DS.Spacing.lg) {
                Link("Gizlilik", destination: Constants.App.websiteURL)
                Link("Kosullar", destination: Constants.App.websiteURL)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)

            Text("Abonelik otomatik yenilenir. Istediginiz zaman iptal edebilirsiniz.")
                .font(.caption2)
                .foregroundStyle(.quaternary)
                .multilineTextAlignment(.center)
        }
    }

    private func purchase() async {
        guard let product = subscription.products.first(where: { $0.id == selectedPlan.rawValue }) else {
            errorMessage = "Urun bulunamadi"
            return
        }
        isPurchasing = true
        errorMessage = nil
        do {
            if try await subscription.purchase(product) { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
            HapticService.error()
        }
        isPurchasing = false
    }
}

#Preview { PaywallView() }
