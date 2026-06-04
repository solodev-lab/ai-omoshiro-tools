# 層 5: 連携層 (main.dart / PopScope / IndexedStack)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 1 / 総行数: 609
- class/mixin/extension/enum: 4
- 関数 (top-level + method の素拾い): 18
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

### `lib/main.dart` (609 行)

**imports:** dart=0 / package=3 / relative=31

- relative: `theme/solara_theme.dart`, `screens/ai_consent_screen.dart`, `screens/map_screen.dart`, `screens/horoscope_screen.dart`, `screens/observe_screen.dart`, `screens/galaxy_screen.dart`, `screens/sanctuary_screen.dart`, `screens/consultation/consultation_input_screen.dart`, `screens/consultation/consultation_result_screen.dart`, `screens/consultation/consultation_history_screen.dart`, `screens/sanctuary/title_history_screen.dart`, `screens/sanctuary/class_share_card.dart`, `utils/app_attest_client.dart`, `utils/app_locale.dart`, `utils/app_text_scale.dart`, `utils/celestial_events.dart`, `utils/consult_restore.dart`, `utils/consultation_credits.dart`, `utils/consultation_record.dart`, `utils/consultation_return.dart`, `utils/device_security_status.dart`, `utils/map_focus.dart`, `utils/moon_event_status.dart`, `utils/moon_notification_service.dart`, `utils/pro_status.dart`, `utils/purchases_service.dart`, `utils/solara_auth.dart`, `utils/solara_i18n.dart`, `utils/solara_storage.dart`, `utils/tarot_data.dart`, `widgets/solara_nav_bar.dart`

**型定義 (4):**

- L98 `class SolaraApp : StatefulWidget`
- L109 `class _SolaraAppState : State`
- L178 `class SolaraHome : StatefulWidget`
- L185 `class _SolaraHomeState : State`

**関数 (8 public + 10 private):**

- L36 `main()`
- L106 `createState()`
- L113 `build()`
- L182 `createState()`
- L201 `initState()`
- L382 `dispose()`
- L437 `didChangeAppLifecycleState()`
- L559 `build()`

  <details><summary>private 関数 10 件</summary>

  - L222 `_restoreLastScreen()`
  - L290 `_restorePushedRoute()`
  - L345 `_saveRestoreSnapshot()`
  - L393 `_onLocaleChanged()`
  - L406 `_onSigninCelebration()`
  - L426 `_onMapFocusRequested()`
  - L470 `_onGalaxyOverlayChanged()`
  - L496 `_refreshMoonStatus()`
  - L510 `_buildScreens()`
  - L523 `_onTabTap()`

  </details>

