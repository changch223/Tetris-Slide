---

description: "Task list for Tetris Slide Game (10x10) — 完全リビルド"
---

# Tasks: Tetris Slide Game (10x10) — 完全リビルド

**Input**: Design documents from `/Users/changchiawei/Desktop/reverse2048/specs/001-tetris-slide-game/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: 含む。憲法 V「Pragmatic Testing」が `Game/` 配下の純関数（盤面 /
滑り / 行消去 / 配置探索 / スコア計算）と save/load ロジックに単体テストを
必須としている。UI スモーク 1 本は quickstart.md §6 に明示されているため
1 本だけ含める。

**Organization**: Tasks are grouped by user story (P1 → P5) で、各ストーリー
が独立にテスト・デプロイ可能になるように整理。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 異なるファイルで依存なしの並列実行可能タスク
- **[Story]**: ユーザーストーリーラベル（US1〜US5）
- ファイルパスはリポジトリルート相対

## Path Conventions

- iOS Xcode プロジェクトの単一 target 構成：
  - アプリソース: `NumberClash/`（target 名は `Reverse2048` を継続）
  - 単体テスト: `NumberClashTests/`
  - UI テスト: `NumberClashUITests/`
  - リソース: `NumberClash/Assets.xcassets/`、`NumberClash/{en,ja,zh-Hans,zh-Hant,zh-HK}.lproj/`、`NumberClash/Sound/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: 既存コードの掃除、新ディレクトリ準備、依存関係再確認

- [X] T001 既存の不要ファイルを削除する: `NumberClash/Classic View.swift`、`NumberClash/ProMax View.swift`、`NumberClash/ReverseView.swift`、`NumberClash/Item.swift`、`NumberClash/AppOpenAdManager.swift`（FR-039、Phase 3 以降の作業はこれら無しで成立）
- [ ] T002 新しいソースディレクトリを作り、Xcode プロジェクトのグループ参照を追加する: `NumberClash/Game/`、`NumberClash/Views/`、`NumberClash/Services/` を `NumberClash.xcodeproj/project.pbxproj` の Reverse2048 ターゲットに登録
- [X] T003 [P] 7 種類のピース色アセットを `NumberClash/Assets.xcassets/` に追加: `PieceI.colorset`、`PieceO.colorset`、`PieceT.colorset`、`PieceS.colorset`、`PieceZ.colorset`、`PieceJ.colorset`、`PieceL.colorset`（標準テトリス配色、light/dark 双方で WCAG コントラスト基準を満たす）
- [ ] T004 [P] `Podfile` の target 名（`Reverse2048`）を確認し、リポジトリルートで `pod install` を実行して `Pods/` を最新化（`Google-Mobile-Ads-SDK` がクリーンビルドできること）

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: すべてのユーザーストーリーが依存するアプリ起動経路と共有型

**⚠️ CRITICAL**: このフェーズが完了するまで User Story 着手不可

- [X] T005 `NumberClash/NumberClashApp.swift` を書き換える: `SwiftData`/`ModelContainer`/`Item.self` の参照を撤去、`AppOpenAdManager` 呼び出しを削除、`MobileAds.shared.start` の即時呼び出しを撤去（後で `AdConsentCoordinator` から呼ぶプレースホルダ `.task` フックを残す）。`scenePhase` 監視はゲームのポーズ/復帰用に残す
- [X] T006 `NumberClash/ContentView.swift` を `MainMenuView` をホストする薄いルートビューに書き換える（`NavigationStack` 採用、`MainMenuView` は次フェーズで実装するため一時的に空ビューを返す型を仮置き）
- [X] T007 共有ゲーム型を `NumberClash/Game/GameTypes.swift` に定義: `GridPosition`（row, col）、`GridOffset`（dRow, dCol）、`SlideDirection`（up/down/left/right）、`GameStatus`（idle/playing/paused/gameOver(Int, Bool)）

**Checkpoint**: ビルドが通り、空のメイン画面が起動する状態。User Story 並行着手可能。

---

## Phase 3: User Story 1 — コアゲームプレイ (Priority: P1) 🎯 MVP

**Goal**: プレイヤーが 10×10 盤面でテトリスピースを 2048 風にスワイプして
動かし、横一行を揃えて消し、ピースが置けなくなるまでスコアを稼げる。
これが MVP の核心。

**Independent Test**: アプリを起動 → PLAY ボタンタップ → 盤面表示と最初の
ピース配置 → 数十回スワイプで盤面が滑り行が消えスコアが増える → 意図的に
盤面を埋めてゲームオーバー画面到達 → PLAY AGAIN で再開できることを実機 1 台
で確認。

### Tests for User Story 1 ⚠️ (write FIRST and verify they FAIL)

- [X] T008 [P] [US1] `NumberClashTests/BoardTests.swift`: 空 Board 生成、`isEmpty(at:)`、`place(_:kind:at:)` の前後比較、`==` の同値判定、`fullRows()` が満杯行のインデックス配列を返すこと、空盤面と部分埋まり盤面の両ケースを検証
- [X] T009 [P] [US1] `NumberClashTests/SlideEngineTests.swift`: 4 方向のスライドで全セルが端まで詰まること、`合体しない`こと（FR-012）、空盤面と全埋まり盤面では no-op になること、ランダムパターンで idempotency を確認
- [X] T010 [P] [US1] `NumberClashTests/LineClearerTests.swift`: 単一行・複数行（最大 4）の消去、消えた行より上のセルが「下に詰めない」こと（FR-016）、消去対象が無い場合の no-op
- [X] T011 [P] [US1] `NumberClashTests/PiecePlacementTests.swift`: 全 7 ピース × 4 回転 = 28 シェイプの座標が正しいこと、空盤面で多数の候補があること、ほぼ満杯の盤面で候補ゼロが返ること、候補の `randomElement()` 抽選が一様であること（種固定で複数試行）
- [X] T012 [P] [US1] `NumberClashTests/ScoreCalculatorTests.swift`: `lineClearPoints(for:)` が 0/1/2/3/4 行に対し 0/100/300/500/800 を返すこと（FR-017）、`placementBonus` が 1 であること（FR-018）
- [X] T013 [P] [US1] `NumberClashTests/GameEngineTests.swift`: `startNewGame()` 後の状態（盤面 1 ピース配置済み、score = 1、status = .playing）、`handleSwipe` の有効遷移、無効スワイプでの no-op（FR-013）、ピース配置不能時の `.gameOver` 遷移、ゲームオーバー時の `isNewHighScore` フラグ計算（スタブ HighScoreStore で）

### Implementation for User Story 1

- [X] T014 [P] [US1] `NumberClash/Game/PieceKind.swift`: `enum PieceKind: CaseIterable { case I, O, T, S, Z, J, L }` と各 case → Asset Catalog の Named Color へのマッピング `var colorAssetName: String`
- [X] T015 [P] [US1] `NumberClash/Game/PieceShape.swift`: `enum Rotation: Int { case deg0, deg90, deg180, deg270 }` と `struct PieceShape { let cells: [GridOffset]; let width: Int; let height: Int }` を定義
- [X] T016 [US1] `NumberClash/Game/PieceShape.swift`: 28 個（7 kind × 4 rotation）の静的シェイプテーブルを `PieceKind.shape(for: Rotation) -> PieceShape` で公開（T015 に追記、O は 4 回転すべて同形）
- [X] T017 [P] [US1] `NumberClash/Game/Cell.swift`: `enum Cell: Equatable { case empty; case filled(PieceKind) }`
- [X] T018 [US1] `NumberClash/Game/Board.swift`: `struct Board: Equatable` を定義、内部に `cells: [[Cell]]`（10×10）、`init()` で全マス `.empty`、メソッド `isEmpty(at:)`、`placed(_ shape: PieceShape, kind: PieceKind, at origin: GridPosition) -> Board`、`fullRows() -> [Int]`、`cleared(rowsToClear: [Int]) -> Board`（依存: T007、T015、T017）
- [X] T019 [P] [US1] `NumberClash/Game/PieceRandomizer.swift`: `protocol PieceRandomizer { func next() -> PieceKind }` と一様ランダム実装 `struct SystemRandomPieceRandomizer: PieceRandomizer`、テスト用 `struct DeterministicRandomizer: PieceRandomizer` を提供（依存: T014）
- [X] T020 [US1] `NumberClash/Game/SlideEngine.swift`: `enum SlideEngine` 名前空間に純関数 `static func slid(_ board: Board, toward direction: SlideDirection) -> Board`。各行 / 列を方向に応じて詰める実装（依存: T018）
- [X] T021 [US1] `NumberClash/Game/LineClearer.swift`: `enum LineClearer` 名前空間に純関数 `static func clearFullRows(_ board: Board) -> (board: Board, clearedRows: [Int])`（依存: T018）
- [X] T022 [US1] `NumberClash/Game/PiecePlacement.swift`: `struct PiecePlacement { let kind: PieceKind; let rotation: Rotation; let origin: GridPosition }` と `extension Board { func placementCandidates(for kind: PieceKind) -> [PiecePlacement] }`（research R-3 の素朴な総当たり、依存: T015、T016、T017、T018）
- [X] T023 [P] [US1] `NumberClash/Game/ScoreCalculator.swift`: `enum ScoreCalculator { static func lineClearPoints(for clearedRows: Int) -> Int; static let placementBonus: Int = 1 }`（FR-017、FR-018）
- [X] T024 [US1] `NumberClash/Game/GameEngine.swift`: `@Observable final class GameEngine`。data-model.md §3.2 の API（`startNewGame`、`handleSwipe(_:)`、`togglePause`、`resumeFromBackground`）と §3.2.2 の処理シーケンスを実装。`handleSwipe` は SlideEngine→LineClearer→ScoreCalculator→PiecePlacement の合成。HighScoreStore は今フェーズではダミー実装（恒に false を返す）を注入する（依存: T018、T019、T020、T021、T022、T023）
- [X] T025 [P] [US1] `NumberClash/Views/CellView.swift`: `struct CellView: View` が `cell: Cell` を受け取り `.empty` は淡い背景、`.filled(kind)` は対応 Asset Color の角丸矩形を描画（依存: T014、T017）
- [X] T026 [US1] `NumberClash/Views/BoardView.swift`: `struct BoardView: View` が `board: Board` をバインドし、10×10 の `LazyVGrid` で `CellView` を並べる。盤面は正方形にレイアウト（依存: T025、T018）
- [X] T027 [US1] `NumberClash/Views/BoardView.swift`: `DragGesture(minimumDistance: 0)` を盤面領域だけにバインドし、`.onEnded` で 30pt 閾値 + 軸支配比 1.5x で 4 方向に分類して `engine.handleSwipe(_:)` を呼ぶ（research R-1、依存: T026、T024）
- [X] T028 [P] [US1] `NumberClash/Views/NextPieceView.swift`: `struct NextPieceView: View` が `kind: PieceKind` を受け取り 4×4 のミニグリッドにデフォルト回転（`.deg0`）の形状を描画（依存: T015、T025）
- [X] T029 [P] [US1] `NumberClash/Views/ScoreHUDView.swift`: `struct ScoreHUDView: View` が現在スコアを大きめのフォントで表示（依存なし）
- [X] T030 [P] [US1] `NumberClash/Views/GameOverOverlay.swift`: `struct GameOverOverlay: View` が `finalScore: Int`, `isNewHighScore: Bool`, `onPlayAgain: () -> Void`, `onMainMenu: () -> Void` を受け取り、半透明オーバーレイ + NEW HIGH SCORE バッジ（フラグが true のとき）+ 2 ボタンを表示（依存: T024）
- [X] T031 [US1] `NumberClash/Views/GameView.swift`: `struct GameView: View` が `@State engine: GameEngine` を保持し、上から `ScoreHUDView` + `NextPieceView` + `BoardView` を縦積み。`status == .gameOver` のとき `GameOverOverlay` を `.overlay` で表示。BoardView に DragGesture が付く（依存: T026、T028、T029、T030、T024）
- [X] T032 [P] [US1] `NumberClash/Views/MainMenuView.swift`: `struct MainMenuView: View` がタイトル + 「PLAY」ボタン（タップで `GameView` に NavigationLink）+ HIGH SCORE 行（今フェーズはダミー値 0 表示）を持つ（依存: T024）
- [X] T033 [US1] `NumberClashUITests/EndlessSmokeUITests.swift`: アプリ起動 → PLAY ボタンタップ → 盤面の中央付近で右スワイプ × 5 → スコアが 0 から増えていることを assert → アプリ終了。XCUIElement の swipe API を使用（依存: T031、T032）

**Checkpoint**: User Story 1 単独で完全プレイ可能（ハイスコア永続化、音、
ロケール、広告なしの素のゲーム）。MVP 達成。

---

## Phase 4: User Story 2 — ハイスコア永続化 (Priority: P2)

**Goal**: ハイスコアを `UserDefaults` に保存し、アプリ再起動後も表示。
新記録時はゲームオーバー画面で祝福。

**Independent Test**: 1 ゲームでスコア達成 → アプリを完全終了 → 再起動 →
メイン画面に前回ハイスコアが表示 → 新ゲームで上回ると NEW HIGH SCORE
バッジが表示されることを実機で確認。

### Tests for User Story 2 ⚠️

- [X] T034 [P] [US2] `NumberClashTests/HighScoreStoreTests.swift`: `UserDefaults(suiteName: "test-\(UUID())")` をストアに注入し、初期値 0、`recordIfHigher` の更新ロジック（高い場合 true、同値・低い場合 false）、再ロード後の永続性をテスト

### Implementation for User Story 2

- [X] T035 [P] [US2] `NumberClash/Services/HighScoreStore.swift`: `protocol HighScoreStore { func current() -> Int; @discardableResult func recordIfHigher(_ score: Int) -> Bool }` と `final class UserDefaultsHighScoreStore: HighScoreStore`（キー `tetris2048.highScore`、persistence-contract.md 準拠）
- [X] T036 [US2] `NumberClash/Game/GameEngine.swift` の修正: T024 のダミー HighScoreStore 注入を `UserDefaultsHighScoreStore` に置き換え、ゲームオーバー遷移時に `recordIfHigher(score)` を呼んで戻り値を `GameStatus.gameOver(_, isNewHighScore:)` に渡す（依存: T024、T035）
- [X] T037 [US2] `NumberClash/Views/MainMenuView.swift` と `NumberClash/Views/GameOverOverlay.swift` の修正: MainMenu のハイスコア行を `HighScoreStore.current()` の値に差し替え、GameOverOverlay の NEW HIGH SCORE バッジを `isNewHighScore` フラグに連動させる（依存: T035、T032、T030）

**Checkpoint**: User Story 1 + 2 が動作。ハイスコアが永続的に記録される。

---

## Phase 5: User Story 3 — 効果音とハプティクス (Priority: P3)

**Goal**: 4 イベント（スワイプ・通常行消去・テトリス・ゲームオーバー）で
効果音と段階的ハプティクスを再生。Settings 画面で音/振動を独立にトグル可能。

**Independent Test**: Settings で両方 ON → 1 ゲーム遊んでスワイプ・通常消し・
テトリス・ゲームオーバーで違う音と振動が鳴る → 両方 OFF → 同じ操作で無音・
無振動になることを実機で確認。

### Tests for User Story 3 ⚠️

- [X] T038 [P] [US3] `NumberClashTests/SettingsStoreTests.swift`: 注入した `UserDefaults(suiteName:)` で初期値（true/true）、各キーへの保存と読み戻し、persistence-contract.md のキー名一致を検証

### Implementation for User Story 3

- [X] T039 [US3] `NumberClash/Services/SettingsStore.swift`: `struct Settings: Codable, Equatable { var soundEnabled: Bool; var hapticsEnabled: Bool }` と `protocol SettingsStore { func load() -> Settings; func save(_ settings: Settings) }` + `final class UserDefaultsSettingsStore: SettingsStore`（キー `tetris2048.settings.soundEnabled`、`tetris2048.settings.hapticsEnabled`）
- [X] T040 [US3] `NumberClash/Services/SoundPlayer.swift`: `enum GameSound { case swipe, lineClear, tetris, gameOver }` と `protocol SoundPlayer { func play(_ sound: GameSound) }` + `final class AVAudioSoundPlayer: SoundPlayer`。起動時に 4 個の `AVAudioPlayer` を `prepareToPlay()` 済みで保持、`play` で `currentTime = 0` リセットして再生。`SettingsStore.load().soundEnabled` が false なら early return（research R-5、依存: T039）
- [X] T041 [US3] `NumberClash/Services/HapticsPlayer.swift`: `enum GameHaptic { case swipeLight, lineClearMedium, tetrisStrong, gameOverError }` と `protocol HapticsPlayer { func play(_ haptic: GameHaptic) }` + `final class UIFeedbackHapticsPlayer: HapticsPlayer`。research R-6 のマッピング（`UIImpactFeedbackGenerator(.light/.medium)`、`UINotificationFeedbackGenerator.success/.error`）。`SettingsStore.load().hapticsEnabled` が false なら early return（依存: T039）
- [X] T042 [P] [US3] 既存の `NumberClash/Sound/` ディレクトリの中身を全削除し、新規録り下ろしの `swipe.wav`、`clear.wav`、`tetris.wav`、`gameover.wav`（各 < 1 秒、44.1kHz）を配置。Xcode の Reverse2048 ターゲットの Copy Bundle Resources にこれら 4 ファイルを登録
- [X] T043 [US3] `NumberClash/Game/GameEngine.swift` の修正: イニシャライザに `SoundPlayer` と `HapticsPlayer` を注入できるようにし、`handleSwipe` の各イベントポイント（有効スワイプ完了、行消去、テトリス、ゲームオーバー）で対応する `play(_:)` を呼ぶ（依存: T024、T040、T041）
- [X] T044 [US3] `NumberClash/Views/SettingsView.swift`: `struct SettingsView: View` に効果音 `Toggle` とハプティクス `Toggle` の 2 行。値変更時に `SettingsStore.save(...)` を即時実行（依存: T039）
- [X] T045 [US3] `NumberClash/Views/MainMenuView.swift` の修正: SETTINGS ボタン（`NavigationLink`）を追加して `SettingsView` を開けるようにする（依存: T044、T032）

**Checkpoint**: 音・触感・設定 ON/OFF が動く。ゲームの感触が完成。

---

## Phase 6: User Story 4 — 多言語対応 (Priority: P3)

**Goal**: en / ja / zh-Hans / zh-Hant / zh-HK の 5 ロケールで全 UI 文字列を
表示。ハードコード文字列ゼロ。

**Independent Test**: iOS の言語設定で 5 言語を順に切り替え、メニュー・
ゲーム画面・ゲームオーバー・設定・About のすべての文字列が翻訳されレイアウト
崩れがないことを目視確認。

### Implementation for User Story 4

- [X] T046 [P] [US4] `NumberClash/en.lproj/Localizable.strings`: 既存内容を全削除し、新ゲームの全キー（タイトル、PLAY、HIGH SCORE、SCORE、NEXT、PAUSE、GAME OVER、NEW HIGH SCORE、PLAY AGAIN、MAIN MENU、SETTINGS、SOUND、HAPTICS、ABOUT、ATT 説明文 など）を英語で記述
- [X] T047 [P] [US4] `NumberClash/ja.lproj/Localizable.strings`: T046 と同じキー一覧を日本語訳で記述
- [X] T048 [P] [US4] `NumberClash/zh-Hans.lproj/Localizable.strings`: 簡体字中国語訳
- [X] T049 [P] [US4] `NumberClash/zh-Hant.lproj/Localizable.strings`: 繁體中文訳
- [X] T050 [P] [US4] `NumberClash/zh-HK.lproj/Localizable.strings`: 香港中文訳
- [X] T051 [US4] 全 View ファイルのハードコード文字列を `String(localized: "KEY")` または `Text("KEY")` 経由に置き換える（対象: `NumberClash/Views/MainMenuView.swift`、`NumberClash/Views/GameView.swift`、`NumberClash/Views/ScoreHUDView.swift`、`NumberClash/Views/GameOverOverlay.swift`、`NumberClash/Views/SettingsView.swift`、`NumberClash/Views/AboutView.swift`、依存: T046〜T050）
- [X] T052 [US4] `NumberClash/Views/BoardView.swift` に `accessibilityAction(named:)` を 4 方向ぶん追加（VoiceOver 用、文言は Localizable のキー `KEY_A11Y_SWIPE_UP/DOWN/LEFT/RIGHT`、依存: T026、T046〜T050）

**Checkpoint**: 5 言語完全パリティ。憲法 III 適合。

---

## Phase 7: User Story 5 — バナー広告と同意フロー (Priority: P3)

**Goal**: AdMob バナーをゲーム画面下部に表示。初回起動時に UMP（GDPR）→
ATT の順で同意取得し、その後で AdMob を初期化。プレイは追跡同意の有無に
関わらず全機能動作。

**Independent Test**: 完全削除後の初回起動で UMP/ATT プロンプトが順に出る
→ ゲーム画面下部にテストバナー広告が表示 → 盤面でスワイプしてもバナー
位置で誤反応しない → ATT「許可しない」を選んでも全機能動作することを実機
で確認。

### Implementation for User Story 5

- [X] T053 [US5] 既存の `NumberClash/BannerAdView.swift` を `NumberClash/Services/BannerAdView.swift` に移動し、`UIViewRepresentable` の `GADBannerView`（または最新 SDK の `BannerView`）ラッパーを最小修正で再利用。広告ユニット ID は dev/prod スイッチ可能な定数で参照
- [X] T054 [US5] `NumberClash/Services/AdConsentCoordinator.swift`: `final class AdConsentCoordinator` を作成。`func start() async` 内で UMP の `requestConsentInfoUpdate` → `presentIfRequired` → `ATTrackingManager.requestTrackingAuthorization` → `MobileAds.shared.start(...)` を直列実行。完了後に `tetris2048.consent.attHasPrompted = true`、`tetris2048.consent.umpDecisionAt = Date()` を保存（research R-4、persistence-contract.md）
- [X] T055 [US5] `NumberClash/NumberClashApp.swift` の修正: `body` の `WindowGroup { ContentView()... }` に `.task { await AdConsentCoordinator().start() }` を付加し、起動時に同意フローを 1 度だけ実行（`attHasPrompted` が true のときは UMP 再評価のみで ATT は再表示しない、依存: T054、T005）
- [X] T056 [US5] `NumberClash/Views/GameView.swift` の修正: 画面下部に `BannerAdView` を `safeAreaInset(edge: .bottom)` で配置し、`BoardView` の DragGesture 領域とは絶対に重ならないレイアウトを取る（FR-034、依存: T031、T053）
- [X] T057 [US5] `NumberClash/Info.plist` の修正: `NSUserTrackingUsageDescription` を 5 言語ぶん（`InfoPlist.strings` 経由）追加し、既存の `GADApplicationIdentifier` と `SKAdNetworkItems` を維持
- [X] T058 [US5] `NumberClash/PrivacyInfo.xcprivacy` を作成（または更新）し、AdMob が要求する Required Reasons API 区分（UserDefaults、SystemBootTime 等）を宣言。Reverse2048 ターゲットの Copy Bundle Resources に登録

**Checkpoint**: User Story 1〜5 すべて完了。リリース候補としての機能要件
を満たす。

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: アイコン差し替え、About 文言更新、リリース前総合検証

- [X] T059 [P] `NumberClash/Assets.xcassets/AppIcon.appiconset/` の中身を新しいテトリス風アイコン（必要全サイズ）に差し替え、`Contents.json` を更新
- [X] T060 [P] `ICON/` ディレクトリの中身を、新ロゴのソース（PNG/SVG/PSD 等のデザインソース）に差し替え。リポジトリには version-controlled な PNG のみ含める
- [X] T061 既存の `NumberClash/AboutView.swift` を `NumberClash/Views/AboutView.swift` に移動し、文言を新ゲーム用に書き換え。クレジット・バージョン表記も最新化（依存: T051 と同じローカライズキーを使用）
- [ ] T062 quickstart.md §4 の「1 セッション通しプレイ」スモークパスを実機 1 台で実施し、結果を PR の Test Plan セクションに記録（憲法 V の必須リリースゲート）
- [ ] T063 [P] `xcodebuild test -workspace NumberClash.xcworkspace -scheme Reverse2048 -destination 'platform=iOS Simulator,name=iPhone 15'` を実行し、`NumberClashTests` 全グリーン + `NumberClashUITests/EndlessSmokeUITests` 1 本グリーンを確認
- [ ] T064 リリース直前の最終確認: バンドル ID = `CHIA.ProMaxHardReverse2048`、バージョン番号インクリメント、AdMob 広告ユニット ID を本番に切替、App Store Connect の App Privacy 申告が現状の SDK 構成と一致することを確認

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 依存なし、即時着手可
- **Foundational (Phase 2)**: Setup 完了後、すべての User Story を**ブロック**
- **User Story 1 (Phase 3)**: Foundational 完了後着手可。MVP の中核。
- **User Story 2 (Phase 4)**: User Story 1 完了後（GameEngine 拡張のため）
- **User Story 3 (Phase 5)**: User Story 1 完了後（GameEngine 拡張のため）
- **User Story 4 (Phase 6)**: User Story 1〜3 の Views が概ね揃った後（文字列置換のため）。実用上は User Story 1 完了後から並行可能
- **User Story 5 (Phase 7)**: User Story 1 完了後（GameView レイアウト調整のため）。User Story 2〜4 とは並行可能
- **Polish (Phase 8)**: User Story 1〜5 完了後

### User Story Dependencies

- **US1**: Foundational のみに依存
- **US2**: US1 の `GameEngine`、`GameOverOverlay`、`MainMenuView` に依存
- **US3**: US1 の `GameEngine`、`MainMenuView` に依存。US2 とは独立
- **US4**: US1〜US3 の Views が完成しているほど影響範囲が明確。実装は US1 完了後から開始可、US2/US3 と並行可
- **US5**: US1 の `GameView`、`NumberClashApp.swift` に依存。US2〜US4 と並行可

### Within Each User Story

- Tests（含まれる場合）は実装の **前**に書き、まず FAIL することを確認
- Models → Services / 純関数 → ViewModels / Views の順
- 1 ファイルだけ修正するタスク同士でも、同じファイルを触るタスクは **直列**

### Parallel Opportunities

- **Phase 1**: T003 と T004 は並列実行可
- **Phase 3 (US1) Tests**: T008〜T013 はすべて別ファイルなので 6 並列可
- **Phase 3 (US1) Models**: T014、T015、T017、T019、T023 は並列可（T016/T018/T020/T021/T022/T024 は依存があるため直列）
- **Phase 3 (US1) Views**: T025、T028、T029、T030、T032 は並列可（T026/T027/T031 は依存）
- **Phase 6 (US4) Localization**: T046〜T050 の 5 ロケールは並列実行可（同じキーセットを各言語で書く）
- **Phase 8**: T059、T060、T063 は並列可

---

## Parallel Example: User Story 1 のテスト一斉立ち上げ

```bash
# 6 個のテストファイルを同時並行で書き始める：
Task: "BoardTests.swift in NumberClashTests/"
Task: "SlideEngineTests.swift in NumberClashTests/"
Task: "LineClearerTests.swift in NumberClashTests/"
Task: "PiecePlacementTests.swift in NumberClashTests/"
Task: "ScoreCalculatorTests.swift in NumberClashTests/"
Task: "GameEngineTests.swift in NumberClashTests/"
```

その直後、データモデル / 純関数の独立タスク群も並列起動可能：

```bash
Task: "PieceKind.swift in NumberClash/Game/"
Task: "PieceShape.swift (型定義のみ) in NumberClash/Game/"
Task: "Cell.swift in NumberClash/Game/"
Task: "PieceRandomizer.swift in NumberClash/Game/"
Task: "ScoreCalculator.swift in NumberClash/Game/"
```

---

## Implementation Strategy

### MVP First (User Story 1 のみ)

1. Phase 1: Setup を完了
2. Phase 2: Foundational を完了（**全 US をブロック**）
3. Phase 3: User Story 1 を完了
4. **STOP & VALIDATE**: アプリを起動 → PLAY → 数十手 → ゲームオーバー
   までを実機で確認。MVP 完成。
5. ハイスコア・音・ロケール・広告なしの状態だが、**遊べる**ことが
   分岐点。

### Incremental Delivery

1. MVP（US1）→ 開発者体験で「ちゃんと遊べる」確認
2. + US2（ハイスコア永続化）→ リプレイ意欲を支える状態に
3. + US3（音・ハプティクス）→ 触感の完成
4. + US4（5 ロケール）→ 既存ユーザーへの公平性確保
5. + US5（広告と同意）→ 収益化と法令遵守
6. + Polish（アイコン・About・最終スモーク）→ リリース候補

### Solo Developer Strategy

1 人開発のため**並列開発は前提としない**が、各 User Story 内で独立タスク
を時間的に並行して進めることで集中力を保ち、コミット粒度を小さくする。
特に Phase 6（5 ロケール翻訳）は 5 ファイルの作業を 1 セッションで通すと
効率が良い。

---

## Notes

- [P] タスク = 別ファイルかつ着手時点で依存タスクが完了済み
- [Story] ラベルは US1〜US5 のいずれか。Setup / Foundational / Polish には付かない
- 各 User Story は独立にテスト可能（Independent Test 欄を参照）
- 実装の前にテストが FAIL することを確認（憲法 V の Pragmatic Testing 適用範囲）
- 各タスク後または論理単位ごとにコミット推奨（`/speckit-git-commit`）
- どの Checkpoint でも止めて検証可能。あえて User Story 1 だけで一旦
  TestFlight に出して反応を見るのも選択肢
- 避けるべきこと: 同じファイルを触るタスクの「並列」起動、ストーリー間の
  暗黙的依存、テストを後回しにすること
