import SwiftUI

// MARK: - Uyku zamanlayici sheet

struct SleepTimerView: View {
    @Environment(\.dismiss) private var dismiss
    let sleepTimer = SleepTimerService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.xxl) {
                if sleepTimer.isActive {
                    activeSection
                } else {
                    presetSection
                }
            }
            .padding(DS.Spacing.lg)
            .navigationTitle("Uyku Zamanlayicisi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    // MARK: - Active

    private var activeSection: some View {
        VStack(spacing: DS.Spacing.xxl) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(.accent.opacity(0.15), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerProgress)

                VStack(spacing: DS.Spacing.xs) {
                    Image(systemName: sleepTimer.selectedPreset?.icon ?? "moon.zzz")
                        .font(.title2)
                        .foregroundStyle(.accent)

                    Text(sleepTimer.formattedRemaining)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    Text("kaldi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 190, height: 190)

            Button {
                sleepTimer.addFiveMinutes()
            } label: {
                Label("+5 dakika", systemImage: "plus.circle")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(.fill.tertiary)
                    .clipShape(Capsule())
            }

            Spacer()

            Button(role: .destructive) {
                sleepTimer.stop()
                HapticService.timerWarning()
            } label: {
                Text("Zamanlayiciyi Durdur")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            }
        }
    }

    // MARK: - Presets

    private var presetSection: some View {
        VStack(spacing: DS.Spacing.xl) {
            VStack(spacing: DS.Spacing.sm) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.accent)

                Text("Dinlerken uykuya dal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, DS.Spacing.lg)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.md) {
                ForEach(SleepTimerService.Preset.allCases) { preset in
                    Button {
                        sleepTimer.start(preset: preset)
                        HapticService.toneChanged()
                        dismiss()
                    } label: {
                        VStack(spacing: DS.Spacing.sm) {
                            Image(systemName: preset.icon)
                                .font(.title2)
                            Text(preset.displayName)
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.lg)
                        .background(.fill.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    private var timerProgress: CGFloat {
        guard let preset = sleepTimer.selectedPreset, preset.seconds > 0 else { return 0 }
        return sleepTimer.remainingSeconds / preset.seconds
    }
}

#Preview { SleepTimerView() }
