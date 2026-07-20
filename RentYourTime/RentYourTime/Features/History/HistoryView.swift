import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var period: HistoryPeriod = .sevenDays

    var body: some View {
        let repository = HistoryRepository(modelContext: modelContext)
        let viewModel = HistoryViewModel(period: period, repository: repository, fallbackCurrency: appState.currency)

        NavigationStack {
            List {
                Section {
                    Picker("Zakres", selection: $period) {
                        ForEach(HistoryPeriod.allCases) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                }

                Section("Podsumowanie") {
                    LabeledContent("Średni czas", value: viewModel.averageUsedMinutesLabel)
                    LabeledContent("Suma rentu", value: viewModel.totalRentLabel)
                    LabeledContent("Dni poniżej limitu", value: viewModel.daysUnderLimitLabel)
                    LabeledContent("Streak", value: viewModel.streakLabel)
                }
                .accessibilityElement(children: .contain)

                Section("Dni") {
                    if viewModel.records.isEmpty {
                        Text("Brak danych w wybranym okresie.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.records) { record in
                            HistoryRow(record: record)
                        }
                    }
                }
            }
            .navigationTitle("Historia")
        }
    }
}

private struct HistoryRow: View {
    let record: DailyUsageRecord

    private var currency: Currency {
        Currency(isoCode: record.currencyCode) ?? .pln
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date, format: .dateTime.day().month().year())
                    .font(.headline)
                Text("\(record.usedMinutes / 60)h \(record.usedMinutes % 60)m użycia")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if record.overageMinutes > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currency.formatted(record.virtualRent))
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text("+\(record.overageMinutes) min")
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
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HistoryView()
        .environment(AppState())
        .modelContainer(for: DailyUsageRecord.self, inMemory: true)
}
