import Foundation

enum Currency: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case pln
    case usd
    case eur

    var id: String { rawValue }

    var isoCode: String { rawValue.uppercased() }

    init?(isoCode: String) {
        self.init(rawValue: isoCode.lowercased())
    }

    var symbol: String {
        switch self {
        case .pln: "zł"
        case .usd: "$"
        case .eur: "€"
        }
    }

    var displayName: String {
        switch self {
        case .pln: "Polski złoty"
        case .usd: "US Dollar"
        case .eur: "Euro"
        }
    }

    func formatted(_ amount: Decimal) -> String {
        "\(amount.formatted(.number.precision(.fractionLength(2)))) \(symbol)"
    }
}
