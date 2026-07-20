import SwiftUI

struct RentStatusBadge: View {
    let status: RentStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.symbolName)
            Text(status.displayName)
                .fontWeight(.semibold)
        }
        .font(.footnote)
        .foregroundStyle(status == .free ? Color.black : status.tintColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(badgeBackground, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status rentu")
        .accessibilityValue(status.displayName)
    }

    private var badgeBackground: Color {
        switch status {
        case .free: .rentGreen
        case .warning: Color.white.opacity(0.15)
        case .rentActive: Color.red.opacity(0.18)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        RentStatusBadge(status: .free)
        RentStatusBadge(status: .warning)
        RentStatusBadge(status: .rentActive)
    }
    .padding()
    .background(Color.rentBackground)
}
