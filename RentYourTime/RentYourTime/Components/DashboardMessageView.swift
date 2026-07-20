import SwiftUI

struct DashboardMessageView: View {
    let symbolName: String
    let title: String
    let message: String
    var tint: Color = .white

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 40))
                .foregroundStyle(tint)

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Brak danych") {
    DashboardMessageView(
        symbolName: "tray",
        title: "Brak danych na dziś",
        message: "Gdy tylko zaczniesz korzystać z wybranych aplikacji, zobaczysz tu swój dzienny postęp.",
        tint: .white.opacity(0.6)
    )
    .background(Color.rentBackground)
}

#Preview("Błąd") {
    DashboardMessageView(
        symbolName: "exclamationmark.triangle.fill",
        title: "Nie udało się wczytać danych",
        message: "Spróbuj ponownie za chwilę.",
        tint: .red
    )
    .background(Color.rentBackground)
}
