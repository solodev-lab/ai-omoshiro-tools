/* imglay.js — 画像の下敷きレイヤー（正典 §16-3 Step 7A）
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * 何をするか:
 *   お客様が撮影した写真や手元の図面を、**地図の上・描画レイヤーの下**に重ねて
 *   位置合わせできるようにする。カメラは MapView 一本（正典 §9-a）なので、
 *   緯度経度と実幅(m)で持てば地図と一緒に動く。
 *
 * 🔴 権利・秘密の線引き（正典 §1-6 / §11-b / §16-3）
 *   1. 画像バイナリは **IndexedDB（この端末の中）だけ**に置く。
 *      案件 JSON に入れるのは配置メタ（どこに・何m幅で・何度）だけ。
 *   2. 書き出し（PNG/PDF）には画像を含めない。書き出しは描画レイヤーのみ。
 *      → export.js はオブジェクトモデルしか見ないので、ここで何もしなければ
 *         その時点で「含まれない」ことが保証される。
 *   3. なぞってよいのは本人・お客様が権利を持つ画像だけ（レーンC）。
 *      Google マップ等の画面コピーは位置確認のみ（画面に注記を出す）。
 */
(function (global) {
  'use strict';

  var NS = 'http://www.w3.org/2000/svg';
  var DB_NAME = 'shakomap';
  var STORE = 'images';
  var MAX_PX = 2600;        // 長辺の上限（下敷きにはこれで十分・容量対策）

  /* ================= IndexedDB（画像バイナリの置き場） ================= */

  function openDB() {
    return new Promise(function (resolve, reject) {
      if (!global.indexedDB) { reject(new Error('この環境では画像を保存できません')); return; }
      var req = indexedDB.open(DB_NAME, 1);
      req.onupgradeneeded = function () {
        var db = req.result;
        if (!db.objectStoreNames.contains(STORE)) db.createObjectStore(STORE);
      };
      req.onsuccess = function () { resolve(req.result); };
      req.onerror = function () { reject(req.error || new Error('この環境では画像を保存できません')); };
    });
  }

  function tx(mode, fn) {
    return openDB().then(function (db) {
      return new Promise(function (resolve, reject) {
        var t = db.transaction(STORE, mode);
        var store = t.objectStore(STORE);
        var out = fn(store, resolve, reject);
        t.oncomplete = function () { db.close(); resolve(out && out.result); };
        t.onerror = function () { db.close(); reject(t.error); };
      });
    });
  }

  function putImage(id, blob) {
    return tx('readwrite', function (s) { s.put(blob, id); });
  }
  function getImage(id) {
    return tx('readonly', function (s) { return s.get(id); });
  }
  function deleteImage(id) {
    return tx('readwrite', function (s) { s.delete(id); });
  }

  /** 案件を消した時に、その案件の画像も消す（正典 §16-3） */
  function deleteCase(caseId) {
    if (!caseId) return Promise.resolve(0);
    return tx('readwrite', function (s, resolve) {
      var n = 0;
      var req = s.openKeyCursor();
      req.onsuccess = function () {
        var cur = req.result;
        if (!cur) return;
        if (String(cur.key).indexOf(caseId + '/') === 0) { s.delete(cur.key); n++; }
        cur.continue();
      };
    }).catch(function () { return 0; });
  }

  /* ================= 取り込み（EXIF 回転補正込み） ================= */

  /**
   * ファイル → {blob, w, h}。
   * スマホ写真は EXIF に回転が入っているので必ず補正する（正典 §16-3）。
   * createImageBitmap の imageOrientation:'from-image' が使えない環境では
   * 元のファイルをそのまま使う（<img> 側の既定で回転が効く）。
   */
  function decodeFile(file) {
    var type = (file.type === 'image/png') ? 'image/png' : 'image/jpeg';
    if (!global.createImageBitmap) return rawFallback(file);
    return createImageBitmap(file, { imageOrientation: 'from-image' })
      .then(function (bmp) {
        var k = Math.min(1, MAX_PX / Math.max(bmp.width, bmp.height));
        var w = Math.max(1, Math.round(bmp.width * k));
        var h = Math.max(1, Math.round(bmp.height * k));
        var cv = document.createElement('canvas');
        cv.width = w; cv.height = h;
        var g = cv.getContext('2d');
        if (type === 'image/jpeg') { g.fillStyle = '#fff'; g.fillRect(0, 0, w, h); }
        g.drawImage(bmp, 0, 0, w, h);
        if (bmp.close) bmp.close();
        return new Promise(function (res) {
          cv.toBlob(function (b) {
            res({ blob: b || file, w: w, h: h });
          }, type, 0.9);
        });
      })
      .catch(function () { return rawFallback(file); });
  }

  function rawFallback(file) {
    return new Promise(function (resolve, reject) {
      var url = URL.createObjectURL(file);
      var im = new Image();
      im.onload = function () {
        resolve({ blob: file, w: im.naturalWidth, h: im.naturalHeight });
        URL.revokeObjectURL(url);
      };
      im.onerror = function () {
        URL.revokeObjectURL(url);
        reject(new Error('画像を読み込めませんでした'));
      };
      im.src = url;
    });
  }

  /* ================= レイヤー本体 ================= */

  function ImgLay(map) {
    this.map = map;
    this.meta = null;          // {imgId, center, w_m, angle, opacity, visible, locked}
    this.url = null;
    this.ratio = 0.75;         // 高さ / 幅
    this.adjust = false;       // 位置合わせ中（つまみを出す）
    this.toolOk = true;        // いまの道具が「選択」か（作図中はつまみを出さない）
    this.missing = false;      // メタはあるが画像がこの端末に無い
    this._listeners = { change: [], edit: [] };

    // 🔴 下敷き(underlayEl)と描画レイヤー(overlay)の**間**に入れる
    this.el = document.createElement('div');
    this.el.className = 'img-layer';
    map.el.insertBefore(this.el, map.overlay);
    this.img = document.createElement('img');
    this.img.alt = '';
    this.img.draggable = false;
    this.el.appendChild(this.img);

    // つまみは描画レイヤーの一番上（図形より手前）に出す
    this.hl = document.createElementNS(NS, 'g');
    this.hl.setAttribute('class', 'imgh');
    map.overlay.appendChild(this.hl);

    var self = this;
    this._size = map.size();
    map.on('change', function () { self._onMapChange(); });
    // 画面固定中は地図を動かすたびに緯度経度が変わる。保存は動かし終わりで1回
    map.on('viewend', function () {
      if (self.isFloating()) self._emit('change');
    });
    this._bindDrag();
  }

  /* ---------- 画面固定（位置合わせ中） ↔ 緯度経度（固定後） ----------
   * 🔒 オーナー指示 2026-08-18（正典 §16-3 改）:
   *   取り込み直後〜［固定］までは **画像を画面に貼り付け、地図だけを動かして**
   *   合わせる。地図も画像も動かす2度手間をなくすため。
   *   ［固定］でその画面位置を緯度経度に焼き付け、以後は地図に追従する
   *   （追従しないと拡大しながらなぞれない）。 */

  /** 位置合わせ中（画面に貼り付いている状態）か */
  ImgLay.prototype.isFloating = function () {
    return !!(this.meta && !this.meta.locked);
  };

  /** 画面上の位置 → 緯度経度・実幅(m)（保存用の写しを常に最新にしておく） */
  ImgLay.prototype._syncMetaFromScreen = function () {
    var s = this.screen;
    if (!this.meta || !s) return;
    var ll = this.map.unproject(s.x, s.y);
    this.meta.center = ll;
    this.meta.w_m = Math.max(0.5, s.w * this.map.metersPerPixel(ll.lat));
    this.meta.angle = ((s.angle % 360) + 360) % 360;
  };

  /** 緯度経度 → 画面上の位置（読み込み直後・固定を外した時） */
  ImgLay.prototype._syncScreenFromMeta = function () {
    var m = this.meta;
    if (!m) { this.screen = null; return; }
    var p = this.map.project(m.center.lat, m.center.lng);
    this.screen = { x: p.x, y: p.y,
                    w: m.w_m / this.map.metersPerPixel(m.center.lat),
                    angle: m.angle || 0 };
  };

  /** 画面外に出ていたら画面内へ引き戻す（読み込み直後のみ）。
   *  画面固定中は地図を動かしても画像は動かないので、画面外にあると
   *  つまみごと手が届かなくなる。 */
  ImgLay.prototype._clampScreen = function () {
    var s = this.screen, size = this.map.size();
    if (!s || !size.w) return false;
    var pad = 40;
    var x = Math.min(size.w - pad, Math.max(pad, s.x));
    var y = Math.min(size.h - pad, Math.max(pad, s.y));
    if (x === s.x && y === s.y) return false;
    s.x = x; s.y = y;
    this._syncMetaFromScreen();
    return true;
  };

  /** 画像を画面の中央・画面幅6割へ戻す（見失った時の逃げ道） */
  ImgLay.prototype.resetScreen = function () {
    if (!this.isFloating()) return false;
    var size = this.map.size();
    if (!this.screen) this._syncScreenFromMeta();
    this.screen.x = size.w / 2;
    this.screen.y = size.h / 2;
    this.screen.w = Math.max(40, size.w * 0.6);
    this._syncMetaFromScreen();
    this.render();
    this._emit('change');
    this._emit('edit');
    return true;
  };

  ImgLay.prototype._onMapChange = function () {
    var s = this.map.size();
    if (this.screen && (s.w !== this._size.w || s.h !== this._size.h)) {
      // 画面の大きさが変わった時は、中央からの位置関係を保つ
      this.screen.x += (s.w - this._size.w) / 2;
      this.screen.y += (s.h - this._size.h) / 2;
    }
    this._size = s;
    // 画面に貼り付いたまま地図が動いた＝画像の指す場所が変わった
    if (this.isFloating()) this._syncMetaFromScreen();
    this.render();
  };

  ImgLay.prototype.on = function (ev, fn) {
    (this._listeners[ev] || (this._listeners[ev] = [])).push(fn);
    return this;
  };
  ImgLay.prototype._emit = function (ev, arg) {
    (this._listeners[ev] || []).forEach(function (f) { f(arg); });
  };

  ImgLay.prototype.hasImage = function () { return !!(this.meta && this.url); };
  ImgLay.prototype.getMeta = function () { return this.meta; };

  /** 案件・タブを開いた時に呼ぶ。meta が null なら画像なし */
  ImgLay.prototype.load = function (meta, caseId, sheet) {
    var self = this;
    this._release();
    this.meta = meta || null;
    this.missing = false;
    if (!meta || !meta.imgId) { this.render(); return Promise.resolve(false); }
    return getImage(meta.imgId).then(function (blob) {
      if (!blob) {
        // JSON だけ別の端末から持ってきた場合（画像は端末にしか無い）
        self.missing = true;
        self.render();
        self._emit('edit');
        return false;
      }
      // 複製・JSON 取り込みで別の案件になった画像は、この案件の鍵で持ち直す。
      // （元の案件を削除した時に道連れで消えないようにする）
      var p = Promise.resolve();
      if (caseId && String(meta.imgId).indexOf(caseId + '/') !== 0) {
        var nid = caseId + '/' + (sheet || 'haichizu') + '/'
                + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
        p = putImage(nid, blob).then(function () {
          if (self.meta !== meta) return;
          meta.imgId = nid;
          self._emit('change');
        }).catch(function () {});
      }
      return p.then(function () { return self._useBlob(blob); }).then(function () {
        // 固定前の画像は画面に貼り付ける。保存してある緯度経度から画面位置を作り、
        // 画面外に出ていたら引き戻す（画面固定中は地図を動かしても寄って来ないため）
        if (self.isFloating()) { self._syncScreenFromMeta(); self._clampScreen(); }
        self.render();
        self._emit('edit');
        return true;
      });
    }).catch(function () {
      self.missing = true;
      self.render();
      return false;
    });
  };

  ImgLay.prototype._useBlob = function (blob) {
    var self = this;
    return new Promise(function (resolve) {
      var url = URL.createObjectURL(blob);
      var im = new Image();
      im.onload = function () {
        self.url = url;
        self.ratio = im.naturalHeight / (im.naturalWidth || 1);
        self.img.src = url;
        resolve(true);
      };
      im.onerror = function () { URL.revokeObjectURL(url); resolve(false); };
      im.src = url;
    });
  };

  ImgLay.prototype._release = function () {
    if (this.url) { URL.revokeObjectURL(this.url); this.url = null; }
    this.img.removeAttribute('src');
  };

  /**
   * 画像を取り込んで、いまの画面の中央に置く。
   * 初期の幅は画面幅の6割（正典 §16-3）。
   */
  ImgLay.prototype.importFile = function (file, caseId, sheet) {
    var self = this;
    if (!file || !/^image\/(jpeg|png)$/.test(file.type)) {
      return Promise.reject(new Error('JPEG か PNG の画像を選んでください'));
    }
    var old = this.meta && this.meta.imgId;
    return decodeFile(file).then(function (dec) {
      var id = (caseId || 'case') + '/' + (sheet || 'haichizu') + '/'
             + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
      return putImage(id, dec.blob).then(function () {
        var s = self.map.size();
        // 画面の中央・幅は画面の6割（正典 §16-3）。まずは画面に貼り付いた状態
        self.screen = { x: s.w / 2, y: s.h / 2, w: Math.max(40, s.w * 0.6), angle: 0 };
        self.meta = {
          imgId: id, center: self.map.getCenter(),
          w_m: 1, angle: 0, opacity: 0.7, visible: true, locked: false
        };
        self._syncMetaFromScreen();
        self.missing = false;
        self.ratio = dec.h / (dec.w || 1);
        return self._useBlob(dec.blob);
      }).then(function () {
        if (old && old !== self.meta.imgId) deleteImage(old);
        self.render();
        self._emit('change');
        self._emit('edit');
        return self.meta;
      });
    });
  };

  /** 画像を外す（バイナリも端末から消す） */
  ImgLay.prototype.remove = function () {
    var id = this.meta && this.meta.imgId;
    this._release();
    this.meta = null;
    this.missing = false;
    this.render();
    this._emit('change');
    this._emit('edit');
    return id ? deleteImage(id).catch(function () {}) : Promise.resolve();
  };

  /** 濃さ・表示・固定・幅・角度を変える */
  ImgLay.prototype.update = function (props) {
    if (!this.meta) return;
    var m = this.meta;
    if (props.opacity !== undefined) m.opacity = props.opacity;
    if (props.visible !== undefined) m.visible = !!props.visible;

    // 固定の入り切りで、画面固定 ⇄ 緯度経度追従を切り替える
    if (props.locked !== undefined && !!props.locked !== !!m.locked) {
      if (props.locked) {
        this._syncMetaFromScreen();     // いまの画面位置を緯度経度に焼き付ける
        m.locked = true;
      } else {
        m.locked = false;
        this._syncScreenFromMeta();     // 画面に貼り付け直す
      }
    }

    if (props.w_m !== undefined && props.w_m > 0.5) m.w_m = props.w_m;
    if (props.angle !== undefined) m.angle = ((props.angle % 360) + 360) % 360;
    if (props.center) m.center = props.center;
    // 数値で幅・角度を直した時は、貼り付いている画面位置にも反映する
    if ((props.w_m !== undefined || props.angle !== undefined || props.center)
        && this.isFloating()) {
      this._syncScreenFromMeta();
    }
    this.render();
    this._emit('change');
  };

  /** 位置合わせのつまみを出すか（パネルを開いている間だけ） */
  ImgLay.prototype.setAdjust = function (on) {
    this.adjust = !!on;
    this.render();
  };

  /** 作図の道具を持っている間はつまみを出さない（描く方を優先する） */
  ImgLay.prototype.setToolOk = function (ok) {
    ok = !!ok;
    if (this.toolOk === ok) return;
    this.toolOk = ok;
    this.render();
  };

  ImgLay.prototype.canAdjust = function () {
    return !!(this.adjust && this.toolOk !== false
              && this.meta && this.url
              && this.meta.visible && !this.meta.locked);
  };

  /* ---------- 画面への反映 ---------- */

  ImgLay.prototype.geom = function () {
    var m = this.meta;
    if (!m) return null;
    if (this.isFloating()) {
      // 位置合わせ中は画面座標そのまま（地図が動いても画像は動かない）
      if (!this.screen) this._syncScreenFromMeta();
      var s = this.screen;
      return { c: { x: s.x, y: s.y }, w: s.w, h: s.w * this.ratio,
               deg: s.angle || 0, ang: (s.angle || 0) * Math.PI / 180 };
    }
    var c = this.map.project(m.center.lat, m.center.lng);
    var mpp = this.map.metersPerPixel(m.center.lat);
    var w = m.w_m / mpp, h = w * this.ratio;
    return { c: c, w: w, h: h, deg: m.angle || 0,
             ang: (m.angle || 0) * Math.PI / 180 };
  };

  ImgLay.prototype.corners = function (g) {
    g = g || this.geom();
    if (!g) return [];
    var ca = Math.cos(g.ang), sa = Math.sin(g.ang);
    return [[-g.w / 2, -g.h / 2], [g.w / 2, -g.h / 2],
            [g.w / 2, g.h / 2], [-g.w / 2, g.h / 2]].map(function (p) {
      return { x: g.c.x + p[0] * ca - p[1] * sa,
               y: g.c.y + p[0] * sa + p[1] * ca };
    });
  };

  /* 🔴 画像の表示は地図の下敷きとは独立（正典 §16-3 改）。
   *    上部バーの下敷きOFF は地図だけを消し、画像は［画像］トグルで切る。
   *    位置合わせ後は「地図OFF＋画像ON」でなぞるのが標準の使い方。 */
  ImgLay.prototype.render = function () {
    var m = this.meta, g = this.geom();
    var show = !!(m && this.url && m.visible !== false);
    this.img.style.display = show ? '' : 'none';
    if (show) {
      this.img.style.width = g.w.toFixed(1) + 'px';
      this.img.style.height = g.h.toFixed(1) + 'px';
      this.img.style.left = (g.c.x - g.w / 2).toFixed(1) + 'px';
      this.img.style.top = (g.c.y - g.h / 2).toFixed(1) + 'px';
      this.img.style.transform = 'rotate(' + g.deg.toFixed(2) + 'deg)';
      this.img.style.opacity = (m.opacity === undefined ? 0.7 : m.opacity);
    }
    this._renderHandles(g);
  };

  ImgLay.prototype._renderHandles = function (g) {
    var L = this.hl;
    while (L.firstChild) L.removeChild(L.firstChild);
    if (!this.canAdjust()) return;
    var c = this.corners(g);

    // 外枠は目印だけ（当たり判定を持たせない）。
    // 🔴 画像の上をドラッグしたら**下の地図が動く**のが位置合わせの主操作なので、
    //    画像全体を掴めるようにすると地図が動かせなくなる（正典 §16-3 改）。
    //    画像そのものの微調整は中央の移動つまみで行う。
    var poly = document.createElementNS(NS, 'polygon');
    poly.setAttribute('points', c.map(function (p) {
      return p.x.toFixed(1) + ',' + p.y.toFixed(1);
    }).join(' '));
    poly.setAttribute('class', 'img-frame');
    L.appendChild(poly);

    var mv = document.createElementNS(NS, 'circle');
    mv.setAttribute('cx', g.c.x.toFixed(1));
    mv.setAttribute('cy', g.c.y.toFixed(1));
    mv.setAttribute('r', 12);
    mv.setAttribute('class', 'hit img-h img-move');
    mv.dataset.grab = 'move';
    L.appendChild(mv);
    var cross = document.createElementNS(NS, 'path');
    cross.setAttribute('d', 'M' + (g.c.x - 6) + ' ' + g.c.y + 'h12M'
                      + g.c.x + ' ' + (g.c.y - 6) + 'v12');
    cross.setAttribute('class', 'img-move-icon');
    L.appendChild(cross);

    c.forEach(function (p, i) {
      var r = document.createElementNS(NS, 'rect');
      r.setAttribute('x', (p.x - 7).toFixed(1));
      r.setAttribute('y', (p.y - 7).toFixed(1));
      r.setAttribute('width', 14);
      r.setAttribute('height', 14);
      r.setAttribute('class', 'hit img-h');
      r.dataset.grab = 'scale';
      r.dataset.index = i;
      L.appendChild(r);
    });

    // 上辺の中央から少し外側に回転つまみ
    var top = { x: (c[0].x + c[1].x) / 2, y: (c[0].y + c[1].y) / 2 };
    var nx = top.x - g.c.x, ny = top.y - g.c.y;
    var len = Math.hypot(nx, ny) || 1;
    var rp = { x: top.x + nx / len * 26, y: top.y + ny / len * 26 };
    var stem = document.createElementNS(NS, 'line');
    stem.setAttribute('x1', top.x.toFixed(1)); stem.setAttribute('y1', top.y.toFixed(1));
    stem.setAttribute('x2', rp.x.toFixed(1)); stem.setAttribute('y2', rp.y.toFixed(1));
    stem.setAttribute('class', 'img-stem');
    L.appendChild(stem);
    var rot = document.createElementNS(NS, 'circle');
    rot.setAttribute('cx', rp.x.toFixed(1));
    rot.setAttribute('cy', rp.y.toFixed(1));
    rot.setAttribute('r', 8);
    rot.setAttribute('class', 'hit img-h img-rot');
    rot.dataset.grab = 'rotate';
    L.appendChild(rot);
  };

  /* ---------- ドラッグ（移動・拡縮・回転） ----------
   * つまみは再描画のたびに作り直すので、掴んでいる間の追跡は window で行う。
   * （要素を握り続けないので、描き直しでドラッグが切れない） */

  ImgLay.prototype._bindDrag = function () {
    var self = this;
    this.hl.addEventListener('pointerdown', function (e) {
      var grab = e.target && e.target.dataset && e.target.dataset.grab;
      if (!grab || !self.canAdjust()) return;
      e.preventDefault();
      e.stopPropagation();
      var r = self.map.el.getBoundingClientRect();
      var start = { x: e.clientX - r.left, y: e.clientY - r.top };
      if (!self.screen) self._syncScreenFromMeta();
      var st = { grab: grab, start: start,
                 x: self.screen.x, y: self.screen.y,
                 w: self.screen.w, angle: self.screen.angle || 0 };
      self.map.inputLocked = true;

      // つまみの操作は画面座標で行う（位置合わせ中は画像が画面に貼り付いている）。
      // 動かした結果は緯度経度の写しへ反映しておく（保存・固定に使う）
      function move(ev) {
        var p = { x: ev.clientX - r.left, y: ev.clientY - r.top };
        var s = self.screen;
        if (st.grab === 'move') {
          s.x = st.x + (p.x - st.start.x);
          s.y = st.y + (p.y - st.start.y);
        } else if (st.grab === 'scale') {
          // 中心を動かさずに拡大縮小する（掴んだ角の距離で決める）
          var a = -st.angle * Math.PI / 180;
          var dx = p.x - st.x, dy = p.y - st.y;
          var lx = dx * Math.cos(a) - dy * Math.sin(a);
          s.w = Math.max(20, Math.abs(lx) * 2);
        } else {
          var ang = Math.atan2(p.y - st.y, p.x - st.x) * 180 / Math.PI + 90;
          if (ev.shiftKey) ang = Math.round(ang / 15) * 15;
          s.angle = ((ang % 360) + 360) % 360;
        }
        self._syncMetaFromScreen();
        self.render();
      }
      function up() {
        window.removeEventListener('pointermove', move, true);
        window.removeEventListener('pointerup', up, true);
        window.removeEventListener('pointercancel', up, true);
        self.map.inputLocked = false;
        self._emit('change');
        self._emit('edit');
      }
      window.addEventListener('pointermove', move, true);
      window.addEventListener('pointerup', up, true);
      window.addEventListener('pointercancel', up, true);
    });
  };

  ImgLay.deleteCase = deleteCase;
  ImgLay.deleteImage = deleteImage;
  global.ImgLay = ImgLay;
})(typeof window !== 'undefined' ? window : this);
