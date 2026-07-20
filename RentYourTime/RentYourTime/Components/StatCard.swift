import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    var tint: Color = .accentColor

    @ScaledMetric(relativeTo: .title2) private var valueFontSize: CGFloat = 26

    init(title: String, value: String, subtitle: String? = nil, tint: Color = .accentColor) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.system(size: valueFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.rentSurface, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack(spacing: 12) {
        StatCard(title: "Czas wykorzystany", value: "3h 07m", tint: .white)
        StatCard(title: "Ponad limit", value: "27 min", subtitle: "od 22:14", tint: .red)
    }
    .padding()
    .background(Color.rentBackground)
}
