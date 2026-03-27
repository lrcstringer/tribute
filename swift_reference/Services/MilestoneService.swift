import Foundation

nonisolated struct Milestone: Sendable, Identifiable {
    let id: String
    let threshold: Double
    let message: String
    let verse: Scripture?
    let isReached: Bool
    var progressHint: String?
}

@Observable
@MainActor
class MilestoneService {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        return cal
    }()

    func lifetimeStat(for habit: Habit) -> LifetimeStat {
        switch habit.habitTrackingType {
        case .timed:
            let totalMinutes = habit.totalValue()
            let hours = Int(totalMinutes) / 60
            let minutes = Int(totalMinutes) % 60
            return LifetimeStat(
                primaryValue: hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m",
                description: "given to God through \(habit.name.lowercased())",
                detail: totalMinutes >= 60 ? "\(Int(totalMinutes)) total minutes" : nil
            )
        case .count:
            let total = Int(habit.totalValue())
            return LifetimeStat(
                primaryValue: "\(total)",
                description: "total \(habit.targetUnit.isEmpty ? "completed" : habit.targetUnit)",
                detail: nil
            )
        case .checkIn:
            let days = habit.totalCompletedDays()
            return LifetimeStat(
                primaryValue: "\(days)",
                description: days == 1 ? "day of \(habit.name.lowercased())" : "days of \(habit.name.lowercased())",
                detail: nil
            )
        case .abstain:
            let consecutive = consecutiveCleanDays(for: habit)
            let total = habit.totalCompletedDays()
            return LifetimeStat(
                primaryValue: "\(total)",
                description: "total clean days",
                detail: "\(consecutive) consecutive days strong"
            )
        }
    }

    func milestones(for habit: Habit) -> [Milestone] {
        var result: [Milestone]
        switch habit.habitTrackingType {
        case .timed:
            result = timedMilestones(for: habit)
        case .count:
            result = countMilestones(for: habit)
        case .checkIn:
            result = checkInMilestones(for: habit)
        case .abstain:
            result = abstainMilestones(for: habit)
        }
        if let nextIndex = result.firstIndex(where: { !$0.isReached }) {
            let currentValue = currentMilestoneValue(for: habit)
            let remaining = result[nextIndex].threshold - currentValue
            if remaining > 0 {
                result[nextIndex].progressHint = progressHintText(for: habit, remaining: remaining)
            }
        }
        return result
    }

    func isRecentlyReached(milestone: Milestone, habit: Habit) -> Bool {
        guard milestone.isReached else { return false }
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEntries = habit.entries.filter { $0.date >= sevenDaysAgo && $0.isCompleted }
        guard !recentEntries.isEmpty else { return false }
        let totalBefore = totalValueBefore(date: sevenDaysAgo, for: habit)
        return totalBefore < milestone.threshold
    }

    private func currentMilestoneValue(for habit: Habit) -> Double {
        switch habit.habitTrackingType {
        case .timed: return habit.totalValue()
        case .count: return habit.totalValue()
        case .checkIn: return Double(habit.totalCompletedDays())
        case .abstain: return Double(habit.totalCompletedDays())
        }
    }

    private func totalValueBefore(date: Date, for habit: Habit) -> Double {
        let entriesBefore = habit.entries.filter { $0.date < calendar.startOfDay(for: date) && $0.isCompleted }
        switch habit.habitTrackingType {
        case .timed, .count:
            return entriesBefore.reduce(0.0) { $0 + $1.value }
        case .checkIn, .abstain:
            return Double(entriesBefore.count)
        }
    }

    private func progressHintText(for habit: Habit, remaining: Double) -> String {
        switch habit.habitTrackingType {
        case .timed:
            let hours = Int(remaining) / 60
            let mins = Int(remaining) % 60
            if hours > 0 {
                return "\(hours)h \(mins)m to go"
            }
            return "\(mins) minutes to go"
        case .count:
            return "\(Int(remaining)) more to go"
        case .checkIn:
            return "\(Int(remaining)) more day\(remaining == 1 ? "" : "s") to go"
        case .abstain:
            return "\(Int(remaining)) more day\(remaining == 1 ? "" : "s") to go"
        }
    }

    func checkForNewMilestone(habit: Habit, previousValue: Double, newValue: Double) -> Milestone? {
        let thresholds: [Double]
        switch habit.habitTrackingType {
        case .timed:
            thresholds = [60, 600, 3000, 6000, 30000, 60000]
        case .count:
            thresholds = [100, 500, 1000, 5000]
        case .checkIn:
            thresholds = [7, 30, 100, 365]
        case .abstain:
            thresholds = [7, 14, 30, 60, 90, 180, 365]
        }

        for threshold in thresholds {
            if previousValue < threshold && newValue >= threshold {
                return milestoneFor(habit: habit, threshold: threshold)
            }
        }
        return nil
    }

    func milestonesHitDuringWeek(habit: Habit, weekDates: [Date]) -> [Milestone] {
        var results: [Milestone] = []

        let entriesBefore = habit.entries.filter { entry in
            guard let firstDate = weekDates.first else { return false }
            return entry.date < calendar.startOfDay(for: firstDate) && entry.isCompleted
        }

        let entriesDuring = habit.entries.filter { entry in
            weekDates.contains { calendar.isDate(entry.date, inSameDayAs: $0) } && entry.isCompleted
        }

        switch habit.habitTrackingType {
        case .timed:
            let valueBefore = entriesBefore.reduce(0.0) { $0 + $1.value }
            var runningTotal = valueBefore
            let thresholds: [Double] = [60, 600, 3000, 6000, 30000, 60000]
            for entry in entriesDuring.sorted(by: { $0.date < $1.date }) {
                let prev = runningTotal
                runningTotal += entry.value
                for t in thresholds {
                    if prev < t && runningTotal >= t {
                        if let m = milestoneFor(habit: habit, threshold: t) {
                            results.append(m)
                        }
                    }
                }
            }
        case .count:
            let valueBefore = entriesBefore.reduce(0.0) { $0 + $1.value }
            var runningTotal = valueBefore
            let thresholds: [Double] = [100, 500, 1000, 5000]
            for entry in entriesDuring.sorted(by: { $0.date < $1.date }) {
                let prev = runningTotal
                runningTotal += entry.value
                for t in thresholds {
                    if prev < t && runningTotal >= t {
                        if let m = milestoneFor(habit: habit, threshold: t) {
                            results.append(m)
                        }
                    }
                }
            }
        case .checkIn:
            let daysBefore = Double(entriesBefore.count)
            var runningDays = daysBefore
            let thresholds: [Double] = [7, 30, 100, 365]
            for _ in entriesDuring.sorted(by: { $0.date < $1.date }) {
                let prev = runningDays
                runningDays += 1
                for t in thresholds {
                    if prev < t && runningDays >= t {
                        if let m = milestoneFor(habit: habit, threshold: t) {
                            results.append(m)
                        }
                    }
                }
            }
        case .abstain:
            let daysBefore = Double(entriesBefore.count)
            var runningDays = daysBefore
            let thresholds: [Double] = [7, 14, 30, 60, 90, 180, 365]
            for _ in entriesDuring.sorted(by: { $0.date < $1.date }) {
                let prev = runningDays
                runningDays += 1
                for t in thresholds {
                    if prev < t && runningDays >= t {
                        if let m = milestoneFor(habit: habit, threshold: t) {
                            results.append(m)
                        }
                    }
                }
            }
        }

        return results
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

    func habitAge(for habit: Habit) -> Int {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: habit.createdAt), to: calendar.startOfDay(for: Date())).day ?? 0
        return max(days, 0)
    }

    private func timedMilestones(for habit: Habit) -> [Milestone] {
        let totalMinutes = habit.totalValue()
        let thresholds: [(Double, String)] = [
            (60, "1 hour"),
            (600, "10 hours"),
            (3000, "50 hours"),
            (6000, "100 hours"),
            (30000, "500 hours"),
            (60000, "1,000 hours")
        ]
        return thresholds.map { threshold, label in
            Milestone(
                id: "timed_\(Int(threshold))",
                threshold: threshold,
                message: "\(label) given to God through \(habit.name.lowercased()).",
                verse: ScriptureLibrary.anchorVerse(for: habit.habitCategory),
                isReached: totalMinutes >= threshold
            )
        }
    }

    private func countMilestones(for habit: Habit) -> [Milestone] {
        let total = habit.totalValue()
        let unit = habit.targetUnit.isEmpty ? "completed" : habit.targetUnit
        let thresholds: [(Double, String)] = [
            (100, "100"), (500, "500"), (1000, "1,000"), (5000, "5,000")
        ]
        return thresholds.map { threshold, label in
            Milestone(
                id: "count_\(Int(threshold))",
                threshold: threshold,
                message: "\(label) \(unit). Every one counts.",
                verse: ScriptureLibrary.anchorVerse(for: habit.habitCategory),
                isReached: total >= threshold
            )
        }
    }

    private func checkInMilestones(for habit: Habit) -> [Milestone] {
        let days = Double(habit.totalCompletedDays())
        let thresholds: [(Double, String)] = [
            (7, "7 days"), (30, "30 days"), (100, "100 days"), (365, "365 days")
        ]
        return thresholds.map { threshold, label in
            Milestone(
                id: "checkin_\(Int(threshold))",
                threshold: threshold,
                message: "\(label) of \(habit.name.lowercased()). That's faithfulness.",
                verse: ScriptureLibrary.anchorVerse(for: habit.habitCategory),
                isReached: days >= threshold
            )
        }
    }

    private func abstainMilestones(for habit: Habit) -> [Milestone] {
        let total = Double(habit.totalCompletedDays())
        let thresholds: [(Double, String)] = [
            (7, "7 days"), (14, "14 days"), (30, "30 days"), (60, "60 days"),
            (90, "90 days"), (180, "180 days"), (365, "365 days")
        ]
        return thresholds.map { threshold, label in
            Milestone(
                id: "abstain_\(Int(threshold))",
                threshold: threshold,
                message: "\(label) of freedom. Those days still stand.",
                verse: ScriptureLibrary.anchorVerse(for: habit.habitCategory),
                isReached: total >= threshold
            )
        }
    }

    private func milestoneFor(habit: Habit, threshold: Double) -> Milestone? {
        switch habit.habitTrackingType {
        case .timed:
            let labels: [Double: String] = [60: "1 hour", 600: "10 hours", 3000: "50 hours", 6000: "100 hours", 30000: "500 hours", 60000: "1,000 hours"]
            guard let label = labels[threshold] else { return nil }
            return Milestone(
                id: "timed_\(Int(threshold))",
                threshold: threshold,
                message: "\(label) given to God through \(habit.name.lowercased()). What an offering.",
                verse: ScriptureLibrary.anchorVerse(for: habit.habitCategory),
                isReached: true
            )
        case .count:
            let unit = habit.targetUnit.isEmpty ? "completed" : habit.targetUnit
            let formatted = threshold >= 1000 ? String(format: "%,.0f", threshold) : "\(Int(threshold))"
            return Milestone(
                id: "count_\(Int(threshold))",
                threshold: threshold,
                message: "\(formatted) \(unit). Every single one counted.",
                verse: ScriptureLibrary.anchorVerse(for: habit.habitCategory),
                isReached: true
            )
        case .checkIn:
            return Milestone(
                id: "checkin_\(Int(threshold))",
                threshold: threshold,
                message: "\(Int(threshold)) days of \(habit.name.lowercased()). \(Int(threshold)) times you chose to show up.",
                verse: ScriptureLibrary.anchorVerse(for: habit.habitCategory),
                isReached: true
            )
        case .abstain:
            return Milestone(
                id: "abstain_\(Int(threshold))",
                threshold: threshold,
                message: "\(Int(threshold)) days of freedom. This is who you're becoming.",
                verse: ScriptureLibrary.anchorVerse(for: habit.habitCategory),
                isReached: true
            )
        }
    }
}

nonisolated struct LifetimeStat: Sendable {
    let primaryValue: String
    let description: String
    let detail: String?
}
