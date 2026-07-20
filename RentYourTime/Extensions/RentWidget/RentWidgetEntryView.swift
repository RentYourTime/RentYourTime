import SwiftUI
import WidgetKit

struct RentWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RentWidgetEntry

    var body: some View {
        content
            .containerBackground(.background, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemMedium:
                MediumRentWidgetView(snapshot: snapshot)
            default:
                SmallRentWidgetView(snapshot: snapshot)
            }
        } else {
            emptyStateView
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Image(systemName: "hourglass")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Otwórz RentYourTime")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Brak jeszcze danych. Otwórz aplikację RentYourTime, żeby je wczytać.")
    }
}

// Wymóg mówi o dwóch stanach widgetu (free / rentActive) — .warning jest
// wizualnie zwijane do wyglądu "w normie", żeby nie mnożyć stanów w UI
// widgetu, choć w danych (WidgetSnapshot.status) zostaje pełna, 3-stanowa
// wartość z silnika.
private extension RentStatus {
    var widgetTint: Color {
        self == .rentActive ? .red : .green
    }

    var widgetLabel: String {
        self == .rentActive ? "Rent aktywny" : "W normie"
    }

    var widgetSymbol: String {
        self == .rentActive ? "flame.fill" : "checkmark.circle.fill"
    }
}

private func timeLabel(_ minutes: Int) -> String {
    "\(minutes / 60)h \(minutes % 60)m"
}

private func widgetCurrency(for snapshot: WidgetSnapshot) -> Currency {
    Currency(isoCode: snapshot.currencyCode) ?? .pln
}

private func accessibilitySummary(snapshot: WidgetSnapshot) -> String {
    let currency = widgetCurrency(for: snapshot)
    let used = "\(snapshot.usedMinutes / 60) godzin \(snapshot.usedMinutes % 60) minut wykorzystane"
    let remaining = "\(snapshot.remainingMinutes / 60) godzin \(snapshot.remainingMinutes % 60) minut pozostało"
    let rent = "naliczony rent \(currency.formatted(snapshot.virtualRentAmount))"
    let status = snapshot.status == .rentActive ? "rent aktywny" : "w normie"
    return "\(used). \(remaining). \(rent). Status: \(status)."
}

private struct SmallRentWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: snapshot.status.widgetSymbol)
                    .foregroundStyle(snapshot.status.widgetTint)
                Text(snapshot.status.widgetLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(snapshot.status.widgetTint)
                Spacer(minLength: 0)
            }

            Spacer(minLength: 0)

            Text(timeLabel(snapshot.usedMinutes))
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("wykorzystane dziś")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pozostało \(timeLabel(snapshot.remainingMinutes))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Rent: \(widgetCurrency(for: snapshot).formatted(snapshot.virtualRentAmount))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(snapshot.status == .rentActive ? .red : .secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary(snapshot: snapshot))
    }
}

private struct MediumRentWidgetView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: snapshot.status.widgetSymbol)
                        .foregroundStyle(snapshot.status.widgetTint)
                    Text(snapshot.status.widgetLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(snapshot.status.widgetTint)
                }
                Text("RentYourTime")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text("Every minute costs.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            statColumn(title: "Wykorzystane", value: timeLabel(snapshot.usedMinutes))
            statColumn(title: "Pozostałe", value: timeLabel(snapshot.remainingMinutes))
            statColumn(
                title: "Rent",
                value: widgetCurrency(for: snapshot).formatted(snapshot.virtualRentAmount),
                tint: snapshot.status == .rentActive ? .red : .primary
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary(snapshot: snapshot))
    }

    private func statColumn(title: String, value: String, tint: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview(as: .systemSmall) {
    RentStatusWidget()
} timeline: {
    RentWidgetEntry(date: .now, snapshot: WidgetSnapshot(
        usedMinutes: 95, allowanceMinutes: 120, remainingMinutes: 25,
        virtualRentAmount: 0, currencyCode: "PLN", status: .free, generatedAt: .now
    ))
    RentWidgetEntry(date: .now, snapshot: WidgetSnapshot(
        usedMinutes: 150, allowanceMinutes: 120, remainingMinutes: 0,
        virtualRentAmount: 15, currencyCode: "PLN", status: .rentActive, generatedAt: .now
    ))
}

#Preview(as: .systemMedium) {
    RentStatusWidget()
} timeline: {
    RentWidgetEntry(date: .now, snapshot: WidgetSnapshot(
        usedMinutes: 95, allowanceMinutes: 120, remainingMinutes: 25,
        virtualRentAmount: 0, currencyCode: "PLN", status: .free, generatedAt: .now
    ))
}
