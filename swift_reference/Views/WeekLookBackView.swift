import SwiftUI
import SwiftData

struct WeekLookBackView: View {
    let weekCycleManager: WeekCycleManager
    let onContinue: () -> Void

    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Environment(\.storeViewModel) private var store

    @State private var showHeading: Bool = false
    @State private var showTile: Bool = false
    @State private var showHabits: Bool = false
    @State private var showMilestones: Bool = false
    @State private var showMessage: Bool = false
    @State private var showButton: Bool = false
    @State private var showUpgradePrompt: Bool = false
    @State private var tileGlow: Bool = false
    @State private var milestoneService = MilestoneService()
    @State private var showPaywall: Bool = false
    @State private var circleGratitudeSummary: String?
    @State private var showCircleSummary: Bool = false

    private var isPremium: Bool {
        store?.isPremium ?? false
    }

    private var previousWeekDates: [Date] {
        weekCycleManager.previousWeekDates
    }

    private var totalCompleted: Int {
        habits.reduce(0) { $0 + weekCycleManager.completedDays(for: $1, in: previousWeekDates) }
    }

    private var totalPossible: Int {
        habits.count * 7
    }

    private var completionRatio: Double {
        guard totalPossible > 0 else { return 0 }
        return Double(totalCompleted) / Double(totalPossible)
    }

    private var tileColor: Color {
        if completionRatio >= 1.0 { return TributeColor.golden }
        if completionRatio >= 0.7 { return TributeColor.golden.opacity(0.8) }
        if completionRatio >= 0.4 { return TributeColor.softGold }
        return TributeColor.mutedSage
    }

    private var weekMilestones: [(Habit, Milestone)] {
        habits.flatMap { habit in
            milestoneService.milestonesHitDuringWeek(habit: habit, weekDates: previousWeekDates)
                .map { (habit, $0) }
        }
    }

    var body: some View {
        ZStack {
            TributeColor.charcoal.ignoresSafeArea()
            TributeColor.warmGlow.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        headingSection
                        weekTileSection
                        habitBreakdownSection
                        if !weekMilestones.isEmpty {
                            milestonesSection
                        }
                        if let summary = circleGratitudeSummary {
                            circleGratitudeSection(summary)
                        }
                        graceMessageSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 100)
                }

                if showButton {
                    VStack(spacing: 12) {
                        if showUpgradePrompt && !isPremium {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.caption)
                                        .foregroundStyle(TributeColor.golden)
                                    Text("See your progress over months")
                                        .font(.system(.caption, design: .serif))
                                        .foregroundStyle(TributeColor.softGold)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 9))
                                        Text("PRO")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                    .foregroundStyle(TributeColor.golden)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(TributeColor.golden.opacity(0.15))
                                    .clipShape(Capsule())
                                }
                                .padding(12)
                                .background(TributeColor.golden.opacity(0.04))
                                .clipShape(.rect(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(TributeColor.golden.opacity(0.12), lineWidth: 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Button {
                            weekCycleManager.completeLookBack()
                            onContinue()
                        } label: {
                            HStack(spacing: 8) {
                                Text("Dedicate this week")
                                Image(systemName: "arrow.right")
                                    .font(.subheadline)
                            }
                            .tributeButton()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear {
            startAnimations()
            loadCircleGratitudeCounts()
        }
        .sheet(isPresented: $showPaywall) {
            if let store {
                TributePaywallView(
                    store: store,
                    contextTitle: "Your week was beautiful",
                    contextMessage: "Unlock the full 52-week heatmap, detailed analytics, and see your long-term growth."
                )
                .preferredColorScheme(.dark)
            }
        }
    }

    private var headingSection: some View {
        VStack(spacing: 8) {
            Text("Last Week")
                .font(.system(.caption, design: .serif))
                .foregroundStyle(TributeColor.softGold.opacity(0.6))

            Text("Your Week in Review")
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(.primary)
        }
        .opacity(showHeading ? 1 : 0)
        .offset(y: showHeading ? 0 : 8)
    }

    private var weekTileSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(tileColor.opacity(tileGlow ? 0.2 : 0.08))
                    .frame(height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(tileColor.opacity(tileGlow ? 0.4 : 0.15), lineWidth: 1)
                    )

                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(totalCompleted)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(tileColor)
                        Text("/ \(totalPossible)")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text("check-ins last week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    weekDayDots
                }
            }
            .animation(.easeInOut(duration: 1.0), value: tileGlow)
        }
        .opacity(showTile ? 1 : 0)
        .scaleEffect(showTile ? 1 : 0.95)
    }

    private var weekDayDots: some View {
        HStack(spacing: 6) {
            let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
            ForEach(Array(previousWeekDates.enumerated()), id: \.offset) { index, date in
                let dayCompleted = habits.allSatisfy { habit in
                    habit.entries.contains { entry in
                        Calendar.current.isDate(entry.date, inSameDayAs: date) && entry.isCompleted
                    }
                }

                let partialComplete = habits.contains { habit in
                    habit.entries.contains { entry in
                        Calendar.current.isDate(entry.date, inSameDayAs: date) && entry.isCompleted
                    }
                }

                VStack(spacing: 4) {
                    Text(dayLabels[index])
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    Circle()
                        .fill(dayCompleted ? TributeColor.golden : (partialComplete ? TributeColor.softGold.opacity(0.4) : Color.white.opacity(0.08)))
                        .frame(width: 10, height: 10)
                }
            }
        }
    }

    private var habitBreakdownSection: some View {
        VStack(spacing: 10) {
            ForEach(habits) { habit in
                let completed = weekCycleManager.completedDays(for: habit, in: previousWeekDates)
                HStack(spacing: 12) {
                    Image(systemName: habit.habitCategory.iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(habit.habitTrackingType == .abstain ? TributeColor.sage : TributeColor.golden)
                        .frame(width: 24)

                    Text(habit.name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(completed)/7")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(completed >= 5 ? TributeColor.golden : TributeColor.softGold.opacity(0.5))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(TributeColor.cardBackground)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                )
            }
        }
        .opacity(showHabits ? 1 : 0)
        .offset(y: showHabits ? 0 : 10)
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(TributeColor.golden)
                Text("Milestones This Week")
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(TributeColor.softGold)
            }

            ForEach(Array(weekMilestones.enumerated()), id: \.offset) { _, item in
                let (habit, milestone) = item
                HStack(spacing: 10) {
                    Image(systemName: habit.habitCategory.iconName)
                        .font(.caption)
                        .foregroundStyle(TributeColor.golden)
                        .frame(width: 20)

                    Text(milestone.message)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TributeColor.golden.opacity(0.04))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(TributeColor.golden.opacity(0.12), lineWidth: 0.5)
        )
        .opacity(showMilestones ? 1 : 0)
        .offset(y: showMilestones ? 0 : 8)
    }

    private var graceMessageSection: some View {
        VStack(spacing: 16) {
            Text(weekCycleManager.graceMessage(completed: totalCompleted, total: totalPossible))
                .font(.system(.body, design: .serif))
                .foregroundStyle(TributeColor.softGold)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            VStack(spacing: 6) {
                Text("\u{201C}The steadfast love of the Lord never ceases; his mercies never come to an end; they are new every morning.\u{201D}")
                    .font(.system(.subheadline, design: .serif))
                    .italic()
                    .foregroundStyle(TributeColor.softGold.opacity(0.5))
                    .multilineTextAlignment(.center)
                Text("Lamentations 3:22\u{2013}23")
                    .font(.caption)
                    .foregroundStyle(TributeColor.golden.opacity(0.4))
            }
        }
        .opacity(showMessage ? 1 : 0)
    }

    private func circleGratitudeSection(_ summary: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TributeColor.golden.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "heart.text.clipboard")
                    .font(.system(size: 14))
                    .foregroundStyle(TributeColor.golden)
            }

            Text(summary)
                .font(.system(.caption, design: .serif))
                .foregroundStyle(TributeColor.softGold)
                .lineSpacing(2)

            Spacer()
        }
        .padding(14)
        .background(TributeColor.golden.opacity(0.04))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(TributeColor.golden.opacity(0.1), lineWidth: 0.5)
        )
        .opacity(showCircleSummary ? 1 : 0)
        .offset(y: showCircleSummary ? 0 : 8)
    }

    private func loadCircleGratitudeCounts() {
        guard AuthenticationService.shared.isAuthenticated else { return }
        Task {
            do {
                let circles = try await APIService.shared.listCircles()
                var parts: [String] = []
                for circle in circles {
                    let response = try await APIService.shared.getGratitudeWeekCount(circleId: circle.id)
                    if response.weekCount > 0 {
                        let name = circles.count > 1 ? circle.name : "your circle"
                        parts.append("\(name) shared \(response.weekCount) gratitude\(response.weekCount == 1 ? "" : "s")")
                    }
                }
                if !parts.isEmpty {
                    circleGratitudeSummary = "This week, " + parts.joined(separator: " and ") + "."
                    withAnimation(.easeOut(duration: 0.5).delay(2.0)) {
                        showCircleSummary = true
                    }
                }
            } catch {}
        }
    }

    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            showHeading = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            showTile = true
        }
        withAnimation(.easeInOut(duration: 1.0).delay(1.2)) {
            tileGlow = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
            showHabits = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.8)) {
            showMilestones = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(2.2)) {
            showMessage = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(2.7)) {
            showButton = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(3.2)) {
            showUpgradePrompt = true
        }
    }
}
