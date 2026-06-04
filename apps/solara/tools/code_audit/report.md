# Solara Code Audit

対象: lib (205 個の .dart)

## 1. ファイル行数 (NOTICE >= 300 / WARN >= 500 / HARD >= 1000)

| 行数 | 判定 | ファイル |
|------|------|----------|
| 3625 | 🔴 HARD | lib/screens/map_screen.dart |
| 2004 | 🔴 HARD | lib/screens/map/map_daily_transit_screen.dart |
| 1723 | 🔴 HARD | lib/screens/sanctuary_screen.dart |
| 1412 | 🔴 HARD | lib/screens/galaxy_screen.dart |
| 1410 | 🔴 HARD | lib/screens/sanctuary/sanctuary_title_diagnosis.dart |
| 1154 | 🔴 HARD | lib/screens/map/daily_transit_data.dart |
| 1093 | 🔴 HARD | lib/screens/forecast_screen.dart |
| 984 | 🟠 WARN | lib/utils/planet_intro.dart |
| 945 | 🟠 WARN | lib/screens/horoscope_screen.dart |
| 941 | 🟠 WARN | lib/utils/solara_storage.dart |
| 858 | 🟠 WARN | lib/screens/map/map_astro_carto.dart |
| 817 | 🟠 WARN | lib/screens/map/map_search.dart |
| 779 | 🟠 WARN | lib/widgets/catasterism_formation_overlay.dart |
| 771 | 🟠 WARN | lib/screens/observe_screen.dart |
| 759 | 🟠 WARN | lib/screens/locations_screen.dart |
| 758 | 🟠 WARN | lib/widgets/fortune_overlays/work_painter.dart |
| 750 | 🟠 WARN | lib/screens/map/map_fortune_sheet.dart |
| 722 | 🟠 WARN | lib/screens/map/map_relocation_popup.dart |
| 702 | 🟠 WARN | lib/screens/horoscope/horo_chart_painter.dart |
| 693 | 🟠 WARN | lib/widgets/fortune_overlays/money_painter.dart |
| 657 | 🟠 WARN | lib/utils/astro_glossary.dart |
| 644 | 🟠 WARN | lib/screens/map/daily_transit_data_en2.dart |
| 642 | 🟠 WARN | lib/widgets/fortune_overlays/communication_painter.dart |
| 640 | 🟠 WARN | lib/screens/consultation/consultation_input_screen.dart |
| 626 | 🟠 WARN | lib/utils/constellation_namer.dart |
| 625 | 🟠 WARN | lib/screens/map/map_astro_lines.dart |
| 623 | 🟠 WARN | lib/screens/map/map_viewpoint_menu.dart |
| 609 | 🟠 WARN | lib/main.dart |
| 582 | 🟠 WARN | lib/screens/consultation/consultation_result_screen.dart |
| 581 | 🟠 WARN | lib/widgets/new_moon_overlay.dart |
| 581 | 🟠 WARN | lib/widgets/fortune_overlays/love_painter.dart |
| 581 | 🟠 WARN | lib/screens/consultation/consultation_result_card.dart |
| 576 | 🟠 WARN | lib/utils/app_attest_client.dart |
| 558 | 🟠 WARN | lib/utils/astro_glossary_en.dart |
| 552 | 🟠 WARN | lib/screens/sanctuary/sanctuary_profile_editor.dart |
| 540 | 🟠 WARN | lib/screens/horoscope/horo_relocation_panel.dart |
| 535 | 🟠 WARN | lib/utils/astro_lines.dart |
| 533 | 🟠 WARN | lib/utils/consultation_v2_api.dart |
| 529 | 🟠 WARN | lib/screens/consultation/consultation_input_widgets.dart |
| 511 | 🟠 WARN | lib/screens/map/map_astro.dart |
| 508 | 🟠 WARN | lib/screens/consultation/consultation_history_widgets.dart |
| 504 | 🟠 WARN | lib/screens/sanctuary/title_history_screen.dart |
| 501 | 🟠 WARN | lib/screens/sanctuary/class_share_card.dart |
| 500 | 🟠 WARN | lib/utils/solara_auth.dart |
| 500 | 🟠 WARN | lib/screens/observe/tarot_altar_scene.dart |
| 498 | 🟡 NOTICE | lib/widgets/fortune_overlays/healing_painter.dart |
| 497 | 🟡 NOTICE | lib/screens/map/map_time_slider.dart |
| 490 | 🟡 NOTICE | lib/widgets/full_moon_overlay.dart |
| 490 | 🟡 NOTICE | lib/screens/map/map_overlays.dart |
| 467 | 🟡 NOTICE | lib/widgets/catasterism_overlay.dart |
| 449 | 🟡 NOTICE | lib/screens/galaxy/galaxy_star_atlas.dart |
| 438 | 🟡 NOTICE | lib/screens/galaxy/constellation_share_card_page.dart |
| 432 | 🟡 NOTICE | lib/screens/consultation/consultation_result_widgets.dart |
| 424 | 🟡 NOTICE | lib/screens/paywall_widgets.dart |
| 423 | 🟡 NOTICE | lib/screens/observe/observe_history.dart |
| 413 | 🟡 NOTICE | lib/utils/forecast_cache.dart |
| 413 | 🟡 NOTICE | lib/screens/consultation/consultation_place_picker_widgets.dart |
| 409 | 🟡 NOTICE | lib/screens/map/map_display_menu.dart |
| 396 | 🟡 NOTICE | lib/widgets/cycle_spiral_painter.dart |
| 395 | 🟡 NOTICE | lib/utils/title_data.dart |
| 393 | 🟡 NOTICE | lib/screens/map/daily_transit_data_en.dart |
| 393 | 🟡 NOTICE | lib/screens/observe/observe_history_filter.dart |
| 375 | 🟡 NOTICE | lib/screens/map/map_direction_popup.dart |
| 363 | 🟡 NOTICE | lib/screens/consultation/consultation_input_when_scope.dart |
| 360 | 🟡 NOTICE | lib/utils/moon_phase.dart |
| 359 | 🟡 NOTICE | lib/utils/consultation_v2_request.dart |
| 357 | 🟡 NOTICE | lib/screens/consultation/consultation_place_picker_screen.dart |
| 357 | 🟡 NOTICE | lib/screens/locations/locations_date_stepper.dart |
| 355 | 🟡 NOTICE | lib/screens/consultation/consultation_credit_sheet.dart |
| 354 | 🟡 NOTICE | lib/widgets/sanctuary_account_section.dart |
| 352 | 🟡 NOTICE | lib/utils/astro_zenith_messages.dart |
| 346 | 🟡 NOTICE | lib/screens/horoscope/horo_birth_panel.dart |
| 345 | 🟡 NOTICE | lib/screens/consultation/consultation_input_picker.dart |
| 340 | 🟡 NOTICE | lib/screens/map/consult_entry_popup.dart |
| 337 | 🟡 NOTICE | lib/screens/horoscope/horo_fortune_cards.dart |
| 335 | 🟡 NOTICE | lib/widgets/class_card.dart |
| 317 | 🟡 NOTICE | lib/utils/celestial_events.dart |
| 316 | 🟡 NOTICE | lib/utils/fortune_api.dart |
| 315 | 🟡 NOTICE | lib/screens/ai_consent_screen.dart |
| 315 | 🟡 NOTICE | lib/widgets/ai_report_button.dart |
| 314 | 🟡 NOTICE | lib/screens/galaxy/galaxy_archive_filter.dart |
| 313 | 🟡 NOTICE | lib/screens/horoscope/horo_panel_shared.dart |
| 312 | 🟡 NOTICE | lib/utils/moon_notification_service.dart |
| 311 | 🟡 NOTICE | lib/screens/paywall_screen.dart |
| 310 | 🟡 NOTICE | lib/screens/observe/observe_history_past.dart |
| 308 | 🟡 NOTICE | lib/utils/purchases_service.dart |
| 306 | 🟡 NOTICE | lib/screens/consultation/consultation_history_screen.dart |
| 305 | 🟡 NOTICE | lib/screens/map/map_location_markers.dart |
| 300 | 🟡 NOTICE | lib/screens/consultation/consultation_start_popup.dart |
| 300 | 🟡 NOTICE | lib/screens/map/map_line_narrative_sheet.dart |

## 2. 重複コード (>= 8 行連続一致、上位 20 件)

### 1. 📁 別ファイル間 (16 箇所、16 ファイル)

  - lib/screens/galaxy_screen.dart:580
  - lib/widgets/celestial_event_bar.dart:64
  - lib/widgets/full_moon_overlay.dart:306
  - lib/widgets/new_moon_overlay.dart:317
  - lib/widgets/sanctuary_account_section.dart:249
  ```
  ),
  ```

### 2. 📁 別ファイル間 (17 箇所、15 ファイル)

  - lib/screens/paywall_comparison.dart:278
  - lib/widgets/ai_report_button.dart:308
  - lib/widgets/class_card.dart:316
  - lib/widgets/location_picker_minimap.dart:136
  - lib/screens/consultation/consultation_input_picker_widgets.dart:85
  ```
  ),
  ```

### 3. 📁 別ファイル間 (11 箇所、11 ファイル)

  - lib/screens/galaxy_screen.dart:579
  - lib/screens/paywall_comparison.dart:277
  - lib/widgets/full_moon_overlay.dart:305
  - lib/widgets/location_picker_minimap.dart:135
  - lib/screens/consultation/consultation_result_widgets.dart:296
  ```
  ),
  ```

### 4. 📁 別ファイル間 (14 箇所、10 ファイル)

  - lib/screens/consultation/consultation_history_widgets.dart:49
  - lib/screens/consultation/consultation_input_widgets.dart:130
  - lib/screens/consultation/consultation_result_card.dart:174
  - lib/screens/consultation/consultation_result_card.dart:267
  - lib/screens/consultation/consultation_result_credit_widgets.dart:142
  ```
  ),
  ```

### 5. 📁 別ファイル間 (12 箇所、10 ファイル)

  - lib/screens/observe_screen.dart:709
  - lib/screens/paywall_comparison.dart:124
  - lib/screens/paywall_comparison.dart:156
  - lib/screens/paywall_comparison.dart:203
  - lib/screens/paywall_legal_links.dart:83
  ```
  ),
  ```

### 6. 📁 別ファイル間 (43 箇所、9 ファイル)

  - lib/screens/forecast_screen.dart:915
  - lib/screens/forecast_screen.dart:930
  - lib/screens/forecast_screen.dart:945
  - lib/screens/forecast_screen.dart:960
  - lib/screens/forecast_screen.dart:975
  ```
  style: const TextStyle(
  ```

### 7. 📁 別ファイル間 (12 箇所、9 ファイル)

  - lib/screens/paywall_widgets.dart:414
  - lib/widgets/catasterism_overlay.dart:192
  - lib/widgets/full_moon_overlay.dart:201
  - lib/widgets/full_moon_overlay.dart:410
  - lib/widgets/full_moon_overlay.dart:467
  ```
  ),
  ```

### 8. 📁 別ファイル間 (11 箇所、8 ファイル)

  - lib/widgets/class_card.dart:317
  - lib/screens/consultation/consultation_input_picker_widgets.dart:86
  - lib/screens/consultation/consultation_input_picker_widgets.dart:127
  - lib/screens/consultation/consultation_input_when_scope.dart:226
  - lib/screens/consultation/consultation_input_when_scope.dart:319
  ```
  ),
  ```

### 9. 📁 別ファイル間 (8 箇所、8 ファイル)

  - lib/widgets/ai_report_button.dart:247
  - lib/screens/consultation/consultation_history_widgets.dart:47
  - lib/screens/consultation/consultation_place_picker_screen.dart:350
  - lib/screens/consultation/consultation_result_credit_widgets.dart:140
  - lib/screens/consultation/consultation_result_widgets.dart:75
  ```
  ),
  ```

### 10. 📁 別ファイル間 (8 箇所、8 ファイル)

  - lib/widgets/ai_report_button.dart:307
  - lib/widgets/new_moon_overlay.dart:316
  - lib/screens/consultation/consultation_input_picker_widgets.dart:84
  - lib/screens/galaxy/constellation_share_card_page.dart:400
  - lib/screens/galaxy/galaxy_cycle_actions_sheet.dart:242
  ```
  ],
  ```

### 11. 📁 別ファイル間 (12 箇所、7 ファイル)

  - lib/screens/sanctuary_screen.dart:1619
  - lib/widgets/class_card.dart:318
  - lib/screens/consultation/consultation_input_picker_widgets.dart:87
  - lib/screens/consultation/consultation_input_picker_widgets.dart:128
  - lib/screens/consultation/consultation_input_when_scope.dart:227
  ```
  ],
  ```

### 12. 📁 別ファイル間 (11 箇所、7 ファイル)

  - lib/screens/ai_consent_screen.dart:212
  - lib/screens/consultation/consultation_input_widgets.dart:404
  - lib/screens/consultation/consultation_result_widgets.dart:31
  - lib/screens/map/consult_entry_popup.dart:278
  - lib/screens/map/map_astro_carto.dart:88
  ```
  ),
  ```

### 13. 📁 別ファイル間 (8 箇所、7 ファイル)

  - lib/screens/sanctuary_screen.dart:423
  - lib/widgets/catasterism_formation_overlay.dart:475
  - lib/widgets/catasterism_overlay.dart:188
  - lib/widgets/full_moon_overlay.dart:197
  - lib/widgets/new_moon_overlay.dart:219
  ```
  ),
  ```

### 14. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/screens/galaxy_screen.dart:581
  - lib/widgets/full_moon_overlay.dart:307
  - lib/widgets/new_moon_overlay.dart:318
  - lib/screens/galaxy/constellation_share_card_page.dart:176
  - lib/screens/map/map_line_narrative_sheet.dart:141
  ```
  ),
  ```

### 15. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/widgets/ai_report_button.dart:248
  - lib/screens/consultation/consultation_history_widgets.dart:48
  - lib/screens/consultation/consultation_result_card.dart:173
  - lib/screens/consultation/consultation_result_credit_widgets.dart:141
  - lib/screens/consultation/consultation_result_widgets.dart:76
  ```
  ],
  ```

### 16. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/widgets/catasterism_overlay.dart:190
  - lib/widgets/full_moon_overlay.dart:199
  - lib/widgets/info_popup.dart:107
  - lib/widgets/new_moon_overlay.dart:221
  - lib/screens/consultation/consultation_result_card.dart:557
  ```
  ),
  ```

### 17. 📁 別ファイル間 (9 箇所、6 ファイル)

  - lib/screens/consultation/consultation_input_picker.dart:337
  - lib/screens/consultation/consultation_result_card.dart:303
  - lib/screens/galaxy/galaxy_star_atlas.dart:137
  - lib/screens/galaxy/galaxy_star_atlas.dart:171
  - lib/screens/galaxy/galaxy_star_atlas.dart:344
  ```
  ),
  ```

### 18. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/screens/ai_consent_screen.dart:211
  - lib/widgets/info_popup.dart:108
  - lib/screens/consultation/consultation_input_widgets.dart:403
  - lib/screens/map/consult_entry_popup.dart:277
  - lib/screens/map/map_astro_carto.dart:448
  ```
  ),
  ```

### 19. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/screens/consultation/consultation_input_picker.dart:336
  - lib/screens/consultation/consultation_result_card.dart:302
  - lib/screens/galaxy/galaxy_archive_filter_chips.dart:58
  - lib/screens/galaxy/galaxy_star_atlas.dart:136
  - lib/screens/galaxy/galaxy_star_atlas.dart:343
  ```
  ),
  ```

### 20. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/screens/forecast_screen.dart:984
  - lib/screens/map/map_astro_carto.dart:211
  - lib/screens/map/map_daily_transit_screen.dart:1997
  - lib/screens/map/map_fortune_sheet.dart:707
  - lib/screens/map/map_viewpoint_menu.dart:103
  ```
  style: const TextStyle(
  ```


## 3. TODO/FIXME/HACK/DEBUG 残置

  - lib/main.dart:59 — `// debug/Web/desktop/設定値不足ではいずれも no-op (Free 動作は不変)。`
  - lib/screens/galaxy_screen.dart:478 — `// DEBUG: Cycle完了フローの各タイミングを手動トリガー`
  - lib/utils/device_security_status.dart:115 — `// debug build では `Threat.debug` で常時発火 + signing cert が release と`
  - lib/screens/galaxy/galaxy_archive_filter.dart:81 — `// debug で過去サイクルを後から作ったり、同月内に複数 cycle を並べると`

## 4. print()/debugPrint() 残置

  - lib/utils/solara_auth.dart:376 — `if (kDebugMode) debugPrint('[SolaraAuth] server purge failed: $e');`

## 5. 未使用 private member 候補 (file 内 reference == 1)

✅ なし

---

総計: 行数 HARD 7 / WARN 38 / NOTICE 45 / 重複 20 / TODO 4 / print 1 / 未使用候補 0
