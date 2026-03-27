import SwiftUI

struct CirclesTab: View {
    @Binding var pendingInviteCode: String?
    @State private var authService = AuthenticationService.shared

    var body: some View {
        if authService.isAuthenticated {
            CirclesListView(pendingInviteCode: $pendingInviteCode)
        } else {
            CirclesAuthGateView(pendingInviteCode: $pendingInviteCode)
        }
    }
}

struct CirclesAuthGateView: View {
    @Binding var pendingInviteCode: String?
    @State private var authService = AuthenticationService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(TributeColor.golden.opacity(0.08))
                                .frame(width: 100, height: 100)
                            Circle()
                                .fill(TributeColor.golden.opacity(0.12))
                                .frame(width: 72, height: 72)
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(TributeColor.golden)
                        }

                        Text("Prayer Circles")
                            .font(.system(.title, design: .serif, weight: .bold))
                            .foregroundStyle(TributeColor.warmWhite)

                        Text("Walk together in faith with your community.\nCreate or join circles to share your journey.")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(TributeColor.softGold.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    VStack(spacing: 12) {
                        featureRow(icon: "hands.sparkles.fill", title: "SOS Prayers", description: "Request urgent prayer from up to 20 people")
                        featureRow(icon: "chart.bar.fill", title: "Shared Progress", description: "See your circle's collective faithfulness")
                        featureRow(icon: "calendar.badge.clock", title: "Sunday Summary", description: "Weekly circle stats and encouragement")
                        featureRow(icon: "link", title: "Easy Invites", description: "Share a link to grow your circle")
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        Button {
                            Task { await authService.signInWithApple() }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18))
                                Text("Sign in with Apple")
                                    .font(.headline)
                            }
                            .foregroundStyle(TributeColor.charcoal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(TributeColor.golden)
                            .clipShape(.rect(cornerRadius: 14))
                        }
                        .disabled(authService.isLoading)
                        .overlay {
                            if authService.isLoading {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(TributeColor.golden.opacity(0.8))
                                    .overlay {
                                        ProgressView()
                                            .tint(TributeColor.charcoal)
                                    }
                            }
                        }

                        if let error = authService.error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(TributeColor.warmCoral)
                        }

                        if pendingInviteCode != nil {
                            Text("Sign in to join this Prayer Circle")
                                .font(.caption)
                                .foregroundStyle(TributeColor.golden.opacity(0.7))
                        } else {
                            Text("Sign in to create and join Prayer Circles")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .scrollContentBackground(.hidden)
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationTitle("Circles")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(TributeColor.golden.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(TributeColor.golden)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TributeColor.warmWhite)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(TributeColor.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
        )
    }
}

struct CirclesListView: View {
    @Binding var pendingInviteCode: String?
    @State private var circles: [CircleListItem] = []
    @State private var isLoading: Bool = true
    @State private var showCreateCircle: Bool = false
    @State private var showJoinCircle: Bool = false
    @State private var joinInviteCode: String = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if circles.isEmpty {
                    emptyState
                } else {
                    circlesList
                }
            }
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationTitle("Circles")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if !circles.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showCreateCircle = true
                            } label: {
                                Label("Create Circle", systemImage: "plus.circle")
                            }
                            Button {
                                showJoinCircle = true
                            } label: {
                                Label("Join Circle", systemImage: "person.badge.plus")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(TributeColor.golden)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateCircle) {
                CreateCircleView { newCircle in
                    circles.insert(CircleListItem(
                        id: newCircle.id,
                        name: newCircle.name,
                        description: "",
                        memberCount: 1,
                        role: "admin",
                        inviteCode: newCircle.inviteCode
                    ), at: 0)
                }
                .presentationDetents([.medium])
                .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showJoinCircle, onDismiss: {
                joinInviteCode = ""
            }) {
                JoinCircleView(initialCode: joinInviteCode) {
                    await loadCircles()
                }
                .presentationDetents([.medium])
                .preferredColorScheme(.dark)
            }
            .task {
                await loadCircles()
            }
            .onChange(of: pendingInviteCode) { _, newCode in
                if let code = newCode, !code.isEmpty {
                    joinInviteCode = code
                    pendingInviteCode = nil
                    showJoinCircle = true
                }
            }
            .onAppear {
                if let code = pendingInviteCode, !code.isEmpty {
                    joinInviteCode = code
                    pendingInviteCode = nil
                    showJoinCircle = true
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(TributeColor.golden.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(TributeColor.golden.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text("No Circles Yet")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(TributeColor.warmWhite)
                Text("Create a circle to pray with friends,\nor join one with an invite code.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    showCreateCircle = true
                } label: {
                    Text("Create a Circle")
                        .tributeButton()
                }

                Button {
                    showJoinCircle = true
                } label: {
                    Text("Join with Code")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(TributeColor.golden)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    @ViewBuilder
    private var circlesList: some View {
        List {
            ForEach(circles) { circle in
                NavigationLink(value: circle.id) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(TributeColor.golden.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Text(String(circle.name.prefix(1)).uppercased())
                                .font(.system(.headline, design: .serif, weight: .bold))
                                .foregroundStyle(TributeColor.golden)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(circle.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TributeColor.warmWhite)
                            HStack(spacing: 6) {
                                Image(systemName: "person.2")
                                    .font(.caption2)
                                Text("\(circle.memberCount) members")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if circle.role == "admin" {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(TributeColor.golden.opacity(0.5))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(TributeColor.cardBackground)
            }

            if let error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(TributeColor.warmCoral)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(TributeColor.warmCoral)
                }
                .listRowBackground(TributeColor.cardBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .navigationDestination(for: String.self) { circleId in
            CircleDetailView(circleId: circleId)
        }
    }

    private func loadCircles() async {
        isLoading = true
        error = nil
        do {
            circles = try await APIService.shared.listCircles()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
