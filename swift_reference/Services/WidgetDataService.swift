import Foundation
import WidgetKit

@MainActor
class WidgetDataService {
    static let shared = WidgetDataService()
    
    private let suiteName = "group.app.rork.tribute"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    func updateWidgetData(habits: [Habit]) {
        guard let defaults = sharedDefaults else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let activeToday = habits.filter { $0.isActive(on: today) }
        let completedToday = activeToday.filter { $0.isCompleted(on: today) }.count
        let totalToday = activeToday.count
        
        defaults.set(completedToday, forKey: "widget_completed")
        defaults.set(totalToday, forKey: "widget_total")
        
        var weekScores: [String: Int] = [:]
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else { return }
        
        for dayOffset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            let key = "\(dayOffset)"
            
            let activeOnDay = habits.filter { $0.isActive(on: dayDate) }
            guard !activeOnDay.isEmpty else {
                weekScores[key] = -1
                continue
            }
            
            let completedOnDay = activeOnDay.filter { $0.isCompleted(on: dayDate) }.count
            let ratio = Double(completedOnDay) / Double(activeOnDay.count)
            
            if ratio <= 0 {
                weekScores[key] = 0
            } else if ratio < 0.5 {
                weekScores[key] = 1
            } else if ratio < 0.95 {
                weekScores[key] = 2
            } else {
                weekScores[key] = 3
            }
        }
        
        defaults.set(weekScores, forKey: "widget_week_scores")
        defaults.set(Date().timeIntervalSince1970, forKey: "widget_last_updated")
        
        WidgetCenter.shared.reloadTimelines(ofKind: "TributeWidget")
    }
}
