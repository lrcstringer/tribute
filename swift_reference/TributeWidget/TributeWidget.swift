import WidgetKit
import SwiftUI

nonisolated struct TributeEntry: TimelineEntry {
    let date: Date
    let completed: Int
    let total: Int
    let weekScores: [Int]
}

nonisolated struct TributeProvider: TimelineProvider {
    private let suiteName = "group.app.rork.tribute"

    func placeholder(in context: Context) -> TributeEntry {
        TributeEntry(date: .now, completed: 3, total: 5, weekScores: [3, 2, 3, 1, 0, -1, -1])
    }

    func getSnapshot(in context: Context, completion: @escaping (TributeEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TributeEntry>) -> Void) {
        let entry = readEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readEntry() -> TributeEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        let completed = defaults?.integer(forKey: "widget_completed") ?? 0
        let total = defaults?.integer(forKey: "widget_total") ?? 0
        let scoresDict = defaults?.dictionary(forKey: "widget_week_scores") as? [String: Int] ?? [:]

        var weekScores: [Int] = []
        for i in 0..<7 {
            weekScores.append(scoresDict["\(i)"] ?? -1)
        }

        return TributeEntry(date: .now, completed: completed, total: total, weekScores: weekScores)
    }
}

struct TributeSmallWidgetView: View {
    var entry: TributeEntry

    private let charcoal = Color(red: 30/255, green: 30/255, blue: 46/255)
    private let golden = Color(red: 212/255, green: 168/255, blue: 67/255)
    private let softGold = Color(red: 232/255, green: 213/255, blue: 163/255)

    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.completed) / Double(entry.total)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(golden.opacity(0.15), lineWidth: 6)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(golden, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(entry.completed)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(golden)
                    Text("of \(entry.total)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(softGold.opacity(0.6))
                }
            }

            Text("given today")
                .font(.system(size: 11, weight: .medium, design: .serif))
                .foregroundStyle(softGold.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "tribute://today"))
        .containerBackground(for: .widget) {
            charcoal
        }
    }
}

struct TributeMediumWidgetView: View {
    var entry: TributeEntry

    private let charcoal = Color(red: 30/255, green: 30/255, blue: 46/255)
    private let golden = Color(red: 212/255, green: 168/255, blue: 67/255)
    private let softGold = Color(red: 232/255, green: 213/255, blue: 163/255)
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.completed) / Double(entry.total)
    }

    private var todayWeekdayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday - 1
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(golden.opacity(0.15), lineWidth: 5)
                        .frame(width: 58, height: 58)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(golden, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 58, height: 58)
                        .rotationEffect(.degrees(-90))

                    Text("\(entry.completed)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(golden)
                }

                Text("\(entry.completed) of \(entry.total) given")
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .foregroundStyle(softGold.opacity(0.5))
            }
            .frame(width: 90)

            Rectangle()
                .fill(golden.opacity(0.1))
                .frame(width: 0.5)
                .padding(.vertical, 8)

            VStack(spacing: 6) {
                Text("This Week")
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .foregroundStyle(softGold.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        VStack(spacing: 4) {
                            Text(dayLabels[index])
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(
                                    index == todayWeekdayIndex
                                        ? softGold.opacity(0.8)
                                        : softGold.opacity(0.3)
                                )

                            ZStack {
                                if index == todayWeekdayIndex {
                                    Circle()
                                        .stroke(golden.opacity(0.4), lineWidth: 1.5)
                                        .frame(width: 18, height: 18)
                                }

                                Circle()
                                    .fill(scoreColor(for: entry.weekScores[index]))
                                    .frame(width: 12, height: 12)
                            }
                            .frame(width: 20, height: 20)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "tribute://today"))
        .containerBackground(for: .widget) {
            charcoal
        }
    }

    private func scoreColor(for tier: Int) -> Color {
        switch tier {
        case -1: return .clear
        case 0: return golden.opacity(0.08)
        case 1: return golden.opacity(0.3)
        case 2: return golden.opacity(0.6)
        case 3: return golden
        default: return golden.opacity(0.08)
        }
    }
}

struct TributeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: TributeEntry

    var body: some View {
        switch family {
        case .systemSmall:
            TributeSmallWidgetView(entry: entry)
        case .systemMedium:
            TributeMediumWidgetView(entry: entry)
        default:
            TributeSmallWidgetView(entry: entry)
        }
    }
}

struct TributeWidget: Widget {
    let kind: String = "TributeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TributeProvider()) { entry in
            TributeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today\u{2019}s Tribute")
        .description("Track your daily habit progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
