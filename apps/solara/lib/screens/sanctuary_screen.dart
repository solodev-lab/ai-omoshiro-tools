import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'horoscope/horo_antique_icons.dart';
// slang も AppLocale を定義するため、app_locale.dart の AppLocale と衝突しないよう hide。
import '../i18n/strings.g.dart' hide AppLocale;
import '../utils/app_locale.dart';
import '../utils/app_text_scale.dart';
import '../utils/consultation_api.dart' show ConsultationCreditStatus;
import '../utils/consultation_credits.dart';
import '../utils/moon_notification_service.dart';
import '../utils/pro_status.dart';
import '../utils/purchases_service.dart';
import '../utils/solara_i18n.dart' show isEnLocale;
import '../utils/solara_storage.dart';
import '../utils/title_data.dart' as title_data;
import '../widgets/class_card.dart';
import '../widgets/pro_unlock_dialog.dart';
import '../widgets/sanctuary_account_section.dart';
import '../widgets/tap_to_unfocus.dart';
import 'consultation/consultation_credit_sheet.dart';
import 'consultation/consultation_history_screen.dart';
import 'paywall_screen.dart';
import 'sanctuary/sanctuary_orb_overlay.dart';
import 'sanctuary/sanctuary_profile_editor.dart';
import 'sanctuary/sanctuary_reset_hour_picker.dart';
import 'sanctuary/sanctuary_settings_pickers.dart';
import 'sanctuary/sanctuary_title_diagnosis.dart';
import 'sanctuary/class_share_card.dart';
import 'sanctuary/sanctuary_home_editor.dart';
import 'sanctuary/sanctuary_legal_menu.dart';
import 'sanctuary/title_history_screen.dart';

class SanctuaryScreen extends StatefulWidget {
  const SanctuaryScreen({super.key});

  @override
  State<SanctuaryScreen> createState() => _SanctuaryScreenState();
}

class _SanctuaryScreenState extends State<SanctuaryScreen> {
  SolaraProfile? _profile;
  bool _loading = true;

  // Stella/タロット クレジット残は ConsultationCredits.instance.status から読む
  // (ローカル state には持たない)。app lifecycle resume の refresh は main.dart の
  // SolaraHome に集約 (各画面で個別 observer を持たない)。

  // Title diagnosis results
  String? _titleLight;
  String? _titleShadow;
  String? _titleLightEN;
  String? _titleShadowEN;
  String? _titleClassEN;
  String? _titleClassJP;
  String? _titleAxis;
  String? _titleCourt;
  bool _titleFlipped = false;
  // やり直し回数 (Free: 1回まで、Pro: 無制限) - Pro 判定は未実装、現状 Free 固定
  int _titleRedoCount = 0;
  static const int _kFreeRedoLimit = 1;

  // Astrology settings
  String _houseSystem = 'placidus';
  bool _houseSelectOpen = false;

  // 1日の基準時刻 (hour 0-23, minute 0-59、1 分単位)。この時刻を跨ぐとタロットの
  // 「1日1回」と月相 overlay の論理日が更新される (星読みは 0 時基準で本設定の対象外)。
  int _dailyResetHour = 0;
  int _dailyResetMinute = 0;

  // Orb values (アスペクト 8 種 + パターン 5 種)。
  // パターン 5 種を含めないと _loadSettings の containsKey ガードで
  // 保存済みパターンオーブが読み戻されない (overlay 再表示でデフォルトに戻る)。
  final Map<String, double> _orbValues = {
    'conjunction': 2, 'opposition': 2, 'trine': 2, 'square': 2, 'sextile': 2,
    'quincunx': 2, 'semisextile': 1, 'semisquare': 1,
    'grandtrine': 3, 'tsquare_opp': 3, 'tsquare_sq': 2.5,
    'yod_sextile': 2.5, 'yod_quincunx': 1.5,
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSettings();
    // Pro 切替 (購入 / DEV toggle) で背景・枠・残数表示を即時反映。
    ProStatus.instance.addListener(_onProChanged);
    // ConsultationCredits singleton の更新通知を購読 (= notifyListeners で rebuild)。
    // 自分から fetch はしない: 起動時 refresh は main.dart、消費/購入時 refresh は
    // 各イベント側 (相談実行・Tarot 引く・購入完了ポーリング) で発火される。
    ConsultationCredits.instance.addListener(_onCreditsChanged);
  }

  @override
  void dispose() {
    ProStatus.instance.removeListener(_onProChanged);
    ConsultationCredits.instance.removeListener(_onCreditsChanged);
    super.dispose();
  }

  void _onProChanged() {
    if (mounted) setState(() {});
  }

  void _onCreditsChanged() {
    if (mounted) setState(() {});
  }

  /// 現在のクレジット残 (build から参照)。null = 未取得/オフライン。
  ConsultationCreditStatus? get _credits => ConsultationCredits.instance.status;

  /// クレジット残バッジタップ → 購入シートを開く。
  /// 成功時はシート側のポーリング (consultation_credit_sheet._pollUntilGranted) が
  /// ConsultationCredits.instance.refresh() を呼ぶので、ここでは即 refresh しない。
  Future<void> _openCreditPurchase() async {
    await showConsultationCreditSheet(context);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // ハウスシステム設定 (load 経由で同期キャッシュも prime)。
    final house = await SolaraStorage.loadHouseSystem();
    if (mounted) setState(() => _houseSystem = house);
    // HTML: localStorage('solara_orb_settings')
    final orbRaw = prefs.getString('solara_orb_settings');
    if (orbRaw != null) {
      final saved = json.decode(orbRaw) as Map<String, dynamic>;
      for (final k in saved.keys) {
        if (_orbValues.containsKey(k)) _orbValues[k] = (saved[k] as num).toDouble();
      }
      if (mounted) setState(() {});
    }
    final h = await SolaraStorage.loadDailyResetHour();
    final m = await SolaraStorage.loadDailyResetMinute();
    if (mounted) {
      setState(() {
        _dailyResetHour = h;
        _dailyResetMinute = m;
      });
    }
  }

  Future<void> _loadProfile() async {
    final p = await SolaraStorage.loadProfile();
    final td = await SolaraStorage.loadTitleData();
    setState(() {
      _profile = p;
      _loading = false;
      if (td != null) {
        _titleLight = td['lightJP'] as String?;
        _titleShadow = td['shadowJP'] as String?;
        _titleLightEN = td['lightEN'] as String?;
        _titleShadowEN = td['shadowEN'] as String?;
        _titleClassEN = td['classEN'] as String?;
        _titleClassJP = td['classJP'] as String?;
        _titleAxis = td['axis'] as String?;
        _titleCourt = td['court'] as String?;
        _titleRedoCount = (td['redoCount'] as int?) ?? 0;
      }
    });
  }

  void _openProfileEditor() async {
    final result = await Navigator.of(context).push<SolaraProfile>(
      MaterialPageRoute(
        builder: (_) => SanctuaryProfileEditorPage(profile: _profile),
      ),
    );
    if (result != null) {
      await SolaraStorage.saveProfile(result);
      // HTML: saveBirthInfo() — auto-update title if sun/moon sign changed
      if (_titleLight != null && _profile != null) {
        final oldSun = title_data.getSunSign(_profile!.birthDate);
        final oldMoon = title_data.getMoonSign(_profile!.birthDate, _profile!.birthTime);
        final newSun = title_data.getSunSign(result.birthDate);
        final newMoon = title_data.getMoonSign(result.birthDate, result.birthTime);
        if (newSun != oldSun || newMoon != oldMoon) {
          final t144 = title_data.title144[newSun]?[newMoon];
          final sunA = title_data.sunAdj[newSun];
          final moonN = title_data.moonNoun[newMoon];
          final newLight = t144?['light'] ?? (sunA?['jp'] ?? '');
          final newShadow = t144?['shadow'] ?? '${sunA?['jp'] ?? ''}${moonN?['jp'] ?? ''}';
          final enFallback = '${sunA?['en'] ?? ''} ${moonN?['en'] ?? ''}';
          final newLightEN = t144?['lightEN'] ?? (sunA?['en'] ?? '');
          final newShadowEN = t144?['shadowEN'] ?? enFallback;
          final updated = {
            'lightJP': newLight, 'shadowJP': newShadow,
            'lightEN': newLightEN, 'shadowEN': newShadowEN,
            'classEN': _titleClassEN ?? '', 'classJP': _titleClassJP ?? '',
            'axis': _titleAxis ?? '', 'court': _titleCourt ?? '',
          };
          await SolaraStorage.saveTitleData(updated);
          setState(() {
            _titleLight = newLight; _titleShadow = newShadow;
            _titleLightEN = newLightEN; _titleShadowEN = newShadowEN;
          });
        }
      }
      setState(() => _profile = result);
    }
  }

  void _openShareCard() {
    if (_titleAxis == null || _titleCourt == null) return;
    final sunSign = title_data.getSunSign(_profile?.birthDate ?? '');
    final moonSign = title_data.getMoonSign(_profile?.birthDate ?? '', _profile?.birthTime ?? '');
    final sunA = title_data.sunAdj[sunSign];
    final moonN = title_data.moonNoun[moonSign];
    final t144 = title_data.title144[sunSign]?[moonSign];
    // 一言 Light / Shadow (フォールバック: sunA.jp + moonN.jp)
    final titleLight = t144?['light'] ?? '${sunA?['jp'] ?? ''}${moonN?['jp'] ?? ''}';
    final titleShadow = t144?['shadow'] ?? '${sunA?['jp'] ?? ''}${moonN?['jp'] ?? ''}';
    final enFallback = '${sunA?['en'] ?? ''} ${moonN?['en'] ?? ''}';
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClassShareCardPage(
        axis: _titleAxis!, court: _titleCourt!,
        titleLightJP: titleLight,
        titleShadowJP: titleShadow,
        titleLightEN: t144?['lightEN'] ?? enFallback,
        titleShadowEN: t144?['shadowEN'] ?? enFallback,
        titleEN: enFallback,
      ),
    ));
  }

  void _startDiagnosis() async {
    // 既に診断済み (= やり直し) なら、現在のクラスを「前の結果」として診断画面に渡す。
    // Free プラン: redoCount >= 1 なら無効化済みなので、ここに到達する時点で redoCount == 0
    final hasPrevious = _titleLight != null && _titleAxis != null && _titleCourt != null;
    final isRedo = hasPrevious; // 初回 == previous なし、2回目以降 == previous あり
    final previousResult = hasPrevious
        ? <String, String>{
            'lightJP': _titleLight ?? '',
            'shadowJP': _titleShadow ?? '',
            'classEN': _titleClassEN ?? '',
            'classJP': _titleClassJP ?? '',
            'axis': _titleAxis ?? '',
            'court': _titleCourt ?? '',
          }
        : null;

    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => SanctuaryTitleDiagnosisPage(
          profile: _profile,
          previousResult: previousResult,
        ),
      ),
    );
    if (result != null) {
      // やり直し時のみ redoCount をインクリメント (初回診断は 0 のまま)
      final newRedoCount = isRedo ? _titleRedoCount + 1 : _titleRedoCount;
      final dataToSave = <String, dynamic>{
        ...result,
        'redoCount': newRedoCount,
      };
      await SolaraStorage.saveTitleData(dataToSave);
      // C4 (柱 3): クラス変遷履歴に追記する。axis+court が同一なら storage 側で skip。
      await SolaraStorage.addTitleHistoryEntry(
        axis: result['axis'] ?? '',
        court: result['court'] ?? '',
        classEN: result['classEN'] ?? '',
        classJP: result['classJP'] ?? '',
        lightJP: result['lightJP'] ?? '',
        shadowJP: result['shadowJP'] ?? '',
        lightEN: result['lightEN'] ?? '',
        shadowEN: result['shadowEN'] ?? '',
      );
      setState(() {
        _titleLight = result['lightJP'];
        _titleShadow = result['shadowJP'];
        _titleLightEN = result['lightEN'];
        _titleShadowEN = result['shadowEN'];
        _titleClassEN = result['classEN'];
        _titleClassJP = result['classJP'];
        _titleAxis = result['axis'];
        _titleCourt = result['court'];
        _titleRedoCount = newRedoCount;
      });
    }
  }

  /// Pro として称号を受け直す前に表示する案内ダイアログ。
  ///
  /// Free の 1 回再診断では出さず、Pro 機能として「何度でも受け直せる」場合のみ表示する。
  /// 伝えたいこと:
  ///   - Pro は称号を何度でも受け取り直せる (毎日でも可)
  ///   - 太陽星座×月星座から導かれる「二つ名」は不変、変わるのは設問で決まる称号(クラス)のみ
  ///   - 内的/外的な変化のタイミングで受け直すと「称号 変遷」で成長を辿れる
  /// 下部に [戻る]（キャンセル）と [OK]（そのまま診断へ）を配置する。
  void _showRediagnoseProGuide(BuildContext anchorCtx) {
    showDialog<void>(
      context: anchorCtx,
      barrierColor: const Color(0x99000000),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            decoration: BoxDecoration(
              color: const Color(0xEE0C0C1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x44F6BD60)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── ヘッダ ──
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFF9D976), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.sanctuary.guide.title,
                        style: const TextStyle(
                          color: Color(0xFFF6D98A),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── 本文 (枠内スクロール) ──
                // ヘッダと下部ボタンは固定し、本文テキストだけを縦スクロールさせる。
                // 小さい端末や文字サイズ拡大時に本文がボタンを画面外へ押し出して
                // 押せなくなる問題を防ぐため、Flexible + SingleChildScrollView で
                // 枠内に収める (枠そのものの見た目は変えない)。
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── リード文 (Pro 特典) ──
                        Text(
                          t.sanctuary.guide.lead,
                          style: const TextStyle(
                            color: Color(0xFFEAEAEA),
                            fontSize: 14.5,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ── 変わるもの / 変わらないもの ──
                        Text(
                          t.sanctuary.guide.body1,
                          style: const TextStyle(
                            color: Color(0xFFC9C9D4),
                            fontSize: 13,
                            height: 1.75,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ── 推奨される使い方 (変遷で成長を辿る) ──
                        Text(
                          t.sanctuary.guide.body2,
                          style: const TextStyle(
                            color: Color(0xFFC9C9D4),
                            fontSize: 13,
                            height: 1.75,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.sanctuary.guide.body3,
                          style: const TextStyle(
                            color: Color(0xFFC9C9D4),
                            fontSize: 13,
                            height: 1.75,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                // ── 下部ボタン: 戻る / OK ──
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFACACAC),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(t.sanctuary.guide.back, style: const TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _startDiagnosis();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'OK',
                              style: TextStyle(
                                color: Color(0xFF0A0A14),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openHomeEditor() async {
    final result = await Navigator.of(context).push<SolaraProfile>(
      MaterialPageRoute(
        builder: (_) => SanctuaryHomeEditorPage(profile: _profile),
      ),
    );
    if (result != null) {
      await SolaraStorage.saveProfile(result);
      setState(() => _profile = result);
      // HTML: syncHomeToVP(p) — sync home to VP slots and locations
      if (result.homeName.isNotEmpty) {
        await _syncHomeToVP(result);
      }
    }
  }

  /// HTML: syncHomeToVP(profile) — sync home to solara_vp_slots and solara_locations
  Future<void> _syncHomeToVP(SolaraProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in ['solara_vp_slots', 'solara_locations']) {
      List<dynamic> slots = [];
      final raw = prefs.getString(key);
      if (raw != null) { try { slots = json.decode(raw) as List; } catch (_) {} }
      final homeSlot = {'name': profile.homeName, 'lat': profile.homeLat, 'lng': profile.homeLng, 'icon': '🏠', 'isHome': true};
      if (slots.isNotEmpty && (slots[0] as Map)['isHome'] == true) {
        slots[0] = homeSlot;
      } else {
        slots.insert(0, homeSlot);
        if (slots.length > 5) slots = slots.sublist(0, 5);
      }
      await prefs.setString(key, json.encode(slots));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: _bgDecoration,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFF9D976))),
      );
    }

    final hasProfile = _profile?.isComplete ?? false;
    final profileName = _profile?.name ?? '';
    final isPro = ProStatus.instance.isPro;

    return TapToUnfocus(
      child: Container(
      decoration: isPro ? _proBgDecoration : _bgDecoration,
      child: SafeArea(
        child: SingleChildScrollView(
          // HTML: .sanctuary-content { padding:56px 20px 100px } — SafeArea handles ~44px top
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── クレジット残 + Profile (Pro はアンティーク金枠で囲む) ──
                  _buildTopHeader(isPro, profileName),
                  const SizedBox(height: 20),

                  // ── ✦ Stellar Profile ──
                  _buildStellarProfileSection(hasProfile),
                  const SizedBox(height: 20),

                  // ── ✦ Title Diagnosis ──
                  _buildTitleDiagnosisSection(hasProfile),
                  const SizedBox(height: 20),

                  // ── ✦ Records (Phase 2-4) ──
                  // 相談履歴の閲覧エントリ。新規相談の入口ではない (それは
                  // Map / Daily Transit popup 側、§7.2 Stage 1 入口 1/2)。
                  _buildRecordsSection(),
                  const SizedBox(height: 20),

                  // ── ✦ Account (Phase 2-9 Sign in 統合) ──
                  // Sign in は任意。サインインで RevenueCat appUserID が
                  // 固定 uid になり端末間 Pro 復元が安定する。
                  // 🔴 const にしない: const widget は祖先が再ビルドされてもスキップ
                  // されるため、言語切替時に t.account.* が旧ロケールのまま残る
                  // (slang global t 対策・main.dart の _onLocaleChanged と対)。
                  SanctuaryAccountSection(),
                  const SizedBox(height: 20),

                  // ── ✦ Cosmic Pro ──
                  _buildCosmicProSection(),
                  const SizedBox(height: 20),

                  // ── ✦ Astrology ──
                  _buildAstrologySection(),
                  const SizedBox(height: 20),

                  // ── ✦ App ──
                  _buildAppSection(),
                  const SizedBox(height: 20),

                  // ── Version ──
                  const Center(
                    child: Text('Solara v1.0.0 · Made with ✦',
                      style: TextStyle(fontSize: 15, color: Color(0x59ACACAC))), // rgba(172,172,172,0.35)
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  // ── 最上段: クレジット残 + Profile (Cosmic Pro はアンティーク金枠で囲む) ──
  Widget _buildTopHeader(bool isPro, String profileName) {
    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCreditRow(isPro),
        const SizedBox(height: 12),
        _buildProfileRow(profileName),
      ],
    );
    if (!isPro) return inner;
    // Cosmic Pro: 金の二重枠 (アンティーク感) + ほのかな金グロー + 四隅の星装飾。
    final frame = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x33F9D976), Color(0x0FF9D976)],
        ),
        border: Border.all(color: const Color(0x80F9D976), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x33F9D976), blurRadius: 26, spreadRadius: 1),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xB3F9D976)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0x14F9D976), Color(0x00F9D976)],
          ),
        ),
        child: inner,
      ),
    );
    // 四隅にアンティークの星 (8-point) を添えて豪華に。
    const corner = AntiqueGlyph(
        icon: AntiqueIcon.pattern, size: 16, color: Color(0xFFF9D976), glow: true);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        frame,
        const Positioned(top: 3, left: 3, child: corner),
        const Positioned(top: 3, right: 3, child: corner),
        const Positioned(bottom: 3, left: 3, child: corner),
        const Positioned(bottom: 3, right: 3, child: corner),
      ],
    );
  }

  // クレジット残 1 行。
  // Pro: 「Pro 週次残 X/100 (月曜リセット)」+ 購入残。タップで購入シート。
  //      (2026-05-27 〜 Pro 週次キャップ導入。旧 "Unlimited Credits" 表示は撤去)
  // 非 Pro: 無料週次残 + 購入残。タップで購入シート。
  Widget _buildCreditRow(bool isPro) {
    final c = _credits;
    if (c == null) return const SizedBox.shrink();
    final pur = c.purchasedBalance ?? 0;
    final String label;
    if (isPro) {
      // クライアントは Pro と思っているが、サーバから proRemaining/proLimit が null で
      // 返ってきているケース (Pro 購入直後の RC Webhook 反映遅延 + reconcile も間に合わず、
      // 等) は「0/0」と誤表示せず「同期中」を出す。次の refresh() で正しい値に追従する。
      final hasProData = c.proRemaining != null && c.proLimit != null;
      if (hasProData) {
        // 月曜リセットを明示。Pro 100/週 を使い切っても購入残で続行可能。
        label = t.sanctuary.creditPro(
            remaining: c.proRemaining!, limit: c.proLimit!, pur: pur);
      } else {
        label = t.sanctuary.creditProSyncing(pur: pur);
      }
    } else {
      final free = c.freeRemaining ?? 0;
      label = t.sanctuary.creditFree(free: free, pur: pur);
    }
    // タップで購入シートを開く（追加クレジットの導線）。InkWell で残バッジ全面を反応域に。
    // Pro でも購入導線を出す: 週次キャップ到達後のフォールバック消費先。
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openCreditPurchase,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isPro ? const Color(0x0FF9D976) : const Color(0x0DFFFFFF),
            border: Border.all(
                color: isPro ? const Color(0x40F9D976) : const Color(0x1AFFFFFF)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: isPro
                        ? const Color(0xFFF3E6C0)
                        : const Color(0xFFEAEAEA),
                  ),
                ),
              ),
              const Icon(Icons.add_circle_outline,
                  size: 18, color: Color(0xFFF9D976)),
            ],
          ),
        ),
      ),
    );
  }

  // プロフィールのオーブ。Free=金の8芒星、Pro=太陽グリフ + 二重リング + 周囲に
  // 小さな星 (コンステレーション風) で豪華に差別化。
  Widget _buildProfileOrb(bool isPro) {
    if (!isPro) {
      return Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0x40F9D976), Color(0x0AF9D976)],
            stops: [0.0, 0.7],
          ),
          border: Border.all(color: const Color(0x40F9D976)),
        ),
        child: const Center(
          child: AntiqueGlyph(
              icon: AntiqueIcon.pattern, size: 24, color: Color(0xFFF9D976)),
        ),
      );
    }
    // Cosmic Pro: 豪華なコンステレーション・オーブ。
    return SizedBox(
      width: 62, height: 62,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 外周リング + グロー
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0x59F9D976), Color(0x0AF9D976)],
                stops: [0.0, 0.74],
              ),
              border: Border.all(color: const Color(0x99F9D976), width: 1.3),
              boxShadow: const [BoxShadow(color: Color(0x4DF9D976), blurRadius: 18)],
            ),
          ),
          // 内側の細いリング
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x40F9D976)),
            ),
          ),
          // 中央: 太陽グリフ (光条あり)
          const AntiqueGlyph(
              icon: AntiqueIcon.planets, size: 30, color: Color(0xFFF9D976)),
          // 周囲の小さな星 (さみしくないように)
          const Positioned(top: 5, right: 11, child: AntiqueGlyph(
              icon: AntiqueIcon.pattern, size: 8, color: Color(0xCCF9D976))),
          const Positioned(bottom: 7, left: 9, child: AntiqueGlyph(
              icon: AntiqueIcon.pattern, size: 6, color: Color(0x99F9D976))),
          const Positioned(bottom: 12, right: 8, child: AntiqueGlyph(
              icon: AntiqueIcon.pattern, size: 5, color: Color(0x80F9D976))),
        ],
      ),
    );
  }

  // ── Profile Row ──
  // HTML: .profile-row { display:flex; align-items:center; gap:14px; }
  Widget _buildProfileRow(String name) {
    return Row(
      children: [
        _buildProfileOrb(ProStatus.instance.isPro),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HTML: .profile-name-big { font-size:20px; font-weight:700; }
              Text(
                name.isEmpty ? 'Guest' : name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA)),
              ),
              const SizedBox(height: 2),
              // HTML: .profile-tier { font-size:12px; color:#ACACAC; margin-top:2px; }
              Text(
                ProStatus.instance.isPro ? '✦ Cosmic Pro' : 'Free Tier · Cosmic Journey',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: ProStatus.instance.isPro ? FontWeight.w600 : FontWeight.w400,
                  color: ProStatus.instance.isPro ? const Color(0xFFF9D976) : const Color(0xFFACACAC),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── ✦ Stellar Profile Section ──
  Widget _buildStellarProfileSection(bool hasProfile) {
    // プライバシー: 誕生日・住所の値は一覧に出さず「設定済み/未設定」のみ表示
    // (行はタップで編集できるよう残す)。
    final birthVal = hasProfile ? t.sanctuary.set : t.sanctuary.unset;
    final homeSet = _profile != null && _profile!.homeName.isNotEmpty;
    return _SettingsGroup(
      label: '✦ Stellar Profile',
      children: [
        _SettingsItem(
          icon: Icons.auto_awesome,
          text: t.sanctuary.birthInfo,
          value: birthVal,
          onTap: _openProfileEditor,
        ),
        _SettingsItem(
          icon: Icons.home_outlined,
          text: t.sanctuary.home,
          value: homeSet ? t.sanctuary.set : t.sanctuary.unset,
          onTap: _openHomeEditor,
        ),
      ],
    );
  }

  // ── ✦ Title Diagnosis Section ──
  Widget _buildTitleDiagnosisSection(bool hasProfile) {
    return _SettingsGroup(
      label: '✦ Title Diagnosis',
      children: [
        // Title card (if diagnosed)
        if (_titleLight != null) ...[
          // 2026-05-12 SHADOW flip 復活: 一言シャドー（10〜18文字）に短縮したことで
          // Solara イメージとの整合性が取れた為、再有効化。
          // タップで LIGHT ↔ SHADOW をトグル。
          // シャドーは「気付いた人だけ」が見れる隠し要素 → タップ案内は出さない。
          GestureDetector(
            onTap: () => setState(() => _titleFlipped = !_titleFlipped),
            child: _buildTitleFlipCard(),
          ),
          const SizedBox(height: 16),
        ],
        // HTML: #titleStartBtn — gold button (shown when not yet diagnosed)
        if (_titleLight == null) ...[
          // HTML: .gold-btn { width:100%; background:linear-gradient(135deg,var(--gold),var(--gold-end));
          //   border-radius:16px; padding:14px; font-size:15px; font-weight:700; color:var(--bg-mid); }
          GestureDetector(
            onTap: hasProfile ? _startDiagnosis : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                ),
                boxShadow: const [BoxShadow(color: Color(0x40F9D976), blurRadius: 24)],
              ),
              child: Center(
                child: Text(t.sanctuary.receiveTitle,
                  style: const TextStyle(color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
            ),
          ),
        ],
        // ── ✦ 称号を共有する（診断後） ──
        if (_titleLight != null && _titleAxis != null && _titleCourt != null) ...[
          GestureDetector(
            onTap: _openShareCard,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x66F9D976)),
                gradient: const LinearGradient(
                  colors: [Color(0x33F9D976), Color(0x1AF9D976)],
                ),
              ),
              child: Center(
                child: Text(t.sanctuary.shareTitleCard,
                  style: const TextStyle(color: Color(0xFFF9D976), fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // 再診断ボタン: Free=1 回まで、Pro=無制限。
        // C4 (柱 3): クラスは「今の自分」クイズなので Pro 限定で取り直せる。
        // 二つ名は出生固定で取り直し不可 (これは別仕様、生年月日変更時のみ更新)。
        if (_titleLight != null) ...[
          AnimatedBuilder(
            animation: ProStatus.instance,
            builder: (ctx, _) {
              final isPro = ProStatus.instance.isPro;
              final canRedoFree = _titleRedoCount < _kFreeRedoLimit;
              final canRedo = isPro || canRedoFree;
              final showProLabel = !canRedo;
              return GestureDetector(
                // Free の 1 回再診断 → 案内なしで直接診断へ。
                // Pro 機能として受け直す場合のみ、再診断前に「称号の受け直しについて」
                // の案内を表示し、OK で診断へ / 戻るでキャンセルする。
                onTap: canRedo
                    ? (isPro ? () => _showRediagnoseProGuide(ctx) : _startDiagnosis)
                    : () => showProUnlockDialog(
                          ctx,
                          featureLabel: t.sanctuary.rediagnoseProFeature,
                          description: t.sanctuary.rediagnoseProDesc,
                        ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: canRedo
                          ? const Color(0x4DF9D976)
                          : const Color(0x22F9D976),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      showProLabel ? t.sanctuary.rediagnoseProOnly : t.sanctuary.rediagnose,
                      style: TextStyle(
                        color: canRedo
                            ? const Color(0xFFF9D976)
                            : const Color(0x77F9D976),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // 🔧 開発デバッグ用: redoCount リセットボタン
          // kDebugMode が true (debug build) の時のみ表示、release build では消える
          if (kDebugMode && _titleRedoCount > 0) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final td = await SolaraStorage.loadTitleData();
                if (td != null) {
                  final updated = <String, dynamic>{
                    ...td,
                    'redoCount': 0,
                  };
                  await SolaraStorage.saveTitleData(updated);
                  if (mounted) {
                    setState(() => _titleRedoCount = 0);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔧 redoCount=0 にリセットしました (dev only)'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x44FF6B6B)),
                ),
                child: const Center(
                  child: Text(
                    '🔧 dev: 再診断カウントをリセット',
                    style: TextStyle(
                      color: Color(0xAAFF8888),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
        // HTML: #titleNeedProfile { display:none; text-align:center; color:#ACACAC; font-size:13px; padding:10px; }
        if (!hasProfile) ...[
          Padding(
            padding: const EdgeInsets.all(10),
            child: Center(
              child: Text(t.sanctuary.needProfile,
                style: const TextStyle(fontSize: 15, color: Color(0xFFACACAC))),
            ),
          ),
        ],
      ],
    );
  }

  // ── Title Flip Card (アール・ヌーヴォーカード + Light/Shadow テキストオーバーレイ) ──
  Widget _buildTitleFlipCard() {
    // axis + court から TitleClass を引いて ClassCard 表示
    // 旧データ（axis/court 未保存）の場合は axis のみ推定 or プレースホルダ
    final cls = (_titleAxis != null && _titleCourt != null)
        ? title_data.getClassByAxisCourt(_titleAxis!, _titleCourt!)
        : null;

    if (cls == null) {
      // フォールバック: 旧データ or アセット欠落時のテキスト表示
      return _buildLegacyVCard();
    }

    // t144 から一言 (Light / Shadow) を取得して「省察に長けた / 騎士」と縦書き連結
    final sunSign = _profile != null ? title_data.getSunSign(_profile!.birthDate) : '';
    final moonSign = _profile != null
        ? title_data.getMoonSign(_profile!.birthDate, _profile!.birthTime)
        : '';
    final t144 = title_data.title144[sunSign]?[moonSign];
    final sunA = title_data.sunAdj[sunSign];
    final moonN = title_data.moonNoun[moonSign];
    final titleLight = t144?['light'] ?? '${sunA?['jp'] ?? ''}${moonN?['jp'] ?? ''}';
    final titleShadow = t144?['shadow'] ?? '${sunA?['jp'] ?? ''}${moonN?['jp'] ?? ''}';
    final titleLightEN = t144?['lightEN'] ?? '${sunA?['en'] ?? ''} ${moonN?['en'] ?? ''}';
    final titleShadowEN = t144?['shadowEN'] ?? '${sunA?['en'] ?? ''} ${moonN?['en'] ?? ''}';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: Center(
        key: ValueKey(_titleFlipped ? 'shadow' : 'light'),
        child: ClassCard(
          classData: cls,
          width: 280,
          mode: _titleFlipped ? ClassCardMode.shadow : ClassCardMode.light,
          showGlow: true,
          isEnglish: isEnLocale(),
          titleLightJP: titleLight,
          titleShadowJP: titleShadow,
          titleLightEN: titleLightEN,
          titleShadowEN: titleShadowEN,
        ),
      ),
    );
  }

  /// 旧データ用フォールバック（axis/court 未保存時 or アセット欠落時）
  Widget _buildLegacyVCard() {
    return _titleFlipped
        ? _buildTitleVCard(
            key: const ValueKey('shadow-legacy'),
            label: '✦ SHADOW ✦',
            labelColor: const Color(0x80ACACAC),
            title: (isEnLocale() ? _titleShadowEN : null)?.isNotEmpty == true
                ? _titleShadowEN!
                : (_titleShadow ?? ''),
            titleColor: const Color(0xFFEAEAEA),
            className: _titleClassEN ?? '',
            isLight: false,
          )
        : _buildTitleVCard(
            key: const ValueKey('light-legacy'),
            label: '✦ LIGHT ✦',
            labelColor: const Color(0x80F9D976),
            title: (isEnLocale() ? _titleLightEN : null)?.isNotEmpty == true
                ? _titleLightEN!
                : (_titleLight ?? ''),
            titleColor: const Color(0xFFF9D976),
            className: _titleClassEN ?? '',
            isLight: true,
          );
  }

  // HTML: .td-vcard { border-radius:16px; padding:28px 20px 24px; border:1px solid rgba(249,217,118,0.15); }
  Widget _buildTitleVCard({
    required Key key,
    required String label,
    required Color labelColor,
    required String title,
    required Color titleColor,
    required String className,
    required bool isLight,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0A0A14),
        border: Border.all(color: const Color(0x26F9D976)), // rgba(249,217,118,0.15)
        boxShadow: const [
          BoxShadow(color: Color(0x80000000), blurRadius: 30),
          BoxShadow(color: Color(0x0DF9D976), blurRadius: 60),
        ],
      ),
      child: Column(
        children: [
          // HTML: .td-vcard-label { font-size:10px; letter-spacing:3px; }
          Text(label, style: TextStyle(fontSize: 15, letterSpacing: 3, color: labelColor, fontWeight: FontWeight.w300)),
          const SizedBox(height: 6),
          // HTML: .td-vcard-line
          Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0x99F9D976), Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // HTML: .td-vcard-title { font-size:19px; font-weight:700; line-height:1.6; }
          Text(title,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: titleColor, height: 1.6,
              letterSpacing: 0.5,
              shadows: isLight
                  ? const [Shadow(color: Color(0x66F9D976), blurRadius: 20), Shadow(color: Color(0xE6000000), offset: Offset(0, 2), blurRadius: 4)]
                  : const [Shadow(color: Color(0x33EAEAEA), blurRadius: 15), Shadow(color: Color(0xE6000000), offset: Offset(0, 2), blurRadius: 4)],
            ),
            textAlign: TextAlign.center,
          ),
          if (className.isNotEmpty) ...[
            const SizedBox(height: 10),
            // HTML: .td-vcard-class-name { font-size:15px; font-weight:700; color:#EAEAEA; letter-spacing:2px; }
            Text(className,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA),
                letterSpacing: 2,
                shadows: [Shadow(color: Color(0x33EAEAEA), blurRadius: 8), Shadow(color: Color(0xCC000000), offset: Offset(0, 2), blurRadius: 4)],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── ✦ Records Section (Phase 2-4) ──
  /// 相談履歴の閲覧エントリ (柱 3 = 記録庫)。
  /// 新規相談は Map / Daily Transit popup 側の入口から (§7.2 Stage 1)。
  Widget _buildRecordsSection() {
    return _SettingsGroup(
      label: '✦ Records',
      children: [
        _SettingsItem(
          icon: Icons.auto_stories_outlined,
          text: t.sanctuary.consultHistory,
          value: '›',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ConsultationHistoryScreen(),
              ),
            );
          },
        ),
        // C4 (柱 3): クラス変遷ギャラリー。Free でも閲覧可能。
        _SettingsItem(
          icon: Icons.history_edu_outlined,
          text: t.sanctuary.titleHistory,
          value: '›',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TitleHistoryScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── ✦ Account Section は widgets/sanctuary_account_section.dart に分離 (Phase 2-9) ──

  // ── ✦ Cosmic Pro Section ──
  Widget _buildCosmicProSection() {
    return _SettingsGroup(
      label: '✦ Cosmic Pro',
      children: [
        // Phase 2-6b: AnimatedBuilder で ProStatus を購読し Pro/Free 状態で表示を切替え
        AnimatedBuilder(
          animation: ProStatus.instance,
          builder: (ctx, _) {
            final isPro = ProStatus.instance.isPro;
            return Column(
              children: [
                isPro ? _buildProActiveBanner() : _buildProUpgradeBanner(),
                const SizedBox(height: 10),
                _buildRestoreRow(),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Free 向け: PaywallScreen へ誘導するバナー。タップでペイウォール画面へ。
  Widget _buildProUpgradeBanner() {
    return InkWell(
      onTap: _openPaywall,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0x17F9D976), Color(0x0AF9D976)],
          ),
          border: Border.all(color: const Color(0x2EF9D976)),
        ),
        child: Column(children: [
          Text('Upgrade to Cosmic Pro',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              foreground: Paint()
                ..shader = const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFF9D976), Color(0xFFF6BD60)],
                ).createShader(const Rect.fromLTWH(0, 0, 220, 24)),
            )),
          const SizedBox(height: 12),
          Text(
            t.sanctuary.proPerks1,
            style: const TextStyle(fontSize: 15, color: Color(0xFFACACAC), height: 1.55),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            t.sanctuary.proPerks2,
            style: const TextStyle(fontSize: 12, color: Color(0x99ACACAC), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFF9D976), Color(0xFFF6BD60)],
              ),
            ),
            child: const Text('Unlock Cosmic Pro ✦',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0C1D3A))),
          ),
          const SizedBox(height: 12),
          Text(
            t.sanctuary.proPaywallNote,
            style: const TextStyle(fontSize: 12, color: Color(0x99ACACAC)),
          ),
        ]),
      ),
    );
  }

  /// Pro 加入済向け: 「Cosmic Pro 加入中」を伝えるバナー (購入不要)。
  /// 解約方法リンクで端末のサブスクリプション設定 deep link を直接開く。
  Widget _buildProActiveBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0x22F9D976), Color(0x11F9D976)],
        ),
        border: Border.all(color: const Color(0x66F9D976)),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFF9D976), size: 18),
            const SizedBox(width: 8),
            Text(
              t.sanctuary.proActive,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF9D976),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          t.sanctuary.proActiveDesc,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFFACACAC), height: 1.6),
        ),
        const SizedBox(height: 12),
        // 解約方法 deep link: タップで端末の定期購入画面に直接遷移。
        // iOS = 設定アプリ → Apple ID → サブスクリプション、Android = Play Store → 定期購入。
        InkWell(
          onTap: () => openSubscriptionSettings(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFF9D976).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.open_in_new, size: 14, color: Color(0xFFF9D976)),
                const SizedBox(width: 6),
                Text(
                  t.paywall.legal.cancelMethod,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFF9D976),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  /// 復元ボタン + ペイウォール再表示ボタン (Pro でも開ける = 解約導線 / 法務リンク確認)。
  Widget _buildRestoreRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: _restorePurchases,
          icon: const Icon(Icons.restore, size: 16),
          label: Text(t.paywall.restore),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFACACAC),
          ),
        ),
        TextButton.icon(
          onPressed: _openPaywall,
          icon: const Icon(Icons.receipt_long_outlined, size: 16),
          label: Text(t.sanctuary.plansTerms),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFACACAC),
          ),
        ),
      ],
    );
  }

  void _openPaywall() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _restorePurchases() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final info = await PurchasesService.instance.restorePurchases();
      if (!mounted) return;
      if (info == null || !ProStatus.instance.isPro) {
        messenger.showSnackBar(SnackBar(
          content: Text(t.sanctuary.restoreNotFound),
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(t.sanctuary.restoreDone),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(t.sanctuary.restoreError(e: e)),
      ));
    }
  }

  // ── ✦ Astrology Section ──
  Widget _buildAstrologySection() {
    final houseLabel = _houseSystem == 'placidus' ? 'Placidus' : 'Whole Sign';
    return _SettingsGroup(
      label: '✦ Astrology',
      children: [
        // House System
        _SettingsItem(
          icon: Icons.grid_view_rounded,
          text: 'House System',
          value: '$houseLabel ›',
          onTap: () => setState(() => _houseSelectOpen = !_houseSelectOpen),
        ),
        // House select panel (hidden by default) — 1つのColumnにまとめてgap制御
        if (_houseSelectOpen)
          Column(children: [
            _buildHouseOption('Placidus', 'placidus'),
            const SizedBox(height: 6),
            _buildHouseOption('Whole Sign', 'whole_sign'),
          ]),
        // ホロスコープのオーブ設定 (Horoscope 画面のアスペクト/パターン検出にのみ反映)
        _SettingsItem(
          icon: Icons.adjust,
          text: t.sanctuary.orbSetting,
          value: _orbSummary(),
          onTap: _openOrbOverlay,
        ),
      ],
    );
  }

  Widget _buildHouseOption(String label, String value) {
    final isSelected = _houseSystem == value;
    return GestureDetector(
      onTap: () async {
        setState(() { _houseSystem = value; _houseSelectOpen = false; });
        // 保存 + 同期キャッシュ更新 (Horo/Map の次回チャート計算から反映)。
        await SolaraStorage.saveHouseSystem(value);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
          borderRadius: BorderRadius.circular(20), // HTML: border-radius:20px
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, color: Color(0xFFEAEAEA))),
            ),
            Text('✓', style: TextStyle(fontSize: 16, color: const Color(0xFFF9D976),
              fontWeight: FontWeight.w600),
            ).withOpacity(isSelected ? 1.0 : 0.0),
          ],
        ),
      ),
    );
  }

  String _orbSummary() {
    // アスペクト 8 + パターン 5 のデフォルト値。全て一致なら「標準」。
    const defaults = {
      'conjunction': 2.0, 'opposition': 2.0, 'trine': 2.0, 'square': 2.0,
      'sextile': 2.0, 'quincunx': 2.0, 'semisextile': 1.0, 'semisquare': 1.0,
      'grandtrine': 3.0, 'tsquare_opp': 3.0, 'tsquare_sq': 2.5,
      'yod_sextile': 2.5, 'yod_quincunx': 1.5,
    };
    final isDefault =
        _orbValues.entries.every((e) => defaults[e.key] == e.value);
    return isDefault ? t.sanctuary.orbStandard : t.sanctuary.orbCustom;
  }

  void _openOrbOverlay() async {
    final result = await showModalBottomSheet<Map<String, double>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SanctuaryOrbOverlay(orbValues: Map.from(_orbValues)),
    );
    if (result != null) {
      setState(() => _orbValues.addAll(result));
      // HTML: saveOrbOverlay() → localStorage.setItem('solara_orb_settings', JSON.stringify(currentOrbs))
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('solara_orb_settings', json.encode(result));
    }
  }

  // ── ✦ App Section ──
  Widget _buildAppSection() {
    return _SettingsGroup(
      label: '✦ App',
      children: [
        // Language — 端末追従 / 日本語 / English を選ぶ bottom sheet。現在値を動的表示。
        ValueListenableBuilder<Locale?>(
          valueListenable: AppLocale.instance.notifier,
          builder: (ctx, _, _) => _SettingsItem(
            icon: Icons.language,
            text: t.appSettings.language,
            value: '${languageValueLabel()} ›',
            onTap: () => showLanguagePicker(ctx),
          ),
        ),
        // Text size — 標準 / 大きめ / 最大 (注意書き付き)。現在値を動的表示。
        ValueListenableBuilder<AppFontSize>(
          valueListenable: AppTextScale.instance.notifier,
          builder: (ctx, _, _) => _SettingsItem(
            icon: Icons.format_size,
            text: t.appSettings.fontSize,
            value: '${fontSizeValueLabel()} ›',
            onTap: () => showFontSizePicker(ctx),
          ),
        ),
        // Notifications — 月イベント (新月/満月/刻星化 + 惑星イベント) のローカル通知トグル。
        const _NotificationToggleItem(),
        // Daily reset hour（今日のタップボタンのリセット時刻）
        _SettingsItem(
          icon: Icons.schedule_outlined,
          text: t.sanctuary.dayStart,
          value: '${_dailyResetHour.toString().padLeft(2, '0')}:${_dailyResetMinute.toString().padLeft(2, '0')} ›',
          onTap: _pickDailyResetHour,
        ),
        // Terms & Privacy — 4 法務リンク popup (sanctuary_legal_menu.dart)
        // launch_checklist Phase 2 残: Sanctuary 単独リンク [WIP] → [x]
        _SettingsItem(
          icon: Icons.description_outlined,
          text: 'Terms & Privacy',
          value: '›',
          onTap: () => showSanctuaryLegalMenu(context),
        ),
      ],
    );
  }

  Future<void> _pickDailyResetHour() async {
    final picked = await showModalBottomSheet<({int hour, int minute})>(
      context: context,
      backgroundColor: const Color(0xFF0A0E1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SanctuaryResetHourPicker(
        initialHour: _dailyResetHour,
        initialMinute: _dailyResetMinute,
        title: t.resetPicker.title,
        subtitle: t.resetPicker.subtitle,
      ),
    );
    if (picked == null) return;
    setState(() {
      _dailyResetHour = picked.hour;
      _dailyResetMinute = picked.minute;
    });
    await SolaraStorage.saveDailyResetHour(picked.hour);
    await SolaraStorage.saveDailyResetMinute(picked.minute);
  }

  // HTML: background: radial-gradient(ellipse at center, #0a1220 0%, #020408 100%)
  // HTML: .main-area.cosmic-bg — radial-gradient(ellipse at 50% 0%, #0f2850 0%, #080C14 55%)
  static const _bgDecoration = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0, -1), radius: 1.1,
      colors: [Color(0xFF0F2850), Color(0xFF080C14)],
      stops: [0.0, 0.55],
    ),
  );

  // Cosmic Pro 限定: 同じ夜空グラデの上に、神殿(アンティーク枠)背景を薄く重ねる。
  static const _proBgDecoration = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment(0, -1), radius: 1.1,
      colors: [Color(0xFF0F2850), Color(0xFF080C14)],
      stops: [0.0, 0.55],
    ),
    image: DecorationImage(
      image: AssetImage('assets/sanctuary-bg/pro.webp'),
      fit: BoxFit.cover,
      opacity: 0.35,
    ),
  );
}

// ── Extension for opacity on any widget ──
extension _WidgetOpacity on Widget {
  Widget withOpacity(double opacity) => Opacity(opacity: opacity, child: this);
}

// ══════════════════════════════════════════════════
// ── Settings Group ──
// HTML: .settings-group { display:flex; flex-direction:column; gap:10px; }
// ══════════════════════════════════════════════════

class _SettingsGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _SettingsGroup({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HTML: .section-label { font-size:11px; font-weight:700; color:var(--gold); letter-spacing:1.8px; text-transform:uppercase; }
        Text(label, style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: Color(0xFFF9D976), letterSpacing: 1.8,
        )),
        const SizedBox(height: 10),
        ...List.generate(children.length, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < children.length - 1 ? 10 : 0),
            child: children[i],
          );
        }),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
// ── Settings Item ──
// HTML: .settings-item { padding:14px 18px; border-radius:20px; }
// .settings-icon { width:36px; height:36px; background:rgba(255,255,255,0.05); border-radius:10px; }
// ══════════════════════════════════════════════════

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String value;
  final VoidCallback? onTap;
  const _SettingsItem({required this.icon, required this.text, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF), // rgba(255,255,255,0.06) — HTML .settings-item.glass
          borderRadius: BorderRadius.circular(20), // HTML: border-radius:20px
          border: Border.all(color: const Color(0x1AFFFFFF)), // rgba(255,255,255,0.1)
        ),
        child: Row(
          children: [
            // HTML: .settings-icon { width:36px; height:36px; background:rgba(255,255,255,0.05);
            //   border-radius:10px; color:rgba(249,217,118,0.7); font-size:17px; }
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, size: 20, color: const Color(0xB3F9D976)), // rgba(249,217,118,0.7)
              ),
            ),
            const SizedBox(width: 12),
            // HTML: .settings-txt { font-size:14px; }
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFFEAEAEA))),
            ),
            // HTML: .settings-val { font-size:13px; color:#ACACAC; }
            Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFFACACAC))),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// ── Notification Toggle Item (A: 月イベント通知) ──
// _SettingsItem と同じ見た目で末尾を Switch にしたトグル行。
// ON: OS 許諾を確保 → schedule。許諾が取れなければ OFF に戻し、設定誘導を SnackBar 表示。
// OFF: 全予約 cancel + 明示 OFF (ソフトアスク抑制)。
// ══════════════════════════════════════════════════
class _NotificationToggleItem extends StatefulWidget {
  const _NotificationToggleItem();

  @override
  State<_NotificationToggleItem> createState() =>
      _NotificationToggleItemState();
}

class _NotificationToggleItemState extends State<_NotificationToggleItem> {
  bool _on = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final on = await SolaraStorage.getNotificationsEnabled();
    if (mounted) setState(() => _on = on);
  }

  Future<void> _toggle(bool want) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (want) {
      final ok = await MoonNotificationService.instance.enableFromToggle();
      if (!mounted) return;
      setState(() {
        _on = ok;
        _busy = false;
      });
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.sanctuary.notifyNeedPermission),
        ));
      }
    } else {
      await MoonNotificationService.instance.disable();
      if (!mounted) return;
      setState(() {
        _on = false;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Switch があるぶん vertical を詰めて _SettingsItem と同じ高さ感にする。
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.notifications_outlined,
                  size: 20, color: Color(0xB3F9D976)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Notifications',
                style: TextStyle(fontSize: 15, color: Color(0xFFEAEAEA))),
          ),
          Switch.adaptive(
            value: _on,
            onChanged: _busy
                ? null
                : (v) {
                    _toggle(v);
                  },
            activeThumbColor: const Color(0xFFF9D976),
          ),
        ],
      ),
    );
  }
}

