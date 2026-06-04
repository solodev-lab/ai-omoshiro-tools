import 'package:flutter/material.dart';

// slang も AppLocale を定義するため、app_locale.dart の AppLocale と衝突しないよう hide。
import '../../i18n/strings.g.dart' hide AppLocale;
import '../../utils/app_locale.dart';
import '../../utils/app_text_scale.dart';

/// Sanctuary「✦ App」設定の言語 / 文字サイズ ピッカー (bottom sheet)。
/// sanctuary_screen.dart が肥大化しているため別ファイルに分離。

const _kSheetBg = Color(0xFF0A0E1C);
const _kGold = Color(0xFFF9D976);
const _kText = Color(0xFFEAEAEA);
const _kSub = Color(0xFFACACAC);

/// 言語設定の現在値ラベル (設定行の右側表示用)。
String languageValueLabel() {
  switch (AppLocale.instance.notifier.value?.languageCode) {
    case 'ja':
      return '日本語';
    case 'en':
      return 'English';
    default:
      return t.profileEdit.langDevice; // 端末 / Device
  }
}

/// 文字サイズ設定の現在値ラベル。
String fontSizeValueLabel() {
  switch (AppTextScale.instance.notifier.value) {
    case AppFontSize.large:
      return t.appSettings.fontLarge;
    case AppFontSize.max:
      return t.appSettings.fontMax;
    case AppFontSize.standard:
      return t.appSettings.fontStandard;
  }
}

/// 言語ピッカー (端末追従 / 日本語 / English)。選択で即 [AppLocale.setOverride]。
Future<void> showLanguagePicker(BuildContext context) {
  final current = AppLocale.instance.notifier.value?.languageCode;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: _kSheetBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetTitle(t.appSettings.langTitle),
          _PickerOption(
            label: t.profileEdit.langDevice,
            sub: t.profileEdit.langDeviceSub,
            selected: current == null,
            onTap: () {
              AppLocale.instance.setOverride(null);
              Navigator.of(ctx).pop();
            },
          ),
          _PickerOption(
            label: '日本語',
            sub: 'Japanese',
            selected: current == 'ja',
            onTap: () {
              AppLocale.instance.setOverride('ja');
              Navigator.of(ctx).pop();
            },
          ),
          _PickerOption(
            label: 'English',
            sub: t.profileEdit.langEnglishSub,
            selected: current == 'en',
            onTap: () {
              AppLocale.instance.setOverride('en');
              Navigator.of(ctx).pop();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

/// 文字サイズピッカー (標準 / 大きめ / 最大) + 注意書き。
Future<void> showFontSizePicker(BuildContext context) {
  final current = AppTextScale.instance.notifier.value;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: _kSheetBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetTitle(t.appSettings.fontSizeTitle),
          _PickerOption(
            label: t.appSettings.fontStandard,
            selected: current == AppFontSize.standard,
            onTap: () {
              AppTextScale.instance.setLevel(AppFontSize.standard);
              Navigator.of(ctx).pop();
            },
          ),
          _PickerOption(
            label: t.appSettings.fontLarge,
            selected: current == AppFontSize.large,
            onTap: () {
              AppTextScale.instance.setLevel(AppFontSize.large);
              Navigator.of(ctx).pop();
            },
          ),
          _PickerOption(
            label: t.appSettings.fontMax,
            selected: current == AppFontSize.max,
            onTap: () {
              AppTextScale.instance.setLevel(AppFontSize.max);
              Navigator.of(ctx).pop();
            },
          ),
          // 注意書き: 大きいサイズは Map / Galaxy 等の絵主役画面が窮屈になり得る。
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: _kSub),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.appSettings.fontCaveat,
                    style: const TextStyle(
                        fontSize: 12, height: 1.5, color: _kSub),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _sheetTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kGold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );

class _PickerOption extends StatelessWidget {
  final String label;
  final String? sub;
  final bool selected;
  final VoidCallback onTap;
  const _PickerOption({
    required this.label,
    this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 16, color: _kText)),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(sub!,
                        style: const TextStyle(fontSize: 12, color: _kSub)),
                  ],
                ],
              ),
            ),
            if (selected) const Icon(Icons.check, size: 20, color: _kGold),
          ],
        ),
      ),
    );
  }
}
