import SwiftUI

struct HabitSummaryScreen: View {
    let habitName: String
    let habitCategory: HabitCategory
    let trackingType: HabitTrackingType
    let purposeStatement: String
    let dailyTarget: Double
    let targetUnit: String
    let activeDays: Set<Int>
    let onFinish: () -> Void

    @State private var showGratitude: Bool = false
    @State private var showCustom: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Tribute habits")
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("Looks good? You can change any of this later.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                TributeColor.golden.opacity(0.35),
                                                TributeColor.golden.opacity(0.12)
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 24
                                        )
                                    )
                                    .frame(width: 48, height: 48)

                                Image(systemName: "hands.sparkles.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(TributeColor.golden)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Daily Gratitude")
                                        .font(.system(.headline, design: .serif))

                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(TributeColor.golden)
                                }

                                Text("Check-in")
                                    .font(.caption)
                                    .foregroundStyle(TributeColor.sage)

                                Text("Already completed today")
                                    .font(.caption)
                                    .foregroundStyle(TributeColor.golden.opacity(0.7))
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(TributeColor.golden.opacity(0.06))
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(TributeColor.golden.opacity(0.2), lineWidth: 0.5)
                        )
                        .opacity(showGratitude ? 1 : 0)
                        .offset(y: showGratitude ? 0 : 12)

                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                accentColor.opacity(0.2),
                                                accentColor.opacity(0.06)
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 24
                                        )
                                    )
                                    .frame(width: 48, height: 48)

                                Image(systemName: habitCategory.iconName)
                                    .font(.system(size: 20))
                                    .foregroundStyle(accentColor)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(habitName)
                                    .font(.system(.headline, design: .serif))

                                Text(trackingDescription)
                                    .font(.caption)
                                    .foregroundStyle(TributeColor.sage)

                                Text(purposeStatement)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)

                                if activeDays.count < 7 {
                                    Text(activeDaysSummary)
                                        .font(.caption2)
                                        .foregroundStyle(TributeColor.softGold.opacity(0.5))
                                }
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(TributeColor.cardBackground)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                        )
                        .opacity(showCustom ? 1 : 0)
                        .offset(y: showCustom ? 0 : 12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            Button {
                onFinish()
            } label: {
                HStack(spacing: 8) {
                    Text("Let's go")
                    Image(systemName: "arrow.right")
                        .font(.subheadline)
                }
                .tributeButton()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showGratitude = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                showCustom = true
            }
        }
    }

    private var accentColor: Color {
        habitCategory == .abstain ? TributeColor.warmCoral : TributeColor.golden
    }

    private var activeDaysSummary: String {
        let names = [1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"]
        let sorted = activeDays.sorted()
        let dayNames = sorted.compactMap { names[$0] }
        return dayNames.joined(separator: ", ")
    }

    private var trackingDescription: String {
        switch trackingType {
        case .timed:
            return "\(Int(dailyTarget)) \(targetUnit)/day"
        case .count:
            return "\(Int(dailyTarget)) \(targetUnit.isEmpty ? "per day" : "\(targetUnit)/day")"
        case .checkIn:
            return "Daily check-in"
        case .abstain:
            return "Confirm daily"
        }
    }
}
