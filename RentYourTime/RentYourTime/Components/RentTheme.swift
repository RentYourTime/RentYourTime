import SwiftUI

// Jawne, nieadaptacyjne kolory (nie Color.primary/systemBackground) —
// Dashboard ma wyglądać tak samo niezależnie od systemowego light/dark mode,
// podobnie jak karta w Apple Wallet.
extension Color {
    static let rentBackground = Color(red: 0.04, green: 0.04, blue: 0.045)
    static let rentSurface = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let rentGreen = Color(red: 0.20, green: 1.00, blue: 0.45)
}

extension RentStatus {
    /// Czerwony (systemowy .red) jest zarezerwowany wyłącznie dla .rentActive.
    var tintColor: Color {
        switch self {
        case .free: .rentGreen
        case .warning: .white
        case .rentActive: .red
        }
    }

    var displayName: String {
        switch self {
        case .free: "W normie"
        case .warning: "Zbliżasz się do limitu"
        case .rentActive: "Rent aktywny"
        }
    }

    var symbolName: String {
        switch self {
        case .free: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .rentActive: "flame.fill"
        }
    }
}
