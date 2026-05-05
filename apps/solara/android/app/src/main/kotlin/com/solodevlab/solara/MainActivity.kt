package com.solodevlab.solara

import io.flutter.embedding.android.FlutterActivity

/**
 * Solara 用 MainActivity。
 *
 * Android 13+ (API 33+) の OnBackInvokedDispatcher.register/unregister は
 * register-side で `sendCancelIfRunning` が必ず呼ばれ、現在進行中ジェスチャ
 * がない場合 (= ほぼ常にそう) Android Framework が
 *   W/WindowOnBackDispatcher: sendCancelIfRunning: isInProgress=false ...
 * という警告を吐く。Flutter は Route push/pop ごとに register/unregister を
 * 反復するため、ダイアログ/ドロップダウン等を 1 回開閉する度に警告が
 * 1〜2 件発生する。
 *
 * Flutter Engine では `setFrameworkHandlesBack` (PlatformChannel) /
 * `onCreate` 経由 (savedInstanceState 復元時) / `release` 経由などから
 * `registerOnBackInvokedCallback()` / `unregisterOnBackInvokedCallback()`
 * が呼ばれる。これら 2 つの public method を直接 no-op 化することで
 * Android dispatcher への登録自体を抑止し、警告を完全に消す。
 *
 * トレードオフ: Flutter の back 処理 (route pop) が Android の
 * predictive back gesture API を経由しなくなる。ただし legacy onBackPressed
 * のフォールバック経路は残るため Solara の動作 (戻る → 前画面) は維持される。
 */
class MainActivity : FlutterActivity() {

    /** Flutter からの toggle (PlatformChannel 経由) を完全無視。 */
    override fun setFrameworkHandlesBack(frameworkHandlesBack: Boolean) {
        // no-op
    }

    /** OnBackInvokedDispatcher への register をしない。 */
    override fun registerOnBackInvokedCallback() {
        // no-op
    }

    /** unregister も呼ぶ意味なし (register していないため)。 */
    override fun unregisterOnBackInvokedCallback() {
        // no-op
    }
}
