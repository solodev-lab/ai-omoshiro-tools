# ============================================================
# Solara Android R8 / ProGuard ルール
# 設計: launch_checklist Phase 2 残 + project_solara_security_principles.md
#
# 方針:
#   - 各 Flutter プラグインが AAR に同梱する consumer-rules.pro を主とし、
#     本ファイルでは「明示的に剥ぎ取り防止が必要なもの」「過去にバグった
#     項目」のみ defensive に keep する
#   - optimize 系は使わない (proguard-android.txt = 非 optimize)
#   - 新規プラグイン追加時は本ファイルに必要 keep を追記
#
# 検証方針:
#   release build を Play Console Internal Testing にアップ → 実機起動 →
#   主要画面 (Map / Horoscope / Observe / Stella 相談 / Cosmic Pro 購入) を
#   全部触る。クラッシュ時は obfuscation/keep の問題を疑う。
# ============================================================

# ── 1. MainActivity / FlutterActivity (既存) ──
# MainActivity の no-op override (setFrameworkHandlesBack 等) が R8 に
# 「親と等価」判定で削除されると、Android 13+ で back キーが Flutter に
# 届かなくなる (project_solara_android_back_popscope.md)。
-keep class com.solodevlab.solara.MainActivity {
    *;
}
-keep class io.flutter.embedding.android.FlutterActivity {
    public void setFrameworkHandlesBack(boolean);
    public void registerOnBackInvokedCallback();
    public void unregisterOnBackInvokedCallback();
}

# ── 2. RevenueCat (purchases_flutter) ──
# 公式 SDK は consumer-rules.pro を同梱しているが、防御的に下位パッケージも
# keep。Trusted Entitlements (informational) 検証ロジックが reflection 経由
# のため、生成クラスを剥がされると `isEntitledFrom` が常に失敗 → 全ユーザー
# Free 扱いになる致命的バグになり得る。
-keep class com.revenuecat.purchases.** { *; }
-keep interface com.revenuecat.purchases.** { *; }

# ── 3. Sign in with Apple (sign_in_with_apple) ──
# 公式 SDK は consumer-rules を同梱。defensive。
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }

# ── 4. Google Sign In (google_sign_in) ──
# Google Play Services Auth は consumer rules を同梱。defensive。
# Google Identity Services の credential manager 経由 callback が reflection 化。
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.libraries.identity.** { *; }
-keep class io.flutter.plugins.googlesignin.** { *; }

# ── 5. Geolocator (位置情報) ──
# Android Location API の listener が reflection で繋がるため defensive。
-keep class com.baseflow.geolocator.** { *; }

# ── 6. shared_preferences / path_provider ──
# プラグイン consumer rules で足りるはずだが念のため。
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# ── 7. http / url_launcher ──
# pure Dart 経路だが Android 側の callback で reflection の場合あり。
-keep class io.flutter.plugins.urllauncher.** { *; }

# ── 8. share_plus ──
-keep class dev.fluttercommunity.plus.share.** { *; }

# ── 9. flutter_map (純 Dart、ルール不要) ──
# 念のため。
-keep class com.google.protobuf.** { *; }

# ── 10. 共通: Kotlin / Coroutines ──
# Kotlin metadata は R8 で剥ぐと SDK の generic 型情報が失われる。
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepattributes Signature, InnerClasses, EnclosingMethod, *Annotation*

# ── 12. flutter_local_notifications / GSON ──
# v19+ では plugin 同梱 consumer rules + GSON が proguard を提供するが、
# R8 minify + shrinkResources ON のため、予約通知の (de)serialize が壊れて
# 「debug では動くが release で通知が出ない/再起動後に消える」典型バグを防ぐべく
# defensive に keep する。Signature/*Annotation* は #10 で既に keep 済。
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# ── 13. 警告抑制 (release build 時のノイズ削減) ──
# 一部 SDK が optional dependency として参照するクラスの「missing」警告を抑制。
# release ビルドが成功しても警告でログが汚れるため。
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn com.google.errorprone.annotations.**
