# 層 5: 連携層 (main.dart / PopScope / IndexedStack)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 1 / 総行数: 449
- class/mixin/extension/enum: 4
- 関数 (top-level + method の素拾い): 14
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

### `lib/main.dart` (449 行)

**imports:** dart=0 / package=3 / relative=26

- relative: `theme/solara_theme.dart`, `screens/ai_consent_screen.dart`, `screens/map_screen.dart`, `screens/horoscope_screen.dart`, `screens/observe_screen.dart`, `screens/galaxy_screen.dart`, `screens/sanctuary_screen.dart`, `screens/consultation/consultation_input_screen.dart`, `screens/consultation/consultation_result_screen.dart`, `screens/consultation/consultation_history_screen.dart`, `screens/sanctuary/title_history_screen.dart`, `screens/sanctuary/class_share_card.dart`, `utils/app_attest_client.dart`, `utils/app_locale.dart`, `utils/celestial_events.dart`, `utils/consult_restore.dart`, `utils/consultation_credits.dart`, `utils/consultation_record.dart`, `utils/device_security_status.dart`, `utils/map_focus.dart`, `utils/pro_status.dart`, `utils/purchases_service.dart`, `utils/solara_auth.dart`, `utils/solara_storage.dart`, `utils/tarot_data.dart`, `widgets/solara_nav_bar.dart`

**型定義 (4):**

- L85 `class SolaraApp : StatefulWidget`
- L96 `class _SolaraAppState : State`
- L143 `class SolaraHome : StatefulWidget`
- L150 `class _SolaraHomeState : State`

**関数 (8 public + 6 private):**

- L31 `main()`
- L93 `createState()`
- L100 `build()`
- L147 `createState()`
- L163 `initState()`
- L317 `dispose()`
- L336 `didChangeAppLifecycleState()`
- L400 `build()`

  <details><summary>private 関数 6 件</summary>

  - L174 `_restoreLastScreen()`
  - L234 `_restorePushedRoute()`
  - L287 `_saveRestoreSnapshot()`
  - L325 `_onMapFocusRequested()`
  - L362 `_onGalaxyOverlayChanged()`
  - L377 `_onTabTap()`

  </details>

