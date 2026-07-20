import UserNotifications

// Treści celowo krótkie i spokojne — bez wykrzykników, bez zawstydzania.
enum NotificationContentBuilder {
    static func content(for kind: NotificationKind) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        switch kind {
        case .eightyPercent:
            content.title = "80% dziennego limitu"
            content.body = "Wykorzystałeś już 80% dzisiejszego czasu ekranowego."
        case .ninetyFivePercent:
            content.title = "95% dziennego limitu"
            content.body = "Zostało tylko trochę do dzisiejszego limitu."
        case .rentStarted:
            content.title = "Naliczanie rentu rozpoczęte"
            content.body = "Dzienny limit przekroczony — od teraz nalicza się rent."
        case .eveningSummary:
            content.title = "Podsumowanie dnia"
            content.body = "Sprawdź, jak wyglądał dziś Twój czas ekranowy."
        }

        content.sound = .default
        return content
    }
}
