import SwiftUI

struct CircleDetailView: View {
    let circleId: String

    @State private var detail: CircleDetail?
    @State private var isLoading: Bool = true
    @State private var error: String?
    @State private var showShareSheet: Bool = false
    @State private var showLeaveConfirmation: Bool = false
    @State private var isLeaving: Bool = false
    @State private var showSOSRequest: Bool = false
    @State private var showSundaySummary: Bool = false
    @State private var recentSOS: [SOSItem] = []
    @State private var isLoadingSOS: Bool = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail {
                circleContent(detail)
            } else if let error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task { await loadDetail() }
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
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadDetail()
            await loadRecentSOS()
        }
        .alert("Leave Circle", isPresented: $showLeaveConfirmation) {
            Button("Leave", role: .destructive) {
                Task { await leaveCircle() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll no longer receive prayer requests or see this circle's progress.")
        }
    }

    @ViewBuilder
    private func circleContent(_ detail: CircleDetail) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if !detail.description.isEmpty {
                        Text(detail.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 16) {
                        Label("\(detail.memberCount) members", systemImage: "person.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(TributeColor.cardBackground)
            }

            GratitudeWallView(circleId: circleId)

            Section {
                Button {
                    showSOSRequest = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(TributeColor.warmCoral.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "bolt.heart.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(TributeColor.warmCoral)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("SOS Prayer Request")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TributeColor.warmWhite)
                            Text("Ask up to 20 people to pray for you")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(TributeColor.warmCoral.opacity(0.04))

                Button {
                    showSundaySummary = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(TributeColor.golden.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(TributeColor.golden)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekly Summary")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TributeColor.warmWhite)
                            Text("See your circle's faithfulness this week")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(TributeColor.golden.opacity(0.04))
            } header: {
                Text("Actions")
            }

            if !recentSOS.isEmpty {
                Section("Recent Prayer Requests") {
                    ForEach(recentSOS.prefix(5)) { sos in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: sos.isMine ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(sos.isMine ? TributeColor.golden : TributeColor.warmCoral)
                                Text(sos.isMine ? "You requested prayer" : "Prayer requested")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(sos.isMine ? TributeColor.golden : TributeColor.warmCoral)
                                Spacer()
                                Text(formattedDate(sos.createdAt))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }

                            Text(sos.message)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(TributeColor.cardBackground)
                    }
                }
            }

            Section("Invite") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invite Code")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(detail.inviteCode)
                            .font(.system(.title3, design: .monospaced, weight: .bold))
                            .foregroundStyle(TributeColor.golden)
                    }

                    Spacer()

                    Button {
                        UIPasteboard.general.string = detail.inviteCode
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.subheadline)
                            .foregroundStyle(TributeColor.golden)
                            .padding(10)
                            .background(TributeColor.golden.opacity(0.1))
                            .clipShape(.rect(cornerRadius: 8))
                    }
                }
                .listRowBackground(TributeColor.cardBackground)

                Button {
                    showShareSheet = true
                } label: {
                    Label("Share Invite Link", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TributeColor.golden)
                }
                .listRowBackground(TributeColor.cardBackground)
            }

            Section("Members (\(detail.members.count))") {
                ForEach(detail.members) { member in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(member.role == "admin" ? TributeColor.golden.opacity(0.12) : TributeColor.sage.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundStyle(member.role == "admin" ? TributeColor.golden : TributeColor.sage)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Member")
                                .font(.subheadline.weight(.medium))
                            if member.role == "admin" {
                                Text("Admin")
                                    .font(.caption2)
                                    .foregroundStyle(TributeColor.golden)
                            }
                        }

                        Spacer()
                    }
                    .listRowBackground(TributeColor.cardBackground)
                }
            }

            Section {
                Button(role: .destructive) {
                    showLeaveConfirmation = true
                } label: {
                    HStack {
                        Label("Leave Circle", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline)
                            .foregroundStyle(TributeColor.warmCoral)
                        Spacer()
                        if isLeaving {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isLeaving)
                .listRowBackground(TributeColor.warmCoral.opacity(0.06))
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(detail.name)
        .sheet(isPresented: $showShareSheet) {
            ShareInviteSheet(circleName: detail.name, inviteCode: detail.inviteCode, circleId: detail.id)
                .presentationDetents([.medium])
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showSOSRequest) {
            SOSPrayerRequestView(circleId: circleId, members: detail.members)
                .presentationDetents([.large])
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showSundaySummary) {
            CircleSundaySummaryView(circleId: circleId, circleName: detail.name)
                .presentationDetents([.large])
                .preferredColorScheme(.dark)
        }
    }

    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else {
            let fallbackFormatter = ISO8601DateFormatter()
            guard let fallbackDate = fallbackFormatter.date(from: dateString) else { return "" }
            return RelativeDateTimeFormatter().localizedString(for: fallbackDate, relativeTo: Date())
        }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }

    private func loadDetail() async {
        isLoading = true
        error = nil
        do {
            detail = try await APIService.shared.getCircleDetail(circleId: circleId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func loadRecentSOS() async {
        do {
            recentSOS = try await APIService.shared.getRecentSOS(circleId: circleId, limit: 5)
        } catch {
            // silently fail for SOS feed
        }
    }

    private func leaveCircle() async {
        isLeaving = true
        do {
            try await APIService.shared.leaveCircle(circleId: circleId)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isLeaving = false
    }
}

struct ShareInviteSheet: View {
    let circleName: String
    let inviteCode: String
    let circleId: String

    @Environment(\.dismiss) private var dismiss
    @State private var shareURL: String?
    @State private var isGenerating: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(TributeColor.golden.opacity(0.1))
                            .frame(width: 64, height: 64)
                        Image(systemName: "link.badge.plus")
                            .font(.title2)
                            .foregroundStyle(TributeColor.golden)
                    }

                    Text("Invite to \(circleName)")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(TributeColor.warmWhite)
                }

                VStack(spacing: 12) {
                    Button {
                        let text = "Join my Prayer Circle \"\(circleName)\" on Tribute! Use invite code: \(inviteCode)"
                        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootVC = window.rootViewController {
                            rootVC.present(activityVC, animated: true)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Invite")
                        }
                        .tributeButton()
                    }

                    Button {
                        UIPasteboard.general.string = inviteCode
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Code: \(inviteCode)")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TributeColor.golden)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(TributeColor.golden.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 24)
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
