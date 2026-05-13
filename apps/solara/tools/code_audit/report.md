# Solara Code Audit

対象: lib (132 個の .dart)

## 1. ファイル行数 (>= 300 行)

| 行数 | 判定 | ファイル |
|------|------|----------|
| 2696 | 🔴 HARD | lib/screens/map_screen.dart |
| 1799 | 🔴 HARD | lib/screens/map/map_daily_transit_screen.dart |
| 1384 | 🔴 HARD | lib/screens/sanctuary/sanctuary_title_diagnosis.dart |
| 1167 | 🔴 HARD | lib/screens/galaxy_screen.dart |
| 1050 | 🔴 HARD | lib/screens/forecast_screen.dart |
| 1034 | 🔴 HARD | lib/screens/sanctuary_screen.dart |
| 1013 | 🔴 HARD | lib/screens/map/daily_transit_data.dart |
| 813 | 🔴 HARD | lib/screens/map/map_astro_carto.dart |
| 775 | 🔴 HARD | lib/screens/map/map_fortune_sheet.dart |
| 758 | 🔴 HARD | lib/widgets/fortune_overlays/work_painter.dart |
| 754 | 🔴 HARD | lib/screens/horoscope_screen.dart |
| 737 | 🔴 HARD | lib/screens/locations_screen.dart |
| 702 | 🔴 HARD | lib/screens/horoscope/horo_chart_painter.dart |
| 693 | 🔴 HARD | lib/widgets/fortune_overlays/money_painter.dart |
| 646 | 🔴 HARD | lib/screens/map/map_viewpoint_menu.dart |
| 642 | 🔴 HARD | lib/widgets/fortune_overlays/communication_painter.dart |
| 626 | 🔴 HARD | lib/utils/constellation_namer.dart |
| 590 | 🔴 HARD | lib/screens/map/map_search.dart |
| 588 | 🔴 HARD | lib/screens/map/map_astro_lines.dart |
| 586 | 🔴 HARD | lib/utils/astro_glossary.dart |
| 585 | 🔴 HARD | lib/widgets/catasterism_formation_overlay.dart |
| 585 | 🔴 HARD | lib/screens/sanctuary/sanctuary_profile_editor.dart |
| 581 | 🔴 HARD | lib/widgets/fortune_overlays/love_painter.dart |
| 564 | 🔴 HARD | lib/widgets/new_moon_overlay.dart |
| 564 | 🔴 HARD | lib/screens/map/map_relocation_popup.dart |
| 559 | 🔴 HARD | lib/utils/planet_intro.dart |
| 524 | 🔴 HARD | lib/screens/observe_screen.dart |
| 508 | 🔴 HARD | lib/screens/map/map_astro.dart |
| 500 | 🔴 HARD | lib/screens/observe/tarot_altar_scene.dart |
| 498 | 🟡 WARN | lib/widgets/fortune_overlays/healing_painter.dart |
| 481 | 🟡 WARN | lib/widgets/full_moon_overlay.dart |
| 481 | 🟡 WARN | lib/screens/map/map_overlays.dart |
| 479 | 🟡 WARN | lib/utils/astro_lines.dart |
| 473 | 🟡 WARN | lib/screens/map/map_time_slider.dart |
| 462 | 🟡 WARN | lib/utils/forecast_cache.dart |
| 447 | 🟡 WARN | lib/screens/sanctuary/class_share_card.dart |
| 445 | 🟡 WARN | lib/widgets/catasterism_overlay.dart |
| 435 | 🟡 WARN | lib/screens/horoscope/horo_birth_panel.dart |
| 422 | 🟡 WARN | lib/screens/horoscope/horo_relocation_panel.dart |
| 410 | 🟡 WARN | lib/screens/map/map_display_menu.dart |
| 404 | 🟡 WARN | lib/utils/solara_storage.dart |
| 396 | 🟡 WARN | lib/widgets/cycle_spiral_painter.dart |
| 395 | 🟡 WARN | lib/utils/title_data.dart |
| 391 | 🟡 WARN | lib/screens/locations/locations_date_stepper.dart |
| 374 | 🟡 WARN | lib/screens/map/map_direction_popup.dart |
| 360 | 🟡 WARN | lib/utils/moon_phase.dart |
| 317 | 🟡 WARN | lib/screens/galaxy/galaxy_star_atlas.dart |
| 314 | 🟡 WARN | lib/utils/celestial_events.dart |
| 307 | 🟡 WARN | lib/screens/horoscope/horo_panel_shared.dart |
| 307 | 🟡 WARN | lib/screens/map/map_menu_chips.dart |
| 306 | 🟡 WARN | lib/widgets/class_card.dart |

## 2. 重複コード (>= 8 行連続一致、上位 20 件)

### 1. 📁 別ファイル間 (10 箇所、10 ファイル)

  - lib/screens/galaxy_screen.dart:475
  - lib/widgets/celestial_event_bar.dart:63
  - lib/widgets/full_moon_overlay.dart:300
  - lib/widgets/new_moon_overlay.dart:313
  - lib/screens/map/map_aspect_chip.dart:95
  ```
  ),
  ```

### 2. 📁 別ファイル間 (37 箇所、8 ファイル)

  - lib/screens/forecast_screen.dart:840
  - lib/screens/forecast_screen.dart:858
  - lib/screens/forecast_screen.dart:874
  - lib/screens/forecast_screen.dart:891
  - lib/screens/forecast_screen.dart:907
  ```
  style: TextStyle(
  ```

### 3. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/screens/galaxy_screen.dart:474
  - lib/widgets/full_moon_overlay.dart:299
  - lib/widgets/location_picker_minimap.dart:133
  - lib/screens/sanctuary/class_share_card.dart:213
  - lib/screens/sanctuary/sanctuary_orb_overlay.dart:164
  ```
  ),
  ```

### 4. 📁 別ファイル間 (12 箇所、6 ファイル)

  - lib/widgets/catasterism_overlay.dart:191
  - lib/widgets/full_moon_overlay.dart:200
  - lib/widgets/full_moon_overlay.dart:403
  - lib/widgets/full_moon_overlay.dart:458
  - lib/widgets/new_moon_overlay.dart:220
  ```
  ),
  ```

### 5. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/screens/sanctuary_screen.dart:1026
  - lib/widgets/catasterism_overlay.dart:189
  - lib/widgets/full_moon_overlay.dart:198
  - lib/widgets/info_popup.dart:105
  - lib/widgets/new_moon_overlay.dart:218
  ```
  ),
  ```

### 6. 📁 別ファイル間 (6 箇所、5 ファイル)

  - lib/screens/forecast_screen.dart:918
  - lib/screens/forecast_screen.dart:1011
  - lib/screens/map/map_astro_carto.dart:229
  - lib/screens/map/map_daily_transit_screen.dart:1792
  - lib/screens/map/map_fortune_sheet.dart:732
  ```
  style: TextStyle(
  ```

### 7. 📁 別ファイル間 (6 箇所、5 ファイル)

  - lib/screens/sanctuary_screen.dart:963
  - lib/widgets/class_card.dart:289
  - lib/screens/galaxy/galaxy_star_atlas.dart:267
  - lib/screens/map/map_daily_transit_screen.dart:295
  - lib/screens/map/map_daily_transit_screen.dart:1390
  ```
  ],
  ```

### 8. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/screens/galaxy_screen.dart:476
  - lib/widgets/full_moon_overlay.dart:301
  - lib/widgets/new_moon_overlay.dart:314
  - lib/screens/sanctuary/class_share_card.dart:215
  - lib/screens/sanctuary/sanctuary_orb_overlay.dart:166
  ```
  ),
  ```

### 9. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/widgets/class_card.dart:287
  - lib/widgets/location_picker_minimap.dart:134
  - lib/screens/galaxy/galaxy_star_atlas.dart:310
  - lib/screens/map/map_direction_popup.dart:286
  - lib/screens/sanctuary/class_share_card.dart:440
  ```
  ),
  ```

### 10. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:151
  - lib/widgets/fortune_overlays/healing_painter.dart:101
  - lib/widgets/fortune_overlays/love_painter.dart:89
  - lib/widgets/fortune_overlays/money_painter.dart:144
  - lib/widgets/fortune_overlays/work_painter.dart:130
  ```
  ));
  ```

### 11. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:152
  - lib/widgets/fortune_overlays/healing_painter.dart:102
  - lib/widgets/fortune_overlays/love_painter.dart:90
  - lib/widgets/fortune_overlays/money_painter.dart:145
  - lib/widgets/fortune_overlays/work_painter.dart:131
  ```
  }
  ```

### 12. 📁 別ファイル間 (6 箇所、4 ファイル)

  - lib/screens/galaxy/galaxy_star_atlas.dart:87
  - lib/screens/galaxy/galaxy_star_atlas.dart:121
  - lib/screens/map/map_astro_lines.dart:478
  - lib/screens/map/map_daily_transit_screen.dart:763
  - lib/screens/map/map_daily_transit_screen.dart:1497
  ```
  ),
  ```

### 13. 📁 別ファイル間 (6 箇所、4 ファイル)

  - lib/screens/map/map_daily_transit_screen.dart:257
  - lib/screens/map/map_location_markers.dart:59
  - lib/screens/map/map_location_markers.dart:114
  - lib/screens/map/map_menu_chips.dart:178
  - lib/screens/map/map_menu_chips.dart:268
  ```
  ),
  ```

### 14. 📁 別ファイル間 (5 箇所、4 ファイル)

  - lib/screens/forecast_screen.dart:919
  - lib/screens/forecast_screen.dart:1012
  - lib/screens/map/map_astro_carto.dart:230
  - lib/screens/map/map_fortune_sheet.dart:733
  - lib/screens/map/map_viewpoint_menu.dart:129
  ```
  color: Color(0xFFE8E0D0), fontSize: 13, height: 1.6),
  ```

### 15. 📁 別ファイル間 (5 箇所、4 ファイル)

  - lib/screens/sanctuary_screen.dart:1027
  - lib/widgets/info_popup.dart:106
  - lib/screens/map/map_astro_carto.dart:444
  - lib/screens/map/map_astro_carto.dart:508
  - lib/screens/map/map_daily_transit_screen.dart:1011
  ```
  ),
  ```

### 16. 📁 別ファイル間 (5 箇所、4 ファイル)

  - lib/widgets/catasterism_overlay.dart:187
  - lib/widgets/full_moon_overlay.dart:196
  - lib/widgets/new_moon_overlay.dart:216
  - lib/widgets/new_moon_overlay.dart:419
  - lib/screens/sanctuary/class_share_card.dart:210
  ```
  ),
  ```

### 17. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/screens/sanctuary_screen.dart:1025
  - lib/widgets/catasterism_overlay.dart:188
  - lib/widgets/full_moon_overlay.dart:197
  - lib/widgets/new_moon_overlay.dart:217
  ```
  ),
  ```

### 18. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/catasterism_overlay.dart:190
  - lib/widgets/full_moon_overlay.dart:199
  - lib/widgets/new_moon_overlay.dart:219
  - lib/screens/map/map_viewpoint_menu.dart:344
  ```
  ),
  ```

### 19. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/location_picker_minimap.dart:131
  - lib/widgets/new_moon_overlay.dart:420
  - lib/screens/sanctuary/class_share_card.dart:211
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:549
  ```
  ),
  ```

### 20. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:153
  - lib/widgets/fortune_overlays/healing_painter.dart:103
  - lib/widgets/fortune_overlays/money_painter.dart:146
  - lib/widgets/fortune_overlays/work_painter.dart:132
  ```
  return list;
  ```


## 3. TODO/FIXME/HACK/DEBUG 残置

  - lib/screens/galaxy_screen.dart:387 — `// DEBUG: Cycle完了フローの各タイミングを手動トリガー`
  - lib/screens/sanctuary_screen.dart:438 — `// TODO(Pro): RevenueCat 実装後、isPro || canRedo に変更`

## 4. print()/debugPrint() 残置

  - lib/screens/map_screen.dart:338 — `debugPrint('[Solara Map] 🔄 settle reset (verify-recover, 4層防御 第4層)');`
  - lib/screens/map_screen.dart:373 — `debugPrint(`
  - lib/screens/map_screen.dart:381 — `debugPrint(`
  - lib/screens/map_screen.dart:400 — `debugPrint(`
  - lib/screens/map_screen.dart:412 — `debugPrint(`
  - lib/screens/map/map_styles.dart:132 — `debugPrint(`
  - lib/screens/map/map_styles.dart:142 — `debugPrint('[Solara TileLayer] 🏗  build style=${cfg.id}');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:203 — `debugPrint(`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:213 — `debugPrint(`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:225 — `debugPrint(`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:319 — `debugPrint('[Solara Title] ═══ 診断結果 ═══');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:320 — `debugPrint('[Solara Title] scores       : $_scores');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:321 — `debugPrint('[Solara Title] selections   : $_selections');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:322 — `debugPrint('[Solara Title] courtCounts  : $courtCounts');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:323 — `debugPrint('[Solara Title] courtList    : $_courtSelections');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:324 — `debugPrint(`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:326 — `debugPrint('[Solara Title] → topAxis    : $topAxis (winners=$winners)');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:327 — `debugPrint('[Solara Title] → court      : $court [$courtRoute]');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:334 — `debugPrint('[Solara Title] ❌ getClassByAxisCourt returned null for $topAxis/$court');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:340 — `debugPrint('[Solara Title] → class      : ${cls.nameJP} (${cls.nameEN})');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:348 — `debugPrint('[Solara Title] → sun/moon   : $sunSign × $moonSign');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:349 — `debugPrint('[Solara Title] → t144.light : ${t144?['light']}');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:350 — `debugPrint('[Solara Title] → t144.shadow: ${t144?['shadow']}');`
  - lib/screens/sanctuary/sanctuary_title_diagnosis.dart:351 — `debugPrint('[Solara Title] ═══════════════');`

## 5. 未使用 private member 候補 (file 内 reference == 1)

✅ なし

---

総計: 行数違反 51 / 重複 20 / TODO 2 / print 24 / 未使用候補 0
