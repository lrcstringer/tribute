import SwiftUI

nonisolated struct Ember: Identifiable, Sendable {
    let id: Int
    let startX: Double
    let size: Double
    let opacity: Double
    let speed: Double
    let drift: Double
    let delay: Double
    let blur: Double
}

struct EmberParticleView: View {
    @State private var animate: Bool = false

    private let embers: [Ember] = (0..<20).map { i in
        Ember(
            id: i,
            startX: Double.random(in: 0.05...0.95),
            size: Double.random(in: 3...8),
            opacity: Double.random(in: 0.3...0.9),
            speed: Double.random(in: 6...14),
            drift: Double.random(in: -40...40),
            delay: Double.random(in: 0...3),
            blur: Double.random(in: 0.5...3)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(embers) { ember in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                TributeColor.golden.opacity(ember.opacity),
                                TributeColor.softGold.opacity(ember.opacity * 0.5),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: ember.size * 2
                        )
                    )
                    .frame(width: ember.size * 4, height: ember.size * 4)
                    .blur(radius: ember.blur)
                    .position(
                        x: geo.size.width * ember.startX + (animate ? ember.drift : 0),
                        y: animate ? -20 : geo.size.height + 20
                    )
                    .animation(
                        .linear(duration: ember.speed)
                        .delay(ember.delay)
                        .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            animate = true
        }
    }
}
