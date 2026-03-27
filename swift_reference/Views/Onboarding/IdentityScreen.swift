import SwiftUI

struct IdentityScreen: View {
    let onContinue: ([String]) -> Void
    let onSkip: () -> Void

    @State private var selectedOptions: Set<String> = []

    private let options: [(id: String, label: String, icon: String)] = [
        ("body", "Taking better care of my body", "figure.run"),
        ("word", "Getting into God's Word more", "book.fill"),
        ("breaking", "Breaking a habit that's holding me back", "shield.fill"),
        ("rest", "Learning to actually rest", "moon.fill"),
        ("discipline", "Building discipline as an act of worship", "flame.fill"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What's God working on\nin your life right now?")
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("This helps us personalise your verses and encouragement.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 10) {
                        ForEach(options, id: \.id) { option in
                            Button {
                                withAnimation(.snappy(duration: 0.25)) {
                                    if selectedOptions.contains(option.id) {
                                        selectedOptions.remove(option.id)
                                    } else {
                                        selectedOptions.insert(option.id)
                                    }
                                }
                            } label: {
                                let isSelected = selectedOptions.contains(option.id)
                                HStack(spacing: 14) {
                                    Image(systemName: option.icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(isSelected ? TributeColor.golden : TributeColor.softGold.opacity(0.6))
                                        .frame(width: 24)

                                    Text(option.label)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(isSelected ? .primary : .secondary)

                                    Spacer()

                                    ZStack {
                                        Circle()
                                            .strokeBorder(isSelected ? TributeColor.golden : Color.white.opacity(0.15), lineWidth: 1.5)
                                            .frame(width: 22, height: 22)

                                        if isSelected {
                                            Circle()
                                                .fill(TributeColor.golden)
                                                .frame(width: 14, height: 14)
                                        }
                                    }
                                }
                                .padding(16)
                                .background(isSelected ? TributeColor.golden.opacity(0.08) : TributeColor.cardBackground)
                                .clipShape(.rect(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(isSelected ? TributeColor.golden.opacity(0.3) : TributeColor.cardBorder, lineWidth: 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            VStack(spacing: 12) {
                Button {
                    onContinue(Array(selectedOptions))
                } label: {
                    HStack(spacing: 8) {
                        Text("That's me")
                        Image(systemName: "arrow.right")
                            .font(.subheadline)
                    }
                    .tributeButton()
                }
                .disabled(selectedOptions.isEmpty)
                .opacity(selectedOptions.isEmpty ? 0.5 : 1)

                Button {
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
