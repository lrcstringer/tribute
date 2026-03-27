import SwiftUI
import SwiftData

@Observable
@MainActor
class HabitViewModel {
    private let modelContext: ModelContext

    var showingAddHabit: Bool = false
    var checkInPulseHabitId: UUID?
    var isRetroactive: Bool = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func ensureGratitudeHabit(existingHabits: [Habit]) {
        let hasGratitude = existingHabits.contains { $0.isBuiltIn && $0.habitCategory == .gratitude }
        if !hasGratitude {
            let gratitude = Habit(
                name: "Daily Gratitude",
                category: .gratitude,
                trackingType: .checkIn,
                purposeStatement: "Give thanks in all circumstances; for this is God\u{2019}s will for you in Christ Jesus.",
                isBuiltIn: true,
                sortOrder: 0
            )
            modelContext.insert(gratitude)
        }
    }

    func checkInHabit(_ habit: Habit, on date: Date, retroactive: Bool = false) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        isRetroactive = retroactive

        if let existing = habit.entries.first(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
            existing.isCompleted = true
            existing.value = habit.dailyTarget
        } else {
            let entry = HabitEntry(date: targetDate, value: habit.dailyTarget, isCompleted: true)
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }

        checkInPulseHabitId = habit.id
    }

    func checkInGratitude(_ habit: Habit, note: String?, on date: Date, retroactive: Bool = false) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        isRetroactive = retroactive

        if let existing = habit.entries.first(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
            existing.isCompleted = true
            existing.value = 1
            existing.gratitudeNote = note
        } else {
            let entry = HabitEntry(date: targetDate, value: 1, isCompleted: true, gratitudeNote: note)
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }

        checkInPulseHabitId = habit.id
    }

    func updateTimedEntry(_ habit: Habit, minutes: Double, on date: Date, retroactive: Bool = false) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        isRetroactive = retroactive

        if let existing = habit.entries.first(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
            existing.value = minutes
            existing.isCompleted = minutes >= habit.dailyTarget
        } else {
            let entry = HabitEntry(date: targetDate, value: minutes, isCompleted: minutes >= habit.dailyTarget)
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }

        if minutes >= habit.dailyTarget {
            checkInPulseHabitId = habit.id
        }
    }

    func updateCountEntry(_ habit: Habit, count: Double, on date: Date, retroactive: Bool = false) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        isRetroactive = retroactive

        if let existing = habit.entries.first(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
            existing.value = count
            existing.isCompleted = count >= habit.dailyTarget
        } else {
            let entry = HabitEntry(date: targetDate, value: count, isCompleted: count >= habit.dailyTarget)
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }

        if count >= habit.dailyTarget {
            checkInPulseHabitId = habit.id
        }
    }

    func addHabit(name: String, category: HabitCategory, trackingType: HabitTrackingType, purpose: String, dailyTarget: Double, targetUnit: String, existingCount: Int, activeDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7], trigger: String = "", copingPlan: String = "") {
        let habit = Habit(
            name: name,
            category: category,
            trackingType: trackingType,
            purposeStatement: purpose,
            dailyTarget: dailyTarget,
            targetUnit: targetUnit,
            sortOrder: existingCount,
            activeDays: activeDays,
            trigger: trigger,
            copingPlan: copingPlan
        )
        modelContext.insert(habit)
    }

    func deleteHabit(_ habit: Habit) {
        guard !habit.isBuiltIn else { return }
        modelContext.delete(habit)
    }
}
