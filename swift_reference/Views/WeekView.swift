import SwiftUI
import SwiftData

struct WeekView: View {
    let weekCycleManager: WeekCycleManager

    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var scoreService = DailyScoreService()

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let calendar = Calendar.current

    private var weekDates: [Date] {
        weekCycleManager.currentWeekDates
    }

    private var todayStart: Date {
        calendar.startOfDay(for: Date())
    }

    private var daysElapsed: [Date] {
        weekDates.filter { calendar.startOfDay(for: $0) <= todayStart }
    }

    private var overallWeekScore: Double {
        guard !daysElapsed.isEmpty else { return 0 }
        let dayScores = daysElapsed.map { scoreService.dailyScore(for: habits, on: $0) }
        return dayScores.reduce(0, +) / Double(dayScores.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    weekSummaryHeader
                    milestoneCallouts

                    ForEach(habits) { habit in
                        habitWeekCard(habit)
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
            .navigationTitle("This Week")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var weekSummaryHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Week So Far")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(TributeColor.softGold)

                Spacer()

                if weekCycleManager.isCurrentWeekDedicated {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                        Text("Dedicated")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(TributeColor.golden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(TributeColor.golden.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            HStack(spacing: 12) {
                weekTierIndicator
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(weekTierLabel)
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(weekCycleManager.graceMessage(
                        completed: totalCompletedCheckIns,
                        total: totalPossibleCheckIns
                    ))
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(TributeColor.sage)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var weekTierIndicator: some View {
        let tier = scoreService.tier(for: overallWeekScore)
        switch tier {
        case .nothing:
            Circle()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1.5)
        case .partial:
            Circle()
                .strokeBorder(TributeColor.golden.opacity(0.6), lineWidth: 2)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(TributeColor.golden.opacity(0.7))
                }
        case .substantial:
            Circle()
                .fill(TributeColor.golden)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(TributeColor.charcoal)
                }
        case .full:
            Circle()
                .fill(TributeColor.golden)
                .overlay {
                    Circle()
                        .strokeBorder(TributeColor.golden.opacity(0.45), lineWidth: 2)
                        .scaleEffect(1.3)
                }
                .shadow(color: TributeColor.golden.opacity(0.7), radius: 14, y: 0)
                .shadow(color: TributeColor.golden.opacity(0.35), radius: 5, y: 0)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(TributeColor.charcoal)
                }
        }
    }

    private var weekTierLabel: String {
        let tier = scoreService.tier(for: overallWeekScore)
        switch tier {
        case .nothing: return "Just getting started"
        case .partial: return "Something given"
        case .substantial: return "Strong week"
        case .full: return "Beautiful week"
        }
    }

    private var totalCompletedCheckIns: Int {
        habits.reduce(0) { $0 + weekCycleManager.completedDaysThisWeek(for: $1) }
    }

    private var totalPossibleCheckIns: Int {
        daysElapsed.reduce(0) { total, date in
            total + habits.filter { $0.isActive(on: date) }.count
        }
    }

    @ViewBuilder
    private var milestoneCallouts: some View {
        let previews = habits.compactMap { habit -> (Habit, String)? in
            guard let preview = weekCycleManager.microMilestonePreview(for: habit) else { return nil }
            return (habit, preview)
        }

        if !previews.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(previews, id: \.0.id) { habit, preview in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkle")
                            .font(.caption2)
                            .foregroundStyle(TributeColor.golden)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(preview)
                                .font(.caption)
                                .foregroundStyle(TributeColor.softGold.opacity(0.7))
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TributeColor.golden.opacity(0.04))
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(TributeColor.golden.opacity(0.12), lineWidth: 0.5)
            )
        }
    }

    private func habitWeekCard(_ habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: habit.habitCategory.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(habit.habitTrackingType == .abstain ? TributeColor.sage : TributeColor.golden)

                Text(habit.name)
                    .font(.system(.headline, design: .serif))

                Spacer()

                Text(weekSummaryText(for: habit))
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(TributeColor.softGold.opacity(0.7))
            }

            HStack(spacing: 6) {
                ForEach(Array(weekDates.enumerated()), id: \.offset) { index, date in
                    let dateStart = calendar.startOfDay(for: date)
                    let isFuture = dateStart > todayStart
                    let isToday = calendar.isDateInToday(date)
                    let isActive = habit.isActive(on: date)
                    let entry = habit.entry(for: date)
                    let isCompleted = entry?.isCompleted ?? false
                    let score = isActive ? scoreService.habitScore(for: habit, on: date) : -1

                    VStack(spacing: 6) {
                        Text(dayLabels[index])
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(isToday ? TributeColor.softGold : .secondary)

                        ZStack {
                            if !isActive {
                                Circle()
                                    .fill(Color.white.opacity(0.02))
                                    .frame(width: 36, height: 36)
                                Text("\u{2013}")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary.opacity(0.3))
                            } else if isFuture {
                                Circle()
                                    .fill(Color.white.opacity(0.03))
                                    .frame(width: 36, height: 36)
                            } else {
                                habitDayTile(
                                    habit: habit,
                                    isCompleted: isCompleted,
                                    score: max(score, 0),
                                    isToday: isToday,
                                    entry: entry
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if let milestone = weekCycleManager.microMilestonePreview(for: habit) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.caption2)
                        .foregroundStyle(TributeColor.golden)
                    Text(milestone)
                        .font(.caption)
                        .foregroundStyle(TributeColor.softGold.opacity(0.6))
                }
                .padding(.top, 2)
            }
        }
        .tributeCard()
    }

    @ViewBuilder
    private func habitDayTile(habit: Habit, isCompleted: Bool, score: Double, isToday: Bool, entry: HabitEntry?) -> some View {
        let tier = scoreService.tier(for: score)

        switch tier {
        case .nothing:
            Circle()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 36, height: 36)
                .overlay {
                    if isToday {
                        Circle()
                            .strokeBorder(TributeColor.golden.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                    }
                }

        case .partial:
            Circle()
                .strokeBorder(TributeColor.golden.opacity(0.6), lineWidth: 1.5)
                .frame(width: 36, height: 36)
                .overlay {
                    habitDayIcon(habit: habit, tier: .partial)
                }

        case .substantial:
            Circle()
                .fill(habit.habitTrackingType == .abstain ? TributeColor.sage : TributeColor.golden)
                .frame(width: 36, height: 36)
                .overlay {
                    habitDayIcon(habit: habit, tier: .substantial)
                }

        case .full:
            let accentColor = habit.habitTrackingType == .abstain ? TributeColor.sage : TributeColor.golden
            Circle()
                .fill(accentColor)
                .frame(width: 36, height: 36)
                .overlay {
                    Circle()
                        .strokeBorder(accentColor.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 44, height: 44)
                }
                .shadow(color: accentColor.opacity(0.7), radius: 10, y: 0)
                .shadow(color: accentColor.opacity(0.3), radius: 4, y: 0)
                .overlay {
                    habitDayIcon(habit: habit, tier: .full)
                }
        }
    }

    @ViewBuilder
    private func habitDayIcon(habit: Habit, tier: DayTier) -> some View {
        if habit.habitTrackingType == .abstain {
            Image(systemName: "shield.fill")
                .font(.system(size: 12))
                .foregroundStyle(tier == .partial ? TributeColor.sage.opacity(0.7) : TributeColor.charcoal)
        } else {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tier == .partial ? TributeColor.golden.opacity(0.7) : TributeColor.charcoal)
        }
    }

    private func weekSummaryText(for habit: Habit) -> String {
        let activeDays = daysElapsed.filter { habit.isActive(on: $0) }
        let activeDayCount = activeDays.count

        switch habit.habitTrackingType {
        case .timed:
            let totalMinutes = activeDays.reduce(0.0) { $0 + (habit.entry(for: $1)?.value ?? 0) }
            let targetMinutes = habit.dailyTarget * Double(activeDayCount)
            if targetMinutes >= 60 {
                return String(format: "%.0f / %.0f min", totalMinutes, targetMinutes)
            }
            return "\(Int(totalMinutes)) / \(Int(targetMinutes)) min"

        case .count:
            let totalCount = activeDays.reduce(0.0) { $0 + (habit.entry(for: $1)?.value ?? 0) }
            let targetCount = habit.dailyTarget * Double(activeDayCount)
            let unit = habit.targetUnit.isEmpty ? "" : " \(habit.targetUnit)"
            return "\(Int(totalCount)) / \(Int(targetCount))\(unit)"

        case .checkIn:
            let completed = activeDays.filter { habit.isCompleted(on: $0) }.count
            return "\(completed) / \(activeDayCount) days"

        case .abstain:
            let confirmed = activeDays.filter { habit.isCompleted(on: $0) }.count
            return "\(confirmed) / \(activeDayCount) days clean"
        }
    }
}
