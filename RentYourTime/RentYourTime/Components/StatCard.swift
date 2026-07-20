import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    var tint: Color = .accentColor

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
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(tint)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    StatCard(title: "Dzisiaj", value: "3h 07m", subtitle: "27 min ponad limit", tint: .orange)
        .padding()
}
