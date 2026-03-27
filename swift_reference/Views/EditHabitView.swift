import SwiftUI

struct EditHabitView: View {
    let habit: Habit

    @Environment(\.dismiss) private var dismiss
    @Environment(\.storeViewModel) private var store

    @State private var habitName: String = ""
    @State private var purposeStatement: String = ""
    @State private var dailyTarget: Double = 1
    @State private var targetUnit: String = ""
    @State private var activeDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    @State private var trigger: String = ""
    @State private var copingPlan: String = ""
    @State private var showPurposePaywall: Bool = false

    private var isPremium: Bool {
        store?.isPremium ?? false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    nameSection

                    purposeSection

                    if habit.habitTrackingType == .timed {
                        timedTargetSection
                    }

                    if habit.habitTrackingType == .count {
                        countTargetSection
                    }

                    DayOfWeekPicker(selectedDays: $activeDays, isAbstain: habit.habitTrackingType == .abstain)

                    anchoringSection
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
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(TributeColor.softGold)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .foregroundStyle(TributeColor.golden)
                        .fontWeight(.semibold)
                        .disabled(habitName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showPurposePaywall) {
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
        .preferredColorScheme(.dark)
        .onAppear { loadCurrentValues() }
    }

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: habit.habitCategory.iconName)
                .font(.system(size: 18))
                .foregroundStyle(habit.habitTrackingType == .abstain ? TributeColor.warmCoral : TributeColor.golden)
            Text(habit.habitCategory.rawValue)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(TributeColor.softGold.opacity(0.7))
            Spacer()
            Text(habit.habitTrackingType.rawValue.capitalized)
                .font(.caption.weight(.medium))
                .foregroundStyle(TributeColor.softGold.opacity(0.5))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(TributeColor.surfaceOverlay)
                .clipShape(Capsule())
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Habit Name")
                .font(.caption.weight(.medium))
                .foregroundStyle(TributeColor.softGold.opacity(0.6))

            if habit.isBuiltIn {
                Text(habitName)
                    .font(.body)
                    .foregroundStyle(.primary.opacity(0.6))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TributeColor.surfaceOverlay)
                    .clipShape(.rect(cornerRadius: 10))
            } else {
                TextField("Habit name", text: $habitName)
                    .font(.body)
                    .padding(12)
                    .background(TributeColor.surfaceOverlay)
                    .clipShape(.rect(cornerRadius: 10))
            }
        }
    }

    private var purposeSection: some View {
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
    }

    private var timedTargetSection: some View {
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

    private var countTargetSection: some View {
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

                TextField("Unit", text: $targetUnit)
                    .font(.subheadline)
                    .padding(10)
                    .background(TributeColor.surfaceOverlay)
                    .clipShape(.rect(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    private var anchoringSection: some View {
        if habit.habitTrackingType == .abstain {
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

                let suggestions = triggerChips(for: habit.habitCategory)
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
        default: return ["In the morning", "After lunch", "Before bed"]
        }
    }

    private func loadCurrentValues() {
        habitName = habit.name
        purposeStatement = habit.purposeStatement
        dailyTarget = habit.dailyTarget
        targetUnit = habit.targetUnit
        activeDays = habit.activeDaySet
        trigger = habit.trigger
        copingPlan = habit.copingPlan
    }

    private func saveChanges() {
        let trimmedName = habitName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if !habit.isBuiltIn {
            habit.name = trimmedName
        }
        if isPremium {
            habit.purposeStatement = purposeStatement
        }
        habit.dailyTarget = dailyTarget
        habit.targetUnit = targetUnit
        habit.activeDaySet = activeDays
        habit.trigger = trigger
        habit.copingPlan = copingPlan

        dismiss()
    }
}
