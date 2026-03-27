import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit

    @Query private var allEntries: [HabitEntry]
    @Environment(\.storeViewModel) private var store
    @State private var milestoneService = MilestoneService()
    @State private var showContent: Bool = false
    @State private var showPaywall: Bool = false
    @State private var showEditSheet: Bool = false

    private var entryRefreshKey: Int {
        allEntries.count + allEntries.filter(\.isCompleted).count
    }

    private var isPremium: Bool {
        store?.isPremium ?? false
    }

    private var lifetimeStat: LifetimeStat {
        milestoneService.lifetimeStat(for: habit)
    }

    private var milestones: [Milestone] {
        milestoneService.milestones(for: habit)
    }

    private var habitAge: Int {
        milestoneService.habitAge(for: habit)
    }

    private var accentColor: Color {
        habit.habitTrackingType == .abstain ? TributeColor.sage : TributeColor.golden
    }

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        return cal
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                lifetimeStatSection
                weekBreakdownSection
                heatmapSection

                if isPremium {
                    yearHeatmapSection
                }

                milestoneSection

                if !habit.trigger.isEmpty || !habit.copingPlan.isEmpty {
                    anchoringSection
                }

                purposeSection
                verseSection
                habitInfoSection

                if !isPremium {
                    lockedYearHeatmapSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 10)
        }
        .background(TributeColor.charcoal)
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(TributeColor.softGold)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                showContent = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            if let store {
                TributePaywallView(
                    store: store,
                    contextTitle: "Year in Tribute",
                    contextMessage: "See your full 52-week activity heatmap and track your long-term growth."
                )
                .preferredColorScheme(.dark)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditHabitView(habit: habit)
                .preferredColorScheme(.dark)
        }
    }

    private var lifetimeStatSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.25), accentColor.opacity(0.04)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: habit.habitTrackingType == .abstain ? "shield.fill" : habit.habitCategory.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(accentColor)
            }

            Text(lifetimeStat.primaryValue)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)

            Text(lifetimeStat.description)
                .font(.system(.body, design: .serif))
                .foregroundStyle(TributeColor.softGold)
                .multilineTextAlignment(.center)

            if let detail = lifetimeStat.detail {
                HStack(spacing: 6) {
                    if habit.habitTrackingType == .abstain {
                        Image(systemName: "shield.checkered")
                            .font(.caption)
                            .foregroundStyle(TributeColor.sage.opacity(0.6))
                    }
                    Text(detail)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var weekBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(TributeColor.softGold)

            HStack(spacing: 0) {
                ForEach(currentWeekDates, id: \.self) { date in
                    let dayLabel = shortDayName(for: date)
                    let isToday = calendar.isDateInToday(date)

                    VStack(spacing: 6) {
                        Text(dayLabel)
                            .font(.system(size: 10, weight: isToday ? .bold : .regular))
                            .foregroundStyle(isToday ? TributeColor.golden : .secondary)

                        weekDayVisual(for: date)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .tributeCard()
    }

    @ViewBuilder
    private func weekDayVisual(for date: Date) -> some View {
        let entry = habit.entry(for: date)
        let isFuture = date > calendar.startOfDay(for: Date())
        let isActive = habit.isActive(on: date)

        switch habit.habitTrackingType {
        case .timed:
            timedDayBar(entry: entry, isFuture: isFuture, isActive: isActive)
        case .count:
            countDayVisual(entry: entry, isFuture: isFuture, isActive: isActive)
        case .checkIn:
            checkInDayCircle(entry: entry, isFuture: isFuture, isActive: isActive)
        case .abstain:
            abstainDayShield(entry: entry, isFuture: isFuture, isActive: isActive)
        }
    }

    private func timedDayBar(entry: HabitEntry?, isFuture: Bool, isActive: Bool) -> some View {
        let value = entry?.value ?? 0
        let target = habit.dailyTarget
        let ratio = target > 0 ? min(value / target, 1.0) : 0
        let completed = entry?.isCompleted ?? false

        return VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 16, height: 40)

                if !isFuture && isActive {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(completed ? TributeColor.golden : TributeColor.mutedSage)
                        .frame(width: 16, height: max(2, 40 * ratio))
                        .animation(.easeInOut(duration: 0.3), value: value)
                }
            }

            if !isFuture && isActive && value > 0 {
                Text("\(Int(value))")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(completed ? TributeColor.golden : .secondary)
            } else {
                Text(" ")
                    .font(.system(size: 9))
            }
        }
    }

    private func countDayVisual(entry: HabitEntry?, isFuture: Bool, isActive: Bool) -> some View {
        let value = entry?.value ?? 0
        let completed = entry?.isCompleted ?? false

        return VStack(spacing: 4) {
            if !isFuture && isActive && value > 0 {
                Text("\(Int(value))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(completed ? TributeColor.golden : TributeColor.softGold.opacity(0.6))
                    .frame(width: 28, height: 28)
                    .background(completed ? TributeColor.golden.opacity(0.15) : Color.white.opacity(0.04))
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.white.opacity(isFuture || !isActive ? 0.02 : 0.04))
                    .frame(width: 28, height: 28)
            }

            Text(" ")
                .font(.system(size: 9))
        }
    }

    private func checkInDayCircle(entry: HabitEntry?, isFuture: Bool, isActive: Bool) -> some View {
        let completed = entry?.isCompleted ?? false

        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(completed ? TributeColor.golden : Color.white.opacity(isFuture || !isActive ? 0.02 : 0.04))
                    .frame(width: 28, height: 28)

                if completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(TributeColor.charcoal)
                }
            }

            Text(" ")
                .font(.system(size: 9))
        }
    }

    private func abstainDayShield(entry: HabitEntry?, isFuture: Bool, isActive: Bool) -> some View {
        let confirmed = entry?.isCompleted ?? false

        return VStack(spacing: 4) {
            Image(systemName: confirmed ? "shield.fill" : "shield")
                .font(.system(size: 20))
                .foregroundStyle(
                    confirmed ? TributeColor.sage :
                        (isFuture || !isActive ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.25))
                )
                .frame(width: 28, height: 28)

            Text(" ")
                .font(.system(size: 9))
        }
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity")
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(TributeColor.softGold)
                Spacer()
                Text("Last 12 weeks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HeatmapView(habit: habit, weekCount: 12)
                .id(entryRefreshKey)
        }
        .tributeCard()
    }

    private var yearHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Year in Tribute")
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(TributeColor.golden)
                Spacer()
                Text("52 weeks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HeatmapView(habit: habit, weekCount: 52)
                .id(entryRefreshKey)
        }
        .tributeCard()
    }

    private var lockedYearHeatmapSection: some View {
        Button {
            showPaywall = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Year in Tribute")
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundStyle(TributeColor.softGold)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                        Text("PRO")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(TributeColor.golden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(TributeColor.golden.opacity(0.15))
                    .clipShape(Capsule())
                }

                HeatmapView(habit: habit, weekCount: 52)
                    .id(entryRefreshKey)
                    .blur(radius: 6)
                    .allowsHitTesting(false)

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(TributeColor.golden)
                    Text("Unlock with Tribute Pro")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(TributeColor.softGold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .tributeCard()
        }
        .buttonStyle(.plain)
    }

    private var milestoneSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Milestones")
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(TributeColor.softGold)

            ForEach(milestones) { milestone in
                let isNew = milestoneService.isRecentlyReached(milestone: milestone, habit: habit)

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(milestone.isReached ? accentColor.opacity(0.2) : TributeColor.surfaceOverlay)
                            .frame(width: 36, height: 36)

                        Image(systemName: milestone.isReached ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundStyle(milestone.isReached ? accentColor : Color.secondary.opacity(0.4))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(milestone.message)
                                .font(.subheadline)
                                .foregroundStyle(milestone.isReached ? Color.primary : Color.secondary.opacity(0.5))

                            if isNew {
                                Text("NEW")
                                    .font(.system(size: 8, weight: .heavy))
                                    .foregroundStyle(TributeColor.charcoal)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(TributeColor.golden)
                                    .clipShape(Capsule())
                            }
                        }

                        if let hint = milestone.progressHint, !milestone.isReached {
                            Text(hint)
                                .font(.caption)
                                .foregroundStyle(accentColor.opacity(0.6))
                        } else if !milestone.isReached {
                            Text("Keep going")
                                .font(.caption)
                                .foregroundStyle(Color.secondary.opacity(0.3))
                        }
                    }

                    Spacer()

                    if milestone.isReached {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(accentColor.opacity(0.6))
                    }
                }
            }
        }
        .tributeCard()
    }

    private var anchoringSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !habit.trigger.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Trigger", systemImage: "clock")
                        .font(.system(.caption, design: .serif, weight: .semibold))
                        .foregroundStyle(TributeColor.golden.opacity(0.7))
                    Text(habit.trigger)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(.primary)
                }
            }

            if !habit.copingPlan.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Coping Plan", systemImage: "shield.checkered")
                        .font(.system(.caption, design: .serif, weight: .semibold))
                        .foregroundStyle(TributeColor.warmCoral.opacity(0.7))
                    Text(habit.copingPlan)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tributeCard()
    }

    private var purposeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Why")
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(TributeColor.softGold)

            Text(habit.purposeStatement)
                .font(.system(.body, design: .serif))
                .foregroundStyle(.primary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tributeCard()
    }

    private var verseSection: some View {
        VStack(spacing: 6) {
            let verse = ScriptureLibrary.completionVerse(for: habit.habitCategory, on: Date(), isPremium: isPremium)
            Text("\u{201C}\(verse.text)\u{201D}")
                .font(.system(.subheadline, design: .serif))
                .italic()
                .foregroundStyle(TributeColor.softGold.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text(verse.reference)
                .font(.caption)
                .foregroundStyle(TributeColor.golden.opacity(0.5))
        }
        .padding(.horizontal, 8)
    }

    private var habitInfoSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Tracking type")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(habit.habitTrackingType.rawValue.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TributeColor.softGold)
            }

            HStack {
                Text("Started")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(habitAge) days ago")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TributeColor.softGold)
            }

            HStack {
                Text("Total entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(habit.entries.filter(\.isCompleted).count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TributeColor.softGold)
            }

            if habit.activeDaySet.count < 7 {
                HStack {
                    Text("Active days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(activeDaysSummary)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(TributeColor.softGold)
                }
            }
        }
        .padding(14)
        .background(TributeColor.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
        )
    }

    private var currentWeekDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func shortDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }

    private var activeDaysSummary: String {
        let names = [1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"]
        return habit.activeDaySet.sorted().compactMap { names[$0] }.joined(separator: ", ")
    }
}
