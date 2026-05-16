import SwiftUI

struct ScoreHUDView: View {
    let score: Int
    let highScore: Int

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("KEY_HUD_SCORE")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(score)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .monospacedDigit()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("KEY_HUD_HIGH_SCORE")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(highScore)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    ScoreHUDView(score: 1234, highScore: 9999)
}
