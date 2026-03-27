import SwiftUI

enum TributeColor {
    static let charcoal = Color(hex: "1E1E2E")
    static let warmWhite = Color(hex: "FAF7F2")
    static let golden = Color(hex: "D4A843")
    static let sage = Color(hex: "7A9E7E")
    static let warmCoral = Color(hex: "D4836B")
    static let softGold = Color(hex: "E8D5A3")
    static let mutedSage = Color(hex: "C5D8C7")

    static let cardBackground = Color(hex: "262638")
    static let cardBackgroundLight = Color(hex: "F0EDE6")

    static let cardBorder = Color.white.opacity(0.06)

    static let surfaceOverlay = Color.white.opacity(0.04)
    static let inputBackground = Color.white.opacity(0.1)

    static let goldenGradient = LinearGradient(
        colors: [Color(hex: "D4A843"), Color(hex: "E8D5A3")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGlow = RadialGradient(
        colors: [
            Color(hex: "D4A843").opacity(0.12),
            Color(hex: "D4A843").opacity(0.04),
            Color.clear
        ],
        center: .top,
        startRadius: 0,
        endRadius: 300
    )
}

struct TributeCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(TributeColor.cardBackground)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
            )
    }
}

struct TributeButtonStyle: ViewModifier {
    var color: Color = TributeColor.golden

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TributeColor.charcoal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .clipShape(.rect(cornerRadius: 12))
    }
}

extension View {
    func tributeCard() -> some View {
        modifier(TributeCardStyle())
    }

    func tributeButton(color: Color = TributeColor.golden) -> some View {
        modifier(TributeButtonStyle(color: color))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
