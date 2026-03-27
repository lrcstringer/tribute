import Foundation
import SwiftData

@Model
class HabitEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var value: Double = 0
    var isCompleted: Bool = false
    var gratitudeNote: String?
    var habit: Habit?

    init(date: Date = Date(), value: Double = 0, isCompleted: Bool = false, gratitudeNote: String? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.value = value
        self.isCompleted = isCompleted
        self.gratitudeNote = gratitudeNote
    }
}
