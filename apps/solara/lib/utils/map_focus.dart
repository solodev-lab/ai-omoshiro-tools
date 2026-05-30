import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// 相談結果カード → Map タブへ「位置＋日付」でフォーカスする橋渡し。
///
/// 相談結果は push 画面、Map はボトムナビのタブ (index 0) なので直接遷移できない。
/// 結果カードの🗺ボタンが [request] で要求を積み → ルート (SolaraHome) が listener で
/// 受けて Map タブへ切替 → MapScreenState.focusLocationAndDate で消化する。
class MapFocusRequest {
  /// センタリングする座標 (候補地)。
  final LatLng pos;

  /// 表示日付 (相談の when から導出)。null は「今日」。
  final DateTime? date;
  const MapFocusRequest(this.pos, this.date);
}

class MapFocus extends ChangeNotifier {
  MapFocus._();
  static final MapFocus instance = MapFocus._();

  MapFocusRequest? _pending;

  /// 位置＋日付でのフォーカスを要求する (notifyListeners でルートが拾う)。
  void request(LatLng pos, DateTime? date) {
    _pending = MapFocusRequest(pos, date);
    notifyListeners();
  }

  /// 保留中の要求を取り出して消費する (一度きり)。
  MapFocusRequest? take() {
    final p = _pending;
    _pending = null;
    return p;
  }
}

/// 相談の when (kind/date/start/timeBand) から Map 表示日付を導く純関数。
/// おでかけ=指定日(+時間帯) / 旅行=初日(range の start) / 移住=時期の代表日 /
/// 未指定 (today/undecided/null) = null (Map のデフォルト=今日)。
/// [now] はテスト用に注入可能 (省略時は実時刻)。
DateTime? mapFocusDate({
  String? kind,
  String? date,
  String? start,
  String? timeBand,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  DateTime? base;
  switch (kind) {
    case 'date':
      base = DateTime.tryParse(date ?? '');
      break;
    case 'range':
      base = DateTime.tryParse(start ?? ''); // 旅行=初日
      break;
    case 'within6mo':
      base = DateTime(n.year, n.month + 3, n.day);
      break;
    case 'within1yr':
      base = DateTime(n.year, n.month + 6, n.day);
      break;
    case 'in3yr':
      base = DateTime(n.year, n.month + 18, n.day);
      break;
    case 'in5yrPlus':
      base = DateTime(n.year, n.month + 36, n.day);
      break;
    default:
      return null; // today / undecided / null → 今日
  }
  if (base == null) return null;
  final hour = _timeBandHour(timeBand);
  return hour == null ? base : DateTime(base.year, base.month, base.day, hour);
}

/// おでかけの時間帯 → 代表時刻 (Map の transit 計算に渡す)。
int? _timeBandHour(String? tb) {
  switch (tb) {
    case 'morning':
      return 8;
    case 'midday':
      return 12;
    case 'evening':
      return 17;
    case 'night':
      return 21;
    case 'lateNight':
      return 23;
    default:
      return null;
  }
}
