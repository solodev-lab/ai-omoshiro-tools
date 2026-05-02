import 'dart:io';

/// アプリ全体の HttpClient デフォルトを絞る。
///
/// 過去の事象 (2026-04-30 / 2026-05-01):
///   ACG モード長時間運用時に Android プロセスの file descriptor が枯渇し、
///   `Too many open files` (errno=24) → `Failed host lookup` (errno=7 EAI_AGAIN)
///   が連鎖発生してアプリが事実上ハングした。
///
///   原因: タイル取得用 `sharedTileHttpClient` だけは絞っていたが、API 系
///   (fortune / daily transit / search 等) で個別生成される HttpClient は
///   無制限のため、全体の socket 累積を抑え切れていなかった。
///
/// 解決策:
///   `HttpOverrides.global` を差し込み、アプリ内で `new HttpClient()` される
///   全クライアントのデフォルトを以下に固定:
///     - maxConnectionsPerHost = 4   (デフォルト 6)
///     - idleTimeout           = 5s  (デフォルト 15s)
///     - connectionTimeout     = 8s
class SolaraHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..maxConnectionsPerHost = 4
      ..idleTimeout = const Duration(seconds: 5)
      ..connectionTimeout = const Duration(seconds: 8);
  }
}
