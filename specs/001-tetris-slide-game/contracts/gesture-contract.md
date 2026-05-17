# Gesture & Input Contract

**Feature**: 001-tetris-slide-game
**Date**: 2026-05-08

各画面でのユーザー入力（タップ・スワイプ）と、それが内部で起こす
状態遷移の対応表。これは `GameEngine` の API と View レイヤの
ジェスチャーバインドが守るべき契約である。

---

## 共通ルール

- **スワイプ判定閾値**: 指の総移動量が **30 pt 以上**で、`|dx|` と `|dy|`
  の差が支配的（≥ 1.5 倍）な軸が定まる場合のみ、4 方向のいずれかとして
  判定する。これに満たないジェスチャーは「ノーアクション」（無視）。
- **タップ判定**: 標準 SwiftUI `Button`。アクセシビリティトレイト等は
  デフォルト。
- **無効スワイプ**: 4 方向のいずれかとして判定されたが、`GameEngine` の
  シミュレーションで盤面が変わらず行も消えない場合は **ターン消費しない**
  （spec FR-013、data-model `handleSwipe` step 4）。視覚的に微小な
  「効果なし」フィードバック（軽いシェイクアニメーション 1 回）を出す。

---

## MainMenuView

| 入力 | アクション | 状態遷移 |
|------|------------|----------|
| PLAY ボタンタップ | `GameEngine.startNewGame()` | `.idle` → `.playing` |
| SETTINGS ボタンタップ | NavigationLink で SettingsView | (画面遷移のみ) |
| ABOUT ボタンタップ | NavigationLink で AboutView | (画面遷移のみ) |

ハイスコア表示は読み取り専用、入力はなし。

---

## GameView

| 入力 | アクション | 状態遷移 / 副作用 |
|------|------------|--------------------|
| 上スワイプ | `GameEngine.handleSwipe(.up)` | data-model §3.2.2 |
| 下スワイプ | `GameEngine.handleSwipe(.down)` | data-model §3.2.2 |
| 左スワイプ | `GameEngine.handleSwipe(.left)` | data-model §3.2.2 |
| 右スワイプ | `GameEngine.handleSwipe(.right)` | data-model §3.2.2 |
| ポーズボタンタップ | `GameEngine.togglePause()` | `.playing` ↔ `.paused` |
| アプリがバックグラウンドへ | scenePhase 監視で `togglePause()` | `.playing` → `.paused` |
| アプリ復帰 | `GameEngine.resumeFromBackground()` | `.paused` → `.playing` |

**ジェスチャー領域の境界**:

- スワイプ認識は **盤面 BoardView の領域だけ**にバインドする（`gesture(...)` を
  BoardView に付ける）。スコア HUD、NEXT プレビュー、バナー広告領域では
  反応しない（spec FR-034、Edge Cases）。

---

## GameOverOverlay

| 入力 | アクション | 状態遷移 |
|------|------------|----------|
| PLAY AGAIN ボタンタップ | `GameEngine.startNewGame()` | `.gameOver(...)` → `.playing` |
| MAIN MENU ボタンタップ | （View 側で navigation pop） | `.gameOver(...)` → `.idle` |

ゲームオーバー画面が表示されている間、盤面のスワイプ判定は無効化する
（DragGesture を `.disabled(true)` 相当）。

---

## SettingsView

| 入力 | アクション | 副作用 |
|------|------------|--------|
| 効果音 トグル | `SettingsStore.save(soundEnabled: ...)` | `UserDefaults` 即時保存 |
| ハプティクス トグル | `SettingsStore.save(hapticsEnabled: ...)` | `UserDefaults` 即時保存 |
| BACK ボタンタップ | navigation pop | (画面遷移のみ) |

トグル値の変化は `GameEngine` を経由せず、`SoundPlayer` / `HapticsPlayer`
が次のイベント発火時に最新の `SettingsStore` 値を参照することで反映される。

---

## アクセシビリティ

- 各ボタンに VoiceOver ラベル（`KEY_BUTTON_PLAY` 等のローカライズ済み文言）
  を付与する。
- 盤面の SwipeGesture はアクセシビリティアクションとしては別途
  `accessibilityAction(named:)` で「上に移動」「下に移動」「左に移動」
  「右に移動」をローカライズ済み文言で公開する（VoiceOver オン時に
  ジェスチャーの代替手段として動作）。
