# Solara Text Overflow 監査レポート
対象: `apps/solara/lib/**/*.dart` (除外: ['.dart_tool', 'test', 'tools'])
検出総数: **5** 箇所

## カテゴリ別サマリ
| 重大度 | カテゴリ | 件数 |
|---|---|---|
| 🔴🔴🔴 | 🔴 Row 直下の裸 Text (Flexible なし & overflow 設定なし) — 最優先 | 5 |
| 🔴🔴⚪ | 🟡 Row 直下、Flex でラップ済みだが overflow 未設定 | 0 |
| 🔴🔴⚪ | 🟡 Row 直下、overflow 設定済みだが Flexible で囲まれていない | 0 |

## ファイル別チェックリスト

各箇所を確認・修正したらチェックを入れてください。

### `lib/screens/map/map_daily_transit_screen.dart` (1 件)

- [ ] **L391** 🔴 Row 直下の裸 Text (Flexible なし & overflow 設定なし) — 最優先
  ```dart
       389:         child: Row(
       390:           children: [
   >>  391:             Text(emoji, style: const TextStyle(fontSize: 18)),
       392:             const SizedBox(width: 10),
       393:             Expanded(
  ```

### `lib/screens/sanctuary_screen.dart` (1 件)

- [ ] **L840** 🔴 Row 直下の裸 Text (Flexible なし & overflow 設定なし) — 最優先
  ```dart
       838:             Icon(Icons.auto_awesome, color: Color(0xFFF9D976), size: 18),
       839:             SizedBox(width: 8),
   >>  840:             Text(
       841:               'Cosmic Pro 加入中',
       842:               style: TextStyle(
  ```

### `lib/widgets/pro_unlock_dialog.dart` (2 件)

- [ ] **L90** 🔴 Row 直下の裸 Text (Flexible なし & overflow 設定なし) — 最優先
  ```dart
        88:         ),
        89:         SizedBox(width: 10),
   >>   90:         Text(
        91:           '✦ Cosmic Pro',
        92:           style: TextStyle(
  ```

- [ ] **L186** 🔴 Row 直下の裸 Text (Flexible なし & overflow 設定なし) — 最優先
  ```dart
       184:         ),
       185:         SizedBox(width: 10),
   >>  186:         Text(
       187:           '✦ デバイスのセキュリティ確認',
       188:           style: TextStyle(
  ```

### `lib/widgets/sanctuary_account_section.dart` (1 件)

- [ ] **L198** 🔴 Row 直下の裸 Text (Flexible なし & overflow 設定なし) — 最優先
  ```dart
       196:             ),
       197:             const SizedBox(width: 8),
   >>  198:             Text(
       199:               label,
       200:               style: TextStyle(
  ```

