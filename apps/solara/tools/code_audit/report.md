# Solara Code Audit

対象: lib (125 個の .dart)

## 1. ファイル行数 (>= 300 行)

| 行数 | 判定 | ファイル |
|------|------|----------|
| 1739 | 🔴 HARD | lib/screens/map_screen.dart |
| 1288 | 🔴 HARD | lib/screens/map/map_daily_transit_screen.dart |
| 904 | 🔴 HARD | lib/screens/galaxy_screen.dart |
| 847 | 🔴 HARD | lib/screens/sanctuary_screen.dart |
| 766 | 🔴 HARD | lib/screens/horoscope_screen.dart |
| 758 | 🔴 HARD | lib/widgets/fortune_overlays/work_painter.dart |
| 712 | 🔴 HARD | lib/screens/forecast_screen.dart |
| 702 | 🔴 HARD | lib/screens/horoscope/horo_chart_painter.dart |
| 693 | 🔴 HARD | lib/widgets/fortune_overlays/money_painter.dart |
| 642 | 🔴 HARD | lib/widgets/fortune_overlays/communication_painter.dart |
| 626 | 🔴 HARD | lib/utils/constellation_namer.dart |
| 585 | 🔴 HARD | lib/widgets/catasterism_formation_overlay.dart |
| 585 | 🔴 HARD | lib/screens/sanctuary/sanctuary_profile_editor.dart |
| 581 | 🔴 HARD | lib/widgets/fortune_overlays/love_painter.dart |
| 579 | 🔴 HARD | lib/screens/map/map_search.dart |
| 559 | 🔴 HARD | lib/widgets/new_moon_overlay.dart |
| 556 | 🔴 HARD | lib/utils/astro_glossary.dart |
| 547 | 🔴 HARD | lib/screens/locations_screen.dart |
| 520 | 🔴 HARD | lib/screens/observe_screen.dart |
| 508 | 🔴 HARD | lib/screens/map/map_astro.dart |
| 500 | 🔴 HARD | lib/screens/map/map_relocation_popup.dart |
| 500 | 🔴 HARD | lib/screens/observe/tarot_altar_scene.dart |
| 498 | 🟡 WARN | lib/widgets/fortune_overlays/healing_painter.dart |
| 481 | 🟡 WARN | lib/screens/map/map_line_narrative_sheet.dart |
| 469 | 🟡 WARN | lib/widgets/full_moon_overlay.dart |
| 467 | 🟡 WARN | lib/utils/astro_lines.dart |
| 462 | 🟡 WARN | lib/utils/forecast_cache.dart |
| 462 | 🟡 WARN | lib/screens/map/map_vp_panel.dart |
| 445 | 🟡 WARN | lib/widgets/catasterism_overlay.dart |
| 445 | 🟡 WARN | lib/screens/map/map_astro_carto.dart |
| 408 | 🟡 WARN | lib/screens/horoscope/horo_relocation_panel.dart |
| 404 | 🟡 WARN | lib/utils/solara_storage.dart |
| 396 | 🟡 WARN | lib/widgets/cycle_spiral_painter.dart |
| 395 | 🟡 WARN | lib/utils/title_data.dart |
| 391 | 🟡 WARN | lib/screens/map/map_direction_popup.dart |
| 386 | 🟡 WARN | lib/screens/map/map_fortune_sheet.dart |
| 381 | 🟡 WARN | lib/screens/map/map_overlays.dart |
| 372 | 🟡 WARN | lib/screens/map/daily_transit_data.dart |
| 364 | 🟡 WARN | lib/screens/sanctuary/sanctuary_title_diagnosis.dart |
| 351 | 🟡 WARN | lib/screens/map/map_time_slider.dart |
| 329 | 🟡 WARN | lib/utils/moon_phase.dart |
| 319 | 🟡 WARN | lib/screens/map/map_astro_lines.dart |
| 317 | 🟡 WARN | lib/screens/galaxy/galaxy_star_atlas.dart |
| 314 | 🟡 WARN | lib/utils/celestial_events.dart |
| 311 | 🟡 WARN | lib/screens/map/map_layer_panel.dart |

## 2. 重複コード (>= 8 行連続一致、上位 20 件)

### 1. 📁 別ファイル間 (10 箇所、7 ファイル)

  - lib/widgets/catasterism_overlay.dart:191
  - lib/widgets/full_moon_overlay.dart:200
  - lib/widgets/full_moon_overlay.dart:403
  - lib/widgets/new_moon_overlay.dart:220
  - lib/widgets/new_moon_overlay.dart:467
  ```
  ),
  ```

### 2. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/widgets/celestial_event_bar.dart:62
  - lib/widgets/full_moon_overlay.dart:300
  - lib/widgets/new_moon_overlay.dart:313
  - lib/screens/map/map_aspect_chip.dart:94
  - lib/screens/map/map_direction_popup.dart:180
  ```
  ),
  ```

### 3. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/screens/sanctuary_screen.dart:839
  - lib/widgets/catasterism_overlay.dart:189
  - lib/widgets/full_moon_overlay.dart:198
  - lib/widgets/new_moon_overlay.dart:218
  - lib/screens/map/map_daily_transit_screen.dart:870
  ```
  ),
  ```

### 4. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:151
  - lib/widgets/fortune_overlays/healing_painter.dart:101
  - lib/widgets/fortune_overlays/love_painter.dart:89
  - lib/widgets/fortune_overlays/money_painter.dart:144
  - lib/widgets/fortune_overlays/work_painter.dart:130
  ```
  ));
  ```

### 5. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:152
  - lib/widgets/fortune_overlays/healing_painter.dart:102
  - lib/widgets/fortune_overlays/love_painter.dart:90
  - lib/widgets/fortune_overlays/money_painter.dart:145
  - lib/widgets/fortune_overlays/work_painter.dart:131
  ```
  }
  ```

### 6. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/screens/sanctuary_screen.dart:838
  - lib/widgets/catasterism_overlay.dart:188
  - lib/widgets/full_moon_overlay.dart:197
  - lib/widgets/new_moon_overlay.dart:217
  ```
  ),
  ```

### 7. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/full_moon_overlay.dart:299
  - lib/widgets/location_picker_minimap.dart:133
  - lib/screens/map/map_direction_popup.dart:179
  - lib/screens/sanctuary/sanctuary_orb_overlay.dart:155
  ```
  ),
  ```

### 8. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/full_moon_overlay.dart:301
  - lib/widgets/new_moon_overlay.dart:314
  - lib/screens/map/map_direction_popup.dart:181
  - lib/screens/sanctuary/sanctuary_orb_overlay.dart:157
  ```
  ),
  ```

### 9. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:153
  - lib/widgets/fortune_overlays/healing_painter.dart:103
  - lib/widgets/fortune_overlays/money_painter.dart:146
  - lib/widgets/fortune_overlays/work_painter.dart:132
  ```
  return list;
  ```

### 10. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:622
  - lib/widgets/fortune_overlays/healing_painter.dart:478
  - lib/widgets/fortune_overlays/money_painter.dart:670
  - lib/widgets/fortune_overlays/work_painter.dart:737
  ```
  const Color(0x00000000),
  ```

### 11. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:623
  - lib/widgets/fortune_overlays/healing_painter.dart:479
  - lib/widgets/fortune_overlays/money_painter.dart:671
  - lib/widgets/fortune_overlays/work_painter.dart:738
  ```
  ], [0.0, 0.5, 1.0])
  ```

### 12. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:624
  - lib/widgets/fortune_overlays/healing_painter.dart:480
  - lib/widgets/fortune_overlays/money_painter.dart:672
  - lib/widgets/fortune_overlays/work_painter.dart:739
  ```
  ..blendMode = BlendMode.plus);
  ```

### 13. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:625
  - lib/widgets/fortune_overlays/healing_painter.dart:481
  - lib/widgets/fortune_overlays/money_painter.dart:673
  - lib/widgets/fortune_overlays/work_painter.dart:740
  ```
  final starPaint = Paint()..color = color.withValues(alpha: alpha)..blendMode = B
  ```

### 14. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:626
  - lib/widgets/fortune_overlays/healing_painter.dart:482
  - lib/widgets/fortune_overlays/money_painter.dart:674
  - lib/widgets/fortune_overlays/work_painter.dart:741
  ```
  canvas.drawPath(Path()
  ```

### 15. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:627
  - lib/widgets/fortune_overlays/healing_painter.dart:483
  - lib/widgets/fortune_overlays/money_painter.dart:675
  - lib/widgets/fortune_overlays/work_painter.dart:742
  ```
  ..moveTo(0, -size2 * 0.5)
  ```

### 16. 📁 別ファイル間 (4 箇所、4 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:628
  - lib/widgets/fortune_overlays/healing_painter.dart:484
  - lib/widgets/fortune_overlays/money_painter.dart:676
  - lib/widgets/fortune_overlays/work_painter.dart:743
  ```
  ..quadraticBezierTo(size2 * 0.04, 0, 0, size2 * 0.5)
  ```

### 17. 📁 別ファイル間 (4 箇所、3 ファイル)

  - lib/widgets/catasterism_overlay.dart:166
  - lib/widgets/full_moon_overlay.dart:175
  - lib/widgets/new_moon_overlay.dart:195
  - lib/widgets/new_moon_overlay.dart:398
  ```
  child: Container(
  ```

### 18. 📁 別ファイル間 (4 箇所、3 ファイル)

  - lib/widgets/catasterism_overlay.dart:167
  - lib/widgets/full_moon_overlay.dart:176
  - lib/widgets/new_moon_overlay.dart:196
  - lib/widgets/new_moon_overlay.dart:399
  ```
  width: 240,
  ```

### 19. 📁 別ファイル間 (4 箇所、3 ファイル)

  - lib/widgets/catasterism_overlay.dart:168
  - lib/widgets/full_moon_overlay.dart:177
  - lib/widgets/new_moon_overlay.dart:197
  - lib/widgets/new_moon_overlay.dart:400
  ```
  padding: const EdgeInsets.symmetric(vertical: 15),
  ```

### 20. 📁 別ファイル間 (4 箇所、3 ファイル)

  - lib/widgets/catasterism_overlay.dart:169
  - lib/widgets/full_moon_overlay.dart:178
  - lib/widgets/new_moon_overlay.dart:198
  - lib/widgets/new_moon_overlay.dart:401
  ```
  decoration: BoxDecoration(
  ```


## 3. TODO/FIXME/HACK/DEBUG 残置

  - lib/screens/galaxy_screen.dart:383 — `// DEBUG: Cycle完了フローの各タイミングを手動トリガー`
  - lib/screens/map_screen.dart:967 — `// TODO: geolocator パッケージ追加後に実装`

## 4. print()/debugPrint() 残置

✅ なし

## 5. 未使用 private member 候補 (file 内 reference == 1)

✅ なし

---

総計: 行数違反 45 / 重複 20 / TODO 2 / print 0 / 未使用候補 0
