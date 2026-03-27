import SwiftUI

struct DedicationCeremonyScreen: View {
    let gratitudeNote: String?
    let habitName: String
    let habitCategory: HabitCategory
    let onComplete: () -> Void

    @State private var showVerse: Bool = false
    @State private var showGratitudeTile: Bool = false
    @State private var showHabitTile: Bool = false
    @State private var showButton: Bool = false
    @State private var isDedicated: Bool = false
    @State private var showPulse: Bool = false
    @State private var showFinalMessage: Bool = false
    @State private var glowRadius: CGFloat = 100
    @State private var glowOpacity: Double = 0.08
    @State private var tilesGlow: Bool = false
    @State private var breathe: Bool = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    TributeColor.golden.opacity(glowOpacity),
                    TributeColor.softGold.opacity(glowOpacity * 0.4),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: glowRadius
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.5), value: glowRadius)
            .animation(.easeInOut(duration: 2.5), value: glowOpacity)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        if !isDedicated {
                            preOfferingContent
                        } else {
                            postOfferingContent
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }

                if !isDedicated && showButton {
                    Button {
                        performDedication()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "hands.sparkles.fill")
                                .font(.subheadline)
                            Text("Offer My Tribute")
                        }
                        .tributeButton()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if isDedicated && showFinalMessage {
                    Button {
                        onComplete()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Enter Tribute")
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
        .onAppear {
            startEntryAnimations()
        }
    }

    @ViewBuilder
    private var preOfferingContent: some View {
        VStack(spacing: 8) {
            Text("Your Tribute")
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(.primary)

            Text("Everything you\u{2019}ve set \u{2014} offered to God.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .opacity(showVerse ? 1 : 0)

        VStack(spacing: 14) {
            habitTile(
                icon: "hands.sparkles.fill",
                name: "Daily Gratitude",
                detail: "Check-in",
                accent: TributeColor.golden,
                isShowing: showGratitudeTile,
                isGlowing: tilesGlow
            )

            habitTile(
                icon: habitCategory.iconName,
                name: habitName,
                detail: habitCategory.rawValue,
                accent: habitCategory == .abstain ? TributeColor.warmCoral : TributeColor.golden,
                isShowing: showHabitTile,
                isGlowing: tilesGlow
            )
        }

        VStack(spacing: 6) {
            Text("\u{201C}Therefore, I urge you, brothers and sisters, in view of God\u{2019}s mercy, to offer your bodies as a living sacrifice, holy and pleasing to God \u{2014} this is your true and proper worship.\u{201D}")
                .font(.system(.subheadline, design: .serif))
                .italic()
                .foregroundStyle(TributeColor.softGold.opacity(0.6))
                .multilineTextAlignment(.center)
            Text("Romans 12:1")
                .font(.caption)
                .foregroundStyle(TributeColor.golden.opacity(0.5))
        }
        .padding(.top, 4)
        .opacity(showVerse ? 1 : 0)
    }

    @ViewBuilder
    private var postOfferingContent: some View {
        Spacer().frame(height: 40)

        ZStack {
            if showPulse {
                DedicationPulseView()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 20) {
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
                        .scaleEffect(breathe ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: breathe)

                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(TributeColor.golden)
                }

                Text("Your tribute is set.")
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Go in grace.")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(TributeColor.softGold)
            }
            .opacity(showFinalMessage ? 1 : 0)
            .scaleEffect(showFinalMessage ? 1 : 0.92)
        }
        .frame(maxWidth: .infinity)

        VStack(spacing: 6) {
            Text("\u{201C}The steadfast love of the Lord never ceases; his mercies never come to an end; they are new every morning.\u{201D}")
                .font(.system(.subheadline, design: .serif))
                .italic()
                .foregroundStyle(TributeColor.softGold.opacity(0.5))
                .multilineTextAlignment(.center)
            Text("Lamentations 3:22\u{2013}23")
                .font(.caption)
                .foregroundStyle(TributeColor.golden.opacity(0.4))
        }
        .opacity(showFinalMessage ? 1 : 0)
    }

    private func habitTile(icon: String, name: String, detail: String, accent: Color, isShowing: Bool, isGlowing: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accent.opacity(isGlowing ? 0.5 : 0.2),
                                accent.opacity(isGlowing ? 0.2 : 0.06)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 24
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(.headline, design: .serif))

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: isGlowing ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isGlowing ? TributeColor.golden : Color.white.opacity(0.15))
        }
        .padding(16)
        .background(isGlowing ? accent.opacity(0.08) : TributeColor.cardBackground)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isGlowing ? accent.opacity(0.3) : TributeColor.cardBorder, lineWidth: 0.5)
        )
        .opacity(isShowing ? 1 : 0)
        .offset(y: isShowing ? 0 : 12)
        .animation(.easeOut(duration: 0.4), value: isGlowing)
    }

    private func startEntryAnimations() {
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            showVerse = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            showGratitudeTile = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            showHabitTile = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(1.5)) {
            showButton = true
        }
    }

    private func performDedication() {
        withAnimation(.easeInOut(duration: 0.4)) {
            tilesGlow = true
        }

        withAnimation(.easeInOut(duration: 1.5)) {
            glowRadius = 350
            glowOpacity = 0.25
        }

        showPulse = true

        Task {
            try? await Task.sleep(for: .seconds(1.2))

            withAnimation(.easeInOut(duration: 0.6)) {
                isDedicated = true
                showButton = false
            }

            withAnimation(.easeInOut(duration: 1.0)) {
                glowRadius = 200
                glowOpacity = 0.12
            }

            try? await Task.sleep(for: .seconds(0.4))

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showFinalMessage = true
                breathe = true
            }

            try? await Task.sleep(for: .seconds(1.5))
            showPulse = false
        }
    }
}

struct DedicationPulseView: View {
    @State private var animate: Bool = false

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                TributeColor.golden.opacity(0.4),
                                TributeColor.softGold.opacity(0.15),
                                TributeColor.softGold.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .scaleEffect(animate ? 3 : 0.2)
                    .opacity(animate ? 0 : 0.6)
                    .animation(
                        .easeOut(duration: 1.5)
                            .delay(Double(index) * 0.2),
                        value: animate
                    )
            }
        }
        .frame(width: 200, height: 200)
        .onAppear {
            animate = true
        }
    }
}
