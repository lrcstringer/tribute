import SwiftUI

struct MilestoneCelebrationView: View {
    let milestone: Milestone
    let onDismiss: () -> Void

    @State private var showContent: Bool = false
    @State private var showVerse: Bool = false
    @State private var burstScale: CGFloat = 0.3
    @State private var burstOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            ZStack {
                Circle()
                    .fill(TributeColor.golden.opacity(0.15))
                    .frame(width: 260, height: 260)
                    .scaleEffect(burstScale)
                    .opacity(burstOpacity)

                Circle()
                    .fill(TributeColor.golden.opacity(0.08))
                    .frame(width: 360, height: 360)
                    .scaleEffect(burstScale * 0.8)
                    .opacity(burstOpacity * 0.5)

                VStack(spacing: 20) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(TributeColor.golden)
                        .symbolEffect(.bounce, value: showContent)

                    Text("Milestone Reached")
                        .font(.system(.caption, design: .serif, weight: .semibold))
                        .foregroundStyle(TributeColor.softGold.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text(milestone.message)
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 24)

                    if showVerse, let verse = milestone.verse {
                        VStack(spacing: 4) {
                            Text("\u{201C}\(verse.text)\u{201D}")
                                .font(.system(.caption, design: .serif))
                                .italic()
                                .foregroundStyle(TributeColor.softGold.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                            Text(verse.reference)
                                .font(.caption2)
                                .foregroundStyle(TributeColor.golden.opacity(0.4))
                        }
                        .padding(.horizontal, 32)
                        .transition(.opacity)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TributeColor.charcoal)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(TributeColor.golden)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 8)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)
            }
        }
        .onAppear { startAnimations() }
        .sensoryFeedback(.success, trigger: showContent)
    }

    private func startAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            burstScale = 1.0
            burstOpacity = 1.0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            showContent = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            showVerse = true
        }
        withAnimation(.easeOut(duration: 1.5).delay(1.5)) {
            burstOpacity = 0.3
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            showContent = false
            burstOpacity = 0
        }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            onDismiss()
        }
    }
}
