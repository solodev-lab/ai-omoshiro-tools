/* pmtiles.js — PMTiles v3 リーダー（依存ゼロ）
 *
 * 車庫証明 所在図・配置図メーカー
 * 法務省 登記所備付地図データ（筆界ポリゴン）が PMTiles 形式で公開されているため、
 * 1ファイル 16GB を丸ごと落とさずに必要なタイルだけ HTTP Range で拾う。
 *
 * 仕様: https://github.com/protomaps/PMTiles （v3）
 *   ヘッダ127バイト → ルートディレクトリ → (葉ディレクトリ) → タイル本体
 *   タイルの並びは Hilbert 曲線順。
 */
(function (global) {
  'use strict';

  var COMPRESSION = { NONE: 1, GZIP: 2, BROTLI: 3, ZSTD: 4 };

  /* ---------- バイト列を読む ---------- */
  function u32(dv, p) { return dv.getUint32(p, true); }
  /** 64bit を Number で読む（16GB 程度なら精度に問題ない） */
  function u64(dv, p) { return u32(dv, p) + u32(dv, p + 4) * 4294967296; }

  function VarReader(buf) { this.b = buf; this.p = 0; }
  VarReader.prototype.v = function () {
    var r = 0, sh = 0, c;
    do { c = this.b[this.p++]; r += (c & 0x7f) * Math.pow(2, sh); sh += 7; }
    while (c & 0x80);
    return r;
  };

  /* ---------- Hilbert 曲線でのタイル番号 ---------- */
  function xyToHilbert(z, x, y) {
    var n = 1 << z, rx, ry, d = 0, s = n >> 1, t;
    while (s > 0) {
      rx = (x & s) ? 1 : 0;
      ry = (y & s) ? 1 : 0;
      d += s * s * ((3 * rx) ^ ry);
      if (ry === 0) {
        if (rx === 1) { x = s - 1 - x; y = s - 1 - y; }
        t = x; x = y; y = t;
      }
      s >>= 1;
    }
    return d;
  }
  function tileId(z, x, y) {
    // z 未満の全タイル数 = (4^z - 1) / 3
    var base = 0;
    for (var i = 0; i < z; i++) base += Math.pow(4, i);
    return base + xyToHilbert(z, x, y);
  }

  /* ---------- 解凍 ---------- */
  function decompress(buf, mode) {
    if (mode === COMPRESSION.NONE || !mode) return Promise.resolve(buf);
    if (mode !== COMPRESSION.GZIP) {
      return Promise.reject(new Error('PMTiles: 未対応の圧縮形式 ' + mode));
    }
    if (typeof DecompressionStream === 'undefined') {
      return Promise.reject(new Error('このブラウザは gzip 展開に対応していません'));
    }
    var ds = new DecompressionStream('gzip');
    var w = ds.writable.getWriter();
    // write/close の返す Promise も拾っておく。放置すると壊れたデータの時に
    // 「Uncaught (in promise)」が出る。
    var noop = function () {};
    w.write(buf).catch(noop);
    w.close().catch(noop);
    return new Response(ds.readable).arrayBuffer().then(function (ab) {
      return new Uint8Array(ab);
    });
  }

  /* ---------- ディレクトリ ---------- */
  function parseDir(buf) {
    var r = new VarReader(buf);
    var n = r.v(), i;
    var ids = new Array(n), runs = new Array(n),
        lens = new Array(n), offs = new Array(n);
    var last = 0;
    for (i = 0; i < n; i++) { last += r.v(); ids[i] = last; }
    for (i = 0; i < n; i++) runs[i] = r.v();
    for (i = 0; i < n; i++) lens[i] = r.v();
    for (i = 0; i < n; i++) {
      var v = r.v();
      // 0 は「前のエントリの直後に続く」の意。先頭で 0 ならデータ先頭(0)。
      // ここを (v-1) にすると -1 になり、ずれた位置を読んで gzip が壊れる。
      offs[i] = (v === 0) ? (i > 0 ? offs[i - 1] + lens[i - 1] : 0) : (v - 1);
    }
    return { n: n, ids: ids, runs: runs, lens: lens, offs: offs };
  }

  /** ディレクトリから tid を探す。葉へ降りる必要があれば isLeaf を立てて返す */
  function findEntry(dir, tid) {
    var lo = 0, hi = dir.n - 1, best = -1;
    while (lo <= hi) {
      var mid = (lo + hi) >> 1;
      if (dir.ids[mid] <= tid) { best = mid; lo = mid + 1; } else { hi = mid - 1; }
    }
    if (best < 0) return null;
    var run = dir.runs[best];
    if (run === 0) return { isLeaf: true, off: dir.offs[best], len: dir.lens[best] };
    if (tid < dir.ids[best] + run) {
      return { isLeaf: false, off: dir.offs[best], len: dir.lens[best] };
    }
    return null;
  }

  /* ================= PMTiles ================= */

  function PMTiles(url) {
    this.url = url;
    this._header = null;
    this._root = null;
    this._leaves = {};      // offset -> dir
    this._tileCache = {};   // 'z/x/y' -> Uint8Array | null
  }

  PMTiles.prototype._range = function (start, length) {
    return fetch(this.url, {
      headers: { Range: 'bytes=' + start + '-' + (start + length - 1) }
    }).then(function (r) {
      if (!r.ok && r.status !== 206) {
        throw new Error('PMTiles の取得に失敗しました (' + r.status + ')');
      }
      return r.arrayBuffer();
    }).then(function (ab) { return new Uint8Array(ab); });
  };

  PMTiles.prototype.header = function () {
    if (this._header) return Promise.resolve(this._header);
    var self = this;
    return this._range(0, 127).then(function (b) {
      var dv = new DataView(b.buffer, b.byteOffset, b.byteLength);
      var magic = String.fromCharCode.apply(null, b.subarray(0, 7));
      if (magic !== 'PMTiles') throw new Error('PMTiles ではありません');
      if (b[7] !== 3) throw new Error('PMTiles v' + b[7] + ' は未対応です');
      self._header = {
        rootOffset: u64(dv, 8), rootLength: u64(dv, 16),
        metaOffset: u64(dv, 24), metaLength: u64(dv, 32),
        leafOffset: u64(dv, 40), leafLength: u64(dv, 48),
        dataOffset: u64(dv, 56), dataLength: u64(dv, 64),
        internalCompression: b[97], tileCompression: b[98],
        tileType: b[99], minZoom: b[100], maxZoom: b[101]
      };
      return self._header;
    });
  };

  PMTiles.prototype._rootDir = function () {
    if (this._root) return Promise.resolve(this._root);
    var self = this;
    return this.header().then(function (h) {
      return self._range(h.rootOffset, h.rootLength);
    }).then(function (b) {
      return decompress(b, self._header.internalCompression);
    }).then(function (b) {
      self._root = parseDir(b);
      return self._root;
    });
  };

  PMTiles.prototype._leafDir = function (off, len) {
    var key = off + ':' + len;
    if (this._leaves[key]) return Promise.resolve(this._leaves[key]);
    var self = this, h = this._header;
    return this._range(h.leafOffset + off, len).then(function (b) {
      return decompress(b, h.internalCompression);
    }).then(function (b) {
      self._leaves[key] = parseDir(b);
      return self._leaves[key];
    });
  };

  /** タイル1枚を取る。データが無ければ null */
  PMTiles.prototype.getTile = function (z, x, y) {
    var key = z + '/' + x + '/' + y;
    if (this._tileCache.hasOwnProperty(key)) {
      return Promise.resolve(this._tileCache[key]);
    }
    var self = this, tid = tileId(z, x, y);

    return this._rootDir().then(function (root) {
      function walk(dir, depth) {
        var e = findEntry(dir, tid);
        if (!e) return null;
        if (!e.isLeaf) return e;
        if (depth > 3) return null;
        return self._leafDir(e.off, e.len).then(function (leaf) {
          return walk(leaf, depth + 1);
        });
      }
      return walk(root, 0);
    }).then(function (e) {
      if (!e) { self._tileCache[key] = null; return null; }
      var h = self._header;
      return self._range(h.dataOffset + e.off, e.len)
        .then(function (b) { return decompress(b, h.tileCompression); })
        .then(function (b) { self._tileCache[key] = b; return b; });
    }).catch(function (err) {
      self._tileCache[key] = null;
      throw err;
    });
  };

  PMTiles.prototype.metadata = function () {
    var self = this;
    return this.header().then(function (h) {
      return self._range(h.metaOffset, h.metaLength);
    }).then(function (b) {
      return decompress(b, self._header.internalCompression);
    }).then(function (b) {
      return JSON.parse(new TextDecoder('utf-8').decode(b));
    });
  };

  PMTiles.COMPRESSION = COMPRESSION;
  PMTiles.tileId = tileId;
  global.PMTiles = PMTiles;
})(typeof window !== 'undefined' ? window : this);
