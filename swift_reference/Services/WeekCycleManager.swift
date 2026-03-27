import SwiftUI
import SwiftData

@Observable
@MainActor
class WeekCycleManager {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        return cal
    }()

    var weekDedicatedDate: Date? {
        get {
            UserDefaults.standard.object(forKey: "tribute_week_dedicated_date") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "tribute_week_dedicated_date")
        }
    }

    var lastLookBackWeekStart: Date? {
        get {
            UserDefaults.standard.object(forKey: "tribute_last_lookback_week") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "tribute_last_lookback_week")
        }
    }

    var currentWeekStart: Date {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
    }

    var previousWeekStart: Date {
        calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) ?? currentWeekStart
    }

    var isCurrentWeekDedicated: Bool {
        guard let dedicatedDate = weekDedicatedDate else { return false }
        return calendar.isDate(dedicatedDate, equalTo: currentWeekStart, toGranularity: .weekOfYear)
    }

    var isSunday: Bool {
        calendar.component(.weekday, from: Date()) == 1
    }

    var dayOfWeekIndex: Int {
        let weekday = calendar.component(.weekday, from: Date())
        return weekday - 1
    }

    var needsLookBack: Bool {
        guard let lastLookBack = lastLookBackWeekStart else {
            let onboardingDate = UserDefaults.standard.object(forKey: "tribute_onboarding_date") as? Date
            guard let onboardingDate else { return false }
            let onboardingWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: onboardingDate)) ?? onboardingDate
            return currentWeekStart > onboardingWeekStart
        }
        return currentWeekStart > lastLookBack
    }

    var needsDedication: Bool {
        !isCurrentWeekDedicated
    }

    func dedicateCurrentWeek() {
        weekDedicatedDate = Date()
    }

    func completeLookBack() {
        lastLookBackWeekStart = currentWeekStart
    }

    func weekDates(for weekStart: Date) -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var currentWeekDates: [Date] {
        weekDates(for: currentWeekStart)
    }

    var previousWeekDates: [Date] {
        weekDates(for: previousWeekStart)
    }

    func completedDays(for habit: Habit, in dates: [Date]) -> Int {
        dates.filter { date in
            habit.entries.contains { entry in
                calendar.isDate(entry.date, inSameDayAs: date) && entry.isCompleted
            }
        }.count
    }

    func completedDaysThisWeek(for habit: Habit) -> Int {
        let datesUpToToday = currentWeekDates.filter { $0 <= Date() }
        return completedDays(for: habit, in: datesUpToToday)
    }

    func activeDaysThisWeek(for habit: Habit) -> Int {
        let datesUpToToday = currentWeekDates.filter { $0 <= Date() }
        return datesUpToToday.filter { date in
            let weekday = calendar.component(.weekday, from: date)
            return habit.activeDaySet.contains(weekday)
        }.count
    }

    func microMilestonePreview(for habit: Habit) -> String? {
        let type = habit.habitTrackingType

        switch type {
        case .timed:
            let totalMinutes = habit.totalValue()
            let dailyTarget = habit.dailyTarget
            let activeDaysRemaining = currentWeekDates.filter { date in
                date > Date() && habit.activeDaySet.contains(calendar.component(.weekday, from: date))
            }.count
            let projectedMinutes = totalMinutes + (dailyTarget * Double(activeDaysRemaining + 1))
            let projectedHours = projectedMinutes / 60.0

            let milestones: [Double] = [1, 5, 10, 25, 50, 100, 250, 500, 1000]
            let currentHours = totalMinutes / 60.0
            for milestone in milestones {
                if currentHours < milestone && projectedHours >= milestone {
                    let minutesNeeded = (milestone * 60) - totalMinutes
                    let daysNeeded = Int(ceil(minutesNeeded / dailyTarget))
                    if let targetDate = calendar.date(byAdding: .day, value: daysNeeded, to: Date()) {
                        let dayName = dayFormatter.string(from: targetDate)
                        return "By \(dayName) you'll cross \(Int(milestone)) total hours."
                    }
                }
            }
            return nil

        case .count:
            let totalCount = habit.totalValue()
            let dailyTarget = habit.dailyTarget
            let activeDaysRemaining = currentWeekDates.filter { date in
                date > Date() && habit.activeDaySet.contains(calendar.component(.weekday, from: date))
            }.count
            let projectedCount = totalCount + (dailyTarget * Double(activeDaysRemaining + 1))

            let milestones: [Double] = [50, 100, 250, 500, 1000, 2500, 5000]
            for milestone in milestones {
                if totalCount < milestone && projectedCount >= milestone {
                    let needed = milestone - totalCount
                    let daysNeeded = Int(ceil(needed / dailyTarget))
                    if let targetDate = calendar.date(byAdding: .day, value: daysNeeded, to: Date()) {
                        let dayName = dayFormatter.string(from: targetDate)
                        return "You'll pass \(Int(milestone)) total \(habit.targetUnit.isEmpty ? "completed" : habit.targetUnit) by \(dayName)."
                    }
                }
            }
            return nil

        case .checkIn:
            let totalDays = Double(habit.totalCompletedDays())
            let activeDaysRemaining = currentWeekDates.filter { date in
                date > Date() && habit.activeDaySet.contains(calendar.component(.weekday, from: date))
            }.count
            let projectedDays = totalDays + Double(activeDaysRemaining + 1)

            let milestones: [Double] = [7, 14, 21, 30, 50, 100, 200, 365]
            for milestone in milestones {
                if totalDays < milestone && projectedDays >= milestone {
                    let needed = Int(milestone - totalDays)
                    if let targetDate = calendar.date(byAdding: .day, value: needed, to: Date()) {
                        let dayName = dayFormatter.string(from: targetDate)
                        return "Day \(Int(milestone)) lands on \(dayName)."
                    }
                }
            }
            return nil

        case .abstain:
            let consecutiveDays = consecutiveCleanDays(for: habit)
            let activeDaysRemaining = currentWeekDates.filter { $0 > Date() }.count
            let projectedConsecutive = consecutiveDays + activeDaysRemaining + 1

            let milestones = [7, 14, 21, 30, 60, 90, 180, 365]
            for milestone in milestones {
                if consecutiveDays < milestone && projectedConsecutive >= milestone {
                    let needed = milestone - consecutiveDays
                    if let targetDate = calendar.date(byAdding: .day, value: needed, to: Date()) {
                        let dayName = dayFormatter.string(from: targetDate)
                        return "By \(dayName), you'll have \(milestone) consecutive clean days."
                    }
                }
            }
            return nil
        }
    }

    func consecutiveCleanDays(for habit: Habit) -> Int {
        guard habit.habitTrackingType == .abstain else { return 0 }
        var count = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let hasEntry = habit.entries.contains { entry in
                calendar.isDate(entry.date, inSameDayAs: checkDate) && entry.isCompleted
            }
            if hasEntry {
                count += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else {
                break
            }
        }
        return count
    }

    func weekProjectionSummary(for habit: Habit) -> String {
        let activeDaysInWeek = currentWeekDates.filter { date in
            habit.activeDaySet.contains(calendar.component(.weekday, from: date))
        }.count

        switch habit.habitTrackingType {
        case .timed:
            let totalMinutes = habit.dailyTarget * Double(activeDaysInWeek)
            if totalMinutes >= 60 {
                let hours = totalMinutes / 60.0
                return String(format: "%.1f hours this week", hours)
            }
            return "\(Int(totalMinutes)) minutes this week"
        case .count:
            let total = Int(habit.dailyTarget) * activeDaysInWeek
            return "\(total) \(habit.targetUnit.isEmpty ? "total" : habit.targetUnit) this week"
        case .checkIn:
            return "\(activeDaysInWeek) days this week"
        case .abstain:
            return "7 days of freedom"
        }
    }

    func graceMessage(completed: Int, total: Int) -> String {
        if total == 0 { return "A new week begins. God is with you." }
        let ratio = Double(completed) / Double(total)
        if ratio >= 1.0 {
            return "Every single one. What a week of giving."
        } else if ratio >= 0.85 {
            return "Almost perfect — and God sees every one."
        } else if ratio >= 0.7 {
            return "A beautiful week. God was with you every single day — including the ones you rested."
        } else if ratio >= 0.5 {
            return "You showed up more than half the time. That's not small — that's faithfulness."
        } else if ratio >= 0.3 {
            return "Some weeks are harder than others. God sees your heart, not your score."
        } else {
            return "Even one day of showing up matters. His mercies are new every morning."
        }
    }

    func proximityMessage(for habit: Habit) -> String? {
        let type = habit.habitTrackingType

        switch type {
        case .timed:
            let totalMinutes = habit.totalValue()
            let currentHours = totalMinutes / 60.0
            let milestones: [Double] = [1, 5, 10, 25, 50, 100, 250, 500, 1000]
            for milestone in milestones {
                if currentHours < milestone {
                    let minutesLeft = (milestone * 60) - totalMinutes
                    if minutesLeft <= habit.dailyTarget * 2 {
                        return "Just \(Int(minutesLeft)) more minutes to hit \(Int(milestone)) total hours of \(habit.name.lowercased())."
                    }
                    return nil
                }
            }
            return nil

        case .count:
            let totalCount = habit.totalValue()
            let milestones: [Double] = [50, 100, 250, 500, 1000, 2500, 5000]
            for milestone in milestones {
                if totalCount < milestone {
                    let left = milestone - totalCount
                    if left <= habit.dailyTarget * 2 {
                        let unit = habit.targetUnit.isEmpty ? "completed" : habit.targetUnit
                        return "Just \(Int(left)) more \(unit) to reach \(Int(milestone)) total."
                    }
                    return nil
                }
            }
            return nil

        case .checkIn:
            let totalDays = Double(habit.totalCompletedDays())
            let milestones: [Double] = [7, 14, 21, 30, 50, 100, 200, 365]
            for milestone in milestones {
                if totalDays < milestone {
                    let left = Int(milestone - totalDays)
                    if left <= 3 {
                        return left == 1 ? "One more day to hit \(Int(milestone)) days of \(habit.name.lowercased())." : "\(left) more days to hit \(Int(milestone)) days of \(habit.name.lowercased())."
                    }
                    return nil
                }
            }
            return nil

        case .abstain:
            let consecutive = consecutiveCleanDays(for: habit)
            let milestones = [7, 14, 21, 30, 60, 90, 180, 365]
            for milestone in milestones {
                if consecutive < milestone {
                    let left = milestone - consecutive
                    if left <= 3 {
                        return left == 1 ? "One more day to \(milestone) consecutive clean days." : "\(left) more days to \(milestone) consecutive clean days."
                    }
                    return nil
                }
            }
            return nil
        }
    }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }
}
