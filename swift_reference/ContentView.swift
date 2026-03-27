import SwiftUI
import SwiftData

struct ContentView: View {
    let store: StoreViewModel

    @State private var selectedTab: Int = 0
    @State private var weekCycleManager = WeekCycleManager()
    @State private var showingDedication: Bool = false
    @State private var showingLookBack: Bool = false
    @State private var showAutoCarryBanner: Bool = false
    @State private var pendingInviteCode: String?
    @State private var hasNewGratitudes: Bool = false

    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Give", systemImage: "gift.fill", value: 0) {
                    TodayView(weekCycleManager: weekCycleManager, showAutoCarryBanner: $showAutoCarryBanner, store: store)
                }
                Tab("Week", systemImage: "calendar", value: 1) {
                    WeekView(weekCycleManager: weekCycleManager)
                }
                Tab("Journey", systemImage: "chart.bar.fill", value: 2) {
                    JourneyView()
                }
                Tab("Circles", systemImage: "person.3.fill", value: 3) {
                    CirclesTab(pendingInviteCode: $pendingInviteCode)
                }
                .badge(hasNewGratitudes ? Text("\u{200B}") : nil)
                Tab("Settings", systemImage: "gearshape.fill", value: 4) {
                    SettingsView(store: store)
                }
            }
            .tint(TributeColor.golden)
            .preferredColorScheme(.dark)
            .environment(\.storeViewModel, store)

            if showingLookBack {
                WeekLookBackView(weekCycleManager: weekCycleManager) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingLookBack = false
                        showingDedication = weekCycleManager.needsDedication
                    }
                }
                .transition(.opacity)
                .zIndex(2)
            }

            if showingDedication {
                SundayDedicationView(weekCycleManager: weekCycleManager) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingDedication = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .onAppear {
            checkWeekCycleState()
            WidgetDataService.shared.updateWidgetData(habits: habits)
            checkNewGratitudes()
        }
        .onChange(of: habits.map(\.entries.count)) { _, _ in
            WidgetDataService.shared.updateWidgetData(habits: habits)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                WidgetDataService.shared.updateWidgetData(habits: habits)
                checkNewGratitudes()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 3 {
                hasNewGratitudes = false
            }
        }
        .onOpenURL { url in
            if let code = extractInviteCode(from: url) {
                pendingInviteCode = code
                selectedTab = 3
            } else if url.scheme == "tribute" && url.host == "today" {
                selectedTab = 0
            }
        }
    }

    private func extractInviteCode(from url: URL) -> String? {
        if url.scheme == "tribute" && url.host == "join" {
            let code = url.pathComponents.last
            if let code, !code.isEmpty, code != "/" { return code }
        }

        if url.host == "tribute.app" || url.host == "www.tribute.app" {
            let components = url.pathComponents
            if components.count >= 3, components[1] == "join" {
                return components[2]
            }
        }

        return nil
    }

    private func checkNewGratitudes() {
        guard AuthenticationService.shared.isAuthenticated else { return }
        Task {
            do {
                let circles = try await APIService.shared.listCircles()
                for circle in circles {
                    let count = try await APIService.shared.getGratitudeNewCount(circleId: circle.id)
                    if count.newCount > 0 {
                        hasNewGratitudes = true
                        return
                    }
                }
                hasNewGratitudes = false
            } catch {}
        }
    }

    private func checkWeekCycleState() {
        if weekCycleManager.needsLookBack && !habits.isEmpty {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingLookBack = true
            }
        } else if weekCycleManager.needsDedication {
            if habits.isEmpty {
                showAutoCarryBanner = false
            } else {
                let hasBeenDedicatedBefore = weekCycleManager.weekDedicatedDate != nil
                if hasBeenDedicatedBefore {
                    showAutoCarryBanner = true
                }
                withAnimation(.easeInOut(duration: 0.3).delay(0.5)) {
                    showingDedication = true
                }
            }
        }
    }
}
