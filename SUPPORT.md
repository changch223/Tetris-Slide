# Tetris Slide — Support

Need help with **Tetris Slide**? You're in the right place.

## Contact / お問い合わせ

- **Bug reports / 不具合報告** —
  [Open a GitHub issue](https://github.com/changch223/reverse2048/issues/new)
- **Feature requests / 機能リクエスト** —
  Same place, please tag with `enhancement`

We aim to respond to issues within 5 business days.
不具合・要望には原則 5 営業日以内にご返信します。

---

## FAQ (English)

### How do I rotate a piece?
Tap the circular **rotate button** next to the NEXT preview. The piece rotates
90° clockwise. If the rotation can't fit at the same position (a wall or
another piece is in the way), the rotation is rejected — try sliding first or
swipe in another direction.

### Why didn't my swipe do anything?
A swipe that **doesn't move any piece AND doesn't clear any line** is treated
as invalid — your turn doesn't advance. Try a different direction.

### What does the colored outline on empty cells mean?
That's the **ghost preview**. It shows the color, shape, and exact cells where
the next piece will appear after your next swipe. If a slid piece lands on
those cells, the ghost will smoothly relocate to a new valid spot before the
new piece appears.

### What happens to a piece if part of it is in a cleared line?
The remaining cells of the same piece are checked for connectivity:
- **Still connected** (e.g., an L-piece losing one corner): keeps moving as
  one smaller rigid group.
- **Disconnected** (e.g., an I-piece losing its middle): splits into separate
  groups that move independently from then on.

### How is the high score saved?
Locally on your device. There is no cloud sync, no Game Center integration,
no account required.

### Can I turn off ads?
There is no ad-removal in-app purchase at this time. Banner ads run at the
bottom of the screen only and never interrupt gameplay. Interstitial and
app-open ads are not used.

### Does declining App Tracking Transparency break anything?
No. The game is **100% playable** whether you allow tracking or not. Ads are
shown either way — they're just less personalized when tracking is declined.

### Privacy
We use Google Mobile Ads SDK for banner ads only. Tracking identifiers are
collected only with your ATT consent (and EU users see a UMP consent form
first). High score and settings are stored locally in `UserDefaults` — never
uploaded.

---

## FAQ (日本語)

### ピースを回転させるには？
NEXT プレビュー横の丸い**回転ボタン**をタップしてください。時計回りに 90°
回転します。回転先で他のピースや壁と衝突する場合は回転できません。先に
スワイプで動かすか、別の方向に動かしてから回転してください。

### スワイプしても何も起きません
**盤面が動かず、かつ消える行・列もない**スワイプは「無効」として扱われ、
ターンが進みません。別の方向にスワイプしてください。

### 空きマスにある色付きの枠は何ですか？
**ゴーストプレビュー**です。次のピースの色・形・着地マスを事前に表示して
います。ゴースト位置に他のピースが滑り込んだ場合は、新しい有効な場所に
ゴーストが滑らかに移動してから、次のピースが出現します。

### ライン消去で一部だけ消えたピースの残りはどうなりますか？
残ったセルの連結性を判定します：
- **まだ繋がっている**（例：L ピースが角を 1 つ失う）→ 小さくなった一塊と
  して引き続き動きます。
- **分断された**（例：縦 I ピースの真ん中が消える）→ それぞれ独立した
  グループに分裂し、以降は別々に動きます。

### ハイスコアはどうやって保存されますか？
端末内のローカル保存のみです。クラウド同期、Game Center 連携、アカウント
登録は不要・非対応です。

### 広告を消せますか？
現在、広告除去の課金は提供していません。バナー広告は画面下部のみで、ゲーム
画面を遮ることはありません。インタースティシャルやアプリ起動時広告は使用
していません。

### App Tracking Transparency で「許可しない」を選ぶと不便ですか？
いいえ。トラッキングの許諾の有無にかかわらず、ゲーム全機能が **100%**
動作します。広告は同じように表示されますが、許諾しない場合はパーソナライ
ズが弱まるだけです。

### プライバシー
バナー広告のために Google Mobile Ads SDK を使用しています。トラッキング
識別子は ATT で許諾された場合のみ収集されます（EU 圏では UMP 同意フォーム
が先に表示されます）。ハイスコアと設定は端末の `UserDefaults` にローカル
保存されます。サーバーへ送信されることはありません。

---

## Reporting a security issue

For security-sensitive reports, please email instead of opening a public
issue. (Contact via GitHub profile.)

セキュリティに関わる報告は、公開 Issue の代わりに GitHub プロフィール
記載のメールへお送りください。
