import SwiftUI

struct ShareGratitudeSheet: View {
    let circles: [CircleListItem]
    let gratitudeText: String?
    let onShare: ([String], Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCircleIds: Set<String> = []
    @State private var isAnonymous: Bool = false
    @State private var isSharing: Bool = false

    private var authService: AuthenticationService { AuthenticationService.shared }

    private var firstName: String {
        let name = authService.displayName ?? "You"
        return name.components(separatedBy: " ").first ?? name
    }

    private var previewText: String {
        if let text = gratitudeText, !text.isEmpty {
            if isAnonymous {
                return "Someone in your circle: \(text)"
            } else {
                return "\(firstName): \(text)"
            }
        } else {
            if isAnonymous {
                return "Someone in your circle gave thanks to God today"
            } else {
                return "\(firstName) gave thanks to God today"
            }
        }
    }

    private var hasMultipleCircles: Bool {
        circles.count > 1
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.clipboard")
                        .font(.system(size: 28))
                        .foregroundStyle(TributeColor.golden)

                    Text("Share Your Gratitude")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(TributeColor.warmWhite)
                }
                .padding(.top, 8)

                if hasMultipleCircles {
                    circleSelector
                }

                anonymityToggle

                previewCard

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        share()
                    } label: {
                        HStack(spacing: 6) {
                            if isSharing {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(TributeColor.charcoal)
                            } else {
                                Text("Share")
                                Image(systemName: "arrow.right")
                                    .font(.subheadline)
                            }
                        }
                        .tributeButton()
                    }
                    .disabled(isSharing || (hasMultipleCircles && selectedCircleIds.isEmpty))

                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            if circles.count == 1, let first = circles.first {
                selectedCircleIds = [first.id]
            }
        }
    }

    private var circleSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SHARE TO")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6B6B7B"))
                .tracking(1.2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(circles) { circle in
                        let isSelected = selectedCircleIds.contains(circle.id)
                        Button {
                            if isSelected {
                                selectedCircleIds.remove(circle.id)
                            } else {
                                selectedCircleIds.insert(circle.id)
                            }
                        } label: {
                            Text(circle.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(isSelected ? TributeColor.charcoal : TributeColor.warmWhite)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? TributeColor.golden : TributeColor.cardBackground)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(isSelected ? Color.clear : TributeColor.cardBorder, lineWidth: 0.5)
                                )
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var anonymityToggle: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAnonymous = false
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isAnonymous ? "circle" : "checkmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(isAnonymous ? .secondary : TributeColor.golden)
                    Text("Share with your name")
                        .font(.subheadline)
                        .foregroundStyle(TributeColor.warmWhite)
                    Spacer()
                }
                .padding(12)
                .background(isAnonymous ? Color.clear : TributeColor.golden.opacity(0.06))
                .clipShape(.rect(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isAnonymous ? TributeColor.cardBorder : TributeColor.golden.opacity(0.2), lineWidth: 0.5)
                )
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAnonymous = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isAnonymous ? "checkmark.circle.fill" : "circle")
                        .font(.body)
                        .foregroundStyle(isAnonymous ? TributeColor.golden : .secondary)
                    Text("Share anonymously")
                        .font(.subheadline)
                        .foregroundStyle(TributeColor.warmWhite)
                    Spacer()
                }
                .padding(12)
                .background(isAnonymous ? TributeColor.golden.opacity(0.06) : Color.clear)
                .clipShape(.rect(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isAnonymous ? TributeColor.golden.opacity(0.2) : TributeColor.cardBorder, lineWidth: 0.5)
                )
            }
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PREVIEW")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6B6B7B"))
                .tracking(1.2)

            Text(previewText)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(TributeColor.warmWhite.opacity(0.8))
                .lineSpacing(3)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "2A2A3C"))
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(hex: "353548"), lineWidth: 1)
                )
        }
    }

    private func share() {
        let ids = hasMultipleCircles ? Array(selectedCircleIds) : circles.map(\.id)
        guard !ids.isEmpty else { return }
        isSharing = true
        onShare(ids, isAnonymous)
        dismiss()
    }
}
