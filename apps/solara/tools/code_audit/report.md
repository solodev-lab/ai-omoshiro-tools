# Solara Code Audit

対象: lib (200 個の .dart)

## 1. ファイル行数 (NOTICE >= 300 / WARN >= 500 / HARD >= 1000)

| 行数 | 判定 | ファイル |
|------|------|----------|
| 3643 | 🔴 HARD | lib/screens/map_screen.dart |
| 2004 | 🔴 HARD | lib/screens/map/map_daily_transit_screen.dart |
| 1678 | 🔴 HARD | lib/screens/sanctuary_screen.dart |
| 1416 | 🔴 HARD | lib/screens/galaxy_screen.dart |
| 1374 | 🔴 HARD | lib/screens/sanctuary/sanctuary_title_diagnosis.dart |
| 1078 | 🔴 HARD | lib/screens/map/daily_transit_data.dart |
| 1057 | 🔴 HARD | lib/screens/forecast_screen.dart |
| 946 | 🟠 WARN | lib/screens/horoscope_screen.dart |
| 937 | 🟠 WARN | lib/utils/solara_storage.dart |
| 859 | 🟠 WARN | lib/screens/map/map_astro_carto.dart |
| 811 | 🟠 WARN | lib/screens/map/map_search.dart |
| 775 | 🟠 WARN | lib/widgets/catasterism_formation_overlay.dart |
| 769 | 🟠 WARN | lib/screens/observe_screen.dart |
| 758 | 🟠 WARN | lib/widgets/fortune_overlays/work_painter.dart |
| 750 | 🟠 WARN | lib/screens/map/map_fortune_sheet.dart |
| 744 | 🟠 WARN | lib/screens/locations_screen.dart |
| 711 | 🟠 WARN | lib/screens/map/map_relocation_popup.dart |
| 702 | 🟠 WARN | lib/screens/horoscope/horo_chart_painter.dart |
| 693 | 🟠 WARN | lib/widgets/fortune_overlays/money_painter.dart |
| 650 | 🟠 WARN | lib/utils/astro_glossary.dart |
| 642 | 🟠 WARN | lib/widgets/fortune_overlays/communication_painter.dart |
| 639 | 🟠 WARN | lib/screens/consultation/consultation_input_screen.dart |
| 626 | 🟠 WARN | lib/utils/constellation_namer.dart |
| 624 | 🟠 WARN | lib/screens/map/map_astro_lines.dart |
| 623 | 🟠 WARN | lib/screens/map/map_viewpoint_menu.dart |
| 610 | 🟠 WARN | lib/screens/sanctuary/sanctuary_profile_editor.dart |
| 582 | 🟠 WARN | lib/screens/consultation/consultation_result_screen.dart |
| 581 | 🟠 WARN | lib/widgets/fortune_overlays/love_painter.dart |
| 581 | 🟠 WARN | lib/screens/consultation/consultation_result_card.dart |
| 576 | 🟠 WARN | lib/utils/app_attest_client.dart |
| 573 | 🟠 WARN | lib/widgets/new_moon_overlay.dart |
| 559 | 🟠 WARN | lib/utils/planet_intro.dart |
| 553 | 🟠 WARN | lib/main.dart |
| 536 | 🟠 WARN | lib/screens/horoscope/horo_relocation_panel.dart |
| 535 | 🟠 WARN | lib/utils/astro_lines.dart |
| 533 | 🟠 WARN | lib/utils/consultation_v2_api.dart |
| 529 | 🟠 WARN | lib/screens/consultation/consultation_input_widgets.dart |
| 511 | 🟠 WARN | lib/screens/map/map_astro.dart |
| 507 | 🟠 WARN | lib/screens/consultation/consultation_history_widgets.dart |
| 505 | 🟠 WARN | lib/screens/sanctuary/title_history_screen.dart |
| 500 | 🟠 WARN | lib/utils/solara_auth.dart |
| 500 | 🟠 WARN | lib/screens/observe/tarot_altar_scene.dart |
| 498 | 🟡 NOTICE | lib/widgets/fortune_overlays/healing_painter.dart |
| 495 | 🟡 NOTICE | lib/screens/map/map_time_slider.dart |
| 487 | 🟡 NOTICE | lib/screens/map/map_overlays.dart |
| 481 | 🟡 NOTICE | lib/widgets/full_moon_overlay.dart |
| 476 | 🟡 NOTICE | lib/screens/sanctuary/class_share_card.dart |
| 451 | 🟡 NOTICE | lib/widgets/catasterism_overlay.dart |
| 445 | 🟡 NOTICE | lib/screens/galaxy/galaxy_star_atlas.dart |
| 432 | 🟡 NOTICE | lib/screens/consultation/consultation_result_widgets.dart |
| 424 | 🟡 NOTICE | lib/screens/paywall_widgets.dart |
| 422 | 🟡 NOTICE | lib/screens/observe/observe_history.dart |
| 415 | 🟡 NOTICE | lib/screens/galaxy/constellation_share_card_page.dart |
| 413 | 🟡 NOTICE | lib/utils/forecast_cache.dart |
| 413 | 🟡 NOTICE | lib/screens/consultation/consultation_place_picker_widgets.dart |
| 409 | 🟡 NOTICE | lib/screens/map/map_display_menu.dart |
| 396 | 🟡 NOTICE | lib/widgets/cycle_spiral_painter.dart |
| 395 | 🟡 NOTICE | lib/utils/title_data.dart |
| 393 | 🟡 NOTICE | lib/screens/observe/observe_history_filter.dart |
| 374 | 🟡 NOTICE | lib/screens/map/map_direction_popup.dart |
| 363 | 🟡 NOTICE | lib/screens/consultation/consultation_input_when_scope.dart |
| 360 | 🟡 NOTICE | lib/utils/moon_phase.dart |
| 359 | 🟡 NOTICE | lib/utils/consultation_v2_request.dart |
| 357 | 🟡 NOTICE | lib/widgets/sanctuary_account_section.dart |
| 357 | 🟡 NOTICE | lib/screens/consultation/consultation_place_picker_screen.dart |
| 355 | 🟡 NOTICE | lib/screens/consultation/consultation_credit_sheet.dart |
| 355 | 🟡 NOTICE | lib/screens/locations/locations_date_stepper.dart |
| 345 | 🟡 NOTICE | lib/screens/consultation/consultation_input_picker.dart |
| 345 | 🟡 NOTICE | lib/screens/horoscope/horo_birth_panel.dart |
| 338 | 🟡 NOTICE | lib/screens/map/consult_entry_popup.dart |
| 337 | 🟡 NOTICE | lib/screens/horoscope/horo_fortune_cards.dart |
| 315 | 🟡 NOTICE | lib/screens/galaxy/galaxy_archive_filter.dart |
| 314 | 🟡 NOTICE | lib/screens/paywall_screen.dart |
| 314 | 🟡 NOTICE | lib/utils/fortune_api.dart |
| 313 | 🟡 NOTICE | lib/utils/celestial_events.dart |
| 313 | 🟡 NOTICE | lib/screens/observe/observe_history_past.dart |
| 312 | 🟡 NOTICE | lib/utils/moon_notification_service.dart |
| 311 | 🟡 NOTICE | lib/widgets/class_card.dart |
| 309 | 🟡 NOTICE | lib/screens/horoscope/horo_panel_shared.dart |
| 308 | 🟡 NOTICE | lib/utils/purchases_service.dart |
| 307 | 🟡 NOTICE | lib/widgets/ai_report_button.dart |
| 305 | 🟡 NOTICE | lib/screens/consultation/consultation_history_screen.dart |
| 304 | 🟡 NOTICE | lib/screens/map/map_location_markers.dart |
| 301 | 🟡 NOTICE | lib/screens/ai_consent_screen.dart |
| 300 | 🟡 NOTICE | lib/screens/consultation/consultation_start_popup.dart |

## 2. 重複コード (>= 8 行連続一致、上位 20 件)

### 1. 📁 別ファイル間 (17 箇所、15 ファイル)

  - lib/screens/paywall_comparison.dart:274
  - lib/widgets/ai_report_button.dart:300
  - lib/widgets/class_card.dart:292
  - lib/widgets/location_picker_minimap.dart:135
  - lib/screens/consultation/consultation_input_picker_widgets.dart:85
  ```
  ),
  ```

### 2. 📁 別ファイル間 (15 箇所、15 ファイル)

  - lib/screens/galaxy_screen.dart:580
  - lib/widgets/celestial_event_bar.dart:63
  - lib/widgets/full_moon_overlay.dart:300
  - lib/widgets/new_moon_overlay.dart:314
  - lib/widgets/sanctuary_account_section.dart:248
  ```
  ),
  ```

### 3. 📁 別ファイル間 (11 箇所、11 ファイル)

  - lib/screens/galaxy_screen.dart:579
  - lib/screens/paywall_comparison.dart:273
  - lib/widgets/full_moon_overlay.dart:299
  - lib/widgets/location_picker_minimap.dart:134
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

### 5. 📁 別ファイル間 (11 箇所、10 ファイル)

  - lib/screens/observe_screen.dart:706
  - lib/screens/paywall_comparison.dart:124
  - lib/screens/paywall_comparison.dart:199
  - lib/screens/paywall_legal_links.dart:83
  - lib/screens/paywall_widgets.dart:413
  ```
  ),
  ```

### 6. 📁 別ファイル間 (14 箇所、9 ファイル)

  - lib/screens/paywall_widgets.dart:414
  - lib/widgets/catasterism_overlay.dart:191
  - lib/widgets/full_moon_overlay.dart:200
  - lib/widgets/full_moon_overlay.dart:403
  - lib/widgets/full_moon_overlay.dart:458
  ```
  ),
  ```

### 7. 📁 別ファイル間 (39 箇所、8 ファイル)

  - lib/screens/forecast_screen.dart:879
  - lib/screens/forecast_screen.dart:894
  - lib/screens/forecast_screen.dart:909
  - lib/screens/forecast_screen.dart:924
  - lib/screens/forecast_screen.dart:939
  ```
  style: const TextStyle(
  ```

### 8. 📁 別ファイル間 (11 箇所、8 ファイル)

  - lib/widgets/class_card.dart:293
  - lib/screens/consultation/consultation_input_picker_widgets.dart:86
  - lib/screens/consultation/consultation_input_picker_widgets.dart:127
  - lib/screens/consultation/consultation_input_when_scope.dart:226
  - lib/screens/consultation/consultation_input_when_scope.dart:319
  ```
  ),
  ```

### 9. 📁 別ファイル間 (8 箇所、8 ファイル)

  - lib/widgets/ai_report_button.dart:239
  - lib/screens/consultation/consultation_history_widgets.dart:47
  - lib/screens/consultation/consultation_place_picker_screen.dart:350
  - lib/screens/consultation/consultation_result_credit_widgets.dart:140
  - lib/screens/consultation/consultation_result_widgets.dart:75
  ```
  ),
  ```

### 10. 📁 別ファイル間 (12 箇所、7 ファイル)

  - lib/screens/sanctuary_screen.dart:1574
  - lib/widgets/class_card.dart:294
  - lib/screens/consultation/consultation_input_picker_widgets.dart:87
  - lib/screens/consultation/consultation_input_picker_widgets.dart:128
  - lib/screens/consultation/consultation_input_when_scope.dart:227
  ```
  ],
  ```

### 11. 📁 別ファイル間 (11 箇所、7 ファイル)

  - lib/screens/ai_consent_screen.dart:198
  - lib/screens/consultation/consultation_input_widgets.dart:404
  - lib/screens/consultation/consultation_result_widgets.dart:31
  - lib/screens/map/consult_entry_popup.dart:277
  - lib/screens/map/map_astro_carto.dart:89
  ```
  ),
  ```

### 12. 📁 別ファイル間 (8 箇所、7 ファイル)

  - lib/screens/sanctuary_screen.dart:403
  - lib/widgets/catasterism_formation_overlay.dart:471
  - lib/widgets/catasterism_overlay.dart:187
  - lib/widgets/full_moon_overlay.dart:196
  - lib/widgets/new_moon_overlay.dart:217
  ```
  ),
  ```

### 13. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/screens/galaxy_screen.dart:581
  - lib/widgets/full_moon_overlay.dart:301
  - lib/widgets/new_moon_overlay.dart:315
  - lib/screens/galaxy/constellation_share_card_page.dart:170
  - lib/screens/map/map_line_narrative_sheet.dart:139
  ```
  ),
  ```

### 14. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/widgets/ai_report_button.dart:240
  - lib/screens/consultation/consultation_history_widgets.dart:48
  - lib/screens/consultation/consultation_result_card.dart:173
  - lib/screens/consultation/consultation_result_credit_widgets.dart:141
  - lib/screens/consultation/consultation_result_widgets.dart:76
  ```
  ],
  ```

### 15. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/widgets/ai_report_button.dart:299
  - lib/widgets/new_moon_overlay.dart:313
  - lib/screens/consultation/consultation_input_picker_widgets.dart:84
  - lib/screens/galaxy/constellation_share_card_page.dart:377
  - lib/screens/galaxy/galaxy_cycle_actions_sheet.dart:234
  ```
  ],
  ```

### 16. 📁 別ファイル間 (7 箇所、7 ファイル)

  - lib/widgets/catasterism_overlay.dart:189
  - lib/widgets/full_moon_overlay.dart:198
  - lib/widgets/info_popup.dart:107
  - lib/widgets/new_moon_overlay.dart:219
  - lib/screens/consultation/consultation_result_card.dart:557
  ```
  ),
  ```

### 17. 📁 別ファイル間 (9 箇所、6 ファイル)

  - lib/screens/consultation/consultation_input_picker.dart:337
  - lib/screens/consultation/consultation_result_card.dart:303
  - lib/screens/galaxy/galaxy_star_atlas.dart:133
  - lib/screens/galaxy/galaxy_star_atlas.dart:167
  - lib/screens/galaxy/galaxy_star_atlas.dart:340
  ```
  ),
  ```

### 18. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/screens/ai_consent_screen.dart:197
  - lib/widgets/info_popup.dart:108
  - lib/screens/consultation/consultation_input_widgets.dart:403
  - lib/screens/map/consult_entry_popup.dart:276
  - lib/screens/map/map_astro_carto.dart:449
  ```
  ),
  ```

### 19. 📁 別ファイル間 (7 箇所、6 ファイル)

  - lib/screens/consultation/consultation_input_picker.dart:336
  - lib/screens/consultation/consultation_result_card.dart:302
  - lib/screens/galaxy/galaxy_archive_filter_chips.dart:58
  - lib/screens/galaxy/galaxy_star_atlas.dart:132
  - lib/screens/galaxy/galaxy_star_atlas.dart:339
  ```
  ),
  ```

### 20. 📁 別ファイル間 (6 箇所、6 ファイル)

  - lib/widgets/catasterism_formation_overlay.dart:472
  - lib/widgets/location_picker_minimap.dart:132
  - lib/widgets/new_moon_overlay.dart:421
  - lib/screens/galaxy/constellation_share_card_page.dart:166
  - lib/screens/sanctuary/class_share_card.dart:240
  ```
  ),
  ```


## 3. TODO/FIXME/HACK/DEBUG 残置

  - lib/main.dart:56 — `// debug/Web/desktop/設定値不足ではいずれも no-op (Free 動作は不変)。`
  - lib/screens/galaxy_screen.dart:478 — `// DEBUG: Cycle完了フローの各タイミングを手動トリガー`
  - lib/utils/device_security_status.dart:115 — `// debug build では `Threat.debug` で常時発火 + signing cert が release と`
  - lib/screens/galaxy/galaxy_archive_filter.dart:80 — `// debug で過去サイクルを後から作ったり、同月内に複数 cycle を並べると`

## 4. print()/debugPrint() 残置

  - lib/utils/solara_auth.dart:376 — `if (kDebugMode) debugPrint('[SolaraAuth] server purge failed: $e');`

## 5. 未使用 private member 候補 (file 内 reference == 1)

✅ なし

---

総計: 行数 HARD 7 / WARN 35 / NOTICE 43 / 重複 20 / TODO 4 / print 1 / 未使用候補 0
