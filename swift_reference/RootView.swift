import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("tribute_onboarding_complete") private var onboardingComplete: Bool = false
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var store = StoreViewModel()

    var body: some View {
        if onboardingComplete {
            ContentView(store: store)
                .task {
                    await NotificationService.shared.refreshAllNotifications(habits: habits)
                }
        } else {
            OnboardingContainerView(store: store) {
                UserDefaults.standard.set(Date(), forKey: "tribute_onboarding_date")
                let manager = WeekCycleManager()
                manager.dedicateCurrentWeek()
                Task {
                    await NotificationService.shared.checkAuthorization()
                    if NotificationService.shared.isAuthorized {
                        NotificationService.shared.scheduleDailyReminders()
                    }
                }
                withAnimation(.easeInOut(duration: 0.5)) {
                    onboardingComplete = true
                }
            }
        }
    }
}
