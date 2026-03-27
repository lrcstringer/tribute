import Foundation
import UserNotifications

@Observable
@MainActor
class NotificationService {
    static let shared = NotificationService()

    var isAuthorized: Bool = false

    private let center = UNUserNotificationCenter.current()
    private let dailyReminderCategory = "DAILY_REMINDER"
    private let milestoneCategory = "MILESTONE"

    private let reminderMessages: [String] = [
        "Your tribute is waiting. Just a moment with God today.",
        "A few minutes. A small gift. God sees it all.",
        "Today's offering is ready whenever you are.",
        "Even a single check-in changes the shape of your day.",
        "Your habits are waiting — each one a gift to God.",
        "A quiet moment with God today. That's all it takes.",
        "Start with gratitude. Everything else follows.",
        "God meets you in the effort and in the rest.",
        "One small step today. He's already walking with you.",
        "Your tribute matters — even on the hard days.",
    ]

    private let timeMilestoneMessages: [(day: Int, title: String, body: String)] = [
        (7, "One week down", "You showed up, and God met you in it. Let's keep going."),
        (14, "Two weeks", "You're past the point where most people quit a new app. You're still here."),
        (21, "3 weeks in", "This is usually when the newness fades and it starts to feel like work. That's normal. You're doing the hard part."),
        (30, "A full month", "30 days of giving this to God. That's not a small thing."),
        (45, "Over 6 weeks", "Most people never make it this far. The rhythm is starting to take hold. Keep showing up."),
        (66, "66 days", "Research says this is roughly when a habit becomes automatic. This isn't something you do anymore — it's who you are."),
        (100, "100 days", "A hundred times you chose to show up. That's a life that's being changed."),
        (365, "A full year", "365 days of giving this to God. Whatever this year looked like — the strong weeks and the quiet ones — He was in all of it."),
    ]

    func checkAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    func clearBadge() {
        center.setBadgeCount(0)
    }

    func scheduleDailyReminders() {
        let enabled = UserDefaults.standard.bool(forKey: "tribute_reminders_enabled")
        guard enabled else {
            cancelDailyReminders()
            return
        }

        let hour = UserDefaults.standard.integer(forKey: "tribute_reminder_hour")
        let minute = UserDefaults.standard.integer(forKey: "tribute_reminder_minute")
        let reminderHour = (hour == 0 && minute == 0 && !UserDefaults.standard.bool(forKey: "tribute_reminders_enabled")) ? 8 : hour

        cancelDailyReminders()

        for i in 0..<7 {
            let content = UNMutableNotificationContent()
            content.title = "Tribute"
            content.body = reminderMessages[i % reminderMessages.count]
            content.sound = .default
            content.categoryIdentifier = dailyReminderCategory
            content.badge = 1

            var dateComponents = DateComponents()
            dateComponents.hour = reminderHour
            dateComponents.minute = minute
            dateComponents.weekday = i + 1

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "daily_reminder_\(i)",
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    func cancelDailyReminders() {
        let ids = (0..<7).map { "daily_reminder_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func scheduleTimeMilestoneNotifications(habitCreatedAt: Date, habitName: String) {
        let calendar = Calendar.current
        let hour = UserDefaults.standard.integer(forKey: "tribute_reminder_hour")
        let minute = UserDefaults.standard.integer(forKey: "tribute_reminder_minute")
        let notifHour = (hour == 0 && minute == 0) ? 9 : hour
        let notifMinute = (hour == 0 && minute == 0) ? 0 : minute

        for milestone in timeMilestoneMessages {
            guard let targetDate = calendar.date(byAdding: .day, value: milestone.day, to: calendar.startOfDay(for: habitCreatedAt)) else { continue }

            if targetDate <= Date() { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = notifHour
            components.minute = notifMinute

            let content = UNMutableNotificationContent()
            content.title = milestone.title
            content.body = milestone.body
            content.sound = .default
            content.categoryIdentifier = milestoneCategory

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "milestone_\(habitName.lowercased().replacingOccurrences(of: " ", with: "_"))_day\(milestone.day)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    func scheduleVariableReinforcement(daysSinceOnboarding: Int) {
        guard daysSinceOnboarding >= 30 else { return }

        center.removePendingNotificationRequests(withIdentifiers: ["variable_reinforcement"])

        let daysUntilNext = Int.random(in: 14...28)
        let calendar = Calendar.current
        guard let targetDate = calendar.date(byAdding: .day, value: daysUntilNext, to: Date()) else { return }

        let messages = [
            "Remember when this felt hard? Look at you now.",
            "You're building something real. God sees every single day.",
            "Your consistency is its own kind of worship. Keep going.",
            "The rhythm you've built? That's not willpower — that's faithfulness.",
            "Some days it's easy, some days it's not. You show up either way. That matters.",
        ]

        let content = UNMutableNotificationContent()
        content.title = "Tribute"
        content.body = messages.randomElement() ?? messages[0]
        content.sound = .default

        let hour = UserDefaults.standard.integer(forKey: "tribute_reminder_hour")
        let minute = UserDefaults.standard.integer(forKey: "tribute_reminder_minute")
        var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
        components.hour = hour == 0 ? 10 : hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "variable_reinforcement",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func refreshAllNotifications(habits: [Habit]) async {
        await checkAuthorization()
        guard isAuthorized else { return }

        scheduleDailyReminders()

        let onboardingDate = UserDefaults.standard.object(forKey: "tribute_onboarding_date") as? Date ?? Date()
        let daysSince = Calendar.current.dateComponents([.day], from: onboardingDate, to: Date()).day ?? 0

        for habit in habits {
            scheduleTimeMilestoneNotifications(habitCreatedAt: habit.createdAt, habitName: habit.name)
        }

        scheduleVariableReinforcement(daysSinceOnboarding: daysSince)
    }
}
