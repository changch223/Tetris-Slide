# Quickstart: Tetris Slide Game (10x10)

**Feature**: 001-tetris-slide-game
**Date**: 2026-05-08

開発者が本ブランチをチェックアウトしてから、シミュレータと実機で
動作確認するまでの最短手順。リリース前のスモークパス（憲法 V）と
5 ロケール検証の手順もここに集約する。

---

## 1. 前提

- macOS（Apple Silicon または Intel）
- Xcode 15.4+（iOS 17.6 SDK が必要）
- CocoaPods 1.15+
- Apple Developer 証明書（実機で AdMob テスト広告を見るため）

---

## 2. 初回セットアップ

```text
# 1. ブランチを取得
git checkout 001-tetris-slide-game

# 2. CocoaPods 依存をインストール（初回のみ）
pod install

# 3. ワークスペースを開く（重要: .xcodeproj ではなく .xcworkspace）
open NumberClash.xcworkspace
```

---

## 3. ビルドと実行

### 3.1 シミュレータで動かす

1. Xcode 上部のスキーム選択で `Reverse2048` を選ぶ。
2. ターゲットデバイスを **iPhone 15** または **iPad (10th gen)** に設定。
3. `⌘R` で Run。

### 3.2 実機で動かす

1. iPhone を Mac に接続。
2. 信頼ダイアログを承認。
3. ターゲットデバイス選択で実機を選び、`⌘R`。
4. Settings → 一般 → デバイス管理 で開発者証明書を信頼。
5. 初回起動時に ATT 許諾プロンプトが出ることを確認。

---

## 4. 1 セッション通しプレイ（スモーク・ゴールデンパス）

リリース判定の必須チェックリスト（憲法 V）。実機 1 台で順番に実施し、
すべてパスすることを確認する。

- [ ] アプリを完全終了 → 起動 → スプラッシュなしで 5 秒以内にメインメニューに到達
- [ ] 初回起動時、ATT 許諾プロンプトが表示される
- [ ] EU 圏のテストでは（VPN 切替で再現）UMP の GDPR 同意フォームが表示される
- [ ] メインメニューに HIGH SCORE が 0（または前回値）で表示
- [ ] PLAY ボタンタップ → ゲーム画面に遷移
- [ ] 盤面 10×10 が中央に正方形でレイアウトされている
- [ ] 右上 NEXT に次のピースのプレビューが見える
- [ ] 画面最下部にバナー広告（テスト広告）が表示されている
- [ ] バナー領域でスワイプしても盤面は動かない（FR-034）
- [ ] 盤面領域で **上 / 下 / 左 / 右** の各方向にスワイプ → 全セルがその
      方向に滑る（2048 風挙動、合体は起きない）
- [ ] スワイプ後にピースが新しい場所にランダム回転で出現
- [ ] 横 1 行を埋めて消去 → スコア +100 + 設置ボーナス +1 を確認
- [ ] 4 行同時消し（テトリス）が起きた瞬間、専用効果音とハプティクス
      （`UINotificationFeedbackGenerator.success`）が発火
- [ ] 無効スワイプ（盤面が動かない方向）でターン消費されないことを確認
- [ ] 意図的に盤面を埋めて、次のピースが入らない状態にしてゲームオーバー
      到達を確認
- [ ] ゲームオーバー画面で最終スコアが正しく表示される
- [ ] ハイスコアを更新したセッションでは NEW HIGH SCORE バッジが出る
- [ ] PLAY AGAIN タップで盤面が初期化されて新ゲーム開始
- [ ] MAIN MENU タップでメニューに戻り、ハイスコアが更新されている
- [ ] アプリを完全終了 → 再起動 → ハイスコアが保持されている
- [ ] ゲーム中にホーム画面へ → 戻ってもゲーム状態が継続している
- [ ] 設定画面で効果音 OFF → ゲームに戻って効果音が鳴らないことを確認
- [ ] 設定画面でハプティクス OFF → 振動が鳴らないことを確認

---

## 5. 5 ロケール表示確認

iOS の **設定 > 一般 > 言語と地域 > 優先する言語の順序** で言語を切り替え、
アプリを再起動して以下のロケールでメニュー / ゲーム画面 / ゲームオーバー
画面 / 設定画面 / About 画面の文字列がすべて翻訳されていることを確認する：

- [ ] English (en)
- [ ] 日本語 (ja)
- [ ] 简体中文 (zh-Hans)
- [ ] 繁體中文 (zh-Hant)
- [ ] 香港中文 (zh-HK)

長い言語（例: 日本語の「ハイスコア」）と短い言語（英語の "HIGH"）の
両方でレイアウト崩れが起きないことを目視確認する。

---

## 6. 自動テスト

```text
# Xcode から
⌘U                                  # NumberClashTests + UITests を全実行

# CLI から
xcodebuild test \
  -workspace NumberClash.xcworkspace \
  -scheme Reverse2048 \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

期待される結果：

- 単体テスト（NumberClashTests）: 全グリーン
- UI スモーク（NumberClashUITests / EndlessSmokeUITests）: 1 本グリーン
- 警告ゼロ、新規導入の警告 0 件

---

## 7. リリース前チェックリスト（憲法 IV / V）

- [ ] §4 のスモーク 1 周（実機）すべてパス
- [ ] §5 の 5 ロケール表示確認すべてパス
- [ ] バンドル ID が `CHIA.ProMaxHardReverse2048` で変わっていない
- [ ] AdMob 広告ユニット ID をテストから本番に差し替え済み
- [ ] App Privacy 申告（App Store Connect）が現在の SDK 構成と一致
- [ ] Privacy Manifest（`PrivacyInfo.xcprivacy` 等）が AdMob の必要項目を
      含んでいる
- [ ] バージョン番号 / ビルド番号をインクリメント済み
- [ ] スクリーンショット（ScreenShoot/）を新ゲームのものに更新

---

## 8. 既知のトラブルシュート

| 症状 | 対処 |
|------|------|
| `pod install` が SDK 解決でエラー | `pod repo update` 後に再実行 |
| 実機で AdMob テスト広告が出ない | テストデバイス ID を AdMob の `requestConfiguration.testDeviceIdentifiers` に追加 |
| ATT プロンプトが出ない | アプリを削除 → 再インストールで `attHasPrompted` を初期化 |
| 5 言語のいずれかでフォールバック英語が出る | 該当 `Localizable.strings` のキー欠損を確認、憲法 III に従いレビュー再実行 |
