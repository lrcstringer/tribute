import SwiftUI

struct HabitSetupScreen: View {
    let category: HabitCategory
    let onComplete: (String, String, HabitTrackingType, Double, String, String, String, Set<Int>) -> Void

    @State private var habitName: String = ""
    @State private var purposeStatement: String = ""
    @State private var trackingType: HabitTrackingType = .checkIn
    @State private var dailyTarget: Double = 1
    @State private var targetUnit: String = ""
    @State private var trigger: String = ""
    @State private var copingPlan: String = ""
    @State private var activeDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]

    private var anchorVerse: Scripture {
        ScriptureLibrary.anchorVerse(for: category)
    }

    @State private var showScrollHint: Bool = true
    @State private var hasScrolled: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 10) {
                        Image(systemName: category.iconName)
                            .font(.system(size: 20))
                            .foregroundStyle(category == .abstain ? TributeColor.warmCoral : TributeColor.golden)

                        Text(category.rawValue)
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(TributeColor.softGold)
                    }

                    if category == .abstain {
                        abstainNameSection
                    } else {
                        nameSection
                    }

                    purposeSection

                    verseSection

                    if category != .abstain {
                        trackingSection
                        targetSection
                    }

                    DayOfWeekPicker(selectedDays: $activeDays, isAbstain: category == .abstain)

                    anchoringSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
            .scrollIndicators(.visible)
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, newOffset in
                if newOffset > 10 && !hasScrolled {
                    hasScrolled = true
                    withAnimation(.easeOut(duration: 0.3)) {
                        showScrollHint = false
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showScrollHint {
                    VStack(spacing: 4) {
                        Text("Scroll for more")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(TributeColor.softGold.opacity(0.5))
                        Image(systemName: "chevron.compact.down")
                            .font(.caption)
                            .foregroundStyle(TributeColor.softGold.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [TributeColor.charcoal.opacity(0), TributeColor.charcoal.opacity(0.95), TributeColor.charcoal],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 60)
                    )
                    .transition(.opacity)
                    .allowsHitTesting(false)
                }
            }

            Button {
                let name = habitName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                onComplete(name, purposeStatement, trackingType, dailyTarget, targetUnit, trigger, copingPlan, activeDays)
            } label: {
                HStack(spacing: 8) {
                    Text("Set this habit")
                    Image(systemName: "arrow.right")
                        .font(.subheadline)
                }
                .tributeButton()
            }
            .disabled(habitName.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(habitName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            habitName = defaultName(for: category)
            purposeStatement = category.defaultPurpose
            trackingType = category.suggestedTrackingType
            dailyTarget = defaultTarget(for: category)
            targetUnit = defaultUnit(for: category)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Habit Name")
                .font(.caption.weight(.medium))
                .foregroundStyle(TributeColor.softGold.opacity(0.6))

            TextField("e.g. Morning run", text: $habitName)
                .font(.body)
                .padding(14)
                .background(TributeColor.inputBackground)
                .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var abstainNameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What are you letting go of?")
                .font(.caption.weight(.medium))
                .foregroundStyle(TributeColor.softGold.opacity(0.6))

            let presets = ["No alcohol", "No porn", "No doom-scrolling", "No junk food", "No smoking"]
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        habitName = preset
                    } label: {
                        Text(preset)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(habitName == preset ? TributeColor.charcoal : TributeColor.softGold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(habitName == preset ? TributeColor.warmCoral : TributeColor.surfaceOverlay)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Or type your own...", text: $habitName)
                .font(.subheadline)
                .padding(14)
                .background(TributeColor.inputBackground)
                .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var purposeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Why")
                .font(.caption.weight(.medium))
                .foregroundStyle(TributeColor.softGold.opacity(0.6))

            Text("Why does this matter to you and to God?")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Your purpose for this habit...", text: $purposeStatement, axis: .vertical)
                .font(.subheadline)
                .lineLimit(2...4)
                .padding(14)
                .background(TributeColor.inputBackground)
                .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var verseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Anchor Verse")
                .font(.caption.weight(.medium))
                .foregroundStyle(TributeColor.softGold.opacity(0.6))

            VStack(alignment: .leading, spacing: 6) {
                Text("\"\(anchorVerse.text)\"")
                    .font(.system(.subheadline, design: .serif))
                    .italic()
                    .foregroundStyle(TributeColor.softGold.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                Text("- \(anchorVerse.reference)")
                    .font(.caption)
                    .foregroundStyle(TributeColor.golden.opacity(0.5))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TributeColor.golden.opacity(0.04))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(TributeColor.golden.opacity(0.12), lineWidth: 0.5)
            )
        }
    }

    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How do you want to track this?")
                .font(.caption.weight(.medium))
                .foregroundStyle(TributeColor.softGold.opacity(0.6))

            HStack(spacing: 8) {
                ForEach([HabitTrackingType.checkIn, .timed, .count], id: \.self) { type in
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            trackingType = type
                            if type == .timed {
                                dailyTarget = 30
                                targetUnit = "minutes"
                            } else if type == .count {
                                dailyTarget = 8
                                targetUnit = ""
                            } else {
                                dailyTarget = 1
                                targetUnit = ""
                            }
                        }
                    } label: {
                        Text(trackingLabel(type))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(trackingType == type ? TributeColor.charcoal : TributeColor.softGold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(trackingType == type ? TributeColor.golden : TributeColor.inputBackground)
                            .clipShape(.rect(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var targetSection: some View {
        if trackingType == .timed {
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Goal (minutes)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TributeColor.softGold.opacity(0.6))

                HStack(spacing: 10) {
                    ForEach([15.0, 30.0, 45.0, 60.0], id: \.self) { minutes in
                        Button {
                            dailyTarget = minutes
                        } label: {
                            Text("\(Int(minutes))")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(dailyTarget == minutes ? TributeColor.charcoal : TributeColor.softGold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(dailyTarget == minutes ? TributeColor.golden : TributeColor.inputBackground)
                                .clipShape(.rect(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }

        if trackingType == .count {
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Goal")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TributeColor.softGold.opacity(0.6))

                HStack(spacing: 12) {
                    Stepper(value: $dailyTarget, in: 1...100) {
                        Text("\(Int(dailyTarget))")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(TributeColor.golden)
                    }

                    TextField("Unit (e.g. glasses)", text: $targetUnit)
                        .font(.subheadline)
                        .padding(10)
                        .background(TributeColor.inputBackground)
                        .clipShape(.rect(cornerRadius: 8))
                }
            }
        }
    }

    private func trackingLabel(_ type: HabitTrackingType) -> String {
        switch type {
        case .checkIn: return "Yes/No"
        case .timed: return "Timed"
        case .count: return "Count"
        case .abstain: return "Abstain"
        }
    }

    private func defaultName(for category: HabitCategory) -> String {
        switch category {
        case .exercise: return "Exercise"
        case .scripture: return "Bible Reading"
        case .rest: return "Sleep"
        case .fasting: return "Fasting"
        case .study: return "Study"
        case .service: return "Serve Someone"
        case .connection: return "Call a Friend"
        case .health: return "Drink Water"
        case .abstain: return ""
        case .custom: return ""
        default: return ""
        }
    }

    private func defaultTarget(for category: HabitCategory) -> Double {
        switch category {
        case .exercise: return 30
        case .scripture: return 15
        case .study: return 30
        case .health: return 8
        default: return 1
        }
    }

    private func defaultUnit(for category: HabitCategory) -> String {
        switch category {
        case .exercise, .scripture, .study: return "minutes"
        case .service: return "acts"
        case .health: return "glasses"
        default: return ""
        }
    }

    @ViewBuilder
    private var anchoringSection: some View {
        if category == .abstain {
            VStack(alignment: .leading, spacing: 8) {
                Text("When I feel tempted, I will\u{2026}")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TributeColor.softGold.opacity(0.6))

                let copingSuggestions = ["Pray first", "Call a friend", "Go for a walk", "Read my verse", "Journal it out"]
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(copingSuggestions, id: \.self) { suggestion in
                            Button {
                                copingPlan = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(copingPlan == suggestion ? TributeColor.charcoal : TributeColor.softGold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(copingPlan == suggestion ? TributeColor.warmCoral : TributeColor.inputBackground)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .contentMargins(.horizontal, 0)

                TextField("Or write your own plan\u{2026}", text: $copingPlan)
                    .font(.subheadline)
                    .padding(14)
                    .background(TributeColor.inputBackground)
                    .clipShape(.rect(cornerRadius: 12))
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("When will you do this?")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TributeColor.softGold.opacity(0.6))

                Text("Anchor it to something you already do.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let triggerSuggestions = triggerChips(for: category)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(triggerSuggestions, id: \.self) { suggestion in
                            Button {
                                trigger = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(trigger == suggestion ? TributeColor.charcoal : TributeColor.softGold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(trigger == suggestion ? TributeColor.golden : TributeColor.inputBackground)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .contentMargins(.horizontal, 0)

                TextField("Or type your own trigger\u{2026}", text: $trigger)
                    .font(.subheadline)
                    .padding(14)
                    .background(TributeColor.inputBackground)
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private func triggerChips(for category: HabitCategory) -> [String] {
        switch category {
        case .exercise: return ["After my morning coffee", "Before work", "During lunch break", "After dinner"]
        case .scripture: return ["First thing in the morning", "Before bed", "During lunch", "After prayer"]
        case .rest: return ["At 10pm", "After dinner", "When I feel tired"]
        case .fasting: return ["After morning prayer", "On Wednesdays", "Weekly"]
        case .study: return ["After dinner", "Morning routine", "Lunch break"]
        case .service: return ["After church", "On weekends", "When I see a need"]
        case .connection: return ["Sunday afternoon", "After dinner", "During commute"]
        case .health: return ["With every meal", "First thing in the morning", "After exercise", "Before bed"]
        default: return ["In the morning", "After lunch", "Before bed"]
        }
    }
}
