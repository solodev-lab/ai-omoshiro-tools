import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/pro_status.dart';
import '../utils/purchases_service.dart';
import '../utils/solara_storage.dart';
import '../utils/title_data.dart' as title_data;
import '../widgets/class_card.dart';
import '../widgets/pro_unlock_dialog.dart';
import 'consultation/consultation_history_screen.dart';
import 'paywall_screen.dart';
import 'sanctuary/sanctuary_orb_overlay.dart';
import 'sanctuary/sanctuary_profile_editor.dart';
import 'sanctuary/sanctuary_reset_hour_picker.dart';
import 'sanctuary/sanctuary_title_diagnosis.dart';
import 'sanctuary/class_share_card.dart';
import 'sanctuary/sanctuary_home_editor.dart';
import 'sanctuary/title_history_screen.dart';

class SanctuaryScreen extends StatefulWidget {
  const SanctuaryScreen({super.key});

  @override
  State<SanctuaryScreen> createState() => _SanctuaryScreenState();
}

class _SanctuaryScreenState extends State<SanctuaryScreen> {
  SolaraProfile? _profile;
  bool _loading = true;

  // Title diagnosis results
  String? _titleLight;
  String? _titleShadow;
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
  bool _notificationsOn = true;

  // 1日の基準時刻 (hour 0-23, minute 0-59、1 分単位)。この時刻を跨ぐと Omen ボタンがリセットされる。
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
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // HTML: localStorage('solara_house_system')
    final house = prefs.getString('solara_house_system');
    if (house != null && mounted) setState(() => _houseSystem = house);
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
          final newLight = t144?['light'] ?? (sunA?['jp'] ?? '');
          final newShadow = t144?['shadow'] ?? '${sunA?['jp'] ?? ''}${title_data.moonNoun[newMoon]?['jp'] ?? ''}';
          final updated = {
            'lightJP': newLight, 'shadowJP': newShadow,
            'classEN': _titleClassEN ?? '', 'classJP': _titleClassJP ?? '',
            'axis': _titleAxis ?? '', 'court': _titleCourt ?? '',
          };
          await SolaraStorage.saveTitleData(updated);
          setState(() { _titleLight = newLight; _titleShadow = newShadow; });
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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClassShareCardPage(
        axis: _titleAxis!, court: _titleCourt!,
        titleLightJP: titleLight,
        titleShadowJP: titleShadow,
        titleEN: '${sunA?['en'] ?? ''} ${moonN?['en'] ?? ''}',
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
      );
      setState(() {
        _titleLight = result['lightJP'];
        _titleShadow = result['shadowJP'];
        _titleClassEN = result['classEN'];
        _titleClassJP = result['classJP'];
        _titleAxis = result['axis'];
        _titleCourt = result['court'];
        _titleRedoCount = newRedoCount;
      });
    }
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

    return Container(
      decoration: _bgDecoration,
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
                  // ── Profile Row ──
                  _buildProfileRow(profileName),
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
    );
  }

  // ── Profile Row ──
  // HTML: .profile-row { display:flex; align-items:center; gap:14px; }
  Widget _buildProfileRow(String name) {
    return Row(
      children: [
        // HTML: .profile-orb { width:56px; height:56px; border-radius:50%;
        //   background:radial-gradient(circle,rgba(249,217,118,0.25) 0%,rgba(249,217,118,0.04) 70%);
        //   border:1px solid rgba(249,217,118,0.25); font-size:24px; }
        Container(
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
            child: Text('✦', style: TextStyle(fontSize: 24, color: Color(0xFFF9D976))),
          ),
        ),
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
              const Text('Free Tier · Cosmic Journey',
                style: TextStyle(fontSize: 15, color: Color(0xFFACACAC))),
            ],
          ),
        ),
      ],
    );
  }

  // ── ✦ Stellar Profile Section ──
  Widget _buildStellarProfileSection(bool hasProfile) {
    final birthVal = hasProfile
        ? '${_profile!.birthDate.replaceAll('-', '/')} ›'
        : '未設定 ›';
    return _SettingsGroup(
      label: '✦ Stellar Profile',
      children: [
        _SettingsItem(
          icon: Icons.auto_awesome,
          text: '出生情報',
          value: birthVal,
          onTap: _openProfileEditor,
        ),
        _SettingsItem(
          icon: Icons.home_outlined,
          text: '自宅（現住所）',
          value: _profile != null && _profile!.homeName.isNotEmpty
              ? '${_profile!.homeName.length > 10 ? '${_profile!.homeName.substring(0, 10)}...' : _profile!.homeName} ›'
              : '未設定 ›',
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
          GestureDetector(
            onTap: () => setState(() => _titleFlipped = !_titleFlipped),
            child: _buildTitleFlipCard(),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _titleFlipped ? 'tap to show LIGHT' : 'tap to show SHADOW',
              style: const TextStyle(fontSize: 12, color: Color(0x80ACACAC), letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 10),
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
              child: const Center(
                child: Text('✦ あなたの称号を受け取る',
                  style: TextStyle(color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
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
              child: const Center(
                child: Text('✦ 称号カードを共有する',
                  style: TextStyle(color: Color(0xFFF9D976), fontSize: 15, fontWeight: FontWeight.w600)),
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
                onTap: canRedo
                    ? _startDiagnosis
                    : () => showProUnlockDialog(
                          ctx,
                          featureLabel: 'クラスの取り直し',
                          description:
                              '「今の自分」は変わっていきます。\n'
                              'Cosmic Pro なら何度でも診断を受け直せ、\n'
                              '変遷ギャラリーで過去のクラスを並べて見返せます。',
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
                      showProLabel ? '再診断はCosmic Pro限定' : '再診断する',
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
          const Padding(
            padding: EdgeInsets.all(10),
            child: Center(
              child: Text('まず出生情報を設定してください',
                style: TextStyle(fontSize: 15, color: Color(0xFFACACAC))),
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
          titleLightJP: titleLight,
          titleShadowJP: titleShadow,
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
            title: _titleShadow ?? '',
            titleColor: const Color(0xFFEAEAEA),
            className: _titleClassEN ?? '',
            isLight: false,
          )
        : _buildTitleVCard(
            key: const ValueKey('light-legacy'),
            label: '✦ LIGHT ✦',
            labelColor: const Color(0x80F9D976),
            title: _titleLight ?? '',
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
          text: '相談履歴',
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
          text: '称号 変遷',
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
        // ── [DEV] Pro 状態切替 (動作確認用、課金基盤と並走) ──
        // kDebugMode のみ表示。リリースビルドでは消える。
        if (kDebugMode) _buildDevProToggle(),
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
          const Text(
            'Stella 相談 · ACG 4 フレーム · 記録庫の道具',
            style: TextStyle(fontSize: 15, color: Color(0xFFACACAC), height: 1.55),
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
          const Text(
            'プランと価格はペイウォールでご確認ください · いつでも解約可能',
            style: TextStyle(fontSize: 12, color: Color(0x99ACACAC)),
          ),
        ]),
      ),
    );
  }

  /// Pro 加入済向け: 「Cosmic Pro 加入中」を伝えるバナー (購入不要)。
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFF9D976), size: 18),
            SizedBox(width: 8),
            Text(
              'Cosmic Pro 加入中',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF9D976),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'すべての機能が解放されています。\n更新と解約は端末のサブスクリプション設定から。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFFACACAC), height: 1.6),
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
          label: const Text('購入を復元'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFACACAC),
          ),
        ),
        TextButton.icon(
          onPressed: _openPaywall,
          icon: const Icon(Icons.receipt_long_outlined, size: 16),
          label: const Text('プラン・規約'),
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
        messenger.showSnackBar(const SnackBar(
          content: Text('復元する購入が見つかりませんでした。'),
        ));
      } else {
        messenger.showSnackBar(const SnackBar(
          content: Text('購入を復元しました。'),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('復元中にエラーが発生しました: $e'),
      ));
    }
  }

  /// [DEV] Pro 状態切替トグル。Phase 2-6a で Pro ゲートの動作確認用。
  /// Phase 2-6b で RevenueCat 接続したら撤去する。
  Widget _buildDevProToggle() {
    return AnimatedBuilder(
      animation: ProStatus.instance,
      builder: (ctx, _) {
        final isPro = ProStatus.instance.isPro;
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x14D6915C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x44D6915C)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bug_report_outlined,
                  size: 16, color: Color(0xFFE8B080)),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[DEV] Pro 状態切替',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE8B080)),
                    ),
                    Text(
                      'リリースビルドでは表示されません',
                      style: TextStyle(
                          fontSize: 10, color: Color(0xFFA56838)),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isPro,
                onChanged: (v) {
                  ProStatus.instance.setPro(v);
                },
                activeThumbColor: const Color(0xFFF9D976),
              ),
            ],
          ),
        );
      },
    );
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
          text: 'ホロスコープのオーブ',
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
        // HTML: localStorage.setItem('solara_house_system', val)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('solara_house_system', value);
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
    return isDefault ? '標準 ›' : 'カスタム ›';
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
        // Language
        _SettingsItem(
          icon: Icons.language,
          text: 'Language',
          value: 'English ›',
          onTap: () {},
        ),
        // Notifications with toggle
        _SettingsItemWithToggle(
          icon: Icons.notifications_outlined,
          text: 'Notifications',
          value: _notificationsOn,
          onChanged: (v) => setState(() => _notificationsOn = v),
        ),
        // Daily reset hour（今日のタップボタンのリセット時刻）
        _SettingsItem(
          icon: Icons.schedule_outlined,
          text: '1日の開始時刻',
          value: '${_dailyResetHour.toString().padLeft(2, '0')}:${_dailyResetMinute.toString().padLeft(2, '0')} ›',
          onTap: _pickDailyResetHour,
        ),
        // Terms & Privacy
        _SettingsItem(
          icon: Icons.description_outlined,
          text: 'Terms & Privacy',
          value: '›',
          onTap: () {},
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

// ── Settings Item with Toggle Switch ──

class _SettingsItemWithToggle extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingsItemWithToggle({required this.icon, required this.text, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
        borderRadius: BorderRadius.circular(20), // HTML: border-radius:20px
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: const Color(0xB3F9D976)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFFEAEAEA))),
          ),
          // HTML: .toggle { width:44px; height:26px; border-radius:13px; }
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44, height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: value
                    ? const Color(0x8CF9D976) // rgba(249,217,118,0.55)
                    : const Color(0x1FFFFFFF), // rgba(255,255,255,0.12)
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
