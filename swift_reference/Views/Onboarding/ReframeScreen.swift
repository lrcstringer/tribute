import SwiftUI

struct ReframeScreen: View {
    let onContinue: () -> Void

    @State private var showLeft: Bool = false
    @State private var showRight: Bool = false
    @State private var showPoints: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Tribute works\na bit differently.")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        VStack(spacing: 12) {
                            Text("Other apps")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            VStack(spacing: 6) {
                                Text("Day 47")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundStyle(TributeColor.warmCoral)
                                    .strikethrough(true, color: TributeColor.warmCoral)

                                Text("Streak broken.")
                                    .font(.caption)
                                    .foregroundStyle(TributeColor.warmCoral.opacity(0.8))

                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(TributeColor.warmCoral.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(TributeColor.warmCoral.opacity(0.06))
                            .clipShape(.rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(TributeColor.warmCoral.opacity(0.15), lineWidth: 0.5)
                            )
                        }
                        .opacity(showLeft ? 1 : 0)
                        .offset(x: showLeft ? 0 : -20)

                        VStack(spacing: 12) {
                            Text("Tribute")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(TributeColor.golden)

                            VStack(spacing: 6) {
                                HStack(spacing: 4) {
                                    ForEach(0..<7, id: \.self) { i in
                                        Circle()
                                            .fill(i < 5 ? TributeColor.golden : Color.white.opacity(0.08))
                                            .frame(width: 14, height: 14)
                                    }
                                }

                                Text("5 out of 7")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(TributeColor.golden)

                                Text("Great week.")
                                    .font(.caption)
                                    .foregroundStyle(TributeColor.sage)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(TributeColor.golden.opacity(0.06))
                            .clipShape(.rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(TributeColor.golden.opacity(0.2), lineWidth: 0.5)
                            )
                        }
                        .opacity(showRight ? 1 : 0)
                        .offset(x: showRight ? 0 : 20)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        reframePoint(
                            icon: "heart.fill",
                            text: "Most apps track your performance. Tribute tracks what you're giving to God."
                        )
                        reframePoint(
                            icon: "arrow.trianglehead.2.clockwise",
                            text: "No streaks. Every week is a fresh start. 5 out of 7 is still a gift."
                        )
                        reframePoint(
                            icon: "hand.raised.fill",
                            text: "We'll never tell you that you failed. We'll meet you wherever you are."
                        )
                    }
                    .opacity(showPoints ? 1 : 0)
                    .offset(y: showPoints ? 0 : 10)

                    VStack(spacing: 6) {
                        Text("\"The steadfast love of the Lord never ceases; his mercies never come to an end; they are new every morning.\"")
                            .font(.system(.subheadline, design: .serif))
                            .italic()
                            .foregroundStyle(TributeColor.softGold.opacity(0.6))
                        Text("Lamentations 3:22-23")
                            .font(.caption)
                            .foregroundStyle(TributeColor.golden.opacity(0.5))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            Button {
                onContinue()
            } label: {
                HStack(spacing: 8) {
                    Text("Got it. Let's set up my habits")
                    Image(systemName: "arrow.right")
                        .font(.subheadline)
                }
                .tributeButton()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showLeft = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showRight = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                showPoints = true
            }
        }
    }

    private func reframePoint(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(TributeColor.golden)
                .frame(width: 20, alignment: .center)
                .padding(.top, 2)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
