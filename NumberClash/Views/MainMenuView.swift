import SwiftUI

struct MainMenuView: View {
    @State private var highScore: Int = UserDefaultsHighScoreStore().current()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("KEY_APP_TITLE")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
            Text("KEY_APP_TAGLINE")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("KEY_HUD_HIGH_SCORE")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(highScore)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            NavigationLink {
                GameView()
            } label: {
                Text("KEY_PLAY")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 60)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(radius: 4)
            }

            HStack(spacing: 28) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("KEY_SETTINGS", systemImage: "gearshape")
                }
                NavigationLink {
                    AboutView()
                } label: {
                    Label("KEY_ABOUT", systemImage: "info.circle")
                }
            }
            .font(.callout)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { highScore = UserDefaultsHighScoreStore().current() }
    }
}

#Preview {
    NavigationStack { MainMenuView() }
}
