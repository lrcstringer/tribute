import SwiftUI
import SwiftData

struct TodayView: View {
    let weekCycleManager: WeekCycleManager
    @Binding var showAutoCarryBanner: Bool
    let store: StoreViewModel

    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HabitViewModel?
    @State private var engagementService = EngagementService()
    @State private var scoreService = DailyScoreService()
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showSOSPicker: Bool = false
    @State private var showSOS: Bool = false
    @State private var showSOSPaywall: Bool = false
    @State private var sosHabit: Habit?
    @State private var showHabitLimitPaywall: Bool = false
    @State private var showEngagementPaywall: Bool = false

    private let freeHabitLimit = 2
    private let calendar = Calendar.current

    private var isViewingToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    private var isRetroactive: Bool {
        !isViewingToday
    }

    private var selectedDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }

    private var gratitudeHabit: Habit? {
        habits.first { $0.isBuiltIn && $0.habitCategory == .gratitude }
    }

    private var customHabits: [Habit] {
        habits.filter { !$0.isBuiltIn }
    }

    private var activeHabitsForSelectedDate: [Habit] {
        customHabits.filter { $0.isActive(on: selectedDate) }
    }

    private var completedOnSelectedDate: Int {
        habits.filter { $0.isCompleted(on: selectedDate) }.count
    }

    private var activeCountOnSelectedDate: Int {
        habits.filter { $0.isActive(on: selectedDate) }.count
    }

    private var proximityMilestones: [(Habit, String)] {
        habits.compactMap { habit -> (Habit, String)? in
            guard let preview = weekCycleManager.proximityMessage(for: habit) else { return nil }
            return (habit, preview)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let message = engagementService.currentMessage, isViewingToday {
                        EngagementBannerView(message: message) {
                            engagementService.dismissCurrentMessage()
                        } onPaywallTap: {
                            showEngagementPaywall = true
                        }
                    }

                    if showAutoCarryBanner && isViewingToday {
                        autoCarryBanner
                    }

                    headerSection

                    WeekStripView(
                        weekDates: weekCycleManager.currentWeekDates,
                        habits: habits,
                        scoreService: scoreService,
                        selectedDate: $selectedDate
                    )

                    if isRetroactive {
                        retroactiveBanner
                    }

                    if isViewingToday && !proximityMilestones.isEmpty {
                        proximityMilestoneSection
                    }

                    if let vm = viewModel {
                        if let gratitude = gratitudeHabit, gratitude.isActive(on: selectedDate) {
                            GratitudeCheckInView(
                                habit: gratitude,
                                viewModel: vm,
                                targetDate: selectedDate,
                                isRetroactive: isRetroactive
                            )
                        }

                        ForEach(activeHabitsForSelectedDate) { habit in
                            HabitCheckInCardView(
                                habit: habit,
                                viewModel: vm,
                                targetDate: selectedDate,
                                isRetroactive: isRetroactive
                            )
                        }

                        if customHabits.isEmpty && isViewingToday {
                            addHabitPrompt
                        }

                        if activeHabitsForSelectedDate.isEmpty && !customHabits.isEmpty && isRetroactive {
                            noHabitsScheduled
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationTitle(isViewingToday ? "Give" : "Logging for \(selectedDayName)")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Habit", systemImage: "plus") {
                        if !store.isPremium && customHabits.count >= freeHabitLimit {
                            showHabitLimitPaywall = true
                        } else {
                            viewModel?.showingAddHabit = true
                        }
                    }
                    .foregroundStyle(TributeColor.golden)
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showingAddHabit ?? false },
                set: { viewModel?.showingAddHabit = $0 }
            )) {
                if let vm = viewModel {
                    AddHabitView(viewModel: vm, existingCount: habits.count)
                }
            }
            .sheet(isPresented: $showHabitLimitPaywall) {
                TributePaywallView(
                    store: store,
                    contextTitle: "You\u{2019}ve reached 2 free habits",
                    contextMessage: "Unlock Tribute Pro for unlimited habits and deeper tracking."
                )
                .preferredColorScheme(.dark)
            }
            .overlay(alignment: .bottomTrailing) {
                if !habits.isEmpty {
                    sosFloatingButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 12)
                }
            }
            .sheet(isPresented: $showSOS) {
                if let habit = sosHabit {
                    SOSView(habit: habit)
                        .preferredColorScheme(.dark)
                }
            }
            .sheet(isPresented: $showSOSPaywall) {
                TributePaywallView(
                    store: store,
                    contextTitle: "Tough moment?",
                    contextMessage: "The SOS feature helps you stay strong with your purpose statement, micro-actions, and prayer support."
                )
                .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showEngagementPaywall) {
                if let context = engagementService.currentMessage?.paywallContext {
                    TributePaywallView(
                        store: store,
                        contextTitle: context.title,
                        contextMessage: context.message
                    )
                    .preferredColorScheme(.dark)
                } else {
                    TributePaywallView(store: store)
                        .preferredColorScheme(.dark)
                }
            }
            .confirmationDialog("Which habit do you need support with?", isPresented: $showSOSPicker, titleVisibility: .visible) {
                ForEach(customHabits) { habit in
                    Button(habit.name) {
                        sosHabit = habit
                        showSOS = true
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HabitViewModel(modelContext: modelContext)
            }
            viewModel?.ensureGratitudeHabit(existingHabits: habits)
            engagementService.isPremium = store.isPremium
            engagementService.evaluateMessage(habits: habits)
        }
        .onChange(of: habits.map(\.entries.count)) { _, _ in
            engagementService.isPremium = store.isPremium
            engagementService.evaluateMessage(habits: habits)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dayGreeting)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(TributeColor.softGold)

            if isViewingToday {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(completedOnSelectedDate)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(TributeColor.golden)
                    Text("of \(activeCountOnSelectedDate) given today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if completedOnSelectedDate == activeCountOnSelectedDate && activeCountOnSelectedDate > 0 {
                    Text("Everything given. God sees every one.")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(TributeColor.sage)
                        .padding(.top, 2)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(completedOnSelectedDate)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(TributeColor.golden)
                    Text("of \(activeCountOnSelectedDate) given on \(selectedDayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var retroactiveBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.subheadline)
                .foregroundStyle(TributeColor.golden)

            Text("Logging for \(selectedDayName)")
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDate = calendar.startOfDay(for: Date())
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(TributeColor.golden.opacity(0.06))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(TributeColor.golden.opacity(0.15), lineWidth: 0.5)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var autoCarryBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.forward.circle.fill")
                .font(.title3)
                .foregroundStyle(TributeColor.golden)

            VStack(alignment: .leading, spacing: 2) {
                Text("New week, same habits.")
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("You\u{2019}re already on Day \(weekCycleManager.dayOfWeekIndex + 1). Let\u{2019}s keep going.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.3)) {
                    showAutoCarryBanner = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(TributeColor.golden.opacity(0.06))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(TributeColor.golden.opacity(0.15), lineWidth: 0.5)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var addHabitPrompt: some View {
        Button {
            viewModel?.showingAddHabit = true
        } label: {
            VStack(spacing: 14) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(TributeColor.golden.opacity(0.5))

                Text("Add your first habit")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(.primary)

                Text("What do you want to give to God this season?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(TributeColor.cardBackground)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(TributeColor.golden.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [8, 6]))
            )
        }
        .buttonStyle(.plain)
    }

    private var noHabitsScheduled: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 28))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No habits scheduled for \(selectedDayName)")
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var sosFloatingButton: some View {
        Button {
            if !store.isPremium {
                showSOSPaywall = true
                return
            }
            let nonGratitude = customHabits
            if nonGratitude.count == 1, let habit = nonGratitude.first {
                sosHabit = habit
                showSOS = true
            } else if nonGratitude.isEmpty, let gratitude = gratitudeHabit {
                sosHabit = gratitude
                showSOS = true
            } else {
                showSOSPicker = true
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                TributeColor.sage.opacity(0.25),
                                TributeColor.sage.opacity(0.08)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 28
                        )
                    )
                    .frame(width: 56, height: 56)

                Circle()
                    .fill(TributeColor.sage.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .strokeBorder(TributeColor.sage.opacity(0.3), lineWidth: 0.5)
                    )

                Text("SOS")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(TributeColor.sage)
            }
        }
        .shadow(color: TributeColor.sage.opacity(0.2), radius: 8, y: 2)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: showSOS)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: showSOSPaywall)
    }

    private var proximityMilestoneSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(proximityMilestones, id: \.0.id) { habit, message in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.caption2)
                        .foregroundStyle(TributeColor.golden)
                        .padding(.top, 2)

                    Text(message)
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(TributeColor.softGold.opacity(0.7))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TributeColor.golden.opacity(0.04))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(TributeColor.golden.opacity(0.1), lineWidth: 0.5)
        )
    }

    private var dayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning"
        } else if hour < 17 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }
}
