import SwiftUI

struct RentSummaryCard: View {
    let amountLabel: String
    let status: RentStatus

    @ScaledMetric(relativeTo: .largeTitle) private var amountFontSize: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Wirtualny rent")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                RentStatusBadge(status: status)
            }

            Text(amountLabel)
                .font(.system(size: amountFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(status == .rentActive ? Color.red : Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityLabel("Wirtualny rent")
                .accessibilityValue(amountLabel)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.rentSurface, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    VStack(spacing: 16) {
        RentSummaryCard(amountLabel: "0,00 zł", status: .free)
        RentSummaryCard(amountLabel: "0,00 zł", status: .warning)
        RentSummaryCard(amountLabel: "25,50 zł", status: .rentActive)
    }
    .padding()
    .background(Color.rentBackground)
}
