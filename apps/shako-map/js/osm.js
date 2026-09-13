/* osm.js — OpenStreetMap (Overpass API) 取得層／正典 §23-6・§26 Step 8
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * ここは「名称の分類なぞり出し（§23-5）」のデータ源のうち、
 * **地理院ベクトルタイルに無い物**（交差点名・お店・会社・バス停・細街路の道路名）
 * を取りに行く層。描画・なぞり出しの判定は一切持たない（reveal.js の仕事）。
 *
 * 設計の要点:
 *  1. 🔴 **サーバーを立てない**（§1-6 ローカル完結）。Overpass は
 *     `Access-Control-Allow-Origin: *` を返すのでブラウザから直接叩ける（実測 §23-6）。
 *     （素の urllib は User-Agent 無しで 406 になるが、ブラウザの fetch は自動付与）
 *  2. 🔴 **公共インスタンスなので控えめに叩く**（§23-6）。
 *     ・分類チェックが ON の時だけ呼ぶ（呼び出し側 reveal.js の責務）
 *     ・取りに行く範囲は表示範囲を PAD だけ広げた矩形。少し動かしても取り直さない
 *     ・案件内キャッシュ（同じ範囲・同じ分類の再取得をしない）
 *     ・広すぎる範囲は**そもそも投げない**（kind:'wide' で断る）
 *  3. 🔴 **落ちても作図は止めない**（§23-6 / §20-6 fail-open と同思想）。
 *     ここは Promise を reject するだけ。呼び出し側は「名称が今は取れない」を
 *     出して、線のなぞり出しと地理院由来の名称はそのまま使い続ける。
 *  4. 予備ミラーを1つ持つ（§23-6）。1つ目が駄目なら2つ目へ。
 *
 * ライセンス（§23-6）: ODbL。書き出し画像は Produced Work なので出典表記のみで商用可。
 *   → 実体化したら ATTRIBUTION を**そのシートの出典**へ足す（§24-3 出典はシート単位）。
 */
(function (global) {
  'use strict';

  /* ================= 仮値（🙋 オーナー実機目視・実測で確定する） ================= */

  /* 🔴 予備ミラー（§23-6）。先頭から順に試す。
   * 外から差し替えられるように**配列の中身を入れ替える**形で公開している
   * （テストで失敗を作る時・別ミラーを足す時に代入せず push/splice で触る）。 */
  var ENDPOINTS = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter'
  ];

  var ATTRIBUTION = '© OpenStreetMap contributors';

  var QL_TIMEOUT = 25;        // Overpass 側のタイムアウト（秒）
  var FETCH_MS = 22000;       // こちらから諦める時間（ms）
  var PAD = 0.25;             // 表示範囲をこの割合だけ広げて取る（パンの取り直しを減らす）
  var MAX_SPAN_M = 4000;      // これより広い範囲は投げない（実測 1km四方 = 2.9秒）
  var MAX_POINTS = 900;       // out center の上限（暴走よけ）
  var MAX_WAYS = 900;         // out geom の上限
  var MAX_ROUTES = 40;        // 🔒 §22-av: 路線関係（国道・都道府県道）の上限
  var CACHE_MAX = 12;         // 案件内キャッシュの本数

  /* ================= 分類（🔒 §23-5 オーナー指定の7分類） =================
   * dot   … ●（anchor）を付けるか。🔴 道路名は「線に付く名前」なので付けない（§18-8）
   * mark  … ●の代わりに描く印の種類（無指定＝●）。実体化した text の dotStyle になる。
   *          🔒 2026-09-02 オーナー指示: 交差点名だけ 'signal'（信号機のアイコン）。
   *          🔒 2026-09-04 オーナー指示: バス停だけ 'bus'（標識アイコン）。
   *          🔴 印の種類はここが唯一の出どころ。表示文字列（'交差点名'/'バス停'）で
   *             分岐してはいけない（§26-2 注意②）
   * size  … 実体化した時の文字の大きさ（shozaizu.js の TEXT_SIZE と揃える）
   * gsi   … 地理院 Anno にも同じ物があるか（両方から集めて名前で名寄せする）
   * osm   … OSM から取るか
   */
  var CATS = [
    { id: 'public',   ja: '公共的建物', dot: true,  size: 'medium', gsi: true,  osm: true },
    { id: 'crossing', ja: '交差点名',   dot: true,  size: 'medium', gsi: false, osm: true,
      mark: 'signal' },
    { id: 'shop',     ja: '大きなお店', dot: true,  size: 'small',  gsi: false, osm: true },
    { id: 'office',   ja: '会社名',     dot: true,  size: 'small',  gsi: false, osm: true },
    { id: 'bus',      ja: 'バス停',     dot: true,  size: 'small',  gsi: false, osm: true,
      mark: 'bus' },
    { id: 'road',     ja: '道路名',     dot: false, size: 'medium', gsi: true,  osm: true }
  ];

  var CAT_BY_ID = Object.create(null);
  CATS.forEach(function (c) { CAT_BY_ID[c.id] = c; });

  /* ================= 小物 ================= */

  function num(v) { return typeof v === 'number' && isFinite(v); }

  /** Overpass の bbox 表記（south,west,north,east） */
  function fmtBBox(b) {
    return b.south.toFixed(6) + ',' + b.west.toFixed(6) + ','
         + b.north.toFixed(6) + ',' + b.east.toFixed(6);
  }

  function padBounds(b, k) {
    var dy = (b.north - b.south) * k, dx = (b.east - b.west) * k;
    return { south: b.south - dy, north: b.north + dy,
             west: b.west - dx, east: b.east + dx };
  }

  function inBounds(lat, lng, b) {
    return lat >= b.south && lat <= b.north && lng >= b.west && lng <= b.east;
  }

  function coversBounds(outer, inner) {
    return outer.south <= inner.south + 1e-9 && outer.north >= inner.north - 1e-9
        && outer.west <= inner.west + 1e-9 && outer.east >= inner.east - 1e-9;
  }

  /** ざっくりの幅・高さ(m)。広すぎる範囲を弾くためだけなので球面近似で十分 */
  function spanMeters(b) {
    var mLat = 110574;
    var mLng = 111320 * Math.cos((b.north + b.south) / 2 * Math.PI / 180);
    return { w: Math.abs(b.east - b.west) * mLng,
             h: Math.abs(b.north - b.south) * mLat };
  }

  /** 有効な分類だけの素直な集合にする（未知の id は捨てる） */
  function normCats(cats) {
    var out = Object.create(null), n = 0;
    CATS.forEach(function (c) {
      if (cats && cats[c.id]) { out[c.id] = true; n++; }
    });
    out._n = n;
    return out;
  }

  function catsCovered(have, want) {
    for (var i = 0; i < CATS.length; i++) {
      var id = CATS[i].id;
      if (want[id] && !have[id]) return false;
    }
    return true;
  }

  /* ================= 問い合わせ文 =================
   * 🔴 点の分類は `out center` で1回・道路は `out geom` で1回。
   *    道路だけ形が要るのは「表示範囲内の同名 way を1ラベルに名寄せ」する時に
   *    代表点を**枠の中**に置く必要があるため（§23-5-a）。center だけだと
   *    枠の外に代表点が出て名前が消える。
   */
  function buildQuery(b, cats, routes) {
    var bb = fmtBBox(b), q = '[out:json][timeout:' + QL_TIMEOUT + '];', any = false;

    /* 🔴 2026-09-04 是正3（§22-ak-6）: **分類ごとに `out` を分ける**。
     * 以前は5分類を1つの union に入れて `out center 900` を1回だけ掛けていたので、
     * 密集地では上限を**分類どうしで奪い合って**いた（実測・名古屋三の丸 枠1625×2181m）:
     *
     *   6分類ぜんぶ要求 → 応答 900点（うち バス停 60・交差点 272）
     *   交差点＋バス停だけ要求 → 応答 461点（うち バス停 187・交差点 274）
     *
     * ＝「バス停をなしにすると交差点の取得結果が変わる」＝ **取得層での段依存**。
     * 分類ごとに out を分ければ、ある分類が返す集合は他の分類の有無に依らない。 */
    function grp(lines) {
      if (!lines.length) return;
      any = true;
      q += (lines.length > 1 ? '(' + lines.join('') + ');' : lines[0])
         + 'out center ' + MAX_POINTS + ';';
    }

    if (cats.public) {
      grp(['node["amenity"]["name"](' + bb + ');',
           'way["amenity"]["name"](' + bb + ');',
           'relation["amenity"]["name"](' + bb + ');']);
    }
    if (cats.crossing) {
      grp(['node["highway"="traffic_signals"]["name"](' + bb + ');']);
    }
    if (cats.shop) {
      grp(['node["shop"]["name"](' + bb + ');',
           'way["shop"]["name"](' + bb + ');']);
    }
    if (cats.office) {
      grp(['node["office"]["name"](' + bb + ');',
           'way["office"]["name"](' + bb + ');']);
    }
    if (cats.bus) {
      grp(['node["highway"="bus_stop"]["name"](' + bb + ');']);
    }
    if (cats.road) {
      q += 'way["highway"]["name"](' + bb + ');out geom ' + MAX_WAYS + ';';
      any = true;
    }
    /* 🔒 §22-av: 路線番号の印（国道 ▽ / 都道府県道 六角形）のもと。
     * 🔴 **way ではなく route 関係**を引く。way の `ref` は国道も県道も裸の数字で、
     *    どちらの路線かを機械的に決められない（実測: 名駅で trunk ref=19 と
     *    primary ref=59 が同居）。関係の `network` は JP:national / JP:prefectural と
     *    明示されているので、ここだけが確実な出どころ。
     * 🔴 `out geom(bb)` で**枠の中だけに切って**返させる（切らないと1本の国道が
     *    県境まで数百kmぶん返ってきて応答が肥大する）。 */
    if (routes) {
      q += 'rel["type"="route"]["route"="road"]'
         + '["network"~"^JP:(national|prefectural)$"](' + bb + ');'
         + 'out geom(' + bb + ') ' + MAX_ROUTES + ';';
      any = true;
    }
    return any ? q : '';
  }

  /* ================= 応答 → 名称 ================= */

  /** 点の分類。🔴 順番が意味を持つ（交差点・バス停は highway なので先に見る） */
  function pointCat(tg) {
    if (tg.highway === 'traffic_signals') return 'crossing';
    if (tg.highway === 'bus_stop') return 'bus';
    if (tg.shop) return 'shop';
    if (tg.office) return 'office';
    if (tg.amenity) return 'public';
    return null;
  }

  function elPoint(e) {
    if (num(e.lat) && num(e.lon)) return { lat: e.lat, lng: e.lon };
    if (e.center && num(e.center.lat) && num(e.center.lon)) {
      return { lat: e.center.lat, lng: e.center.lon };
    }
    return null;
  }

  /**
   * 🔒 §22-av: 路線番号を取り出す。
   * 🔴 `ref` が無い関係が実在する（実測 2026-09-06: 国道19号は ref 無しで名前だけ）ので、
   *    名前からも拾う。`ref` が "19;22" のように複数付く事もあるので先頭だけ使う。
   */
  function routeNumber(tg) {
    var r = String(tg.ref || '').split(';')[0].trim();
    if (/^[0-9]{1,3}$/.test(r)) return r;
    var m = /(?:国道|県道|府道|道道|都道)\s*([0-9]{1,3})\s*号/.exec(tg.name || '');
    return m ? m[1] : '';
  }

  function parse(json, cats) {
    var els = (json && json.elements) || [];
    var items = [], roads = [], routes = [], seenPt = Object.create(null),
        seenWay = Object.create(null), i;
    for (i = 0; i < els.length; i++) {
      var e = els[i], tg = e.tags || {};
      var name = tg.name;
      /* 🔒 §22-av: 路線関係（国道・都道府県道）。名前が無い関係もあるので
       * **名前の判定より前**に見る。番号が取れない関係は印を描けないので捨てる。 */
      if (e.type === 'relation' && tg.route === 'road' && tg.network) {
        var kind = (tg.network === 'JP:national') ? 'national'
                 : (tg.network === 'JP:prefectural') ? 'pref' : '';
        var no = routeNumber(tg);
        if (!kind || !no) continue;
        var pts = [], ms = e.members || [];
        for (var mi = 0; mi < ms.length; mi++) {
          var gm = ms[mi].geometry;
          if (!gm) continue;
          /* 🔴 `out geom(bb)` は枠の外を切った所に **null** を挟んで返す（実測
           * 2026-09-06）。素直に読むと null.lat で落ちるので必ず弾く。 */
          for (var gj = 0; gj < gm.length; gj++) {
            var gp = gm[gj];
            if (gp && num(gp.lat) && num(gp.lon)) {
              pts.push({ lat: gp.lat, lng: gp.lon });
            }
          }
        }
        if (pts.length) {
          routes.push({ kind: kind, no: no, name: name || '', pts: pts, id: e.id });
        }
        continue;
      }
      if (!name) continue;
      /* 道路（out geom で返ってきた物）は geometry を持つ。
       * 点の分類（out center）と取り違えないよう geometry の有無で分ける。 */
      if (e.type === 'way' && e.geometry && e.geometry.length >= 2 && tg.highway) {
        if (!cats.road) continue;
        if (seenWay[e.id]) continue;
        seenWay[e.id] = true;
        roads.push({ name: name, geom: e.geometry, id: e.id });
        continue;
      }
      var cat = pointCat(tg);
      if (!cat || !cats[cat]) continue;
      var ll = elPoint(e);
      if (!ll) continue;
      // 同じ物が node と way の両方で地図に入っている事があるので詰める
      var k = cat + '|' + name + '|' + ll.lat.toFixed(4) + ',' + ll.lng.toFixed(4);
      if (seenPt[k]) continue;
      seenPt[k] = true;
      /* 🔒 2026-09-03: `sub` ＝ 分類を決めたタグの**値**（amenity=school / shop=supermarket…）。
       * 🔴 「他の目印」は amenity 全部なので自販機・駐輪場・ベンチまで入る
       *    （§23-6-a 持ち越し2・名駅前で319件）。自動描画の5段階では
       *    公共性・規模の高い物から先に出す必要があり、その優先順の判定に使う
       *    （shozaizu.js POI_PRIO / SHOP_PRIO）。表示文字では判定しない（§26-2 注意②）。 */
      items.push({ cat: cat, name: name, lat: ll.lat, lng: ll.lng, src: 'osm',
                   sub: tg.amenity || tg.shop || tg.office || tg.highway || '' });
    }
    return { items: items, roads: roads, routes: routes };
  }

  /* ================= 道路名の名寄せ（🔒 §23-5-a） =================
   * OSM は1本の道路が複数 way に切れている（実測 名城1km四方で 45本 → ユニーク24名）。
   * **表示範囲内の同名 way は1ラベルに統合**し、代表点を1つだけ返す。
   * 代表点は「枠の中に入っている頂点のうち、それらの重心に一番近い頂点」＝必ず道の上に乗る。
   */

  /** way の頂点のうち枠の中に入っている物。1つも無ければ辺を刻んで拾う（長い直線対策） */
  function insidePoints(geom, b) {
    var out = [], i, k;
    for (i = 0; i < geom.length; i++) {
      if (inBounds(geom[i].lat, geom[i].lon, b)) {
        out.push({ lat: geom[i].lat, lng: geom[i].lon });
      }
    }
    if (out.length) return out;
    for (i = 1; i < geom.length; i++) {
      var a = geom[i - 1], c = geom[i];
      for (k = 1; k < 8; k++) {
        var u = k / 8;
        var la = a.lat + (c.lat - a.lat) * u, lo = a.lon + (c.lon - a.lon) * u;
        if (inBounds(la, lo, b)) out.push({ lat: la, lng: lo });
      }
    }
    return out;
  }

  /**
   * @param roads  parse() が返した way の配列
   * @param b      いま表示している範囲
   * @return [{cat:'road', name, lat, lng, src:'osm', ways:n}]
   */
  function mergeRoads(roads, b) {
    var by = Object.create(null), order = [], i, j;
    for (i = 0; i < roads.length; i++) {
      var pts = insidePoints(roads[i].geom, b);
      if (!pts.length) continue;
      var a = by[roads[i].name];
      if (!a) { a = by[roads[i].name] = { pts: [], ways: 0 }; order.push(roads[i].name); }
      a.ways++;
      for (j = 0; j < pts.length; j++) a.pts.push(pts[j]);
    }
    var out = [];
    for (i = 0; i < order.length; i++) {
      var name = order[i], g = by[name], n = g.pts.length;
      var sx = 0, sy = 0;
      for (j = 0; j < n; j++) { sx += g.pts[j].lng; sy += g.pts[j].lat; }
      var cxv = sx / n, cyv = sy / n, best = 0, bd = Infinity;
      for (j = 0; j < n; j++) {
        var dx = g.pts[j].lng - cxv, dy = g.pts[j].lat - cyv;
        var d = dx * dx + dy * dy;
        if (d < bd) { bd = d; best = j; }
      }
      out.push({ cat: 'road', name: name, lat: g.pts[best].lat,
                 lng: g.pts[best].lng, src: 'osm', ways: g.ways });
    }
    return out;
  }

  /* ================= 取得 ================= */

  var _cache = [];        // [{cats, bbox, data, ms, bytes}]
  var _last = null;       // 直近の実測（実装メモ・オーナー確認用）

  function clearCache() { _cache.length = 0; }

  function findCache(bounds, cats, routes) {
    for (var i = _cache.length - 1; i >= 0; i--) {
      var e = _cache[i];
      if (!catsCovered(e.cats, cats)) continue;
      // 🔒 §22-av: 路線が要る時は、路線も入れて取った物でないと使えない
      if (routes && !e.routes) continue;
      if (!coversBounds(e.bbox, bounds)) continue;
      return e;
    }
    return null;
  }

  function putCache(e) {
    _cache.push(e);
    if (_cache.length > CACHE_MAX) _cache.splice(0, _cache.length - CACHE_MAX);
  }

  function err(kind, msg) {
    var e = new Error(msg);
    e.kind = kind;
    return e;
  }

  /** 1つのミラーへ投げる */
  function post(url, query) {
    var ctl = (typeof AbortController !== 'undefined') ? new AbortController() : null;
    var timer = setTimeout(function () { if (ctl) ctl.abort(); }, FETCH_MS);
    var opt = {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'data=' + encodeURIComponent(query)
    };
    if (ctl) opt.signal = ctl.signal;
    return fetch(url, opt).then(function (r) {
      if (!r.ok) throw err('net', 'Overpass ' + r.status);
      return r.text();
    }).then(function (txt) {
      clearTimeout(timer);
      var json;
      try { json = JSON.parse(txt); }
      catch (e) { throw err('net', '応答を読めませんでした'); }
      return { json: json, bytes: txt.length };
    }, function (e) {
      clearTimeout(timer);
      throw (e && e.kind) ? e : err('net', (e && e.message) || '通信に失敗しました');
    });
  }

  /**
   * 表示範囲の名称を取る。
   * @param bounds {west,south,east,north}（＝いま画面に写っている範囲）
   * @param cats   {public:true, road:true, ...}
   * @return Promise<{items, roads, bbox, ms, bytes, cached}>
   *   🔴 失敗は reject（e.kind = 'wide' | 'none' | 'net'）。
   *      呼び出し側は**名称なぞり出しだけ**を止め、作図は続けること（§23-6）。
   */
  function fetchNames(bounds, cats, opts) {
    var cs = normCats(cats);
    // 🔒 §22-av: 路線番号（国道・都道府県道）も一緒に取るか。分類とは別の軸
    var wantRoutes = !!(opts && opts.routes);
    if (!cs._n && !wantRoutes) return Promise.reject(err('none', '分類が選ばれていません'));

    var hit = findCache(bounds, cs, wantRoutes);
    if (hit) {
      return Promise.resolve({ items: hit.data.items, roads: hit.data.roads,
                               routes: hit.data.routes || [],
                               bbox: hit.bbox, ms: hit.ms, bytes: hit.bytes,
                               cached: true });
    }

    var sp = spanMeters(bounds);
    if (sp.w > MAX_SPAN_M || sp.h > MAX_SPAN_M) {
      return Promise.reject(err('wide', '範囲が広すぎます'));
    }

    var bbox = padBounds(bounds, PAD);
    var q = buildQuery(bbox, cs, wantRoutes);
    if (!q) return Promise.reject(err('none', '分類が選ばれていません'));

    var t0 = (global.performance && performance.now) ? performance.now() : Date.now();
    var idx = 0;
    function attempt() {
      if (idx >= ENDPOINTS.length) throw err('net', '地図データの取得に失敗しました');
      var url = ENDPOINTS[idx++];
      return post(url, q).then(function (r) {
        r.endpoint = url;
        return r;
      }, function (e) {
        if (idx < ENDPOINTS.length) return attempt();   // 予備ミラーへ（§23-6）
        throw e;
      });
    }

    return Promise.resolve().then(attempt).then(function (r) {
      var now = (global.performance && performance.now) ? performance.now() : Date.now();
      var ms = Math.round(now - t0);
      var data = parse(r.json, cs);
      var e = { cats: cs, routes: wantRoutes, bbox: bbox, data: data,
                ms: ms, bytes: r.bytes };
      putCache(e);
      _last = { ms: ms, bytes: r.bytes, endpoint: r.endpoint,
                points: data.items.length, ways: data.roads.length,
                routes: data.routes.length };
      return { items: data.items, roads: data.roads, routes: data.routes,
               bbox: bbox, ms: ms, bytes: r.bytes, cached: false,
               endpoint: r.endpoint };
    });
  }

  global.OSM = {
    ENDPOINTS: ENDPOINTS,
    ATTRIBUTION: ATTRIBUTION,
    CATS: CATS,
    CAT_BY_ID: CAT_BY_ID,
    MAX_SPAN_M: MAX_SPAN_M,
    PAD: PAD,
    fetchNames: fetchNames,
    mergeRoads: mergeRoads,
    clearCache: clearCache,
    cacheSize: function () { return _cache.length; },
    lastStats: function () { return _last; },
    /* 単体で試せるように出しておく（実測・回帰用） */
    _buildQuery: buildQuery,
    _parse: parse,
    _spanMeters: spanMeters
  };
})(typeof window !== 'undefined' ? window : this);
