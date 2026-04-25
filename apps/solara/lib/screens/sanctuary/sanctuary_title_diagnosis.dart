import 'package:flutter/material.dart';

import '../../utils/solara_storage.dart';
import '../../utils/title_data.dart' as title_data;

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
    final cls = title_data.getClassByAxisCourt(topAxis, court);
    if (cls == null) { Navigator.of(context).pop(null); return; }

    // HTML: getSunSign/getMoonSign → TITLE_144 lookup
    final sunSign = title_data.getSunSign(_profile?.birthDate ?? '');
    final moonSign = title_data.getMoonSign(_profile?.birthDate ?? '', _profile?.birthTime ?? '');
    final t144 = title_data.title144[sunSign]?[moonSign];

    // HTML: mainTitle = {jp: t144.shadow, en: sunAdj.en + moonNoun.en, lightJP: t144.light}
    final sunA = title_data.sunAdj[sunSign];
    final moonN = title_data.moonNoun[moonSign];
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
        transform: Matrix4.identity()..scaleByDouble(v, v, v, 1.0))),
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
