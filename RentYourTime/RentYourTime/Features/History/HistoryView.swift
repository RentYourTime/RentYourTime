import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let viewModel = HistoryViewModel(appState: appState)

        NavigationStack {
            List(viewModel.entries) { entry in
                HistoryRow(entry: entry)
            }
            .navigationTitle("Historia")
        }
    }
}

private struct HistoryRow: View {
    let entry: UsageEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, format: .dateTime.day().month().year())
                    .font(.headline)
                Text("\(entry.usedMinutes / 60)h \(entry.usedMinutes % 60)m użycia")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if entry.overLimitMinutes > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.currency.formatted(entry.rentCost))
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text("+\(entry.overLimitMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("W limicie")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .environment(AppState())
}
