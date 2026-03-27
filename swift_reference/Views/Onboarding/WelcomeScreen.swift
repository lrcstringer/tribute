import SwiftUI

struct WelcomeScreen: View {
    let onContinue: () -> Void

    @State private var showGlow: Bool = false
    @State private var showTitle: Bool = false
    @State private var showTagline: Bool = false
    @State private var showVerse: Bool = false
    @State private var showButton: Bool = false
    @State private var breathe: Bool = false

    var body: some View {
        ZStack {
            TributeColor.charcoal.ignoresSafeArea()

            RadialGradient(
                colors: [
                    TributeColor.golden.opacity(showGlow ? 0.18 : 0),
                    TributeColor.golden.opacity(showGlow ? 0.06 : 0),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.65),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.0), value: showGlow)

            EmberParticleView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(breathe ? 0.12 : 0.04),
                                        TributeColor.golden.opacity(breathe ? 0.25 : 0.08),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: breathe ? 120 : 80
                                )
                            )
                            .frame(width: 280, height: 280)
                            .blur(radius: 40)

                        Text("TRIBUTE")
                            .font(.system(size: 52, weight: .bold, design: .serif))
                            .tracking(8)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [TributeColor.warmWhite, TributeColor.softGold],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: TributeColor.golden.opacity(breathe ? 0.9 : 0.4), radius: breathe ? 35 : 18)
                            .shadow(color: TributeColor.golden.opacity(breathe ? 0.5 : 0.15), radius: breathe ? 70 : 35)
                    }
                    .opacity(showTitle ? 1 : 0)
                    .scaleEffect(showTitle ? 1 : 0.8)

                    Text("Track your habits. Give them to God.")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(TributeColor.softGold.opacity(0.85))
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 8)

                    VStack(spacing: 8) {
                        Text("\u{201C}Offer your bodies as a living sacrifice, holy and pleasing to God \u{2014} this is your true and proper worship.\u{201D}")
                            .font(.system(.subheadline, design: .serif))
                            .italic()
                            .foregroundStyle(TributeColor.softGold.opacity(0.55))
                            .multilineTextAlignment(.center)

                        Text("Romans 12:1")
                            .font(.caption)
                            .foregroundStyle(TributeColor.golden.opacity(0.45))
                    }
                    .padding(.top, 8)
                    .opacity(showVerse ? 1 : 0)
                    .offset(y: showVerse ? 0 : 10)
                }
                .padding(.horizontal, 40)

                Spacer()

                Button {
                    onContinue()
                } label: {
                    HStack(spacing: 8) {
                        Text("Let\u{2019}s begin")
                        Image(systemName: "arrow.right")
                            .font(.subheadline)
                    }
                    .tributeButton()
                }
                .padding(.horizontal, 40)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 16)

                Spacer().frame(height: 56)
            }
        }
        .allowsHitTesting(true)
        .onAppear {
            withAnimation(.easeIn(duration: 1.5).delay(0.3)) {
                showGlow = true
            }

            withAnimation(.spring(duration: 0.9, bounce: 0.25).delay(0.6)) {
                showTitle = true
            }

            withAnimation(.easeOut(duration: 0.7).delay(1.0)) {
                showTagline = true
            }

            withAnimation(.easeOut(duration: 0.7).delay(1.4)) {
                showVerse = true
            }

            withAnimation(.easeOut(duration: 0.6).delay(1.8)) {
                showButton = true
            }

            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}
