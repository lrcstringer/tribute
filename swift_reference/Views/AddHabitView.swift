import SwiftUI

struct AddHabitView: View {
    let viewModel: HabitViewModel
    let existingCount: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.storeViewModel) private var store

    @State private var selectedCategory: HabitCategory?
    @State private var habitName: String = ""
    @State private var purposeStatement: String = ""
    @State private var trackingType: HabitTrackingType = .checkIn
    @State private var dailyTarget: Double = 1
    @State private var targetUnit: String = ""
    @State private var activeDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    @State private var trigger: String = ""
    @State private var copingPlan: String = ""
    @State private var step: Int = 1
    @State private var showPurposePaywall: Bool = false

    private var isPremium: Bool {
        store?.isPremium ?? false
    }

    private let selectableCategories: [HabitCategory] = [
        .exercise, .scripture, .rest, .fasting, .study, .service, .connection, .health
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    switch step {
                    case 1:
                        categorySelection
                    case 2:
                        habitDetails
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationTitle(step == 1 ? "Choose a Habit" : "Set It Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(TributeColor.softGold)
                }
            }
            .sheet(isPresented: $showPurposePaywall) {
                PurposePaywallSheet(store: store)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var categorySelection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What do you want to give to God this season?")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(.primary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(selectableCategories, id: \.self) { category in
                    Button {
                        withAnimation(.snappy) {
                            selectedCategory = category
                            trackingType = category.suggestedTrackingType
                            habitName = defaultName(for: category)
                            purposeStatement = category.defaultPurpose
                            targetUnit = defaultUnit(for: category)
                            dailyTarget = defaultTarget(for: category)
                            step = 2
                        }
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 24))
                                .foregroundStyle(TributeColor.golden)

                            Text(category.rawValue)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(TributeColor.cardBackground)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                withAnimation(.snappy) {
                    selectedCategory = .abstain
                    trackingType = .abstain
                    habitName = ""
                    purposeStatement = HabitCategory.abstain.defaultPurpose
                    step = 2
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(TributeColor.warmCoral)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("I'm letting go of something")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("Break a bad habit with God's help")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(TributeColor.cardBackground)
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(TributeColor.warmCoral.opacity(0.2), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.snappy) {
                    selectedCategory = .custom
                    trackingType = .checkIn
                    habitName = ""
                    purposeStatement = HabitCategory.custom.defaultPurpose
                    dailyTarget = 1
                    targetUnit = ""
                    step = 2
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundStyle(TributeColor.golden)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Something else entirely")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("Create a fully custom habit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(TributeColor.cardBackground)
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(TributeColor.golden.opacity(0.15), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var habitDetails: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let category = selectedCategory {
                HStack(spacing: 10) {
                    Image(systemName: category.iconName)
                        .font(.system(size: 18))
                        .foregroundStyle(TributeColor.golden)
                    Text(category.rawValue)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(TributeColor.softGold.opacity(0.7))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Habit Name")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TributeColor.softGold.opacity(0.6))
                TextField("e.g. Morning run", text: $habitName)
                    .font(.body)
                    .padding(12)
                    .background(TributeColor.surfaceOverlay)
                    .clipShape(.rect(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Your Why")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(TributeColor.softGold.opacity(0.6))
                    if !isPremium {
                        Spacer()
                        Button {
                            showPurposePaywall = true
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 8))
                                Text("Customise")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(TributeColor.golden)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(TributeColor.golden.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }

                if isPremium {
                    TextField("Why does this matter to you and to God?", text: $purposeStatement, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(2...4)
                        .padding(12)
                        .background(TributeColor.surfaceOverlay)
                        .clipShape(.rect(cornerRadius: 10))
                } else {
                    Text(purposeStatement)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(TributeColor.softGold.opacity(0.7))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TributeColor.surfaceOverlay)
                        .clipShape(.rect(cornerRadius: 10))
                }
            }

            if selectedCategory != .abstain {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tracking Type")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(TributeColor.softGold.opacity(0.6))

                    HStack(spacing: 8) {
                        ForEach([HabitTrackingType.checkIn, .timed, .count], id: \.self) { type in
                            Button {
                                withAnimation(.snappy) {
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
                                Text(trackingTypeLabel(type))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(trackingType == type ? TributeColor.charcoal : TributeColor.softGold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(trackingType == type ? TributeColor.golden : TributeColor.surfaceOverlay)
                                    .clipShape(.rect(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if trackingType == .timed {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Goal (minutes)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(TributeColor.softGold.opacity(0.6))

                    HStack(spacing: 12) {
                        ForEach([15.0, 30.0, 45.0, 60.0], id: \.self) { minutes in
                            Button {
                                dailyTarget = minutes
                            } label: {
                                Text("\(Int(minutes))")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(dailyTarget == minutes ? TributeColor.charcoal : TributeColor.softGold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(dailyTarget == minutes ? TributeColor.golden : TributeColor.surfaceOverlay)
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
                            .background(TributeColor.surfaceOverlay)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                }
            }

            if selectedCategory == .abstain {
                abstainPresets
            }

            DayOfWeekPicker(selectedDays: $activeDays, isAbstain: selectedCategory == .abstain)

            anchoringSection

            Spacer(minLength: 20)

            Button {
                saveHabit()
            } label: {
                Text("Set this habit")
                    .tributeButton()
            }
            .disabled(habitName.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(habitName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
    }

    private var abstainPresets: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What are you letting go of?")
                .font(.caption.weight(.medium))
                .foregroundStyle(TributeColor.softGold.opacity(0.6))

            let presets = ["No alcohol", "No porn", "No doom-scrolling", "No junk food", "No smoking"]
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        habitName = preset
                    } label: {
                        Text(preset)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(habitName == preset ? TributeColor.charcoal : TributeColor.softGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(habitName == preset ? TributeColor.warmCoral : TributeColor.surfaceOverlay)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func trackingTypeLabel(_ type: HabitTrackingType) -> String {
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
        case .custom: return ""
        default: return ""
        }
    }

    private func defaultTarget(for category: HabitCategory) -> Double {
        switch category {
        case .exercise: return 30
        case .scripture: return 15
        case .rest: return 1
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
        if selectedCategory == .abstain {
            VStack(alignment: .leading, spacing: 8) {
                Text("When I feel tempted, I will\u{2026}")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TributeColor.softGold.opacity(0.6))

                let suggestions = ["Pray first", "Call a friend", "Go for a walk", "Read my verse", "Journal it out"]
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                copingPlan = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(copingPlan == suggestion ? TributeColor.charcoal : TributeColor.softGold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(copingPlan == suggestion ? TributeColor.warmCoral : TributeColor.surfaceOverlay)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .contentMargins(.horizontal, 0)

                TextField("Or write your own plan\u{2026}", text: $copingPlan)
                    .font(.subheadline)
                    .padding(12)
                    .background(TributeColor.surfaceOverlay)
                    .clipShape(.rect(cornerRadius: 10))
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("When will you do this?")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TributeColor.softGold.opacity(0.6))

                let suggestions = triggerChips(for: selectedCategory ?? .gratitude)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                trigger = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(trigger == suggestion ? TributeColor.charcoal : TributeColor.softGold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(trigger == suggestion ? TributeColor.golden : TributeColor.surfaceOverlay)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .contentMargins(.horizontal, 0)

                TextField("Or type your own trigger\u{2026}", text: $trigger)
                    .font(.subheadline)
                    .padding(12)
                    .background(TributeColor.surfaceOverlay)
                    .clipShape(.rect(cornerRadius: 10))
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

    private func saveHabit() {
        guard let category = selectedCategory else { return }
        let trimmedName = habitName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let finalPurpose = isPremium ? purposeStatement : (selectedCategory?.defaultPurpose ?? purposeStatement)

        viewModel.addHabit(
            name: trimmedName,
            category: category,
            trackingType: trackingType,
            purpose: finalPurpose,
            dailyTarget: dailyTarget,
            targetUnit: targetUnit,
            existingCount: existingCount,
            activeDays: activeDays,
            trigger: trigger,
            copingPlan: copingPlan
        )
        dismiss()
    }
}

private struct PurposePaywallSheet: View {
    let store: StoreViewModel?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let store {
            TributePaywallView(
                store: store,
                contextTitle: "Custom purpose statements",
                contextMessage: "Write your own \u{2018}why\u{2019} for each habit. Make it personal and God-centred."
            )
            .preferredColorScheme(.dark)
        }
    }
}
