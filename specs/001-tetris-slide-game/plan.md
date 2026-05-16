# Implementation Plan: Tetris Slide Game (10x10) — 完全リビルド

**Branch**: `001-tetris-slide-game` | **Date**: 2026-05-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-tetris-slide-game/spec.md`

## Summary

既存 2048 系コード（Classic/ProMax/Reverse の 3 モード、SwiftData の Item モデル、
AppOpen 広告まわり）をすべて削除し、SwiftUI ネイティブの 10×10「テトリス×2048」
ゲームに完全リビルドする。

技術アプローチの要点：

- **状態モデル**: `GameEngine`（`@Observable` クラス）が 10×10 の `Board`、現在
  スコア、`NEXT` ピース、ゲーム進行状態を保持する。スワイプ操作は純関数として
  実装した「滑り」「行消去」「ピース配置」の合成で表現する。
- **SwiftUI 中心**: 主要画面（MainMenu / Game / GameOver / Settings / About）
  はすべて SwiftUI。AdMob のバナーは既存の `BannerAdView` (UIViewRepresentable)
  ラッパーをそのまま流用する。
- **永続化**: ハイスコアと設定（音 / ハプティクス）は `UserDefaults` 直書き。
  既存の SwiftData (`Item.self`) と `ModelContainer` は撤去する。
- **広告とプライバシー**: AdMob バナーのみ。ATT 許諾と UMP（GDPR 同意）は
  起動シーケンスで `AdConsentCoordinator` が直列処理する。AppOpen 広告と
  Interstitial は撤去。
- **ローカライズ**: 既存 5 ロケール（en / ja / zh-Hans / zh-Hant / zh-HK）の
  `Localizable.strings` を新ゲーム用に総入れ替え。SwiftUI 側はすべて
  `String(localized:)` または `Text("KEY")` 経由で参照する。
- **音とハプティクス**: 軽量な `SoundPlayer`（AVAudioPlayer ラッパー）と
  `HapticsPlayer`（UIFeedbackGenerator）を Service レイヤーに用意。Sound/ と
  ICON/ ディレクトリは中身を新規アセットに差し替える。

## Technical Context

**Language/Version**: Swift 5.0
**Primary Dependencies**: SwiftUI、Google-Mobile-Ads-SDK（既存 Podfile 維持）、
UserMessagingPlatform（UMP、AdMob SDK 同梱）、AppTrackingTransparency、AVFoundation、
UIKit（最小限：UIFeedbackGenerator と既存の BannerAdView ラッパーのみ）
**Storage**: `UserDefaults`（HighScore、Settings、ATT/UMP の状態キャッシュ）
**Testing**: XCTest（`NumberClashTests` ターゲット）でゲームエンジン純関数の単体
テスト。XCUITest（`NumberClashUITests` ターゲット）で起動 → PLAY → ゲームオー
バーまでのスモーク 1 本。
**Target Platform**: iOS 17.6+（既存 Xcode 設定を継承）、iPhone + iPad（既存
TARGETED_DEVICE_FAMILY = "1,2"）
**Project Type**: mobile-app（単一 iOS Xcode プロジェクト、target 名は
`Reverse2048` を継続）
**Performance Goals**: スワイプ成立から盤面アニメ完了まで 200 ms 以内、対応
端末で 60 fps を維持（憲法 II）
**Constraints**: ATT「許可しない」でも全機能動作、5 ロケール完全パリティ、
既存 Bundle ID `CHIA.ProMaxHardReverse2048` を継続使用
**Scale/Scope**: ~12 SwiftUI ビュー、~7 ゲームロジックファイル、永続化キー数
3〜5 個、外部 SDK は AdMob 1 個のみ

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

憲法 v1.0.0 の 5 原則に対する評価：

| # | 原則 | 状態 | 根拠 |
|---|------|------|------|
| I | SwiftUI-Native Simplicity | ✅ PASS | 全画面 SwiftUI。UIKit 利用は AdMob バナーラッパー（既存 `BannerAdView`）と `UIFeedbackGenerator` のみで、いずれも SwiftUI に未対応の機能を補う最小限のアダプタ。 |
| II | Player-First UX | ✅ PASS | 60 fps 目標、無効スワイプはターン消費しない、バナー広告は盤面ジェスチャー領域と重ならない、Interstitial / AppOpen 廃止でプレイ中の中断ゼロ。 |
| III | Localization Parity | ✅ PASS | 既存 5 ロケールを維持し、すべての UI 文言を `Localizable.strings` 経由に統一。新規追加文言も同時に 5 ロケール更新（後述 quickstart のレビューチェックに含む）。 |
| IV | Ads & Privacy Compliance | ✅ PASS | ATT 許諾 → UMP 同意 → AdMob 初期化の順序を `AdConsentCoordinator` で直列化。バナーのみ、Interstitial / AppOpen は撤去。Privacy Manifest と App Privacy 申告を SDK 構成に合わせて更新。 |
| V | Pragmatic Testing | ✅ PASS | ゲームコアロジック（盤面、滑り、行消去、配置探索、スコア計算）に XCTest を入れる。リリース前に quickstart.md のスモークパスを実機で実施。 |

**Initial Constitution Check**: PASS（違反なし、Complexity Tracking は空）

## Project Structure

### Documentation (this feature)

```text
specs/001-tetris-slide-game/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── gesture-contract.md
│   └── persistence-contract.md
└── tasks.md             # Phase 2 output (created by /speckit-tasks, not here)
```

### Source Code (repository root)

mobile-app（単一 iOS プロジェクト）の構成。既存ファイルの一部は削除、一部は
中身を書き換える。

```text
NumberClash/                       # アプリ target ソースフォルダ（既存名を継続）
├── NumberClashApp.swift           # 書き換え: AdMob/ATT 初期化、SwiftData 撤去
├── ContentView.swift              # 書き換え: ルートを MainMenuView に
├── Game/                          # 新規: ゲームエンジン（純粋ロジック）
│   ├── Piece.swift                # 7 種類の形・回転・色
│   ├── Board.swift                # 10x10 グリッドと不変操作
│   ├── PieceRandomizer.swift      # 一様ランダム抽選
│   ├── PiecePlacement.swift       # 配置候補列挙とランダム選択
│   ├── SlideEngine.swift          # 4 方向の滑り処理（純関数）
│   ├── LineClearer.swift          # 行検出と消去
│   ├── ScoreCalculator.swift      # FR-017/018 の点数計算
│   └── GameEngine.swift           # @Observable 状態機械（中心ハブ）
├── Views/                         # 新規: SwiftUI 画面
│   ├── MainMenuView.swift         # PLAY / SETTINGS / ABOUT、ハイスコア表示
│   ├── GameView.swift             # 盤面 + HUD + バナー、ジェスチャー認識
│   ├── BoardView.swift            # 10x10 グリッド描画
│   ├── CellView.swift             # 単一セル描画
│   ├── NextPieceView.swift        # NEXT プレビュー（4x4 ミニグリッド）
│   ├── ScoreHUDView.swift         # スコア + ハイスコア表示
│   ├── GameOverOverlay.swift      # 半透明オーバーレイ
│   ├── SettingsView.swift         # 音 / ハプティクス トグル
│   └── AboutView.swift            # 既存を流用、文言更新
├── Services/                      # 新規 + 既存ラッパーの再配置
│   ├── HighScoreStore.swift       # UserDefaults
│   ├── SettingsStore.swift        # UserDefaults
│   ├── SoundPlayer.swift          # AVAudioPlayer ラッパー
│   ├── HapticsPlayer.swift        # UIFeedbackGenerator ラッパー
│   ├── AdConsentCoordinator.swift # ATT + UMP の直列フロー
│   └── BannerAdView.swift         # 既存ファイルから流用（最小修正）
├── Resources/
│   ├── Sound/                     # ★中身を入れ替え: swipe/clear/tetris/gameover
│   ├── Assets.xcassets/           # ★AppIcon と各ピース色アセットを差し替え
│   ├── en.lproj/Localizable.strings    # ★中身を入れ替え
│   ├── ja.lproj/Localizable.strings    # ★中身を入れ替え
│   ├── zh-Hans.lproj/Localizable.strings  # ★中身を入れ替え
│   ├── zh-Hant.lproj/Localizable.strings  # ★中身を入れ替え
│   └── zh-HK.lproj/Localizable.strings    # ★中身を入れ替え
├── Info.plist                     # 既存維持: GADApplicationIdentifier、SKAdNetworkItems
└── NumberClash.entitlements       # 既存維持

NumberClashTests/                  # XCTest 単体
├── BoardTests.swift               # 滑りロジックの境界
├── SlideEngineTests.swift
├── LineClearerTests.swift
├── PiecePlacementTests.swift      # 候補列挙の正確性
├── ScoreCalculatorTests.swift     # FR-017/018
└── GameEngineTests.swift          # 状態遷移統合

NumberClashUITests/                # XCUITest スモーク
└── EndlessSmokeUITests.swift      # 起動 → PLAY → 数手 → ゲームオーバー復帰

ICON/                              # ★中身を入れ替え: 新ロゴ / 各サイズアプリアイコン
ScreenShoot/                       # 既存維持（App Store スクショ）
Pods/                              # CocoaPods 自動生成、編集不要
Podfile                            # 既存維持: pod 'Google-Mobile-Ads-SDK'
Podfile.lock                       # CocoaPods 自動生成

[削除対象]
NumberClash/Classic View.swift
NumberClash/ProMax View.swift
NumberClash/ReverseView.swift
NumberClash/Item.swift             # SwiftData モデル、ゲームでは未使用
NumberClash/AppOpenAdManager.swift # AppOpen 広告は廃止（FR-035）
```

**Structure Decision**: 単一 Xcode プロジェクト + 単一アプリ target（既存
`Reverse2048` を継続）。`Game/` を純粋ロジック層として独立させて XCTest が
`@testable import` できる構造にする。`Views/` と `Services/` は SwiftUI と
プラットフォーム依存の境界。`Resources/` 配下の `Sound/` `*.lproj/` 
`Assets.xcassets` は Xcode の File Reference 経由で target に含める（実装時
タスクで Xcode プロジェクトファイルへの参照追加が必要）。

## Phase 0: Outline & Research → research.md

詳細は [research.md](./research.md) に記載。本プランから派生した調査項目は
以下のとおり：

1. SwiftUI でのスワイプジェスチャー実装パターン（DragGesture vs
   `.onSwipe`）と、無効スワイプを取り消す方法
2. 100 セル同時アニメーションを 60 fps で回すための SwiftUI 戦術
   （`.animation` の効率、`Canvas` 採用判断、`@Observable` のリビルド粒度）
3. テトリスピース 7 種の形状定義と、4 回転 + 全位置の配置候補列挙アルゴリ
   ズム（10×10 で実用的に <10ms 完了する設計）
4. AdMob UMP（User Messaging Platform）の SwiftUI からの利用パターンと
   ATT との順序問題
5. AVAudioPlayer による短い効果音再生のベストプラクティス
   （プールせず都度生成 vs 事前ロード）
6. UIFeedbackGenerator vs CoreHaptics の使い分け（短くて軽いゲーム触感
   なら UIFeedbackGenerator で十分か）
7. iOS 17.6 + SwiftData の `ModelContainer` を撤去しても既存ストア（旧
   バージョンのユーザー）に副作用が無いか

**Output**: `research.md` に上記 7 項目の Decision / Rationale / Alternatives
を記録（NEEDS CLARIFICATION ゼロ）。

## Phase 1: Design & Contracts

**Prerequisites**: research.md 完了。

1. **エンティティとデータモデル** → [data-model.md](./data-model.md)
   - `PieceKind`（enum: I/O/T/S/Z/J/L、固定色を保持）
   - `Rotation`（enum: 0/90/180/270 → 各ピースの 4 通りのセル相対座標）
   - `Cell`（位置 + 色）
   - `Board`（10x10、不変的にスライド・行消去ができる構造体）
   - `GameStatus`（idle / playing / paused / gameOver）
   - `GameEngine`（`@Observable`、Board・score・NEXT・status を集約）
   - `Settings`（soundEnabled, hapticsEnabled）
   - `HighScore`（Int、永続化）
   - `AdConsentState`（ATT 結果 + UMP 結果のスナップショット）

2. **インターフェース契約** → `contracts/`
   - **gesture-contract.md**: 各画面でのジェスチャーマッピング
     （MainMenu の PLAY タップ、GameView の上下左右スワイプ閾値、
     GameOver の PLAY AGAIN / MENU タップ、Settings のトグル等）
   - **persistence-contract.md**: UserDefaults キー一覧と型
     （`highScore: Int`, `soundEnabled: Bool`, `hapticsEnabled: Bool`,
     `attHasPrompted: Bool`, `umpDecisionAt: Date?` 等）

   外部 API・REST/GraphQL は無いので contracts/ はこの 2 ファイルのみ。

3. **クイックスタート** → [quickstart.md](./quickstart.md)
   - 開発者がブランチをチェックアウトしてビルドし、シミュレータと実機で
     1 セッション遊び切るまでの手順
   - リリース前のスモークパス（憲法 V）チェックリスト
   - 5 ロケール切替の確認手順

4. **エージェントコンテキスト更新**: ルート `CLAUDE.md` の
   `<!-- SPECKIT START -->` 〜 `<!-- SPECKIT END -->` 間を、本プラン
   `specs/001-tetris-slide-game/plan.md` への参照に書き換える。

**Output**: data-model.md、contracts/gesture-contract.md、
contracts/persistence-contract.md、quickstart.md、ルート CLAUDE.md 更新。

## Post-Design Constitution Re-Check

Phase 1 設計を作り終えたあと、再度 5 原則を確認：

| # | 原則 | 状態 | コメント |
|---|------|------|----------|
| I | SwiftUI-Native Simplicity | ✅ PASS | UIKit 利用箇所は BannerAdView と UIFeedbackGenerator のみ。設計上の追加 UIKit 依存なし。|
| II | Player-First UX | ✅ PASS | DragGesture 閾値 30pt、無効スワイプの取り消しを `GameEngine` の純関数で実装。バナーと盤面ジェスチャー領域は GameView レイアウトで明示分離。|
| III | Localization Parity | ✅ PASS | UserDefaults キー以外、ハードコード文字列なし。spec の FR-031〜033 を data-model に反映。|
| IV | Ads & Privacy Compliance | ✅ PASS | `AdConsentCoordinator` で ATT → UMP → AdMob start を直列化。Interstitial / AppOpen はコードベースから物理削除（FR-039 と整合）。|
| V | Pragmatic Testing | ✅ PASS | Game/ 配下を純関数化することで XCTest 容易化。UI スモークは 1 本。|

**Post-Design Constitution Check**: PASS（Complexity Tracking 空のまま）。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

該当なし。憲法違反ゼロ。
