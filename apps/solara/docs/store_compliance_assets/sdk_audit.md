# Solara — SDK 監査 (Privacy Manifest + 16 KB page size)

> Apple Privacy Manifest (2024-05 全 SDK 必須) + Android 16 KB page size (2026-05-31 期限延長) の
> 対応状況を pubspec.yaml の native plugin について監査する。
>
> 関連: [store_compliance.md](../store_compliance.md) §2.3 (Privacy Manifest) / §3.3 (16 KB)
>
> 最終更新: 2026-05-28

---

## 0. サマリ

| 項目 | 状態 | アクション |
|---|---|---|
| Privacy Manifest 同梱 (iOS) | 🟡 一部要確認 | `flutter pub upgrade` + Xcode で Validate App |
| 16 KB page size (Android) | 🟡 一部要確認 | `flutter pub upgrade` + apkanalyzer で .so 監査 |
| Google Maps SDK | ✅ 使用していない (OSM HOT のみ) | 監査対象外 |
| Crashlytics / Firebase | ✅ 未導入 | 監査対象外 |
| Android ID 収集 | 🟡 RC が読む可能性 | Data Safety form で開示済 |

**結論**: 大きな改修は不要見込み。`flutter pub upgrade` で各 plugin を最新化 + Xcode/apkanalyzer で
最終確認すれば、両要件をクリアできる可能性が高い。

---

## 1. Dependencies の分類

### 1.1 Pure Dart (Privacy Manifest / 16 KB の影響なし)

これらは Dart コードのみで、native (Swift/ObjC/Kotlin/Java/C++) を含まない。両ストアの監査対象外。

| パッケージ | 現バージョン | 備考 |
|---|---|---|
| cupertino_icons | ^1.0.8 | アイコン |
| google_fonts | ^8.0.2 | フォント (Web フェッチ) |
| characters | ^1.4.1 | 文字列処理 |
| latlong2 | ^0.9.1 | 緯度経度型 |
| http | ^1.6.0 | HTTP クライアント |
| crypto | ^3.0.6 | SHA-256 等 |
| flutter_riverpod | ^3.3.1 | 状態管理 |
| riverpod_annotation | ^4.0.2 | コード生成 |
| flutter_map | ^8.3.0 | 地図 (OSM タイル表示、Pure Dart) |

### 1.2 Native Plugin (Privacy Manifest + 16 KB 対象)

iOS と Android で native コードを含むため、両ストアの要件チェック対象。

| パッケージ | 現バージョン | Privacy Manifest (iOS) | 16 KB (Android) |
|---|---|---|---|
| shared_preferences | ^2.5.5 | ✅ 公式対応済 (2.3+) | ✅ pure Java/Kotlin (16 KB 不要) |
| share_plus | ^11.1.0 | ✅ 公式対応済 (8.0+) | ✅ pure Java/Kotlin |
| path_provider | ^2.1.5 | ✅ 公式対応済 (2.1+) | ✅ pure Java/Kotlin |
| geolocator | ^14.0.0 | ✅ 公式対応済 (10.0+) | 🟡 NDK 依存 → 14.0+ で対応見込み |
| purchases_flutter | ^10.1.0 | ✅ 公式対応済 (RC v6.0+) | 🟡 RC SDK 7.x で 16 KB 対応、要確認 |
| url_launcher | ^6.3.2 | ✅ 公式対応済 (6.2+) | ✅ pure Kotlin |
| sign_in_with_apple | ^8.0.0 | ✅ 公式対応済 (6.0+) | ✅ pure Kotlin |
| google_sign_in | ^7.2.0 | ✅ 公式対応済 (6.1+) | 🟡 Play Services 内部依存、要確認 |
| freerasp | ^7.5.1 | 🟡 talsec、要確認 | 🟡 NDK 依存 (root/jailbreak 検知の native コード)、要確認 |
| app_attest_integrity | ^1.0.0 | 🟡 個人 maintainer、要確認 | ✅ iOS 専用 (Android なし) |

### 1.3 監査対象外 (Apple/Google 共通)

| 項目 | 状態 | 備考 |
|---|---|---|
| Google Maps SDK | 未使用 | Solara は OSM HOT タイル + flutter_map のみ |
| google_places package | 未使用 | 検索は Worker 経由で Nominatim + Google Places API (Web API 呼出、native SDK 不要) |
| Firebase Analytics / Crashlytics | 未導入 | release_checklist.md で TODO だが未着手 |

---

## 2. 監査の実行手順

### 2.1 Privacy Manifest (iOS) — Xcode で Validate App

**目的**: 全 plugin が `PrivacyInfo.xcprivacy` を同梱しているか確認

**手順**:
```bash
cd E:\AppCreate\apps\solara
flutter pub upgrade
flutter build ios --release --no-codesign
# Xcode で ios/Runner.xcworkspace を開く
# Product > Archive > Validate App > "Privacy Manifest" タブで確認
```

**期待結果**:
- 全 SDK が privacy manifest を持つ ✅
- 警告なし

**警告が出た場合の対処**:
- 該当 plugin が古い → pubspec.yaml で version 上限を更新 → `flutter pub upgrade`
- 公式 plugin が未対応 → GitHub issue で確認、代替検討 or 自前で `PrivacyInfo.xcprivacy` を追加

### 2.2 16 KB page size (Android) — apkanalyzer で .so 監査

**目的**: 全 .so バイナリが 16 KB page size 互換でビルドされているか確認

**手順**:
```bash
cd E:\AppCreate\apps\solara
flutter pub upgrade
flutter build apk --release
# AAB から APK 展開
# %ANDROID_HOME%\cmdline-tools\latest\bin\apkanalyzer.bat apk apk-summary build\app\outputs\flutter-apk\app-release.apk
# 各 .so について alignment 確認: readelf -d <.so>
```

**より簡単な代替** — Android Studio で Build > Analyze APK > 各 .so のロード コマンドを確認:
- `PT_LOAD` の alignment が `0x4000` (16 KB) 以上なら ✅
- `0x1000` (4 KB) のままの .so があれば該当 plugin を upgrade

**期待結果**: すべての .so が 16 KB アライメント

### 2.3 検査結果記録テンプレート

監査実行後、以下を記録:

```
監査日: 2026-MM-DD
ビルドバージョン: v1.0.0+13

iOS Privacy Manifest:
- ✅ 全 plugin OK / ⚠ 警告あり: <plugin 名> <内容>

Android 16 KB:
- ✅ 全 .so 16 KB / ⚠ 4 KB の .so あり: <plugin 名>

対応:
- (必要なら) pubspec.yaml の version 更新内容
- (必要なら) 別 plugin への差し替え
```

---

## 3. 公式 SDK 対応状況の参照先

### Privacy Manifest (Apple)
- 公式リスト: https://developer.apple.com/support/third-party-SDK-requirements/
- Flutter plugin 対応状況: https://docs.flutter.dev/release/breaking-changes/required-privacy-manifests
- RevenueCat: https://www.revenuecat.com/blog/engineering/apple-privacy-manifests/
- google_sign_in: GitHub issue で各 Plugin の進捗

### 16 KB page size (Android)
- 公式 docs: https://developer.android.com/guide/practices/page-sizes
- Flutter blog: https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html
- 各 plugin の GitHub issue で対応 PR を検索

---

## 4. 16 KB 期限の延長申請

Play Console で **2026-05-31 まで延長申請可能**。

申請手順:
1. Play Console > Solara > リリース管理 > リリース ステータス
2. "16 KB ページ サイズ" セクション > "延長を申請"
3. 理由: 「依存 SDK の 16 KB 対応待ち」(該当する場合)

延長中も新規 AAB 提出は可能。延長期限を超えると新規 AAB 提出ブロック。

---

## 5. アクション アイテム (オーナー作業)

```
- [ ] `flutter pub upgrade` を実行 (主要 native plugin を最新へ)
- [ ] iOS: Xcode で Validate App → Privacy Manifest 警告ゼロを確認
- [ ] Android: apkanalyzer で全 .so の 16 KB alignment を確認
- [ ] 警告が出たら本 docs の §3 で公式対応状況を確認 → plugin 上げ or 別 plugin
- [ ] 監査結果を §2.3 のテンプレートで本 docs に追記
- [ ] 16 KB 期限延長が必要なら Play Console で申請
```

---

## 6. 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-05-28 | 初版作成 (G8 + G10 対応) |
