// setState は part 元の State で定義されているが extension からの呼び出しでも
// 実態は同じインスタンス。analyzer は extension を State 外と判定するため抑制。
// ignore_for_file: invalid_use_of_protected_member
part of '../horoscope_screen.dart';

// ══════════════════════════════════════════════════
// Bottom Sheet — 2-state (half 280px / full 65%)
// バーをタップで half ↔ full トグル
// horoscope_screen.dart の part として State 経由でタブ状態を管理。
// ══════════════════════════════════════════════════

extension _HoroBottomSheet on HoroscopeScreenState {
  /// chart 描画域に最低限残しておきたい高さ。これ未満になる端末では sheet を縮める。
  static const double _minChartArea = 320;

  double _bsHeight(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    // sheet の上限: 「画面高 - 最低 chart 領域」 で chart に必ず読める空間を残す。
    // 縦に短い端末でホロスコープが sheet に被って見えなくなる問題への対策 (2026-04-29)。
    final maxH = (screenH - _minChartArea).clamp(160.0, screenH);
    if (_bsState == 2) return min(screenH * 0.65, maxH); // full
    return min(280.0, maxH); // half (default)
  }

  void _cycleBsState() {
    // half ↔ full トグル
    setState(() {
      _bsState = _bsState == 2 ? 1 : 2;
    });
  }

  Widget _buildBottomSheet() {
    final h = _bsHeight(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: h,
      decoration: const BoxDecoration(
        color: Color(0xF80C0C16),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0x4DF6BD60))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ドラッグハンドル + タブバーを1つのドラッグエリアに統合
          // タブバー上の縦フリックでも half ↔ full 切替できるようにする
          // タブのタップは内側 GestureDetector で個別処理 (gesture arena が解決)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragEnd: (d) {
              if (d.primaryVelocity != null) {
                setState(() {
                  if (d.primaryVelocity! < -200) { _bsState = 2; }
                  else if (d.primaryVelocity! > 200) { _bsState = 1; }
                });
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ドラッグハンドル本体: タップで half ↔ full トグル
                GestureDetector(
                  onTap: _cycleBsState,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.transparent,
                    child: Center(child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0x66F6BD60),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
                  ),
                ),
                _buildBSTabs(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              child: _buildBSContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBSTabs() {
    final showTransit = _chartMode == 'nt' || _chartMode == 'np';
    // 拠点(リロケーション解説)タブ: 1重円 + home有効 + houses両方取得済みの時のみ表示
    final showRelocate = _chartMode == 'single'
        && _natalHouses.length == 12
        && _relocateHouses.length == 12;
    // HTML: bs-tab — 5 tabs (fortune has no tab button in HTML mobile)
    final tabs = <(String, AntiqueIcon, String)>[
      ('birth', AntiqueIcon.birth, '誕生'),
      if (showTransit)
        ('transit', _chartMode == 'np' ? AntiqueIcon.progressed : AntiqueIcon.transit,
         _chartMode == 'np' ? '進行' : '経過'),
      ('planets', AntiqueIcon.planets, '天体'),
      if (showRelocate)
        ('relocate', AntiqueIcon.cycle, '拠点'),
      ('filter', AntiqueIcon.filter, '絞込'),
      ('aspects', AntiqueIcon.aspects, '相'),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: tabs.map((t) {
        final active = _bsTab == t.$1;
        final tabColor = active ? const Color(0xFFF6BD60) : const Color(0xFF888888);
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _bsTab = t.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(
                color: active ? const Color(0xFFF6BD60) : Colors.transparent, width: 2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AntiqueGlyph(icon: t.$2, size: 15, color: tabColor, glow: active),
                const SizedBox(width: 5),
                Text(t.$3, style: GoogleFonts.cinzel(
                  fontSize: 12, letterSpacing: 1.2,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: tabColor,
                )),
              ],
            ),
          ),
        ));
      }).toList()),
    );
  }

  Widget _buildBSContent() {
    switch (_bsTab) {
      case 'birth': return HoroBirthPanel(
        profile: _profile!,
        isEdited: _isEdited,
        // 2026-05-07: 別画面 push (_openProfileEditor) を廃止し、
        // パネル内フォームから直接 _applyWorkingProfile を呼ぶ形に変更。
        onApply: _applyWorkingProfile,
        onReset: _resetWorkingProfile,
      );
      case 'transit': return HoroTransitPanel(
        chartMode: _chartMode,
        onUpdate: _onTransitUpdate,
      );
      case 'planets': return HoroPlanetTable(
        natalPlanets: _natalPlanets,
        asc: _asc, mc: _mc,
        birthTimeUnknown: _birthTimeUnknown,
        secondaryPlanets: (_chartMode == 'nt' || _chartMode == 'np') ? _secondaryPlanets : null,
        secondaryAsc: (_chartMode == 'nt' || _chartMode == 'np') ? _secondaryAsc : null,
        secondaryMc: (_chartMode == 'nt' || _chartMode == 'np') ? _secondaryMc : null,
        chartMode: _chartMode,
        houses: _houses,
      );
      case 'relocate': return HoroRelocationPanel(
        natalPlanets: _natalPlanets,
        natalHouses: _natalHouses,
        relocateHouses: _relocateHouses,
        natalAsc: _natalAsc, natalMc: _natalMc,
        relocateAsc: _relocateAsc, relocateMc: _relocateMc,
        birthPlaceName: _profile?.birthPlace,
        homeName: _profile?.homeName,
        userName: _profile?.name,
      );
      case 'filter': return HoroFilterPanel(
        qualityFilters: _qualityFilters,
        pgroupFilters: _pgroupFilters,
        fortuneFilter: _fortuneFilter,
        onReset: () => setState(() {
          _qualityFilters.updateAll((k, v) => true);
          _pgroupFilters.updateAll((k, v) => true);
          _fortuneFilter = null;
        }),
        onQualityChanged: (k, v) => setState(() => _qualityFilters[k] = v),
        onPgroupChanged: (k, v) => setState(() => _pgroupFilters[k] = v),
        onFortuneChanged: (v) => setState(() => _fortuneFilter = v),
      );
      case 'aspects': return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HoroAspectList(
          filteredAspects: _allAspectsWithDimmed(),
          hiddenAspects: _hiddenAspects,
          onToggleAspect: (key) => setState(() {
            if (_hiddenAspects.contains(key)) { _hiddenAspects.remove(key); } else { _hiddenAspects.add(key); }
          }),
        ),
        const SizedBox(height: 12),
        HoroPredictionPanel(
          activePatterns: _modeFilteredPatterns(),
          // 60日予測はnt/npモードで表示。singleでは不要 (メモ化済)
          predictions: _memoizedPredictions(),
          hiddenPatterns: _hiddenPatterns,
          onPatternToggle: (key) => setState(() {
            if (_hiddenPatterns.contains(key)) {
              _hiddenPatterns.remove(key);
            } else {
              _hiddenPatterns.add(key);
            }
          }),
        ),
      ]);
      default: return const SizedBox();
    }
  }
}
