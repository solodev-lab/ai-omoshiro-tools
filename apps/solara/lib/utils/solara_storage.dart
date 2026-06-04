import 'dart:convert';
import 'package:characters/characters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_reading.dart';
import '../models/galaxy_cycle.dart';
import '../models/lunar_intention.dart';
import 'consultation_record.dart';

/// User profile data.
class SolaraProfile {
  final String name;
  final String birthDate; // YYYY-MM-DD
  final String birthTime; // HH:mm
  final bool birthTimeUnknown;
  final String birthPlace;
  final double birthLat;
  final double birthLng;
  final int birthTz; // UTC offset in hours (legacy fallback)
  final String? birthTzName; // IANA TZ name e.g. 'Asia/Tokyo' (DST-aware, C案)
  final String homeName; // HTML: p.homeName
  final double homeLat;  // HTML: p.homeLat
  final double homeLng;  // HTML: p.homeLng

  const SolaraProfile({
    this.name = '',
    this.birthDate = '',
    this.birthTime = '12:00',
    this.birthTimeUnknown = false,
    this.birthPlace = '',
    this.birthLat = 0,
    this.birthLng = 0,
    this.birthTz = 9,
    this.birthTzName,
    this.homeName = '',
    this.homeLat = 0,
    this.homeLng = 0,
  });

  bool get isComplete => birthDate.isNotEmpty && birthPlace.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'name': name,
    'birthDate': birthDate,
    'birthTime': birthTime,
    'birthTimeUnknown': birthTimeUnknown,
    'birthPlace': birthPlace,
    'birthLat': birthLat,
    'birthLng': birthLng,
    'birthTz': birthTz,
    'birthTzName': birthTzName,
    'homeName': homeName,
    'homeLat': homeLat,
    'homeLng': homeLng,
  };

  factory SolaraProfile.fromJson(Map<String, dynamic> j) => SolaraProfile(
    name: j['name'] ?? '',
    birthDate: j['birthDate'] ?? '',
    birthTime: j['birthTime'] ?? '12:00',
    birthTimeUnknown: j['birthTimeUnknown'] ?? false,
    birthPlace: j['birthPlace'] ?? '',
    birthLat: (j['birthLat'] ?? 0).toDouble(),
    birthLng: (j['birthLng'] ?? 0).toDouble(),
    birthTz: j['birthTz'] ?? 9,
    birthTzName: j['birthTzName'] as String?,
    homeName: j['homeName'] ?? '',
    homeLat: (j['homeLat'] ?? 0).toDouble(),
    homeLng: (j['homeLng'] ?? 0).toDouble(),
  );

  SolaraProfile copyWith({
    String? name,
    String? birthDate,
    String? birthTime,
    bool? birthTimeUnknown,
    String? birthPlace,
    double? birthLat,
    double? birthLng,
    int? birthTz,
    String? birthTzName,
    String? homeName,
    double? homeLat,
    double? homeLng,
  }) => SolaraProfile(
    name: name ?? this.name,
    birthDate: birthDate ?? this.birthDate,
    birthTime: birthTime ?? this.birthTime,
    birthTimeUnknown: birthTimeUnknown ?? this.birthTimeUnknown,
    birthPlace: birthPlace ?? this.birthPlace,
    birthLat: birthLat ?? this.birthLat,
    birthLng: birthLng ?? this.birthLng,
    birthTz: birthTz ?? this.birthTz,
    birthTzName: birthTzName ?? this.birthTzName,
    homeName: homeName ?? this.homeName,
    homeLat: homeLat ?? this.homeLat,
    homeLng: homeLng ?? this.homeLng,
  );
}

/// ウェルカム特典 (恒久クレジット) のローカル状態。
/// [baselineSet] 初回ベースライン記録済 / [eligible] 新規完了者 (付与対象) /
/// [granted] 付与成功済 / [consultUsed] 付与後に相談へ進んだ or バナーを閉じた。
class WelcomeGiftFlags {
  final bool baselineSet;
  final bool eligible;
  final bool granted;
  final bool consultUsed;

  const WelcomeGiftFlags({
    required this.baselineSet,
    required this.eligible,
    required this.granted,
    required this.consultUsed,
  });
}

/// Persistence wrapper for Solara data.
class SolaraStorage {
  static const _profileKey = 'solara_profile';
  static const _currentReadingsKey = 'solara_current_cycle_readings';
  static const _completedCyclesKey = 'solara_galaxy_cycles';
  static const _intentionKey = 'solara_lunar_intention';
  static const _overlayShownKey = 'solara_overlay_shown';
  /// 2026-05-29: Sanctuary リセット時刻に左右されない、端末日付 (常に 0 時切替)
  /// 基準の overlay seen キー。Sanctuary picker subtitle が「タロットのみ」と
  /// 明示している通り、Daily Transit Badge / Galaxy 3 演出はリセット時刻設定の
  /// 影響を受けない設計に揃えるための新キー。
  static const _localOverlayShownKey = 'solara_local_overlay_shown';
  static const _mapStyleKey = 'solara_map_style';
  static const _dailyResetHourKey = 'solara_daily_reset_hour';
  static const _dailyResetMinuteKey = 'solara_daily_reset_minute';
  static const _lastFreeTarotDayKey = 'solara_last_free_tarot_day';
  static const _forecastColorModeKey = 'solara_forecast_color_mode';
  static const _forecastHighColorKey = 'solara_forecast_high_color';
  static const _forecastYearOffsetKey = 'solara_forecast_year_offset';
  // V2 (全要素統合) でレコード形式が変わったため key を更新。旧キーのデータは
  // 互換性がないので無視 (pre-launch・内部テストのみ。実害なし)。
  static const _consultationHistoryKey = 'solara_consultation_history_v2';

  /// 相談 候補「無連続」avoid-window (C-2)。theme×scope ごとに直近に提示した地名を
  /// 覚えておき、次の相談で同じ土地の繰り返しを避ける。JSON マップ {key: [names]} を 1 キーに保存。
  /// key = 'theme:scopeKind'。各リストは最新 N 件 (Pro 9 / Free 6) に trim。端末ローカル。
  static const _consultationAvoidKey = 'solara_consultation_avoid_v1';
  // AI 生成同意 (Apple 5.1.2(i) 2025-11-13 改定、Google Generative AI Apps policy)。
  // 出生情報・相談内容を Google Gemini API に送る旨を明示し、初回起動時に
  // 一度だけユーザー同意を取得する。ISO8601 文字列を保存 (null = 未同意)。
  // 詳細: docs/store_compliance.md §2.1 / §5.2
  static const _aiConsentAtKey = 'solara_ai_consent_at_v1';

  /// 画面復元スナップショット (Android プロセス死対策)。
  /// 低 RAM 端末 (A101FC 等) で外部アプリ (Google マップ等) へ離脱中に OS が
  /// Solara プロセスを kill → 復帰時にコールド再起動して初期画面に戻る問題の対策。
  /// バックグラウンド遷移 (paused) 時に「タブ + 各画面の最小復元キー」を保存し、
  /// 次回コールド起動時に復元する。warm resume 時は破棄 (メモリ状態が無傷のため)。
  static const _restoreSnapshotKey = 'solara_restore_snapshot_v1';

  /// 相談履歴の上限 (Free / Pro 共通)。柱 3 の原則「Free でも自分の記録を永久に
  /// 失わない」を満たす範囲で、ストレージ肥大を抑える上限。
  /// 1 件 ~3KB 想定 × 200 件 = ~600KB、SharedPreferences で十分。
  static const consultationHistoryMax = 200;

  // --- AI Generation Consent (Apple 5.1.2(i) / Google Gen AI Policy) ---

  /// AI 生成同意の取得日時 (null = 未同意)。
  /// Apple Reviewer は onboarding 同意とプライバシーポリシー記載の line-by-line
  /// 一致を確認するため、同意済みかどうかを確実に永続化する。
  static Future<DateTime?> loadAiConsentAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_aiConsentAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// 同意ボタンが押された瞬間に呼ぶ (現在時刻を ISO8601 で保存)。
  static Future<void> saveAiConsentNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiConsentAtKey, DateTime.now().toIso8601String());
  }

  /// 主に main.dart の起動分岐用。null チェックを 1 関数に。
  static Future<bool> hasAiConsent() async {
    final at = await loadAiConsentAt();
    return at != null;
  }

  // --- Welcome gift (出生地+現住所を初めて揃えた新規完了者へ恒久クレジット3) ---
  //
  // 「新規完了者のみ」を守るため、本機能の初回到達時に既に birth+home が揃っていた
  // 既存ユーザーは eligible=false にして付与対象外にする。付与の冪等/farming 防止は
  // Worker 側 (端末固定キー) が担保。ここのフラグは付与トリガ判定 + バナー表示制御用。
  static const _welcomeBaselineKey = 'solara_welcome_baseline_set_v1';
  static const _welcomeEligibleKey = 'solara_welcome_eligible_v1';
  static const _welcomeGrantedKey = 'solara_welcome_granted_v1';
  static const _welcomeConsultUsedKey = 'solara_welcome_consult_used_v1';
  // バナー D (サインイン勧誘) を ✕ で閉じた永続フラグ。WelcomeGiftFlags には
  // 含めず独立 getter で読む (既存構造を壊さないため)。
  static const _welcomeSigninDismissedKey =
      'solara_welcome_signin_dismissed_v1';

  /// 本機能の初回到達時に 1 度だけベースラインを記録する (以後 no-op)。
  /// [profileCompleteNow] = その瞬間に birth+home が揃っているか。
  /// 既に揃っている既存ユーザーは eligible=false (付与対象外) になる。
  static Future<void> ensureWelcomeBaseline(bool profileCompleteNow) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_welcomeBaselineKey) == true) return;
    await prefs.setBool(_welcomeBaselineKey, true);
    await prefs.setBool(_welcomeEligibleKey, !profileCompleteNow);
  }

  static Future<WelcomeGiftFlags> loadWelcomeFlags() async {
    final prefs = await SharedPreferences.getInstance();
    return WelcomeGiftFlags(
      baselineSet: prefs.getBool(_welcomeBaselineKey) ?? false,
      eligible: prefs.getBool(_welcomeEligibleKey) ?? false,
      granted: prefs.getBool(_welcomeGrantedKey) ?? false,
      consultUsed: prefs.getBool(_welcomeConsultUsedKey) ?? false,
    );
  }

  /// 恒久クレジット付与が成功した (granted) ら呼ぶ。バナー C の表示条件になる。
  static Future<void> setWelcomeGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeGrantedKey, true);
  }

  /// 相談に進んだ or バナー C を閉じたら呼ぶ。以後バナー C を出さない。
  static Future<void> setWelcomeConsultUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeConsultUsedKey, true);
  }

  /// バナー D (サインイン勧誘) を ✕ で閉じたか。true なら以後 D を出さない。
  static Future<bool> loadWelcomeSigninDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeSigninDismissedKey) ?? false;
  }

  /// バナー D を ✕ で閉じたら呼ぶ。
  static Future<void> setWelcomeSigninDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeSigninDismissedKey, true);
  }

  // --- Forecast heatmap display settings ---

  /// ヒートマップ色モード: 'relative' | 'absolute' | 'category'
  static Future<String> loadForecastColorMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_forecastColorModeKey) ?? 'relative';
  }

  static Future<void> saveForecastColorMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_forecastColorModeKey, mode);
  }

  /// 高スコア側の色: 'green' | 'red'
  static Future<String> loadForecastHighColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_forecastHighColorKey) ?? 'green';
  }

  static Future<void> saveForecastHighColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_forecastHighColorKey, color);
  }

  /// Forecast 画面で最後に見た年オフセット（0-4）
  static Future<int> loadForecastYearOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_forecastYearOffsetKey) ?? 0).clamp(0, 4);
  }

  static Future<void> saveForecastYearOffset(int offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_forecastYearOffsetKey, offset.clamp(0, 4));
  }

  // --- Map style ---

  static Future<String?> loadMapStyleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mapStyleKey);
  }

  static Future<void> saveMapStyleId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mapStyleKey, id);
  }

  // --- Profile ---

  static Future<SolaraProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return SolaraProfile.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveProfile(SolaraProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, json.encode(profile.toJson()));
  }

  // --- Current cycle readings ---

  static Future<List<DailyReading>> loadCurrentReadings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentReadingsKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list
        .map((e) => DailyReading.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveCurrentReadings(List<DailyReading> readings) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(readings.map((r) => r.toJson()).toList());
    await prefs.setString(_currentReadingsKey, raw);
  }

  static Future<void> addReading(DailyReading reading) async {
    final readings = await loadCurrentReadings();
    // Replace if same date exists
    readings.removeWhere((r) => r.date == reading.date);
    readings.add(reading);
    // HTML: if (hist.length > 50) hist.length = 50
    if (readings.length > 50) {
      readings.removeRange(0, readings.length - 50);
    }
    await saveCurrentReadings(readings);
  }

  static Future<void> clearReadings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentReadingsKey);
  }

  /// Update synchronicity text for a specific reading date.
  static Future<void> updateSynchronicity(String date, String text) async {
    final readings = await loadCurrentReadings();
    for (final r in readings) {
      if (r.date == date) {
        r.synchronicity = text;
        break;
      }
    }
    await saveCurrentReadings(readings);
  }

  /// Update an existing reading (matched by date) with new reading text.
  /// 用途: /tarot API 応答後に Stella の生成テキストを保存する。
  static Future<void> updateReading(DailyReading updated) async {
    final readings = await loadCurrentReadings();
    for (final r in readings) {
      if (r.date == updated.date) {
        r.reading = updated.reading;
        // synchronicity はユーザー入力なので上書きしない
        break;
      }
    }
    await saveCurrentReadings(readings);
  }

  /// Remove a reading by date (used for the dev "reset today" button).
  /// 本番では呼ばれない想定。
  static Future<void> removeReadingByDate(String date) async {
    final readings = await loadCurrentReadings();
    readings.removeWhere((r) => r.date == date);
    await saveCurrentReadings(readings);
  }

  // --- Title Diagnosis persistence ---

  static const _titleKey = 'solara_title_data';
  static const _titleHistoryKey = 'solara_title_history';

  /// クラス変遷履歴の上限 (柱 3 原則: Free でも自分の記録を失わない、
  /// 上限はストレージ肥大を抑える技術フェイルセーフ)。
  /// 月 1 回取り直し前提で 60 件 = 5 年分。
  static const titleHistoryMax = 60;

  static Future<Map<String, dynamic>?> loadTitleData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_titleKey);
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveTitleData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_titleKey, json.encode(data));
  }

  /// クラス変遷履歴を新しい順 (savedAt 降順) で読込む。
  /// 各エントリ: {savedAt, axis, court, classEN, classJP, lightJP, shadowJP}
  static Future<List<Map<String, dynamic>>> loadTitleHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_titleHistoryKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = json.decode(raw) as List;
      final records = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      records.sort((a, b) {
        final ta = DateTime.tryParse(a['savedAt'] as String? ?? '');
        final tb = DateTime.tryParse(b['savedAt'] as String? ?? '');
        if (ta == null || tb == null) return 0;
        return tb.compareTo(ta);
      });
      return records;
    } catch (_) {
      return const [];
    }
  }

  /// 称号診断結果を履歴に追加する。
  /// 同じ axis+court は「変遷ではない」のでスキップ (連続同一クラス防止)。
  /// 上限超過は古いものから削除。
  static Future<void> addTitleHistoryEntry({
    required String axis,
    required String court,
    required String classEN,
    required String classJP,
    required String lightJP,
    required String shadowJP,
    String lightEN = '',
    String shadowEN = '',
  }) async {
    final list = (await loadTitleHistory()).toList();
    // 直近 (新しい順 1 件目) と同じクラスなら skip。
    if (list.isNotEmpty &&
        list.first['axis'] == axis &&
        list.first['court'] == court) {
      return;
    }
    list.insert(0, {
      'savedAt': DateTime.now().toIso8601String(),
      'axis': axis,
      'court': court,
      'classEN': classEN,
      'classJP': classJP,
      'lightJP': lightJP,
      'shadowJP': shadowJP,
      'lightEN': lightEN,
      'shadowEN': shadowEN,
    });
    if (list.length > titleHistoryMax) {
      list.removeRange(titleHistoryMax, list.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_titleHistoryKey, json.encode(list));
  }

  /// 履歴全削除 (Sanctuary 設定からの「すべて削除」用)。
  static Future<void> clearTitleHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_titleHistoryKey);
  }

  /// 指定 savedAt のエントリにメモを書き込む (200 字 cap、超過は切詰)。
  /// savedAt が一致するレコードが無ければ no-op (履歴削除後の遅延書込みを許容)。
  /// 称号変遷ギャラリーで「商号変更時の心境」を残す用途。
  static Future<void> updateTitleHistoryNote(
      String savedAt, String note) async {
    final list = (await loadTitleHistory()).toList();
    final idx = list.indexWhere((e) => e['savedAt'] == savedAt);
    if (idx < 0) return;
    final trimmed = note.characters.take(200).toString();
    list[idx] = {
      ...list[idx],
      'note': trimmed,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_titleHistoryKey, json.encode(list));
  }

  static Future<DailyReading?> getTodayReading() async {
    final dateStr = await logicalTodayKey();
    final readings = await loadCurrentReadings();
    for (final r in readings) {
      if (r.date == dateStr) return r;
    }
    return null;
  }

  /// タロットを最後に引いた「論理日」(YYYY-MM-DD)。未記録なら null。
  /// 2026-05-26 改修: 旧名 loadLastFreeTarotDay (全体運専用) のままだが、
  /// 意味は「Tarot 全体 (全体運/カテゴリ/Free/Pro 問わず) で最後に引いた論理日」
  /// に拡張。SharedPreferences キー (_lastFreeTarotDayKey) はそのまま再利用
  /// (旧データとの互換性維持、マイグレーション不要)。
  static Future<String?> loadLastFreeTarotDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastFreeTarotDayKey);
  }

  /// タロットを「今日」引いたものとして記録する。
  /// 単調更新: 既存値より新しい論理日のときだけ上書き。これにより、引いた後に
  /// リセット時刻を後ろへずらして論理日を過去へ戻し、再ドローする不正を防ぐ。
  ///
  /// 2026-05-26 改修: 全 Tarot draw (全体運/カテゴリ/Free/Pro) でこの単調ガードを
  /// 共通に使う。旧設計では「無料全体運のみ」だったが、新仕様「Tarot は Pro 含め
  /// 1日1回」を実現するため対象を拡大。関数名 markFreeTarotDrawn は互換性のため
  /// 維持 (内部実装と意味は『Tarot 全体』に拡張)。
  static Future<void> markFreeTarotDrawn() async {
    final prefs = await SharedPreferences.getInstance();
    final today = await logicalTodayKey();
    final last = prefs.getString(_lastFreeTarotDayKey);
    if (last == null || today.compareTo(last) > 0) {
      await prefs.setString(_lastFreeTarotDayKey, today);
    }
  }

  /// タロットを「今日 (論理日)」もう引いたか。
  /// 記録された論理日が現在の論理日以上なら true (= まだ同じ 1 日の中)。
  /// リセット時刻を変えて論理日を過去へ戻しても、より新しい記録が残るため
  /// 再ドローはブロックされる (= 論理日が前進したときだけ引ける)。
  ///
  /// 2026-05-26 改修: markFreeTarotDrawn と同様、全 Tarot draw 共通の単調ガード。
  static Future<bool> hasDrawnFreeTarotToday() async {
    final last = await loadLastFreeTarotDay();
    if (last == null) return false;
    final today = await logicalTodayKey();
    return last.compareTo(today) >= 0;
  }

  /// テスト用: 無料タロットの引き記録をクリア (再ドロー可能に戻す)。
  static Future<void> clearFreeTarotDay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastFreeTarotDayKey);
  }

  // --- Completed cycles ---

  static Future<List<GalaxyCycle>> loadCompletedCycles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_completedCyclesKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list
        .map((e) => GalaxyCycle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveCompletedCycle(GalaxyCycle cycle) async {
    final cycles = await loadCompletedCycles();
    cycles.add(cycle);
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(cycles.map((c) => c.toJson()).toList());
    await prefs.setString(_completedCyclesKey, raw);
  }

  /// 過去サイクルに含まれる reading の synchronicity (自由メモ) を更新する。
  ///
  /// 🔴 (2026-05-19) 過去 HISTORY のメモ編集用。
  /// GalaxyCycle 自体は刻星化後ほぼ不変だが、 ユーザー視点ではメモだけは
  /// 後から書き足したい — 「自分の記録は永久」原則を維持しつつ、 体験を
  /// 自然にするため。 構造的にはネストが深いが、 完了サイクルは実用上
  /// 数十件 (60 件 cap) で各 cycle も数 KB なので、 全 cycles を書き戻して
  /// も実害は無い (100ms 以内)。
  ///
  /// 該当 cycle / reading が見つからない場合は no-op (silent)。
  static Future<void> updateCompletedCycleReadingSynchronicity(
      String cycleId, String readingDate, String text) async {
    final cycles = await loadCompletedCycles();
    final cycleIdx = cycles.indexWhere((c) => c.id == cycleId);
    if (cycleIdx < 0) return;
    final cycle = cycles[cycleIdx];
    final readingIdx =
        cycle.readings.indexWhere((r) => r.date == readingDate);
    if (readingIdx < 0) return;
    cycle.readings[readingIdx].synchronicity = text;
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(cycles.map((c) => c.toJson()).toList());
    await prefs.setString(_completedCyclesKey, raw);
  }

  static Future<void> clearCurrentReadings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentReadingsKey);
  }

  // --- Lunar intentions ---

  static Future<LunarIntention?> loadIntention(String cycleId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_intentionKey}_$cycleId');
    if (raw == null) return null;
    return LunarIntention.fromJson(
        json.decode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveIntention(LunarIntention intention) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_intentionKey}_${intention.cycleId}',
      json.encode(intention.toJson()),
    );
  }

  /// 1日の基準時刻（0-23時）。この時刻を跨ぐと「今日」が更新される。
  /// 例: 3 に設定すると、深夜3時を日付の区切りとして扱う。
  static Future<int> loadDailyResetHour() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt(_dailyResetHourKey) ?? 0;
    return h.clamp(0, 23);
  }

  static Future<void> saveDailyResetHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyResetHourKey, hour.clamp(0, 23));
  }

  /// 1日の基準時刻 (分、0-59)。1 分単位ピッカーの導入で追加。
  /// 旧バージョンとの互換性のため、未保存時は 0 を返す。
  static Future<int> loadDailyResetMinute() async {
    final prefs = await SharedPreferences.getInstance();
    final m = prefs.getInt(_dailyResetMinuteKey) ?? 0;
    return m.clamp(0, 59);
  }

  static Future<void> saveDailyResetMinute(int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyResetMinuteKey, minute.clamp(0, 59));
  }

  // ── ハウスシステム ('placidus' | 'whole_sign')。Sanctuary「ハウスシステム」設定。
  static const _houseSystemKey = 'solara_house_system';
  static String _houseSystemCache = 'placidus';

  /// 直近に load/save したハウスシステムの同期キャッシュ。
  /// チャート取得 (fetchChart) が毎回 loadHouseSystem で更新するので、
  /// relocation popup の同期 build からも最新値を参照できる。
  static String get currentHouseSystem => _houseSystemCache;

  /// ハウスシステム設定を読み込む (未保存は 'placidus')。同期キャッシュも更新。
  static Future<String> loadHouseSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_houseSystemKey) ?? 'placidus';
    _houseSystemCache = v;
    return v;
  }

  /// ハウスシステム設定を保存する。同期キャッシュも即時更新。
  static Future<void> saveHouseSystem(String system) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_houseSystemKey, system);
    _houseSystemCache = system;
  }

  /// Sanctuary「ホロスコープのオーブ設定」で設定されたアスペクト/パターンの
  /// オーブ値を読み込む。
  /// SharedPreferences key: 'solara_orb_settings' (JSON)
  /// 戻り値: アスペクト 8 種 {conjunction, opposition, trine, square, sextile,
  ///         quincunx, semisextile, semisquare} + パターン 5 種 {grandtrine,
  ///         tsquare_opp, tsquare_sq, yod_sextile, yod_quincunx} の各 orb（°）。
  /// 未保存時はデフォルト値（Sanctuary の初期値と同じ）を返す。
  static Future<Map<String, double>> loadOrbSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('solara_orb_settings');
    final defaults = <String, double>{
      // アスペクト 8 種
      'conjunction': 2, 'opposition': 2, 'trine': 2, 'square': 2,
      'sextile': 2, 'quincunx': 2, 'semisextile': 1, 'semisquare': 1,
      // パターン 5 種 (horo_constants.dart patternOrbSettings と一致)
      'grandtrine': 3, 'tsquare_opp': 3, 'tsquare_sq': 2.5,
      'yod_sextile': 2.5, 'yod_quincunx': 1.5,
    };
    if (raw == null) return defaults;
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      final result = Map<String, double>.from(defaults);
      for (final k in m.keys) {
        final v = m[k];
        if (v is num) result[k] = v.toDouble();
      }
      return result;
    } catch (_) {
      return defaults;
    }
  }

  /// リセット時刻 (「1日の開始時刻」設定) を考慮した「今日」の論理日キー
  /// (YYYY-MM-DD)。現在時刻がリセット時刻 (hour:minute) より前なら前日を返す。
  /// タロット日次 (getTodayReading / hasDrawnFreeTarotToday) と overlay 重複防止で使用。
  /// ※ Horo の星読みは意図的に 0 時基準 (本キーを使わない)。
  static Future<String> logicalTodayKey() async {
    final hour = await loadDailyResetHour();
    final minute = await loadDailyResetMinute();
    var now = DateTime.now();
    final beforeReset =
        now.hour < hour || (now.hour == hour && now.minute < minute);
    if (beforeReset) {
      now = now.subtract(const Duration(days: 1));
    }
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Track which overlay was shown today to avoid re-showing.
  static Future<bool> wasOverlayShownToday(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final day = await logicalTodayKey();
    final key = '${_overlayShownKey}_${type}_$day';
    return prefs.getBool(key) ?? false;
  }

  static Future<void> markOverlayShown(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final day = await logicalTodayKey();
    final key = '${_overlayShownKey}_${type}_$day';
    await prefs.setBool(key, true);
  }

  /// 端末日付 (常に 0 時切替) の "今日" キー (YYYY-MM-DD)。
  /// Sanctuary リセット時刻設定の影響を受けない。
  /// Daily Transit Badge / Galaxy 3 演出 / popup Header glow が使用。
  static String localDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 端末 0 時基準で「今日この type の演出を表示したか」を返す。
  /// 2026-05-29 新設: Sanctuary subtitle と整合させるための独立系統。
  static Future<bool> wasLocalOverlayShownToday(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_localOverlayShownKey}_${type}_${localDateKey()}';
    return prefs.getBool(key) ?? false;
  }

  /// 端末 0 時基準で「今日この type の演出を表示した」と記録する。
  static Future<void> markLocalOverlayShown(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_localOverlayShownKey}_${type}_${localDateKey()}';
    await prefs.setBool(key, true);
  }

  /// Not today 押下回数（サイクルID単位で保存）
  static Future<int> getNotTodayCount(String cycleId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('not_today_count_$cycleId') ?? 0;
  }

  static Future<void> incrementNotTodayCount(String cycleId) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('not_today_count_$cycleId') ?? 0;
    await prefs.setInt('not_today_count_$cycleId', count + 1);
  }

  // ─── 月イベント通知 (A: MoonNotificationService) ──────────────
  // アプリ側マスタスイッチ (Sanctuary トグル) と、ソフトアスクの back-off 状態。
  // OS 許諾は別 (flutter_local_notifications が司る)。両方 ON で初めて schedule する。

  static const _notificationsEnabledKey = 'moon_notifications_enabled';
  static const _notifSoftAskDeclinesKey = 'moon_notif_softask_declines';
  static const _notifSoftAskCycleKey = 'moon_notif_softask_cycle';

  /// 通知マスタスイッチ (Sanctuary トグル)。デフォルト false (オプトイン)。
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
  }

  /// ソフトアスクを「今はしない」で断られた累計回数 (上限超過で以後出さない)。
  static Future<int> getNotifSoftAskDeclines() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notifSoftAskDeclinesKey) ?? 0;
  }

  static Future<void> incrementNotifSoftAskDeclines() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getInt(_notifSoftAskDeclinesKey) ?? 0;
    await prefs.setInt(_notifSoftAskDeclinesKey, n + 1);
  }

  /// declines を直接設定 (0=リセット / 2=明示 OFF でソフトアスク抑制)。
  static Future<void> setNotifSoftAskDeclines(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notifSoftAskDeclinesKey, value);
  }

  /// ソフトアスクを最後に出したサイクル ID (= 同一サイクルで二度出さない)。
  static Future<String?> getNotifSoftAskCycle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_notifSoftAskCycleKey);
  }

  static Future<void> setNotifSoftAskCycle(String cycleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notifSoftAskCycleKey, cycleId);
  }

  // ─── Consultation History (Phase 2-4) ────────────────────────
  // 設計: docs/pro_candidates.md §7.2 Stage 4 + §7.3 柱3
  // Free でも自分の記録を永久に失わない。Pro 機能は検索・フィルタ (記録を使う道具)。

  /// 履歴全件を新しい順 (savedAt 降順) で読込む。
  static Future<List<ConsultationRecord>> loadConsultationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_consultationHistoryKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = json.decode(raw) as List;
      final records = list
          .map((e) =>
              ConsultationRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      records.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return records;
    } catch (_) {
      // 破損データは捨てて空に戻す (ユーザーの記録より整合性を優先)。
      return const [];
    }
  }

  /// 履歴を 1 件追加 (新しい順で先頭、上限超過分は古いものから削除)。
  static Future<void> addConsultationRecord(ConsultationRecord record) async {
    final list = (await loadConsultationHistory()).toList();
    // id 重複は新規で上書き (再保存のケース対策)。
    list.removeWhere((r) => r.id == record.id);
    list.insert(0, record);
    if (list.length > consultationHistoryMax) {
      list.removeRange(consultationHistoryMax, list.length);
    }
    await _writeConsultationHistory(list);
  }

  /// id 指定でお気に入りフラグを設定。見つからない場合は no-op。
  static Future<void> setConsultationFavorite(String id, bool favorite) async {
    final list = (await loadConsultationHistory()).toList();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(favorite: favorite);
    await _writeConsultationHistory(list);
  }

  /// id 指定で 1 件削除。見つからない場合は no-op。
  static Future<void> deleteConsultationRecord(String id) async {
    final list = (await loadConsultationHistory()).toList();
    list.removeWhere((r) => r.id == id);
    await _writeConsultationHistory(list);
  }

  /// 履歴全削除 (Sanctuary 設定からの「すべて削除」用)。
  static Future<void> clearConsultationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consultationHistoryKey);
  }

  static Future<void> _writeConsultationHistory(
      List<ConsultationRecord> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(list.map((r) => r.toJson()).toList());
    await prefs.setString(_consultationHistoryKey, raw);
  }

  // --- Consultation 候補 無連続 avoid-window (C-2) ---

  /// theme×scope キーの直近提示地名 (無連続用)。新規相談の開始時に読み、avoid として送る。
  static Future<List<String>> getConsultationAvoid(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_consultationAvoidKey);
    if (raw == null) return const [];
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      final list = map[key];
      if (list is List) {
        return list.map((e) => e.toString()).toList(growable: false);
      }
    } catch (_) {
      // 壊れたデータは無視 (no-repeat は best-effort、失敗で相談を止めない)。
    }
    return const [];
  }

  /// 提示した地名を window に積む (最新を末尾)。最新 [maxN] 件だけ残す。
  /// maxN = Pro 9 / Free 6 (呼び出し側で決定)。
  static Future<void> pushConsultationAvoid(
      String key, String name, int maxN) async {
    if (name.isEmpty || maxN <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_consultationAvoidKey);
    Map<String, dynamic> map;
    try {
      map = raw == null
          ? <String, dynamic>{}
          : (json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      map = <String, dynamic>{};
    }
    final cur = (map[key] is List)
        ? (map[key] as List).map((e) => e.toString()).toList()
        : <String>[];
    cur.remove(name); // 既出なら末尾へ移動 (最新化)
    cur.add(name);
    if (cur.length > maxN) {
      cur.removeRange(0, cur.length - maxN); // 最新 maxN 件に trim
    }
    map[key] = cur;
    await prefs.setString(_consultationAvoidKey, json.encode(map));
  }

  /// avoid-window 全消去 (Sanctuary「すべて削除」と一緒に呼ぶ用)。
  static Future<void> clearConsultationAvoid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consultationAvoidKey);
  }

  // --- 画面復元スナップショット (Android プロセス死対策) ---

  /// 現在の画面状態スナップショットを保存する (paused 時に呼ぶ)。
  /// snap 例: {savedAt: ISO8601, tab: 0, map: {search: {...}}}
  static Future<void> saveRestoreSnapshot(Map<String, dynamic> snap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_restoreSnapshotKey, json.encode(snap));
  }

  /// 保存済みスナップショットを読み込む (コールド起動時)。無ければ null。
  static Future<Map<String, dynamic>?> loadRestoreSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_restoreSnapshotKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null; // 壊れたデータは無視
    }
  }

  /// スナップショットを破棄する (warm resume 時 / 復元消費後)。
  static Future<void> clearRestoreSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_restoreSnapshotKey);
  }
}
