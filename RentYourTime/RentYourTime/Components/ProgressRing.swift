import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let status: RentStatus
    let primaryText: String
    let secondaryText: String

    @ScaledMetric(relativeTo: .largeTitle) private var primaryFontSize: CGFloat = 40
    @ScaledMetric(relativeTo: .footnote) private var secondaryFontSize: CGFloat = 13

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 14)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(status.tintColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text(primaryText)
                    .font(.system(size: primaryFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(secondaryText)
                    .font(.system(size: secondaryFontSize, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
        }
        .animation(.easeInOut, value: progress)
        .animation(.easeInOut, value: status)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dzienny postęp")
        .accessibilityValue("\(primaryText), \(status.displayName)")
    }
}

#Preview {
    VStack(spacing: 24) {
        ProgressRing(progress: 0.2, status: .free, primaryText: "20%", secondaryText: "w normie")
            .frame(width: 160, height: 160)
        ProgressRing(progress: 0.85, status: .warning, primaryText: "85%", secondaryText: "blisko limitu")
            .frame(width: 160, height: 160)
        ProgressRing(progress: 1.0, status: .rentActive, primaryText: "128%", secondaryText: "rent aktywny")
            .frame(width: 160, height: 160)
    }
    .padding(40)
    .background(Color.rentBackground)
}
