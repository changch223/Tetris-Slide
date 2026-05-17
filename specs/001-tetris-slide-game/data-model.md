# Phase 1 Data Model: Tetris Slide Game (10x10)

**Feature**: 001-tetris-slide-game
**Date**: 2026-05-08
**Source plan**: [plan.md](./plan.md)

ここでは spec.md で識別したエンティティを、実装に直接マップ可能なレベル
まで分解する。SwiftUI / Swift 5 を前提とした型を提示するが、特定 API への
依存（SwiftData など）は意図的に避け、**純粋値型（struct/enum）+
`@Observable` クラス 1 つ**で組む。

---

## 1. ピース定義

### 1.1 `PieceKind`

```text
enum PieceKind: CaseIterable {
    case I, O, T, S, Z, J, L
}
```

各 kind は固定色（spec FR-007）と、4 回転状態における 4 セルの相対座標を
持つ。

### 1.2 `Rotation` と `PieceShape`

各 `PieceKind` × 各回転（0°/90°/180°/270°）について、4 つのセルの相対
座標を **`(rowOffset, colOffset)` の 4 タプル**として静的テーブルに保持。

```text
enum Rotation: Int { case deg0 = 0, deg90, deg180, deg270 }

struct PieceShape {
    let cells: [GridOffset]   // 4 個固定
    let width: Int            // 0..<width が有効列範囲
    let height: Int           // 0..<height が有効行範囲
}

PieceKind.I, .deg0  → cells: [(0,0),(0,1),(0,2),(0,3)],   w=4, h=1
PieceKind.I, .deg90 → cells: [(0,0),(1,0),(2,0),(3,0)],   w=1, h=4
... (全 7 種 × 4 回転 = 28 シェイプ。O は 4 つすべて同形)
```

`width / height` は配置候補列挙時の境界チェックに使う（research R-3）。

### 1.3 ピース色

| Kind | 色（spec Assumption） |
|------|----------------------|
| I | シアン |
| O | 黄 |
| T | 紫 |
| S | 緑 |
| Z | 赤 |
| J | 青 |
| L | オレンジ |

実装では `Asset Catalog` 内の Named Color（`Piece.I`, `Piece.O`, ...）として
登録し、ダーク/ライトの両モードで十分なコントラストを確保する。

---

## 2. 盤面とセル

### 2.1 `Cell`

```text
enum Cell: Equatable {
    case empty
    case filled(PieceKind)   // 配置元の kind を保持して色を決定
}
```

**注意**: 配置後のセルは「個別に滑る」（spec FR-004）。`PieceKind` は色を
決めるためだけに保持し、形（4 セルのグルーピング）は失われる。

### 2.2 `Board`

```text
struct Board: Equatable {
    static let width = 10
    static let height = 10
    private(set) var cells: [[Cell]]   // [row][col]、size = 10x10
}
```

- 不変的に操作する（メソッドは新しい `Board` を返す）。
- `init()` で全マス `.empty`。
- ヘルパ:
  - `isEmpty(at: GridPosition) -> Bool`
  - `place(_ shape: PieceShape, kind: PieceKind, at origin: GridPosition) -> Board`
  - `slid(toward: SlideDirection) -> Board`（research R-3 の純関数）
  - `cleared(rowsToClear: [Int]) -> Board`
  - `fullRows() -> [Int]`（埋まっている横行のインデックス）
  - `placementCandidates(for kind: PieceKind) -> [PiecePlacement]`
  - `==` で「無効スワイプ判定」に使う（spec FR-013）

### 2.3 `SlideDirection` と `PiecePlacement`

```text
enum SlideDirection { case up, down, left, right }

struct PiecePlacement {
    let kind: PieceKind
    let rotation: Rotation
    let origin: GridPosition   // 左上基準のオフセット
}

struct GridPosition: Equatable, Hashable { let row: Int; let col: Int }
struct GridOffset: Equatable, Hashable { let dRow: Int; let dCol: Int }
```

---

## 3. ゲーム進行状態

### 3.1 `GameStatus`

```text
enum GameStatus: Equatable {
    case idle           // メインメニュー表示中
    case playing        // ゲーム中
    case paused         // 一時停止（バックグラウンド復帰待ち）
    case gameOver(finalScore: Int, isNewHighScore: Bool)
}
```

### 3.2 `GameEngine`（中心ハブ、`@Observable`）

```text
@Observable
final class GameEngine {
    private(set) var board: Board
    private(set) var score: Int
    private(set) var nextPiece: PieceKind
    private(set) var status: GameStatus

    init(randomizer: PieceRandomizer = .systemRandom,
         highScoreStore: HighScoreStore,
         soundPlayer: SoundPlayer,
         hapticsPlayer: HapticsPlayer)

    func startNewGame()
    func handleSwipe(_ direction: SlideDirection)
    func togglePause()
    func resumeFromBackground()
}
```

#### 3.2.1 状態遷移

```text
              [tap PLAY]                  [swipe → invalid]
   .idle  ─────────────────►  .playing  ◄─────────────  (状態維持、副作用なし)
                                  │
                                  │  [swipe → valid placement]
                                  │
            ┌─────────────────────┴───────────────────────┐
            ▼                                              ▼
  [next piece fits anywhere]                  [next piece fits nowhere]
            │                                              │
            ▼                                              ▼
        .playing                                  .gameOver(score, isNew)

  .playing  ── [scenePhase != .active] ──►  .paused
  .paused   ── [scenePhase == .active] ──►  .playing
  .gameOver ── [tap PLAY AGAIN] ────────►  startNewGame() → .playing
  .gameOver ── [tap MAIN MENU] ─────────►  .idle
```

#### 3.2.2 `handleSwipe(_:)` の処理シーケンス

```text
1. guard status == .playing else { return }
2. let next = board.slid(toward: direction)
3. let fullRows = next.fullRows()
4. if next == board && fullRows.isEmpty:
       // 無効スワイプ（FR-013）: 何もしない、副作用ゼロ
       return
5. let cleared = next.cleared(rowsToClear: fullRows)
6. score += ScoreCalculator.lineClearPoints(for: fullRows.count)
7. effects: sound + haptics for line clear (or tetris if 4)
8. let candidates = cleared.placementCandidates(for: nextPiece)
9. guard let chosen = candidates.randomElement() else:
       finalize gameOver: status = .gameOver(score, isNewHighScore)
       persist high score, sound + haptics for gameover
       return
10. board = cleared.placed(chosen)
11. score += ScoreCalculator.placementBonus    // +1 (FR-018)
12. effects: sound + haptics for swipe
13. nextPiece = randomizer.next()
```

**ピース「最初の 1 個」**: `startNewGame()` 内で `Board().placementCandidates(for:
firstPiece).randomElement()` を **必ず**取得できる（空盤面なら全 7 種の
すべての回転で多数の候補がある）→ 配置直後にスコア +1（FR-018 + Assumptions）。

---

## 4. スコア計算

### 4.1 `ScoreCalculator`（純粋関数群）

```text
enum ScoreCalculator {
    static func lineClearPoints(for clearedRows: Int) -> Int {
        switch clearedRows {
        case 0: return 0
        case 1: return 100
        case 2: return 300
        case 3: return 500
        case 4: return 800   // テトリス
        default: return 800  // 理論上 5+ は起こり得ないが安全側
        }
    }
    static let placementBonus: Int = 1   // FR-018
}
```

### 4.2 ハイスコア更新

`GameEngine.handleSwipe(_:)` でゲームオーバーが確定した瞬間に、
`HighScoreStore.recordIfHigher(score)` を呼び、戻り値（更新されたか）を
`gameOver(.., isNewHighScore: Bool)` の引数にして View 側で NEW HIGH SCORE
バッジ表示の有無を決める（FR-025）。

---

## 5. 永続化エンティティ

### 5.1 `Settings`（永続化）

```text
struct Settings: Codable, Equatable {
    var soundEnabled: Bool   // default true
    var hapticsEnabled: Bool // default true
}

protocol SettingsStore {
    func load() -> Settings
    func save(_ settings: Settings)
}
```

`UserDefaults` 実装は次のキーを使用（contracts/persistence-contract.md 参照）。

### 5.2 `HighScore`（永続化）

```text
protocol HighScoreStore {
    func current() -> Int
    @discardableResult
    func recordIfHigher(_ score: Int) -> Bool   // true if new high
}
```

### 5.3 `AdConsentState`（永続化）

```text
struct AdConsentState: Codable {
    var attHasPrompted: Bool
    var umpDecisionAt: Date?
}
```

ATT 結果そのものは `ATTrackingManager.trackingAuthorizationStatus` から都度
取得できるので保存不要。プロンプトを 2 回出さないためのガードフラグだけ
保存する。

---

## 6. 画面と View モデルの対応

| Screen | 主要なモデル参照 |
|--------|-----------------|
| MainMenuView | `HighScoreStore.current()`, `Settings`, `GameEngine`（PLAY タップで `startNewGame()`） |
| GameView | `GameEngine`（board / score / nextPiece / status） |
| BoardView / CellView | `Board`, `Cell`, `PieceKind` の色マッピング |
| NextPieceView | `GameEngine.nextPiece`（4×4 ミニグリッドにデフォルト回転で描画） |
| ScoreHUDView | `GameEngine.score`, `HighScoreStore.current()` |
| GameOverOverlay | `GameStatus.gameOver(_, isNewHighScore)` |
| SettingsView | `SettingsStore` |
| AboutView | 静的文言のみ |

---

## 7. テスト容易化のためのプロトコル境界

`GameEngine` は依存を以下の小さなプロトコルで受け取り、テスト時にスタブ
差し替えを可能にする：

```text
protocol PieceRandomizer { func next() -> PieceKind }
protocol HighScoreStore { ... }
protocol SettingsStore { ... }
protocol SoundPlayer { func play(_ sound: GameSound) }
protocol HapticsPlayer { func play(_ haptic: GameHaptic) }
```

`GameSound` / `GameHaptic` は spec FR-028/029 を直接 enum 化したもの：

```text
enum GameSound { case swipe, lineClear, tetris, gameOver }
enum GameHaptic { case swipeLight, lineClearMedium, tetrisStrong, gameOverError }
```

これにより XCTest では Board のスナップショットを与えて `handleSwipe`
の前後を比較するテストが書ける（NumberClashTests/GameEngineTests.swift）。
