/* mapview.js — 地図ビューと「差し替え可能な下敷き」（正典 §1-5 / §2）
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * 設計の要点:
 *   カメラ（中心・ズーム・マウス操作）は MapView が一手に持つ。
 *   下敷き(underlay)は「この範囲をこの倍率で描け」と言われて描くだけの部品にする。
 *   こうしておくと下敷きが何であっても描画レイヤー側の座標計算は一切変わらない。
 *   実際に §17（2026-08-18）で Google の下敷きを撤去した時も、
 *   §17-b（2026-08-19）で 2種だけ復活させた時も、
 *   描画・当たり判定・書き出しには手を入れずに済んだ（正典 §1-5）。
 *
 *   全オブジェクトは緯度経度にアンカーし、表示のたびに project() で画面座標へ
 *   落とす。パン・ズームでズレないのはこのため（正典 §1-2）。
 */
(function (global) {
  'use strict';

  var TILE = 256;
  var underlayFactories = {};

  /* ================= 投影（Webメルカトル） ================= */

  function lngToWorldX(lng, worldSize) {
    return (lng + 180) / 360 * worldSize;
  }
  function latToWorldY(lat, worldSize) {
    var s = Math.sin(lat * Math.PI / 180);
    s = Math.max(-0.9999, Math.min(0.9999, s));
    return (0.5 - Math.log((1 + s) / (1 - s)) / (4 * Math.PI)) * worldSize;
  }
  function worldXToLng(x, worldSize) {
    return x / worldSize * 360 - 180;
  }
  function worldYToLat(y, worldSize) {
    var n = Math.PI * (1 - 2 * y / worldSize);
    return Math.atan(Math.sinh(n)) * 180 / Math.PI;
  }

  /* ================= ズームの刻み ================= */

  /**
   * 使えるズーム値の一覧（はしご）。**細かさは2段**（🔒 §30-14-2）:
   *   ・fineFrom 未満        … 1 刻み
   *   ・fineFrom 〜 fineFrom2 … fineStep 刻み（既定 0.5）
   *   ・fineFrom2 以上        … fineStep2 刻み（既定 0.25）
   * fineFrom2 を省く（undefined）と従来どおり1段だけ（fineStep がそのまま上まで）。
   */
  function buildLadder(min, max, fineFrom, fineStep, fineFrom2, fineStep2) {
    var out = [], z;
    var hi = (fineFrom2 === undefined || fineFrom2 === null) ? Infinity : fineFrom2;
    for (z = Math.ceil(min); z < fineFrom && z <= max; z++) out.push(z);
    for (z = Math.max(min, fineFrom); z < hi - 1e-9 && z <= max + 1e-9; z += fineStep) {
      out.push(Math.round(z * 1000) / 1000);   // 浮動小数の誤差を溜めない
    }
    if (hi !== Infinity) {
      for (z = Math.max(min, hi); z <= max + 1e-9; z += fineStep2) {
        out.push(Math.round(z * 1000) / 1000);
      }
    }
    return out.filter(function (v) { return v >= min - 1e-9 && v <= max + 1e-9; });
  }

  /* ================= MapView ================= */

  function MapView(container, opts) {
    opts = opts || {};
    this.el = container;
    this.el.classList.add('mv-root');
    this.center = opts.center || { lat: 35.681236, lng: 139.767125 };
    this.zoom = opts.zoom === undefined ? 16 : opts.zoom;
    this.minZoom = opts.minZoom === undefined ? 5 : opts.minZoom;
    this.maxZoom = opts.maxZoom === undefined ? 20 : opts.maxZoom;
    /* 0.5 刻みで細かく合わせられる下限。
     * 🔒 2026-09-02 オーナー指示: 既定を 20 → **14** に下げた（ZL14 以上は全部 0.5 刻み）。
     *    所在図の広域側（ZL14〜17）でも「1段で2倍飛ぶ」のを避けて紙に合わせられる。
     * 下敷きの倍率差は underlay 側が拡大縮小で吸収するので小数でも破綻しない
     * （tz = ceil(zoom) なので .5 は1段上のタイルを 0.707 倍に**縮めて**使う＝粗くならない）。 */
    this.fineFrom = opts.fineFrom === undefined ? 14 : opts.fineFrom;
    this.fineStep = opts.fineStep === undefined ? 0.5 : opts.fineStep;
    /* 🔒 §30-14-2（2026-09-10 オーナー指示）: **2段目の細かさ**。
     * ZL18 以上は 0.25 刻み（配置図の作図はほぼ ZL18〜20 なので、ここだけ
     * さらに細かく紙に合わせられるようにする）。下敷きは tz = ceil(zoom) で
     * 1段上のタイルを**縮めて**使うので .25／.75 でも粗くならない
     * （🔴 正典 §30-14-2 は「round」と書いているが、round だと .25 が下へ丸まって
     *   引き伸ばしになる。下の draw() の注記を参照）。 */
    this.fineFrom2 = opts.fineFrom2 === undefined ? 18 : opts.fineFrom2;
    this.fineStep2 = opts.fineStep2 === undefined ? 0.25 : opts.fineStep2;
    this._ladder = buildLadder(this.minZoom, this.maxZoom,
                               this.fineFrom, this.fineStep,
                               this.fineFrom2, this.fineStep2);
    this._listeners = { change: [], viewend: [] };

    this.underlayEl = document.createElement('div');
    this.underlayEl.className = 'mv-underlay';
    this.el.appendChild(this.underlayEl);

    this.overlay = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    this.overlay.setAttribute('class', 'mv-overlay');
    this.el.appendChild(this.overlay);

    this.underlay = null;
    this._opacity = 1;
    this._kind = 'roadmap';

    this._bindInput();
    this._ro = new ResizeObserver(this._onResize.bind(this));
    this._ro.observe(this.el);
    this._onResize();
  }

  MapView.registerUnderlay = function (name, factory) {
    underlayFactories[name] = factory;
  };
  MapView.hasUnderlay = function (name) { return !!underlayFactories[name]; };

  MapView.prototype.on = function (ev, fn) {
    (this._listeners[ev] || (this._listeners[ev] = [])).push(fn);
    return this;
  };
  MapView.prototype._emit = function (ev) {
    (this._listeners[ev] || []).forEach(function (f) { f(); });
  };

  MapView.prototype.size = function () {
    return { w: this.el.clientWidth, h: this.el.clientHeight };
  };
  MapView.prototype.worldSize = function () {
    return TILE * Math.pow(2, this.zoom);
  };

  /** 緯度経度 → コンテナ内ピクセル */
  MapView.prototype.project = function (lat, lng) {
    var ws = this.worldSize(), s = this.size();
    return {
      x: lngToWorldX(lng, ws) - lngToWorldX(this.center.lng, ws) + s.w / 2,
      y: latToWorldY(lat, ws) - latToWorldY(this.center.lat, ws) + s.h / 2
    };
  };

  /** コンテナ内ピクセル → 緯度経度 */
  MapView.prototype.unproject = function (x, y) {
    var ws = this.worldSize(), s = this.size();
    return {
      lat: worldYToLat(latToWorldY(this.center.lat, ws) + y - s.h / 2, ws),
      lng: worldXToLng(lngToWorldX(this.center.lng, ws) + x - s.w / 2, ws)
    };
  };

  /** 画面に写っている緯度経度の範囲 */
  MapView.prototype.getBounds = function () {
    var s = this.size();
    var nw = this.unproject(0, 0), se = this.unproject(s.w, s.h);
    return { west: nw.lng, north: nw.lat, east: se.lng, south: se.lat };
  };

  /** 画面1ピクセルあたりの実距離(m)。実寸ラベルや縮尺に使う（正典 §6） */
  MapView.prototype.metersPerPixel = function (lat) {
    lat = lat === undefined ? this.center.lat : lat;
    return 40075016.686 * Math.cos(lat * Math.PI / 180) / this.worldSize();
  };

  MapView.prototype.setView = function (center, zoom, silent) {
    if (center) this.center = { lat: center.lat, lng: center.lng };
    if (zoom !== undefined) this.zoom = this.snapZoom(zoom);
    this._render();
    if (!silent) { this._emit('change'); this._scheduleViewEnd(); }
  };
  MapView.prototype.getCenter = function () {
    return { lat: this.center.lat, lng: this.center.lng };
  };
  MapView.prototype.getZoom = function () { return this.zoom; };

  /** 一番近い「使えるズーム値」に丸める */
  MapView.prototype.snapZoom = function (z) {
    var L = this._ladder, best = L[0], bd = Infinity;
    for (var i = 0; i < L.length; i++) {
      var d = Math.abs(L[i] - z);
      if (d < bd) { bd = d; best = L[i]; }
    }
    return best;
  };

  /** 1段ぶんズームする。dir = +1 拡大 / -1 縮小 */
  MapView.prototype.stepZoom = function (dir) {
    var L = this._ladder, cur = this.snapZoom(this.zoom);
    var i = L.indexOf(cur);
    if (i < 0) i = 0;
    return L[Math.max(0, Math.min(L.length - 1, i + dir))];
  };
  MapView.prototype.zoomLadder = function () { return this._ladder.slice(); };

  /**
   * 2点が収まるように寄せる（余白 pad は割合）。
   * box={w,h} を渡すと**画面ではなくその大きさの窓**に収める（🔒 §18-n）。
   * 🔴 書き出されるのは画面そのものではなく、画面から記載欄の縦横比で切り出した
   *    **一回り狭い窓**。画面に合わせると横長の2点配置で枠から外れるので、
   *    所在図の自動調節は枠の大きさを渡して呼ぶこと。
   */
  MapView.prototype.fitPoints = function (points, pad, box) {
    var pts = points.filter(Boolean);
    if (!pts.length) return;
    pad = pad === undefined ? 0.35 : pad;
    var s = this.size();
    if (pts.length === 1) {
      this.setView(pts[0], this.zoom);
      return;
    }
    // 画面が未レイアウト(幅0)のまま呼ばれると、下の縮小ループが最小ズームまで
    // 落ちきってしまう。中心だけ合わせて保留し、サイズが付いてからやり直す。
    if (!s.w || !s.h) {
      var mid = {
        lat: (Math.min.apply(null, pts.map(function (p) { return p.lat; }))
            + Math.max.apply(null, pts.map(function (p) { return p.lat; }))) / 2,
        lng: (Math.min.apply(null, pts.map(function (p) { return p.lng; }))
            + Math.max.apply(null, pts.map(function (p) { return p.lng; }))) / 2
      };
      this.setView(mid, this.zoom);
      this._pendingFit = { points: pts, pad: pad, box: box };
      return;
    }
    if (box && box.w > 0 && box.h > 0) s = box;
    var minLat = Math.min.apply(null, pts.map(function (p) { return p.lat; }));
    var maxLat = Math.max.apply(null, pts.map(function (p) { return p.lat; }));
    var minLng = Math.min.apply(null, pts.map(function (p) { return p.lng; }));
    var maxLng = Math.max.apply(null, pts.map(function (p) { return p.lng; }));
    var center = { lat: (minLat + maxLat) / 2, lng: (minLng + maxLng) / 2 };
    var z = this.maxZoom;
    for (; z > this.minZoom; z--) {
      var ws = TILE * Math.pow(2, z);
      var w = Math.abs(lngToWorldX(maxLng, ws) - lngToWorldX(minLng, ws));
      var h = Math.abs(latToWorldY(minLat, ws) - latToWorldY(maxLat, ws));
      if (w <= s.w * (1 - pad) && h <= s.h * (1 - pad)) break;
    }
    this.setView(center, z);
  };

  /* ---------- 下敷き ---------- */

  MapView.prototype.setUnderlay = function (name, kind) {
    if (this.underlay && this.underlay.name === name) {
      if (kind) this.setUnderlayKind(kind);
      return;
    }
    if (this.underlay) {
      this.underlay.destroy();
      this.underlay = null;
    }
    this.underlayEl.innerHTML = '';
    var factory = underlayFactories[name];
    if (!factory) { this._emit('change'); return; }
    this.underlay = factory(this.underlayEl, this);
    this.underlay.name = name;
    this.underlay.setKind(kind || this._kind);
    this.underlay.setOpacity(this._opacity);
    this._render();
  };

  MapView.prototype.setUnderlayKind = function (kind) {
    this._kind = kind;
    if (this.underlay) this.underlay.setKind(kind);
    this._render();
  };
  MapView.prototype.getUnderlayKind = function () { return this._kind; };

  /** 透明度。0 で「下敷きOFF＝提出プレビュー」（正典 §3） */
  MapView.prototype.setUnderlayOpacity = function (o) {
    this._opacity = o;
    this.underlayEl.style.opacity = o;
    if (this.underlay) this.underlay.setOpacity(o);
  };
  MapView.prototype.getUnderlayOpacity = function () { return this._opacity; };

  MapView.prototype.attribution = function () {
    return this.underlay && this.underlay.attribution
      ? this.underlay.attribution() : '';
  };

  /** 🔒 §26-4-e: いま画面に出している下敷きタイルの成否（対応しない下敷きは null） */
  MapView.prototype.underlayCoverage = function () {
    return this.underlay && this.underlay.coverage
      ? this.underlay.coverage() : null;
  };

  /* ---------- 描画 ---------- */

  MapView.prototype._render = function () {
    var s = this.size();
    this.overlay.setAttribute('width', s.w);
    this.overlay.setAttribute('height', s.h);
    this.overlay.setAttribute('viewBox', '0 0 ' + s.w + ' ' + s.h);
    if (this.underlay) this.underlay.draw();
  };

  MapView.prototype._onResize = function () {
    // 幅0の時に保留した fitPoints をここで実行する
    if (this._pendingFit) {
      var s = this.size();
      if (s.w && s.h) {
        var p = this._pendingFit;
        this._pendingFit = null;
        this.fitPoints(p.points, p.pad, p.box);
        return;
      }
    }
    this._render();
    this._emit('change');
  };

  MapView.prototype._scheduleViewEnd = function () {
    var self = this;
    if (this._veTimer) clearTimeout(this._veTimer);
    this._veTimer = setTimeout(function () {
      self._veTimer = null;
      self._emit('viewend');
    }, 220);
  };

  /* ---------- 入力（パン・ズーム） ---------- */

  MapView.prototype._bindInput = function () {
    var self = this;
    var dragging = false, lastX = 0, lastY = 0, moved = 0;

    this.el.addEventListener('pointerdown', function (e) {
      // 描画ツールが掴んでいる時は地図を動かさない。
      // shouldPan は editor が差し込む判定（中ボタンは常にパン可）。
      if (e.button !== 1) {
        if (self.inputLocked) return;
        if (self.shouldPan && !self.shouldPan(e)) return;
      }
      if (e.button !== 0 && e.button !== 1) return;
      dragging = true; moved = 0;
      lastX = e.clientX; lastY = e.clientY;
      // 既に離された後のポインタだと例外になる環境がある（editor.js と同じ扱い）
      try { self.el.setPointerCapture(e.pointerId); } catch (err) {}
      self.el.classList.add('mv-dragging');
    });

    this.el.addEventListener('pointermove', function (e) {
      if (!dragging) return;
      var dx = e.clientX - lastX, dy = e.clientY - lastY;
      lastX = e.clientX; lastY = e.clientY;
      moved += Math.abs(dx) + Math.abs(dy);
      var ws = self.worldSize();
      var cx = lngToWorldX(self.center.lng, ws) - dx;
      var cy = latToWorldY(self.center.lat, ws) - dy;
      self.center = { lat: worldYToLat(cy, ws), lng: worldXToLng(cx, ws) };
      self._render();
      self._emit('change');
    });

    function endDrag(e) {
      if (!dragging) return;
      dragging = false;
      self.el.classList.remove('mv-dragging');
      try { self.el.releasePointerCapture(e.pointerId); } catch (err) {}
      self._scheduleViewEnd();
    }
    this.el.addEventListener('pointerup', endDrag);
    this.el.addEventListener('pointercancel', endDrag);

    this.el.addEventListener('wheel', function (e) {
      e.preventDefault();
      if (self.inputLocked) return;
      var rect = self.el.getBoundingClientRect();
      var px = e.clientX - rect.left, py = e.clientY - rect.top;
      // カーソル位置の緯度経度を固定したままズームする
      var before = self.unproject(px, py);
      var z = self.stepZoom(e.deltaY < 0 ? 1 : -1);
      if (z === self.zoom) return;
      self.zoom = z;
      var after = self.unproject(px, py);
      self.center = {
        lat: self.center.lat + (before.lat - after.lat),
        lng: self.center.lng + (before.lng - after.lng)
      };
      self._render();
      self._emit('change');
      self._scheduleViewEnd();
    }, { passive: false });

    /* 🔴 ダブルクリック（ダブルタップ）による地図の拡大は**全面的に廃止**した
     *    （🔒 オーナー指示 2026-08-30・修正3）。
     *    理由: 作図アプリでは暴発の害しかない。回転ボタンや枠の＋を速く連打すると
     *    2クリック目が dblclick になり、意図せず地図が拡大していた。
     *    「ボタンの上だけ無効」ではなく**地図全面で無効**にする。
     *    拡大縮小は ホイール／［＋］［−］ボタン（app.js の btnZoomIn/Out）で行う。
     * 🔴 ここに「地図を動かす」dblclick の listener を**足さない**こと。
     *    図形側のダブルクリック（多角形の確定・テキストの再編集）は editor.js が
     *    同じ el に別の listener を張って処理している。あちらは地図を動かさない
     *    ので消してはいけない（＝廃止したのは「拡大」だけ）。
     * 🔴 タッチのダブルタップ拡大はブラウザ既定だが、.mv-root は
     *    `touch-action: none`（style.css）なので元から起きない。 */
  };

  MapView.prototype.destroy = function () {
    if (this._ro) this._ro.disconnect();
    if (this.underlay) this.underlay.destroy();
  };

  /* ================= 下敷き: 国土地理院ラスタタイル =================
   * キー不要・無料・出典表記のみで使える。§17 以降はこれと PLATEAU が
   * アプリの下敷きの全て（Google は撤去）。
   * 制約: 航空写真(seamlessphoto)・オルソとも ZL18 まで。それ以上は
   *       タイルを引き伸ばして作図倍率を稼ぐ（§9-b）。
   */
  var GSI_SOURCES = {
    roadmap:   { url: 'https://cyberjapandata.gsi.go.jp/xyz/pale/{z}/{x}/{y}.png',
                 maxZoom: 18, attr: '出典：地理院タイル（淡色地図）' },
    roadmapStd:{ url: 'https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png',
                 maxZoom: 18, attr: '出典：地理院タイル（標準地図）' },
    satellite: { url: 'https://cyberjapandata.gsi.go.jp/xyz/seamlessphoto/{z}/{x}/{y}.jpg',
                 maxZoom: 18, attr: '出典：地理院タイル（全国最新写真）' },
    // 正射画像(オルソ) = 真上から見た形に幾何補正済み。建物が傾かないので
    // なぞる下敷きに向く。ライセンス上もトレース可（正典 §11-b の三分法）。
    ort:       { url: 'https://cyberjapandata.gsi.go.jp/xyz/ort/{z}/{x}/{y}.jpg',
                 maxZoom: 18, attr: '出典：地理院タイル（電子国土基本図オルソ画像）' },
    /* 🔒 §18-an: minZoom は実測値（2026-08-22・名古屋城で z8〜18 を1枚ずつ fetch。
     * z9 以下=404 / z10〜18=200）。下限未満は1枚も要求しない（draw() 冒頭のガード）。
     * 対象都市の外の 404 は配信側に索引が無い以上消せない＝仕様（§18-am）。 */
    plateau:   { url: 'https://api.plateauview.mlit.go.jp/tiles/plateau-ortho-2023/{z}/{x}/{y}.png',
                 minZoom: 10, maxZoom: 18, attr: '出典：国土交通省 PLATEAU オルソ画像' },
    /* 🔒 §28-5 B / §28-9（Step 3）: OSMFJ（tile.openstreetmap.jp）。国土地理院とは
     * 無関係の別法人（OpenStreetMap Foundation Japan）だが、生の XYZ ラスタタイルを
     * 取得して並べるだけの仕組みは共通なので、この汎用エンジンに相乗りする
     * （PLATEAU＝国交省も同じ理由でここに同居している）。
     * 🔴 実測（2026-09-07）: スタイル一覧 https://tile.openstreetmap.jp/ に
     *    "osm-bright" の識別子で掲載・200 で応答（image/png・CORS 許可）。
     *    ライセンスは OSM Wiki(Japan/OSMFJ_Tileserver) の記載どおり CC-BY
     *    （バージョン指定なし・表記は「© OpenStreetMap Contributors」）。
     *    大量利用の可否を定めた明文の規約ページは見つからなかった
     *    （運営告知には「ご自由にご利用ください」とあるのみ）ので、
     *    他の下敷きと同じ流儀（節度ある XYZ キャッシュ利用）に留める。
     * 🔴 ズーム上限: ベクタ元データ(planet.json)の maxzoom は 14 だが、
     *    サーバー側でオーバーズーム描画するため z21 まで実測で 200 が返る。
     *    地理院/PLATEAU（ここでは 18）に合わせて **19** に据え置いた
     *    （元データの精細さがそこで頭打ちのため、それ以上要求を増やす利がない）。 */
    /* 🔒 §28-12（Fable 裁定 2026-09-07）: スタイルは **osm-bright-ja**（日本語ラベル）。
     *    "osm-bright" は英語（ローマ字）表記で、交差点名・バス停・店名を日本語で
     *    読むという §28-5 B の用途に合わない。-ja も 200（image/png・実測 z16 89KB）。 */
    osmfj:     { url: 'https://tile.openstreetmap.jp/styles/osm-bright-ja/{z}/{x}/{y}.png',
                 maxZoom: 19,
                 attr: '出典：OpenStreetMap Japan（tile.openstreetmap.jp）\n'
                     + '© OpenStreetMap contributors（CC-BY）' }
  };

  /* 🔒 §28-13 決定5（実測 2026-09-07・Step 4）: オーナー指摘「OSM の表示が遅い」に
   * 対して**アプリ側でできる事**を点検した結果、直す所は無かった。記録として残す。
   *   (a) タイルは元から `<img>`（ブラウザの並列読み込みに任せている）
   *   (b) 下敷きを切り替えて戻した時・パンで戻った時に**取り直していない**。
   *       ここは img を作り直すが、同じ URL の画像はブラウザ自身の画像キャッシュから
   *       返るので**要求は0件**（実測: 他所を93枚読んだ後に戻っても新規要求0・全部
   *       そろうまで 32ms）。アプリ側にもう1段キャッシュを積む利は無い
   *   (c) 見えていないタイルの先読みはしていない（下の draw は画面の矩形しか回らない）
   * 残る遅さは配信側（OSMFJ は有志運営・CDN 無し）。§28-13 のとおり時間帯で変わる。 */
  MapView.registerUnderlay('gsi', function (host, map) {
    var pane = document.createElement('div');
    pane.className = 'mv-tilepane';
    host.appendChild(pane);
    var cache = {};        // key -> img
    var kind = 'roadmap';

    function src() { return GSI_SOURCES[kind] || GSI_SOURCES.roadmap; }

    return {
      setKind: function (k) {
        if (kind === k) return;
        kind = GSI_SOURCES[k] ? k : 'roadmap';
        pane.innerHTML = '';
        cache = {};
      },
      setOpacity: function (o) { pane.style.opacity = 1; host.style.opacity = o; },
      attribution: function () { return src().attr; },
      /* 🔒 §26-4-e: いま画面に出しているタイルの成否。
       * cache は画面外になった分を捨てるので、**いま見えている範囲**の答えになる。
       * 下限ズーム未満（PLATEAU の ZL10 未満）は1枚も要求しないので total=0。 */
      coverage: function () {
        var total = 0, miss = 0, ok = 0;
        Object.keys(cache).forEach(function (k) {
          var im = cache[k];
          total++;
          if (im.dataset.miss === '1') miss++;
          else if (im.complete && im.naturalWidth > 0) ok++;
        });
        return { kind: kind, total: total, miss: miss, ok: ok };
      },
      draw: function () {
        var s = map.size();
        if (!s.w || !s.h) return;
        var cfg = src();
        /* 地理院は ZL18 が上限。それ以上はタイルを引き伸ばして作図倍率を稼ぐ。
         * 🔒 §30-14-2: 端数のあるズームでは**1段上のタイルを縮めて**使う（＝粗くしない）。
         * 🔴 round では 18.25 が 18 に丸まってタイルを 1.19 倍に**引き伸ばして**しまう
         *    （0.5 刻みしか無かった頃は round == ceil だったので気付かなかった）。
         *    ceil にしても 0.5 刻み・整数の時の結果は従来とまったく同じ。 */
        var tz = Math.max(0, Math.min(cfg.maxZoom, Math.ceil(map.zoom - 1e-9)));
        /* 🔒 §18-an: 下限未満（PLATEAU の ZL10 未満）はタイルが存在しないので
         * 1枚も要求せず、出ているタイルも片付ける。見た目は従来（404→無地）と
         * 同じで、空振りの要求（1画面≒20枚）だけが消える。 */
        if (cfg.minZoom && tz < cfg.minZoom) {
          map.underlayOverzoom = 1;
          Object.keys(cache).forEach(function (k) {
            pane.removeChild(cache[k]); delete cache[k];
          });
          return;
        }
        var scale = Math.pow(2, map.zoom - tz);
        map.underlayOverzoom = scale > 1.001 ? scale : 1;
        var ws = TILE * Math.pow(2, tz);
        var cx = lngToWorldX(map.center.lng, ws);
        var cy = latToWorldY(map.center.lat, ws);
        var n = Math.pow(2, tz);

        // 画面に必要なタイル範囲
        var halfW = s.w / 2 / scale, halfH = s.h / 2 / scale;
        var x0 = Math.floor((cx - halfW) / TILE), x1 = Math.floor((cx + halfW) / TILE);
        var y0 = Math.floor((cy - halfH) / TILE), y1 = Math.floor((cy + halfH) / TILE);
        var live = {};

        for (var x = x0; x <= x1; x++) {
          for (var y = y0; y <= y1; y++) {
            if (y < 0 || y >= n) continue;
            var wx = ((x % n) + n) % n;           // 経度方向は巻き込む
            var key = tz + '/' + wx + '/' + y;
            live[key] = true;
            var img = cache[key];
            if (!img) {
              img = document.createElement('img');
              img.className = 'mv-tile';
              img.decoding = 'async';
              img.loading = 'eager';
              img.alt = '';
              img.src = cfg.url.replace('{z}', tz).replace('{x}', wx)
                               .replace('{y}', y);
              img.addEventListener('error', function () {
                this.style.visibility = 'hidden';   // 空タイルは無視
                /* 🔒 §26-4-e: 「無い」印を残す。PLATEAU は対象都市の外に
                 * タイルが無く（§18-am）、黙って灰色だと壊れたように見えるので、
                 * app 側がこの印を数えて一言出す。 */
                this.dataset.miss = '1';
              });
              cache[key] = img;
              pane.appendChild(img);
            }
            var left = (x * TILE - cx) * scale + s.w / 2;
            var top = (y * TILE - cy) * scale + s.h / 2;
            var size = TILE * scale;
            img.style.transform = 'translate3d(' + left.toFixed(2) + 'px,'
              + top.toFixed(2) + 'px,0)';
            img.style.width = size.toFixed(2) + 'px';
            img.style.height = size.toFixed(2) + 'px';
          }
        }
        // 画面外になったタイルを捨てる（増えすぎ防止）
        Object.keys(cache).forEach(function (k) {
          if (!live[k]) { pane.removeChild(cache[k]); delete cache[k]; }
        });
      },
      destroy: function () { if (pane.parentNode) pane.parentNode.removeChild(pane); }
    };
  });

  /* ================= 下敷き: Google Maps =================
   * 🔴 §17（2026-08-18）で一度撤去し、§17-b（2026-08-19 オーナー指示）で
   *    **下敷き2種だけ**を復活させた。復活したのはこのアダプタと
   *    app.js のローダ／gm_authFailure だけで、住所検索（地理院 msearch）や
   *    描画・書き出しには一切戻していない。
   *
   * 🔴 三分法（§11-b）: Google の下敷きは **見る・位置確認のみ**。
   *    なぞらない／画像認識をかけない（認識が触るのは取り込み画像だけなので
   *    構造的にも地図タイルには届かない）。
   * 🔴 Google の地図画像を書き出す機能は作らない（§1-3）。
   *
   * カメラ（中心・ズーム・操作）は MapView 側が持つ（§9-a）ので、Google 地図は
   * 操作を殺して setCenter/setZoom で追従させるだけにする。投影は同じ
   * Web メルカトルなので、地理院タイルと座標がそのまま一致する。
   *
   * app.js が Maps JavaScript API を読み終わるまで window.google は無い。
   * その間 init() は素通りして何も描かず、読み終わった後の draw() で
   * 初めて地図を作る（＝アダプタ側はローダの完了を待たなくてよい）。
   */
  MapView.registerUnderlay('google', function (host, map) {
    var gmap = null, ready = false, kind = 'satellite';
    var div = document.createElement('div');
    div.className = 'mv-gmap';
    host.appendChild(div);

    function init() {
      if (ready || !global.google || !global.google.maps) return;
      gmap = new global.google.maps.Map(div, {
        center: map.getCenter(),
        zoom: Math.round(map.getZoom()),
        mapTypeId: kind === 'satellite' ? 'satellite' : 'roadmap',
        disableDefaultUI: true,
        gestureHandling: 'none',      // 操作は MapView 側に一本化する
        keyboardShortcuts: false,
        tilt: 0
      });
      ready = true;
      api.gmap = gmap;      // 座標一致の確認用
    }

    var api = {
      setKind: function (k) {
        kind = k === 'roadmap' ? 'roadmap' : 'satellite';
        if (ready) gmap.setMapTypeId(kind);
      },
      setOpacity: function (o) { host.style.opacity = o; },
      attribution: function () { return ''; },   // Google の帰属は地図内に出る
      draw: function () {
        init();
        if (!ready) return;
        var s = map.size();

        // Google は整数ズームしか取れず、しかも自前の上限(実測: 航空写真は
        // ZL21)で頭打ちになる。実際に効いたズームとの差は CSS の拡大縮小で埋める。
        //   ・上限超え(k>1) … 画像は粗くなるが作図に必要な大きさが得られる
        //   ・0.5刻みの中間(k<1) … 一段上のタイルを縮小するので画質は落ちない
        // div は s/k で作ってから scale(k) するので、拡大でも縮小でも
        // 画面をちょうど埋める（隙間も無駄なタイル読み込みも出ない）。
        var want = Math.round(map.getZoom());
        gmap.setZoom(want);
        var actual = gmap.getZoom();
        var k = Math.pow(2, map.getZoom() - actual);

        var dw = Math.ceil(s.w / k), dh = Math.ceil(s.h / k);
        div.style.width = dw + 'px';
        div.style.height = dh + 'px';
        div.style.left = Math.round((s.w - dw) / 2) + 'px';
        div.style.top = Math.round((s.h - dh) / 2) + 'px';
        div.style.transformOrigin = '50% 50%';
        div.style.transform = (Math.abs(k - 1) > 0.001)
          ? 'scale(' + k.toFixed(5) + ')' : '';

        map.underlayOverzoom = k > 1.001 ? k : 1;
        gmap.setCenter(map.getCenter());
      },
      destroy: function () { if (div.parentNode) div.parentNode.removeChild(div); }
    };
    return api;
  });

  MapView.TILE = TILE;
  global.MapView = MapView;
})(typeof window !== 'undefined' ? window : this);
