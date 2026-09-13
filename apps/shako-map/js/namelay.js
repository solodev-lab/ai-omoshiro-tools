/* namelay.js — 交差点名・バス停名を地図に「重ねて見せる」層（正典 §28-13 決定3）
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * オーナーの指摘（§28-13）:「OSM に交差点名が出ていない（案内文と違う）」。
 * 事実は §28-13 のとおりで、**交差点名はどの OSM ラスタスタイルにも描かれない**。
 * 交差点名を持っているのは所在図生成が使っている Overpass の**データ**の方なので、
 * ここでそのデータを取って地図の上に薄く重ねる。
 *
 * 🔴 この層が守る一線（§28-13 決定3）:
 *   1. **図形（objects）にしない**。editor.objects には1個も足さない
 *      （足すのは §23 のなぞり出しだけ。あちらは筆でなぞって「実体化」する道具）
 *   2. **紙に出ない**。書き出しは editor.objects しか見ないので構造的に混ざらない
 *   3. **案件に保存しない**。画面の状態＝案件を開き直したら OFF（app.js openCaseInner）
 *
 * 🔴 印の形は自前で持たない。Reveal.drawSignal / Reveal.drawBusStop を呼ぶ
 *    （その先は Editor.signalGeom / Editor.busStopGeom・§22-aj-2／§22-al-3）。
 *    ＝薄出し・この重ね表示・画面・紙の4か所が必ず同じ形になる。
 *
 * 🔴 Overpass は控えめに叩く（§23-6）。地図を動かしたら 500ms のデバウンスで
 *    1回だけ。範囲が前と同じなら OSM 側のキャッシュが同期で返す（通信0件）。
 *    失敗（429/504・ミラー不達）は**黙って何も描かない**（fail-soft）。
 */
(function (global) {
  'use strict';

  /* ================= 仮値（🙋 オーナー実機目視で確定する） ================= */

  var DEBOUNCE_MS = 500;        // 地図を動かし終えてから取りに行くまで（§28-13 決定3）
  var SOON_MS = 120;            // ON にした直後・案件を開いた直後
  var LATE_MS = 150;            // これより早く返ったら「取得中…」を出さない（点滅よけ）

  /* 🔒 §28-13 決定3: 取る分類は交差点名とバス停名の2つだけ。
   * 🔴 表示文字列ではなく分類 id で持つ（§26-2 注意②）。 */
  var CATS = { crossing: true, bus: true };

  /* 「下敷きの一部」に見える濃さ（🔴 なぞり出しの薄出しより淡い＝別物だと分かる）。
   * なぞり出しは「これから実体化できる候補」、こちらは「見るだけ」なので、
   * 触れそうな見た目にしない。 */
  var TEXT_COLOR = 'rgba(64,70,82,0.72)';
  var HALO_COLOR = 'rgba(255,255,255,0.88)';
  var MARK_COLOR = 'rgba(64,70,82,0.60)';

  var GAP = 4;                  // 印と文字の間(px)。reveal の NAME_GAP と同値
  var PAD = 3;                  // 重なり判定の余白(px)
  var MARGIN = 40;              // 画面のこの外側までは描かない(px)
  var SLOTS = [0, -1, 1, -2, 2];   // 重なった時に縦へ逃がす段（reveal と同じ作法）

  var FALLBACK_PX = { small: 12, medium: 15, large: 19 };

  /* 🔴 同じ名前が固まって返る（実測 2026-09-07・名駅 ZL17: 91件）。
   * OSM は交差点の**角ごと**に traffic_signals の点を持ち、バス停も**のりばごと**に
   * 点を持つので、素直に描くと「中央郵便局北」が3つ・「名古屋駅」が5つ並ぶ。
   * → 同じ分類・同じ名前で、この距離の中にある点は**1つにまとめて重心へ置く**
   *   （交差点なら交差点の真ん中、バス停なら両方向ののりばの間に来る）。
   * 🙋 仮値 150m（実機目視で確定）。離れた同名（別の「名古屋駅」バス停）は
   *    まとまらないので消えない。 */
  var CLUSTER_M = 150;

  function distM(aLat, aLng, bLat, bLng) {
    var mLat = 110574, mLng = 111320 * Math.cos((aLat + bLat) / 2 * Math.PI / 180);
    var dy = (aLat - bLat) * mLat, dx = (aLng - bLng) * mLng;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /** 同じ分類・同じ名前・近い点を1つにまとめる（重心へ置く） */
  function cluster(items) {
    var out = [], i, j;
    for (i = 0; i < items.length; i++) {
      var it = items[i];
      if (!it || !it.name) continue;
      var hit = null;
      for (j = 0; j < out.length; j++) {
        var g = out[j];
        if (g.cat !== it.cat || g.name !== it.name) continue;
        if (distM(g.lat, g.lng, it.lat, it.lng) > CLUSTER_M) continue;
        hit = g; break;
      }
      if (hit) {
        hit.n++; hit.sLat += it.lat; hit.sLng += it.lng;
        hit.lat = hit.sLat / hit.n; hit.lng = hit.sLng / hit.n;
      } else {
        out.push({ cat: it.cat, name: it.name, lat: it.lat, lng: it.lng,
                   sLat: it.lat, sLng: it.lng, n: 1 });
      }
    }
    return out;
  }

  function namePx(size) {
    var T = (global.Reveal && Reveal.NAME_PX) || FALLBACK_PX;
    return T[size] || T.medium || 15;
  }
  function markHalfH(mark, fs) {
    if (global.Reveal && Reveal.markHalfH) return Reveal.markHalfH(mark, fs);
    return 3.6;
  }
  function boxHit(a, b) {
    return !(a.x + a.w < b.x || b.x + b.w < a.x
          || a.y + a.h < b.y || b.y + b.h < a.y);
  }
  function anyHit(list, t) {
    for (var i = 0; i < list.length; i++) if (boxHit(list[i], t)) return true;
    return false;
  }

  /* ================= 本体 ================= */

  /**
   * @param map    MapView
   * @param editor Editor（🔴 読むだけ。**書かない**＝この層は図形を作らない）
   */
  function NameLay(map, editor) {
    this.map = map;
    this.editor = editor || null;
    this.on = false;            // 利用者が④の切替を入れたか
    this.suppressed = false;    // なぞり出し中は出さない（曇り下書きと二重に見えるため）
    this.onStatus = null;       // function({state, shown}) … 画面の一言

    this._items = [];           // 直近に取れた {cat,name,lat,lng}
    this._state = 'idle';       // idle | loading | ready | error | wide
    this._shown = 0;
    this._timer = 0;
    this._seq = 0;
    this._raf = 0;

    /* 曇り下書き（reveal-fog）と同じ場所＝**下敷きと SVG の間**。
     * 🔴 pointer-events:none。この層は掴めない・触れない（見るだけ）。 */
    var cv = document.createElement('canvas');
    cv.className = 'namelay';
    cv.hidden = true;
    map.el.insertBefore(cv, map.overlay);
    this.canvas = cv;
    this.ctx = cv.getContext('2d');

    var self = this;
    map.on('change', function () {
      if (!self._live()) return;
      self.invalidate();
      self._schedule();          // 範囲が変わったら取り直す（デバウンス）
    });
  }

  /** いま描く／取りに行く状態か */
  NameLay.prototype._live = function () {
    return this.on && !this.suppressed;
  };

  /** ④の切替（利用者の ON/OFF）。🔴 案件には保存しない */
  NameLay.prototype.setOn = function (on) {
    on = !!on;
    if (this.on === on) return;
    this.on = on;
    if (!on) {
      this._items = [];
      this._state = 'idle';
      this._shown = 0;
      this._seq++;               // 走っている取得の結果を捨てる
    }
    this._sync();
    if (on) this._schedule(true);
    this._emit();
  };

  /** なぞり出しの道具を持っている間は出さない（曇り下書きが同じ名前を出すため） */
  NameLay.prototype.setSuppressed = function (v) {
    v = !!v;
    if (this.suppressed === v) return;
    this.suppressed = v;
    this._sync();
    if (this._live()) this._schedule(true);
  };

  NameLay.prototype._sync = function () {
    var live = this._live();
    this.canvas.hidden = !live;
    if (live) this.invalidate();
    else if (this._timer) { clearTimeout(this._timer); this._timer = 0; }
  };

  NameLay.prototype._emit = function () {
    if (this.onStatus) {
      this.onStatus({ on: this.on, state: this._state, shown: this._shown });
    }
  };

  NameLay.prototype.stats = function () {
    return { on: this.on, suppressed: this.suppressed, state: this._state,
             items: this._items.length, shown: this._shown };
  };

  /* ---------- 取得（§23-6 の作法をそのまま） ---------- */

  NameLay.prototype._schedule = function (soon) {
    if (this._timer) { clearTimeout(this._timer); this._timer = 0; }
    if (!this._live() || !global.OSM) return;
    var self = this;
    this._timer = setTimeout(function () {
      self._timer = 0;
      self._run();
    }, soon ? SOON_MS : DEBOUNCE_MS);
  };

  NameLay.prototype._run = function () {
    if (!this._live() || !global.OSM) return;
    var self = this, seq = ++this._seq;
    /* キャッシュに当たれば同期で戻るので「取得中…」を出さない
     * （地図を動かすたびに文言が点滅するのを避ける・reveal と同じ作法） */
    var late = setTimeout(function () {
      if (seq !== self._seq) return;
      self._state = 'loading';
      self._emit();
    }, LATE_MS);
    OSM.fetchNames(this.map.getBounds(), CATS).then(function (r) {
      clearTimeout(late);
      if (seq !== self._seq) return;
      self._state = 'ready';
      /* 🔴 まとめるのはここ（取得のたび1回）。draw は毎フレーム走るので置かない。 */
      self._items = cluster(r.items || []);
      self._emit();
      self.invalidate();
    }, function (e) {
      clearTimeout(late);
      if (seq !== self._seq) return;
      /* 🔴 §23-6 fail-soft: 落ちても作図は止めない。ここは**黙って何も描かない**
       * （§28-13 決定3「通信失敗（429/504）は黙って何も描かない」）。
       * 状態だけは持っておき、切替の横の一言で「今は出ません」と伝える。 */
      self._state = (e && e.kind === 'wide') ? 'wide'
                  : ((e && e.kind === 'none') ? 'idle' : 'error');
      self._items = [];
      self._shown = 0;
      self._emit();
      self.invalidate();
    });
  };

  /* ---------- 描画 ---------- */

  NameLay.prototype.invalidate = function () {
    if (this._raf) return;
    var self = this;
    this._raf = requestAnimationFrame(function () {
      self._raf = 0;
      self.draw();
    });
  };

  NameLay.prototype.draw = function () {
    if (!this._live()) return;
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

    /* 🔴 この紙に**既にある同じ文字は重ねない**（§23-6-a の名寄せと同じ作法）。
     * ③でまとめて描いた交差点名の上に薄い灰色が重なると、同じ名前が二重に見える
     * （実測 2026-09-07・名駅: 37件のうち7件が紙の文字と同名だった）。
     * 消せばまた出る＝「まだ図に無い名前」だけが薄く見える、が分かりやすい。 */
    var onPaper = Object.create(null), i;
    var objs = (this.editor && this.editor.objects) || [];
    for (i = 0; i < objs.length; i++) {
      if (objs[i] && objs[i].type === 'text' && objs[i].text) onPaper[objs[i].text] = true;
    }

    var items = this._items, placed = [], shown = 0, k;
    for (i = 0; i < items.length; i++) {
      var it = items[i];
      if (onPaper[it.name]) continue;
      var meta = (global.OSM && OSM.CAT_BY_ID[it.cat]) || {};
      var mark = meta.mark || 'dot';
      var p = map.project(it.lat, it.lng);
      if (p.x < -MARGIN || p.x > s.w + MARGIN
          || p.y < -MARGIN || p.y > s.h + MARGIN) continue;

      var fs = namePx(meta.size);
      ctx.font = '700 ' + fs + 'px "Yu Gothic UI","Meiryo",sans-serif';
      var w = ctx.measureText(it.name).width;
      var h = fs * 1.15;
      var mHalf = markHalfH(mark, fs);
      var baseCy = p.y - mHalf - GAP - h / 2;

      /* 印の実寸を置き場所から除く（🔴 ここに PAD を足さないこと。足すと
       * 1段目が必ず自分の印と当たり、常に2段目へ飛ぶ＝§22-aj-2 の罠）。 */
      var icon = null;
      if (mark === 'signal' && global.Editor && Editor.signalGeom) {
        var sg = Editor.signalGeom(fs);
        icon = { x: p.x - sg.w / 2, y: p.y - sg.h / 2, w: sg.w, h: sg.h };
      } else if (mark === 'bus' && global.Editor && Editor.busStopGeom) {
        var bg = Editor.busStopGeom(fs);
        var bw = Math.max(bg.bw, bg.foot);
        icon = { x: p.x - bw / 2, y: p.y - bg.h, w: bw, h: bg.h };
      }
      if (icon) placed.push(icon);

      var box = null;
      for (k = 0; k < SLOTS.length; k++) {
        var cy = baseCy + SLOTS[k] * (h + 2);
        var t = { x: p.x - w / 2 - PAD, y: cy - h / 2 - PAD,
                  w: w + PAD * 2, h: h + PAD * 2, cy: cy };
        if (!anyHit(placed, t)) { box = t; break; }
      }
      if (!box) {                       // 逃げ場なし＝出さない（重ねると読めない）
        if (icon) placed.pop();
        continue;
      }
      placed.push(box);

      // ---- 印（形の出どころは Editor.signalGeom / busStopGeom の1か所）----
      if (mark === 'signal' && global.Reveal && Reveal.drawSignal) {
        Reveal.drawSignal(ctx, p.x, p.y, fs, MARK_COLOR);
      } else if (mark === 'bus' && global.Reveal && Reveal.drawBusStop) {
        Reveal.drawBusStop(ctx, p.x, p.y, fs, MARK_COLOR);
      } else {
        // 印を持たない分類が来た時の保険（交差点＝signal・バス停＝bus なので通常は通らない）
        ctx.beginPath();
        ctx.arc(p.x, p.y, (global.Reveal && Reveal.NAME_DOT_R) || 3.6, 0, Math.PI * 2);
        ctx.fillStyle = MARK_COLOR;
        ctx.fill();
      }
      if (Math.abs(box.cy - baseCy) > 1) {      // 逃がした分は細い線でつなぐ
        ctx.strokeStyle = MARK_COLOR;
        ctx.lineWidth = 0.8;
        ctx.beginPath();
        ctx.moveTo(p.x, p.y + (box.cy > p.y ? mHalf : -mHalf));
        ctx.lineTo(p.x, box.cy + (box.cy > p.y ? -h / 2 : h / 2));
        ctx.stroke();
      }

      // ---- 名前 ----
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.lineWidth = 3;
      ctx.lineJoin = 'round';
      ctx.strokeStyle = HALO_COLOR;
      ctx.strokeText(it.name, p.x, box.cy);
      ctx.fillStyle = TEXT_COLOR;
      ctx.fillText(it.name, p.x, box.cy);
      shown++;
    }
    ctx.textAlign = 'start';
    ctx.textBaseline = 'alphabetic';
    if (this._shown !== shown) { this._shown = shown; this._emit(); }
  };

  NameLay.CATS = CATS;
  NameLay.DEBOUNCE_MS = DEBOUNCE_MS;
  global.NameLay = NameLay;
})(typeof window !== 'undefined' ? window : this);
