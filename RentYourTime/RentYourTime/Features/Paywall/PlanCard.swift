import StoreKit
import SwiftUI

struct PlanCard: View {
    let product: Product
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(product.displayName)
                        .font(.headline)
                    Spacer()
                    if isPurchasing {
                        ProgressView()
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title2.bold())
                    if let period = product.subscription?.subscriptionPeriod {
                        Text(period.billingCycleLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Label("Odnawia się automatycznie", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [product.displayName, product.displayPrice]
        if let period = product.subscription?.subscriptionPeriod {
            parts.append(period.billingCycleLabel)
        }
        parts.append("odnawia się automatycznie")
        return parts.joined(separator: ", ")
    }
}

extension Product.SubscriptionPeriod {
    var billingCycleLabel: String {
        switch unit {
        case .day: value == 1 ? "dziennie" : "co \(value) dni"
        case .week: value == 1 ? "tygodniowo" : "co \(value) tygodni"
        case .month: value == 1 ? "miesięcznie" : "co \(value) miesięcy"
        case .year: value == 1 ? "rocznie" : "co \(value) lat"
        @unknown default: ""
        }
    }
}
