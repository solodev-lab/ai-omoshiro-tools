# Play Integrity device recall 導入計画 (Android 匿名 farming の根本対策)

> 2026-05-31 起案。ウェルカム恒久クレジット (§0.2.39) の Android 匿名リインストール farming を
> 端末単位で封じるための計画。**ベータ機能のため Google 承認 + Play Console 有効化が前提**で、
> コードはそれまで着手しない (未承認・変更され得るベータに対し動かないコードを書くのは手戻り)。

## 背景 / なぜ必要か

- 恒久クレジット (`consultation_purchased`) は `app_user_id` キー。
- 端末キー (`consultationDeviceKey`) は **iOS=App Attest keyId (再インストール耐性)** / **Android=`usr:{appUserId}`**。
- Android で**未サインイン (匿名)** のまま再インストールすると RevenueCat 匿名 ID が作り直され → deviceKey が変わり → ウェルカム/無料週次が復活 = farming 可。
- サインインすれば認証済 ID で安定 → farming 不可 (本セッションで sign-in 付与 + 匿名→認証移送を実装済 §0.2.40)。
- **未サインインのままの Android 匿名ユーザー**だけが残る穴。これを device recall で塞ぐ。

## device recall とは (公式)

- Play Integrity API のベータ機能。**端末ごとに 3 ビット (=8 状態)** を Google サーバに保存。
- **アプリ再インストール・factory reset を貫通**して読み出せる (データは Google 側、3 年保持)。
- **アプリへのサインイン不要**。端末に Play ライセンス済 Google アカウントがあれば可 (通常の Android 端末)。
- プライバシー規約で **「無料トライアル等 高価値特典の不正検知」は明示的に許可**された用途 (フィンガープリント/追跡は禁止)。
- 公式: https://developer.android.com/google/play/integrity/device-recall

## オーナー作業 (これが無いと動かない)

1. **ベータ申請**: https://forms.gle/2d24B4gNyoVrqztG6 から interest を送り承認を得る。
2. **Play Console で device recall を有効化** (承認後にトグルが出る)。
3. (任意) テスト応答で挙動確認。on/off 切替でテスト応答はリセットされる。

## 実装設計 (承認後に着手)

Solara の Play Integrity は **Standard request** で、Worker が `decodeIntegrityToken` (Google API) で
**verdict 全体をサーバ側で復号**している (`worker/src/auth/play_integrity.js`)。よって verdict に
`deviceRecall` を含められ、server-to-server で write も可能。

### 読み取り (付与前チェック)
- `verifyPlayIntegrityFlow` (play_integrity.js) の復号後 payload に `deviceRecall.bitFirst` 等が入る。
- これを `verifyPlayIntegrityRoute` (index.js:1208 付近) の戻り値に通し、`/protected/consultation/welcome-grant`
  ハンドラ (`consultationWelcomeGrant`) まで届ける。
- **bit1 = "welcome 付与済"** と定義。verdict で bit1=true なら **Android でも再付与しない** (deviceKey が
  変わっても端末単位で封じられる)。

### 書き込み (付与後)
- 付与成功後、Worker から server-to-server:
  `POST https://playintegrity.googleapis.com/v1/{package}/deviceRecall:write`
  body `{ integrityToken, newValues: { bitFirst: true } }` (既存の Google SA 認証 `GOOGLE_PLAY_INTEGRITY_SA_JSON` を流用)。
- integrityToken は write に最大 14 日有効。反映 ~30 秒。Standard は warmup 再取得で最新値反映。

### 既存ガードとの関係
- 現状の eventId 冪等 (`welcome_profile:{deviceKey}`) は**そのまま残す** (二重付与防止の一次ガード)。
- device recall は**その上の二次ガード** (deviceKey が変わっても封じる)。両者併用。
- iOS は App Attest keyId で実質同等の耐性。必要なら iOS は **Apple DeviceCheck** (端末ごと 2 ビット) で
  同じ二次ガードを足せる (別途検討)。

## 制約・注意

- ベータ (仕様変更あり)。エミュ非対応。Play ライセンス無しアカウントでは verdict 未評価。
- 3 ビットは開発者アカウント内の全アプリで共有。リファービッシュ端末の転売を考慮し、古い書込
  (`lastWriteDateMonthYear`) はビジネス閾値で無視する判断も。
- 当面は「匿名にも付与 + farming は bounded で許容」(§0.2.40 のオーナー判断)。本対策は承認が下り次第。
