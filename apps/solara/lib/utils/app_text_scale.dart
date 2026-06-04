import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ユーザーがアプリ内で選べるフォントサイズ段階。
enum AppFontSize { standard, large, max }

/// アプリ内フォントサイズ設定 (段階選択) の global singleton。
///
/// 端末フォント設定 (1.0〜1.5 にクランプ) + 言語別倍率 ([AppLocale.textScaleBoost])
/// の上に、ユーザー選択の倍率を掛ける。
/// - standard = 1.0 は従来挙動と完全一致 (退行なし)。
/// - large / max は標準クランプ(1.5)の上からさらに拡大するため、Map / Galaxy 等の
///   「絵主役」画面が窮屈になり得る → 設定 UI に注意書きを添える
///   (sanctuary_settings_pickers.dart の showFontSizePicker)。
class AppTextScale {
  AppTextScale._();
  static final instance = AppTextScale._();

  static const _prefKey = 'app_font_size_level';

  /// MediaQuery の textScaler 計算が購読する notifier (main.dart builder)。
  final ValueNotifier<AppFontSize> notifier =
      ValueNotifier<AppFontSize>(AppFontSize.standard);

  /// 段階ごとの追加倍率 (端末設定 × 言語別倍率 の上に掛ける)。
  static const Map<AppFontSize, double> _multiplier = {
    AppFontSize.standard: 1.0,
    AppFontSize.large: 1.15,
    AppFontSize.max: 1.3,
  };

  /// 起動時に SharedPreferences から復元。
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = _parse(prefs.getString(_prefKey));
  }

  /// 段階を変更して保存。
  Future<void> setLevel(AppFontSize level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, level.name);
    notifier.value = level;
  }

  /// 現在段階の追加倍率 (未設定は 1.0 = 標準)。
  double get multiplier => _multiplier[notifier.value] ?? 1.0;

  static AppFontSize _parse(String? v) => switch (v) {
        'large' => AppFontSize.large,
        'max' => AppFontSize.max,
        _ => AppFontSize.standard,
      };
}
