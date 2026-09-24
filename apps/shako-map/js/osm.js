/* osm.js — OpenStreetMap の名前の取得層（自前の名前タイル）／正典 §23-6・§26 Step 8・§30-44
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * ここは「名称の分類なぞり出し（§23-5）」のデータ源のうち、
 * **地理院ベクトルタイルに無い物**（交差点名・お店・会社・バス停・細街路の道路名）
 * を取りに行く層。描画・なぞり出しの判定は一切持たない（reveal.js の仕事）。
 *
 * 設計の要点:
 *  1. 🔒 §30-44（2026-09-24）: 名前は**自前の抜き出しデータ**（OSM の pbf から
 *     tools/names_tiles/build.py が作った z13 のタイル・Cloudflare R2・NAMES_BASE）から取る。
 *     タイルの中身は `{elements:[…]}` の形なので、分類・名寄せは下の parse() がそのまま読む。
 *     抜き出す集合の定義は正典 §30-44-2 A と build.py にある（分類の表 pointCat はここ1か所）。
 *  2. 🔒 §30-44-9 3（2026-09-24 オーナー決定 B 案）: 名前の取り方は**自前のタイルだけ**
 *     （公開の問い合わせ API を叩く経路・予備ミラー・範囲ごとのキャッシュは外した）。
 *  3. 🔴 **落ちても作図は止めない**（§23-6 / §20-6 fail-open と同思想）。
 *     ここは Promise を reject するだけ。呼び出し側は名前なしで作図を続ける。
 *     🔒 §30-44-9 1: 失敗は利用者に**何も見せない**（取り直しは裏で・次に地図を動かせばまた取りに行く）。
 *  4. 🔒 §30-44-9 2: manifest（今どの版のタイルを読むか）は**取得のたびに確かめる**
 *     （読めていなければその場で読み直す・読めなければ今回は名前を取らない＝'net'）。
 *
 * ライセンス（§23-6）: ODbL。書き出し画像は Produced Work なので出典表記のみで商用可。
 *   → 実体化したら ATTRIBUTION を**そのシートの出典**へ足す（§24-3 出典はシート単位）。
 */
(function (global) {
  'use strict';

  var ATTRIBUTION = '© OpenStreetMap contributors';

  var PAD = 0.25;             // 表示範囲をこの割合だけ広げて取る（パンの取り直しを減らす）

  /* ================= 🔒 §30-44（2026-09-24 オーナー決定「D すぐやる」）: 自前の名前データ =================
   * OSM の抜き出し（tools/names_tiles/build.py）を Cloudflare R2 に置き、**z13 のタイル**で取る。
   * 🔒 §30-44-7 2: 定数はここ1か所。 */
  var NAMES_BASE = 'https://names.solodev-lab.com';
  var NAMES_Z = 13;
  /* 🔒 §30-44-7 2 / 4: 1回に取るタイルの上限（4×4 枚＝1辺 12km・🔒 オーナー決定）。
   * 超えたら名前は取らない（'wide'）。 */
  var NAMES_MAX_TILES = 16;
  /* 🔒 §30-44-7 7: タイル単位のキャッシュの上限（案件内・東京中心でも 50MB 程度） */
  var NAMES_TILE_CACHE_MAX = 64;
  /* 🔒 §30-44-7 5: 通信の失敗（ネットワーク・5xx）は 1 秒→3 秒→9 秒待って**黙って** 3 回まで
   * 取り直す（最初の1回＋取り直し 3 回）。利用者向けには何も出さない（🔒 §30-43-5）。 */
  var NAMES_RETRY_MS = [1000, 3000, 9000];
  var NAMES_CONC = 6;         // 🔒 §30-44-7 5: 同時接続の上限
  /* 1回の取得の打ち切り（ms）。止まったままの接続で「描画中…」が終わらないのを防ぐ
   * （打ち切りも通信の失敗＝上の取り直しに乗る）。🔒 §30-44-9 2: manifest の読み込みにも使う。 */
  var NAMES_FETCH_MS = 15000;

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
  /* 🔒 §30-21-2（2026-09-13）: 既存6分類＋**施設・公園／建物名**の8分類。
   * 並びは正典の表のとおり（pointCat が上から順に1つへ決める）。 */
  var CATS = [
    { id: 'public',   ja: '公共的建物', dot: true,  size: 'medium', gsi: true,  osm: true },
    { id: 'crossing', ja: '交差点名',   dot: true,  size: 'medium', gsi: false, osm: true,
      mark: 'signal' },
    { id: 'shop',     ja: '大きなお店', dot: true,  size: 'small',  gsi: false, osm: true },
    { id: 'office',   ja: '会社名',     dot: true,  size: 'small',  gsi: false, osm: true },
    { id: 'bus',      ja: 'バス停',     dot: true,  size: 'small',  gsi: false, osm: true,
      mark: 'bus' },
    { id: 'road',     ja: '道路名',     dot: false, size: 'medium', gsi: true,  osm: true },
    /* 🔒 §30-21-2 新2分類。印は●（駅の印は今のところ無いので●のまま）。
     * 🔴 road より後ろに置く＝名前の置き場所の取り合いで既存6分類を押しのけない
     *    （buildAutoNames は CATS の順に out へ積む）。 */
    { id: 'facility', ja: '施設・公園', dot: true,  size: 'small',  gsi: false, osm: true },
    { id: 'building', ja: '建物名',     dot: true,  size: 'small',  gsi: false, osm: true }
  ];

  var CAT_BY_ID = Object.create(null);
  CATS.forEach(function (c) { CAT_BY_ID[c.id] = c; });

  /* ================= 小物 ================= */

  function num(v) { return typeof v === 'number' && isFinite(v); }

  function padBounds(b, k) {
    var dy = (b.north - b.south) * k, dx = (b.east - b.west) * k;
    return { south: b.south - dy, north: b.north + dy,
             west: b.west - dx, east: b.east + dx };
  }

  function inBounds(lat, lng, b) {
    return lat >= b.south && lat <= b.north && lng >= b.west && lng <= b.east;
  }

  /** 有効な分類だけの素直な集合にする（未知の id は捨てる）。_n … 要求された分類の数 */
  function normCats(cats) {
    var out = Object.create(null), n = 0;
    CATS.forEach(function (c) {
      if (cats && cats[c.id]) { out[c.id] = true; n++; }
    });
    out._n = n;
    return out;
  }

  /* ================= タイルの中身 → 名称 =================
   * 🔒 §30-44-2 A: タイルには ①名前のある node と way/relation の中心点（`center`）
   * ②名前のある道路の way（`geometry`＝線の形ごと）③国道・県道の路線 relation
   * （`members` の線の形・タイルの矩形で切ってある）が入っている。
   */

  /**
   * 点の分類（🔒 §30-21-2 の表）。
   * 🔴 **順番が意味を持つ**。1つの物が複数のタグを持つ時は表の**上から**1つに決める
   *    （例: `amenity=school` かつ `building=school` → 公共的建物）。
   * @return null（分類なし）か {cat, sub, mark}
   *   sub  … 分類を決めたタグの**値**。格の表（shozaizu.js の POI_PRIO 系）が読む。
   *          🔴 新2分類は `キー:値`（'leisure:park'）＝別のキーで同じ値が来ても混ざらない。
   *   mark … その物だけ分類の既定の印と違う時（信号の無い交差点＝●）。
   */
  function pointCat(tg) {
    /* ① 公共的建物（他の目印）＝ amenity 全部（従来どおり） */
    if (tg.amenity) return { cat: 'public', sub: tg.amenity };
    /* ② 交差点名。信号あり＝信号機の印／信号なし・高速の出入口＝● */
    if (tg.highway === 'traffic_signals') {
      return { cat: 'crossing', sub: 'traffic_signals' };
    }
    if (tg.junction === 'yes') {
      return { cat: 'crossing', sub: 'junction', mark: 'dot' };
    }
    if (tg.highway === 'motorway_junction') {
      return { cat: 'crossing', sub: 'motorway_junction', mark: 'dot' };
    }
    /* ③ お店 */
    if (tg.shop) return { cat: 'shop', sub: tg.shop };
    /* ④ 会社名 */
    if (tg.office) return { cat: 'office', sub: tg.office };
    if (tg.craft) return { cat: 'office', sub: tg.craft };
    if (tg.industrial) return { cat: 'office', sub: tg.industrial };
    /* ⑤ バス停 */
    if (tg.highway === 'bus_stop') return { cat: 'bus', sub: 'bus_stop' };
    if (tg.public_transport === 'platform' && tg.bus === 'yes') {
      return { cat: 'bus', sub: 'platform' };
    }
    /* ⑥ 施設・公園（🔒 §30-21-2 新） */
    if (tg.power) return { cat: 'facility', sub: 'power:' + tg.power };
    if (tg.man_made) return { cat: 'facility', sub: 'man_made:' + tg.man_made };
    if (tg.leisure) return { cat: 'facility', sub: 'leisure:' + tg.leisure };
    if (tg.landuse) return { cat: 'facility', sub: 'landuse:' + tg.landuse };
    if (tg.healthcare) return { cat: 'facility', sub: 'healthcare:' + tg.healthcare };
    if (tg.railway === 'station' || tg.railway === 'halt') {
      return { cat: 'facility', sub: 'railway:' + tg.railway };
    }
    if (tg.public_transport === 'station') {
      return { cat: 'facility', sub: 'public_transport:station' };
    }
    if (tg.waterway) return { cat: 'facility', sub: 'waterway:' + tg.waterway };
    if (tg.natural === 'water') return { cat: 'facility', sub: 'natural:water' };
    /* ⑦ 建物名（🔒 §30-21-2 新・**棟名を含む**） */
    if (tg.building) return { cat: 'building', sub: 'building:' + tg.building };
    if (tg.tourism) return { cat: 'building', sub: 'tourism:' + tg.tourism };
    if (tg.historic) return { cat: 'building', sub: 'historic:' + tg.historic };
    /* 🔒 §30-21-2「`brand` だけの店」＝上のどれにも当たらず brand だけ持つ物。
     * 🔴 表の3行目（お店）だが、**他のどれかに当たる物はそちらが先**（表の上から）
     *    なので、判定はここ（最後）に置く。 */
    if (tg.brand) return { cat: 'shop', sub: '' };
    return null;
  }

  /** 英字（ASCII）だけの文字列か。ソースに制御文字を入れないための小物 */
  function isAscii(s) {
    for (var i = 0; i < s.length; i++) { if (s.charCodeAt(i) > 127) return false; }
    return true;
  }

  /**
   * 🔒 §30-21-1 名前の取り方: `name` → 無ければ `name:ja` → 無ければ `brand`。
   * 🔴 `name` が**英字だけ**で `name:ja` がある時は `name:ja` を優先する
   *    （所在図は日本語の紙なので、"Nagoya Station" より「名古屋駅」）。
   */
  function pickName(tg) {
    var n = tg.name, ja = tg['name:ja'];
    if (n && ja && isAscii(n)) return ja;
    return n || ja || tg.brand || '';
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

  /**
   * 中身 → {items, roads, routes, counts}。
   * 🔒 §30-21-1: 点は**分類で絞らずに全部**作る（タイルは全部持っているので、
   * ここで捨てるとキャッシュに穴が空く）。要求された分類だけにするのは fetchNames。
   * 🔒 §30-44-9 3: タイルは切っていない（件数の上限が無い）ので「省いたか」の印は持たない。
   * counts … 実測の報告用（node と、`center` を持つ way/relation の数）。
   */
  function parse(json) {
    var els = (json && json.elements) || [];
    var items = [], roads = [], routes = [], seenPt = Object.create(null),
        seenWay = Object.create(null), i, nNode = 0, nArea = 0;
    for (i = 0; i < els.length; i++) {
      var e = els[i], tg = e.tags || {};
      if (e.type === 'node') nNode++;
      else if ((e.type === 'way' || e.type === 'relation') && e.center) nArea++;
      var name = pickName(tg);
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
          /* 🔴 矩形で切った線は切れ目に **null** を挟んである（build.py clip_geom・
           * 実測 2026-09-06）。素直に読むと null.lat で落ちるので必ず弾く。 */
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
      /* 道路（線の形ごと入っている way）は geometry を持つ。
       * 点の分類（中心点）と取り違えないよう geometry の有無で分ける。 */
      if (e.type === 'way' && e.geometry && e.geometry.length >= 2 && tg.highway) {
        if (seenWay[e.id]) continue;
        seenWay[e.id] = true;
        roads.push({ name: name, geom: e.geometry, id: e.id });
        continue;
      }
      var pc = pointCat(tg);
      if (!pc) continue;
      var cat = pc.cat;
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
      /* 🔒 §30-21-2: sub と印（mark）の出どころは pointCat の1か所だけ。
       * 🔴 mark は「その物だけ分類の既定の印と違う」時に入る（信号の無い交差点＝'dot'）。
       *    描く側は it.mark || CATS の mark で読む（表示文字では判定しない・注意②）。 */
      var item = { cat: cat, name: name, lat: ll.lat, lng: ll.lng, src: 'osm',
                   sub: pc.sub || '' };
      if (pc.mark) item.mark = pc.mark;
      items.push(item);
    }
    return { items: items, roads: roads, routes: routes,
             counts: { node: nNode, area: nArea } };
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

  var _last = null;       // 直近の実測（実装メモ・オーナー確認用）

  /* 🔒 §30-44-7 7: タイル単位のキャッシュ（案件内）。key 'x/y' → {els, bytes, empty}。
   * 🔴 空タイル（404）も正常系なのでキャッシュする（取り直さない）。失敗は入れない
   *    （🔒 §30-44-9 1: 失敗は覚えない＝次に地図を動かした時にまた取りに行く）。
   * 🔴 入れた順に古い物から捨てる（NAMES_TILE_CACHE_MAX）。 */
  var _tileCache = Object.create(null);
  var _tileKeys = [];
  var _tileInflight = Object.create(null);   // 取りに行っている最中のタイル（二重に取らない）
  /* 同じタイルの組を続けて読んだ時は、連結と parse を省く（設定盤の作り直しは毎回同じ範囲） */
  var _merged = null;                        // {sig, data, bytes}

  /* 🔒 §30-44-7 7: 案件を開いた時にタイルのキャッシュを空にする */
  function clearCache() {
    _tileCache = Object.create(null);
    _tileKeys.length = 0;
    _merged = null;
  }

  function err(kind, msg) {
    var e = new Error(msg);
    e.kind = kind;
    return e;
  }

  /**
   * 🔒 §30-21-1: キャッシュ（＝取った物ぜんぶ）から、要求された分類だけを渡す。
   * 🔴 取る時に絞らず**渡す時に絞る**のが肝。重ね表示（namelay・交差点名とバス停だけ）が
   *    取った物を、所在図の生成（全分類）がそのまま使い回せる。
   */
  function pickCats(items, cs) {
    var out = [];
    for (var i = 0; i < items.length; i++) {
      if (cs[items[i].cat]) out.push(items[i]);
    }
    return out;
  }

  /** 実測の報告用（lastStats）。分類ごとの点数 */
  function countByCat(items) {
    var m = Object.create(null);
    CATS.forEach(function (c) { m[c.id] = 0; });
    for (var i = 0; i < items.length; i++) {
      if (m[items[i].cat] !== undefined) m[items[i].cat]++;
    }
    return m;
  }

  /* ================= 🔒 §30-44-7: 自前の名前データ（タイルの経路） ================= */

  function nowMs() {
    return (global.performance && performance.now) ? performance.now() : Date.now();
  }

  function waitMs(ms) {
    return new Promise(function (res) { setTimeout(res, ms); });
  }

  var _manifest = null;       // {built, tiles, source, date}｜null（＝まだ読めていない）
  var _manifestP = null;      // 🔒 §30-44-9 2: 読みに行っている最中の Promise（相乗り用・終われば null）
  var _manifestFns = [];      // 🔒 §30-44-9 2: 読めた時に呼ぶ（app.js が右下の日付を書き直す）

  /** 🔒 §30-44-9 2: manifest が読めたことを知らせる（受け手の失敗は握る＝取得を止めない） */
  function notifyManifest() {
    for (var i = 0; i < _manifestFns.length; i++) {
      try { _manifestFns[i](); } catch (e) { /* 画面側の失敗で名前の取得を止めない */ }
    }
  }

  /**
   * 🔒 §30-44-7 3 / 🔒 §30-44-9 2（2026-09-24 オーナー決定）: manifest を読む。
   * ・読めていれば（_manifest）そのまま返す＝通信しない
   * ・読めていなければ**その場で読み直す**（起動時に失敗していても、次の取得で取り戻す）
   * ・同時に何本呼ばれても通信は1回（読みに行っている最中の Promise に相乗り）
   * ・取れない時（通信・404・形が違う・打ち切り）は null ＝今回は名前を取らない（呼び出し側が
   *   'net' にする）。失敗は覚えない＝次の呼び出しでまた読みに行く。利用者向けには何も出さない。
   * @return Promise<manifest|null>
   */
  function loadManifest() {
    if (_manifest) return Promise.resolve(_manifest);
    if (_manifestP) return _manifestP;
    if (typeof fetch !== 'function') return Promise.resolve(null);
    var ctl = (typeof AbortController !== 'undefined') ? new AbortController() : null;
    var timer = setTimeout(function () { if (ctl) ctl.abort(); }, NAMES_FETCH_MS);
    var opt = { cache: 'no-cache' };
    if (ctl) opt.signal = ctl.signal;
    _manifestP = fetch(NAMES_BASE + '/manifest.json', opt).then(function (r) {
      if (!r.ok) throw err('net', 'manifest ' + r.status);
      return r.json();
    }).then(function (m) {
      /* 🔴 形を確かめる: tiles に {x}{y} があり、ズームがこちらの前提（z13）と同じ物だけ使う
       * （ズームが違うと 16 枚＝12km の上限が崩れる）。 */
      if (!m || typeof m.tiles !== 'string' || m.tiles.indexOf('{x}') < 0
          || m.tiles.indexOf('{y}') < 0 || Number(m.z) !== NAMES_Z) {
        return null;
      }
      var src = String(m.source || '');
      var d = /(\d{4}-\d{2}-\d{2})/.exec(src);
      _manifest = { built: String(m.built || ''), tiles: m.tiles, source: src,
                    /* 🔒 §30-44-7 13: 元データ（pbf）の日付＝画面右下の「… 時点」 */
                    date: d ? d[1] : '' };
      return _manifest;
    }).catch(function () {
      return null;
    }).then(function (v) {
      clearTimeout(timer);
      _manifestP = null;
      if (v) notifyManifest();
      return v;
    });
    return _manifestP;
  }

  /**
   * 🔒 §30-44-9 2: manifest が読めた時に呼ぶ関数を足す（既に読めていればすぐ1回呼ぶ）。
   * 起動時に読めず、後の取得で読み直せた時にも右下の日付が出るようにするため。
   */
  function onManifest(fn) {
    if (typeof fn !== 'function') return;
    _manifestFns.push(fn);
    if (_manifest) Promise.resolve().then(function () { try { fn(); } catch (e) { /* 同上 */ } });
  }

  /** タイル座標の変換（🔒 §30-44-2 C1: GSI の mercator 変換を再利用する） */
  function tileMath() {
    var G = global.GSI;
    return (G && G.lonLatToTile && G.tileToLonLat) ? G : null;
  }

  /** 矩形に重なる z13 タイルの範囲 */
  function tileRange(b) {
    var G = tileMath(), n = Math.pow(2, NAMES_Z);
    var a = G.lonLatToTile(b.west, b.north, NAMES_Z);
    var c = G.lonLatToTile(b.east, b.south, NAMES_Z);
    function cl(v) { return Math.max(0, Math.min(n - 1, Math.floor(v))); }
    var r = { x0: cl(a.x), x1: cl(c.x), y0: cl(a.y), y1: cl(c.y) };
    r.n = (r.x1 - r.x0 + 1) * (r.y1 - r.y0 + 1);
    return r;
  }

  /**
   * 🔒 §30-44-7 4: 取るタイルの範囲を決める。PAD を足した矩形に重なる z13 タイル →
   * 16 枚超なら PAD 無しで数え直し → それでも超えたら null（＝'wide'・名前は取らない）。
   */
  function pickRange(bounds) {
    var r = tileRange(padBounds(bounds, PAD));
    if (r.n > NAMES_MAX_TILES) r = tileRange(bounds);
    return (r.n > NAMES_MAX_TILES) ? null : r;
  }

  /**
   * 🔒 §30-44-9 3: その範囲の名前を1回で取れるか（タイルの上限 16 枚＝1辺 12km に収まるか）。
   * shozaizu.js fetchOsmNames が「取得範囲（画面∪枠＋8%）が広すぎる時だけ枠に戻す」判定に使う
   * （旧・4km の判定 §30-25-3 1 の置き換え。判定は fetchNames の 'wide' と同じ pickRange）。
   */
  function namesFit(bounds) {
    if (!bounds || !tileMath()) return true;
    return !!pickRange(bounds);
  }

  function putTile(key, t) {
    if (!(key in _tileCache)) _tileKeys.push(key);
    _tileCache[key] = t;
    while (_tileKeys.length > NAMES_TILE_CACHE_MAX) delete _tileCache[_tileKeys.shift()];
  }

  /** 1枚を1回だけ取る。404＝空タイル（正常）。e.retry＝取り直してよい失敗か */
  function getTileOnce(url) {
    var ctl = (typeof AbortController !== 'undefined') ? new AbortController() : null;
    var timer = setTimeout(function () { if (ctl) ctl.abort(); }, NAMES_FETCH_MS);
    return fetch(url, ctl ? { signal: ctl.signal } : undefined).then(function (r) {
      if (r.status === 404) return null;                 // 中身が無いタイル＝書いていない
      if (!r.ok) {
        var e = err('net', 'names ' + r.status);
        e.retry = (r.status >= 500 || r.status === 429);  // 5xx・混雑は取り直す
        throw e;
      }
      return r.text();
    }).then(function (txt) {
      clearTimeout(timer);
      if (txt === null) return { els: [], bytes: 0, empty: true };
      var json;
      try { json = JSON.parse(txt); }
      catch (e0) {
        var ep = err('net', '応答を読めませんでした');
        ep.retry = true;
        throw ep;
      }
      return { els: (json && Array.isArray(json.elements)) ? json.elements : [],
               bytes: txt.length, empty: false };
    }, function (e) {
      clearTimeout(timer);
      if (e && e.kind) throw e;
      var en = err('net', (e && e.message) || '通信に失敗しました');
      en.retry = true;                                   // ネットワーク・打ち切り
      throw en;
    });
  }

  /**
   * 🔒 §30-44-7 5 / 7: 1枚を取る（キャッシュ→取りに行っている最中の物→取得）。
   * 通信の失敗は NAMES_RETRY_MS の間隔で黙って取り直す。駄目なら reject（'net'）。
   * @param st 実測の控え（cached / fetched / tries を数える）
   */
  function getTile(m, x, y, st) {
    var key = x + '/' + y;
    if (key in _tileCache) { st.cached++; return Promise.resolve(_tileCache[key]); }
    if (_tileInflight[key]) { st.fetched++; return _tileInflight[key]; }
    st.fetched++;
    var url = NAMES_BASE + '/' + m.tiles.replace('{x}', x).replace('{y}', y);
    var tries = 0;
    function go() {
      tries++;
      return getTileOnce(url).catch(function (e) {
        var i = tries - 1;
        if (!e || !e.retry || i >= NAMES_RETRY_MS.length) throw e;
        return waitMs(NAMES_RETRY_MS[i]).then(go);
      });
    }
    var p = go().then(function (t) {
      delete _tileInflight[key];
      putTile(key, t);
      if (tries > st.tries) st.tries = tries;
      return t;
    }, function (e) {
      delete _tileInflight[key];
      if (tries > st.tries) st.tries = tries;
      throw e;
    });
    _tileInflight[key] = p;
    return p;
  }

  /** 🔒 §30-44-7 5: 同時接続を n 本までに絞って順に流す（1つでも失敗したら reject） */
  function runPool(jobs, n) {
    return new Promise(function (resolve, reject) {
      var out = new Array(jobs.length), next = 0, done = 0, failed = false;
      if (!jobs.length) { resolve(out); return; }
      function run() {
        if (failed || next >= jobs.length) return;
        var i = next++;
        jobs[i]().then(function (v) {
          out[i] = v;
          done++;
          if (done === jobs.length) resolve(out); else run();
        }, function (e) {
          if (!failed) { failed = true; reject(e); }
        });
      }
      for (var k = 0; k < Math.min(n, jobs.length); k++) run();
    });
  }

  /**
   * 🔒 §30-44-7 6: 取れたタイルの elements を連結する。
   * 🔴 relation は **id ごとに1つに寄せる**（路線はタイルの矩形で切った線がタイルごとに
   *    入っている＝members の geometry を連結。10% 余白の重なりはそのまま・描画に害なし）。
   * 🔴 キャッシュの中身は書き換えない（relation は写してから members を足す）。
   * 道路の way の重複（線が掛かるタイル全部に入っている）は parse の seenWay が詰める。
   */
  function mergeTiles(tiles) {
    var out = [], rel = Object.create(null), i, j;
    for (i = 0; i < tiles.length; i++) {
      var els = tiles[i].els;
      for (j = 0; j < els.length; j++) {
        var e = els[j];
        if (!e || e.type !== 'relation') { if (e) out.push(e); continue; }
        var have = rel[e.id];
        if (!have) {
          have = {};
          for (var k in e) { if (Object.prototype.hasOwnProperty.call(e, k)) have[k] = e[k]; }
          have.members = (e.members || []).slice();
          rel[e.id] = have;
          out.push(have);
        } else {
          if (e.members && e.members.length) have.members = have.members.concat(e.members);
          if (!have.center && e.center) have.center = e.center;
        }
      }
    }
    return out;
  }

  /**
   * 🔒 §30-44-7 1〜7: タイルの経路（範囲 r は pickRange で決めた物）。
   * ①タイルごとに取る（キャッシュ・404＝空・通信の失敗は黙って取り直す）
   * ②連結（relation は id で寄せる）→ parse → 分類を絞る
   */
  function fetchNamesTiles(r, cs, wantRoutes, m) {
    var G = tileMath();
    var t0 = nowMs();
    var st = { cached: 0, fetched: 0, tries: 0 };
    var keys = [], jobs = [];
    for (var y = r.y0; y <= r.y1; y++) {
      for (var x = r.x0; x <= r.x1; x++) {
        keys.push(x + '/' + y);
        jobs.push((function (xx, yy) {
          return function () { return getTile(m, xx, yy, st); };
        })(x, y));
      }
    }
    var nw = G.tileToLonLat(r.x0, r.y0, NAMES_Z);
    var se = G.tileToLonLat(r.x1 + 1, r.y1 + 1, NAMES_Z);
    var bbox = { west: nw.lon, north: nw.lat, east: se.lon, south: se.lat };

    return runPool(jobs, NAMES_CONC).then(function (tiles) {
      var sig = m.built + '|' + keys.join(',');
      var data, bytes;
      if (_merged && _merged.sig === sig) {
        data = _merged.data; bytes = _merged.bytes;
      } else {
        bytes = 0;
        for (var i = 0; i < tiles.length; i++) bytes += tiles[i].bytes;
        data = parse({ elements: mergeTiles(tiles) });
        _merged = { sig: sig, data: data, bytes: bytes };
      }
      var ms = Math.round(nowMs() - t0), nEmpty = 0;
      for (var ei = 0; ei < tiles.length; ei++) { if (tiles[ei].empty) nEmpty++; }
      _last = { route: 'tiles', ms: ms, bytes: bytes, built: m.built,
                tiles: keys.length, cachedTiles: st.cached, fetchedTiles: st.fetched,
                emptyTiles: nEmpty, tries: st.tries,
                points: data.items.length, ways: data.roads.length,
                routes: data.routes.length, byCat: countByCat(data.items),
                nodes: data.counts.node, areas: data.counts.area };
      return { items: pickCats(data.items, cs),
               roads: cs.road ? data.roads : [],
               routes: wantRoutes ? data.routes : [],
               bbox: bbox, ms: ms, bytes: bytes,
               cached: st.cached === keys.length };
    });
  }

  /**
   * 🔒 §30-44-7 4: 名前を取れる範囲の1辺（km・丸め）。結果の1行の数字の出どころ。
   * 4×4 枚（NAMES_MAX_TILES）はずれて掛かっても 3 枚分の辺は必ず入る
   * ＝ 3 × z13 の1辺（その緯度で ≈4km）≈ 12km。
   * 🔴 文言の数字はここから組む（画面の文字で分岐しない）。
   */
  function namesSpanKm(lat) {
    var la = num(lat) ? lat : 35;
    var tileKm = 40075.016686 * Math.cos(la * Math.PI / 180) / Math.pow(2, NAMES_Z);
    return Math.round((Math.floor(Math.sqrt(NAMES_MAX_TILES)) - 1) * tileKm);
  }

  /**
   * 表示範囲の名称を取る。
   * @param bounds {west,south,east,north}（＝いま画面に写っている範囲）
   * @param cats   {public:true, road:true, ...}
   * @return Promise<{items, roads, routes, bbox, ms, bytes, cached}>
   *   🔴 失敗は reject（e.kind = 'wide' | 'none' | 'net'）。
   *      呼び出し側は**名称だけ**を止め、作図は続けること（§23-6）。
   * 🔒 §30-44-9: ①範囲がタイルの上限を超えたら 'wide'（通信しない）②manifest を確かめる
   *    （読めていなければその場で読み直す・読めなければ 'net'）③自前のタイルを取る。
   */
  function fetchNames(bounds, cats, opts) {
    var cs = normCats(cats);
    // 🔒 §22-av: 路線番号（国道・都道府県道）も一緒に取るか。分類とは別の軸
    var wantRoutes = !!(opts && opts.routes);
    if (!cs._n && !wantRoutes) return Promise.reject(err('none', '分類が選ばれていません'));
    if (!tileMath()) return Promise.reject(err('net', 'タイルの計算ができません'));
    var r = pickRange(bounds);
    if (!r) return Promise.reject(err('wide', '範囲が広すぎます'));
    // 🔒 §30-44-9 2: manifest は取得のたびに確かめる（読めていれば通信しない）
    return loadManifest().then(function (m) {
      if (!m) throw err('net', '名前データの版を読めませんでした');
      return fetchNamesTiles(r, cs, wantRoutes, m);
    });
  }

  global.OSM = {
    ATTRIBUTION: ATTRIBUTION,
    CATS: CATS,
    CAT_BY_ID: CAT_BY_ID,
    PAD: PAD,
    fetchNames: fetchNames,
    mergeRoads: mergeRoads,
    clearCache: clearCache,
    lastStats: function () { return _last; },
    /* 🔒 §30-44-7: 自前の名前データ（定数・manifest の読み口） */
    NAMES_BASE: NAMES_BASE,
    NAMES_Z: NAMES_Z,
    NAMES_MAX_TILES: NAMES_MAX_TILES,
    /** manifest の読み込み（読めていなければ読みに行く・結果を待てる）。null＝読めなかった */
    ready: loadManifest,
    /** 🔒 §30-44-9 2: manifest が読めた時に呼ぶ関数を足す（右下の日付の書き直し用） */
    onManifest: onManifest,
    /** 読み込んだ manifest の写し（{built, tiles, source, date}）。無ければ null */
    manifest: function () {
      return _manifest ? { built: _manifest.built, tiles: _manifest.tiles,
                           source: _manifest.source, date: _manifest.date } : null;
    },
    namesSpanKm: namesSpanKm,
    namesFit: namesFit,
    tileCacheSize: function () { return _tileKeys.length; },
    /* 単体で試せるように出しておく（実測・回帰用） */
    _parse: parse,
    _mergeTiles: mergeTiles
  };

  /* 🔒 §30-44-7 3: 起動時に1回 manifest を読みに行く（ブラウザの時だけ）。
   * 🔒 §30-44-9 2: ここで読めなくても、名前を取る時に読み直す（fetchNames）。 */
  if (typeof window !== 'undefined' && typeof fetch === 'function') loadManifest();
})(typeof window !== 'undefined' ? window : this);
