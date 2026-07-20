import SwiftUI
import WidgetKit

struct RentStatusWidget: Widget {
    let kind: String = WidgetKind.rentStatus

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RentWidgetProvider()) { entry in
            RentWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("RentYourTime")
        .description("Wykorzystany czas, pozostały limit i naliczony rent.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct RentWidgetBundle: WidgetBundle {
    var body: some Widget {
        RentStatusWidget()
    }
}
