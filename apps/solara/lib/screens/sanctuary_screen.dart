import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/solara_storage.dart';
import '../utils/title_data.dart' as titleData;

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
  bool _titleFlipped = false;

  // Astrology settings
  String _houseSystem = 'placidus';
  bool _houseSelectOpen = false;
  bool _notificationsOn = true;

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
  }

  Future<void> _loadProfile() async {
    final p = await SolaraStorage.loadProfile();
    final titleData = await SolaraStorage.loadTitleData();
    setState(() {
      _profile = p;
      _loading = false;
      if (titleData != null) {
        _titleLight = titleData['lightJP'] as String?;
        _titleShadow = titleData['shadowJP'] as String?;
        _titleClassEN = titleData['classEN'] as String?;
      }
    });
  }

  void _openProfileEditor() async {
    final result = await Navigator.of(context).push<SolaraProfile>(
      MaterialPageRoute(
        builder: (_) => _ProfileEditorPage(profile: _profile),
      ),
    );
    if (result != null) {
      await SolaraStorage.saveProfile(result);
      // HTML: saveBirthInfo() — auto-update title if sun/moon sign changed
      if (_titleLight != null && _profile != null) {
        final oldSun = titleData.getSunSign(_profile!.birthDate);
        final oldMoon = titleData.getMoonSign(_profile!.birthDate, _profile!.birthTime);
        final newSun = titleData.getSunSign(result.birthDate);
        final newMoon = titleData.getMoonSign(result.birthDate, result.birthTime);
        if (newSun != oldSun || newMoon != oldMoon) {
          final t144 = titleData.title144[newSun]?[newMoon];
          final sunA = titleData.sunAdj[newSun];
          final newLight = t144?['light'] ?? (sunA?['jp'] ?? '');
          final newShadow = t144?['shadow'] ?? '${sunA?['jp'] ?? ''}${titleData.moonNoun[newMoon]?['jp'] ?? ''}';
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
      MaterialPageRoute(builder: (_) => _TitleDiagnosisPage(profile: _profile)),
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
        builder: (_) => _HomeEditorPage(profile: _profile),
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
          GestureDetector(
            onTap: () => setState(() => _titleFlipped = !_titleFlipped),
            child: _buildTitleFlipCard(),
          ),
          // HTML: .td-flip-hint { font-size:10px; color:rgba(172,172,172,0.4); text-align:center; }
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(
              child: Text('tap to flip',
                style: TextStyle(fontSize: 10, color: Color(0x66ACACAC), letterSpacing: 0.5)),
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
      builder: (ctx) => _OrbOverlay(orbValues: Map.from(_orbValues)),
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

// ══════════════════════════════════════════════════
// ── Orb Overlay (Bottom Sheet) ──
// HTML: birth-overlay > birth-card for Aspect Orbs
// ══════════════════════════════════════════════════

class _OrbOverlay extends StatefulWidget {
  final Map<String, double> orbValues;
  const _OrbOverlay({required this.orbValues});

  @override
  State<_OrbOverlay> createState() => _OrbOverlayState();
}

class _OrbOverlayState extends State<_OrbOverlay> {
  late Map<String, double> _vals;

  static const _majorAspects = [
    ('Conjunction (0°)', 'conjunction', 2.0),
    ('Opposition (180°)', 'opposition', 2.0),
    ('Trine (120°)', 'trine', 2.0),
    ('Square (90°)', 'square', 2.0),
    ('Sextile (60°)', 'sextile', 2.0),
  ];

  static const _minorAspects = [
    ('Quincunx (150°)', 'quincunx', 2.0),
    ('Semi-Sextile (30°)', 'semisextile', 1.0),
    ('Semi-Square (45°)', 'semisquare', 1.0),
  ];

  // HTML exact: PATTERN_ORBS (5 entries)
  static const _patternOrbs = [
    ('Grand Trine (120°)', 'grandtrine', 3.0),
    ('T-Square Opp (180°)', 'tsquare_opp', 3.0),
    ('T-Square Sq (90°)', 'tsquare_sq', 2.5),
    ('Yod Sextile (60°)', 'yod_sextile', 2.5),
    ('Yod Quincunx (150°)', 'yod_quincunx', 1.5),
  ];

  @override
  void initState() {
    super.initState();
    _vals = Map.from(widget.orbValues);
  }

  void _reset() {
    setState(() {
      for (final a in _majorAspects) _vals[a.$2] = a.$3;
      for (final a in _minorAspects) _vals[a.$2] = a.$3;
      for (final a in _patternOrbs) _vals[a.$2] = a.$3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xF2040810), // rgba(4,8,16,0.95)
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: ListView(
          controller: scrollCtrl,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // HTML: .birth-title { font-size:16px; font-weight:700; color:#F9D976; letter-spacing:1px; }
                const Text('🔭 Aspect Orbs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 1)),
                Row(children: [
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x40F9D976)),
                      ),
                      child: const Text('リセット', style: TextStyle(fontSize: 12, color: Color(0xFFF9D976))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x14FFFFFF),
                      ),
                      child: const Center(child: Text('✕', style: TextStyle(fontSize: 18, color: Color(0xFFACACAC)))),
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 20),

            // Major Aspects
            const _OrbSectionLabel('MAJOR ASPECTS'),
            const SizedBox(height: 8),
            ..._majorAspects.map((a) => _orbRow(a.$1, a.$2, a.$3)),

            const SizedBox(height: 16),

            // Minor Aspects
            const _OrbSectionLabel('MINOR ASPECTS'),
            const SizedBox(height: 8),
            ..._minorAspects.map((a) => _orbRow(a.$1, a.$2, a.$3)),

            const SizedBox(height: 16),

            // HTML exact: Pattern Orbs
            const _OrbSectionLabel('PATTERNS'),
            const SizedBox(height: 8),
            ..._patternOrbs.map((a) => _orbRow(a.$1, a.$2, a.$3)),

            const SizedBox(height: 24),

            // Save button
            GestureDetector(
              onTap: () => Navigator.pop(context, _vals),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                  ),
                ),
                child: const Center(
                  child: Text('保存する', style: TextStyle(
                    color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HTML: .orb-row { padding:8px 10px; border-radius:10px; background:rgba(255,255,255,0.03); }
  Widget _orbRow(String label, String key, double defaultVal) {
    final val = _vals[key] ?? defaultVal;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF), // rgba(255,255,255,0.03)
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // HTML: .orb-name { font-size:12px; color:#ACACAC; min-width:120px; }
          SizedBox(width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFACACAC)))),
          // − button
          _orbPmBtn('−', () {
            if (val > 0.5) setState(() => _vals[key] = val - 0.5);
          }),
          // Slider with default value mark
          Expanded(
            child: LayoutBuilder(builder: (ctx, constraints) {
              // HTML: .orb-default-mark — vertical line at default value position
              // Flutter Slider has 24px horizontal padding (overlayRadius=12 each side)
              const sliderPadding = 24.0;
              final trackW = constraints.maxWidth - sliderPadding;
              final ratio = (defaultVal - 0.5) / (8.0 - 0.5);
              final markX = sliderPadding / 2 + ratio * trackW;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFF9D976),
                      inactiveTrackColor: const Color(0x1AFFFFFF),
                      thumbColor: const Color(0xFFF9D976),
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: val, min: 0.5, max: 8.0,
                      divisions: 15,
                      onChanged: (v) => setState(() => _vals[key] = (v * 2).round() / 2),
                    ),
                  ),
                  // HTML: .orb-default-mark { position:absolute; top:2px; bottom:2px; width:1px; background:rgba(249,217,118,0.25) }
                  Positioned(
                    left: markX, top: 8, bottom: 8,
                    child: IgnorePointer(
                      child: Container(width: 1, color: const Color(0x40F9D976)),
                    ),
                  ),
                ],
              );
            }),
          ),
          // HTML: .orb-val { font-size:13px; color:#F9D976; min-width:36px; text-align:center; }
          SizedBox(width: 36,
            child: Text('${val.toStringAsFixed(1)}°',
              style: TextStyle(fontSize: 13, color: const Color(0xFFF9D976), fontWeight: FontWeight.w600,
                decoration: val == defaultVal ? TextDecoration.underline : null),
              textAlign: TextAlign.center)),
          // + button
          _orbPmBtn('+', () {
            if (val < 8.0) setState(() => _vals[key] = val + 0.5);
          }),
        ],
      ),
    );
  }

  // HTML: .orb-pm { width:26px; height:26px; border-radius:50%; border:1px solid rgba(249,217,118,0.3); color:#F9D976; }
  Widget _orbPmBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x4DF9D976)),
      ),
      child: Center(child: Text(label, style: const TextStyle(color: Color(0xFFF9D976), fontSize: 16))),
    ),
  );
}

class _OrbSectionLabel extends StatelessWidget {
  final String text;
  const _OrbSectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 12, color: Color(0xFFACACAC), letterSpacing: 0.5, fontWeight: FontWeight.w600));
}

// ══════════════════════════════════════════════════
// ── Profile Editor Page ──
// (Separate full-screen page matching HTML birth overlay)
// ══════════════════════════════════════════════════

class _ProfileEditorPage extends StatefulWidget {
  final SolaraProfile? profile;
  const _ProfileEditorPage({this.profile});

  @override
  State<_ProfileEditorPage> createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends State<_ProfileEditorPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _birthDateCtrl;
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  bool _birthTimeUnknown = false;
  String _birthPlace = '';
  double _birthLat = 0;
  double _birthLng = 0;
  int _birthTz = 9;

  final TextEditingController _placeCtrl = TextEditingController();
  List<Map<String, dynamic>> _placeResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    if (p != null && p.birthDate.isNotEmpty) {
      final parts = p.birthDate.split('-').map(int.parse).toList();
      _birthDate = DateTime(parts[0], parts[1], parts[2]);
      _birthDateCtrl = TextEditingController(text: '${parts[0]}/${parts[1].toString().padLeft(2, '0')}/${parts[2].toString().padLeft(2, '0')}');
    } else {
      _birthDateCtrl = TextEditingController();
    }
    if (p != null && !p.birthTimeUnknown && p.birthTime.isNotEmpty) {
      final tp = p.birthTime.split(':').map(int.parse).toList();
      _birthTime = TimeOfDay(hour: tp[0], minute: tp[1]);
    }
    _birthTimeUnknown = p?.birthTimeUnknown ?? false;
    _birthPlace = p?.birthPlace ?? '';
    _birthLat = p?.birthLat ?? 0;
    _birthLng = p?.birthLng ?? 0;
    _birthTz = p?.birthTz ?? 9;
    _placeCtrl.text = _birthPlace;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthDateCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  // 時間(0-23)と分(0-59)の選択肢
  static final _hourOptions = List.generate(24, (i) => i.toString().padLeft(2, '0'));
  static final _minuteOptions = List.generate(60, (i) => i.toString().padLeft(2, '0'));

  Future<void> _searchPlace(String query) async {
    if (query.length < 2) return;
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'SolaraApp/1.0 (solodev-lab.com)',
        'Accept-Language': 'ja,en',
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        setState(() {
          _placeResults = data.map<Map<String, dynamic>>((item) => {
            'name': item['display_name'] as String,
            'lat': double.parse(item['lat'] as String),
            'lng': double.parse(item['lon'] as String),
          }).toList();
        });
      }
    } catch (_) {
      // Silently fail
    } finally {
      setState(() => _searching = false);
    }
  }

  void _selectPlace(Map<String, dynamic> place) {
    setState(() {
      _birthPlace = place['name'] as String;
      _birthLat = place['lat'] as double;
      _birthLng = place['lng'] as double;
      _placeCtrl.text = _birthPlace;
      _placeResults = [];
    });
  }

  void _save() {
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('生年月日を入力してください')),
      );
      return;
    }
    if (_birthPlace.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('出生地を入力してください')),
      );
      return;
    }

    final dateStr = '${_birthDate!.year}-'
        '${_birthDate!.month.toString().padLeft(2, '0')}-'
        '${_birthDate!.day.toString().padLeft(2, '0')}';
    final timeStr = _birthTimeUnknown
        ? '12:00'
        : '${(_birthTime?.hour ?? 12).toString().padLeft(2, '0')}:'
          '${(_birthTime?.minute ?? 0).toString().padLeft(2, '0')}';

    final profile = SolaraProfile(
      name: _nameCtrl.text.trim(),
      birthDate: dateStr,
      birthTime: timeStr,
      birthTimeUnknown: _birthTimeUnknown,
      birthPlace: _birthPlace,
      birthLat: _birthLat,
      birthLng: _birthLng,
      birthTz: _birthTz,
    );

    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    // HTML: .birth-overlay { background:rgba(4,8,16,0.95); backdrop-filter:blur(12px); }
    // HTML: .birth-card { max-width:420px; width:92%; padding:24px 20px 32px; border-radius:24px; }
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('✦ 出生情報',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 1)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32, height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x14FFFFFF),
                            ),
                            child: const Center(child: Text('✕', style: TextStyle(fontSize: 18, color: Color(0xFFACACAC)))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 氏名
                    _birthSection('氏名', TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 14),
                      decoration: _inputDecoration('氏名を入力'),
                    )),

                    // 生年月日 — auto-format: 19901231 → 1990/12/31
                    _birthSection('生年月日', TextField(
                      controller: _birthDateCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 14),
                      decoration: _inputDecoration('YYYY/MM/DD'),
                      inputFormatters: [_DateSlashFormatter()],
                      onChanged: (v) {
                        final parts = v.split('/');
                        if (parts.length == 3 && parts[2].length == 2) {
                          final y = int.tryParse(parts[0]);
                          final m = int.tryParse(parts[1]);
                          final d = int.tryParse(parts[2]);
                          if (y != null && m != null && d != null && y > 1900 && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
                            setState(() => _birthDate = DateTime(y, m, d));
                          }
                        }
                      },
                    )),

                    // 出生時刻 — 24時間表記ドロップダウン（30分刻み）
                    _birthSection('出生時刻', Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 時間・分 2つのドロップダウン
                        Row(children: [
                          // 時間 (00-23)
                          Expanded(child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x0FFFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x1FFFFFFF)),
                            ),
                            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                              value: _birthTimeUnknown ? null : _birthTime != null ? _birthTime!.hour.toString().padLeft(2, '0') : null,
                              hint: Text(_birthTimeUnknown ? '12' : '時', style: TextStyle(fontSize: 14, color: _birthTimeUnknown ? const Color(0x59EAEAEA) : const Color(0x99EAEAEA))),
                              isExpanded: true, dropdownColor: const Color(0xFF0A1220),
                              style: const TextStyle(fontSize: 14, color: Color(0xFFEAEAEA)),
                              icon: Icon(Icons.arrow_drop_down, color: _birthTimeUnknown ? const Color(0x59EAEAEA) : const Color(0xFFACACAC)),
                              items: _birthTimeUnknown ? null : _hourOptions.map((h) => DropdownMenuItem(value: h, child: Text('$h 時'))).toList(),
                              onChanged: _birthTimeUnknown ? null : (val) {
                                if (val != null) setState(() => _birthTime = TimeOfDay(hour: int.parse(val), minute: _birthTime?.minute ?? 0));
                              },
                            )),
                          )),
                          const SizedBox(width: 8),
                          const Text(':', style: TextStyle(fontSize: 18, color: Color(0xFFACACAC))),
                          const SizedBox(width: 8),
                          // 分 (00-59)
                          Expanded(child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x0FFFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x1FFFFFFF)),
                            ),
                            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                              value: _birthTimeUnknown ? null : _birthTime != null ? _birthTime!.minute.toString().padLeft(2, '0') : null,
                              hint: Text(_birthTimeUnknown ? '00' : '分', style: TextStyle(fontSize: 14, color: _birthTimeUnknown ? const Color(0x59EAEAEA) : const Color(0x99EAEAEA))),
                              isExpanded: true, dropdownColor: const Color(0xFF0A1220),
                              style: const TextStyle(fontSize: 14, color: Color(0xFFEAEAEA)),
                              icon: Icon(Icons.arrow_drop_down, color: _birthTimeUnknown ? const Color(0x59EAEAEA) : const Color(0xFFACACAC)),
                              items: _birthTimeUnknown ? null : _minuteOptions.map((m) => DropdownMenuItem(value: m, child: Text('$m 分'))).toList(),
                              onChanged: _birthTimeUnknown ? null : (val) {
                                if (val != null) setState(() => _birthTime = TimeOfDay(hour: _birthTime?.hour ?? 12, minute: int.parse(val)));
                              },
                            )),
                          )),
                        ]),
                        // HTML: .time-unknown-row { display:flex; align-items:center; gap:8px; margin-top:8px; }
                        const SizedBox(height: 8),
                        Row(children: [
                          SizedBox(width: 18, height: 18,
                            child: Checkbox(
                              value: _birthTimeUnknown,
                              onChanged: (v) => setState(() => _birthTimeUnknown = v ?? false),
                              activeColor: const Color(0xFFF9D976),
                              side: const BorderSide(color: Color(0xFFACACAC)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _birthTimeUnknown = !_birthTimeUnknown),
                            child: const Text('出生時刻が分からない',
                              style: TextStyle(fontSize: 12, color: Color(0xFFACACAC))),
                          ),
                        ]),
                        // HTML: .time-noon-hint
                        if (_birthTimeUnknown) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x14F9D976),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '鑑定には惑星配置とアスペクト情報を使用します。ハウス・ASC・MCの鑑定は省略されます。',
                              style: TextStyle(color: Color(0xFFF9D976), fontSize: 11, height: 1.4),
                            ),
                          ),
                        ],
                      ],
                    )),

                    // 出生地
                    _birthSection('出生地', Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HTML: .map-search-row { display:flex; gap:8px; }
                        Row(children: [
                          Expanded(child: TextField(
                            controller: _placeCtrl,
                            style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 14),
                            decoration: _inputDecoration('例: 岐阜県岐阜市'),
                            onSubmitted: _searchPlace,
                          )),
                          const SizedBox(width: 8),
                          // HTML: .map-search-btn
                          GestureDetector(
                            onTap: () => _searchPlace(_placeCtrl.text),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                                ),
                              ),
                              child: const Text('検索', style: TextStyle(
                                color: Color(0xFF0A0A14), fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                        if (_searching)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Center(child: SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF9D976)))),
                          ),
                        if (_placeResults.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1220),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x1AFFFFFF)),
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _placeResults.length,
                              separatorBuilder: (_, __) => const Divider(color: Color(0x1AFFFFFF), height: 1),
                              itemBuilder: (_, i) {
                                final place = _placeResults[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(place['name'] as String,
                                    style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 13),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                  leading: const Icon(Icons.location_on, color: Color(0xFFF9D976), size: 18),
                                  onTap: () => _selectPlace(place),
                                );
                              },
                            ),
                          ),
                        ],
                        // HTML: .map-coords
                        if (_birthLat != 0 && _birthLng != 0) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: _readonlyField('緯度', _birthLat.toStringAsFixed(4))),
                            const SizedBox(width: 8),
                            Expanded(child: _readonlyField('経度', _birthLng.toStringAsFixed(4))),
                          ]),
                        ],
                      ],
                    )),

                    const SizedBox(height: 8),

                    // Save button
                    // HTML: .birth-save-btn { width:100%; padding:14px; border-radius:14px; }
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                          ),
                        ),
                        child: const Center(
                          child: Text('保存する', style: TextStyle(
                            color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // HTML: .birth-section { margin-bottom:18px; }
  Widget _birthSection(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HTML: .birth-label { font-size:12px; color:#ACACAC; letter-spacing:0.5px; text-transform:uppercase; }
          Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 12, color: Color(0xFFACACAC), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  // HTML: .birth-input { padding:12px 14px; background:rgba(255,255,255,0.06);
  //   border:1px solid rgba(255,255,255,0.12); border-radius:12px; color:#EAEAEA; font-size:14px; }
  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0x66EAEAEA)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: const Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1FFFFFFF))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1FFFFFFF))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x66F9D976))), // rgba(249,217,118,0.4)
  );

  Widget _readonlyField(String hint, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0x0FFFFFFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x1FFFFFFF)),
    ),
    child: Text(value.isEmpty ? hint : value,
      style: TextStyle(fontSize: 14, color: value.isEmpty ? const Color(0x66EAEAEA) : const Color(0xFFEAEAEA))),
  );
}

// ══════════════════════════════════════════════════
// ── Title Diagnosis Page ──
// HTML: #titleDiagOverlay
// ══════════════════════════════════════════════════

class _TitleDiagnosisPage extends StatefulWidget {
  final SolaraProfile? profile;
  const _TitleDiagnosisPage({this.profile});
  @override
  State<_TitleDiagnosisPage> createState() => _TitleDiagnosisPageState();
}

class _TitleDiagnosisPageState extends State<_TitleDiagnosisPage>
    with TickerProviderStateMixin {
  // HTML exact: 28 rounds, 3 parts
  static const _rounds = <Map<String, dynamic>>[
    // HTML: TD_ROUNDS — Part 1 Minor Arcana (img = card-images/ filename)
    {'part':1,'q':'新しい何かが始まるとき、あなたが最初に手に取るのは？','qen':'When something new begins, what do you reach for first?',
     'cards':[{'img':'W01.webp','axis':'power'},{'img':'C01.webp','axis':'heart'},{'img':'S01.webp','axis':'mind'},{'img':'P01.webp','axis':'spirit'}]},
    {'part':1,'q':'選択する時が来た。なにをおもう？','qen':'The moment of choice has come. What goes through your mind?',
     'cards':[{'img':'W02.webp','axis':'power'},{'img':'C02.webp','axis':'heart'},{'img':'S02.webp','axis':'mind'},{'img':'P02.webp','axis':'shadow'}]},
    {'part':1,'q':'あなたは大きな決断をした。どんな気持ち？','qen':'You\'ve made a big decision. How does it feel?',
     'cards':[{'img':'W03.webp','axis':'power'},{'img':'C03.webp','axis':'heart'},{'img':'S03.webp','axis':'mind'},{'img':'P03.webp','axis':'spirit'}]},
    {'part':1,'q':'安心を感じるのはどんなとき？','qen':'When do you feel most at ease?',
     'cards':[{'img':'W04.webp','axis':'power'},{'img':'C04.webp','axis':'heart'},{'img':'S04.webp','axis':'mind'},{'img':'P04.webp','axis':'spirit'}]},
    {'part':1,'q':'困難にぶつかったとき、あなたはどうなっている？','qen':'When you hit a wall, what happens to you?',
     'cards':[{'img':'W05.webp','axis':'power'},{'img':'C05.webp','axis':'heart'},{'img':'S05.webp','axis':'mind'},{'img':'P05.webp','axis':'shadow'}]},
    {'part':1,'q':'あなたが癒されるのは？','qen':'What heals you?',
     'cards':[{'img':'W06.webp','axis':'power'},{'img':'C06.webp','axis':'heart'},{'img':'S06.webp','axis':'mind'},{'img':'P06.webp','axis':'spirit'}]},
    {'part':1,'q':'眠れない夜、頭をよぎるのは？','qen':'What crosses your mind on sleepless nights?',
     'cards':[{'img':'W07.webp','axis':'power'},{'img':'C07.webp','axis':'heart'},{'img':'S07.webp','axis':'mind'},{'img':'P07.webp','axis':'shadow'}]},
    {'part':1,'q':'前進する為に、やるべきことは','qen':'What must be done to move forward?',
     'cards':[{'img':'W08.webp','axis':'power'},{'img':'C08.webp','axis':'heart'},{'img':'S08.webp','axis':'mind'},{'img':'P08.webp','axis':'shadow'}]},
    {'part':1,'q':'今の自分の姿にちかいのは？','qen':'Which one looks most like you right now?',
     'cards':[{'img':'W09.webp','axis':'power'},{'img':'C09.webp','axis':'heart'},{'img':'S09.webp','axis':'mind'},{'img':'P09.webp','axis':'spirit'}]},
    // HTML: TD_ROUNDS — Part 2 Major Arcana (with wildcard cards)
    {'part':2,'q':'生まれ変わるとしたら、誰になる？','qen':'If reborn, who would you become?',
     'cards':[{'img':'M04.webp','axis':'power'},{'img':'M01.webp','axis':'mind'},{'img':'M03.webp','axis':'heart'}]},
    {'part':2,'q':'迷ったとき、頼りにしたいのは？','qen':'When lost, what do you trust?',
     'cards':[{'img':'M02.webp','axis':'spirit'},{'img':'M10.webp','axis':'shadow'},{'img':'M07.webp','axis':'power'}]},
    {'part':2,'q':'旅の仲間にするなら、誰を選ぶ？','qen':'Who would you choose as your travel companion?',
     'cards':[{'img':'M06.webp','axis':'heart'},{'img':'M09.webp','axis':'mind'},{'img':'M13.webp','axis':'shadow'},{'img':'M07.webp','axis':'power'},{'img':'M17.webp','axis':'spirit'},{'img':'M00.webp','axis':'wildcard'}]},
    {'part':2,'q':'あなたの師匠になるのは？','qen':'Who would be your mentor?',
     'cards':[{'img':'M08.webp','axis':'power'},{'img':'M05.webp','axis':'spirit'},{'img':'M14.webp','axis':'heart'}]},
    {'part':2,'q':'深夜、語り明かすとしたら何を語りたい？','qen':'If you could talk until dawn, what would you talk about?',
     'cards':[{'img':'M15.webp','axis':'shadow'},{'img':'M11.webp','axis':'mind'},{'img':'M17.webp','axis':'spirit'},{'img':'M16.webp','axis':'power'},{'img':'M19.webp','axis':'heart'},{'img':'M21.webp','axis':'wildcard'}]},
    {'part':2,'q':'壁にぶつかったとき、あなたの心は？','qen':'When you hit a wall, where does your heart go?',
     'cards':[{'img':'M19.webp','axis':'heart'},{'img':'M12.webp','axis':'shadow'},{'img':'M16.webp','axis':'power'}]},
    {'part':2,'q':'夜明け前、あなたを導くのは？','qen':'Before dawn, what guides you?',
     'cards':[{'img':'M20.webp','axis':'mind'},{'img':'M18.webp','axis':'spirit'},{'img':'M04.webp','axis':'power'}]},
    {'part':2,'q':'あなたを理解してくれるのは？','qen':'Who truly understands you?',
     'cards':[{'img':'M13.webp','axis':'shadow'},{'img':'M03.webp','axis':'heart'},{'img':'M02.webp','axis':'spirit'},{'img':'M08.webp','axis':'power'},{'img':'M09.webp','axis':'mind'},{'img':'M00.webp','axis':'wildcard'}]},
    {'part':2,'q':'世界を変えるなら、何を手に取る？','qen':'To change the world, what would you reach for?',
     'cards':[{'img':'M07.webp','axis':'power'},{'img':'M01.webp','axis':'mind'},{'img':'M10.webp','axis':'shadow'}]},
    {'part':2,'q':'あなたの魂が一番安らぐのは、どんな瞬間？','qen':'When does your soul feel most at peace?',
     'cards':[{'img':'M05.webp','axis':'spirit'},{'img':'M06.webp','axis':'heart'},{'img':'M09.webp','axis':'mind'}]},
    {'part':2,'q':'未知の扉の向こうはどんな世界？','qen':'What kind of world lies beyond the unknown door?',
     'cards':[{'img':'M08.webp','axis':'power'},{'img':'M10.webp','axis':'shadow'},{'img':'M00.webp','axis':'wildcard'}]},
    {'part':2,'q':'大切な人に贈りたい力は？','qen':'What power would you gift to someone you love?',
     'cards':[{'img':'M11.webp','axis':'mind'},{'img':'M14.webp','axis':'heart'},{'img':'M17.webp','axis':'spirit'}]},
    {'part':2,'q':'手放したとき、残るものは？','qen':'When you let go, what remains?',
     'cards':[{'img':'M12.webp','axis':'shadow'},{'img':'M18.webp','axis':'spirit'},{'img':'M21.webp','axis':'wildcard'},{'img':'M08.webp','axis':'power'},{'img':'M14.webp','axis':'heart'},{'img':'M20.webp','axis':'mind'}]},
    {'part':2,'q':'あなたが一番輝ける場所は？','qen':'Where do you shine brightest?',
     'cards':[{'img':'M19.webp','axis':'heart'},{'img':'M16.webp','axis':'power'},{'img':'M00.webp','axis':'wildcard'}]},
    {'part':2,'q':'この旅の終わりに、誰として立っていたい？','qen':'At the end of this journey, who do you want to be?',
     'cards':[{'img':'M20.webp','axis':'mind'},{'img':'M15.webp','axis':'shadow'},{'img':'M21.webp','axis':'wildcard'},{'img':'M04.webp','axis':'power'},{'img':'M19.webp','axis':'heart'},{'img':'M17.webp','axis':'spirit'}]},
    // HTML: Part 3 Court Cards — court 属性で集計（axisではなくcourt）
    {'part':3,'q':'あなたの情熱の形は？','qen':'What shape does your passion take?',
     'cards':[{'img':'W11.webp','court':'page'},{'img':'W12.webp','court':'knight'},{'img':'W13.webp','court':'queen'},{'img':'W14.webp','court':'king'}]},
    {'part':3,'q':'奇跡が目の前に降りた瞬間のあなたは誰？','qen':'When a miracle descends before you, who are you?',
     'cards':[{'img':'C11.webp','court':'page'},{'img':'C12.webp','court':'knight'},{'img':'C13.webp','court':'queen'},{'img':'C14.webp','court':'king'}]},
    {'part':3,'q':'戦いの時期が迫る。あなたはどう剣を構える？','qen':'Battle draws near. How do you hold your sword?',
     'cards':[{'img':'S11.webp','court':'page'},{'img':'S12.webp','court':'knight'},{'img':'S13.webp','court':'queen'},{'img':'S14.webp','court':'king'}]},
    {'part':3,'q':'あなたが築きたいものは？','qen':'What do you want to build?',
     'cards':[{'img':'P11.webp','court':'page'},{'img':'P12.webp','court':'knight'},{'img':'P13.webp','court':'queen'},{'img':'P14.webp','court':'king'}]},
  ];
  static const _partNames = {1:'PART 1: MINOR ARCANA',2:'PART 2: MAJOR ARCANA',3:'PART 3: COURT CARDS'};

  int _roundIdx = 0;
  final Map<String, int> _scores = {'power':0,'mind':0,'spirit':0,'shadow':0,'heart':0};
  // HTML: TD.courtSelections — Part 3 で選ばれた court type を記録
  final List<String> _courtSelections = [];
  // HTML: TD.selections — tiebreak 用に全選択を記録
  final List<Map<String, String>> _selections = [];

  String _screen = 'intro'; // intro, round, partTrans, forging, reveal
  int? _selectedCard;
  int _lastPart = 0;
  late AnimationController _revealCtrl;
  String _revealTitleJP = '', _revealTitleEN = '';
  String _revealClassEN = '', _revealClassJP = '';
  String _revealLightJP = '', _revealShadowJP = '', _revealAxis = '';

  @override
  void initState() { super.initState(); _revealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 7000)); }
  @override
  void dispose() { _revealCtrl.dispose(); super.dispose(); }

  void _beginRounds() => setState(() { _screen = 'round'; _lastPart = _rounds[0]['part'] as int; });

  void _selectCard(int idx, String axisOrCourt) {
    setState(() => _selectedCard = idx);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final round = _rounds[_roundIdx];
      final part = round['part'] as int;
      final card = (round['cards'] as List)[idx] as Map<String, dynamic>;

      if (part == 1 || part == 2) {
        final axis = card['axis'] as String? ?? axisOrCourt;
        _selections.add({'axis': axis});
        if (axis == 'wildcard') {
          // HTML: applyWildcard() — boost lowest axis
          int minVal = 999;
          for (final v in _scores.values) { if (v < minVal) minVal = v; }
          for (final k in ['power','mind','spirit','shadow','heart']) {
            if (_scores[k] == minVal) { _scores[k] = _scores[k]! + 1; break; }
          }
        } else {
          _scores[axis] = (_scores[axis] ?? 0) + 1;
        }
      } else if (part == 3) {
        // HTML: TD.courtSelections.push(card.court)
        final court = card['court'] as String? ?? 'page';
        _courtSelections.add(court);
        _selections.add({'court': court});
      }

      if (_roundIdx < _rounds.length - 1) {
        final nextPart = _rounds[_roundIdx + 1]['part'] as int;
        final curPart = _rounds[_roundIdx]['part'] as int;
        setState(() { _roundIdx++; _selectedCard = null; });
        if (nextPart != curPart) {
          setState(() => _screen = 'partTrans');
          _lastPart = nextPart;
          Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _screen = 'round'); });
        }
      } else {
        setState(() => _screen = 'forging');
        Future.delayed(const Duration(seconds: 3), () { if (mounted) _finishDiagnosis(); });
      }
    });
  }

  void _finishDiagnosis() {
    // HTML: determineFinalAxis() — with tiebreak (last selected among tied)
    final axes = ['power','mind','spirit','shadow','heart'];
    int maxScore = 0;
    final winners = <String>[];
    for (final a in axes) {
      if ((_scores[a] ?? 0) > maxScore) {
        maxScore = _scores[a]!;
        winners.clear();
        winners.add(a);
      } else if ((_scores[a] ?? 0) == maxScore) {
        winners.add(a);
      }
    }
    String topAxis;
    if (winners.length == 1) {
      topAxis = winners[0];
    } else {
      // Tiebreak: last selected axis among tied
      topAxis = winners[0];
      for (int j = _selections.length - 1; j >= 0; j--) {
        final sel = _selections[j];
        if (sel['axis'] != null && sel['axis'] != 'wildcard' && winners.contains(sel['axis'])) {
          topAxis = sel['axis']!;
          break;
        }
      }
    }

    // HTML: determineCourt() — tally Part 3 courtSelections, >=2 wins, else 'mixed'
    final courtCounts = {'page':0,'knight':0,'queen':0,'king':0};
    for (final c in _courtSelections) {
      courtCounts[c] = (courtCounts[c] ?? 0) + 1;
    }
    String court = 'mixed';
    for (final t in ['page','knight','queen','king']) {
      if ((courtCounts[t] ?? 0) >= 2) { court = t; break; }
    }

    // HTML: TITLE_CLASSES[axis][court]
    final cls = titleData.getClassByAxisCourt(topAxis, court);
    if (cls == null) { Navigator.of(context).pop(null); return; }

    // HTML: getSunSign/getMoonSign → TITLE_144 lookup
    final sunSign = titleData.getSunSign(_profile?.birthDate ?? '');
    final moonSign = titleData.getMoonSign(_profile?.birthDate ?? '', _profile?.birthTime ?? '');
    final t144 = titleData.title144[sunSign]?[moonSign];

    // HTML: mainTitle = {jp: t144.shadow, en: sunAdj.en + moonNoun.en, lightJP: t144.light}
    final sunA = titleData.sunAdj[sunSign];
    final moonN = titleData.moonNoun[moonSign];
    _revealTitleJP = t144?['shadow'] ?? '${sunA?['jp'] ?? ''}${moonN?['jp'] ?? ''}';
    _revealTitleEN = '${sunA?['en'] ?? ''} ${moonN?['en'] ?? ''}';
    _revealLightJP = t144?['light'] ?? (sunA?['jp'] ?? '');
    _revealShadowJP = cls.shadowJP;
    _revealClassEN = cls.nameEN;
    _revealClassJP = cls.nameJP;
    _revealAxis = topAxis;
    setState(() => _screen = 'reveal');
    _revealCtrl.forward();
  }

  SolaraProfile? get _profile => widget.profile;

  void _accept() {
    Navigator.of(context).pop({
      'lightJP': _revealLightJP, 'shadowJP': _revealShadowJP,
      'classEN': _revealClassEN, 'classJP': _revealClassJP, 'axis': _revealAxis,
      'titleJP': _revealTitleJP, 'titleEN': _revealTitleEN,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Container(
        decoration: const BoxDecoration(gradient: RadialGradient(
          center: Alignment.center, radius: 1.2, colors: [Color(0xFF0A1220), Color(0xFF020408)])),
        child: SafeArea(child: switch (_screen) {
          'round' => _buildRound(),
          'partTrans' => _buildPartTrans(),
          'forging' => _buildForging(),
          'reveal' => _buildReveal(),
          _ => _buildIntro(),
        }),
      ),
    );
  }

  Widget _buildIntro() => Center(child: Container(
    constraints: const BoxConstraints(maxWidth: 340),
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
    decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x1AFFFFFF))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('\u2726', style: TextStyle(fontSize: 28, color: Color(0xFFF9D976))),
      const SizedBox(height: 12),
      const Text('\u79f0\u53f7\u306e\u5100\u5f0f', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFF9D976))),
      const SizedBox(height: 8),
      const Text('\u30ab\u30fc\u30c9\u304c\u3042\u306a\u305f\u3092\u6620\u3057\u51fa\u3057\u307e\u3059\u3002\n28\u306e\u554f\u3044\u306b\u3001\u76f4\u611f\u3067\u7b54\u3048\u3066\u304f\u3060\u3055\u3044\u3002', textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Color(0xFFACACAC), height: 1.7)),
      const SizedBox(height: 24),
      GestureDetector(onTap: _beginRounds, child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(colors: [Color(0xFFF9D976), Color(0xFFE8A840)])),
        child: const Center(child: Text('\u59cb\u3081\u308b', style: TextStyle(color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700))))),
      const SizedBox(height: 12),
      GestureDetector(onTap: () => Navigator.pop(context),
        child: const Text('\u3042\u3068\u3067', style: TextStyle(fontSize: 11, color: Color(0x66ACACAC)))),
    ]),
  ));

  Widget _buildRound() {
    final r = _rounds[_roundIdx];
    final cards = r['cards'] as List;
    final progress = (_roundIdx + 1) / _rounds.length;
    return Stack(children: [
      Positioned(top: 0, left: 0, right: 0,
        child: LinearProgressIndicator(value: progress, minHeight: 3,
          backgroundColor: const Color(0x14FFFFFF), valueColor: const AlwaysStoppedAnimation(Color(0xFFF9D976)))),
      Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(children: [
          Text('${_roundIdx + 1} / ${_rounds.length}',
            style: const TextStyle(fontSize: 14, color: Color(0xCCF9D976), letterSpacing: 2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(_partNames[r['part']] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xB3F9D976), letterSpacing: 2)),
          const SizedBox(height: 16),
          Text(r['q'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA), height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(r['qen'] as String, style: const TextStyle(fontSize: 12, color: Color(0x80ACACAC)), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Expanded(child: Center(child: Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
            children: List.generate(cards.length, (i) {
              final c = cards[i] as Map;
              final selected = _selectedCard == i;
              final dimmed = _selectedCard != null && !selected;
              return GestureDetector(
                onTap: _selectedCard == null ? () => _selectCard(i, (c['axis'] ?? c['court'] ?? 'power') as String) : null,
                child: AnimatedContainer(duration: const Duration(milliseconds: 300),
                  width: cards.length <= 4 ? 140.0 : 110.0,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? const Color(0xFFF9D976) : const Color(0x33FFFFFF), width: selected ? 2 : 1),
                    color: selected ? const Color(0x1AF9D976) : const Color(0x08FFFFFF),
                    boxShadow: selected ? [const BoxShadow(color: Color(0x66F9D976), blurRadius: 20)] : null),
                  child: AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: dimmed ? 0.25 : 1.0,
                    // HTML: <img src="card-images/XX.png"> — show card image
                    child: c['img'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/card-images/${c['img']}', fit: BoxFit.cover))
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(c['emoji'] as String? ?? '', style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(c['name'] as String? ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFFEAEAEA), fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        ])),
                ),
              );
            })))),
        ])),
    ]);
  }

  Widget _buildPartTrans() => Center(child: TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(seconds: 1),
    builder: (_, v, child) => Opacity(opacity: v, child: Text(_partNames[_lastPart] ?? '',
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 3)))));

  Widget _buildForging() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    TweenAnimationBuilder<double>(tween: Tween(begin: 0.9, end: 1.15), duration: const Duration(seconds: 1), curve: Curves.easeInOut,
      builder: (_, v, child) => Container(width: 120, height: 120,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0x99F9D976), Color(0x1AF9D976), Colors.transparent], stops: [0, 0.6, 0.8]),
          boxShadow: [BoxShadow(color: const Color(0x4DF9D976), blurRadius: 40 + (v - 0.9) * 160)]),
        transform: Matrix4.identity()..scale(v))),
    const SizedBox(height: 24),
    const Text('Forging your title...', style: TextStyle(fontSize: 14, color: Color(0xFFACACAC), letterSpacing: 2)),
  ]));

  Widget _buildReveal() => AnimatedBuilder(animation: _revealCtrl, builder: (_, child) {
    final t = _revealCtrl.value * 7;
    return Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Opacity(opacity: (t / 1.5).clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 20 * (1 - (t / 1.5).clamp(0.0, 1.0))),
            child: Text(_revealTitleJP, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFF9D976))))),
        const SizedBox(height: 4),
        Opacity(opacity: ((t - 0.3) / 1.2).clamp(0.0, 1.0),
          child: Text(_revealTitleEN, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0x80F9D976)))),
        Container(width: 200 * ((t - 1.8) / 1.0).clamp(0.0, 1.0), height: 1, margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFF9D976), Colors.transparent]))),
        Opacity(opacity: ((t - 2.8) / 0.8).clamp(0.0, 1.0),
          child: Transform.scale(scale: 1.0 + 0.5 * (1 - ((t - 2.8) / 0.8).clamp(0.0, 1.0)),
            child: Text('\u2014 $_revealClassJP / $_revealClassEN \u2014', textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA), letterSpacing: 3)))),
        const SizedBox(height: 20),
        Opacity(opacity: ((t - 3.8) / 1.2).clamp(0.0, 1.0),
          child: Text('\u2726 $_revealLightJP', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFFACACAC), height: 1.6))),
        const SizedBox(height: 6),
        Opacity(opacity: ((t - 5.0) / 1.2).clamp(0.0, 1.0),
          child: Text('\u2726 $_revealShadowJP', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFFACACAC), height: 1.6, fontStyle: FontStyle.italic))),
        const SizedBox(height: 28),
        Opacity(opacity: ((t - 6.2) / 0.8).clamp(0.0, 1.0),
          child: Column(children: [
            GestureDetector(onTap: _accept, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [Color(0xFFF9D976), Color(0xFFE8A840)])),
              child: const Center(child: Text('\u3053\u308c\u3067\u3044\u304f', style: TextStyle(color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700))))),
            const SizedBox(height: 12),
            GestureDetector(onTap: () => setState(() { _roundIdx = 0; _scores.updateAll((_, v) => 0); _selectedCard = null; _screen = 'intro'; _revealCtrl.reset(); }),
              child: const Text('\u3082\u3046\u4e00\u5ea6\u8a3a\u65ad\u3059\u308b', style: TextStyle(fontSize: 12, color: Color(0xFFACACAC), decoration: TextDecoration.underline))),
          ])),
      ])));
  });
}

/// Auto-inserts `/` after YYYY and MM for date input (YYYY/MM/DD format).
/// Only allows digits; max 8 digits (10 chars with slashes).
class _DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip non-digits
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) {
      // Max 8 digits: YYYYMMDD
      return oldValue;
    }

    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 4 || i == 6) buf.write('/');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();

    // Cursor at end
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ══════════════════════════════════════════════════
// ── Home Info Editor Page ──
// HTML exact: #homeOverlay (Nominatim search + lat/lng)
// ══════════════════════════════════════════════════

class _HomeEditorPage extends StatefulWidget {
  final SolaraProfile? profile;
  const _HomeEditorPage({this.profile});

  @override
  State<_HomeEditorPage> createState() => _HomeEditorPageState();
}

class _HomeEditorPageState extends State<_HomeEditorPage> {
  late final TextEditingController _nameCtrl;
  double? _lat;
  double? _lng;
  String _searchResult = '';
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.homeName ?? '');
    if (p != null && p.homeLat != 0) _lat = p.homeLat;
    if (p != null && p.homeLng != 0) _lng = p.homeLng;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _nameCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _searching = true; _searchResult = ''; });
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=1&accept-language=ja',
      );
      final resp = await http.get(uri, headers: {'User-Agent': 'Solara/1.0'});
      final data = json.decode(resp.body) as List;
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat'] as String);
        final lng = double.parse(data[0]['lon'] as String);
        final display = (data[0]['display_name'] as String).length > 50
            ? (data[0]['display_name'] as String).substring(0, 50)
            : data[0]['display_name'] as String;
        setState(() { _lat = lat; _lng = lng; _searchResult = display; _searching = false; });
      } else {
        setState(() { _searchResult = '見つかりませんでした'; _searching = false; });
      }
    } catch (_) {
      setState(() { _searchResult = '通信エラー'; _searching = false; });
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _lat == null || _lng == null) return;

    final p = widget.profile ?? const SolaraProfile();
    final updated = SolaraProfile(
      name: p.name,
      birthDate: p.birthDate,
      birthTime: p.birthTime,
      birthTimeUnknown: p.birthTimeUnknown,
      birthPlace: p.birthPlace,
      birthLat: p.birthLat,
      birthLng: p.birthLng,
      birthTz: p.birthTz,
      homeName: name,
      homeLat: _lat!,
      homeLng: _lng!,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('🏠 自宅（現住所）', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), letterSpacing: 1)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x14FFFFFF)),
                      child: const Center(child: Text('✕', style: TextStyle(fontSize: 18, color: Color(0xFFACACAC)))),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // Search
                const Text('住所・地名', style: TextStyle(fontSize: 12, color: Color(0xFFACACAC), letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: _input(_nameCtrl, '例: 東京都渋谷区')),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _searching ? null : _search,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [Color(0xFFF9D976), Color(0xFFE8A840)]),
                      ),
                      child: Text(_searching ? '...' : '検索',
                        style: const TextStyle(color: Color(0xFF0A0A14), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
                if (_searchResult.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_searchResult, style: const TextStyle(fontSize: 11, color: Color(0xFF6CC070))),
                  ),
                const SizedBox(height: 8),

                // Lat/Lng
                Row(children: [
                  Expanded(child: _readonlyField('緯度', _lat?.toStringAsFixed(4) ?? '')),
                  const SizedBox(width: 8),
                  Expanded(child: _readonlyField('経度', _lng?.toStringAsFixed(4) ?? '')),
                ]),
                const SizedBox(height: 16),

                // Save
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [Color(0xFFF9D976), Color(0xFFE8A840)]),
                    ),
                    child: const Center(child: Text('保存する',
                      style: TextStyle(color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700))),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(color: Color(0xFFEAEAEA), fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x40FFFFFF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0x0FFFFFFF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1EFFFFFF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1EFFFFFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x66F9D976))),
    ),
  );

  Widget _readonlyField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFACACAC))),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1EFFFFFF)),
        ),
        child: Text(value.isEmpty ? '—' : value,
          style: TextStyle(fontSize: 14, color: value.isEmpty ? const Color(0x40FFFFFF) : const Color(0xFFEAEAEA))),
      ),
    ],
  );
}
