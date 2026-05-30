# 層 5: 連携層 (main.dart / PopScope / IndexedStack)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 1 / 総行数: 275
- class/mixin/extension/enum: 4
- 関数 (top-level + method の素拾い): 11
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

### `lib/main.dart` (275 行)

**imports:** dart=0 / package=3 / relative=19

- relative: `theme/solara_theme.dart`, `screens/ai_consent_screen.dart`, `screens/map_screen.dart`, `screens/horoscope_screen.dart`, `screens/observe_screen.dart`, `screens/galaxy_screen.dart`, `screens/sanctuary_screen.dart`, `utils/app_attest_client.dart`, `utils/app_locale.dart`, `utils/celestial_events.dart`, `utils/consultation_credits.dart`, `utils/device_security_status.dart`, `utils/map_focus.dart`, `utils/pro_status.dart`, `utils/purchases_service.dart`, `utils/solara_auth.dart`, `utils/solara_storage.dart`, `utils/tarot_data.dart`, `widgets/solara_nav_bar.dart`

**型定義 (4):**

- L78 `class SolaraApp : StatefulWidget`
- L89 `class _SolaraAppState : State`
- L131 `class SolaraHome : StatefulWidget`
- L138 `class _SolaraHomeState : State`

**関数 (8 public + 3 private):**

- L24 `main()`
- L86 `createState()`
- L93 `build()`
- L135 `createState()`
- L145 `initState()`
- L152 `dispose()`
- L171 `didChangeAppLifecycleState()`
- L226 `build()`

  <details><summary>private 関数 3 件</summary>

  - L160 `_onMapFocusRequested()`
  - L188 `_onGalaxyOverlayChanged()`
  - L203 `_onTabTap()`

  </details>

