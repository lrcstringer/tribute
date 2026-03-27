import SwiftUI

struct JoinCircleView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var inviteCode: String
    @State private var isLoading: Bool = false
    @State private var error: String?
    @State private var joinedName: String?

    var onJoined: () async -> Void

    init(initialCode: String = "", onJoined: @escaping () async -> Void) {
        _inviteCode = State(initialValue: initialCode)
        self.onJoined = onJoined
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let joinedName {
                    VStack(spacing: 16) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(TributeColor.sage.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(TributeColor.sage)
                        }

                        Text("Joined \(joinedName)!")
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .foregroundStyle(TributeColor.warmWhite)

                        Button {
                            Task {
                                await onJoined()
                                dismiss()
                            }
                        } label: {
                            Text("Done")
                                .tributeButton()
                        }
                        .padding(.horizontal, 20)

                        Spacer()
                    }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Invite Code")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            TextField("Enter invite code", text: $inviteCode)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(12)
                                .background(TributeColor.cardBackground)
                                .clipShape(.rect(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                                )
                        }

                        Text("Ask the circle creator for their invite code, or tap a shared invite link.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let error {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text(error)
                                .font(.caption)
                        }
                        .foregroundStyle(TributeColor.warmCoral)
                    }

                    Button {
                        Task { await joinCircle() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(TributeColor.charcoal)
                            } else {
                                Text("Join Circle")
                            }
                        }
                        .tributeButton()
                    }
                    .disabled(inviteCode.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    .opacity(inviteCode.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

                    Spacer()
                }
            }
            .padding(20)
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationTitle("Join Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func joinCircle() async {
        let code = inviteCode.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return }

        isLoading = true
        error = nil

        do {
            let response = try await APIService.shared.joinCircle(inviteCode: code)
            if response.alreadyMember {
                error = "You're already a member of this circle"
            } else {
                joinedName = response.name
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
