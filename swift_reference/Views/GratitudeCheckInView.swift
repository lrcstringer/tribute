import SwiftUI

struct GratitudeCheckInView: View {
    let habit: Habit
    let viewModel: HabitViewModel
    let targetDate: Date
    let isRetroactive: Bool

    @State private var gratitudeText: String = ""
    @State private var showPulse: Bool = false
    @State private var isCompleted: Bool = false
    @State private var showDetail: Bool = false
    @State private var celebrationMilestone: Milestone?
    @State private var milestoneService = MilestoneService()
    @State private var completionVerse: Scripture?
    @State private var showSharePrompt: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareConfirmed: Bool = false
    @State private var userCircles: [CircleListItem] = []
    @State private var lastCompletedGratitudeText: String?

    @Environment(\.storeViewModel) private var store

    private var isPremium: Bool {
        store?.isPremium ?? false
    }

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
                                        TributeColor.golden.opacity(isCompleted ? 0.35 : 0.12),
                                        TributeColor.golden.opacity(isCompleted ? 0.15 : 0.04)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 22
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "hands.sparkles.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(isCompleted ? TributeColor.golden : TributeColor.softGold)
                            .symbolEffect(.bounce, value: showPulse)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Daily Gratitude")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(.primary)

                        if isCompleted {
                            Text("\(habit.totalCompletedDays()) days of gratitude")
                                .font(.caption)
                                .foregroundStyle(TributeColor.sage)
                        } else {
                            Text(isRetroactive ? "Were you grateful on \(dayName)?" : "What\u{2019}s one thing you\u{2019}re grateful for?")
                                .font(.caption)
                                .foregroundStyle(TributeColor.softGold.opacity(0.7))
                        }
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

            if !isCompleted {
                VStack(spacing: 12) {
                    TextField(isRetroactive ? "What were you grateful for?" : "Thank God for something today...", text: $gratitudeText, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(2...4)
                        .padding(12)
                        .background(TributeColor.surfaceOverlay)
                        .clipShape(.rect(cornerRadius: 10))

                    Button {
                        completeGratitude(note: gratitudeText.isEmpty ? nil : gratitudeText)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                            Text(gratitudeText.isEmpty ? "Thank you, God" : "Give thanks")
                        }
                        .tributeButton()
                    }
                }
            }

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

            if showSharePrompt && isCompleted && !userCircles.isEmpty {
                if shareConfirmed {
                    Text("Shared \u{2713}")
                        .font(.system(.caption, design: .serif, weight: .medium))
                        .foregroundStyle(TributeColor.sage)
                        .transition(.opacity)
                } else {
                    Button {
                        showShareSheet = true
                    } label: {
                        HStack {
                            Text("Share with your circle?")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "9A98A0"))
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13))
                                .foregroundStyle(TributeColor.golden)
                        }
                    }
                    .transition(.opacity)
                }
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
        .sheet(isPresented: $showShareSheet) {
            ShareGratitudeSheet(
                circles: userCircles,
                gratitudeText: lastCompletedGratitudeText
            ) { circleIds, isAnonymous in
                performShare(circleIds: circleIds, isAnonymous: isAnonymous)
            }
            .presentationDetents([.medium])
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(item: $celebrationMilestone) { milestone in
            MilestoneCelebrationView(milestone: milestone) {
                celebrationMilestone = nil
            }
            .preferredColorScheme(.dark)
        }
        .onAppear { refreshState() }
        .onChange(of: targetDate) { _, _ in
            refreshState()
            gratitudeText = ""
        }
        .sensoryFeedback(.success, trigger: showPulse)
    }

    private func refreshState() {
        isCompleted = habit.isCompleted(on: targetDate)
        if isCompleted {
            completionVerse = ScriptureLibrary.completionVerse(for: habit.habitCategory, on: targetDate, isPremium: isPremium)
        } else {
            completionVerse = nil
        }
    }

    private func completeGratitude(note: String?) {
        let previousTotal = Double(habit.totalCompletedDays())
        withAnimation(.easeInOut(duration: 0.5)) {
            showPulse = true
            isCompleted = true
        }
        viewModel.checkInGratitude(habit, note: note, on: targetDate, retroactive: isRetroactive)
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

        lastCompletedGratitudeText = note
        loadUserCirclesForSharePrompt()
    }

    private func loadUserCirclesForSharePrompt() {
        guard AuthenticationService.shared.isAuthenticated else { return }
        Task {
            do {
                let circles = try await APIService.shared.listCircles()
                guard !circles.isEmpty else { return }
                userCircles = circles
                try? await Task.sleep(for: .seconds(1.3))
                withAnimation(.easeIn(duration: 0.3)) {
                    showSharePrompt = true
                }
            } catch {}
        }
    }

    private func performShare(circleIds: [String], isAnonymous: Bool) {
        let text: String
        if let written = lastCompletedGratitudeText, !written.isEmpty {
            text = written
        } else {
            let firstName = AuthenticationService.shared.displayName?.components(separatedBy: " ").first ?? "Someone"
            text = isAnonymous ? "gave thanks to God today" : "\(firstName) gave thanks to God today"
        }

        Task {
            do {
                _ = try await APIService.shared.shareGratitude(
                    circleIds: circleIds,
                    gratitudeText: text,
                    isAnonymous: isAnonymous,
                    displayName: AuthenticationService.shared.displayName
                )
                withAnimation(.easeIn(duration: 0.3)) {
                    shareConfirmed = true
                }
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeOut(duration: 0.3)) {
                    shareConfirmed = false
                    showSharePrompt = false
                }
            } catch {}
        }
    }
}
