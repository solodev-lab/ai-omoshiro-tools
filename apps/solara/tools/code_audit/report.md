# Solara Code Audit

対象: lib (191 個の .dart)

## 1. ファイル行数 (NOTICE >= 300 / WARN >= 500 / HARD >= 1000)

| 行数 | 判定 | ファイル |
|------|------|----------|
| 3214 | 🔴 HARD | lib/screens/map_screen.dart |
| 2029 | 🔴 HARD | lib/screens/map/map_daily_transit_screen.dart |
| 1473 | 🔴 HARD | lib/screens/sanctuary_screen.dart |
| 1385 | 🔴 HARD | lib/screens/sanctuary/sanctuary_title_diagnosis.dart |
| 1278 | 🔴 HARD | lib/screens/galaxy_screen.dart |
| 1084 | 🔴 HARD | lib/screens/forecast_screen.dart |
| 1013 | 🔴 HARD | lib/screens/map/daily_transit_data.dart |
| 943 | 🟠 WARN | lib/screens/horoscope_screen.dart |
| 872 | 🟠 WARN | lib/screens/map/map_astro_carto.dart |
| 798 | 🟠 WARN | lib/screens/map/map_fortune_sheet.dart |
| 780 | 🟠 WARN | lib/utils/solara_storage.dart |
| 764 | 🟠 WARN | lib/widgets/catasterism_formation_overlay.dart |
| 759 | 🟠 WARN | lib/screens/locations_screen.dart |
| 758 | 🟠 WARN | lib/widgets/fortune_overlays/work_painter.dart |
| 704 | 🟠 WARN | lib/screens/observe_screen.dart |
| 702 | 🟠 WARN | lib/screens/horoscope/horo_chart_painter.dart |
| 693 | 🟠 WARN | lib/widgets/fortune_overlays/money_painter.dart |
| 658 | 🟠 WARN | lib/screens/map/map_search.dart |
| 656 | 🟠 WARN | lib/screens/map/map_relocation_popup.dart |
| 647 | 🟠 WARN | lib/utils/astro_glossary.dart |
| 646 | 🟠 WARN | lib/screens/map/map_viewpoint_menu.dart |
| 642 | 🟠 WARN | lib/widgets/fortune_overlays/communication_painter.dart |
| 626 | 🟠 WARN | lib/utils/constellation_namer.dart |
| 624 | 🟠 WARN | lib/screens/map/map_astro_lines.dart |
| 592 | 🟠 WARN | lib/screens/sanctuary/sanctuary_profile_editor.dart |
| 581 | 🟠 WARN | lib/widgets/fortune_overlays/love_painter.dart |
| 564 | 🟠 WARN | lib/widgets/new_moon_overlay.dart |
| 559 | 🟠 WARN | lib/utils/planet_intro.dart |
| 535 | 🟠 WARN | lib/utils/astro_lines.dart |
| 511 | 🟠 WARN | lib/screens/map/map_astro.dart |
| 508 | 🟠 WARN | lib/screens/map/map_time_slider.dart |
| 500 | 🟠 WARN | lib/screens/observe/tarot_altar_scene.dart |
| 498 | 🟡 NOTICE | lib/widgets/fortune_overlays/healing_painter.dart |
| 488 | 🟡 NOTICE | lib/screens/consultation/consultation_history_widgets.dart |
| 485 | 🟡 NOTICE | lib/screens/consultation/consultation_input_screen.dart |
| 481 | 🟡 NOTICE | lib/widgets/full_moon_overlay.dart |
| 481 | 🟡 NOTICE | lib/screens/map/map_overlays.dart |
| 476 | 🟡 NOTICE | lib/utils/app_attest_client.dart |
| 472 | 🟡 NOTICE | lib/screens/consultation/consultation_result_screen.dart |
| 467 | 🟡 NOTICE | lib/screens/horoscope/horo_relocation_panel.dart |
| 460 | 🟡 NOTICE | lib/screens/galaxy/galaxy_star_atlas.dart |
| 459 | 🟡 NOTICE | lib/utils/solara_auth.dart |
| 447 | 🟡 NOTICE | lib/screens/sanctuary/class_share_card.dart |
| 445 | 🟡 NOTICE | lib/widgets/catasterism_overlay.dart |
| 431 | 🟡 NOTICE | lib/utils/consultation_v2_api.dart |
| 430 | 🟡 NOTICE | lib/screens/consultation/consultation_input_widgets.dart |
| 427 | 🟡 NOTICE | lib/screens/consultation/consultation_result_widgets.dart |
| 423 | 🟡 NOTICE | lib/screens/observe/observe_history.dart |
| 415 | 🟡 NOTICE | lib/screens/galaxy/constellation_share_card_page.dart |
| 413 | 🟡 NOTICE | lib/screens/paywall_widgets.dart |
| 413 | 🟡 NOTICE | lib/utils/forecast_cache.dart |
| 413 | 🟡 NOTICE | lib/screens/map/map_display_menu.dart |
| 411 | 🟡 NOTICE | lib/screens/consultation/consultation_place_picker_widgets.dart |
| 404 | 🟡 NOTICE | lib/screens/sanctuary/title_history_screen.dart |
| 397 | 🟡 NOTICE | lib/screens/observe/observe_history_filter.dart |
| 396 | 🟡 NOTICE | lib/widgets/cycle_spiral_painter.dart |
| 395 | 🟡 NOTICE | lib/utils/title_data.dart |
| 374 | 🟡 NOTICE | lib/screens/map/map_direction_popup.dart |
| 360 | 🟡 NOTICE | lib/utils/moon_phase.dart |
| 355 | 🟡 NOTICE | lib/widgets/sanctuary_account_section.dart |
| 355 | 🟡 NOTICE | lib/screens/locations/locations_date_stepper.dart |
| 354 | 🟡 NOTICE | lib/screens/consultation/consultation_place_picker_screen.dart |
| 353 | 🟡 NOTICE | lib/screens/ai_consent_screen.dart |
| 348 | 🟡 NOTICE | lib/screens/consultation/consultation_credit_sheet.dart |
| 345 | 🟡 NOTICE | lib/screens/consultation/consultation_input_picker.dart |
| 343 | 🟡 NOTICE | lib/screens/horoscope/horo_fortune_cards.dart |
| 338 | 🟡 NOTICE | lib/screens/map/consult_entry_popup.dart |
| 336 | 🟡 NOTICE | lib/screens/horoscope/horo_birth_panel.dart |
| 319 | 🟡 NOTICE | lib/screens/galaxy/galaxy_archive_filter.dart |
| 313 | 🟡 NOTICE | lib/screens/paywall_screen.dart |
| 313 | 🟡 NOTICE | lib/utils/celestial_events.dart |
| 313 | 🟡 NOTICE | lib/screens/observe/observe_history_past.dart |
| 309 | 🟡 NOTICE | lib/utils/fortune_api.dart |
| 309 | 🟡 NOTICE | lib/screens/horoscope/horo_panel_shared.dart |
| 308 | 🟡 NOTICE | lib/utils/purchases_service.dart |
| 307 | 🟡 NOTICE | lib/widgets/ai_report_button.dart |
| 306 | 🟡 NOTICE | lib/widgets/class_card.dart |
| 304 | 🟡 NOTICE | lib/screens/map/map_location_markers.dart |

## 2. 重複コード (>= 8 行連続一致、上位 20 件)

### 1. 📁 別ファイル間 (16 箇所、14 ファイル)

  - lib/screens/paywall_comparison.dart:260
  - lib/widgets/ai_report_button.dart:300
  - lib/widgets/class_card.dart:287
  - lib/widgets/location_picker_minimap.dart:135
  - lib/screens/consultation/consultation_input_picker_widgets.dart:85
  ```
  ),
  ```

### 2. 📁 別ファイル間 (14 箇所、14 ファイル)

  - lib/screens/galaxy_screen.dart:555
  - lib/widgets/celestial_event_bar.dart:63
  - lib/widgets/full_moon_overlay.dart:300
  - lib/widgets/new_moon_overlay.dart:313
  - lib/widgets/sanctuary_account_section.dart:248
  ```
  ),
  ```

### 3. 📁 別ファイル間 (14 箇所、11 ファイル)

  - lib/screens/consultation/consultation_history_widgets.dart:49
  - lib/screens/consultation/consultation_input_widgets.dart:112
  - lib/screens/consultation/consultation_result_card.dart:142
  - lib/screens/consultation/consultation_result_credit_widgets.dart:145
  - lib/screens/consultation/consultation_result_widgets.dart:77
  ```
  ),
  ```

### 4. 📁 別ファイル間 (10 箇所、10 ファイル)

  - lib/screens/galaxy_screen.dart:554
  - lib/screens/paywall_comparison.dart:259
  - lib/widgets/full_moon_overlay.dart:299
  - lib/widgets/location_picker_minimap.dart:134
  - lib/screens/consultation/consultation_result_widgets.dart:294
  ```
  ),
  ```

### 5. 📁 別ファイル間 (37 箇所、8 ファイル)

  - lib/screens/forecast_screen.dart:854
  - lib/screens/forecast_screen.dart:872
  - lib/screens/forecast_screen.dart:888
  - lib/screens/forecast_screen.dart:905
  - lib/screens/forecast_screen.dart:921
  ```
  style: TextStyle(
  ```

### 6. 📁 別ファイル間 (13 箇所、8 ファイル)

  - lib/screens/paywall_widgets.dart:403
  - lib/widgets/catasterism_overlay.dart:191
  - lib/widgets/full_moon_overlay.dart:200
  - lib/widgets/full_moon_overlay.dart:403
  - lib/widgets/full_moon_overlay.dart:458
  ```
  ),
  ```

### 7. 📁 別ファイル間 (9 箇所、8 ファイル)

  - lib/screens/paywall_comparison.dart:94
  - lib/screens/paywall_comparison.dart:169
  - lib/screens/paywall_legal_links.dart:83
  - lib/screens/paywall_widgets.dart:402
  - lib/widgets/catasterism_overlay.dart:190
  ```
  ),
  ```

### 8. 📁 別ファイル間 (8 箇所、8 ファイル)

  - lib/widgets/ai_report_button.dart:239
  - lib/screens/consultation/consultation_history_widgets.dart:47
  - lib/screens/consultation/consultation_place_picker_screen.dart:347
  - lib/screens/consultation/consultation_result_credit_widgets.dart:143
  - lib/screens/consultation/consultation_result_widgets.dart:75
  ```
  ),
  ```

### 9. 📁 別ファイル間 (8 箇所、8 ファイル)

  - lib/widgets/ai_report_button.dart:299
  - lib/widgets/new_moon_overlay.dart:312
  - lib/screens/consultation/consultation_input_picker_widgets.dart:84
  - lib/screens/galaxy/constellation_share_card_page.dart:377
  - lib/screens/galaxy/galaxy_cycle_actions_sheet.dart:264
  ```
  ],
  ```

### 10. 📁 別ファイル間 (11 箇所、7 ファイル)

  - lib/screens/ai_consent_screen.dart:250
  - lib/screens/consultation/consultation_input_widgets.dart:384
  - lib/screens/consultation/consultation_result_widgets.dart:31
  - lib/screens/map/consult_entry_popup.dart:277
  - lib/screens/map/map_astro_carto.dart:88
  ```
  ),
  ```

### 11. 📁 別ファイル間 (9 箇所、7 ファイル)

  - lib/widgets/class_card.dart:288
  - lib/screens/consultation/consultation_input_picker_widgets.dart:86
  - lib/screens/consultation/consultation_input_picker_widgets.dart:127
  - lib/screens/consultation/consultation_result_widgets.dart:296
  - lib/screens/consultation/consultation_result_widgets.dart:381
  ```
  ),
  ```

### 12. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/screens/galaxy_screen.dart:556
  - lib/widgets/full_moon_overlay.dart:301
  - lib/widgets/new_moon_overlay.dart:314
  - lib/screens/galaxy/constellation_share_card_page.dart:170
  - lib/screens/map/map_line_narrative_sheet.dart:139
  ```
  ),
  ```

### 13. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/widgets/ai_report_button.dart:240
  - lib/screens/consultation/consultation_history_widgets.dart:48
  - lib/screens/consultation/consultation_result_card.dart:141
  - lib/screens/consultation/consultation_result_credit_widgets.dart:144
  - lib/screens/consultation/consultation_result_widgets.dart:76
  ```
  ],
  ```

### 14. 📁 別ファイル間 (9 箇所、6 ファイル)

  - lib/screens/consultation/consultation_input_picker.dart:337
  - lib/screens/consultation/consultation_result_card.dart:219
  - lib/screens/galaxy/galaxy_star_atlas.dart:155
  - lib/screens/galaxy/galaxy_star_atlas.dart:189
  - lib/screens/galaxy/galaxy_star_atlas.dart:355
  ```
  ),
  ```

### 15. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/screens/ai_consent_screen.dart:249
  - lib/widgets/info_popup.dart:106
  - lib/screens/consultation/consultation_input_widgets.dart:383
  - lib/screens/map/consult_entry_popup.dart:276
  - lib/screens/map/map_astro_carto.dart:462
  ```
  ),
  ```

### 16. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/widgets/catasterism_formation_overlay.dart:460
  - lib/widgets/catasterism_overlay.dart:187
  - lib/widgets/full_moon_overlay.dart:196
  - lib/widgets/new_moon_overlay.dart:216
  - lib/widgets/new_moon_overlay.dart:419
  ```
  ),
  ```

### 17. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/screens/consultation/consultation_input_picker.dart:336
  - lib/screens/consultation/consultation_result_card.dart:218
  - lib/screens/galaxy/galaxy_archive_filter_chips.dart:58
  - lib/screens/galaxy/galaxy_star_atlas.dart:154
  - lib/screens/galaxy/galaxy_star_atlas.dart:354
  ```
  ),
  ```

### 18. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/widgets/catasterism_formation_overlay.dart:461
  - lib/widgets/location_picker_minimap.dart:132
  - lib/widgets/new_moon_overlay.dart:420
  - lib/screens/galaxy/constellation_share_card_page.dart:166
  - lib/screens/sanctuary/class_share_card.dart:211
  ```
  ),
  ```

### 19. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/widgets/catasterism_overlay.dart:189
  - lib/widgets/full_moon_overlay.dart:198
  - lib/widgets/info_popup.dart:105
  - lib/widgets/new_moon_overlay.dart:218
  - lib/screens/consultation/consultation_result_card.dart:273
  ```
  ),
  ```

### 20. 📁 別ファイル間 (9 箇所、5 ファイル)

  - lib/widgets/class_card.dart:289
  - lib/screens/consultation/consultation_input_picker_widgets.dart:87
  - lib/screens/consultation/consultation_input_picker_widgets.dart:128
  - lib/screens/consultation/consultation_result_widgets.dart:297
  - lib/screens/consultation/consultation_result_widgets.dart:382
  ```
  ],
  ```


## 3. TODO/FIXME/HACK/DEBUG 残置

  - lib/main.dart:38 — `// debug/Web/desktop/設定値不足ではいずれも no-op (Free 動作は不変)。`
  - lib/screens/galaxy_screen.dart:453 — `// DEBUG: Cycle完了フローの各タイミングを手動トリガー`
  - lib/utils/device_security_status.dart:115 — `// debug build では `Threat.debug` で常時発火 + signing cert が release と`
  - lib/screens/galaxy/galaxy_archive_filter.dart:81 — `// debug で過去サイクルを後から作ったり、同月内に複数 cycle を並べると`

## 4. print()/debugPrint() 残置

  - lib/utils/solara_auth.dart:366 — `if (kDebugMode) debugPrint('[SolaraAuth] server purge failed: $e');`

## 5. 未使用 private member 候補 (file 内 reference == 1)

✅ なし

---

総計: 行数 HARD 7 / WARN 25 / NOTICE 46 / 重複 20 / TODO 4 / print 1 / 未使用候補 0
