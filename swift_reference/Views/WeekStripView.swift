import SwiftUI

struct WeekStripView: View {
    let weekDates: [Date]
    let habits: [Habit]
    let scoreService: DailyScoreService
    @Binding var selectedDate: Date

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let calendar = Calendar.current

    private var todayStart: Date {
        calendar.startOfDay(for: Date())
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDates.enumerated()), id: \.offset) { index, date in
                let dateStart = calendar.startOfDay(for: date)
                let isToday = calendar.isDateInToday(date)
                let isFuture = dateStart > todayStart
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let tier = isFuture ? DayTier.nothing : scoreService.tier(for: habits, on: date)

                Button {
                    guard !isFuture else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDate = dateStart
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(dayLabels[index])
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(isToday ? TributeColor.golden : .secondary)

                        ZStack {
                            dayTile(tier: tier, isToday: isToday, isFuture: isFuture, isSelected: isSelected)
                        }
                        .frame(width: isToday ? 44 : 40, height: isToday ? 44 : 40)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func dayTile(tier: DayTier, isToday: Bool, isFuture: Bool, isSelected: Bool) -> some View {
        switch tier {
        case .nothing:
            Circle()
                .strokeBorder(
                    isFuture ? Color.white.opacity(0.04) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
                .background(Circle().fill(Color.clear))
                .overlay {
                    if isSelected && !isFuture {
                        Circle()
                            .strokeBorder(TributeColor.golden.opacity(0.5), lineWidth: 1.5)
                    }
                }

        case .partial:
            Circle()
                .strokeBorder(TributeColor.golden.opacity(0.6), lineWidth: 1.5)
                .background(Circle().fill(Color.clear))
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(TributeColor.golden.opacity(0.7))
                }
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(TributeColor.golden, lineWidth: 2)
                    }
                }

        case .substantial:
            Circle()
                .fill(TributeColor.golden)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(TributeColor.charcoal)
                }
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
                    }
                }

        case .full:
            Circle()
                .fill(TributeColor.golden)
                .overlay {
                    Circle()
                        .strokeBorder(TributeColor.golden.opacity(0.5), lineWidth: 1.5)
                        .scaleEffect(1.25)
                }
                .shadow(color: TributeColor.golden.opacity(0.7), radius: 12, y: 0)
                .shadow(color: TributeColor.golden.opacity(0.3), radius: 4, y: 0)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(TributeColor.charcoal)
                }
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                    }
                }
        }
    }
}
