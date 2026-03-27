import SwiftUI

struct HabitSelectionScreen: View {
    let onSelect: (HabitCategory) -> Void

    @State private var showScrollHint: Bool = true
    @State private var hasScrolled: Bool = false

    private let categories: [HabitCategory] = [
        .exercise, .scripture, .rest, .fasting, .study, .service, .connection, .health
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Now pick your\nown habit.")
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("Gratitude is set. What else do you want to give to God this season?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Pick 1 to start. You can add more later.")
                            .font(.caption)
                            .foregroundStyle(TributeColor.softGold.opacity(0.6))
                    }

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                onSelect(category)
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: category.iconName)
                                        .font(.system(size: 26))
                                        .foregroundStyle(TributeColor.golden)

                                    Text(category.rawValue)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)

                                    Text(category.defaultPurpose)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .padding(.horizontal, 8)
                                .background(TributeColor.cardBackground)
                                .clipShape(.rect(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        onSelect(.abstain)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(TributeColor.warmCoral)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("I'm letting go of something")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("Break a bad habit with God's help")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(TributeColor.cardBackground)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(TributeColor.warmCoral.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onSelect(.custom)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20))
                                .foregroundStyle(TributeColor.golden)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Something else entirely")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("Create a fully custom habit")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(TributeColor.cardBackground)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(TributeColor.golden.opacity(0.15), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.visible)
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, newOffset in
                if newOffset > 10 && !hasScrolled {
                    hasScrolled = true
                    withAnimation(.easeOut(duration: 0.3)) {
                        showScrollHint = false
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showScrollHint {
                    VStack(spacing: 4) {
                        Text("Scroll for more")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(TributeColor.softGold.opacity(0.5))
                        Image(systemName: "chevron.compact.down")
                            .font(.caption)
                            .foregroundStyle(TributeColor.softGold.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [TributeColor.charcoal.opacity(0), TributeColor.charcoal.opacity(0.95), TributeColor.charcoal],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 60)
                    )
                    .transition(.opacity)
                    .allowsHitTesting(false)
                }
            }
        }
    }
}
