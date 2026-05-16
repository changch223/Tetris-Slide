# Persistence Contract

**Feature**: 001-tetris-slide-game
**Date**: 2026-05-08

新ゲームが端末ローカルに永続化するすべての値の一覧。すべて
**`UserDefaults.standard`**（標準 suite）に保存し、`UserDefaults`
よりも重い仕組み（SwiftData / CoreData / Keychain）は使わない。

---

## キー一覧

| キー文字列 | 型 | デフォルト | 用途 / 関連 spec |
|-----------|-----|-----------|------------------|
| `tetris2048.highScore` | `Int` | `0` | エンドレスモードのハイスコア（FR-023, FR-024） |
| `tetris2048.settings.soundEnabled` | `Bool` | `true` | 効果音 ON/OFF（FR-030） |
| `tetris2048.settings.hapticsEnabled` | `Bool` | `true` | ハプティクス ON/OFF（FR-030） |
| `tetris2048.consent.attHasPrompted` | `Bool` | `false` | ATT プロンプトを既に出したか（重複表示防止） |
| `tetris2048.consent.umpDecisionAt` | `Date?` | `nil` | UMP 同意フォームを最後に処理した時刻 |

**プレフィックス規約**: すべて `tetris2048.` で始める。これにより
旧アプリ（NumberClash / Reverse2048）が使っていた `UserDefaults` キーと
名前空間が衝突しない。

---

## 読み書き責務

| ストアクラス | 担当キー |
|--------------|---------|
| `HighScoreStore` | `tetris2048.highScore` |
| `SettingsStore` | `tetris2048.settings.soundEnabled`, `tetris2048.settings.hapticsEnabled` |
| `AdConsentCoordinator` | `tetris2048.consent.attHasPrompted`, `tetris2048.consent.umpDecisionAt` |

各ストアは内部でしかキー文字列を知らない。テスト容易化のため、ストアは
プロトコル経由で `GameEngine` などに注入する（data-model §7）。

---

## 旧データの扱い

- 旧バージョンが `UserDefaults` に書いていたキー（NumberClash 系のスコアや
  設定）は **読まない**。新キー名で新たに書き始める。
- 旧バージョンが SwiftData (`Item.self`) に書いていた永続データは触らない
  （research R-7）。`ModelContainer` も生成しない。
- 既存ハイスコアは仕様 Assumptions により初期値 0 として扱う。

---

## マイグレーション方針

将来的にキー名・型を変える場合は、新キーへ書き、旧キーから読み込む期間を
1 リリース挟んでから旧キー削除する **dual-read / single-write** 方式とする。
本フェーズではすべて新規キーなのでマイグレーション不要。

---

## テスト容易化

XCTest では `UserDefaults(suiteName: "TestSuite-\(UUID())")` を使った
インメモリ相当の `UserDefaults` をストアに注入することで、ファイル I/O を
回避し、各テストが独立して実行できる構成にする。
