import SwiftUI

struct CreateCircleView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isLoading: Bool = false
    @State private var error: String?

    var onCreated: (CircleResponse) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Circle Name")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("e.g. Family Prayer", text: $name)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(TributeColor.cardBackground)
                            .clipShape(.rect(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("Optional — what is this circle about?", text: $description, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(2...4)
                            .padding(12)
                            .background(TributeColor.cardBackground)
                            .clipShape(.rect(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(TributeColor.cardBorder, lineWidth: 0.5)
                            )
                    }
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
                    Task { await createCircle() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(TributeColor.charcoal)
                        } else {
                            Text("Create Circle")
                        }
                    }
                    .tributeButton()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

                Spacer()
            }
            .padding(20)
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationTitle("New Circle")
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

    private func createCircle() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        isLoading = true
        error = nil

        do {
            let response = try await APIService.shared.createCircle(
                name: trimmedName,
                description: description.trimmingCharacters(in: .whitespaces)
            )
            onCreated(response)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
