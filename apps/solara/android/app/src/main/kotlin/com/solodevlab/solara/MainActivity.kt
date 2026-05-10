package com.solodevlab.solara

import io.flutter.embedding.android.FlutterActivity

/**
 * Solara 用 MainActivity。
 *
 * 2026-05-10: 旧実装で OnBackInvokedDispatcher への register/unregister と
 * setFrameworkHandlesBack を no-op override していた。これは
 *   W/WindowOnBackDispatcher: sendCancelIfRunning: isInProgress=false ...
 * の警告ノイズを抑える目的だったが、副作用として Flutter 側の PopScope
 * (onPopInvokedWithResult) が完全に無効化されていた:
 *   - Android 13+ の PopScope は OnBackInvokedDispatcher 経由で発火する
 *   - register を no-op にすると dispatcher が動かず PopScope.callback も呼ばれない
 *   - 結果、 Solara の Galaxy 等のタブから back ボタンを押すと、 PopScope
 *     によるタブ切替が起きずに直接 finish() = アプリ終了していた
 *
 * PopScope を機能させるため override を全廃止。 警告ノイズ
 * (sendCancelIfRunning) は Flutter Engine 既知 issue で致命ではないため
 * 受け入れる。
 *
 * 注: R8/ProGuard 設定 (proguard-rules.pro) で MainActivity を keep しているが、
 * 空 class でも keep ルールは有効。
 */
class MainActivity : FlutterActivity()
