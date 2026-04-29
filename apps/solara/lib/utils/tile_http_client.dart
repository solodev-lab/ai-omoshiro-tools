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
/// 設定:
///   - maxConnectionsPerHost = 6
///       同一ホストへの同時 socket 数を 6 に固定。dart:io のデフォルトは
///       理論上 6 だが端末/Flutter バージョンで変動するため明示。
///   - idleTimeout = 15 秒
///       keep-alive socket を 15 秒で再利用。長すぎると累積、短すぎると
///       毎回 TCP/DNS 再接続でコスト悪化。
///   - connectionTimeout = 10 秒
///       到達不能ホストへの試行を 10 秒で諦める。fd ハングを防ぐ。
final HttpClient _ioClient = HttpClient()
  ..maxConnectionsPerHost = 6
  ..idleTimeout = const Duration(seconds: 15)
  ..connectionTimeout = const Duration(seconds: 10);

/// `flutter_map` の `NetworkTileProvider(httpClient: ...)` に渡すための
/// 共有クライアント。`RetryClient` で 1 回まで自動リトライする
/// (flutter_map デフォルト挙動と同等)。
final Client sharedTileHttpClient = RetryClient(IOClient(_ioClient));
