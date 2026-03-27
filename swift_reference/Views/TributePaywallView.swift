import SwiftUI
import RevenueCat

struct TributePaywallView: View {
    let store: StoreViewModel
    var contextTitle: String?
    var contextMessage: String?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PlanType = .yearly
    @State private var showContent: Bool = false
    @State private var purchaseSuccess: Bool = false

    private enum PlanType {
        case monthly, yearly
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    if let title = contextTitle {
                        contextSection(title: title, message: contextMessage)
                    }

                    planCards
                    featuresSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }

            bottomSection
        }
        .background(TributeColor.charcoal)
        .presentationDragIndicator(.visible)
        .presentationBackground(TributeColor.charcoal)
        .opacity(showContent ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
        .alert("Error", isPresented: .init(
            get: { store.error != nil },
            set: { if !$0 { store.error = nil } }
        )) {
            Button("OK") { store.error = nil }
        } message: {
            Text(store.error ?? "")
        }
        .onChange(of: store.isPremium) { _, isPremium in
            if isPremium {
                purchaseSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            }
        }
        .sensoryFeedback(.success, trigger: purchaseSuccess)
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [TributeColor.golden.opacity(0.2), TributeColor.golden.opacity(0.04)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "crown.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(TributeColor.golden)
            }

            Text("Tribute Pro")
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(.primary)

            Text("Go deeper in your walk with God.")
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func contextSection(title: String, message: String?) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(TributeColor.golden)
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(TributeColor.golden.opacity(0.06))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(TributeColor.golden.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var planCards: some View {
        HStack(spacing: 12) {
            if let monthly = store.monthlyPackage {
                planCard(
                    title: "Monthly",
                    price: monthly.storeProduct.localizedPriceString,
                    subtitle: "per month",
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

                planCard(
                    title: "Yearly",
                    price: annual.storeProduct.localizedPriceString,
                    subtitle: "\(monthlyStr)/mo",
                    isSelected: selectedPlan == .yearly,
                    badge: store.monthlySavingsText
                ) {
                    selectedPlan = .yearly
                }
            }
        }
    }

    private func planCard(
        title: String,
        price: String,
        subtitle: String,
        isSelected: Bool,
        badge: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(TributeColor.charcoal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(TributeColor.golden)
                        .clipShape(Capsule())
                } else {
                    Spacer().frame(height: 19)
                }

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? TributeColor.golden : .secondary)
                    .tracking(0.5)

                Text(price)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(isSelected ? TributeColor.golden.opacity(0.08) : TributeColor.cardBackground)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? TributeColor.golden.opacity(0.4) : TributeColor.cardBorder,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let features: [(icon: String, text: String)] = [
                ("infinity", "Unlimited habits"),
                ("shield.fill", "SOS temptation support"),
                ("chart.bar.fill", "Detailed analytics & insights"),
                ("text.quote", "Custom purpose statements"),
                ("calendar.badge.clock", "52-week Year in Tribute heatmap"),
                ("bell.badge.fill", "Smart reminders"),
            ]

            ForEach(features, id: \.text) { feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(TributeColor.golden)
                        .frame(width: 22)

                    Text(feature.text)
                        .font(.subheadline)
                        .foregroundStyle(TributeColor.softGold)
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
    }

    private var bottomSection: some View {
        VStack(spacing: 12) {
            if purchaseSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(TributeColor.sage)
                    Text("Welcome to Tribute Pro")
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundStyle(TributeColor.sage)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .transition(.opacity)
            } else {
                Button {
                    Task {
                        let pkg = selectedPlan == .yearly ? store.annualPackage : store.monthlyPackage
                        if let pkg { await store.purchase(package: pkg) }
                    }
                } label: {
                    Group {
                        if store.isPurchasing {
                            ProgressView()
                                .tint(TributeColor.charcoal)
                        } else {
                            Text("Continue")
                        }
                    }
                    .tributeButton()
                }
                .disabled(store.isPurchasing || store.isLoading)

                HStack(spacing: 16) {
                    Button {
                        Task { await store.restore() }
                    } label: {
                        Text("Restore Purchases")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button { dismiss() } label: {
                        Text("Not now")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .padding(.top, 12)
    }
}
