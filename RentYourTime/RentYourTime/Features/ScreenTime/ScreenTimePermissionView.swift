import SwiftUI

struct ScreenTimePermissionView: View {
    let onAuthorized: () -> Void

    @State private var service = ScreenTimeAuthorizationService()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text("Dostęp do Screen Time")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 12) {
                explanationRow(
                    icon: "chart.bar.fill",
                    text: "RentYourTime potrzebuje dostępu do Screen Time, żeby wiedzieć, ile czasu spędzasz na telefonie i naliczać rent po przekroczeniu limitu."
                )
                explanationRow(
                    icon: "lock.shield.fill",
                    text: "Dane są przetwarzane zgodnie z ograniczeniami nałożonymi przez Apple — aplikacja nie widzi treści Twojej aktywności, tylko zagregowane informacje o czasie."
                )
                explanationRow(
                    icon: "hand.raised.fill",
                    text: "Możesz odmówić. Bez dostępu aplikacja nie będzie mogła mierzyć realnego czasu ekranowego."
                )
            }
            .padding(.horizontal)

            statusView

            Spacer(minLength: 0)

            actionButton
        }
        .padding()
        .task {
            service.refreshStatus()
            if service.state == .authorized {
                onAuthorized()
            }
        }
        .onChange(of: service.state) { _, newValue in
            if newValue == .authorized {
                onAuthorized()
            }
        }
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

    @ViewBuilder
    private var statusView: some View {
        switch service.state {
        case .denied:
            Label("Odmówiono dostępu do Screen Time.", systemImage: "xmark.circle")
                .foregroundStyle(.red)
                .font(.footnote)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
                .font(.footnote)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch service.state {
        case .requesting:
            ProgressView()
                .controlSize(.large)
        case .denied, .failed:
            Button("Spróbuj ponownie") {
                requestAccess()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        default:
            Button("Enable Screen Time Access") {
                requestAccess()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func requestAccess() {
        Task {
            await service.requestAuthorization()
        }
    }
}

#Preview {
    ScreenTimePermissionView(onAuthorized: {})
}
