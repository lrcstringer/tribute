import Foundation
import SwiftData

@Observable
@MainActor
class DailyScoreService {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        return cal
    }()

    func habitScore(for habit: Habit, on date: Date) -> Double {
        let dayStart = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: date)
        guard habit.activeDaySet.contains(weekday) else { return -1 }

        guard let entry = habit.entries.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) else {
            return 0
        }

        switch habit.habitTrackingType {
        case .timed:
            guard habit.dailyTarget > 0 else { return entry.isCompleted ? 1.0 : 0.0 }
            return min(entry.value / habit.dailyTarget, 1.0)
        case .count:
            guard habit.dailyTarget > 0 else { return entry.isCompleted ? 1.0 : 0.0 }
            return min(entry.value / habit.dailyTarget, 1.0)
        case .checkIn:
            return entry.isCompleted ? 1.0 : 0.0
        case .abstain:
            return entry.isCompleted ? 1.0 : 0.0
        }
    }

    func dailyScore(for habits: [Habit], on date: Date) -> Double {
        let scores = habits.compactMap { habit -> Double? in
            let score = habitScore(for: habit, on: date)
            return score >= 0 ? score : nil
        }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    func tier(for score: Double) -> DayTier {
        if score <= 0 { return .nothing }
        if score < 0.5 { return .partial }
        if score < 0.95 { return .substantial }
        return .full
    }

    func tier(for habits: [Habit], on date: Date) -> DayTier {
        let score = dailyScore(for: habits, on: date)
        return tier(for: score)
    }
}

enum DayTier: Int, Sendable {
    case nothing = 0
    case partial = 1
    case substantial = 2
    case full = 3
}
