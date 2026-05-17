import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var engine: GameEngine

    init(engine: GameEngine = GameEngine.makeDefault()) {
        _engine = State(initialValue: engine)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                ScoreHUDView(
                    score: engine.score,
                    highScore: engine.highScoreStore.current()
                )
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("KEY_NEXT")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        NextPieceView(kind: engine.nextPiece)
                    }
                    Spacer(minLength: 0)
                    SkipGauge(count: engine.consecutiveSkips,
                              max: GameEngine.maxConsecutiveSkips)
                    Spacer(minLength: 0)
                    Button(action: { engine.rotateCurrentPiece() }) {
                        Label("KEY_ROTATE", systemImage: "rotate.right.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 32, weight: .bold))
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(engine.currentPiece == nil
                                          ? Color.gray.opacity(0.25)
                                          : Color.blue.opacity(0.85))
                            )
                            .foregroundStyle(.white)
                    }
                    .disabled(engine.currentPiece == nil)
                    .accessibilityLabel(Text("KEY_ROTATE"))
                }
                .padding(.horizontal, 8)
                BoardView(
                    board: engine.board,
                    clearingCells: engine.clearingCells,
                    plannedSpawn: engine.plannedNextSpawn.map {
                        (kind: $0.kind, positions: engine.board.cells(of: $0))
                    },
                    skippedCells: engine.skippedSpawn.map {
                        engine.board.cells(of: $0)
                    } ?? [],
                    currentCells: engine.currentPiece.map {
                        Set(engine.board.groups()[$0.groupID] ?? [])
                    } ?? []
                ) { direction in
                    engine.handleSwipe(direction)
                }
                .padding(.horizontal, 12)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)

            if case let .gameOver(finalScore, isNewHighScore) = engine.status {
                GameOverOverlay(
                    finalScore: finalScore,
                    isNewHighScore: isNewHighScore,
                    onPlayAgain: { engine.startNewGame() },
                    onMainMenu: { dismiss() }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                    Text("KEY_MAIN_MENU")
                }
            }
        }
        .onAppear {
            if engine.status == .idle {
                engine.startNewGame()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active: engine.resumeFromBackground()
            case .inactive, .background:
                if engine.status == .playing { engine.togglePause() }
            @unknown default: break
            }
        }
    }
}

/// Danger gauge: `max` pips, the first `count` filled red. Shows how close
/// the player is to losing by consecutive skips. Language-free by design.
private struct SkipGauge: View {
    let count: Int
    let max: Int

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(count == 0 ? Color.secondary.opacity(0.5)
                                            : Color.red.opacity(0.9))
            HStack(spacing: 4) {
                ForEach(0..<max, id: \.self) { i in
                    Circle()
                        .fill(i < count ? Color.red : Color.secondary.opacity(0.25))
                        .frame(width: 7, height: 7)
                }
            }
        }
        .accessibilityHidden(true)
        .animation(.easeInOut(duration: 0.2), value: count)
    }
}

#Preview {
    NavigationStack { GameView() }
}
