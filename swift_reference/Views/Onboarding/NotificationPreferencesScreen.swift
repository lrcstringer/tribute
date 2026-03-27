import SwiftUI
import UserNotifications

struct NotificationPreferencesScreen: View {
    let onContinue: () -> Void

    @State private var remindersEnabled: Bool = true
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var permissionRequested: Bool = false
    @State private var showContent: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Stay on track,\ngently.")
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("We\u{2019}ll send a gentle nudge \u{2014} never guilt. Just a quiet reminder that your tribute is waiting.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily Reminders")
                                    .font(.system(.headline, design: .serif))

                                Text("A small prompt at the time you choose")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $remindersEnabled)
                                .tint(TributeColor.golden)
                                .labelsHidden()
                        }
                        .padding(16)
                        .background(TributeColor.cardBackground)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                        )

                        if remindersEnabled {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Remind me at")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(TributeColor.softGold.opacity(0.6))

                                DatePicker(
                                    "",
                                    selection: $reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .clipped()
                                .colorScheme(.dark)
                            }
                            .padding(16)
                            .background(TributeColor.cardBackground)
                            .clipShape(.rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: remindersEnabled)

                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(TributeColor.golden.opacity(0.5))

                        Text("You can change this anytime in Settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 6) {
                        Text("\u{201C}Commit to the Lord whatever you do, and he will establish your plans.\u{201D}")
                            .font(.system(.subheadline, design: .serif))
                            .italic()
                            .foregroundStyle(TributeColor.softGold.opacity(0.6))
                            .multilineTextAlignment(.center)
                        Text("Proverbs 16:3")
                            .font(.caption)
                            .foregroundStyle(TributeColor.golden.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
            }

            VStack(spacing: 12) {
                Button {
                    handleContinue()
                } label: {
                    HStack(spacing: 8) {
                        Text(remindersEnabled ? "Enable Reminders" : "Continue")
                        Image(systemName: "arrow.right")
                            .font(.subheadline)
                    }
                    .tributeButton()
                }

                if remindersEnabled {
                    Button {
                        remindersEnabled = false
                        savePreferences()
                        onContinue()
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showContent = true
            }
        }
    }

    private func handleContinue() {
        if remindersEnabled {
            requestNotificationPermission()
        } else {
            savePreferences()
            onContinue()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            Task { @MainActor in
                if granted {
                    savePreferences()
                }
                onContinue()
            }
        }
    }

    private func savePreferences() {
        UserDefaults.standard.set(remindersEnabled, forKey: "tribute_reminders_enabled")
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        UserDefaults.standard.set(components.hour ?? 8, forKey: "tribute_reminder_hour")
        UserDefaults.standard.set(components.minute ?? 0, forKey: "tribute_reminder_minute")
    }
}
