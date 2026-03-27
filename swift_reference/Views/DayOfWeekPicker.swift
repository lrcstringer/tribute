import SwiftUI

struct DayOfWeekPicker: View {
    @Binding var selectedDays: Set<Int>
    var isAbstain: Bool = false

    private let days: [(id: Int, label: String)] = [
        (1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isAbstain ? "Which days are you committing to this?" : "Which days will you do this?")
                .font(.caption.weight(.medium))
                .foregroundStyle(TributeColor.softGold.opacity(0.6))

            HStack(spacing: 8) {
                ForEach(days, id: \.id) { day in
                    let isSelected = selectedDays.contains(day.id)
                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            if isSelected {
                                if selectedDays.count > 1 {
                                    selectedDays.remove(day.id)
                                }
                            } else {
                                selectedDays.insert(day.id)
                            }
                        }
                    } label: {
                        Text(day.label)
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(isSelected ? TributeColor.charcoal : TributeColor.softGold.opacity(0.5))
                            .frame(width: 38, height: 38)
                            .background(isSelected ? TributeColor.golden : TributeColor.surfaceOverlay)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: isSelected)
                }
            }

            if selectedDays.count < 7 {
                Text(daysDescription)
                    .font(.caption2)
                    .foregroundStyle(TributeColor.softGold.opacity(0.4))
            }
        }
    }

    private var daysDescription: String {
        let names = [1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"]
        let sorted = selectedDays.sorted()
        let dayNames = sorted.compactMap { names[$0] }
        return "\(dayNames.joined(separator: ", ")) · \(selectedDays.count) days/week"
    }
}
