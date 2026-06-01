# Solara Code Audit

対象: lib (196 個の .dart)

## 1. ファイル行数 (NOTICE >= 300 / WARN >= 500 / HARD >= 1000)

| 行数 | 判定 | ファイル |
|------|------|----------|
| 3515 | 🔴 HARD | lib/screens/map_screen.dart |
| 2029 | 🔴 HARD | lib/screens/map/map_daily_transit_screen.dart |
| 1628 | 🔴 HARD | lib/screens/sanctuary_screen.dart |
| 1374 | 🔴 HARD | lib/screens/sanctuary/sanctuary_title_diagnosis.dart |
| 1334 | 🔴 HARD | lib/screens/galaxy_screen.dart |
| 1084 | 🔴 HARD | lib/screens/forecast_screen.dart |
| 1013 | 🔴 HARD | lib/screens/map/daily_transit_data.dart |
| 943 | 🟠 WARN | lib/screens/horoscope_screen.dart |
| 873 | 🟠 WARN | lib/utils/solara_storage.dart |
| 872 | 🟠 WARN | lib/screens/map/map_astro_carto.dart |
| 798 | 🟠 WARN | lib/screens/map/map_fortune_sheet.dart |
| 775 | 🟠 WARN | lib/widgets/catasterism_formation_overlay.dart |
| 759 | 🟠 WARN | lib/screens/locations_screen.dart |
| 758 | 🟠 WARN | lib/widgets/fortune_overlays/work_painter.dart |
| 737 | 🟠 WARN | lib/screens/observe_screen.dart |
| 702 | 🟠 WARN | lib/screens/horoscope/horo_chart_painter.dart |
| 693 | 🟠 WARN | lib/widgets/fortune_overlays/money_painter.dart |
| 688 | 🟠 WARN | lib/screens/map/map_search.dart |
| 656 | 🟠 WARN | lib/screens/map/map_relocation_popup.dart |
| 647 | 🟠 WARN | lib/utils/astro_glossary.dart |
| 646 | 🟠 WARN | lib/screens/map/map_viewpoint_menu.dart |
| 642 | 🟠 WARN | lib/widgets/fortune_overlays/communication_painter.dart |
| 640 | 🟠 WARN | lib/screens/consultation/consultation_input_screen.dart |
| 626 | 🟠 WARN | lib/utils/constellation_namer.dart |
| 624 | 🟠 WARN | lib/screens/map/map_astro_lines.dart |
| 592 | 🟠 WARN | lib/screens/sanctuary/sanctuary_profile_editor.dart |
| 581 | 🟠 WARN | lib/widgets/fortune_overlays/love_painter.dart |
| 579 | 🟠 WARN | lib/screens/consultation/consultation_result_screen.dart |
| 564 | 🟠 WARN | lib/widgets/new_moon_overlay.dart |
| 562 | 🟠 WARN | lib/screens/consultation/consultation_result_card.dart |
| 559 | 🟠 WARN | lib/utils/planet_intro.dart |
| 550 | 🟠 WARN | lib/screens/consultation/consultation_input_widgets.dart |
| 535 | 🟠 WARN | lib/utils/astro_lines.dart |
| 511 | 🟠 WARN | lib/screens/map/map_astro.dart |
| 510 | 🟠 WARN | lib/utils/consultation_v2_api.dart |
| 500 | 🟠 WARN | lib/screens/observe/tarot_altar_scene.dart |
| 499 | 🟡 NOTICE | lib/screens/consultation/consultation_history_widgets.dart |
| 498 | 🟡 NOTICE | lib/widgets/fortune_overlays/healing_painter.dart |
| 495 | 🟡 NOTICE | lib/screens/map/map_time_slider.dart |
| 490 | 🟡 NOTICE | lib/utils/app_attest_client.dart |
| 487 | 🟡 NOTICE | lib/screens/map/map_overlays.dart |
| 486 | 🟡 NOTICE | lib/utils/solara_auth.dart |
| 481 | 🟡 NOTICE | lib/widgets/full_moon_overlay.dart |
| 476 | 🟡 NOTICE | lib/screens/sanctuary/class_share_card.dart |
| 467 | 🟡 NOTICE | lib/screens/horoscope/horo_relocation_panel.dart |
| 455 | 🟡 NOTICE | lib/main.dart |
| 445 | 🟡 NOTICE | lib/widgets/catasterism_overlay.dart |
| 438 | 🟡 NOTICE | lib/screens/galaxy/galaxy_star_atlas.dart |
| 427 | 🟡 NOTICE | lib/screens/consultation/consultation_result_widgets.dart |
| 424 | 🟡 NOTICE | lib/screens/paywall_widgets.dart |
| 417 | 🟡 NOTICE | lib/screens/sanctuary/title_history_screen.dart |
| 415 | 🟡 NOTICE | lib/screens/galaxy/constellation_share_card_page.dart |
| 415 | 🟡 NOTICE | lib/screens/observe/observe_history.dart |
| 413 | 🟡 NOTICE | lib/utils/forecast_cache.dart |
| 413 | 🟡 NOTICE | lib/screens/map/map_display_menu.dart |
| 411 | 🟡 NOTICE | lib/screens/consultation/consultation_place_picker_widgets.dart |
| 396 | 🟡 NOTICE | lib/widgets/cycle_spiral_painter.dart |
| 395 | 🟡 NOTICE | lib/utils/title_data.dart |
| 388 | 🟡 NOTICE | lib/screens/observe/observe_history_filter.dart |
| 374 | 🟡 NOTICE | lib/screens/map/map_direction_popup.dart |
| 360 | 🟡 NOTICE | lib/utils/moon_phase.dart |
| 359 | 🟡 NOTICE | lib/screens/consultation/consultation_input_when_scope.dart |
| 355 | 🟡 NOTICE | lib/widgets/sanctuary_account_section.dart |
| 355 | 🟡 NOTICE | lib/screens/locations/locations_date_stepper.dart |
| 354 | 🟡 NOTICE | lib/screens/consultation/consultation_place_picker_screen.dart |
| 353 | 🟡 NOTICE | lib/screens/ai_consent_screen.dart |
| 350 | 🟡 NOTICE | lib/screens/horoscope/horo_fortune_cards.dart |
| 348 | 🟡 NOTICE | lib/screens/consultation/consultation_credit_sheet.dart |
| 345 | 🟡 NOTICE | lib/screens/consultation/consultation_input_picker.dart |
| 338 | 🟡 NOTICE | lib/screens/map/consult_entry_popup.dart |
| 336 | 🟡 NOTICE | lib/screens/horoscope/horo_birth_panel.dart |
| 315 | 🟡 NOTICE | lib/screens/galaxy/galaxy_archive_filter.dart |
| 313 | 🟡 NOTICE | lib/screens/paywall_screen.dart |
| 313 | 🟡 NOTICE | lib/utils/celestial_events.dart |
| 313 | 🟡 NOTICE | lib/screens/observe/observe_history_past.dart |
| 311 | 🟡 NOTICE | lib/screens/paywall_comparison.dart |
| 309 | 🟡 NOTICE | lib/utils/fortune_api.dart |
| 309 | 🟡 NOTICE | lib/screens/horoscope/horo_panel_shared.dart |
| 308 | 🟡 NOTICE | lib/utils/purchases_service.dart |
| 307 | 🟡 NOTICE | lib/widgets/ai_report_button.dart |
| 306 | 🟡 NOTICE | lib/widgets/class_card.dart |
| 304 | 🟡 NOTICE | lib/screens/map/map_location_markers.dart |

## 2. 重複コード (>= 8 行連続一致、上位 20 件)

### 1. 📁 別ファイル間 (17 箇所、15 ファイル)

  - lib/screens/paywall_comparison.dart:304
  - lib/widgets/ai_report_button.dart:300
  - lib/widgets/class_card.dart:287
  - lib/widgets/location_picker_minimap.dart:135
  - lib/screens/consultation/consultation_input_picker_widgets.dart:85
  ```
  ),
  ```

### 2. 📁 別ファイル間 (14 箇所、14 ファイル)

  - lib/screens/galaxy_screen.dart:558
  - lib/widgets/celestial_event_bar.dart:63
  - lib/widgets/full_moon_overlay.dart:300
  - lib/widgets/new_moon_overlay.dart:313
  - lib/widgets/sanctuary_account_section.dart:248
  ```
  ),
  ```

### 3. 📁 別ファイル間 (14 箇所、10 ファイル)

  - lib/screens/consultation/consultation_history_widgets.dart:49
  - lib/screens/consultation/consultation_input_widgets.dart:112
  - lib/screens/consultation/consultation_result_card.dart:171
  - lib/screens/consultation/consultation_result_card.dart:247
  - lib/screens/consultation/consultation_result_credit_widgets.dart:145
  ```
  ),
  ```

### 4. 📁 別ファイル間 (10 箇所、10 ファイル)

  - lib/screens/galaxy_screen.dart:557
  - lib/screens/paywall_comparison.dart:303
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

  - lib/screens/paywall_widgets.dart:414
  - lib/widgets/catasterism_overlay.dart:191
  - lib/widgets/full_moon_overlay.dart:200
  - lib/widgets/full_moon_overlay.dart:403
  - lib/widgets/full_moon_overlay.dart:458
  ```
  ),
  ```

### 7. 📁 別ファイル間 (11 箇所、8 ファイル)

  - lib/widgets/class_card.dart:288
  - lib/screens/consultation/consultation_input_picker_widgets.dart:86
  - lib/screens/consultation/consultation_input_picker_widgets.dart:127
  - lib/screens/consultation/consultation_input_when_scope.dart:225
  - lib/screens/consultation/consultation_input_when_scope.dart:317
  ```
  ),
  ```

### 8. 📁 別ファイル間 (9 箇所、8 ファイル)

  - lib/screens/paywall_comparison.dart:111
  - lib/screens/paywall_comparison.dart:186
  - lib/screens/paywall_legal_links.dart:83
  - lib/screens/paywall_widgets.dart:413
  - lib/widgets/catasterism_overlay.dart:190
  ```
  ),
  ```

### 9. 📁 別ファイル間 (8 箇所、8 ファイル)

  - lib/widgets/ai_report_button.dart:239
  - lib/screens/consultation/consultation_history_widgets.dart:47
  - lib/screens/consultation/consultation_place_picker_screen.dart:347
  - lib/screens/consultation/consultation_result_credit_widgets.dart:143
  - lib/screens/consultation/consultation_result_widgets.dart:75
  ```
  ),
  ```

### 10. 📁 別ファイル間 (8 箇所、8 ファイル)

  - lib/widgets/ai_report_button.dart:299
  - lib/widgets/new_moon_overlay.dart:312
  - lib/screens/consultation/consultation_input_picker_widgets.dart:84
  - lib/screens/galaxy/constellation_share_card_page.dart:377
  - lib/screens/galaxy/galaxy_cycle_actions_sheet.dart:234
  ```
  ],
  ```

### 11. 📁 別ファイル間 (11 箇所、7 ファイル)

  - lib/screens/ai_consent_screen.dart:250
  - lib/screens/consultation/consultation_input_widgets.dart:384
  - lib/screens/consultation/consultation_result_widgets.dart:31
  - lib/screens/map/consult_entry_popup.dart:277
  - lib/screens/map/map_astro_carto.dart:88
  ```
  ),
  ```

### 12. 📁 別ファイル間 (8 箇所、7 ファイル)

  - lib/screens/sanctuary_screen.dart:402
  - lib/widgets/catasterism_formation_overlay.dart:471
  - lib/widgets/catasterism_overlay.dart:187
  - lib/widgets/full_moon_overlay.dart:196
  - lib/widgets/new_moon_overlay.dart:216
  ```
  ),
  ```

### 13. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/screens/galaxy_screen.dart:559
  - lib/widgets/full_moon_overlay.dart:301
  - lib/widgets/new_moon_overlay.dart:314
  - lib/screens/galaxy/constellation_share_card_page.dart:170
  - lib/screens/map/map_line_narrative_sheet.dart:139
  ```
  ),
  ```

### 14. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/widgets/ai_report_button.dart:240
  - lib/screens/consultation/consultation_history_widgets.dart:48
  - lib/screens/consultation/consultation_result_card.dart:170
  - lib/screens/consultation/consultation_result_credit_widgets.dart:144
  - lib/screens/consultation/consultation_result_widgets.dart:76
  ```
  ],
  ```

### 15. 📁 別ファイル間 (11 箇所、6 ファイル)

  - lib/widgets/class_card.dart:289
  - lib/screens/consultation/consultation_input_picker_widgets.dart:87
  - lib/screens/consultation/consultation_input_picker_widgets.dart:128
  - lib/screens/consultation/consultation_input_when_scope.dart:226
  - lib/screens/consultation/consultation_input_when_scope.dart:318
  ```
  ],
  ```

### 16. 📁 別ファイル間 (9 箇所、6 ファイル)

  - lib/screens/consultation/consultation_input_picker.dart:337
  - lib/screens/consultation/consultation_result_card.dart:283
  - lib/screens/galaxy/galaxy_star_atlas.dart:133
  - lib/screens/galaxy/galaxy_star_atlas.dart:167
  - lib/screens/galaxy/galaxy_star_atlas.dart:333
  ```
  ),
  ```

### 17. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/screens/ai_consent_screen.dart:249
  - lib/widgets/info_popup.dart:108
  - lib/screens/consultation/consultation_input_widgets.dart:383
  - lib/screens/map/consult_entry_popup.dart:276
  - lib/screens/map/map_astro_carto.dart:462
  ```
  ),
  ```

### 18. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/screens/consultation/consultation_input_picker.dart:336
  - lib/screens/consultation/consultation_result_card.dart:282
  - lib/screens/galaxy/galaxy_archive_filter_chips.dart:58
  - lib/screens/galaxy/galaxy_star_atlas.dart:132
  - lib/screens/galaxy/galaxy_star_atlas.dart:332
  ```
  ),
  ```

### 19. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/widgets/catasterism_formation_overlay.dart:472
  - lib/widgets/location_picker_minimap.dart:132
  - lib/widgets/new_moon_overlay.dart:420
  - lib/screens/galaxy/constellation_share_card_page.dart:166
  - lib/screens/sanctuary/class_share_card.dart:240
  ```
  ),
  ```

### 20. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/widgets/catasterism_overlay.dart:189
  - lib/widgets/full_moon_overlay.dart:198
  - lib/widgets/info_popup.dart:107
  - lib/widgets/new_moon_overlay.dart:218
  - lib/screens/consultation/consultation_result_card.dart:538
  ```
  ),
  ```


## 3. TODO/FIXME/HACK/DEBUG 残置

  - lib/main.dart:47 — `// debug/Web/desktop/設定値不足ではいずれも no-op (Free 動作は不変)。`
  - lib/screens/galaxy_screen.dart:456 — `// DEBUG: Cycle完了フローの各タイミングを手動トリガー`
  - lib/utils/device_security_status.dart:115 — `// debug build では `Threat.debug` で常時発火 + signing cert が release と`
  - lib/screens/galaxy/galaxy_archive_filter.dart:80 — `// debug で過去サイクルを後から作ったり、同月内に複数 cycle を並べると`

## 4. print()/debugPrint() 残置

  - lib/utils/solara_auth.dart:368 — `if (kDebugMode) debugPrint('[SolaraAuth] server purge failed: $e');`

## 5. 未使用 private member 候補 (file 内 reference == 1)

✅ なし

---

総計: 行数 HARD 7 / WARN 29 / NOTICE 46 / 重複 20 / TODO 4 / print 1 / 未使用候補 0
