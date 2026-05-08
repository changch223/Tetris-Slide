# Tetris Slide

> Tetris meets 2048 — a 10×10 puzzle where one swipe slides every block at once,
> and full rows AND columns clear.
>
> テトリスと 2048 の融合 — 10×10 盤面で 1 回のスワイプで全ブロックが滑り、
> 横一列も縦一列も揃うと消える。

---

## How to play / 遊び方

1. **PLAY** — A Tetris piece (I/O/T/S/Z/J/L) appears on the 10×10 board.
2. **Rotate** — Tap the rotate button to turn the just-spawned piece 90° clockwise.
3. **Swipe** — Up / Down / Left / Right. Every piece on the board slides as
   one rigid unit in that direction until it hits another piece or the wall.
4. **Clear** — Any horizontal row or vertical column that becomes completely
   filled disappears in one go.
5. **Plan** — A faint **ghost preview** shows exactly where the next piece
   will land before you swipe.
6. **Game over** — When the next piece can't fit anywhere on the board.

---

1. **PLAY** をタップすると、テトリスのピース (I/O/T/S/Z/J/L) が 10×10 盤面に出現します。
2. **回転ボタン**で出現したばかりのピースを 90° 時計回りに回転できます。
3. **スワイプ** — 上下左右いずれかの方向。盤面上のすべてのピースがその方向に
   剛体ごと滑り、他のピースか壁に当たって止まります。
4. **消去** — 横一列、または縦一列が完全に埋まると同時に消えます。
5. **先読み** — 薄いゴーストプレビューで「次のピースがどこに出るか」が
   スワイプ前にわかります。
6. **ゲームオーバー** — 次のピースが盤面のどこにも置けなくなったら終了。

---

## Scoring / スコア計算

| Lines cleared at once / 同時消し | Points / 点 |
|---|---|
| 1 | 100 |
| 2 | 300 |
| 3 | 500 |
| 4 (TETRIS!) | 800 |
| Each piece placed / 設置毎 | +1 |

A "line" counts whether it's a row OR a column — clear them mixed for combos.

「ライン」は行・列どちらでもカウント。混在させて同時消しを狙えます。

---

## Features / 主な機能

- **Rigid pieces** with connectivity-aware splitting after partial clears
- **Predictive ghost preview** — see the next piece's color, shape & landing cells
- **Smooth line-clear animation** with sound + haptic feedback
- **5 languages**: English, 日本語, 简体中文, 繁體中文, 香港中文
- **One-handed play** on iPhone, scales to iPad
- **No interstitials, no paywalls** — bottom banner only, optional ATT/UMP consent
- **Local high score** persisted across launches

---

## Links

- 📨 **Support / サポート** — [SUPPORT.md](./SUPPORT.md)
- 🐛 **Bugs / 不具合報告** — [GitHub Issues](https://github.com/changch223/reverse2048/issues)

---

## Tech / 技術スタック

- Swift 5 + SwiftUI (iOS 17.6+)
- Google Mobile Ads SDK (banner only)
- App Tracking Transparency + Google UMP
- CocoaPods
- XCTest + XCUITest

---

## License

© 2026 Chia-Wei Chang. All rights reserved.
