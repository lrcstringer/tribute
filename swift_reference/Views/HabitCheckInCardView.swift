import SwiftUI

struct HabitCheckInCardView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    let targetDate: Date
    let isRetroactive: Bool

    @State private var showPulse: Bool = false
    @State private var isCompleted: Bool = false
    @State private var currentValue: Double = 0
    @State private var showDetail: Bool = false

    @State private var celebrationMilestone: Milestone?
    @State private var milestoneService = MilestoneService()
    @State private var completionVerse: Scripture?

    @Environment(\.storeViewModel) private var store

    private var isPremium: Bool {
        store?.isPremium ?? false
    }

    private let calendar = Calendar.current

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: targetDate)
    }

    var body: some View {
        VStack(spacing: 16) {
            Button {
                showDetail = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        habitAccentColor.opacity(isCompleted ? 0.35 : 0.12),
                                        habitAccentColor.opacity(isCompleted ? 0.15 : 0.04)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 22
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: habit.habitCategory.iconName)
                            .font(.system(size: 18))
                            .foregroundStyle(isCompleted ? habitAccentColor : habitAccentColor.opacity(0.7))
                            .symbolEffect(.bounce, value: showPulse)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.name)
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(.primary)

                        Text(habit.purposeStatement)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(TributeColor.golden)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.4))
                    }
                }
            }
            .buttonStyle(.plain)

            trackingContent

            if let verse = completionVerse, isCompleted {
                VStack(spacing: 4) {
                    Text("\u{201C}\(verse.text)\u{201D}")
                        .font(.system(.caption, design: .serif))
                        .italic()
                        .foregroundStyle(TributeColor.softGold.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                    Text(verse.reference)
                        .font(.caption2)
                        .foregroundStyle(TributeColor.golden.opacity(0.4))
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .tributeCard()
        .overlay {
            if showPulse {
                GoldenPulseView(dimmed: isRetroactive)
                    .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                HabitDetailView(habit: habit)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showDetail = false }
                                .foregroundStyle(TributeColor.golden)
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(item: $celebrationMilestone) { milestone in
            MilestoneCelebrationView(milestone: milestone) {
                celebrationMilestone = nil
            }
            .preferredColorScheme(.dark)
        }
        .onAppear { refreshState() }
        .onChange(of: targetDate) { _, _ in refreshState() }
        .sensoryFeedback(.success, trigger: showPulse)
    }

    private func refreshState() {
        isCompleted = habit.isCompleted(on: targetDate)
        currentValue = habit.entry(for: targetDate)?.value ?? 0
        if isCompleted {
            completionVerse = ScriptureLibrary.completionVerse(for: habit.habitCategory, on: targetDate, isPremium: isPremium)
        } else {
            completionVerse = nil
        }
    }

    @ViewBuilder
    private var trackingContent: some View {
        switch habit.habitTrackingType {
        case .checkIn:
            checkInContent
        case .abstain:
            abstainContent
        case .timed:
            timedContent
        case .count:
            countContent
        }
    }

    private var checkInContent: some View {
        Group {
            if !isCompleted {
                Button {
                    completeCheckIn()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text("Check in")
                    }
                    .tributeButton()
                }
            } else {
                HStack {
                    Text(isRetroactive ? "Given on \(dayName)" : "Given to God today")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(TributeColor.sage)
                    Spacer()
                    Text("\(habit.totalCompletedDays()) total days")
                        .font(.caption)
                        .foregroundStyle(TributeColor.softGold.opacity(0.6))
                }
            }
        }
    }

    private var abstainContent: some View {
        Group {
            if !isCompleted {
                Button {
                    completeCheckIn()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .font(.subheadline)
                        Text(isRetroactive ? "Were you strong on \(dayName)?" : "Stayed strong today")
                    }
                    .tributeButton(color: TributeColor.sage)
                }
            } else {
                HStack {
                    Label(isRetroactive ? "Strong on \(dayName)" : "Strong today", systemImage: "shield.fill")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(TributeColor.sage)
                    Spacer()
                    Text("\(habit.totalCompletedDays()) clean days")
                        .font(.caption)
                        .foregroundStyle(TributeColor.softGold.opacity(0.6))
                }
            }
        }
    }

    private var timedContent: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: habit.dailyTarget > 0 ? min(currentValue / habit.dailyTarget, 1.0) : 0)
                    .stroke(
                        isCompleted ? TributeColor.golden : TributeColor.softGold,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: currentValue)

                VStack(spacing: 2) {
                    Text("\(Int(currentValue))")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(TributeColor.golden)
                    Text("/ \(Int(habit.dailyTarget)) min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 90, height: 90)

            HStack(spacing: 10) {
                ForEach([5, 10, 15], id: \.self) { minutes in
                    Button {
                        addMinutes(Double(minutes))
                    } label: {
                        Text("+\(minutes)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TributeColor.softGold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(TributeColor.surfaceOverlay)
                            .clipShape(.rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                            )
                    }
                }
            }
        }
    }

    private var countContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("\(Int(currentValue))")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(TributeColor.golden)
                Text("/ \(Int(habit.dailyTarget))")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(habit.targetUnit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                Button {
                    updateCount(max(0, currentValue - 1))
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Button {
                    updateCount(currentValue + 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(TributeColor.golden)
                }
            }

            if isCompleted {
                Text("Target reached \u{2014} \(Int(habit.totalValue())) total")
                    .font(.caption)
                    .foregroundStyle(TributeColor.sage)
            }
        }
    }

    private var habitAccentColor: Color {
        switch habit.habitTrackingType {
        case .abstain: return TributeColor.sage
        default: return TributeColor.golden
        }
    }

    private func completeCheckIn() {
        let previousTotal = Double(habit.totalCompletedDays())
        withAnimation(.easeInOut(duration: 0.5)) {
            showPulse = true
            isCompleted = true
        }
        viewModel.checkInHabit(habit, on: targetDate, retroactive: isRetroactive)
        withAnimation(.easeInOut(duration: 0.5).delay(0.8)) {
            completionVerse = ScriptureLibrary.completionVerse(for: habit.habitCategory, on: targetDate, isPremium: isPremium)
        }

        if !isRetroactive {
            let newTotal = previousTotal + 1
            if let milestone = milestoneService.checkForNewMilestone(habit: habit, previousValue: previousTotal, newValue: newTotal) {
                Task {
                    try? await Task.sleep(for: .seconds(1.8))
                    withAnimation { showPulse = false }
                    try? await Task.sleep(for: .seconds(0.3))
                    celebrationMilestone = milestone
                }
                return
            }
        }

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { showPulse = false }
        }
    }

    private func addMinutes(_ minutes: Double) {
        let previousTotal = habit.totalValue()
        let newValue = currentValue + minutes
        withAnimation(.easeInOut(duration: 0.3)) {
            currentValue = newValue
            if newValue >= habit.dailyTarget && !isCompleted {
                isCompleted = true
                showPulse = true
            }
        }
        viewModel.updateTimedEntry(habit, minutes: newValue, on: targetDate, retroactive: isRetroactive)

        if !isRetroactive {
            let newTotal = previousTotal + minutes
            if let milestone = milestoneService.checkForNewMilestone(habit: habit, previousValue: previousTotal, newValue: newTotal) {
                Task {
                    try? await Task.sleep(for: .seconds(1.8))
                    withAnimation { showPulse = false }
                    try? await Task.sleep(for: .seconds(0.3))
                    celebrationMilestone = milestone
                }
                return
            }
        }

        if showPulse {
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation { showPulse = false }
            }
        }
    }

    private func updateCount(_ count: Double) {
        let previousTotal = habit.totalValue()
        let diff = count - currentValue
        withAnimation(.easeInOut(duration: 0.3)) {
            currentValue = count
            if count >= habit.dailyTarget && !isCompleted {
                isCompleted = true
                showPulse = true
            }
        }
        viewModel.updateCountEntry(habit, count: count, on: targetDate, retroactive: isRetroactive)

        if !isRetroactive && diff > 0 {
            let newTotal = previousTotal + diff
            if let milestone = milestoneService.checkForNewMilestone(habit: habit, previousValue: previousTotal, newValue: newTotal) {
                Task {
                    try? await Task.sleep(for: .seconds(1.8))
                    withAnimation { showPulse = false }
                    try? await Task.sleep(for: .seconds(0.3))
                    celebrationMilestone = milestone
                }
                return
            }
        }

        if showPulse {
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation { showPulse = false }
            }
        }
    }
}
