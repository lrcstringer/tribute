import SwiftUI

struct SOSView: View {
    let habit: Habit

    @State private var milestoneService = MilestoneService()
    @State private var microActionCompleted: Bool = false
    @State private var showPrayerCircleMessage: Bool = false
    @State private var showCirclePicker: Bool = false
    @State private var circles: [CircleListItem] = []
    @State private var isLoadingCircles: Bool = false
    @State private var pulseShield: Bool = false
    @Environment(\.dismiss) private var dismiss

    private var microActions: [String] {
        switch habit.habitCategory {
        case .exercise:
            return [
                "Just do the first 5 minutes.",
                "Do 10 pushups to reset your headspace.",
                "Step outside and walk for 2 minutes."
            ]
        case .scripture:
            return [
                "Open to any page. Read one verse.",
                "Pray for 60 seconds. Just talk to Him.",
                "Write down one thing God has done for you."
            ]
        case .rest:
            return [
                "Put your phone down for 5 minutes.",
                "Close your eyes and breathe for 60 seconds.",
                "Tell God what's keeping you up."
            ]
        case .abstain:
            return [
                "Pray for 60 seconds. Tell God what you're feeling.",
                "Do 10 pushups to reset your headspace.",
                "Text someone you trust right now.",
                "Step outside. Change your environment."
            ]
        case .fasting:
            return [
                "Drink a glass of water slowly.",
                "Pray for 60 seconds. Offer the hunger to God.",
                "Read one verse about God's provision."
            ]
        case .study:
            return [
                "Just open the book. Read one page.",
                "Set a 5-minute timer. That's all.",
                "Write down why you started this."
            ]
        case .service:
            return [
                "Send one encouraging text to someone.",
                "Pray for someone specific right now.",
                "Do one small act of kindness today."
            ]
        case .connection:
            return [
                "Reach out to one person right now.",
                "Pray for someone you haven't talked to.",
                "Send a simple 'thinking of you' message."
            ]
        case .health:
            return [
                "Drink a glass of water right now.",
                "Fill your bottle and take three sips.",
                "Set a timer for your next glass."
            ]
        case .custom:
            return [
                "Just start. Do the smallest version of this.",
                "Pray for 60 seconds. Ask God for strength.",
                "Remember why you committed to this."
            ]
        case .gratitude:
            return ["Thank God for one thing right now."]
        }
    }

    private var selectedMicroAction: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % microActions.count
        return microActions[index]
    }

    private var milestoneShieldMessage: String {
        switch habit.habitTrackingType {
        case .abstain:
            let consecutive = milestoneService.consecutiveCleanDays(for: habit)
            let total = habit.totalCompletedDays()
            let nextMilestone = nextMilestoneTarget(current: consecutive, thresholds: [7, 14, 30, 60, 90, 180, 365])
            var message = ""
            if consecutive > 0 {
                message = "You've been going strong for \(consecutive) day\(consecutive == 1 ? "" : "s")."
                if let next = nextMilestone {
                    let remaining = next - consecutive
                    message += " You're just \(remaining) day\(remaining == 1 ? "" : "s") from \(next) days. That's worth protecting."
                }
            }
            if total > 0 && total != consecutive {
                message += "\n\nEven if today is hard, those \(total) total clean days still stand. They're not going anywhere."
            } else if consecutive > 0 {
                message += "\n\nBut even if today is hard, those \(consecutive) days still stand. They're not going anywhere."
            }
            return message.isEmpty ? "Every moment of strength matters. God sees you in this." : message

        case .timed:
            let totalMinutes = habit.totalValue()
            let hours = Int(totalMinutes) / 60
            let mins = Int(totalMinutes) % 60
            let timeStr = hours > 0 ? "\(hours) hour\(hours == 1 ? "" : "s") and \(mins) minute\(mins == 1 ? "" : "s")" : "\(mins) minute\(mins == 1 ? "" : "s")"
            if totalMinutes > 0 {
                return "You've given \(timeStr) to God through \(habit.name.lowercased()). That's real. That's yours. Keep going."
            }
            return "Every minute you give matters. Start with just one."

        case .count:
            let total = Int(habit.totalValue())
            let unit = habit.targetUnit.isEmpty ? "times" : habit.targetUnit
            if total > 0 {
                return "You've reached \(total) \(unit). Every single one counted. Keep building."
            }
            return "Every one counts. Start with just one."

        case .checkIn:
            let days = habit.totalCompletedDays()
            if days > 0 {
                let nextTarget = nextMilestoneTarget(current: days, thresholds: [7, 30, 100, 365])
                var message = "\(days) day\(days == 1 ? "" : "s") of showing up. That's faithfulness."
                if let next = nextTarget {
                    let remaining = next - days
                    message += " You're \(remaining) day\(remaining == 1 ? "" : "s") from \(next). Worth protecting."
                }
                return message
            }
            return "Showing up matters. Even today."
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                shieldHeader
                refocusSection
                if !habit.copingPlan.isEmpty {
                    copingPlanSection
                }
                bridgeSection
                milestoneShieldSection
                prayerCircleSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(TributeColor.charcoal)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(TributeColor.charcoal)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseShield = true
            }
        }
    }

    private var shieldHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                TributeColor.sage.opacity(pulseShield ? 0.3 : 0.15),
                                TributeColor.sage.opacity(pulseShield ? 0.08 : 0.02)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "shield.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(TributeColor.sage)
                    .symbolEffect(.pulse, value: pulseShield)
            }

            Text("You reached out. That takes courage.")
                .font(.system(.headline, design: .serif))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text("Let's take this one moment at a time.")
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var refocusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Your Why", systemImage: "heart.fill")
                .font(.system(.caption, design: .serif, weight: .semibold))
                .foregroundStyle(TributeColor.golden)

            Text(habit.purposeStatement)
                .font(.system(.body, design: .serif))
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            let verse = ScriptureLibrary.anchorVerse(for: habit.habitCategory)
            VStack(spacing: 4) {
                Text("\u{201C}\(verse.text)\u{201D}")
                    .font(.system(.subheadline, design: .serif))
                    .italic()
                    .foregroundStyle(TributeColor.softGold.opacity(0.7))
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(verse.reference)
                    .font(.caption)
                    .foregroundStyle(TributeColor.golden.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(TributeColor.cardBackground)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(TributeColor.golden.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var copingPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your Plan for Moments Like This", systemImage: "shield.checkered")
                .font(.system(.caption, design: .serif, weight: .semibold))
                .foregroundStyle(TributeColor.warmCoral)

            Text(habit.copingPlan)
                .font(.system(.title3, design: .serif, weight: .medium))
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("You wrote this when you were strong. Trust that version of yourself.")
                .font(.system(.caption, design: .serif))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(TributeColor.warmCoral.opacity(0.06))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(TributeColor.warmCoral.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var bridgeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("A Small Step Right Now", systemImage: "figure.walk")
                .font(.system(.caption, design: .serif, weight: .semibold))
                .foregroundStyle(TributeColor.sage)

            Text(selectedMicroAction)
                .font(.system(.title3, design: .serif, weight: .medium))
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            if microActionCompleted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(TributeColor.sage)
                    Text("You did it. That moment of strength matters.")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(TributeColor.sage)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        microActionCompleted = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.subheadline)
                        Text("Did it")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TributeColor.charcoal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(TributeColor.sage)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .sensoryFeedback(.success, trigger: microActionCompleted)
            }
        }
        .padding(16)
        .background(TributeColor.sage.opacity(0.06))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(TributeColor.sage.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var milestoneShieldSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("What You're Protecting", systemImage: "shield.lefthalf.filled")
                .font(.system(.caption, design: .serif, weight: .semibold))
                .foregroundStyle(TributeColor.golden)

            let stat = milestoneService.lifetimeStat(for: habit)
            HStack(spacing: 14) {
                Text(stat.primaryValue)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(TributeColor.golden)

                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.description)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(TributeColor.softGold)
                    if let detail = stat.detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(milestoneShieldMessage)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(.primary.opacity(0.85))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [TributeColor.golden.opacity(0.06), TributeColor.golden.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(TributeColor.golden.opacity(0.12), lineWidth: 0.5)
        )
    }

    private var prayerCircleSection: some View {
        VStack(spacing: 12) {
            if AuthenticationService.shared.isAuthenticated {
                Button {
                    Task { await loadCirclesAndShow() }
                } label: {
                    HStack(spacing: 8) {
                        if isLoadingCircles {
                            ProgressView()
                                .controlSize(.small)
                                .tint(TributeColor.softGold)
                        } else {
                            Image(systemName: "bolt.heart.fill")
                                .font(.subheadline)
                        }
                        Text("Send SOS prayer request")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TributeColor.warmCoral)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(TributeColor.warmCoral.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(TributeColor.warmCoral.opacity(0.2), lineWidth: 0.5)
                    )
                }
                .disabled(isLoadingCircles)
            } else {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        showPrayerCircleMessage = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.subheadline)
                        Text("Send a prayer request")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TributeColor.softGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(TributeColor.surfaceOverlay)
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                    )
                }

                if showPrayerCircleMessage {
                    Text("Sign in and join a Prayer Circle to send SOS prayer requests to your community.")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .sheet(isPresented: $showCirclePicker) {
            SOSCirclePickerView(circles: circles)
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
                .preferredColorScheme(.dark)
        }
    }

    private func loadCirclesAndShow() async {
        isLoadingCircles = true
        do {
            circles = try await APIService.shared.listCircles()
            if circles.isEmpty {
                withAnimation(.spring(duration: 0.3)) {
                    showPrayerCircleMessage = true
                }
            } else {
                showCirclePicker = true
            }
        } catch {
            withAnimation(.spring(duration: 0.3)) {
                showPrayerCircleMessage = true
            }
        }
        isLoadingCircles = false
    }

    private func nextMilestoneTarget(current: Int, thresholds: [Int]) -> Int? {
        thresholds.first { $0 > current }
    }
}
