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
  /// 時刻行展開状態が変化した時に呼ばれる (省略可、true=展開、false=畳む)。
  /// map_screen.dart の back ハンドラが PopScope.canPop を再計算するために使う。
  final ValueChanged<bool>? onExpandedChanged;

  const MapTimeSlider({
    super.key,
    required this.date,
    required this.onCommit,
    this.onExpandedChanged,
  });

  @override
  State<MapTimeSlider> createState() => MapTimeSliderState();
}

/// public State: GlobalKey 経由で map_screen.dart の PopScope から
/// 時刻行展開を制御する (back 押下時に畳む) ため public 化。
class MapTimeSliderState extends State<MapTimeSlider> {
  /// 時刻行が展開中か (外部参照用)
  bool get isTimeRowExpanded => _timeRowExpanded;

  /// 時刻行が開いていれば閉じる。 開いていなければ何もしない。
  /// map_screen.dart の back ハンドラから呼ばれる。
  void closeTimeRow() {
    if (_timeRowExpanded) {
      setState(() => _timeRowExpanded = false);
      widget.onExpandedChanged?.call(false);
    }
  }

  void _setTimeRowExpanded(bool v) {
    if (_timeRowExpanded == v) return;
    setState(() => _timeRowExpanded = v);
    widget.onExpandedChanged?.call(v);
  }

  static const _rangeDays = 365.0; // ±1年

  // 上段ドラフト (日数オフセット、ドラッグ中のみ非null)
  double? _draftDays;
  // 下段ドラフト (JST 0..23、ドラッグ中のみ非null)
  double? _draftHour;
  // 下段展開状態
  bool _timeRowExpanded = false;

  /// widget.date を「今日からの日数オフセット」に変換 (null=0)。
  /// 日付境界は端末ローカル (JST) で判定する。UTC で計算すると
  /// JST 0..8 時 = UTC 前日 となり、JST 9 時で日付ラベルが進んでしまう。
  double _committedDays() {
    final d = widget.date;
    if (d == null) return 0;
    final nowLocal = DateTime.now();
    final pivot = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final dl = d.toLocal();
    final picked = DateTime(dl.year, dl.month, dl.day);
    return picked.difference(pivot).inDays.toDouble();
  }

  /// 確定中の JST 時刻 (0..23)
  int _committedHourJst() {
    final d = widget.date ?? DateTime.now();
    return d.toLocal().hour;
  }

  /// step 操作の base となる JST 分 (10 分刻みに floor)。
  /// 「11:02 → ▶ で 11:10、▶▶で 11:20」の挙動を実現するため、
  /// 加減算の起点を 10 分の倍数に揃える。
  int _committedMinuteJst() {
    final d = widget.date ?? DateTime.now();
    return (d.toLocal().minute ~/ 10) * 10;
  }

  /// 表示用 JST 分 (floor しない実分)。
  /// 2026-05-12: Daily Transit から onJumpToTime で 11:02 等
  /// 1 分単位の時刻が入った場合、ユーザーがその時刻をそのまま
  /// 確認できるよう表示は実分にする。
  /// (step ボタンを押すと _stepMinute が _committedMinuteJst を
  /// 起点に 10 分刻み移動するので、即座に grid に合流する)
  int _displayMinuteJst() {
    final d = widget.date ?? DateTime.now();
    return d.toLocal().minute;
  }

  /// 表示用の (日付 + 時刻) JST。
  /// base はローカル日付の 00:00 で取り、そこに dayOffset 日を足す。
  /// UTC 経由で .toLocal() すると JST 0..8 時帯で日付が 1 日ずれる。
  DateTime _previewDateJst() {
    final dayOffset = (_draftDays ?? _committedDays()).round();
    final hourJst = (_draftHour ?? _committedHourJst().toDouble()).round();
    final nowLocal = DateTime.now();
    final base = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final picked = base.add(Duration(days: dayOffset));
    return DateTime(picked.year, picked.month, picked.day, hourJst, 0, 0);
  }

  /// 日数オフセットを commit (時刻部分は既存値を維持)。
  /// 日付計算はローカル (JST) で行い、最後に toUtc() して外に渡す。
  void _commitDays(double days) {
    final rounded = days.round();
    final existingHourJst = _committedHourJst();
    if (rounded == 0 && _isLiveHour()) {
      // 完全に LIVE: 日=0かつ時刻=現在
      widget.onCommit(null);
      return;
    }
    final nowLocal = DateTime.now();
    final base = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final picked = base.add(Duration(days: rounded));
    final localDt = DateTime(
      picked.year, picked.month, picked.day,
      existingHourJst, 0, 0,
    );
    widget.onCommit(localDt.toUtc());
  }

  /// 時刻 (JST hour) を commit (日付部分は既存値を維持、分は維持)
  void _commitHour(int hourJst) {
    final base = widget.date ?? DateTime.now();
    final local = base.toLocal();
    final newLocal = DateTime(
      local.year, local.month, local.day, hourJst, local.minute, 0,
    );
    widget.onCommit(newLocal.toUtc());
  }

  /// 日付 ±delta 日 + 指定時分を一括 commit (時/分の wrap 連鎖用)。
  void _commitDayShiftAndTime(int dayDelta, int hour, int minute) {
    final base = widget.date ?? DateTime.now();
    final local = base.toLocal();
    final shifted = DateTime(
      local.year, local.month, local.day, hour, minute, 0,
    ).add(Duration(days: dayDelta));
    widget.onCommit(shifted.toUtc());
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
    final raw = cur + delta;
    final next = ((raw % 24) + 24) % 24;
    final dayDelta = (raw < 0) ? -1 : (raw >= 24 ? 1 : 0);
    setState(() => _draftHour = null);
    if (dayDelta != 0) {
      // 23 → 0 で翌日、0 → 23 で前日 (日時の連続感)
      _commitDayShiftAndTime(dayDelta, next, _committedMinuteJst());
    } else {
      _commitHour(next);
    }
  }

  /// 分を delta 刻み (典型: +10) で進める。
  /// 60 を超えたら時間に繰り上がり、24 時に達したら日付に繰り上がる。
  /// 分ステップ。常に 10 分グリッドに合わせる (2026-05-31: 1 分刻みは廃止)。
  /// グリッド外の時刻 (例 10:33、Daily の地図アイコン経由) からは
  ///   △ → 次の 10 分グリッド (10:40) / ▽ → 手前の 10 分グリッド (10:30)。
  /// グリッド上 (10:30) では通常の ±10 分 (△→10:40 / ▽→10:20)。
  /// delta は方向の指示にのみ使う (符号のみ参照)。
  void _stepMinute(int delta) {
    final base = widget.date ?? DateTime.now();
    final actualMin = base.toLocal().minute;
    final floorMin = (actualMin ~/ 10) * 10;
    final onGrid = actualMin % 10 == 0;
    final targetMin =
        delta > 0 ? floorMin + 10 : (onGrid ? floorMin - 10 : floorMin);
    final curHour = _committedHourJst();
    final totalMin = curHour * 60 + targetMin;
    // 1 日 = 1440 分。負・1440超えを正規化。
    final normMin = ((totalMin % 1440) + 1440) % 1440;
    final dayDelta = (totalMin < 0)
        ? -((((-totalMin) - 1) ~/ 1440) + 1)
        : (totalMin >= 1440 ? totalMin ~/ 1440 : 0);
    final nextHour = normMin ~/ 60;
    final nextMin = normMin % 60;
    if (dayDelta != 0) {
      _commitDayShiftAndTime(dayDelta, nextHour, nextMin);
    } else {
      final local = base.toLocal();
      final newLocal = DateTime(
        local.year, local.month, local.day, nextHour, nextMin, 0,
      );
      widget.onCommit(newLocal.toUtc());
    }
  }

  String _fmtDate(DateTime d, double dayOffsetForLabel) {
    // 日数オフセット 0 = 今日 → 数字でなく「今日」表記
    if (dayOffsetForLabel.round() == 0) return '今日';
    // 2026-05-07: 年表示を撤去してコンパクト化 (旧 '2026/05/07' → '05/07')。
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  String _fmtTime(int hourJst, int minuteJst) {
    return '${hourJst.toString().padLeft(2, '0')}:${minuteJst.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dayValue = (_draftDays ?? _committedDays()).clamp(-_rangeDays, _rangeDays);
    final hourValue = (_draftHour ?? _committedHourJst().toDouble()).clamp(0, 23).toDouble();
    final preview = _previewDateJst();
    final isLive = _isLive();

    // 2026-05-08: 全体クランプ 1.5 倍をそのまま適用 (内側追加クランプは撤去)。
    //   - 'MM/DD' (5 文字) と 'HH:MM' (5 文字) を固定幅 64px に収める
    //     fontSize 13 × 1.5 = 19.5 → 5 文字 ≈ 55px (OK)
    //   - 矢印位置は 56→64 で 8px 外側にシフト
    //   - NOW バッジは内部で textScaler.noScaling 維持 (44px に収めるため)
    //
    // 2026-05-10: 時刻行展開時の back ボタン処理は map_screen.dart の
    //   PopScope に統合 (GlobalKey<MapTimeSliderState> で closeTimeRow() を呼ぶ)。
    //   旧: 本 widget 内の PopScope が動作しないケースがあったため撤去。
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
      // 日付ラベル: 固定幅 64 で時刻ラベルと中央揃え (▶ の X 位置を一致させる)。
      // 2026-05-08: 端末フォント 1.5 倍時にも '05/07' / '今日' が収まる幅に拡張
      // (旧 56 → 64)。noScaling 撤去でアクセシビリティ拡大に追従させる。
      SizedBox(
        width: 64,
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
      // NOW バッジ (固定幅 44 で時刻行のスペーサーと一致させる)。
      // 2026-05-08: 稲妻アイコン → 'NOW' テキストバッジに変更。
      // ON  : 鮮やかオレンジ + 背景塗り + 太縁
      // OFF : 薄いオレンジ + 透明背景 + 細縁
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
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLive
                    ? const Color(0xFFFF8E5C)
                    : const Color(0x33FF8E5C),
                width: isLive ? 1.0 : 0.8,
              ),
              color: isLive
                  ? const Color(0x22FF8E5C)
                  : Colors.transparent,
            ),
            child: Text(
              'NOW',
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 13,
                color: isLive
                    ? const Color(0xFFFF8E5C)
                    : const Color(0x66FF8E5C),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 4),
      // 時刻行展開トグル
      GestureDetector(
        onTap: () => _setTimeRowExpanded(!_timeRowExpanded),
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
      // 時刻表示: 固定幅 64 で日付ラベルと中央揃え (▶ の X 位置を一致)。
      // 2026-05-08: 日付ラベル 56→64 同期 + noScaling 撤去でアクセシビリティ追従。
      SizedBox(
        width: 64,
        child: Center(
          child: Text(
            _fmtTime(hourValue.round(), _displayMinuteJst()),
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
      // 上段スペーサー (LIVE 44 + gap 4 + ⏰ 28 = 76) の真下に
      // 分用 ◀▶ (10 分刻み) を 2 個配置:
      //   gap 4 + ◀ 32 + gap 4 + ▶ 32 + gap 4 = 76 (ぴったり一致)
      //
      // 2026-05-31: Pro 1 分刻み (長押し) は廃止。常に 10 分グリッド。
      const SizedBox(width: 4),
      _stepperBtn(
        icon: Icons.arrow_left,
        onTap: () => _stepMinute(-10),
      ),
      const SizedBox(width: 4),
      _stepperBtn(
        icon: Icons.arrow_right,
        onTap: () => _stepMinute(10),
      ),
      const SizedBox(width: 4),
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

  Widget _stepperBtn({
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
