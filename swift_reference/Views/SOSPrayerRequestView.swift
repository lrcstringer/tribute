import SwiftUI

struct SOSPrayerRequestView: View {
    let circleId: String
    let members: [CircleMemberInfo]

    @Environment(\.dismiss) private var dismiss
    @State private var message: String = ""
    @State private var selectedRecipientIds: Set<String> = []
    @State private var isSending: Bool = false
    @State private var error: String?
    @State private var sentSuccessfully: Bool = false
    @State private var recipientCount: Int = 0

    private let maxRecipients = 20
    private let currentUserId = AuthenticationService.shared.userId

    private var otherMembers: [CircleMemberInfo] {
        members.filter { $0.userId != currentUserId }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sentSuccessfully {
                    successView
                } else {
                    composeView
                }
            }
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationTitle(sentSuccessfully ? "" : "SOS Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(sentSuccessfully ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var composeView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(TributeColor.warmCoral.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(TributeColor.warmCoral)
                    }

                    Text("Request Urgent Prayer")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(TributeColor.warmWhite)

                    Text("Select up to \(maxRecipients) people who will be notified to pray for you.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Message")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(message.count)/500")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    TextField("Please pray for me...", text: $message, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(TributeColor.cardBackground)
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                        )
                        .onChange(of: message) { _, newValue in
                            if newValue.count > 500 {
                                message = String(newValue.prefix(500))
                            }
                        }
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recipients")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(selectedRecipientIds.count)/\(maxRecipients)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(selectedRecipientIds.count >= maxRecipients ? TributeColor.warmCoral : .secondary)
                    }

                    if otherMembers.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "person.slash")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("No other members in this circle yet.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TributeColor.cardBackground)
                        .clipShape(.rect(cornerRadius: 10))
                    } else {
                        Button {
                            if selectedRecipientIds.count == min(otherMembers.count, maxRecipients) {
                                selectedRecipientIds.removeAll()
                            } else {
                                selectedRecipientIds = Set(otherMembers.prefix(maxRecipients).map(\.userId))
                            }
                        } label: {
                            let allSelected = selectedRecipientIds.count == min(otherMembers.count, maxRecipients)
                            HStack(spacing: 6) {
                                Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.subheadline)
                                    .foregroundStyle(allSelected ? TributeColor.golden : .secondary)
                                Text(allSelected ? "Deselect All" : "Select All (\(min(otherMembers.count, maxRecipients)))")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                        }

                        ForEach(otherMembers) { member in
                            recipientRow(member)
                        }
                    }
                }
                .padding(.horizontal, 20)

                if let error {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                    }
                    .foregroundStyle(TributeColor.warmCoral)
                    .padding(.horizontal, 20)
                }

                Button {
                    Task { await sendSOS() }
                } label: {
                    Group {
                        if isSending {
                            ProgressView()
                                .tint(TributeColor.charcoal)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.heart.fill")
                                Text("Send SOS Prayer Request")
                            }
                        }
                    }
                    .tributeButton(color: TributeColor.warmCoral)
                }
                .disabled(selectedRecipientIds.isEmpty || isSending)
                .opacity(selectedRecipientIds.isEmpty ? 0.5 : 1)
                .padding(.horizontal, 20)
            }
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(TributeColor.sage.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(TributeColor.sage)
            }

            VStack(spacing: 8) {
                Text("Prayer Request Sent")
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(TributeColor.warmWhite)

                Text("\(recipientCount) \(recipientCount == 1 ? "person has" : "people have") been asked to pray for you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("\"Bear one another's burdens, and so fulfill the law of Christ.\"")
                .font(.system(.subheadline, design: .serif))
                .italic()
                .foregroundStyle(TributeColor.softGold.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Galatians 6:2")
                .font(.caption)
                .foregroundStyle(TributeColor.golden.opacity(0.5))

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func recipientRow(_ member: CircleMemberInfo) -> some View {
        let isSelected = selectedRecipientIds.contains(member.userId)
        let isDisabled = !isSelected && selectedRecipientIds.count >= maxRecipients

        return Button {
            if isSelected {
                selectedRecipientIds.remove(member.userId)
            } else if selectedRecipientIds.count < maxRecipients {
                selectedRecipientIds.insert(member.userId)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? TributeColor.golden.opacity(0.15) : TributeColor.cardBackground)
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundStyle(isSelected ? TributeColor.golden : .secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Member")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    if member.role == "admin" {
                        Text("Admin")
                            .font(.caption2)
                            .foregroundStyle(TributeColor.golden)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? TributeColor.golden : Color.white.opacity(0.15))
            }
            .padding(10)
            .background(isSelected ? TributeColor.golden.opacity(0.04) : TributeColor.cardBackground)
            .clipShape(.rect(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? TributeColor.golden.opacity(0.2) : TributeColor.cardBorder, lineWidth: 0.5)
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
    }

    private func sendSOS() async {
        isSending = true
        error = nil

        let sosMessage = message.trimmingCharacters(in: .whitespaces)
        let finalMessage = sosMessage.isEmpty ? "Please pray for me" : sosMessage

        do {
            let response = try await APIService.shared.sendSOS(
                circleId: circleId,
                message: finalMessage,
                recipientIds: Array(selectedRecipientIds)
            )
            recipientCount = response.recipientCount
            withAnimation(.spring(duration: 0.5)) {
                sentSuccessfully = true
            }
        } catch {
            self.error = error.localizedDescription
        }
        isSending = false
    }
}
