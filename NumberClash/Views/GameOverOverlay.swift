import SwiftUI

struct GameOverOverlay: View {
    let finalScore: Int
    let isNewHighScore: Bool
    let onPlayAgain: () -> Void
    let onMainMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("KEY_GAMEOVER_TITLE")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                if isNewHighScore {
                    Text("KEY_NEW_HIGH_SCORE")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.18))
                        .clipShape(Capsule())
                }
                VStack(spacing: 4) {
                    Text("KEY_HUD_SCORE")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(finalScore)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 8)
                HStack(spacing: 12) {
                    Button(action: onPlayAgain) {
                        Text("KEY_PLAY_AGAIN")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button(action: onMainMenu) {
                        Text("KEY_MAIN_MENU")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 32)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(32)
        }
    }
}

#Preview {
    GameOverOverlay(finalScore: 1500, isNewHighScore: true,
                    onPlayAgain: {}, onMainMenu: {})
}
