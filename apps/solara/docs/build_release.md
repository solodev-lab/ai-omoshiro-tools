# Solara リリースビルド手順

> launch_checklist Phase 2 残「`--obfuscate --split-debug-info` + Android R8 keep rules」対応の運用ドキュメント。

## TL;DR

```powershell
# Android Play Console 提出 (AAB)
cd apps/solara
python tools/build_release.py aab --release-mode

# Android 実機テスト (APK)
python tools/build_release.py apk --release-mode

# iOS TestFlight (Xcode + macOS 必須)
python tools/build_release.py ios --release-mode
```

`--release-mode` を付けないと dry-run（コマンド表示のみ）。

## 🔴 RASP 設定値の注入 (--dart-define、release build 必須)

freerasp による改変検知を有効にするには、リリースビルド時に署名証明書ハッシュを
`--dart-define` で渡す必要がある。未設定なら `DeviceSecurityStatus.start()` は
no-op (Pro 機能は通常動作、改変検知は効かない)。

```powershell
# Android (release keystore 作成後に取得した SHA-256 を base64 化)
keytool -list -v -keystore <path-to-release.keystore> | findstr "SHA-256"
# → 16 進数を base64 化 (PowerShell の場合):
$bytes = [byte[]]@(0xAA,0xBB, ...)  # SHA-256 を 32 byte に
[Convert]::ToBase64String($bytes)

flutter build aab --release `
  --obfuscate `
  --split-debug-info=build/symbols/aab/1.0.0+1 `
  --dart-define=SOLARA_FREERASP_ANDROID_HASH=<base64-hash> `
  --dart-define=SOLARA_FREERASP_IOS_TEAM_ID=<Apple_Team_ID>
```

`build_release.py` から自動で渡すのは将来対応 (TODO)。現状はオーナーが手動で
`--dart-define` を flutter build に付与するか、`tools/build_release.py` の
`build_command()` を編集して恒久化する。

## 仕組み

1. **`--obfuscate`**: Dart 関数名/クラス名をランダム化。アプリ改変による Pro 解放（`isPro=true` 直書き）の難易度を上げる
2. **`--split-debug-info=<dir>`**: シンボルファイル (`.symbols`) を `dir` に分離出力。クラッシュ deobfuscation 用
3. **Android R8 minify**: `android/app/build.gradle.kts` で `isMinifyEnabled = true` + `isShrinkResources = true`。`proguard-rules.pro` の keep ルール参照
4. **iOS dSYM**: App Store Connect が dSYM を自動受領 (Xcode Archive 経由)。Solara 側追加作業なし

## 🔴 シンボルファイル保管ポリシー

シンボルファイルは `build/symbols/<platform>/<version>/` に出力。`build/` は `.gitignore` 済みのため **手動バックアップ必須**。

### 推奨運用 (公開前)
- リリースビルド毎に `build/symbols/<platform>/<version>/` を外部ストレージ (Google Drive / iCloud / 個人 NAS) にコピー
- アーカイブ名: `solara-symbols-<platform>-<version>-<git-sha>.zip`
- 最低保持期間: ストア公開後 **1 年** (古い版を使うユーザーのクラッシュ復号のため)

### 公開後の移行 (launch_checklist Phase 0)
- Git LFS or Cloudflare R2 / Backblaze B2 等の非公開バケットへ
- ローカル git に直接コミットすると履歴肥大 + 機密漏洩リスク

## 🔴 release build 検証手順 (TestFlight Internal Testing 前必須)

R8 minify を本コミットで初有効化したため、**初回リリースビルドで必ずクラッシュ確認**を行う。

### Android
1. `python tools/build_release.py apk --release-mode`
2. 出力 APK を実機 (`adb install build/app/outputs/flutter-apk/app-release.apk`)
3. 主要画面を全部触る:
   - Map (タイル表示・拠点タップ・relocation popup)
   - Horoscope (5 カテゴリ fortune fetch、Free=overall のみ、Pro 切替で残り 4)
   - Observe (タロット 1 枚引き、Pro なら質問入力)
   - Daily Transit popup から Stella 相談
   - Sanctuary > Cosmic Pro 購入フロー (sandbox 環境)
   - Sign in (Apple/Google)
4. ❌ クラッシュ時:
   - `adb logcat | grep "FATAL EXCEPTION"` でスタック取得
   - `flutter symbolize -i <stack.txt> -d build/symbols/apk/<version>/app.android-arm64.symbols`
   - 復号後のクラスから `proguard-rules.pro` に keep を追加
   - 例: `-keep class <パッケージ>.** { *; }`

### iOS
1. `python tools/build_release.py ios --release-mode`
2. Xcode で Archive → Distribute App → App Store Connect
3. TestFlight Internal Testing で配信 → 実機で同じ画面網羅
4. クラッシュは App Store Connect の Organizer / Crashes で確認 (dSYM 自動付与)

## ProGuard keep ルール追加が必要なケース

| 症状 | 原因の可能性 | 対処 |
|---|---|---|
| サブスク購入後 isPro が反映されない | `purchases_flutter` の reflection broken | `-keep class com.revenuecat.purchases.** { *; }` 強化 |
| Sign in with Apple ボタンタップで黒画面 | Native bridge 剥がし | `com.aboutyou.dart_packages.sign_in_with_apple.**` keep 確認 |
| Google Sign In credential manager クラッシュ | gms.auth reflection broken | `com.google.android.gms.auth.**` keep 強化 |
| 起動時 NoClassDefFoundError | プラグイン consumer-rules が無い | プラグイン公式 README で keep 例確認 |

## トラブルシュート

### dry-run でコンソールが文字化け (Windows)
PowerShell の文字コード問題 (cp932)。表示だけの問題なので無視可。
気になる場合: `chcp 65001` で UTF-8 化してから再実行。

### `flutter symbolize` が `unable to find symbol file`
- `--split-debug-info` の dir 名と version の対応を間違えていないか確認
- マルチアーキ APK の場合は arm64/x64/x86 別の `.symbols` を試す

### Play Console 提出時に「mapping.txt が無い」警告
- AAB ビルド時に R8 が自動生成する `build/app/outputs/mapping/release/mapping.txt`
- Play Console 提出 (`fastlane` 経由 or 手動) で同梱必要

## 関連メモリ

- `project_solara_security_principles.md` — クライアント単独 `isPro` 禁止原則
- `project_solara_launch_checklist.md` — Phase 2 ビルド設定 3 項目
- `project_solara_android_back_popscope.md` — MainActivity keep が必須な理由
