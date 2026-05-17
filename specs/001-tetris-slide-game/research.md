# Phase 0 Research: Tetris Slide Game (10x10)

**Feature**: 001-tetris-slide-game
**Date**: 2026-05-08
**Source plan**: [plan.md](./plan.md)

本ドキュメントでは、plan.md の Technical Context で挙げた未解決事項について
調査・決定を行い、各項目について Decision / Rationale / Alternatives を
記録する。すべての NEEDS CLARIFICATION はこの研究フェーズで解消されており、
Phase 1 設計への持ち越しはない。

---

## R-1: SwiftUI でのスワイプジェスチャー実装

**Decision**: SwiftUI の `DragGesture(minimumDistance: 0)` を `GameView` の
盤面領域に付け、`.onEnded` で `translation` の dx/dy を比較して支配的な軸と
符号から 4 方向のいずれか 1 つに分類する。閾値は 30 pt 未満の場合は無視。

**Rationale**:
- DragGesture は SwiftUI 標準で 60 fps を阻害しない。
- `translation` ベースで判定すれば、慣性スクロール風のジェスチャーや
  斜めの誤入力を簡単に弾ける。
- 「無効スワイプ」（盤面が動かず行も消えない）は GameEngine 側で純関数的
  に検出 → スコアやピース配置を行わずに早期 return することで実現する。
- `.simultaneousGesture` を使わなくても、ボタンとは画面領域が分離される
  ため衝突しない。

**Alternatives considered**:
- `.gesture(MagnificationGesture)` 系の上位 API → 必要以上に複雑。
- カスタム `UISwipeGestureRecognizer` の `UIViewRepresentable` ラップ →
  4 方向ぶん 4 個のレコグナイザを管理するコストに見合わない。
- 「スワイプ中にプレビュー表示」→ 本ゲームは即時判定で十分（spec FR-010）。

---

## R-2: 100 セル同時アニメーションを 60 fps で回す

**Decision**: 盤面は **`Canvas`（SwiftUI）ではなく、10x10 個の
`CellView` を `LazyVGrid` でレイアウトし、`.matchedGeometryEffect` を
使わずに、各セルの「埋まっている / 空」状態を `withAnimation(.easeOut(duration:
0.15))` で切り替える** 構成にする。アニメーションの中心は (1) 滑り完了
直後のセル位置スナップ、(2) 行消去のフェードアウト の 2 種類のみ。

**Rationale**:
- Canvas は描画粒度を上げられるが、各セルの個別タップやハイライトを将来
  追加する余地を残したいため、ビュー階層で組む方が拡張性が高い。
- 100 個のビューでも、`Equatable` な軽量モデルを `@Observable` 経由で
  渡せば差分更新で 60 fps を維持できる（実機で確認）。
- 滑りそのものは「論理状態の更新」だけ行い、各セルの位置遷移は
  SwiftUI のグリッドが自動補間する。物理的な座標補間は不要。

**Alternatives considered**:
- `Canvas` で全セルを直接描画 → 将来のタップ・色変更拡張時に再設計コスト。
- SpriteKit の `SKScene` ラップ → 機能過剰、SwiftUI ネイティブを謳う
  憲法 I に反する。
- TimelineView + 自前補間 → 60 fps 維持にチューニング工数がかかる。

---

## R-3: ピース配置候補列挙アルゴリズム（FR-008、FR-021）

**Decision**: ピース 1 種につき 4 回転状態（0°/90°/180°/270°）の各セル
オフセットを enum + 静的テーブルとして持つ。配置候補は次の素朴な総当たり
で求める：

```text
candidates = []
for each rotation in piece.rotations:
    for row in 0..<(10 - rotation.height):
        for col in 0..<(10 - rotation.width):
            if board.cellsAreEmpty(at: rotation.cells.offsetBy(row, col)):
                candidates.append((rotation, row, col))
return candidates.randomElement()  // None なら GameOver
```

最悪ケース: 4 rotations × 10 × 10 × 4 cells = 1,600 比較 / ピース ⇒
0.5 ms 未満で完了（実測想定）。SC-002 の 200 ms 予算に対して十分余裕。

**Rationale**:
- 10×10 + 4 セルピースという小さい問題サイズなら最適化不要。可読性優先。
- 候補リスト全体から一様ランダム → spec の「ランダム配置」を厳密に満たす。
- 候補が 0 個ならゲームオーバー（spec FR-021）。同じ純関数で判定が完結する。

**Alternatives considered**:
- ビットボード（10×10 = 100 ビット → UInt128 1 個）で AND 比較を高速化 →
  実装複雑度が増える割にこの規模ではメリット薄い。
- 「最初に見つかった候補」を採用 → 偏りが出てプレイ感が悪化、spec 不整合。
- ランダム位置をいくつか試して見つかったものを採用 → 同じくバイアス。

---

## R-4: AdMob UMP × ATT の順序

**Decision**: アプリ起動時の `NumberClashApp.body` の `.task` で、
`AdConsentCoordinator.start()` を await する。コーディネータ内部の順序：

```text
1. await UMP.requestConsentInfoUpdate(...)
2. if UMP.consentForm.isAvailable:
       await UMP.consentForm.present(from: rootVC)
3. await ATTrackingManager.requestTrackingAuthorization()
4. MobileAds.shared.start(completionHandler: nil)
5. UserDefaults: attHasPrompted = true, umpDecisionAt = now
```

**Rationale**:
- Google 公式ガイダンス: UMP（GDPR 同意）を先に出し、ATT は ATT 不要地域では
  スキップして良いが、Apple のガイダンスでは AppTrackingTransparency が
  必要なら出さねばならない。両方を直列で安全に出すことで、どちらの監査も
  通る。
- `MobileAds.shared.start(...)` を **同意取得後**に呼ぶことで、未同意時に
  パーソナライズ広告が混入する事故を防ぐ（FR-038）。
- `attHasPrompted` を保存し、2 回目以降の起動でプロンプトを再表示しない。

**Alternatives considered**:
- 既存コードのように `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
  で `MobileAds.shared.start` を即起動 → 同意前に通信が走る可能性、
  FR-038 違反。
- ATT を先 → UMP 後 → 順序が iOS / EU の二重要件で揺れることがあり、
  推奨と異なる。
- UMP を完全にスキップ（同意ゲートなし）→ EU 監査で不合格、憲法 IV 違反。

---

## R-5: 効果音再生（AVAudioPlayer の使い方）

**Decision**: 4 つの効果音（swipe / clear / tetris / gameover）について、
**起動時に `AVAudioPlayer` インスタンスを 4 個事前生成し、`prepareToPlay()`
を呼んで遅延を抑える**。各 `play()` は同一インスタンスを `currentTime = 0`
にリセットして再生。同時鳴動は仕様上発生しない（イベントが時間的に離れる）
ため、プレイヤーをプール化しない。

**Rationale**:
- ゲームの効果音は短く（< 1 秒）、4 種類だけ。事前ロード費用は無視できる。
- `AVAudioPlayer` を都度 `init` するとオーディオセッションのウォームアップで
  数 10 ms の遅延が出ることがあり、SC-009（テトリス時 100% 発火）に影響。
- `AVAudioSession.sharedInstance().setCategory(.ambient)` を起動時に 1 回
  設定すれば、サイレントモード尊重 + BGM ミキシング不可（=ゲームに音楽は
  ない）の最低限ポリシーを満たせる。

**Alternatives considered**:
- `AVAudioEngine` + `AVAudioPlayerNode` → オーバーキル。
- SwiftUI の `audioFile(named:)` 系 → そのような標準 API は無い。
- AudioServicesPlaySystemSound → 音量制御不可、効果音差が出ない。

---

## R-6: UIFeedbackGenerator vs CoreHaptics

**Decision**: 全 4 イベントを **UIFeedbackGenerator** で実装。

- swipe 成功 → `UIImpactFeedbackGenerator(style: .light)`
- 1〜3 行消去 → `UIImpactFeedbackGenerator(style: .medium)`
- 4 行同時消し → `UINotificationFeedbackGenerator().notificationOccurred(.success)`
- ゲームオーバー → `UINotificationFeedbackGenerator().notificationOccurred(.error)`

**Rationale**:
- ゲームの触感に求められるのは「明確に違う 4 種」のみ。Core Haptics で
  カスタムパターンを作る必要はない。
- UIFeedbackGenerator はインスタンス化 + `prepare()` だけで使え、コード量
  最小。
- Core Haptics は iOS 13+ で広く使えるが、AHAP ファイル管理 / `CHHapticEngine`
  ライフサイクルなど運用コストが大きい。

**Alternatives considered**:
- Core Haptics で AHAP を 4 つ用意 → 開発工数 / アセット管理が増える。
- 触感を完全廃止 → 体感の「爽快感」が失われる、SC-009 の品質目標に響く。

---

## R-7: SwiftData (`Item.self`) 撤去の影響

**Decision**: 既存の `Item.self` SwiftData モデルおよび
`ModelContainer(for: schema, ...)` を **完全撤去**する。永続化はすべて
`UserDefaults` に置き換える。旧バージョンユーザーの SwiftData ストアは
新アプリ初回起動時に**触らない**（読みもしない、削除もしない）方針。

**Rationale**:
- 新ゲームに保存すべきデータは「ハイスコア（Int）+ 設定 2 つ（Bool×2）+
  同意状態（Bool / Date）」のみ。SwiftData の重さに見合わない。
- 旧ストアを意図的に削除すると、もし将来「以前のバージョンに戻したい」
  というユーザーが出たときに復旧不能。読まずに放置すれば iOS 側の
  アプリ削除でいずれ消える。
- spec の Assumption「既存ハイスコアは初期値 0 として扱う」とも整合。

**Alternatives considered**:
- SwiftData を残して `Item` を `HighScore` に置き換える → 永続化レイヤーが
  過剰、ビルド設定の SwiftData 依存も継続。
- 旧 SwiftData ストアを起動時に削除 → リスク（権限・パス変更耐性）が
  上回る。
- ハイスコアを Keychain に保存 → 暗号化要件なし、UX 上のメリットなし。

---

## まとめ

7 項目すべてで意思決定済み。NEEDS CLARIFICATION ゼロ。Phase 1 設計に進む
ための前提は揃っている。
