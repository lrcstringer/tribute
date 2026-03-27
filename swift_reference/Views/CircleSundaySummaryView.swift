import SwiftUI

struct CircleSundaySummaryView: View {
    let circleId: String
    let circleName: String

    @State private var summary: SundaySummaryResponse?
    @State private var isLoading: Bool = true
    @State private var error: String?
    @State private var gratitudeWeekCount: Int = 0

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let summary {
                    summaryContent(summary)
                } else if let error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await loadSummary() }
                        }
                        .foregroundStyle(TributeColor.golden)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationTitle("Weekly Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .task {
                await loadSummary()
                await loadGratitudeCount()
            }
        }
    }

    @ViewBuilder
    private func summaryContent(_ summary: SundaySummaryResponse) -> some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        TributeColor.golden.opacity(0.2),
                                        TributeColor.golden.opacity(0.05)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 80, height: 80)
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(TributeColor.golden)
                    }

                    Text(circleName)
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .foregroundStyle(TributeColor.warmWhite)

                    Text("This week's faithfulness")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(TributeColor.softGold.opacity(0.7))
                }
                .padding(.top, 8)

                HStack(spacing: 0) {
                    statCard(
                        value: "\(summary.activeMembers)",
                        label: "Active",
                        sublabel: "of \(summary.totalMembers)",
                        color: TributeColor.sage
                    )
                    statCard(
                        value: "\(Int(summary.averageScore * 100))%",
                        label: "Avg Score",
                        sublabel: "this week",
                        color: TributeColor.golden
                    )
                    statCard(
                        value: "\(summary.totalMembers)",
                        label: "Members",
                        sublabel: "total",
                        color: TributeColor.softGold
                    )
                }
                .padding(.horizontal, 20)

                if summary.averageScore > 0 {
                    faithfulnessBar(score: summary.averageScore)
                        .padding(.horizontal, 20)
                }

                if !summary.topStreaks.isEmpty {
                    topStreaksSection(summary.topStreaks)
                        .padding(.horizontal, 20)
                }

                if gratitudeWeekCount > 0 {
                    gratitudeCountCard
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 6) {
                    Text("\u{201C}Therefore encourage one another and build one another up, just as you are doing.\u{201D}")
                        .font(.system(.subheadline, design: .serif))
                        .italic()
                        .foregroundStyle(TributeColor.softGold.opacity(0.6))
                        .multilineTextAlignment(.center)
                    Text("1 Thessalonians 5:11")
                        .font(.caption)
                        .foregroundStyle(TributeColor.golden.opacity(0.5))
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding(.bottom, 40)
        }
    }

    private func statCard(value: String, label: String, sublabel: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TributeColor.warmWhite)

            Text(sublabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(TributeColor.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
        )
        .padding(.horizontal, 4)
    }

    private func faithfulnessBar(score: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Circle Faithfulness", systemImage: "chart.bar.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(TributeColor.golden)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(TributeColor.cardBackground)
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [TributeColor.golden.opacity(0.8), TributeColor.golden],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(score, 1.0), height: 12)
                }
            }
            .frame(height: 12)

            HStack {
                Text(scoreMessage(score))
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .background(TributeColor.golden.opacity(0.04))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(TributeColor.golden.opacity(0.1), lineWidth: 0.5)
        )
    }

    private func topStreaksSection(_ streaks: [TopStreak]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Top Streaks", systemImage: "flame.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(TributeColor.warmCoral)

            ForEach(Array(streaks.prefix(5).enumerated()), id: \.element.id) { index, streak in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(index == 0 ? TributeColor.golden : .secondary)
                        .frame(width: 20)

                    ZStack {
                        Circle()
                            .fill(index == 0 ? TributeColor.golden.opacity(0.12) : TributeColor.sage.opacity(0.1))
                            .frame(width: 28, height: 28)
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(index == 0 ? TributeColor.golden : TributeColor.sage)
                    }

                    Text("Member")
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(TributeColor.warmCoral)
                        Text("\(streak.streak) days")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(TributeColor.warmCoral)
                    }
                }
            }
        }
        .padding(16)
        .background(TributeColor.warmCoral.opacity(0.04))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(TributeColor.warmCoral.opacity(0.1), lineWidth: 0.5)
        )
    }

    private func scoreMessage(_ score: Double) -> String {
        if score >= 0.9 { return "Outstanding! Your circle walked in near-perfect faithfulness this week." }
        if score >= 0.7 { return "Strong week! Your circle showed up with consistency and dedication." }
        if score >= 0.5 { return "Good effort! More than half the circle stayed faithful this week." }
        if score >= 0.3 { return "A start! Every small step counts. Encourage each other." }
        return "A quiet week. Rally together — you're stronger in community."
    }

    private var gratitudeCountCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TributeColor.golden.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "heart.text.clipboard")
                    .font(.system(size: 14))
                    .foregroundStyle(TributeColor.golden)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Shared Gratitudes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TributeColor.warmWhite)
                Text("\(gratitudeWeekCount) gratitude\(gratitudeWeekCount == 1 ? "" : "s") shared this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(gratitudeWeekCount)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(TributeColor.golden)
        }
        .padding(16)
        .background(TributeColor.golden.opacity(0.04))
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(TributeColor.golden.opacity(0.1), lineWidth: 0.5)
        )
    }

    private func loadSummary() async {
        isLoading = true
        error = nil
        do {
            summary = try await APIService.shared.getSundaySummary(circleId: circleId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func loadGratitudeCount() async {
        do {
            let response = try await APIService.shared.getGratitudeWeekCount(circleId: circleId)
            gratitudeWeekCount = response.weekCount
        } catch {}
    }
}
