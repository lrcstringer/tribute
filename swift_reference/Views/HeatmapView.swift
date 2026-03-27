import SwiftUI

struct HeatmapView: View {
    let habit: Habit
    let weekCount: Int

    @State private var scoreService = DailyScoreService()

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        return cal
    }()

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var weeks: [[HeatmapDay]] {
        var result: [[HeatmapDay]] = []
        let today = calendar.startOfDay(for: Date())

        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return result
        }

        for weekOffset in stride(from: -(weekCount - 1), through: 0, by: 1) {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart) else { continue }
            var week: [HeatmapDay] = []
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
                let isFuture = date > today
                let score = isFuture ? 0 : scoreService.habitScore(for: habit, on: date)
                let tier = isFuture ? DayTier.nothing : scoreService.tier(for: max(score, 0))
                week.append(HeatmapDay(date: date, isFuture: isFuture, tier: tier))
            }
            result.append(week)
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if weekCount > 1 {
                HStack(spacing: 0) {
                    ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            let tileSpacing: CGFloat = weekCount > 4 ? 2 : 3

            VStack(spacing: tileSpacing) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: tileSpacing) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                            heatmapTile(day)
                        }
                    }
                }
            }
        }
    }

    private func heatmapTile(_ day: HeatmapDay) -> some View {
        let cornerRadius: CGFloat = weekCount > 12 ? 2 : 3
        let isAbstain = habit.habitTrackingType == .abstain
        let accentColor = isAbstain ? TributeColor.sage : TributeColor.golden

        return RoundedRectangle(cornerRadius: cornerRadius)
            .fill(tileFill(day: day, accent: accentColor))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if day.tier == .partial && !day.isFuture {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(accentColor.opacity(0.5), lineWidth: 1)
                }
            }
            .shadow(
                color: day.tier == .full && !day.isFuture ? accentColor.opacity(0.35) : .clear,
                radius: 3,
                y: 0
            )
    }

    private func tileFill(day: HeatmapDay, accent: Color) -> Color {
        if day.isFuture {
            return Color.white.opacity(0.02)
        }
        switch day.tier {
        case .nothing:
            return TributeColor.surfaceOverlay
        case .partial:
            return accent.opacity(0.12)
        case .substantial:
            return accent.opacity(0.55)
        case .full:
            return accent.opacity(0.8)
        }
    }
}

private struct HeatmapDay {
    let date: Date
    let isFuture: Bool
    let tier: DayTier
}
