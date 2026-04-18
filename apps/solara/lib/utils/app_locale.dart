import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリ内の言語切替 (オーバーライド) を管理する global singleton。
/// - null: 端末設定に従う (デフォルト)
/// - Locale('ja'): 日本語固定
/// - Locale('en'): 英語固定
class AppLocale {
  AppLocale._();
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

  String get currentCode => notifier.value?.languageCode ?? 'system';
}
