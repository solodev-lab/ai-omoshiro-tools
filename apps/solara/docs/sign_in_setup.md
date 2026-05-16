# Sign in 設定ガイド (Phase 2-9 オーナー作業)

Phase 2-9 (Sign in 統合) で実装した `SolaraAuth` を本番で動かすために必要な、ストア / コンソール側の設定手順をまとめる。コード側は配線済 (`lib/utils/solara_auth.dart` + Sanctuary `_buildAccountSection`)、本ドキュメントはアプリ外設定の手順書。

---

## 概要

| プロバイダ | iOS | Android | 必要な作業 |
|---|---|---|---|
| Apple | ✅ ネイティブ | ❌ 非対応 (本フェーズ) | iOS Capabilities 追加 |
| Google | ✅ Plist 設定 | ✅ google-services.json | OAuth クライアント ID 取得 |

🔴 **Apple Guideline 5.4 遵守**: iOS で Google サインインを提供する場合、Apple サインインを同時に提供する義務がある。Solara は iOS のみで Apple を提供することで遵守 (Android は Google のみで合法)。

---

## 1. Apple サインイン (iOS)

### 1-1. Apple Developer Portal

1. [Identifiers](https://developer.apple.com/account/resources/identifiers/list) → 既存の App ID `com.solodev.solara` を開く
2. **Capabilities** タブで **Sign In with Apple** を有効化 → Save
3. 関連する Provisioning Profile を再生成 (古い Profile では Capabilities 不一致でビルド失敗)

### 1-2. Xcode

1. `ios/Runner.xcworkspace` を開く
2. Runner ターゲット → **Signing & Capabilities** → **+ Capability** → **Sign In with Apple**
3. ビルド: `flutter run --release` で動作確認

### 1-3. 動作確認

- iOS 13+ 必須 (それ未満では `SignInWithApple.isAvailable()` が false → 「この端末では Sign in with Apple が利用できません」を SolaraAuth が SnackBar で出す)
- 初回サインインで `givenName / familyName / email` が取得できる (2 回目以降は userIdentifier のみ)
- リレーアドレス (`xxx@privaterelay.appleid.com`) は通常メールとして扱える

### 1-4. テストアカウント

- TestFlight 配信時は Apple ID で実機サインインを必ず通す
- 「Apple ID を共有」している端末で revoke → アプリ側で `getCredentialState != authorized` を検知し SolaraAuth が自動サインアウト

---

## 2. Google サインイン

### 2-1. Google Cloud Console

1. [Google Cloud Console](https://console.cloud.google.com/) で新規プロジェクト or 既存 Solara プロジェクトを開く
2. **APIs & Services** → **Credentials** → **+ CREATE CREDENTIALS** → **OAuth client ID**
3. 以下 3 種類を作成:
   - **iOS**: Bundle ID `com.solodev.solara` を入力 → クライアント ID 発行
   - **Android**: パッケージ名 `com.solodev.solara` + SHA-1 (debug / release 両方) → クライアント ID 発行
   - **Web** (Android backend 兼用): server client ID として使う場合 → クライアント ID 発行
4. OAuth 同意画面: アプリ名 / サポートメール / スコープ (email, profile) を設定 → 公開 (External, Testing)

### 2-2. iOS 設定

1. iOS クライアント ID と **reversed client ID** (例: `com.googleusercontent.apps.123456789-xxxxxx`) を Google Cloud Console からコピー
2. `ios/Runner/Info.plist` に URL Scheme を追加:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.123456789-xxxxxx</string>
       </array>
     </dict>
   </array>
   ```
3. クライアント ID を `--dart-define` で渡す or `GoogleService-Info.plist` をプロジェクトに配置
   - Solara は dart-define 優先: `--dart-define=SOLARA_GOOGLE_IOS_CLIENT_ID=xxxxx.apps.googleusercontent.com`

### 2-3. Android 設定

1. Android クライアント ID 作成時に SHA-1 fingerprint を登録する。debug は `~/.android/debug.keystore` から取得:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
2. release ビルド用の SHA-1 も登録 (Play Console > Setup > App signing から取得)
3. `android/app/google-services.json` を Firebase Console / Cloud Console からダウンロードして配置
4. `android/app/build.gradle` で `id 'com.google.gms.google-services'` プラグインを apply (既に他で Firebase を使っていればスキップ)

### 2-4. server client ID (オプション)

- バックエンド (Worker) で Google ID トークンを検証したい場合のみ必要
- `--dart-define=SOLARA_GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com` で渡す
- 未設定でも基本のサインインは動く (uid / email / displayName が取得可能)

### 2-5. 動作確認

- 初回タップで Google のアカウント選択シート → 1 つ選んで同意 → SolaraAuth が `account` を更新
- 端末で Google アカウントを切替えた場合、`GoogleSignInAuthenticationEvent` ストリーム経由で自動的に新アカウントに切替わる
- `attemptLightweightAuthentication` が次回起動時のサイレント復元を担当

---

## 3. RevenueCat 連携

- SolaraAuth がサインイン成功時に `PurchasesService.instance.logIn(uid)` を自動で呼ぶ
- uid 形式: `apple:{userIdentifier}` / `google:{user.id}` (プロバイダ間で衝突しない)
- RevenueCat ダッシュボードで `App User ID` が `apple:xxx` / `google:xxx` 形式で記録されるので、サポート時はこの形式で照合する
- 同一ユーザーが Apple → Google に切替えると別 uid 扱い。クロスプラットフォーム merge はサポート外 (公開後検討)

---

## 4. 注意事項

- **Apple サインインは Android 非対応**: 公式パッケージは webview 経由で対応可能だが Service ID + redirect URI のサーバ設定が必要。本フェーズは iOS のみ
- **Sign in は任意**: Free 機能はサインインなしで全て使える。Pro 購入も anonymous appUserID で可能。サインインは「端末跨ぎの Pro 復元」を安定化するためにすすめる
- **法的要件**: プライバシーポリシーで「Apple / Google から名前・メールを取得し、当社サーバには送信しない (現状)」を記載する。Worker 連携時はサーバ送信を追記
- **Family Sharing OFF** (security_principles 原則 5) と整合: 同一 Apple ID の家族メンバーが Pro を共有することは想定しない設計
