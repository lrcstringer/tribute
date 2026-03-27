import SwiftUI
import RevenueCat

struct PaywallScreen: View {
    let store: StoreViewModel
    let onContinue: () -> Void

    @State private var showContent: Bool = false
    @State private var showFeatures: Bool = false
    @State private var selectedPlan: PlanType = .yearly

    private enum PlanType {
        case monthly, yearly
    }

    private let freeFeatures: [(icon: String, text: String)] = [
        ("hands.sparkles.fill", "Daily Gratitude"),
        ("plus.circle", "2 Custom Habits"),
        ("calendar", "Weekly View"),
        ("book.fill", "Anchor Verses"),
    ]

    private let proFeatures: [(icon: String, text: String)] = [
        ("infinity", "Unlimited Habits"),
        ("text.quote", "Custom Purpose Statements"),
        ("chart.bar.fill", "Detailed Stats & Insights"),
        ("bell.badge.fill", "Smart Reminders"),
        ("shield.fill", "SOS Temptation Support"),
        ("sparkles", "52-Week Year in Tribute"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Text("Go deeper with\nTribute Pro")
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)

                        Text("Everything you need to build lasting habits rooted in faith.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(showContent ? 1 : 0)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("FREE")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .tracking(1.5)

                            ForEach(freeFeatures, id: \.text) { feature in
                                HStack(spacing: 10) {
                                    Image(systemName: feature.icon)
                                        .font(.system(size: 13))
                                        .foregroundStyle(TributeColor.softGold.opacity(0.5))
                                        .frame(width: 18)

                                    Text(feature.text)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(TributeColor.cardBackground)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                        )

                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 6) {
                                Text("PRO")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(TributeColor.golden)
                                    .tracking(1.5)

                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(TributeColor.golden)
                            }

                            ForEach(proFeatures, id: \.text) { feature in
                                HStack(spacing: 10) {
                                    Image(systemName: feature.icon)
                                        .font(.system(size: 13))
                                        .foregroundStyle(TributeColor.golden)
                                        .frame(width: 18)

                                    Text(feature.text)
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(TributeColor.golden.opacity(0.06))
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(TributeColor.golden.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .opacity(showFeatures ? 1 : 0)
                    .offset(y: showFeatures ? 0 : 12)

                    planSelector
                        .opacity(showFeatures ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            VStack(spacing: 12) {
                Button {
                    Task {
                        let pkg = selectedPlan == .yearly ? store.annualPackage : store.monthlyPackage
                        if let pkg {
                            await store.purchase(package: pkg)
                            if store.isPremium {
                                onContinue()
                            }
                        } else {
                            onContinue()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if store.isPurchasing {
                            ProgressView()
                                .tint(TributeColor.charcoal)
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.subheadline)
                            Text("Start Free Trial")
                        }
                    }
                    .tributeButton()
                }
                .disabled(store.isPurchasing)

                HStack(spacing: 16) {
                    Button {
                        Task { await store.restore() }
                    } label: {
                        Text("Restore")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        onContinue()
                    } label: {
                        Text("Continue with Free")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showFeatures = true
            }
        }
    }

    private var planSelector: some View {
        HStack(spacing: 12) {
            if let monthly = store.monthlyPackage {
                planOption(
                    title: "Monthly",
                    price: monthly.storeProduct.localizedPriceString,
                    detail: "per month",
                    isSelected: selectedPlan == .monthly,
                    badge: nil
                ) {
                    selectedPlan = .monthly
                }
            }

            if let annual = store.annualPackage {
                let monthlyEquiv = annual.storeProduct.price / 12
                let formatter = NumberFormatter()
                let _ = { formatter.numberStyle = .currency; formatter.locale = annual.storeProduct.priceFormatter?.locale ?? .current }()
                let monthlyStr = formatter.string(from: monthlyEquiv as NSDecimalNumber) ?? ""

                planOption(
                    title: "Yearly",
                    price: annual.storeProduct.localizedPriceString,
                    detail: "\(monthlyStr)/mo",
                    isSelected: selectedPlan == .yearly,
                    badge: store.monthlySavingsText
                ) {
                    selectedPlan = .yearly
                }
            }
        }
    }

    private func planOption(
        title: String,
        price: String,
        detail: String,
        isSelected: Bool,
        badge: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(TributeColor.charcoal)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(TributeColor.golden)
                        .clipShape(Capsule())
                } else {
                    Spacer().frame(height: 17)
                }

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? TributeColor.golden : .secondary)

                Text(price)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? TributeColor.golden.opacity(0.08) : TributeColor.cardBackground)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? TributeColor.golden.opacity(0.4) : TributeColor.cardBorder,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
