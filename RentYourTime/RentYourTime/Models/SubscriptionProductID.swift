enum SubscriptionProductID: String, CaseIterable, Sendable {
    case monthly = "com.rentyourtime.app.pro.monthly"
    case annual = "com.rentyourtime.app.pro.annual"

    static var all: [String] { allCases.map(\.rawValue) }
}
