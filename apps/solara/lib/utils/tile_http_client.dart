import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:http/retry.dart';

/// アプリ全体で共有する地図タイル取得用 HTTP クライアント。
///
/// 過去の事象 (2026-04-30):
///   ACG モード world view (zoom 2.5) で大量タイルを並列リクエスト中、
///   Android プロセスの file descriptor が枯渇し
///   `Too many open files` (fcntl 失敗) → `Failed host lookup`
///   (errno=7 EAI_AGAIN) が連鎖発生してアプリが事実上ハングした。
///
///   原因は flutter_map の `NetworkTileProvider` がデフォルトで
///   `RetryClient(Client())` を**内部生成**しており、`TileLayer` が
///   再構築されるたびに新規 client が作られて socket pool が累積していたこと。
///
///   解決策: シングルトン HttpClient を外部から渡し、接続上限と timeout を
///   明示する。
///
/// 2026-05-01 再調整:
///   ACG モードで世界規模 (zoom 2.5) になると 24+ tile を一気に要求するため、
///   旧 maxConn=6 / idle=15s では keep-alive socket が滞留し fd 枯渇の
///   主要因となっていた。maxConn=4 / idle=3s に絞り、socket 再利用回転率を
///   上げて常時保有 fd 数を半分以下に。
///
///   RetryClient の retries も 3 → 1 に。retry が連鎖すると socket が
///   さらに累積するため、ACG モードでは「速やかに諦める」方針に変更。
///
/// 設定:
///   - maxConnectionsPerHost = 4
///       ACG world view 24+ tiles で socket pool 滞留を防ぐ。
///   - idleTimeout = 3 秒
///       keep-alive を短く切ることで常時保有 socket 数を抑制。
///   - connectionTimeout = 12 秒
///       Worker 経由の遠回り通信を考慮しやや余裕を持たせる。
final HttpClient _ioClient = HttpClient()
  ..maxConnectionsPerHost = 4
  ..idleTimeout = const Duration(seconds: 3)
  ..connectionTimeout = const Duration(seconds: 12);

/// `flutter_map` の `NetworkTileProvider(httpClient: ...)` に渡すための
/// 共有クライアント。
///
/// 2026-05-01: retries 3 → 1。SocketException / TimeoutException /
/// HandshakeException のときだけ 1 度だけ 400ms 後に再試行する。
/// 連続 retry で socket pool が膨張するのを防ぐ。
final Client sharedTileHttpClient = RetryClient(
  IOClient(_ioClient),
  retries: 1,
  whenError: (error, _) =>
      error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException,
  delay: (_) => const Duration(milliseconds: 400),
);
