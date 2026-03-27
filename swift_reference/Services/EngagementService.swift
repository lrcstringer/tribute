import Foundation
import SwiftData

@Observable
@MainActor
class EngagementService {
    private let calendar = Calendar.current

    var currentMessage: EngagementMessage?

    private var onboardingDate: Date {
        (UserDefaults.standard.object(forKey: "tribute_onboarding_date") as? Date) ?? Date()
    }

    var daysSinceOnboarding: Int {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: onboardingDate), to: calendar.startOfDay(for: Date())).day ?? 0
        return max(days, 0)
    }

    private var dismissedKey: String {
        "tribute_engagement_dismissed_day_\(daysSinceOnboarding)"
    }

    private var isDismissedToday: Bool {
        UserDefaults.standard.bool(forKey: dismissedKey)
    }

    func dismissCurrentMessage() {
        UserDefaults.standard.set(true, forKey: dismissedKey)
        currentMessage = nil
    }

    var isPremium: Bool = false

    func evaluateMessage(habits: [Habit]) {
        guard !isDismissedToday else {
            currentMessage = nil
            return
        }

        let day = daysSinceOnboarding

        guard day >= 1 && day <= 10 else {
            evaluateTimeMilestoneMessage(habits: habits)
            return
        }

        let gratitudeHabit = habits.first { $0.isBuiltIn && $0.habitCategory == .gratitude }
        let customHabits = habits.filter { !$0.isBuiltIn }
        let firstCustom = customHabits.first
        let gratitudeDays = gratitudeHabit?.totalCompletedDays() ?? 0

        let message: EngagementMessage?

        switch day {
        case 1:
            message = EngagementMessage(
                icon: "sun.max.fill",
                title: "Day 1",
                body: "Your second day of gratitude plus your first custom habit check-in. Two tributes in one day. Nice.",
                accent: .golden
            )
        case 2:
            if let habit = firstCustom {
                message = EngagementMessage(
                    icon: "quote.opening",
                    title: "Remember why",
                    body: "You said: \"\(habit.purposeStatement)\" That's still true today.",
                    accent: .golden
                )
            } else {
                message = EngagementMessage(
                    icon: "quote.opening",
                    title: "Day 2",
                    body: "Two days of showing up. God sees every one.",
                    accent: .golden
                )
            }
        case 3:
            if let habit = firstCustom {
                let stat = statDescription(for: habit)
                message = EngagementMessage(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "It's adding up",
                    body: "You've given God \(stat) through \(habit.name.lowercased()) this week. That's more than most people give to any habit.",
                    accent: .golden
                )
            } else {
                message = EngagementMessage(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Day 3",
                    body: "Three days in. Your tribute is building.",
                    accent: .golden
                )
            }
        case 4:
            message = EngagementMessage(
                icon: "hand.raised.fill",
                title: "The hard part",
                body: "You're in the hardest days of any new habit. But you've thanked God \(gratitudeDays) days straight — He sees your faithfulness.",
                accent: .sage
            )
        case 5:
            message = EngagementMessage(
                icon: "heart.fill",
                title: "Still here",
                body: "Day 5. The novelty fades, but the purpose doesn't. You're doing this for something bigger than motivation.",
                accent: .sage
            )
        case 6:
            message = EngagementMessage(
                icon: "calendar",
                title: "Tomorrow is special",
                body: "Tomorrow is your first Look Back. Whatever it looks like, it's worth celebrating.",
                accent: .golden
            )
        case 7:
            message = nil
        case 8:
            message = EngagementMessage(
                icon: "person.2.fill",
                title: "You're not alone",
                body: "Having even one person praying with you makes a real difference. Prayer Circles are coming soon.",
                accent: .golden
            )
        case 9:
            message = EngagementMessage(
                icon: "person.2.fill",
                title: "Community matters",
                body: "Accountability isn't about pressure — it's about knowing someone's in your corner. Stay tuned for Prayer Circles.",
                accent: .golden
            )
        case 10:
            message = EngagementMessage(
                icon: "star.fill",
                title: "10 days in",
                body: "10 days of gratitude. \(gratitudeDays) times you chose to thank God. This is when most people quit other apps. Not you.",
                accent: .golden
            )
        default:
            message = nil
        }

        currentMessage = message
    }

    private func evaluateTimeMilestoneMessage(habits: [Habit]) {
        let day = daysSinceOnboarding
        let milestoneKey = "tribute_time_milestone_shown_\(day)"
        guard !UserDefaults.standard.bool(forKey: milestoneKey) else {
            evaluateVariableReinforcement(habits: habits)
            return
        }

        let freeMilestones: Set<Int> = [7, 21, 30]
        let allMilestones: [(day: Int, title: String, body: String)] = [
            (7, "One week down", "You showed up, and God met you in it. Let\u{2019}s keep going."),
            (14, "Two weeks", "You\u{2019}re past the point where most people quit a new app. You\u{2019}re still here."),
            (21, "3 weeks in", "This is usually when the newness fades and it starts to feel like work. That\u{2019}s normal. You\u{2019}re doing the hard part."),
            (30, "A full month", "30 days of giving this to God. That\u{2019}s not a small thing."),
            (45, "Over 6 weeks", "Most people never make it this far. The rhythm is starting to take hold. Keep showing up."),
            (66, "66 days", "Research says this is roughly when a habit becomes automatic. This isn\u{2019}t something you do anymore \u{2014} it\u{2019}s who you are. Keep going."),
            (100, "100 days", "A hundred times you chose to show up. That\u{2019}s a life that\u{2019}s being changed."),
            (365, "A full year", "365 days of giving this to God. Whatever this year looked like \u{2014} the strong weeks and the quiet ones \u{2014} He was in all of it."),
        ]

        let availableMilestones = isPremium ? allMilestones : allMilestones.filter { freeMilestones.contains($0.day) }

        if let milestone = availableMilestones.first(where: { $0.day == day }) {
            UserDefaults.standard.set(true, forKey: milestoneKey)
            var msg = EngagementMessage(
                icon: "sparkles",
                title: milestone.title,
                body: milestone.body,
                accent: .golden
            )
            if !isPremium && milestone.day == 21 {
                msg.paywallContext = EngagementMessage.PaywallContext(
                    title: "3 weeks in and still going",
                    message: "Unlock your 52-week heatmap, detailed analytics, and see the full picture of your journey."
                )
            }
            currentMessage = msg
        } else {
            evaluateVariableReinforcement(habits: habits)
        }
    }

    private func evaluateVariableReinforcement(habits: [Habit]) {
        guard isPremium else {
            currentMessage = nil
            return
        }

        let day = daysSinceOnboarding
        guard day > 14 else {
            currentMessage = nil
            return
        }

        let reinforcementKey = "tribute_variable_reinforcement_last"
        let lastShown = UserDefaults.standard.integer(forKey: reinforcementKey)
        let daysSinceLast = day - lastShown

        var rng = SeededRandomNumberGenerator(seed: UInt64(day * 7 + 31))
        let interval = Int.random(in: 14...28, using: &rng)

        guard daysSinceLast >= interval else {
            currentMessage = nil
            return
        }

        let gratitudeHabit = habits.first { $0.isBuiltIn && $0.habitCategory == .gratitude }
        let gratitudeDays = gratitudeHabit?.totalCompletedDays() ?? 0
        let customHabits = habits.filter { !$0.isBuiltIn }

        var messages: [(String, String, String)] = []

        if day >= 180 {
            messages.append(("sparkles", "Still here", "\(day) days ago you started this. You\u{2019}re still here. That\u{2019}s remarkable."))
        }

        if gratitudeDays >= 100 {
            messages.append(("heart.fill", "Gratitude milestone", "Your gratitude count just passed \(gratitudeDays). \(gratitudeDays) days of thanking God. Let that sink in."))
        }

        for habit in customHabits {
            if habit.habitTrackingType == .timed {
                let totalHours = Int(habit.totalValue() / 60)
                if totalHours >= 50 {
                    messages.append(("flame.fill", "Time given", "You\u{2019}ve given God \(totalHours) hours through \(habit.name.lowercased()). That\u{2019}s incredible dedication."))
                }
            }
            if habit.habitTrackingType == .count {
                let total = Int(habit.totalValue())
                if total >= 500 {
                    let unit = habit.targetUnit.isEmpty ? "completed" : habit.targetUnit
                    messages.append(("number", "Count milestone", "\(total) \(unit). Every single one counted."))
                }
            }
        }

        if messages.isEmpty {
            messages.append(("sun.max.fill", "Keep going", "Remember when this felt hard? Look at you now."))
        }

        let index = Int.random(in: 0..<messages.count, using: &rng)
        let (icon, title, body) = messages[index]

        UserDefaults.standard.set(day, forKey: reinforcementKey)
        currentMessage = EngagementMessage(
            icon: icon,
            title: title,
            body: body,
            accent: .golden
        )
    }

    private func statDescription(for habit: Habit) -> String {
        switch habit.habitTrackingType {
        case .timed:
            let mins = Int(habit.totalValue())
            if mins >= 60 {
                return "\(mins / 60)h \(mins % 60)m"
            }
            return "\(mins) minutes"
        case .count:
            let total = Int(habit.totalValue())
            let unit = habit.targetUnit.isEmpty ? "completed" : habit.targetUnit
            return "\(total) \(unit)"
        case .checkIn:
            return "\(habit.totalCompletedDays()) days"
        case .abstain:
            return "\(habit.totalCompletedDays()) clean days"
        }
    }
}

nonisolated struct EngagementMessage: Sendable, Equatable {
    let icon: String
    let title: String
    let body: String
    let accent: EngagementAccent
    var paywallContext: PaywallContext?

    nonisolated enum EngagementAccent: Sendable, Equatable {
        case golden
        case sage
    }

    nonisolated struct PaywallContext: Sendable, Equatable {
        let title: String
        let message: String
    }
}

nonisolated struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
