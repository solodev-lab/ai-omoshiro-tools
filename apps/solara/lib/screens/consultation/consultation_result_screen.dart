// Consultation Result Screen — Stage 4 UI
//
// 設計: apps/solara/docs/pro_candidates.md §7.2 Stage 4
//
// レイアウト:
//   - AppBar (戻る / share プレースホルダ / 閉じる)
//   - intro (固定、上部)
//   - PageView × N 候補 (横スワイプ + HapticFeedback.selectionClick)
//     候補カード: 名前 + energyLabels chips + narrative (縦スクロール)
//   - outro (固定、下部)
//   - 「もう一度候補を出す」ボタン (refresh callback がある場合のみ)
//
// 状態: loading / loaded / error / refreshing
//
// Phase 2-4 で対応:
//   - 自動保存 (solara_storage に request + response 永続化)
//   - 履歴閲覧画面
//   - 「📍地図で確認」連動 (公開後 v1.x)
//   - share ボタンの実体化

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/solara_colors.dart';
import '../../utils/consultation_api.dart';
import '../../utils/consultation_engine.dart';
import '../../widgets/glass_panel.dart';

class ConsultationResultScreen extends StatefulWidget {
  final String theme;
  final String mode;
  final String scope;
  final String freeText;
  final List<CandidateLocation> initialCandidates;

  /// Refresh callback: 既出名のリストを受け取り、新規候補を返す。
  /// null = リフレッシュ不可 (specific スコープ等 1 候補のケース)。
  final Future<List<CandidateLocation>> Function(List<String> excludeNames)?
      regenerateCandidates;

  /// テスト/モック差し替え用: 通常は null で標準 fetchConsultation を呼ぶ。
  final Future<ConsultationReading?> Function({
    required String theme,
    required String mode,
    required String scope,
    required List<CandidateLocation> candidates,
    String freeText,
    List<String> excluded,
  })? fetchOverride;

  const ConsultationResultScreen({
    super.key,
    required this.theme,
    required this.mode,
    required this.scope,
    required this.initialCandidates,
    this.freeText = '',
    this.regenerateCandidates,
    this.fetchOverride,
  });

  @override
  State<ConsultationResultScreen> createState() =>
      _ConsultationResultScreenState();
}

class _ConsultationResultScreenState extends State<ConsultationResultScreen> {
  late final PageController _pageCtrl;
  int _pageIndex = 0;

  late List<CandidateLocation> _candidates;
  ConsultationReading? _reading;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  /// リフレッシュで除外する候補名 (累積)。
  final Set<String> _excludedNames = <String>{};

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _candidates = List.of(widget.initialCandidates);
    _fetch();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<ConsultationReading?> _runFetch({
    required List<CandidateLocation> candidates,
    required List<String> excluded,
  }) async {
    if (widget.fetchOverride != null) {
      return widget.fetchOverride!(
        theme: widget.theme,
        mode: widget.mode,
        scope: widget.scope,
        candidates: candidates,
        freeText: widget.freeText,
        excluded: excluded,
      );
    }
    return fetchConsultation(
      theme: widget.theme,
      mode: widget.mode,
      scope: widget.scope,
      candidates: candidates,
      freeText: widget.freeText,
      excluded: excluded,
    );
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final reading = await _runFetch(
      candidates: _candidates,
      excluded: const [],
    );
    if (!mounted) return;
    if (reading == null) {
      setState(() {
        _loading = false;
        _error = '接続に届きませんでした。もう一度試せます。';
      });
      return;
    }
    setState(() {
      _reading = reading;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    final gen = widget.regenerateCandidates;
    if (gen == null) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    // 既出として今表示中の候補名を全部追加 (累積)。
    for (final c in _candidates) {
      _excludedNames.add(c.nameJP);
    }
    final excludedList = _excludedNames.toList(growable: false);
    final newCands = await gen(excludedList);
    if (!mounted) return;
    if (newCands.isEmpty) {
      setState(() {
        _refreshing = false;
        _error = '別の候補が見つかりませんでした。';
      });
      return;
    }
    final reading = await _runFetch(
      candidates: newCands,
      excluded: excludedList,
    );
    if (!mounted) return;
    if (reading == null) {
      setState(() {
        _refreshing = false;
        _error = '接続に届きませんでした。もう一度試せます。';
      });
      return;
    }
    setState(() {
      _candidates = newCands;
      _reading = reading;
      _refreshing = false;
      _pageIndex = 0;
    });
    if (_pageCtrl.hasClients) {
      _pageCtrl.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SolaraColors.celestialBlueDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SolaraColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: '戻る',
        ),
        title: const Text(
          '相談の結果',
          style: TextStyle(
            color: SolaraColors.textPrimary,
            fontSize: 16,
            letterSpacing: 0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const _LoadingSkeleton();
    if (_error != null && _reading == null) {
      return _ErrorBox(message: _error!, onRetry: _fetch);
    }
    final reading = _reading;
    if (reading == null) return const _LoadingSkeleton();

    return Column(
      children: [
        _IntroBlock(text: reading.intro, fallback: reading.fallback),
        _PageIndicator(
          count: _candidates.length,
          index: _pageIndex,
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _candidates.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _pageIndex = i);
            },
            itemBuilder: (ctx, i) {
              final cand = _candidates[i];
              final readingForI = i < reading.candidates.length
                  ? reading.candidates[i]
                  : null;
              return _CandidateCard(
                candidate: cand,
                reading: readingForI,
              );
            },
          ),
        ),
        _OutroBlock(text: reading.outro),
        if (widget.regenerateCandidates != null)
          _RefreshButton(
            loading: _refreshing,
            onTap: _refreshing ? null : _refresh,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── サブウィジェット ───────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: SolaraColors.solaraGold,
            strokeWidth: 2,
          ),
          const SizedBox(height: 20),
          Text(
            'Gemini が解釈中…',
            style: TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 14,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: SolaraColors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: SolaraColors.solaraGold,
                ),
                child: const Text('もう一度試す'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroBlock extends StatelessWidget {
  final String text;
  final bool fallback;
  const _IntroBlock({required this.text, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fallback)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x33D6915C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SolaraColors.energyHardDark),
              ),
              child: Text(
                'AI が届きませんでした (静的表示)',
                style: TextStyle(
                  color: SolaraColors.energyHardLight,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          Text(
            text,
            style: const TextStyle(
              color: SolaraColors.textPrimary,
              fontSize: 14,
              height: 1.7,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutroBlock extends StatelessWidget {
  final String text;
  const _OutroBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: SolaraColors.glassBorder, width: 1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: SolaraColors.textSecondary,
          fontSize: 12.5,
          height: 1.7,
          letterSpacing: 0.4,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _PageIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? SolaraColors.solaraGold
                  : SolaraColors.glassBorder,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _RefreshButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0x1AFFFFFF),
            foregroundColor: SolaraColors.solaraGold,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: SolaraColors.glassBorder),
            ),
          ),
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: SolaraColors.solaraGold,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.refresh, size: 18),
          label: Text(loading ? '別の候補を探しています…' : 'もう一度候補を出す'),
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final CandidateLocation candidate;
  final ConsultationCandidateReading? reading;

  const _CandidateCard({
    required this.candidate,
    required this.reading,
  });

  String get _subtitle {
    final parts = <String>[];
    if (candidate.region.isNotEmpty) parts.add(candidate.region);
    if (candidate.country.isNotEmpty && candidate.bearing == null) {
      parts.add(candidate.country);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final energyLabels = r?.energyLabels ?? const <String>[];
    final narrative = r?.narrative ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassPanel(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate.nameJP,
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 22,
                  height: 1.3,
                  letterSpacing: 0.5,
                ),
              ),
              if (_subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _subtitle,
                  style: TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
              if (energyLabels.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: energyLabels
                      .map((label) => _EnergyChip(label: label))
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                narrative.isNotEmpty ? narrative : '(narrative なし)',
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 14,
                  height: 1.85,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnergyChip extends StatelessWidget {
  final String label;
  const _EnergyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x1AF6BD60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x44F6BD60)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: SolaraColors.solaraGoldLight,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
