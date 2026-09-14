/* reveal.js — なぞり出し（曇り下書き＋ブラシ）／正典 §23・§26 Step 7
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * 思想（§23-1）: どこまで細かく描くかはアプリが決めない。
 *   曇りガラスの下に「表示中ZLの地理院ベクトルタイル」が全部うっすら見えていて、
 *   〇でなぞった所だけが浮き出て**普通のオブジェクト**になる。
 *
 * 設計の要点:
 *  1. 曇り下書きは **canvas に薄描き**（SVG ではない）。z16 の都市部は建物が
 *     数千面あり（§11-6 柏 6,748面）、SVG 要素にすると掴めてしまうし重い。
 *     下書きはただの絵で掴めなくてよい。掴めるのは実体化した後だけ（§23-2）。
 *  2. 🔴 **書き出し（PNG/PDF）には一切含めない**。export.js は
 *     「オブジェクトモデル → まっさらな canvas」に描き直す作りなので、
 *     この canvas が DOM 上のどこにあっても構造的に紙には出ない（§23-2）。
 *  3. ZL連動の間引きロジックは**要らない**（§23-4 実測）。地理院タイルが
 *     最初から z14=主要な建物だけ / z16=全建物 という中身になっている。
 *     ZL17 以上は z16 タイルの内容をそのまま使う（§12-a と同じ扱い）。
 *  4. 座標は**正規化メルカトル（0〜1）**で持つ。タイル内部座標からは
 *     `(tileX + gx/extent) / 2^z` の割り算だけで出る（三角関数ゼロ）。
 *     画面座標は `(w - 中心w) * worldSize + 画面幅/2` の1回の乗加算で出るので、
 *     パンのたびに数万点を投影しても軽い。MapView.project と完全に同じ式。
 *  5. 二重線を防ぐ2段構え（§23-3）:
 *     ①**弧長の区間帳簿**（線を 0〜1 で測り、なぞった区間の和集合を持つ）
 *       … 同じ線を何度なぞっても区間が合体するだけ。セッション内の高速化用。
 *     ②**既存の実体化物との重なり判定**（永続の帳簿を兼ねる）
 *       … 同じ建物が z15 と z16 の両タイルに**簡略度の違う形**で入っているので、
 *         ①だけでは（線の同一性が無いので）防げない。実体化の直前に
 *         「もうそこに線があるか」を距離で見て、あるなら実体化しない。
 */
(function (global) {
  'use strict';

  /* ================= 仮値（🙋 オーナー実機目視で確定する） ================= */

  /* 曇りの濃さ。「不透明な霧」ではなく**薄く見えている**状態（§23-2） */
  var FOG = {
    bld:  'rgba(24,28,36,0.34)',   // 建物 BldA（輪郭だけ・§23-3）
    road: 'rgba(24,28,36,0.30)',   // 道路中心線 RdCL
    edge: 'rgba(24,28,36,0.22)',   // 道路縁 RdEdg（z16 だけ・§23-4）
    rail: 'rgba(24,28,36,0.34)'    // 鉄道中心線 RailCL
  };
  var FOG_W = 1.1;                 // 下書きの線の太さ(px)

  /* ブラシ半径(画面px)。3段をワンクリック切替（§23-3） */
  var BRUSH_R = { small: 10, medium: 20, large: 36 };
  var SIZES = ['small', 'medium', 'large'];
  var SIZE_JA = { small: '小', medium: '中', large: '大' };

  /* 🔴 ズーム跨ぎの二重実体化を止めるしきい値。
   * 同じ建物の z15 版と z16 版は簡略度が違うだけで、ずれは数m以内に収まる。
   * 一方 RdCL と RdEdg（道路の中心線と縁）は片側 3m 前後離れているので、
   * ここを大きくし過ぎると「縁をなぞったら中心線が出せない」になる。 */
  var OVERLAP_M = 2.5;             // これ以内に既存線があれば実体化しない
  var SAMPLE_DIV = 3;              // 重なり判定の刻み ＝ OVERLAP_M / これ
  var MIN_KEEP_PX = 7;             // これより短い切れ端は作らない（画面px）

  /* 1画面で取りに行くタイルの上限（暴走よけ）。
   * 🔴 必要枚数は**画面の大きさだけ**で決まる（256px/枚）ので、ズームを引いても
   *    増えない。1188×703 の実測で 20〜24枚、4K(3840×2160) でも 160枚ほど。
   *    ここを小さくすると大きなモニタで曇り下書きが**黙って出なくなる**ので、
   *    「まず起こらない値」にしてある（バグの保険であって節約装置ではない）。 */
  var MAX_TILES = 180;
  var TILE_CACHE_MAX = 220;        // タイルの持ち過ぎ防止（LRU・見えている物は必ず残る）

  var GSI_ZOOM_MAX = 16;           // 地理院ベクトルタイルの上限（§11・§12-a）
  var GSI_ZOOM_MIN = 4;

  var EQUATOR_M = 40075016.686;

  /* 実体化した線の見た目。所在図の自動生成（shozaizu.js）と揃える。
   * 🔒 §23-9: 建物（bld）の太さ・色は Editor.MAPSTYLE.bldg が唯一の出どころ
   * （自動生成の建物となぞり出した建物が別の見た目になると不具合に見えるため）。
   * 🔴 道路（road）・道路縁（edge）は**白帯にしない**。§23-9 の高ZL側は
   *    「建物が実線の輪郭のみ・細街路や敷地内通路まで線」＝線で描くのが目標像で、
   *    なぞり出しは途中まで塗れば線の切れ端になる（§23-3）ので、
   *    切れ端に帯を付けると端が黒く塞がって見える。白帯は所在図の自動生成の
   *    選択肢（case.roadStyle）に閉じておく。 */
  function outStyle(kind) {
    if (kind === 'bld') {
      var M = global.Editor && global.Editor.MAPSTYLE && global.Editor.MAPSTYLE.bldg;
      return { w: (M && M.w) || OUT_STYLE.bld.w,
               color: (M && M.color) || OUT_STYLE.bld.color };
    }
    return OUT_STYLE[kind] || OUT_STYLE.road;
  }
  var OUT_STYLE = {
    bld:  { w: 1.3, color: '#333' },   // ← Editor.MAPSTYLE.bldg のフォールバック
    road: { w: 2.0, color: '#111' },
    edge: { w: 1.2, color: '#111' },
    rail: { w: 2.6, color: '#111', rail: true }
  };

  /* ================= 名称の分類なぞり出し（🔒 §23-5・Step 8） =================
   * 思想（オーナー原文・§23-5）: 一覧が文字として並んでいても、どこにその名称が
   * 存在するか分からない。どの分類を出すかは提出する警察署で違うので、
   * **一括で出すレベルをこちらで決めず、ユーザーが出しやすいようにする**。
   *   → 分類チェックが ON の物だけ「地図上のその場所」に薄く出し、
   *     〇でなぞると **1個まるごと** 実体化する（§23-3 の例外＝文字を半分出す意味がない）。
   */

  /* 文字の大きさ（画面px）。editor.js の TEXT_PX と同じ値にする
   * ＝薄出しと実体化後の見た目がぴったり重なる（ずれると「なぞったら動いた」に見える） */
  var NAME_PX = { small: 12, medium: 15, large: 19 };
  /* 🔒 §30-25-7: 文字の大きさが**ズームに連動**するようになったので、薄出しも
   * editor と同じ換算（Editor.prototype.textPx ＝ 紙のミリ × mmPx()）で出す。
   * ＝「なぞったら大きさが変わった」に見えない（上の表は予備）。 */
  function namePxOf(ed, size) {
    if (ed && typeof ed.textPx === 'function') {
      var v = ed.textPx({ size: size });
      if (v > 0) return v;
    }
    return NAME_PX[size] || NAME_PX.medium;
  }
  /* 🔒 §30-30-1: 印（信号機・バス停）の大きさは**文字の大きさに連動しない**。
   * 薄出しの仮の印も「図に入れた時の見た目」に合わせて、基準（MARK_BASE_MM × mmPx）
   * で描く＝拾った瞬間に大きさが変わらない。
   * 🔴 値の出どころは editor.js の Editor.prototype.markBasePx 1か所。 */
  function markBasePxOf(ed) {
    if (ed && typeof ed.markBasePx === 'function') {
      var v = ed.markBasePx();
      if (v > 0) return v;
    }
    return NAME_PX.medium;
  }
  var NAME_DOT_R = 3.6;            // 薄出しの●の半径(px)。editor の r0（size*0.24）と揃う
  var NAME_GAP = 4;                // 印と文字の間(px)
  var NAME_PAD = 3;                // 当たり判定・重なり判定の余白(px)
  var NAME_MARGIN = 60;            // 画面のこの外側までは候補を作らない(px)

  var FOG_NAME = 'rgba(24,28,36,0.55)';    // 薄出しの文字（線より少し濃い＝読めないと選べない）
  var FOG_NAME_HALO = 'rgba(255,255,255,0.85)';
  var FOG_NAME_DOT = 'rgba(24,28,36,0.5)';

  /* 印の形（🔒 2026-09-02 オーナー指示）。交差点名だけ**信号機のアイコン**にする。
   * 寸法は editor.js の Editor.signalGeom が唯一の出どころ ＝ 薄出し・画面・紙の
   * 3か所が同じ形になる（Editor.MAPSTYLE.bldg を outStyle が読むのと同じ作法）。 */
  var SIGNAL_FALLBACK = { w: 1.25, h: 0.55, r: 0.13, gap: 0.375, rx: 0.16, lw: 1.6 };
  function signalGeom(size) {
    if (global.Editor && global.Editor.signalGeom) return global.Editor.signalGeom(size);
    var K = SIGNAL_FALLBACK;
    return { w: size * K.w, h: size * K.h, r: size * K.r,
             gap: size * K.gap, rx: size * K.rx, lw: K.lw };
  }
  /* バス停の標識アイコン（🔒 2026-09-04）。寸法は Editor.busStopGeom が唯一の出どころ
   * （signalGeom と同じ作法）。anchor は足の接地点＝アイコンは anchor から上へだけ伸びる。 */
  var BUS_FALLBACK = { bw: 0.42, bh: 0.68, rx: 0.10, pole: 0.32, foot: 0.50, lw: 1.6 };
  function busGeom(size) {
    if (global.Editor && global.Editor.busStopGeom) return global.Editor.busStopGeom(size);
    var K = BUS_FALLBACK;
    return { bw: size * K.bw, bh: size * K.bh, rx: size * K.rx,
             pole: size * K.pole, foot: size * K.foot, lw: K.lw,
             h: size * (K.pole + K.bh) };
  }
  /** 印の「上に文字を逃がす量」。signal は矩形が anchor を中心に上下対称なので高さの半分、
   *  bus は anchor（足の接地点）から上へだけ伸びるので**全高**、●は半径そのもの。
   *  🔒 §30-30-1: 引数は**印の大きさ**（基準 markBasePxOf）＝文字の大きさではない。 */
  function markHalfH(mark, fs) {
    if (mark === 'signal') return signalGeom(fs).h / 2;
    if (mark === 'bus') return busGeom(fs).h;
    return NAME_DOT_R;
  }
  /** 角丸矩形のパス（canvas 標準の roundRect は環境差があるので自前で引く） */
  function roundRectPath(ctx, x, y, w, h, r) {
    r = Math.max(0, Math.min(r, w / 2, h / 2));
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y);
    ctx.arcTo(x + w, y, x + w, y + r, r);
    ctx.lineTo(x + w, y + h - r);
    ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
    ctx.lineTo(x + r, y + h);
    ctx.arcTo(x, y + h, x, y + h - r, r);
    ctx.lineTo(x, y + r);
    ctx.arcTo(x, y, x + r, y, r);
    ctx.closePath();
  }
  /** 信号機を1つ描く（薄出しは色を薄く・実体化直後は本番色）。§23-9 線だけ＋灯だけ塗る */
  function drawSignal(ctx, px, py, fs, color) {
    var sg = signalGeom(fs);
    ctx.lineWidth = sg.lw;
    ctx.strokeStyle = color;
    roundRectPath(ctx, px - sg.w / 2, py - sg.h / 2, sg.w, sg.h, sg.rx);
    ctx.stroke();
    ctx.fillStyle = color;
    for (var i = -1; i <= 1; i++) {
      ctx.beginPath();
      ctx.arc(px + i * sg.gap, py, sg.r, 0, Math.PI * 2);
      ctx.fill();
    }
  }
  /** バス停標識を1つ描く（🔒 2026-09-04）。(px,py) は足の接地点＝アイコンは上へだけ伸びる。
   *  §23-9 線だけ・塗りは一切なし（板の中に灯は入れない＝信号機と区別）。 */
  function drawBusStop(ctx, px, py, fs, color) {
    var bg = busGeom(fs);
    var poleTopY = py - bg.pole, boardTopY = poleTopY - bg.bh;
    ctx.lineWidth = bg.lw;
    ctx.strokeStyle = color;
    ctx.beginPath();
    ctx.moveTo(px - bg.foot / 2, py);
    ctx.lineTo(px + bg.foot / 2, py);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(px, py);
    ctx.lineTo(px, poleTopY);
    ctx.stroke();
    roundRectPath(ctx, px - bg.bw / 2, boardTopY, bg.bw, bg.bh, bg.rx);
    ctx.stroke();
  }

  /* 重なった時に縦へ逃がす段数。
   * 🔴 ここで空きが見つからない名称は**出さない**（重ねて描かない）。
   *    重ねると①読めない②筆が触れた時に見えていない名称まで実体化する、の2つが起きる。
   *    出せなかった数は画面に出し「拡大すると出ます」と案内する（実測: 名駅前で発生）。 */
  var NAME_SLOTS = [0, -1, 1, -2, 2, -3, 3];

  var OSM_DEBOUNCE_MS = 700;       // 地図を動かし終えてから取りに行くまで（§23-6 控えめに叩く）

  /* ================= 投影（MapView と同じ Web メルカトル） ================= */

  function mercX(lng) { return (lng + 180) / 360; }
  function mercY(lat) {
    var s = Math.sin(lat * Math.PI / 180);
    s = Math.max(-0.9999, Math.min(0.9999, s));
    return 0.5 - Math.log((1 + s) / (1 - s)) / (4 * Math.PI);
  }
  function invMercX(x) { return x * 360 - 180; }
  function invMercY(y) {
    return Math.atan(Math.sinh(Math.PI * (1 - 2 * y))) * 180 / Math.PI;
  }

  function uid() {
    return 'v' + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  }

  /* ================= 折れ線のかたまり =================
   * p   … 正規化メルカトルの平坦配列 [x0,y0,x1,y1,...]
   * cum … 各頂点までの累積長（メルカトル単位）／ len … 全長
   * これがあれば「弧長 0〜1 の区間」を切り出せる。 */

  function makeChunk(p, n) {
    var cum = new Float64Array(n), tot = 0, i;
    for (i = 1; i < n; i++) {
      var dx = p[i * 2] - p[(i - 1) * 2];
      var dy = p[i * 2 + 1] - p[(i - 1) * 2 + 1];
      tot += Math.sqrt(dx * dx + dy * dy);
      cum[i] = tot;
    }
    return { p: p, n: n, cum: cum, len: tot };
  }

  /** 弧長 t0〜t1（0〜1）の部分を切り出す。返り値は同じ形のかたまり */
  function subChunk(c, t0, t1) {
    var L0 = t0 * c.len, L1 = t1 * c.len;
    var out = [], p = c.p, cum = c.cum, i;
    for (i = 1; i < c.n; i++) {
      var s0 = cum[i - 1], s1 = cum[i], seg = s1 - s0;
      if (seg <= 0 || s1 <= L0 || s0 >= L1) continue;
      var a = Math.max(L0, s0), b = Math.min(L1, s1);
      var ua = (a - s0) / seg, ub = (b - s0) / seg;
      var ax = p[(i - 1) * 2], ay = p[(i - 1) * 2 + 1];
      var bx = p[i * 2], by = p[i * 2 + 1];
      if (!out.length) {
        out.push(ax + (bx - ax) * ua, ay + (by - ay) * ua);
      }
      out.push(ax + (bx - ax) * ub, ay + (by - ay) * ub);
    }
    if (out.length < 4) return null;
    return makeChunk(Float64Array.from(out), out.length / 2);
  }

  function chunkToLatLng(c) {
    var out = [], i;
    for (i = 0; i < c.n; i++) {
      out.push({ lat: invMercY(c.p[i * 2 + 1]), lng: invMercX(c.p[i * 2]) });
    }
    return out;
  }

  /** 円（中心 cx,cy／半径 r）が線分 a→b を覆う区間 [t0,t1] を返す。無ければ null */
  function circleSeg(ax, ay, bx, by, cx, cy, r) {
    var dx = bx - ax, dy = by - ay;
    var a = dx * dx + dy * dy;
    if (a <= 0) return null;
    var fx = ax - cx, fy = ay - cy;
    var b = 2 * (fx * dx + fy * dy);
    var c = fx * fx + fy * fy - r * r;
    var disc = b * b - 4 * a * c;
    if (disc < 0) return null;
    var sq = Math.sqrt(disc);
    var t0 = (-b - sq) / (2 * a), t1 = (-b + sq) / (2 * a);
    if (t0 < 0) t0 = 0;
    if (t1 > 1) t1 = 1;
    if (t1 <= t0) return null;
    return [t0, t1];
  }

  /* ================= 重なり判定のための格子 =================
   * 既存の実体化物（線・折れ線・多角形）を cell 刻みで点に散らして格子に入れる。
   * 問い合わせは 3×3 セルを見るだけ（cell = しきい値なので取りこぼさない）。 */

  function Grid(cell) {
    this.cell = cell;
    this.m = Object.create(null);
    this.count = 0;
  }
  Grid.prototype._put = function (x, y) {
    var k = Math.floor(x / this.cell) + ':' + Math.floor(y / this.cell);
    var a = this.m[k];
    if (!a) { a = this.m[k] = []; }
    a.push(x, y);
    this.count++;
  };
  /** 平坦配列の折れ線を step 刻みで点にして入れる */
  Grid.prototype.addFlat = function (p, n, step) {
    if (n < 2) { if (n === 1) this._put(p[0], p[1]); return; }
    for (var i = 1; i < n; i++) {
      var ax = p[(i - 1) * 2], ay = p[(i - 1) * 2 + 1];
      var bx = p[i * 2], by = p[i * 2 + 1];
      var d = Math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
      var k = Math.max(1, Math.ceil(d / step)), j;
      for (j = 0; j < k; j++) {
        var u = j / k;
        this._put(ax + (bx - ax) * u, ay + (by - ay) * u);
      }
    }
    this._put(p[(n - 1) * 2], p[(n - 1) * 2 + 1]);
  };
  Grid.prototype.addLatLngs = function (pts, step) {
    var n = pts.length;
    if (!n) return;
    var p = new Float64Array(n * 2);
    for (var i = 0; i < n; i++) {
      p[i * 2] = mercX(pts[i].lng);
      p[i * 2 + 1] = mercY(pts[i].lat);
    }
    this.addFlat(p, n, step);
  };
  Grid.prototype.near = function (x, y, tol) {
    var c = this.cell, gx = Math.floor(x / c), gy = Math.floor(y / c);
    var t2 = tol * tol, dx, dy, a, i;
    for (dx = -1; dx <= 1; dx++) {
      for (dy = -1; dy <= 1; dy++) {
        a = this.m[(gx + dx) + ':' + (gy + dy)];
        if (!a) continue;
        for (i = 0; i < a.length; i += 2) {
          var ex = a[i] - x, ey = a[i + 1] - y;
          if (ex * ex + ey * ey <= t2) return true;
        }
      }
    }
    return false;
  };

  /* ================= Reveal ================= */

  /**
   * @param map    MapView
   * @param editor Editor（実体化物の置き場。this.objects へ**代入はしない**・§26-2 注意①）
   */
  function Reveal(map, editor) {
    this.map = map;
    this.editor = editor;
    this.active = false;
    this.size = 'medium';
    this.sheetKey = '';          // シート固有（§24-1）。app が bindCurrentSheet で入れる
    /* 🔒 §22-am-3: 実体化した名前を外帯へ置くのに使う紙の枠。
     * app から入れてもらえるならそれが最優先。入っていなければ画面に出ている
     * 書き出し枠（.frame-rect）を読む（_frameBounds）。 */
    this.frameBounds = null;
    this.onReveal = null;        // function(n) … 実体化したら呼ぶ（出典・ヒント用）
    this.onStatus = null;        // function(text) … 取得中などの状態

    this._tiles = Object.create(null);   // 'z/x/y' -> {state, lines, seq}
    this._seq = 0;
    this._ledgerLines = [];      // 区間帳簿を持っている線（掃除用）
    this._cursor = null;         // ブラシの輪を出す位置（画面px）
    this._stroke = null;         // なぞっている最中の状態
    this._strokeObjs = [];       // このなぞりで作った図形（canvas に即時描画する分）
    this._raf = 0;
    this._lastDrawMs = 0;

    /* ---- 名称の分類なぞり出し（§23-5・Step 8） ---- */
    this.nameCats = Object.create(null);   // {public:true, road:true, ...}
    this.onNames = null;         // function(info) … 取得の状態を画面へ（fail-soft の表示）
    this._osm = { state: 'idle', items: [], roads: [], bbox: null,
                  ms: 0, bytes: 0, err: '', cached: false };
    this._osmTimer = 0;
    this._osmSeq = 0;
    this._nameBoxes = [];        // 直近の draw で置いた薄出しラベル（当たり判定に使う）
    this._nameCounts = Object.create(null);   // 分類ごとの薄出し件数（実測・表示用）
    this._nameShown = '';        // 画面に出ている薄出しの数（変わった時だけ案内を更新）
    this._nameHidden = 0;        // 重なりで出せなかった数（拡大すれば出る・案内に使う）
    this._strokeNames = [];      // このなぞりで実体化した名称（commit まで canvas に出す）

    /* 曇り下書きの canvas は **下敷きと SVG の間**に入れる（imglay と同じ作法）。
     * 🔴 pointer-events:none。掴めるのは実体化した後だけ（§23-2）。 */
    var cv = document.createElement('canvas');
    cv.className = 'reveal-fog';
    cv.hidden = true;
    map.el.insertBefore(cv, map.overlay);
    this.canvas = cv;
    this.ctx = cv.getContext('2d');

    var self = this;
    map.on('change', function () {
      self.invalidate();
      /* 🔒 §23-6: 表示範囲が変わったら OSM を取り直す（**デバウンス**して控えめに）。
       * 取れている範囲で足りていれば OSM 側のキャッシュが同期で返す。 */
      self._scheduleOsm();
    });
    map.el.addEventListener('pointermove', function (e) {
      if (!self.active) return;
      var r = map.el.getBoundingClientRect();
      self._cursor = { x: e.clientX - r.left, y: e.clientY - r.top };
      self.invalidate();
    });
    map.el.addEventListener('pointerleave', function () {
      if (!self.active) return;
      self._cursor = null;
      self.invalidate();
    });
  }

  /* ---------- 出入り ---------- */

  /** なぞり出しの道具を持っている間だけ曇り下書きを出す（§23-2 の ON/OFF） */
  Reveal.prototype.setActive = function (on) {
    on = !!on;
    if (this.active === on) return;
    this.active = on;
    this.canvas.hidden = !on;
    if (on) {
      this.invalidate();
      this._scheduleOsm(true);        // 分類が ON なら道具を持った時点で取りに行く
    } else {
      this._stroke = null;
      this._strokeObjs = [];
      this._strokeNames = [];
      this._nameBoxes = [];
      this._cursor = null;
      if (this._osmTimer) { clearTimeout(this._osmTimer); this._osmTimer = 0; }
      var c = this.ctx;
      if (c) c.clearRect(0, 0, this.canvas.width, this.canvas.height);
    }
  };

  /** 🔴 §24-1: 実体化物はそのシート固有。帳簿もシートごとに分ける */
  Reveal.prototype.setSheet = function (key) {
    this.sheetKey = key || '';
    this._stroke = null;
    this._strokeObjs = [];
    /* 🔒 §24-1: 実体化した名称は**そのシート固有**。薄出しの候補は
     * 「その紙に既にある文字」を見て決める（§23-5）ので、紙が変われば作り直す。 */
    this._strokeNames = [];
    this._nameBoxes = [];
    this.invalidate();
  };

  Reveal.prototype.setSize = function (s) {
    if (BRUSH_R[s] === undefined) return;
    this.size = s;
    this.invalidate();
  };
  /** 3段を1つ送る（キー操作用）。d = +1 / -1 */
  Reveal.prototype.stepSize = function (d) {
    var i = SIZES.indexOf(this.size);
    if (i < 0) i = 1;
    i = Math.max(0, Math.min(SIZES.length - 1, i + (d > 0 ? 1 : -1)));
    this.setSize(SIZES[i]);
    return this.size;
  };
  Reveal.sizeJa = function (s) { return SIZE_JA[s] || s; };
  Reveal.SIZES = SIZES;

  /**
   * 次の描画を予約する。
   * 🔴 requestAnimationFrame **だけ**に頼らない。ウィンドウが他の窓に隠れている・
   *    タブが背面にある環境では rAF が呼ばれず、曇り下書きが出ないまま固まる
   *    （実測: 背面タブでは 3 秒待っても発火しない）。取りこぼしを拾う保険として
   *    短いタイマーを併走させ、先に来た方で描いてもう片方を取り消す。
   */
  Reveal.prototype.invalidate = function () {
    if (!this.active || this._raf) return;
    var self = this;
    var done = false;
    function run() {
      if (done) return;
      done = true;
      if (self._timer) { clearTimeout(self._timer); self._timer = 0; }
      self._raf = 0;
      self.draw();
    }
    this._raf = requestAnimationFrame(run) || -1;
    this._timer = setTimeout(run, 60);
  };

  /* ---------- タイル ---------- */

  /** 表示中ZLに対応する地理院タイルのズーム（17以上は z16 のまま・§23-4/§12-a） */
  Reveal.prototype.tileZoom = function () {
    return Math.max(GSI_ZOOM_MIN,
                    Math.min(GSI_ZOOM_MAX, Math.round(this.map.getZoom())));
  };

  Reveal.prototype._need = function () {
    var m = this.map, s = m.size();
    if (!s.w || !s.h) return null;
    var tz = this.tileZoom();
    var n = Math.pow(2, tz);
    var b = m.getBounds();
    var x0 = Math.floor(mercX(b.west) * n), x1 = Math.floor(mercX(b.east) * n);
    var y0 = Math.floor(mercY(b.north) * n), y1 = Math.floor(mercY(b.south) * n);
    x0 = Math.max(0, x0); y0 = Math.max(0, y0);
    x1 = Math.min(n - 1, x1); y1 = Math.min(n - 1, y1);
    return { z: tz, x0: x0, x1: x1, y0: y0, y1: y1,
             count: (x1 - x0 + 1) * (y1 - y0 + 1) };
  };

  Reveal.prototype._ensureTiles = function (need) {
    if (!need || need.count > MAX_TILES) return;
    var self = this, x, y;
    for (x = need.x0; x <= need.x1; x++) {
      for (y = need.y0; y <= need.y1; y++) {
        var key = need.z + '/' + x + '/' + y;
        var t = this._tiles[key];
        if (t) { t.seq = ++this._seq; continue; }
        t = this._tiles[key] = { state: 'loading', lines: null, names: null,
                                 seq: ++this._seq };
        /* eslint-disable no-loop-func */
        (function (entry, z, tx, ty) {
          GSI.fetchTile(z, tx, ty).then(function (tile) {
            var b = tile ? buildTile(tile) : { lines: [], names: [] };
            entry.state = 'ready';
            entry.lines = b.lines;
            entry.names = b.names;
            self.invalidate();
          }).catch(function () {
            entry.state = 'error';
            entry.lines = [];
            entry.names = [];
          });
        })(t, need.z, x, y);
        /* eslint-enable no-loop-func */
      }
    }
    this._evict();
  };

  Reveal.prototype._evict = function () {
    var keys = Object.keys(this._tiles);
    if (keys.length <= TILE_CACHE_MAX) return;
    var self = this;
    keys.sort(function (a, b) { return self._tiles[a].seq - self._tiles[b].seq; });
    var drop = keys.length - TILE_CACHE_MAX, dirty = false;
    for (var i = 0; i < drop; i++) {
      var t = this._tiles[keys[i]];
      if (t && t.lines) {
        for (var j = 0; j < t.lines.length; j++) {
          if (t.lines[j]._listed) { t.lines[j]._listed = false; dirty = true; }
        }
      }
      delete this._tiles[keys[i]];
    }
    /* 捨てたタイルの線を掃除リストからも外す（帳簿はセッション内の高速化用なので
     * 消えても害は無い。重なり判定の方が永続の帳簿・§23-3）。 */
    if (dirty) {
      this._ledgerLines = this._ledgerLines.filter(function (l) { return l._listed; });
    }
  };

  /** いま見えているタイルの線を集める */
  Reveal.prototype._visibleLines = function (need) {
    var out = [];
    if (!need || need.count > MAX_TILES) return out;
    for (var x = need.x0; x <= need.x1; x++) {
      for (var y = need.y0; y <= need.y1; y++) {
        var t = this._tiles[need.z + '/' + x + '/' + y];
        if (t && t.lines && t.lines.length) out.push(t.lines);
      }
    }
    return out;
  };

  /** いま見えているタイルの注記（地理院 Anno 由来の名称）を集める（§23-5） */
  Reveal.prototype._visibleGsiNames = function (need) {
    var out = [];
    if (!need || need.count > MAX_TILES) return out;
    for (var x = need.x0; x <= need.x1; x++) {
      for (var y = need.y0; y <= need.y1; y++) {
        var t = this._tiles[need.z + '/' + x + '/' + y];
        if (t && t.names && t.names.length) out.push(t.names);
      }
    }
    return out;
  };

  /* ================= タイル → 折れ線 ================= */

  /**
   * 地理院 Anno（注記）→ 名称の薄出し候補（§23-5）。
   * 🔴 ここで拾うのは**分類表で「地理院 Anno（既存）」と書かれた2つだけ**:
   *    公共的建物（landmark）と 道路名（roadname＝411系）。
   *    交差点名・お店・会社・バス停は地理院に無い（実測 §23-5）ので OSM 側で取る。
   * 地名(place)・自然地名・鉄道名は §23-5 の7分類に無いので候補にしない
   * （所在図の自動生成 §5 が従来どおり出す側）。
   */
  function buildNames(tile) {
    var out = [], A = tile.layers && tile.layers.Anno;
    if (!A) return out;
    var n = Math.pow(2, tile.z), i;
    for (i = 0; i < A.features.length; i++) {
      var f = A.features[i];
      var kind = GSI.annoKind(f.props.vt_code, { vegetation: false, nature: false });
      var cat = kind === 'landmark' ? 'public' : (kind === 'roadname' ? 'road' : null);
      if (!cat) continue;
      var txt = f.props.vt_text;
      if (!txt || !f.geom.length || !f.geom[0].length) continue;
      var p0 = f.geom[0][0];
      out.push({
        cat: cat, name: txt, src: 'gsi', code: f.props.vt_code,
        // 正規化メルカトル（下書き線と同じ持ち方＝画面座標は乗加算1回で出る）
        mx: (tile.x + p0[0] / A.extent) / n,
        my: (tile.y + p0[1] / A.extent) / n
      });
    }
    return out;
  }

  function buildTile(tile) {
    return { lines: buildLines(tile), names: buildNames(tile) };
  }

  function buildLines(tile) {
    var out = [], n = Math.pow(2, tile.z), L;

    function add(kind, ring, extent, minPts, widthM, floorU) {
      var m = ring.length;
      if (m < minPts) return;
      var p = new Float64Array(m * 2), i;
      var bx0 = Infinity, by0 = Infinity, bx1 = -Infinity, by1 = -Infinity;
      for (i = 0; i < m; i++) {
        var X = (tile.x + ring[i][0] / extent) / n;
        var Y = (tile.y + ring[i][1] / extent) / n;
        p[i * 2] = X; p[i * 2 + 1] = Y;
        if (X < bx0) bx0 = X;
        if (X > bx1) bx1 = X;
        if (Y < by0) by0 = Y;
        if (Y > by1) by1 = Y;
      }
      var c = makeChunk(p, m);
      if (!(c.len > 0)) return;
      c.kind = kind;
      // 🔒 §22-at 規則6: 道路は RdCL の同じ属性(vt_rnkwidth)から widthM を持つ。
      // 'road' 以外・不明ランクは undefined のまま(実体化物は widthM を持たない)。
      if (widthM) c.widthM = widthM;
      // 🔒 §22-at-2: ランク別の紙の下限(内部属性)。同じ作法で floorU も運ぶ。
      if (floorU) c.floorU = floorU;
      c.bx0 = bx0; c.by0 = by0; c.bx1 = bx1; c.by1 = by1;
      c.rev = null;                 // 区間帳簿（シートごと）。使う時に作る
      out.push(c);
    }

    function eachGeom(layer, kind, minPts, skip) {
      if (!layer) return;
      for (var i = 0; i < layer.features.length; i++) {
        var f = layer.features[i];
        if (skip && skip(f)) continue;
        var widthM = (kind === 'road') ? GSI.roadWidthM(f.props) : undefined;
        var floorU = (kind === 'road') ? GSI.roadFloorU(f.props) : undefined;
        for (var g = 0; g < f.geom.length; g++) {
          add(kind, f.geom[g], layer.extent, minPts, widthM, floorU);
        }
      }
    }

    /* 🔒 §23-3/§23-9: 建物は**線（輪郭）のみ**。塗りは使わない */
    eachGeom(tile.layers.BldA, 'bld', 3);
    eachGeom(tile.layers.RdCL, 'road', 2);
    eachGeom(tile.layers.RdEdg, 'edge', 2);
    /* 地下・トンネルの鉄道は所在図に描かない（§11 実測・shozaizu.js と同じ扱い） */
    eachGeom(tile.layers.RailCL, 'rail', 2, function (f) {
      return f.props.vt_railstate === '地下' || f.props.vt_railstate === 'トンネル';
    });
    return out;
  }

  /* ================= 描画 ================= */

  Reveal.prototype.draw = function () {
    if (!this.active) return;
    var t0 = (global.performance && performance.now) ? performance.now() : 0;
    var map = this.map, s = map.size();
    if (!s.w || !s.h) return;
    var dpr = Math.min(2, global.devicePixelRatio || 1);
    var cv = this.canvas, ctx = this.ctx;
    if (cv.width !== Math.round(s.w * dpr) || cv.height !== Math.round(s.h * dpr)) {
      cv.width = Math.round(s.w * dpr);
      cv.height = Math.round(s.h * dpr);
      cv.style.width = s.w + 'px';
      cv.style.height = s.h + 'px';
    }
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, s.w, s.h);

    var need = this._need();
    this._ensureTiles(need);

    var ws = map.worldSize();
    var cx = mercX(map.getCenter().lng), cy = mercY(map.getCenter().lat);
    var ox = s.w / 2 - cx * ws, oy = s.h / 2 - cy * ws;
    // 画面に写っているメルカトル範囲（少しだけ外も含める）
    var vx0 = (0 - ox) / ws, vx1 = (s.w - ox) / ws;
    var vy0 = (0 - oy) / ws, vy1 = (s.h - oy) / ws;
    var pad = 40 / ws;
    vx0 -= pad; vx1 += pad; vy0 -= pad; vy1 += pad;

    var groups = this._visibleLines(need);
    var kinds = ['edge', 'road', 'rail', 'bld'], ki, gi, i, j, c;
    ctx.lineWidth = FOG_W;
    ctx.lineJoin = 'round';
    ctx.lineCap = 'round';
    var drawn = 0;
    for (ki = 0; ki < kinds.length; ki++) {
      var kind = kinds[ki];
      ctx.strokeStyle = FOG[kind];
      ctx.beginPath();
      for (gi = 0; gi < groups.length; gi++) {
        var arr = groups[gi];
        for (i = 0; i < arr.length; i++) {
          c = arr[i];
          if (c.kind !== kind) continue;
          if (c.bx1 < vx0 || c.bx0 > vx1 || c.by1 < vy0 || c.by0 > vy1) continue;
          ctx.moveTo(c.p[0] * ws + ox, c.p[1] * ws + oy);
          for (j = 1; j < c.n; j++) {
            ctx.lineTo(c.p[j * 2] * ws + ox, c.p[j * 2 + 1] * ws + oy);
          }
          drawn++;
        }
      }
      ctx.stroke();
    }

    /* なぞっている最中に作った線は、SVG を組み直さずここへ即描きする
     * （editor.render() は図形が多いと重いので、離した時に1回だけ呼ぶ）。 */
    if (this._strokeObjs.length) {
      ctx.strokeStyle = '#111';
      ctx.lineWidth = 2;
      ctx.beginPath();
      for (i = 0; i < this._strokeObjs.length; i++) {
        var pts = this._strokeObjs[i].points;
        for (j = 0; j < pts.length; j++) {
          var X = mercX(pts[j].lng) * ws + ox, Y = mercY(pts[j].lat) * ws + oy;
          if (j) ctx.lineTo(X, Y); else ctx.moveTo(X, Y);
        }
      }
      ctx.stroke();
    }

    /* 🔒 §23-5: 分類チェックが ON の名称を「その場所」に薄く出す。
     * ここで置いた位置がそのまま実体化後の位置になる（_nameBoxes）。 */
    this._drawNames(ctx, ws, ox, oy, s);
    if (this._strokeNames.length) this._drawStrokeNames(ctx, ws, ox, oy);

    /* ブラシの輪（大きさが見えないと3段の切替が伝わらない）。
     * 🔒 §23-7-b: スペース一時パン中は輪を出さない ―― カーソルは掌になっていて
     *    「いまはなぞれない」が伝わるべき場面なので、筆の輪が残ると嘘になる。 */
    if (this._cursor && !(this.editor && this.editor.isSpacePan
                          && this.editor.isSpacePan())) {
      var r = BRUSH_R[this.size];
      ctx.beginPath();
      ctx.arc(this._cursor.x, this._cursor.y, r, 0, Math.PI * 2);
      ctx.strokeStyle = 'rgba(26,86,196,0.95)';
      ctx.lineWidth = 1.6;
      ctx.stroke();
      ctx.strokeStyle = 'rgba(255,255,255,0.9)';
      ctx.lineWidth = 0.8;
      ctx.beginPath();
      ctx.arc(this._cursor.x, this._cursor.y, r + 1.2, 0, Math.PI * 2);
      ctx.stroke();
    }

    this._lastDrawMs = t0
      ? ((global.performance && performance.now) ? performance.now() - t0 : 0) : 0;
    this._lastDrawn = drawn;
  };

  /** 実測用（開発時に window.SHAKO_DEBUG から読む） */
  Reveal.prototype.stats = function () {
    return { drawMs: Math.round(this._lastDrawMs * 100) / 100,
             lines: this._lastDrawn || 0,
             tiles: Object.keys(this._tiles).length };
  };

  /* ================= 名称の分類なぞり出し（🔒 §23-5 / §23-5-a / §23-6） =================
   * 「一括で出すレベルをこちらで決めず、ユーザーが出しやすいようにする」（オーナー §23-5）
   * ＝ 分類チェックが ON の名称だけを**その場所に薄く出す**。〇でなぞると1個まるごと実体化。
   */

  function hasOSM() { return typeof global.OSM !== 'undefined'; }

  Reveal.prototype._anyNameCat = function () {
    for (var k in this.nameCats) if (this.nameCats[k]) return true;
    return false;
  };

  /** 分類チェックの ON/OFF（app.js のチェックボックスから） */
  Reveal.prototype.setNameCats = function (cats) {
    var next = Object.create(null);
    if (cats && hasOSM()) {
      OSM.CATS.forEach(function (c) { if (cats[c.id]) next[c.id] = true; });
    }
    this.nameCats = next;
    this._nameBoxes = [];
    if (this._anyNameCat()) {
      this._scheduleOsm(true);
    } else {
      if (this._osmTimer) { clearTimeout(this._osmTimer); this._osmTimer = 0; }
      this._osmSeq++;                       // 走っている取得の結果を捨てる
      this._osm.state = 'idle';
      this._osm.items = [];
      this._osm.roads = [];
      this._osm.err = '';
      this._emitNames();
    }
    this.invalidate();
  };

  /**
   * 表示範囲の OSM 取得を予約する。
   * 🔴 §23-6「公共インスタンスなので控えめに叩く」＝ **デバウンス**。
   *    地図を動かし終えてから OSM_DEBOUNCE_MS 待って初めて投げる。
   */
  Reveal.prototype._scheduleOsm = function (soon) {
    if (this._osmTimer) { clearTimeout(this._osmTimer); this._osmTimer = 0; }
    if (!this.active || !this._anyNameCat() || !hasOSM()) return;
    var self = this;
    this._osmTimer = setTimeout(function () {
      self._osmTimer = 0;
      self._runOsm();
    }, soon ? 120 : OSM_DEBOUNCE_MS);
  };

  Reveal.prototype._runOsm = function () {
    if (!this.active || !this._anyNameCat() || !hasOSM()) return;
    var self = this, o = this._osm;
    var seq = ++this._osmSeq;
    /* キャッシュに当たれば同期で戻るので、その時は「取得中」を出さない
     * （地図を動かすたびに文言が点滅するのを避ける） */
    var late = setTimeout(function () {
      if (seq !== self._osmSeq) return;
      o.state = 'loading';
      self._emitNames();
    }, 150);
    OSM.fetchNames(this.map.getBounds(), this.nameCats).then(function (r) {
      clearTimeout(late);
      if (seq !== self._osmSeq) return;
      o.state = 'ready';
      o.items = r.items; o.roads = r.roads; o.bbox = r.bbox;
      o.ms = r.ms; o.bytes = r.bytes; o.cached = !!r.cached; o.err = '';
      self._emitNames();
      self.invalidate();
    }, function (e) {
      clearTimeout(late);
      if (seq !== self._osmSeq) return;
      /* 🔴 §23-6 fail-soft: **名称なぞり出しだけ**を無効化し、作図は止めない。
       * 地理院 Anno 由来の名称（公共的建物・道路名）と線のなぞり出しはそのまま効く。 */
      o.state = (e && e.kind === 'wide') ? 'wide'
              : ((e && e.kind === 'none') ? 'idle' : 'error');
      o.items = []; o.roads = []; o.bbox = null;
      o.err = (e && e.message) || '';
      self._emitNames();
      self.invalidate();
    });
  };

  /** 取り直し（画面の［再試行］から） */
  Reveal.prototype.retryNames = function () {
    if (hasOSM()) OSM.clearCache();
    this._osm.state = 'idle';
    this._scheduleOsm(true);
  };

  Reveal.prototype._emitNames = function () {
    if (this.onNames) this.onNames(this.nameStats());
  };

  /** 画面に出ている薄出しの内訳（実測・状態表示用） */
  Reveal.prototype.nameStats = function () {
    var counts = this._nameCounts || {};
    var total = 0;
    for (var k in counts) total += counts[k];
    return {
      on: this._anyNameCat(),
      cats: Object.keys(this.nameCats),
      shown: total,
      hidden: this._nameHidden || 0,
      byCat: counts,
      osm: { state: this._osm.state, items: this._osm.items.length,
             roads: this._osm.roads.length, ms: this._osm.ms,
             bytes: this._osm.bytes, cached: this._osm.cached, err: this._osm.err }
    };
  };

  /**
   * 薄く出す候補を作る。
   *  ① 🔴 **この紙に既にある同名の文字は候補から外す**
   *     （自動生成 §5/§18-r で出ている物・手で書いた物・もう実体化した物）
   *  ② 地理院 Anno（公共的建物・道路名）を先に入れる
   *  ③ OSM を後から入れる ＝ 同名は地理院側が残る（§23-5-a の名寄せ）
   *  ④ 道路名は表示範囲内の同名 way を1ラベルに統合（§23-5-a・OSM.mergeRoads）
   */
  Reveal.prototype._candidates = function (need, b) {
    var cats = this.nameCats, out = [], seen = Object.create(null), i, j;

    var objs = this.editor.objects;
    for (i = 0; i < objs.length; i++) {
      var o = objs[i];
      if (o && o.type === 'text' && o.text) seen[o.text] = true;
    }
    function push(c) {
      if (!cats[c.cat] || seen[c.name]) return;
      seen[c.name] = true;
      out.push(c);
    }

    if (cats.public || cats.road) {
      var groups = this._visibleGsiNames(need);
      for (i = 0; i < groups.length; i++) {
        var arr = groups[i];
        for (j = 0; j < arr.length; j++) push(arr[j]);
      }
    }

    if (this._osm.state === 'ready') {
      var items = this._osm.items;
      for (i = 0; i < items.length; i++) {
        var it = items[i];
        if (!cats[it.cat] || seen[it.name]) continue;
        if (!(it.lat >= b.south && it.lat <= b.north
              && it.lng >= b.west && it.lng <= b.east)) continue;
        push({ cat: it.cat, name: it.name, src: 'osm', mark: it.mark || '',
               mx: mercX(it.lng), my: mercY(it.lat) });
      }
      if (cats.road && this._osm.roads.length && hasOSM()) {
        var merged = OSM.mergeRoads(this._osm.roads, b);
        for (i = 0; i < merged.length; i++) {
          var r = merged[i];
          push({ cat: 'road', name: r.name, src: 'osm', ways: r.ways,
                 mx: mercX(r.lng), my: mercY(r.lat) });
        }
      }
    }
    return out;
  };

  function boxesHit(a, c) {
    return !(a.x + a.w < c.x || c.x + c.w < a.x
             || a.y + a.h < c.y || c.y + c.h < a.y);
  }
  function anyBoxHit(list, c) {
    for (var i = 0; i < list.length; i++) if (boxesHit(list[i], c)) return true;
    return false;
  }
  /** 円（px,py,r）が矩形に触れているか */
  function circleHitsBox(px, py, r, b) {
    var qx = Math.max(b.x, Math.min(px, b.x + b.w));
    var qy = Math.max(b.y, Math.min(py, b.y + b.h));
    var dx = px - qx, dy = py - qy;
    return dx * dx + dy * dy <= r * r;
  }

  /**
   * 🔒 §26-4-d: いまこの紙に載っている text の画面矩形（薄出しの置き場所から除く分）。
   * 🔴 座標系は _drawNames と同じ（fog canvas ＝ map.project と同一の変換）ので、
   *    editor.outlinePoints() の返り値をそのまま箱にできる。
   * 画面の外（NAME_MARGIN の外）の文字は当たりようがないので数えない。
   */
  Reveal.prototype._existingTextBoxes = function (s) {
    var out = [], objs = (this.editor && this.editor.objects) || [], i;
    for (i = 0; i < objs.length; i++) {
      var o = objs[i];
      if (!o || o.type !== 'text' || !o.text || !o.at) continue;
      var pts = this.editor.outlinePoints(o);
      if (!pts || pts.length < 2) continue;
      var x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
      for (var j = 0; j < pts.length; j++) {
        if (pts[j].x < x0) x0 = pts[j].x;
        if (pts[j].x > x1) x1 = pts[j].x;
        if (pts[j].y < y0) y0 = pts[j].y;
        if (pts[j].y > y1) y1 = pts[j].y;
      }
      if (!isFinite(x0) || !isFinite(y0)) continue;
      x0 -= NAME_PAD; y0 -= NAME_PAD; x1 += NAME_PAD; y1 += NAME_PAD;
      if (x1 < -NAME_MARGIN || x0 > s.w + NAME_MARGIN
          || y1 < -NAME_MARGIN || y0 > s.h + NAME_MARGIN) continue;
      out.push({ x: x0, y: y0, w: x1 - x0, h: y1 - y0, cy: (y0 + y1) / 2 });
    }
    return out;
  };

  /**
   * 薄い名称を描き、当たり判定用の箱を作る。
   * 🔴 描いた位置がそのまま実体化後の位置になる（＝なぞった瞬間に文字が飛ばない）。
   */
  Reveal.prototype._drawNames = function (ctx, ws, ox, oy, s) {
    this._nameBoxes = [];
    this._nameCounts = Object.create(null);
    this._nameHidden = 0;
    if (!this._anyNameCat() || !hasOSM()) return;

    var cand = this._candidates(this._need(), this.map.getBounds());
    /* 🔒 §26-4-d（裁定4）: 空きの判定は**紙に既にある文字**から始める。
     * 🔴 §23-6-a「空きが無ければ出さない」の実装漏れ。薄出しどうししか見ていなかったので、
     *    道路名が「使用の本拠」の14mに置かれて紙で読めなくなっていた（案件③で実測）。 */
    var placed = this._existingTextBoxes(s), i, k;
    // 🔒 §30-30-1: 印の基準の大きさ（画面と同じ式）。文字（fs）とは別物
    var mBase = markBasePxOf(this.editor);
    for (i = 0; i < cand.length; i++) {
      var c = cand[i];
      var px = c.mx * ws + ox, py = c.my * ws + oy;
      if (px < -NAME_MARGIN || px > s.w + NAME_MARGIN
          || py < -NAME_MARGIN || py > s.h + NAME_MARGIN) continue;
      var meta = OSM.CAT_BY_ID[c.cat] || {};
      var fs = namePxOf(this.editor, meta.size);   // 🔒 §30-25-7
      ctx.font = '700 ' + fs + 'px "Yu Gothic UI","Meiryo",sans-serif';
      var w = ctx.measureText(c.name).width;
      var h = fs * 1.15;
      var dot = !!meta.dot;
      /* 🔒 2026-09-02: 印の形は分類の meta.mark（交差点名だけ 'signal'）。
       * 🔴 表示文字列では分岐しない（§26-2 注意②）。無指定は従来どおり●。 */
      /* 🔒 §30-21-2: まず**その物の印**（信号の無い交差点＝'dot'）→ 分類の印 */
      var mark = dot ? (c.mark || meta.mark || 'dot') : null;
      // 🔒 §30-30-1: 印の大きさは基準（mBase）＝文字の大きさに連動しない
      var mHalf = dot ? markHalfH(mark, mBase) : 0;   // 逃がし量が印の大きさに追従する
      /* 印が付く分類は文字を印の上へ逃がす（§18-8 の「●＝場所／文字＝脇」）。
       * 道路名は線に付く名前なので印を作らず、その場に横書きで置く（§23-5-a・v1）。 */
      var baseCy = dot ? (py - mHalf - NAME_GAP - h / 2) : py;
      /* 信号機・バス停は●より大きいので、**アイコンの矩形そのもの**を置き場所から除く。
       * 🔴 自分の文字は上へ逃がしてあるので当たらない。効くのは「下の段へ逃げた
       *    別の名称がアイコンに乗る」ケース（§23-6-a「空きが無ければ出さない」）。 */
      var icon = null;
      if (mark === 'signal') {
        var sg0 = signalGeom(mBase);       // 🔒 §30-30-1
        /* 🔴 ここに NAME_PAD を足してはいけない。文字の箱は上下に NAME_PAD を持つので、
         *    印にも足すと 1段目（真上・逃がし量 NAME_GAP=4）が必ず自分の印と当たり、
         *    交差点名だけ常に2段目へ飛ぶ（実測 36px 逃げた）。印の実寸のまま使う。 */
        icon = { x: px - sg0.w / 2, y: py - sg0.h / 2, w: sg0.w, h: sg0.h };
        placed.push(icon);
      } else if (mark === 'bus') {
        /* 🔒 §22-aj-2 の教訓を踏襲: ここも NAME_PAD を足さず印の実寸のまま使う。
         * バス停は anchor（足の接地点＝py）から上へだけ伸びるので、箱は
         * py を下端に、板の上端（py - 全高）を上端にする（signal の上下対称とは違う）。 */
        var bg0 = busGeom(mBase);          // 🔒 §30-30-1
        var busIconW = Math.max(bg0.bw, bg0.foot);
        icon = { x: px - busIconW / 2, y: py - bg0.h, w: busIconW, h: bg0.h };
        placed.push(icon);
      }
      var box = null;
      for (k = 0; k < NAME_SLOTS.length; k++) {
        var cy = baseCy + NAME_SLOTS[k] * (h + 2);
        var t = { x: px - w / 2 - NAME_PAD, y: cy - h / 2 - NAME_PAD,
                  w: w + NAME_PAD * 2, h: h + NAME_PAD * 2, cy: cy };
        if (!anyBoxHit(placed, t)) { box = t; break; }
      }
      if (!box) {                                  // 逃げ場なし＝出さない（上の注記）
        if (icon) placed.pop();                    // 出さない印の場所は空けておく
        this._nameHidden++;
        continue;
      }
      placed.push(box);

      // ---- 描く ----
      if (dot) {
        if (mark === 'signal') {
          drawSignal(ctx, px, py, mBase, FOG_NAME_DOT);   // 🔒 §30-30-1
        } else if (mark === 'bus') {
          drawBusStop(ctx, px, py, mBase, FOG_NAME_DOT);  // 🔒 §30-30-1
        } else {
          ctx.beginPath();
          ctx.arc(px, py, NAME_DOT_R, 0, Math.PI * 2);
          ctx.fillStyle = FOG_NAME_DOT;
          ctx.fill();
        }
        if (Math.abs(box.cy - baseCy) > 1) {     // 逃がした分は細い線でつなぐ
          ctx.strokeStyle = FOG_NAME_DOT;
          ctx.lineWidth = 0.8;
          ctx.beginPath();
          // 印の縁から引く（信号機の中を線が横切らないように）
          ctx.moveTo(px, py + (box.cy > py ? mHalf : -mHalf));
          ctx.lineTo(px, box.cy + (box.cy > py ? -h / 2 : h / 2));
          ctx.stroke();
        }
      }
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.lineWidth = 3;
      ctx.lineJoin = 'round';
      ctx.strokeStyle = FOG_NAME_HALO;
      ctx.strokeText(c.name, px, box.cy);
      ctx.fillStyle = FOG_NAME;
      ctx.fillText(c.name, px, box.cy);

      this._nameCounts[c.cat] = (this._nameCounts[c.cat] || 0) + 1;
      this._nameBoxes.push({ cand: c, x: box.x, y: box.y, w: box.w, h: box.h,
                             cx: px, cy: box.cy, px: px, py: py,
                             dot: dot, mark: mark, icon: icon,
                             size: meta.size || 'medium', fs: fs });
    }
    ctx.textAlign = 'start';
    ctx.textBaseline = 'alphabetic';

    /* 件数が変わった時だけ画面の案内を更新する（毎フレーム呼ぶと重い） */
    var sig = this._nameBoxes.length + '/' + this._nameHidden;
    if (sig !== this._nameShown) {
      this._nameShown = sig;
      this._emitNames();
    }
  };

  /** なぞり中に実体化した名称を（SVG を組み直す前に）そのまま出す */
  Reveal.prototype._drawStrokeNames = function (ctx, ws, ox, oy) {
    var i, list = this._strokeNames;
    // 🔒 §30-30-1: 印の基準の大きさ（文字の大きさには連動しない）
    var mBase = markBasePxOf(this.editor);
    for (i = 0; i < list.length; i++) {
      var o = list[i].obj;
      var fs = namePxOf(this.editor, o.size);      // 🔒 §30-25-7
      var px = mercX(o.at.lng) * ws + ox, py = mercY(o.at.lat) * ws + oy;
      ctx.font = '700 ' + fs + 'px "Yu Gothic UI","Meiryo",sans-serif';
      if (o.anchor) {
        var ax = mercX(o.anchor.lng) * ws + ox, ay = mercY(o.anchor.lat) * ws + oy;
        /* 🔒 §22-am-2 ⑥: 離して置いた名前（o.lead）は引き出し線を常時描く。
         * 🔒 §22-am-6-2: ●から**文字の箱の縁**まで（隙間 0）。描くかどうかの判定も
         * 止める位置も画面（editor.js `_drawText`）・紙（export.js `drawAnchor`）と
         * 同じ Editor.wantLead / Editor.leadStop を読む＝なぞっている最中から同じ見た目。 */
        var ldx = px - ax, ldy = py - ay;
        var ld = Math.sqrt(ldx * ldx + ldy * ldy);
        /* 🔒 §22-am-6-2: 幅は実寸で測る（ctx.font は上で紙・画面と同じ指定にしてある）。
         * 画面（editor.js）の textDrawWidth と同じ値になる＝終点も同じ。 */
        var lwHalf = ctx.measureText(o.text || '').width / 2;
        var E = global.Editor;
        /* 🔒 §30-24-5: 同一住所の主役ラベル（noLead:true）はなぞり出しでも線を描かない。
         * E.wantLead に委ねる経路・自前の予備（E 未取得時）の両方に効かせる。 */
        var draw = (o && o.noLead) ? false
                 : E && E.wantLead ? E.wantLead(o, ld, lwHalf, fs, 4)
                                   : (ld > 1 && (o.lead || ld > fs * 2.2 + lwHalf));
        if (draw) {
          var LD = (E && E.LEAD) || { w: 1.1, dash: [3, 2] };
          var stop = E && E.leadStop ? E.leadStop(ldx, ldy, ld, lwHalf, fs)
                                     : Math.min(ld * 0.55, lwHalf + fs * 0.4);
          ctx.save();
          ctx.strokeStyle = '#6b7280';
          ctx.lineWidth = LD.w;
          ctx.setLineDash(LD.dash);
          ctx.beginPath();
          ctx.moveTo(ax, ay);
          ctx.lineTo(px - ldx / ld * stop, py - ldy / ld * stop);
          ctx.stroke();
          ctx.restore();
        }
        /* 🔒 2026-09-02: 交差点名は信号機（画面 editor.js・紙 export.js と同じ形）
         * 🔒 §30-30-1: 大きさは基準（mBase）× markScale＝文字の大きさに連動しない */
        var mSz = (E && E.markSizeOf) ? E.markSizeOf(o, fs, mBase) : mBase;
        if (o.dotStyle === 'signal') {
          drawSignal(ctx, ax, ay, mSz, '#111');
        } else if (o.dotStyle === 'bus') {
          // 🔒 2026-09-04: バス停は標識アイコン（画面 editor.js・紙 export.js と同じ形）
          drawBusStop(ctx, ax, ay, mSz, '#111');
        } else {
          ctx.beginPath();
          ctx.arc(ax, ay, NAME_DOT_R, 0, Math.PI * 2);
          ctx.fillStyle = '#111';
          ctx.fill();
        }
      }
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.lineWidth = 3.2;
      ctx.lineJoin = 'round';
      ctx.strokeStyle = '#fff';
      ctx.strokeText(o.text, px, py);
      ctx.fillStyle = '#111';
      ctx.fillText(o.text, px, py);
    }
    ctx.textAlign = 'start';
    ctx.textBaseline = 'alphabetic';
  };

  /**
   * ブラシの円に触れた名称を実体化する。
   * 🔒 §23-3 の例外: 名称は**1個まるごと**（文字を半分だけ出す意味がない）。
   */
  Reveal.prototype._paintNames = function (px, py, r) {
    var st = this._stroke;
    if (!st) return;
    var boxes = this._nameBoxes, i;
    for (i = 0; i < boxes.length; i++) {
      var b = boxes[i];
      if (b.done) continue;
      var hit = circleHitsBox(px, py, r, b);
      // 印そのものをなぞっても実体化する。当たりの大きさは印の形に追従する
      if (!hit && b.dot) {
        if (b.icon) {
          hit = circleHitsBox(px, py, r, b.icon);
        } else {
          var dx = px - b.px, dy = py - b.py, rr = r + NAME_DOT_R;
          hit = (dx * dx + dy * dy) <= rr * rr;
        }
      }
      if (!hit) continue;
      b.done = true;
      this._materializeName(b, st);
    }
  };

  Reveal.prototype._materializeName = function (b, st) {
    if (!st.snapped) { this.editor.snapshot(); st.snapped = true; }
    var s = this.map.size(), ws = this.map.worldSize(), c = this.map.getCenter();
    var ox = s.w / 2 - mercX(c.lng) * ws, oy = s.h / 2 - mercY(c.lat) * ws;
    var cand = b.cand;
    var obj = {
      id: uid(), type: 'text',
      at: { lat: invMercY((b.cy - oy) / ws), lng: invMercX((b.cx - ox) / ws) },
      text: cand.name,
      size: b.size,
      style: { color: '#111' },
      /* 🔴 固有の source 印（§23-3）。所在図の作り直しは source==='shozaizu' しか
       * 消さないので、なぞり出した名称は再生成でも消えない。 */
      source: 'reveal', revKind: 'name', nameCat: cand.cat, nameSrc: cand.src
    };
    /* 🔒 §18-8: ●（anchor）を付けるのは「点に付く名前」だけ。
     * 🔴 道路名は線に付く名前なので●を付けない（点を打つと嘘になる）。 */
    if (b.dot) {
      obj.anchor = { lat: invMercY(cand.my), lng: invMercX(cand.mx) };
      /* 🔒 2026-09-02: 印の種類を**データに焼く**（editor.js / export.js が
       * dotStyle で分岐する・§25-4 の 'double'/'none' と同じ仕組み）。
       * 🔴 既に●で実体化済みの旧データは dotStyle を持たない＝そのまま●で
       *    描き続ける（後方互換・変換はしない）。 */
      if (b.mark && b.mark !== 'dot') obj.dotStyle = b.mark;
    }
    /* 🔴 §26-2 注意①: this.objects への**代入はしない**。
     * 文字は一番上に出したいので push（線の unshift と逆・§23-7-1 の並び）。 */
    this.editor.objects.push(obj);
    /* 🔒 §22-am-3 ＋ §22-am-6: 点に付く名前（●を持つ物）は、実体化したその場で
     * **生成と同じ配置関数**に通して「主役・結線から離れた空き地」へ出す。
     * 道路名（b.dot なし）はその場のまま。 */
    if (obj.anchor) this._placeName(obj);
    this._strokeNames.push({ obj: obj });
    st.madeNames++;
    if (cand.src === 'osm') st.usedOsm = true; else st.usedGsi = true;
  };

  /**
   * 🔒 §22-am-3 ＋ §22-am-6-1: 実体化した1件だけを shozaizu.js の配置関数
   * （生成とまったく同じ物）に通す。既にある文字は**動かさない**
   * ―― その名前だけを空いている所へ挿す（開いただけ・足しただけで図が動かない原則）。
   * 既にある文字と引き出し線は「障害物」として数えられる（placeLabels の only 経路）。
   */
  Reveal.prototype._placeName = function (obj) {
    var SZ = global.Shozaizu;
    if (!SZ || !SZ.placeNames) return;
    var fb = this._frameBounds();
    if (!fb) return;
    /* 主役の2地点は**役割ラベルから読む**（app の state を覗かない）。
     * 表示文字ではなく role / pinKey で見分ける（§26-2 注意②）。 */
    var objs = this.editor.objects, home = null, lot = null, i;
    for (i = 0; i < objs.length; i++) {
      var o = objs[i];
      if (!o || o.type !== 'text' || o.role !== 'pinlabel' || !o.anchor) continue;
      if (o.pinKey === 'home') home = o.anchor;
      else if (o.pinKey === 'lot') lot = o.anchor;
    }
    /* spanM は shozaizu.js が「文字1行の高さ」を出すのに使う物差し。
     * 候補の距離・回廊・立入禁止域は枠の幅から出る（生成と同じ物差しになる）ので
     * ここは枠の幅でよい。 */
    var spanM = GSI.distanceMeters(
      { lat: (fb.north + fb.south) / 2, lng: fb.west },
      { lat: (fb.north + fb.south) / 2, lng: fb.east });
    /* 🔒 §28-3: 部品として置かれた方位記号は名前が避ける障害物（生成と同じ扱い） */
    var comps = [];
    for (i = 0; i < objs.length; i++) {
      if (objs[i] && objs[i].type === 'compass' && objs[i].at) {
        comps.push({ lat: objs[i].at.lat, lng: objs[i].at.lng });
      }
    }
    try {
      SZ.placeNames(objs, spanM, home, lot, fb, { only: [obj], compasses: comps });
    } catch (e) { /* 配置に失敗しても実体化そのものは残す（fail-soft） */ }
  };

  /**
   * いま書き出される紙の枠（緯度経度）。
   * 🔴 app.js が枠を画面に描いている `.frame-rect`（決定済みでも未決定でも常に同期）を
   *    読んで逆投影する。枠が読めない時だけ画面全体に落ちる。
   */
  Reveal.prototype._frameBounds = function () {
    if (this.frameBounds) return this.frameBounds;
    var ov = this.map.overlay;
    var r = ov && ov.querySelector ? ov.querySelector('.frame-rect') : null;
    if (r && r.style.display !== 'none') {
      var x = parseFloat(r.getAttribute('x')), y = parseFloat(r.getAttribute('y'));
      var w = parseFloat(r.getAttribute('width')), h = parseFloat(r.getAttribute('height'));
      if (isFinite(x) && isFinite(y) && w > 0 && h > 0) {
        var a = this.map.unproject(x, y), b = this.map.unproject(x + w, y + h);
        return { north: Math.max(a.lat, b.lat), south: Math.min(a.lat, b.lat),
                 west: Math.min(a.lng, b.lng), east: Math.max(a.lng, b.lng) };
      }
    }
    return this.map.getBounds();
  };

  /* ================= なぞる ================= */

  Reveal.prototype._tolMerc = function () {
    var lat = this.map.getCenter().lat;
    return OVERLAP_M / (EQUATOR_M * Math.cos(lat * Math.PI / 180));
  };

  /** 画面px → 正規化メルカトル */
  Reveal.prototype._toMerc = function (px, py) {
    var s = this.map.size(), ws = this.map.worldSize();
    var c = this.map.getCenter();
    return { x: mercX(c.lng) + (px - s.w / 2) / ws,
             y: mercY(c.lat) + (py - s.h / 2) / ws };
  };

  /** その線のこのシートぶんの区間帳簿 */
  Reveal.prototype._ledger = function (line) {
    if (!line.rev) line.rev = Object.create(null);
    var a = line.rev[this.sheetKey];
    if (!a) {
      a = line.rev[this.sheetKey] = [];
      if (!line._listed) { line._listed = true; this._ledgerLines.push(line); }
    }
    return a;
  };

  /**
   * 🔴 帳簿は「セッション内の高速化用」でしかない（§23-3）。
   * 消しゴムで消された実体化物ぶんの区間は捨てないと、消した所を二度と
   * なぞり出せなくなる。なぞり始めに一度だけ掃除する。
   */
  Reveal.prototype._pruneLedger = function () {
    var alive = Object.create(null), objs = this.editor.objects, i;
    for (i = 0; i < objs.length; i++) if (objs[i] && objs[i].id) alive[objs[i].id] = 1;
    var key = this.sheetKey;
    for (i = 0; i < this._ledgerLines.length; i++) {
      var rev = this._ledgerLines[i].rev;
      var a = rev && rev[key];
      if (!a || !a.length) continue;
      var keep = [];
      for (var j = 0; j < a.length; j++) if (alive[a[j].id]) keep.push(a[j]);
      rev[key] = keep;
    }
  };

  /** 既存の実体化物（線・折れ線・多角形）から重なり判定の格子を作る */
  Reveal.prototype._buildGrid = function () {
    var tol = this._tolMerc();
    var g = new Grid(tol);
    var step = tol / SAMPLE_DIV;
    var b = this.map.getBounds();
    var vx0 = mercX(b.west), vx1 = mercX(b.east);
    var vy0 = mercY(b.north), vy1 = mercY(b.south);
    var m = (vx1 - vx0) * 0.25 + tol * 4;
    vx0 -= m; vx1 += m; vy0 -= m; vy1 += m;

    var objs = this.editor.objects, i;
    for (i = 0; i < objs.length; i++) {
      var o = objs[i];
      if (!o) continue;
      var pts = null;
      if (o.type === 'path' || o.type === 'polygon') pts = o.points;
      else if (o.type === 'line' && o.a && o.b) pts = [o.a, o.b];
      if (!pts || pts.length < 2) continue;
      // 画面から遠い物は入れない（所在図の広域生成物で格子が膨らむのを防ぐ）
      var x = mercX(pts[0].lng), y = mercY(pts[0].lat);
      var far = true;
      for (var j = 0; j < pts.length; j++) {
        x = mercX(pts[j].lng); y = mercY(pts[j].lat);
        if (x >= vx0 && x <= vx1 && y >= vy0 && y <= vy1) { far = false; break; }
      }
      if (far) continue;
      g.addLatLngs(pts, step);
      if (o.type === 'polygon' && pts.length > 2) {
        g.addLatLngs([pts[pts.length - 1], pts[0]], step);
      }
    }
    return g;
  };

  Reveal.prototype.strokeStart = function (px, py) {
    if (!this.active) return;
    this._pruneLedger();
    this._stroke = {
      id: 's' + (++this._seq),
      grid: this._buildGrid(),
      tol: this._tolMerc(),
      last: { x: px, y: py },
      lines: this._visibleLines(this._need()),
      snapped: false,
      made: 0,
      /* 名称は線とは別勘定（§23-5 は「1個まるごと」で区間帳簿を使わない） */
      madeNames: 0, usedOsm: false, usedGsi: false
    };
    this._strokeObjs = [];
    this._strokeNames = [];
    this._cursor = { x: px, y: py };
    this._paint(px, py);
    this.invalidate();
  };

  Reveal.prototype.strokeMove = function (px, py) {
    var st = this._stroke;
    if (!st) return;
    this._cursor = { x: px, y: py };
    var r = BRUSH_R[this.size];
    var dx = px - st.last.x, dy = py - st.last.y;
    var d = Math.sqrt(dx * dx + dy * dy);
    var steps = Math.max(1, Math.ceil(d / (r * 0.5)));
    for (var i = 1; i <= steps; i++) {
      this._paint(st.last.x + dx * i / steps, st.last.y + dy * i / steps);
    }
    st.last = { x: px, y: py };
    this.invalidate();
  };

  Reveal.prototype.strokeEnd = function () {
    var st = this._stroke;
    this._stroke = null;
    this._strokeObjs = [];
    this._strokeNames = [];
    if (!st) return 0;
    if (st.made || st.madeNames) {
      // SVG の組み直しと自動保存はここで1回だけ（なぞっている間は canvas 描画）
      this.editor.commit();
      /* 出典（§24-3・シート単位）を足すのに「どのデータ源を使ったか」が要る。
       * 🔴 OSM を使ったら ODbL の「© OpenStreetMap contributors」が要る（§23-6）。 */
      if (this.onReveal) {
        this.onReveal(st.made, { names: st.madeNames,
                                 osm: st.usedOsm, gsi: st.usedGsi });
      }
    }
    this.invalidate();
    return st.made + st.madeNames;
  };

  /* ---------- 1点ぶんのブラシ ---------- */

  Reveal.prototype._paint = function (px, py) {
    var st = this._stroke;
    if (!st) return;
    /* 🔒 §23-5: 名称は線とは別扱い。円に触れたら**1個まるごと**実体化する */
    this._paintNames(px, py, BRUSH_R[this.size]);
    var ws = this.map.worldSize();
    var r = BRUSH_R[this.size] / ws;             // メルカトル単位の半径
    var c = this._toMerc(px, py);
    var groups = st.lines, gi, i, j;

    for (gi = 0; gi < groups.length; gi++) {
      var arr = groups[gi];
      for (i = 0; i < arr.length; i++) {
        var line = arr[i];
        if (line.bx1 < c.x - r || line.bx0 > c.x + r
            || line.by1 < c.y - r || line.by0 > c.y + r) continue;
        var lo = Infinity, hi = -Infinity;
        for (j = 1; j < line.n; j++) {
          var ax = line.p[(j - 1) * 2], ay = line.p[(j - 1) * 2 + 1];
          var bx = line.p[j * 2], by = line.p[j * 2 + 1];
          var t = circleSeg(ax, ay, bx, by, c.x, c.y, r);
          if (!t) continue;
          var s0 = line.cum[j - 1], seg = line.cum[j] - s0;
          var g0 = (s0 + t[0] * seg) / line.len;
          var g1 = (s0 + t[1] * seg) / line.len;
          if (g0 < lo) lo = g0;
          if (g1 > hi) hi = g1;
        }
        if (hi > lo) this._reveal(line, lo, hi);
      }
    }
  };

  /**
   * 線の弧長区間 [t0,t1] を実体化する。
   *  ①帳簿（既に浮き出ている区間）を引く … 同じ場所を何度なぞっても増えない
   *  ②残りを「既存の実体化物との重なり判定」にかける … ズーム跨ぎの二重を防ぐ
   *  ③このなぞりで作った隣り合う切れ端は**1本に伸ばす**（線が細切れにならない）
   */
  Reveal.prototype._reveal = function (line, t0, t1) {
    var st = this._stroke;
    var led = this._ledger(line);
    var parts = subtract(t0, t1, led), k;
    if (!parts.length) return;
    for (k = 0; k < parts.length; k++) {
      this._materialize(line, parts[k][0], parts[k][1], led, st);
    }
  };

  Reveal.prototype._materialize = function (line, t0, t1, led, st) {
    var ws = this.map.worldSize();
    var minLen = MIN_KEEP_PX / ws;                       // メルカトル単位
    if ((t1 - t0) * line.len < minLen * 0.5) return;

    var sub = subChunk(line, t0, t1);
    if (!sub) return;

    /* 🔴 §23-3 ズーム跨ぎの二重実体化を止める。
     * 同じ建物が z15 と z16 の両タイルに簡略度の違う形で入っているので、
     * 弧長の帳簿（線の同一性が前提）だけでは防げない。既に線がある所は
     * なぞっても何も起きない＝それが正しい挙動。 */
    var keep = uncovered(sub, st.grid, st.tol, this._tolMerc() / SAMPLE_DIV, minLen);
    for (var i = 0; i < keep.length; i++) {
      var u0 = keep[i][0], u1 = keep[i][1];
      var piece = subChunk(sub, u0, u1);
      if (!piece || piece.len < minLen) continue;
      var a = t0 + (t1 - t0) * u0, b = t0 + (t1 - t0) * u1;

      // このなぞりで作った隣接する切れ端があれば伸ばす（細切れ防止）
      var host = null;
      for (var j = 0; j < led.length; j++) {
        var e = led[j];
        if (e.stroke !== st.id) continue;
        if (e.t1 >= a - 1e-9 && e.t0 <= b + 1e-9) { host = e; break; }
      }
      if (host) {
        host.t0 = Math.min(host.t0, a);
        host.t1 = Math.max(host.t1, b);
        var whole = subChunk(line, host.t0, host.t1);
        if (whole) host.obj.points = chunkToLatLng(whole);
        st.grid.addLatLngs(chunkToLatLng(piece), this._tolMerc() / SAMPLE_DIV);
        continue;
      }

      if (!st.snapped) { this.editor.snapshot(); st.snapped = true; }
      var pts = chunkToLatLng(piece);
      var style = outStyle(line.kind);
      var obj = {
        id: uid(), type: 'path', points: pts, closed: false,
        style: { w: style.w, color: style.color },
        /* 🔴 固有の source 印（§23-3）。所在図の再生成は source==='shozaizu' しか
         * 消さないので、なぞり出した物は作り直しでも消えない。 */
        source: 'reveal', revKind: line.kind
      };
      if (style.rail) obj.style.rail = true;
      // 🔒 §22-at 規則6: 道路は widthM を持つ(casing を立てないので見た目は変わらない＝
      // なぞり出しの道路は白帯にしない §23-9-a・OUT_STYLE.road の方針のまま)
      if (line.widthM) obj.widthM = line.widthM;
      // 🔒 §22-at-2: 同じ理由で floorU も運ぶ(casing 無しなので見た目には影響しない)
      if (line.floorU) obj.floorU = line.floorU;
      /* 🔴 §26-2 注意①: this.objects への**代入はしない**。
       * unshift は同じ配列オブジェクトのままなので参照共有は切れない。
       * 先頭＝下に敷く（文字や主役マークの下に入る）。 */
      this.editor.objects.unshift(obj);
      this._strokeObjs.push(obj);
      st.made++;
      led.push({ t0: a, t1: b, id: obj.id, obj: obj, stroke: st.id });
      st.grid.addLatLngs(pts, this._tolMerc() / SAMPLE_DIV);
    }
  };

  /* ---------- 区間の計算 ---------- */

  /** [t0,t1] から既存区間の和集合を引いた残りを返す */
  function subtract(t0, t1, entries) {
    var cuts = [];
    for (var i = 0; i < entries.length; i++) {
      var e = entries[i];
      if (e.t1 <= t0 || e.t0 >= t1) continue;
      cuts.push([Math.max(t0, e.t0), Math.min(t1, e.t1)]);
    }
    if (!cuts.length) return [[t0, t1]];
    cuts.sort(function (a, b) { return a[0] - b[0]; });
    var out = [], cur = t0;
    for (i = 0; i < cuts.length; i++) {
      if (cuts[i][0] > cur + 1e-12) out.push([cur, cuts[i][0]]);
      if (cuts[i][1] > cur) cur = cuts[i][1];
    }
    if (t1 > cur + 1e-12) out.push([cur, t1]);
    return out;
  }

  /**
   * 既存線に覆われていない区間（自身の弧長 0〜1）を返す。
   * 刻みごとに「その点の近くに既存線があるか」を見て、覆われていない連なりを拾う。
   */
  function uncovered(chunk, grid, tol, step, minLen) {
    if (!grid || !grid.count) return [[0, 1]];
    var n = Math.max(2, Math.ceil(chunk.len / step) + 1);
    var flags = new Uint8Array(n), i;
    for (i = 0; i < n; i++) {
      var t = i / (n - 1);
      var q = pointAt(chunk, t);
      flags[i] = grid.near(q[0], q[1], tol) ? 1 : 0;
    }
    var out = [], from = -1;
    for (i = 0; i < n; i++) {
      if (!flags[i]) { if (from < 0) from = i; }
      else if (from >= 0) { pushRun(out, from, i - 1, n); from = -1; }
    }
    if (from >= 0) pushRun(out, from, n - 1, n);
    // 短すぎる切れ端は作らない
    var keep = [];
    for (i = 0; i < out.length; i++) {
      if ((out[i][1] - out[i][0]) * chunk.len >= minLen) keep.push(out[i]);
    }
    return keep;
  }
  function pushRun(out, a, b, n) {
    if (b <= a) return;
    out.push([a / (n - 1), b / (n - 1)]);
  }

  function pointAt(c, t) {
    var L = t * c.len, i;
    for (i = 1; i < c.n; i++) {
      if (c.cum[i] >= L || i === c.n - 1) {
        var s0 = c.cum[i - 1], seg = c.cum[i] - s0;
        var u = seg > 0 ? Math.max(0, Math.min(1, (L - s0) / seg)) : 0;
        var ax = c.p[(i - 1) * 2], ay = c.p[(i - 1) * 2 + 1];
        var bx = c.p[i * 2], by = c.p[i * 2 + 1];
        return [ax + (bx - ax) * u, ay + (by - ay) * u];
      }
    }
    return [c.p[0], c.p[1]];
  }

  /* 定数を外から読めるようにしておく（実装メモ・オーナー目視の調整用） */
  Reveal.FOG = FOG;
  Reveal.BRUSH_R = BRUSH_R;
  Reveal.OVERLAP_M = OVERLAP_M;
  Reveal.MIN_KEEP_PX = MIN_KEEP_PX;
  Reveal.NAME_PX = NAME_PX;
  /* 🔒 §30-25-7: 文字の大きさ（紙基準・ズーム連動）の換算はこの1か所。
   * namelay.js（重ね表示）も同じ物を読む＝薄出し・重ね表示・図の文字がそろう。 */
  Reveal.namePxOf = namePxOf;
  Reveal.NAME_DOT_R = NAME_DOT_R;
  Reveal.FOG_NAME = FOG_NAME;
  Reveal.OSM_DEBOUNCE_MS = OSM_DEBOUNCE_MS;
  /* 🔒 §28-13（Step 4）: 印を canvas に描く関数。ガイダンス④の
   * ［交差点名・バス停名を地図に重ねる］（js/namelay.js）が**この1か所**を呼ぶ。
   * 🔴 形の出どころは Editor.signalGeom / Editor.busStopGeom のまま（上の
   *    signalGeom/busGeom がそれを読んでいる）＝薄出し・重ね表示・画面・紙の
   *    4か所が必ず同じ形になる。namelay 側で描き方を書き写さないこと。 */
  Reveal.drawSignal = drawSignal;
  Reveal.drawBusStop = drawBusStop;
  Reveal.markHalfH = markHalfH;

  global.Reveal = Reveal;
})(typeof window !== 'undefined' ? window : this);
