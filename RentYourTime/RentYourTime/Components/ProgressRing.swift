import SwiftUI

struct ProgressRing: View {
    let progress: Double
    var isOverLimit: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 14)
            Circle()
                .trim(from: 0, to: min(1, progress))
                .stroke(
                    isOverLimit ? Color.red : Color.accentColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(Int(min(progress, 1) * 100))%")
                .font(.title3.bold())
        }
        .animation(.easeInOut, value: progress)
    }
}

#Preview {
    ProgressRing(progress: 0.75)
        .frame(width: 160, height: 160)
        .padding()
}
