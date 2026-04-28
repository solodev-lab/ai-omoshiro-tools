import 'package:flutter/material.dart';

/// ============================================================
/// Time Slider — Tier A #5 / CCG (Cyclo*Carto*Graphy)
///
/// 案B (2段折りたたみ、2026-04-29):
///   上段 (常時表示): [◀] 日付 [▶] [日スライダー±365日] [LIVE] [⏰▼]
///   下段 (折りたたみ): [◀] 時刻 [▶] [時スライダー 0..23h]
///
/// 上段スライダー: 1日刻み、ドラッグ→ラベル更新、指離しで commit。
/// 下段スライダー: 1時間刻み (0..23 JST)、同じく指離し commit。
/// ⏰▼ で下段の展開/折りたたみ (default: 折りたたみ)。
///
/// 時刻だけ変えた場合 chart は再fetch せず GMST のみ更新で動く
/// (chart cache が同UTC日でヒットするため、オーナー側で意識不要)。
/// ============================================================
class MapTimeSlider extends StatefulWidget {
  /// 確定中の日付 (null = 今日 + 現在時刻)
  final DateTime? date;
  /// commit 時に呼ばれる: null=今日 LIVE、それ以外は具体UTC日時 (時刻含む)
  final ValueChanged<DateTime?> onCommit;

  const MapTimeSlider({
    super.key,
    required this.date,
    required this.onCommit,
  });

  @override
  State<MapTimeSlider> createState() => _MapTimeSliderState();
}

class _MapTimeSliderState extends State<MapTimeSlider> {
  static const _rangeDays = 365.0; // ±1年

  // 上段ドラフト (日数オフセット、ドラッグ中のみ非null)
  double? _draftDays;
  // 下段ドラフト (JST 0..23、ドラッグ中のみ非null)
  double? _draftHour;
  // 下段展開状態
  bool _timeRowExpanded = false;

  /// widget.date を「今日からの日数オフセット」に変換 (null=0)
  double _committedDays() {
    final d = widget.date;
    if (d == null) return 0;
    final today = DateTime.now().toUtc();
    final pivot = DateTime.utc(today.year, today.month, today.day);
    final picked = DateTime.utc(d.year, d.month, d.day);
    return picked.difference(pivot).inDays.toDouble();
  }

  /// 確定中の JST 時刻 (0..23)
  int _committedHourJst() {
    final d = widget.date ?? DateTime.now();
    return d.toLocal().hour;
  }

  /// 表示用の (日付 + 時刻) JST
  DateTime _previewDateJst() {
    final dayOffset = (_draftDays ?? _committedDays()).round();
    final hourJst = (_draftHour ?? _committedHourJst().toDouble()).round();
    final today = DateTime.now().toUtc();
    final base = DateTime.utc(today.year, today.month, today.day);
    final utc = base.add(Duration(days: dayOffset));
    // base+dayOffset = 該当日 00:00 UTC、これを JST 表示で hour 上書き
    final local = utc.toLocal();
    return DateTime(local.year, local.month, local.day, hourJst, 0, 0);
  }

  /// 日数オフセットを commit (時刻部分は既存値を維持)
  void _commitDays(double days) {
    final rounded = days.round();
    final existingHourJst = _committedHourJst();
    if (rounded == 0 && _isLiveHour()) {
      // 完全に LIVE: 日=0かつ時刻=現在
      widget.onCommit(null);
      return;
    }
    final today = DateTime.now().toUtc();
    final base = DateTime.utc(today.year, today.month, today.day);
    final pickedUtc = base.add(Duration(days: rounded));
    final pickedLocal = pickedUtc.toLocal();
    final localDt = DateTime(
      pickedLocal.year, pickedLocal.month, pickedLocal.day,
      existingHourJst, 0, 0,
    );
    widget.onCommit(localDt.toUtc());
  }

  /// 時刻 (JST hour) を commit (日付部分は既存値を維持)
  void _commitHour(int hourJst) {
    final base = widget.date ?? DateTime.now();
    final local = base.toLocal();
    final newLocal = DateTime(local.year, local.month, local.day, hourJst, 0, 0);
    widget.onCommit(newLocal.toUtc());
  }

  /// LIVE 判定: widget.date が null なら LIVE
  bool _isLive() => widget.date == null;

  /// 時刻が「現在」と一致するか (LIVE の hour 側判定用)
  bool _isLiveHour() {
    final d = widget.date;
    if (d == null) return true;
    final now = DateTime.now();
    return d.toLocal().hour == now.hour && d.toLocal().day == now.day;
  }

  void _stepDay(int delta) {
    final cur = _committedDays();
    final next = (cur + delta).clamp(-_rangeDays, _rangeDays);
    setState(() => _draftDays = null);
    _commitDays(next);
  }

  void _stepHour(int delta) {
    final cur = _committedHourJst();
    final next = ((cur + delta) % 24 + 24) % 24;
    setState(() => _draftHour = null);
    _commitHour(next);
  }

  String _fmtDate(DateTime d, double dayOffsetForLabel) {
    // 日数オフセット 0 = 今日 → 数字でなく「今日」表記
    if (dayOffsetForLabel.round() == 0) return '今日';
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  String _fmtHour(int hourJst) {
    return '${hourJst.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    final dayValue = (_draftDays ?? _committedDays()).clamp(-_rangeDays, _rangeDays);
    final hourValue = (_draftHour ?? _committedHourJst().toDouble()).clamp(0, 23).toDouble();
    final preview = _previewDateJst();
    final isLive = _isLive();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
      decoration: BoxDecoration(
        color: const Color(0xE60C0C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 上段: 日付コントロール ──
          _buildDayRow(dayValue, preview, isLive),
          // ── 下段: 時刻コントロール (折りたたみ可能) ──
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _timeRowExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildHourRow(hourValue),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(double dayValue, DateTime preview, bool isLive) {
    return Row(children: [
      _stepperBtn(icon: Icons.arrow_left, onTap: () => _stepDay(-1)),
      const SizedBox(width: 4),
      // 日付ラベル: 固定幅 90 で時刻ラベルと中央揃え (▶ の X 位置を一致させる)
      SizedBox(
        width: 90,
        child: Center(
          child: Text(
            _fmtDate(preview, dayValue),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFE9D29A),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              height: 1.1,
            ),
          ),
        ),
      ),
      const SizedBox(width: 4),
      _stepperBtn(icon: Icons.arrow_right, onTap: () => _stepDay(1)),
      const SizedBox(width: 4),
      Expanded(
        child: SliderTheme(
          data: _sliderTheme(),
          child: Slider(
            min: -_rangeDays, max: _rangeDays,
            value: dayValue,
            divisions: (_rangeDays * 2).round(),
            onChanged: (v) => setState(() => _draftDays = v),
            onChangeEnd: (v) {
              _commitDays(v);
              setState(() => _draftDays = null);
            },
          ),
        ),
      ),
      // LIVE (固定幅 44 で時刻行のスペーサーと一致させる)
      SizedBox(
        width: 44,
        child: GestureDetector(
          onTap: isLive ? null : () {
            setState(() {
              _draftDays = null;
              _draftHour = null;
            });
            widget.onCommit(null);
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLive ? const Color(0xFFFF8E5C) : const Color(0x33FF8E5C),
                width: isLive ? 1.0 : 0.8,
              ),
              color: isLive ? const Color(0x22FF8E5C) : Colors.transparent,
            ),
            child: Text(
              isLive ? '● LIVE' : 'LIVE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: isLive ? const Color(0xFFFF8E5C) : const Color(0x99FF8E5C),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 4),
      // 時刻行展開トグル
      GestureDetector(
        onTap: () => setState(() => _timeRowExpanded = !_timeRowExpanded),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _timeRowExpanded
                  ? const Color(0xFFC9A84C)
                  : const Color(0x33C9A84C),
              width: _timeRowExpanded ? 1.0 : 0.8,
            ),
            color: _timeRowExpanded
                ? const Color(0x22C9A84C)
                : Colors.transparent,
          ),
          child: Icon(
            _timeRowExpanded ? Icons.access_time_filled : Icons.access_time,
            size: 16,
            color: _timeRowExpanded
                ? const Color(0xFFE9D29A)
                : const Color(0x99C9A84C),
          ),
        ),
      ),
    ]);
  }

  Widget _buildHourRow(double hourValue) {
    return Row(children: [
      _stepperBtn(icon: Icons.arrow_left, onTap: () => _stepHour(-1)),
      const SizedBox(width: 4),
      // 時刻表示: 固定幅 90 で日付ラベルと中央揃え (▶ の X 位置を一致)
      SizedBox(
        width: 90,
        child: Center(
          child: Text(
            _fmtHour(hourValue.round()),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF63D6A0), // 緑系で日付と区別
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              height: 1.1,
            ),
          ),
        ),
      ),
      const SizedBox(width: 4),
      _stepperBtn(icon: Icons.arrow_right, onTap: () => _stepHour(1)),
      const SizedBox(width: 4),
      Expanded(
        child: SliderTheme(
          data: _sliderTheme(green: true),
          child: Slider(
            min: 0, max: 23,
            value: hourValue,
            divisions: 23,
            onChanged: (v) => setState(() => _draftHour = v),
            onChangeEnd: (v) {
              _commitHour(v.round());
              setState(() => _draftHour = null);
            },
          ),
        ),
      ),
      // 時刻側の隙間: 上段 LIVE(44) + gap(4) + ⏰(28) = 76 と一致させてバー長を完全揃える
      const SizedBox(width: 76),
    ]);
  }

  SliderThemeData _sliderTheme({bool green = false}) {
    final accent = green ? const Color(0xFF63D6A0) : const Color(0xFFC9A84C);
    final accentLight = green ? const Color(0xFF7FE3B0) : const Color(0xFFE9D29A);
    return SliderThemeData(
      trackHeight: 2,
      activeTrackColor: accent,
      inactiveTrackColor: accent.withAlpha(60),
      thumbColor: accentLight,
      overlayColor: accent.withAlpha(40),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
    );
  }

  Widget _stepperBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 32, height: 32,
        child: Center(
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x55C9A84C), width: 0.8),
              color: const Color(0x22C9A84C),
            ),
            child: Icon(icon, size: 22, color: const Color(0xFFE9D29A)),
          ),
        ),
      ),
    );
  }
}
