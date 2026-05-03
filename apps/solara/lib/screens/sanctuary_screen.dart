import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/solara_storage.dart';
import '../utils/title_data.dart' as title_data;
import 'sanctuary/sanctuary_orb_overlay.dart';
import 'sanctuary/sanctuary_profile_editor.dart';
import 'sanctuary/sanctuary_reset_hour_picker.dart';
import 'sanctuary/sanctuary_title_diagnosis.dart';
import 'sanctuary/sanctuary_home_editor.dart';

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
  // 2026-04-30: シャドー称号無効化中のため変化しないが、復活時に flip するため var 維持
  bool _titleFlipped = false; // ignore: prefer_final_fields

  // Astrology settings
  String _houseSystem = 'placidus';
  bool _houseSelectOpen = false;
  bool _notificationsOn = true;

  // 1日の基準時刻 (hour 0-23, minute 0-59、1 分単位)。この時刻を跨ぐと Omen ボタンがリセットされる。
  int _dailyResetHour = 0;
  int _dailyResetMinute = 0;

  // Orb values
  final Map<String, double> _orbValues = {
    'conjunction': 2, 'opposition': 2, 'trine': 2, 'square': 2, 'sextile': 2,
    'quincunx': 2, 'semisextile': 1, 'semisquare': 1,
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
            'classEN': _titleClassEN ?? '', 'classJP': '',
          };
          await SolaraStorage.saveTitleData(updated);
          setState(() { _titleLight = newLight; _titleShadow = newShadow; });
        }
      }
      setState(() => _profile = result);
    }
  }

  void _startDiagnosis() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => SanctuaryTitleDiagnosisPage(profile: _profile)),
    );
    if (result != null) {
      await SolaraStorage.saveTitleData(result);
      setState(() {
        _titleLight = result['lightJP'];
        _titleShadow = result['shadowJP'];
        _titleClassEN = result['classEN'];
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
                      style: TextStyle(fontSize: 11, color: Color(0x59ACACAC))), // rgba(172,172,172,0.35)
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
                style: TextStyle(fontSize: 12, color: Color(0xFFACACAC))),
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
          // 2026-04-30 オーナー判断: シャドー称号は一時的に無効化（後で復活可能）。
          //   - flip タップを停止し、`tap to flip` ヒントも非表示
          //   - `_titleFlipped` は常に false のまま → LIGHT 側のみ表示
          //   - SHADOW 描画ロジック（_buildTitleFlipCard 内の SHADOW 分岐）と
          //     `_titleShadow` state、保存ロジックは維持
          //   復活手順: ここで GestureDetector で _titleFlipped をトグル + hint 復元
          _buildTitleFlipCard(),
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
        // HTML: #titleRediagnose — ghost button (shown after diagnosis)
        if (_titleLight != null) ...[
          // HTML: border:1px solid rgba(249,217,118,0.3); background:none; color:#F9D976; font-size:13px;
          GestureDetector(
            onTap: _startDiagnosis,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x4DF9D976)), // rgba(249,217,118,0.3)
              ),
              child: const Center(
                child: Text('再診断する（Cosmic Pro）',
                  style: TextStyle(color: Color(0xFFF9D976), fontSize: 13)),
              ),
            ),
          ),
        ],
        // HTML: #titleNeedProfile { display:none; text-align:center; color:#ACACAC; font-size:13px; padding:10px; }
        if (!hasProfile) ...[
          const Padding(
            padding: EdgeInsets.all(10),
            child: Center(
              child: Text('まず出生情報を設定してください',
                style: TextStyle(fontSize: 13, color: Color(0xFFACACAC))),
            ),
          ),
        ],
      ],
    );
  }

  // ── Title Flip Card ──
  Widget _buildTitleFlipCard() {
    // HTML: .td-result-card-inner { height:480px; }
    // AnimatedSwitcher for flip effect
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _titleFlipped
          ? _buildTitleVCard(
              key: const ValueKey('shadow'),
              label: '✦ SHADOW ✦',
              labelColor: const Color(0x80ACACAC),
              title: _titleShadow ?? '',
              titleColor: const Color(0xFFEAEAEA),
              className: _titleClassEN ?? '',
              isLight: false,
            )
          : _buildTitleVCard(
              key: const ValueKey('light'),
              label: '✦ LIGHT ✦',
              labelColor: const Color(0x80F9D976),
              title: _titleLight ?? '',
              titleColor: const Color(0xFFF9D976),
              className: _titleClassEN ?? '',
              isLight: true,
            ),
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
          Text(label, style: TextStyle(fontSize: 10, letterSpacing: 3, color: labelColor, fontWeight: FontWeight.w300)),
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

  // ── ✦ Cosmic Pro Section ──
  Widget _buildCosmicProSection() {
    return _SettingsGroup(
      label: '✦ Cosmic Pro',
      children: [
        // HTML: .pro-banner { padding:22px; background:linear-gradient(135deg,rgba(249,217,118,0.09),rgba(249,217,118,0.04));
        //   border:1px solid rgba(249,217,118,0.18); border-radius:22px;
        //   display:flex; flex-direction:column; gap:12px; align-items:center; text-align:center; }
        // HTML inline: style="padding:16px;gap:10px;" (overrides .pro-banner padding:22px)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0x17F9D976), Color(0x0AF9D976)], // rgba(249,217,118,0.09/0.04)
            ),
            border: Border.all(color: const Color(0x2EF9D976)), // rgba(249,217,118,0.18)
          ),
          child: Column(children: [
            // HTML: .pro-title { font-size:18px; font-weight:700; background:linear-gradient(135deg,var(--gold),var(--gold-end));
            //   -webkit-background-clip:text; -webkit-text-fill-color:transparent; }
            // (Flutter doesn't support background-clip text easily, use ShaderMask)
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFF9D976), Color(0xFFF6BD60)],
              ).createShader(bounds),
              child: const Text('Upgrade to Cosmic Pro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            // HTML: .pro-sub { font-size:13px; color:var(--text-secondary); line-height:1.55; }
            const Text('Aether shaders · Galaxy Archive · Advanced astrology',
              style: TextStyle(fontSize: 13, color: Color(0xFFACACAC), height: 1.55),
              textAlign: TextAlign.center),
            const SizedBox(height: 12),
            // Price row (from sanctuary.html inline styles)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text('\$9.99', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFF9D976))),
                SizedBox(width: 6),
                Text('/month', style: TextStyle(fontSize: 12, color: Color(0xFFACACAC))),
              ],
            ),
            const SizedBox(height: 12),
            // HTML: .pro-btn { background:linear-gradient(135deg,var(--gold),var(--gold-end)); border-radius:14px;
            //   padding:13px 30px; font-size:14px; font-weight:700; color:var(--bg-mid); }
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0C1D3A))),
            ),
            const SizedBox(height: 12),
            // HTML inline: font-size:11px; color:rgba(172,172,172,0.45)
            const Text('\$49.99/year · Cancel anytime',
              style: TextStyle(fontSize: 11, color: Color(0x73ACACAC))),
          ]),
        ),
      ],
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
        // Aspect Orbs
        _SettingsItem(
          icon: Icons.adjust,
          text: 'Aspect Orbs',
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
            Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFFEAEAEA))),
            Text('✓', style: TextStyle(fontSize: 16, color: const Color(0xFFF9D976),
              fontWeight: FontWeight.w600),
            ).withOpacity(isSelected ? 1.0 : 0.0),
          ],
        ),
      ),
    );
  }

  String _orbSummary() {
    final vals = _orbValues.values.toSet();
    if (vals.length == 1) return 'All ${vals.first.toStringAsFixed(0)}° ›';
    return 'Custom ›';
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
          fontSize: 11, fontWeight: FontWeight.w700,
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
              child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFFEAEAEA))),
            ),
            // HTML: .settings-val { font-size:13px; color:#ACACAC; }
            Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFFACACAC))),
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
            child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFFEAEAEA))),
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
