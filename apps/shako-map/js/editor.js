/* editor.js — 描画エンジン（正典 §4 / §6 / Step 2-3）
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * 設計の要点:
 *  1. 全オブジェクトは**緯度経度と実寸メートル**で持つ（正典 §1-2 / §6）。
 *     画面座標は保存しない。だからパン・ズームしてもズレないし、
 *     書き出し時に別解像度で描き直しても同じ図になる。
 *  2. SVG は**出力専用**。当たり判定・ドラッグは全部モデル座標の計算で行う。
 *     再描画のたびに SVG 要素を作り直しても、掴んでいる最中の操作が壊れない。
 *  3. 実寸 <-> 画面の換算は MapView.metersPerPixel(緯度) を使う。
 *     これは cos(緯度) を含むので、正典 §6 の「メルカトルの縮尺補正」を満たす。
 */
(function (global) {
  'use strict';

  var SVGNS = 'http://www.w3.org/2000/svg';
  var HANDLE = 7;        // つまみの半径(px)
  /* 🔒 §30-14-5 2（2026-09-10 オーナー指示）: 「4辺の□をもっと小さく。□をつかんで
   * しまい辺の長さ変更になる」→ **四角・塊の辺つまみだけ**小さくする（当たりは +2）。
   * 🔴 他の図形（線の端・多角形の頂点・ラベル）のつまみは HANDLE 7 のまま。 */
  /* 🔒 §30-25-17（2026-09-14 オーナー指示「ZL が高い時もう少し大きく」）:
   * 辺つまみの半径は**ズームに応じて可変**（段差より自然）。
   *   ZL ≤ 19 …… 4（今までのまま）／ZL ≥ 21 …… 8／その間は直線
   * 🔴 出どころは `Editor.prototype.edgeHandleR()` の1関数（描く2か所・当たり1か所が
   *    全部ここを通る）。線の端・多角形の頂点・文字のつまみは変えない。 */
  var HANDLE_EDGE_MIN = 4;          // 四角・塊の「辺つまみ」の半径(px・低い ZL）
  var HANDLE_EDGE_MAX = 8;          // 同（高い ZL）
  var HANDLE_EDGE_ZL = [19, 21];    // この間を直線でつなぐ
  /* 🔒 §30-22-3 3（2026-09-13 オーナー指示）: 選択した**文字の右下**に出す
   * 「大きさを変えるつまみ」の半径(px)。当たりは +3。 */
  var HANDLE_TEXT = 4;
  /* 🔒 §30-14-5 3: 四角（主役マーク以外）と塊の**中心**に置く移動の十字（✥）。
   * ドラッグ＝図形ごと移動（＝図形の中を掴んだ時と同じ move）。 */
  var MOVE_R = 8;        // 白丸の半径(px)
  var MOVE_HIT = 10;     // 十字の当たり半径(px)
  var HIT_PAD = 7;       // 線の当たり判定の太さ(px)
  /* 🔒 §30-38-2（2026-09-15 オーナー指示「Photoshop と同じで何かのキーを押しながら
   * 線をクリックすると頂点が増える仕組み」）: 頂点を足す・消す時に押しておくキー。
   * 🔴 出どころはこの1か所（Alt が Windows のメニューと取り合うようなら
   *    ここを 'shiftKey' 等に替えるだけでよい）。 */
  var VERTEX_KEY = 'altKey';
  /* 🔒 §30-38-1 5: 頂点のつまみを出す点の数の上限（これを超える図形には出さない）。
   * ［道路を描く］が縁を1本に繋ぐようになって長い道は 60 を超えるので 200 へ。
   * 🔴 描く3か所（_drawRoadRun / _drawPolygon の主役枝・ふつうの枝）と
   *    当たり1か所（hitHandle）が必ずここを読む（§22-z の教訓）。 */
  var VERTEX_HANDLE_MAX = 200;
  var MIN_PX = 6;        // 図形の最小サイズ(px)
  var HISTORY_MAX = 60;
  var DIM_LABEL_PX = 12; // 寸法ラベルの字の大きさ(px)。style.css の .dim-label と揃える

  /* 🔒 §25-8: 回転ボタン／矢印キー1回あたりの角度(°)。
   * 🔴 「刻みは実装後にオーナー目視で確定」なので**この1か所だけ**を直せば
   *    ボタン・キーの両方に効くようにしてある。 */
  var ROT_STEP = 0.5;

  /* 🔒 §25-7: 塊スタンプの「±方向ボタン」の寸法（すべて画面px）。
   * 意匠＝中央の枠の四方に大きな矢羽（＜ ＞ ∧ ∨）、その両脇に小さな＋と−。
   * 🔴 §30-19-2 で改めた: 矢羽は四辺とも同じ間隔にして、避ける側（回転つまみ
   *    §18-t・回転＋/−ボタン）を上へ離した（ROT_STEM_STAMP）。
   * 🔒 §30-14-5 1（2026-09-10 オーナー指示・参考画像に合わせた）: 「いまのは
   *   大きすぎてぐちゃぐちゃ」→ **全部を小さく・近く**した（旧値は括弧内）。
   *   🙋 数値はオーナー目視で微調整する（正典 §30-14-5 5）。 */
  var NAV_R = 6;          // ＋／− の丸の半径（旧 9）
  /* 🔒 §30-19-2（2026-09-13 オーナー指示）: 矢羽は**四辺とも**同じ間隔（旧 16／上だけ 34）。
   * 上を外へ逃がす役目は ROT_STEM_STAMP（回転の3つを上へ離す）に移した。 */
  var NAV_GAP = 24;       // 図形の縁から矢羽の中心まで（旧 16）
  var NAV_GAP_UP = 24;    // 上も同じ（旧 34・§30-19-2 で統一）
  var NAV_PM = 14;        // 矢羽の中心から＋／−までのずれ（矢羽と直角の方向・旧 24）
  var NAV_MINH = 16;      // 図形が小さい時に確保する最小の張り出し
  var NAV_CHEV = 7;       // 矢羽の長さ（先端までの半分・旧 10）
  var NAV_HIT = 9;        // 矢羽そのものの当たり半径（＝大きな＋の的・旧 14）
  var ROTBTN_R = 8;       // 回転＋／− の丸の半径（旧 10）
  var ROTBTN_OFF = 24;    // 回転つまみからの左右のずれ（旧 22・🔒 §30-19-2）
  /* 🔒 §30-14-5 1: 回転つまみの柄の長さ（旧 24）。
   * 🔴 描画（_drawStamp / _drawRect）・当たり判定（hitHandle）・回転ボタンの高さ
   *    （rotBtns）の**4か所が同じ値**を見る。全部 rotStemOf(o) を通す（§30-19-2）。
   * 🔒 §30-19-2: 塊（stampGroup）だけは矢羽（縁から 24・先端 31）とぶつかるので
   *    **かなり上**へ離す＝つまみの中心は縁から 58、柄の線は 38 から描き始める。
   *    四角（rect）は矢羽が無いので今までどおり 18 のまま。 */
  var ROT_STEM = 18;
  var ROT_STEM_STAMP = 58;       // 塊の回転つまみ・回転ボタンの高さ（縁から）
  var ROT_STEM_STAMP_LINE = 38;  // 塊の柄の線を描き始める高さ（矢羽の先より上）

  /* 🔴 §30-19-2: 描画と当たり判定が**同じ値**を見るための1か所。
   * 図形の種類だけで決める（表示文字列では分けない）。 */
  function rotStemOf(o) {
    return (o && o.type === 'stampGroup') ? ROT_STEM_STAMP : ROT_STEM;
  }

  /* 🔒 §30-19-3 1（2026-09-13 Fable 裁定）: 塊の上の縁は**張り出し後**の値
   * （矢羽 stampNav と同じ max(hh, NAV_MINH)）。小さい塊でも矢羽と回転の3つの
   * 隙間（58 − 24 − 矢羽の先 7 ＝ 27）がそのまま保たれる。 */
  function stampTopEdge(geo) { return Math.max(geo.hh, NAV_MINH); }

  /* 回転の3つ（つまみ・柄の始点・回転ボタン）が測る縁。
   * 🔴 描画（_drawStamp / _drawRect）・当たり判定（hitHandle）・回転ボタン
   *    （rotBtns）の**全部がこの1か所**を通る。四角（rect）は矢羽が無いので実寸のまま。 */
  function rotEdgeOf(o, geo) {
    return (o && o.type === 'stampGroup') ? stampTopEdge(geo) : geo.hh;
  }

  /* 🔒 §30-15-1（2026-09-13 オーナー指示）: 消しゴム道具のカーソルは**消しゴムの絵**。
   * 旧 'not-allowed'（禁止マーク）は「押しても無駄」に見えるので廃止。
   * 意匠: 斜めの角丸の四角（白い本体＋濃い先端）。先端が左下を向く＝消える場所が
   * ポインタの位置（ホットスポット 3 21）。
   * 🔴 出どころはこの1か所（setTool の _toolCursor が読む）。
   * 🔴 data URL は encodeURIComponent 済みにする（'#' が断片記号になって色が落ちる）。 */
  var ERASER_SVG =
    "<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24'>"
    + "<g stroke='#111827' stroke-width='1.6' stroke-linejoin='round'>"
    + "<path fill='#ffffff' d='M1.05 17.85L6.15 22.95L20.55 8.55L15.45 3.45Z'/>"
    + "<path fill='#6b7280' d='M1.05 17.85L6.15 22.95L10.39 18.71L5.29 13.61Z'/>"
    + "</g></svg>";
  var ERASER_CURSOR = 'url("data:image/svg+xml;utf8,'
    + encodeURIComponent(ERASER_SVG) + '") 3 21, auto';

  /* 🔒 §25-7 申し送りの決着（オーナー決定 2026-08-30）:
   * 「＋を押すと塊が伸びるので＋ボタン自体も1枠分(ZL21 で約33px)外へ動き、
   *  連打すると的を追いかけることになる」→ **ボタンを一定時間その場に固定する**。
   * 🔴 据え置くのは**見た目と当たり判定だけ**。塊の実データ(origin/count)は
   *    従来どおり即座に正しく更新する（freezeOverlay を参照）。
   * 連打のたびに時間は延長する（押し続ける限り動かない）。
   * 🔒 §30-25-5（2026-09-13 オーナー実機）: 「駐車枠の＋−を連続で押す時、
   *    アイコンが残る時間を2倍に」→ 600 → 1200。
   * 🔒 §30-25-5 改定（2026-09-14 オーナー実機「1200 では短い」）→ **2000**（2秒）。 */
  var NAV_FREEZE_MS = 2000;

  /* テキストの大きさ。
   * 🔴 実寸メートルで持ってはいけない。地図の注記は「紙面で一定の大きさ」で
   *    あるべきで、作図時のズームに左右されてはならない。
   *    （実寸で持っていた時は、引いた状態で所在図を作ると 50〜78m の巨大な
   *      文字になり、書き出すと図が文字で埋まった。）
   *    画面では画面px、紙面ではミリで解決する（export.js の SHEET_TEXT_MM）。 */
  var TEXT_PX = { small: 12, medium: 15, large: 19 };

  /* 🔒 §25-4（2026-08-29 オーナー指示）: 使用の本拠・駐車場の**主役マーク**。
   * ◎（二重丸・§18-r）をやめ、**四角＋色＋45°の斜線ハッチ**で描く。
   * べた塗りにしないのは、白黒コピーでも斜線として残り判別できるため
   * （配置図の伝統的作法とも一致・§23-9 の「塗り原則なし」の唯一の例外）。
   *
   * 🔴 数値の変更はこの表**1か所**で行う（オーナー目視で確定する予定）。
   *    生成の既定（shozaizu.js）・画面（editor.js）・紙（export.js）が
   *    すべてここを見る（export.js は global.Editor.MARK 経由）。
   * 🔴 マーカーは type:'rect' だが **role:'mainmark' の固有印**を持つ。
   *    車両枠と混同させないため、寸法ラベルを出さず（showDims:false）、
   *    ⑥の枠数・敷き詰め・提出前チェックの枠系判定からは外れる
   *    （それらは配置図 objects.haichizu 側だけを見る）。 */
  var MARK = {
    minMm: 4,        // 紙面での最小の一辺(mm)。広域の所在図でも見え続ける下限
    hatchMm: 1.6,    // 斜線ハッチの間隔(mm・45°)
    hatchW: 1.3,     // 斜線の太さ（画面px基準。紙は線幅倍率 S を掛ける）
    strokeW: 1.8,    // 輪郭線の太さ（同上）
    // 色は3択（🔒 §25-4「赤・オレンジ・黄」）。key を o.markColor に持つ
    colors: [
      { key: 'red',    ja: '赤',       hex: '#c0392b' },
      { key: 'orange', ja: 'オレンジ', hex: '#e06000' },
      { key: 'yellow', ja: '黄',       hex: '#c8a000' }
    ],
    // 生成時の既定。実寸(m)基準＝使用の本拠 10×10m・駐車場 6×10m（§25-4）
    kinds: {
      home: { w_m: 10, h_m: 10, color: 'red' },
      lot:  { w_m: 6,  h_m: 10, color: 'orange' }
    }
  };

  /* 🔒 §30-22-1 4 / §30-22-4 9（2026-09-13 オーナー指示）: 線の色は**黒／赤／青**。
   * 主役の多角形（mainpoly）と保管場所マークの書式が**同じ表**を読む。
   * 🔴 §25-4 の四角の印の色（赤／オレンジ／黄＝ MARK.colors）とは別の表。
   *    混ぜない ―― 四角の印は「地図の中の主役」、こちらは「線の書式」。 */
  var INK = [
    { key: 'black', ja: '黒', hex: '#111111' },
    { key: 'red',   ja: '赤', hex: '#c0392b' },
    { key: 'blue',  ja: '青', hex: '#1d4ed8' }
  ];
  function inkHex(key) {
    for (var i = 0; i < INK.length; i++) {
      if (INK[i].key === key) return INK[i].hex;
    }
    return INK[0].hex;
  }

  /* 🔒 §30-22-1 4: 線の太さ3段（細／標準／太）。数値の出どころはこの1か所 */
  var POLY_W = [
    { key: 'thin',   ja: '細',   w: 1.2 },
    { key: 'normal', ja: '標準', w: 2 },
    { key: 'thick',  ja: '太',   w: 3.2 }
  ];
  function polyW(key) {
    for (var i = 0; i < POLY_W.length; i++) {
      if (POLY_W[i].key === key) return POLY_W[i].w;
    }
    return POLY_W[1].w;
  }

  /**
   * 🔒 §30-22-1 4: 多角形の重心（＝ピンの位置）。
   * 🔴 面の重心ではなく**頂点の平均**にする。頂点を掴んで形を直した時も
   *    「動かした分だけ」重心が動く＝画面（editor.js）と案件の追従（app.js の
   *    syncRoleObjects）で必ず同じ値になり、行ったり来たりしない。
   */
  function polyCentroid(pts) {
    if (!pts || !pts.length) return null;
    var lat = 0, lng = 0;
    for (var i = 0; i < pts.length; i++) { lat += pts[i].lat; lng += pts[i].lng; }
    return { lat: lat / pts.length, lng: lng / pts.length };
  }

  /* 🔒 2026-09-02 オーナー指示: **交差点名の印は●ではなく信号機のアイコン**。
   * 意匠（Fable 指定）: 日本の信号機は横型なので**横長の角丸矩形の輪郭＋中に3つの●**。
   * §23-9 の全体則どおり**線だけで描く**（矩形は塗らない。塗るのは3つの灯だけ）。
   *
   * 🔴 数値の変更はこの表**1か所**で行う。画面（editor.js）・薄出し（reveal.js）・
   *    紙（export.js）が全部 Editor.signalGeom を呼ぶ（Editor.MARK / roadBand と同じ作法）。
   * 比率の基準は**その文字の大きさ**（画面px／紙面px）。交差点名は size:'medium'
   * ＝ 画面 15px・紙 3.4mm×SHEET_SCALE 1.377 ＝ 4.68mm なので、実寸は
   *   幅 18.8px / 5.85mm・高さ 8.3px / 2.58mm・灯 直径 3.9px / 1.22mm
   *   輪郭 1.6U ＝ 紙 0.304mm（§23-9-b の下限 0.2mm を上回る）。 */
  var SIGNAL = {
    w:  1.25,    // 横幅 ＝ 文字サイズ × この比
    h:  0.55,    // 高さ（横型なので幅の 0.44 倍）
    r:  0.13,    // 灯（●）の半径
    gap: 0.375,  // 灯の中心間の間隔（左灯・中灯・右灯）
    rx: 0.16,    // 角丸の半径
    lw: 1.6      // 輪郭の太さ（画面px基準。紙は線幅倍率 S を掛ける＝ MARK.strokeW と同じ作法）
  };
  /** 信号機アイコンの実寸。size ＝ その文字の大きさ（画面px または 紙面px） */
  function signalGeom(size) {
    return { w: size * SIGNAL.w, h: size * SIGNAL.h, r: size * SIGNAL.r,
             gap: size * SIGNAL.gap, rx: size * SIGNAL.rx, lw: SIGNAL.lw };
  }

  /* 🔒 2026-09-04 オーナー指示: **バス停の印は●ではなく標識アイコン**。
   * 意匠（オーナー指定）: 縦長の角丸矩形の輪郭（標識板・中に灯は入れない＝縦型信号機との
   * 混同を避ける）＋ポール（縦線）＋逆さT字の足（横線）。§23-9「線だけで描く」どおり
   * 塗りは一切なし。交差点の信号機（横長・§22-aj-2）とは縦横・足の有無の両方で見分けが付く。
   *
   * 🔴 数値の変更はこの表**1か所**で行う。画面（editor.js）・薄出し（reveal.js）・
   *    紙（export.js）が全部 Editor.busStopGeom を呼ぶ（Editor.SIGNAL / signalGeom と同じ作法）。
   * 🔴 anchor（実世界の位置）は**足が地面に着く点**＝アイコンは anchor から上へだけ伸びる
   *    （signalGeom の「矩形が anchor を中心に上下対称」とは違う。看板の設置点を指す作法）。
   *    比率の基準は signalGeom と同じく**その文字の大きさ**（画面px／紙面px）。 */
  var BUSSTOP = {
    bw: 0.42,    // 標識板の幅 ＝ 文字サイズ × この比
    bh: 0.68,    // 標識板の高さ（縦型なので幅より高い）
    rx: 0.10,    // 角丸の半径
    pole: 0.32,  // ポール長（板の下端〜足の中心）
    foot: 0.50,  // 足（逆さT字の横棒）の全長。板の幅より広くして「足」に見せる
    lw: 1.6      // 輪郭・線の太さ（画面px基準。紙は線幅倍率 S を掛ける＝ SIGNAL.lw と同じ作法）
  };
  /** バス停標識アイコンの実寸。size ＝ その文字の大きさ（画面px または 紙面px） */
  function busStopGeom(size) {
    return { bw: size * BUSSTOP.bw, bh: size * BUSSTOP.bh, rx: size * BUSSTOP.rx,
             pole: size * BUSSTOP.pole, foot: size * BUSSTOP.foot, lw: BUSSTOP.lw,
             // 全高＝ anchor（足の接地点）から板の上端までの伸び（reveal.js の逃がし量が使う）
             h: size * (BUSSTOP.pole + BUSSTOP.bh) };
  }

  /* 🔒 §30-22-3 2（2026-09-13 オーナー指示）: **P マーク**＝□の中に「P」。
   * 意匠: 角丸の正方形の輪郭（塗らない・§23-9）＋中央に太字の P。
   * 🔴 大きさの決め方は信号機・バス停と同じ規則＝**その文字の大きさ**の比。
   *    数値の変更はこの表 1か所（画面 editor.js・紙 export.js が
   *    Editor.parkingGeom を読む＝ Editor.SIGNAL / BUSSTOP と同じ作法）。
   * 🔴 anchor は箱の**中心**（信号機と同じ。バス停の接地点方式ではない）。 */
  var PARKING = {
    s:    0.95,   // 一辺 ＝ 文字サイズ × この比
    rx:   0.12,   // 角丸の半径
    font: 0.72,   // 中の「P」の字の大きさ
    lw:   1.6     // 輪郭の太さ（画面px基準。紙は線幅倍率 S を掛ける）
  };
  /** P マークの実寸。size ＝ その文字の大きさ（画面px または 紙面px） */
  function parkingGeom(size) {
    return { s: size * PARKING.s, rx: size * PARKING.rx,
             font: size * PARKING.font, lw: PARKING.lw };
  }

  /* 🔒 §30-25-9（2026-09-13 オーナー指示「木はテキストから削除して、印を置くに
   * 木を加える」）: **木の印**＝落葉樹の記号（樹冠＋幹）。
   * 🔒 §30-30-2: 樹冠は**もこもこ**（雲のような輪郭・下の canopy）。
   * 意匠: 樹冠は**線だけ・白で塗る**（§23-9 の全体則。下の地図が透けない）。
   * 🔴 数値の変更はこの表**1か所**。画面（editor.js）・紙（export.js）・
   *    道具の絵（app.js TOOL_ICONS）が全部 Editor.TREE / Editor.treeGeom を読む
   *    （Editor.SIGNAL / BUSSTOP / PARKING と同じ作法）。
   * 🔴 anchor（置いた点）＝**幹の下端**（バス停の接地点方式）。
   * 🔴 比率の基準は信号機・バス停・P と同じく**その文字の大きさ**。正典の寸法
   *    （紙 mm）は「中サイズの文字（紙 3.4mm × SHEET_SCALE 1.377 ＝ 4.68mm）」
   *    と並べた時の値で、そこから比に直してある:
   *      樹冠の半径 1.8mm ÷ 4.68mm ＝ 0.385 ／ 幹の長さ 1.6mm ÷ 4.68mm ＝ 0.342 */
  /* 🔒 §30-30-2（2026-09-15 オーナー指示「木のイメージをもう少しもこもこできない？」）:
   * 樹冠は**円1つ**から**雲のような輪郭**（7つのふくらみの和集合の外形）にした。
   * 🔴 数値はこの `canopy` の表**1か所**。[中心x, 中心y, 半径] の点列で、単位は
   *    「樹冠の**横の半径** ＝ 1」の単位空間（中心が原点・y は画面と同じく下が＋）。
   *    ＝ 旧（円）の r と同じ物差しなので、横幅は今までと変わらない。
   * 🔴 並びは**真上から時計まわり**（輪郭をこの順に辿る）。上のふくらみを大きく・
   *    下を小さくして「上が大きめ・下は幹に向かってすぼむ」形にしてある。
   *    真下は隣り合う2つのふくらみの谷＝そこに幹が刺さる（treeCanopyArcs の joint）。 */
  var TREE = {
    r:     0.385,  // 樹冠の横の半径 ＝ 文字サイズ × この比（紙 1.8mm 相当）
    trunk: 0.342,  // 幹の長さ（樹冠の谷 → 置いた点。紙 1.6mm 相当）
    lw:    1.6,    // 線の太さ（信号機と同じ。紙は線幅倍率 S を掛ける）
    canopy: [
      [ 0.00000, -0.70906, 0.45122],
      [ 0.53539, -0.42696, 0.43099],
      [ 0.61445,  0.14024, 0.38555],
      [ 0.25448,  0.52844, 0.34910],
      [-0.25448,  0.52844, 0.34910],
      [-0.61445,  0.14024, 0.38555],
      [-0.53539, -0.42696, 0.43099]
    ]
  };

  /** 2つの円の交点のうち**外側**（原点から遠い方）＝輪郭の谷。🔒 §30-30-2 */
  function treeCanopyJoint(a, b) {
    var dx = b[0] - a[0], dy = b[1] - a[1];
    var d = Math.sqrt(dx * dx + dy * dy);
    if (!(d > 0)) return [a[0], a[1]];
    var t = (a[2] * a[2] - b[2] * b[2] + d * d) / (2 * d);
    var h = Math.sqrt(Math.max(0, a[2] * a[2] - t * t));
    var mx = a[0] + t * dx / d, my = a[1] + t * dy / d;
    var p = [mx - h * dy / d, my + h * dx / d];
    var q = [mx + h * dy / d, my - h * dx / d];
    return (p[0] * p[0] + p[1] * p[1] > q[0] * q[0] + q[1] * q[1]) ? p : q;
  }

  /**
   * 🔒 §30-30-2: 樹冠の輪郭（単位空間）。TREE.canopy から**1回だけ**組み立てる。
   * @return {arcs, hw, up, joint}
   *   arcs＝[{x,y,r,a0,sweep,x0,y0,x1,y1}]（円の中心・半径・始点角・回す量・両端の点）
   *   hw＝外接の半幅（＝1）／up＝中心から上端まで／joint＝幹が刺さる谷の y（下が＋）
   */
  var _treeCanopy = null;
  function treeCanopyArcs() {
    if (_treeCanopy) return _treeCanopy;
    var c = TREE.canopy, n = c.length, j = [], i;
    for (i = 0; i < n; i++) j.push(treeCanopyJoint(c[i], c[(i + 1) % n]));
    var arcs = [], hw = 0, up = 0, joint = -Infinity;
    for (i = 0; i < n; i++) {
      var k = c[i], p0 = j[(i - 1 + n) % n], p1 = j[i];
      var a0 = Math.atan2(p0[1] - k[1], p0[0] - k[0]);
      var a1 = Math.atan2(p1[1] - k[1], p1[0] - k[0]);
      var sw = a1 - a0;
      while (sw < 0) sw += Math.PI * 2;
      arcs.push({ x: k[0], y: k[1], r: k[2], a0: a0, sweep: sw,
                  x0: p0[0], y0: p0[1], x1: p1[0], y1: p1[1] });
      hw = Math.max(hw, Math.abs(k[0]) + k[2]);
      up = Math.max(up, k[2] - k[1]);
      if (p1[1] > joint) joint = p1[1];
    }
    _treeCanopy = { arcs: arcs, hw: hw, up: up, joint: joint };
    return _treeCanopy;
  }

  /**
   * 🔒 §30-30-2: 樹冠の輪郭を SVG の `d` にする（画面 editor.js と道具の絵 app.js が読む）。
   * @param cx,cy 樹冠の中心（px）／@param r 樹冠の横の半径（px）
   */
  function treeCanopyPath(cx, cy, r) {
    var a = treeCanopyArcs().arcs, i, d = '';
    for (i = 0; i < a.length; i++) {
      var rr = (a[i].r * r).toFixed(2);
      if (i === 0) {
        d += 'M' + (cx + a[i].x0 * r).toFixed(2) + ' ' + (cy + a[i].y0 * r).toFixed(2);
      }
      d += 'A' + rr + ' ' + rr + ' 0 ' + (a[i].sweep > Math.PI ? 1 : 0) + ' 1 '
         + (cx + a[i].x1 * r).toFixed(2) + ' ' + (cy + a[i].y1 * r).toFixed(2);
    }
    return d + 'Z';
  }

  /** 木の印の実寸。size ＝ **印の大きさ**（画面px または 紙面px・🔒 §30-30-1）
   *  @return {r, trunk, cy, hw, up, h, lw} cy＝anchor から樹冠の中心までのずれ（上が−）／
   *    hw＝樹冠の外接の半幅／h＝全高（anchor から樹冠の上端まで） */
  function treeGeom(size) {
    var C = treeCanopyArcs();
    var r = size * TREE.r, tr = size * TREE.trunk;
    return { r: r, trunk: tr, cy: -(tr + r * C.joint), hw: r * C.hw, up: r * C.up,
             h: tr + r * (C.joint + C.up), lw: TREE.lw };
  }

  /* 🔒 §28-5 A / §28-7（2026-09-07）: 手で置く「印つき文字」の道具。
   * 道具の名前 → 印の種類（dotStyle）と分類（nameCat）。
   * 🔴 中身は自動生成・なぞり出しと**同じデータの形**（§22-aj-2 / §22-al-3）。
   *    出どころだけが違う（nameSrc/source ＝ 'manual'）ので、
   *    所在図の作り直し（source==='shozaizu' だけ消す）でも消えない。
   * 🔴 表示文字ではなくこの表の id で分岐する（§26-2 注意②）。 */
  /* 🔒 §30-35-2 1・2: `askName` ＝ 置いた後に**名前の入力欄を出すか**。
   * 信号機・バス停は交差点名・停留所名を続けて聞く（true）。
   * P・木は置いた瞬間に印だけ（false）＝ placeMark が 'text' を投げない。
   * 🔴 この表が唯一の出どころ（呼ぶ側で道具の名前を見て分岐しない）。 */
  var MARK_TOOL = {
    signal:  { dotStyle: 'signal',  nameCat: 'crossing', askName: true },
    bus:     { dotStyle: 'bus',     nameCat: 'bus',      askName: true },
    /* 🔒 §30-22-3 2（2026-09-13 オーナー指示）: **P マーク**（□の中に P）。
     * 中身は信号機・バス停とまったく同じ「印つき文字」で、印の絵だけが違う。
     * 🔒 §30-35-2 1（2026-09-15 オーナー指示）: 名前は聞かない（印だけ）。 */
    parking: { dotStyle: 'parking', nameCat: 'parking',  askName: false },
    /* 🔒 §30-25-9（2026-09-13 オーナー指示）: **木**（樹冠＋幹・🔒 §30-30-2 もこもこ）。
     * 中身は信号機・P マークとまったく同じ「印つき文字」で、印の絵だけが違う。
     * 🔒 §30-35-2 1: 木も名前は聞かない（印だけ）。 */
    tree:    { dotStyle: 'tree',    nameCat: 'tree',     askName: false }
  };

  /** その文字が「印だけでも意味を持つ」物か（文字が空でも消さない・§28-5 A） */
  function keepsMark(o) {
    return !!(o && o.type === 'text' && o.anchor
              && (o.dotStyle === 'signal' || o.dotStyle === 'bus'
                  || o.dotStyle === 'parking' || o.dotStyle === 'tree'));
  }

  /**
   * 🔒 §30-25-28: **印の隣に置く文字**か。「印を置く」の4種（keepsMark）に加えて
   * 主役ラベル（使用の本拠・駐車場＝ role:'pinlabel'）も同じ規則で置く
   * （マーカーを置いた瞬間に印の右隣へ出すため・置き場所の規則は markTextAt 1か所）。
   * 🔴 表示文字では分岐しない（role / dotStyle で見る・§26-2 注意②）。
   */
  function sitsByMark(o) {
    return !!(keepsMark(o)
              || (o && o.type === 'text' && o.anchor && o.role === 'pinlabel'));
  }

  /** 🔒 §30-25-28: 手で動かした／大きさを変えた主役ラベルの印（生成が上書きしない） */
  function noteUserMoved(o) {
    if (o && o.type === 'text' && o.role === 'pinlabel') o.userMoved = true;
  }

  /* 🔒 §30-25-18 3（2026-09-14 オーナー指示「印を置くマーカー4種類が置いたら
   * 動かせない。大きさも変えたい」）: 印の大きさの倍率 `o.markScale`。
   * 🔴 上下限の出どころはこの**1か所**（つまみのドラッグ・右パネルのボタン・
   *    store.js の読み込みが全部ここを通る）。
   * 🔴 効くのは「印を置く」の4種（keepsMark）だけ。●／◎／四角の印には掛けない。 */
  /* 🔒 §30-25-37（2026-09-14 オーナー指示「使用の本拠・駐車場の◎と□斜線の
   *    マーカーサイズを変更できるように」）: **主役ラベル（role:'pinlabel'）にも**
   *    同じ倍率を効かせる（◎の輪の半径・線の太さ／■の四角の実寸）。
   *    ＝ 門は sitsByMark（「印を置く」の4種＋主役ラベル）。
   *    値の出どころは案件の points[key].mark.scale 1つで、app.js applyMarkChoice が
   *    そこから図形の markScale へ写す。 */
  /* 🔒 §30-30-3 2: 大きさの上限をなくす（max:Infinity）。Math.min(Infinity, v) は
   * v のままなので clampMarkScale／markScaleOf／store.js の丸めは変更不要。
   * JSON には常に丸めた**値**だけを書く（MARK_SCALE_RANGE.max 自体を書き出さない）。 */
  var MARK_SCALE_RANGE = { min: 0.2, max: Infinity, def: 1 };

  /** その印の倍率（持っていなければ 1）。🔴 値の出どころは markScale の1か所 */
  function markScaleOf(o) {
    if (!sitsByMark(o)) return 1;
    var v = Number(o.markScale);
    if (!isFinite(v) || !(v > 0)) return MARK_SCALE_RANGE.def;
    return Math.max(MARK_SCALE_RANGE.min, Math.min(MARK_SCALE_RANGE.max, v));
  }
  function clampMarkScale(v) {
    var n = Number(v);
    if (!isFinite(n) || !(n > 0)) return MARK_SCALE_RANGE.def;
    return Math.max(MARK_SCALE_RANGE.min,
                    Math.min(MARK_SCALE_RANGE.max, Math.round(n * 100) / 100));
  }

  /* 🔒 §30-32-2（2026-09-15 オーナー指示「配置図ガイダンスのプレビューで
   *    駐車位置ラベルも動かせる・サイズを変更できるように」）: 駐車位置ラベルの塊
   *    （labelBlock）の大きさ（倍率）の上下限。
   * 🔴 値の出どころはこの1か所。画面の右下のつまみ（_drag の lbSize）と
   *    プレビューのつまみ（app.js exTextLayer）が同じ範囲で丸める。 */
  var LABEL_SCALE_RANGE = { min: 0.5, max: 4, def: 1 };
  function clampLabelScale(v) {
    var n = Number(v);
    if (!isFinite(n) || !(n > 0)) return LABEL_SCALE_RANGE.def;
    return Math.max(LABEL_SCALE_RANGE.min,
                    Math.min(LABEL_SCALE_RANGE.max, Math.round(n * 100) / 100));
  }

  /* 🔒 §30-25-40（2026-09-14 オーナー指示「印やテキストの拡大縮小と同じ動作に。
   *    左メニューの印の大きさの選択肢は無くす」）: 主役の印（◎・■）の大きさは
   *    **つまみ**で変える。印つき文字4種のつまみ（§30-25-18 3）と同じ見た目・
   *    同じドラッグの作法だが、**値の書き先が違う**。
   * 🔴 主役の印の値の出どころは案件の `points[key].mark.scale` **1か所**
   *    （◎の markScale も■の w_m/h_m も app.js applyMarkChoice がそこから写す）。
   *    ＝ editor は図形へ直接書かず app.js の口（onMainMarkScale）へ渡す。 */

  /** 主役の◎（主役の文字＝ role:'pinlabel' の二重丸）か。🔴 表示文字では分岐しない */
  function isMainRing(o) {
    return !!(o && o.type === 'text' && o.anchor
              && o.role === 'pinlabel' && o.dotStyle === 'double');
  }

  /**
   * 🔒 §30-25-40 2〜4: その図形が**主役の印につながる物**（主役の文字＝ pinlabel／
   * ■＝主役の四角）なら、どちらの地点の物かを返す（そうでなければ null）。
   * 🔴 判定は role / markRole（§26-2 注意②）。◎のつまみを出すかどうかは別判定
   *    （isMainRing＝ dotStyle:'double' の時だけ）。右パネルの「印の大きさ」は
   *    ■を選んだ時の主役の文字にも出すので、ここでは dotStyle で絞らない。
   */
  function mainMarkKeyOf(o) {
    if (!o) return null;
    if (o.type === 'rect' && o.role === 'mainmark') {
      return (o.markRole === 'lot') ? 'lot' : 'home';
    }
    if (o.type === 'text' && o.anchor && o.role === 'pinlabel') {
      return (o.pinKey === 'lot') ? 'lot' : 'home';
    }
    return null;
  }

  /** 🔒 §30-25-40: 主役の印の今の倍率（◎＝文字の markScale ／■＝四角の markScale） */
  function mainMarkScaleOf(o) {
    if (o && o.type === 'rect' && o.role === 'mainmark') return clampMarkScale(o.markScale);
    /* 🔒 §30-37 1: 方位記号も同じつまみで大きさを変える（倍率は図形の markScale）。
     * ここを通さないと、ドラッグの基準（drag.base）が毎回 1 に戻ってしまう。 */
    if (o && o.type === 'compass') return clampMarkScale(o.markScale);
    return markScaleOf(o);
  }

  /* 🔒 §30-30-1（2026-09-15 オーナー指示「信号機アイコン、テキストを拡大縮小すると
   *    信号機まで拡大縮小されてしまう。それぞれ独立して」）: 印の**基準の大きさ**は
   *    紙のミリで固定（＝文字「中」と同じ 3.4mm）。文字の大きさ（sizeMm）は印に
   *    一切効かない。印を変えるのは印の倍率（markScale）だけ。
   * 🔴 値の出どころは export.js の SHEET_TEXT_MM.medium **1か所**（読めない時＝
   *    単体テストの予備だけここに持つ・textMmTable と同じ作法）。 */
  var MARK_BASE_MM_FALLBACK = 3.4;
  function markBaseMm() {
    var mm = textMmTable().medium;
    return (mm > 0) ? mm : MARK_BASE_MM_FALLBACK;
  }

  /**
   * 🔒 §30-30-1: 印の絵を描く時の「大きさ」＝ **基準（固定）× markScale**。
   * 🔴 画面（editor.js `_drawText`）・紙（export.js `drawAnchor`）・箱（markGeom /
   *    markBoxGeom）が全部ここを通る＝画面と紙で必ず同じ大きさになる。
   * 🔴 基準は「紙 MARK_BASE_MM が呼ぶ側の単位でいくつか」＝ basePx。
   *    画面は `MARK_BASE_MM × this.mmPx()`／紙は `mmPx(MARK_BASE_MM, pxmm)` を渡す。
   *    渡されない時（所在図 shozaizu.js は実距離mで呼ぶ）は、size が文字の紙ミリに
   *    比例することを使って `size × MARK_BASE_MM ÷ その文字の紙ミリ` で逆算する
   *    ＝ どの単位で呼んでも「文字の大きさに連動しない」が保てる。
   * 🔴 第2引数 size は**この関数では大きさとして使わない**（基準の逆算だけに使う）。
   *    呼ぶ側の引数はそのまま（§30-30-1 の直しで意味だけが変わった）。
   * 🔴 薄出しの仮の印（reveal.js / namelay.js）は markScale を持たない図形なので
   *    倍率1（大きさは呼ぶ側が基準 basePx を渡す）。
   */
  function markSizeOf(o, size, basePx) {
    var b = (typeof basePx === 'number' && isFinite(basePx) && basePx > 0)
          ? basePx : markBaseFrom(o, size);
    return b * markScaleOf(o);
  }
  /** 🔒 §30-30-1: 基準が渡されない時の逆算（size の単位で MARK_BASE_MM 相当を返す） */
  function markBaseFrom(o, size) {
    var mm = textMmOf(o);
    return (mm > 0 && size > 0) ? size * (markBaseMm() / mm) : size;
  }

  /**
   * 🔒 §30-25-37 1: ■（主役の四角の印・role:'mainmark'）の実寸 ＝ **基準 × 倍率**。
   * 🔴 基準は MARK.kinds（この表1か所）。makeMark（作る時）も applyMarkChoice
   *    （倍率を変えて引き直す時）もここを読む＝値の出どころが割れない。
   * @param {'home'|'lot'} kind
   * @param {number} scale 倍率（省略・範囲外は clampMarkScale が 0.5〜3 に丸める）
   * @return {{w_m:number, h_m:number, scale:number}}
   */
  function markRectDims(kind, scale) {
    var k = MARK.kinds[kind] || MARK.kinds.home;
    var s = clampMarkScale(scale);
    return { w_m: k.w_m * s, h_m: k.h_m * s, scale: s };
  }

  /* 🔒 §30-31-1（2026-09-15 オーナー指示「①の□マーカー、4辺を自由に調節したい。
   *    いまは正方形しか作れないが長方形も作りたい」）: ■の実寸は図形の `w_m/h_m`
   *    （＝案件の points[key].mark.w_m/h_m）が**真実**。倍率（markScale）は
   *    ◎のための値として残る。
   * 🔴 基準（MARK.kinds）に対する**軸ごとの比**＝紙の最小 mm に掛ける倍率。
   *    縦横が同じ比の時は従来（minMm × markScale）と同じ値になる＝後方互換。 */
  function markAxisScale(o) {
    var k = MARK.kinds[(o && o.markRole === 'lot') ? 'lot' : 'home'] || MARK.kinds.home;
    var s = clampMarkScale(o && o.markScale);
    var w = (k.w_m > 0 && o && o.w_m > 0) ? (o.w_m / k.w_m) : s;
    var h = (k.h_m > 0 && o && o.h_m > 0) ? (o.h_m / k.h_m) : s;
    return { w: w, h: h };
  }

  /**
   * 🔒 §30-31-1 3: ■の**紙の最小 mm（縦横それぞれ）**。
   * 🔴 画面（rectHalf）も紙（export.js rectCorners）もここを通る＝長方形の比が
   *    広域でも崩れない（縦横に同じ下限を当てると正方形に化ける）。
   */
  function markMinMm(o) {
    var a = markAxisScale(o);
    return { w: MARK.minMm * a.w, h: MARK.minMm * a.h };
  }

  /* 🔒 §30-25-37 1: ◎（主役の二重丸）の輪の線の太さ。CSS（.anno-ring）・紙（export.js）
   * と同じ値をここに置き、倍率（markScale）を掛けて style で入れる。 */
  var RING_W = 2.2;

  /* 🔒 §30-15-3: 印つき文字（信号機・バス停）の名前は**印の右隣**に置く。
   * 隙間は入力欄（app.js）と確定した文字（commitText）の**両方**が読む1か所。 */
  /* 🔒 §30-25-7: 画面px の固定値（6px）をやめ、**文字の大きさに比例**させた
   * （文字がズームに連動するようになったので、隙間だけ固定だと近づき過ぎ／離れ過ぎる）。
   * 値は下の MARK_TEXT_GAP_MM と同じ規則＝隙間の出どころは1つ。 */
  var MARK_TEXT_GAP_MIN = 3;   // 印の右端 → 文字の左端の下限（画面px）

  /* 🔒 §30-15-5 規則2（2026-09-13 Fable 裁定）: **隙間は紙基準**。
   * 画面 px のまま緯度経度へ焼くと、名付けた時のズームで紙の見え方が変わる
   * （ZL17 では隙間 6〜7mm・ZL19 以上では印と文字が重なる）。
   * 枠が決まっている紙では「紙に刷られる文字の高さ(mm)× この比」を隙間にする。 */
  var MARK_TEXT_GAP_MM = 0.4;

  /* 🔒 §18-r: 点に付く名前の●の半径 ÷ 文字の高さ。◎（自宅・駐車場）はこの2倍。
   * 🔴 描画（_drawText）・印の半幅（markGeom）・所在図の置き場所（shozaizu.js が
   *    Editor.markGeom 経由で読む）の**1か所**。画面では最小 DOT_MIN_PX まで。 */
  var DOT_R = 0.24;
  var DOT_MIN_PX = 2.4;

  /**
   * 🔒 §30-25-40 2: ◎（主役の印）の**外側の輪の半径**（画面px）。
   * 🔴 描画（_drawText の rr）・箱（markBoxGeom＝つまみの位置と当たり）が
   *    必ずここを通る＝つまみが輪の右下にぴったり載る（§22-z の教訓）。
   * 🔒 §30-30-1: 半径は**文字の大きさに連動しない**。基準（MARK_BASE_MM × mmPx）に
   *    主役の印の倍率（mainMarkScaleOf）を掛ける＝文字を大きくしても◎は動かない。
   * @param size 文字の大きさ（基準 basePx が渡されない時の逆算だけに使う）
   * @param basePx 印の基準の大きさ（画面＝ MARK_BASE_MM × mmPx()）
   */
  function mainRingR(o, size, basePx) {
    var b = (typeof basePx === 'number' && isFinite(basePx) && basePx > 0)
          ? basePx : markBaseFrom(o, size);
    return Math.max(DOT_MIN_PX, b * DOT_R) * 2 * mainMarkScaleOf(o);
  }

  /* 緯度1度の地上距離(m)。経度は cos(緯度) を掛ける（editor.js 内の既存の作法と同値） */
  var M_PER_DEG = 111320;

  /** 同じ緯度経度か（≒0.1mm。「文字をまだ動かしていない」の判定に使う） */
  function sameLL(a, b) {
    return !!(a && b && Math.abs(a.lat - b.lat) < 1e-9
                     && Math.abs(a.lng - b.lng) < 1e-9);
  }

  /**
   * 🔒 §30-15-5 規則2: 紙に実際に刷られる文字の高さ(mm)。
   * 🔴 数値の出どころは export.js（SHEET_TEXT_MM × SHEET_SCALE）**1か所**。
   *    export.js が読み込まれていない時（単体テスト）は null ＝ 画面px に落ちる。
   */
  function sheetTextMm(o) {
    var E = global.Exporter;
    if (!E || !E.SHEET_TEXT_MM || !(E.SHEET_SCALE > 0)) return null;
    var mm = textMmOf(o);
    return mm > 0 ? mm * E.SHEET_SCALE : null;
  }

  /* 🔒 §30-22-3 3（2026-09-13 オーナー指示）: **文字の大きさは連続値（紙のミリ）**。
   * 小／中／大（o.size）は「その値の目安の既定」に格下げした。
   * 🔴 o.sizeMm を持つ物だけが連続値。持たない旧データは今までどおり
   *    TEXT_PX / SHEET_TEXT_MM の3段で描く（見た目を1pxも変えない）。
   * 🔴 表の出どころは export.js（SHEET_TEXT_MM）1か所。読めない時（単体テスト）の
   *    保険だけここに持つ（値は export.js と同じ）。 */
  var TEXT_MM_FALLBACK = { small: 2.6, medium: 3.4, large: 4.4 };
  function textMmTable() {
    var E = global.Exporter;
    return (E && E.SHEET_TEXT_MM) || TEXT_MM_FALLBACK;
  }
  /* 🔒 §30-25-7: 補助文字（寸法・保管場所・番号）の紙面ミリ。
   * 🔴 表の出どころは export.js（LABEL_MM）1か所。読めない時（単体テスト）の
   *    保険だけここに持つ（値は export.js と同じ）。
   * 🔒 §30-25-19: 保管場所マークは**印だけ**になった（「保管場所」の文字は出さない）
   *    ので、いまこの関数を呼ぶ所は無い。表そのものは紙（export.js）が使うので残す。 */
  var LABEL_MM_FALLBACK = { dim: 3.4, storage: 3.4, number: 4.4 };
  function labelMm(key) {
    var E = global.Exporter;
    var T = (E && E.LABEL_MM) || LABEL_MM_FALLBACK;
    return T[key] || LABEL_MM_FALLBACK[key] || LABEL_MM_FALLBACK.dim;
  }

  /* 🔒 §30-22-3 3 / §30-25-10 2: 文字の大きさ（紙のミリ）の上限・下限。
   * 🔴 画面のつまみ（textSize ドラッグ）と、プレビューのつまみ（app.js）が
   *    **同じ1か所**を読む（値が2か所に割れない）。 */
  var TEXT_MM_RANGE = { min: 1.2, max: 30 };
  function clampTextMm(mm) {
    if (!(mm > 0)) return TEXT_MM_RANGE.min;
    return Math.max(TEXT_MM_RANGE.min,
                    Math.min(TEXT_MM_RANGE.max, Math.round(mm * 100) / 100));
  }

  /** その文字の紙面ミリ（連続値があればそれ・無ければ3段の既定） */
  function textMmOf(o) {
    if (o && o.sizeMm > 0) return o.sizeMm;
    var T = textMmTable();
    return T[(o && o.size) || 'medium'] || T.medium;
  }

  /** 緯度経度を東(dxM)・南(dyM) へメートルでずらす（y は画面と同じく下が＋） */
  function offsetLL(ll, dxM, dyM) {
    var c = Math.cos(ll.lat * Math.PI / 180);
    return { lat: ll.lat - dyM / M_PER_DEG,
             lng: ll.lng + dxM / (M_PER_DEG * Math.max(1e-6, c)) };
  }

  /* 🔒 §30-35-3 4: 実距離(m) ⇄ 緯度経度の換算は**この2つ1か所**。
   * makeMark（作る時）・app.js の setMainMarkDims（書く時）・syncRoleObjects /
   * applyMarkChoice（追従する時）が全部同じ物を読む＝ずれの意味が割れない。
   * 🔴 向きは**東が dx_m ＋・北が dy_m ＋**（地図の読み方）。画面の y（下が＋）と
   *    上下が逆なので、中の offsetLL（南が＋）へは符号を反転して渡す。 */
  /** p から東へ dxM・北へ dyM 動いた緯度経度 */
  function offsetLatLng(p, dxM, dyM) {
    if (!p) return p;
    return offsetLL(p, dxM || 0, -(dyM || 0));
  }
  /** from → to の東・北の実距離(m)（offsetLatLng の逆・同じ緯度で往復が一致する） */
  function offsetMeters(from, to) {
    if (!from || !to) return { dx_m: 0, dy_m: 0 };
    var c = Math.max(1e-6, Math.cos(from.lat * Math.PI / 180));
    return { dx_m: (to.lng - from.lng) * M_PER_DEG * c,
             dy_m: (to.lat - from.lat) * M_PER_DEG };
  }

  /* 🔒 §28-3（2026-09-06 オーナー指示）: **方位記号（北矢印）は「部品」**。
   * 書き出し・プレビューが右上に自動で描いていた物は廃止し、［枠を決定］の時に
   * 1個だけ置く普通のオブジェクト（type:'compass'）にした。ドラッグで動かせて
   * 消しゴムで消せる。§18-ag「向きが確かな図にだけ出す」は**置く条件**として残る
   * （所在図だけ・配置図には置かない＝app.js の sheetNorthUnknown）。
   *
   * 🔴 数値の変更はこの表**1か所**で行う。画面（editor.js）・紙（export.js）・
   *    名前よけ（shozaizu.js）が全部 Editor.compassGeom / compassBox を読む
   *    （Editor.SIGNAL / BUSSTOP と同じ作法）。
   * 🔴 大きさは**紙面ミリで一定**（文字と同じ物差し）。旧 drawNorth は
   *    針の半径 17S ＝ 17 × 138mm/1000 ＝ 2.346mm だったので、そのままの見た目にする
   *    （部品化しても紙に出る大きさは変わらない）。比率も旧 drawNorth と同じ。 */
  var COMPASS = {
    rMm: 2.346,     // 針の半分の高さ(紙面mm)。旧 drawNorth の 17S と同じ
    wide: 0.42,     // 針の半幅 ÷ r
    waist: 0.55,    // 針のくびれ（下側の切れ込み）の深さ ÷ r
    gap: 11 / 17,   // 針の先端から 'N' の中心まで ÷ r（旧 11S）
    label: 13 / 17, // 'N' の字の大きさ ÷ r（旧 13S）
    lw: 2           // 輪郭の太さ（画面px基準。紙は線幅倍率 S を掛ける＝ MARK.strokeW と同じ作法）
  };
  /**
   * 🔒 §30-37 1〜2（2026-09-15 オーナー指示「方位もサイズ変更できるようにして」）:
   * その方位記号の**針の半分の高さ（紙面mm）**。基準 COMPASS.rMm × 倍率 markScale。
   * 🔴 大きさの出どころはこの**1か所**。画面（_drawCompass・当たり判定・選択枠・
   *    つまみの箱）・紙（export.js drawCompass）・名前よけ（shozaizu.js）が全部
   *    これに物差し（mmPx / mPerMm）を掛けて使う＝ COMPASS.rMm を直接読む所は無い。
   * 🔴 上下限は印と同じ clampMarkScale（0.2〜上限なし・既定 1）＝旧案件は 1。
   */
  function compassRadiusMm(o) {
    return COMPASS.rMm * clampMarkScale(o && o.markScale);
  }
  /**
   * 方位記号の形。**at（＝針の中心）を原点**にした相対座標を返す。
   * @param r 針の半分の高さ（画面px または 紙面px）
   */
  function compassGeom(r) {
    return {
      r: r,
      /* 針（上が尖った矢羽根）: 旧 drawNorth と同じ4点 */
      pts: [[0, -r], [r * COMPASS.wide, r], [0, r * COMPASS.waist], [-r * COMPASS.wide, r]],
      labelY: -r - r * COMPASS.gap,          // 'N' の中心（先端の上）
      labelSize: r * COMPASS.label,
      lw: COMPASS.lw
    };
  }
  /**
   * 方位記号の外接箱（当たり判定・名前よけが読む）。
   * at からの相対で {hw:半幅, hh:半高, cy:箱の中心のずれ} を返す。
   */
  function compassBox(r) {
    var g = compassGeom(r);
    var top = g.labelY - g.labelSize * 0.5;   // 'N' は中心そろえ（描画も textBaseline middle）
    var bot = r;
    var hw = Math.max(r * COMPASS.wide, g.labelSize * 0.5);
    return { hw: hw, hh: (bot - top) / 2, cy: (top + bot) / 2 };
  }
  /** 方位記号のオブジェクトを1個作る（🔒 §28-3・app.js の［枠を決定］から呼ぶ） */
  function makeCompass(at, id) {
    return { id: id || uid(), type: 'compass',
             at: { lat: at.lat, lng: at.lng },
             style: { color: '#111', w: COMPASS.lw } };
  }

  /* 🔒 §22-am-2 ⑤⑥ ＋ §22-am-6-2: 名前と●をつなぐ引き出し線（.anno-lead）。
   * 🔴 数値の変更はこの表**1か所**で行う。画面（editor.js）が要素へ直に書き、
   *    紙（export.js）・なぞり中の薄出し（reveal.js）が Editor.LEAD / Editor.leadStop を
   *    読む（Editor.SIGNAL / BUSSTOP と同じ作法）。
   * 🔴 太さ 1.1U ＝ 300dpi で 0.209mm。§23-9-b の下限 0.2mm を上回る
   *    （従来の 0.9U ＝ 0.171mm は下限を割っていた・§22-am-4 の実測で判明）。
   * 🔒 §22-am-6-2（2026-09-05 オーナー指摘「線がテキストにくっついていない。
   *    究極くっついてほしい」）: 線は●から**文字の箱の縁**まで引く（隙間 0）。
   *    箱の半分の大きさ ＝ 横は文字の実幅の半分、縦は文字の高さ × hHalf。
   *    どちらにも白フチ（pad）を足す＝線が白フチの外側でぴたりと止まる。 */
  var LEAD = {
    w: 1.1,          // 線の太さ（画面px基準。紙は線幅倍率 S を掛ける）
    dash: [3, 2],    // 破線の刻み（同じく画面px基準）
    hHalf: 0.5,      // 文字の箱の半分の高さ ÷ 文字の高さ（dominant-baseline:middle）
    pad: 0.11        // 白フチの半分 ÷ 文字の高さ（.obj-text の stroke-width 相当）
  };

  /* 🔒 §22-am-6-2: 引き出し線を文字にくっつけるには、**実際に描かれる幅**が要る。
   * em の見積り（emWidth）は**カタカナで 25% ほど広く出る**（実測: 画面の
   * 「タリーズコーヒー」は見積りの 0.71 倍）。その幅で箱の縁を出すと、線が
   * 文字のはるか手前で止まる（実測 22.8px）。
   * 🔴 canvas の measureText は SVG の getComputedTextLength と**完全に一致**する
   *    （実測・同じ font 指定なら 0.0px 差）ので、画面・紙・なぞり中の3か所が
   *    同じ数値になる。配置の当たり判定（shozaizu.js の箱）は従来どおり em の
   *    見積りのまま＝**線の終点だけ**を実寸に合わせる。 */
  var _measCtx;
  function textDrawWidth(text, size) {
    if (_measCtx === undefined) {
      var cv = (typeof document !== 'undefined') ? document.createElement('canvas') : null;
      _measCtx = (cv && cv.getContext) ? cv.getContext('2d') : null;
    }
    if (!_measCtx) return emWidth(text) * size;
    _measCtx.font = '700 ' + size + 'px "Yu Gothic UI","Meiryo",sans-serif';
    var w = _measCtx.measureText(text || '').width;
    return w > 0 ? w : emWidth(text) * size;
  }

  /**
   * 🔒 §22-av: 路線番号の印。国道＝逆三角形（おにぎり）／都道府県道＝六角形（ヘキサ）。
   * 画面（editor.js）・紙（export.js）で同じ形になるよう、寸法はここ1か所で決める。
   *
   * 返す座標は**数字の中心を原点**にした相対値（px）。数字は原点にそのまま描く。
   * 🔴 下向き三角形は上が広いので、原点（数字）は箱の上寄り＝図形は下に長い。
   *
   * @param text 数字（"19" 等）
   * @param size 数字の高さ(px)
   * @param kind 'national'（▽）/ 'pref'（六角形）
   * @return {hw, hh, pts:[[x,y]…]} hw=半幅（引き出し線・重なり判定が読む）
   */
  function badgeGeom(text, size, kind) {
    var tw = textDrawWidth(text, size);
    if (kind === 'pref') {
      var k = size * 0.42;                        // 左右の尖りの深さ
      var hw = Math.max(tw / 2 + size * 0.30 + k, size * 0.95);
      var hh = size * 0.80;
      return { hw: hw, hh: hh,
               pts: [[-hw, 0], [-hw + k, -hh], [hw - k, -hh],
                     [hw, 0], [hw - k, hh], [-hw + k, hh]] };
    }
    var hwT = Math.max(tw * 0.72 + size * 0.46, size * 1.05);
    var top = -size * 0.78, bot = size * 1.16;
    return { hw: hwT, hh: (bot - top) / 2,
             pts: [[-hwT, top], [hwT, top], [0, bot]] };
  }

  /** 印つきなら印の半幅。ふつうの文字は実寸の半幅（🔒 §22-av / §22-am-6-2） */
  function drawHalfWidth(o, size) {
    if (o && o.badge) return badgeGeom(o.text, size, o.badge).hw;
    return textDrawWidth(o ? o.text : '', size) / 2;
  }

  /** 印の輪郭の SVG パス（cx,cy ＝数字の中心） */
  function badgePath(g, cx, cy) {
    var d = '';
    for (var i = 0; i < g.pts.length; i++) {
      d += (i ? 'L' : 'M') + (cx + g.pts[i][0]).toFixed(1)
         + ' ' + (cy + g.pts[i][1]).toFixed(1) + ' ';
    }
    return d + 'Z';
  }

  /**
   * 🔒 §22-am-6-2: ●へ向かう向きで、文字の中心から**箱の縁**までの長さ。
   * 画面（editor.js）・紙（export.js）・なぞり中（reveal.js）の3か所が同じ物を使う。
   * @param dx,dy 文字の中心 − ●（どちら向きでも同じ値になる）
   * @param d     その長さ
   * @param wHalf 文字の半幅（textDrawWidth ＝実際に描かれる幅の半分）
   * @param size  文字の高さ
   */
  function leadStop(dx, dy, d, wHalf, size) {
    if (!(d > 0)) return 0;
    var hw = wHalf + size * LEAD.pad, hh = size * (LEAD.hHalf + LEAD.pad);
    var m = Math.max(Math.abs(dx) / d / Math.max(hw, 1e-6),
                     Math.abs(dy) / d / Math.max(hh, 1e-6));
    return m > 0 ? Math.min(1 / m, d) : 0;
  }

  /**
   * 🔒 §22-am-6-2: この名前に引き出し線を描くか。
   * 🔴 `o.lead` は shozaizu.js が**紙の物差し**で決めた印（true＝描く／false＝描かない）。
   *    印を持たない古いデータだけ、従来の距離しきい値（画面px基準）に落ちる。
   *    印で決めるのは、閲覧ズームで線が出たり消えたりしないため（§22-y の教訓）。
   * @param d     ●と文字の中心の距離
   * @param near  「近い」とみなす下限（画面は 4px・紙は 4×S）
   */
  function wantLead(o, d, wHalf, size, near) {
    /* 🔒 §30-24-5: 同一住所の間、主役ラベル（noLead:true）はどこへ動かしても
     * 引き出し線を描かない（印と文字はそのまま・線だけ無し）。 */
    if (o && o.noLead) return false;
    if (!(d > 0.5)) return false;
    if (o.lead === true) return true;
    if (o.lead === false) return false;
    return d > size * 2.2 + wHalf || (o.nearMain && d > near);
  }

  /* ================= 所在図の地図スタイル（🔒 §23-9 目標スタイル） =================
   * オーナーが提示したヤフー地図モノクロ（三菱重工業名古屋周辺）の見え方を
   * 地理院データ＋自前描画で再現するための定数。**ここが唯一の出どころ**で、
   * shozaizu.js（生成）・editor.js（画面）・export.js（紙）が全部ここを読む
   * （export.js は global.Editor.MAPSTYLE / global.Editor.roadBand 経由。
   *  Editor.MARK と同じ作法）。
   *
   * 🔴 数値の変更はこの表**1か所**で行う（オーナー目視で確定する予定）。
   *
   * 🔒 道路の描き方は**2種類あってユーザーが選ぶ**（2026-08-31 オーナー決定）。
   *    アプリが一括で決めない、というこのアプリ一貫の方針（§23-11 自動生成と
   *    なぞり出しの併存・§23-5 名称分類・§23-10 建物5段階）と同じ思想:
   *      'line' … 従来の黒線1本（等級別の太さ・**既定**／既存案件はこちら）
   *      'band' … §23-9 の白い帯＋黒の縁取り（ヤフー式・2本描き）
   *    選択は案件データ（c.roadStyle）に保存する（markStyle / bldgLevel と同じ）。
   *
   * 太さの単位は「線の太さの単位 U」＝画面 SVG の px。紙は線幅倍率 S を掛ける。
   * 300dpi では **1U = 0.19003mm**（export.js lineScale ＝
   * PANEL_MM.w/NOMINAL_W × SHEET_SCALE × px/mm ＝ 0.138 × 1.377 × 11.811）。 */
  var MAPSTYLE = {
    road: {
      /* --- 'line'（従来・既定）: 黒線1本。国道>県道>生活道路 の差は §5 の決定事項 ---
       * 🔴 §23-9-b（2026-08-31 オーナー指示で是正）: 旧値の下2段は白黒印刷の下限割れ
       *    だった。実効インクの実測は 市区町村道 0.163mm・等級不明 **0.074mm** で、
       *    公称（0.190/0.152mm）より痩せる。細いほど反かじ処理で色が乗り切らず、
       *    さらに #333/#555 と薄いので端から飛ぶ＝白黒コピーで細街路が消えていた。
       *    → **太さと色の両方**を上げ、最細でも縁取りの下限（casingMinU 0.209mm）を
       *    下回らないようにした。上3段は据え置き（見え方を変えない）。 */
      line: {
        4: { w: 3.4, color: '#111' },   // 高速自動車国道等   0.646mm
        3: { w: 2.4, color: '#111' },   // 国道・主要道路     0.456mm
        2: { w: 1.8, color: '#111' },   // 都道府県道         0.342mm
        1: { w: 1.3, color: '#111' },   // 市区町村道等       0.247mm（旧 1.0/#333）
        0: { w: 1.2, color: '#222' }    // 等級不明           0.228mm（旧 0.8/#555）
      },
      /* --- 'band'（§23-9 ヤフー式）: 外側（黒の縁取り）の太さ U --- */
      band: {
        4: { w: 7.0, color: '#111' },   // 高速自動車国道等   外 1.330mm
        3: { w: 5.6, color: '#111' },   // 国道・主要道路     外 1.064mm
        2: { w: 4.4, color: '#111' },   // 都道府県道         外 0.836mm
        1: { w: 3.6, color: '#111' },   // 市区町村道等       外 0.684mm
        0: { w: 1.2, color: '#111' }    // 等級不明＝細いので帯にならず黒1本 0.228mm
      },
      /* 縁取りの太さ ＝ clamp(外幅 × casingFrac, casingMinU, casingMaxU)。
         🙋 仮値。白黒印刷の下限（縁 0.2mm・帯 0.25mm）から逆算している */
      casingFrac: 0.22,
      casingMinU: 1.10,      // 縁取りの最小 = 0.209mm（白黒コピーで消えない下限）
      /* 🔒 §22-at-3 欠陥1（2026-09-06 Fable 裁定）: 実距離換算で外幅が広い道
       * （ZL17 の22m道路 外10.3mm 等）は、旧式（上限なし）だと縁が 2.3mm にもなり
       * 図が真っ黒に近くなっていた。実距離の帯は「道路の縁の線」なので細いまま
       * にする＝上限を付ける（🙋 仮値・1.6U＝0.30mm）。 */
      casingMaxU: 1.6,       // 縁取りの最大 = 0.304mm
      minBandU: 1.00,        // 帯がこれ未満になるなら帯をやめて黒1本にする（0.190mm）
      bandColor: '#fff'      // 帯（道路の中身）の色
    },
    /* --- 建物 ＝ 実線の輪郭のみ（🔒 §23-3・塗りは入れない） ---
     * 旧値 {w:0.6, color:'#b9bfc9'} は紙で 0.114mm の薄灰＝白黒印刷で消えていた。
     * なぞり出しの実体化（reveal.js OUT_STYLE.bld）と**同じ見た目**にそろえる。 */
    bldg: { w: 1.3, color: '#333' },    // 0.247mm
    /* --- 川（🔒 2026-09-03 オーナー指示「グレーの帯＋黒の縁取り」） ---
     * 🔴 §23-9「線だけで描く・塗りは原則使わない」の**明示的な例外**。
     *    オーナーが色を指定したため、水面だけは塗る（他の地物は従来どおり線のみ）。
     * 地理院の水部は川幅で表現が変わる（§11 実測で確定）:
     *   幅のある川・池・海 … WA（水域面・ポリゴン）＋ WL（水涯線＝岸の線）
     *   細い川            … RvrCL（河川中心線・1本の線）
     * → 面は fill で塗り、岸は WL の黒線。細い川は道路の帯と同じ2本描きで
     *   「グレーの帯＋黒縁」にする（band が外幅・fill が帯の色）。
     * 🙋 仮値（紙面実測で確定）: fill は白黒印刷で道路の白帯（#fff）とも
     *    建物の輪郭（#333）とも区別が付く濃さにしてある。 */
    water: {
      band: 4.6,                       // RvrCL の帯の外幅 U（外 0.874mm）
      color: '#111',                   // 帯の黒縁・岸の線の色
      /* 水面のグレー。🙋 仮値（紙面実測で決めた）。
       * 実測（300dpi）: インク約 **31%**（相対輝度 0.686）。
       * 道路の白帯（0%）・紙の白（0%）と明らかに違い、建物の輪郭（#333＝80%）や
       * 道路の黒線（#111＝93%）とも重ならない濃さ＝白黒印刷で3者が区別できる。 */
      fill: '#a9b0b8',
      edge: { w: 1.3, color: '#111' }  // WL（岸の線）0.247mm＝建物と同じ太さ
    },
    /* --- 等高線（🔒 2026-09-03 オーナー選択「山頂付近だけ間引いて描く」） ---
     * 道路・建物より一段細く・薄くする（主役は道路なので背景に回す）。
     * 🔴 ただし §23-9-b の下限（実効 0.2mm）は割らない。 */
    contour: { w: 1.1, color: '#6b7076' }   // 0.209mm
  };

  /**
   * 道路の「白帯＋黒縁」の寸法（🔒 §23-9・§22-at）。
   * 技法は鉄道ハッチ（§5）と同じ**2本描き**＝太い黒を敷いて細い白を重ねる。
   * casing が立っていない道路（＝従来の黒線1本）は null を返す。
   *
   * 🔴 ここが寸法の**唯一の実装**。画面（editor.js）と紙（export.js）が同じ形に
   *    なるよう、export.js は global.Editor.roadBand を呼ぶ。
   * 戻り値 inner が 0 の時は「細すぎて帯にできない」＝黒1本で描く（自動退避）。
   *
   * 🔒 §22-at-2（改めた規則3・2026-09-06）: `o.floorU`（幅員ランク別の紙の下限・
   *    内部属性）を持つ道路は、外幅＝**max(o.floorU, widthMを今の縮尺でU換算した値)**
   *    にする。🔴 等級の従来値 `R.band[rank].w` は**下限に使わない**（色だけに残す）。
   *    換算は `widthM(m) / ctx.mPerU`（1Uが今のスケールで何mか＝呼び出し側が
   *    画面はメートル/px、紙は mpp×S で用意して渡す）。
   *    `o.floorU` が無い（不明ランク・旧データ・川・なぞり出しの道路）道路は
   *    §22-at 当初の規則のまま＝外幅＝max(等級の従来値U, widthM換算値)。
   */
  function roadBand(o, ctx) {
    var st = (o && o.style) || {};
    if (!st.casing) return null;
    var R = MAPSTYLE.road;
    var wU = (o && o.widthM > 0 && ctx && ctx.mPerU > 0) ? o.widthM / ctx.mPerU : 0;
    var w;
    if (o && o.floorU > 0) {
      w = Math.max(o.floorU, wU);                 // §22-at-2: 等級の従来値は使わない
    } else {
      w = (st.w > 0) ? st.w : R.band[1].w;
      if (wU > w) w = wU;                          // §22-at 規則3: 今より細くはしない
    }
    /* 🔒 §22-at-3 欠陥1: 縁は下限〜上限で clamp（上限が無いと実距離の広い道で
     * 縁だけが太り過ぎる＝図が真っ黒に近くなる）。 */
    var c = Math.min(Math.max(w * R.casingFrac, R.casingMinU), R.casingMaxU);
    var inner = w - c * 2;
    /* 🔒 2026-09-03: 帯の中身の色は**オブジェクトが持てる**（st.bandColor）。
     * 道路は従来どおり白（R.bandColor）で、川だけグレー（MAPSTYLE.water.fill）を
     * 焼いて渡す。🔴 これで2本描きの機構（run の2パス）を丸ごと使い回せる
     *   ＝ 川の合流点も道路の交差点と同じ理屈で黒く潰れない（§23-9-a の教訓）。 */
    return { outer: w, inner: (inner >= R.minBandU ? inner : 0),
             outerColor: st.color || '#111',
             innerColor: st.bandColor || R.bandColor };
  }

  /** 2本描きで描く道路か（塊にまとめて2パスで描く対象）。§23-9 */
  function isCasingRoad(o) {
    return !!(o && (o.type === 'path' || o.type === 'polygon')
              && o.style && o.style.casing && o.points && o.points.length >= 2);
  }

  /**
   * 🔒 §30-25-4（2026-09-13 オーナー実機「④描き足し: 道路は最も下のレイヤーに
   * ＝交差点や名前を選びたいのに道路が動く」）: **「道路」の判定はここ1か所**。
   *   ① 白帯＋黒縁（isCasingRoad。§23-9 の川の帯も同じ描き方なので含む）
   *   ② ［道路を描く］で自動で引いた線（source:'roadauto'）
   *   ③ 所在図の生成が置いた道路線（roadRank を持つ物）
   *   ④ 配置図で手で引いた道路（source:'road'）
   * 🔴 表示文字では分岐しない（§26-2 注意②）。紙（export.js drawObjects）も
   *    `Editor.isRoad` を読む＝画面と紙で並びが必ず同じになる。
   */
  function isRoad(o) {
    if (!o) return false;
    if (isCasingRoad(o)) return true;
    if (o.source === 'roadauto' || o.source === 'road') return true;
    return o.roadRank !== undefined && o.roadRank !== null;
  }

  /**
   * 🔒 §30-25-4: 「道路 → その他」の順に並べ替えた**写し**を返す（文字の後回しは
   * 呼ぶ側の §22-at-3 のまま）。
   * 🔴 元の配列（this.objects / シートの objects）には絶対に触らない（注意①）。
   * 🔴 同じ組の中の前後関係は元のまま＝道路どうしの塊（連続する casing）も
   *    §23-9 の2パス描きにそのまま乗る。
   */
  function sortRoadsFirst(objs) {
    var roads = [], rest = [];
    for (var i = 0; i < objs.length; i++) {
      (isRoad(objs[i]) ? roads : rest).push(objs[i]);
    }
    return roads.concat(rest);
  }

  /* 画面px と紙面mm の換算。文字と同じ物差しを使う
     （TEXT_PX.large 19px ＝ export.js SHEET_TEXT_MM.large 4.4mm）。
     🔒 §30-25-7: これは**枠が無い時の予備**になった。ふだんは
     `Editor.prototype.mmPx()`（枠の画面幅から出す）を使う。 */
  var SHEET_MM_PX = TEXT_PX.large / 4.4;         // ≒ 4.32 px/mm

  var HATCH_ID = 'mkHatch-';                     // SVG パターンの id 接頭辞

  /** マークの色（key → 16進）。未知・旧データは style.color に落とす */
  function markHex(o) {
    for (var i = 0; i < MARK.colors.length; i++) {
      if (MARK.colors[i].key === o.markColor) return MARK.colors[i].hex;
    }
    return (o.style && o.style.color) || MARK.colors[0].hex;
  }

  function el(name, attrs) {
    var n = document.createElementNS(SVGNS, name);
    for (var k in attrs) n.setAttribute(k, attrs[k]);
    return n;
  }
  function uid() {
    return 'o' + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  }
  function clone(o) { return JSON.parse(JSON.stringify(o)); }
  function rad(d) { return d * Math.PI / 180; }
  function fmtM(m) { return (Math.round(m * 10) / 10).toFixed(1) + 'm'; }

  /* 🔒 §22-ae（2026-08-28 オーナー実機報告）: ショートカットを譲る相手は
   * **文字を打っている欄だけ**にする。
   * 🔴 経緯: 以前は「INPUT なら一律で無視」だったので、上部バーの
   *    ［下敷きの濃さ］［画像の濃さ］スライダーを触ると focus がそこへ移り、
   *    多角形の Enter 確定・Backspace 戻し・Escape 取り消しが**全部効かなくなった**。
   *    スライダー・チェックボックス・ラジオは Enter や Backspace で何もしないので、
   *    ショートカットを止める理由がない。
   * 🔴 SELECT は残す（開いた候補一覧を Enter で選ぶ操作を奪ってしまうため）。 */
  var TYPING_INPUT = {
    text: 1, number: 1, search: 1, tel: 1, url: 1, email: 1, password: 1,
    date: 1, time: 1, month: 1, week: 1, 'datetime-local': 1
  };
  function isTypingTarget(t) {
    if (!t) return false;
    if (t.isContentEditable) return true;
    var tag = t.tagName;
    if (tag === 'TEXTAREA' || tag === 'SELECT') return true;
    if (tag !== 'INPUT') return false;
    return !!TYPING_INPUT[(t.type || 'text').toLowerCase()];
  }

  /* 🔒 §25-7/§25-8（2026-08-30）: **矢印キーだけは譲る相手が広い**。
   * 🔴 §22-ae の但し書き「方向キーはこのエディタでは使っていないので range に
   *    focus が残っていても矢印でのつまみ操作は効く」は、矢印を使い始めた今
   *    そのままでは嘘になる。スライダー（range）・チェック・ラジオは
   *    **矢印キーそのものが操作手段**なので、ここで明示的に譲る。 */
  var ARROW_KEEP = { range: 1, radio: 1, checkbox: 1 };
  function arrowsBlocked(t) {
    if (!t) return false;
    if (isTypingTarget(t)) return true;
    return t.tagName === 'INPUT' && !!ARROW_KEEP[(t.type || '').toLowerCase()];
  }

  /* 🔒 §23-7-b（2026-08-31 オーナー決定「スペース押下中はパン」）:
   * スペースを奪ってよいかの判定。**スペースが「文字」か「押す操作」になる相手**
   * からは絶対に奪わない。
   *  ・文字入力欄／textarea／SELECT／contenteditable … スペースは文字そのもの
   *    （isTypingTarget と同じ集合＝判定の実装を1つに保つ）
   *  ・checkbox / radio / file / button 型の input・SUMMARY … スペースが操作手段
   * 🔴 逆に <button> からは**敢えて奪う**: 道具ボタンを押した直後は focus が
   *    そのボタンに残っているので、奪わないと「地図を動かすつもりが、同じ道具
   *    ボタンをもう一度押す」になる（道具の押し直しは draft と選択を捨てる）。
   *    ボタンの起動は Enter で従来どおりできる。 */
  var SPACE_KEEP = { checkbox: 1, radio: 1, file: 1, button: 1, submit: 1, reset: 1 };
  function spaceBlocked(t) {
    if (!t) return false;
    if (isTypingTarget(t)) return true;
    if (t.tagName === 'SUMMARY') return true;
    return t.tagName === 'INPUT' && !!SPACE_KEEP[(t.type || 'text').toLowerCase()];
  }
  function isSpaceKey(e) {
    return e.code === 'Space' || e.key === ' ' || e.key === 'Spacebar';
  }
  /** 矢印キーの押した向き（画面座標。y は下が＋） */
  var ARROW_DIR = {
    ArrowLeft: { x: -1, y: 0 }, ArrowRight: { x: 1, y: 0 },
    ArrowUp: { x: 0, y: -1 }, ArrowDown: { x: 0, y: 1 }
  };

  /* 文字の幅を「字の数」ではなく em で見積もる（🔒 §18-j）。
     🔴 実装は export.js（Exporter.textEmWidth）に**1つだけ**置く。
        画面と紙で同じ形にするため、ここは実行時にそれを呼ぶだけ。
        （読み込み順が変わっても落ちないよう最小の代替だけ持つ） */
  function emWidth(s) {
    if (global.Exporter && global.Exporter.textEmWidth) {
      return global.Exporter.textEmWidth(s);
    }
    var w = 0, t = s || '';
    for (var i = 0; i < t.length; i++) {
      var c = t.charCodeAt(i);
      w += (c < 0x100 || (c >= 0xFF61 && c <= 0xFF9F)) ? 0.55 : 1;
    }
    return w;
  }

  /* ---------- 回転つまみのアイコン（🔒 §18-t） ----------
   * ●だけでは「掴んで何ができるか」が分からない（オーナー指摘）。
   * ●の上に**半円状の弧＋両端の矢頭**＝「曲がった↔」を重ねて回転だと一目で分かるようにする。
   * 🔴 画面(SVG)だけの部品。紙（export.js）には出ない。
   *    ヒット判定は従来どおり中心からの距離で見るので、絵を足しても操作は変わらない。 */
  function rotIconPath(cx, cy, R) {
    var a0 = 200 * Math.PI / 180, a1 = 340 * Math.PI / 180;   // 上側を通る弧
    var N = 16, d = '', i, a, x, y;
    for (i = 0; i <= N; i++) {
      a = a0 + (a1 - a0) * i / N;
      x = cx + Math.cos(a) * R;
      y = cy + Math.sin(a) * R;
      d += (i ? 'L' : 'M') + x.toFixed(1) + ' ' + y.toFixed(1);
    }
    // 両端の矢頭。弧の接線の向き（外向き）に開く
    d += arrowHead(cx + Math.cos(a0) * R, cy + Math.sin(a0) * R, a0 - Math.PI / 2, R);
    d += arrowHead(cx + Math.cos(a1) * R, cy + Math.sin(a1) * R, a1 + Math.PI / 2, R);
    return d;
  }
  /* 🔒 §25-8 修正2（オーナー指示 2026-08-30）: 回転ボタンの意匠は
   * **曲線の矢印**（増減の ＋/− と紛らわしいので記号をやめる）。
   * 回転つまみ（§18-t の rotIconPath）と同じ「弧＋矢頭」の作りにして統一感を出す。
   * 違いは**矢頭が片側だけ**＝回る向きが一目で分かること。
   *   dir > 0 … 時計回り（画面で右回り）／ dir < 0 … 反時計回り
   * 弧の範囲は左右対称（時計回り 130°→340°／反時計回り 50°→-160°）にしてあるので、
   * 2つのボタンが鏡像に見える。 */
  function rotArrowPath(cx, cy, R, dir) {
    var SPAN = 210 * Math.PI / 180;
    var a0 = (dir > 0 ? 130 : 50) * Math.PI / 180;
    var a1 = a0 + (dir > 0 ? SPAN : -SPAN);
    var N = 20, d = '', i, a, x, y;
    for (i = 0; i <= N; i++) {
      a = a0 + (a1 - a0) * i / N;
      x = cx + Math.cos(a) * R;
      y = cy + Math.sin(a) * R;
      d += (i ? 'L' : 'M') + x.toFixed(1) + ' ' + y.toFixed(1);
    }
    // 進んでいく先（終端の接線の向き）に矢頭を1つだけ付ける
    d += arrowHead(cx + Math.cos(a1) * R, cy + Math.sin(a1) * R,
                   a1 + (dir > 0 ? 1 : -1) * Math.PI / 2, R);
    return d;
  }
  function arrowHead(x, y, dir, R) {
    var L = Math.max(3.5, R * 0.42), s = '';
    [-0.6, 0.6].forEach(function (o) {
      var e = dir + Math.PI + o;
      s += 'M' + x.toFixed(1) + ' ' + y.toFixed(1)
         + 'L' + (x + Math.cos(e) * L).toFixed(1)
         + ' ' + (y + Math.sin(e) * L).toFixed(1);
    });
    return s;
  }

  /* 🔒 §25-7 の矢羽（＜ ＞ ∧ ∨）。u の向きに開いた「く」の字を1本の線で描く。
   * 先端が u 側、両足が後ろ。回転済みの向きベクトルをそのまま渡すので、
   * 塊を回しても矢羽は塊の伸びる向きを指し続ける。 */
  function chevronPath(p, u, len, half) {
    var nx = -u.y, ny = u.x;                       // u と直角
    var tipX = p.x + u.x * len, tipY = p.y + u.y * len;
    var bx = p.x - u.x * len, by = p.y - u.y * len;
    return 'M' + (bx + nx * half).toFixed(1) + ' ' + (by + ny * half).toFixed(1)
         + 'L' + tipX.toFixed(1) + ' ' + tipY.toFixed(1)
         + 'L' + (bx - nx * half).toFixed(1) + ' ' + (by - ny * half).toFixed(1);
  }
  /** ＋（sign>0）と −（sign<0）の記号。ボタンの丸の中に置く。
   *  🔒 §30-14-5 1: 丸を小さくした（NAV_R 9→6）ので、記号も丸に比例させる（r を引数に）。 */
  function plusMinusPath(p, sign, r) {
    if (!(r > 0)) r = 4.5;
    var d = 'M' + (p.x - r).toFixed(1) + ' ' + p.y.toFixed(1) + 'h' + (r * 2);
    if (sign > 0) d += 'M' + p.x.toFixed(1) + ' ' + (p.y - r).toFixed(1) + 'v' + (r * 2);
    return d;
  }

  /** 箱の中心から t の方向へ出た所（矢印の始点）。少しだけ外へ逃がす */
  function boxEdgePoint(g, t, gap) {
    var cx = g.x + g.w / 2, cy = g.y + g.h / 2;
    var dx = t.x - cx, dy = t.y - cy;
    var len = Math.hypot(dx, dy);
    if (!len) return { x: cx, y: cy };
    var s = Math.min(dx ? (g.w / 2) / Math.abs(dx) : Infinity,
                     dy ? (g.h / 2) / Math.abs(dy) : Infinity);
    var e = (gap || 0) / len;
    return { x: cx + dx * (s + e), y: cy + dy * (s + e) };
  }

  function distToSegment(px, py, a, b) {
    var vx = b.x - a.x, vy = b.y - a.y;
    var len2 = vx * vx + vy * vy;
    var t = len2 ? ((px - a.x) * vx + (py - a.y) * vy) / len2 : 0;
    t = Math.max(0, Math.min(1, t));
    var dx = px - (a.x + t * vx), dy = py - (a.y + t * vy);
    return Math.sqrt(dx * dx + dy * dy);
  }

  /* ================= Editor ================= */

  function Editor(map) {
    this.map = map;
    this.objects = [];
    this.selection = [];
    this.tool = 'select';
    this.clipboard = null;
    this.undoStack = [];
    this.redoStack = [];
    this.draft = null;
    this.numberStart = 1;
    /* 🔒 2026-08-19（正典 §16-10-d-4）: 寸法の自動記入は廃止した。
     * 新しい図形は showDims:false で作る（表示は手入力か個別スイッチのみ）。 */
    this.arrowWidth = '';        // ツールバーの幅欄（空なら地図から計算した距離を出す・§25-5）
    /* 🔒 §30-29-4 2: 幅の決め方が「幅を入力」か（app.js の state.arrowMode の控え。
     * 出どころは app.js 側1か所・setArrowMode がここへ写す）。真の時に引いた矢印は
     * `noAuto:true` を持つ＝欄が空なら**何も出さない**（自動の値に落ちない）。 */
    this.arrowManual = false;
    this.textSize = 'medium';
    this.textPreset = '';
    /* 🔒 §30-22-1 4: ［多角形で描く］がどちらの地点の印を作るか。
     * app.js が道具を持ち替える時に入れる（既定は使用の本拠）。 */
    this.mainPolyKey = 'home';
    this._numFrom = null;        // 番号割付の開始枠
    this.polygonMustClose = false;   // ウィザードの外周ステップでは必ず閉じる
    this._listeners = { change: [], select: [], tool: [], number: [], text: [],
                        parcel: [], ctrl: [], draft: [], stagger: [], hint: [],
                        space: [] };
    this.staggerMode = false;
    this._ctrl = false;
    this._toolCursor = '';

    /* 🔒 §23-7-b: スペース＝一時パン（画像編集ソフトの共通作法・**全道具で共通**）。
     *   _space      … スペースを押している最中か（キーの状態そのもの）
     *   _spaceDrag  … その状態で左ボタンを押した＝いま地図を掴んでいる（掌カーソル）
     *   _spaceClick … 直後の click/dblclick を捨てる印（矢印の2クリック目にしない）
     * 🔴 実際に地図を動かすのは mapview（_shouldPan が true を返すだけ）。
     *    ここは「作図を始めない・カーソルを掌にする」係に徹する。 */
    this._space = false;
    this._spaceDrag = false;
    this._spaceClick = false;
    this._cursorBefore = null;   // スペースを押す前のカーソル（離した時に戻す）

    /* 🔒 §25-8「矢印キーの取り合いの決着」: **最後に触った操作系に矢印キーが付く**。
     * ±方向ボタンを触ったら 'grow'、回転ボタン／回転つまみを触ったら 'rotate'。
     * Shift＋矢印は文脈によらず必ず回転（近道なので文脈そのものは変えない）。 */
    this.arrowMode = 'grow';
    /* §25-7「左に伸ばしている状態で ←＝追加・→＝減る／減り切ったら右へ転じる」の
     * 覚え書き。局所軸ごとに「いまどちら側を伸ばしているか」(-1/+1/0)を持つ。
     * 🔴 図形（塊）には持たせない ―― 保存JSONに操作の途中状態を混ぜないため。 */
    this._growSide = { id: null, x: 0, y: 0 };
    /* 🔒 §25-7 修正1: ±/回転ボタンの「その場に固定」（NAV_FREEZE_MS 参照）。
     * { id, nav:{key:{at,plus,minus,u}}, rot:[{delta,at}], until, timer } */
    this._navFreeze = null;

    /* 🔒 §25-4: 主役マークの斜線ハッチ（45°）。SVG の pattern は図に1組あればよいので
     * ここで一度だけ作る（render() は this.layer だけを作り直すので消えない）。 */
    this._buildHatchDefs(map.overlay);

    this.layer = el('g', { class: 'obj-layer' });
    map.overlay.insertBefore(this.layer, map.overlay.firstChild);
    /* 🔒 §23（なぞり出し）の受け口。app.js が Reveal（js/reveal.js）を差し込む。
     * 期待する形: { strokeStart(px,py), strokeMove(px,py), strokeEnd() }。
     * 🔴 曇り下書きは reveal.js が持つ**別の canvas**（SVG の下）に描く。
     *    editor.objects には実体化した物しか入らないので、書き出しにも履歴にも
     *    下書きは混ざらない（§23-2）。 */
    this.reveal = null;

    // 敷地候補（法務省の筆界）を薄く重ねる一時レイヤー。図形ではないので保存しない
    this.candidates = null;
    this.candLayer = el('g', { class: 'cand-layer' });
    map.overlay.insertBefore(this.candLayer, this.layer.nextSibling);

    var self = this;
    /* 🔒 §25-7 修正1: 地図のパン・ズームが起きたら据え置きは**即解除**する
     * （画面が動いたのにボタンだけ取り残されるのを防ぐ）。 */
    map.on('change', function () {
      self.clearOverlayFreeze(true);
      self.render();
    });
    map.shouldPan = function (e) { return self._shouldPan(e); };

    this._bindInput();
    this._bindKeys();
  }

  /**
   * 主役マークの斜線ハッチ（🔒 §25-4）。色ごとに1つの pattern を用意する。
   * 45° は patternTransform で作る（縦線を並べたパターンを 45° 回す）ので、
   * 四角を回転させてもハッチの向きは紙面に対して常に 45° のまま。
   */
  /* 🔒 §30-25-7: 斜線の間隔も**紙のミリ**（MARK.hatchMm）なので、文字と同じ
   * mmPx() で画面pxへ直す＝ズームすると斜線も他の図形と同じ比率で変わる。 */
  Editor.prototype._hatchSpacing = function () {
    return Math.max(1.5, MARK.hatchMm * this.mmPx());
  };
  /** pattern 1つに間隔を書き込む（作る時と、ズームで引き直す時の1か所） */
  function setHatchSp(pat, sp) {
    pat.setAttribute('width', sp.toFixed(2));
    pat.setAttribute('height', sp.toFixed(2));
    var ln = pat.firstChild;
    if (ln) ln.setAttribute('y2', sp.toFixed(2));
  }
  /* 🔒 §30-25-7: パターンは「1度作ったら使い回す」作りなので、ズームで
   * mmPx() が変わったら**作り直さずに間隔だけ書き替える**（全色まとめて）。
   * render のたびに呼ぶ（値が同じ間は何もしない）。 */
  Editor.prototype._syncHatchScale = function () {
    var sp = this._hatchSpacing();
    if (this._hatchSpNow === sp) return;
    this._hatchSpNow = sp;
    var svg = this.map && this.map.overlay;
    if (!svg) return;
    var pats = svg.querySelectorAll('defs.mark-hatch-defs pattern');
    for (var i = 0; i < pats.length; i++) setHatchSp(pats[i], sp);
  };

  Editor.prototype._buildHatchDefs = function (svg) {
    if (!svg || svg.querySelector('#' + HATCH_ID + MARK.colors[0].key)) return;
    var defs = el('defs', { class: 'mark-hatch-defs' });
    var sp = this._hatchSpacing();               // 斜線の間隔(px)
    MARK.colors.forEach(function (c) {
      var pat = el('pattern', { id: HATCH_ID + c.key,
        patternUnits: 'userSpaceOnUse', patternTransform: 'rotate(45)' });
      pat.appendChild(el('line', { x1: 0, y1: 0, x2: 0, y2: sp.toFixed(2),
        stroke: c.hex, 'stroke-width': MARK.hatchW }));
      setHatchSp(pat, sp);
      defs.appendChild(pat);
    });
    svg.appendChild(defs);
  };

  /**
   * 🔒 §30-22-1 4 / §30-22-4 9: **任意の色**の斜線ハッチ（主役の多角形・保管場所）。
   * 間隔・太さ・角度は §25-4 の四角の印とまったく同じ（MARK.hatchMm / hatchW）。
   * 🔴 id は色から作るので、同じ色なら pattern は1つだけ作られる（初回だけ足す）。
   * @return 使う pattern の id（`fill:url(#…)` で参照する）
   */
  Editor.prototype._hatchId = function (hex) {
    var svg = this.map && this.map.overlay;
    var id = 'mkHatchX-' + String(hex || '#111').replace(/[^0-9a-fA-F]/g, '');
    if (!svg || svg.querySelector('#' + id)) return id;
    var defs = svg.querySelector('defs.mark-hatch-defs');
    if (!defs) { defs = el('defs', { class: 'mark-hatch-defs' }); svg.appendChild(defs); }
    var sp = this._hatchSpacing();               // 🔒 §30-25-7: 紙のミリ × mmPx()
    var pat = el('pattern', { id: id,
      patternUnits: 'userSpaceOnUse', patternTransform: 'rotate(45)' });
    pat.appendChild(el('line', { x1: 0, y1: 0, x2: 0, y2: sp.toFixed(2),
      stroke: hex, 'stroke-width': MARK.hatchW }));
    setHatchSp(pat, sp);
    defs.appendChild(pat);
    return id;
  };

  Editor.prototype.on = function (ev, fn) {
    (this._listeners[ev] || (this._listeners[ev] = [])).push(fn);
    return this;
  };
  Editor.prototype._emit = function (ev, arg) {
    (this._listeners[ev] || []).forEach(function (f) { f(arg); });
  };

  /** 階段モードを解除する（選択が変わった時・道具を変えた時） */
  Editor.prototype.clearStaggerMode = function () {
    if (!this.staggerMode) return;
    this.staggerMode = false;
    this._emit('stagger', false);
  };

  Editor.prototype.bind = function (objects) {
    this.objects = objects || [];
    this.selection = [];
    this.undoStack = [];
    this.redoStack = [];
    this.draft = null;
    this._numFrom = null;
    // 🔒 §25-7: 押しっぱなしの取りまとめ（_burstCommit）を別の案件へ持ち越さない
    if (this._burstT) { clearTimeout(this._burstT); this._burstT = null; }
    this._growSide = { id: null, x: 0, y: 0 };
    // 🔒 §25-7 修正1: 案件・シートの切替でボタンの据え置きを持ち越さない
    this.clearOverlayFreeze(true);
    this.render();
    this._emit('select', this.getSelected());
  };

  /* ---------- Ctrl を押している間だけ「選択」に切り替える ----------
   * 作図の途中で図形を掴みたい時、いちいち道具を切り替えなくて済む。
   * Ctrl を離せば元の道具に戻り、描きかけの状態も保たれる。
   * ブラウザ側の Ctrl 操作（リンクを新タブで開く／ホイールで拡大）は
   * 地図上では起きない（リンクが無い・ホイールは preventDefault 済み）。 */
  Editor.prototype.effectiveTool = function () {
    return (this._ctrl && this.tool !== 'select') ? 'select' : this.tool;
  };

  Editor.prototype._setCtrl = function (on) {
    on = !!on;
    if (this._ctrl === on) return;
    this._ctrl = on;
    if (this.tool === 'select') return;
    this._applyCursor();
    this._emit('ctrl', on);
    this.render();
  };

  /* ---------- スペース＝一時パン（🔒 §23-7-b） ---------- */

  /**
   * 地図の上のカーソルを決める**唯一の場所**。
   * 🔴 優先順位: 掴んでいる(grabbing) ＞ スペース中(grab) ＞ Ctrl(既定) ＞ 道具。
   *    インライン style は CSS の `.mv-root{cursor:grab}` / `.mv-dragging{grabbing}`
   *    より強いので、掌に見せる責任はここが全部持つ（CSS 側は触らない）。
   */
  Editor.prototype._applyCursor = function () {
    var el = this.map.el;
    if (this._spaceDrag) { el.style.cursor = 'grabbing'; return; }
    if (this._space) { el.style.cursor = 'grab'; return; }
    /* 🔴 スペースを離した直後だけは「押す前の姿」へ戻す。app.js が地図に直接
     *    置くカーソル（地点を選ぶ十字・階段モードの ns-resize）を、こちらが
     *    知らないまま道具のカーソルで踏み潰さないため。 */
    if (this._cursorBefore !== null) {
      el.style.cursor = this._cursorBefore;
      this._cursorBefore = null;
      return;
    }
    el.style.cursor = this._ctrl ? '' : this._toolCursor;
  };

  /** スペース一時パンの最中か（reveal.js がブラシの輪を隠すのに使う） */
  Editor.prototype.isSpacePan = function () {
    return !!(this._space || this._spaceDrag);
  };

  Editor.prototype._setSpace = function (on) {
    on = !!on;
    if (this._space === on) return;
    if (on) this._cursorBefore = this.map.el.style.cursor;
    this._space = on;
    this._applyCursor();
    this._emit('space', on);
  };

  /**
   * いまスペースを奪ってよいか。
   * 🔴 ①地図が出ていない画面では触らない ②かぶせ物が出ている間は譲る（keysBusy・
   *    「見えているが focus が外れている入力欄」はここでしか判らない・§25-7 と同じ作法）
   *    ③スペースが文字／操作になる相手には触らない（spaceBlocked）。
   */
  Editor.prototype._spaceAllowed = function (t) {
    if (!this.map.el.offsetParent) return false;
    if (this.keysBusy && this.keysBusy()) return false;
    if (spaceBlocked(t) || spaceBlocked(document.activeElement)) return false;
    return true;
  };

  Editor.prototype.setTool = function (t) {
    this.tool = t;
    this.draft = null;
    this._numFrom = null;
    this.clearStaggerMode();
    this.clearOverlayFreeze(true);   // 🔒 §25-7 修正1
    if (t !== 'select') this.selection = [];
    /* 🔒 §30-15-1: 消しゴムは消しゴムの絵（ERASER_CURSOR）。他の作図道具は十字。 */
    this._toolCursor = (t === 'select') ? ''
      : (t === 'eraser' ? ERASER_CURSOR : 'crosshair');
    // 道具が変われば「押す前の姿」は古くなる（スペース中の持ち替え対策）
    this._cursorBefore = null;
    this._applyCursor();
    this.render();
    this._emit('tool', t);
    this._emit('select', this.getSelected());
  };

  Editor.prototype.getSelected = function () {
    var ids = this.selection, out = [];
    for (var i = 0; i < this.objects.length; i++) {
      if (ids.indexOf(this.objects[i].id) >= 0) out.push(this.objects[i]);
    }
    return out;
  };
  Editor.prototype.byId = function (id) {
    for (var i = 0; i < this.objects.length; i++) {
      if (this.objects[i].id === id) return this.objects[i];
    }
    return null;
  };

  /* ---------- 履歴 ---------- */

  Editor.prototype.snapshot = function () {
    this.undoStack.push(clone(this.objects));
    if (this.undoStack.length > HISTORY_MAX) this.undoStack.shift();
    this.redoStack.length = 0;
    // 新しい操作をした印（戻す・進むでは増えない）。
    // 画像の縮尺のような「履歴の外にある変更」を、どの枝の話か見分けるのに使う
    this.historySeq = (this.historySeq || 0) + 1;
  };
  Editor.prototype._restore = function (arr) {
    this.objects.length = 0;
    for (var i = 0; i < arr.length; i++) this.objects.push(arr[i]);
    var alive = {};
    this.objects.forEach(function (o) { alive[o.id] = true; });
    this.selection = this.selection.filter(function (id) { return alive[id]; });
    this.render();
    this._emit('change');
    this._emit('select', this.getSelected());
  };
  Editor.prototype.undo = function () {
    // 作図の途中なら、まず「打った点」を1つ戻す
    if (this.canUndoPoint()) { this.undoPoint(); this._emit('change'); return; }
    if (!this.undoStack.length) return;
    this.redoStack.push(clone(this.objects));
    this._restore(this.undoStack.pop());
  };
  Editor.prototype.redo = function () {
    if (!this.redoStack.length) return;
    this.undoStack.push(clone(this.objects));
    this._restore(this.redoStack.pop());
  };
  Editor.prototype.canUndo = function () {
    return this.undoStack.length > 0 || this.canUndoPoint();
  };
  Editor.prototype.canRedo = function () { return this.redoStack.length > 0; };

  /* ---------- 作図中の「1クリック戻す」 ----------
   * 多角形や折れ線を描いている最中は、履歴を巻き戻すのではなく
   * 直前に打った点だけを取り消す方が自然（オーナー指示 2026-08-16）。 */
  Editor.prototype.canUndoPoint = function () {
    var d = this.draft;
    if (!d) return false;
    if (d.type === 'polygon') return d.points.length > 0;
    if (d.type === 'line' || d.type === 'arrow') return true;
    if (d.type === 'curve') return true;
    return false;
  };

  /** 直前のクリックを1つ取り消す。取り消せたら true */
  Editor.prototype.undoPoint = function () {
    var d = this.draft;
    if (!d) return false;
    if (d.type === 'polygon') {
      d.points.pop();
      if (!d.points.length) this.draft = null;
      this.render();
      return true;
    }
    if (d.type === 'curve' && d.stage === 2) {
      d.stage = 1;                 // 膨らみ決め → 2点目の指定へ戻る
      this.render();
      return true;
    }
    // 直線・幅矢印・曲線の1点目は、その1点を捨てる＝作図の取りやめ
    this.draft = null;
    this.render();
    return true;
  };

  /* ---------- 編集操作 ---------- */

  Editor.prototype.deleteSelected = function () {
    if (!this.selection.length) return;
    this.snapshot();
    var ids = this.selection;
    for (var i = this.objects.length - 1; i >= 0; i--) {
      if (ids.indexOf(this.objects[i].id) >= 0) this.objects.splice(i, 1);
    }
    this.selection = [];
    this.commit();
    this._emit('select', []);
  };
  Editor.prototype.copySelected = function () {
    var sel = this.getSelected();
    if (sel.length) this.clipboard = clone(sel);
  };
  /**
   * 主役マーク（🔒 §25-4）は「使用の本拠 1個・駐車場 1個」で1組。
   * 複製すると同じ markRole の四角が2個になり、ピンを動かすと**両方が同じ座標へ
   * 追従して重なる**（オーナー実機報告 2026-08-30）。増やす経路を全部ここで塞ぐ。
   */
  function isMainMark(o) { return !!o && o.role === 'mainmark'; }

  /**
   * 🔒 §30-32-1（2026-09-15 オーナー指示「所在図でも配置図でも、マーカーも
   * 消しゴムで普通に消せるように」）: 消しゴムで触れた物が**その地点そのもの**か。
   * 主役の印（■＝role:'mainmark' の rect）と主役の文字（role:'pinlabel'）が該当する。
   * 🔴 どちらの地点（home/lot）かの判定は app.js（pinKeyOf の旧案件の保険つき）
   *    1か所に任せる＝ここは「地点の部品か」だけを見る。
   * 🔒 §30-32-7 3（補正）: 主役の**多角形**（type:'polygon'）は対象から外す。
   * 多角形は従来どおり1個ずつ消しゴムで消せる（全部消えたら syncMarkShapeFromPolys
   * が◎に戻す・§30-24-1）。この type!=='polygon' が唯一の除外判定＝onErasePoint
   * （app.js）側では多角形を除外する判定を重複させない（多角形はここで弾かれて
   * onErasePoint 自体が呼ばれないので、渡って来ない）。
   */
  function isPointPart(o) {
    return (isMainMark(o) && o.type !== 'polygon')
      || !!(o && o.type === 'text' && o.role === 'pinlabel');
  }

  /**
   * 🔒 §30-24-1: その地点の主役の多角形を**描いた順**に並べて返す。
   * 🔴 ピンの位置は「最初に描いた多角形」の重心なので、順番の出どころは1か所にする。
   *    `mainPolyOrder`（描いた順の通し番号）→ 無い旧データは配列の並び（安定ソート）。
   * @param {Array} list その紙の図形
   * @param {'home'|'lot'} key
   */
  function mainPolysOf(list, key) {
    var k = (key === 'lot') ? 'lot' : 'home', out = [];
    for (var i = 0; i < (list || []).length; i++) {
      var o = list[i];
      if (isMainMark(o) && o.type === 'polygon' && (o.markRole || 'home') === k) out.push(o);
    }
    return out.sort(function (a, b) {
      return (a.mainPolyOrder || 0) - (b.mainPolyOrder || 0);
    });
  }

  Editor.prototype.paste = function (src) {
    var items = (src || this.clipboard || []).filter(function (o) {
      // 🔒 §25-4: 主役マークは複製させない／§28-3: 方位記号も1枚に1つ
      return !isMainMark(o) && !(o && o.type === 'compass');
    });
    if (!items.length) return;
    this.snapshot();
    var mpp = this.map.metersPerPixel();
    var dLat = -(14 * mpp) / 111320;
    var dLng = (14 * mpp) / (111320 * Math.cos(rad(this.map.getCenter().lat)));
    var ids = [], self = this;
    clone(items).forEach(function (o) {
      o.id = uid();
      shiftObject(o, dLat, dLng);
      self.objects.push(o);
      ids.push(o.id);
    });
    this.selection = ids;
    this.commit();
    this._emit('select', this.getSelected());
  };
  Editor.prototype.duplicateSelected = function () {
    var sel = this.getSelected();
    if (sel.length) this.paste(clone(sel));
  };
  Editor.prototype.commit = function () {
    this.render();
    this._emit('change');
  };

  function shiftObject(o, dLat, dLng) {
    function sh(p) { p.lat += dLat; p.lng += dLng; }
    if (o.center) sh(o.center);
    if (o.origin) sh(o.origin);
    if (o.at) sh(o.at);
    // 複製は●も一緒に運ぶ（ドラッグ移動＝_moveSelection は at だけ・§18-8）
    if (o.anchor) sh(o.anchor);
    // 塊ラベルの矢印の先も複製では一緒に運ぶ（§18-f 駐車位置ラベル。移動では動かさない）
    if (o.arrowTo) sh(o.arrowTo);
    // 距離ラベルの追従基準（§18-x-5）。複製はずれを保ったまま増える
    if (o.mid) sh(o.mid);
    if (o.a) sh(o.a);
    if (o.b) sh(o.b);
    if (o.c) sh(o.c);
    if (o.points) o.points.forEach(sh);
  }

  /* ================= 幾何 ================= */

  Editor.prototype.rectCorners = function (r) {
    var c = this.map.project(r.center.lat, r.center.lng);
    var h = this.rectHalf(r);
    var ca = Math.cos(rad(r.angle || 0)), sa = Math.sin(rad(r.angle || 0));
    return [[-h.hw, -h.hh], [h.hw, -h.hh], [h.hw, h.hh], [-h.hw, h.hh]].map(function (p) {
      return { x: c.x + p[0] * ca - p[1] * sa, y: c.y + p[0] * sa + p[1] * ca };
    });
  };
  /** 局所座標(lx,ly) → 画面座標。四角も塊も中心（center / origin）まわりで同じ */
  Editor.prototype.toScreen = function (o, lx, ly) {
    var anchor = o.center || o.origin;
    var c = this.map.project(anchor.lat, anchor.lng);
    var a = rad(o.angle || 0), ca = Math.cos(a), sa = Math.sin(a);
    return { x: c.x + lx * ca - ly * sa, y: c.y + lx * sa + ly * ca };
  };
  Editor.prototype.toLocal = function (r, px, py) {
    var anchor = r.center || r.origin;
    var c = this.map.project(anchor.lat, anchor.lng);
    var dx = px - c.x, dy = py - c.y;
    var a = -rad(r.angle || 0);
    return { x: dx * Math.cos(a) - dy * Math.sin(a),
             y: dx * Math.sin(a) + dy * Math.cos(a) };
  };
  Editor.prototype.rectHalf = function (r) {
    var mpp = this.map.metersPerPixel(r.center.lat);
    var hw = (r.w_m / mpp) / 2, hh = (r.h_m / mpp) / 2;
    /* 🔒 §25-4: 主役マークだけは**紙面での最小サイズ**を保証する。
     * 広域の所在図では建物サイズ(10m)の四角が紙で 1mm を切って見えなくなる。
     * 🔴 当たり判定（_hitOne / hitHandle / outlinePoints）も同じ rectHalf を通るので、
     *    見えている大きさ＝掴める大きさ になる。 */
    if (r.role === 'mainmark') {
      /* 🔒 §30-25-7: 紙のミリ → 画面px は mmPx()（ズーム連動）
       * 🔒 §30-25-37 1: 紙の最小 mm にも印の大きさ（markScale）を掛ける
       *    （［大］にしたのに広域で下限に張り付いて大きくならない、を防ぐ）。
       * 🔒 §30-31-1 3: 下限は**縦横それぞれ**（出どころは markMinMm 1か所）。 */
      var mm = markMinMm(r), half = this.mmPx() / 2;
      var minW = mm.w * half, minH = mm.h * half;
      if (hw < minW) hw = minW;
      if (hh < minH) hh = minH;
    }
    return { hw: hw, hh: hh, mpp: mpp };
  };

  /* ---------- 塊スタンプ（正典 §4-4 / §6） ----------
   * 子rect を実体で持たず、origin(中心)・count・cellサイズ・向きから毎回導出する。
   * 全体伸縮は cell サイズの再計算だけで済み、歯抜け(skip)も添字で表せる。 */
  /**
   * 塊の形。stagger_m は「1枠ずつ横へずらす量(m)」＝階段状の配置。
   * 変な形の駐車場で車列が斜めに並ぶ場合に使う（オーナー指示 2026-08-16）。
   */
  Editor.prototype.stampGeom = function (g) {
    var mpp = this.map.metersPerPixel(g.origin.lat);
    var cw = g.cell_w_m / mpp, ch = g.cell_h_m / mpp;   // 1枠の画面サイズ
    var col = (g.direction !== 'row');
    var st = (g.stagger_m || 0) / mpp;                  // ずらし量(px/枠)
    var span = Math.abs(st) * (g.count - 1);            // ずれで広がる分
    var cellsW = col ? cw : cw * g.count;
    var cellsH = col ? ch * g.count : ch;
    var totalW = cellsW + (col ? span : 0);
    var totalH = cellsH + (col ? 0 : span);
    return { mpp: mpp, cw: cw, ch: ch, col: col, st: st, span: span,
             cellsW: cellsW, cellsH: cellsH,
             hw: totalW / 2, hh: totalH / 2 };
  };
  /** i 番目の枠のローカル中心。並ぶ向きと直角にずらすと階段になる */
  Editor.prototype.stampCellLocal = function (g, i, geo) {
    var off = (i - (g.count - 1) / 2);
    return geo.col
      ? { x: off * geo.st, y: off * geo.ch }
      : { x: off * geo.cw, y: off * geo.st };
  };
  Editor.prototype.stampCellCorners = function (g, i, geo) {
    geo = geo || this.stampGeom(g);
    var c = this.map.project(g.origin.lat, g.origin.lng);
    var ca = Math.cos(rad(g.angle || 0)), sa = Math.sin(rad(g.angle || 0));
    var lc = this.stampCellLocal(g, i, geo);
    var hw = geo.cw / 2, hh = geo.ch / 2;
    return [[-hw, -hh], [hw, -hh], [hw, hh], [-hw, hh]].map(function (p) {
      var lx = lc.x + p[0], ly = lc.y + p[1];
      return { x: c.x + lx * ca - ly * sa, y: c.y + lx * sa + ly * ca };
    });
  };
  Editor.prototype.stampCells = function (g) {
    var out = [], skip = g.skip || [];
    for (var i = 0; i < g.count; i++) {
      if (skip.indexOf(i) < 0) out.push(i);
    }
    return out;
  };
  /** 画面座標がどの枠に当たるか {group, index} */
  Editor.prototype.hitStampCell = function (px, py) {
    for (var k = this.objects.length - 1; k >= 0; k--) {
      var g = this.objects[k];
      if (g.type !== 'stampGroup') continue;
      var geo = this.stampGeom(g);
      var loc = this.toLocal(g, px, py);
      if (Math.abs(loc.x) > geo.hw + 2 || Math.abs(loc.y) > geo.hh + 2) continue;
      var live = this.stampCells(g);
      for (var n = 0; n < live.length; n++) {
        var lc = this.stampCellLocal(g, live[n], geo);
        if (Math.abs(loc.x - lc.x) <= geo.cw / 2 + 1 &&
            Math.abs(loc.y - lc.y) <= geo.ch / 2 + 1) {
          return { group: g, index: live[n] };
        }
      }
    }
    return null;
  };

  /* ========== ±方向ボタン（🔒 §25-7）＝ 塊を押した向きに1枠ずつ伸ばす ==========
   *
   * 🔴 設計の肝: 塊は子rectを実体で持たない（§4-4）。枠 i の位置は
   *    off = i - (count-1)/2 の倍数で決まるので、**count を1増やすと既存の枠が
   *    半枠ぶんずれる**。ずれた分だけ origin を逆に動かして
   *    「押した側だけが伸びた」ように見せる ―― これが増減の全てである。
   *
   *    足す側    Δoff        origin を動かす量（局所）
   *    高い添字側  -1/2       +1/2 × 軸ベクトル
   *    低い添字側  +1/2       -1/2 × 軸ベクトル      （添字も1つずつ繰り上がる）
   *
   *    軸ベクトルは stampCellLocal と同じ組み合わせ＝
   *    横並び(row): (cw, stagger) ／ 縦並び(col): (stagger, ch)。
   *    stagger（階段配置）も off の倍数なので、必ず一緒にずらす。
   */

  /** 添字で持っている物（歯抜け・番号・保管場所）をまとめて d だけずらす */
  function shiftStampIndex(g, d) {
    if (g.skip) {
      g.skip = g.skip.map(function (i) { return i + d; })
                     .filter(function (i) { return i >= 0; });
    }
    /* 🔒 §30-22-3 2: 来客用（guest）・車いす（wheel）も**枠の添字にぶら下がる**
     * （numbers / storage と同じ作法）ので、伸縮で添字がずれる時は一緒に運ぶ。 */
    ['numbers', 'storage', 'guest', 'wheel'].forEach(function (k) {
      var m = g[k];
      if (!m) return;
      var out = {};
      Object.keys(m).forEach(function (i) {
        var j = (+i) + d;
        if (j >= 0) out[j] = m[i];
      });
      g[k] = out;
    });
  }
  /** 添字 i にぶら下がっている物を捨てる（その枠を消す時） */
  function dropStampIndex(g, i) {
    if (g.skip) {
      var k = g.skip.indexOf(i);
      if (k >= 0) g.skip.splice(k, 1);
    }
    if (g.numbers) delete g.numbers[i];
    if (g.storage) delete g.storage[i];
    // 🔒 §30-22-3 2: 来客用・車いすも枠と一緒に消える
    if (g.guest) delete g.guest[i];
    if (g.wheel) delete g.wheel[i];
  }

  /** その軸に伸ばせるか。1枠の時はまだ向きが決まっていないのでどちらでも伸ばせる */
  Editor.prototype.canGrowStamp = function (g, axis) {
    if (!g || g.type !== 'stampGroup') return false;
    if (g.count <= 1) return true;
    return axis === (g.direction === 'row' ? 'x' : 'y');
  };

  /**
   * 塊を局所軸 axis（'x'=横 / 'y'=縦）の dir 側（-1/+1）へ1枠ぶん伸ばす／縮める。
   * @param {boolean} remove true で「その側から1枠減らす」
   * @return {boolean} 実際に増減できたら true
   */
  Editor.prototype.growStamp = function (g, axis, dir, remove) {
    if (!this.canGrowStamp(g, axis)) return false;
    if (remove && g.count <= 1) return false;
    // 1枠だけの塊は、押した向きでそのまま並びの向きが決まる（見た目は変わらない）
    if (g.count <= 1 && !remove) g.direction = (axis === 'x') ? 'row' : 'col';

    var geo = this.stampGeom(g);          // cw/ch/stagger は count に依らない
    var high = (dir > 0);                 // 添字が増える側か
    var n = 0;

    if (remove) {
      /* 端の枠が「消しゴムで消した歯抜け」だと、減らしても見た目が変わらない。
       * 生きている枠を1つ減らすまで詰める（歯抜けだけが残る状態を作らない）。 */
      var guard = g.count;
      while (g.count > 1 && guard-- > 0) {
        var idx = high ? (g.count - 1) : 0;
        var wasSkipped = (g.skip || []).indexOf(idx) >= 0;
        dropStampIndex(g, idx);
        g.count -= 1;
        if (!high) shiftStampIndex(g, -1);
        n += 1;
        if (!wasSkipped) break;
      }
      if (!n) return false;
    } else {
      g.count += 1;
      if (!high) shiftStampIndex(g, 1);
      n = 1;
    }

    // 既存の枠が動かないように origin をずらす（上の表のとおり）
    var dOff = (remove ? 1 : -1) * (high ? 1 : -1) * 0.5 * n;
    var av = geo.col ? { x: geo.st, y: geo.ch } : { x: geo.cw, y: geo.st };
    var lx = -dOff * av.x, ly = -dOff * av.y;
    var a = rad(g.angle || 0), ca = Math.cos(a), sa = Math.sin(a);
    var c = this.map.project(g.origin.lat, g.origin.lng);
    var np = this.map.unproject(c.x + lx * ca - ly * sa, c.y + lx * sa + ly * ca);
    g.origin.lat = np.lat;
    g.origin.lng = np.lng;
    if (g.skip) {
      g.skip = g.skip.filter(function (i) { return i >= 0 && i < g.count; });
    }
    return true;
  };

  /**
   * 選択中の塊の周りに出す ±オーバーレイの位置（🔒 §25-7 の参考絵）。
   * 四方に矢羽（大きな的＝そのまま＋として押せる）、その両脇に小さな＋と−。
   * ＋は「上／右」側、−は「下／左」側に置く（増える方向と揃える）。
   * 🔒 §25-7 修正1: 据え置き中（_navFreeze）は**画面座標だけ**凍った値を返す。
   *    active / canRemove は常に最新で計算する（並びの軸は増減で変わるため）。
   */
  Editor.prototype.stampNav = function (g) {
    if (!g || g.type !== 'stampGroup' || !g.origin) return null;
    var geo = this.stampGeom(g);
    // 🔒 §30-19-3 1: 上の縁は stampTopEdge（回転の3つと同じ1か所を見る）
    var hw = Math.max(geo.hw, NAV_MINH), hh = stampTopEdge(geo);
    var layoutAxis = geo.col ? 'y' : 'x';
    var self = this;
    var fz = this._frozenOverlay(g);
    var frozen = (fz && fz.nav) || null;
    /* lx/ly＝矢羽の中心（局所）／ pxy＝＋を置く向き（矢羽と直角の単位ベクトル） */
    return [
      { key: 'left',  axis: 'x', dir: -1, lx: -(hw + NAV_GAP),    ly: 0, ux: -1, uy: 0, px: 0, py: -1 },
      { key: 'right', axis: 'x', dir:  1, lx:  (hw + NAV_GAP),    ly: 0, ux:  1, uy: 0, px: 0, py: -1 },
      { key: 'up',    axis: 'y', dir: -1, lx: 0, ly: -(hh + NAV_GAP_UP), ux: 0, uy: -1, px: 1, py: 0 },
      { key: 'down',  axis: 'y', dir:  1, lx: 0, ly:  (hh + NAV_GAP),    ux: 0, uy:  1, px: 1, py: 0 }
    ].map(function (s) {
      s.active = (g.count <= 1) || (s.axis === layoutAxis);
      s.canRemove = s.active && g.count > 1 && s.axis === layoutAxis;
      var f = frozen && frozen[s.key];
      if (f) {
        s.at = f.at; s.plus = f.plus; s.minus = f.minus; s.u = f.u;
        s.frozen = true;
        return s;
      }
      s.at = self.toScreen(g, s.lx, s.ly);
      s.plus = self.toScreen(g, s.lx + s.px * NAV_PM, s.ly + s.py * NAV_PM);
      s.minus = self.toScreen(g, s.lx - s.px * NAV_PM, s.ly - s.py * NAV_PM);
      // 矢羽の向き（画面）。塊を回すと矢羽も一緒に回る
      var o0 = self.toScreen(g, 0, 0);
      var o1 = self.toScreen(g, s.ux, s.uy);
      s.u = { x: o1.x - o0.x, y: o1.y - o0.y };
      return s;
    });
  };

  /** 回転＋／−ボタンの位置（🔒 §25-8）。回転つまみ（§18-t）の両脇に並べる */
  Editor.prototype.rotBtns = function (o) {
    if (!o) return null;
    if (o.type !== 'rect' && o.type !== 'stampGroup') return null;
    // 🔒 §25-7 修正1: 据え置き中は押した時の位置のまま（回転で弧を描いて逃げない）
    var fz = this._frozenOverlay(o);
    if (fz && fz.rot) {
      return fz.rot.map(function (b) {
        return { delta: b.delta, at: b.at, frozen: true };
      });
    }
    var geo = (o.type === 'rect') ? this.rectHalf(o) : this.stampGeom(o);
    // 回転つまみと同じ高さ（🔒 §30-19-2）。縁は rotEdgeOf（🔒 §30-19-3 1）
    var y = -rotEdgeOf(o, geo) - rotStemOf(o);
    return [{ delta: -1, at: this.toScreen(o, -ROTBTN_OFF, y) },
            { delta:  1, at: this.toScreen(o,  ROTBTN_OFF, y) }];
  };

  /** ±オーバーレイを押したか。{spoke, act:'plus'|'minus'} */
  Editor.prototype.hitStampNav = function (px, py) {
    var sel = this.getSelected();
    if (sel.length !== 1 || this.tool !== 'select') return null;
    var nav = this.stampNav(sel[0]);
    if (!nav) return null;
    for (var i = 0; i < nav.length; i++) {
      var s = nav[i];
      if (!s.active) continue;
      if (Math.hypot(px - s.plus.x, py - s.plus.y) <= NAV_R + 3) {
        return { obj: sel[0], spoke: s, act: 'plus' };
      }
      if (s.canRemove && Math.hypot(px - s.minus.x, py - s.minus.y) <= NAV_R + 3) {
        return { obj: sel[0], spoke: s, act: 'minus' };
      }
      // 🔒 §25-7「矢羽自体を＋として扱うかは実装時に微調整」→ 大きな的として＋にする
      if (Math.hypot(px - s.at.x, py - s.at.y) <= NAV_HIT) {
        return { obj: sel[0], spoke: s, act: 'plus' };
      }
    }
    return null;
  };

  /** 回転＋／−ボタンを押したか。{obj, delta} */
  Editor.prototype.hitRotBtn = function (px, py) {
    var sel = this.getSelected();
    if (sel.length !== 1 || this.tool !== 'select') return null;
    var bs = this.rotBtns(sel[0]);
    if (!bs) return null;
    for (var i = 0; i < bs.length; i++) {
      if (Math.hypot(px - bs[i].at.x, py - bs[i].at.y) <= ROTBTN_R + 3) {
        return { obj: sel[0], delta: bs[i].delta };
      }
    }
    return null;
  };

  /* ---------- ±/回転ボタンの「その場に固定」（🔒 §25-7 修正1） ----------
   *
   * 🔴 据え置くのは**画面座標だけ**。塊の実データ（origin / count / angle）は
   *    growStamp / nudgeRotate が従来どおり即座に正しく更新する。
   *    ここで凍らせた点は「描く」と「当たり判定」の**両方**が同じ物を見るので、
   *    据え置き中でもボタンは押した位置でそのまま押せる（ずれない）。
   * 🔴 「その向きに伸ばせるか（active / canRemove）」は凍らせない。
   *    1枠→2枠で並びの軸が決まるといった**状態**は常に最新で判定する。
   */

  /** 据え置き中なら、その図形ぶんの凍った座標を返す */
  Editor.prototype._frozenOverlay = function (o) {
    var f = this._navFreeze;
    if (!f || !o || f.id !== o.id) return null;
    if (Date.now() > f.until + 50) return null;   // 念のための保険（普通は timer が消す）
    return f;
  };

  /**
   * 押した瞬間の画面座標でオーバーレイを据え置く。
   * 既に据え置き中の同じ図形なら**時間を延長するだけ**（連打し続ける限り動かない）。
   * 🔴 必ず増減／回転を実行する**前**に呼ぶこと（押した時の位置を覚えるため）。
   */
  Editor.prototype.freezeOverlay = function (o) {
    if (!o) return;
    var f = this._navFreeze;
    if (f && f.id === o.id) {
      f.until = Date.now() + NAV_FREEZE_MS;
    } else {
      this._navFreeze = null;               // ← 一旦外して「いまの実位置」を採る
      var nav = this.stampNav(o), rot = this.rotBtns(o), m = null;
      if (nav) {
        m = {};
        nav.forEach(function (s) {
          m[s.key] = { at: s.at, plus: s.plus, minus: s.minus, u: s.u };
        });
      }
      this._navFreeze = {
        id: o.id, nav: m,
        rot: rot ? rot.map(function (b) { return { delta: b.delta, at: b.at }; }) : null,
        until: Date.now() + NAV_FREEZE_MS, timer: null
      };
    }
    this._armFreezeTimer();
  };

  /** 時間切れで本来の位置へ戻す。連打のたびに掛け直す */
  Editor.prototype._armFreezeTimer = function () {
    var self = this, f = this._navFreeze;
    if (!f) return;
    if (f.timer) clearTimeout(f.timer);
    f.timer = setTimeout(function () {
      if (self._navFreeze !== f) return;
      self._navFreeze = null;
      self.render();                        // 本来の位置へ（動きは付けない）
    }, NAV_FREEZE_MS);
  };

  /** 据え置きを解く。silent=true なら描き直しは呼び手に任せる */
  Editor.prototype.clearOverlayFreeze = function (silent) {
    var f = this._navFreeze;
    if (!f) return false;
    if (f.timer) clearTimeout(f.timer);
    this._navFreeze = null;
    if (!silent) this.render();
    return true;
  };

  /* ---------- 増減・回転の実行（ボタンと矢印キーの共通の入口） ----------
   * burst=true は「キーの押しっぱなし（自動リピート）」。
   * 履歴を1回だけにし、保存や右パネルの引き直しもまとめて1回にする
   * （でないと押しっぱなしで履歴 60 件が2秒で埋まる）。 */
  Editor.prototype._burstCommit = function (burst) {
    this.render();
    if (!burst) { this._emit('change'); return; }
    var self = this;
    if (this._burstT) clearTimeout(this._burstT);
    this._burstT = setTimeout(function () {
      self._burstT = null;
      self._emit('change');
    }, 180);
  };

  /** 塊を1枠増やす／減らす（🔒 §25-7）。触ったら矢印キーは「増減」に付く */
  Editor.prototype.nudgeStamp = function (g, axis, dir, remove, burst) {
    if (!burst) this.snapshot();
    if (!this.growStamp(g, axis, dir, remove)) {
      if (!burst) this.undoStack.pop();
      return false;
    }
    this.arrowMode = 'grow';
    var st = this._growSide;
    if (st.id !== g.id) { st.id = g.id; st.x = 0; st.y = 0; }
    st[axis] = dir;
    this._burstCommit(burst);
    return true;
  };

  /** 0.5°ずつ回す（🔒 §25-8）。触ったら矢印キーは「回転」に付く */
  Editor.prototype.nudgeRotate = function (o, sign, burst) {
    if (!o || (o.type !== 'rect' && o.type !== 'stampGroup')) return false;
    if (!burst) this.snapshot();
    var a = (o.angle || 0) + sign * ROT_STEP;
    o.angle = ((a % 360) + 360) % 360;
    this.arrowMode = 'rotate';
    this._burstCommit(burst);
    return true;
  };

  /**
   * 矢印キーでの増減（🔒 §25-7 のキーボード規則）。
   * 「左に伸ばしている状態で ←＝左に追加／→＝減る。減り切ってさらに→を
   *  押し続けると右への追加に転じる」。上下も同じ。
   * 押した向き（画面）に一番近い矢羽を選ぶので、塊を回していても見たとおりに動く。
   */
  Editor.prototype.arrowGrow = function (g, dirScreen, burst) {
    var nav = this.stampNav(g);
    if (!nav) return false;
    var best = null, bestDot = -Infinity;
    nav.forEach(function (s) {
      var len = Math.hypot(s.u.x, s.u.y) || 1;
      var dot = (s.u.x / len) * dirScreen.x + (s.u.y / len) * dirScreen.y;
      if (dot > bestDot) { bestDot = dot; best = s; }
    });
    if (!best) return false;
    if (!best.active) {
      // 押しっぱなしの間は同じ知らせを出し続けない（1押し目だけ）
      if (!burst) {
        this._emit('hint', (g.direction === 'row' ? '横' : '縦')
          + 'に並ぶ塊なので、その向きには伸ばせません（枠を1つに戻すと変えられます）');
      }
      return false;
    }
    var st = this._growSide;
    if (st.id !== g.id) { st.id = g.id; st.x = 0; st.y = 0; }
    var side = st[best.axis];
    // まだどちら側も伸ばしていない／同じ向き ＝ その向きへ追加
    if (!side || side === best.dir) {
      return this.nudgeStamp(g, best.axis, best.dir, false, burst);
    }
    // 逆向き ＝ 伸ばした側から1つ減らす。減り切ったら反対側への追加に転じる
    if (g.count > 1) return this.nudgeStamp(g, best.axis, side, true, burst);
    return this.nudgeStamp(g, best.axis, best.dir, false, burst);
  };

  /* ---------- 曲線（2次ベジェ・正典 §4-2「必ず1本の曲線」） ---------- */
  function bezier(p0, pc, p1, t) {
    var u = 1 - t;
    return { x: u * u * p0.x + 2 * u * t * pc.x + t * t * p1.x,
             y: u * u * p0.y + 2 * u * t * pc.y + t * t * p1.y };
  }
  Editor.prototype.curvePts = function (o) {
    return { a: this.map.project(o.a.lat, o.a.lng),
             b: this.map.project(o.b.lat, o.b.lng),
             c: this.map.project(o.c.lat, o.c.lng) };
  };

  /* ---------- 紙面mm → 画面px（🔒 §30-25-7） ----------
   * オーナー実機 2026-09-13:「ZL を変えたらテキストの大きさも一緒に変わるべき。
   * 他の描画素材と同じように ZL と連動」。
   * 🔴 直す前は定数 SHEET_MM_PX（≒4.32 px/mm）だったので、拡大すると地図に対して
   *    文字だけが小さく見えていた（＝紙の見え方と違う）。
   * 直し: 換算率を**枠の画面上の大きさ**から出す。
   *    mmPx ＝ 紙の作図幅(mm) が画面で何px か
   *          ＝ 枠の画面幅(px) ÷ 紙の作図幅(mm) × SHEET_SCALE
   * 🔴 SHEET_SCALE を掛けるのは、**この mm が export.js の mmPx() と同じ単位**
   *    （SHEET_TEXT_MM / MARK.hatchMm / COMPASS.rMm は全部「記載欄 138mm 基準の mm」で、
   *     紙には SHEET_SCALE 倍で刷られる）だから。これで
   *    「画面の 文字÷枠」＝「紙の 文字÷図」＝ **紙と同じ見え方**になる。
   * 🔴 枠の矩形と作図幅は app.js しか知らないので、app.js が bindEditor で
   *    `editor.frameMmPx` を挿す（paperScale / keysBusy と同じ作法）。
   *    挿されていない・枠が無い時は従来の定数に落ちる（＝今までの見え方）。 */
  Editor.prototype.mmPx = function () {
    if (typeof this.frameMmPx === 'function') {
      var v = this.frameMmPx();
      if (typeof v === 'number' && isFinite(v) && v > 0) return v;
    }
    return SHEET_MM_PX;
  };

  /* ---------- テキストの画面上の大きさ ----------
   * 🔒 §30-22-3 3: 文字の大きさは連続値（o.sizeMm・紙のミリ）。
   * 🔒 §30-25-7: 小／中／大（sizeMm 無しの旧データ）も textMmOf が
   *   Exporter.SHEET_TEXT_MM（2.6／3.4／4.4mm）へ読み替えるので、**全部の文字が
   *   「紙のミリ × mmPx()」の同じ道**を通る（＝ズームに連動する）。
   * 🔴 TEXT_PX の3段は Exporter が読めない時（単体テスト）の予備だけになった。 */
  Editor.prototype.textPx = function (o) {
    var mm = textMmOf(o);
    if (mm > 0) return Math.max(6, mm * this.mmPx());
    return TEXT_PX[o && o.size] || TEXT_PX.medium;
  };

  /* ---------- 印の基準の大きさ（画面px・🔒 §30-30-1） ----------
   * 印（信号機・バス停・P・木・主役の◎）は**文字の大きさに連動しない**。
   * 🔴 出どころはこの1か所（描画・箱・つまみ・当たり判定・薄出しが全部これを読む）。
   *    紙（export.js）は同じ式を `mmPx(MARK_BASE_MM, pxmm)` で解く。 */
  Editor.prototype.markBasePx = function () {
    return Math.max(6, markBaseMm() * this.mmPx());
  };

  /* ---------- 駐車位置ラベルの塊（labelBlock・正典 §18-f 駐車位置ラベル） ----------
   * {at（塊の左上・ドラッグで移動）, arrowTo（矢印の終点＝対象の枠・別ドラッグ）,
   *  lines（1行目は見出し「保管場所」）, scale（大きさ）}
   * 文字は紙面ミリ基準の text と同じ考え方で、画面では画面px・紙では mm で解く。 */
  Editor.prototype.labelBlockGeom = function (o) {
    var p = this.map.project(o.at.lat, o.at.lng);
    /* 🔒 §30-25-7: 紙（export.js labelBlockGeom）と同じ「紙のミリ × 倍率」。
     * 画面は mmPx()（ズーム連動）、紙は mmPx(mm, pxmm) で解く＝同じ形になる。 */
    var size = Math.max(7, textMmOf(o) * this.mmPx() * (o.scale || 1));
    var lh = size * 1.5, pad = size * 0.45;
    var lines = o.lines || [];
    var maxEm = 0;
    lines.forEach(function (t) { maxEm = Math.max(maxEm, emWidth(t)); });
    return { x: p.x, y: p.y, size: size, lh: lh, pad: pad, lines: lines,
             w: Math.max(size * 2, maxEm * size + pad * 2),
             h: Math.max(size, lines.length * lh) + pad * 2 };
  };

  /** 塊ラベルを1つ置く（誘導⑧の［ラベル貼り付け］から呼ぶ） */
  Editor.prototype.addLabelBlock = function (opt) {
    var o = {
      id: uid(), type: 'labelBlock',
      at: { lat: opt.at.lat, lng: opt.at.lng },
      arrowTo: opt.arrowTo ? { lat: opt.arrowTo.lat, lng: opt.arrowTo.lng } : null,
      lines: (opt.lines || []).slice(),
      size: opt.size || 'medium',
      scale: opt.scale || 1,
      style: { color: '#111', w: 2 }
    };
    this.snapshot();
    this.objects.push(o);
    this.selection = [o.id];
    this.commit();
    this._emit('select', this.getSelected());
    return o;
  };

  /* ================= 当たり判定 ================= */

  /* ---------- 選択中の図形に出す「複製 / 削除」ボタン ----------
   * 回転つまみの右隣に並べる。選択したその場でコピー・削除できる。 */
  var ACT_R = 11;          // ボタンの半径(px)
  var ACT_GAP = 27;        // つまみからの間隔(px)

  /**
   * ボタン列の左右の位置決めに使う「図形＋オーバーレイ」の点。
   * 🔒 §25-7: ±方向ボタン・回転ボタンと**重ならないように**、横だけは
   * それらの外側へ回す（縦は図形の上端のままにして、いつもの場所から動かさない）。
   */
  Editor.prototype.actionOutline = function (o) {
    var pts = this.outlinePoints(o);
    if (!pts || !pts.length) return null;
    pts = pts.slice();
    // オーバーレイが出ていない時（複数選択・作図中）は図形の外形だけで決める
    if (this.tool !== 'select' || this.selection.length !== 1) return pts;
    var nav = this.stampNav(o);
    if (nav) {
      nav.forEach(function (s) {
        if (!s.active) return;
        pts.push(s.at, s.plus, s.minus);
      });
    }
    var rb = this.rotBtns(o);
    if (rb) rb.forEach(function (b) { pts.push(b.at); });
    return pts;
  };

  /** ボタンを置く位置。図形の外接箱の右上あたりに出す */
  Editor.prototype.actionAnchor = function (o) {
    var pts = this.outlinePoints(o);
    if (!pts || !pts.length) return null;
    var minY = Infinity;
    pts.forEach(function (p) { if (p.y < minY) minY = p.y; });
    var maxX = -Infinity;
    this.actionOutline(o).forEach(function (p) {
      if (p.x + NAV_R > maxX) maxX = p.x + NAV_R;
    });
    return { x: maxX + ACT_GAP, y: minY - 4 };
  };

  /** 図形の画面上の外形（当たり判定・ボタン位置の共通材料） */
  Editor.prototype.outlinePoints = function (o) {
    var self = this;
    if (o.type === 'rect') return this.rectCorners(o);
    if (o.type === 'stampGroup') {
      var geo = this.stampGeom(o);
      var ca = Math.cos(rad(o.angle || 0)), sa = Math.sin(rad(o.angle || 0));
      var c = this.map.project(o.origin.lat, o.origin.lng);
      return [[-geo.hw, -geo.hh], [geo.hw, -geo.hh],
              [geo.hw, geo.hh], [-geo.hw, geo.hh]].map(function (p) {
        return { x: c.x + p[0] * ca - p[1] * sa, y: c.y + p[0] * sa + p[1] * ca };
      });
    }
    if (o.type === 'labelBlock') {
      if (!o.at) return null;
      var lg = this.labelBlockGeom(o);
      return [{ x: lg.x, y: lg.y }, { x: lg.x + lg.w, y: lg.y },
              { x: lg.x + lg.w, y: lg.y + lg.h }, { x: lg.x, y: lg.y + lg.h }];
    }
    /* 🔒 §28-3: 方位記号は at（針の中心）1点だけ持つので、箱を自分で出す
     * （下の汎用 o.at の枝は o.text の幅で測るため、文字を持たないこの型では潰れる） */
    if (o.type === 'compass') {
      if (!o.at) return null;
      var cp = this.map.project(o.at.lat, o.at.lng);
      // 🔒 §30-37 2: 大きさの出どころは compassRadiusMm（倍率 markScale 込み）1か所
      var cb = compassBox(compassRadiusMm(o) * this.mmPx());
      return [{ x: cp.x - cb.hw, y: cp.y + cb.cy - cb.hh },
              { x: cp.x + cb.hw, y: cp.y + cb.cy + cb.hh }];
    }
    if (o.points) {
      return o.points.map(function (p) { return self.map.project(p.lat, p.lng); });
    }
    if (o.a && o.b) {
      var out = [this.map.project(o.a.lat, o.a.lng), this.map.project(o.b.lat, o.b.lng)];
      if (o.c) out.push(this.map.project(o.c.lat, o.c.lng));
      return out;
    }
    if (o.at) {
      var p = this.map.project(o.at.lat, o.at.lng);
      var s = this.textPx(o);
      var w = emWidth(o.text) * s;             // §18-j: 実幅
      return [{ x: p.x - w / 2, y: p.y - s * 0.7 }, { x: p.x + w / 2, y: p.y + s * 0.7 }];
    }
    return null;
  };

  /** 複製・削除ボタンを押したか */
  /** ボタンの並び。塊だけ「階段状にずらす」を真ん中に挟む */
  Editor.prototype.actionList = function (o) {
    /* 🔒 §25-4: 主役マークは1組（本拠1個・駐車場1個）なので「＋」を出さない。
     * 複製すると同じ markRole が2個になり、ピン追従で重なって別物に見える。 */
    if (isMainMark(o)) return ['delete'];
    /* 🔒 §28-3「既に方位記号があるシートには2つ目を置かない」。手でも増やせない
     * ようにする（1枚の紙に北矢印が2本あると、どちらが正しいのか分からない）。 */
    if (o && o.type === 'compass') return ['delete'];
    return (o && o.type === 'stampGroup')
      ? ['duplicate', 'stagger', 'delete']
      : ['duplicate', 'delete'];
  };

  Editor.prototype.actionPos = function (o, i) {
    var a = this.actionAnchor(o);
    if (!a) return null;
    return { x: a.x + i * (ACT_R * 2 + 6), y: a.y };
  };

  Editor.prototype.hitAction = function (px, py) {
    var sel = this.getSelected();
    if (!sel.length) return null;
    var list = this.actionList(sel[0]);
    for (var i = 0; i < list.length; i++) {
      var p = this.actionPos(sel[0], i);
      if (p && Math.hypot(px - p.x, py - p.y) <= ACT_R + 3) return list[i];
    }
    return null;
  };

  /**
   * 🔒 §30-14-5 3: 中心に移動の十字（✥）を出す図形か。
   * 四角（**主役マーク以外**）と塊だけ。主役マークは所在図のピンそのもの
   * （§25-4）で、掴める場所を増やす必要がない。
   * 🔴 描画・当たり判定の**両方**がこの1か所を見る（§22-z の教訓）。
   */
  Editor.prototype._hasMoveCross = function (o) {
    if (!o) return false;
    if (o.type === 'stampGroup') return true;
    return o.type === 'rect' && o.role !== 'mainmark';
  };

  /**
   * 🔒 §30-25-17: 四角・塊の「辺つまみ」の半径(px)。**ズームに応じて可変**。
   * 🔴 描く2か所（_drawRect / _drawStamp）と当たり1か所（hitHandle）が
   *    必ずここを通る（§22-z の教訓: 描画と当たり判定はセットで直す）。
   */
  Editor.prototype.edgeHandleR = function () {
    var z = (this.map && typeof this.map.getZoom === 'function') ? this.map.getZoom() : null;
    if (!(typeof z === 'number' && isFinite(z))) return HANDLE_EDGE_MIN;
    var z0 = HANDLE_EDGE_ZL[0], z1 = HANDLE_EDGE_ZL[1];
    if (z <= z0) return HANDLE_EDGE_MIN;
    if (z >= z1) return HANDLE_EDGE_MAX;
    return HANDLE_EDGE_MIN
         + (HANDLE_EDGE_MAX - HANDLE_EDGE_MIN) * (z - z0) / (z1 - z0);
  };

  Editor.prototype.hitHandle = function (px, py) {
    var sel = this.getSelected();
    if (sel.length !== 1) return null;
    var o = sel[0], i;

    if (o.type === 'rect' || o.type === 'stampGroup') {
      var geo = (o.type === 'rect') ? this.rectHalf(o) : this.stampGeom(o);
      var loc = this.toLocal(o, px, py);
      // 🔒 §30-19-3 1: 回転の当たりも描画と同じ縁（rotEdgeOf）から測る
      if (Math.abs(loc.x) <= HANDLE + 3 &&
          Math.abs(loc.y - (-rotEdgeOf(o, geo) - rotStemOf(o))) <= HANDLE + 3) {
        return { obj: o, kind: 'rotate' };
      }
      /* 🔒 §30-14-5 3: 中心の移動の十字（✥）。**辺つまみより先に**見る
       * （小さい図形では中心と辺つまみが近づくため）。主役マークには出さない。
       * 🔴 返すのは kind:'move'＝図形の中を掴んだ時とまったく同じ経路に流す。 */
      if (this._hasMoveCross(o) &&
          Math.hypot(loc.x, loc.y) <= MOVE_HIT) {
        return { obj: o, kind: 'move' };
      }
      /* 🔒 §30-25-40 3: 主役の■の**右下の角のつまみ**（縦横を同じ比率で変える）。
       * 🔒 §30-31-1 1: 角に加えて**4辺の辺つまみ**も出す（下のふつうの四角と同じ
       *    edgeHandleR）。角＝同じ比率／辺＝掴んだ辺だけ（🔒 §30-35-3 1・
       *    反対の辺は動かないので中心はピンからずれる）。
       * 🔴 角を先に見る（小さい■では角と辺つまみが重なるため）。 */
      if (isMainMark(o) && o.type === 'rect') {
        if (Math.abs(loc.x - geo.hw) <= HANDLE_TEXT + 3 &&
            Math.abs(loc.y - geo.hh) <= HANDLE_TEXT + 3) {
          return { obj: o, kind: 'markSize' };
        }
      }
      /* 🔒 §30-14-5 2 / §30-25-17: 辺つまみは小さく（edgeHandleR＝ZL で可変）。
       * 当たりは今までどおり半径 +2 まで。 */
      var edgeR = this.edgeHandleR();
      var edges = [{ i: 0, x: 0, y: -geo.hh }, { i: 1, x: geo.hw, y: 0 },
                   { i: 2, x: 0, y: geo.hh }, { i: 3, x: -geo.hw, y: 0 }];
      for (i = 0; i < edges.length; i++) {
        if (Math.abs(loc.x - edges[i].x) <= edgeR + 2 &&
            Math.abs(loc.y - edges[i].y) <= edgeR + 2) {
          return { obj: o, kind: 'edge', index: edges[i].i };
        }
      }
      return null;
    }

    /* 塊ラベル（§18-f 駐車位置ラベル）: 矢印の**先だけ**別に動かせる／右下で大きさを変える */
    if (o.type === 'labelBlock' && o.at) {
      if (o.arrowTo) {
        var ta = this.map.project(o.arrowTo.lat, o.arrowTo.lng);
        if (Math.hypot(px - ta.x, py - ta.y) <= HANDLE + 3) {
          return { obj: o, kind: 'lbArrow' };
        }
      }
      var lg = this.labelBlockGeom(o);
      if (Math.abs(px - (lg.x + lg.w)) <= HANDLE + 3 &&
          Math.abs(py - (lg.y + lg.h)) <= HANDLE + 3) {
        return { obj: o, kind: 'lbSize' };
      }
      return null;
    }

    /* 🔒 §30-22-3 3: 文字の右下＝大きさのつまみ（ドラッグで連続値 sizeMm）。
     * 🔴 文字が空の物はつまむ所が無いので出さない（textHandleAt が null）。
     * 🔒 §30-25-18 3: 印（信号機・バス停・P・木）は**印の絵の右下**に別のつまみ
     *    （markScale）。文字が空でも出す＝印だけ置いた時も大きさを変えられる。 */
    if (o.type === 'text' && o.at) {
      var tp0 = this.textHandleAt(o);
      if (tp0 && Math.hypot(px - tp0.x, py - tp0.y) <= HANDLE_TEXT + 3) {
        return { obj: o, kind: 'textSize' };
      }
      var mp0 = this.markHandleAt(o);
      if (mp0 && Math.hypot(px - mp0.x, py - mp0.y) <= HANDLE_TEXT + 3) {
        return { obj: o, kind: 'markSize' };
      }
      return null;
    }

    /* 🔒 §30-37 1・3: 方位記号も**印と同じ右下のつまみ**で大きさを変える。
     * 🔴 位置の出どころは markHandleAt（＝ markRect の方位記号の枝）1か所で、
     *    描画（_drawCompass）とここが必ず一致する（§22-z の教訓）。 */
    if (o.type === 'compass' && o.at) {
      var cp1 = this.markHandleAt(o);
      if (cp1 && Math.hypot(px - cp1.x, py - cp1.y) <= HANDLE_TEXT + 3) {
        return { obj: o, kind: 'markSize' };
      }
      return null;
    }

    if (o.type === 'line' || o.type === 'arrow') {
      /* 🔒 §18-x-5: 使用の本拠⇄駐車場の結線は**両端がピンそのもの**。
       * 端をつまんで外せると図とピンが食い違うので、つまみを出さない
       * （動かしたい時はピン＝主役マークの方を動かす）。 */
      if (o.role === 'distance') return null;
      var pa = this.map.project(o.a.lat, o.a.lng);
      var pb = this.map.project(o.b.lat, o.b.lng);
      if (Math.hypot(px - pa.x, py - pa.y) <= HANDLE + 2) return { obj: o, kind: 'end', index: 0 };
      if (Math.hypot(px - pb.x, py - pb.y) <= HANDLE + 2) return { obj: o, kind: 'end', index: 1 };
      return null;
    }

    if (o.type === 'curve') {
      var q = this.curvePts(o);
      if (Math.hypot(px - q.a.x, py - q.a.y) <= HANDLE + 2) return { obj: o, kind: 'end', index: 0 };
      if (Math.hypot(px - q.b.x, py - q.b.y) <= HANDLE + 2) return { obj: o, kind: 'end', index: 1 };
      if (Math.hypot(px - q.c.x, py - q.c.y) <= HANDLE + 2) return { obj: o, kind: 'ctrl' };
      return null;
    }

    if (o.type === 'polygon' || o.type === 'path') {
      /* 頂点が多い自動下書きは、つまみを出しすぎても掴めないので上限を設ける。
       * 🔒 §30-38-1 5: ［道路を描く］が縁を1本に繋ぐようになり、長い道は
       *    60 を超えることがある（超えると直せなくなる）ので上限を 200 に上げた。 */
      if (o.points.length > VERTEX_HANDLE_MAX) return null;
      for (i = 0; i < o.points.length; i++) {
        var p = this.map.project(o.points[i].lat, o.points[i].lng);
        if (Math.hypot(px - p.x, py - p.y) <= HANDLE + 2) {
          return { obj: o, kind: 'vertex', index: i };
        }
      }
      return null;
    }
    return null;
  };

  /**
   * 🔒 §30-22-3 3: 文字の大きさのつまみの位置（画面px）。
   * 🔴 選択枠（_drawText の sel-box）の**右下の角**と同じ式をここ1か所に置く
   *    ＝ 描画と当たり判定が必ず一致する（§22-z の教訓）。
   */
  Editor.prototype.textHandleAt = function (o) {
    if (!o || o.type !== 'text' || !o.at || !o.text) return null;
    var p = this.map.project(o.at.lat, o.at.lng);
    var s = Math.max(6, this.textPx(o));
    var w = emWidth(o.text) * s;
    return { x: p.x + w / 2 + 4, y: p.y + s * 0.7 };
  };

  /**
   * 🔒 §30-25-18 2: **文字そのものの箱**を掴んだか（§18-j: 実幅で掴める）。
   * 🔴 _hitOne と「印を掴んだのか文字を掴んだのか」の判別（pointerdown）が
   *    同じ式を読むための1か所。
   */
  Editor.prototype.textBoxHit = function (o, px, py) {
    if (!o || o.type !== 'text' || !o.at) return false;
    var p = this.map.project(o.at.lat, o.at.lng);
    var size = this.textPx(o);
    var w = emWidth(o.text) * size;
    return Math.abs(px - p.x) <= w / 2 + 4 && Math.abs(py - p.y) <= size * 0.75;
  };

  /**
   * 🔒 §30-25-18 2: 印の絵の箱（画面px）。掴む・消す・つまみを置くの3つが読む1か所。
   * @return {x, y, hw, hh} x,y＝箱の中心の画面座標。印つき文字でなければ null
   */
  Editor.prototype.markRect = function (o) {
    /* 🔒 §30-37 3: 方位記号も同じ箱を返す＝ markHandleAt／markHit／markSize の
     * ドラッグ（つまみ）がそのまま効く。箱の出どころは compassBox 1か所で、
     * 中心は針の中心（at）＋ cy（箱の中心までのずれ）。 */
    if (o && o.type === 'compass' && o.at) {
      var cb = compassBox(compassRadiusMm(o) * this.mmPx());
      var at = this.map.project(o.at.lat, o.at.lng);
      return { x: at.x, y: at.y + cb.cy, hw: cb.hw, hh: cb.hh };
    }
    // 🔒 §30-30-1: 印の大きさは基準（markBasePx）× markScale＝文字に連動しない
    var g = markBoxGeom(o, Math.max(6, this.textPx(o)), this.markBasePx());
    if (!g) return null;
    var a = this.map.project(o.anchor.lat, o.anchor.lng);
    return { x: a.x, y: a.y + g.dy, hw: g.hw, hh: g.hh };
  };

  /** 🔒 §30-25-18 2: 印の絵そのものを掴んだか（当たりは箱＋3px） */
  Editor.prototype.markHit = function (o, px, py) {
    var r = this.markRect(o);
    if (!r) return false;
    return Math.abs(px - r.x) <= r.hw + 3 && Math.abs(py - r.y) <= r.hh + 3;
  };

  /**
   * 🔒 §30-25-18 3: 印の大きさのつまみの位置（画面px）＝**印の絵の右下の角**。
   * 🔴 描画（_drawText）と当たり判定（hitHandle）が必ずここを通る。
   */
  Editor.prototype.markHandleAt = function (o) {
    var r = this.markRect(o);
    if (!r) return null;
    return { x: r.x + r.hw, y: r.y + r.hh };
  };

  /**
   * 🔒 §30-25-40: 印の大きさのドラッグの**基準の中心**（画面px）。
   * 印つき文字・主役の◎＝印の箱の中心／主役の■＝四角の中心
   * （🔒 §30-35-3 1 で中心はピンからずれ得るが、基準は**四角の中心**のまま）。
   * 🔴 掴んでいる間に動かない点を選ぶ（動く点を基準にすると倍率が暴れる）。
   */
  Editor.prototype.markScaleOrigin = function (o) {
    if (o && o.type === 'rect' && o.role === 'mainmark' && o.center) {
      return this.map.project(o.center.lat, o.center.lng);
    }
    /* 🔒 §30-37 3: 方位記号の基準は**針の中心（at）**。at は大きさを変えても
     * 動かない点なので、そこから測る（箱の中心 cy は倍率で動く）。 */
    if (o && o.type === 'compass' && o.at) {
      return this.map.project(o.at.lat, o.at.lng);
    }
    var r = this.markRect(o);
    return r ? { x: r.x, y: r.y } : null;
  };

  /**
   * 画面座標の下にある図形（一番「上」に見えている物）。
   * 🔒 §30-25-4（2026-09-13 オーナー実機「交差点や名前を選びたいのに道路が動く」）:
   *   **道路以外を先に**配列の後ろから探し、どれにも当たらなければ道路を後ろから探す。
   *   ＝ 描く順（道路 → その他 → 文字）の逆から見ることになるので
   *   「見えている物が掴める」（§22-z の教訓: 描画・当たり判定・パン判定はセット）。
   * 🔴 選択・ドラッグ・消しゴム・採番・保管場所・パン判定は全部ここを通る。
   */
  Editor.prototype.hitObject = function (px, py) {
    var i, o;
    for (i = this.objects.length - 1; i >= 0; i--) {
      o = this.objects[i];
      if (isRoad(o)) continue;                 // 道路は後回し（一番下の層）
      if (this._hitOne(o, px, py)) return o;
    }
    for (i = this.objects.length - 1; i >= 0; i--) {
      o = this.objects[i];
      if (!isRoad(o)) continue;
      if (this._hitOne(o, px, py)) return o;
    }
    return null;
  };

  Editor.prototype._hitOne = function (o, px, py) {
    var j, a, b;
    if (o.type === 'rect') {
      var h = this.rectHalf(o), loc = this.toLocal(o, px, py);
      return Math.abs(loc.x) <= h.hw + 2 && Math.abs(loc.y) <= h.hh + 2;
    }
    if (o.type === 'stampGroup') {
      return !!this.hitStampCell(px, py) &&
             this.hitStampCell(px, py).group.id === o.id;
    }
    if (o.type === 'line' || o.type === 'arrow') {
      a = this.map.project(o.a.lat, o.a.lng);
      b = this.map.project(o.b.lat, o.b.lng);
      return distToSegment(px, py, a, b) <= HIT_PAD;
    }
    if (o.type === 'curve') {
      var q = this.curvePts(o), prev = q.a;
      for (j = 1; j <= 20; j++) {
        var cur = bezier(q.a, q.c, q.b, j / 20);
        if (distToSegment(px, py, prev, cur) <= HIT_PAD) return true;
        prev = cur;
      }
      return false;
    }
    if (o.type === 'polygon' || o.type === 'path') {
      var closed = (o.type === 'polygon');
      var pts = o.points.map(function (p) { return this.map.project(p.lat, p.lng); }, this);
      var last = closed ? pts.length : pts.length - 1;
      for (j = 0; j < last; j++) {
        if (distToSegment(px, py, pts[j], pts[(j + 1) % pts.length]) <= HIT_PAD) return true;
      }
      return false;
    }
    if (o.type === 'text') {
      if (this.textBoxHit(o, px, py)) return true;
      /* 🔒 §28-5 A: 文字が空の印つき文字（手で置いた信号機・バス停）は文字の箱が
       * 幅0なので掴めない。印そのものを当たり判定にする。
       * 🔒 §30-25-18 2: **文字があっても印の絵で掴める**（印を掴んで動かす・
       *    消しゴムで消す）。箱の出どころは markRect の1か所＝見えている大きさ＝
       *    掴める大きさ（markScale を掛けた後の絵に合う）。 */
      if (keepsMark(o) && this.markHit(o, px, py)) return true;
      return false;
    }
    if (o.type === 'labelBlock') {
      if (!o.at) return false;
      var lg = this.labelBlockGeom(o);
      return px >= lg.x - 3 && px <= lg.x + lg.w + 3
          && py >= lg.y - 3 && py <= lg.y + lg.h + 3;
    }
    /* 🔒 §28-3: 方位記号。細い形なので少し広めに取る（掴めない・消せないと困る） */
    if (o.type === 'compass') {
      if (!o.at) return false;
      var cp = this.map.project(o.at.lat, o.at.lng);
      // 🔒 §30-37 2: 大きさの出どころは compassRadiusMm（倍率 markScale 込み）1か所
      var cb = compassBox(compassRadiusMm(o) * this.mmPx());
      return Math.abs(px - cp.x) <= cb.hw + 6
          && Math.abs(py - (cp.y + cb.cy)) <= cb.hh + 4;
    }
    return false;
  };

  /* ===== 🔒 §30-38-2: 線に頂点を足す・消す（Alt＋クリック）=====
   * 🔴 対象は多角形（polygon）・線（path）・直線（line）だけ。
   *    結線（role:'distance'）・矢印・曲線・四角・駐車枠は対象外（§30-38-2 3）。 */
  function canAddVertex(o) {
    if (!o) return false;
    if (o.type === 'line') return o.role !== 'distance';
    return o.type === 'polygon' || o.type === 'path';
  }

  /**
   * その図形の**線分**を掴んだか（画面px）。当たりの太さは `edgeHandleR()`（§30-38-2 4）。
   * @return {obj, index（線分の始点の添字）, at（足の画面座標）} / null
   */
  Editor.prototype._segHitOne = function (o, px, py, r) {
    var a, b, i, last, pts;
    if (!canAddVertex(o)) return null;
    if (o.type === 'line') {
      a = this.map.project(o.a.lat, o.a.lng);
      b = this.map.project(o.b.lat, o.b.lng);
      if (distToSegment(px, py, a, b) > r) return null;
      return { obj: o, index: 0, at: segFoot(px, py, a, b) };
    }
    if (!o.points || o.points.length < 2) return null;
    pts = o.points.map(function (p) { return this.map.project(p.lat, p.lng); }, this);
    // 多角形は閉じているので「最後の点 → 最初の点」の線分も対象にする
    last = (o.type === 'polygon') ? pts.length : pts.length - 1;
    for (i = 0; i < last; i++) {
      a = pts[i]; b = pts[(i + 1) % pts.length];
      if (distToSegment(px, py, a, b) <= r) {
        return { obj: o, index: i, at: segFoot(px, py, a, b) };
      }
    }
    return null;
  };

  /** 点から線分へ下ろした足（画面px） */
  function segFoot(px, py, a, b) {
    var vx = b.x - a.x, vy = b.y - a.y, len2 = vx * vx + vy * vy;
    var t = len2 ? ((px - a.x) * vx + (py - a.y) * vy) / len2 : 0;
    t = Math.max(0, Math.min(1, t));
    return { x: a.x + t * vx, y: a.y + t * vy };
  }

  /**
   * 🔒 §30-38-2 4: 頂点を足す先の線分を探す。
   *   ① 選んでいる図形の線分が当たればそれ（掴みたい物が先）
   *   ② 無ければ `hitObject` と同じ順（道路は最後）で最初に当たった図形
   */
  Editor.prototype.hitSegment = function (px, py) {
    var r = this.edgeHandleR(), i, o, h;
    var sel = this.getSelected();
    if (sel.length === 1) {
      h = this._segHitOne(sel[0], px, py, r);
      if (h) return h;
    }
    for (i = this.objects.length - 1; i >= 0; i--) {
      o = this.objects[i];
      if (isRoad(o)) continue;                 // 道路は後回し（一番下の層）
      h = this._segHitOne(o, px, py, r);
      if (h) return h;
    }
    for (i = this.objects.length - 1; i >= 0; i--) {
      o = this.objects[i];
      if (!isRoad(o)) continue;
      h = this._segHitOne(o, px, py, r);
      if (h) return h;
    }
    return null;
  };

  /**
   * 🔒 §30-38-2 1・3: 線分の途中に頂点を1つ足す。
   * 直線（line）は **同じ id・書式・source のまま** `path` へ変える。
   * 🔴 履歴は snapshot 1回だけ（commit は指を離した時の endDrag に任せる
   *    ＝そのまま続けてドラッグできる）。
   * @return {obj, index（足した頂点の添字）} / null
   */
  Editor.prototype.addVertexAt = function (o, index, ll) {
    if (!canAddVertex(o) || !ll) return null;
    this.snapshot();
    if (o.type === 'line') {
      var a = o.a, b = o.b;
      o.type = 'path';
      o.closed = false;
      o.points = [a, ll, b];
      delete o.a;
      delete o.b;
      return { obj: o, index: 1 };
    }
    o.points.splice(index + 1, 0, ll);
    return { obj: o, index: index + 1 };
  };

  /**
   * 🔒 §30-38-2 2: 頂点を1つ消す。下限＝線は2点・多角形は3点（下限なら一言だけ）。
   * 主役の多角形はピン（重心）を追従させる（ドラッグと同じ）。
   */
  Editor.prototype.removeVertexAt = function (o, index) {
    if (!o || !o.points) return false;
    var min = (o.type === 'polygon') ? 3 : 2;
    if (o.points.length <= min) {
      this._emit('hint', (o.type === 'polygon')
        ? 'これ以上は頂点を減らせません（囲むには頂点が3つ必要です）'
        : 'これ以上は頂点を減らせません（線には点が2つ必要です）');
      return false;
    }
    this.snapshot();
    o.points.splice(index, 1);
    if (isMainMark(o)) this.syncMarkPin(o);
    this.commit();
    return true;
  };

  /**
   * 幅矢印に出す文字（正典 §25-5・§4-6 再改定）。
   * 🔒 **手入力（o.label）があればそれを優先**。無ければ2端点の緯度経度から
   *    実距離を計算して小数1桁で出す（＝「地図上で計算して記載する」実務）。
   * 🔴 見た目は手入力と同じ（§25-5「自動値と手入力値が見分けられる必要は無い」）。
   *    書き出し（export.js の drawArrow）も同じ規則で紙に出す。
   * 🔒 §30-29-4 2: 「幅を入力」を選んで**空のまま**引いた矢印（`noAuto`）は
   *    何も出さない（自動の値に落ちない）。あとで「表示」欄に入れれば出る
   *    （`o.label` が先に立つので `noAuto` が付いたままでも構わない）。
   * 🔴 画面（ここ）と紙（export.js の arrowText）が**この1つの関数**を読む。
   */
  Editor.arrowText = function (o) {
    if (o.label) return o.label;
    if (o.noAuto) return '';
    if (!o.a || !o.b || !global.GSI) return '';
    return fmtM(GSI.distanceMeters(o.a, o.b));
  };

  /**
   * 幅矢印の値ラベルを掴んだか（§25-5 で復活。§22-z 以前の `hitAutoLabel` に相当）。
   * 🔴 押して採用する機能はもう無い（値は常に出ている）ので、ここは
   *    **ラベルの上でも矢印を掴める / 地図がパンしない** ための判定に役割を変えた。
   * 🔴 §22-z の記録どおり `_shouldPan()` からも呼ぶ。片方だけ直すと
   *    「ラベルを掴んだつもりが地図が動く」or「その場で何も掴めない」になる。
   */
  Editor.prototype.hitArrowLabel = function (px, py) {
    for (var i = this.objects.length - 1; i >= 0; i--) {
      var o = this.objects[i];
      if (o.type !== 'arrow') continue;
      var txt = Editor.arrowText(o);
      if (!txt) continue;
      var a = this.map.project(o.a.lat, o.a.lng);
      var b = this.map.project(o.b.lat, o.b.lng);
      var mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2 - 7;   // _drawArrow と同じ位置
      var hw = Math.max(14, emWidth(txt) * DIM_LABEL_PX / 2 + 4);
      if (Math.abs(px - mx) <= hw && Math.abs(py - my) <= 10) return o;
    }
    return null;
  };

  /* ================= 入力 ================= */

  Editor.prototype._shouldPan = function (e) {
    if (e && e.ctrlKey !== undefined) this._setCtrl(e.ctrlKey);
    /* 🔒 §23-7-b: スペースを押している間は**道具にも図形にも関係なく必ずパン**。
     * 🔴 当たり判定より先に返す（掴める物の上でも地図が動く＝画像編集ソフトと同じ）。
     *    editor 側の pointerdown も同じ条件で作図を始めないので取り合いにならない。 */
    if (this._space) return true;
    if (this.effectiveTool() !== 'select') return false;
    var p = this._pt(e);
    if (this.hitAction(p.x, p.y)) return false;
    /* 🔒 §25-7/§25-8: ±方向ボタン・回転ボタンの上では地図を動かさない
     * （押したのに地図がパンする、を防ぐ。§22-z の教訓どおり
     *  「描く・当たり判定・パン判定」の3つを必ずセットで直す）。 */
    if (this.hitStampNav(p.x, p.y)) return false;
    if (this.hitRotBtn(p.x, p.y)) return false;
    if (this.staggerMode) {
      var sc = this.hitStampCell(p.x, p.y);
      if (sc && this.selection.indexOf(sc.group.id) >= 0) return false;
    }
    /* 🔒 §25-5: 幅矢印の値ラベルの上では地図を動かさない（ラベルを掴んで矢印を運べる）。
     * 🔴 §22-z の記録どおり、ここと描画・pointerdown はセットで直すこと。 */
    if (this.hitArrowLabel(p.x, p.y)) return false;
    /* 🔒 §30-38-2: Alt＋クリックで頂点を足す所では地図を動かさない。
     * 🔴 当たりの太さが hitObject（HIT_PAD）と違う（edgeHandleR）ので、
     *    pointerdown とここをセットで見る（§22-z の教訓）。 */
    if (e && e[VERTEX_KEY] && !e.ctrlKey && this.hitSegment(p.x, p.y)) return false;
    if (this.hitHandle(p.x, p.y)) return false;
    if (this.hitObject(p.x, p.y)) return false;
    return true;
  };
  Editor.prototype._pt = function (e) {
    var r = this.map.el.getBoundingClientRect();
    return { x: e.clientX - r.left, y: e.clientY - r.top };
  };

  Editor.prototype._bindInput = function () {
    var self = this;
    var drag = null;

    this.map.el.addEventListener('pointerdown', function (e) {
      if (e.button !== 0) return;
      self._spaceClick = false;
      /* 🔒 §23-7-b: スペース＝一時パン。**どの道具でも**ここで手を引く
       * （ブラシも多角形も矢印も始めない＝ドラッグの取り合いを起こさない）。
       * 🔴 地図を動かすのは mapview 側（_shouldPan が true を返している）。
       *    preventDefault はしない ―― 従来のパンと同じ振る舞いに揃えるため。 */
      if (self._space) {
        self._spaceDrag = true;
        self._spaceClick = true;   // 直後の click/dblclick を捨てる印
        self._applyCursor();
        return;
      }
      var p = self._pt(e), ll = self.map.unproject(p.x, p.y);
      self._setCtrl(e.ctrlKey);
      var t = self.effectiveTool();

      /* --- 直線: 2クリック --- */
      if (t === 'line') {
        e.preventDefault();
        if (!self.draft) {
          self.draft = { type: 'line', a: ll, b: ll };
          self.render(); self._emit('draft');
        } else { self.draft.b = ll; self._commitLine(); }
        return;
      }

      /* --- 曲線: 2クリックで両端 → 動かして膨らみ → もう1クリックで確定 --- */
      if (t === 'curve') {
        e.preventDefault();
        if (!self.draft) { self.draft = { type: 'curve', a: ll, b: ll, c: ll, stage: 1 }; }
        else if (self.draft.stage === 1) {
          self.draft.b = ll;
          self.draft.c = { lat: (self.draft.a.lat + ll.lat) / 2,
                           lng: (self.draft.a.lng + ll.lng) / 2 };
          self.draft.stage = 2;
        } else { self._commitCurve(); }
        self.render();
        self._emit('draft');
        return;
      }

      /* --- 多角形: クリック追加 / ダブルクリックで閉じる ---
       * 🔒 §30-22-1 4: 主役の多角形（mainpoly）も**点の打ち方は同じ**。
       *    違うのは確定の仕方だけ（Enter で必ず閉じる・§4-5 の唯一の例外）。 */
      if (t === 'polygon' || t === 'mainpoly') {
        e.preventDefault();
        if (!self.draft) self.draft = { type: 'polygon', points: [ll], cursor: ll };
        else self.draft.points.push(ll);
        self.render();
        self._emit('draft');
        return;
      }

      /* --- 幅矢印: ドラッグでも2クリックでも（🔒 §30-22-4 8）---
       * 🔴 2026-09-13 是正: ここで**無条件に draft を作り直していた**ため、
       *    2クリック方式が成立していなかった（2回目の押下で1点目が上書きされ、
       *    続く click は「同じ点」になって長さ 0＝確定しない）。
       *    1点目が置いてある時は a を保ち、この押下は**2点目**として扱う。 */
      if (t === 'arrow') {
        e.preventDefault();
        if (self.draft && self.draft.type === 'arrow') {
          drag = { mode: 'draw-arrow', moved: false, second: true };
          self.draft.b = ll;
        } else {
          drag = { mode: 'draw-arrow', moved: false };
          self.draft = { type: 'arrow', a: ll, b: ll };
        }
        try { self.map.el.setPointerCapture(e.pointerId); } catch (err) {}
        self.render();
        return;
      }

      /* --- 四角: ドラッグ --- */
      if (t === 'rect') {
        e.preventDefault();
        drag = { mode: 'draw-rect' };
        self.draft = { type: 'rect-preview', x0: p.x, y0: p.y, x1: p.x, y1: p.y };
        try { self.map.el.setPointerCapture(e.pointerId); } catch (err) {}
        self.render();
        return;
      }

      /* --- テキスト: クリックで置いてその場入力 --- */
      if (t === 'text') {
        e.preventDefault();
        self._emit('text', { at: ll, obj: null });
        return;
      }

      /* --- 「印を置く」の4種（🔒 §28-5 A / §28-7）: クリックした場所に印を置く ---
       * 中身は既存の「印つき文字」（text ＋ anchor ＋ dotStyle）を**手で置くだけ**。
       * 🔴 先に印を作ってから名前を聞く（req.obj あり）ので、名前を入れなくても
       *    ―― 空のまま Enter でも Esc でも ―― 印は残る（§28-5 A）。
       * 🔒 §30-35-2 1: 名前を聞くかは MARK_TOOL の askName（信号機・バス停だけ）。 */
      if (MARK_TOOL[t]) {
        e.preventDefault();
        self.placeMark(t, ll);
        return;
      }

      /* --- なぞって写す（🔒 §23）: ドラッグで〇が通った下書きを実体化する ---
       * 🔴 中身は reveal.js（曇り下書き層・区間帳簿・重なり判定）。ここは
       *    「ポインタを預ける」だけにして、editor 側に §23 の知識を持ち込まない。
       * 🔴 _shouldPan は select 以外で必ず false を返すので、なぞっている間に
       *    地図がパンすることはない（他の作図道具と同じ扱い）。 */
      if (t === 'reveal') {
        e.preventDefault();
        if (!self.reveal) return;
        drag = { mode: 'reveal' };
        self.reveal.strokeStart(p.x, p.y);
        try { self.map.el.setPointerCapture(e.pointerId); } catch (err) {}
        return;
      }

      /* --- 消しゴム: 1つだけ消す（塊は枠1枚・正典 §4-9） --- */
      if (t === 'eraser') {
        e.preventDefault();
        self._eraseAt(p.x, p.y);
        return;
      }

      /* --- 番号割付（正典 §4-7）。押したまま撫でると連番を振れる --- */
      if (t === 'number') {
        e.preventDefault();
        if (e.altKey) { self._numberAt(p.x, p.y, true); return; }
        drag = { mode: 'number', moved: false, started: false, ox: p.x, oy: p.y };
        try { self.map.el.setPointerCapture(e.pointerId); } catch (err) {}
        return;
      }

      /* --- 保管場所マーク（正典 §16-5 A）。枠をクリックで入り切り --- */
      if (t === 'storage') {
        e.preventDefault();
        self.toggleStorageAt(p.x, p.y);
        return;
      }

      /* --- 来客用・車いす（🔒 §30-22-3 2）。枠をクリックで入り切り --- */
      if (t === 'guest' || t === 'wheel') {
        e.preventDefault();
        if (!self.toggleCellFlagAt(p.x, p.y, t)) {
          self._emit('hint', '駐車枠をクリックしてください（［駐車枠］で置いた枠が対象です）');
        }
        return;
      }

      /* --- 敷地の取り込み（筆界をクリック1回） --- */
      if (t === 'parcel') {
        e.preventDefault();
        var c = self.hitCandidate(p.x, p.y);
        if (c) {
          self.adoptParcel(c);
          self._emit('parcel', c);
        }
        return;
      }

      /* --- 選択 --- */
      if (t !== 'select') return;

      // 図形の脇に出した「複製 / 削除」を最優先で見る
      var act = self.hitAction(p.x, p.y);
      if (act) {
        e.preventDefault();
        if (act === 'duplicate') { self.duplicateSelected(); return; }
        if (act === 'delete') { self.deleteSelected(); return; }
        if (act === 'stagger') {
          // クリックで「階段状にずらすモード」を入り切りする。
          // 有効な間は、枠そのものをドラッグしてずらす。
          self.staggerMode = !self.staggerMode;
          self._emit('stagger', self.staggerMode);
          self.render();
          return;
        }
      }

      /* --- 🔒 §30-38-2: Alt＋クリックで線に頂点を足す・頂点を消す ---
       * ① 頂点の上（つまみの当たり）なら消す
       * ② 線の上なら足して**そのまま掴んだ状態**にする（Photoshop と同じ）
       * ③ どちらにも当たらなければ何もしない＝ふつうのクリックとして下へ落とす */
      if (e[VERTEX_KEY] && !e.ctrlKey) {
        var vh = self.hitHandle(p.x, p.y);
        if (vh && vh.kind === 'vertex') {
          e.preventDefault();
          self.removeVertexAt(vh.obj, vh.index);
          return;
        }
        var sg = self.hitSegment(p.x, p.y);
        if (sg) {
          var add = self.addVertexAt(sg.obj, sg.index,
                                     self.map.unproject(sg.at.x, sg.at.y));
          if (add) {
            e.preventDefault();
            if (self.selection.indexOf(add.obj.id) < 0) {
              self.selection = [add.obj.id];
              self.clearStaggerMode();
            }
            self._emit('select', self.getSelected());
            // 足した頂点をそのまま掴む（指を離した時の処理は既存の vertex の経路）
            drag = { mode: 'vertex', obj: add.obj, index: add.index, moved: false };
            try { self.map.el.setPointerCapture(e.pointerId); } catch (err) {}
            self.render();
            return;
          }
        }
      }

      /* 🔒 §25-7: 塊の四方に出した矢羽＋（＋/−）。押した向きへ1枠ずつ増減する。
       * 🔴 図形そのものより先に見る（矢羽は図形の外に出ているが、
       *    伸びてくると枠と重なる位置に来ることがあるため）。 */
      var nv = self.hitStampNav(p.x, p.y);
      if (nv) {
        e.preventDefault();
        /* 🔒 §25-7 修正1: 押した瞬間の位置でボタンを据え置く（連打で延長）。
         * 🔴 必ず増減の**前**に呼ぶ。塊のデータはこの後すぐ正しく更新される。 */
        self.freezeOverlay(nv.obj);
        self.nudgeStamp(nv.obj, nv.spoke.axis, nv.spoke.dir,
                        nv.act === 'minus', false);
        return;
      }
      /* 🔒 §25-8: 回転の＋／−（0.5°ずつ）。マウスの回転つまみは従来どおり残す */
      var rb = self.hitRotBtn(p.x, p.y);
      if (rb) {
        e.preventDefault();
        self.freezeOverlay(rb.obj);       // 🔒 §25-7 修正1（回転でも的を動かさない）
        self.nudgeRotate(rb.obj, rb.delta, false);
        return;
      }

      /* 🔒 §25-5: 幅矢印の値ラベルは**押して採用する物ではなくなった**（値は常に出ている）。
       * ここでは何もせず、下の hitObject のフォールバックで矢印そのものを掴ませる。 */

      // 階段モード中は、選択中の塊の枠を掴んだらスキューを最優先する。
      // 枠の中心が辺つまみと重なることがあるので、つまみ判定より先に見る。
      if (self.staggerMode) {
        var sc = self.hitStampCell(p.x, p.y);
        // 中央の枠は動かしようがないので掴ませない（端を掴んでもらう）
        if (sc && Math.abs(sc.index - (sc.group.count - 1) / 2) < 0.5) sc = null;
        if (sc && self.selection.indexOf(sc.group.id) >= 0) {
          e.preventDefault();
          self.snapshot();
          drag = { mode: 'stagger', obj: sc.group, ox: p.x, oy: p.y,
                   base: sc.group.stagger_m || 0, moved: false,
                   grip: sc.index };      // 掴んだ枠が指についてくるように
          try { self.map.el.setPointerCapture(e.pointerId); } catch (err) {}
          return;
        }
      }

      var h = self.hitHandle(p.x, p.y);
      /* 🔒 §30-14-5 3: 中心の十字（✥）は「確実に掴める move の的」。
       * 図形の中を掴んだ時（下の hitObject の分岐）と**同じ形の drag** に流す
       * ＝動き方も履歴（snapshot／動かさなければ undo を捨てる）も同じ。
       * 🔴 選択は変えない（十字は選択中の1つにしか出ない）。 */
      if (h && h.kind === 'move') {
        e.preventDefault();
        self.snapshot();
        drag = { mode: 'move', lastX: p.x, lastY: p.y, moved: false };
        try { self.map.el.setPointerCapture(e.pointerId); } catch (err) {}
        return;
      }
      if (h) {
        e.preventDefault();
        self.snapshot();
        drag = { mode: h.kind, obj: h.obj, index: h.index, moved: false };
        /* 🔒 §25-8「最後に触った操作系に矢印キーが付く」。
         * マウスの回転つまみを掴んだ時も“回転を触った”と数える。 */
        if (h.kind === 'rotate') self.arrowMode = 'rotate';
        if (h.kind === 'lbSize') {
          // 掴んだ時の「左上からの距離」を基準に倍率を決める（§18-f 駐車位置ラベル）
          var lg = self.labelBlockGeom(h.obj);
          drag.ox = lg.x; drag.oy = lg.y;
          drag.base = h.obj.scale || 1;
          drag.d0 = Math.max(12, Math.hypot(p.x - lg.x, p.y - lg.y));
        }
        /* 🔒 §30-22-3 3: 文字の大きさ。基準は「文字の中心からの距離」
         * （塊ラベルの lbSize と同じ作法）。値は紙のミリ（sizeMm）。 */
        if (h.kind === 'textSize') {
          var tc = self.map.project(h.obj.at.lat, h.obj.at.lng);
          drag.ox = tc.x; drag.oy = tc.y;
          drag.base = textMmOf(h.obj);
          drag.d0 = Math.max(8, Math.hypot(p.x - tc.x, p.y - tc.y));
        }
        /* 🔒 §30-25-18 3: 印の大きさ。基準は「印の箱の中心からの距離」
         * （文字の textSize とまったく同じ作法）。値は倍率（markScale）。 */
        if (h.kind === 'markSize') {
          /* 🔒 §30-25-40 2〜3: 主役の印（◎・■）も同じつまみ。基準の中心は
           * ◎＝印の箱の中心／■＝四角の中心（markScaleOrigin の1か所）。
           * 値の書き先だけが違う（points[key].mark.scale＝ drag.mainKey で見分ける）。 */
          var mr = self.markScaleOrigin(h.obj);
          drag.ox = mr ? mr.x : p.x; drag.oy = mr ? mr.y : p.y;
          drag.base = mainMarkScaleOf(h.obj);
          drag.d0 = Math.max(8, Math.hypot(p.x - drag.ox, p.y - drag.oy));
          drag.mainKey = mainMarkKeyOf(h.obj);
        }
        try { self.map.el.setPointerCapture(e.pointerId); } catch (err) {}
        return;
      }

      /* 🔒 §25-5: 線そのものを外していても、値ラベルの上なら矢印を掴めるようにする
       * （_shouldPan も同じ判定でパンを止めている＝掴めるのに地図が動く、を防ぐ）。 */
      var o = self.hitObject(p.x, p.y) || self.hitArrowLabel(p.x, p.y);
      if (o) {
        e.preventDefault();
        // Ctrl は「一時的に選択にする」ための修飾なので、
        // 作図中の Ctrl+クリックは追加選択にしない。追加選択は Shift。
        var addMode = e.shiftKey || (e.ctrlKey && self.tool === 'select');
        if (addMode) {
          var at = self.selection.indexOf(o.id);
          if (at >= 0) self.selection.splice(at, 1); else self.selection.push(o.id);
        } else if (self.selection.indexOf(o.id) < 0) {
          self.selection = [o.id];
          self.clearStaggerMode();       // 別の図形に移ったらモードを切る
        }
        self._emit('select', self.getSelected());
        self.snapshot();
        /* 🔒 §30-25-18 2: **印の絵を掴んだ**時は印（anchor）と文字（at）を一緒に
         * 動かす（相対位置が変わらない＝答えも変わらない）。文字の箱を掴んだ時は
         * 今までどおり文字（at）だけ。判定は markHit / textBoxHit の1か所ずつ。 */
        var grabMark = self.markHit(o, p.x, p.y)
                    && !(o.text && self.textBoxHit(o, p.x, p.y));
        drag = { mode: 'move', lastX: p.x, lastY: p.y, moved: false,
                 markId: grabMark ? o.id : null };
        try { self.map.el.setPointerCapture(e.pointerId); } catch (err) {}
        self.render();
        return;
      }

      if (self.selection.length) {
        self.selection = [];
        self.clearStaggerMode();
        self._emit('select', []);
        self.render();
      }
    });

    this.map.el.addEventListener('dblclick', function (e) {
      // 🔒 §23-7-b: スペース一時パンの2度押しは作図操作ではない
      if (self._space || self._spaceClick) return;
      var p = self._pt(e);
      /* 🔒 修正3（2026-08-30）: ±/回転ボタンの上での2度押しは「連打」であって
       * ダブルクリック操作ではない。ボタンの下に文字が隠れていても
       * 再編集の窓を開かない（地図の拡大は mapview.js で全面廃止済み）。 */
      if (self.hitStampNav(p.x, p.y) || self.hitRotBtn(p.x, p.y)) {
        e.preventDefault(); e.stopPropagation();
        return;
      }
      // 多角形を閉じる（正典 §4-5）
      if (self.tool === 'polygon' && self.draft) {
        e.preventDefault(); e.stopPropagation();
        self._commitPolygon();
        return;
      }
      // 🔒 §30-22-1 4: 主役の多角形はダブルクリックでも閉じる（Enter と同じ）
      if (self.tool === 'mainpoly' && self.draft) {
        e.preventDefault(); e.stopPropagation();
        self._commitMainPoly();
        return;
      }
      // テキストを再編集（正典 §4-8）
      if (self.tool === 'select') {
        var o = self.hitObject(p.x, p.y);
        if (o && o.type === 'text') {
          e.preventDefault(); e.stopPropagation();
          self._emit('text', { at: o.at, obj: o });
        }
      }
    });

    this.map.el.addEventListener('pointermove', function (e) {
      var p = self._pt(e), ll = self.map.unproject(p.x, p.y);
      if (!drag) self._setCtrl(e.ctrlKey);

      /* 🔒 §23-7-b: スペース一時パン中は作図を進めない（Ctrl と同じ扱い）。
       * 🔴 ただし drag が既にある＝スペースより先に始めた操作は最後までやらせる
       *    （途中でスペースを押しても手が止まらない）。 */
      if (!drag && (self._space || self._spaceDrag)) return;

      // Ctrl を押している間は作図を進めない（掴む操作に譲る）
      if (!drag && self.draft && self._ctrl) return;
      if (!drag && self.draft) {
        if (self.draft.type === 'line') { self.draft.b = ll; self.render(); return; }
        if (self.draft.type === 'curve') {
          if (self.draft.stage === 1) self.draft.b = ll;
          else self.draft.c = ll;             // 膨らみを決める
          self.render(); return;
        }
        if (self.draft.type === 'polygon') { self.draft.cursor = ll; self.render(); return; }
        /* 🔒 §30-22-4 8: 2クリック待ちの幅矢印も、1点目から指先まで下書きを見せる
         * （直線と同じ見え方。見えないと「1点目が置けたのか」が分からない）。 */
        if (self.draft.type === 'arrow') { self.draft.b = ll; self.render(); return; }
      }
      if (!drag) return;
      e.preventDefault();

      if (drag.mode === 'number') {
        // 少し動いたらドラッグ採番を開始（動かなければクリック扱い）
        if (!drag.started) {
          if (Math.abs(p.x - drag.ox) + Math.abs(p.y - drag.oy) < 4) return;
          drag.started = self.startNumberStroke(drag.ox, drag.oy);
          if (!drag.started) { drag.moved = true; return; }
        }
        drag.moved = true;
        self.extendNumberStroke(p.x, p.y);
        return;
      }
      if (drag.mode === 'reveal') {
        if (self.reveal) self.reveal.strokeMove(p.x, p.y);
        return;
      }
      if (drag.mode === 'draw-rect') {
        self.draft.x1 = p.x; self.draft.y1 = p.y; self.render(); return;
      }
      if (drag.mode === 'draw-arrow') {
        self.draft.b = ll; drag.moved = true; self.render(); return;
      }
      if (drag.mode === 'move') {
        var dx = p.x - drag.lastX, dy = p.y - drag.lastY;
        drag.lastX = p.x; drag.lastY = p.y; drag.moved = true;
        // 🔒 §30-25-18 2: 印を掴んだ物だけ anchor も一緒に動かす
        self._moveSelection(dx, dy, drag.markId);
        return;
      }
      if (drag.mode === 'stagger') { drag.moved = true; self._stagger(drag, p); return; }
      if (drag.mode === 'edge') { self._resizeEdge(drag.obj, drag.index, p); return; }
      if (drag.mode === 'rotate') { self._rotate(drag.obj, p, e.shiftKey); return; }
      if (drag.mode === 'end') {
        if (drag.index === 0) drag.obj.a = ll; else drag.obj.b = ll;
        self.render(); return;
      }
      if (drag.mode === 'ctrl') { drag.obj.c = ll; self.render(); return; }
      if (drag.mode === 'vertex') {
        drag.obj.points[drag.index] = ll; self.render(); return;
      }
      // 塊ラベル: 矢印の終点だけを動かす／右下で大きさを変える（§18-f 駐車位置ラベル）
      if (drag.mode === 'lbArrow') {
        drag.obj.arrowTo = ll; drag.moved = true; self.render(); return;
      }
      /* 🔒 §30-22-3 3: 文字の大きさをドラッグで変える（紙のミリ・連続値）
       * 🔒 §30-25-10 2: 上限・下限は clampTextMm 1か所（プレビューのつまみも同じ） */
      if (drag.mode === 'textSize') {
        var td = Math.hypot(p.x - drag.ox, p.y - drag.oy);
        drag.obj.sizeMm = clampTextMm(drag.base * (td / drag.d0));
        // 🔒 §30-25-28 4: 大きさを変えた主役ラベルも生成で上書きしない
        noteUserMoved(drag.obj);
        drag.moved = true;
        self.render();
        return;
      }
      /* 🔒 §30-25-18 3: 印の大きさをドラッグで変える（倍率・連続値）。
       * 🔴 上限・下限は clampMarkScale 1か所（右パネルのボタンも同じ値を通る）。 */
      if (drag.mode === 'markSize') {
        var md = Math.hypot(p.x - drag.ox, p.y - drag.oy);
        var mv2 = clampMarkScale(drag.base * (md / drag.d0));
        /* 🔒 §30-25-40 2〜3: 主役の印（◎・■）は案件の points[key].mark.scale が
         * 値の出どころ。図形の markScale へ直接書かず app.js の口へ渡す
         * （紙の印・画面のピン・同一住所のもう一方を1か所で引き直す）。
         * 🔴 保存は指を離した時（endDrag）＝ドラッグ中は見た目だけ追う。 */
        if (drag.mainKey && self.onMainMarkScale) {
          self.onMainMarkScale(drag.mainKey, mv2, { obj: drag.obj, done: false });
        } else {
          drag.obj.markScale = mv2;
        }
        drag.moved = true;
        self.render();
        return;
      }
      if (drag.mode === 'lbSize') {
        var dd = Math.hypot(p.x - drag.ox, p.y - drag.oy);
        // 🔒 §30-32-2: 上下限の出どころは clampLabelScale 1か所（プレビューと同じ範囲）
        drag.obj.scale = clampLabelScale(drag.base * (dd / drag.d0));
        drag.moved = true;
        self.render();
        return;
      }
    });

    function endDrag(e) {
      /* 🔒 §23-7-b: スペース一時パンの終わり。
       * 🔴 **ドラッグ中にスペースを離してもパンは最後まで続く**（mapview は
       *    pointerdown の時だけ _shouldPan を見るので、そのまま完走する）。
       *    途中で地図が止まる方が事故なので、掌カーソルを戻すのも「指を離した時」
       *    ＝ここ1か所にする。_spaceClick は直後の click まで残す。 */
      if (self._spaceDrag) { self._spaceDrag = false; self._applyCursor(); }
      if (!drag) return;
      try { self.map.el.releasePointerCapture(e.pointerId); } catch (err) {}
      if (drag.mode === 'number') {
        if (drag.started) self.endNumberStroke();
        else self._numberAt(drag.ox, drag.oy, false);   // 動かなければクリック採番
        drag = null;
        return;
      }
      /* 🔒 §23: なぞり終わり。SVG の組み直しと自動保存はここで1回だけ走る
       * （なぞっている間は reveal.js が canvas に即描きしている）。 */
      if (drag.mode === 'reveal') {
        if (self.reveal) self.reveal.strokeEnd();
        drag = null;
        return;
      }
      if (drag.mode === 'draw-rect') self._commitRectPreview();
      else if (drag.mode === 'draw-arrow') {
        if (drag.moved) self._commitArrow();
        // 動かさなければ2クリック方式の1点目として残す
      } else if (!drag.moved && drag.mode === 'move') {
        self.undoStack.pop();
      } else {
        /* 🔒 §30-22-1 4: 主役の多角形の頂点を掴んで形を直したら、
         * 重心（＝ピン）も動く。指を離した時に1回だけ書き戻す。 */
        if (drag.mode === 'vertex' && isMainMark(drag.obj)) self.syncMarkPin(drag.obj);
        /* 🔒 §30-25-40 2: 主役の印の大きさは**指を離した時**に案件へ保存する
         * （ドラッグ中は見た目だけ追う）。 */
        if (drag.mode === 'markSize' && drag.mainKey && self.onMainMarkScale) {
          self.onMainMarkScale(drag.mainKey, mainMarkScaleOf(drag.obj),
                               { obj: drag.obj, done: true });
        }
        /* 🔒 §30-31-1 2: ■の辺つまみで変えた**縦横**も指を離した時に案件へ保存する
         * （値の出どころは points[key].mark.w_m/h_m＝ app.js の口へ渡す）。
         * 🔒 §30-35-3 3: 掴んだ辺だけ伸びる＝**中心がピンからずれる**ので、
         *    中心（緯度経度）も一緒に渡す。ずれを m に直して
         *    points[key].mark.dx_m/dy_m へ書くのは app.js（setMainMarkDims）。 */
        if (drag.mode === 'edge' && drag.obj && drag.obj.type === 'rect'
            && isMainMark(drag.obj) && self.onMainMarkDims) {
          var dk = mainMarkKeyOf(drag.obj);
          if (dk) self.onMainMarkDims(dk, drag.obj.w_m, drag.obj.h_m, drag.obj.center);
        }
        self._emit('change');
      }
      drag = null;
    }
    this.map.el.addEventListener('pointerup', endDrag);
    this.map.el.addEventListener('pointercancel', endDrag);

    // 2クリック方式の幅矢印（1点目を置いた後の2回目のクリック）
    this.map.el.addEventListener('click', function (e) {
      // 🔒 §23-7-b: スペースで地図を動かしただけ。矢印の2点目にはしない
      if (self._spaceClick) return;
      if (self.tool !== 'arrow' || !self.draft || drag) return;
      var p = self._pt(e);
      self.draft.b = self.map.unproject(p.x, p.y);
      var a = self.map.project(self.draft.a.lat, self.draft.a.lng);
      if (Math.hypot(p.x - a.x, p.y - a.y) >= MIN_PX) self._commitArrow();
    });
  };

  Editor.prototype._bindKeys = function () {
    var self = this;

    /* Ctrl の押し／離しを見張る。押しっぱなしのまま画面から離れても
       戻ってきた時に固まらないよう、blur でも必ず解除する。 */
    window.addEventListener('keydown', function (e) {
      if (e.key === 'Control' || e.ctrlKey) self._setCtrl(true);
    });
    window.addEventListener('keyup', function (e) {
      if (e.key === 'Control' || !e.ctrlKey) self._setCtrl(false);
    });
    window.addEventListener('blur', function () {
      self._setCtrl(false);
      /* 押しっぱなしで画面を離れても固まらない。
       * 🔴 窓の外で指を離すと pointerup が来ない環境があるので、掴んでいる印も
       *    ここで落とす（落とさないと掌を握ったままのカーソルが残る）。 */
      var wasSpace = self._space;
      self._spaceDrag = false;
      self._setSpace(false);
      // 🔴 _setSpace が動いた時は中でカーソルを直している。二度直すと
      //    「押す前の姿」(_cursorBefore) を上書きしてしまうのでここでは触らない。
      if (!wasSpace) self._applyCursor();
    });

    /* 🔒 §23-7-b（2026-08-31 オーナー決定）: **スペースを押している間だけ
     * 左ドラッグで地図をパンできる**（画像編集ソフトの共通作法）。
     * 🔴 なぞり出しに限らず**全ての道具**で同じに効かせる。道具ごとに挙動が
     *    違うのは覚えられない、というのが決定の理由。
     * 🔴 Ctrl/ホイール/中ボタンの従来のパンは**そのまま残す**（増やすだけ）。
     * 🔴 修飾キーとの組み合わせ（Ctrl+Space の IME 切替など）は横取りしない。 */
    window.addEventListener('keydown', function (e) {
      if (!isSpaceKey(e)) return;
      if (e.ctrlKey || e.metaKey || e.altKey) return;
      if (!self._spaceAllowed(e.target)) return;
      // 押しっぱなしでページが下にスクロールするのを止める（連打時も毎回止める）
      e.preventDefault();
      if (e.repeat) return;
      self._setSpace(true);
    });
    /* 🔴 離した時は**条件を見ずに必ず**解除する。押した後に focus が入力欄へ
     *    移った、等で解除を取りこぼすと掌のまま固まるため。 */
    window.addEventListener('keyup', function (e) {
      if (!isSpaceKey(e)) return;
      self._setSpace(false);
    });

    // Ctrl+クリックが右クリック扱いになる環境でメニューを出さない
    this.map.el.addEventListener('contextmenu', function (e) {
      if (self._ctrl) e.preventDefault();
    });

    document.addEventListener('keydown', function (e) {
      if (isTypingTarget(e.target)) return;
      if (!self.map.el.offsetParent) return;

      var ctrl = e.ctrlKey || e.metaKey;
      if (e.key === 'Escape') {
        if (self.draft) { self.draft = null; self.render(); self._emit('draft'); }
        else if (self._numFrom) { self._numFrom = null; self.render(); }
        else if (self.selection.length) {
          self.selection = []; self._emit('select', []); self.render();
        }
        return;
      }
      /* 🔒 §22-ac（2026-08-28 オーナー指示「自動で閉じる機能をなくして。
       * クリックした場を終点とする」）: **既定を入れ替えた**。
       *   Enter       … 閉じずに確定（最後にクリックした点が終点）＝ path
       *   Shift+Enter … 閉じて確定（明示操作なので残す・オーナー指示）＝ polygon
       * 🔴 旧: Enter=閉じて確定 / Shift+Enter=開いたまま確定。
       *    「自動で」閉じるのをやめただけで、閉じる手段そのものは残してある。
       * 「写真から配置図」の外周ステップだけは従来どおり必ず閉じる
       * （polygonMustClose・敷地の外周は閉じていないと図として不自然・オーナー決定）。 */
      /* 🔒 §30-22-1 4（2026-09-13 オーナー指示）: 主役の多角形（mainpoly）だけは
       * **最後の Enter で閉じる**（§4-5「自動で閉じない」の唯一の例外）。
       * 土地の形を囲む道具なので、開いたままでは印にならない。 */
      if (e.key === 'Enter' && self.tool === 'mainpoly' && self.draft) {
        e.preventDefault();
        self._commitMainPoly();
        return;
      }
      if (e.key === 'Enter' && self.tool === 'polygon' && self.draft) {
        e.preventDefault();
        if (self.polygonMustClose) {
          if (!e.shiftKey) self._emit('hint', 'この手順では外周を閉じて確定します');
          self._commitPolygon();
        } else {
          self._commitPolygon({ open: !e.shiftKey });
        }
        return;
      }
      /* 🔒 §25-7/§25-8 矢印キー。取り合いの決着（オーナー決定 2026-08-29）:
       *  ・**最後に触った操作系**に付く（±方向ボタンの後＝増減／回転の後＝回転）
       *  ・**Shift＋矢印は文脈によらず必ず回転**（近道なので文脈自体は変えない）
       *  ・塊以外（四角・主役マーク）は増減が無いので常に回転
       * 🔴 文字入力欄・スライダー・かぶせ物の上では奪わない（arrowsBlocked / keysBusy）。 */
      var ar = ARROW_DIR[e.key];
      if (ar) {
        if (arrowsBlocked(e.target) || arrowsBlocked(document.activeElement)) return;
        if (self.keysBusy && self.keysBusy()) return;
        var one = self.getSelected();
        if (one.length !== 1 || self.tool !== 'select') return;
        var so = one[0];
        var canGrow = (so.type === 'stampGroup');
        var canRot = (so.type === 'rect' || so.type === 'stampGroup');
        if (e.shiftKey || !canGrow || self.arrowMode !== 'grow') {
          if (!canRot) return;
          e.preventDefault();
          var keep = self.arrowMode;
          // 画面の右／上＝時計回り、左／下＝反時計回り
          self.nudgeRotate(so, (ar.x > 0 || ar.y < 0) ? 1 : -1, e.repeat);
          if (e.shiftKey) self.arrowMode = keep;   // 近道は文脈を変えない
          return;
        }
        e.preventDefault();
        self.arrowGrow(so, ar, e.repeat);
        return;
      }
      if (e.key === 'Backspace') {
        // 作図中は「直前のクリックを1つ戻す」（オーナー指示 2026-08-16）
        if (self.canUndoPoint()) {
          e.preventDefault();
          self.undoPoint();
          self._emit('change');
          return;
        }
      }
      if (e.key === 'Delete' || e.key === 'Backspace') {
        if (self.selection.length) { e.preventDefault(); self.deleteSelected(); }
        return;
      }
      if (ctrl && (e.key === 'z' || e.key === 'Z')) {
        e.preventDefault(); if (e.shiftKey) self.redo(); else self.undo(); return;
      }
      if (ctrl && (e.key === 'y' || e.key === 'Y')) { e.preventDefault(); self.redo(); return; }
      if (ctrl && (e.key === 'c' || e.key === 'C')) { self.copySelected(); return; }
      if (ctrl && (e.key === 'v' || e.key === 'V')) { e.preventDefault(); self.paste(); return; }
      if (ctrl && (e.key === 'd' || e.key === 'D')) {
        e.preventDefault(); self.duplicateSelected(); return;
      }
      if (ctrl && (e.key === 'a' || e.key === 'A')) {
        e.preventDefault();
        self.selection = self.objects.map(function (o) { return o.id; });
        self._emit('select', self.getSelected());
        self.render();
      }
    });
  };

  /* ---------- 変形 ---------- */

  /**
   * 🔒 §25-4 / §18-x-5（2026-08-30 オーナー実機報告の修正）:
   * 主役マークの四角を掴んで動かしたら、**動かすのはピンそのもの**。
   * ピン（points.home / points.lot）が唯一の真実で、四角・役割ラベル・結線・
   * 距離ラベルはそこへ追従する（app.js の syncRoleObjects）。四角だけが単独で
   * 地図上をさまよう状態は作らない。
   * app.js が bindEditor で差し込む: function(key, lat, lng) -> ピンを動かせたら true。
   */
  Editor.prototype.movePin = null;

  /**
   * 🔒 §30-24-1: **次に描く多角形の書式**（{width,color,hatch}）。
   * 画面の状態なので案件には保存しない（app.js の state.mainPolyDefault が真実で、
   * bindEditor がここへ写す）。null なら makeMainPoly の既定（標準・黒・斜線あり）。
   */
  Editor.prototype.mainPolyDefault = null;

  /**
   * 🔒 §25-7/§25-8: **矢印キーを取ってはいけない場面**を app.js から教えてもらう口。
   * 文字のその場入力（textInput）・A4プレビュー・提出前チェック・使い方動画などの
   * かぶせ物が出ている間は true を返してもらい、矢印キーに手を出さない。
   * app.js が bindEditor で差し込む: function() -> true なら矢印キーを譲る。
   */
  Editor.prototype.keysBusy = null;

  /**
   * 🔒 §30-32-1: 消しゴムが**その地点の部品**（主役の印・主役の文字）に当たった時の口。
   * app.js が bindEditor で差し込む: function(obj) -> true なら地点ごと消した。
   * （editor は「地点の部品に当たった」と言うだけ。消し方も地点の判定も app.js 側）
   */
  Editor.prototype.onErasePoint = null;

  /**
   * @param markId 🔒 §30-25-18 2: 「印の絵を掴んだ」図形の id（無ければ null）。
   *   その1つだけは印（anchor）と文字（at）を**一緒に**動かす（相対位置を保つ＝
   *   引き出し線の答えも変わらないので `lead` の印も捨てない）。
   */
  Editor.prototype._moveSelection = function (dx, dy, markId) {
    var self = this;
    function mv(p) {
      var s = self.map.project(p.lat, p.lng);
      var n = self.map.unproject(s.x + dx, s.y + dy);
      p.lat = n.lat; p.lng = n.lng;
    }
    this.getSelected().forEach(function (o) {
      /* ① 主役マーク＝ピンの分身。ピンを動かして一式（線・ラベル・距離）を連れて行く。
       *    ピンが無い案件（消した後など）だけは、ふつうの四角として動かす。 */
      /* 🔒 §30-35-3 6: ■がピンからずれている（辺つまみで掴んだ辺だけ伸ばした）時も
       * 動きは従来のまま＝**■がカーソルに付いてきて、ピンも同じだけ動く**。
       * 渡すのは■の新しい中心で、ずれを引いてピンの位置に直すのは app.js 側
       * （ずれの真実は案件にあるので editor は m を持たない）。 */
      if (isMainMark(o) && o.center && self.movePin) {
        var s0 = self.map.project(o.center.lat, o.center.lng);
        var n0 = self.map.unproject(s0.x + dx, s0.y + dy);
        if (self.movePin(o.markRole === 'lot' ? 'lot' : 'home', n0.lat, n0.lng,
                         { fromMark: true })) return;
      }
      /* 🔒 §30-22-1 4: 主役の**多角形**は形を持つので、点は自分で動かしてから
       * 重心をピンへ書き戻す（ピンが動けば結線・距離・名前が追従する）。 */
      if (isMainMark(o) && o.points) {
        o.points.forEach(mv);
        self.syncMarkPin(o);
        return;
      }
      /* ② 結線の破線は**両端がピンそのもの**（syncRoleObjects が毎回引き直す）。
       *    単独で動かすと図とピンが食い違うだけなので掴んでも動かさない。 */
      if (o.role === 'distance' && o.type === 'line') return;
      /* 🔒 §22-am-6-2: 引き出し線を「描く／描かない」の印（lead）は、生成した時の
       * 位置に対する答え。**人が文字を掴んで動かしたら答えが変わる**ので印を捨てて、
       * 従来の距離しきい値に戻す（●から離せば線が出る・寄せれば消える）。
       * 🔒 §30-24-5: `noLead`（同一住所の間は線を出さない印）はここでは消さない
       *    ＝同一住所の間はどこへ動かしても線が出ない。 */
      /* 🔒 §30-25-18 2: 印を掴んだ物は印と文字を一緒に運ぶ（相対位置が変わらない
       * ＝引き出し線を描くかどうかの答えも変わらないので `lead` は捨てない）。 */
      if (markId && o.id === markId && keepsMark(o)) {
        mv(o.anchor); mv(o.at);
        return;
      }
      /* 🔒 §30-25-28 4: 手で動かした主役ラベルは、次の生成（③の作り直し）で
       * 位置を上書きされない。印は**ここでは付かない**（ピンのドラッグに追従した
       * 時＝ syncRoleObjects はこの関数を通らないので、人が掴んだ時だけ付く）。 */
      noteUserMoved(o);
      if (o.type === 'text' && o.anchor && 'lead' in o) delete o.lead;
      if (o.center) mv(o.center);
      if (o.origin) mv(o.origin);
      if (o.at) mv(o.at);
      if (o.a) mv(o.a);
      if (o.b) mv(o.b);
      if (o.c) mv(o.c);
      if (o.points) o.points.forEach(mv);
    });
    this.render();
  };

  /** 辺つまみで伸縮。掴んだ辺だけ動き、反対の辺は固定する。
   *  掴んだ辺のローカル座標を X、固定側の辺を F とすると
   *    新しい辺の長さ = |X - F| ／ 中心は (X + F) / 2 へ動く。 */
  Editor.prototype._resizeEdge = function (o, edge, p) {
    var isStamp = (o.type === 'stampGroup');
    var geo = isStamp ? this.stampGeom(o) : this.rectHalf(o);
    var loc = this.toLocal(o, p.x, p.y);

    /* 🔒 §30-35-3 1（2026-09-15 オーナー指示「右を伸ばすと左も伸びてしまう。
     * 対はやめて、1つずつ、掴んだ辺だけ伸びるように」）: 主役マークも**ふつうの
     * 四角と同じ**経路で伸縮する（掴んだ辺だけ動き、反対の辺は固定＝中心はピンから
     * ずれる）。§25-4 / §30-31-1 1 の「中心＝ピンに固定（鏡で伸ばす）」は廃止。
     * 🔴 ずれ（中心 − ピン）は指を離した時に endDrag → onMainMarkDims が
     *    案件（points[key].mark.dx_m/dy_m）へ書く＝ドラッグ中は図形の値で見た目を追う。
     * 🔴 右パネルの幅／奥行の欄は従来どおり中心を動かさない（§30-35-3 3）。 */
    var ca = Math.cos(rad(o.angle || 0)), sa = Math.sin(rad(o.angle || 0));
    var anchor = o.center || o.origin;
    var c = this.map.project(anchor.lat, anchor.lng);
    var nx = 0, ny = 0, span;

    if (edge === 1 || edge === 3) {
      var fx = (edge === 1) ? -geo.hw : geo.hw;
      var x = loc.x;
      x = (edge === 1) ? Math.max(x, fx + MIN_PX) : Math.min(x, fx - MIN_PX);
      span = Math.abs(x - fx) * geo.mpp;
      // 塊は枠数を保ったまま各枠が等分に追従する（正典 §4-4「全体伸縮」）。
      // 階段状にずらしている分は枠の大きさではないので差し引く。
      if (isStamp) {
        var sx = geo.col ? geo.span * geo.mpp : 0;
        o.cell_w_m = geo.col ? Math.max(0.3, span - sx) : span / o.count;
      } else o.w_m = span;
      var dx = (x + fx) / 2;
      nx = dx * ca; ny = dx * sa;
    } else {
      var fy = (edge === 2) ? -geo.hh : geo.hh;
      var y = loc.y;
      y = (edge === 2) ? Math.max(y, fy + MIN_PX) : Math.min(y, fy - MIN_PX);
      span = Math.abs(y - fy) * geo.mpp;
      if (isStamp) {
        var sy = geo.col ? 0 : geo.span * geo.mpp;
        o.cell_h_m = geo.col ? span / o.count : Math.max(0.3, span - sy);
      } else o.h_m = span;
      var dy = (y + fy) / 2;
      nx = -dy * sa; ny = dy * ca;
    }
    var np = this.map.unproject(c.x + nx, c.y + ny);
    anchor.lat = np.lat; anchor.lng = np.lng;
    this.render();
  };

  /**
   * 階段状のずらし。並ぶ向きと直角の方向へ動かした分を、
   * 「最後の枠がその分ずれる」量として配る（1枠あたり = 全体 / (枠数-1)）。
   * ＝ 5枠なら、5枠目を上へ動かした距離がそのまま見た目になる。
   */
  Editor.prototype._stagger = function (drag, p) {
    var g = drag.obj;
    if (!g || g.count < 2) return;
    var geo = this.stampGeom(g);
    var a = -rad(g.angle || 0);
    var dx = p.x - drag.ox, dy = p.y - drag.oy;
    // 図形の向きに合わせた座標へ（回転していても直感どおりに動く）
    var lx = dx * Math.cos(a) - dy * Math.sin(a);
    var ly = dx * Math.sin(a) + dy * Math.cos(a);
    var perp = geo.col ? lx : ly;          // 並びと直角の成分

    // 掴んだ枠がその距離だけ動くように配る。
    // 枠 i のずれは (i - (count-1)/2) * stagger なので、その係数で割る。
    // 中央の枠は係数が 0＝どうずらしても動かないので掴めないようにしてある。
    var k = (drag.grip != null) ? (drag.grip - (g.count - 1) / 2) : (g.count - 1);
    if (Math.abs(k) < 0.5) return;
    g.stagger_m = drag.base + (perp * geo.mpp) / k;
    this.render();
  };

  Editor.prototype._rotate = function (o, p, snap) {
    var anchor = o.center || o.origin;
    var c = this.map.project(anchor.lat, anchor.lng);
    var a = Math.atan2(p.y - c.y, p.x - c.x) * 180 / Math.PI + 90;
    if (snap) a = Math.round(a / 15) * 15;
    o.angle = ((a % 360) + 360) % 360;
    this.render();
  };

  /* ---------- 作図の確定 ---------- */

  Editor.prototype._pushNew = function (o) {
    this.snapshot();
    this.objects.push(o);
    this.selection = [o.id];
    this.commit();
    this._emit('select', this.getSelected());
    this._emit('draft');
  };

  Editor.prototype._tooShort = function (a, b) {
    var pa = this.map.project(a.lat, a.lng), pb = this.map.project(b.lat, b.lng);
    return Math.hypot(pb.x - pa.x, pb.y - pa.y) < MIN_PX;
  };

  Editor.prototype._commitLine = function () {
    var d = this.draft; this.draft = null;
    if (!d || this._tooShort(d.a, d.b)) { this.render(); return; }
    this._pushNew({ id: uid(), type: 'line', a: d.a, b: d.b,
                    style: { w: 2, color: '#111' } });
  };

  Editor.prototype._commitCurve = function () {
    var d = this.draft; this.draft = null;
    if (!d || this._tooShort(d.a, d.b)) { this.render(); return; }
    this._pushNew({ id: uid(), type: 'curve', a: d.a, b: d.b, c: d.c,
                    style: { w: 2, color: '#111' } });
  };

  /**
   * 多角形の確定（正典 §4-5・🔒2026-08-18／🔒 §22-ac 2026-08-28）。
   *   opts.open … 閉じずに確定＝開いた折れ線（path）。**Enter の既定はこちら**
   *               （クリックした場が終点・塀・擁壁・境界線・道路の縁など）
   *   省略時   … 閉じて確定（polygon）。Shift+Enter と外周ステップから来る
   * 🔴 呼び出し側の既定が §22-ac で入れ替わっている（ここの引数の意味は変えていない）。
   * 点が足りない時は**確定せずに作図を続ける**（勝手に捨てない・案内を出す）。
   */
  Editor.prototype._commitPolygon = function (opts) {
    var d = this.draft;
    if (!d) return false;
    var open = !!(opts && opts.open);
    var need = open ? 2 : 3;
    if (d.points.length < need) {
      this._emit('hint', open
        ? '線にするには点が2つ以上必要です。クリックで点を足してください'
        : '囲むには頂点が3つ以上必要です。クリックで頂点を足してください');
      this.render();
      return false;
    }
    this.draft = null;
    this._pushNew(open
      ? { id: uid(), type: 'path', points: d.points, closed: false,
          style: { w: 2, color: '#111' } }
      : { id: uid(), type: 'polygon', points: d.points,
          style: { w: 2, color: '#111' } });
    return true;
  };

  /**
   * 🔒 §30-22-1 4（2026-09-13 オーナー指示）: **主役の多角形**を確定する。
   * 既存の四角の主役マーク（§25-4 role:'mainmark' の rect）と**同じ役目**で、
   * 形だけが多角形になった物（結線・距離はピン＝多角形の重心から）。
   * 🔴 この道具だけが「閉じて確定」＝ §4-5 の例外（Enter・ダブルクリック）。
   * 🔴 ピンは案件が持つ唯一の真実なので、置いた時点で movePin で重心へ動かす。
   */
  Editor.prototype._commitMainPoly = function () {
    var d = this.draft;
    if (!d) return false;
    if (d.points.length < 3) {
      this._emit('hint', '囲むには頂点が3つ以上必要です。クリックで頂点を足してください');
      this.render();
      return false;
    }
    this.draft = null;
    var key = (this.mainPolyKey === 'lot') ? 'lot' : 'home';
    /* 🔒 §30-24-1: 書式（太さ・色・斜線）は「次に描く多角形の既定」。
     * 出どころは app.js の state.mainPolyDefault（画面の状態）1か所で、
     * bindEditor がこの口へ差し込む。無ければ makeMainPoly の既定（標準・黒・斜線あり）。 */
    var o = Editor.makeMainPoly(key, d.points, this.mainPolyDefault || null);
    /* 🔴 取り除きも含めて**1回の操作**にする（先に控えを取ってから消す＝
     *    ［戻す］1回で「消した印」ごと元に戻る）。 */
    this.snapshot();
    /* 🔒 §30-24-1（2026-09-13 オーナー指示）: 多角形は**同じ役目にいくつでも**
     * （建物と土地など）。ここで取り除くのは◎／■の印（rect）だけ＝
     * 「この地点の印の種類を多角形にした」という意味。先に描いた多角形は消さない。
     * 🔴 配列は差し替えず splice だけ（§23-7-1 / §26-2 注意①）。 */
    var had = 0, maxOrder = 0;
    for (var i = this.objects.length - 1; i >= 0; i--) {
      var x = this.objects[i];
      if (!isMainMark(x) || (x.markRole || 'home') !== key) continue;
      if (x.type !== 'polygon') { this.objects.splice(i, 1); continue; }
      had++;
      if ((x.mainPolyOrder || 0) > maxOrder) maxOrder = x.mainPolyOrder || 0;
    }
    o.mainPolyOrder = maxOrder + 1;       // 描いた順（ピンを持つのは一番小さい物）
    this.objects.push(o);
    this.selection = [o.id];
    this.commit();
    this._emit('draft');
    /* 🔒 §30-24-1: ピン＝**最初に描いた多角形**の重心。
     * 2つ目以降を足してもピン（＝結線・距離・名前の基準）は動かさない。 */
    if (!had) this.syncMarkPin(o);
    /* 🔒 §30-15-6: 置いたら選択道具へ戻す（置いた物は選ばれたまま＝そのまま直せる） */
    if (this.tool !== 'select') this.setTool('select');
    this.selection = [o.id];
    this._emit('select', this.getSelected());
    /* 🔒 §30-24-1: 印の種類が「多角形」になったことを案件へ伝える
     * （points[key].mark.shape='polygon'。◎■を描かなくする・app.js が受ける）。 */
    this._emit('mainpoly', { key: key, id: o.id });
    this.render();
    return true;
  };

  /**
   * 🔒 §30-22-1 4: 主役の多角形の重心をピンへ書き戻す（movePin）。
   * 多角形ごと動かした時・頂点を掴んで形を直した時に呼ぶ。
   */
  Editor.prototype.syncMarkPin = function (o) {
    if (!isMainMark(o) || !o.points || !o.points.length || !this.movePin) return false;
    /* 🔒 §30-24-1: ピンを持つのは**最初に描いた多角形**だけ。
     * 後から足した多角形を動かしてもピン（結線・距離・名前の基準）は動かない。 */
    if (!this.isPrimaryMainPoly(o)) return false;
    var c = polyCentroid(o.points);
    if (!c) return false;
    return !!this.movePin(o.markRole === 'lot' ? 'lot' : 'home', c.lat, c.lng);
  };

  /** 🔒 §30-24-1: この多角形がその地点の「最初に描いた物」か（＝ピンを持つ物か） */
  Editor.prototype.isPrimaryMainPoly = function (o) {
    if (!isMainMark(o) || o.type !== 'polygon') return false;
    var list = mainPolysOf(this.objects, o.markRole === 'lot' ? 'lot' : 'home');
    return !!list.length && list[0] === o;
  };

  Editor.prototype.applyMainPolyProps = function (o, props) {
    if (!o) return;
    this.snapshot();
    o.style = o.style || {};
    if (props.width) { o.widthKey = props.width; o.style.w = polyW(props.width); }
    if (props.color) { o.inkColor = props.color; o.style.color = inkHex(props.color); }
    if (props.hatch !== undefined) o.hatch = !!props.hatch;
    this.commit();
  };

  Editor.prototype._commitArrow = function () {
    var d = this.draft; this.draft = null;
    if (!d || this._tooShort(d.a, d.b)) { this.render(); return; }
    /* ツールバーに値があれば**手入力のラベル付き**で置く。
     * 🔒 §25-5: 空欄なら label:null のまま置き、描画側が地図から計算した実距離を出す。
     * 🔒 §30-29-4 2: ただし「幅を入力」を選んでいる時（arrowManual）は、欄が空でも
     *    自動の値に落とさない＝`noAuto:true` を付けて**何も出さない**。
     *    🔴 判定は arrowManual と欄の値だけ（表示文字では分岐しない）。 */
    var w = String(this.arrowWidth || '').trim();
    var label = w ? (/m$/.test(w) ? w : w + 'm') : null;
    var o = { id: uid(), type: 'arrow', a: d.a, b: d.b, label: label,
              style: { w: 2, color: '#111' } };
    if (this.arrowManual) o.noAuto = true;
    this._pushNew(o);
  };

  Editor.prototype._commitRectPreview = function () {
    var d = this.draft; this.draft = null;
    if (!d) { this.render(); return; }
    var w = Math.abs(d.x1 - d.x0), h = Math.abs(d.y1 - d.y0);
    if (w < MIN_PX || h < MIN_PX) { this.render(); return; }
    var center = this.map.unproject((d.x0 + d.x1) / 2, (d.y0 + d.y1) / 2);
    var mpp = this.map.metersPerPixel(center.lat);
    this._pushNew({ id: uid(), type: 'rect', center: center,
                    w_m: w * mpp, h_m: h * mpp, angle: 0,
                    labelOverride: null, number: null,
                    /* 🔒 v4（正典 §16-10-d-4）: 新しく描いた図形に寸法は入れない。
                     * 出るのは (a)「表示」欄への手入力 (b) 選んで［寸法(m)を図に出す］だけ。
                     * 既存データは showDims を持っているのでそのまま（!==false の判定は不変）。 */
                    showDims: false,
                    style: { w: 2, color: '#111' } });
  };

  /**
   * 🔒 §30-15-3: 印（信号機・バス停）の箱。文字・入力欄を右隣に置くために読む。
   * 🔴 寸法の出どころは signalGeom / busStopGeom の**1か所**（描画と同じ表）。
   * @return {x, xl, y, hw, dy} x=印の右端の画面x／xl=印の左端の画面x／
   *   y=印の縦の中心の画面y／hw=印の半幅(px)／dy=anchor から縦の中心までのずれ
   *   (px・下が＋)。信号機は anchor が矩形の中心なので dy=0、バス停は anchor が
   *   足の接地点で板が上に伸びるので dy=−(ポール長＋板の高さの半分)。
   *   印つきでなければ null
   */
  Editor.prototype.markBox = function (o) {
    if (!keepsMark(o)) return null;
    // 🔒 §30-30-1: 印の大きさは基準（markBasePx）× markScale＝文字に連動しない
    var g = markGeom(o, Math.max(6, this.textPx(o)), this.markBasePx());
    var a = this.map.project(o.anchor.lat, o.anchor.lng);
    return { x: a.x + g.hw, xl: a.x - g.hw, y: a.y + g.dy, hw: g.hw, dy: g.dy };
  };

  /**
   * 🔒 §30-15-3: 印つき文字の「まだ動かしていない時の置き場所」。
   * 入力欄（app.js）と確定した文字（commitText）が同じ場所を指すための1か所。
   * 🔴 既に動かした文字（at ≠ anchor）・印つきでない文字は null ＝置き場所を触らない。
   * @return {x, xl, y, hw, dy, gap} x=右隣に出す時の左端の画面x／
   *   xl=左隣に出す時の**右端**の画面x（🔒 §30-15-5 規則3）／y=縦の中心の画面y
   */
  /* 🔒 §30-25-7: 印と文字の隙間（画面px）。文字の大きさに比例させる
   * （markTextOffset の既定の隙間と同じ規則＝出どころは MARK_TEXT_GAP_MM 1つ）。 */
  Editor.prototype.markGapPx = function (o) {
    return Math.max(MARK_TEXT_GAP_MIN, Math.max(6, this.textPx(o)) * MARK_TEXT_GAP_MM);
  };

  /**
   * 🔒 §30-25-28: 主役ラベル（使用の本拠・駐車場）の**印の半幅**（画面px）。
   * ■（四角の印）は別図形で実寸（w_m）なので markGeom の比例値では出せない。
   * 🔴 実寸の控えは `o.mark`（生成 shozaizu.js ／ applyMarkChoice ／ ensureMainLabels
   *    が同じ値を入れる）1か所。所在図の「名前の位置＝近く」（shozaizu.js markHalfW）
   *    と同じ考え方で、こちらは画面px 版。
   * @return px。主役ラベルでない・実寸の控えが無ければ undefined（markGeom に任せる）
   */
  Editor.prototype.mainMarkHwPx = function (o) {
    if (!o || o.role !== 'pinlabel' || !o.anchor || !o.mark) return undefined;
    var w = Number(o.mark.w_m);
    if (!(w > 0)) return undefined;
    var mpp = this.map.metersPerPixel(o.anchor.lat);
    return (mpp > 0) ? (w / mpp) / 2 : undefined;
  };

  /**
   * 🔒 §30-35-4 3: 主役ラベルの文字を置く**基準の点**（緯度経度）。
   * ■（主役の四角）は辺つまみでピンからずらせる（§30-35-3・控えは o.mark の
   * dx_m/dy_m＝東＋・北＋）ので、文字は**■の実際の縁**の外へ置く:
   *   右隣の左端＝ピン＋dx＋w/2＋隙間／左隣の右端＝ピン＋dx−w/2−隙間／
   *   上下の中心＝ピン＋dy
   * ＝ 基準の点をピンから■の中心へ移せば、あとの規則（半幅＋隙間＋文字の半幅）は
   *    従来のまま同じ式で解ける。
   * 🔴 m ⇄ 緯度経度の換算は offsetLatLng（§30-35-3 4 の1か所）を使う。
   * 🔴 ◎・印つき文字（ずれを持たない物）は anchor のまま＝規則は従来どおり。
   */
  Editor.prototype.markBaseLL = function (o) {
    if (!o || !o.anchor) return null;
    var m = (o.role === 'pinlabel') ? o.mark : null;
    var dx = (m && isFinite(Number(m.dx_m))) ? Number(m.dx_m) : 0;
    var dy = (m && isFinite(Number(m.dy_m))) ? Number(m.dy_m) : 0;
    return (dx || dy) ? offsetLatLng(o.anchor, dx, dy) : o.anchor;
  };

  Editor.prototype.markSlot = function (o) {
    if (!keepsMark(o) || !sameLL(o.at, o.anchor)) return null;
    var b = this.markBox(o);
    if (!b) return null;
    var gp = this.markGapPx(o);
    return { x: b.x + gp, xl: b.xl - gp,
             y: b.y, hw: b.hw, dy: b.dy, gap: gp };
  };

  /**
   * 🔒 §30-15-5 規則2: **印つき文字を印の隣へ置いた時の緯度経度**（A の1関数）。
   * ここが §30-15（名付け）と §30-16（重ねた名前を図に入れる）の**唯一の置き場所**。
   *
   * 枠が決まっている紙では**紙の物差し**で解く（名付けた時のズームに依らない）:
   *   ずれ(mm) ＝ 印の半幅 ＋ 文字高×0.4 ＋ 文字の半幅   … 全部「紙のミリ」
   *   ずれ(m)  ＝ ずれ(mm) × 縮尺N ÷ 1000                （紙1mm ＝ 実寸 N mm）
   * 枠が未定の紙では従来どおり画面px（枠を決めてから名付けるのが普通の流れ）。
   *
   * 🔴 幅は「画面pxで測って mm へ比例配分」する。寸法は全部 size に比例するので
   *    結果は同じで、極小フォント（4.7px 相当）で measureText を呼ばずに済む。
   * @param o     印つき文字（anchor・dotStyle・size を読む）
   * @param text  確定する文字（幅を測る対象。o.text はまだ更新していなくてよい）
   * @param side  'left' なら印の左隣（§30-15-5 規則3）。既定は右隣
   * @return {lat, lng}。印つきでなければ null
   */
  Editor.prototype.markTextAt = function (o, text, side) {
    if (!sitsByMark(o)) return null;
    var sizePx = Math.max(6, this.textPx(o));
    // 文字の半幅は引き出し線（§22-am-6-2）と同じ測り方＝ drawHalfWidth
    var half = drawHalfWidth({ text: text || '', badge: o.badge }, sizePx);
    /* 🔒 §30-25-28: 主役の■（四角の印）は別図形の**実寸**なので markGeom では
     * 出ない。実寸の控え（o.mark）から半幅を作って渡す（無ければ markGeom に任せる）。 */
    var mhw = this.mainMarkHwPx(o);
    /* 🔒 §30-35-4 3: ずれた■の横の文字は**■の実際の縁**が基準（markBaseLL） */
    var base = this.markBaseLL(o);
    var mm = sheetTextMm(o);
    var N = this.paperScaleN();
    if (mm > 0 && N > 0) {
      /* 隙間は紙の物差し（size × MARK_TEXT_GAP_MM）。全部 size に比例するので
       * 画面px で解いてから k 倍しても紙mm で解いたのと同じ値になる。 */
      // 🔒 §30-30-1: 印の半幅は基準（markBasePx）から＝文字の大きさに連動しない
      var op = markTextOffset(o, sizePx, half, undefined, mhw, this.markBasePx());
      var k = mm / sizePx;                       // 画面px → 紙mm（全部 size に比例）
      var mPerMm = N / 1000;                     // 紙 1mm ＝ 実寸 何 m か
      var dxM = op.dx * k * mPerMm;
      var dyM = op.dy * k * mPerMm;
      return offsetLL(base, (side === 'left') ? -dxM : dxM, dyM);
    }
    var os = markTextOffset(o, sizePx, half, this.markGapPx(o), mhw, this.markBasePx());
    var a0 = this.map.project(base.lat, base.lng);
    var ll = this.map.unproject(a0.x + ((side === 'left') ? -os.dx : os.dx), a0.y + os.dy);
    return { lat: ll.lat, lng: ll.lng };
  };

  /**
   * 🔒 §30-15-5 規則3: 右隣に置くと**地図の右端からはみ出す**か（はみ出すなら左隣）。
   * 🔴 入力欄（app.js）は器の実寸で同じ判定をする。ここは**文字そのもの**の判定で、
   *    §30-16（入力欄を出さずに図へ入れる）が使う。
   */
  Editor.prototype.markSide = function (o, text) {
    // 🔒 §30-25-28: 主役ラベルも同じ判定（sitsByMark）で右隣／左隣を決める
    if (!sitsByMark(o) || !this.map.size) return 'right';
    var s = this.map.size();
    if (!s || !(s.w > 0)) return 'right';
    /* 🔴 実際に置く場所（markTextAt）をそのまま測る。文字の幅だけで測ると、
     *    紙基準の置き場所（ズームで画面上の距離が変わる）とずれる。 */
    var half = drawHalfWidth({ text: text || '', badge: o.badge },
                             Math.max(6, this.textPx(o)));
    var pr = this.markTextAt(o, text, 'right');
    var r = pr ? this.map.project(pr.lat, pr.lng) : null;
    if (r && r.x + half <= s.w - 4) return 'right';
    var pl = this.markTextAt(o, text, 'left');
    var l = pl ? this.map.project(pl.lat, pl.lng) : null;
    if (l && l.x - half >= 4) return 'left';
    // どちらもはみ出す＝広い方（はみ出しが少ない方）へ
    return (l && r && (l.x - half) * -1 < (r.x + half) - s.w) ? 'left' : 'right';
  };

  /**
   * 印の半幅と縦の中心のずれ。**単位は size と同じ**（画面px でも紙mm でも実距離m でも
   * 同じ比で解ける＝寸法が全部 size に比例するため）。
   * 🔒 §30-22-10: 所在図（shozaizu.js）も Editor.markGeom でここを読む＝印の形の
   *    出どころは _drawText と同じこの1か所（signalGeom / busStopGeom / parkingGeom / DOT_R）。
   * 🔴 dy は**画面と同じ y 下向き**（メートル座標で使う側が符号を返す）。
   * 🔴 四角の印（dotStyle:'none'）は別オブジェクト（role:'mainmark' の rect）が
   *    担うので hw は 0 ＝呼ぶ側が実寸（w_m）から出す。
   * @return {hw, dy}
   */
  function markGeom(o, size, basePx) {
    if (!o) return { hw: 0, dy: 0 };
    /* 🔒 §30-25-18 3 / §30-30-1: 印の大きさ＝**基準（固定）× markScale**。
     * ここで出すので、印の半幅を読む全部（文字の置き場所 markTextOffset /
     * markSlot / markTextAt・所在図の置き場所 shozaizu.js）が同じ値になる。
     * 🔴 ふつうの●だけは印ではないので**文字の大きさのまま**（§30-30-1 2 の対象外）。 */
    var ms = markSizeOf(o, size, basePx);
    if (o.dotStyle === 'signal') {
      return { hw: signalGeom(ms).w / 2, dy: 0 };
    }
    // 🔒 §30-22-3 2: P マークは anchor が箱の中心（信号機と同じ）
    if (o.dotStyle === 'parking') {
      return { hw: parkingGeom(ms).s / 2, dy: 0 };
    }
    if (o.dotStyle === 'bus') {
      var bg = busStopGeom(ms);
      // 板より足（逆さT字）の方が広いので広い方を半幅にする（文字が足に触れない）
      return { hw: Math.max(bg.bw, bg.foot) / 2,
               dy: -(bg.pole + bg.bh / 2) };     // 板の中心の高さ
    }
    /* 🔒 §30-25-9: 木は anchor が幹の下端。半幅＝樹冠の外接の半幅、縦の中心＝樹冠の中心
     * （名前は P マークと同じ規則で右隣＝ markTextOffset がこの値で置く）。 */
    if (o.dotStyle === 'tree') {
      var tg = treeGeom(ms);
      return { hw: tg.hw, dy: tg.cy };
    }
    if (o.dotStyle === 'none') return { hw: 0, dy: 0 };
    /* ◎（自宅・駐車場）は●の2倍（_drawText の rr = r0 * 2）。
     * 🔴 ここは下限（DOT_MIN_PX）を掛けない＝所在図が実距離m で呼んでも壊れない
     *    （画面の半径そのものは mainRingR 1か所）。 */
    if (o.dotStyle === 'double' || o.role === 'pinlabel') {
      return { hw: ms * DOT_R * 2, dy: 0 };
    }
    return { hw: size * DOT_R, dy: 0 };          // ふつうの●（文字の大きさに比例）
  }

  /**
   * 🔒 §30-25-18 2: **印の絵の外接する箱**（掴む・消す・つまみを置くための1か所）。
   * markGeom は「半幅と文字を置く高さ」なので、箱の高さ（hh）と箱の中心（dy）は
   * ここで別に出す。単位は size と同じ（画面px）。
   * 🔴 形の出どころは描画と同じ signalGeom / busStopGeom / parkingGeom / treeGeom。
   * @return {hw, hh, dy} dy＝ anchor から箱の中心までのずれ（y 下向き）
   */
  function markBoxGeom(o, size, basePx) {
    /* 🔒 §30-25-40 2: 主役の◎も箱を出す（＝右下につまみが載る）。
     * 🔴 半径の出どころは mainRingR 1か所（描画 _drawText と同じ式）。
     *    ■（主役の四角）は別図形なのでここには来ない（_drawRect の角に出す）。 */
    if (isMainRing(o)) {
      var rr = mainRingR(o, size, basePx);
      return { hw: rr, hh: rr, dy: 0 };
    }
    if (!keepsMark(o)) return null;
    var s = markSizeOf(o, size, basePx);
    if (o.dotStyle === 'signal') {
      var sg = signalGeom(s);
      return { hw: sg.w / 2, hh: sg.h / 2, dy: 0 };
    }
    if (o.dotStyle === 'parking') {
      var pk = parkingGeom(s);
      return { hw: pk.s / 2, hh: pk.s / 2, dy: 0 };
    }
    if (o.dotStyle === 'tree') {
      /* 幹の下端が anchor＝上へだけ伸びる。
       * 🔒 §30-30-2: 箱は**樹冠の外接**（もこもこの一番外側）で取る。 */
      var tg = treeGeom(s);
      return { hw: tg.hw, hh: tg.h / 2, dy: -tg.h / 2 };
    }
    var bg = busStopGeom(s);       // 足の接地点が anchor＝上へだけ伸びる
    return { hw: Math.max(bg.bw, bg.foot) / 2, hh: bg.h / 2, dy: -bg.h / 2 };
  }

  /**
   * 🔒 §30-15-3／§30-22-10: 印つき文字を「印のすぐ隣」へ置く時の、anchor からの
   * ずれ（**単位は size と同じ**）。印の半幅 ＋ 隙間 ＋ 文字の半幅。
   * ここが §30-15（名付け）・§30-16（重ねた名前を図に入れる）・
   * §30-22-10（所在図の「名前の位置＝近く」）の**唯一の規則**。
   * @param halfW  文字の半幅（size と同じ単位）
   * @param gap    隙間。省略（null）なら size × MARK_TEXT_GAP_MM（紙の物差し）
   * @param markHw 印の半幅を外から与える（四角の印など・省略なら markGeom）
   * @return {dx, dy}（dx は右隣。左隣は呼ぶ側で符号を返す。dy は y 下向き）
   */
  function markTextOffset(o, size, halfW, gap, markHw, basePx) {
    var g = markGeom(o, size, basePx);
    var hw = (typeof markHw === 'number' && markHw >= 0) ? markHw : g.hw;
    var gp = (typeof gap === 'number' && isFinite(gap)) ? gap : size * MARK_TEXT_GAP_MM;
    return { dx: hw + gp + (halfW || 0), dy: g.dy };
  }

  /**
   * いま編集している紙の縮尺 1:N（枠が決まっている時だけ）。
   * 🔴 editor はシートを知らないので、app.js が `editor.paperScale` に
   *    関数を挿す（keysBusy / movePin と同じ作法）。無ければ null ＝画面px で解く。
   */
  Editor.prototype.paperScaleN = function () {
    if (typeof this.paperScale !== 'function') return null;
    var n = this.paperScale();
    return (typeof n === 'number' && isFinite(n) && n > 0) ? n : null;
  };

  /**
   * 🔒 §28-5 A / §28-7: 「印を置く」の印を**その場に置く**（名前は後から聞く）。
   * 🔴 先に印つき文字（text は空）を作ってから 'text' を投げるので、
   *    名前を入れなくても（空 Enter・Esc）印だけが残る。
   * 🔒 §30-35-2 1〜2: 名前を聞くのは **MARK_TOOL の askName が true の物だけ**
   *    （信号機・バス停）。P・木（false）は置いた瞬間に印だけで終わる
   *    ＝器（印つき文字・文字は空）は同じまま（§30-35-2 4）。
   * 🔴 anchor ＝ クリックした場所そのもの（§18-8「●は場所そのもの」）。
   *    文字（at）はドラッグで動かせるが、印（anchor）は動かない。
   * @param kind 'signal' | 'bus' | 'parking' | 'tree'
   */
  Editor.prototype.placeMark = function (kind, at) {
    var m = MARK_TOOL[kind];
    if (!m || !at) return null;
    var o = { id: uid(), type: 'text',
              at: { lat: at.lat, lng: at.lng },
              anchor: { lat: at.lat, lng: at.lng },
              text: '', size: 'medium',
              dotStyle: m.dotStyle, nameCat: m.nameCat,
              /* 🔴 出どころの印。所在図の作り直し・§22-am の置き直しが
               * 「手で置いた物」を動かさない／消さないための識別子。 */
              nameSrc: 'manual', source: 'manual',
              style: { color: '#111' } };
    this._pushNew(o);
    /* 🔒 §30-15-2（2026-09-13 オーナー指示）: 1回1個。置いたら**選択道具へ戻す**
     * （置き忘れ・二重置きを防ぐ。続けて置きたい時はもう一度道具を押す）。
     * 🔴 持ち替えは 'text' より**先**に行う。app.js の tool ハンドラが
     *    hideTextInput() を呼ぶので、後にすると開いたばかりの名前の入力欄が
     *    その場で閉じてしまう（入力欄は開いたまま＝§30-15-2）。
     * 🔴 setTool('select') は選択を消さない（選択が消えるのは select 以外の時だけ）
     *    ので、いま置いた印は選ばれたまま＝そのまま掴んで動かせる。 */
    if (this.tool !== 'select') this.setTool('select');
    // 🔒 §30-35-2 1: 名前を聞く道具（信号機・バス停）だけ入力欄を出す
    if (m.askName) this._emit('text', { at: o.at, obj: o });
    return o;
  };

  /**
   * 🔒 §30-16（2026-09-13 オーナー指示）: 重ねて見せている交差点名・バス停名を
   * **そのまま図に入れる**。placeMark と同じ作りで、違いは3つだけ:
   *   ① 文字が最初から入っている（重ね表示の名前そのまま）
   *   ② 出どころが `source:'reveal'` / `nameSrc:'osm'`（なぞり出しで実体化した
   *      名称と同じ扱い＝所在図の作り直しで消えない・§23-6 の出典を足す対象）
   *   ③ 入力欄を出さない（'text' を投げない）・道具も持ち替えない
   *      （拾う状態を続けたまま何個でも入れられる・§30-16-1）
   * 🔴 文字の置き場所は §30-15-5 規則2 の markTextAt **1か所**（右隣／右端なら左隣）。
   * @param kind 'signal' | 'bus'
   */
  Editor.prototype.placeNamed = function (kind, at, text) {
    var m = MARK_TOOL[kind];
    if (!m || !at) return null;
    var o = { id: uid(), type: 'text',
              at: { lat: at.lat, lng: at.lng },
              anchor: { lat: at.lat, lng: at.lng },
              text: (text || '').trim(), size: 'medium',
              dotStyle: m.dotStyle, nameCat: m.nameCat,
              nameSrc: 'osm', source: 'reveal',
              style: { color: '#111' } };
    if (o.text) {
      var p = this.markTextAt(o, o.text, this.markSide(o, o.text));
      if (p) o.at = p;
    }
    this._pushNew(o);
    return o;
  };

  /**
   * テキストを確定（app 側の入力欄から呼ばれる）。
   * @param side 🔒 §30-15-5 規則3: 入力欄が左隣に出ていたら 'left'（文字も左隣へ）
   * @return 🔒 §30-15-6: 新規の自由入力を置いた時だけ、置いたオブジェクトを返す
   *   （空で取消した時は null）。app.js が選択道具へ戻す時に選び直せるように。
   *   既存 obj（印つき文字・編集）の枝は今までどおり何も返さない（呼び出し側は
   *   道具が既に select＝この戻り値を使わない・§30-15-6 の④）。
   */
  Editor.prototype.commitText = function (obj, at, text, size, side) {
    text = (text || '').trim();
    if (obj) {
      this.snapshot();
      /* 🔒 §28-5 A: 印つき文字（信号機・バス停）は**文字が空でも消さない**。
       * 印そのものが図の中身なので、名前が分からない交差点・バス停でも置ける。 */
      if (!text && keepsMark(obj)) {
        obj.text = '';
        if (size) obj.size = size;
      } else if (!text) {
        var i = this.objects.indexOf(obj);
        if (i >= 0) this.objects.splice(i, 1);
        this.selection = [];
      } else {
        /* 🔒 §30-15-3: 印つき文字は**印の隣**から書き始める（右隣・§30-15-5
         *    規則3 で入力欄が左隣に出ていた時は左隣）。
         * 🔴 判定（まだ動かしていないか）は文字を入れる**前**に取る。
         * 🔴 置き場所の計算は markTextAt **1か所**（§30-15-5 規則2・紙基準）。
         *    大きさを変えた時はその新しい大きさで測るので size を先に入れる。 */
        var moved = !this.markSlot(obj);
        obj.text = text;
        if (size) obj.size = size;
        if (!moved) {
          var p = this.markTextAt(obj, text, side);
          if (p) obj.at = p;
        }
      }
      this.commit();
      this._emit('select', this.getSelected());
      return;
    }
    if (!text) { this.render(); return null; }
    var o = { id: uid(), type: 'text', at: at, text: text,
              size: size || 'medium', style: { color: '#111' } };
    this._pushNew(o);
    return o;
  };

  /* ---------- 自動下書き（正典 §11-b レーンA） ---------- */

  /** 生成した図形群をまとめて足す。1回の undo で全部戻せる */
  Editor.prototype.addGenerated = function (objs) {
    if (!objs || !objs.length) return 0;
    this.snapshot();
    /* 🔴 §23-7-1: 単純な `this.objects = objs.concat(this.objects)` は不可。
     * bind() が this.objects を state.current.objects[sheet] と**参照共有**して
     * いるため、代入で配列を丸ごと差し替えると参照が切れ、次のシート切替/自動保存で
     * 生成物が消える（実機確認済）。_restore() と同じ「length=0 → push」で
     * 同じ配列オブジェクトのまま並べ替える（順序保持・下敷き側に敷く挙動は不変）。 */
    var merged = objs.concat(this.objects);
    this.objects.length = 0;
    for (var i = 0; i < merged.length; i++) this.objects.push(merged[i]);
    this.selection = [];
    this.commit();
    this._emit('select', []);
    return objs.length;
  };

  /** 自動生成した物だけ消す（やり直し用） */
  Editor.prototype.clearGenerated = function () {
    var n = 0;
    this.snapshot();
    for (var i = this.objects.length - 1; i >= 0; i--) {
      if (this.objects[i].source === 'auto') { this.objects.splice(i, 1); n++; }
    }
    this.selection = [];
    this.commit();
    this._emit('select', []);
    return n;
  };

  /** 敷地候補（筆界）を表示する。null で消す */
  Editor.prototype.setCandidates = function (list) {
    this.candidates = list;
    this.renderCandidates();
  };

  Editor.prototype.renderCandidates = function () {
    var L = this.candLayer;
    while (L.firstChild) L.removeChild(L.firstChild);
    if (!this.candidates) return;
    var self = this;
    this.candidates.forEach(function (c) {
      var pts = c.points.map(function (p) {
        var s = self.map.project(p.lat, p.lng);
        return s.x.toFixed(1) + ',' + s.y.toFixed(1);
      }).join(' ');
      L.appendChild(el('polygon', { points: pts, class: 'cand' }));
      if (c.chiban) {
        var ctr = AutoDraft.centroid(c.points);
        var s2 = self.map.project(ctr.lat, ctr.lng);
        var t = el('text', { x: s2.x.toFixed(1), y: s2.y.toFixed(1), class: 'cand-label' });
        t.textContent = c.chiban;
        L.appendChild(t);
      }
    });
  };

  /** 画面座標の下にある敷地候補 */
  Editor.prototype.hitCandidate = function (px, py) {
    if (!this.candidates) return null;
    var ll = this.map.unproject(px, py);
    var best = null, bestA = Infinity;
    for (var i = 0; i < this.candidates.length; i++) {
      var c = this.candidates[i];
      if (!AutoDraft.pointInPolygon(ll, c.points)) continue;
      var a = AutoDraft.areaM2(c.points);       // 入れ子なら小さい方を採る
      if (a < bestA) { bestA = a; best = c; }
    }
    return best;
  };

  /** 敷地を図形として取り込む（外枠＋地番ラベル） */
  Editor.prototype.adoptParcel = function (c) {
    this.snapshot();
    var poly = AutoDraft.toPolygon(c.points, { w: 2.4, color: '#111' });
    poly.source = 'parcel';
    this.objects.push(poly);
    var ids = [poly.id];
    if (c.chiban) {
      var ctr = AutoDraft.centroid(c.points);
      var h = Editor.TEXT_PX.medium * this.map.metersPerPixel(ctr.lat);
      var t = { id: 't' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
                type: 'text', at: ctr, text: c.chiban, size: 'medium', h_m: h,
                style: { color: '#111' }, source: 'parcel' };
      this.objects.push(t);
      ids.push(t.id);
    }
    this.selection = ids;
    this.commit();
    this._emit('select', this.getSelected());
    return poly;
  };

  /** 敷き詰め結果を四角として置く（正典 §9 Step 3.5）。
   *  1枠=1つの rect にするので、いらない枠は消しゴムで1枚ずつ消せる。 */
  Editor.prototype.addFilledCells = function (cells, opt) {
    if (!cells || !cells.length) return 0;
    this.snapshot();
    // 同じ undo にまとめたい前処理（縮尺の較正など）は snapshot の後に呼ぶ
    if (opt && typeof opt.beforeAdd === 'function') opt.beforeAdd();
    var self = this, n = this.numberStart;
    cells.forEach(function (c, i) {
      self.objects.push({
        id: uid(), type: 'rect', center: c.center,
        // 画像認識の枠は1枚ずつ大きさが違うことがある（線を1本落とすと合体する）
        w_m: c.w_m || opt.cell_w_m, h_m: c.h_m || opt.cell_h_m,
        angle: c.angleDeg || 0,
        labelOverride: null,
        number: opt.number === false ? null : n++,
        // 🔒 v4（正典 §16-10-d-4）: 自動生成の枠にも寸法は入れない
        showDims: false,
        style: { w: 2, color: '#111' }, source: 'fill'
      });
    });
    if (opt.number !== false) {
      this.numberStart = n;
      this._emit('number', n);
    }
    this.selection = [];
    this.commit();
    this._emit('select', []);
    return cells.length;
  };

  /**
   * 塊スタンプを置く（正典 §4-4）。
   * 🔒 §30-19-1: opt.origin（{lat,lng}）を渡すとその場所へ置く。
   *    省略した時は今までどおり**地図の中央**（［台数を指定して置く…］の窓）。
   */
  Editor.prototype.placeStamp = function (opt) {
    var o = { id: uid(), type: 'stampGroup',
              origin: opt.origin || this.map.getCenter(), angle: 0,
              count: Math.max(1, opt.count | 0),
              cell_w_m: opt.cell_w_m, cell_h_m: opt.cell_h_m,
              direction: opt.direction === 'row' ? 'row' : 'col',
              // 🔒 v4（§16-10-d-4）: 新しい塊にも代表寸法を自動では出さない。
              // 旧データは showDims を持たない＝従来どおり表示（!==false 判定）
              showDims: false,
              skip: [], numbers: {}, style: { w: 2, color: '#111' } };
    this._pushNew(o);
    return o;
  };

  /* ================= 番号割付（正典 §4-7 / 2026-08-16 改) =================
   * 塊で作った枠も、単独で作った四角も、同じ「採番できる対象」として扱う。
   * 塊をまたいでも連番を振れる。
   */

  /** 画面座標の下にある採番対象。{key, set(n), get()} を返す */
  Editor.prototype.hitNumberTarget = function (px, py) {
    var cell = this.hitStampCell(px, py);
    if (cell) {
      var g = cell.group, i = cell.index;
      return {
        key: 'g:' + g.id + ':' + i,
        get: function () { return g.numbers ? g.numbers[i] : null; },
        set: function (n) {
          if (!g.numbers) g.numbers = {};
          if (n == null) delete g.numbers[i]; else g.numbers[i] = n;
        }
      };
    }
    var o = this.hitObject(px, py);
    // 🔒 §25-4: 主役マークは駐車枠ではないので採番の対象にしない
    if (o && o.type === 'rect' && o.role !== 'mainmark') {
      return {
        key: 'r:' + o.id,
        get: function () { return o.number; },
        set: function (n) { o.number = (n == null) ? null : n; }
      };
    }
    return null;
  };

  /** ドラッグ採番を始める */
  Editor.prototype.startNumberStroke = function (px, py) {
    var t = this.hitNumberTarget(px, py);
    if (!t) return false;
    this.snapshot();                    // 一連の採番をまとめて1回で戻せるように
    this._numFrom = null;               // クリック採番の起点は捨てる
    this._numFromN = null;
    this._numStroke = { keys: [t.key] };
    t.set(this.numberStart++);
    this._emit('number', this.numberStart);
    this.render();
    return true;
  };

  /** ドラッグ中に通った枠へ続きの番号を振る */
  Editor.prototype.extendNumberStroke = function (px, py) {
    if (!this._numStroke) return;
    var t = this.hitNumberTarget(px, py);
    if (!t) return;
    if (this._numStroke.keys.indexOf(t.key) >= 0) return;   // 同じ枠は1回だけ
    this._numStroke.keys.push(t.key);
    t.set(this.numberStart++);
    this._emit('number', this.numberStart);
    this.render();
  };

  Editor.prototype.endNumberStroke = function () {
    if (!this._numStroke) return;
    var n = this._numStroke.keys.length;
    this._numStroke = null;
    this.render();
    this._emit('change');
    return n;
  };

  /* ---------- 消しゴム / 番号 ---------- */

  Editor.prototype._eraseAt = function (px, py) {
    // 塊の枠は1枚だけ消す（実在駐車場の歯抜け対応・正典 §4-9）
    var cell = this.hitStampCell(px, py);
    if (cell) {
      this.snapshot();
      cell.group.skip = (cell.group.skip || []).concat([cell.index]);
      if (cell.group.numbers) delete cell.group.numbers[cell.index];
      if (this.stampCells(cell.group).length === 0) {
        var gi = this.objects.indexOf(cell.group);
        if (gi >= 0) this.objects.splice(gi, 1);
      }
      this.commit();
      return;
    }
    var o = this.hitObject(px, py);
    if (!o) return;
    /* 🔒 §30-32-1: 主役の印・主役の文字は「その地点そのもの」なので、図形を1個
     * 消すのではなく**地点ごと**消す（app.js の removePoint＝紙の印も文字も
     * 結線も一度に消える）。口は onErasePoint 1つ（bindEditor が差し込む）。
     * 🔴 true が返れば消えた＝ここでは何もしない。 */
    if (this.onErasePoint && isPointPart(o) && this.onErasePoint(o)) return;
    this.snapshot();
    var i = this.objects.indexOf(o);
    if (i >= 0) this.objects.splice(i, 1);
    this.selection = [];
    this.commit();
    this._emit('select', []);
  };

  /**
   * クリック採番。
   * 1回目にクリックした枠が起点(=小さい番号)、2回目が終点になる。
   * 🔴 内部の枠の並び順で決めてはいけない。押した順が起点→終点。
   *    （並び順で決めていた時は「常に下から番号が振られる」状態だった）
   */
  Editor.prototype._numberAt = function (px, py, alt) {
    var target = this.hitNumberTarget(px, py);
    if (!target) return;

    if (alt) {                                  // Alt+クリックで番号消去
      this.snapshot();
      target.set(null);
      this.commit();
      return;
    }

    var cell = this.hitStampCell(px, py);

    // 塊の中で「起点 → 終点」を指定した時だけ、間をまとめて埋める
    if (cell && this._numFrom && this._numFrom.group === cell.group) {
      this.snapshot();
      var g = cell.group;
      var live = this.stampCells(g);
      var i0 = live.indexOf(this._numFrom.index), i1 = live.indexOf(cell.index);
      var step = (i0 <= i1) ? 1 : -1;           // 押した向きに数える
      // 1回目のクリックで起点に振った番号から続ける。
      // ここで numberStart を使うと起点が2番になってしまう。
      var n = (this._numFromN != null) ? this._numFromN : this.numberStart;
      for (var k = i0; ; k += step) {
        g.numbers[live[k]] = n++;
        if (k === i1) break;
      }
      this.numberStart = n;
      this._numFrom = null;
      this._numFromN = null;
      this._emit('number', this.numberStart);
      this.commit();
      return;
    }

    // それ以外は1枠ずつ。塊の枠なら次のクリックで範囲指定もできるよう覚えておく
    this.snapshot();
    this._numFromN = this.numberStart;
    target.set(this.numberStart++);
    this._numFrom = cell || null;
    this._emit('number', this.numberStart);
    this.commit();
  };

  /* ================= 保管場所マーク（正典 §16-5 A） =================
   * 番号ツールと同じセルヒットを使い、クリックした枠に太枠＋「保管場所」の
   * ラベルを付ける。単独の四角なら寸法表示も一緒に ON にする
   * （警察様式では保管場所の幅・奥行が要るため）。複数の枠に付けられる。 */

  Editor.prototype.toggleStorageAt = function (px, py) {
    var cell = this.hitStampCell(px, py);
    if (cell) {
      this.snapshot();
      var g = cell.group;
      if (!g.storage) g.storage = {};
      if (g.storage[cell.index]) delete g.storage[cell.index];
      else g.storage[cell.index] = storageConf(storageDef);   // 🔒 §30-22-4 9: 既定の書式
      this.commit();
      return true;
    }
    var o = this.hitObject(px, py);
    // 🔒 §25-4: 主役マークは車両枠ではないので保管場所マークの対象外（§16-5A は無変更）
    if (!o || o.type !== 'rect' || o.role === 'mainmark') return false;
    this.snapshot();
    if (o.storage) {
      delete o.storage;
    } else {
      o.storage = storageConf(storageDef);
      o.showDims = true;      // 保管場所の寸法は必ず図に出す
    }
    this.commit();
    return true;
  };

  /**
   * 🔒 §30-22-4 9（2026-09-13 オーナー指示）: 保管場所マークの**書式**。
   *   色（黒／赤／青）・斜線（入れる／入れない）・太線（する／しない）
   * 🔴 旧データ（`storage: true`）は「黒・斜線あり・太線あり」に読み替える。
   *    値の読み替えはこの1か所（画面 editor.js・紙 export.js が同じ物を通る）。
   */
  /* 🔒 §30-22-7 4（2026-09-13 Fable 裁定）: **既定は 黒・斜線なし・太線あり**
   *    ＝ 旧 `storage: true` の見た目そのまま（旧案件の紙を変えない）。
   *    斜線は書式で「入れる」にした時だけ入る。 */
  function storageConf(v) {
    if (!v) return null;
    var c = (v === true) ? {} : v;
    var color = c.color, ok = false;
    for (var i = 0; i < INK.length; i++) {
      if (INK[i].key === color) ok = true;
    }
    if (!ok) color = INK[0].key;
    return { color: color,
             hatch: (c.hatch === undefined) ? false : !!c.hatch,
             bold:  (c.bold  === undefined) ? true : !!c.bold };
  }
  /**
   * 🔒 §30-22-4 9 / §30-22-7 4: **これから置く**保管場所マークの書式（既定）。
   * 配置図⑦の「保管場所マークの書式」がここを書き換える（app.js Editor.storageDefault）。
   * 🔴 画面の状態（案件には保存しない）＝開き直すと §30-22-7 4 の既定に戻る。
   * 🔴 既に置いてある印は applyStorageProps で変える（この値は新しい印にだけ効く）。
   */
  var storageDef = storageConf(true);

  /** 既定の書式を読む（引数なし）／変える（patch を渡す）。返り値はいまの既定 */
  Editor.storageDefault = function (patch) {
    if (patch) {
      var c = storageConf(storageDef);
      if (patch.color) c.color = patch.color;
      if (patch.hatch !== undefined) c.hatch = !!patch.hatch;
      if (patch.bold !== undefined) c.bold = !!patch.bold;
      storageDef = storageConf(c);
    }
    return storageConf(storageDef);
  };

  /** 保管場所の太枠の太さ（画面px基準・紙は線幅倍率 S を掛ける） */
  var STORAGE_W = { bold: 5, thin: 2 };

  /** 保管場所の太枠とラベルを描く（画面・書き出しで同じ見た目） */
  Editor.prototype._drawStorage = function (layer, corners, ctr, v) {
    var cf = storageConf(v || true);
    var hex = inkHex(cf.color);
    var pts = corners.map(function (p) {
      return p.x.toFixed(1) + ',' + p.y.toFixed(1);
    }).join(' ');
    /* 🔒 §30-22-4 9: 斜線（入れる時だけ）。主役マークと同じ 45° の斜線パターンを
     * 色ごとに用意して塗る（＝白黒コピーでも保管場所が塗り分けとして残る）。 */
    if (cf.hatch) {
      layer.appendChild(el('polygon', { points: pts,
        fill: 'url(#' + this._hatchId(hex) + ')', stroke: 'none' }));
    }
    layer.appendChild(el('polygon', { points: pts, fill: 'none',
      /* 🔴 太さ・色は **style で** 入れる（表示属性は CSS の .obj-storage に負ける） */
      style: 'stroke:' + hex + ';stroke-width:'
           + (cf.bold ? STORAGE_W.bold : STORAGE_W.thin),
      class: 'obj-storage' }));
    /* 🔒 §30-25-19（2026-09-14 オーナー指示）: 保管場所マークは**印だけ**。
     * 「保管場所」の文字は描かない（太枠・斜線・色はそのまま）。
     * 言葉が要る時は配置図⑦の［保管場所］で**文字として**置く
     * （動かせる・大きさも変えられる・§30-25-20）。 */
  };

  /**
   * 🔒 §30-22-3 2（2026-09-13 オーナー指示）: 枠の中に入れる文字
   * （［来客用］［車いす］）。**枠が縦長なら縦書き・横長なら横書き**。
   * 🔴 枠と一緒に回る（枠の辺の向きで書く）。大きさは枠に収まるよう自動で決める
   *    ＝ 紙のミリではなく「枠の何割」（枠からはみ出す方が事故なので）。
   * @param corners 枠の4隅（画面px・c[0]→c[1] が幅の辺）
   */
  function cellTextGeom(corners, text) {
    var w = Math.hypot(corners[1].x - corners[0].x, corners[1].y - corners[0].y);
    var h = Math.hypot(corners[3].x - corners[0].x, corners[3].y - corners[0].y);
    var n = Math.max(1, (text || '').length);
    var vertical = (h > w);                       // 縦長の枠＝縦書き
    var size = vertical
      ? Math.min(w * 0.62, (h * 0.86) / n)
      : Math.min(h * 0.5, (w * 0.86) / (emWidth(text) || 1));
    // 枠の向き（画面角度）。文字が逆さにならないよう ±90° に収める
    var ang = Math.atan2(corners[1].y - corners[0].y,
                         corners[1].x - corners[0].x) * 180 / Math.PI;
    if (ang > 90 || ang < -90) ang += 180;
    return { vertical: vertical, size: size, ang: ang, n: n,
             cx: (corners[0].x + corners[2].x) / 2,
             cy: (corners[0].y + corners[2].y) / 2 };
  }

  /**
   * 🔒 §30-25-25（2026-09-14 オーナー実機「ZL が高いと画面では番号が枠に収まるが、
   * プレビューでは枠をはみ出す」）: 駐車枠の番号の大きさ＝
   * 「標準の大きさ」（呼び出し側が渡す stdPx＝紙 LABEL_MM.number をそれぞれの
   * mmPx で px にした値）と「枠に収まる大きさ」（cellTextGeom が枠の短辺・長辺と
   * 文字数から出す size をそのまま読む＝来客用の文字と同じ作法）の**小さい方**。
   * 🔴 向きは回さない（cellTextGeom の ang/vertical は使わない＝今までどおり
   *    枠の中心に水平のまま）。
   * 画面（editor.js の塊の番号・四角の番号）と紙（export.js drawStamp／drawRect の
   * 番号）が全部この1関数を通る＝ズームや紙の縮尺で決め方が割れない。
   * @param cellPts 枠の4隅（c[0]→c[1] が幅の辺）
   * @param text 番号の文字列
   * @param stdPx 標準の大きさ（px）
   * @return {cx, cy, size}
   */
  function cellNumberGeom(cellPts, text, stdPx) {
    var g = cellTextGeom(cellPts, text);
    return { cx: g.cx, cy: g.cy, size: Math.min(stdPx, g.size) };
  }

  /** 🔒 §30-25-25: 番号の「標準の大きさ」（画面px）＝紙 LABEL_MM.number（既定4.4mm）を
   * mmPx()（ズーム連動）で画面pxに直した値。紙は export.js が自前の mmPx(mm,pxmm)
   * で同じ mm から出す（この関数は画面専用・呼び出し側がそれぞれの単位で作る）。 */
  Editor.prototype.numberStdPx = function () {
    return labelMm('number') * this.mmPx();
  };
  /** 🔒 §30-25-25: 下限（画面px）＝紙 1.8mm 相当。それ未満なら描かない
   * （来客用の size >= 4px と同じ考え方）。 */
  Editor.prototype.numberMinPx = function () {
    return 1.8 * this.mmPx();
  };

  /** 枠の中の文字を描く（画面。紙は export.js の drawCellText が同じ形を描く） */
  Editor.prototype._drawCellText = function (layer, corners, text) {
    var g = cellTextGeom(corners, text);
    if (!(g.size >= 4)) return;                   // 小さすぎる枠には入れない
    var rot = 'rotate(' + g.ang.toFixed(1) + ' ' + g.cx.toFixed(1)
            + ' ' + g.cy.toFixed(1) + ')';
    if (!g.vertical) {
      var t = el('text', { x: g.cx.toFixed(1), y: g.cy.toFixed(1),
        'font-size': g.size.toFixed(1), transform: rot, class: 'cell-label' });
      t.textContent = text;
      layer.appendChild(t);
      return;
    }
    var lh = g.size * 1.02;
    for (var i = 0; i < g.n; i++) {
      var y = g.cy + (i - (g.n - 1) / 2) * lh;
      var c = el('text', { x: g.cx.toFixed(1), y: y.toFixed(1),
        'font-size': g.size.toFixed(1), transform: rot, class: 'cell-label' });
      c.textContent = text.charAt(i);
      layer.appendChild(c);
    }
  };

  /**
   * 🔒 §30-22-7 5（2026-09-13 Fable 裁定）: **車いすは自前の単色パス**。
   * 絵文字 ♿ はフォント任せ＝環境差があり、カラー絵文字だと白黒コピーで潰れる。
   * 線だけ（§23-9 の全体則）で描き、**画面（SVG）も紙（canvas）もこの表を読む**。
   * 座標は一辺 1 の正方形の中（中心が原点・y は下が＋）。描く側が大きさを掛ける。
   */
  var WHEELCHAIR = {
    lw: 0.085,                                     // 線の太さ（一辺に対する比）
    head: { x: -0.14, y: -0.36, r: 0.095 },        // 頭（塗り）
    wheel: { x: 0.02, y: 0.14, r: 0.30, lw: 0.07 },// 車輪（線）
    lines: [                                       // 背〜腰／腕／腿／すね／足置き
      [[-0.17, -0.23], [-0.06, -0.05]],
      [[-0.14, -0.16], [0.10, -0.12]],
      [[-0.06, -0.05], [0.12, 0.03]],
      [[0.12, 0.03], [0.20, 0.22]],
      [[0.20, 0.22], [0.31, 0.20]]
    ]
  };

  /**
   * 🔒 §30-22-3 2 / §30-22-7 5: 枠の中に入れる**印**（車いす）の置き方。
   * 文字（cellTextGeom）と同じ「枠の向きに合わせて回す」作法で、
   * 大きさは枠に収まるよう自動（紙のミリではなく枠の何割か）。
   */
  function cellIconGeom(corners) {
    var w = Math.hypot(corners[1].x - corners[0].x, corners[1].y - corners[0].y);
    var h = Math.hypot(corners[3].x - corners[0].x, corners[3].y - corners[0].y);
    var ang = Math.atan2(corners[1].y - corners[0].y,
                         corners[1].x - corners[0].x) * 180 / Math.PI;
    if (ang > 90 || ang < -90) ang += 180;
    return { size: Math.min(w, h) * 0.72, ang: ang,
             cx: (corners[0].x + corners[2].x) / 2,
             cy: (corners[0].y + corners[2].y) / 2 };
  }

  /** 枠の中の車いすの印を描く（画面。紙は export.js の drawCellWheel が同じ形を描く） */
  Editor.prototype._drawCellWheel = function (layer, corners) {
    var q = cellIconGeom(corners);
    if (!(q.size >= 8)) return;                   // 小さすぎる枠には入れない
    var W = WHEELCHAIR, s = q.size;
    var g = el('g', { class: 'cell-wheel',
      transform: 'translate(' + q.cx.toFixed(1) + ',' + q.cy.toFixed(1) + ') '
               + 'rotate(' + q.ang.toFixed(1) + ')' });
    g.appendChild(el('circle', { cx: (W.wheel.x * s).toFixed(1),
      cy: (W.wheel.y * s).toFixed(1), r: (W.wheel.r * s).toFixed(1),
      fill: 'none', 'stroke-width': (W.wheel.lw * s).toFixed(2) }));
    g.appendChild(el('circle', { cx: (W.head.x * s).toFixed(1),
      cy: (W.head.y * s).toFixed(1), r: (W.head.r * s).toFixed(1),
      class: 'is-fill' }));
    W.lines.forEach(function (ln) {
      g.appendChild(el('line', { x1: (ln[0][0] * s).toFixed(1), y1: (ln[0][1] * s).toFixed(1),
        x2: (ln[1][0] * s).toFixed(1), y2: (ln[1][1] * s).toFixed(1),
        'stroke-width': (W.lw * s).toFixed(2) }));
    });
    layer.appendChild(g);
  };

  /**
   * 🔒 §30-22-3 2: 枠に「来客用」「車いす」の印を入り切りする（保管場所と同じ作法）。
   * @param key 'guest' | 'wheel'
   */
  Editor.prototype.toggleCellFlagAt = function (px, py, key) {
    var cell = this.hitStampCell(px, py);
    if (!cell) return false;
    this.snapshot();
    var g = cell.group;
    if (!g[key]) g[key] = {};
    if (g[key][cell.index]) delete g[key][cell.index];
    else g[key][cell.index] = true;
    this.commit();
    return true;
  };

  /** 保管場所マークの書式を変える（右パネル・§30-22-4 9） */
  Editor.prototype.applyStorageProps = function (o, props) {
    if (!o) return false;
    var next = function (cur) {
      var c = storageConf(cur || true);
      if (props.color) c.color = props.color;
      if (props.hatch !== undefined) c.hatch = !!props.hatch;
      if (props.bold !== undefined) c.bold = !!props.bold;
      return c;
    };
    this.snapshot();
    var n = 0;
    if (o.type === 'stampGroup' && o.storage) {
      Object.keys(o.storage).forEach(function (i) {
        if (!o.storage[i]) return;
        o.storage[i] = next(o.storage[i]);
        n++;
      });
    } else if (o.storage) {
      o.storage = next(o.storage);
      n++;
    }
    if (!n) { this.undoStack.pop(); this.render(); return false; }
    this.commit();
    return true;
  };

  /**
   * 🔒 §30-25-18 4: 印（信号機・バス停・P・木）の大きさを右パネルのボタンで変える。
   * 🔴 値の出どころは `markScale` 1つ（つまみのドラッグと同じ場所を書く）。
   * @param v 倍率（clampMarkScale で上下限に丸める）
   */
  Editor.prototype.applyMarkScale = function (o, v) {
    if (!keepsMark(o)) return false;
    this.snapshot();
    o.markScale = clampMarkScale(v);
    this.commit();
    return true;
  };

  /** 選択中の四角に実寸を直接入れる（実測値優先・正典 §4-3） */
  Editor.prototype.applyRectProps = function (o, props) {
    this.snapshot();
    if (props.w_m !== undefined && props.w_m > 0) o.w_m = props.w_m;
    if (props.h_m !== undefined && props.h_m > 0) o.h_m = props.h_m;
    if (props.angle !== undefined) o.angle = ((props.angle % 360) + 360) % 360;
    if (props.labelOverride !== undefined) o.labelOverride = props.labelOverride || null;
    if (props.showDims !== undefined) o.showDims = !!props.showDims;
    this.commit();
  };

  /**
   * 主役マーク（🔒 §25-4）の大きさ・向き・色。
   * 🔴 寸法ラベル（showDims / labelOverride）は扱わない ―― マークは車両枠ではないので
   *    寸法を出さない、が仕様。
   */
  Editor.prototype.applyMarkProps = function (o, props) {
    this.snapshot();
    if (props.w_m !== undefined && props.w_m > 0) o.w_m = props.w_m;
    if (props.h_m !== undefined && props.h_m > 0) o.h_m = props.h_m;
    if (props.angle !== undefined) o.angle = ((props.angle % 360) + 360) % 360;
    if (props.markColor) {
      o.markColor = props.markColor;
      // style.color も揃えておく（輪郭線・汎用コードはこちらを見る）
      o.style = o.style || {};
      o.style.color = markHex(o);
    }
    o.showDims = false;
    this.commit();
  };

  Editor.prototype.applyStampProps = function (o, props) {
    this.snapshot();
    if (props.count !== undefined && props.count > 0) {
      o.count = props.count | 0;
      o.skip = (o.skip || []).filter(function (i) { return i < o.count; });
    }
    if (props.cell_w_m !== undefined && props.cell_w_m > 0) o.cell_w_m = props.cell_w_m;
    if (props.cell_h_m !== undefined && props.cell_h_m > 0) o.cell_h_m = props.cell_h_m;
    if (props.direction) o.direction = props.direction;
    if (props.angle !== undefined) o.angle = ((props.angle % 360) + 360) % 360;
    if (props.stagger_m !== undefined) o.stagger_m = props.stagger_m;
    if (props.showDims !== undefined) o.showDims = !!props.showDims;
    this.commit();
  };

  Editor.prototype.applyArrowProps = function (o, props) {
    this.snapshot();
    if (props.label !== undefined) {
      var w = String(props.label || '').trim();
      o.label = w ? (/m$/.test(w) ? w : w + 'm') : null;
    }
    this.commit();
  };

  Editor.prototype.applyTextProps = function (o, props) {
    this.snapshot();
    if (props.text !== undefined) o.text = props.text;
    /* 🔒 §30-22-3 3: 小／中／大を選び直したら**連続値は捨てて**その段の既定に戻す
     * （3段は「目安の既定値」になった＝選び直しが効かないと直せなくなる）。 */
    if (props.size && props.size !== o.size) { o.size = props.size; delete o.sizeMm; }
    else if (props.size) o.size = props.size;
    if (props.sizeMm !== undefined) {
      if (props.sizeMm > 0) o.sizeMm = props.sizeMm; else delete o.sizeMm;
    }
    /* 🔒 §30-25-28 4: 右パネルで大きさ・文字を変えた主役ラベルも「手で触った物」
     * ＝生成（③の作り直し）で置き直さない（つまみのドラッグと同じ扱い）。 */
    if (props.size || props.sizeMm !== undefined) noteUserMoved(o);
    this.commit();
  };

  /* ================= 描画 ================= */

  Editor.prototype.render = function () {
    var layer = this.layer;
    while (layer.firstChild) layer.removeChild(layer.firstChild);
    var self = this;
    // 🔒 §30-25-7: ズームが変わったら斜線パターンの間隔を引き直す（作り直さない）
    this._syncHatchScale();

    /* 🔒 §30-25-4（2026-09-13 オーナー実機）: **道路は一番下**に描く。
     * 描く順は「道路 → その他 → 文字」。
     * 🔴 this.objects の並びは変えない（注意①・§23-7-1）。ここで**写しを作って**
     *    並べ替える（安定＝同じ組の中の前後関係は元のまま）。
     * 🔴 当たり判定（hitObject）も同じ理屈で「道路は最後に見る」＝
     *    見えている物が掴める（§22-z の教訓どおり描画と当たりはセットで直す）。 */
    var objs = sortRoadsFirst(this.objects);
    /* 🔒 §22-at-3 欠陥2-①（2026-09-06 Fable 裁定）: 文字（引き出し線・●・
     * 信号/バス停アイコンを含む type:'text' 一式）は道路の帯・川・建物より
     * **必ず後**に描く。this.objects の並び順のまま混ぜて描くと、文字より後ろに
     * 並んでいる道路の白帯が文字に乗って切ってしまう（実例:「名古屋中央郵便局」
     * 「東海旅客鉄道株式会社」）。ここで type:'text' だけ後回しにする1パスへ分ける
     * （this.objects 自体の並びは §23-7-1 のまま触らない・注意①）。 */
    var texts = [];
    for (var i = 0; i < objs.length; i++) {
      var o = objs[i];
      if (o.type === 'text') { texts.push(o); continue; }
      /* 🔒 §23-9 白帯＋黒縁の道路は**連続する塊ごとに2パス**で描く。
       * 1本ずつ「黒→白」と描くと、次の道路の黒縁が前の道路の白帯に乗って
       * 交差点が黒くぶつ切りになる（ヤフーの見え方にならない）。
       * 塊の中を「全部の黒縁 → 全部の白帯」の順にすると交差点がつながる。
       * 🔴 塊の外（主役マーク等）との前後関係は元の並びのまま
       *    ＝ §23-7-1 で直した z順は壊さない。this.objects にも触らない（注意①）。 */
      if (isCasingRoad(o)) {
        var run = [];
        while (i < objs.length && isCasingRoad(objs[i])) { run.push(objs[i]); i++; }
        i--;
        this._drawRoadRun(layer, run);
        continue;
      }
      var sel = self.selection.indexOf(o.id) >= 0;
      switch (o.type) {
        case 'rect': self._drawRect(layer, o, sel); break;
        case 'line': self._drawLine(layer, o, sel); break;
        case 'curve': self._drawCurve(layer, o, sel); break;
        case 'polygon': self._drawPolygon(layer, o, sel); break;
        case 'path': self._drawPolygon(layer, o, sel); break;
        case 'arrow': self._drawArrow(layer, o, sel); break;
        case 'labelBlock': self._drawLabelBlock(layer, o, sel); break;
        case 'stampGroup': self._drawStamp(layer, o, sel); break;
        // 🔒 §28-3: 方位記号は「部品」（紙の付き物ではなく普通のオブジェクト）
        case 'compass': self._drawCompass(layer, o, sel); break;
      }
    }
    for (var ti = 0; ti < texts.length; ti++) {
      var to = texts[ti];
      self._drawText(layer, to, self.selection.indexOf(to.id) >= 0);
    }

    this._drawDraft(layer);
    this._drawActions(layer);
    this._drawOverlayBtns(layer);      // 🔒 §25-7/§25-8 ±方向ボタン・回転ボタン
    this.renderCandidates();
  };

  /**
   * 選択中の1つに出す操作ボタン（🔒 §25-7 ±方向 / §25-8 回転）。
   * 複製・削除のアイコン（§18）とは別の層で、その上に描く。
   */
  Editor.prototype._drawOverlayBtns = function (layer) {
    if (this.tool !== 'select') return;
    var sel = this.getSelected();
    if (sel.length !== 1) return;
    this._drawStampNav(layer, sel[0]);
    this._drawRotBtns(layer, sel[0]);
  };

  /** 四方の矢羽＋（＋/−）。意匠は §25-7 のオーナー提供の参考絵どおり */
  Editor.prototype._drawStampNav = function (layer, g) {
    var nav = this.stampNav(g);
    if (!nav) return;
    var grp = el('g', { class: 'nav-group' }), self = this;
    nav.forEach(function (s) {
      var off = s.active ? '' : ' is-off';
      var d = chevronPath(s.at, s.u, NAV_CHEV, NAV_CHEV * 0.9);
      grp.appendChild(el('path', { d: d, class: 'nav-chev-halo' + off }));
      grp.appendChild(el('path', { d: d, class: 'nav-chev' + off }));
      if (!s.active) return;
      self._navBtn(grp, s.plus, 1, 'この向きに枠を1つ足す');
      if (s.canRemove) self._navBtn(grp, s.minus, -1, 'この向きの枠を1つ減らす');
    });
    layer.appendChild(grp);
  };

  Editor.prototype._navBtn = function (grp, p, sign, tip) {
    var c = el('circle', { cx: p.x.toFixed(1), cy: p.y.toFixed(1),
                           r: NAV_R, class: 'nav-btn' });
    var t = el('title', {});
    t.textContent = tip;
    c.appendChild(t);
    grp.appendChild(c);
    grp.appendChild(el('path', { d: plusMinusPath(p, sign, NAV_R * 0.55),
                                 class: 'nav-btn-icon' }));
  };

  /** 回転のボタン（🔒 §25-8）。回転つまみ（§18-t）の両脇に並べる。
   * 🔒 修正2（オーナー指示 2026-08-30）: 記号は ＋/− ではなく**曲線の矢印**。
   * 増減の ＋/− と紛らわしいのをやめ、回転つまみと同じ「弧＋矢頭」で揃える。 */
  Editor.prototype._drawRotBtns = function (layer, o) {
    var bs = this.rotBtns(o);
    if (!bs) return;
    var grp = el('g', { class: 'rotbtn-group' });
    bs.forEach(function (b) {
      var c = el('circle', { cx: b.at.x.toFixed(1), cy: b.at.y.toFixed(1),
                             r: ROTBTN_R, class: 'rotbtn' });
      var t = el('title', {});
      t.textContent = (b.delta > 0 ? '右回り（時計回り）に' : '左回り（反時計回り）に')
        + ROT_STEP + '°回す（矢印キーでも／押しっぱなしで連続）';
      c.appendChild(t);
      grp.appendChild(c);
      var d = rotArrowPath(b.at.x, b.at.y, ROTBTN_R * 0.62, b.delta);
      grp.appendChild(el('path', { d: d, class: 'rotbtn-arrow-halo' }));
      grp.appendChild(el('path', { d: d, class: 'rotbtn-arrow' }));
    });
    layer.appendChild(grp);
  };

  /** 選択中の図形の脇に「複製 / 削除」を出す */
  Editor.prototype._drawActions = function (layer) {
    var sel = this.getSelected();
    if (!sel.length || this.tool !== 'select') return;
    var a = this.actionAnchor(sel[0]);
    if (!a) return;
    var s = this.map.size();
    // 画面からはみ出す時は図形の左側に回す
    if (a.x + ACT_R * 3 > s.w) {
      // 🔒 §25-7: 左へ回す時も ±方向ボタンの外側へ（重なると押せない）
      var pts = this.actionOutline(sel[0]) || this.outlinePoints(sel[0]);
      var minX = Infinity;
      pts.forEach(function (p) { if (p.x - NAV_R < minX) minX = p.x - NAV_R; });
      a = { x: minX - ACT_GAP - ACT_R * 2 - 6, y: a.y };
    }
    if (a.y < ACT_R + 2) a.y = ACT_R + 2;

    var g = el('g', { class: 'act-group' });
    var self = this;
    this.actionList(sel[0]).forEach(function (kind, i) {
      var x = a.x + i * (ACT_R * 2 + 6), y = a.y;
      if (kind === 'duplicate') {
        g.appendChild(el('circle', { cx: x, cy: y, r: ACT_R, class: 'act-btn' }));
        g.appendChild(el('path', { class: 'act-icon',
          d: 'M' + (x - 5) + ' ' + y + 'h10M' + x + ' ' + (y - 5) + 'v10' }));
      } else if (kind === 'stagger') {
        // 階段状にずらす。押すとモードが入り、枠をドラッグしてずらせる
        g.appendChild(el('circle', { cx: x, cy: y, r: ACT_R,
          class: 'act-btn act-stagger' + (self.staggerMode ? ' is-on' : '') }));
        g.appendChild(el('path', {
          class: 'act-icon act-icon-stagger' + (self.staggerMode ? ' is-on' : ''),
          d: 'M' + (x - 6) + ' ' + (y + 5) + 'h4v-4h4v-4h4' }));
      } else {
        g.appendChild(el('circle', { cx: x, cy: y, r: ACT_R, class: 'act-btn act-del' }));
        g.appendChild(el('path', { class: 'act-icon act-icon-del',
          d: 'M' + (x - 5) + ' ' + (y - 3) + 'h10l-1 9h-8Z'
           + 'M' + (x - 6.5) + ' ' + (y - 3) + 'h13'
           + 'M' + (x - 2.5) + ' ' + (y - 5.5) + 'h5' }));
      }
    });
    layer.appendChild(g);
  };

  Editor.prototype._drawDraft = function (layer) {
    var d = this.draft, i;
    if (!d) return;
    if (d.type === 'line') {
      var a = this.map.project(d.a.lat, d.a.lng), b = this.map.project(d.b.lat, d.b.lng);
      layer.appendChild(el('line', { x1: a.x, y1: a.y, x2: b.x, y2: b.y, class: 'draft-line' }));
    } else if (d.type === 'curve') {
      var q = this.curvePts(d);
      layer.appendChild(el('path', { class: 'draft-line', fill: 'none',
        d: 'M' + q.a.x + ' ' + q.a.y + 'Q' + q.c.x + ' ' + q.c.y + ' ' + q.b.x + ' ' + q.b.y }));
    } else if (d.type === 'polygon') {
      var pts = d.points.map(function (p) { return this.map.project(p.lat, p.lng); }, this);
      if (d.cursor) pts.push(this.map.project(d.cursor.lat, d.cursor.lng));
      layer.appendChild(el('polyline', { class: 'draft-line', fill: 'none',
        points: pts.map(function (p) { return p.x + ',' + p.y; }).join(' ') }));
      for (i = 0; i < d.points.length; i++) {
        var pp = this.map.project(d.points[i].lat, d.points[i].lng);
        layer.appendChild(el('circle', { cx: pp.x, cy: pp.y, r: 4, class: 'handle' }));
      }
    } else if (d.type === 'arrow') {
      this._drawArrow(layer, { a: d.a, b: d.b, label: null, style: {} }, false, true);
    } else if (d.type === 'rect-preview') {
      layer.appendChild(el('rect', {
        x: Math.min(d.x0, d.x1), y: Math.min(d.y0, d.y1),
        width: Math.abs(d.x1 - d.x0), height: Math.abs(d.y1 - d.y0), class: 'draft-rect' }));
    }
  };

  Editor.prototype._drawLine = function (layer, o, sel) {
    var a = this.map.project(o.a.lat, o.a.lng), b = this.map.project(o.b.lat, o.b.lng);
    var st = o.style || {};
    var attrs = {
      x1: a.x.toFixed(1), y1: a.y.toFixed(1), x2: b.x.toFixed(1), y2: b.y.toFixed(1),
      stroke: st.color || '#111', 'stroke-width': st.w || 2, 'stroke-linecap': 'round',
      class: 'obj-line' + (sel ? ' is-sel' : '') };
    if (st.dash) attrs['stroke-dasharray'] = st.dash;
    layer.appendChild(el('line', attrs));
    // 🔒 §18-x-5: 結線の端はピンなので、外せるように見えるつまみは出さない
    if (sel && o.role !== 'distance') {
      layer.appendChild(el('circle', { cx: a.x, cy: a.y, r: HANDLE, class: 'handle' }));
      layer.appendChild(el('circle', { cx: b.x, cy: b.y, r: HANDLE, class: 'handle' }));
    }
  };

  Editor.prototype._drawCurve = function (layer, o, sel) {
    var q = this.curvePts(o), st = o.style || {};
    layer.appendChild(el('path', {
      d: 'M' + q.a.x.toFixed(1) + ' ' + q.a.y.toFixed(1) +
         'Q' + q.c.x.toFixed(1) + ' ' + q.c.y.toFixed(1) + ' ' +
               q.b.x.toFixed(1) + ' ' + q.b.y.toFixed(1),
      fill: 'none', stroke: st.color || '#111', 'stroke-width': st.w || 2,
      'stroke-linecap': 'round', class: 'obj-line' + (sel ? ' is-sel' : '') }));
    if (sel) {
      layer.appendChild(el('line', { x1: q.a.x, y1: q.a.y, x2: q.c.x, y2: q.c.y, class: 'rot-stem' }));
      layer.appendChild(el('line', { x1: q.b.x, y1: q.b.y, x2: q.c.x, y2: q.c.y, class: 'rot-stem' }));
      layer.appendChild(el('circle', { cx: q.a.x, cy: q.a.y, r: HANDLE, class: 'handle' }));
      layer.appendChild(el('circle', { cx: q.b.x, cy: q.b.y, r: HANDLE, class: 'handle' }));
      layer.appendChild(el('circle', { cx: q.c.x, cy: q.c.y, r: HANDLE, class: 'handle handle-rot' }));
    }
  };

  /** 折れ線の points 属性（画面座標）。2本描きと通常描画で同じ物を使う */
  Editor.prototype._ptsAttr = function (o) {
    return o.points.map(function (p) {
      var s = this.map.project(p.lat, p.lng);
      return s.x.toFixed(1) + ',' + s.y.toFixed(1);
    }, this).join(' ');
  };

  /**
   * 🔒 §23-9: 道路の「白い帯＋黒の縁取り」を**塊まるごと2パス**で描く。
   * 技法は鉄道ハッチ（§5・_drawPolygon の st.rail）と同じ2本描きだが、
   * 交差点をつなぐために「1本ずつ黒→白」ではなく「全部黒→全部白」にしてある。
   * 細すぎて帯にできない道（inner=0・等級不明の細街路など）はパス1の黒だけで終わる
   * ＝ 太い道の白帯の下をくぐる形になり、実際の地図と同じ見え方になる。
   */
  Editor.prototype._drawRoadRun = function (layer, run) {
    var self = this;
    var pts = run.map(function (o) { return self._ptsAttr(o); });
    // 🔒 §22-at: 画面は「1U＝画面1px」なので、1Uが表す実距離＝今のZLのm/px
    var ctx = { mPerU: this.map.metersPerPixel() };
    var bds = run.map(function (o) { return roadBand(o, ctx); });
    function tagOf(o) { return (o.type === 'path') ? 'polyline' : 'polygon'; }

    // パス1: 黒の縁取り（外側）を全部
    run.forEach(function (o, i) {
      var sel = self.selection.indexOf(o.id) >= 0;
      layer.appendChild(el(tagOf(o), {
        points: pts[i], fill: 'none', stroke: bds[i].outerColor,
        'stroke-width': bds[i].outer, 'stroke-linejoin': 'round',
        'stroke-linecap': 'round',
        class: 'obj-rect' + (sel ? ' is-sel' : '') }));
    });
    // パス2: 白い帯（内側）を全部
    run.forEach(function (o, i) {
      if (!(bds[i].inner > 0)) return;
      layer.appendChild(el(tagOf(o), {
        points: pts[i], fill: 'none', stroke: bds[i].innerColor,
        'stroke-width': bds[i].inner, 'stroke-linejoin': 'round',
        'stroke-linecap': 'round' }));
    });
    // 選択中のつまみは帯より上に（掴めなくならないように）
    run.forEach(function (o) {
      if (self.selection.indexOf(o.id) < 0
          || o.points.length > VERTEX_HANDLE_MAX) return;
      o.points.forEach(function (p) {
        var s = self.map.project(p.lat, p.lng);
        layer.appendChild(el('circle', { cx: s.x, cy: s.y, r: HANDLE, class: 'handle' }));
      });
    });
  };

  Editor.prototype._drawPolygon = function (layer, o, sel) {
    var st = o.style || {};
    var closed = (o.type !== 'path');
    var pts = this._ptsAttr(o);
    var cls = 'obj-rect' + (sel ? ' is-sel' : '') + (o.source === 'auto' ? ' is-auto' : '');
    var tag = closed ? 'polygon' : 'polyline';
    /* 🔒 §30-22-1 4: 主役の多角形（role:'mainmark'）は斜線ハッチ＋選んだ太さ・色。
     * 四角の主役マーク（_drawRect の mark 枝）と同じ見え方にそろえる。 */
    if (isMainMark(o)) {
      var mhex = inkHex(o.inkColor);
      if (o.hatch !== false) {
        layer.appendChild(el('polygon', { points: pts,
          fill: 'url(#' + this._hatchId(mhex) + ')', stroke: 'none' }));
      }
      layer.appendChild(el('polygon', { points: pts, fill: 'none',
        stroke: mhex, 'stroke-width': st.w || 2, 'stroke-linejoin': 'miter',
        class: 'obj-mark' + (sel ? ' is-sel' : '') }));
      if (sel && o.points.length <= VERTEX_HANDLE_MAX) {
        o.points.forEach(function (p) {
          var s = this.map.project(p.lat, p.lng);
          layer.appendChild(el('circle', { cx: s.x, cy: s.y, r: HANDLE, class: 'handle' }));
        }, this);
      }
      return;
    }
    var bd = roadBand(o, { mPerU: this.map.metersPerPixel() });
    if (bd) {
      /* 🔒 §23-9: 塊にまとまらなかった道路（点が足りない等）の逃げ道。
       * 通常は render が _drawRoadRun へ回すので、ここへは来ない。 */
      layer.appendChild(el(tag, { points: pts, fill: 'none', stroke: bd.outerColor,
        'stroke-width': bd.outer, 'stroke-linejoin': 'round',
        'stroke-linecap': 'round', class: cls }));
      if (bd.inner > 0) {
        layer.appendChild(el(tag, { points: pts, fill: 'none', stroke: bd.innerColor,
          'stroke-width': bd.inner, 'stroke-linejoin': 'round',
          'stroke-linecap': 'round' }));
      }
    } else if (st.rail) {
      // 鉄道は白黒ハッチ（黒の下地に白の破線を重ねる・正典 §5）
      layer.appendChild(el(tag, { points: pts, fill: 'none', stroke: '#111',
        'stroke-width': (st.w || 2.6), class: cls }));
      layer.appendChild(el(tag, { points: pts, fill: 'none', stroke: '#fff',
        'stroke-width': (st.w || 2.6) * 0.62, 'stroke-dasharray': '7 7',
        class: cls }));
    } else {
      /* 🔒 2026-09-03: st.fill を持つ図形だけ塗る（＝水域面 WA・§23-9 の明示的な例外）。
       * 🔴 塗りだけで線を持たない物（st.w が 0）もある。タイル境界で切られた面を
       *    1枚ずつ縁取ると継ぎ目に黒い筋が出るので、面は塗るだけにして
       *    岸の線は WL（別オブジェクト）に任せている（shozaizu.js の水部3パス）。 */
      var noLine = (st.fill && !(st.w > 0));      // 塗るだけ＝線を持たない図形
      var a2 = { points: pts, fill: st.fill || 'none',
        stroke: noLine ? 'none' : (st.color || '#111'),
        'stroke-width': noLine ? 0 : (st.w || 2),
        'stroke-linejoin': 'round', 'stroke-linecap': 'round', class: cls };
      if (st.dash) a2['stroke-dasharray'] = st.dash;
      layer.appendChild(el(tag, a2));
    }
    if (sel && o.points.length <= VERTEX_HANDLE_MAX) {
      o.points.forEach(function (p) {
        var s = this.map.project(p.lat, p.lng);
        layer.appendChild(el('circle', { cx: s.x, cy: s.y, r: HANDLE, class: 'handle' }));
      }, this);
    }
  };

  Editor.prototype._drawArrow = function (layer, o, sel, isDraft) {
    var a = this.map.project(o.a.lat, o.a.lng), b = this.map.project(o.b.lat, o.b.lng);
    var st = o.style || {}, w = st.w || 2;
    var cls = isDraft ? 'draft-line' : ('obj-line' + (sel ? ' is-sel' : ''));
    var g = el('g', {});
    g.appendChild(el('line', { x1: a.x.toFixed(1), y1: a.y.toFixed(1),
      x2: b.x.toFixed(1), y2: b.y.toFixed(1), stroke: st.color || '#111',
      'stroke-width': w, class: cls }));
    // 両端の矢羽
    [[a, b], [b, a]].forEach(function (pair) {
      var p = pair[0], q = pair[1];
      var ang = Math.atan2(q.y - p.y, q.x - p.x);
      var L = 9;
      [-0.5, 0.5].forEach(function (s) {
        var e2 = ang + s;
        g.appendChild(el('line', { x1: p.x.toFixed(1), y1: p.y.toFixed(1),
          x2: (p.x + Math.cos(e2) * L).toFixed(1), y2: (p.y + Math.sin(e2) * L).toFixed(1),
          stroke: st.color || '#111', 'stroke-width': w, class: cls }));
      });
    });
    layer.appendChild(g);

    if (isDraft) return;
    var mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2;
    /* 🔒 §25-5（2026-08-29 オーナー指示・§4-6 再改定。§22-z の全廃を覆す）:
     * 矢印は**常に値を出す**。手入力（o.label）があればそれ、無ければ2端点の
     * 緯度経度から計算した実距離（小数1桁）。
     * 🔴 自動値は「地図上で計算して記載する」実務そのもの（立入できない所・広い道路）。
     *    実測できた所は「表示」欄に手入力して上書きする、が使い分け。
     * 🔴 値の見た目は手入力と同じ（.dim-label）。見分けは付けない（§25-5）。 */
    var txt = Editor.arrowText(o);
    if (txt) {
      var t = el('text', { x: mx.toFixed(1), y: (my - 7).toFixed(1), class: 'dim-label' });
      t.textContent = txt;
      layer.appendChild(t);
    }
    if (sel) {
      layer.appendChild(el('circle', { cx: a.x, cy: a.y, r: HANDLE, class: 'handle' }));
      layer.appendChild(el('circle', { cx: b.x, cy: b.y, r: HANDLE, class: 'handle' }));
    }
  };

  Editor.prototype._drawText = function (layer, o, sel) {
    var p = this.map.project(o.at.lat, o.at.lng);
    var size = Math.max(6, this.textPx(o));
    /* 🔒 §30-30-1: 印（信号機・バス停・P・木・主役の◎）の**基準の大きさ**。
     * 文字の大きさ（size）とは別物＝文字を大きくしても印は変わらない。 */
    var mBase = this.markBasePx();
    /* 🔒 §18-8: 目標物の●（anchor）。文字と対で持つが、
     * 動くのは文字（at）だけで●は動かない（_moveSelection は at しか触らない）。
     * 文字が離れた時だけ細い引き出し線でつなぐ。 */
    if (o.anchor) {
      var a = this.map.project(o.anchor.lat, o.anchor.lng);
      var dx = p.x - a.x, dy = p.y - a.y;
      var d = Math.sqrt(dx * dx + dy * dy);
      /* 🔒 §18-j / §22-am-6-2: 文字の半幅は**実際に描かれる幅**で測る
       * （引き出し線の終点をここから出すので、見積りだと線が文字に届かない）。 */
      var wHalf = drawHalfWidth(o, size);   // 🔒 §22-av: 印つきは印の半幅
      /* 🔒 §22-y（2026-08-28 オーナー指示）: 自宅・駐車場の◎に近い施設（nearMain）は、
       * 主役とごちゃつかないよう文字を離した以上、**引き出し線は必ず描く**。
       * 🔴 textPx() は「ズームによらず画面上一定」なので、d（画面px距離）は現在ズーム次第
       *    ―― shozaizu.js 生成時の実距離(m)ベースの間隔が、閲覧ズームによっては
       *    この d>閾値 判定を跨がないことが実機で確認できた（ズームアウトで線が消える）。
       *    nearMain の時だけは閾値を無視して常時描く方が確実。 */
      /* 🔒 §22-am-2 ⑥（2026-09-04）: **離して置いた名前（o.lead）は常時描く**。
       * ●から遠く離した以上、線が無いとどの●の名前か分からない。nearMain と
       * 同じ理由（画面px基準の距離しきい値はズームで跨がない）で判定を外す。
       * 🔒 §22-am-6-2: 止める位置は**文字の箱の縁**（隙間 0）。
       *    旧 `Math.min(d*0.55, wHalf + size*0.4)` は向きを見ていなかったので、
       *    長い名前を上下に置くと文字のはるか手前で線が切れていた。 */
      if (wantLead(o, d, wHalf, size, 4)) {
        var stop = leadStop(dx, dy, d, wHalf, size);
        layer.appendChild(el('line', {
          x1: a.x.toFixed(1), y1: a.y.toFixed(1),
          x2: (p.x - dx / d * stop).toFixed(1), y2: (p.y - dy / d * stop).toFixed(1),
          /* 🔴 太さは **style で** 入れる。SVG の表示属性（stroke-width="…"）は
           * CSS の .anno-lead に負けるので、値の出どころが2つに割れてしまう。 */
          style: 'stroke-width:' + LEAD.w + ';stroke-dasharray:' + LEAD.dash.join(' '),
          class: 'anno-lead' }));
      }
      /* 🔒 §18-r: 自宅・駐車場は**二重丸（◎）で施設●の約2倍**。
       * 白黒で刷っても主役の2地点が一目で分かるようにする。 */
      var r0 = Math.max(DOT_MIN_PX, size * DOT_R);
      /* 🔒 §25-4（2026-08-29）: 新しく生成した主役ラベルは dotStyle:'none'。
       * 印は**四角＋斜線ハッチ**（role:'mainmark' の rect）が担うので●は描かない。
       * anchor は残す（引き出し線・文字の逃がし計算・ピン追従がこれを使う）。
       * 🔴 下の◎の枝は**旧データ用に残す**（既存案件はそのまま二重丸で開く・§25-4-7）。 */
      if (o.dotStyle === 'none') {
        /* 何も描かない（四角のマーカーが印） */
      } else if (o.dotStyle === 'signal') {
        /* 🔒 2026-09-02: 交差点名は●ではなく**信号機**（横長の角丸矩形＋3灯）。
         * 🔴 旧データ（dotStyle 無しで実体化済みの交差点名）は下の●の枝に落ちる＝
         *    そのまま●で描き続ける（後方互換・変換はしない）。
         * 🔒 §30-25-18 3 / §30-30-1: 印の大きさは markSizeOf（基準 × markScale）。 */
        var sg = signalGeom(markSizeOf(o, size, mBase));
        layer.appendChild(el('rect', {
          x: (a.x - sg.w / 2).toFixed(1), y: (a.y - sg.h / 2).toFixed(1),
          width: sg.w.toFixed(1), height: sg.h.toFixed(1),
          rx: sg.rx.toFixed(1), ry: sg.rx.toFixed(1),
          'stroke-width': sg.lw,
          class: 'anno-signal' + (sel ? ' is-sel' : '') }));
        for (var sgi = -1; sgi <= 1; sgi++) {
          layer.appendChild(el('circle', {
            cx: (a.x + sgi * sg.gap).toFixed(1), cy: a.y.toFixed(1),
            r: sg.r.toFixed(2),
            class: 'anno-signal-lamp' + (sel ? ' is-sel' : '') }));
        }
      } else if (o.dotStyle === 'bus') {
        /* 🔒 2026-09-04: バス停は信号機を縦にしたような標識アイコン
         * （角丸矩形の板＋ポール＋逆さT字の足）。anchor は足の接地点＝
         * アイコンは anchor から上へだけ伸びる（signal の上下対称とは違う）。
         * 🔴 旧データ（dotStyle 無しで実体化済みのバス停）は下の●の枝に落ちる＝
         *    そのまま●で描き続ける（後方互換・変換はしない）。 */
        // 🔒 §30-25-18 3 / §30-30-1: 印の大きさは markSizeOf（基準 × markScale）
        var bg = busStopGeom(markSizeOf(o, size, mBase));
        var footY = a.y, poleTopY = footY - bg.pole, boardTopY = poleTopY - bg.bh;
        var busCls = 'anno-bus' + (sel ? ' is-sel' : '');
        layer.appendChild(el('line', {
          x1: (a.x - bg.foot / 2).toFixed(1), y1: footY.toFixed(1),
          x2: (a.x + bg.foot / 2).toFixed(1), y2: footY.toFixed(1),
          'stroke-width': bg.lw, class: busCls }));
        layer.appendChild(el('line', {
          x1: a.x.toFixed(1), y1: footY.toFixed(1),
          x2: a.x.toFixed(1), y2: poleTopY.toFixed(1),
          'stroke-width': bg.lw, class: busCls }));
        layer.appendChild(el('rect', {
          x: (a.x - bg.bw / 2).toFixed(1), y: boardTopY.toFixed(1),
          width: bg.bw.toFixed(1), height: bg.bh.toFixed(1),
          rx: bg.rx.toFixed(1), ry: bg.rx.toFixed(1),
          'stroke-width': bg.lw, class: busCls }));
      } else if (o.dotStyle === 'parking') {
        /* 🔒 §30-22-3 2: P マーク＝□の中に「P」。形の出どころは parkingGeom
         * （紙 export.js も同じ関数を読む＝信号機・バス停と同じ作法）。
         * 🔒 §30-25-18 3 / §30-30-1: 印の大きさは markSizeOf（基準 × markScale）。 */
        var pk = parkingGeom(markSizeOf(o, size, mBase));
        layer.appendChild(el('rect', {
          x: (a.x - pk.s / 2).toFixed(1), y: (a.y - pk.s / 2).toFixed(1),
          width: pk.s.toFixed(1), height: pk.s.toFixed(1),
          rx: pk.rx.toFixed(1), ry: pk.rx.toFixed(1),
          'stroke-width': pk.lw,
          class: 'anno-parking' + (sel ? ' is-sel' : '') }));
        var pt = el('text', { x: a.x.toFixed(1), y: a.y.toFixed(1),
          'font-size': pk.font.toFixed(1),
          class: 'anno-parking-p' + (sel ? ' is-sel' : '') });
        pt.textContent = 'P';
        layer.appendChild(pt);
      } else if (o.dotStyle === 'tree') {
        /* 🔒 §30-25-9: 木＝樹冠（線だけ・白塗り）＋幹。形の出どころは treeGeom /
         * treeCanopyPath の1か所（紙 export.js・道具の絵 app.js も同じ物を読む）。
         * anchor（a）は幹の下端＝印は a から上へだけ伸びる（バス停と同じ作法）。
         * 🔒 §30-25-18 3 / §30-30-1: 印の大きさは markSizeOf（基準 × markScale）。
         * 🔒 §30-30-2: 樹冠は**もこもこ**（7つのふくらみの輪郭・TREE.canopy）。 */
        var tg = treeGeom(markSizeOf(o, size, mBase));
        var trCls = 'anno-tree' + (sel ? ' is-sel' : '');
        layer.appendChild(el('line', {
          x1: a.x.toFixed(1), y1: a.y.toFixed(1),
          x2: a.x.toFixed(1), y2: (a.y - tg.trunk).toFixed(1),
          'stroke-width': tg.lw, class: trCls }));
        layer.appendChild(el('path', {
          d: treeCanopyPath(a.x, a.y + tg.cy, tg.r),
          'stroke-width': tg.lw, class: trCls + ' anno-tree-crown' }));
      } else if (o.dotStyle === 'double' || o.role === 'pinlabel') {
        /* 🔒 §30-25-37 1: ◎の輪の半径と線の太さに印の大きさ（markScale）を掛ける。
         * 🔴 倍率の出どころは markScaleOf 1か所（紙 export.js も同じ値を読む）。 */
        var ms = mainMarkScaleOf(o);
        /* 🔒 §30-25-40 2: 半径の出どころは mainRingR 1か所（つまみの位置と同じ式）
         * 🔒 §30-30-1: 基準（mBase）× 倍率＝文字の大きさに連動しない */
        var rr = mainRingR(o, size, mBase);
        /* 🔒 §28-14 ①-4: ◎も**色を選べる**（形2種×色3種）。色の key は o.markColor
         * （四角の印と同じ表＝ MARK.colors）。持っていない旧データは従来どおり
         * CSS（.anno-ring / .anno-core）の黒のまま。 */
        var dHex = o.markColor ? markHex(o) : '';
        var ring = el('circle', { cx: a.x.toFixed(1), cy: a.y.toFixed(1),
          r: rr.toFixed(1), class: 'anno-ring' + (sel ? ' is-sel' : '') });
        var core = el('circle', { cx: a.x.toFixed(1), cy: a.y.toFixed(1),
          r: (rr * 0.45).toFixed(1), class: 'anno-core' + (sel ? ' is-sel' : '') });
        // 線の太さも倍率どおりに（CSS の .anno-ring と同じ値 RING_W が出どころ）
        ring.style.strokeWidth = (RING_W * ms).toFixed(2);
        if (dHex && !sel) { ring.style.stroke = dHex; core.style.fill = dHex; }
        layer.appendChild(ring);
        layer.appendChild(core);
      } else {
        layer.appendChild(el('circle', { cx: a.x.toFixed(1), cy: a.y.toFixed(1),
          r: r0.toFixed(1), class: 'anno-dot' + (sel ? ' is-sel' : '') }));
      }
    }
    /* 🔒 §22-av: 路線番号の印（国道 ▽ / 都道府県道 六角形）を数字の**下に**敷く。
     * 白で塗るので、下の道路の線が数字に被らない。 */
    if (o.badge) {
      layer.appendChild(el('path', {
        d: badgePath(badgeGeom(o.text, size, o.badge), p.x, p.y),
        class: 'route-badge' + (sel ? ' is-sel' : '') }));
    }
    var t = el('text', { x: p.x.toFixed(1), y: p.y.toFixed(1),
      'font-size': size.toFixed(1), class: 'obj-text' + (sel ? ' is-sel' : '') });
    t.textContent = o.text || '';
    layer.appendChild(t);
    if (sel) {
      var w = emWidth(o.text) * size;          // §18-j: 実幅に合わせる
      layer.appendChild(el('rect', { x: p.x - w / 2 - 4, y: p.y - size * 0.8,
        width: w + 8, height: size * 1.5, fill: 'none', class: 'sel-box' }));
      /* 🔒 §30-22-3 3: 右下のつまみ＝ドラッグで大きさを変える。
       * 位置の出どころは textHandleAt（当たり判定と同じ1か所）。 */
      var th = this.textHandleAt(o);
      if (th) {
        var hc = el('circle', { cx: th.x.toFixed(1), cy: th.y.toFixed(1),
          r: HANDLE_TEXT, class: 'handle handle-text' });
        var htt = el('title', {});
        htt.textContent = 'ドラッグで文字の大きさを変える';
        hc.appendChild(htt);
        layer.appendChild(hc);
      }
      /* 🔒 §30-25-18 3: 印（信号機・バス停・P・木）の**絵の右下**にも小さなつまみ。
       * ドラッグで印だけの大きさ（markScale）が変わる（文字の大きさとは別）。
       * 🔴 文字が空でも出す（印だけ置いた時も大きさを変えられる）。
       * 🔴 位置の出どころは markHandleAt（当たり判定と同じ1か所）。 */
      var mh = this.markHandleAt(o);
      if (mh) {
        var mc = el('circle', { cx: mh.x.toFixed(1), cy: mh.y.toFixed(1),
          r: HANDLE_TEXT, class: 'handle handle-text' });
        var mtt = el('title', {});
        mtt.textContent = 'ドラッグで印の大きさを変える';
        mc.appendChild(mtt);
        layer.appendChild(mc);
      }
    }
  };

  /**
   * 方位記号（🔒 §28-3）。針＋'N'。at は**針の中心**。
   * 大きさは紙面ミリ基準（🔒 §30-25-7: mmPx() でズームに連動＝文字と同じ扱い）。
   * 形の出どころは compassGeom の1か所で、紙（export.js drawCompass）と同じ点列。
   */
  Editor.prototype._drawCompass = function (layer, o, sel) {
    if (!o.at) return;
    var p = this.map.project(o.at.lat, o.at.lng);
    // 🔒 §30-37 2: 大きさの出どころは compassRadiusMm（倍率 markScale 込み）1か所
    var g = compassGeom(compassRadiusMm(o) * this.mmPx());
    var d = '';
    for (var i = 0; i < g.pts.length; i++) {
      d += (i ? 'L' : 'M') + (p.x + g.pts[i][0]).toFixed(1)
         + ' ' + (p.y + g.pts[i][1]).toFixed(1) + ' ';
    }
    layer.appendChild(el('path', { d: d + 'Z', 'stroke-width': g.lw,
      class: 'compass-needle' + (sel ? ' is-sel' : '') }));
    var t = el('text', { x: p.x.toFixed(1), y: (p.y + g.labelY).toFixed(1),
      'font-size': g.labelSize.toFixed(1),
      class: 'obj-text compass-n' + (sel ? ' is-sel' : '') });
    t.textContent = 'N';
    layer.appendChild(t);
    if (sel) {
      var b = compassBox(g.r);
      layer.appendChild(el('rect', { x: (p.x - b.hw - 4).toFixed(1),
        y: (p.y + b.cy - b.hh - 3).toFixed(1),
        width: (b.hw * 2 + 8).toFixed(1), height: (b.hh * 2 + 6).toFixed(1),
        fill: 'none', class: 'sel-box' }));
      /* 🔒 §30-37 1・3: 印と同じ**右下のつまみ**で大きさを変える。
       * 🔴 位置の出どころは markHandleAt（当たり判定と同じ1か所・§22-z の教訓）。 */
      var ch = this.markHandleAt(o);
      if (ch) {
        var cc = el('circle', { cx: ch.x.toFixed(1), cy: ch.y.toFixed(1),
          r: HANDLE_TEXT, class: 'handle handle-text' });
        var ctt = el('title', {});
        ctt.textContent = 'ドラッグで方位記号の大きさを変える';
        cc.appendChild(ctt);
        layer.appendChild(cc);
      }
    }
  };

  /**
   * 駐車位置ラベルの塊（正典 §18-f 駐車位置ラベル）。
   * 1行目の見出し「保管場所」＋項目を左揃えで積み、対象の枠へ矢印を1本引く。
   * 🔴 矢印の終点（arrowTo）は塊を動かしても動かない（_moveSelection は at だけ）。
   */
  Editor.prototype._drawLabelBlock = function (layer, o, sel) {
    if (!o.at) return;
    var g = this.labelBlockGeom(o), st = o.style || {};
    var color = st.color || '#111';

    if (o.arrowTo) {
      var t = this.map.project(o.arrowTo.lat, o.arrowTo.lng);
      var s0 = boxEdgePoint(g, t, g.size * 0.3);
      var grp = el('g', {});
      grp.appendChild(el('line', { x1: s0.x.toFixed(1), y1: s0.y.toFixed(1),
        x2: t.x.toFixed(1), y2: t.y.toFixed(1), stroke: color,
        'stroke-width': st.w || 2, class: 'obj-line' + (sel ? ' is-sel' : '') }));
      var ang = Math.atan2(t.y - s0.y, t.x - s0.x), L = Math.max(7, g.size * 0.8);
      [-0.42, 0.42].forEach(function (d) {
        var e2 = ang + Math.PI + d;
        grp.appendChild(el('line', { x1: t.x.toFixed(1), y1: t.y.toFixed(1),
          x2: (t.x + Math.cos(e2) * L).toFixed(1),
          y2: (t.y + Math.sin(e2) * L).toFixed(1),
          stroke: color, 'stroke-width': st.w || 2,
          class: 'obj-line' + (sel ? ' is-sel' : '') }));
      });
      layer.appendChild(grp);
    }

    for (var i = 0; i < g.lines.length; i++) {
      var tx = el('text', {
        x: (g.x + g.pad).toFixed(1),
        y: (g.y + g.pad + g.lh * (i + 0.5)).toFixed(1),
        'font-size': g.size.toFixed(1), fill: color,
        class: 'obj-text is-lb' + (sel ? ' is-sel' : '') });
      tx.textContent = g.lines[i];
      layer.appendChild(tx);
    }

    if (sel) {
      layer.appendChild(el('rect', { x: g.x.toFixed(1), y: g.y.toFixed(1),
        width: g.w.toFixed(1), height: g.h.toFixed(1), fill: 'none', class: 'sel-box' }));
      // 右下＝大きさのつまみ
      layer.appendChild(el('rect', { x: (g.x + g.w - HANDLE).toFixed(1),
        y: (g.y + g.h - HANDLE).toFixed(1), width: HANDLE * 2, height: HANDLE * 2,
        class: 'handle' }));
      if (o.arrowTo) {
        var t2 = this.map.project(o.arrowTo.lat, o.arrowTo.lng);
        layer.appendChild(el('circle', { cx: t2.x.toFixed(1), cy: t2.y.toFixed(1),
          r: HANDLE, class: 'handle handle-rot' }));
      }
    }
  };

  /** 回転つまみを1つ置く（🔒 §18-t。四角も塊も同じ部品を使う） */
  Editor.prototype._rotHandle = function (layer, p) {
    layer.appendChild(el('circle', { cx: p.x.toFixed(1), cy: p.y.toFixed(1),
      r: HANDLE, class: 'handle handle-rot' }));
    var d = rotIconPath(p.x, p.y, HANDLE * 1.6);
    layer.appendChild(el('path', { d: d, class: 'rot-icon-halo' }));
    layer.appendChild(el('path', { d: d, class: 'rot-icon' }));
  };

  Editor.prototype._drawStamp = function (layer, g, sel) {
    var geo = this.stampGeom(g), st = g.style || {};
    var live = this.stampCells(g);
    var self = this;
    var skewing = sel && this.staggerMode;   // 枠をドラッグでずらせる状態
    live.forEach(function (i) {
      var c = self.stampCellCorners(g, i, geo);
      // 中央の枠は動かしようがないので、掴める枠だけ色を付ける
      var grabbable = skewing && Math.abs(i - (g.count - 1) / 2) >= 0.5;
      layer.appendChild(el('polygon', {
        points: c.map(function (p) { return p.x.toFixed(1) + ',' + p.y.toFixed(1); }).join(' '),
        fill: grabbable ? 'rgba(122,81,153,.13)' : 'none',
        stroke: skewing ? '#7a5199' : (st.color || '#111'),
        'stroke-width': st.w || 2,
        class: 'obj-rect' + (sel ? ' is-sel' : '') + (skewing ? ' is-skew' : '') }));
      var num = g.numbers && g.numbers[i];
      var mid = { x: (c[0].x + c[2].x) / 2, y: (c[0].y + c[2].y) / 2 };
      if (g.storage && g.storage[i]) self._drawStorage(layer, c, mid, g.storage[i]);
      /* 🔒 §30-22-3 2: 来客用（枠の中に「来客用」）・車いす（枠の中に ♿）。
       * 番号より先に描く（番号が上に乗る＝どちらも読める）。 */
      if (g.guest && g.guest[i]) self._drawCellText(layer, c, '来客用');
      // 🔒 §30-22-7 5: 車いすは絵文字ではなく自前の単色パス（白黒コピーに耐える）
      if (g.wheel && g.wheel[i]) self._drawCellWheel(layer, c);
      if (num != null) {
        // 🔒 §30-25-25: 大きさ＝標準(numberStdPx)と枠に収まる大きさの小さい方
        var ng = cellNumberGeom(c, String(num), self.numberStdPx());
        if (ng.size >= self.numberMinPx()) {
          var t = el('text', { x: ng.cx.toFixed(1), y: ng.cy.toFixed(1),
            'font-size': ng.size.toFixed(1), class: 'rect-number' });
          t.textContent = num;
          layer.appendChild(t);
        }
      }
      // 採番の起点、およびドラッグで通った枠を光らせる
      var lit = (self._numFrom && self._numFrom.group === g && self._numFrom.index === i)
        || (self._numStroke &&
            self._numStroke.keys.indexOf('g:' + g.id + ':' + i) >= 0);
      if (lit) {
        layer.appendChild(el('polygon', {
          points: c.map(function (p) { return p.x.toFixed(1) + ',' + p.y.toFixed(1); }).join(' '),
          class: 'num-from' }));
      }
    });

    // 1枠の実寸を代表表示（🔒 v4: 個別に［寸法(m)を図に出す］を入れた時だけ）
    if (live.length && g.showDims !== false) {
      var c0 = this.stampCellCorners(g, live[0], geo);
      var lx = (c0[0].x + c0[1].x) / 2, ly = (c0[0].y + c0[1].y) / 2;
      var ang = Math.atan2(c0[1].y - c0[0].y, c0[1].x - c0[0].x) * 180 / Math.PI;
      if (ang > 90 || ang < -90) ang += 180;
      var lab = el('text', { x: lx.toFixed(1), y: (ly - 9).toFixed(1), class: 'dim-label',
        transform: 'rotate(' + ang.toFixed(1) + ' ' + lx.toFixed(1) + ' ' + (ly - 9).toFixed(1) + ')' });
      lab.textContent = fmtM(g.cell_w_m) + '×' + fmtM(g.cell_h_m);
      layer.appendChild(lab);
    }

    if (sel) {
      var ca = Math.cos(rad(g.angle || 0)), sa = Math.sin(rad(g.angle || 0));
      var ctr = this.map.project(g.origin.lat, g.origin.lng);
      function toScreen(lx2, ly2) {
        return { x: ctr.x + lx2 * ca - ly2 * sa, y: ctr.y + lx2 * sa + ly2 * ca };
      }
      // 🔒 §30-14-5 2 / §30-25-17: 辺つまみは小さく・ZL で可変（edgeHandleR）
      var ehR = this.edgeHandleR();
      [[0, -geo.hh], [geo.hw, 0], [0, geo.hh], [-geo.hw, 0]].forEach(function (p) {
        var s = toScreen(p[0], p[1]);
        layer.appendChild(el('rect', { x: s.x - ehR, y: s.y - ehR,
          width: ehR * 2, height: ehR * 2, class: 'handle' }));
      });
      /* 🔒 §30-19-2: 塊の回転は矢羽よりかなり上。柄の線も矢羽の先（縁から 31）より
       * 上＝縁から ROT_STEM_STAMP_LINE から描き始める（矢羽と交差しない）。
       * 🔒 §30-19-3 1: 縁は**張り出し後**（stampTopEdge）＝矢羽と同じ基準。 */
      var edge = stampTopEdge(geo);
      var rp = toScreen(0, -edge - rotStemOf(g)),
          tp = toScreen(0, -edge - ROT_STEM_STAMP_LINE);
      layer.appendChild(el('line', { x1: tp.x, y1: tp.y, x2: rp.x, y2: rp.y, class: 'rot-stem' }));
      this._rotHandle(layer, rp);            // 🔒 §18-t: 回転だと分かるアイコン
      this._drawMoveCross(layer, g);         // 🔒 §30-14-5 3: 中心の移動の十字
    }
  };

  Editor.prototype._drawRect = function (layer, o, sel) {
    var c = this.rectCorners(o), st = o.style || {};
    var pts = c.map(function (p) { return p.x.toFixed(1) + ',' + p.y.toFixed(1); }).join(' ');
    /* 🔒 §25-4: 主役マーク（使用の本拠・駐車場）は**斜線ハッチ＋細い輪郭**。
     * 🔴 車両枠とは別物なので、寸法ラベル・番号・保管場所マーク・採番ハイライトは
     *    一切付けない（＝この分岐で以降を飛ばす）。 */
    var mark = (o.role === 'mainmark');
    if (mark) {
      var hex = markHex(o);
      layer.appendChild(el('polygon', { points: pts,
        fill: 'url(#' + HATCH_ID + (o.markColor || MARK.colors[0].key) + ')',
        stroke: hex, 'stroke-width': st.w || MARK.strokeW,
        'stroke-linejoin': 'miter',
        class: 'obj-mark' + (sel ? ' is-sel' : '') }));
    } else {
      layer.appendChild(el('polygon', {
        points: pts,
        fill: 'none', stroke: st.color || '#111', 'stroke-width': st.w || 2,
        'stroke-linejoin': 'round', class: 'obj-rect' + (sel ? ' is-sel' : '') }));

      // 自動の寸法は showDims で出し分ける。
      // ただし利用者が入れた値(labelOverride)は OFF でも必ず出す。
      if (o.showDims !== false) {
        this._dimLabel(layer, o, c, 'w');
        this._dimLabel(layer, o, c, 'h');
      } else if (o.labelOverride) {
        this._dimLabel(layer, o, c, (o.w_m >= o.h_m) ? 'w' : 'h');
      }

      // ドラッグ採番で通った四角も光らせる
      if (this._numStroke && this._numStroke.keys.indexOf('r:' + o.id) >= 0) {
        layer.appendChild(el('polygon', { points: pts, class: 'num-from' }));
      }
      var rc = this.map.project(o.center.lat, o.center.lng);
      if (o.storage) this._drawStorage(layer, c, rc, o.storage);
      if (o.number != null) {
        // 🔒 §30-25-25: 大きさ＝標準(numberStdPx)と枠に収まる大きさの小さい方
        var ng = cellNumberGeom(c, String(o.number), this.numberStdPx());
        if (ng.size >= this.numberMinPx()) {
          var t = el('text', { x: ng.cx.toFixed(1), y: ng.cy.toFixed(1),
            'font-size': ng.size.toFixed(1), class: 'rect-number' });
          t.textContent = o.number;
          layer.appendChild(t);
        }
      }
    }

    if (sel) {
      var h = this.rectHalf(o);
      var ca = Math.cos(rad(o.angle || 0)), sa = Math.sin(rad(o.angle || 0));
      var ctr2 = this.map.project(o.center.lat, o.center.lng);
      function toScreen(lx, ly) {
        return { x: ctr2.x + lx * ca - ly * sa, y: ctr2.y + lx * sa + ly * ca };
      }
      // 🔒 §30-14-5 2 / §30-25-17: 辺つまみは小さく・ZL で可変（edgeHandleR）
      /* 🔒 §30-31-1 1: 主役の■にも**4辺の辺つまみ**を出す（ふつうの四角と同じ形）。
       * 🔒 §30-35-3 1: 動くのは**掴んだ辺だけ**（反対の辺は固定＝ふつうの四角と
       * まったく同じ _resizeEdge の経路・中心はピンからずれる）。 */
      var ehR2 = this.edgeHandleR();
      [[0, -h.hh], [h.hw, 0], [0, h.hh], [-h.hw, 0]].forEach(function (p) {
        var s = toScreen(p[0], p[1]);
        layer.appendChild(el('rect', { x: s.x - ehR2, y: s.y - ehR2,
          width: ehR2 * 2, height: ehR2 * 2, class: 'handle' }));
      });
      /* 🔒 §30-25-40 3: 主役の■は**右下の角**にもつまみを出す（印つき文字の
       * つまみと同じ見た目＝ handle-text）＝縦横を同じ比率で変える。
       * 🔴 位置は当たり判定（hitHandle の geo.hw / geo.hh）と同じ角。
       * 🔴 辺つまみの**後**に足す（重なった時に角が上＝当たり判定の順と揃う）。 */
      if (mark) {
        var mhp = toScreen(h.hw, h.hh);
        var mhc = el('circle', { cx: mhp.x.toFixed(1), cy: mhp.y.toFixed(1),
          r: HANDLE_TEXT, class: 'handle handle-text' });
        var mhT = el('title', {});
        mhT.textContent = 'ドラッグで印の大きさを変える（辺のつまみは縦・横だけ）';
        mhc.appendChild(mhT);
        layer.appendChild(mhc);
      }
      // 🔒 §30-19-3 1: 四角は張り出しが無いので rotEdgeOf は h.hh のまま（今までどおり）
      var rp = toScreen(0, -rotEdgeOf(o, h) - rotStemOf(o)), tp = toScreen(0, -h.hh);
      layer.appendChild(el('line', { x1: tp.x, y1: tp.y, x2: rp.x, y2: rp.y, class: 'rot-stem' }));
      this._rotHandle(layer, rp);            // 🔒 §18-t: 回転だと分かるアイコン
      this._drawMoveCross(layer, o);         // 🔒 §30-14-5 3: 中心の移動の十字
    }
  };

  /**
   * 🔒 §30-14-5 3: 図形の**中心**に置く移動の十字（✥）。
   * 白丸（r = MOVE_R）＋青の十字矢印。ドラッグ＝図形ごと移動（hitHandle が
   * kind:'move' を返し、図形の中を掴んだ時とまったく同じ経路に流れる）。
   * 🔴 出す図形の判定は _hasMoveCross の1か所（当たり判定と同じ物を見る）。
   * 🔴 十字は**回さない**（画面の上下左右にまっすぐ＝「動かす」の意味が読める）。
   */
  Editor.prototype._drawMoveCross = function (layer, o) {
    if (!this._hasMoveCross(o)) return;
    var anchor = o.center || o.origin;
    if (!anchor) return;
    var c = this.map.project(anchor.lat, anchor.lng);
    var x = Math.round(c.x * 10) / 10, y = Math.round(c.y * 10) / 10;
    var a = MOVE_R - 2;            // 矢の先までの長さ
    var b = 2.6;                   // 矢頭の開き
    var t = a - 3;                 // 矢頭の根元
    var d = 'M' + (x - a) + ' ' + y + 'H' + (x + a)
          + 'M' + x + ' ' + (y - a) + 'V' + (y + a)
          // 4つの矢頭
          + 'M' + (x - t) + ' ' + (y - b) + 'L' + (x - a) + ' ' + y + 'L' + (x - t) + ' ' + (y + b)
          + 'M' + (x + t) + ' ' + (y - b) + 'L' + (x + a) + ' ' + y + 'L' + (x + t) + ' ' + (y + b)
          + 'M' + (x - b) + ' ' + (y - t) + 'L' + x + ' ' + (y - a) + 'L' + (x + b) + ' ' + (y - t)
          + 'M' + (x - b) + ' ' + (y + t) + 'L' + x + ' ' + (y + a) + 'L' + (x + b) + ' ' + (y + t);
    var g = el('g', { class: 'move-cross' });
    g.appendChild(el('circle', { cx: x, cy: y, r: MOVE_R, class: 'move-cross-bg' }));
    g.appendChild(el('path', { d: d, class: 'move-cross-icon' }));
    var ttl = el('title', {});
    ttl.textContent = 'ドラッグで動かす';
    g.appendChild(ttl);
    layer.appendChild(g);
  };

  Editor.prototype._dimLabel = function (layer, o, c, which) {
    var txt, p0, p1;
    if (which === 'w') { txt = fmtM(o.w_m); p0 = c[0]; p1 = c[1]; }
    else { txt = fmtM(o.h_m); p0 = c[1]; p1 = c[2]; }
    if (o.labelOverride) {
      if (which === 'w' && o.w_m >= o.h_m) txt = o.labelOverride;
      else if (which === 'h' && o.h_m > o.w_m) txt = o.labelOverride;
    }
    var mx = (p0.x + p1.x) / 2, my = (p0.y + p1.y) / 2;
    var ctr = this.map.project(o.center.lat, o.center.lng);
    var vx = mx - ctr.x, vy = my - ctr.y;
    var len = Math.hypot(vx, vy) || 1;
    var lx = mx + vx / len * 13, ly = my + vy / len * 13;
    var ang = Math.atan2(p1.y - p0.y, p1.x - p0.x) * 180 / Math.PI;
    if (ang > 90 || ang < -90) ang += 180;
    var t = el('text', { x: lx.toFixed(1), y: ly.toFixed(1), class: 'dim-label',
      transform: 'rotate(' + ang.toFixed(1) + ' ' + lx.toFixed(1) + ' ' + ly.toFixed(1) + ')' });
    t.textContent = txt;
    layer.appendChild(t);
  };

  /**
   * 主役マークのオブジェクトを1個作る（🔒 §25-4）。
   * 所在図の生成（shozaizu.js）から呼ぶ。**定数は MARK 表だけを見る**ので、
   * 大きさ・色を直したい時はこのファイルの MARK を触れば全経路に効く。
   * @param {'home'|'lot'} kind 使用の本拠 / 駐車場
   * @param {{lat:number,lng:number}} p 中心
   * @param {string} id 付けたい id（省略時は自動）
   * @param {string} color 色の key（🔒 §28-14 ①-4 でガイダンス①が選んだ色。
   *        省略・未知の値なら従来どおり MARK.kinds の既定色＝本拠 赤／駐車場 オレンジ）
   */
  /* 🔒 §30-25-37 1: scale（印の大きさ・0.5〜3・既定 1）。四角の実寸と紙の最小 mm に
   *    掛かる。倍率は図形にも `markScale` として控える（引き直しと保存のため）。 */
  /* 🔒 §30-31-1 2: 第6引数 dims（{w_m,h_m}）＝案件に入っている**縦横**。
   *    渡されればそれが真実（基準×倍率は dims が無い時の既定だけ）。
   * 🔒 §30-35-3 4: dims に **dx_m / dy_m**（■の中心 − ピン・東と北の m）があれば、
   *    中心は「ピン＋ずれ」。無ければ従来どおりピンそのもの（旧案件＝ずれ 0）。 */
  Editor.makeMark = function (kind, p, id, color, scale, dims) {
    var k = MARK.kinds[kind] || MARK.kinds.home;
    var col = k.color;
    for (var ci = 0; ci < MARK.colors.length; ci++) {
      if (MARK.colors[ci].key === color) col = color;
    }
    var dim = markRectDims(kind, scale);
    var mw = (dims && dims.w_m > 0) ? dims.w_m : dim.w_m;
    var mh = (dims && dims.h_m > 0) ? dims.h_m : dim.h_m;
    var ctr = (dims && (dims.dx_m || dims.dy_m))
            ? offsetLatLng(p, dims.dx_m, dims.dy_m) : p;
    var o = { id: id || uid(), type: 'rect',
              center: { lat: ctr.lat, lng: ctr.lng },
              w_m: mw, h_m: mh, markScale: dim.scale, angle: 0,
              /* 🔴 車両枠と混同させないための固有の印。
               *    寸法ラベルを出さず、枠数・敷き詰め・提出前チェックの対象外。 */
              role: 'mainmark', markRole: kind,
              markColor: col, hatch: 'diag', showDims: false,
              style: { color: '', w: MARK.strokeW },
              source: 'shozaizu' };
    o.style.color = markHex(o);
    return o;
  };

  /**
   * 主役の多角形（🔒 §30-22-1 4）を1個作る。
   * 四角の主役マーク（makeMark）と**同じ役目**＝ role:'mainmark'。
   * 🔴 どちらの地点かは既存の主役マークと同じ `markRole`（'home'|'lot'）で持つ。
   *    正典 §30-22-5 A の `markKey` はこれと同じ物（実装は markRole に一本化した）。
   * @param {'home'|'lot'} kind
   * @param {Array} points 頂点（緯度経度）
   * @param {{width:string,color:string,hatch:boolean}} opt 既定は 標準・黒・斜線あり
   */
  Editor.makeMainPoly = function (kind, points, opt) {
    opt = opt || {};
    var k = (kind === 'lot') ? 'lot' : 'home';
    var wKey = opt.width || 'normal';
    var cKey = opt.color || 'black';
    return {
      id: opt.id || uid(), type: 'polygon',
      points: points.map(function (p) { return { lat: p.lat, lng: p.lng }; }),
      closed: true,
      role: 'mainmark', markRole: k,
      widthKey: wKey, inkColor: cKey,
      hatch: (opt.hatch === undefined) ? true : !!opt.hatch,
      showDims: false,
      style: { w: polyW(wKey), color: inkHex(cKey) },
      source: 'shozaizu'
    };
  };

  Editor.TEXT_PX = TEXT_PX;
  Editor.MARK = MARK;
  /* 🔒 §28-14 ①-4: 色の key → 16進。ガイダンス①（app.js）が、既に生成してある
   * 主役の印の色を書き換える時に使う（表は MARK.colors の1か所のまま）。 */
  Editor.markHex = markHex;
  /* 🔒 2026-09-02: 交差点名の信号機アイコン。reveal.js（薄出し）・export.js（紙）が
   * この1か所を読む＝3か所で必ず同じ見た目になる。 */
  Editor.SIGNAL = SIGNAL;
  Editor.signalGeom = signalGeom;
  /* 🔒 2026-09-04: バス停の標識アイコン。reveal.js（薄出し）・export.js（紙）が
   * この1か所を読む＝3か所で必ず同じ見た目になる（Editor.SIGNAL と同じ作法）。 */
  Editor.BUSSTOP = BUSSTOP;
  Editor.busStopGeom = busStopGeom;
  /* 🔒 §30-22-3 2: P マークの印。export.js（紙）がここを読む（SIGNAL と同じ作法） */
  Editor.PARKING = PARKING;
  Editor.parkingGeom = parkingGeom;
  /* 🔒 §30-25-9: 木の印（樹冠＋幹）。export.js（紙）・app.js（道具の絵）が
   * ここを読む＝絵と図に入る印が食い違わない（SIGNAL と同じ作法）。 */
  Editor.TREE = TREE;
  Editor.treeGeom = treeGeom;
  /* 🔒 §30-30-2: もこもこの樹冠。輪郭（円の和集合）の組み立ては treeCanopyArcs 1か所で、
   * 画面（SVG path）＝ treeCanopyPath ／ 紙（canvas の arc）＝ treeCanopyArcs ／
   * 道具の絵（app.js）＝ treeCanopyPath が同じ数値から描く。 */
  Editor.treeCanopyArcs = treeCanopyArcs;
  Editor.treeCanopyPath = treeCanopyPath;
  /* 🔒 §30-22-10: 印の半幅・縦のずれ（size と同じ単位）と、「印のすぐ隣」の置き場所。
   * 所在図（shozaizu.js）の「名前の位置＝近く」がここを読む＝規則は1か所。 */
  Editor.markGeom = markGeom;
  Editor.markTextOffset = markTextOffset;
  /* 🔒 §30-25-18 3: 印の大きさ（markScale）。紙（export.js）・右パネル（app.js）・
   * 読み込み（store.js）が**同じ1か所**を読む＝画面と紙で必ず同じ大きさになる。 */
  Editor.MARK_SCALE_RANGE = MARK_SCALE_RANGE;
  Editor.markScaleOf = markScaleOf;
  Editor.clampMarkScale = clampMarkScale;
  /* 🔒 §30-32-2: 駐車位置ラベルの塊の大きさ（倍率）の上下限。画面のつまみと
   * プレビューのつまみが**同じ1か所**を読む＝範囲が割れない。 */
  Editor.LABEL_SCALE_RANGE = LABEL_SCALE_RANGE;
  Editor.clampLabelScale = clampLabelScale;
  Editor.markSizeOf = markSizeOf;
  /* 🔒 §30-30-1: 印の基準の大きさ（紙のミリ）。紙（export.js）・薄出し
   * （reveal.js / namelay.js）がここを読む＝文字の大きさに連動しない値の出どころ1か所。 */
  Editor.markBaseMm = markBaseMm;
  Editor.mainRingR = mainRingR;
  Editor.keepsMark = keepsMark;
  /* 🔒 §30-25-40: その図形が主役の印（◎＝主役の文字／■＝主役の四角）か。
   * app.js（右パネルの「印の大きさ」）が読む＝判定は1か所。 */
  Editor.mainMarkKeyOf = mainMarkKeyOf;
  /* 🔒 §30-25-37: 主役の印（◎・■）の大きさ。■の実寸は markRectDims（基準×倍率）、
   * ◎の輪の太さは RING_W（CSS .anno-ring・紙 export.js と同じ値）。
   * app.js（applyMarkChoice／▼「印を変える」）・export.js が読む1か所。 */
  Editor.markRectDims = markRectDims;
  /* 🔒 §30-31-1 3: ■の紙の最小 mm（縦横それぞれ）。画面（rectHalf）と
   * 紙（export.js rectCorners）が同じ値を読む＝長方形の比が広域でも崩れない。 */
  Editor.markMinMm = markMinMm;
  /* 🔒 §30-35-3 4: ■の中心とピンの**ずれ**（東・北の実距離 m）の換算1か所。
   * app.js（setMainMarkDims／applyMarkChoice／syncRoleObjects）と
   * Editor.makeMark が同じ関数を読む＝ m ⇄ 緯度経度の式を2か所に持たない。 */
  Editor.offsetLatLng = offsetLatLng;
  Editor.offsetMeters = offsetMeters;
  Editor.RING_W = RING_W;
  /* 🔒 §30-22-1 4 / §30-22-4 9: 線の色（黒／赤／青）・太さ3段・保管場所の書式。
   * app.js（右パネル）・export.js（紙）がここを読む＝値の出どころは1か所 */
  Editor.INK = INK;
  Editor.inkHex = inkHex;
  Editor.POLY_W = POLY_W;
  Editor.polyW = polyW;
  Editor.polyCentroid = polyCentroid;
  /* 🔒 §30-24-1: その地点の主役の多角形（描いた順）。app.js（ピン追従・印の種類の
   * 後始末）と store.js が同じ並びを見る＝「最初の1つ」の定義は1か所 */
  Editor.mainPolysOf = mainPolysOf;
  Editor.storageConf = storageConf;
  Editor.STORAGE_W = STORAGE_W;
  /* 🔒 §30-22-3 3: 文字の紙面ミリ（連続値 sizeMm ／ 無ければ3段の既定）。
   * export.js（紙）がここを読む＝画面と紙で必ず同じ大きさになる */
  Editor.textMm = textMmOf;
  /* 🔒 §30-25-10 2: 文字の大きさ（紙のミリ）の上限・下限。app.js のプレビューの
   * つまみが読む＝画面のつまみと同じ範囲になる。 */
  Editor.TEXT_MM_RANGE = TEXT_MM_RANGE;
  Editor.clampTextMm = clampTextMm;
  Editor.cellTextGeom = cellTextGeom;
  /* 🔒 §30-25-25: 駐車枠の番号の大きさ（標準 or 枠に収まる、の小さい方）。
   * export.js（紙）の drawStamp／drawRect の番号がここを読む＝画面と紙で同じ規則 */
  Editor.cellNumberGeom = cellNumberGeom;
  /* 🔒 §30-22-7 5: 車いすの印（自前の単色パス）。export.js（紙）がここを読む */
  Editor.WHEELCHAIR = WHEELCHAIR;
  Editor.cellIconGeom = cellIconGeom;
  /* 🔒 §28-3: 方位記号の部品。export.js（紙）・shozaizu.js（名前よけ）・app.js
   * （［枠を決定］で1個置く）がここを読む＝画面と紙で必ず同じ形になる。 */
  Editor.COMPASS = COMPASS;
  Editor.compassGeom = compassGeom;
  Editor.compassBox = compassBox;
  /* 🔒 §30-37 2: 方位記号の**大きさ（紙面mm）の出どころ1か所**（基準 × markScale）。
   * 紙（export.js drawCompass）・名前よけ（shozaizu.js）はこれに物差しを掛ける
   * ＝ COMPASS.rMm を直接読まない。 */
  Editor.compassRadiusMm = compassRadiusMm;
  Editor.makeCompass = makeCompass;
  /* 画面px と紙面mm の換算（TEXT_PX.large 19px ＝ SHEET_TEXT_MM.large 4.4mm）。
   * app.js が方位記号の画面上の大きさを出すのに読む */
  Editor.SHEET_MM_PX = SHEET_MM_PX;
  /* 🔒 §22-am-2: 引き出し線の太さ・破線。export.js（紙）がここを読む＝画面と紙で同じ */
  Editor.LEAD = LEAD;
  /* 🔒 §22-am-6-2: 引き出し線の幾何は3か所（画面・紙・なぞり中）で同じ物を使う */
  Editor.leadStop = leadStop;
  Editor.wantLead = wantLead;
  Editor.textDrawWidth = textDrawWidth;
  /* 🔒 §22-av: 路線番号の印（▽・六角形）。export.js（紙）・shozaizu.js（配置）が読む */
  Editor.badgeGeom = badgeGeom;
  Editor.badgePath = badgePath;
  Editor.drawHalfWidth = drawHalfWidth;
  /* 🔒 §23-9: 所在図の地図スタイル（道路2種・建物の線）。
   * shozaizu.js（生成）・export.js（紙）・reveal.js（実体化）がここを読む。 */
  Editor.MAPSTYLE = MAPSTYLE;
  Editor.roadBand = roadBand;
  Editor.isCasingRoad = isCasingRoad;
  /* 🔒 §30-25-4: 「道路」の判定（描く順・当たり判定の両方が読む唯一の実装）。
   * export.js（紙の drawObjects）も自前で書かずにここを読む。 */
  Editor.isRoad = isRoad;
  /* 🔒 §30-38-2 / §30-38-5 1: 「頂点を足せる図形か」の判定はここ1か所。
   * app.js（配置図で選んだ時の一言）も自前で書かずにここを読む。 */
  Editor.canAddVertex = canAddVertex;
  Editor.ROAD_STYLE_DEFAULT = 'line';   // 既存案件・新規案件の既定（後方互換）
  Editor.markHex = markHex;
  Editor.fmtM = fmtM;
  global.Editor = Editor;
})(typeof window !== 'undefined' ? window : this);
