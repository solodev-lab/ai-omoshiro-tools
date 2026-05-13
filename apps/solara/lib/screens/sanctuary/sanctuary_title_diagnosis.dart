import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/solara_storage.dart';
import '../../utils/title_data.dart' as title_data;
import '../../widgets/class_card.dart';
import '../../widgets/info_popup.dart';

// ══════════════════════════════════════════════════
// ── Title Diagnosis Page ──
// HTML: #titleDiagOverlay
// ══════════════════════════════════════════════════

class SanctuaryTitleDiagnosisPage extends StatefulWidget {
  final SolaraProfile? profile;
  const SanctuaryTitleDiagnosisPage({super.key, this.profile});
  @override
  State<SanctuaryTitleDiagnosisPage> createState() => _SanctuaryTitleDiagnosisPageState();
}

class _SanctuaryTitleDiagnosisPageState extends State<SanctuaryTitleDiagnosisPage>
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

  String _screen = 'summoning'; // summoning, intro, round, partTrans, forging, reveal
  int? _selectedCard;
  int _lastPart = 0;
  late AnimationController _revealCtrl;
  late AnimationController _summoningCtrl;
  late AnimationController _forgingCtrl;
  late AnimationController _flipCtrl;
  bool _showShadowSide = false;
  String _revealTitleJP = '', _revealTitleEN = '';
  String _revealClassEN = '', _revealClassJP = '';
  String _revealLightJP = '', _revealShadowJP = '', _revealAxis = '', _revealCourt = '';
  String _revealClsLightJP = ''; // クラス Light テキスト (cls.lightJP)

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 7000));
    _summoningCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4400));
    _forgingCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    // 召喚演出: 起動と同時に Haptic + アニメ開始、2.4秒後に Intro へ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.heavyImpact();
      _summoningCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 4400), () {
      if (mounted) setState(() => _screen = 'intro');
    });
  }
  @override
  void dispose() {
    _revealCtrl.dispose();
    _summoningCtrl.dispose();
    _forgingCtrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  void _beginRounds() {
    HapticFeedback.mediumImpact();
    _lastPart = _rounds[0]['part'] as int; // = 1
    setState(() => _screen = 'partTrans');
    Future.delayed(const Duration(milliseconds: 3300), () {
      if (mounted) setState(() => _screen = 'round');
    });
  }

  void _selectCard(int idx, String axisOrCourt) {
    HapticFeedback.lightImpact();
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
          // wildcard: 最低スコア軸を +1。
          // 旧実装は順序 power→mind→spirit→shadow→heart で先頭優先 → power バイアス。
          // 新実装は同点なら占星術シードで公平に選択する。
          const allAxes = ['power', 'mind', 'spirit', 'shadow', 'heart'];
          int minVal = 999;
          for (final v in _scores.values) {
            if (v < minVal) minVal = v;
          }
          final minAxes =
              allAxes.where((k) => _scores[k] == minVal).toList();
          final pick = _pickByAstroSeed(minAxes);
          _scores[pick] = (_scores[pick] ?? 0) + 1;
          // ── デバッグ: wildcard の決定経路 ──
          debugPrint(
            '[Solara Title] R${_roundIdx + 1} (Part$part) pick=wildcard '
            'minAxes=$minAxes → boost=$pick '
            '(${minAxes.length > 1 ? "astro-seed" : "single"}) '
            'scores=$_scores',
          );
        } else {
          _scores[axis] = (_scores[axis] ?? 0) + 1;
          // ── デバッグ: 通常選択 ──
          debugPrint(
            '[Solara Title] R${_roundIdx + 1} (Part$part) pick=$axis '
            'scores=$_scores',
          );
        }
      } else if (part == 3) {
        // HTML: TD.courtSelections.push(card.court)
        final court = card['court'] as String? ?? 'page';
        _courtSelections.add(court);
        _selections.add({'court': court});
        // ── デバッグ: 選択したコートと累積選択履歴 ──
        debugPrint(
          '[Solara Title] R${_roundIdx + 1} (Part$part) pick=$court '
          'courts=$_courtSelections',
        );
      }

      if (_roundIdx < _rounds.length - 1) {
        final nextPart = _rounds[_roundIdx + 1]['part'] as int;
        final curPart = _rounds[_roundIdx]['part'] as int;
        setState(() { _roundIdx++; _selectedCard = null; });
        if (nextPart != curPart) {
          HapticFeedback.mediumImpact();
          setState(() => _screen = 'partTrans');
          _lastPart = nextPart;
          Future.delayed(const Duration(milliseconds: 3300), () { if (mounted) setState(() => _screen = 'round'); });
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() => _screen = 'forging');
        _forgingCtrl.forward();
        Future.delayed(const Duration(milliseconds: 4200), () { if (mounted) _finishDiagnosis(); });
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

    // court 決定: 最大票数 court が単独 (>=2) なら確定、同点なら占星術シードで公平に。
    // 旧実装は順序 page→knight→queen→king で先頭優先 → king バイアス (出ない)。
    final courtCounts = {'page': 0, 'knight': 0, 'queen': 0, 'king': 0};
    for (final c in _courtSelections) {
      courtCounts[c] = (courtCounts[c] ?? 0) + 1;
    }
    int maxCourtCount = 0;
    courtCounts.forEach((_, v) {
      if (v > maxCourtCount) maxCourtCount = v;
    });
    String court;
    String courtRoute; // デバッグ用: 決定経路
    if (maxCourtCount < 2) {
      // 全部 1 票 (1+1+1+1) または全部 0 → 混合型
      court = 'mixed';
      courtRoute = 'all-tied → mixed';
    } else {
      final maxCourts = courtCounts.entries
          .where((e) => e.value == maxCourtCount)
          .map((e) => e.key)
          .toList();
      if (maxCourts.length == 1) {
        court = maxCourts.first;
        courtRoute = 'single-max ($maxCourtCount votes)';
      } else {
        court = _pickByAstroSeed(maxCourts);
        courtRoute = 'tied(${maxCourts.join(",")}) → astro-seed';
      }
    }

    // ── デバッグ: 最終決定の各段階を出力 ──
    final sunSignDbg = title_data.getSunSign(_profile?.birthDate ?? '');
    final moonSignDbg = title_data.getMoonSign(
        _profile?.birthDate ?? '', _profile?.birthTime ?? '');
    final sunIdxDbg = _zodiacOrder.indexOf(sunSignDbg);
    final moonIdxDbg = _zodiacOrder.indexOf(moonSignDbg);
    final astroSeedDbg =
        (sunIdxDbg >= 0 ? sunIdxDbg : 0) * 12 + (moonIdxDbg >= 0 ? moonIdxDbg : 0);
    debugPrint('[Solara Title] ═══ 診断結果 ═══');
    debugPrint('[Solara Title] scores       : $_scores');
    debugPrint('[Solara Title] selections   : $_selections');
    debugPrint('[Solara Title] courtCounts  : $courtCounts');
    debugPrint('[Solara Title] courtList    : $_courtSelections');
    debugPrint(
        '[Solara Title] astroSeed    : $astroSeedDbg ($sunSignDbg×$moonSignDbg)');
    debugPrint('[Solara Title] → topAxis    : $topAxis (winners=$winners)');
    debugPrint('[Solara Title] → court      : $court [$courtRoute]');

    // HTML: TITLE_CLASSES[axis][court]
    final cls = title_data.getClassByAxisCourt(topAxis, court);
    if (cls == null) {
      debugPrint('[Solara Title] ❌ getClassByAxisCourt returned null for $topAxis/$court');
      Navigator.of(context).pop(null);
      return;
    }
    debugPrint('[Solara Title] → class      : ${cls.nameJP} (${cls.nameEN})');

    // HTML: getSunSign/getMoonSign → TITLE_144 lookup
    final sunSign = title_data.getSunSign(_profile?.birthDate ?? '');
    final moonSign = title_data.getMoonSign(_profile?.birthDate ?? '', _profile?.birthTime ?? '');
    final t144 = title_data.title144[sunSign]?[moonSign];
    debugPrint('[Solara Title] → sun/moon   : $sunSign × $moonSign');
    debugPrint('[Solara Title] → t144.light : ${t144?['light']}');
    debugPrint('[Solara Title] → t144.shadow: ${t144?['shadow']}');
    debugPrint('[Solara Title] ═══════════════');

    // HTML: mainTitle = {jp: t144.shadow, en: sunAdj.en + moonNoun.en, lightJP: t144.light}
    final sunA = title_data.sunAdj[sunSign];
    final moonN = title_data.moonNoun[moonSign];
    _revealTitleJP = t144?['shadow'] ?? '${sunA?['jp'] ?? ''}${moonN?['jp'] ?? ''}';
    _revealTitleEN = '${sunA?['en'] ?? ''} ${moonN?['en'] ?? ''}';
    _revealLightJP = t144?['light'] ?? (sunA?['jp'] ?? '');
    _revealClsLightJP = cls.lightJP;
    _revealShadowJP = cls.shadowJP;
    _revealClassEN = cls.nameEN;
    _revealClassJP = cls.nameJP;
    _revealAxis = topAxis;
    _revealCourt = court;
    HapticFeedback.heavyImpact();
    setState(() => _screen = 'reveal');
    _revealCtrl.forward();
    // Reveal フィナーレで脈動的に振動
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) HapticFeedback.heavyImpact();
    });
  }

  SolaraProfile? get _profile => widget.profile;

  /// 同点解消用: 太陽星座 × 月星座から決定的に 1 つ選ぶ。
  /// - 占星術的シード (12 × 12 = 144 通り)
  /// - 順序バイアス (page > knight ... や power > mind ...) を回避
  /// - 同じ太陽×月星座の人は同じ結果 (占いの再現性 + 一貫性)
  /// - title_data の sunAdj/moonNoun と同じ zodiac 順を採用
  /// - 候補が空なら空文字 (実用上は呼び出し側で保証)
  static const _zodiacOrder = [
    'aries', 'taurus', 'gemini', 'cancer',
    'leo', 'virgo', 'libra', 'scorpio',
    'sagittarius', 'capricorn', 'aquarius', 'pisces',
  ];

  String _pickByAstroSeed(List<String> candidates) {
    if (candidates.isEmpty) return '';
    if (candidates.length == 1) return candidates.first;
    final sun = title_data.getSunSign(_profile?.birthDate ?? '');
    final moon = title_data.getMoonSign(
        _profile?.birthDate ?? '', _profile?.birthTime ?? '');
    final sunIdx = _zodiacOrder.indexOf(sun);
    final moonIdx = _zodiacOrder.indexOf(moon);
    // sun を 12 進数の上位桁、moon を下位桁にして 144 通りの seed を作る
    final seed = (sunIdx >= 0 ? sunIdx : 0) * 12 + (moonIdx >= 0 ? moonIdx : 0);
    return candidates[seed % candidates.length];
  }

  void _accept() {
    Navigator.of(context).pop({
      'lightJP': _revealLightJP, 'shadowJP': _revealShadowJP,
      'classEN': _revealClassEN, 'classJP': _revealClassJP,
      'axis': _revealAxis, 'court': _revealCourt,
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
          'summoning' => _buildSummoning(),
          'round' => _buildRound(),
          'partTrans' => _buildPartTrans(),
          'forging' => _buildForging(),
          'reveal' => _buildReveal(),
          _ => _buildIntro(),
        }),
      ),
    );
  }

  // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
  // \u53ec\u559a\u6f14\u51fa (Summoning) \u2014 \u8d77\u52d5\u76f4\u5f8c\u306e\u6697\u8ee2 + \u91d1\u5149\u51fa\u73fe
  // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
  Widget _buildSummoning() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // \u2500\u2500 \u80cc\u666f: \u9ed2+\u91d1\u7c92\u5b50\uff08\u30d5\u30a9\u30fc\u30eb\u30d0\u30c3\u30af\uff09\u2500\u2500
        Image.asset(
          'assets/diagnosis-bg/ceremony.webp',
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Container(color: Colors.black),
        ),
        // \u2500\u2500 \u53ec\u559a\u30c6\u30ad\u30b9\u30c8\u300c\u2726 THE CEREMONY \u2726\u300d\u2500\u2500
        Center(
          child: AnimatedBuilder(
            animation: _summoningCtrl,
            builder: (ctx, child) {
              final t = _summoningCtrl.value;
              final opacity = t < 0.15
                  ? t / 0.15
                  : (t > 0.85 ? (1.0 - t) / 0.15 : 1.0);
              final scale = 0.9 + 0.15 * (t.clamp(0.0, 0.5) / 0.5);
              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '\u2726',
                  style: TextStyle(
                    fontSize: 40,
                    color: Color(0xFFF9D976),
                    shadows: [
                      Shadow(color: Color(0xFFF9D976), blurRadius: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'THE CEREMONY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    color: Color(0xFFF9D976),
                    letterSpacing: 10,
                    fontWeight: FontWeight.w300,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 8),
                      Shadow(color: Color(0x66F9D976), blurRadius: 32),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '\u2014 \u79f0\u53f7\u306e\u5100\u5f0f \u2014',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0x99F9D976),
                    letterSpacing: 4,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
  // Intro \u753b\u9762 \u2014 Mucha \u80cc\u666f + slide-in + pulse \u30dc\u30bf\u30f3
  // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
  Widget _buildIntro() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // \u2500\u2500 \u80cc\u666f: Mucha\u98a8 \u796d\u58c7 (5\u8ef8\u30b7\u30f3\u30dc\u30eb+\u308d\u3046\u305d\u304f) \u2500\u2500
        Image.asset(
          'assets/diagnosis-bg/intro.webp',
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF1A0820), Color(0xFF050208)],
              ),
            ),
          ),
        ),
        // \u2500\u2500 \u4e2d\u592e\u30d3\u30cd\u30c3\u30c8 \u2500\u2500
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        // \u2500\u2500 \u4e2d\u592e\u30b3\u30f3\u30c6\u30f3\u30c4 \u2500\u2500
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOut,
            builder: (ctx, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '\u2726',
                      style: TextStyle(
                        fontSize: 32,
                        color: Color(0xFFF9D976),
                        shadows: [Shadow(color: Color(0xFFF9D976), blurRadius: 20)],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '\u79f0\u53f7\u306e\u5100\u5f0f',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF9D976),
                        letterSpacing: 8,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 10),
                          Shadow(color: Color(0x80F9D976), blurRadius: 24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'THE TITLE CEREMONY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0x99F9D976),
                        letterSpacing: 3,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // \u88c5\u98fe\u30e9\u30a4\u30f3
                    Container(
                      width: 80,
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Color(0xFFF9D976), Colors.transparent],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '\u30ab\u30fc\u30c9\u304c\u3042\u306a\u305f\u3092\u6620\u3057\u51fa\u3057\u307e\u3059\u3002\n28\u306e\u554f\u3044\u306b\u3001\u76f4\u611f\u3067\u7b54\u3048\u3066\u304f\u3060\u3055\u3044\u3002',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xCCEAEAEA),
                        height: 1.8,
                        letterSpacing: 1,
                        shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // \u8108\u52d5\u3059\u308b\u300c\u59cb\u3081\u308b\u300d\u30dc\u30bf\u30f3
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1800),
                      curve: Curves.easeInOut,
                      builder: (ctx, pulse, child) {
                        // 0\u21921\u3067\u8108\u52d5: 0, 1, 0 \u306e\u30b5\u30a4\u30f3\u6ce2\u76f8\u5f53
                        final p = (pulse * 2 * 3.14159).remainder(2 * 3.14159);
                        final intensity = 0.5 + 0.5 * (p < 3.14159 ? p / 3.14159 : (6.28318 - p) / 3.14159);
                        return GestureDetector(
                          onTap: _beginRounds,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF9D976), Color(0xFFE8A840)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF9D976).withValues(alpha: 0.3 + 0.4 * intensity),
                                  blurRadius: 24 + 16 * intensity,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '\u59cb\u3081\u308b',
                                style: TextStyle(
                                  color: Color(0xFF0A0A14),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      onEnd: () {
                        // \u6c38\u7d9a\u8108\u52d5: setState \u3067\u518d\u30ad\u30c3\u30af\u3057\u306a\u3044\u3068\u518d\u751f\u3055\u308c\u306a\u3044\u306e\u3067\u3001
                        // \u3053\u3053\u3067 rebuild \u30c8\u30ea\u30ac\u30fc\uff08\u7c21\u6613\u30eb\u30fc\u30d7\uff09
                        if (mounted && _screen == 'intro') setState(() {});
                      },
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        '\u3042\u3068\u3067',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0x88ACACAC),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // \u2500\u2500 \u53f3\u4e0a i \u30dc\u30bf\u30f3 (\u79f0\u53f7\u306e\u4ed5\u7d44\u307f\u3092\u8868\u793a) \u2500\u2500
        Positioned(
          top: 12,
          right: 12,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => _showHowItWorks(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x66000000),
                  border: Border.all(color: const Color(0x66F9D976), width: 1),
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xCCF9D976),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// \u79f0\u53f7\u306e\u4ed5\u7d44\u307f\u8aac\u660e\u30dd\u30c3\u30d7\u30a2\u30c3\u30d7
  void _showHowItWorks(BuildContext context) {
    showInfoPopup(
      context: context,
      borderColor: const Color(0xFFF9D976),
      child: const _HowItWorksContent(),
    );
  }

  Widget _buildRound() {
    final r = _rounds[_roundIdx];
    final cards = r['cards'] as List;
    final progress = (_roundIdx + 1) / _rounds.length;
    // 質問+カード選択画面は端末によりカードが画面下端で切れるため
    // SingleChildScrollView で全要素を可視化 (スクロール可能化)。
    // タイトル/PART遷移画面 (_buildPartTrans) はスクロール対応しない。
    return Stack(children: [
      Positioned(top: 0, left: 0, right: 0,
        child: LinearProgressIndicator(value: progress, minHeight: 3,
          backgroundColor: const Color(0x14FFFFFF), valueColor: const AlwaysStoppedAnimation(Color(0xFFF9D976)))),
      Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: [
            Text('${_roundIdx + 1} / ${_rounds.length}',
              style: const TextStyle(fontSize: 15, color: Color(0xCCF9D976), letterSpacing: 2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_partNames[r['part']] ?? '', style: const TextStyle(fontSize: 15, color: Color(0xB3F9D976), letterSpacing: 2)),
            const SizedBox(height: 16),
            Text(r['q'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA), height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(r['qen'] as String, style: const TextStyle(fontSize: 15, color: Color(0x80ACACAC)), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
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
                            Text(c['name'] as String? ?? '', style: const TextStyle(fontSize: 15, color: Color(0xFFEAEAEA), fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                          ])),
                  ),
                );
              })),
            // 下端余白 (スクロール末尾でカード下に少し空間を確保)
            const SizedBox(height: 24),
          ]))),
    ]);
  }

  Widget _buildPartTrans() {
    final raw = _partNames[_lastPart] ?? '';
    final parts = raw.split(':').map((s) => s.trim()).toList();
    final partNum = parts.isNotEmpty ? parts[0] : raw;       // "PART 2"
    final partTitle = parts.length > 1 ? parts[1] : '';      // "MAJOR ARCANA"

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 背景画像 (PART別、フォールバックでグラデーション) ──
        Image.asset(
          'assets/diagnosis-bg/part_$_lastPart.webp',
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF1A0820), Color(0xFF050208)],
              ),
            ),
          ),
        ),
        // ── 暗いビネット (タイトル可読性) ──
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.black.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.85),
              ],
            ),
          ),
        ),
        // ── タイトル (中央2行配置) ──
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (ctx, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - v)),
                child: child,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PART X (上、小さめ)
                Text(
                  partNum,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xCCF9D976),
                    letterSpacing: 8,
                    fontWeight: FontWeight.w300,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 16),
                // 装飾ライン
                Container(
                  width: 80,
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xFFF9D976), Colors.transparent],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // MAJOR ARCANA (下、大きく)
                Text(
                  partTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Color(0xFFF9D976),
                    letterSpacing: 6,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 12),
                      Shadow(color: Color(0x66F9D976), blurRadius: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════
  // Forging — 銀河背景 + 脈動オーブ + 多段テキスト
  // ════════════════════════════════════════════════
  Widget _buildForging() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 背景: 銀河・星雲 ──
        Image.asset(
          'assets/diagnosis-bg/forging.webp',
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.4,
                colors: [Color(0xFF1F0D38), Color(0xFF050208)],
              ),
            ),
          ),
        ),
        // ── 中央ビネット ──
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.9,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
        // ── 脈動オーブ + 多段テキスト ──
        Center(
          child: AnimatedBuilder(
            animation: _forgingCtrl,
            builder: (ctx, child) {
              final t = _forgingCtrl.value;
              // オーブ脈動 (0→1で 0.8→1.3→0.8 の繰返し)
              final orbScale = 0.85 + 0.35 * (1 - ((t * 4) % 1.0 - 0.5).abs() * 2);
              // テキスト3段階フェード
              final stage1Op = (t / 0.3).clamp(0.0, 1.0) - ((t - 0.3) / 0.2).clamp(0.0, 1.0);
              final stage2Op = ((t - 0.35) / 0.3).clamp(0.0, 1.0) - ((t - 0.65) / 0.2).clamp(0.0, 1.0);
              final stage3Op = ((t - 0.7) / 0.3).clamp(0.0, 1.0);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 脈動オーブ
                  Transform.scale(
                    scale: orbScale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFFFFFAEA),
                            Color(0xFFF9D976),
                            Color(0x66F9D976),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.3, 0.7, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF9D976).withValues(alpha: 0.6),
                            blurRadius: 60 + 60 * orbScale,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: const Color(0xFFE8A840).withValues(alpha: 0.4),
                            blurRadius: 120,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 多段テキスト（同じ高さに重ね、フェードで切替）
                  SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: stage1Op.clamp(0.0, 1.0),
                          child: const Text(
                            'あなたの星を読み取る…',
                            style: TextStyle(fontSize: 16, color: Color(0xFFEAEAEA), letterSpacing: 3),
                          ),
                        ),
                        Opacity(
                          opacity: stage2Op.clamp(0.0, 1.0),
                          child: const Text(
                            '運命が結ばれる…',
                            style: TextStyle(fontSize: 16, color: Color(0xFFEAEAEA), letterSpacing: 3),
                          ),
                        ),
                        Opacity(
                          opacity: stage3Op.clamp(0.0, 1.0),
                          child: const Text(
                            '称号が刻まれる…',
                            style: TextStyle(fontSize: 16, color: Color(0xFFF9D976), letterSpacing: 3, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  // Reveal — Light/Shadow 2面フリップ
  //   Front (Light): ✦ Light の言葉 + クラス名 + カード
  //   Back  (Shadow): t144.shadow タイトル + cls.shadowJP
  //   タップで画面全体が Y軸回転、両面切替
  // ══════════════════════════════════════════════════════
  void _toggleShadowSide() {
    if (_revealCtrl.value < 0.98) return;
    HapticFeedback.mediumImpact();
    if (_showShadowSide) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _showShadowSide = !_showShadowSide);
  }

  Widget _buildReveal() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 背景: 神殿 (reveal.webp) ──
        Image.asset(
          'assets/diagnosis-bg/reveal.webp',
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.4,
                colors: [Color(0xFF1A0820), Color(0xFF050208)],
              ),
            ),
          ),
        ),
        // ── 暗化ビネット (テキスト可読性) ──
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.78),
              ],
            ),
          ),
        ),
        // ── フリップする内容 (Light ⟷ Shadow) ──
        AnimatedBuilder(
          animation: Listenable.merge([_revealCtrl, _flipCtrl]),
          builder: (_, child) {
            final flip = _flipCtrl.value;
            final showBack = flip >= 0.5;
            final angle = flip * 3.14159265;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.14159265),
                      child: _buildRevealShadowSide(),
                    )
                  : _buildRevealLightSide(),
            );
          },
        ),
      ],
    );
  }

  // ── Front: Light side ─────────────────────────────────
  Widget _buildRevealLightSide() {
    // Reveal animation timeline (t = 0.0 → 7.0):
    //   0.0 — 1.5 : Light の言葉 fade in + slide
    //   1.0 — 2.0 : クラス名 (JP + EN)
    //   2.0 — 3.0 : 区切り線が伸びる
    //   2.8 — 4.5 : ClassCard が拡大しながら出現
    //   4.5 — 5.5 : Title EN (太陽×月の二つ名 英)
    //   5.8 — 6.6 : シャドー誘導ヒント
    //   6.2 — 7.0 : ボタン群
    final t = _revealCtrl.value * 7;
    final cls = title_data.getClassByAxisCourt(_revealAxis, _revealCourt);

    return GestureDetector(
      onTap: _toggleShadowSide,
      behavior: HitTestBehavior.opaque,
      child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Light の言葉 (最上段、ゴールド) ──
          Opacity(opacity: (t / 1.5).clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(0, 20 * (1 - (t / 1.5).clamp(0.0, 1.0))),
              child: Text('✦ $_revealLightJP ✦', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFF9D976), height: 1.5, letterSpacing: 1)))),
          const SizedBox(height: 10),
          // ── クラス名 ──
          if (cls != null)
            Opacity(opacity: ((t - 1.0) / 1.0).clamp(0.0, 1.0),
              child: Column(children: [
                Text(_revealClassJP, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFEAEAEA), letterSpacing: 6)),
                const SizedBox(height: 2),
                Text(_revealClassEN, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Color(0x80EAEAEA), letterSpacing: 3)),
              ])),
          // ── divider ──
          Container(width: 200 * ((t - 2.0) / 1.0).clamp(0.0, 1.0), height: 1, margin: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFF9D976), Colors.transparent]))),
          // ── ClassCard (メインビジュアル) ──
          if (cls != null)
            Opacity(opacity: ((t - 2.8) / 1.5).clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.85 + 0.15 * ((t - 2.8) / 1.5).clamp(0.0, 1.0),
                child: ClassCard(
                  classData: cls,
                  width: 260,
                  mode: ClassCardMode.none,
                  showGlow: true,
                ))),
          const SizedBox(height: 16),
          // ── クラス Light テキスト (カード下、Shadow 面と対をなす) ──
          Opacity(opacity: ((t - 4.5) / 1.0).clamp(0.0, 1.0),
            child: Text('✦ $_revealClsLightJP ✦', textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFFF9D976), height: 1.6, fontStyle: FontStyle.italic))),
          const SizedBox(height: 8),
          // ── Title EN (太陽×月の英語二つ名) ──
          Opacity(opacity: ((t - 5.0) / 1.0).clamp(0.0, 1.0),
            child: Text(_revealTitleEN, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0x80F9D976), letterSpacing: 2, fontStyle: FontStyle.italic))),
          const SizedBox(height: 18),
          // ── シャドー誘導ヒント ──
          Opacity(opacity: ((t - 6.0) / 0.8).clamp(0.0, 1.0),
            child: const Text('✦ タップしてシャドーを見る ✦',
              style: TextStyle(fontSize: 12, color: Color(0xAAF9D976), letterSpacing: 3))),
          const SizedBox(height: 24),
          // ── ボタン群 ──
          Opacity(opacity: ((t - 6.2) / 0.8).clamp(0.0, 1.0),
            child: Column(children: [
              GestureDetector(onTap: _accept, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [Color(0xFFF9D976), Color(0xFFE8A840)])),
                child: const Center(child: Text('これでいく', style: TextStyle(color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700))))),
              const SizedBox(height: 12),
              GestureDetector(onTap: () => setState(() { _roundIdx = 0; _scores.updateAll((_, v) => 0); _courtSelections.clear(); _selections.clear(); _selectedCard = null; _screen = 'intro'; _revealCtrl.reset(); _flipCtrl.reset(); _showShadowSide = false; }),
                child: const Text('もう一度診断する', style: TextStyle(fontSize: 15, color: Color(0xFFACACAC), decoration: TextDecoration.underline))),
            ])),
        ]))),
    );
  }

  // ── Back: Shadow side ─────────────────────────────────
  Widget _buildRevealShadowSide() {
    final cls = title_data.getClassByAxisCourt(_revealAxis, _revealCourt);
    return GestureDetector(
      onTap: _toggleShadowSide,
      behavior: HitTestBehavior.opaque,
      child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── 一言シャドー (タイトル、アメジスト) ──
          Text('✦ $_revealTitleJP ✦', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFC9A8E0), height: 1.5, letterSpacing: 1)),
          const SizedBox(height: 10),
          // ── クラス名 (SHADOW SIDE) ──
          if (cls != null)
            Column(children: [
              Text(_revealClassJP, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFD7BCEC), letterSpacing: 6)),
              const SizedBox(height: 2),
              Text('SHADOW SIDE', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: const Color(0xFFC9A8E0).withValues(alpha: 0.55), letterSpacing: 4)),
            ]),
          // ── divider (アメジスト) ──
          Container(width: 200, height: 1, margin: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFC9A8E0), Colors.transparent]))),
          // ── ClassCard (mode=none: 外側のテキスト群と重複しないよう画像のみ) ──
          if (cls != null)
            ClassCard(
              classData: cls,
              width: 260,
              mode: ClassCardMode.none,
              showGlow: true,
            ),
          const SizedBox(height: 18),
          // ── クラス Shadow テキスト ──
          Text('✦ $_revealShadowJP ✦', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFFD7BCEC), height: 1.6, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          // ── ライト誘導ヒント ──
          const Text('◀ タップしてライトに戻る',
            style: TextStyle(fontSize: 12, color: Color(0xAAC9A8E0), letterSpacing: 3)),
          const SizedBox(height: 24),
          // ── ボタン群 (シャドー配色) ──
          Column(children: [
            GestureDetector(onTap: _accept, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [Color(0xFFC9A8E0), Color(0xFF8C5BC0)])),
              child: const Center(child: Text('これでいく', style: TextStyle(color: Color(0xFF0A0A14), fontSize: 15, fontWeight: FontWeight.w700))))),
            const SizedBox(height: 12),
            GestureDetector(onTap: () => setState(() { _roundIdx = 0; _scores.updateAll((_, v) => 0); _courtSelections.clear(); _selections.clear(); _selectedCard = null; _screen = 'intro'; _revealCtrl.reset(); _flipCtrl.reset(); _showShadowSide = false; }),
              child: const Text('もう一度診断する', style: TextStyle(fontSize: 15, color: Color(0xFFACACAC), decoration: TextDecoration.underline))),
          ]),
        ]))),
    );
  }
}

// ══════════════════════════════════════════════════════
// 称号の仕組み説明 popup の中身
// (showInfoPopup の child に渡される。Shell側で × ボタンと外枠を提供)
// ══════════════════════════════════════════════════════
class _HowItWorksContent extends StatelessWidget {
  const _HowItWorksContent();

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFF9D976);
    const body = Color(0xFFEAEAEA);
    const sub = Color(0xCCACACAC);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル
            const Text(
              '✦ 称号の仕組み',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: gold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 14),

            // 1. 一言
            _section(
              num: '1',
              title: '生年月日 → 一言',
              body:
                  '太陽星座 × 月星座の組み合わせから、144通りの「一言の称号」が決まります。\n'
                  'これはあなた固有のもの。診断では変わりません。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 2. 5軸
            _section(
              num: '2',
              title: '28問の選択 → 5軸スコア',
              body:
                  'PART 1 (日常) と PART 2 (運命) の問いに、直感でカードを選ぶと、'
                  '5つの軸 (パワー・マインド・スピリット・シャドー・ハート) に'
                  '点数が加算されます。\n'
                  '最高得点の軸があなたの「気質」になります。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 3. コート
            _section(
              num: '3',
              title: 'PART 3 → コート (役職)',
              body:
                  '4問のコートカードで、page・knight・queen・king のうち'
                  '2回以上選んだものがあなたのコートに。'
                  'バラバラなら mixed (混合) になります。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 4. クラス
            _section(
              num: '4',
              title: '軸 × コート → 25クラス',
              body:
                  '5軸 × 5コート = 25種類のクラス (騎士・賢者・占星術師・忍者…) '
                  'から、あなたに合うクラスが1つ決まります。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 5. Light/Shadow
            _section(
              num: '5',
              title: 'Light面 / Shadow面',
              body:
                  '結果画面はタップすると、表 (Light=光) と裏 (Shadow=影) を'
                  '切替できます。\n'
                  '光は長所、影はユーモア混じりの「あるある」です。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 6. 同点処理 — 占星術シード
            _section(
              num: '6',
              title: '同点処理 — 占星術シード',
              body:
                  '軸やコートが同点になったとき、太陽星座 × 月星座'
                  ' (144通り) から1つに決めます。\n'
                  '判定の主役はあなたが選んだカードそのもの。違うカードを'
                  '選べば違う結果が出ます。\n'
                  '占星術シードは「審判が困ったときの最後の判定基準」のポジションです。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 18),

            // フッターメモ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x14F9D976),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x33F9D976)),
              ),
              child: const Text(
                '※ いつでももう一度診断できます。気質はその日の気分で動くもの。'
                '「いまの自分」を映す鏡として楽しんでください。',
                style: TextStyle(
                  fontSize: 12,
                  color: sub,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String num,
    required String title,
    required String body,
    required Color gold,
    required Color bodyColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold, width: 1),
              ),
              child: Text(
                num,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: gold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: gold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: bodyColor,
            ),
          ),
        ),
      ],
    );
  }
}
