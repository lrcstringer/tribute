import SwiftUI

struct FirstGratitudeScreen: View {
    let onComplete: (String?) -> Void

    @State private var gratitudeText: String = ""
    @State private var hasCompleted: Bool = false
    @State private var showPulse: Bool = false
    @State private var showResult: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Every journey starts\nwith gratitude.")
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("Your first habit is already set \u{2014} a daily moment to thank God for something. It takes a few seconds. It changes everything.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !hasCompleted {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Let's do your first one right now.")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(TributeColor.softGold)

                            Text("What's one thing you're grateful to God for today?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextField("Something you're thankful for...", text: $gratitudeText, axis: .vertical)
                                .font(.subheadline)
                                .lineLimit(2...4)
                                .padding(14)
                                .background(TributeColor.surfaceOverlay)
                                .clipShape(.rect(cornerRadius: 12))

                            Button {
                                completeGratitude()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "heart.fill")
                                        .font(.subheadline)
                                    Text(gratitudeText.trimmingCharacters(in: .whitespaces).isEmpty ? "Thank you, God" : "Give thanks")
                                }
                                .tributeButton()
                            }
                        }
                    }

                    if hasCompleted {
                        VStack(spacing: 24) {
                            ZStack {
                                if showPulse {
                                    GoldenPulseView()
                                        .allowsHitTesting(false)
                                }

                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [
                                                        TributeColor.golden.opacity(0.3),
                                                        TributeColor.golden.opacity(0.08)
                                                    ],
                                                    center: .center,
                                                    startRadius: 0,
                                                    endRadius: 40
                                                )
                                            )
                                            .frame(width: 72, height: 72)

                                        Image(systemName: "hands.sparkles.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(TributeColor.golden)
                                    }

                                    Text("1")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundStyle(TributeColor.golden)

                                    Text("day of gratitude")
                                        .font(.system(.subheadline, design: .serif))
                                        .foregroundStyle(TributeColor.softGold)
                                }
                                .opacity(showResult ? 1 : 0)
                                .scaleEffect(showResult ? 1 : 0.9)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)

                            Text("That's your first tribute. It's received.")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .opacity(showResult ? 1 : 0)

                            VStack(spacing: 6) {
                                Text("\"Give thanks in all circumstances; for this is God's will for you in Christ Jesus.\"")
                                    .font(.system(.subheadline, design: .serif))
                                    .italic()
                                    .foregroundStyle(TributeColor.softGold.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                Text("1 Thessalonians 5:18")
                                    .font(.caption)
                                    .foregroundStyle(TributeColor.golden.opacity(0.5))
                            }
                            .opacity(showResult ? 1 : 0)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            if hasCompleted {
                Button {
                    let note = gratitudeText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : gratitudeText
                    onComplete(note)
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                            .font(.subheadline)
                    }
                    .tributeButton()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .opacity(showResult ? 1 : 0)
            }
        }
        .sensoryFeedback(.success, trigger: showPulse)
    }

    private func completeGratitude() {
        withAnimation(.easeInOut(duration: 0.5)) {
            hasCompleted = true
            showPulse = true
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            showResult = true
        }

        Task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation { showPulse = false }
        }
    }
}
