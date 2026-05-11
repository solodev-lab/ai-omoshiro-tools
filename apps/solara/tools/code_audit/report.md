# Solara Code Audit

対象: lib (129 個の .dart)

## 1. ファイル行数 (>= 300 行)

| 行数 | 判定 | ファイル |
|------|------|----------|
| 2324 | 🔴 HARD | lib/screens/map_screen.dart |
| 1799 | 🔴 HARD | lib/screens/map/map_daily_transit_screen.dart |
| 1167 | 🔴 HARD | lib/screens/galaxy_screen.dart |
| 1045 | 🔴 HARD | lib/screens/forecast_screen.dart |
| 1023 | 🔴 HARD | lib/screens/map/daily_transit_data.dart |
| 852 | 🔴 HARD | lib/screens/sanctuary_screen.dart |
| 813 | 🔴 HARD | lib/screens/map/map_astro_carto.dart |
| 763 | 🔴 HARD | lib/screens/map/map_fortune_sheet.dart |
| 758 | 🔴 HARD | lib/widgets/fortune_overlays/work_painter.dart |
| 754 | 🔴 HARD | lib/screens/horoscope_screen.dart |
| 732 | 🔴 HARD | lib/screens/locations_screen.dart |
| 702 | 🔴 HARD | lib/screens/horoscope/horo_chart_painter.dart |
| 693 | 🔴 HARD | lib/widgets/fortune_overlays/money_painter.dart |
| 685 | 🔴 HARD | lib/screens/map/map_search.dart |
| 642 | 🔴 HARD | lib/widgets/fortune_overlays/communication_painter.dart |
| 626 | 🔴 HARD | lib/utils/constellation_namer.dart |
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
| 498 | 🟡 WARN | lib/screens/map/map_viewpoint_menu.dart |
| 481 | 🟡 WARN | lib/widgets/full_moon_overlay.dart |
| 479 | 🟡 WARN | lib/utils/astro_lines.dart |
| 473 | 🟡 WARN | lib/screens/map/map_time_slider.dart |
| 462 | 🟡 WARN | lib/utils/forecast_cache.dart |
| 445 | 🟡 WARN | lib/widgets/catasterism_overlay.dart |
| 432 | 🟡 WARN | lib/screens/horoscope/horo_birth_panel.dart |
| 422 | 🟡 WARN | lib/screens/horoscope/horo_relocation_panel.dart |
| 408 | 🟡 WARN | lib/screens/map/map_display_menu.dart |
| 404 | 🟡 WARN | lib/utils/solara_storage.dart |
| 396 | 🟡 WARN | lib/widgets/cycle_spiral_painter.dart |
| 395 | 🟡 WARN | lib/utils/title_data.dart |
| 391 | 🟡 WARN | lib/screens/locations/locations_date_stepper.dart |
| 374 | 🟡 WARN | lib/screens/map/map_direction_popup.dart |
| 364 | 🟡 WARN | lib/screens/sanctuary/sanctuary_title_diagnosis.dart |
| 360 | 🟡 WARN | lib/utils/moon_phase.dart |
| 322 | 🟡 WARN | lib/screens/map/map_overlays.dart |
| 317 | 🟡 WARN | lib/screens/galaxy/galaxy_star_atlas.dart |
| 314 | 🟡 WARN | lib/utils/celestial_events.dart |
| 307 | 🟡 WARN | lib/screens/horoscope/horo_panel_shared.dart |

## 2. 重複コード (>= 8 行連続一致、上位 20 件)

### 1. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/screens/galaxy_screen.dart:475
  - lib/widgets/celestial_event_bar.dart:63
  - lib/widgets/full_moon_overlay.dart:300
  - lib/widgets/new_moon_overlay.dart:313
  - lib/screens/map/map_aspect_chip.dart:95
  ```
  ),
  ```

### 2. 📁 別ファイル間 (28 箇所、6 ファイル)

  - lib/screens/forecast_screen.dart:835
  - lib/screens/forecast_screen.dart:853
  - lib/screens/forecast_screen.dart:869
  - lib/screens/forecast_screen.dart:886
  - lib/screens/forecast_screen.dart:902
  ```
  style: TextStyle(
  ```

### 3. 📁 別ファイル間 (12 箇所、6 ファイル)

  - lib/widgets/catasterism_overlay.dart:191
  - lib/widgets/full_moon_overlay.dart:200
  - lib/widgets/full_moon_overlay.dart:403
  - lib/widgets/full_moon_overlay.dart:458
  - lib/widgets/new_moon_overlay.dart:220
  ```
  ),
  ```

### 4. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/screens/sanctuary_screen.dart:844
  - lib/widgets/catasterism_overlay.dart:189
  - lib/widgets/full_moon_overlay.dart:198
  - lib/widgets/info_popup.dart:105
  - lib/widgets/new_moon_overlay.dart:218
  ```
  ),
  ```

### 5. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:151
  - lib/widgets/fortune_overlays/healing_painter.dart:101
  - lib/widgets/fortune_overlays/love_painter.dart:89
  - lib/widgets/fortune_overlays/money_painter.dart:144
  - lib/widgets/fortune_overlays/work_painter.dart:130
  ```
  ));
  ```

### 6. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:152
  - lib/widgets/fortune_overlays/healing_painter.dart:102
  - lib/widgets/fortune_overlays/love_painter.dart:90
  - lib/widgets/fortune_overlays/money_painter.dart:145
  - lib/widgets/fortune_overlays/work_painter.dart:131
  ```
  }
  ```

### 7. 📁 別ファイル間 (6 箇所、4 ファイル)

  - lib/screens/galaxy/galaxy_star_atlas.dart:87
  - lib/screens/galaxy/galaxy_star_atlas.dart:121
  - lib/screens/map/map_astro_lines.dart:478
  - lib/screens/map/map_daily_transit_screen.dart:763
  - lib/screens/map/map_daily_transit_screen.dart:1497
  ```
  ),
  ```

### 8. 📁 別ファイル間 (5 箇所、4 ファイル)

  - lib/screens/forecast_screen.dart:913
  - lib/screens/forecast_screen.dart:1006
  - lib/screens/map/map_astro_carto.dart:229
  - lib/screens/map/map_daily_transit_screen.dart:1792
  - lib/screens/map/map_fortune_sheet.dart:720
  ```
  style: TextStyle(
  ```

### 9. 📁 別ファイル間 (5 箇所、4 ファイル)

  - lib/screens/sanctuary_screen.dart:781
  - lib/screens/galaxy/galaxy_star_atlas.dart:267
  - lib/screens/map/map_daily_transit_screen.dart:295
  - lib/screens/map/map_daily_transit_screen.dart:1390
  - lib/screens/map/map_menu_chips.dart:62
  ```
  ],
  ```

### 10. 📁 別ファイル間 (5 箇所、4 ファイル)

  - lib/screens/sanctuary_screen.dart:845
  - lib/widgets/info_popup.dart:106
  - lib/screens/map/map_astro_carto.dart:444
  - lib/screens/map/map_astro_carto.dart:508
  - lib/screens/map/map_daily_transit_screen.dart:1011
  ```
  ),
  ```

### 11. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/screens/galaxy_screen.dart:474
  - lib/widgets/full_moon_overlay.dart:299
  - lib/widgets/location_picker_minimap.dart:133
  - lib/screens/sanctuary/sanctuary_orb_overlay.dart:164
  ```
  ),
  ```

### 12. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/screens/galaxy_screen.dart:476
  - lib/widgets/full_moon_overlay.dart:301
  - lib/widgets/new_moon_overlay.dart:314
  - lib/screens/sanctuary/sanctuary_orb_overlay.dart:166
  ```
  ),
  ```

### 13. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/screens/sanctuary_screen.dart:843
  - lib/widgets/catasterism_overlay.dart:188
  - lib/widgets/full_moon_overlay.dart:197
  - lib/widgets/new_moon_overlay.dart:217
  ```
  ),
  ```

### 14. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/catasterism_overlay.dart:190
  - lib/widgets/full_moon_overlay.dart:199
  - lib/widgets/new_moon_overlay.dart:219
  - lib/screens/map/map_viewpoint_menu.dart:196
  ```
  ),
  ```

### 15. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:153
  - lib/widgets/fortune_overlays/healing_painter.dart:103
  - lib/widgets/fortune_overlays/money_painter.dart:146
  - lib/widgets/fortune_overlays/work_painter.dart:132
  ```
  return list;
  ```

### 16. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:622
  - lib/widgets/fortune_overlays/healing_painter.dart:478
  - lib/widgets/fortune_overlays/money_painter.dart:670
  - lib/widgets/fortune_overlays/work_painter.dart:737
  ```
  const Color(0x00000000),
  ```

### 17. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:623
  - lib/widgets/fortune_overlays/healing_painter.dart:479
  - lib/widgets/fortune_overlays/money_painter.dart:671
  - lib/widgets/fortune_overlays/work_painter.dart:738
  ```
  ], [0.0, 0.5, 1.0])
  ```

### 18. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:624
  - lib/widgets/fortune_overlays/healing_painter.dart:480
  - lib/widgets/fortune_overlays/money_painter.dart:672
  - lib/widgets/fortune_overlays/work_painter.dart:739
  ```
  ..blendMode = BlendMode.plus);
  ```

### 19. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:625
  - lib/widgets/fortune_overlays/healing_painter.dart:481
  - lib/widgets/fortune_overlays/money_painter.dart:673
  - lib/widgets/fortune_overlays/work_painter.dart:740
  ```
  final starPaint = Paint()..color = color.withValues(alpha: alpha)..blendMode = B
  ```

### 20. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:626
  - lib/widgets/fortune_overlays/healing_painter.dart:482
  - lib/widgets/fortune_overlays/money_painter.dart:674
  - lib/widgets/fortune_overlays/work_painter.dart:741
  ```
  canvas.drawPath(Path()
  ```


## 3. TODO/FIXME/HACK/DEBUG 残置

  - lib/screens/galaxy_screen.dart:387 — `// DEBUG: Cycle完了フローの各タイミングを手動トリガー`
  - lib/screens/map_screen.dart:1276 — `// TODO: geolocator パッケージ追加後に実装`

## 4. print()/debugPrint() 残置

  - lib/screens/map_screen.dart:329 — `debugPrint('[Solara Map] 🔄 settle reset (verify-recover, 4層防御 第4層)');`
  - lib/screens/map_screen.dart:364 — `debugPrint(`
  - lib/screens/map_screen.dart:372 — `debugPrint(`
  - lib/screens/map_screen.dart:391 — `debugPrint(`
  - lib/screens/map_screen.dart:403 — `debugPrint(`
  - lib/screens/map/map_styles.dart:132 — `debugPrint(`
  - lib/screens/map/map_styles.dart:142 — `debugPrint('[Solara TileLayer] 🏗  build style=${cfg.id}');`

## 5. 未使用 private member 候補 (file 内 reference == 1)

✅ なし

---

総計: 行数違反 48 / 重複 20 / TODO 2 / print 7 / 未使用候補 0
