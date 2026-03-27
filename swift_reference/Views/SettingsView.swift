import SwiftUI
import SwiftData

struct SettingsView: View {
    let store: StoreViewModel

    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Environment(\.modelContext) private var modelContext
    @State private var milestoneService = MilestoneService()
    @State private var remindersEnabled: Bool = UserDefaults.standard.bool(forKey: "tribute_reminders_enabled")
    @State private var reminderTime: Date = {
        let hour = UserDefaults.standard.integer(forKey: "tribute_reminder_hour")
        let minute = UserDefaults.standard.integer(forKey: "tribute_reminder_minute")
        var components = DateComponents()
        components.hour = (hour == 0 && !UserDefaults.standard.bool(forKey: "tribute_reminders_enabled")) ? 8 : hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var notificationStatus: NotificationStatus = .unknown
    @State private var showPaywall: Bool = false
    @State private var showResetConfirmation: Bool = false
    @State private var showResetSuccess: Bool = false
    @State private var authService = AuthenticationService.shared

    private enum NotificationStatus {
        case unknown, authorized, denied, notDetermined
    }

    private var totalCheckIns: Int {
        habits.reduce(0) { $0 + $1.totalCompletedDays() }
    }

    private var totalMinutesGiven: Double {
        habits.filter { $0.habitTrackingType == .timed }.reduce(0.0) { $0 + $1.totalValue() }
    }

    private var totalCleanDays: Int {
        habits.filter { $0.habitTrackingType == .abstain }.reduce(0) { $0 + $1.totalCompletedDays() }
    }

    private var totalCountValue: Double {
        habits.filter { $0.habitTrackingType == .count }.reduce(0.0) { $0 + $1.totalValue() }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TRIBUTE")
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(TributeColor.golden)
                        Text("Track your habits. Give them to God.")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(TributeColor.softGold.opacity(0.7))
                    }
                    .listRowBackground(TributeColor.cardBackground)
                }

                accountSection

                subscriptionSection

                remindersSection

                habitsSection

                statsSection

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                        .listRowBackground(TributeColor.cardBackground)
                }

                resetSection
            }
            .scrollContentBackground(.hidden)
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                TributePaywallView(store: store)
                    .preferredColorScheme(.dark)
            }
            .alert("Reset All Data", isPresented: $showResetConfirmation) {
                Button("Reset Everything", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your habits, entries, and progress. This cannot be undone.")
            }
            .alert("Data Reset", isPresented: $showResetSuccess) {
                Button("OK") {}
            } message: {
                Text("All data has been cleared. Your subscription status is unchanged.")
            }
            .task {
                await checkNotificationStatus()
            }
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        Section("Account") {
            if authService.isAuthenticated {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(TributeColor.sage.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(TributeColor.sage)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(authService.displayName ?? "Signed In")
                            .font(.subheadline.weight(.semibold))
                        Text("Apple Account")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(TributeColor.sage)
                }
                .listRowBackground(TributeColor.cardBackground)

                Button(role: .destructive) {
                    authService.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                        .foregroundStyle(TributeColor.warmCoral)
                }
                .listRowBackground(TributeColor.cardBackground)
            } else {
                Button {
                    Task { await authService.signInWithApple() }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sign in with Apple")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Required for Prayer Circles & backup")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if authService.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(authService.isLoading)
                .listRowBackground(TributeColor.cardBackground)
            }

            if let error = authService.error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(TributeColor.warmCoral)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(TributeColor.warmCoral)
                }
                .listRowBackground(TributeColor.cardBackground)
            }
        }
    }

    @ViewBuilder
    private var subscriptionSection: some View {
        Section("Subscription") {
            if store.isPremium {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(TributeColor.golden.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(TributeColor.golden)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tribute Pro")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TributeColor.golden)
                        Text("All premium features unlocked")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(TributeColor.golden)
                }
                .listRowBackground(TributeColor.golden.opacity(0.06))
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(TributeColor.golden.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: "crown")
                                .font(.system(size: 16))
                                .foregroundStyle(TributeColor.golden.opacity(0.6))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Pro")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Unlimited habits, SOS, analytics & more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(TributeColor.cardBackground)
            }

            Button {
                Task { await store.restore() }
            } label: {
                HStack {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if store.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .listRowBackground(TributeColor.cardBackground)
        }
    }

    @ViewBuilder
    private var remindersSection: some View {
        Section("Reminders") {
            Toggle(isOn: $remindersEnabled) {
                Label("Daily Reminders", systemImage: "bell.fill")
            }
            .tint(TributeColor.golden)
            .listRowBackground(TributeColor.cardBackground)
            .onChange(of: remindersEnabled) { _, _ in
                saveReminderPreferences()
            }

            if remindersEnabled {
                DatePicker(selection: $reminderTime, displayedComponents: .hourAndMinute) {
                    Label("Reminder Time", systemImage: "clock")
                }
                .listRowBackground(TributeColor.cardBackground)
                .onChange(of: reminderTime) { _, _ in
                    saveReminderPreferences()
                }
            }

            switch notificationStatus {
            case .denied:
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(TributeColor.warmCoral)
                        Text("Notifications disabled — tap to open Settings")
                            .font(.caption)
                            .foregroundStyle(TributeColor.warmCoral)
                    }
                }
                .listRowBackground(TributeColor.cardBackground)
            case .notDetermined:
                Button {
                    Task {
                        let _ = await NotificationService.shared.requestAuthorization()
                        await checkNotificationStatus()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge")
                            .font(.caption)
                            .foregroundStyle(TributeColor.golden)
                        Text("Enable notifications")
                            .font(.caption)
                            .foregroundStyle(TributeColor.golden)
                    }
                }
                .listRowBackground(TributeColor.cardBackground)
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var habitsSection: some View {
        Section("Your Habits") {
            ForEach(habits) { habit in
                HStack(spacing: 12) {
                    Image(systemName: habit.habitCategory.iconName)
                        .font(.system(size: 16))
                        .foregroundStyle(habit.isBuiltIn ? TributeColor.golden : TributeColor.sage)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(habit.name)
                                .font(.subheadline.weight(.medium))
                            if habit.isBuiltIn {
                                Text("Built-in")
                                    .font(.caption2)
                                    .foregroundStyle(TributeColor.golden)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(TributeColor.golden.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }

                        HStack(spacing: 8) {
                            Text(habit.habitTrackingType.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("\u{00B7}")
                                .font(.caption)
                                .foregroundStyle(.secondary.opacity(0.4))

                            Text("\(milestoneService.habitAge(for: habit)) days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Text(milestoneService.lifetimeStat(for: habit).primaryValue)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(TributeColor.softGold.opacity(0.6))
                }
                .listRowBackground(TributeColor.cardBackground)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let habit = habits[index]
                    if !habit.isBuiltIn {
                        modelContext.delete(habit)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statsSection: some View {
        Section("Lifetime Stats") {
            LabeledContent {
                Text("\(totalCheckIns)")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(TributeColor.golden)
            } label: {
                Label("Total check-ins", systemImage: "checkmark.circle")
            }
            .listRowBackground(TributeColor.cardBackground)

            if totalMinutesGiven > 0 {
                let hours = Int(totalMinutesGiven) / 60
                let mins = Int(totalMinutesGiven) % 60
                LabeledContent {
                    Text(hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(TributeColor.golden)
                } label: {
                    Label("Time given", systemImage: "clock")
                }
                .listRowBackground(TributeColor.cardBackground)
            }

            if totalCleanDays > 0 {
                LabeledContent {
                    Text("\(totalCleanDays)")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(TributeColor.sage)
                } label: {
                    Label("Clean days", systemImage: "shield.fill")
                }
                .listRowBackground(TributeColor.cardBackground)
            }

            if totalCountValue > 0 {
                LabeledContent {
                    Text("\(Int(totalCountValue))")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(TributeColor.golden)
                } label: {
                    Label("Total counted", systemImage: "number")
                }
                .listRowBackground(TributeColor.cardBackground)
            }

            LabeledContent {
                Text("\(habits.count)")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(TributeColor.golden)
            } label: {
                Label("Active habits", systemImage: "list.bullet")
            }
            .listRowBackground(TributeColor.cardBackground)

            let reachedMilestones = habits.flatMap { milestoneService.milestones(for: $0).filter(\.isReached) }
            if !reachedMilestones.isEmpty {
                LabeledContent {
                    Text("\(reachedMilestones.count)")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(TributeColor.golden)
                } label: {
                    Label("Milestones reached", systemImage: "star.fill")
                }
                .listRowBackground(TributeColor.cardBackground)
            }
        }
    }

    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Label("Reset All Data", systemImage: "trash")
                        .font(.subheadline)
                        .foregroundStyle(TributeColor.warmCoral)
                    Spacer()
                }
            }
            .listRowBackground(TributeColor.warmCoral.opacity(0.06))
        } footer: {
            Text("This permanently deletes all habits, entries, and progress.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func saveReminderPreferences() {
        UserDefaults.standard.set(remindersEnabled, forKey: "tribute_reminders_enabled")
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        UserDefaults.standard.set(components.hour ?? 8, forKey: "tribute_reminder_hour")
        UserDefaults.standard.set(components.minute ?? 0, forKey: "tribute_reminder_minute")

        let notificationService = NotificationService.shared
        if remindersEnabled {
            notificationService.scheduleDailyReminders()
        } else {
            notificationService.cancelDailyReminders()
        }
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            notificationStatus = .authorized
        case .denied:
            notificationStatus = .denied
        case .notDetermined:
            notificationStatus = .notDetermined
        default:
            notificationStatus = .unknown
        }
    }

    private func resetAllData() {
        for habit in habits {
            modelContext.delete(habit)
        }
        try? modelContext.save()

        UserDefaults.standard.removeObject(forKey: "tribute_reminders_enabled")
        UserDefaults.standard.removeObject(forKey: "tribute_reminder_hour")
        UserDefaults.standard.removeObject(forKey: "tribute_reminder_minute")

        remindersEnabled = false

        NotificationService.shared.cancelDailyReminders()

        showResetSuccess = true
    }
}
