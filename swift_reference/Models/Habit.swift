import Foundation
import SwiftData

nonisolated enum HabitTrackingType: String, Codable, CaseIterable, Sendable {
    case timed
    case count
    case checkIn
    case abstain
}

nonisolated enum HabitCategory: String, Codable, CaseIterable, Sendable {
    case exercise = "Exercise & Movement"
    case scripture = "Scripture & Prayer"
    case rest = "Rest & Sleep"
    case fasting = "Fasting"
    case study = "Study & Learning"
    case service = "Service & Generosity"
    case connection = "Connection"
    case health = "Health & Nourishment"
    case abstain = "Breaking a Bad Habit"
    case custom = "Custom"
    case gratitude = "Gratitude"

    var iconName: String {
        switch self {
        case .exercise: return "figure.run"
        case .scripture: return "book.fill"
        case .rest: return "moon.fill"
        case .fasting: return "leaf.fill"
        case .study: return "graduationcap.fill"
        case .service: return "heart.fill"
        case .connection: return "person.2.fill"
        case .health: return "drop.fill"
        case .abstain: return "shield.fill"
        case .custom: return "sparkles"
        case .gratitude: return "hands.sparkles.fill"
        }
    }

    var defaultPurpose: String {
        switch self {
        case .exercise: return "My body is a gift. Moving it honours the One who made it."
        case .scripture: return "I'm someone who puts God's Word first."
        case .rest: return "Rest isn't laziness. God commands it because He designed me to need it."
        case .fasting: return "Fasting draws me closer to God and teaches me discipline."
        case .study: return "Growing my mind is an act of stewardship."
        case .service: return "Serving others is serving God."
        case .connection: return "I was made for community."
        case .health: return "My body is God's temple. Nourishing it is an act of worship."
        case .abstain: return "God made me for freedom."
        case .custom: return "Whatever you do, do it all for the glory of God."
        case .gratitude: return "Every good gift comes from above."
        }
    }

    var suggestedTrackingType: HabitTrackingType {
        switch self {
        case .exercise, .scripture, .rest, .study: return .timed
        case .fasting, .connection, .gratitude, .custom: return .checkIn
        case .service: return .count
        case .health: return .count
        case .abstain: return .abstain
        }
    }
}

@Model
class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var category: String = "Gratitude"
    var trackingType: String = "checkIn"
    var purposeStatement: String = ""
    var dailyTarget: Double = 1
    var targetUnit: String = ""
    var isBuiltIn: Bool = false
    var createdAt: Date = Date()
    var sortOrder: Int = 0
    var activeDays: String = "1,2,3,4,5,6,7"
    var trigger: String = ""
    var copingPlan: String = ""

    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit) var entries: [HabitEntry] = []

    init(
        name: String,
        category: HabitCategory,
        trackingType: HabitTrackingType,
        purposeStatement: String = "",
        dailyTarget: Double = 1,
        targetUnit: String = "",
        isBuiltIn: Bool = false,
        sortOrder: Int = 0,
        activeDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7],
        trigger: String = "",
        copingPlan: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.category = category.rawValue
        self.trackingType = trackingType.rawValue
        self.purposeStatement = purposeStatement.isEmpty ? category.defaultPurpose : purposeStatement
        self.dailyTarget = dailyTarget
        self.targetUnit = targetUnit
        self.isBuiltIn = isBuiltIn
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.activeDays = activeDays.sorted().map(String.init).joined(separator: ",")
        self.trigger = trigger
        self.copingPlan = copingPlan
    }

    var habitCategory: HabitCategory {
        HabitCategory(rawValue: category) ?? .gratitude
    }

    var habitTrackingType: HabitTrackingType {
        HabitTrackingType(rawValue: trackingType) ?? .checkIn
    }

    var activeDaySet: Set<Int> {
        get {
            Set(activeDays.split(separator: ",").compactMap { Int($0) })
        }
        set {
            activeDays = newValue.sorted().map(String.init).joined(separator: ",")
        }
    }

    var isActiveToday: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return activeDaySet.contains(weekday)
    }

    func entry(for date: Date) -> HabitEntry? {
        let calendar = Calendar.current
        return entries.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func todayEntry() -> HabitEntry? {
        entry(for: Date())
    }

    func isCompleted(on date: Date) -> Bool {
        guard let entry = entry(for: date) else { return false }
        return entry.isCompleted
    }

    func isCompletedToday() -> Bool {
        isCompleted(on: Date())
    }

    func isActive(on date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return activeDaySet.contains(weekday)
    }

    func entriesForCurrentWeek() -> [HabitEntry] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else { return [] }
        return entries.filter { $0.date >= weekStart }
    }

    func completedDaysThisWeek() -> Int {
        entriesForCurrentWeek().filter(\.isCompleted).count
    }

    func totalCompletedDays() -> Int {
        entries.filter(\.isCompleted).count
    }

    func totalValue() -> Double {
        entries.reduce(0) { $0 + $1.value }
    }
}
