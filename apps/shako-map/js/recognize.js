/* recognize.js — 取り込み画像から駐車枠を読み取る（R3・正典 §16-10-k / §16-10-l）
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * 🔴 前提（正典 §1-6 / §11-b の三分法）
 *   1. **完全ローカル**。画像も解析結果も外へ出さない。依存ライブラリも無し
 *   2. 認識をかけてよいのは**本人・お客様が権利を持つ画像**だけ（呼び出し側で確認する）
 *
 * ===== R3「検出即枠」の背骨（オーナー指示・§16-10-k）=====
 *   オーナー: 「今の方式＝格子モデルを推定してモデルの位置に枠をスタンプ、では写真で使えない。
 *              この図から分かるのは**同じサイズの四角が8個ある**こと。そして**8台と入力済み**。
 *              これだけで確定できる」「**線が無い所に線を描く。これはありえない**」
 *
 *   1. **生成の全廃**。枠は「検出された実物のコピー」だけ。
 *      モデル（周期・位相）を推定して位置にスタンプする経路は R2 から**全部消した**
 *      （等差数列フィット `apFits`・グリッド切り `bandCuts`・位相外挿は削除）
 *   2. **台数 N は会計係**。解の生成にも選択にも使わない。同サイズ群の照合・過不足の案内・打切りだけ
 *   3. **予測は「探す場所のヒント」であって「描く根拠」ではない**（§16-10-l の背骨）
 *   4. どの周でも**画素の根拠が無ければ記帳しない**。最後に全枠を画素で再検証して落とす（L4）
 *
 * ===== 4層構成（正典 §16-10-l）=====
 *   L1 検出器3種: (a) 囲み四角（閉領域） (b) 線オブジェクト（端点・長さ・向き・太さを持つ実体）
 *                 (c) 車ブロブ（同サイズ・整列・等間隔のまとまり）
 *   L2 予測層   : 外周＋確定済み物差しから「列がありうる帯」を出す。layout.js の容量計算を転用
 *   L3 台帳     : 根拠タグつきの確定枠リスト。厳格な第1周 → 未記帳の帯だけ第2周（予測との一致が条件）
 *   L4 ハードゲート: 全出力枠の境界に画素根拠を要求。無い枠は落とす
 *
 * 内部の単位は**ピクセルだけ**（R2 から継承）。メートルは「ラスタ解像度を決める1行」と
 * 「枠を出力する最後の1回」にしか出てこない＝取り込み倍率が変わっても結果は変わらない。
 */
(function (global) {
  'use strict';

  /* ================= 定数（px か「比」しか持たない） ================= */

  var MAX_PX = 1100;           // 解析ラスタの長辺(px)上限
  var ANGLE_SPAN = 10;         // 外周の辺から許す振れ(度)
  var ANGLE_STEP = 2;          // その刻み(度)
  var MAX_DIRS = 3;            // 使う辺方向の数（長い順）
  var DIAG_OFFSETS = [30, 45, 60, 120, 135, 150];  // 斜め駐車の救済（枠が全く採れない時だけ）
  var MIN_PITCH_PX = 4;        // これ未満の周期は画素として意味がない
  var MAX_CELLS_ACROSS = 40;   // 稜線の太さの上限を決める目安 = 投影長 / 40
  var RIDGE_K = 3.0;           // 稜線のしきい（ノイズの床の何倍か）
  var RIDGE_PCT = 0.5;         // ノイズの床＝|detrend| のこの分位（🔴 下げてはいけない・§16-19⑤）
  var PERIOD_AC_MIN = 0.45;    // 密な縞の救済を許す自己相関の下限（§16-19⑤）
  var RIDGE_FLOOR = 4;         // 稜線の最低コントラスト（階調）
  var MAX_RIDGES = 60;         // 1角度あたりに見る稜線の本数
  var SEG_MIN_PX = 5;          // 線分と認める最短長(px)。🔴 ピッチ比にしない
                               //   （車で線が隠れて端しか見えない時、その「端」が唯一の証人）
  /* 枠の幅 ÷ 奥行。普通車 2.5/5.0=0.5・軽 2.0/5.0=0.4。手前後ろに余裕を見て広めに取る */
  var W_D_MIN = 0.28;
  var W_D_MAX = 1.05;
  var OVL_MIN = 0.5;           // 線分どうしの重なり ≥ この倍 × その族の代表長
  var BOX_FILL = 0.85;         // 閉領域が四角と認められる充填率（§16-10-l L1-a）
  var BOX_ASPECT_MAX = 4.0;    // 細長すぎる閉領域は枠でない
  var SIZE_TOL = 0.25;         // 同サイズとみなす許容（±25%）
  var CAR_ASPECT_MIN = 1.4;    // 車の縦横比（≈2:1）
  var CAR_ASPECT_MAX = 3.2;
  var CAR_FILL = 0.5;          // 車の塊の充填率
  var MIN_LINES = 3;           // 列と認める仕切り線の本数。🔴 2本は「車1台の輪郭」と区別できない
  var ROW_MIN_CARS = 3;        // 車列と認める台数。🔴 2台は「通路に停めた車」と区別できない
  var MIN_ROW_CELLS = 3;       // 「列が採れた」と言える枠数（斜め救済に行くかの判断）
  var SIZE_KEEP_MIN = 0.6;     // 主群のサイズに対して、残してよい枠の大きさの下限
  var SIZE_KEEP_MAX = 1.7;     // 同・上限
  var OCC_FILL = 0.78;         // 「間が車で埋まっている」と認める連続率
  var COVER_STRICT = 0.6;      // 第2周で枠を認める辺のインク被覆
  var COVER_GATE = 0.45;       // 最終ゲートで辺に線があると認める被覆（🔴 監査 EDGE_COVER と同値）
  var EDGES_STRICT = 3;        // 第2周は4辺のうち何辺にインクが要るか
  var TAN_HALF = 3;            // インクを測る時、線に沿って平均する幅(±px)
  var NEAR_PX = 2;             // 枠の位置ずれの許容(px)
  var INK_MIN = 8;             // インクの下限（階調）
  var NOISE_PCT = 0.92;        // 自己較正: 敷地内をでたらめに測った値のこの分位を
  var NOISE_K = 1.2;           //           ノイズの天井とし、その何倍を超えたら本物か
  var MAX_ROUNDS = 3;          // 台帳の照合ループの上限
  var MAX_CELLS = 200;         // 出力の上限（暴走よけ）
  var GAP_SLOTS_MAX = 1;       // 🔴 挟まれ空きは**1枠分まで**（2枠以上の空白は描かない）

  function rad(d) { return d * Math.PI / 180; }
  /* 🔴 枠の向きは **[0, π) に畳んで持つ**。
   * 枠は点対称なので th と th+π は同じ物だが、`uc/vc` は th のフレームで測った値なので
   * **同じ群の中に th=0 と th=π が混ざると座標系が食い違う**（(u,v) が (-u,-v) になる）。
   * 実測 B2: 閉領域の1つだけ「90°アンカーで du>dv」→ th=π になり、
   * その枠が群の先頭だったため `reprobe` が群全員の (uc,vc) を π のフレームで読み、
   * 候補がラスタ外（-116,-186）へ飛んで**第2周が1つも走らなかった**（＝ハッチのマスが拾えない）。 */
  function normTh(t) { var p = Math.PI; return ((t % p) + p) % p; }
  function med(arr) {
    if (!arr.length) return 0;
    var a = arr.slice().sort(function (x, y) { return x - y; });
    return a[Math.floor(a.length / 2)];
  }

  /* 解析を細切れに実行するための「次の隙間」。
   * setTimeout(...,0) は裏タブだと1秒に間引かれるので MessageChannel を使う。 */
  function yieldSoon(fn) {
    if (global.MessageChannel) {
      var ch = new global.MessageChannel();
      ch.port1.onmessage = function () { ch.port1.close(); fn(); };
      ch.port2.postMessage(0);
      return;
    }
    setTimeout(fn, 0);
  }

  /* ================= 解析用ラスタ（ここから先は px だけ） ================= */

  function buildRaster(polygonLL, placement, image) {
    var frame = Layout._makeFrame(polygonLL[0]);
    var poly = polygonLL.map(frame.toXY);            // 見かけm（地図と同じ単位）
    var minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
    poly.forEach(function (p) {
      if (p.x < minX) minX = p.x; if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y; if (p.y > maxY) maxY = p.y;
    });
    var wM = Math.max(1e-6, maxX - minX), hM = Math.max(1e-6, maxY - minY);
    var imgW = image.naturalWidth || image.width || 1;
    /* 解像度: 外周の長辺を MAX_PX に収める。ただし元画像より細かくしても情報は増えないので、
     * 元画素の4倍までに抑える（速度と安定のため）。ここでしか「m」は出てこない。 */
    var srcPxPerM = imgW / Math.max(1e-6, placement.w_m);
    var pxPerM = Math.min(MAX_PX / Math.max(wM, hM), srcPxPerM * 4);
    var W = Math.max(16, Math.round(wM * pxPerM));
    var H = Math.max(16, Math.round(hM * pxPerM));

    var cv = document.createElement('canvas');
    cv.width = W; cv.height = H;
    var g = cv.getContext('2d', { willReadFrequently: true });
    /* 🔴 **拡大する時は補間しない**（§16-10-f 画像不可侵の原則）。
     * 小さく切り出した航空写真は最大4倍に引き伸ばされる。双一次補間で拡大すると
     * 隣り合う元画素が混ざり、**元画像には無い中間値**が生まれる。
     * すると「元画素の刻みで測ったつもり」のインク値の分散が実際の 1/2〜1/4 になり、
     * 自己較正のノイズ天井が下がって**根拠の無い枠がゲートを通る**
     * （実測 B4a: エンジン 39.0 に対し、同じ画像を元解像度で測るベンチの監査は 67.4）。
     * 縮小の時は逆にモアレが出るので補間を残す。 */
    var upscaling = pxPerM > srcPxPerM;
    if (upscaling) {
      g.imageSmoothingEnabled = false;
      g.mozImageSmoothingEnabled = false;
      g.webkitImageSmoothingEnabled = false;
      g.msImageSmoothingEnabled = false;
    }
    g.save();
    g.beginPath();
    poly.forEach(function (p, i) {
      var x = (p.x - minX) * pxPerM, y = (p.y - minY) * pxPerM;
      if (i) g.lineTo(x, y); else g.moveTo(x, y);
    });
    g.closePath();
    g.clip();                                   // ← 外周の内側だけを描く
    var c = frame.toXY(placement.center);
    g.translate((c.x - minX) * pxPerM, (c.y - minY) * pxPerM);
    g.rotate(rad(placement.angle || 0));
    var iw = placement.w_m * pxPerM, ih = iw * placement.ratio;
    g.drawImage(image, -iw / 2, -ih / 2, iw, ih);
    g.restore();

    var d = g.getImageData(0, 0, W, H).data;
    var lum = new Float32Array(W * H), mask = new Uint8Array(W * H), n = 0;
    for (var i = 0; i < W * H; i++) {
      if (d[i * 4 + 3] > 10) {
        mask[i] = 1; n++;
        lum[i] = 0.299 * d[i * 4] + 0.587 * d[i * 4 + 1] + 0.114 * d[i * 4 + 2];
      }
    }
    // 元画像1画素がラスタ何画素か（線の細さの下限に使う）
    var srcScale = pxPerM / srcPxPerM;
    return { frame: frame, poly: poly, minX: minX, minY: minY, pxPerM: pxPerM,
             W: W, H: H, lum: lum, mask: mask, valid: n, srcScale: srcScale };
  }

  /* ================= 座標（内部は全て px） ================= */

  function uvToPx(th, u, v) {
    var cos = Math.cos(th), sin = Math.sin(th);
    return { x: u * cos - v * sin, y: u * sin + v * cos };
  }
  function pxToUv(th, x, y) {
    var cos = Math.cos(th), sin = Math.sin(th);
    return { u: x * cos + y * sin, v: -x * sin + y * cos };
  }
  /** px の (u,v) → 緯度経度（**出力時だけ**呼ぶ） */
  function uvToLL(r, th, u, v) {
    var q = uvToPx(th, u, v);
    return r.frame.toLL({ x: q.x / r.pxPerM + r.minX, y: q.y / r.pxPerM + r.minY });
  }
  function lumXY(r, x, y) {
    var xi = Math.round(x), yi = Math.round(y);
    if (xi < 0 || yi < 0 || xi >= r.W || yi >= r.H) return null;
    var i = yi * r.W + xi;
    return r.mask[i] ? r.lum[i] : null;
  }
  function lumAt(r, th, u, v) {
    var q = uvToPx(th, u, v);
    return lumXY(r, q.x, q.y);
  }
  function insidePoly(r, th, u, v) {
    var q = uvToPx(th, u, v);
    var x = Math.round(q.x), y = Math.round(q.y);
    if (x < 0 || y < 0 || x >= r.W || y >= r.H) return false;
    return !!r.mask[y * r.W + x];
  }

  /* ================= インク（|画素 − 局所背景|）の測り方 =================
   *
   * 🔴 R3 の全判定はここに帰着する。「線がある」＝**画素がそう言っている**という意味に統一した。
   * 1画素の値をそのまま使うと砂利・芝のざらつきが全部インクに見えるので、
   * **線に沿って平均してから**左右の背景と比べる（線は長さ方向に続くがノイズは続かない）。 */

  /* 🔴 インクは**元画像の画素の刻み**で測る（§16-10-i スケールフリー化の徹底）。
   *
   * 小さく切り出した航空写真はラスタへ最大4倍に引き伸ばされる。TAN_HALF=3 を
   * **ラスタ px** のまま使うと、25点平均しているようで**実体は元画像の6画素ぶん**しか見ていない
   * （しかも双一次補間で滑らかに繋がった値）。その結果**ノイズの天井が実際より低く出て**、
   * 自己較正のしきい値が下がり、根拠の無い枠がゲートを通る。
   * 実測 B4a: エンジンのしきい値 39.8 に対し、同じ画像を**元解像度で**測るベンチの監査は 67.4。
   * 1.7倍の食い違いがあり、ベンチが「4辺とも被覆 0.00」と判定した枠をエンジンは通していた。
   *
   * 直し方: 歩幅を `srcScale`（＝元画像1画素）にする。これで平均する点が
   * **互いに独立した元画素**になり、ラスタ倍率が変わってもインクの意味が変わらない。 */
  function stepOf(r) { return Math.max(1, r.srcScale); }

  function alongMean(r, px, py, tx, ty, nx, ny, o) {
    var s = 0, n = 0, st = stepOf(r);
    for (var t = -TAN_HALF; t <= TAN_HALF; t++) {
      var v = lumXY(r, px + tx * t * st + nx * o, py + ty * t * st + ny * o);
      if (v !== null) { s += v; n++; }
    }
    return n >= TAN_HALF ? s / n : null;
  }

  /** 1点でのインクらしさ（法線方向に元画素 ±NEAR_PX ずらして最大を採る） */
  function inkAt(r, px, py, tx, ty, nx, ny, dU) {
    var best = 0, got = false, st = stepOf(r);
    for (var k = -NEAR_PX; k <= NEAR_PX; k++) {
      var o = k * st;
      var c = alongMean(r, px, py, tx, ty, nx, ny, o);
      if (c === null) continue;
      var b1 = alongMean(r, px, py, tx, ty, nx, ny, o - dU);
      var b2 = alongMean(r, px, py, tx, ty, nx, ny, o + dU);
      var bg = (b1 === null) ? b2 : (b2 === null ? b1 : (b1 + b2) / 2);
      if (bg === null) continue;
      got = true;
      best = Math.max(best, Math.abs(c - bg));
    }
    return got ? best : null;
  }

  /**
   * 🔴 インクのしきい値を**その画像で自己較正する**（決定的・種は固定）。
   * 敷地の中をでたらめな位置・向きで測った値の上位分位を「ノイズの天井」とし、
   * その NOISE_K 倍を超えた物だけをインクとみなす。
   * 図面（ノイズ皆無）では INK_MIN、砂利・芝ではその粒に応じて自動で上がる。
   */
  function calibrateInk(r, dU) {
    var dirs = [[1, 0], [0, 1], [0.7071, 0.7071], [0.7071, -0.7071]];
    var vals = [], s = 20260819, tries = 0;
    function rnd() { s = (s * 1103515245 + 12345) & 0x7fffffff; return s / 0x7fffffff; }
    while (vals.length < 260 && tries < 5200) {
      tries++;
      var x = rnd() * r.W, y = rnd() * r.H;
      if (lumXY(r, x, y) === null) continue;
      var d = dirs[(rnd() * 4) | 0];
      var v = inkAt(r, x, y, d[0], d[1], -d[1], d[0], dU);
      if (v !== null) vals.push(v);
    }
    if (vals.length < 30) return INK_MIN;
    vals.sort(function (a, b) { return a - b; });
    return Math.max(INK_MIN, vals[Math.floor(vals.length * NOISE_PCT)] * NOISE_K);
  }

  /** 枠の4辺それぞれの「インクが乗っている割合」 */
  function edgeCover(r, c, thr) {
    var th = c.th, w = c.w, d = c.d;
    var ux = Math.cos(th), uy = Math.sin(th);      // 幅方向
    var vx = -Math.sin(th), vy = Math.cos(th);     // 奥行方向
    var o = uvToPx(th, c.uc, c.vc);
    /* 背景を測る距離も**元画像の画素**で下限を置く（tanHalfOf と同じ理由） */
    var dU = Math.max(3 * r.srcScale, Math.min(w, d) * 0.22);
    function P(du, dv) { return [o.x + ux * du + vx * dv, o.y + uy * du + vy * dv]; }
    var edges = [
      [P(-w / 2, -d * 0.42), P(-w / 2, d * 0.42), ux, uy],
      [P(w / 2, -d * 0.42), P(w / 2, d * 0.42), ux, uy],
      [P(-w * 0.42, -d / 2), P(w * 0.42, -d / 2), vx, vy],
      [P(-w * 0.42, d / 2), P(w * 0.42, d / 2), vx, vy]
    ];
    return edges.map(function (e) {
      var a = e[0], b = e[1];
      var len = Math.hypot(b[0] - a[0], b[1] - a[1]) || 1;
      var tx = (b[0] - a[0]) / len, ty = (b[1] - a[1]) / len;
      var hit = 0, tot = 0, S = 16;
      for (var i = 0; i <= S; i++) {
        var t = i / S;
        var v = inkAt(r, a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t,
                      tx, ty, e[2], e[3], dU);
        if (v === null) continue;
        tot++;
        if (v >= thr) hit++;
      }
      return tot ? hit / tot : 0;
    });
  }

  /* ================= 敷地の代表値（舗装の明るさ・ざらつき） ================= */

  /**
   * 敷地の代表値。
   *   mean … 舗装の明るさ（全体の中央値。舗装がいちばん広いので中央値＝舗装）
   *   mad  … 🔴 **きめの粗さ（局所のざらつき）**。全体のばらつきではない
   *
   * 🔴 ここを「全体の中央絶対偏差」にしていたのが実写が読めない原因だった（実測 B4a）。
   *   建物・車・道路が混ざった航空写真では全体のばらつきが大きく（mad=25）、
   *   そこから作ったしきい値（55階調）を超えるのは白い屋根と影だけ。
   *   **車が1台も塊にならず**、13×23px の破片が14個できて終わっていた。
   *   欲しいのは「センサやきめのゆらぎ」なので、隣の画素との差で測る。
   */
  function siteBaseline(r) {
    var vals = [], dev = [], i;
    for (i = 0; i < r.W * r.H; i += 7) {          // 間引いて中央値（決定的）
      if (r.mask[i]) vals.push(r.lum[i]);
    }
    if (vals.length < 40) return null;
    vals.sort(function (a, b) { return a - b; });
    var m = vals[Math.floor(vals.length / 2)];
    var step = Math.max(1, Math.round(r.srcScale));
    for (i = 0; i + step < r.W * r.H; i += 5) {
      if (r.mask[i] && r.mask[i + step] && ((i % r.W) + step) < r.W) {
        dev.push(Math.abs(r.lum[i] - r.lum[i + step]));
      }
    }
    /* 🔴 `pave` ＝**小ブロックの平均値の中央値**（＝枠くらいの大きさで見た時の舗装の明るさ）。
     * `mean`（画素そのものの中央値）とは別に要る。
     * ハードゲートは「枠の**平均**が舗装と違うか」を見るのに、比べる相手が
     * **1画素の中央値**では尺度が合わない。影や小さな暗い物が画素の中央値を引き下げるので、
     * 枠の平均との差が実際より大きく出て、**根拠の無い枠が通る**。
     * 実測 B5 の1枠: 画素中央値 121.3 との差は 16.3（＝ゲート通過）だが、
     * ブロック平均の中央値 126.7 との差は 11.1（＝舗装と区別が付かない）。
     * ベンチの根拠監査も後者で測っており、この枠を「根拠なし」と判定していた。 */
    var blk = Math.max(8, Math.round(r.srcScale * 8)), bm = [], x, y, dx, dy;
    for (y = 0; y + blk <= r.H; y += blk) {
      for (x = 0; x + blk <= r.W; x += blk) {
        var s = 0, n2 = 0;
        for (dy = 0; dy < blk; dy += 2) {
          for (dx = 0; dx < blk; dx += 2) {
            var q = (y + dy) * r.W + (x + dx);
            if (r.mask[q]) { s += r.lum[q]; n2++; }
          }
        }
        if (n2 >= 6) bm.push(s / n2);
      }
    }
    bm.sort(function (a, b) { return a - b; });
    var pave = bm.length >= 4 ? bm[Math.floor(bm.length / 2)] : m;
    if (dev.length < 40) return { mean: m, mad: 3, pave: pave };
    dev.sort(function (a, b) { return a - b; });
    return { mean: m, mad: Math.max(1, dev[Math.floor(dev.length / 2)]), pave: pave };
  }

  /* ================= L1-a 囲み四角（閉領域） =================
   *
   * 図面のマス・写真の箱型白枠は「インクで囲まれた領域」として**実在する**。
   * 二値化 → 背景を外から flood fill → 届かなかった領域＝閉領域 → 充填率で四角を選ぶ。
   * 🔴 これが R3 で図面を読む本筋（線の周期を推定する必要が無い）。 */

  /**
   * インクの二値化（白線でも黒線でも同じ＝極性不問・§16-10-l L1-a）。
   *
   * 🔴 局所平均（箱平均）をそのまま背景にしてはいけない。線の近くでは平均が線に引っ張られ、
   *   **線のまわり半窓ぶんが丸ごとインク扱いになる**（＝ハロー）。実測: 窓51px で B1 のマスが
   *   123×246px → 73×80px に痩せ、文字のハローと壁がつながってマスが上下に割れた。
   *   なので **2段階**にする:
   *     ① 敷地全体の代表値（中央値）から粗くインクを決める
   *     ② その粗インクを**除いた画素だけ**で局所平均を取り直し、それを背景にする
   *   これで日照ムラ（写真）に追随しつつ、ハローが消える。
   */
  function inkMask(r, base, opt) {
    opt = opt || {};
    var W = r.W, H = r.H, i;
    var thr = Math.max(10, (base ? base.mad : 3) * (opt.thrK || 4));
    var rough = new Uint8Array(W * H);
    var bm = base ? base.mean : 128;
    for (i = 0; i < W * H; i++) {
      if (r.mask[i] && Math.abs(r.lum[i] - bm) > thr) rough[i] = 1;
    }
    // ② 粗インクを除いた画素だけの積分画像
    var win = Math.max(31, Math.round(Math.min(W, H) / (opt.winDiv || 8))) | 1;
    var half = (win - 1) / 2;
    var is = new Float64Array((W + 1) * (H + 1)), ic = new Float64Array((W + 1) * (H + 1));
    for (var y = 0; y < H; y++) {
      for (var x = 0; x < W; x++) {
        var k = y * W + x, p = (y + 1) * (W + 1) + (x + 1);
        var ok = (r.mask[k] && !rough[k]) ? 1 : 0;
        is[p] = (ok ? r.lum[k] : 0) + is[p - 1] + is[p - (W + 1)] - is[p - (W + 1) - 1];
        ic[p] = ok + ic[p - 1] + ic[p - (W + 1)] - ic[p - (W + 1) - 1];
      }
    }
    function boxMean(x0, y0, x1, y1) {
      x0 = Math.max(0, x0); y0 = Math.max(0, y0);
      x1 = Math.min(W - 1, x1); y1 = Math.min(H - 1, y1);
      var a = (y1 + 1) * (W + 1) + (x1 + 1), b = y0 * (W + 1) + (x1 + 1);
      var c = (y1 + 1) * (W + 1) + x0, e = y0 * (W + 1) + x0;
      var cnt = ic[a] - ic[b] - ic[c] + ic[e];
      return cnt >= 8 ? (is[a] - is[b] - is[c] + is[e]) / cnt : null;
    }
    /* ③ しきい値は**残差そのものの分布**から決める（自己較正）。
     * 🔴 別の統計（隣接画素差など）から決めてはいけない。航空写真は大小の構造が
     *   あらゆる尺度に入っているので、隣接画素差から作った 10階調では
     *   **ROI の 83% が「物」になった**（実測 B4a）。 */
    var res = new Float32Array(W * H), samp = [];
    for (y = 0; y < H; y++) {
      for (x = 0; x < W; x++) {
        var q = y * W + x;
        if (!r.mask[q]) continue;
        var bg = boxMean(x - half, y - half, x + half, y + half);
        if (bg === null) bg = bm;
        res[q] = Math.abs(r.lum[q] - bg);
        if ((q % 7) === 0) samp.push(res[q]);
      }
    }
    samp.sort(function (a, b) { return a - b; });
    var medRes = samp.length ? samp[Math.floor(samp.length / 2)] : 0;
    thr = Math.max(opt.absMin || 10, medRes * (opt.thrK || 4));
    var ink = new Uint8Array(W * H);
    for (i = 0; i < W * H; i++) if (r.mask[i] && res[i] >= thr) ink[i] = 1;
    /* 車は「明るい車体＋暗いガラス」で1台が2つ3つに割れる。閉じて1台に戻す */
    if (opt.close) ink = erode(dilate(ink, W, H, opt.close), W, H, opt.close);
    return { ink: ink, thr: thr };
  }

  /** 1画素ぶん痩せさせる（太らせた後に戻す＝穴や隙間だけを塞ぐ「閉じ」） */
  function erode(src, W, H, rad2) {
    var out = src;
    for (var it = 0; it < rad2; it++) {
      var nx = new Uint8Array(W * H);
      for (var y = 0; y < H; y++) {
        for (var x = 0; x < W; x++) {
          var i = y * W + x;
          if (!out[i]) continue;
          if ((x > 0 && !out[i - 1]) || (x + 1 < W && !out[i + 1]) ||
              (y > 0 && !out[i - W]) || (y + 1 < H && !out[i + W])) continue;
          nx[i] = 1;
        }
      }
      out = nx;
    }
    return out;
  }

  /** 1画素ぶん太らせる（手描きの角の隙間を塞いで閉領域にする） */
  function dilate(src, W, H, rad2) {
    var out = src;
    for (var it = 0; it < rad2; it++) {
      var nx = new Uint8Array(W * H);
      for (var y = 0; y < H; y++) {
        for (var x = 0; x < W; x++) {
          var i = y * W + x;
          if (out[i]) { nx[i] = 1; continue; }
          if ((x > 0 && out[i - 1]) || (x + 1 < W && out[i + 1]) ||
              (y > 0 && out[i - W]) || (y + 1 < H && out[i + W])) nx[i] = 1;
        }
      }
      out = nx;
    }
    return out;
  }

  /**
   * 閉領域（インクに囲まれた領域）を列挙し、外接矩形と充填率を測る。
   * 角度は外周の辺に係留した候補の中から、いちばん充填率の高い物を選ぶ。
   */
  function closedBoxes(r, anchors, seal, base) {
    var W = r.W, H = r.H, i;
    var im = inkMask(r, base);
    var ink = dilate(im.ink, W, H, seal);
    // 外側 = 外周の外 ∪ 縁から届く非インク
    var outside = new Uint8Array(W * H);
    var stack = new Int32Array(W * H), sp = 0;
    for (i = 0; i < W * H; i++) {
      if (!r.mask[i]) { outside[i] = 1; }
    }
    function push(i2) {
      if (i2 < 0 || i2 >= W * H || outside[i2] || ink[i2]) return;
      outside[i2] = 1; stack[sp++] = i2;
    }
    for (i = 0; i < W * H; i++) {
      if (!outside[i]) continue;
      var x0 = i % W, y0 = (i / W) | 0;
      if (x0 > 0) push(i - 1);
      if (x0 + 1 < W) push(i + 1);
      if (y0 > 0) push(i - W);
      if (y0 + 1 < H) push(i + W);
    }
    for (var x = 0; x < W; x++) { push(x); push((H - 1) * W + x); }
    for (var y = 0; y < H; y++) { push(y * W); push(y * W + W - 1); }
    while (sp > 0) {
      var q = stack[--sp], qx = q % W, qy = (q / W) | 0;
      if (qx > 0) push(q - 1);
      if (qx + 1 < W) push(q + 1);
      if (qy > 0) push(q - W);
      if (qy + 1 < H) push(q + W);
    }
    // 閉領域をラベリングしつつ、候補角度ごとの外接範囲を測る
    var seen = new Uint8Array(W * H), boxes = [];
    var ths = anchors.map(function (a) { return rad(a); });
    var minSide = Math.max(4, r.srcScale * 2);
    for (i = 0; i < W * H; i++) {
      if (seen[i] || outside[i] || ink[i]) continue;
      var ext = ths.map(function () {
        return { u0: Infinity, u1: -Infinity, v0: Infinity, v1: -Infinity };
      });
      var area = 0;
      sp = 0; stack[sp++] = i; seen[i] = 1;
      while (sp > 0) {
        var p = stack[--sp], px = p % W, py = (p / W) | 0;
        area++;
        for (var t = 0; t < ths.length; t++) {
          var c2 = pxToUv(ths[t], px, py), e = ext[t];
          if (c2.u < e.u0) e.u0 = c2.u; if (c2.u > e.u1) e.u1 = c2.u;
          if (c2.v < e.v0) e.v0 = c2.v; if (c2.v > e.v1) e.v1 = c2.v;
        }
        if (px > 0 && !seen[p - 1] && !outside[p - 1] && !ink[p - 1]) { seen[p - 1] = 1; stack[sp++] = p - 1; }
        if (px + 1 < W && !seen[p + 1] && !outside[p + 1] && !ink[p + 1]) { seen[p + 1] = 1; stack[sp++] = p + 1; }
        if (py > 0 && !seen[p - W] && !outside[p - W] && !ink[p - W]) { seen[p - W] = 1; stack[sp++] = p - W; }
        if (py + 1 < H && !seen[p + W] && !outside[p + W] && !ink[p + W]) { seen[p + W] = 1; stack[sp++] = p + W; }
      }
      if (area < minSide * minSide) continue;
      var best = null;
      for (t = 0; t < ths.length; t++) {
        var e2 = ext[t];
        var du = e2.u1 - e2.u0 + 1, dv = e2.v1 - e2.v0 + 1;
        if (du < minSide || dv < minSide) continue;
        var fill = area / (du * dv);
        if (!best || fill > best.fill) {
          best = { fill: fill, th: ths[t], du: du, dv: dv,
                   uc: (e2.u0 + e2.u1) / 2, vc: (e2.v0 + e2.v1) / 2 };
        }
      }
      if (!best || best.fill < BOX_FILL) continue;
      var asp = Math.max(best.du, best.dv) / Math.max(1, Math.min(best.du, best.dv));
      if (asp > BOX_ASPECT_MAX) continue;
      // 幅は短い方・奥行は長い方（駐車枠は幅より深い）。太らせたぶんを戻す
      var grow = seal * 2 + 1;
      var wide = best.du <= best.dv;
      var w = (wide ? best.du : best.dv) + grow, dd = (wide ? best.dv : best.du) + grow;
      var th2 = normTh(wide ? best.th : best.th + Math.PI / 2);
      var cc = uvToPx(best.th, best.uc, best.vc);
      var uv = pxToUv(th2, cc.x, cc.y);
      boxes.push({ uc: uv.u, vc: uv.v, w: w, d: dd, th: th2,
                   fill: best.fill, area: area, basis: 'box' });
      if (boxes.length > 400) break;
    }
    return boxes;
  }

  /** 大きさの近い箱をまとめる（同サイズ・クラスタ） */
  function sizeClusters(items) {
    var used = [], out = [];
    items.forEach(function (a, i) {
      if (used[i]) return;
      var grp = [a];
      used[i] = 1;
      items.forEach(function (b, j) {
        if (used[j] || j === i) return;
        if (Math.abs(b.w - a.w) <= a.w * SIZE_TOL &&
            Math.abs(b.d - a.d) <= a.d * SIZE_TOL) { grp.push(b); used[j] = 1; }
      });
      out.push(grp);
    });
    out.sort(function (p, q) { return q.length - p.length; });
    return out;
  }

  /* ================= L1-b 線オブジェクト ================= */

  /**
   * 角度 th で u 軸へ投影した明るさ（1px 刻み）。ok=有効な列
   * vLo/vHi を渡すと、線方向（v）の一部だけを投影する。
   * 🔴 これが実写で効く。敷地の一部にしか駐車列が無いのに敷地全体を平均すると、
   *   **列の白線が薄まって消える**（実測 B4a: 敷地の1/4を占める列の線が、全体投影では稜線に立たない）。
   */
  function profile(r, th, step, vLo, vHi) {
    var cos = Math.cos(th), sin = Math.sin(th);
    var corners = [[0, 0], [r.W, 0], [0, r.H], [r.W, r.H]];
    var uMin = Infinity, uMax = -Infinity;
    corners.forEach(function (p) {
      var u = p[0] * cos + p[1] * sin;
      if (u < uMin) uMin = u; if (u > uMax) uMax = u;
    });
    var n = Math.max(8, Math.ceil(uMax - uMin) + 1);
    var sum = new Float32Array(n), cnt = new Float32Array(n);
    var lim = (vLo !== undefined && vHi !== undefined);
    step = step || 1;
    for (var y = 0; y < r.H; y += step) {
      for (var x = 0; x < r.W; x += step) {
        var i = y * r.W + x;
        if (!r.mask[i]) continue;
        if (lim) {
          var vv = -x * sin + y * cos;
          if (vv < vLo || vv > vHi) continue;
        }
        var b = Math.round(x * cos + y * sin - uMin);
        if (b < 0 || b >= n) continue;
        sum[b] += r.lum[i]; cnt[b] += 1;
      }
    }
    var maxCnt = 0;
    for (var k = 0; k < n; k++) if (cnt[k] > maxCnt) maxCnt = cnt[k];
    var need = Math.max(2, maxCnt * 0.25);
    var val = new Float32Array(n), ok = new Uint8Array(n);
    for (k = 0; k < n; k++) {
      if (cnt[k] >= need) { val[k] = sum[k] / cnt[k]; ok[k] = 1; }
    }
    return { uMin: uMin, n: n, val: val, ok: ok, cnt: cnt };
  }

  /** 局所背景（移動平均）との差。win は px */
  function detrend(p, win) {
    win = Math.max(3, Math.round(win)) | 1;
    var half = (win - 1) / 2;
    var ps = new Float64Array(p.n + 1), pc = new Float64Array(p.n + 1);
    for (var i = 0; i < p.n; i++) {
      ps[i + 1] = ps[i] + (p.ok[i] ? p.val[i] : 0);
      pc[i + 1] = pc[i] + (p.ok[i] ? 1 : 0);
    }
    var out = new Float32Array(p.n);
    for (i = 0; i < p.n; i++) {
      if (!p.ok[i]) continue;
      var lo = Math.max(0, i - half), hi = Math.min(p.n - 1, i + half);
      var c = pc[hi + 1] - pc[lo];
      if (c > 0) out[i] = p.val[i] - (ps[hi + 1] - ps[lo]) / c;
    }
    return out;
  }

  /**
   * 稜線（線の候補位置）を拾う。
   * 🔴 **|画素 − 局所背景| の山**なので、白線でも黒線でも同じ経路で拾える。
   */
  function ridges(r, p, win, maxWidth) {
    var sig = detrend(p, win);
    var abs = [], i;
    for (i = 0; i < p.n; i++) if (p.ok[i]) abs.push(Math.abs(sig[i]));
    if (!abs.length) return [];
    /* 🔴 ここが B5（PLATEAU 広域凹形）が読めない**唯一の原因**。機序は特定済み・直し方は未確定。
     *
     * ノイズの床を |detrend| の**中央値**で取ると、
     * 「探している物が投影を埋め尽くしている時」に**しきい値が自分で自分を消す**。
     * 仕切り線が密で規則正しいほど中央値は線の振幅に近づき、しきい値（中央値×3）が
     * **線の山より上に来る**。デューティ比 20% の縞では中央値|AC| ≈ 0.6×山なので
     * thr ≈ 1.8×山 ＝ **どんなに濃い縞でも原理的に検出できない**。
     *
     * 実測 B5（白線列・ピッチ 20px・投影の生値 127→157→138→113→114 と明瞭）:
     *   detrend 後の山 30〜35 / 中央値 11.93 → thr 35.8 → **稜線 0 本**（15% 足りない）。
     *
     * 🔴 **試して却下した直し（§16-19⑤ に実測表）**: 床を下位分位に変える／RIDGE_K を下げる。
     *   どちらも B5 は 26〜31枠まで出るようになるが、**B4a が 25〜67枠に暴発して
     *   根拠なし枠が 2〜13個**出る。分位 0.50→0.45→0.42→0.40→0.35→0.30 の合格数は
     *   19→16→18→17→18→16 と**非単調で不安定**＝ここは調整で越えられる崖ではない。
     *   次に触る人は、しきい値をいじるのではなく
     *   **「密な縞」を別経路（規則性を候補生成にだけ使う・§16-10-l L2）で拾う**ことを検討すること。 */
    var sorted = abs.slice().sort(function (a, b) { return a - b; });
    var floorNoise = sorted[Math.floor(sorted.length * RIDGE_PCT)];
    var thr = Math.max(RIDGE_FLOOR, floorNoise * RIDGE_K);
    var out = [];
    for (i = 1; i + 1 < p.n; i++) {
      if (!p.ok[i]) continue;
      var a = Math.abs(sig[i]);
      if (a < thr) continue;
      if (a < Math.abs(sig[i - 1]) || a < Math.abs(sig[i + 1])) continue;
      var half = a / 2, lo = i, hi = i;
      while (lo > 0 && p.ok[lo - 1] && Math.abs(sig[lo - 1]) > half) lo--;
      while (hi < p.n - 1 && p.ok[hi + 1] && Math.abs(sig[hi + 1]) > half) hi++;
      var width = hi - lo + 1;
      if (width > maxWidth) continue;                  // 太い明暗は線ではない
      out.push({ u: p.uMin + i, v: a, sign: sig[i] >= 0 ? 1 : -1, width: width });
    }
    out.sort(function (x, y) { return x.u - y.u; });
    var keep = [];
    out.forEach(function (pk) {
      var last = keep[keep.length - 1];
      if (last && pk.u - last.u < Math.max(2, r.srcScale * 1.5)) {
        if (pk.v > last.v) keep[keep.length - 1] = pk;
      } else keep.push(pk);
    });
    return keep;
  }

  /**
   * 🔴 密な縞の救済（§16-19⑤）。B5（PLATEAU 広域凹形）を 0枠 → 13枠にした経路。
   *
   * `ridges` の「中央値×K」は、**縞が投影を埋め尽くすと自分で自分を消す**。
   * そこで「投影に強い周期が立っている時だけ」、**1周期につき1本**だけ候補位置を足す。
   *
   * 🔴 R3 の背骨は壊さない（§16-10-l L2）:
   *   ここで作るのは**探す場所の仮説**であって枠ではない。実際にそこが塗られているかは
   *   `segmentsAt` が画素で確かめ、最後に L4 のハードゲートがもう一度確かめる。
   *   位相を外挿して「線を描く」ことは一切しない。
   *
   * 自己抑制の量: 候補は最大 n/周期 本（＝重なりようがない）。周期が立たなければ0本。
   */
  function periodicRidges(r, p, win, maxWidth) {
    var sig = detrend(p, win), n = p.n, i, L;
    // いちばん長い連続有効区間を使う（外周の外は ok=0 になる）
    var bs = -1, bl = 0, cs = -1, cl = 0;
    for (i = 0; i < n; i++) {
      if (p.ok[i]) { if (cs < 0) { cs = i; cl = 0; } cl++; if (cl > bl) { bl = cl; bs = cs; } }
      else { cs = -1; cl = 0; }
    }
    if (bl < 40) return [];

    /* 🔴 周期は**投影の一部分**でしか立たない。ここを外すと何も見つからない。
     * 実測 B5（真のピッチ 20px）: 自己相関の山は
     *   投影の全域        … lag 60（AC 0.40）／lag 20 は **AC 0.14** で埋もれる
     *   縞のある u 範囲だけ … **lag 20 で AC 0.90** ← 真のピッチがはっきり立つ
     * 敷地の大半は建物・道路・車路なので、全域で相関を取ると
     * **大きな構造の周期に負ける**。だから u 方向にも窓を切って探す。 */
    var out = [];
    var segLen = Math.max(120, Math.round(bl / 3));
    var step = Math.max(40, Math.round(segLen / 2));
    for (var a0 = bs; a0 < bs + bl - 40; a0 += step) {
      var a1 = Math.min(bs + bl, a0 + segLen);
      if (a1 - a0 < 40) break;
      var e0 = 0;
      for (i = a0; i < a1; i++) e0 += sig[i] * sig[i];
      if (e0 <= 0) continue;
      var lagMax = Math.min(Math.floor((a1 - a0) / 4), 240), best = null;
      for (L = Math.max(MIN_PITCH_PX, Math.ceil(r.srcScale * 2)); L <= lagMax; L++) {
        var s = 0, m = 0;
        for (i = a0; i + L < a1; i++) { s += sig[i] * sig[i + L]; m++; }
        if (m < 8) break;
        var ac = s / e0 * ((a1 - a0) / m);         // 重なりの短さを補正
        if (!best || ac > best.ac) best = { ac: ac, L: L };
      }
      if (!best || best.ac < PERIOD_AC_MIN) continue;
      L = best.L;
      // 位相は「その位相に並ぶ |sig| の合計」がいちばん大きい所（＝実際に線が来ている位相）
      var bestPh = 0, bestSc = -1;
      for (var ph = 0; ph < L; ph++) {
        var sc = 0;
        for (i = a0 + ph; i < a1; i += L) sc += Math.abs(sig[i]);
        if (sc > bestSc) { bestSc = sc; bestPh = ph; }
      }
      // 1周期につき1本だけ、位相の近く（±L/4）の山を候補にする
      var half = Math.max(1, Math.floor(L / 4));
      for (var c = a0 + bestPh; c < a1; c += L) {
        var pi = -1, pv = 0;
        for (i = Math.max(a0, c - half); i <= Math.min(a1 - 1, c + half); i++) {
          var av = Math.abs(sig[i]);
          if (av > pv) { pv = av; pi = i; }
        }
        if (pi < 1 || pi + 1 >= n || pv < RIDGE_FLOOR) continue;
        if (pv < Math.abs(sig[pi - 1]) || pv < Math.abs(sig[pi + 1])) continue;
        var h2 = pv / 2, lo2 = pi, hi2 = pi;
        while (lo2 > 0 && p.ok[lo2 - 1] && Math.abs(sig[lo2 - 1]) > h2) lo2--;
        while (hi2 < n - 1 && p.ok[hi2 + 1] && Math.abs(sig[hi2 + 1]) > h2) hi2++;
        var w2 = hi2 - lo2 + 1;
        if (w2 > maxWidth) continue;
        out.push({ u: p.uMin + pi, v: pv, sign: sig[pi] >= 0 ? 1 : -1, width: w2 });
      }
    }
    return out;
  }

  /**
   * 稜線の位置 u で線方向(v)へ走査し、**実際に塗られている区間**を線分として取り出す。
   * 🔴 これが「線オブジェクト」の実体（端点・長さ・向き・太さを持つ）。
   *   取れなければその候補は捨てる＝根拠の無い場所に線は無い。
   */
  function segmentsAt(r, th, u, dU, thr, width) {
    var diag = Math.hypot(r.W, r.H);
    /* 十字の交点・文字の被りで消える幅は「直交線の太さ ＋ 背景を測る距離の2倍」 */
    var maxGap = Math.max(3, dU * 2 + Math.max(3, r.srcScale * 3));
    var runs = [], cur = null, gap = 0, sign = 0;

    function contrastAt(v) {
      var s = 0, n = 0, k;
      for (k = -1; k <= 1; k++) {
        var c = lumAt(r, th, u, v + k);
        if (c !== null) { s += c; n++; }
      }
      if (!n) return null;
      var line = s / n, bs = 0, bn = 0;
      [-dU, dU, -dU * 1.6, dU * 1.6].forEach(function (o) {
        var b = lumAt(r, th, u + o, v);
        if (b !== null) { bs += b; bn++; }
      });
      if (!bn) return null;
      return line - bs / bn;                       // 符号つき（白線=+ / 黒線=-）
    }
    function close() {
      if (cur && cur.v1 - cur.v0 >= SEG_MIN_PX) {
        var mean = cur.n ? cur.sum / cur.n : 0;
        if (Math.abs(mean) >= thr) {
          runs.push({ th: th, u: u, v0: cur.v0, v1: cur.v1,
                      len: cur.v1 - cur.v0, contrast: Math.abs(mean),
                      width: width, sign: mean >= 0 ? 1 : -1 });
        }
      }
      cur = null; gap = 0;
    }
    for (var v = -diag; v <= diag; v += 1) {
      var c2 = contrastAt(v);
      var on = (c2 !== null && Math.abs(c2) >= thr * 0.7
                && (!sign || (c2 >= 0 ? 1 : -1) === sign));
      if (on) {
        if (!cur) { cur = { v0: v, v1: v, sum: 0, n: 0 }; sign = c2 >= 0 ? 1 : -1; }
        cur.v1 = v; cur.sum += c2; cur.n++; gap = 0;
      } else if (cur) {
        gap += 1;
        if (gap > maxGap) { close(); sign = 0; }
      }
    }
    close();
    return runs;
  }

  /** 線方向(v)の広がり（ラスタの4隅から） */
  function vRange(r, th) {
    var cos = Math.cos(th), sin = Math.sin(th);
    var lo = Infinity, hi = -Infinity;
    [[0, 0], [r.W, 0], [0, r.H], [r.W, r.H]].forEach(function (p) {
      var v = -p[0] * sin + p[1] * cos;
      if (v < lo) lo = v; if (v > hi) hi = v;
    });
    return { lo: lo, hi: hi };
  }

  /**
   * 角度 th で線オブジェクトを全部取り出す。
   * 🔴 投影は**全体＋線方向の3つの帯**で行い、稜線の候補位置を合わせて使う。
   *   敷地の一部にしか列が無い実写で、全体投影だけだと線が薄まって1本も立たない。
   *   位置の候補が増えるだけで、採否は `segmentsAt`（実際に塗られているか）が決める。
   */
  function lineObjects(r, th) {
    var vr = vRange(r, th), span = vr.hi - vr.lo;
    var wins = [[undefined, undefined]];
    if (span > 40) {
      wins.push([vr.lo, vr.lo + span * 0.55]);
      wins.push([vr.lo + span * 0.225, vr.lo + span * 0.775]);
      wins.push([vr.lo + span * 0.45, vr.hi]);
    }
    var all = [], lo = 0, dU = 0, maxW = 0;
    wins.forEach(function (w) {
      var p = profile(r, th, 1, w[0], w[1]);
      lo = Math.max(MIN_PITCH_PX, p.n / MAX_CELLS_ACROSS);
      /* 稜線の太さの上限は「元画像の画素」でも考える。小さく切り出した航空写真は
       * ラスタへ4倍に引き伸ばされるので、元1px の白線がラスタでは4px 幅になる。 */
      maxW = Math.max(lo * 0.5, r.srcScale * 1.6);
      dU = Math.max(1.5, lo * 0.3);
      ridges(r, p, lo * 2.2, maxW).forEach(function (pk) { all.push(pk); });
      /* 🔴 密な縞は上の稜線検出が構造的に落とすので、周期が立っている時だけ候補を足す。
       * 足すのは**位置の候補**だけ。実際に塗られているかは `segmentsAt` が決める。 */
      periodicRidges(r, p, lo * 2.2, maxW).forEach(function (pk) { all.push(pk); });
    });
    // 同じ位置の稜線はまとめる（強い方を残す）
    all.sort(function (a, b) { return a.u - b.u; });
    var pks = [];
    all.forEach(function (pk) {
      var last = pks[pks.length - 1];
      if (last && pk.u - last.u < Math.max(2, r.srcScale * 1.5)) {
        if (pk.v > last.v) pks[pks.length - 1] = pk;
      } else pks.push(pk);
    });
    if (pks.length > MAX_RIDGES) {
      pks = pks.slice().sort(function (a, b) { return b.v - a.v; }).slice(0, MAX_RIDGES)
               .sort(function (a, b) { return a.u - b.u; });
    }
    var out = [];
    pks.forEach(function (pk) {
      var thr = Math.max(RIDGE_FLOOR, pk.v * 0.5);
      segmentsAt(r, th, pk.u, dU, thr, pk.width).forEach(function (s) { out.push(s); });
    });
    return out;
  }

  /** v の範囲が重なる線分どうしを1つの帯に（向かい合わせの2列は別の帯になる） */
  function bandsOf(segs) {
    var sorted = segs.slice().sort(function (a, b) {
      return (a.v0 + a.v1) / 2 - (b.v0 + b.v1) / 2;
    });
    var bands = [];
    sorted.forEach(function (s) {
      var best = null, bestOv = 0;
      bands.forEach(function (g) {
        var ov = Math.max(0, Math.min(s.v1, g.v1) - Math.max(s.v0, g.v0))
               / Math.max(1, Math.min(s.len, g.v1 - g.v0));
        if (ov > bestOv) { bestOv = ov; best = g; }
      });
      if (best && bestOv >= 0.45) {
        best.segs.push(s);
        best.v0 = Math.min(best.v0, s.v0);
        best.v1 = Math.max(best.v1, s.v1);
      } else bands.push({ segs: [s], v0: s.v0, v1: s.v1 });
    });
    return bands;
  }

  /**
   * 2本の線の「間」が一様に埋まっていないか（＝1つの物体の両端ではないか）。
   * 枠と枠の間は地面（または車）なので、間が両脇と同じくらい一様なら
   * 「線2本」ではなく「物体1つ」とみなして捨てる。
   */
  function filledBetween(r, th, a, b, v0, v1) {
    var mid = (a.u + b.u) / 2, w = b.u - a.u;
    if (w < 3) return false;
    function strip(u0, u1) {
      var s = 0, s2 = 0, n = 0;
      var step = Math.max(1, Math.round((v1 - v0) / 24));
      for (var v = v0; v <= v1; v += step) {
        for (var u = u0; u <= u1; u += Math.max(1, (u1 - u0) / 4)) {
          var L = lumAt(r, th, u, v);
          if (L === null) continue;
          s += L; s2 += L * L; n++;
        }
      }
      if (n < 6) return null;
      var m = s / n;
      return { mean: m, std: Math.sqrt(Math.max(0, s2 / n - m * m)) };
    }
    var inner = strip(mid - w * 0.25, mid + w * 0.25);
    var outA = strip(a.u - w * 0.45, a.u - w * 0.15);
    var outB = strip(b.u + w * 0.15, b.u + w * 0.45);
    if (!inner) return false;
    var out = (outA && outB) ? { mean: (outA.mean + outB.mean) / 2,
                                 std: (outA.std + outB.std) / 2 } : (outA || outB);
    if (!out) return false;
    return Math.abs(inner.mean - out.mean) > 18 && inner.std < out.std * 1.3 + 3;
  }

  /**
   * 🔴 車＝線の証人（§16-10-l L3）。
   * 2本の線の間が**車で埋まっている**なら、線が車に隠れて端しか見えなくても枠と数える。
   * 奥行は車の塊の伸びから取る（線の見えている長さからではなく）。
   */
  function occupiedSpan(r, th, u0, u1, base) {
    if (!base) return null;
    var diag = Math.hypot(r.W, r.H);
    var thr = Math.max(12, base.mad * 2.2);
    var us = [u0 + (u1 - u0) * 0.3, (u0 + u1) / 2, u0 + (u1 - u0) * 0.7];
    var best = null, cur = null, gap = 0;
    for (var v = -diag; v <= diag; v += 1) {
      var s = 0, n = 0;
      for (var i = 0; i < us.length; i++) {
        var L = lumAt(r, th, us[i], v);
        if (L !== null) { s += L; n++; }
      }
      var on = (n >= 2) && Math.abs(s / n - base.mean) > thr;
      if (on) {
        if (!cur) cur = { v0: v, v1: v, on: 0, tot: 0 };
        cur.v1 = v; cur.on++; gap = 0;
      } else if (cur) {
        gap++;
        if (gap > 2) {
          cur.tot = cur.v1 - cur.v0 + 1;
          if (!best || (cur.v1 - cur.v0) > (best.v1 - best.v0)) best = cur;
          cur = null; gap = 0;
        }
      }
    }
    if (cur) { cur.tot = cur.v1 - cur.v0 + 1;
      if (!best || (cur.v1 - cur.v0) > (best.v1 - best.v0)) best = cur; }
    if (!best) return null;
    var len = best.v1 - best.v0;
    if (len < 4) return null;
    var fill = best.on / Math.max(1, best.tot);
    if (fill < OCC_FILL) return null;
    return { v0: best.v0, v1: best.v1, len: len, fill: fill };
  }

  /**
   * 帯（v が重なる線分の集まり）から枠を作る。
   * 🔴 **枠になるのは「検証済みの隣り合う線分2本の間」だけ**（§16-10-k-3）。
   *   k 分割（1つの隙間に複数の枠を割り付ける）は**生成**なので廃止した。
   */
  /**
   * 🔴 帯の中を**長さでまとめ直す**（§16-10-l L1-b「同じ長さ×同じ向きのまとまり＝仕切り線族」）。
   * 線の長さ＝枠の奥行なので、長さの違う線は別の物（建物の縁・道路の縁・文字）。
   * 実測 B5: 敷地の縁の長い線（200px超）と本物の仕切り線（80px）が同じ帯に入り、
   * 「重なりが中央値の半分以上」の条件で**本物の方が落ちて**列が1つも採れなかった。
   */
  function lengthFamilies(segs) {
    var sorted = segs.slice().sort(function (a, b) { return a.len - b.len; });
    var fams = [], cur = null;
    sorted.forEach(function (s) {
      if (cur && s.len <= cur.maxLen * 1.45) {
        cur.segs.push(s); cur.maxLen = Math.max(cur.maxLen, s.len);
      } else {
        cur = { segs: [s], maxLen: s.len };
        fams.push(cur);
      }
    });
    return fams.map(function (f) { return f.segs; });
  }

  function cellsFromBand(r, th, band, base) {
    var cells = [];
    lengthFamilies(band.segs).forEach(function (fam) {
      cellsFromFamily(r, th, fam, base).forEach(function (c) { cells.push(c); });
    });
    return cells;
  }

  function cellsFromFamily(r, th, family, base) {
    var segs = family.slice().sort(function (a, b) { return a.u - b.u; });
    /* 🔴 線が2本だけの族からは枠を作らない。
     * 停まっている車1台の左右の輪郭がちょうど「線2本」に見えるため、
     * これを許すと通路の車が枠になる（実測 B9c）。列なら仕切り線は3本以上ある。 */
    if (segs.length < MIN_LINES) return [];
    var medLen = med(segs.map(function (s) { return s.len; }));
    // 短いストローク（文字・ハッチ・矢印）は仕切り線ではない
    var keep = segs.filter(function (s) { return s.len >= medLen * 0.5; });
    if (keep.length < MIN_LINES) return [];
    var cells = [];
    for (var i = 0; i + 1 < keep.length; i++) {
      var a = keep[i], b = keep[i + 1];
      var gapU = b.u - a.u;
      if (gapU < MIN_PITCH_PX) continue;
      var ov0 = Math.max(a.v0, b.v0), ov1 = Math.min(a.v1, b.v1);
      var ovLen = ov1 - ov0;
      var ratio = ovLen > 0 ? gapU / ovLen : 0;
      if (ovLen >= OVL_MIN * medLen && ratio >= W_D_MIN && ratio <= W_D_MAX) {
        /* 🔴 ここで「間が一様に埋まっていたら1つの物体」として捨てるのは**やめた**（R2 から変更）。
         * 検証済みの線2本にはさまれた区画が車で埋まっているのは、
         * R3 では**捨てる理由ではなく根拠そのもの**（車＝線の証人）。
         * 実測 B12: 隣り合う車の色が違うと `filledBetween` が誤爆し、8枠のうち中央2枠が消えた。
         * 「車1台を線2本と見誤る」問題は、上の**線3本以上**の条件で断つ。 */
        cells.push({ uc: a.u + gapU / 2, vc: (ov0 + ov1) / 2, w: gapU, d: ovLen,
                     th: th, basis: 'linepair',
                     conf: Math.min(a.contrast, b.contrast) });
        continue;
      }
      // 線が車に隠れている場合（車＝線の証人）
      var sp = occupiedSpan(r, th, a.u, b.u, base);
      if (!sp) continue;
      var r2 = gapU / sp.len;
      if (r2 < W_D_MIN || r2 > W_D_MAX) continue;
      cells.push({ uc: a.u + gapU / 2, vc: (sp.v0 + sp.v1) / 2, w: gapU, d: sp.len,
                   th: th, basis: 'vehicle',
                   conf: Math.min(a.contrast, b.contrast) * 0.8 });
    }
    return cells;
  }

  /* ================= L1-c 車ブロブ ================= */

  /**
   * 舗装から浮いた塊を拾い、大きさ・縦横比・充填率で車らしい物だけ残す。
   * 🔴 1台では車列にしない（通路に停めた車と区別が付かない）。
   *   **同サイズ・整列・等間隔が3台以上**そろって初めて「列」と認める。
   */
  function carBlobs(r, anchors, base) {
    if (!base) return [];
    var W = r.W, H = r.H, i;
    /* 🔴 「敷地全体の明るさ」と比べてはいけない。日照・舗装の色ムラで車が半分に割れる
     * （実測 B4a: 55×100px の車が 20×40px の破片になり、同サイズの塊が3つ揃わず列にならなかった）。
     * **局所の舗装**と比べ、明るい車体と暗いガラスを「閉じ」で1台に戻す。 */
    var m = inkMask(r, base, { winDiv: 3, thrK: 3,
                               close: Math.max(1, Math.round(r.srcScale)) }).ink;
    var seen = new Uint8Array(W * H), stack = new Int32Array(W * H), sp = 0;
    var ths = anchors.map(function (a) { return rad(a); });
    var minSide = Math.max(4, r.srcScale * 2), maxSide = Math.min(W, H) * 0.6;
    var out = [];
    for (i = 0; i < W * H; i++) {
      if (seen[i] || !m[i]) continue;
      var ext = ths.map(function () {
        return { u0: Infinity, u1: -Infinity, v0: Infinity, v1: -Infinity };
      });
      var area = 0;
      sp = 0; stack[sp++] = i; seen[i] = 1;
      while (sp > 0) {
        var p = stack[--sp], px = p % W, py = (p / W) | 0;
        area++;
        for (var t = 0; t < ths.length; t++) {
          var c2 = pxToUv(ths[t], px, py), e = ext[t];
          if (c2.u < e.u0) e.u0 = c2.u; if (c2.u > e.u1) e.u1 = c2.u;
          if (c2.v < e.v0) e.v0 = c2.v; if (c2.v > e.v1) e.v1 = c2.v;
        }
        if (px > 0 && !seen[p - 1] && m[p - 1]) { seen[p - 1] = 1; stack[sp++] = p - 1; }
        if (px + 1 < W && !seen[p + 1] && m[p + 1]) { seen[p + 1] = 1; stack[sp++] = p + 1; }
        if (py > 0 && !seen[p - W] && m[p - W]) { seen[p - W] = 1; stack[sp++] = p - W; }
        if (py + 1 < H && !seen[p + W] && m[p + W]) { seen[p + W] = 1; stack[sp++] = p + W; }
      }
      if (area < minSide * minSide) continue;
      var best = null;
      for (t = 0; t < ths.length; t++) {
        var e2 = ext[t], du = e2.u1 - e2.u0 + 1, dv = e2.v1 - e2.v0 + 1;
        var fill = area / Math.max(1, du * dv);
        if (!best || fill > best.fill) {
          best = { fill: fill, th: ths[t], du: du, dv: dv,
                   uc: (e2.u0 + e2.u1) / 2, vc: (e2.v0 + e2.v1) / 2 };
        }
      }
      if (!best || best.fill < CAR_FILL) continue;
      var shortS = Math.min(best.du, best.dv), longS = Math.max(best.du, best.dv);
      if (shortS < minSide || longS > maxSide) continue;
      var asp = longS / Math.max(1, shortS);
      if (asp < CAR_ASPECT_MIN || asp > CAR_ASPECT_MAX) continue;
      var wide = best.du <= best.dv;
      var th2 = normTh(wide ? best.th : best.th + Math.PI / 2);
      var cc = uvToPx(best.th, best.uc, best.vc);
      var uv = pxToUv(th2, cc.x, cc.y);
      out.push({ uc: uv.u, vc: uv.v, w: shortS, d: longS, th: th2, fill: best.fill });
      if (out.length > 300) break;
    }
    return out;
  }

  /** 車ブロブを「同サイズ・整列・等間隔」の列にまとめる */
  function carRows(blobs) {
    if (blobs.length < ROW_MIN_CARS) return [];
    var rows = [];
    sizeClusters(blobs).forEach(function (grp) {
      if (grp.length < ROW_MIN_CARS) return;
      // 同じ向きごとに、v が近い物を1列に
      var byTh = {};
      grp.forEach(function (b) {
        var k = Math.round(b.th * 180 / Math.PI);
        (byTh[k] = byTh[k] || []).push(b);
      });
      Object.keys(byTh).forEach(function (k) {
        var list = byTh[k];
        if (list.length < ROW_MIN_CARS) return;
        var dRef = med(list.map(function (b) { return b.d; }));
        var lanes = [];
        list.slice().sort(function (a, b) { return a.vc - b.vc; }).forEach(function (b) {
          var ln = lanes[lanes.length - 1];
          if (ln && Math.abs(b.vc - ln.v) <= dRef * 0.5) {
            ln.items.push(b); ln.v = (ln.v * (ln.items.length - 1) + b.vc) / ln.items.length;
          } else lanes.push({ v: b.vc, items: [b] });
        });
        lanes.forEach(function (ln) {
          if (ln.items.length < ROW_MIN_CARS) return;
          var items = ln.items.slice().sort(function (a, b) { return a.uc - b.uc; });
          var gaps = [];
          for (var i = 0; i + 1 < items.length; i++) gaps.push(items[i + 1].uc - items[i].uc);
          var g0 = Math.min.apply(null, gaps);
          if (g0 < MIN_PITCH_PX) return;
          // すべての間隔が g0 の整数倍か（＝等間隔の格子に乗っているか）
          var okGrid = gaps.every(function (g) {
            var k2 = Math.round(g / g0);
            return k2 >= 1 && k2 <= 4 && Math.abs(g - k2 * g0) <= g0 * 0.25;
          });
          if (!okGrid) return;
          rows.push({ items: items, pitch: g0, th: items[0].th,
                      w: med(items.map(function (b) { return b.w; })),
                      d: med(items.map(function (b) { return b.d; })) });
        });
      });
    });
    return rows;
  }

  /* ================= 外周の辺から角度候補を作る ================= */

  function edgeDirections(r) {
    var poly = r.poly, groups = [];
    for (var i = 0; i < poly.length; i++) {
      var a = poly[i], b = poly[(i + 1) % poly.length];
      var dx = (b.x - a.x) * r.pxPerM, dy = (b.y - a.y) * r.pxPerM;
      var len = Math.hypot(dx, dy);
      if (len < 8) continue;                    // 8px 未満の辺は向きの根拠にしない
      var deg = ((Math.atan2(dy, dx) * 180 / Math.PI) % 90 + 90) % 90;
      var hit = null;
      for (var k = 0; k < groups.length; k++) {
        var d = Math.abs(groups[k].deg - deg);
        d = Math.min(d, 90 - d);
        if (d < 5) { hit = groups[k]; break; }
      }
      if (hit) {
        var v = deg;
        if (Math.abs(hit.deg - v) > 45) v += (hit.deg > v) ? 90 : -90;
        hit.deg = ((hit.deg * hit.len + v * len) / (hit.len + len) % 90 + 90) % 90;
        hit.len += len;
      } else groups.push({ deg: deg, len: len });
    }
    groups.sort(function (x, y) { return y.len - x.len; });
    return groups.slice(0, MAX_DIRS);
  }

  function angleGap90(a, b) {
    var d = Math.abs(((a - b) % 90 + 90) % 90);
    return Math.min(d, 90 - d);
  }
  /* 🔴 走査する向きの重複判定には**180度で畳んだ差**を使う。
   * angleGap90 は 0° と 90° を「同じ」と見なす（枠の向きとしては同じだから正しい）が、
   * **線を探す向きとしては 0° と 90° は全くの別物**。ここを取り違えて
   * 「0° を入れたら 90° が重複扱いで捨てられ、直交する列を一生見に行かない」バグを踏んだ
   * （実測 B14: 縦の列4枠だけで横の列4枠が出ない）。 */
  function angleGap180(a, b) {
    var d = Math.abs(((a - b) % 180 + 180) % 180);
    return Math.min(d, 180 - d);
  }

  /* ================= L3 台帳 ================= */

  /** 枠の中心が外周の内側にあるか（4隅も見る） */
  function cellInside(r, c) {
    var ok = 0, tot = 0;
    [[0, 0], [-c.w * 0.35, -c.d * 0.35], [c.w * 0.35, -c.d * 0.35],
     [-c.w * 0.35, c.d * 0.35], [c.w * 0.35, c.d * 0.35]].forEach(function (o) {
      tot++;
      if (insidePoly(r, c.th, c.uc + o[0], c.vc + o[1])) ok++;
    });
    return ok >= tot - 1;
  }

  /** 2つの枠が同じ場所か（中心が互いの半分より近い） */
  function sameSpot(a, b) {
    var pa = uvToPx(a.th, a.uc, a.vc), pb = uvToPx(b.th, b.uc, b.vc);
    var dd = Math.hypot(pa.x - pb.x, pa.y - pb.y);
    return dd < Math.min(Math.min(a.w, a.d), Math.min(b.w, b.d)) * 0.55;
  }

  /** 台帳へ記帳（重複は強い根拠を残す） */
  var BASIS_RANK = { box: 4, linepair: 3, vehicle: 2, gap: 1 };
  function post(ledger, c) {
    for (var i = 0; i < ledger.length; i++) {
      if (sameSpot(ledger[i], c)) {
        if ((BASIS_RANK[c.basis] || 0) > (BASIS_RANK[ledger[i].basis] || 0)) ledger[i] = c;
        return false;
      }
    }
    if (ledger.length >= MAX_CELLS) return false;
    ledger.push(c);
    return true;
  }

  /**
   * 🔴 挟まれ空きルール（§16-10-l L3）。
   * 同じ列の中で、確定した枠が**ちょうど1枠分あけて**並んでいたら、その間を1つ埋める。
   * 両脇の枠が線（または車）で裏付けられているので、その空きの両側にも線がある。
   * **2枠分以上あいていたら埋めない**（不足として案内する）。
   */
  function fillSandwich(cells) {
    var out = [];
    var byRow = {};
    cells.forEach(function (c) {
      var k = Math.round(c.th * 180 / Math.PI) + '|' + Math.round(c.vc / Math.max(4, c.d * 0.6));
      (byRow[k] = byRow[k] || []).push(c);
    });
    Object.keys(byRow).forEach(function (k) {
      var list = byRow[k].slice().sort(function (a, b) { return a.uc - b.uc; });
      if (list.length < 2) return;
      var steps = [];
      for (var i = 0; i + 1 < list.length; i++) steps.push(list[i + 1].uc - list[i].uc);
      var p = med(steps.filter(function (s) { return s > MIN_PITCH_PX; }));
      if (!(p > 0)) return;
      for (i = 0; i + 1 < list.length; i++) {
        var g = list[i + 1].uc - list[i].uc;
        var n = Math.round(g / p);
        if (n !== GAP_SLOTS_MAX + 1) continue;          // 空きは1枠分だけ
        if (Math.abs(g - n * p) > p * 0.3) continue;
        out.push({ uc: (list[i].uc + list[i + 1].uc) / 2,
                   vc: (list[i].vc + list[i + 1].vc) / 2,
                   w: (list[i].w + list[i + 1].w) / 2,
                   d: (list[i].d + list[i + 1].d) / 2,
                   th: list[i].th, basis: 'gap',
                   conf: Math.min(list[i].conf || 1, list[i + 1].conf || 1) * 0.7 });
      }
    });
    return out;
  }

  /* ================= L2 予測層（探す場所を決めるだけ） =================
   *
   * 🔴 ここで作るのは**仮説**であって枠ではない。仮説の位置に画素の根拠が無ければ記帳しない。
   * 容量則（オーナーの3倍/2倍ルール）は layout.js の敷き詰め計算を**そのまま転用**する
   *   奥行 ≥ 2d+a（≈3d）→ 対面2列がありうる
   *   奥行 ≈ d+a（≈2d）→ 片側1列のみ（前面道路が車路）
   *   奥行 < d       → 列は存在できない → **探さない**（誤検出の機会を消す）
   * 生成器としては失格でも、予測器としては適任（正典 §16-10-l L2）。 */

  function predictCapacity(polygonLL, r, th, d) {
    try {
      var a = d;                                     // 車路 ≒ 枠の奥行（5m 前後）
      var res = Layout.fillParking(polygonLL, [], {
        cell_w_m: Math.max(0.2, d * 0.5 / r.pxPerM),
        cell_h_m: Math.max(0.2, d / r.pxPerM),
        aisle_m: Math.max(0.2, a / r.pxPerM),
        margin_m: 0,
        angle: (th * 180 / Math.PI) + 90             // 枠の並ぶ向き
      });
      if (!res) return { rows: 0, capacity: 0 };
      return { rows: res.rows || 0, capacity: res.capacity || 0 };
    } catch (e) {
      return { rows: 0, capacity: 0 };
    }
  }

  /* ================= 本体 ================= */

  /**
   * opts: {image, placement:{center,w_m,angle,ratio}, polygonLL,
   *        targetCount, angleHintDeg, onProgress}
   * 返り値(Promise): {ok, cells, groups, segments, vehicles, lineCount,
   *                   pitch_m, depth_m, angleDeg, groupCount, reason, ledger, diag}
   * 🔴 targetCount（台数 N）は**会計係**。生成にも選択にも使わない。
   */
  function detect(opts) {
    return new Promise(function (resolve) {
      var r;
      try {
        r = buildRaster(opts.polygonLL, opts.placement, opts.image);
      } catch (e) {
        resolve({ ok: false, reason: 'raster:' + (e.message || e) });
        return;
      }
      var target = (opts.targetCount > 0) ? Math.round(opts.targetCount) : null;
      var diag = { anchors: [], top: [], rounds: 0, ledger: {} };
      if (r.valid < 64) {
        resolve({ ok: false, reason: 'too-small', diag: diag });
        return;
      }
      var base = siteBaseline(r);
      var edges = edgeDirections(r);
      var anchors = [];
      edges.forEach(function (g) {
        [g.deg, (g.deg + 90) % 180].forEach(function (a) {
          var dup = anchors.some(function (b) { return angleGap180(a, b) < 3; });
          if (!dup) anchors.push(((a % 180) + 180) % 180);
        });
      });
      if (!anchors.length) anchors = [0, 90];
      if (opts.angleHintDeg !== undefined && opts.angleHintDeg !== null) {
        var h = ((opts.angleHintDeg % 180) + 180) % 180;
        if (!anchors.some(function (b) { return angleGap180(h, b) < 3; })) anchors.unshift(h);
      }
      diag.anchors = anchors.map(function (a) { return Math.round(a); });

      var ledger = [], segments = [], vehicles = [], groupInfo = [];
      var inkThr = INK_MIN;
      var steps = [], si = 0;

      function report(p) {
        if (opts.onProgress) { try { opts.onProgress(Math.min(0.99, p)); } catch (e) {} }
      }

      /* ---------- 角度ごとに線オブジェクトを取る（向きを1つに決めない） ----------
       * 🔴 直交2族が同じ長さなら**両方とも仕切り線**（向き違いの列）。
       *   長さ＝枠の奥行は、向きが変わっても不変の物差し（§16-10-l L1-b）。 */

      /** その向きの「線らしさ」の強さ（稜線の鋭さの合計）。角度合わせにだけ使う */
      function ridgePower(th) {
        var p = profile(r, th, 2);
        var lo = Math.max(MIN_PITCH_PX, p.n / MAX_CELLS_ACROSS);
        var pks = ridges(r, p, lo * 2.2, Math.max(lo * 0.5, r.srcScale * 1.6));
        var s = 0;
        /* 🔴 二乗で足す。ずれた角度では稜線が寝て**本数は増えるが1本1本は鈍る**ので、
         * 単純な和だと「少しずれた角度」が勝ってしまう（実測 B10: 45°の列を40°で採り、
         * 線が切れて奥行が半分になった）。 */
        pks.forEach(function (pk) { s += pk.v * pk.v; });
        return s;
      }

      /** その角度ちょうどで線オブジェクトを取り出す（同じ角度は1回だけ計算する） */
      var lineCache = {};
      function linesAt(deg) {
        var key = deg.toFixed(2);
        if (lineCache[key] !== undefined) return lineCache[key];
        var th = rad(deg);
        var segs = lineObjects(r, th);
        if (!segs.length) { lineCache[key] = null; return null; }
        var k = Math.round(deg);
        // 診断行は「見た角度」を1度単位で1回だけ並べる（同じ角度を2つ出すと読みにくい）
        if (!diag.top.some(function (x) { return x[0] === k; })) diag.top.push([k, segs.length]);
        lineCache[key] = { th: th, deg: deg, segs: segs };
        return lineCache[key];
      }

      function scanAngle(deg) {
        var best = null, o;
        for (o = -ANGLE_SPAN; o <= ANGLE_SPAN; o += ANGLE_STEP) {
          var s = ridgePower(rad(deg + o));
          if (!best || s > best.s) best = { s: s, deg: deg + o };
        }
        // 1度刻みで詰める（角度が1〜2度ずれるだけで線分がぶつ切りになる）
        for (o = -ANGLE_STEP + 1; o <= ANGLE_STEP - 1; o++) {
          if (!o) continue;
          var s2 = ridgePower(rad(best.deg + o));
          if (s2 > best.s) { best = { s: s2, deg: best.deg + o }; }
        }
        return linesAt(best.deg);
      }

      /** 1つの角度の線から枠を作って記帳する */
      function harvestLines(sc) {
        if (!sc) return 0;
        var made = 0;
        bandsOf(sc.segs).forEach(function (band) {
          var cells = cellsFromBand(r, sc.th, band, base);
          if (!cells.length) return;
          // 同じ帯の枠は大きさがそろっているはず（そろわない物は列の一部ではない）
          var mw = med(cells.map(function (c) { return c.w; }));
          var mdp = med(cells.map(function (c) { return c.d; }));
          cells = cells.filter(function (c) {
            return Math.abs(c.w - mw) <= mw * 0.35 && Math.abs(c.d - mdp) <= mdp * 0.35;
          });
          /* 🔴 「列」と言えるのは枠が3つ以上そろった時だけ。
           * 停まっている車2台は輪郭が4本の線に見え、そのうち車の上の2枠だけが残って
           * 「通路の車が枠になる」（実測 B9c）。列なら枠は3つ以上連なる。 */
          if (cells.length < MIN_ROW_CELLS) return;
          fillSandwich(cells).forEach(function (c) { cells.push(c); });
          var gi = groupInfo.length;
          var n = 0;
          cells.forEach(function (c) {
            if (!cellInside(r, c)) return;
            c.group = gi;
            if (post(ledger, c)) n++;
          });
          if (!n) return;
          groupInfo.push({ th: sc.th, angleDeg: ((sc.deg % 360) + 360) % 360,
                           lines: band.segs.length, pitchPx: mw, depthPx: mdp,
                           segMedPx: med(band.segs.map(function (s) { return s.len; })) });
          band.segs.forEach(function (s) { segments.push(s); });
          made += n;
        });
        return made;
      }

      /** 車列から枠を作って記帳する */
      function harvestCars() {
        var blobs = carBlobs(r, anchors, base);
        var rows = carRows(blobs);
        var made = 0;
        rows.forEach(function (row) {
          var w = Math.max(row.w, Math.min(row.pitch, row.w * 1.6));
          var d = row.d * 1.1;
          var cells = row.items.map(function (b) {
            return { uc: b.uc, vc: b.vc, w: w, d: d, th: row.th,
                     basis: 'vehicle', conf: b.fill };
          });
          fillSandwich(cells).forEach(function (c) { cells.push(c); });
          var gi = groupInfo.length, n = 0;
          cells.forEach(function (c) {
            if (!cellInside(r, c)) return;
            c.group = gi;
            if (post(ledger, c)) { n++; if (c.basis === 'vehicle') vehicles.push(c); }
          });
          if (!n) return;
          groupInfo.push({ th: row.th, angleDeg: ((row.th * 180 / Math.PI) % 360 + 360) % 360,
                           lines: 0, pitchPx: w, depthPx: d, segMedPx: 0 });
          made += n;
        });
        return made;
      }

      /** 閉領域（図面のマス）から枠を作って記帳する */
      function harvestBoxes() {
        var seal = Math.max(1, Math.round(r.srcScale * 1.5));
        var boxes = closedBoxes(r, anchors, seal, base);
        if (!boxes.length) return 0;
        var clusters = sizeClusters(boxes);
        var made = 0;
        clusters.forEach(function (grp) {
          if (grp.length < 2) return;                 // 1つだけの四角は「列」ではない
          if (grp.length * 3 < clusters[0].length) return;  // 主群から外れた小群は捨てる
          var gi = groupInfo.length, n = 0;
          grp.forEach(function (c) {
            if (!cellInside(r, c)) return;
            c.group = gi; c.conf = c.fill;
            if (post(ledger, c)) n++;
          });
          if (!n) return;
          groupInfo.push({ th: grp[0].th, angleDeg: ((grp[0].th * 180 / Math.PI) % 360 + 360) % 360,
                           lines: 0, pitchPx: med(grp.map(function (c) { return c.w; })),
                           depthPx: med(grp.map(function (c) { return c.d; })), segMedPx: 0 });
          made += n;
        });
        return made;
      }

      /**
       * 🔴 第2周以降（§16-10-l L3）。
       * 確定した枠の**格子の隣**と、**車路をはさんだ向かいの帯**だけを見に行く。
       * 予測は「探す場所」でしかなく、採るかどうかは**辺のインク**が決める（EDGES_STRICT 辺）。
       */
      function reprobe() {
        if (!ledger.length) return 0;
        var made = 0;
        var byGroup = {};
        ledger.forEach(function (c) { (byGroup[c.group] = byGroup[c.group] || []).push(c); });
        Object.keys(byGroup).forEach(function (gk) {
          var list = byGroup[gk];
          if (!list.length) return;
          var w = med(list.map(function (c) { return c.w; }));
          var d = med(list.map(function (c) { return c.d; }));
          var cap = predictCapacity(opts.polygonLL, r, list[0].th, d);
          var offs = [[w, 0], [-w, 0], [0, d], [0, -d]];
          if (cap.rows >= 2) { offs.push([0, d * 2]); offs.push([0, -d * 2]); }  // 車路の向かい
          list.slice(0, 60).forEach(function (c) {
            offs.forEach(function (o) {
              /* 🔴 隣は**その枠自身のフレーム**で測る。群の代表 th を全員に当てると、
               * 群の中に別向き（0° と 90°、あるいは 0° と 180°）が混ざった瞬間に
               * 全員の (uc,vc) が壊れる（実測 B2・§16-19）。 */
              var cand = { uc: c.uc + o[0], vc: c.vc + o[1], w: w, d: d, th: c.th,
                           basis: 'linepair', conf: (c.conf || 1) * 0.9, group: c.group };
              if (!cellInside(r, cand)) return;
              for (var i = 0; i < ledger.length; i++) if (sameSpot(ledger[i], cand)) return;
              var cov = edgeCover(r, cand, inkThr);
              var nInk = cov.filter(function (v) { return v >= COVER_STRICT; }).length;
              if (nInk < EDGES_STRICT) return;
              if (post(ledger, cand)) made++;
            });
          });
        });
        return made;
      }

      /**
       * 🔴 「同じサイズの四角」だけを残す（オーナーの読み方そのもの・§16-10-k）。
       * オーナー: 「この図から分かるのは**同じサイズの四角が8個ある**こと」。
       * 実測でここを外すと、文字のストローク2本の隙間（7×15px）や
       * 砂利のむらの大枠（157×187px）が枠として紛れ込む。
       * 主群（いちばん数の多いサイズの塊）の中央値から大きく外れた枠は列の一部ではない。
       */
      function pruneBySize() {
        if (ledger.length < 3) return 0;
        var cl = sizeClusters(ledger);
        if (!cl.length) return 0;
        var mw = med(cl[0].map(function (c) { return c.w; }));
        var mdp = med(cl[0].map(function (c) { return c.d; }));
        var before = ledger.length;
        ledger = ledger.filter(function (c) {
          return c.w >= mw * SIZE_KEEP_MIN && c.w <= mw * SIZE_KEEP_MAX
              && c.d >= mdp * SIZE_KEEP_MIN && c.d <= mdp * SIZE_KEEP_MAX;
        });
        vehicles = vehicles.filter(function (c) { return ledger.indexOf(c) >= 0; });
        return before - ledger.length;
      }

      /**
       * 🔴 ゲートで枠が落ちた**後**に、もう一度「列と言えるか」を確かめる（§16-10-l L1-c）。
       * `harvestLines` / `harvestCars` は記帳の**前**に「3枠以上そろっているか」を見るが、
       * その後 `pruneBySize` と `hardGate` が枠を落とすので、
       * **終わってみたら2枠しか残っていない群**ができる。
       * 実測 B9c（通路の車2台・期待0枠）: 斜め救済が3枠を記帳 → ゲートで1枠落ち → 2枠が残った。
       * 「2枠は車1台の輪郭と区別できない」という R3 の前提は、
       * **出力の時点で**成り立っていなければ意味がない。
       * 例外は `box`（閉領域）。完全に囲まれた同サイズの四角は1つ1つが強い実物なので、
       * `harvestBoxes` の「クラスタ2つ以上」で足りる（2台分の区画図を殺さない）。
       */
      function dropThinRows() {
        var cnt = {};
        ledger.forEach(function (c) { cnt[c.group] = (cnt[c.group] || 0) + 1; });
        var before = ledger.length;
        ledger = ledger.filter(function (c) {
          return c.basis === 'box' || cnt[c.group] >= MIN_ROW_CELLS;
        });
        vehicles = vehicles.filter(function (c) { return ledger.indexOf(c) >= 0; });
        return before - ledger.length;
      }

      /** いちばん枠数の多い群の枠数（「列が採れたか」の判断に使う） */
      function bestGroupCells() {
        var cnt = {}, best = 0;
        ledger.forEach(function (c) {
          cnt[c.group] = (cnt[c.group] || 0) + 1;
          if (cnt[c.group] > best) best = cnt[c.group];
        });
        return best;
      }

      /* ---------- L4 ハードゲート ---------- */

      function hardGate() {
        var info = ledger.map(function (c) {
          var cov = edgeCover(r, c, inkThr);
          var nInk = cov.filter(function (v) { return v >= COVER_GATE; }).length;
          var occ = false;
          if (base) {
            var st = 0, n = 0, step = Math.max(1, Math.round(Math.min(c.w, c.d) / 12));
            for (var dv = -c.d * 0.35; dv <= c.d * 0.35; dv += step) {
              for (var du = -c.w * 0.35; du <= c.w * 0.35; du += step) {
                var L = lumAt(r, c.th, c.uc + du, c.vc + dv);
                if (L !== null) { st += L; n++; }
              }
            }
            /* 🔴 比べる相手は `pave`（ブロック平均の中央値）。**尺度を合わせる**。
             * 散らばり（きめ）も根拠に足す案は実測で却下した: 枠の中の散らばりは
             * 車だけでなく**線・影・隣の建物の縁**でも大きくなるので、
             * 根拠の無い枠を3件（B4a・B5・B6 各1）通してしまった（§16-19⑥）。 */
            if (n >= 8) {
              var pv = (base.pave !== undefined) ? base.pave : base.mean;
              occ = Math.abs(st / n - pv) > Math.max(14, base.mad * 2.2);
            }
          }
          var direct = (nInk >= 2) || (nInk >= 1 && occ) || occ;
          return { c: c, cov: cov, nInk: nInk, occ: occ, direct: direct };
        });
        // 挟まれ空き: 幅方向の両隣に根拠のある枠があるなら、その空きは裏付けられている
        info.forEach(function (a) {
          if (a.direct) return;
          var l = false, rr = false;
          info.forEach(function (b) {
            if (b === a || !b.direct) return;
            if (Math.abs(angleGap90(a.c.th * 180 / Math.PI, b.c.th * 180 / Math.PI)) > 6) return;
            var du = b.c.uc - a.c.uc, dv = b.c.vc - a.c.vc;
            if (Math.abs(dv) > a.c.w * 0.9) return;
            if (Math.abs(Math.abs(du) - a.c.w) > a.c.w * 0.4) return;
            if (du < 0) l = true; else rr = true;
          });
          if (l && rr) a.direct = true;
        });
        var kept = info.filter(function (x) { return x.direct; });
        var dropped = info.length - kept.length;
        ledger = kept.map(function (x) { return x.c; });
        return dropped;
      }

      /* ---------- 実行の段取り（細切れに回して UI を止めない） ---------- */

      steps.push(function () { harvestBoxes(); });
      anchors.forEach(function (a) {
        steps.push(function () {
          /* 🔴 **外周の辺の向きそのものは、絶対に捨てない**（§16-10-g の係留の徹底）。
           * `ridgePower` は敷地全体の稜線の鋭さなので、航空写真では
           * **建物の縁や道路の方が駐車線より強く**、山が駐車列の向きに立たない。
           * 実測 B4a: **90°ちょうどで5枠**採れるのに ridgePower は 92° を選び、
           * 92°では0枠。±10°を1度刻みで見ても**枠が採れるのは 90°の1点だけ**だった。
           * そこで「係留角ちょうど」と「振れを許した最良角」の**両方**で走らせる。
           * 増やしたのは**探す目**だけで、採否は従来どおり画素が決める（§16-10-l L3）。 */
          harvestLines(linesAt(a));
          var sc = scanAngle(a);
          if (sc && Math.round(sc.deg) !== Math.round(a)) harvestLines(sc);
        });
      });
      steps.push(function () { harvestCars(); });
      steps.push(function () {
        /* 斜め駐車の救済。🔴 「1枠も無い時だけ」ではなく
         * 「**列と言える群がまだ無い時**」に走らせる（実測 B10: 文字や縁で2枠だけ拾って
         * しまい、45°の本物の列を一生探しに行かなかった）。 */
        if (bestGroupCells() >= MIN_ROW_CELLS) return;
        var a0 = anchors[0] || 0, i;
        var picks = [];
        DIAG_OFFSETS.forEach(function (o) {
          var deg = (a0 + o) % 180;
          picks.push({ deg: deg, s: ridgePower(rad(deg)) });
        });
        picks.sort(function (x, y) { return y.s - x.s; });
        for (i = 0; i < picks.length && bestGroupCells() < MIN_ROW_CELLS; i++) {
          harvestLines(scanAngle(picks[i].deg));
        }
      });
      steps.push(function () {
        pruneBySize();
        // ここまでで物差しが決まったので、インクのしきい値を較正する
        if (!ledger.length) return;
        var mm = med(ledger.map(function (c) { return Math.min(c.w, c.d); }));
        inkThr = calibrateInk(r, Math.max(3 * r.srcScale, mm * 0.22));
        diag.inkThr = Math.round(inkThr * 10) / 10;
      });
      var exhausted = false;
      for (var ri = 0; ri < MAX_ROUNDS; ri++) {
        steps.push(function () {
          if (!ledger.length || exhausted) return;
          diag.rounds++;
          if (!reprobe()) exhausted = true;          // 証拠が尽きた → 残りの周はやらない
        });
      }
      steps.push(function () {
        if (!ledger.length) return;
        if (inkThr === INK_MIN) {
          var mm = med(ledger.map(function (c) { return Math.min(c.w, c.d); }));
          inkThr = calibrateInk(r, Math.max(3 * r.srcScale, mm * 0.22));
        }
        diag.pruned = pruneBySize();
        diag.dropped = hardGate();
        diag.thinRows = dropThinRows();
      });

      function pump() {
        if (si >= steps.length) { finish(); return; }
        var fn = steps[si++];
        try { fn(); } catch (e) { diag.error = String(e && e.message || e); }
        report(si / steps.length);
        yieldSoon(pump);
      }

      function finish() {
        if (!ledger.length) {
          diag.rounds = diag.rounds || 0;
          resolve({ ok: false, reason: 'no-painted-lines', diag: diag,
                    segments: [], vehicles: [], lineCount: segments.length });
          return;
        }
        /* 台数より多い時だけ、弱い根拠から落とす（選択ではなく削り・§16-10-k-4） */
        var removed = 0;
        if (target && ledger.length > target) {
          var order = ledger.slice().sort(function (a, b) {
            var ra = BASIS_RANK[a.basis] || 0, rb = BASIS_RANK[b.basis] || 0;
            if (ra !== rb) return ra - rb;
            return (a.conf || 0) - (b.conf || 0);
          });
          var drop = order.slice(0, ledger.length - target)
                          .filter(function (c) { return c.basis === 'vehicle' || c.basis === 'gap'; });
          if (drop.length) {
            ledger = ledger.filter(function (c) { return drop.indexOf(c) < 0; });
            vehicles = vehicles.filter(function (c) { return drop.indexOf(c) < 0; });
            removed = drop.length;
          }
        }
        // 台帳の内訳（診断行に出す）
        var tally = { box: 0, linepair: 0, vehicle: 0, gap: 0 };
        ledger.forEach(function (c) { tally[c.basis] = (tally[c.basis] || 0) + 1; });
        diag.ledger = tally;

        // ---- ここで初めて px → 緯度経度・メートルに直す（出力の1回だけ）----
        var mpp = 1 / r.pxPerM;
        var out = ledger.map(function (c) {
          return { center: uvToLL(r, c.th, c.uc, c.vc),
                   w_m: c.w * mpp, h_m: c.d * mpp,
                   angleDeg: ((c.th * 180 / Math.PI) % 360 + 360) % 360,
                   basis: c.basis, large: false, conf: c.conf || 0, group: c.group || 0 };
        });
        var vehOut = vehicles.filter(function (c) { return ledger.indexOf(c) >= 0; })
          .map(function (c) {
            return { center: uvToLL(r, c.th, c.uc, c.vc),
                     w_m: c.w * mpp, h_m: c.d * mpp,
                     angleDeg: ((c.th * 180 / Math.PI) % 360 + 360) % 360, large: false };
          });
        var used = {};
        ledger.forEach(function (c) { used[c.group] = (used[c.group] || 0) + 1; });
        var groups = [];
        Object.keys(used).forEach(function (gk) {
          var gi = groupInfo[gk];
          if (!gi) return;
          groups.push({ angleDeg: gi.angleDeg, cells: used[gk], lines: gi.lines,
                        pitch_m: gi.pitchPx * mpp, depth_m: gi.depthPx * mpp,
                        pitch_px: Math.round(gi.pitchPx), segMed_px: Math.round(gi.segMedPx),
                        vehicleCells: 0 });
        });
        if (!groups.length) {
          groups.push({ angleDeg: out[0].angleDeg, cells: out.length, lines: 0,
                        pitch_m: out[0].w_m, depth_m: out[0].h_m,
                        pitch_px: Math.round(ledger[0].w), segMed_px: 0, vehicleCells: 0 });
        }
        var segOut = segments.map(function (s) {
          return { a: uvToLL(r, s.th, s.u, s.v0), b: uvToLL(r, s.th, s.u, s.v1) };
        });
        var ws = out.map(function (c) { return c.w_m; });
        var hs = out.map(function (c) { return c.h_m; });
        var edgeDegs = edges.map(function (e) { return e.deg; });
        diag.adopted = groups.map(function (g) {
          var gp = 90;
          edgeDegs.forEach(function (e) { gp = Math.min(gp, angleGap90(g.angleDeg, e)); });
          return { deg: Math.round(g.angleDeg), gap: Math.round(edgeDegs.length ? gp : 0),
                   pitchPx: g.pitch_px, segMed: g.segMed_px, lines: g.lines, cells: g.cells };
        });
        resolve({
          ok: true, reason: '',
          cells: out, groups: groups, segments: segOut, vehicles: vehOut,
          vehicleCells: out.filter(function (c) { return c.basis === 'vehicle'; }).length,
          largeCells: 0, ambiguousCells: 0,
          lineCount: segOut.length, removedCells: removed, rounds: diag.rounds,
          ledger: tally,
          pitch_m: med(ws), depth_m: med(hs),
          angleDeg: groups[0].angleDeg, groupCount: groups.length, diag: diag
        });
      }

      pump();
    });
  }

  /** 台数 N との照合結果の案内文（§16-10-l L3 の会計）。選択には使わない */
  function reconcile(res, target) {
    if (!res || !res.ok || !res.cells) {
      return { kind: 'failed', note: '駐車枠を検出できませんでした' };
    }
    var n = res.cells.length;
    if (!target) return { kind: 'no-target', note: '画像から ' + n + ' 枠を読み取りました' };
    if (n === target) {
      return { kind: 'exact', note: '画像認識と台数が一致しました'
        + (res.removedCells ? '（根拠の弱い枠を ' + res.removedCells + ' 個除きました）' : '') };
    }
    if (n > target) {
      return { kind: 'over',
        note: (n - target) + '台多く描画しています。多い分は消しゴムで削除してください' };
    }
    return { kind: 'under',
      note: (target - n) + '台分は画像から見つかりませんでした。'
        + '足りない場所は［四角］で追加してください（線も車も写っていない所には枠を描きません）' };
  }

  global.Recognize = {
    detect: detect,
    reconcile: reconcile,
    _buildRaster: buildRaster, _profile: profile, _ridges: ridges,
    _lineObjects: lineObjects, _closedBoxes: closedBoxes, _carBlobs: carBlobs,
    _carRows: carRows, _bandsOf: bandsOf, _cellsFromBand: cellsFromBand,
    _edgeDirections: edgeDirections, _siteBaseline: siteBaseline, _inkMask: inkMask,
    _calibrateInk: calibrateInk, _edgeCover: edgeCover
  };
})(typeof window !== 'undefined' ? window : this);
