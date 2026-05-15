// Solara Pro 状態管理 — Phase 2-6a (暫定)
//
// 設計: apps/solara/docs/pro_candidates.md §7 + project_solara_security_principles.md
//
// 役割:
//   - SharedPreferences に Pro フラグを保存し、UI が同期で参照できる cache を持つ
//   - ChangeNotifier 経由で Pro 切替を全画面に即時反映
//
// 現状 (Phase 2-6a):
//   - 暫定的にクライアント単独でフラグ管理 (DEV ビルドでは Sanctuary から toggle 可能)
//   - 本番ビルドでは default false 固定、ユーザーが操作する手段はない
//   - 機能ゲートの「配線」だけ済ませる目的
//
// Phase 2-6b 以降 (RevenueCat 接続後):
//   - RevenueCat callback で `setPro` を呼んで本物の購読状態を反映
//   - Worker 側で署名検証もする (project_solara_security_principles の原則 1
//     「クライアント単独 isPro 禁止」を守るため、機密機能は Worker でも再チェック)
//
// 🔴 セキュリティ原則 (security_principles.md):
//   - クライアント側 isPro だけでロックを完結させない
//   - Stella 相談の Worker 呼出は最終的に Sign in + サーバ側 Pro 検証で守る
//   - 本ファイルは「UI の出し分け」までを担当する

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProStatus extends ChangeNotifier {
  ProStatus._();

  /// アプリ全体で 1 つのインスタンスを共有する。
  static final ProStatus instance = ProStatus._();

  static const String _kKey = 'solara_is_pro';

  bool _isPro = false;
  bool _loaded = false;

  bool get isPro => _isPro;

  /// 初回 load 完了したか。`false` の間は default (`false`) を返す。
  bool get loaded => _loaded;

  /// SharedPreferences から読み出して内部キャッシュを更新する。
  /// アプリ起動時に main() から 1 度呼んでおくと、各画面で同期 access できる。
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(_kKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  /// Pro 状態を更新する。永続化 + リスナー通知。
  ///
  /// Phase 2-6a (暫定): Sanctuary の DEV toggle から呼ばれる (kDebugMode のみ)。
  /// Phase 2-6b 以降: RevenueCat callback から呼ぶ。
  Future<void> setPro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, value);
    _isPro = value;
    _loaded = true;
    notifyListeners();
  }

  /// テスト/開発用: フラグ直書きを SharedPreferences とキャッシュ両方に反映。
  /// 通常コードからは setPro を使う。
  @visibleForTesting
  Future<void> resetForTest({bool isPro = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, isPro);
    _isPro = isPro;
    _loaded = true;
    notifyListeners();
  }
}
