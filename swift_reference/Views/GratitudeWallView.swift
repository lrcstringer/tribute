import SwiftUI

struct GratitudeWallView: View {
    let circleId: String

    @State private var gratitudes: [SharedGratitudeItem] = []
    @State private var isLoading: Bool = true
    @State private var weeksBack: Int = 0
    @State private var isLoadingMore: Bool = false
    @State private var hasOlderWeeks: Bool = true
    @State private var newCount: Int = 0
    @State private var showNewBadge: Bool = false
    @State private var deleteTarget: SharedGratitudeItem?

    var body: some View {
        Section {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if gratitudes.isEmpty {
                HStack {
                    Spacer()
                    Text(weeksBack == 0 ? "No gratitudes shared this week yet" : "No gratitudes this week")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(Color(hex: "9A98A0"))
                    Spacer()
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            } else {
                if showNewBadge && newCount > 0 {
                    HStack {
                        Spacer()
                        Text("\(newCount) new gratitude\(newCount == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(TributeColor.golden)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                ForEach(gratitudes) { item in
                    gratitudeCard(item)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .contextMenu {
                            if item.isMine {
                                Button(role: .destructive) {
                                    deleteTarget = item
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                }

                if hasOlderWeeks {
                    Button {
                        loadPreviousWeek()
                    } label: {
                        HStack {
                            Spacer()
                            if isLoadingMore {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Previous weeks")
                                    .font(.caption)
                                    .foregroundStyle(TributeColor.golden.opacity(0.7))
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoadingMore)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        } header: {
            Text("GRATITUDE WALL")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6B6B7B"))
                .tracking(1.2)
        }
        .task {
            await loadWall()
            await loadNewCount()
            await markSeen()
        }
        .alert("Delete Gratitude", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let target = deleteTarget {
                    performDelete(target)
                }
            }
            Button("Cancel", role: .cancel) {
                deleteTarget = nil
            }
        } message: {
            Text("This gratitude will be removed from the wall for all circle members.")
        }
        .onAppear {
            startNewBadgeTimer()
        }
    }

    private func gratitudeCard(_ item: SharedGratitudeItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if item.isAnonymous {
                    Text("Someone in your circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "9A98A0"))
                } else {
                    Text(item.displayName?.components(separatedBy: " ").first ?? "Member")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TributeColor.warmWhite)
                }

                Spacer()

                Text(relativeTime(item.sharedAt))
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "6B6B7B"))
            }

            Text(item.gratitudeText)
                .font(.system(size: 14))
                .foregroundStyle(TributeColor.warmWhite)
                .lineSpacing(4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "2A2A3C"))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(hex: "353548"), lineWidth: 1)
        )
    }

    private func relativeTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: dateString)
        if date == nil {
            let fallback = ISO8601DateFormatter()
            date = fallback.date(from: dateString)
        }
        guard let date else { return "" }

        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }

        let calendar = Calendar.current
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let weekday = DateFormatter()
        weekday.dateFormat = "EEE"
        return weekday.string(from: date)
    }

    private func loadWall() async {
        isLoading = true
        do {
            let response = try await APIService.shared.getGratitudeWall(circleId: circleId, weeksBack: weeksBack)
            gratitudes = response.gratitudes
        } catch {}
        isLoading = false
    }

    private func loadNewCount() async {
        do {
            let response = try await APIService.shared.getGratitudeNewCount(circleId: circleId)
            newCount = response.newCount
        } catch {}
    }

    private func markSeen() async {
        do {
            try await APIService.shared.markGratitudesSeen(circleId: circleId)
        } catch {}
    }

    private func loadPreviousWeek() {
        isLoadingMore = true
        let nextWeek = weeksBack + 1
        Task {
            do {
                let response = try await APIService.shared.getGratitudeWall(circleId: circleId, weeksBack: nextWeek)
                if response.gratitudes.isEmpty {
                    hasOlderWeeks = false
                } else {
                    gratitudes.append(contentsOf: response.gratitudes)
                    weeksBack = nextWeek
                }
            } catch {}
            isLoadingMore = false
        }
    }

    private func performDelete(_ item: SharedGratitudeItem) {
        Task {
            do {
                try await APIService.shared.deleteGratitude(circleId: circleId, gratitudeId: item.id)
                withAnimation {
                    gratitudes.removeAll { $0.id == item.id }
                }
            } catch {}
        }
    }

    private func startNewBadgeTimer() {
        guard newCount > 0 else { return }
        showNewBadge = true
        Task {
            try? await Task.sleep(for: .seconds(5))
            withAnimation(.easeOut(duration: 0.3)) {
                showNewBadge = false
            }
        }
    }
}
