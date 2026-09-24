/* gsi.js — 国土地理院(GSI)のオープンデータ取得層
 *
 * 車庫証明 所在図・配置図メーカー
 * 正典 §1-4「所在図はオープンデータから自前で線画を描く」の土台。
 * Google の画像は一切触らない。ここで取れるのは地理院のベクトルデータのみ。
 *
 * Step 0 スパイク(2026-08-16)で実測・確定した値を定数として持つ。
 */
(function (global) {
  'use strict';

  /* ================= エンドポイント（Step 0 で実測確定） ================= */

  // 最適化ベクトルタイル optimal_bvmap-v1。ZL4-16 提供、ZL17 は z16 の overzoom。
  // CORS: Origin ヘッダがある時のみ Access-Control-Allow-Origin:* を返す
  //       (Vary: Origin)。ブラウザの fetch はそのまま通る。実測済み。
  var TILE_URL = 'https://cyberjapandata.gsi.go.jp/xyz/optimal_bvmap-v1/{z}/{x}/{y}.pbf';
  var TILE_MIN_ZOOM = 4;
  var TILE_MAX_ZOOM = 16;   // 17 以上は 404

  // 住所検索。キー不要・CORS 可。番地レベルでズレるのでピン微調整前提(正典 §2)。
  var GEOCODE_URL = 'https://msearch.gsi.go.jp/address-search/AddressSearch?q=';

  // 淡色地図ラスタ。正典 §5 のフォールバック「背景に地理院地図を含める」用。
  var RASTER_PALE_URL = 'https://cyberjapandata.gsi.go.jp/xyz/pale/{z}/{x}/{y}.png';

  // 出典表記。国土地理院コンテンツ利用規約(PDL1.0)は
  //   ①出典の記載 ②編集・加工したことの記載 ③地理院が作ったように見せない
  // を求めるため、「加工して作成」まで書く。
  var ATTRIBUTION = '出典：国土地理院ベクトルタイル（加工して作成）';
  var ATTRIBUTION_RASTER = '出典：地理院タイル（淡色地図）';
  var ATTRIBUTION_URL = 'https://maps.gsi.go.jp/development/ichiran.html';

  /* ================= 注記(Anno)の vt_code 分類 =================
   * 出典: optbv_featurecodes.xlsx (国土地理院)
   * Step 0 の実測で判明した重要点:
   *   - 7101/7102/7103/7201 等の測地・標高系は "23.4" のような数値文字列を
   *     大量に吐く。所在図では純粋なノイズなので必ず捨てる。
   *   - 6311-6327 の植生(田・畑・広葉樹林…)は地方部で注記の 8〜9 割を占める。
   *     既定で捨てる。
   *   - 880-899 は仕様表の ZL16 列が "―" だが、実際には z16 タイルに入っている
   *     (警察署・郵便局・消防署・学校・病院 等)。目標物として最重要なので拾う。
   */

  // 捨てる: 測地基準点・標高・水深・等高線数値
  var ANNO_NOISE = [7101, 7102, 7103, 7201, 7221, 7701, 7711, 7352, 7372,
                    7601, 7621];

  // 捨てる(既定): 耕地・未耕地植生
  var ANNO_VEGETATION = [6311, 6312, 6313, 6314, 6321, 6322, 6323, 6324,
                         6325, 6326, 6327];

  // 拾う: 道路名・国道番号・道路施設
  var ANNO_ROADNAME = [411, 412, 413, 2901, 2903, 2904];

  // 拾う: 鉄道路線名・駅名・鉄道構造物
  var ANNO_RAILNAME = [421, 422, 423];

  // 拾う: 地名(市区町村・町字・丁目・集落)
  var ANNO_PLACE = [110, 120, 210, 220, 800];

  // 拾う: 目標物(所在図で一番効く)
  var ANNO_LANDMARK = [
    // 官公署・公共施設(シンボル付き)
    3201, 3202, 3203, 3204, 3205, 3206, 3211, 3212, 3213, 3214, 3215,
    3216, 3217, 3218, 3221, 3231, 3232, 3241, 3242, 3243, 3244,
    // 国・地方の機関、学校、病院、郵便局 ほか(仕様表 ZL16="―" だが実在)
    860, 870, 880, 881, 882, 883, 884, 885, 886, 887, 888, 889, 890, 899,
    // 名称注記
    611, 612, 613, 615, 621, 631, 632, 633, 634, 651, 653, 661, 662,
    671, 673, 681,
    // 土地利用・史跡・公園・墓地・城跡
    531, 532, 534, 6301, 6341, 6342,
    // 構造物
    511, 4101, 4102, 4104, 4105, 8103, 8105
  ];

  // 拾う(任意): 自然地名。河川名は所在図の目印になるので既定 ON。
  var ANNO_NATURE = [311, 312, 313, 321, 322, 323, 331, 332, 341, 342, 343,
                     352, 353, 810, 820, 822, 830, 831, 832, 840, 841, 842,
                     843, 850];

  function toSet(arr) {
    var s = Object.create(null);
    for (var i = 0; i < arr.length; i++) s[arr[i]] = true;
    return s;
  }

  var SET = {
    noise: toSet(ANNO_NOISE),
    vegetation: toSet(ANNO_VEGETATION),
    roadname: toSet(ANNO_ROADNAME),
    railname: toSet(ANNO_RAILNAME),
    place: toSet(ANNO_PLACE),
    landmark: toSet(ANNO_LANDMARK),
    nature: toSet(ANNO_NATURE)
  };

  /* ================= ●（anchor）を付ける種別 =================
   * 🔒 §18-j（2026-08-21 オーナー報告 → 実測）: ここは**許可リストにしない**。
   *    「landmark と place と nature に付ける」のように種別を列挙すると、
   *    新しい施設コードを ANNO_LANDMARK に足した時に●を付け忘れる穴ができる。
   *    そこで**除外リスト**にした ―― ●を付けないのは
   *    「線や面に付く名前」だけ（点を打つと嘘になる・§18-8）:
   *      地名(place) / 道路名(roadname) / 鉄道名(railname) /
   *      自然地名(nature＝河川名・山名など) / 植生(vegetation)
   *    それ以外（＝点の目標物。官公署・警察・消防・学校・病院・郵便局・寺社・
   *    美術館・施設…）は**分類を問わず全部●が付く**。
   */
  var ANNO_NO_DOT = {
    place: true, roadname: true, railname: true, nature: true, vegetation: true
  };

  /* 🔒 §22-aa（2026-08-28 オーナー決定「A」）: 除外リストの**例外**＝コード単位で●を戻す。
   * 🔴 **422（駅名）は railname に分類されるが、実体は点データ**（実測: 地理院の
   *    Anno レイヤで名古屋城駅は rings:1 / pts:1 ＝ 座標1つ）。
   *    railname を除外する理由は「線に付く名前だから点を打つと嘘になる」（§18-8）で、
   *    421（路線名）には当てはまるが 422 には当てはまらない。巻き添えで●を失っていた。
   * 実害（オーナー実機報告）: 名古屋城駅は地下鉄なので鉄道中心線が近くに描かれず
   *    （最寄りの鉄道頂点まで 283m）、●も線も無い**宙に浮いた文字**になっていた。
   * 出入口が多い件は問題にならない: 地理院は駅ごとに**代表点を1つ**しか持たず、
   *    出入口の情報はそもそもデータに無い。愛知県庁舎など出入口の多い建物も●1つで出している。 */
  var ANNO_DOT_BY_CODE = { 422: true };

  /**
   * その注記に●（anchor）を付けるか。
   * kind は annoKind() の戻り値／code は元の vt_code（省略可・省略時は従来動作）
   */
  function annoHasDot(kind, code) {
    if (code !== undefined && ANNO_DOT_BY_CODE[code]) return true;
    return !!kind && !ANNO_NO_DOT[kind];
  }

  /* ================= 目標物の「格」（🔒 §18-r） =================
   * 所在図で道案内に効く順を数値にした物（§9-f「警察署・学校・駅を優先」を表にした）。
   * 官庁街では施設注記が数十件出るので、**近さだけ**で選ぶと
   * 「〇〇審議会」のような案内に効かない名前が並ぶ。格を足して選ぶ。
   * 表に無いコードは 2（ふつうの施設）。
   * 🔴 駅名は分類が railname なのでここには出てこない。
   *    駅は施設の件数制限（pickLandmarks）の対象外で、**全部出る**。
   * 🔒 §22-aa（2026-08-28 オーナー決定）: 駅名(422)は●が付くようになったが、
   *    **件数制限の対象外のままにする**（駅は道案内に効くので特別枠）。
   *    ここに駅のコードを足すと厳選に巻き込まれて駅が落ちるので、足さないこと。 */
  var ANNO_GRADE = {
    // 役所・警察・消防・学校・病院 ＝ 誰でも知っていて地図でも探しやすい
    881: 5, 883: 5, 884: 5, 885: 5, 886: 5,
    // 国・地方の機関、郵便局
    860: 4, 870: 4, 880: 4, 882: 4, 887: 4, 888: 4,
    // 美術館・福祉施設・大学・寺社・文化施設
    889: 3, 890: 3, 899: 3, 631: 3, 632: 3, 633: 3, 634: 3,
    651: 3, 653: 3, 661: 3, 662: 3, 671: 3, 673: 3, 681: 3,
    611: 3, 612: 3, 613: 3, 615: 3, 621: 3,
    // 公園・史跡・墓地
    531: 2, 532: 2, 534: 2, 6301: 2, 6341: 2, 6342: 2,
    // 構造物（塔・橋など）
    511: 1, 4101: 1, 4102: 1, 4104: 1, 4105: 1, 8103: 1, 8105: 1
  };

  /** 目標物の格（大きいほど所在図で残したい）。0〜5 */
  function annoGrade(code) {
    var g = ANNO_GRADE[code];
    if (g !== undefined) return g;
    // 3201〜3244 は官公署・公共施設のシンボル群（表は持っていないのでまとめて扱う）
    if (code >= 3201 && code <= 3244) return 3;
    return 2;
  }

  /** 注記 feature の用途種別を返す。捨てるものは null。 */
  function annoKind(code, opts) {
    opts = opts || {};
    if (SET.noise[code]) return null;
    if (SET.vegetation[code]) return opts.vegetation ? 'vegetation' : null;
    if (SET.roadname[code]) return 'roadname';
    if (SET.railname[code]) return 'railname';
    if (SET.landmark[code]) return 'landmark';
    if (SET.place[code]) return 'place';
    if (SET.nature[code]) return opts.nature === false ? null : 'nature';
    return null;
  }

  /* ================= 道路の等級 =================
   * RdCL の属性 vt_rdctg は文字列でそのまま等級が入っている(Step 0 実測)。
   * vt_code は橋・トンネル等の構造区分なので等級判定には使わない。
   */
  var ROAD_RANK = {
    '高速自動車国道等': 4,
    '国道': 3,
    '主要道路': 3,
    '都道府県道': 2,
    '市区町村道等': 1
  };

  function roadRank(props) {
    var r = ROAD_RANK[props && props.vt_rdctg];
    return r === undefined ? 0 : r;
  }

  /* ================= 道路の幅員ランク → 実距離(m)（§22-at） =================
   * RdCL の属性 vt_rnkwidth（幅員ランク文字列）から仮の実距離(m)を引く表。
   * 🔴 `vt_width` は描画用の定数で実幅ではない（§11・使わない）。
   * 文字列は実データの表記そのまま（半角数字・半角ハイフン・「未満」の有無、
   * 実タイル実測で確認済み・2026-09-06）。表に無い値（"不明" 等）は
   * `undefined` を返す＝呼び出し側は widthM を持たせず等級の従来値に留める。 */
  var ROAD_WIDTH_M = {
    '3m未満': 2.5,
    '3m-5.5m未満': 4.2,
    '5.5m-13m未満': 9,
    '13m-19.5m未満': 16,
    '19.5m以上': 22
  };

  function roadWidthM(props) {
    return ROAD_WIDTH_M[props && props.vt_rnkwidth];
  }

  /* ================= 道路の幅員ランク → 紙の下限(U)（§22-at-2） =================
   * 低い ZL（実距離の換算値が小さい）でも幅員ランクの差を紙で見せるための
   * ランク別下限。改めた規則3（editor.js roadBand）が使う。
   * 表に無い値（"不明" 等）は `undefined` を返す＝呼び出し側は floorU を
   * 持たせず等級の従来値に留める（roadWidthM と同じ作法）。 */
  var ROAD_FLOOR_U = {
    '3m未満': 1.2,
    '3m-5.5m未満': 1.9,
    '5.5m-13m未満': 4.4,
    '13m-19.5m未満': 6.0,
    '19.5m以上': 8.0
  };

  function roadFloorU(props) {
    return ROAD_FLOOR_U[props && props.vt_rnkwidth];
  }

  /* ================= タイル座標 ================= */

  function lonLatToTile(lon, lat, z) {
    var n = Math.pow(2, z);
    var latR = lat * Math.PI / 180;
    return {
      x: (lon + 180) / 360 * n,
      y: (1 - Math.log(Math.tan(latR) + 1 / Math.cos(latR)) / Math.PI) / 2 * n
    };
  }

  function tileToLonLat(xt, yt, z) {
    var n = Math.pow(2, z);
    return {
      lon: xt / n * 360 - 180,
      lat: Math.atan(Math.sinh(Math.PI * (1 - 2 * yt / n))) * 180 / Math.PI
    };
  }

  /** 2点間の距離(m)。ヒュベニではなく球面近似で十分(正典「大まかでよい」)。 */
  function distanceMeters(a, b) {
    var R = 6378137;
    var dLat = (b.lat - a.lat) * Math.PI / 180;
    var dLon = (b.lng - a.lng) * Math.PI / 180;
    var la1 = a.lat * Math.PI / 180, la2 = b.lat * Math.PI / 180;
    var h = Math.sin(dLat / 2) * Math.sin(dLat / 2)
          + Math.cos(la1) * Math.cos(la2) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    return 2 * R * Math.asin(Math.sqrt(h));
  }

  /* ================= 取得 ================= */

  /** 住所文字列 -> [{lng, lat, title}] （先頭が最有力） */
  function geocode(query) {
    return fetch(GEOCODE_URL + encodeURIComponent(query))
      .then(function (r) {
        if (!r.ok) throw new Error('住所検索に失敗しました (' + r.status + ')');
        return r.json();
      })
      .then(function (list) {
        return (list || []).map(function (f) {
          return {
            lng: f.geometry.coordinates[0],
            lat: f.geometry.coordinates[1],
            title: f.properties && f.properties.title
          };
        });
      });
  }

  /* 🔒 §30-13-5（2026-09-10 オーナー指摘「⑦の書き直しにずいぶん時間がかかる」）:
   * タイルの**メモリキャッシュ**。所在図の設定盤を触るたびに Shozaizu.generate が
   * 走るが、取ってくるタイルは毎回まったく同じ（範囲もズームも変わらない）ので、
   * 通信＋デコードをそのまま繰り返していた。OSM 側（osm.js の _cache）と同じ考え方。
   * 🔴 案件をまたいで持ち越さない（別の土地なので当たらない）＝ clearCache() を
   *    app.js openCaseInner から呼ぶ。
   * 🔴 失敗（通信エラー）はキャッシュしない＝次にまた取りに行ける。
   *    空タイル（404）は正常系なので null のままキャッシュする（再取得しない）。
   * 🔴 入れる物は**デコード済みの結果**（{z,x,y,layers}）。読む側は中身を書き換えない
   *    （collect* はどれも読むだけ）。 */
  var TILE_CACHE_MAX = 600;
  var _tileCache = Object.create(null);   // key 'z/x/y' → {z,x,y,layers} | null
  var _tileKeys = [];                     // 入れた順（あふれたら古い方から捨てる）

  function clearCache() {
    _tileCache = Object.create(null);
    _tileKeys.length = 0;
  }

  /* 🔒 §30-44-7 8: 取りに行っている最中のタイル（key → Promise）。
   * ②［枠を決定］の先読みの直後に③で生成が走っても、同じタイルを二重に取らず
   * 先読みの取得にそのまま相乗りする（先読みの効き目を消さない）。 */
  var _inflight = Object.create(null);

  /** 1タイル取得してデコード。空タイル(404)は null を返す。 */
  function fetchTile(z, x, y) {
    var key = z + '/' + x + '/' + y;
    if (key in _tileCache) return Promise.resolve(_tileCache[key]);
    if (_inflight[key]) return _inflight[key];
    var url = TILE_URL.replace('{z}', z).replace('{x}', x).replace('{y}', y);
    var p = fetch(url).then(function (r) {
      if (r.status === 404) return null;      // データ無しは正常系
      if (!r.ok) throw new Error('タイル取得に失敗しました (' + r.status + ')');
      return r.arrayBuffer();
    }).then(function (buf) {
      delete _inflight[key];
      var t = buf ? { z: z, x: x, y: y, layers: MVT.decode(new Uint8Array(buf)) } : null;
      if (!(key in _tileCache)) {
        _tileCache[key] = t;
        _tileKeys.push(key);
        while (_tileKeys.length > TILE_CACHE_MAX) delete _tileCache[_tileKeys.shift()];
      }
      return t;
    }, function (e) {
      delete _inflight[key];                  // 失敗はキャッシュしない＝次にまた取りに行ける
      throw e;
    });
    _inflight[key] = p;
    return p;
  }

  /**
   * 緯度経度の矩形をカバーするタイル群を並列取得。
   * bounds = {west, south, east, north}
   * 返り値: Promise<[{z,x,y,layers}, ...]>
   */
  function fetchTiles(bounds, z) {
    z = Math.max(TILE_MIN_ZOOM, Math.min(TILE_MAX_ZOOM, Math.round(z)));
    var a = lonLatToTile(bounds.west, bounds.north, z);
    var b = lonLatToTile(bounds.east, bounds.south, z);
    var x0 = Math.floor(a.x), x1 = Math.floor(b.x);
    var y0 = Math.floor(a.y), y1 = Math.floor(b.y);
    var jobs = [];
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) jobs.push(fetchTile(z, x, y));
    }
    return Promise.all(jobs).then(function (tiles) {
      return tiles.filter(function (t) { return t; });
    });
  }

  global.GSI = {
    TILE_URL: TILE_URL,
    TILE_MIN_ZOOM: TILE_MIN_ZOOM,
    TILE_MAX_ZOOM: TILE_MAX_ZOOM,
    RASTER_PALE_URL: RASTER_PALE_URL,
    ATTRIBUTION: ATTRIBUTION,
    ATTRIBUTION_RASTER: ATTRIBUTION_RASTER,
    ATTRIBUTION_URL: ATTRIBUTION_URL,
    ANNO: {
      NOISE: ANNO_NOISE, VEGETATION: ANNO_VEGETATION,
      ROADNAME: ANNO_ROADNAME, RAILNAME: ANNO_RAILNAME,
      PLACE: ANNO_PLACE, LANDMARK: ANNO_LANDMARK, NATURE: ANNO_NATURE
    },
    annoKind: annoKind,
    annoHasDot: annoHasDot,
    annoGrade: annoGrade,
    ANNO_NO_DOT: ANNO_NO_DOT,
    ANNO_DOT_BY_CODE: ANNO_DOT_BY_CODE,
    ANNO_GRADE: ANNO_GRADE,
    roadRank: roadRank,
    roadWidthM: roadWidthM,
    roadFloorU: roadFloorU,
    lonLatToTile: lonLatToTile,
    tileToLonLat: tileToLonLat,
    distanceMeters: distanceMeters,
    geocode: geocode,
    fetchTile: fetchTile,
    fetchTiles: fetchTiles,
    /* 🔒 §30-13-5: タイルのメモリキャッシュ（案件をまたいで持ち越さない） */
    clearCache: clearCache,
    cacheSize: function () { return _tileKeys.length; }
  };
})(typeof window !== 'undefined' ? window : this);
