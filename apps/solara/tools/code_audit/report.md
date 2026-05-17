# Solara Code Audit

対象: lib (163 個の .dart)

## 1. ファイル行数 (>= 300 行)

| 行数 | 判定 | ファイル |
|------|------|----------|
| 3020 | 🔴 HARD | lib/screens/map_screen.dart |
| 1923 | 🔴 HARD | lib/screens/map/map_daily_transit_screen.dart |
| 1385 | 🔴 HARD | lib/screens/sanctuary/sanctuary_title_diagnosis.dart |
| 1288 | 🔴 HARD | lib/screens/sanctuary_screen.dart |
| 1238 | 🔴 HARD | lib/screens/galaxy_screen.dart |
| 1067 | 🔴 HARD | lib/screens/forecast_screen.dart |
| 1013 | 🔴 HARD | lib/screens/map/daily_transit_data.dart |
| 944 | 🔴 HARD | lib/utils/world_cities.dart |
| 868 | 🔴 HARD | lib/screens/map/map_astro_carto.dart |
| 814 | 🔴 HARD | lib/screens/horoscope_screen.dart |
| 775 | 🔴 HARD | lib/screens/map/map_fortune_sheet.dart |
| 758 | 🔴 HARD | lib/widgets/fortune_overlays/work_painter.dart |
| 737 | 🔴 HARD | lib/screens/locations_screen.dart |
| 702 | 🔴 HARD | lib/screens/horoscope/horo_chart_painter.dart |
| 693 | 🔴 HARD | lib/widgets/fortune_overlays/money_painter.dart |
| 647 | 🔴 HARD | lib/utils/astro_glossary.dart |
| 646 | 🔴 HARD | lib/screens/map/map_viewpoint_menu.dart |
| 642 | 🔴 HARD | lib/widgets/fortune_overlays/communication_painter.dart |
| 631 | 🔴 HARD | lib/widgets/catasterism_formation_overlay.dart |
| 626 | 🔴 HARD | lib/utils/constellation_namer.dart |
| 617 | 🔴 HARD | lib/screens/map/map_relocation_popup.dart |
| 616 | 🔴 HARD | lib/screens/map/map_astro_lines.dart |
| 590 | 🔴 HARD | lib/screens/map/map_search.dart |
| 585 | 🔴 HARD | lib/screens/sanctuary/sanctuary_profile_editor.dart |
| 581 | 🔴 HARD | lib/widgets/fortune_overlays/love_painter.dart |
| 564 | 🔴 HARD | lib/widgets/new_moon_overlay.dart |
| 560 | 🔴 HARD | lib/screens/observe_screen.dart |
| 559 | 🔴 HARD | lib/utils/planet_intro.dart |
| 541 | 🔴 HARD | lib/utils/solara_storage.dart |
| 535 | 🔴 HARD | lib/utils/astro_lines.dart |
| 518 | 🔴 HARD | lib/screens/consultation/consultation_history_screen.dart |
| 508 | 🔴 HARD | lib/screens/map/map_astro.dart |
| 508 | 🔴 HARD | lib/screens/map/map_time_slider.dart |
| 500 | 🔴 HARD | lib/screens/observe/tarot_altar_scene.dart |
| 498 | 🟡 WARN | lib/widgets/fortune_overlays/healing_painter.dart |
| 484 | 🟡 WARN | lib/screens/consultation/consultation_input_picker.dart |
| 481 | 🟡 WARN | lib/widgets/full_moon_overlay.dart |
| 481 | 🟡 WARN | lib/screens/map/map_overlays.dart |
| 472 | 🟡 WARN | lib/screens/consultation/consultation_result_screen.dart |
| 467 | 🟡 WARN | lib/screens/horoscope/horo_relocation_panel.dart |
| 462 | 🟡 WARN | lib/utils/forecast_cache.dart |
| 461 | 🟡 WARN | lib/screens/consultation/consultation_input_widgets.dart |
| 460 | 🟡 WARN | lib/screens/galaxy/galaxy_star_atlas.dart |
| 451 | 🟡 WARN | lib/screens/consultation/consultation_input_examples.dart |
| 447 | 🟡 WARN | lib/screens/sanctuary/class_share_card.dart |
| 446 | 🟡 WARN | lib/screens/consultation/consultation_result_widgets.dart |
| 445 | 🟡 WARN | lib/widgets/catasterism_overlay.dart |
| 443 | 🟡 WARN | lib/screens/paywall_widgets.dart |
| 435 | 🟡 WARN | lib/screens/horoscope/horo_birth_panel.dart |
| 422 | 🟡 WARN | lib/utils/consultation_engine.dart |
| 413 | 🟡 WARN | lib/screens/map/map_display_menu.dart |
| 411 | 🟡 WARN | lib/screens/consultation/consultation_place_picker_widgets.dart |
| 397 | 🟡 WARN | lib/screens/observe/observe_history_filter.dart |
| 396 | 🟡 WARN | lib/widgets/cycle_spiral_painter.dart |
| 396 | 🟡 WARN | lib/screens/consultation/consultation_input_screen.dart |
| 395 | 🟡 WARN | lib/utils/title_data.dart |
| 391 | 🟡 WARN | lib/screens/locations/locations_date_stepper.dart |
| 387 | 🟡 WARN | lib/screens/galaxy/constellation_share_card_page.dart |
| 385 | 🟡 WARN | lib/screens/sanctuary/title_history_screen.dart |
| 383 | 🟡 WARN | lib/screens/observe/observe_history.dart |
| 374 | 🟡 WARN | lib/screens/map/map_direction_popup.dart |
| 360 | 🟡 WARN | lib/utils/moon_phase.dart |
| 357 | 🟡 WARN | lib/utils/solara_auth.dart |
| 350 | 🟡 WARN | lib/screens/horoscope/horo_fortune_cards.dart |
| 348 | 🟡 WARN | lib/screens/consultation/consultation_place_picker_screen.dart |
| 313 | 🟡 WARN | lib/utils/celestial_events.dart |
| 312 | 🟡 WARN | lib/screens/galaxy/galaxy_archive_filter.dart |
| 307 | 🟡 WARN | lib/screens/horoscope/horo_panel_shared.dart |
| 307 | 🟡 WARN | lib/screens/map/map_menu_chips.dart |
| 306 | 🟡 WARN | lib/widgets/class_card.dart |
| 304 | 🟡 WARN | lib/screens/map/map_location_markers.dart |

## 2. 重複コード (>= 8 行連続一致、上位 20 件)

### 1. 📁 別ファイル間 (14 箇所、14 ファイル)

  - lib/screens/galaxy_screen.dart:511
  - lib/widgets/celestial_event_bar.dart:63
  - lib/widgets/full_moon_overlay.dart:300
  - lib/widgets/new_moon_overlay.dart:313
  - lib/widgets/sanctuary_account_section.dart:206
  ```
  ),
  ```

### 2. 📁 別ファイル間 (13 箇所、12 ファイル)

  - lib/widgets/class_card.dart:287
  - lib/widgets/location_picker_minimap.dart:134
  - lib/screens/consultation/consultation_input_picker.dart:373
  - lib/screens/consultation/consultation_input_picker.dart:408
  - lib/screens/consultation/consultation_place_picker_screen.dart:341
  ```
  ),
  ```

### 3. 📁 別ファイル間 (37 箇所、8 ファイル)

  - lib/screens/forecast_screen.dart:837
  - lib/screens/forecast_screen.dart:855
  - lib/screens/forecast_screen.dart:871
  - lib/screens/forecast_screen.dart:888
  - lib/screens/forecast_screen.dart:904
  ```
  style: TextStyle(
  ```

### 4. 📁 別ファイル間 (8 箇所、8 ファイル)

  - lib/screens/galaxy_screen.dart:510
  - lib/widgets/full_moon_overlay.dart:299
  - lib/widgets/location_picker_minimap.dart:133
  - lib/screens/galaxy/constellation_share_card_page.dart:163
  - lib/screens/sanctuary/class_share_card.dart:213
  ```
  ),
  ```

### 5. 📁 別ファイル間 (13 箇所、7 ファイル)

  - lib/widgets/catasterism_overlay.dart:191
  - lib/widgets/full_moon_overlay.dart:200
  - lib/widgets/full_moon_overlay.dart:403
  - lib/widgets/full_moon_overlay.dart:458
  - lib/widgets/new_moon_overlay.dart:220
  ```
  ),
  ```

### 6. 📁 別ファイル間 (9 箇所、7 ファイル)

  - lib/screens/consultation/consultation_result_widgets.dart:81
  - lib/screens/galaxy/galaxy_star_atlas.dart:410
  - lib/screens/map/map_daily_transit_screen.dart:255
  - lib/screens/map/map_location_markers.dart:59
  - lib/screens/map/map_location_markers.dart:114
  ```
  ),
  ```

### 7. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/screens/galaxy_screen.dart:512
  - lib/widgets/full_moon_overlay.dart:301
  - lib/widgets/new_moon_overlay.dart:314
  - lib/screens/galaxy/constellation_share_card_page.dart:165
  - lib/screens/map/map_line_narrative_sheet.dart:139
  ```
  ),
  ```

### 8. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/screens/sanctuary_screen.dart:1280
  - lib/widgets/catasterism_overlay.dart:189
  - lib/widgets/full_moon_overlay.dart:198
  - lib/widgets/info_popup.dart:105
  - lib/widgets/new_moon_overlay.dart:218
  ```
  ),
  ```

### 9. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/widgets/new_moon_overlay.dart:312
  - lib/screens/consultation/consultation_input_picker.dart:372
  - lib/screens/galaxy/constellation_share_card_page.dart:349
  - lib/screens/galaxy/galaxy_cycle_actions_sheet.dart:264
  - lib/screens/horoscope/horo_relocation_pro_teaser.dart:88
  ```
  ],
  ```

### 10. 📁 別ファイル間 (11 箇所、6 ファイル)

  - lib/screens/consultation/consultation_input_widgets.dart:415
  - lib/screens/consultation/consultation_result_widgets.dart:35
  - lib/screens/consultation/consultation_result_widgets.dart:128
  - lib/screens/map/consult_entry_popup.dart:231
  - lib/screens/map/map_astro_carto.dart:84
  ```
  ),
  ```

### 11. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/screens/sanctuary_screen.dart:1281
  - lib/widgets/info_popup.dart:106
  - lib/screens/consultation/consultation_input_widgets.dart:414
  - lib/screens/map/consult_entry_popup.dart:230
  - lib/screens/map/map_astro_carto.dart:458
  ```
  ),
  ```

### 12. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/widgets/catasterism_formation_overlay.dart:333
  - lib/widgets/catasterism_overlay.dart:187
  - lib/widgets/full_moon_overlay.dart:196
  - lib/widgets/new_moon_overlay.dart:216
  - lib/widgets/new_moon_overlay.dart:419
  ```
  ),
  ```

### 13. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/widgets/class_card.dart:288
  - lib/screens/consultation/consultation_input_picker.dart:374
  - lib/screens/consultation/consultation_input_picker.dart:409
  - lib/screens/galaxy/constellation_share_card_page.dart:351
  - lib/screens/map/map_daily_transit_screen.dart:315
  ```
  ),
  ```

### 14. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/screens/paywall_widgets.dart:367
  - lib/widgets/catasterism_overlay.dart:190
  - lib/widgets/full_moon_overlay.dart:199
  - lib/widgets/new_moon_overlay.dart:219
  - lib/screens/map/map_viewpoint_menu.dart:344
  ```
  ),
  ```

### 15. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/widgets/catasterism_formation_overlay.dart:334
  - lib/widgets/location_picker_minimap.dart:131
  - lib/widgets/new_moon_overlay.dart:420
  - lib/screens/galaxy/constellation_share_card_page.dart:161
  - lib/screens/sanctuary/class_share_card.dart:211
  ```
  ),
  ```

### 16. 📁 別ファイル間 (6 箇所、5 ファイル)

  - lib/screens/consultation/consultation_input_picker.dart:290
  - lib/screens/galaxy/galaxy_archive_filter_chips.dart:58
  - lib/screens/galaxy/galaxy_star_atlas.dart:154
  - lib/screens/galaxy/galaxy_star_atlas.dart:354
  - lib/screens/map/map_astro_lines.dart:505
  ```
  ),
  ```

### 17. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/screens/forecast_screen.dart:927
  - lib/screens/map/map_astro_carto.dart:229
  - lib/screens/map/map_daily_transit_screen.dart:1916
  - lib/screens/map/map_fortune_sheet.dart:732
  - lib/screens/map/map_viewpoint_menu.dart:128
  ```
  style: TextStyle(
  ```

### 18. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:151
  - lib/widgets/fortune_overlays/healing_painter.dart:101
  - lib/widgets/fortune_overlays/love_painter.dart:89
  - lib/widgets/fortune_overlays/money_painter.dart:144
  - lib/widgets/fortune_overlays/work_painter.dart:130
  ```
  ));
  ```

### 19. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/widgets/fortune_overlays/communication_painter.dart:152
  - lib/widgets/fortune_overlays/healing_painter.dart:102
  - lib/widgets/fortune_overlays/love_painter.dart:90
  - lib/widgets/fortune_overlays/money_painter.dart:145
  - lib/widgets/fortune_overlays/work_painter.dart:131
  ```
  }
  ```

### 20. 📁 別ファイル間 (7 箇所、4 ファイル)

  - lib/screens/galaxy/galaxy_star_atlas.dart:155
  - lib/screens/galaxy/galaxy_star_atlas.dart:189
  - lib/screens/galaxy/galaxy_star_atlas.dart:355
  - lib/screens/map/map_astro_lines.dart:506
  - lib/screens/map/map_daily_transit_screen.dart:887
  ```
  ),
  ```


## 3. TODO/FIXME/HACK/DEBUG 残置

  - lib/main.dart:34 — `// debug/Web/desktop/設定値不足ではいずれも no-op (Free 動作は不変)。`
  - lib/screens/galaxy_screen.dart:421 — `// DEBUG: Cycle完了フローの各タイミングを手動トリガー`
  - lib/utils/device_security_status.dart:115 — `// debug build では `Threat.debug` で常時発火 + signing cert が release と`

## 4. print()/debugPrint() 残置

✅ なし

## 5. 未使用 private member 候補 (file 内 reference == 1)

✅ なし

---

総計: 行数違反 71 / 重複 20 / TODO 3 / print 0 / 未使用候補 0
