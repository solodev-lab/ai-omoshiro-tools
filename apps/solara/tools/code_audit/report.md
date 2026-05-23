# Solara Code Audit

対象: lib (174 個の .dart)

## 1. ファイル行数 (>= 300 行)

| 行数 | 判定 | ファイル |
|------|------|----------|
| 3017 | 🔴 HARD | lib/screens/map_screen.dart |
| 1923 | 🔴 HARD | lib/screens/map/map_daily_transit_screen.dart |
| 1385 | 🔴 HARD | lib/screens/sanctuary/sanctuary_title_diagnosis.dart |
| 1291 | 🔴 HARD | lib/screens/sanctuary_screen.dart |
| 1289 | 🔴 HARD | lib/screens/galaxy_screen.dart |
| 1067 | 🔴 HARD | lib/screens/forecast_screen.dart |
| 1013 | 🔴 HARD | lib/screens/map/daily_transit_data.dart |
| 944 | 🔴 HARD | lib/utils/world_cities.dart |
| 868 | 🔴 HARD | lib/screens/map/map_astro_carto.dart |
| 819 | 🔴 HARD | lib/screens/horoscope_screen.dart |
| 775 | 🔴 HARD | lib/screens/map/map_fortune_sheet.dart |
| 758 | 🔴 HARD | lib/widgets/fortune_overlays/work_painter.dart |
| 746 | 🔴 HARD | lib/widgets/catasterism_formation_overlay.dart |
| 735 | 🔴 HARD | lib/screens/locations_screen.dart |
| 702 | 🔴 HARD | lib/screens/horoscope/horo_chart_painter.dart |
| 693 | 🔴 HARD | lib/widgets/fortune_overlays/money_painter.dart |
| 647 | 🔴 HARD | lib/utils/astro_glossary.dart |
| 646 | 🔴 HARD | lib/screens/map/map_viewpoint_menu.dart |
| 642 | 🔴 HARD | lib/widgets/fortune_overlays/communication_painter.dart |
| 626 | 🔴 HARD | lib/utils/constellation_namer.dart |
| 620 | 🔴 HARD | lib/screens/observe_screen.dart |
| 617 | 🔴 HARD | lib/screens/map/map_relocation_popup.dart |
| 616 | 🔴 HARD | lib/screens/map/map_astro_lines.dart |
| 590 | 🔴 HARD | lib/screens/map/map_search.dart |
| 590 | 🔴 HARD | lib/screens/sanctuary/sanctuary_profile_editor.dart |
| 584 | 🔴 HARD | lib/utils/solara_storage.dart |
| 581 | 🔴 HARD | lib/widgets/fortune_overlays/love_painter.dart |
| 564 | 🔴 HARD | lib/widgets/new_moon_overlay.dart |
| 559 | 🔴 HARD | lib/utils/planet_intro.dart |
| 535 | 🔴 HARD | lib/utils/astro_lines.dart |
| 518 | 🔴 HARD | lib/screens/consultation/consultation_history_screen.dart |
| 508 | 🔴 HARD | lib/screens/map/map_astro.dart |
| 508 | 🔴 HARD | lib/screens/map/map_time_slider.dart |
| 500 | 🔴 HARD | lib/screens/observe/tarot_altar_scene.dart |
| 498 | 🟡 WARN | lib/widgets/fortune_overlays/healing_painter.dart |
| 490 | 🟡 WARN | lib/screens/consultation/consultation_input_screen.dart |
| 484 | 🟡 WARN | lib/screens/consultation/consultation_input_picker.dart |
| 481 | 🟡 WARN | lib/widgets/full_moon_overlay.dart |
| 481 | 🟡 WARN | lib/screens/map/map_overlays.dart |
| 477 | 🟡 WARN | lib/screens/consultation/consultation_result_screen.dart |
| 467 | 🟡 WARN | lib/screens/horoscope/horo_relocation_panel.dart |
| 462 | 🟡 WARN | lib/utils/forecast_cache.dart |
| 461 | 🟡 WARN | lib/screens/consultation/consultation_input_widgets.dart |
| 460 | 🟡 WARN | lib/screens/galaxy/galaxy_star_atlas.dart |
| 456 | 🟡 WARN | lib/utils/app_attest_client.dart |
| 454 | 🟡 WARN | lib/screens/consultation/consultation_input_examples.dart |
| 453 | 🟡 WARN | lib/screens/consultation/consultation_result_widgets.dart |
| 447 | 🟡 WARN | lib/screens/sanctuary/class_share_card.dart |
| 445 | 🟡 WARN | lib/widgets/catasterism_overlay.dart |
| 443 | 🟡 WARN | lib/screens/paywall_widgets.dart |
| 435 | 🟡 WARN | lib/screens/horoscope/horo_birth_panel.dart |
| 423 | 🟡 WARN | lib/screens/observe/observe_history.dart |
| 422 | 🟡 WARN | lib/utils/consultation_engine.dart |
| 417 | 🟡 WARN | lib/utils/solara_auth.dart |
| 413 | 🟡 WARN | lib/screens/map/map_display_menu.dart |
| 411 | 🟡 WARN | lib/screens/consultation/consultation_place_picker_widgets.dart |
| 404 | 🟡 WARN | lib/screens/sanctuary/title_history_screen.dart |
| 397 | 🟡 WARN | lib/screens/observe/observe_history_filter.dart |
| 396 | 🟡 WARN | lib/widgets/cycle_spiral_painter.dart |
| 395 | 🟡 WARN | lib/utils/title_data.dart |
| 391 | 🟡 WARN | lib/screens/locations/locations_date_stepper.dart |
| 387 | 🟡 WARN | lib/screens/galaxy/constellation_share_card_page.dart |
| 374 | 🟡 WARN | lib/screens/map/map_direction_popup.dart |
| 360 | 🟡 WARN | lib/utils/moon_phase.dart |
| 354 | 🟡 WARN | lib/widgets/sanctuary_account_section.dart |
| 353 | 🟡 WARN | lib/screens/consultation/consultation_place_picker_screen.dart |
| 350 | 🟡 WARN | lib/screens/horoscope/horo_fortune_cards.dart |
| 325 | 🟡 WARN | lib/screens/consultation/consultation_credit_sheet.dart |
| 319 | 🟡 WARN | lib/screens/galaxy/galaxy_archive_filter.dart |
| 313 | 🟡 WARN | lib/utils/celestial_events.dart |
| 313 | 🟡 WARN | lib/screens/observe/observe_history_past.dart |
| 307 | 🟡 WARN | lib/screens/horoscope/horo_panel_shared.dart |
| 307 | 🟡 WARN | lib/screens/map/map_menu_chips.dart |
| 306 | 🟡 WARN | lib/widgets/class_card.dart |
| 304 | 🟡 WARN | lib/screens/map/map_location_markers.dart |

## 2. 重複コード (>= 8 行連続一致、上位 20 件)

### 1. 📁 別ファイル間 (14 箇所、14 ファイル)

  - lib/screens/galaxy_screen.dart:549
  - lib/widgets/celestial_event_bar.dart:63
  - lib/widgets/full_moon_overlay.dart:300
  - lib/widgets/new_moon_overlay.dart:313
  - lib/widgets/sanctuary_account_section.dart:248
  ```
  ),
  ```

### 2. 📁 別ファイル間 (13 箇所、12 ファイル)

  - lib/widgets/class_card.dart:287
  - lib/widgets/location_picker_minimap.dart:134
  - lib/screens/consultation/consultation_input_picker.dart:373
  - lib/screens/consultation/consultation_input_picker.dart:408
  - lib/screens/consultation/consultation_result_credit_widgets.dart:181
  ```
  ),
  ```

### 3. 📁 別ファイル間 (9 箇所、9 ファイル)

  - lib/screens/galaxy_screen.dart:548
  - lib/widgets/full_moon_overlay.dart:299
  - lib/widgets/location_picker_minimap.dart:133
  - lib/screens/consultation/consultation_result_credit_widgets.dart:180
  - lib/screens/galaxy/constellation_share_card_page.dart:163
  ```
  ),
  ```

### 4. 📁 別ファイル間 (37 箇所、8 ファイル)

  - lib/screens/forecast_screen.dart:837
  - lib/screens/forecast_screen.dart:855
  - lib/screens/forecast_screen.dart:871
  - lib/screens/forecast_screen.dart:888
  - lib/screens/forecast_screen.dart:904
  ```
  style: TextStyle(
  ```

### 5. 📁 別ファイル間 (11 箇所、8 ファイル)

  - lib/screens/consultation/consultation_result_credit_widgets.dart:117
  - lib/screens/consultation/consultation_result_widgets.dart:81
  - lib/screens/consultation/consultation_result_widgets.dart:114
  - lib/screens/galaxy/galaxy_star_atlas.dart:410
  - lib/screens/map/map_daily_transit_screen.dart:255
  ```
  ),
  ```

### 6. 📁 別ファイル間 (8 箇所、8 ファイル)

  - lib/screens/consultation/consultation_history_screen.dart:243
  - lib/screens/consultation/consultation_input_screen.dart:483
  - lib/screens/consultation/consultation_place_picker_screen.dart:346
  - lib/screens/consultation/consultation_result_credit_widgets.dart:115
  - lib/screens/consultation/consultation_result_widgets.dart:79
  ```
  ),
  ```

### 7. 📁 別ファイル間 (13 箇所、7 ファイル)

  - lib/widgets/catasterism_overlay.dart:191
  - lib/widgets/full_moon_overlay.dart:200
  - lib/widgets/full_moon_overlay.dart:403
  - lib/widgets/full_moon_overlay.dart:458
  - lib/widgets/new_moon_overlay.dart:220
  ```
  ),
  ```

### 8. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/screens/galaxy_screen.dart:550
  - lib/widgets/full_moon_overlay.dart:301
  - lib/widgets/new_moon_overlay.dart:314
  - lib/screens/galaxy/constellation_share_card_page.dart:165
  - lib/screens/map/map_line_narrative_sheet.dart:139
  ```
  ),
  ```

### 9. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/screens/sanctuary_screen.dart:1283
  - lib/widgets/catasterism_overlay.dart:189
  - lib/widgets/full_moon_overlay.dart:198
  - lib/widgets/info_popup.dart:105
  - lib/widgets/new_moon_overlay.dart:218
  ```
  ),
  ```

### 10. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/widgets/new_moon_overlay.dart:312
  - lib/screens/consultation/consultation_input_picker.dart:372
  - lib/screens/galaxy/constellation_share_card_page.dart:349
  - lib/screens/galaxy/galaxy_cycle_actions_sheet.dart:264
  - lib/screens/horoscope/horo_relocation_pro_teaser.dart:88
  ```
  ],
  ```

### 11. 📁 別ファイル間 (10 箇所、6 ファイル)

  - lib/screens/consultation/consultation_input_widgets.dart:415
  - lib/screens/consultation/consultation_result_widgets.dart:35
  - lib/screens/map/consult_entry_popup.dart:231
  - lib/screens/map/map_astro_carto.dart:84
  - lib/screens/map/map_astro_carto.dart:459
  ```
  ),
  ```

### 12. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/screens/sanctuary_screen.dart:1284
  - lib/widgets/info_popup.dart:106
  - lib/screens/consultation/consultation_input_widgets.dart:414
  - lib/screens/map/consult_entry_popup.dart:230
  - lib/screens/map/map_astro_carto.dart:458
  ```
  ),
  ```

### 13. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/widgets/catasterism_formation_overlay.dart:442
  - lib/widgets/catasterism_overlay.dart:187
  - lib/widgets/full_moon_overlay.dart:196
  - lib/widgets/new_moon_overlay.dart:216
  - lib/widgets/new_moon_overlay.dart:419
  ```
  ),
  ```

### 14. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/widgets/class_card.dart:288
  - lib/screens/consultation/consultation_input_picker.dart:374
  - lib/screens/consultation/consultation_input_picker.dart:409
  - lib/screens/galaxy/constellation_share_card_page.dart:351
  - lib/screens/map/map_daily_transit_screen.dart:315
  ```
  ),
  ```

### 15. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/screens/paywall_widgets.dart:367
  - lib/widgets/catasterism_overlay.dart:190
  - lib/widgets/full_moon_overlay.dart:199
  - lib/widgets/new_moon_overlay.dart:219
  - lib/screens/map/map_viewpoint_menu.dart:344
  ```
  ),
  ```

### 16. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/widgets/catasterism_formation_overlay.dart:443
  - lib/widgets/location_picker_minimap.dart:131
  - lib/widgets/new_moon_overlay.dart:420
  - lib/screens/galaxy/constellation_share_card_page.dart:161
  - lib/screens/sanctuary/class_share_card.dart:211
  ```
  ),
  ```

### 17. 📁 別ファイル間 (8 箇所、5 ファイル)

  - lib/screens/consultation/consultation_result_widgets.dart:164
  - lib/screens/galaxy/galaxy_star_atlas.dart:155
  - lib/screens/galaxy/galaxy_star_atlas.dart:189
  - lib/screens/galaxy/galaxy_star_atlas.dart:355
  - lib/screens/map/map_astro_lines.dart:506
  ```
  ),
  ```

### 18. 📁 別ファイル間 (6 箇所、5 ファイル)

  - lib/screens/consultation/consultation_history_screen.dart:244
  - lib/screens/consultation/consultation_result_credit_widgets.dart:116
  - lib/screens/consultation/consultation_result_widgets.dart:80
  - lib/screens/consultation/consultation_result_widgets.dart:346
  - lib/screens/galaxy/galaxy_cycle_actions_sheet.dart:186
  ```
  ],
  ```

### 19. 📁 別ファイル間 (6 箇所、5 ファイル)

  - lib/screens/consultation/consultation_input_picker.dart:290
  - lib/screens/galaxy/galaxy_archive_filter_chips.dart:58
  - lib/screens/galaxy/galaxy_star_atlas.dart:154
  - lib/screens/galaxy/galaxy_star_atlas.dart:354
  - lib/screens/map/map_astro_lines.dart:505
  ```
  ),
  ```

### 20. 📁 別ファイル間 (5 箇所、5 ファイル)

  - lib/screens/forecast_screen.dart:927
  - lib/screens/map/map_astro_carto.dart:229
  - lib/screens/map/map_daily_transit_screen.dart:1916
  - lib/screens/map/map_fortune_sheet.dart:732
  - lib/screens/map/map_viewpoint_menu.dart:128
  ```
  style: TextStyle(
  ```


## 3. TODO/FIXME/HACK/DEBUG 残置

  - lib/main.dart:35 — `// debug/Web/desktop/設定値不足ではいずれも no-op (Free 動作は不変)。`
  - lib/screens/galaxy_screen.dart:449 — `// DEBUG: Cycle完了フローの各タイミングを手動トリガー`
  - lib/utils/device_security_status.dart:115 — `// debug build では `Threat.debug` で常時発火 + signing cert が release と`
  - lib/screens/galaxy/galaxy_archive_filter.dart:81 — `// debug で過去サイクルを後から作ったり、同月内に複数 cycle を並べると`

## 4. print()/debugPrint() 残置

  - lib/utils/solara_auth.dart:320 — `debugPrint(`
  - lib/utils/solara_auth.dart:324 — `if (kDebugMode) debugPrint('[SolaraAuth] server purge failed: $e');`

## 5. 未使用 private member 候補 (file 内 reference == 1)

✅ なし

---

総計: 行数違反 75 / 重複 20 / TODO 4 / print 2 / 未使用候補 0
