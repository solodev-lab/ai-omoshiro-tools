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
 * Flutter Engine の `setFrameworkHandlesBack` (PlatformChannel) /
 * `registerOnBackInvokedCallback` / `unregisterOnBackInvokedCallback`
 * を no-op で override し、Android dispatcher への登録自体を抑止する。
 * これによりエミュレータ実機上で警告は完全消滅。
 *
 * トレードオフ: Flutter の back 処理が Android の predictive back gesture
 * API 経由ではなく、legacy onBackPressed() フォールバック経路を通る。
 * Solara の戻る挙動 (画面遷移・モーダル閉じ) は維持される。
 *
 * 注: R8/ProGuard が空 body の override を strip しないよう
 * proguard-rules.pro で MainActivity を keep。
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
