import SwiftUI

struct NotificationPermissionExplainerView: View {
    let onFinished: () -> Void

    @Environment(NotificationService.self) private var notificationService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text("Powiadomienia")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 12) {
                explanationRow(
                    icon: "gauge.with.dots.needle.67percent",
                    text: "Damy znać, gdy zbliżysz się do dziennego limitu (80% i 95%), zanim zacznie się naliczać rent."
                )
                explanationRow(
                    icon: "flame.fill",
                    text: "Powiadomimy Cię też w momencie, gdy naliczanie rentu faktycznie się zacznie."
                )
                explanationRow(
                    icon: "slider.horizontal.3",
                    text: "Każdy z tych typów możesz osobno wyłączyć w każdej chwili w Ustawieniach."
                )
            }
            .padding(.horizontal)

            Spacer(minLength: 0)

            Button("Włącz powiadomienia") {
                Task {
                    await notificationService.requestAuthorization()
                    onFinished()
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Nie teraz") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func explanationRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NotificationPermissionExplainerView(onFinished: {})
        .environment(NotificationService())
}
