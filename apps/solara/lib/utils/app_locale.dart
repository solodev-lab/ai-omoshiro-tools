import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/strings.g.dart' as i18n;

/// アプリ内の言語切替 (オーバーライド) を管理する global singleton。
/// - null: 端末設定に従う (デフォルト)
/// - Locale('ja'): 日本語固定
/// - Locale('en'): 英語固定
///
/// 🔴 完成度ゲート (正典「半英語UIを出さない」):
///   notifier の変化を slang の LocaleSettings へ橋渡しする (_syncSlang)。
///   Phase 3 (2026-06-04) で system 連動へ解除済: EN カバレッジが揃った
///   (slang analyze 未訳 0 + Phase 2 content/data 英訳完了) ため、override が
///   null (端末設定) のときは端末ロケールに従う (英語端末 → en、それ以外 → ja)。
///   override=='ja'/'en' は固定。半英語UIはもう出ない。
class AppLocale {
  AppLocale._() {
    // notifier の変化を slang ロケールへ反映 (直接 value を差し替えるテストにも追従)。
    notifier.addListener(_syncSlang);
  }
  static final instance = AppLocale._();

  static const _prefKey = 'app_locale_override';

  /// MaterialApp.locale に渡す ValueNotifier
  final ValueNotifier<Locale?> notifier = ValueNotifier<Locale?>(null);

  /// 起動時に SharedPreferences から復元
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code == 'ja' || code == 'en') {
      notifier.value = Locale(code!);
    } else {
      notifier.value = null;
    }
    _syncSlang(); // 復元値が null→null で listener が発火しないケースを保証
  }

  /// 言語を変更して保存 (null=端末設定に戻す)
  Future<void> setOverride(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_prefKey);
      notifier.value = null;
    } else {
      await prefs.setString(_prefKey, code);
      notifier.value = Locale(code);
    }
  }

  /// override → slang LocaleSettings の橋渡し (完成度ゲート本体)。
  /// Phase 3: override=='en'/'ja' は固定。null=端末設定なら slang の supported
  /// (ja=base / en) から端末ロケールの最良一致を取る (英語端末 → en、他 → ja)。
  /// lazy:false なので setLocaleRawSync は同期。
  void _syncSlang() {
    final ov = notifier.value?.languageCode;
    final want = (ov == 'en' || ov == 'ja')
        ? ov!
        : i18n.AppLocaleUtils.findDeviceLocale().languageCode;
    i18n.LocaleSettings.setLocaleRawSync(want);
  }

  String get currentCode => notifier.value?.languageCode ?? 'system';
}
