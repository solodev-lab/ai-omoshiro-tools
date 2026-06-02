import 'package:flutter/foundation.dart';

import 'consultation_v2_api.dart';

/// 相談結果(live) → Map → 相談結果 への「戻り導線」橋渡し singleton。
///
/// 相談結果カードの🗺ボタンで Map タブへ移る際、live セッションの状態を
/// [stash] しておき、Map 下部の「← 相談結果に戻る」チップから fetch なしで
/// 同じ結果を再表示する (= クレジット非消費)。
///
/// 破棄タイミング (Map タブ専用・一過性の導線):
///   - 戻りチップ押下で消費 ([take])
///   - ✕ で手動破棄 / Map 以外のタブへ移動 / 新規 live 相談を開始 ([clear])
///
/// 設計の背景: 相談結果は push 画面、Map はボトムナビのタブで層が別。🗺 は
/// 相談スタックを畳んで Map を見せるため結果が消える。この holder で live 状態を
/// 退避し、戻れるようにする (map_focus.dart と対になる仕組み)。
class ConsultationResumeState {
  /// 元の相談リクエスト (「別の候補地」継続に必須)。
  final ConsultationRequest request;

  /// 取得済みの候補読み解き (fetch せず再注入する)。
  final List<ConsultationV2Reading> readings;

  /// avoid-window スナップショット (出し直し時の無連続用)。
  final List<String> avoid;

  /// 自動保存レコードの savedAt (同一レコードを上書きし続けるため復元する)。
  final DateTime? recordSavedAt;

  /// 退避時に表示していたページ。
  final int pageIndex;

  /// scope の詳細ラベル (履歴カード用)。
  final String? scopeDetail;

  const ConsultationResumeState({
    required this.request,
    required this.readings,
    required this.avoid,
    required this.recordSavedAt,
    required this.pageIndex,
    required this.scopeDetail,
  });

  /// プロセス死復元 (SolaraStorage.saveRestoreSnapshot) 用。
  /// 低 RAM 端末で Google マップ等の外部アプリ往復中に OS が Solara を kill した
  /// 場合でも、コールド起動時にこのスナップショットから戻りチップを復活させる。
  Map<String, dynamic> toJson() => {
        'request': request.toJson(),
        'readings': readings.map((r) => r.toJson()).toList(),
        if (avoid.isNotEmpty) 'avoid': avoid,
        if (recordSavedAt != null)
          'recordSavedAt': recordSavedAt!.toIso8601String(),
        'pageIndex': pageIndex,
        if (scopeDetail != null) 'scopeDetail': scopeDetail,
      };

  factory ConsultationResumeState.fromJson(Map<String, dynamic> j) =>
      ConsultationResumeState(
        request: ConsultationRequest.fromJson(
          (j['request'] as Map).cast<String, dynamic>(),
        ),
        readings: (j['readings'] as List?)
                ?.map((e) => ConsultationV2Reading.fromJson(
                      (e as Map).cast<String, dynamic>(),
                    ))
                .toList() ??
            const [],
        avoid:
            (j['avoid'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        recordSavedAt: DateTime.tryParse(j['recordSavedAt'] as String? ?? ''),
        pageIndex: (j['pageIndex'] as num?)?.toInt() ?? 0,
        scopeDetail: j['scopeDetail'] as String?,
      );
}

class ConsultationReturn extends ChangeNotifier {
  ConsultationReturn._();
  static final ConsultationReturn instance = ConsultationReturn._();

  ConsultationResumeState? _pending;
  ConsultationResumeState? get pending => _pending;
  bool get hasPending => _pending != null;

  /// 🗺 で Map へ移る前に live 状態を積む。
  void stash(ConsultationResumeState state) {
    _pending = state;
    notifyListeners();
  }

  /// 戻りチップ押下時: 取り出して消費する (一度きり)。
  ConsultationResumeState? take() {
    final p = _pending;
    if (p != null) {
      _pending = null;
      notifyListeners();
    }
    return p;
  }

  /// 破棄 (✕ / Map タブ離脱 / 新規相談開始)。
  void clear() {
    if (_pending != null) {
      _pending = null;
      notifyListeners();
    }
  }

  /// プロセス死復元用: 現在の pending をスナップショット化 (なければ null)。
  /// SolaraHome が paused 時に pull し、restore snapshot に載せる。
  Map<String, dynamic>? captureRestore() => _pending?.toJson();

  /// コールド起動時: スナップショットから pending を復元する。
  /// 壊れたスナップショットはチップを出さないだけで握り潰す (クラッシュ回避)。
  void restoreFrom(Map<String, dynamic> json) {
    try {
      _pending = ConsultationResumeState.fromJson(json);
      notifyListeners();
    } catch (_) {
      _pending = null;
    }
  }
}
