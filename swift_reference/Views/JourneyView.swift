import SwiftUI
import SwiftData

struct JourneyView: View {
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var allEntries: [HabitEntry]
    @Environment(\.storeViewModel) private var store

    @State private var milestoneService = MilestoneService()
    @State private var showPaywall: Bool = false
    @State private var showContent: Bool = false

    private var entryRefreshKey: Int {
        allEntries.count + allEntries.filter(\.isCompleted).count
    }

    private var isPremium: Bool {
        store?.isPremium ?? false
    }

    private var totalGivingDays: Int {
        let calendar = Calendar.current
        var uniqueDays: Set<String> = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for habit in habits {
            for entry in habit.entries where entry.isCompleted {
                let key = formatter.string(from: calendar.startOfDay(for: entry.date))
                uniqueDays.insert(key)
            }
        }
        return uniqueDays.count
    }

    private var totalCheckIns: Int {
        habits.reduce(0) { $0 + $1.entries.filter(\.isCompleted).count }
    }

    private var gratitudeDays: Int {
        habits.first { $0.isBuiltIn && $0.habitCategory == .gratitude }?.totalCompletedDays() ?? 0
    }

    private var allEarnedMilestones: [(Habit, Milestone)] {
        habits.flatMap { habit in
            milestoneService.milestones(for: habit)
                .filter(\.isReached)
                .map { (habit, $0) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    heroStatSection
                    statCardsRow
                    heatmapSection
                    milestonesSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
            }
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                    contextMessage: "See your full 52-week heatmap and track your long-term growth across every habit."
                )
                .preferredColorScheme(.dark)
            }
        }
    }

    private var heroStatSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [TributeColor.golden.opacity(0.25), TributeColor.golden.opacity(0.04)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(TributeColor.golden)
            }

            Text("\(totalGivingDays)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(TributeColor.golden)

            Text(totalGivingDays == 1 ? "day of giving" : "days of giving")
                .font(.system(.body, design: .serif))
                .foregroundStyle(TributeColor.softGold)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var statCardsRow: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "hands.sparkles.fill",
                value: "\(gratitudeDays)",
                label: "gratitude days",
                color: TributeColor.golden
            )

            statCard(
                icon: "checkmark.circle.fill",
                value: "\(totalCheckIns)",
                label: "total check-ins",
                color: TributeColor.sage
            )

            statCard(
                icon: "star.fill",
                value: "\(allEarnedMilestones.count)",
                label: "milestones",
                color: TributeColor.golden
            )
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(TributeColor.cardBackground)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var heatmapSection: some View {
        if isPremium {
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

                AllHabitsHeatmapView(habits: habits, weekCount: 52)
                    .id(entryRefreshKey)

                heatmapLegend
            }
            .tributeCard()
        } else {
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

                    AllHabitsHeatmapView(habits: habits, weekCount: 52)
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

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Activity")
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundStyle(TributeColor.softGold)
                    Spacer()
                    Text("4 weeks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                AllHabitsHeatmapView(habits: habits, weekCount: 4)
                    .id(entryRefreshKey)

                heatmapLegend
            }
            .tributeCard()
        }
    }

    private var heatmapLegend: some View {
        HStack(spacing: 16) {
            Spacer()
            legendItem(color: TributeColor.surfaceOverlay, label: "None")
            legendItem(color: TributeColor.golden.opacity(0.12), label: "Some", hasBorder: true)
            legendItem(color: TributeColor.golden.opacity(0.55), label: "Strong")
            legendItem(color: TributeColor.golden.opacity(0.8), label: "Full")
            Spacer()
        }
        .padding(.top, 4)
    }

    private func legendItem(color: Color, label: String, hasBorder: Bool = false) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay {
                    if hasBorder {
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(TributeColor.golden.opacity(0.5), lineWidth: 0.5)
                    }
                }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(TributeColor.golden)
                Text("Milestones Earned")
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(TributeColor.softGold)
            }

            if allEarnedMilestones.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "star")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary.opacity(0.3))
                    Text("Keep giving \u{2014} milestones are on their way")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(Array(allEarnedMilestones.enumerated()), id: \.offset) { _, item in
                    let (habit, milestone) = item
                    let isNew = milestoneService.isRecentlyReached(milestone: milestone, habit: habit)
                    let accentColor: Color = habit.habitTrackingType == .abstain ? TributeColor.sage : TributeColor.golden

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(accentColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(milestone.message)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)

                                if isNew {
                                    Text("NEW")
                                        .font(.system(size: 7, weight: .heavy))
                                        .foregroundStyle(TributeColor.charcoal)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1.5)
                                        .background(TributeColor.golden)
                                        .clipShape(Capsule())
                                }
                            }

                            Text(habit.name)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(accentColor.opacity(0.5))
                    }
                }
            }
        }
        .tributeCard()
    }
}
