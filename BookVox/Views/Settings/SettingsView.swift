import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Ayarlar ekrani
// Hesap, oynatma tercihleri, gorunum, bildirimler, depolama, hakkinda

struct SettingsView: View {
    @Bindable var authVM: AuthViewModel
    @Environment(\.modelContext) private var context
    @Query private var preferences: [UserPreferences]

    @State private var cacheSize: String = "Hesaplaniyor..."
    @State private var showClearConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var showPaywall = false
    @State private var notificationPermission = false

    private let subscription = SubscriptionService.shared

    private var prefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }

    var body: some View {
        NavigationStack {
            List {
                // Hesap
                accountSection

                // Oynatma
                playbackSection

                // Gorunum
                appearanceSection

                // Bildirimler
                notificationSection

                // Depolama
                storageSection

                // Hakkinda
                aboutSection

                // Cikis
                Section {
                    Button("Cikis Yap", role: .destructive) {
                        Task { await authVM.signOut() }
                    }

                    Button("Hesabi Sil", role: .destructive) {
                        showDeleteAccountConfirm = true
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert(
                "Hesabi Sil",
                isPresented: $showDeleteAccountConfirm
            ) {
                Button("Sil", role: .destructive) {
                    Task { await authVM.deleteAccount() }
                }
                Button("Iptal", role: .cancel) { }
            } message: {
                Text("Hesabiniz ve tum verileriniz kalici olarak silinecek. Bu islem geri alinamaz.")
            }
            .confirmationDialog(
                "Cache'i temizlemek istediginize emin misiniz?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Temizle", role: .destructive) {
                    Task {
                        try? await StorageService.shared.clearAllCache()
                        await updateCacheSize()
                    }
                }
            }
            .task {
                await updateCacheSize()
                notificationPermission = await checkNotificationPermission()
            }
        }
    }

    // MARK: - Hesap

    private var accountSection: some View {
        Section("Hesap") {
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(.accent.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Text(String(authVM.email.prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundStyle(.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(authVM.email.isEmpty ? "Kullanici" : authVM.email)
                        .font(.subheadline.bold())
                    Text(subscription.isPremium ? "Premium" : "Free Plan")
                        .font(.caption)
                        .foregroundStyle(subscription.isPremium ? .orange : .secondary)
                }
            }
            .padding(.vertical, 4)

            if subscription.isPremium {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading) {
                        Text("Premium Aktif")
                            .foregroundStyle(.orange)
                        if let exp = subscription.expirationDate {
                            Text("Yenileme: \(exp, style: .date)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.orange)
                        Text("Premium'a Yukselt")
                            .foregroundStyle(.orange)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Oynatma

    private var playbackSection: some View {
        Section("Oynatma") {
            // Varsayilan ton
            NavigationLink {
                TonePickerView(
                    selectedTone: TTSService.Tone(rawValue: prefs.defaultTone) ?? .storyteller,
                    onSelect: { tone in
                        prefs.defaultTone = tone.rawValue
                        try? context.save()
                    }
                )
            } label: {
                HStack {
                    Label("Varsayilan Ses Tonu", systemImage: "waveform")
                    Spacer()
                    Text(TTSService.Tone(rawValue: prefs.defaultTone)?.displayName ?? "Storyteller")
                        .foregroundStyle(.secondary)
                }
            }

            // Oynatma hizi
            HStack {
                Label("Varsayilan Hiz", systemImage: "gauge.with.dots.needle.33percent")
                Spacer()
                Stepper(
                    String(format: "%.2gx", prefs.playbackSpeed),
                    value: Binding(
                        get: { prefs.playbackSpeed },
                        set: {
                            prefs.playbackSpeed = $0
                            try? context.save()
                        }
                    ),
                    in: 0.5...3.0,
                    step: 0.25
                )
            }

            // Atlama suresi
            HStack {
                Label("Ileri Atlama", systemImage: "goforward")
                Spacer()
                Picker("", selection: Binding(
                    get: { prefs.skipForwardInterval },
                    set: {
                        prefs.skipForwardInterval = $0
                        try? context.save()
                    }
                )) {
                    ForEach([5.0, 10.0, 15.0, 30.0, 60.0], id: \.self) { sec in
                        Text("\(Int(sec))sn").tag(sec)
                    }
                }
                .pickerStyle(.menu)
            }

            // Otomatik sonraki sayfa
            Toggle(isOn: Binding(
                get: { prefs.autoPlayNextPage },
                set: {
                    prefs.autoPlayNextPage = $0
                    try? context.save()
                }
            )) {
                Label("Otomatik Sonraki Sayfa", systemImage: "forward.fill")
            }

            // Crossfade
            Toggle(isOn: Binding(
                get: { prefs.crossfadeEnabled },
                set: {
                    prefs.crossfadeEnabled = $0
                    try? context.save()
                }
            )) {
                Label("Sayfa Gecis Efekti", systemImage: "arrow.right.arrow.left")
            }
        }
    }

    // MARK: - Gorunum

    private var appearanceSection: some View {
        Section("Gorunum") {
            // Tema
            Picker(selection: Binding(
                get: { prefs.darkModePreference },
                set: {
                    prefs.darkModePreference = $0
                    try? context.save()
                }
            )) {
                ForEach(UserPreferences.DarkMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            } label: {
                Label("Tema", systemImage: "circle.lefthalf.filled")
            }

            // Font boyutu
            HStack {
                Label("Okuyucu Font Boyutu", systemImage: "textformat.size")
                Spacer()
                Stepper(
                    "\(Int(prefs.readerFontSize))",
                    value: Binding(
                        get: { prefs.readerFontSize },
                        set: {
                            prefs.readerFontSize = $0
                            try? context.save()
                        }
                    ),
                    in: 14...28,
                    step: 2
                )
            }

            // Satir araligi
            HStack {
                Label("Satir Araligi", systemImage: "text.alignleft")
                Spacer()
                Stepper(
                    "\(Int(prefs.readerLineSpacing))",
                    value: Binding(
                        get: { prefs.readerLineSpacing },
                        set: {
                            prefs.readerLineSpacing = $0
                            try? context.save()
                        }
                    ),
                    in: 4...12,
                    step: 2
                )
            }
        }
    }

    // MARK: - Bildirimler

    private var notificationSection: some View {
        Section("Bildirimler") {
            Toggle(isOn: Binding(
                get: { prefs.dailyReminderEnabled },
                set: { enabled in
                    prefs.dailyReminderEnabled = enabled
                    try? context.save()
                    if enabled {
                        Task {
                            let granted = await NotificationService.requestPermission()
                            if granted {
                                NotificationService.scheduleDailyReminder(
                                    hour: prefs.dailyReminderHour,
                                    minute: prefs.dailyReminderMinute
                                )
                            }
                        }
                    } else {
                        NotificationService.cancelAll()
                    }
                }
            )) {
                Label("Gunluk Hatirlatici", systemImage: "bell")
            }

            if prefs.dailyReminderEnabled {
                DatePicker(
                    "Hatirlatma Saati",
                    selection: Binding(
                        get: {
                            Calendar.current.date(
                                from: DateComponents(
                                    hour: prefs.dailyReminderHour,
                                    minute: prefs.dailyReminderMinute
                                )
                            ) ?? .now
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            prefs.dailyReminderHour = components.hour ?? 20
                            prefs.dailyReminderMinute = components.minute ?? 0
                            try? context.save()
                            NotificationService.scheduleDailyReminder(
                                hour: prefs.dailyReminderHour,
                                minute: prefs.dailyReminderMinute
                            )
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )

                // Gunluk hedef
                HStack {
                    Label("Gunluk Hedef", systemImage: "target")
                    Spacer()
                    Stepper(
                        "\(Int(prefs.dailyGoalMinutes))dk",
                        value: Binding(
                            get: { prefs.dailyGoalMinutes },
                            set: {
                                prefs.dailyGoalMinutes = $0
                                try? context.save()
                            }
                        ),
                        in: 5...120,
                        step: 5
                    )
                }
            }
        }
    }

    // MARK: - Depolama

    private var storageSection: some View {
        Section("Depolama") {
            HStack {
                Label("Cache Boyutu", systemImage: "internaldrive")
                Spacer()
                Text(cacheSize)
                    .foregroundStyle(.secondary)
            }

            Button("Cache'i Temizle", role: .destructive) {
                showClearConfirm = true
            }
        }
    }

    // MARK: - Hakkinda

    private var aboutSection: some View {
        Section("Hakkinda") {
            HStack {
                Text("Surum")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }

            // Baglanti durumu
            HStack {
                Label("Baglanti", systemImage: NetworkMonitor.shared.connectionType.icon)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(NetworkMonitor.shared.isConnected ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(NetworkMonitor.shared.isConnected ? "Bagli" : "Cevrimdisi")
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: URL(string: "https://bookvox.app/privacy")!) {
                Label("Gizlilik Politikasi", systemImage: "hand.raised")
            }

            Link(destination: URL(string: "https://bookvox.app/terms")!) {
                Label("Kullanim Kosullari", systemImage: "doc.text")
            }
        }
    }

    // MARK: - Helpers

    private func updateCacheSize() async {
        do {
            let bytes = try await StorageService.shared.cacheSize()
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            cacheSize = formatter.string(fromByteCount: bytes)
        } catch {
            cacheSize = "Hesaplanamadi"
        }
    }

    private func checkNotificationPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}

#Preview {
    SettingsView(authVM: AuthViewModel())
        .modelContainer(for: [UserPreferences.self], inMemory: true)
}
