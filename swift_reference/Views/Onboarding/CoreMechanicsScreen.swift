import SwiftUI

struct CoreMechanicsScreen: View {
    let onContinue: () -> Void

    @State private var currentPanel: Int = 0
    @State private var counterValue: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPanel) {
                weeklyRhythmPanel.tag(0)
                timeAddsUpPanel.tag(1)
                prayerCirclesPanel.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPanel ? TributeColor.golden : Color.white.opacity(0.15))
                            .frame(width: index == currentPanel ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPanel)
                    }
                }

                if currentPanel == 2 {
                    Button(action: onContinue) {
                        Text("Continue")
                            .tributeButton()
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    HStack(spacing: 6) {
                        Text("Swipe to continue")
                            .font(.subheadline)
                            .foregroundStyle(TributeColor.softGold.opacity(0.5))
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(TributeColor.softGold.opacity(0.4))
                    }
                    .frame(height: 48)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentPanel)
            .padding(.bottom, 32)
        }
    }

    private var weeklyRhythmPanel: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Image(systemName: "calendar.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(TributeColor.golden)
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))

                VStack(spacing: 16) {
                    Text("Every week is an offering,\nnot a scorecard.")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TributeColor.softGold)
                        .multilineTextAlignment(.center)

                    Text("Every Sunday you set your intention. Monday through Saturday you check in — each one is a small gift to God. The next Sunday you look back. 5 out of 7? That's a beautiful week.")
                        .font(.body)
                        .foregroundStyle(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 8)

                verseFooter(
                    text: "Because of the Lord's great love we are not consumed, for his compassions never fail. They are new every morning; great is your faithfulness.",
                    reference: "Lamentations 3:22–23"
                )
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
    }

    private var timeAddsUpPanel: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Image(systemName: "chart.line.uptrend.xyaxis.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(TributeColor.golden)

                VStack(spacing: 16) {
                    Text("Every minute counts.\nEvery day counts.")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TributeColor.softGold)
                        .multilineTextAlignment(.center)

                    Text("Tribute tracks everything you give — minutes, reps, days. Not just today, but all of it. Over weeks and months you'll see something amazing build up. Different habits track differently: some by time, some by count, some just by showing up.")
                        .font(.body)
                        .foregroundStyle(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 8)

                animatedCounter

                verseFooter(
                    text: "Whatever you do, work at it with all your heart, as working for the Lord, not for human masters.",
                    reference: "Colossians 3:23"
                )
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .onChange(of: currentPanel) { _, newValue in
            if newValue == 1 {
                counterValue = 0
                withAnimation(.spring(duration: 2.0, bounce: 0.1)) {
                    counterValue = 247
                }
            }
        }
    }

    private var animatedCounter: some View {
        VStack(spacing: 4) {
            Text("\(Int(counterValue))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(TributeColor.golden)
                .contentTransition(.numericText(value: counterValue))
                .animation(.spring(duration: 2.0, bounce: 0.1), value: counterValue)

            Text("minutes given")
                .font(.subheadline)
                .foregroundStyle(TributeColor.softGold.opacity(0.6))
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(TributeColor.cardBackground)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(TributeColor.golden.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var prayerCirclesPanel: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(TributeColor.golden)

                VStack(spacing: 16) {
                    Text("You're not doing\nthis alone.")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TributeColor.softGold)
                        .multilineTextAlignment(.center)

                    Text("Invite 2–5 people you trust to form a Prayer Circle. You'll track together, see your group's combined progress on a shared heatmap, and — if you ever need it — ask for prayer with one tap. No details shared. Just prayer.")
                        .font(.body)
                        .foregroundStyle(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("Your circle sees the group's combined effort, not your individual habits. It's community without comparison.")
                        .font(.callout)
                        .foregroundStyle(Color.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 8)

                verseFooter(
                    text: "The prayer of a righteous person is powerful and effective.",
                    reference: "James 5:16"
                )
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
    }

    private func verseFooter(text: String, reference: String) -> some View {
        VStack(spacing: 8) {
            Text("\"\(text)\"")
                .font(.callout.italic())
                .foregroundStyle(TributeColor.softGold.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Text("— \(reference)")
                .font(.caption.weight(.medium))
                .foregroundStyle(TributeColor.golden.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}
