// 押下ルート (相談入力 / 相談結果画面) の画面復元レジストリ。
//
// Android プロセス死対策のハイブリッド復元 (SolaraStorage.saveRestoreSnapshot) の
// うち、`Navigator.push` で積まれたルートを扱う部分。低 RAM 端末 (A101FC 等) で
// 外部アプリ (Google マップ / 共有シート等) へ離脱中に OS が Solara を kill →
// 復帰時コールド再起動で押下ルートが失われる問題への対策。
//
// 設計: 各画面が mount 時に capture コールバックを register し、dispose 時に
// unregister する「登録スタック」。SolaraHome が paused 時に captureTop() で
// 最前面 (最後に登録され、まだ生存している) 画面のスナップショットを取得する。
// 登録スタック方式なので、入力→結果の push 連鎖や、結果を pop して入力へ戻る
// ケースも追加配線なしで自然に扱える (RouteObserver 不要)。
//
// capture は「今この瞬間の復元スナップショット (復元不要なら null)」を返す純関数。
// SolaraHome が paused のタイミングで pull するので、画面側に lifecycle 監視を
// 持たせる必要がない (SharedPreferences への書き込みは SolaraHome に一本化)。
class ConsultRestore {
  ConsultRestore._();
  static final ConsultRestore instance = ConsultRestore._();

  final List<_Entry> _stack = [];

  /// 画面 mount 時に呼ぶ。返ってきた token を dispose 時に [unregister] へ渡す。
  Object register(Map<String, dynamic>? Function() capture) {
    final token = Object();
    _stack.add(_Entry(token, capture));
    return token;
  }

  /// 画面 dispose 時に呼ぶ。
  void unregister(Object token) {
    _stack.removeWhere((e) => e.token == token);
  }

  /// 最前面 (末尾) から順に capture を呼び、最初の非 null を返す。
  /// 全て null (= 復元対象なし) なら null。
  Map<String, dynamic>? captureTop() {
    for (var i = _stack.length - 1; i >= 0; i--) {
      final snap = _stack[i].capture();
      if (snap != null) return snap;
    }
    return null;
  }
}

class _Entry {
  final Object token;
  final Map<String, dynamic>? Function() capture;
  _Entry(this.token, this.capture);
}
