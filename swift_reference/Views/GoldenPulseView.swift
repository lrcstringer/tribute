import SwiftUI

struct GoldenPulseView: View {
    var dimmed: Bool = false

    @State private var animate: Bool = false

    private var opacity: Double { dimmed ? 0.5 : 1.0 }

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                TributeColor.golden.opacity(0.5 * opacity),
                                TributeColor.softGold.opacity(0.2 * opacity),
                                TributeColor.softGold.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .scaleEffect(animate ? 2.5 : 0.3)
                    .opacity(animate ? 0 : 0.7)
                    .animation(
                        .easeOut(duration: 1.2)
                            .delay(Double(index) * 0.15),
                        value: animate
                    )
            }

            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(TributeColor.golden)
                .scaleEffect(animate ? 1 : 0.5)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: animate)
        }
        .frame(width: 160, height: 160)
        .onAppear {
            animate = true
        }
    }
}
