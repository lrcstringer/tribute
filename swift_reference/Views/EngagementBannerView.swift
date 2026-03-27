import SwiftUI

struct EngagementBannerView: View {
    let message: EngagementMessage
    let onDismiss: () -> Void
    var onPaywallTap: (() -> Void)? = nil

    @State private var showContent: Bool = false

    private var accentColor: Color {
        switch message.accent {
        case .golden: return TributeColor.golden
        case .sage: return TributeColor.sage
        }
    }

    private var hasPaywall: Bool {
        message.paywallContext != nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: message.icon)
                .font(.system(size: 18))
                .foregroundStyle(accentColor)
                .frame(width: 28, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(message.title)
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundStyle(.primary)

                    if hasPaywall {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                            Text("PRO")
                                .font(.system(size: 8, weight: .bold))
                                .tracking(0.3)
                        }
                        .foregroundStyle(TributeColor.golden)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(TributeColor.golden.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                Text(message.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if hasPaywall {
                    Text("Tap to learn more")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(accentColor.opacity(0.7))
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 4)

            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    showContent = false
                }
                Task {
                    try? await Task.sleep(for: .seconds(0.25))
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(accentColor.opacity(0.06))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(accentColor.opacity(0.15), lineWidth: 0.5)
        )
        .contentShape(.rect)
        .onTapGesture {
            if hasPaywall {
                onPaywallTap?()
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : -8)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
                showContent = true
            }
        }
    }
}
