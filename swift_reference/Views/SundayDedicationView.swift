import SwiftUI
import SwiftData

struct SundayDedicationView: View {
    let weekCycleManager: WeekCycleManager
    let onDedicated: () -> Void

    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var showHeading: Bool = false
    @State private var showVerse: Bool = false
    @State private var showButton: Bool = false
    @State private var revealedTileCount: Int = 0
    @State private var isDedicating: Bool = false
    @State private var isDedicated: Bool = false
    @State private var showDedicatedMessage: Bool = false
    @State private var breathe: Bool = false
    @State private var glowIntensity: Double = 0.08

    private var isMidWeekStart: Bool {
        !weekCycleManager.isSunday && !weekCycleManager.isCurrentWeekDedicated
    }

    var body: some View {
        ZStack {
            TributeColor.charcoal.ignoresSafeArea()

            RadialGradient(
                colors: [
                    TributeColor.golden.opacity(glowIntensity),
                    TributeColor.softGold.opacity(glowIntensity * 0.4),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: breathe ? 320 : 250
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: breathe)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        if !isDedicated {
                            preDedicationContent
                        } else {
                            postDedicationContent
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 100)
                }

                Spacer(minLength: 0)

                if !isDedicated && showButton && !isDedicating {
                    Button {
                        performDedication()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "hands.sparkles.fill")
                                .font(.subheadline)
                            Text("Dedicate this week to God")
                        }
                        .tributeButton()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if isDedicated && showDedicatedMessage {
                    Button {
                        onDedicated()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Begin your week")
                            Image(systemName: "arrow.right")
                                .font(.subheadline)
                        }
                        .tributeButton()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .sensoryFeedback(.success, trigger: isDedicated)
        .onAppear { startEntryAnimations() }
    }

    @ViewBuilder
    private var preDedicationContent: some View {
        VStack(spacing: 6) {
            if isMidWeekStart {
                Text("Starting mid-week?")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(TributeColor.softGold.opacity(0.6))
            }

            Text(isMidWeekStart ? "No problem. Let's dedicate\nwhat's left of this week." : "Set Your Week")
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text("Your habits, your purpose, your offering.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .opacity(showHeading ? 1 : 0)
        .offset(y: showHeading ? 0 : 8)

        VStack(spacing: 14) {
            ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                let isRevealed = index < revealedTileCount
                dedicationHabitTile(habit: habit)
                    .opacity(isRevealed ? 1 : 0)
                    .offset(y: isRevealed ? 0 : 12)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.2), value: revealedTileCount)
            }
        }

        if !habits.isEmpty {
            milestonePreviewSection
                .opacity(showVerse ? 1 : 0)
                .offset(y: showVerse ? 0 : 8)
        }

        VStack(spacing: 6) {
            Text("\u{201C}The steadfast love of the Lord never ceases; his mercies never come to an end; they are new every morning.\u{201D}")
                .font(.system(.subheadline, design: .serif))
                .italic()
                .foregroundStyle(TributeColor.softGold.opacity(0.6))
                .multilineTextAlignment(.center)
            Text("Lamentations 3:22\u{2013}23")
                .font(.caption)
                .foregroundStyle(TributeColor.golden.opacity(0.5))
        }
        .opacity(showVerse ? 1 : 0)
    }

    @ViewBuilder
    private var postDedicationContent: some View {
        Spacer().frame(height: 60)

        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                TributeColor.golden.opacity(0.4),
                                TributeColor.golden.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)

                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(TributeColor.golden)
            }

            VStack(spacing: 8) {
                Text("Your week is dedicated.")
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(.primary)

                Text("God is with you in the effort and in the rest.")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(TributeColor.softGold)
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(showDedicatedMessage ? 1 : 0)
        .scaleEffect(showDedicatedMessage ? 1 : 0.92)
    }

    private func dedicationHabitTile(habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    tileAccent(habit).opacity(0.25),
                                    tileAccent(habit).opacity(0.06)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 24
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: habit.habitCategory.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(tileAccent(habit))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.name)
                        .font(.system(.headline, design: .serif))

                    Text(habit.purposeStatement)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(weekCycleManager.weekProjectionSummary(for: habit))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(TributeColor.softGold.opacity(0.6))
            }

            if habit.isCompletedToday() && habit.isBuiltIn {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(TributeColor.golden)
                    Text("Already completed today")
                        .font(.caption)
                        .foregroundStyle(TributeColor.sage)
                }
            }

            let verse = ScriptureLibrary.anchorVerse(for: habit.habitCategory)
            Text("\u{201C}\(verse.text)\u{201D} \u{2014} \(verse.reference)")
                .font(.caption)
                .italic()
                .foregroundStyle(TributeColor.softGold.opacity(0.5))
                .lineLimit(2)
        }
        .tributeCard()
    }

    @ViewBuilder
    private var milestonePreviewSection: some View {
        let previews = habits.compactMap { habit -> (Habit, String)? in
            guard let preview = weekCycleManager.microMilestonePreview(for: habit) else { return nil }
            return (habit, preview)
        }

        if !previews.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("If you hit your targets this week:")
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(TributeColor.softGold)

                ForEach(previews, id: \.0.id) { habit, preview in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkle")
                            .font(.caption)
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
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TributeColor.golden.opacity(0.04))
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(TributeColor.golden.opacity(0.12), lineWidth: 0.5)
            )
        }
    }

    private func tileAccent(_ habit: Habit) -> Color {
        habit.habitTrackingType == .abstain ? TributeColor.sage : TributeColor.golden
    }

    private func startEntryAnimations() {
        breathe = true

        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            showHeading = true
        }

        let tileDelay = 0.8
        for i in 0...habits.count {
            let delay = tileDelay + Double(i) * 0.2
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                revealedTileCount = i + 1
            }
        }

        let verseDelay = tileDelay + Double(habits.count) * 0.2 + 0.3
        withAnimation(.easeOut(duration: 0.5).delay(verseDelay)) {
            showVerse = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(verseDelay + 0.3)) {
            showButton = true
        }
    }

    private func performDedication() {
        isDedicating = true

        withAnimation(.easeInOut(duration: 1.5)) {
            glowIntensity = 0.3
        }

        Task {
            try? await Task.sleep(for: .seconds(1.0))

            weekCycleManager.dedicateCurrentWeek()

            withAnimation(.easeInOut(duration: 0.8)) {
                isDedicated = true
                showButton = false
            }

            withAnimation(.easeInOut(duration: 1.0)) {
                glowIntensity = 0.12
            }

            try? await Task.sleep(for: .seconds(0.5))

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showDedicatedMessage = true
            }
        }
    }
}
