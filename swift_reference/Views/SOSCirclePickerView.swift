import SwiftUI

struct SOSCirclePickerView: View {
    let circles: [CircleListItem]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCircle: CircleListItem?
    @State private var circleDetail: CircleDetail?
    @State private var isLoadingDetail: Bool = false
    @State private var showSOSRequest: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if circles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No circles yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Join or create a Prayer Circle first to send SOS requests.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            Text("Choose which circle to send your prayer request to.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .listRowBackground(Color.clear)
                        }

                        Section("Your Circles") {
                            ForEach(circles) { circle in
                                Button {
                                    Task { await selectCircle(circle) }
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(TributeColor.golden.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                            Text(String(circle.name.prefix(1)).uppercased())
                                                .font(.system(.subheadline, design: .serif, weight: .bold))
                                                .foregroundStyle(TributeColor.golden)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(circle.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(TributeColor.warmWhite)
                                            Text("\(circle.memberCount) members")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        if isLoadingDetail && selectedCircle?.id == circle.id {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(TributeColor.cardBackground)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background {
                ZStack {
                    TributeColor.charcoal.ignoresSafeArea()
                    TributeColor.warmGlow.ignoresSafeArea()
                }
            }
            .navigationTitle("Send SOS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showSOSRequest) {
                if let circleDetail {
                    SOSPrayerRequestView(circleId: circleDetail.id, members: circleDetail.members)
                        .presentationDetents([.large])
                        .preferredColorScheme(.dark)
                }
            }
        }
    }

    private func selectCircle(_ circle: CircleListItem) async {
        selectedCircle = circle
        isLoadingDetail = true
        do {
            circleDetail = try await APIService.shared.getCircleDetail(circleId: circle.id)
            showSOSRequest = true
        } catch {
            // Fall back silently
        }
        isLoadingDetail = false
    }
}
