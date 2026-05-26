// Stella / Tarot 共用クレジット残数の Single Source of Truth (singleton)。
//
// 設計理由 (2026-05-26):
//   CF logs 分析で /protected/consultation/credits が 5 分間に 45 回 (1 ユーザー、
//   ピーク 1 分 13 回) 叩かれていた。原因は各画面 (Sanctuary / 相談入力 /
//   開始ポップアップ / Tarot カテゴリ選択 / 購入シート) がそれぞれ initState で
//   fetchConsultationCredits を独立に呼んでいたこと + 旧 ConsultationCreditEvents
//   (notify-only ChangeNotifier) に listener を登録した複数画面が、1 イベントで
//   それぞれ refetch していたこと。1 ユーザー操作 → 4-5 件の重複 fetch + 内部
//   DO 4 個 fan-out で 320+ 件まで増幅していた。
//
// 本クラスの役割:
//   - クレジット状況 (ConsultationCreditStatus) を 1 個だけ保持
//   - UI 各所は instance.status を build で読む (= 自分で fetch しない)
//   - refresh() は in-flight dedup (同時複数 await でも HTTP は 1 本)
//   - notifyListeners で全 UI を一括更新
//
// fetch をトリガーする 4 イベント (これ以外で呼んではいけない):
//   1. アプリ起動時 (main.dart で 1 回・非同期)
//   2. 消費イベント直後 (相談実行 / Tarot カテゴリ draw)
//   3. 購入完了 webhook 反映ポーリング (consultation_credit_sheet)
//   4. app resumed (バックグラウンド復帰、別端末購入や Webhook 遅延吸収)
//
// 非・キャッシュ方針 (オーナー方針: 問題を見えなくしない):
//   - TTL ベースのキャッシュは置かない (= 古いデータを返さない)
//   - 「画面遷移で勝手に refresh」は廃止
//   - 各 refresh は明示イベントが原因 → CF ログで「消費 N 回 ⇔ fetch N 回」
//     が 1:1 で対応する。バーストが再発したら新規バグとして検出可能。

import 'package:flutter/foundation.dart';

import 'consultation_api.dart'
    show ConsultationCreditStatus, fetchConsultationCredits;

class ConsultationCredits extends ChangeNotifier {
  ConsultationCredits._();

  /// アプリ全体で 1 つのインスタンスを共有する (ProStatus と同じパターン)。
  static final ConsultationCredits instance = ConsultationCredits._();

  ConsultationCreditStatus? _status;
  bool _loaded = false;
  Future<void>? _inflight;

  /// 現在のクレジット状況。初回 refresh() 成功前は null。
  /// 失敗時は前回値を保持 (古いより無い方が悪い)。
  ConsultationCreditStatus? get status => _status;

  /// 初回 refresh() が成功して値を持っているか。
  /// ネットワーク失敗時は false のまま (= UI は「確認中」のままになる)。
  bool get loaded => _loaded;

  /// クレジット残を再取得し、変更があれば listener に通知する。
  ///
  /// In-flight dedup: 既に refresh が走っているときの並行呼び出しは
  /// 同じ HTTP リクエストの完了を共有する (= バースト発生時も実 HTTP は 1 本)。
  ///
  /// 必ず明示イベントから呼ぶこと (initState や画面遷移からは呼ばない)。
  /// 詳細は本ファイル冒頭の「fetch をトリガーする 4 イベント」を参照。
  Future<void> refresh() async {
    final existing = _inflight;
    if (existing != null) return existing;
    final newFetch = _doFetch();
    _inflight = newFetch;
    try {
      await newFetch;
    } finally {
      if (identical(_inflight, newFetch)) _inflight = null;
    }
  }

  Future<void> _doFetch() async {
    final fresh = await fetchConsultationCredits();
    if (fresh != null) {
      _status = fresh;
      _loaded = true;
      notifyListeners();
    }
    // null = ネットワーク失敗。既存 _status は維持 (UI は前回値を表示し続ける)。
  }

  /// テスト/開発用: 状態を直接セットして listener に通知する。
  @visibleForTesting
  void resetForTest({ConsultationCreditStatus? status, bool loaded = false}) {
    _status = status;
    _loaded = loaded;
    _inflight = null;
    notifyListeners();
  }
}
