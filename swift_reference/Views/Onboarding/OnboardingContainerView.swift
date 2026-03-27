import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    let store: StoreViewModel
    let onComplete: () -> Void

    @State private var currentStep: Int = 0
    @State private var identitySelections: [String] = []
    @State private var gratitudeNote: String?
    @State private var selectedCategory: HabitCategory?
    @State private var customHabitName: String = ""
    @State private var customPurpose: String = ""
    @State private var customTrackingType: HabitTrackingType = .checkIn
    @State private var customDailyTarget: Double = 1
    @State private var customTargetUnit: String = ""
    @State private var customTrigger: String = ""
    @State private var customCopingPlan: String = ""
    @State private var customActiveDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]

    private let totalSteps: Int = 11

    var body: some View {
        ZStack {
            TributeColor.charcoal.ignoresSafeArea()
            TributeColor.warmGlow.ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 0) {
                if currentStep > 0 && currentStep < totalSteps - 1 {
                    HStack {
                        if currentStep > 1 {
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep -= 1
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(TributeColor.softGold.opacity(0.6))
                                    .frame(width: 44, height: 44)
                            }
                        } else {
                            Spacer().frame(width: 44)
                        }

                        Spacer()

                        progressDots

                        Spacer()

                        Spacer().frame(width: 44)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }

                screenContent
                    .allowsHitTesting(true)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(1..<(totalSteps - 1), id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? TributeColor.golden : Color.white.opacity(0.15))
                    .frame(width: step == currentStep ? 8 : 6, height: step == currentStep ? 8 : 6)
                    .animation(.easeInOut(duration: 0.25), value: currentStep)
            }
        }
    }

    @ViewBuilder
    private var screenContent: some View {
        switch currentStep {
        case 0:
            WelcomeScreen {
                advance()
            }

        case 1:
            IdentityScreen(
                onContinue: { selections in
                    identitySelections = selections
                    UserDefaults.standard.set(selections, forKey: "tribute_identity_selections")
                    advance()
                },
                onSkip: {
                    advance()
                }
            )

        case 2:
            ReframeScreen {
                advance()
            }

        case 3:
            FirstGratitudeScreen { note in
                gratitudeNote = note
                createGratitudeHabit(note: note)
                advance()
            }

        case 4:
            HabitSelectionScreen { category in
                selectedCategory = category
                advance()
            }

        case 5:
            if let category = selectedCategory {
                HabitSetupScreen(category: category) { name, purpose, tracking, target, unit, trigger, copingPlan, days in
                    customHabitName = name
                    customPurpose = purpose
                    customTrackingType = tracking
                    customDailyTarget = target
                    customTargetUnit = unit
                    customTrigger = trigger
                    customCopingPlan = copingPlan
                    customActiveDays = days
                    advance()
                }
            }

        case 6:
            if let category = selectedCategory {
                HabitSummaryScreen(
                    habitName: customHabitName,
                    habitCategory: category,
                    trackingType: customTrackingType,
                    purposeStatement: customPurpose,
                    dailyTarget: customDailyTarget,
                    targetUnit: customTargetUnit,
                    activeDays: customActiveDays
                ) {
                    createCustomHabit()
                    advance()
                }
            }

        case 7:
            CoreMechanicsScreen {
                advance()
            }

        case 8:
            NotificationPreferencesScreen {
                advance()
            }

        case 9:
            PaywallScreen(store: store) {
                advance()
            }

        case 10:
            DedicationCeremonyScreen(
                gratitudeNote: gratitudeNote,
                habitName: customHabitName,
                habitCategory: selectedCategory ?? .gratitude
            ) {
                onComplete()
            }

        default:
            EmptyView()
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }

    private func createGratitudeHabit(note: String?) {
        let hasGratitude = habits.contains { $0.isBuiltIn && $0.habitCategory == .gratitude }
        guard !hasGratitude else { return }

        let gratitude = Habit(
            name: "Daily Gratitude",
            category: .gratitude,
            trackingType: .checkIn,
            purposeStatement: "Give thanks in all circumstances; for this is God's will for you in Christ Jesus.",
            isBuiltIn: true,
            sortOrder: 0
        )
        modelContext.insert(gratitude)

        let entry = HabitEntry(date: Calendar.current.startOfDay(for: Date()), value: 1, isCompleted: true, gratitudeNote: note)
        entry.habit = gratitude
        gratitude.entries.append(entry)
        modelContext.insert(entry)
    }

    private func createCustomHabit() {
        guard let category = selectedCategory else { return }
        let habit = Habit(
            name: customHabitName,
            category: category,
            trackingType: customTrackingType,
            purposeStatement: customPurpose,
            dailyTarget: customDailyTarget,
            targetUnit: customTargetUnit,
            sortOrder: 1,
            activeDays: customActiveDays,
            trigger: customTrigger,
            copingPlan: customCopingPlan
        )
        modelContext.insert(habit)
    }
}
