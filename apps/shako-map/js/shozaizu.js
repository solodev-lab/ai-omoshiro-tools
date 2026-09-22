/* shozaizu.js — 所在図の自動生成（正典 §5 / Step 5）
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * 白地に「道路・鉄道・目標物の名称・自宅⇄駐車場の破線と距離」を描く略図を、
 * 国土地理院のベクトルデータだけから起こす。Google の画像は一切使わない。
 * 生成物は全部ふつうのオブジェクトなので、ドラッグで直せる・消せる（正典 §5）。
 *
 * Step 0 のスパイクで確定した知見をそのまま持ち込んでいる:
 *   ・注記の大半はノイズ（測地・標高の数値、地方部は植生が8〜9割）
 *   ・コード 880-899 は仕様表の ZL16 が「―」だが実際は入っている（目標物の主力）
 *   ・道路の間引きは「表示範囲の広さ」ではなく「本数」で決める
 */
(function (global) {
  'use strict';

  /* ---- 実測の計り（🔒 §30-13-5 の内訳 ／ §30-13-7 7 の「必ず閉じる」）----
   * console.time / console.timeEnd の薄い包み。**開いたラベルを覚えておき**、
   * 途中で失敗した時は tEndAll() でまとめて閉じる（try/finally 相当）。
   * 🔴 閉じ忘れると次の生成の console.time が「Timer already exists」を出す
   *    （警告だけで図には影響しないが、実測の内訳が読めなくなる）。
   * 🔴 計るだけ＝図の中身には一切影響しない。console が無い環境でも落ちない。 */
  var _timers = Object.create(null);

  function tStart(label) {
    if (_timers[label]) tEnd(label);          // 前回が開いたままなら先に閉じる
    if (!global.console || !console.time) return;
    try { console.time(label); _timers[label] = true; } catch (e) { /* 計りは捨てる */ }
  }

  function tEnd(label) {
    if (!_timers[label]) return;
    delete _timers[label];
    if (!global.console || !console.timeEnd) return;
    try { console.timeEnd(label); } catch (e) { /* 計りは捨てる */ }
  }

  function tEndAll() { Object.keys(_timers).forEach(function (k) { tEnd(k); }); }

  /** 🔒 §30-37 2: 方位記号1個の針の半分の高さ（紙面mm）。大きさの出どころは
   * Editor.compassRadiusMm（基準 × その記号の倍率 markScale）1か所。
   * Editor が無い／古い時（単体テスト）は基準（COMPASS.rMm）で見積もる。 */
  function compassRMm(o) {
    var E = global.Editor;
    if (E && E.compassRadiusMm) return E.compassRadiusMm(o);
    return (E && E.COMPASS) ? E.COMPASS.rMm : 2.346;
  }

  /* 道路の等級別の太さ（正典 §5「国道>県道>生活道路」）。
   * 🔴 §23-9 以降、数値の**唯一の出どころは editor.js の Editor.MAPSTYLE.road**。
   *    ここに残しているのは editor.js を読み込まない環境（単体テスト等）の
   *    保険＝フォールバックで、値は Editor.MAPSTYLE.road.line と同じにしてある。 */
  var ROAD_STYLE = {
    4: { w: 3.4, color: '#111' },   // 高速自動車国道等
    3: { w: 2.4, color: '#111' },   // 国道・主要道路
    2: { w: 1.8, color: '#111' },   // 都道府県道
    1: { w: 1.0, color: '#333' },   // 市区町村道等
    0: { w: 0.8, color: '#555' }
  };
  /* 白帯＋黒縁（§23-9 ヤフー式）の外幅のフォールバック。上と同じ理由で保険 */
  var ROAD_STYLE_BAND = {
    4: { w: 7.0, color: '#111' }, 3: { w: 5.6, color: '#111' },
    2: { w: 4.4, color: '#111' }, 1: { w: 3.6, color: '#111' },
    0: { w: 1.2, color: '#111' }
  };
  /* 建物の輪郭線（§23-3 線のみ）のフォールバック。Editor.MAPSTYLE.bldg と同じ値 */
  var BLDG_STYLE = { w: 1.3, color: '#333' };

  /**
   * 🔒 §23-9 / 2026-08-31 オーナー決定: 道路の描き方は2種類から**ユーザーが選ぶ**。
   *   'line'（既定・後方互換） … 従来の黒線1本
   *   'band'                   … 白い帯＋黒の縁取り（2本描き・ヤフー式）
   * 返すのは等級 → {w, color, casing?} の表。casing が立った物だけ2本描きになる。
   */
  function roadStyleTable(roadStyle) {
    var M = global.Editor && global.Editor.MAPSTYLE && global.Editor.MAPSTYLE.road;
    if (roadStyle === 'band') {
      var b = (M && M.band) || ROAD_STYLE_BAND, out = {};
      for (var k in b) out[k] = { w: b[k].w, color: b[k].color, casing: true };
      return out;
    }
    return (M && M.line) || ROAD_STYLE;
  }

  /** 建物の輪郭線のスタイル（§23-3・§23-9。塗りは入れない） */
  function bldgStyle() {
    var M = global.Editor && global.Editor.MAPSTYLE && global.Editor.MAPSTYLE.bldg;
    return { w: (M && M.w) || BLDG_STYLE.w, color: (M && M.color) || BLDG_STYLE.color };
  }

  var RANK_JA = ['', '市区町村道', '都道府県道', '国道', '高速'];

  /* 注記の種別ごとの文字の大きさ（size クラス。紙面で一定の大きさになる） */
  var TEXT_SIZE = {
    roadname: 'medium', railname: 'medium', landmark: 'medium',
    place: 'small', nature: 'small'
  };

  /* 間引きの閾値（Step 0 実測: 郊外は道のほぼ全部が市区町村道なので
     等級で切ると地図が空になる。本数が多い時だけ1段ずつ上げる） */
  var MAX_ROADS = 2200, MIN_ROADS = 250, RANK_CAP = 2;

  var GSI_ZOOM_MAX = 16;

  /* ================= 建物の自動描画（🔒 §23-10・2026-08-29 オーナー追加指示） =================
   * 「自動は初期値・ブラシと消しゴムが最終判断」（§23-1）。5段階の閾値で
   * 面積・距離のしきい値を切り替える。段1「なし」は旧 szBldg のOFF相当（既定・後方互換）。
   *
   * 🔴 §23-10-b 根治（2026-09-01・オーナー報告「5段階が3パターンにしかならない」への対処）:
   * 旧実装は半径を D（2地点間距離）にだけ連動させていたため、2地点が近い案件
   * （隣接・同一敷地＝実務で最多）では枠自体が小さく、段2の絶対半径（旧 max(80,D*0.08)）
   * だけで枠全体を覆ってしまい、段2〜4の差が面積下限（15m²/8m²・大半の建物が超える）
   * だけになって実質「なし/全部」の2択になっていた。
   * → 半径は D ではなく「その所在図の描画範囲(bounds)の対角の半分」＝R_frame に連動させる
   *   （bldgRadiusFor）。どんな縮尺でも段差が体感できる。
   * → 面積下限も絶対値をやめ、その場に実際にある建物の面積の分位点にする（bldgAreaThreshold・
   *   2パス: 半径で候補を集めてから面積でソートし分位点を決める）。地域差・縮尺差を吸収する。 */
  /* 🔒 §26-4-c（裁定3）: 半径と分位点の**両方**を単調にする。
   * 🔴 旧値は段2だけ分位点が無かったため、枠が狭くて半径が下限に張り付くと
   *    「分位点の無い段2が最多」＝ 0/20/18/19/23 の非単調になった（案件①で実測）。
   *    段2 にも分位点（上位35%）を入れ、段3 を 55%→60% に上げて、
   *    半径が全段で同じになっても件数が必ず段の順に増えるようにする。 */
  var BLDG_LEVELS = {
    1: { ja: 'なし',          radiusFrac: null, keepFrac: null },
    2: { ja: '主役の周りだけ', radiusFrac: 0.22, keepFrac: 0.35 },
    3: { ja: '標準',          radiusFrac: 0.45, keepFrac: 0.60 },
    4: { ja: '多め',          radiusFrac: 0.75, keepFrac: 0.85 },
    5: { ja: '全部',          radiusFrac: null, keepFrac: null }
  };
  var BLDG_LEVEL_JA = ['', 'なし', '主役の周りだけ', '標準', '多め', '全部'];

  /* 🙋 仮値（実機目視で確定）: 枠が極端に小さい案件でも段2が狭すぎて
   * 「駐車場の建物そのもの」まで欠けることがないよう入れる半径の下限(m)。 */
  var BLDG_RADIUS_MIN_M = 40;

  /* 🔒 §26-4-c（裁定3）: 下限そのものが枠を飲み込まないよう、極小の枠では
   * R_frame に対する割合へ落とす（＝ min(40m, R_frame×0.6)）。
   * 🔴 §26-4-a の最小枠幅300mが入ると R_frame×0.22 が 40m を超えるので
   *    下限自体がほとんど効かなくなる。これは「ユーザーが手で拡大して
   *    再生成した時」の保険。🙋 仮値 0.6。 */
  var BLDG_RADIUS_MIN_FRAC = 0.6;

  /* 🙋 仮値（実機目視で確定）: 主役2地点からこの距離以内の建物は、
   * 段の面積下限（分位点）を無視して全部残す（§18-r nearMain と同じ思想。
   * 「駐車場の隣の小屋」が面積下限で消える事故を防ぐ）。 */
  var BLDG_NEAR_MAIN_M = 30;

  /** 段の半径(m)。null=無制限（段5）/ 対象外（段1）。R_frame は枠の対角の半分(m)。
   * 🔴 段が上がるほど半径も広がる単調性を保証するため、前段の半径を下回らないよう
   *    クランプする（R_frame が極小だと素の *radiusFrac だけでは段3が段2より
   *    狭くなり得るため。§23-10-b）。 */
  function bldgRadiusFor(level, Rframe) {
    var cfg = BLDG_LEVELS[level];
    if (!cfg.radiusFrac) return null;
    var r = Rframe * cfg.radiusFrac;
    // 🔒 §26-4-c: 下限は min(40m, R_frame×0.6)＝極小の枠では下限が枠を飲まない
    if (level <= 2) {
      return Math.max(Math.min(BLDG_RADIUS_MIN_M, Rframe * BLDG_RADIUS_MIN_FRAC), r);
    }
    var prev = bldgRadiusFor(level - 1, Rframe);
    return (prev !== null) ? Math.max(r, prev) : r;
  }

  /** 面積(m²)の分位点しきい値。areasAsc は昇順ソート済みの面積配列、keepFrac は
   * 「大きい方から残す割合」（例 0.55 なら上位55%を残す＝下位45%を落とす）。 */
  function bldgAreaThreshold(areasAsc, keepFrac) {
    if (!keepFrac || !areasAsc.length) return 0;
    var dropIdx = Math.floor(areasAsc.length * (1 - keepFrac));
    if (dropIdx >= areasAsc.length) dropIdx = areasAsc.length - 1;
    if (dropIdx < 0) dropIdx = 0;
    return areasAsc[dropIdx];
  }

  /** 環の面積(m²)。shoelace。局所平面近似は placeLabels と同じ式 */
  function polyAreaM2(pts, lat0) {
    var M_LNG = 111320 * Math.cos(lat0 * Math.PI / 180), M_LAT = 110540;
    var a = 0, n = pts.length;
    for (var i = 0, j = n - 1; i < n; j = i++) {
      a += (pts[j].lng * M_LNG) * (pts[i].lat * M_LAT)
         - (pts[i].lng * M_LNG) * (pts[j].lat * M_LAT);
    }
    return Math.abs(a) / 2;
  }

  /* ================= 道路の量（🔒 2026-09-03 オーナー指示・所在図パネルの再構成） =========
   * 従来は「本数による自動間引き」だけで、ユーザーが量を選べなかった。
   * 建物（§23-10）・目標物（§18-r）と同じ **5段階**（なし/主役の周りだけ/標準/多め/全部）
   * にする。段3「標準」は**従来の自動間引きそのもの**＝後方互換の基準点。
   *
   * 🔴 単調性は「パラメータの調整」ではなく**構造**で保証する（§26-4-c の教訓）。
   *    残す条件を「等級 ≧ 下限」かつ「主役からの距離 ≦ 半径」の2つだけにし、
   *      ・半径     … 段が上がるほど**広がる**（段2だけ有限・段3〜5 は無制限）
   *      ・等級の下限 … 段が上がるほど**下がる**（段2 ≧ 段3 ≧ 段4 ≧ 段5）
   *    と定めた。両方が単調なので残る集合は必ず入れ子（S2 ⊆ S3 ⊆ S4 ⊆ S5）になり、
   *    地域・縮尺が何であっても件数が段の順に増えることが**証明できる**。
   *    🔴 基準の下限（base）は「全部の道路」から1回だけ計算する。段ごとに
   *       計算し直すと入れ子が壊れる。 */
  var ROAD_LEVEL_JA = ['', 'なし', '主役の周りだけ', '標準', '多め', '全部'];

  /* 🙋 仮値（実機目視で確定）: 段2「主役の周りだけ」の半径。
   * 建物（§23-10-b）と同じく **R_frame（枠の対角の半分）連動**にする。
   * 🔴 建物の 0.22 より広い 0.35 にしてあるのは、所在図の主役が道路だから
   *    （道路まで 0.22 にすると「主役の周りだけ」が使い物にならない図になる）。 */
  var ROAD_RADIUS_FRAC2 = 0.35;
  /* 🙋 仮値: 枠が極端に小さい案件で段2が狭くなりすぎないための下限(m)。
   * 🔴 下限そのものが枠を飲み込まないよう R_frame×0.6 で頭打ち（§26-4-c と同じ作法）。 */
  var ROAD_RADIUS_MIN_M = 60;
  var ROAD_RADIUS_MIN_FRAC = 0.6;

  /* 🔴 段4「多め」だけに掛ける本数の上限（🙋 仮値＝従来の上限 MAX_ROADS の4倍）。
   * 理由（実測 2026-09-03・名古屋 枠13km/z14）: 等級は 0〜4 の5段しか無く、しかも
   * **等級不明(rank 0) が 57,944本中 56,532本**を占める。そのため「等級の下限を
   * 1段下げる」だけだと 1,412 → 57,944 と一足飛びになり、段4と段5が同じ図になる。
   * 段4に本数の上限を入れて、段3 と 段5 の間に必ず1段を作る。
   * 🔴 上限は必ず**段3の本数以上**に持ち上げるので（下の Math.max）、
   *    段3 ⊆ 段4 は数値の選び方に関係なく成り立つ＝構造で保証（§26-4-c と同じ考え方）。 */
  var ROAD_BUDGET4 = MAX_ROADS * 4;

  /** 折れ線の長さ(m)。段4で「どれを残すか」を長い順に決めるのに使う */
  function polylineLenM(pts, lat0) {
    var M_LNG = 111320 * Math.cos(lat0 * Math.PI / 180), M_LAT = 110540;
    var sum = 0;
    for (var i = 1; i < pts.length; i++) {
      var dx = (pts[i].lng - pts[i - 1].lng) * M_LNG;
      var dy = (pts[i].lat - pts[i - 1].lat) * M_LAT;
      sum += Math.sqrt(dx * dx + dy * dy);
    }
    return sum;
  }

  /** 段の半径(m)。null＝半径では絞らない（段3〜5）。R_frame は枠の対角の半分(m) */
  function roadRadiusFor(level, Rframe) {
    if (level !== 2) return null;
    return Math.max(Math.min(ROAD_RADIUS_MIN_M, Rframe * ROAD_RADIUS_MIN_FRAC),
                    Rframe * ROAD_RADIUS_FRAC2);
  }

  /**
   * 段の「等級の下限」。base＝従来の自動間引きが出した下限（＝段3 標準）。
   * maxRankPresent＝その場に実際にある一番高い等級。
   * 🔴 段2 で base+1 に上げるが、その等級の道が1本も無い地域（郊外は大半が
   *    市区町村道）では図が空になるので maxRankPresent で頭打ちにする。
   *    さらに **base を下回らせない**（下回ると段2が段3より多くなり単調性が壊れる）。
   */
  function roadRankFloor(level, base, maxRankPresent) {
    if (level >= 5) return 0;                            // 全部＝間引きなし
    if (level === 4) return Math.max(0, base - 1);       // 多め＝下限を1段下げる
    if (level === 3) return base;                        // 標準＝従来どおり
    return Math.max(base, Math.min(base + 1, maxRankPresent));   // 段2
  }

  /**
   * 折れ線と点の最短距離(m)。局所平面近似は polyAreaM2 / placeLabels と同じ式。
   * 🔴 頂点だけの距離で見ると、頂点が疎な高速道路の長い直線区間を取りこぼす
   *    （主役のすぐ横を通っているのに「遠い」と判定される）ので、線分で見る。
   */
  function polylineDistM(pts, p, lat0) {
    var M_LNG = 111320 * Math.cos(lat0 * Math.PI / 180), M_LAT = 110540;
    var px = p.lng * M_LNG, py = p.lat * M_LAT;
    var best = Infinity, bx = 0, by = 0;
    for (var i = 0; i < pts.length; i++) {
      var ax = pts[i].lng * M_LNG, ay = pts[i].lat * M_LAT;
      var qx, qy;
      if (i === 0) {
        qx = ax; qy = ay;
      } else {
        var vx = ax - bx, vy = ay - by;
        var L2 = vx * vx + vy * vy;
        var t = (L2 > 0) ? ((px - bx) * vx + (py - by) * vy) / L2 : 0;
        if (t < 0) t = 0; else if (t > 1) t = 1;
        qx = bx + t * vx; qy = by + t * vy;
      }
      var d = (qx - px) * (qx - px) + (qy - py) * (qy - py);
      if (d < best) best = d;
      bx = ax; by = ay;
    }
    return Math.sqrt(best);
  }

  /**
   * 🔒 §22-ar ②: 複数の折れ線（同名道路の全 way）のうち、点 p に最も近い点を返す。
   * polylineDistM と同じ局所平面近似・同じ「線分上の射影」で見る（頂点だけだと
   * 頂点が疎な区間を取りこぼすため）。
   * @param ways 折れ線の配列（各要素は [{lat,lng},...]）
   * @param p    主役の座標 {lat,lng}
   * @param lat0 平面近似の基準緯度
   * @return {d(m), pt:{lat,lng}} … ways が空なら null
   */
  function nearestOnWays(ways, p, lat0) {
    var M_LNG = 111320 * Math.cos(lat0 * Math.PI / 180), M_LAT = 110540;
    var px = p.lng * M_LNG, py = p.lat * M_LAT;
    var best = Infinity, bestPt = null, w, pts, i, bx, by;
    for (w = 0; w < ways.length; w++) {
      pts = ways[w];
      bx = 0; by = 0;
      for (i = 0; i < pts.length; i++) {
        var ax = pts[i].lng * M_LNG, ay = pts[i].lat * M_LAT;
        var qx, qy;
        if (i === 0) {
          qx = ax; qy = ay;
        } else {
          var vx = ax - bx, vy = ay - by;
          var L2 = vx * vx + vy * vy;
          var t = (L2 > 0) ? ((px - bx) * vx + (py - by) * vy) / L2 : 0;
          if (t < 0) t = 0; else if (t > 1) t = 1;
          qx = bx + t * vx; qy = by + t * vy;
        }
        var d = (qx - px) * (qx - px) + (qy - py) * (qy - py);
        if (d < best) { best = d; bestPt = { lng: qx / M_LNG, lat: qy / M_LAT }; }
        bx = ax; by = ay;
      }
    }
    return bestPt ? { d: Math.sqrt(best), pt: bestPt } : null;
  }

  /* ================= 川・山（🔒 2026-09-03 オーナー指示・§22-ak-1 ②の中身） =================
   * トグル「川・山を入れる」が ON の時だけ描く。名前（自然地名の注記）は従来どおり。
   *
   * 【川】🔒 オーナー指示「グレーの帯＋黒の縁取り」。
   *   地理院の水部は**川幅で表現が変わる**（§11 のレイヤ一覧を実測して確定）:
   *     ・幅のある川・池・海 … `WA`（水域面・ポリゴン）＋ `WL`（水涯線＝岸の線）
   *     ・細い川            … `RvrCL`（河川中心線・1本の線）
   *   実測（optimal_bvmap-v1 z16）: 庄内川 = WA 5面 / WL 9本・**RvrCL なし**、
   *   大鹿村の谷川 = RvrCL 2本・**WA/WL なし**。→ **両方使わないと川が消える**。
   *   🔴 描く順は ①WA を全部塗る ②RvrCL の帯 ③WL の岸の線 の3パス。
   *      面を1枚ずつ「塗って縁取る」とタイル境界の切り口に黒い筋が出る
   *      （道路を1本ずつ黒→白と描くと交差点が黒く潰れるのと同じ理屈・§23-9-a）。
   *      面は塗るだけにして、岸の線は WL に任せる＝切り口には線が引かれない。
   *   細い川（RvrCL）は道路の白帯と**同じ2本描き**（style.casing）に乗せる。
   *   帯の色だけ style.bandColor でグレーに差し替える（Editor.roadBand が読む）。
   *   ＝ 合流点も交差点と同じく run の2パスで潰れない。
   *
   * 【山】🔒 オーナー選択「山頂付近だけ等高線を間引いて描く」。
   *   `Cntr`（等高線）を使う。**属性を実測したところ `vt_alti`（標高m）を持っていた**
   *   （富士山 z14 で 2740〜3776m が 10m 刻み・vt_code 7351/7352/7353）。
   *   → 間引きは「N本に1本」ではなく**標高の刻みを粗くする**方式を採る
   *     （どのタイルでも同じ高さの線が残る＝図として意味が通る）。
   *   🔴 山の在り処は**山名の注記**（Anno 311 山地／312 山／313 丘）で判定する。
   *      実測: 富士山=311「富士山」+312「剣ヶ峯」／箱根=311「箱根山」+312「神山」。
   *      名古屋駅前・高山市街には 311/312/313 が1件も無い（Cntr は 2本あるが
   *      標高10mの平地）。→ **都市部では山名が無いので等高線は1本も出ない**。 */

  /* 山名とみなす注記コード（🔴 実測で確定・311=山地/312=山/313=丘） */
  var MOUNTAIN_ANNO = { 311: true, 312: true, 313: true };

  /* 🙋 仮値（オーナー調整用）: 山名から見て等高線を描く半径。
   * 枠に連動（R_frame＝枠の対角の半分）させて、どの縮尺でも「山頂付近だけ」になる。 */
  var CNTR_RADIUS_FRAC = 0.45;
  var CNTR_RADIUS_MIN_M = 250;
  /* 🙋 仮値: 標高の刻みの候補（粗い順）。この順に試して、
   * 本数が CNTR_TARGET に収まる**一番細かい刻み**を採る＝地域差を吸収する。 */
  var CNTR_STEPS = [500, 200, 100, 50, 20, 10];
  var CNTR_TARGET = 140;      // この本数までなら細かい刻みにしてよい
  var CNTR_MAX = 400;         // 保険の上限（これを超えたら粗い刻みへ戻す）

  /** 水部のスタイル（🔴 唯一の出どころは Editor.MAPSTYLE.water。読めない時だけ既定） */
  function waterStyle() {
    var W = global.Editor && global.Editor.MAPSTYLE && global.Editor.MAPSTYLE.water;
    return W || { band: 4.6, color: '#111', fill: '#a9b0b8',
                  edge: { w: 1.3, color: '#111' } };
  }
  /** 等高線のスタイル（同上） */
  function contourStyle() {
    var C = global.Editor && global.Editor.MAPSTYLE && global.Editor.MAPSTYLE.contour;
    return C || { w: 1.1, color: '#6b7076' };
  }

  /* ============ 名称の自動描画 6分類（🔒 2026-09-03 オーナー指示・§23-5/§22-ak-1 ⑦〜⑫） ====
   * 「交差点名 / 大きなお店 / 会社名 / バス停 / 道路名 / 他の目印」を、
   * 建物・道路と同じ**5段階**で自動的に描く。
   *
   * 🔒 なぞり出し（ブラシ）は残す（オーナー決定）＝
   *    **自動が初期値・ブラシが足す・消しゴムが削る**（§23-10 / §23-11 と同じ思想）。
   *    自動で出した名称もただの text オブジェクトなので、reveal.js の重なり判定
   *    （紙にある text を候補から外す・§23-6-a ①）が**無改修でそのまま効く**。
   *
   * データ源は §23-5 の表どおり **OSM（Overpass）**。
   * 🔴 地理院 Anno の目標物は既存の「目標物（施設）の数」（lmLevel）が担当なので、
   *    ここでは**地理院を一切見ない**（二重に出さないため）。道路名も同じで、
   *    地理院 411系は従来どおり自動生成が出し、ここは OSM の細街路名だけを足す。
   * 🔴 同名の重複は出さない: §23-6-a の「既存 text → 地理院 → OSM の先勝ち」を
   *    そのまま自動描画にも適用する（下の seenName）。
   * 🔴 印の規則は既存のまま: 交差点名＝信号機アイコン（§22-aj-2）／
   *    道路名＝印なし（§18-8「線に付く名前に点を打つと嘘になる」）。
   *    どの印かは **OSM.CAT_BY_ID の meta** が唯一の出どころ（表示文字で判定しない）。
   *
   * 【5段階の作り方】§23-10-b / §22-ak-2 と**同じ作法**＝単調性を構造で保証する。
   *   ① 分類ごとに候補それぞれの「実効距離 dEff」を**段に依らず1回だけ**決める
   *      dEff ＝ 主役2地点までの最短距離(m) ＋ 優先順位 × NAME_PRIO_UNIT
   *      （§18-r の「150m 離れる ＝ 格1つ分の不利」と同じ物差し）
   *   ② dEff の昇順に**1回だけ**並べる
   *   ③ 段 n は「dEff ≦ 半径R_n」かつ「先頭から件数N_n 件まで」
   *   R_n も N_n も段が上がるほど大きいので、③はどちらも**同じ並びの前置き集合**
   *   ＝ S2 ⊆ S3 ⊆ S4 ⊆ S5 が数値の選び方に関係なく成り立つ。
   *   （lexicographic に「優先度→距離」で並べると前置きにならず入れ子が壊れる。
   *     優先度を距離に**足し込んで1つのスカラーにする**のがこの設計の肝） */
  var NAME_LEVEL_JA = ['', 'なし', '主役の周りだけ', '標準', '多め', '全部'];

  /* 🙋 仮値（実機目視で確定）: 段ごとの半径（R_frame 連動）と件数。
   * 🔒 2026-09-04 是正1（Fable 指定・オーナー実機報告「標準がすごい量になっている」）:
   *    件数は**1分類あたり**なのに分類が6つあるので**掛け算で効く**。
   *    旧 3/8/20 では標準＝8×6＝48件＋目標物＋地理院の地名/道路名で50〜60件になり、
   *    官庁街（名古屋三の丸）で図が文字に埋まった。
   *    **標準＝全分類ONでも読める密度**（6分類で計18件）に下げる。
   *    1〜2分類に絞って使う人は「多め」を選ぶ、という役割分担にする。 */
  var NAME_LEVELS = {
    1: { radiusFrac: null, count: 0 },
    2: { radiusFrac: 0.22, count: 1 },           // 6分類ON時 計 6
    3: { radiusFrac: 0.45, count: 3 },           // 6分類ON時 計 18
    4: { radiusFrac: 0.75, count: 8 },           // 6分類ON時 計 48
    5: { radiusFrac: null, count: Infinity }     // 全部＝半径も件数も無制限
  };
  var NAME_RADIUS_MIN_M = 60;        // 枠が極小の時の下限(m)
  var NAME_RADIUS_MIN_FRAC = 0.6;    // 下限そのものが枠を飲まないための頭打ち
  var NAME_PRIO_UNIT = 150;          // 優先順位1つ分の不利(m)。§18-r と同じ物差し

  /* 🔒 §30-40-2（2026-09-21 オーナー指示）: 名前の8分類だけが持てる**6つ目の選択
   * 「自動」**（段 NAME_AUTO.level）。ZL を上げて枠が小さくなると、段ごとの半径
   * （NAME_LEVELS の radiusFrac × 枠の半対角）と件数で候補が 0 になり、
   * 分類によっては名前が1つも出ない ―― これを「枠に入る候補の数」で自動調整する。
   *
   * 決め方（この表が唯一の出どころ）:
   *   その分類の**枠の中の候補**（近接重複を落とした後）が
   *     ・allMax 件以下 … allLevel の段として件数・半径を決める
   *     ・それより多い  … elseLevel の段として件数・半径を決める
   * 🔴 自動で決めた段は**件数と半径だけ**に使う。描く範囲は枠の中のまま
   *    （段4〜5 が画面まで描く規則＝areaFor は「手で選んだ時」の物。自動は
   *     「紙に載る物を決める」仕組みなので枠の外へは広げない・§30-40-2 3）。
   * 🙋 else を「多め」にしたければ elseLevel を1つ変えるだけ
   *    （画面の文言も title もこの表の実値から組むので、書き換えは1か所）。 */
  var NAME_AUTO = { level: 0, allMax: 5, allLevel: 5, elseLevel: 3 };

  /** 名前の8分類の段を数字にそろえる（🔒 §30-40-2: 0＝自動はそのまま通す） */
  function nameLevelOf(v) {
    var n = Math.round(Number(v));
    if (!isFinite(n)) return 1;                       // 値が無い＝なし（従来どおり）
    if (n === NAME_AUTO.level) return NAME_AUTO.level;
    return Math.max(1, Math.min(5, n));
  }

  /** その分類を使うか（🔒 §30-40-2 4: 「自動」も**使う**と数える＝OSM も取りに行く） */
  function nameCatUsed(v) {
    var n = nameLevelOf(v);
    return n === NAME_AUTO.level || n >= 2;
  }

  /* 🔒 §22-aq（2026-09-05 オーナー決定「案②」）: **交差点名だけ半径で絞らない**。
   * 交差点名は所在図で警察が一番見る目印なのに、枠 406×545m の名駅案件では
   * 「標準」の半径（半対角×0.45 ≈ 150m）の外に落ちて中央郵便局・中央郵便局北が
   * 出ていなかった（実測）。枠に数件しか無い分類なので密集の原因にならず、
   * 半径で絞る意味が薄い（お店・会社名は数十件あるので半径が要る）。
   *
   * 段3以上は **枠の中の全部を候補**にして、主役に近い順に件数だけで切る
   * （候補はもともと offer() が枠の中に限っている＝「枠の中の全部」になる）。
   * 段2（主役の周りだけ）と段1は従来どおり半径で絞る。
   *
   * 🔴 単調性（§22-ak-4）は保たれる: 段2の1件＝ dEff 最小の交差点は、段3の
   *    「近い順3件」に必ず含まれる（同じ並びの前置きを取るだけ）。
   * 🔴 分類の独立性（§22-ak-6）も不変（他分類の判定に触れない）。
   * 🔴 判定は **nameCat（＝分類表の id）** で行う。表示文字では判定しない（§26-2 注意②）。 */
  /* 🔒 §25-1 / §30-22-1 6: 主役（2地点）のラベルの文言は**ここ1か所**。
   * app.js（画面のピン・状態の一言）もここを読む（Shozaizu.PIN_LABEL）。
   * 🔒 §30-24-2（2026-09-13 オーナー指示）: 同一住所の「使用の本拠・駐車場」という
   *    1つの文字は**廃止**（`same` を消した）。同一住所でも文字は2つ置き、
   *    それぞれ別々に動かせる（印だけが1つ）。 */
  var PIN_LABEL = { home: '使用の本拠', lot: '駐車場' };

  var CROSSING_CAT = 'crossing';     // 半径を外す分類（osm.js CATS の id）
  var CROSSING_FRAME_FROM = 3;       // この段から半径を掛けない（3=標準）

  /* 🔒 §30-21-4 4: 同じ分類の中の近接重複（§22-aq-3 ③）を掛けない分類（棟名が並ぶため）。
   * 🔴 分類の id（osm.js CATS）で持つ＝表示文字では判定しない（§26-2 注意②）。 */
  var BUILDING_CAT = 'building';

  /* 🔒 §22-aq-2（2026-09-05 オーナー指示・上の §22-aq を改める）:
   * **主役の周囲の交差点名は絶対**。
   *
   * > オーナー: 「駐車場位置でいうと、名駅二丁目の右の交差点が必ずでる必要があると感じる。
   * >   それは主役の周囲だから。**主役の周囲は絶対だよ**。使用の本拠の交差点も
   * >   必ず出すようにしてほしい。標準でも、少な目でも、周囲でも。」
   *
   * ① 主役（使用の本拠・駐車場）**ごと**に最寄りの交差点名 CROSS_MAIN_N 件は
   *    段2以上の**全部の段で**必ず出す（重複は1つ）。段1「なし」だけは出さない。
   *    🔴 半径ではなく「最寄り N 件」にする理由: 地方部では最寄りの交差点名が
   *       数百m 先にもなり、半径だと「絶対」が空振りする。
   * ② 絶対分を置いた上で、段3以上は §22-aq の表どおり「**枠の中の**全部を候補・
   *    近い順に 3件／8件／無制限」を追加する（絶対分は件数に数えない）。
   *
   * 🔒 §22-aq-4（2026-09-05 オーナー決定「A」・§22-aq-2 ②③を**撤回**）:
   *    **枠の外の交差点名は出さない**（§18-n-4 に戻す）。
   *    > オーナー:「枠外の交差点名（大津橋）が枠外から線を引かれている。
   *    >   **なんのことかさっぱり分からない**。」
   *    紙では枠で切れる＝**どこにも行かない線**にしかならないため。
   *    ・`CROSS_OUT_M`（枠外 150m まで候補）・`padForCrossing`（Overpass の範囲を
   *      広げる）・`forceIn`（枠外でも通す内部印）は**廃止**した
   *    ・「主役の周囲は絶対（最寄り2件）」は **枠の中の交差点名**に対して効く（①②は維持）
   *    ・縁の少し外を出したい時は利用者が ZL を半段引く（§22-an で自動では動かさない）
   *
   * 🔴 単調性（§22-ak-4）: 絶対分は段に依らない前置き集合なので段2⊂段3⊂段4⊂段5 は不変。
   * 🔴 独立性（§22-ak-6）: 触るのは交差点名の候補集めと件数だけ（他分類は不変）。
   * 🔴 判定は nameCat と主役の座標（opts.home / opts.lot）で行う。表示文字では判定しない。 */
  var CROSS_MAIN_N = 2;              // 🙋 仮値: 主役1つあたり「絶対に出す」交差点名の件数

  /* 🔒 §22-ar（2026-09-06 オーナー決定）: **主役に接する通り名は絶対**。
   *
   * > オーナー: 「主役の位置が分かることが最も重要。交差点名が無い場合、通りと通りが
   * >   交差する。通り名が分かれば解決する。」
   *
   * 交差点名（§22-aq）は場所を特定する手段の1つで、**主役が面する通りの名前**は
   * もう1つの手段。郊外・地方では県道・国道名が主役のそばにある。
   *
   * ① 主役ごとに最寄りの名前付き道路 ROAD_MAIN_N 本は絶対に出す（ROAD_MAIN_M 以内・
   *    使用の本拠と駐車場それぞれ・同名は1つ）。段2以上の全段で。段1「なし」だけは出さない。
   *    crossingMustSet と同じ形＝ arr[i].dHome/dLot（代表点までの距離）で判定する
   *    （§22-aq-2 の名駅の実測「名駅通186m」もこの代表点距離）。
   * ② 置く場所は主役のそば: その道路の線のうち**主役に最も近い点（枠内）**を名前の位置にする
   *    （道路名は「その場に置く名前」の原則のまま・§22-am-1／§22-al の ROAD_STAY は不変）。
   *    🔴 対象は OSM の道路名（nameCat:'road'・byCat.road）だけにする。地理院の道路名
   *       （annoKind:'roadname'）は**段に関わらず常に描画される**（§23-5 是正3 の設計・
   *       nameLevels で絞っているのは OSM 側の追加分だけ）ので、そもそも「絶対」で
   *       強制する対象が無い＝ここでの forced 化は OSM 側だけで足りる。
   *    地理院側は RdCL に道路名の属性が無く「この名前がどの線か」を機械的に対応付ける
   *    手段が無いため、位置は動かさない（取れない時は従来の位置のまま・報告する）。
   * ③ 絶対分は段の件数に数えない（§22-aq-2 ④ と同じ）。単調性・分類の独立性は不変。 */
  var ROAD_MAIN_N = 2;               // 🙋 仮値: 主役1つあたり「絶対に出す」道路名の件数
  var ROAD_MAIN_M = 100;             // 🙋 仮値: 道路名を絶対にする範囲(m)。§22-as の判定もこれを使う

  /* ===== 🔒 §22-av 路線番号の印（2026-09-06 オーナー指示）=====
   * オーナー: 「国道のマーク▽の中に数字、県道のマーク◇の中に数字として道路標示できる？
   *            いまは国道19号だと19という数字しかない。警察はわかるだろうが少し分かりにくい」
   * → 県道の形は**六角形（ヘキサ・実物どおり）**でオーナー決定。
   *
   * 出どころは2つ:
   *   ① 地理院 Anno vt_code 2901 ＝ 国道番号（実測でこのコードは国道だけ）→ ▽
   *   ② OSM の route 関係（network=JP:national / JP:prefectural）→ ▽ / 六角形
   * 🔴 OSM の way の `ref` は国道も県道も裸の数字で見分けられない。**関係の network**
   *    だけが確実な出どころ（osm.js buildQuery のコメント参照）。
   */
  var GSI_ROUTE_NATIONAL = 2901;     // 地理院 Anno の「国道番号」コード
  var ROUTE_MAX = 6;                 // 🙋 仮値: 1枚に出す路線番号の印の上限
  /* 🔴 OSM の路線の線と、紙に描く地理院の道路の中心線は**同じ物を指していてもずれる**
   * （実測 2026-09-06: 国道19号 9.6m・県道60号 11.4m。上下線が別の線になっている等）。
   * 印が道から浮いて見えるので、描いた道路の線へ寄せる。これより遠い時は寄せない
   * （別の道に吸い付くと嘘になる）。 */
  var ROUTE_SNAP_M = 40;             // 🙋 仮値: 印を道路の線へ寄せる上限(m)
  /* 🙋 仮値: 枠の縁から内側へ空ける割合。印は動かさない（下記）ので、
   * 縁ぎりぎりに置くと紙で枠に切られる。実測 2026-09-06: v=0.006（枠の上端）に出た。 */
  var ROUTE_EDGE_PAD = 0.05;

  /* ===== 🔒 2026-09-04 是正2（Fable 指定）: 近接重複の抑制 =====
   * オーナー実機報告（名古屋三の丸）: 同じ画面に
   *   「愛知県庁」「愛知県庁舎」「愛知県庁内郵便局」「愛知県庁本庁舎」／
   *   「名古屋市役所」「名古屋市役所東庁舎」「名古屋市役所内郵便局」…
   * が並ぶ。完全一致の重複除去（§23-6-a の seenName）は効いているが、
   * **別名で近い場所**は落ちない。地理院の目標物と OSM が同じ施設を別名で持つ場合も同じ。
   *
   * 【判定】① 距離が NAME_DUP_M 以内なら名前が違っても「同じ場所」＝1つに寄せる
   *          （枠700mの A4 で 40m ≒ 紙面 1.1mm。並べても物理的に読めない）
   *        ② 片方の名前がもう片方を**含む**時だけ NAME_DUP_SUB_M まで広げる
   *          （「名古屋市役所」⊂「名古屋市役所東庁舎」= 56m は同じ施設の別名）
   *   🔴 ②は §26-2 注意②（表示文字列での内部識別）の**例外**。種別や役割を
   *      文字で当てているのではなく「**同じ施設か**」を推定しているだけなので可。
   *      内部識別（分類・出どころ・役割）は従来どおり nameCat / nameSrc / role が持つ。
   *   🔴 ②の半径を広げすぎると「久屋橋」と「久屋橋西」（実測80m）のような
   *      **別々の交差点**まで1つに寄ってしまうので 60m で止める（実測で確定）。 */
  var NAME_DUP_M = 40;               // 🙋 仮値: これより近ければ同じ場所とみなす
  var NAME_DUP_SUB_M = 60;           // 🙋 仮値: 名前が含み合う時だけ広げる上限
  var NAME_DUP_SUB_MIN = 2;          // 含み判定に使う短い方の最小文字数（誤爆よけ）

  /* ===== 🔒 2026-09-04 是正4（オーナー実機報告・道路名の配置順）=====
   * オーナー: 「**道路名と会社名が重なっている。道路名は動かすわけにはいかない。
   *   会社名を動かしたい**」。
   *
   * 🔴 道路名は「線に付く名前」なので●が無い（§18-8）＝**文字の位置そのものが
   *    『どの道か』を指している**。脇へ逃がすと隣の道に名前が付いて嘘になる。
   *    点に付く名前（会社・店・バス停・交差点）は●が場所を持つので、
   *    文字はいくら逃げても嘘にならない。だから**避けるのは点の側**が正しい。
   *
   * 【仕掛け】① 置く順番で道路名を点の名前より**先**にする（placeRank）
   *          ② 道路名が「その場」から離れる候補にだけ ROAD_STAY の不利を足す
   * 🔴 ②は完全固定にはしない。道路名どうしが重なった時に逃げ場が無くなるため。
   *    重み比: 枠の外 80 ／ 結線に被る 60 ／ **道路から離れる 40** ／ 文字の重なり 18。
   *    ＝「よほどのこと（枠外・結線の真上）」でだけ動く。 */
  var ROAD_STAY = 40;                // 🙋 仮値: 道路名を道路から引き剥がす代償
  var ROAD_YIELD_OVERLAP = 0.25;     // 🙋 仮値: 先に置いた文字をこれ以上埋めるなら譲る
  /* 🔒 §22-al-2: 主役ラベル（使用の本拠・駐車場・距離＝role持ち）に対しては、
   * 道路名は普通の名称よりずっと軽い重なりで譲る（書類として成立しない欠陥のため）。 */
  var ROAD_YIELD_MAIN = 0.02;        // 🙋 仮値: 主役ラベルはこれ以上埋めるなら道路名が必ず譲る

  /* 🔒 §22-am-6（2026-09-05 オーナー指摘・§22-am-2 の「枠の縁の帯」を**廃止**）:
   * **点に付く名前は「主役・結線から離れた空き地」へ置く**。
   *
   * > オーナー:「全ての名称は使用の本拠から離れる、駐車場から離れる、その間の線からも離れる。
   * >   そうすると道順の邪魔になりにくい」「右上のテキストがごちゃごちゃ。中央右にスペースが
   * >   ある。そういう所に配置できないの？」
   *
   * 候補＝●の周り **8方向 × 距離 1〜8 行**（近い環から）。枠の縁は候補の1つに過ぎない。
   * 除外（罰点ではない）＝主役の立入禁止域／結線の回廊／枠の外／紙の付き物の席／
   * 🔒 §22-am-7 裁定1: 結線を跨ぐ引き出し線／裁定2: 既に置いた文字との重なり面積比 >0.05。
   *
   * 単位は全部「文字の行」＝ふつうの大きさ(medium)の文字1行の高さ。
   * 紙の大きさに追従させるため、m でも px でもなくこの単位で持つ。
   * 🙋 全部**仮値**（オーナー実機目視で確定する）。
   * 🔒 §22-am-7 裁定3（2026-09-05 Fable 裁定・実装者の目視所感採用）:
   *    wLen 1→2・wSide 20→12（向きが強すぎて「正しい側の遠い環」を選び 100m 級の
   *    線が出ていた）・ringMax 10→8。mainPad 4・corr 3・wDens 15・ringMin 1 は据え置き。 */
  var PLACE = {
    ringMax: 8,      // ●から文字の箱の縁までの距離の上限（行・§22-am-6-1 ⑤⑥・§22-am-7 裁定3）
    ringMin: 1,      // 最も近い環（この距離以内に置けたら引き出し線を描かない）
    mainPad: 4,      // 主役の立入禁止域を膨らませる量（行・§22-am-6-1 ①）
    corr: 3,         // 結線の回廊の半幅（行・§22-am-6-1 ②）
    densPad: 2,      // 空き地の密度を測る時に箱を膨らませる量（行・同 ④）
    wSeg: 30,        // 結線からの近さ（回廊の外でも近いほど不利）
    wSide: 12,       // 結線側の向き（●→結線の向きへ逃がすのは不利・同 ③・§22-am-7 裁定3）
    wDens: 15,       // 空き地の密度（既にある箱で埋まっているほど不利）
    wOver: 18,       // 文字の重なり（従来の costOf と同じ物差し。>0.05 は除外・§22-am-7 裁定2）
    wMain: 20,       // 主役ラベルを埋める時は wOver をこの倍にする（§22-al-2 と同じ考え）
    wLen: 2,         // 引き出し線の長さ（1行につき・同 ⑤・§22-am-7 裁定3）
    wCross: 8,       // 主役の印・道路名の箱を横切る／他の引き出し線と交差（同 ⑦）
    wDot: 12,        // 他の●を文字で塗り潰す（従来の costOf ③ と同じ）
    /* 🔒 §22-at-3 欠陥2-②（2026-09-06 Fable 裁定）: 点に付く名前が道路の帯
     * （実距離の帯・style.casing && widthM）の面に乗るのは罰点（除外ではない）。
     * 帯だらけの場所で置き場が無くならないよう、除外ではなく awayCost に足すだけ。
     * 🙋 仮値 15（wDens と同格・wOver よりやや軽い）。 */
    wBand: 15,
    overMax: 0.05,   // 🔒 §22-am-7 裁定2: 既に置いた文字との重なり面積比の上限（超えたら除外）
    /* 🔒 §22-am-8 裁定1（2026-09-06 Fable 裁定）: 全滅時（forced）の「最善」は
     * 通常コスト（awayCost）に違反の量×この重みを足して選ぶ＝「違反を量で罰する」。
     * > Fable「全滅時の最善（forced）が回廊・禁止域を無視する（『中部経済産業局』＝
     * >  ●が枠の左端と結線の狭い楔にあり80候補が全滅→コストだけで選ぶので結線から
     * >  1.2行の回廊内に置かれた）」
     * 全部 200（🙋 仮値・除外の基準を超えたら通常コスト（数十止まり）を確実に上回り、
     * 違反の少ない候補が必ず勝つようにするための大きな重み）。1か所に集約。 */
    forcedCorr: 200, // 回廊への食い込み深さ（行）× この重み
    forcedMain: 200, // 主役の禁止域への食い込み（行）× この重み
    forcedCross: 200,// 結線を跨ぐ引き出し線（固定・跨いだら加算）
    forcedOver: 200, // 文字どうしの重なり比（0〜1）× この重み
    forcedOut: 200   // 枠外比（0〜1）× この重み
  };
  /* 🔒 §30-41 5（2026-09-21 オーナー指示「距離表示が結ぶ線から離れている。
   * くっつくくらいがいい」）: **直線距離の文字だけ**の置き方の数値。1か所。
   * 単位は PLACE と同じ「文字の行」（ふつうの大きさの文字1行の高さ）。
   * 🙋 全部**仮値**（オーナー実機目視で詰める）。 */
  var DIST = {
    gap: 0.15,       // 箱の縁と結線の隙間（行・0 に近いほど線にくっつく）
    along: 0.2,      // 中点から両端へずらす候補の位置（線の長さに対する比）
    sideBias: 0.5    // 好まない側（画面で線より下／真横の線なら左）の不利
  };
  /* 🔒 §30-22-10（2026-09-13 オーナー実機「近くが全然近くない。標準より離れる」）:
   * **名前と印の距離は3段**（1=近く／2=標準／3=離す。既定＝離す・Store.SZ_STD.nameGap）。
   *   近く（1）… 印の**すぐ隣**（§30-15-3 の規則＝印の右端＋文字高×0.4・上下は印の中心）。
   *              外側へ（§22-am-6）・主役から離す（§22-y）・空き地探し（§22-aq）は
   *              一切掛けない。引き出し線も出さない（重なりは利用者がドラッグで直す）
   *   離す（3）… 従来どおり（§22-am-6〜8・§22-y・§22-aq）
   *   標準（2）… 🔒 §30-22-11 2 で訂正（下記）: 誤＝「離す」と「近く」の**中点**
   *              （緯度経度の中点。中点だと離すと近くが印の反対側の時に文字が印に乗る）
   * 🔴 §30-22-2 2 の係数方式（0.6／1.0／1.5）は**廃止**した。
   * 🔴 段は数字で持つ。表示文字（「近く」等）では判定しない（§26-2 注意②）。 */
  var NAME_GAP_NEAR = 1, NAME_GAP_MID = 2, NAME_GAP_FAR = 3;
  function nameGapStep(v) {
    var n = Math.round(Number(v));
    return (n === NAME_GAP_NEAR || n === NAME_GAP_MID) ? n : NAME_GAP_FAR;
  }
  /* 🔒 §30-22-11（2026-09-13 Fable 裁定）: 上の「標準（2）」を訂正。
   *   正＝「離す」で決めた位置への**向きはそのまま**、印からの距離を**半分**にする
   *   （半分が「近く」の距離より短ければ「近く」の距離を使う＝文字が印に乗らない）。
   *   引き出し線は従来の距離規則で判定し直す（変更なし）。実装は midStandardBox。
   * 🔒 §30-22-11 1: 離す（3）の隙間は変えない＝ ×1.5 のまま（awayCands 参照）。 */
  var AWAY_GAP_K = 1.5;
  /* 🔒 §30-22-12（2026-09-13 Fable・§30-22-11 2 の補正）: 「印からの距離を半分」を
   *   「印の縁と文字の箱の縁の**隙間**を半分」に直す。中心どうしの距離を半分にすると
   *   文字の半幅（長い名前ほど大きい）を含んでしまい、実測でほぼ全件が「近く」の
   *   下限に張り付いた（標準＝近く）。隙間の下限は「近く」の隙間＝字高×0.4。
   *   実装は midStandardBox（markHalfW／ellipseR で向きに応じた半幅を出す）。 */

  /* 候補の8方向（単位ベクトル・§22-am-6-1 ⑥）。●の周りを均等に見る */
  var DIR8 = (function () {
    var a = [], k, t;
    for (k = 0; k < 8; k++) {
      t = k * Math.PI / 4;
      a.push([Math.cos(t), Math.sin(t)]);
    }
    return a;
  })();

  /* 🔴 「他の目印」＝ OSM `amenity` **全部**なので、自販機・駐輪場・ベンチまで入る
   * （§23-6-a 持ち越し2・名古屋駅前で319件）。低い段では役所・学校・病院・寺社が
   * 先に出るよう、公共性・規模で優先順位を付ける。表に無い amenity は 3（ふつう）。
   * 🔴 判定は**タグの値**（item.sub）で行う。表示文字では判定しない（§26-2 注意②）。 */
  var POI_PRIO = {
    /* 0 = 役所・警察・消防・病院・学校・寺社（所在図の目印として最上位） */
    townhall: 0, police: 0, fire_station: 0, hospital: 0, courthouse: 0,
    embassy: 0, prison: 0, university: 0, college: 0, school: 0,
    kindergarten: 0, post_office: 0, place_of_worship: 0, community_centre: 0,
    library: 0, public_building: 0, social_facility: 0, nursing_home: 0,
    childcare: 0, monastery: 0, ranger_station: 0,
    /* 1 = 生活の目印になる規模の施設 */
    clinic: 1, doctors: 1, dentist: 1, pharmacy: 1, bank: 1, theatre: 1,
    cinema: 1, museum: 1, arts_centre: 1, marketplace: 1, bus_station: 1,
    ferry_terminal: 1, fuel: 1, driving_school: 1, veterinary: 1,
    conference_centre: 1, exhibition_centre: 1, events_venue: 1,
    public_bath: 1, townhall_annex: 1, research_institute: 1,
    /* 2 = 店舗系（数が多いので中位） */
    restaurant: 2, cafe: 2, fast_food: 2, bar: 2, pub: 2, food_court: 2,
    nightclub: 2, car_rental: 2, car_wash: 2, parking: 2, casino: 2,
    internet_cafe: 2, charging_station: 2, bicycle_rental: 2, gambling: 2,
    /* 4 = 図に載せても案内にならない小物（自販機・駐輪場・ベンチ…） */
    vending_machine: 4, bicycle_parking: 4, motorcycle_parking: 4, bench: 4,
    waste_basket: 4, waste_disposal: 4, drinking_water: 4, toilets: 4,
    atm: 4, telephone: 4, smoking_area: 4, shelter: 4, clock: 4,
    fountain: 4, bbq: 4, parking_space: 4, parking_entrance: 4,
    bicycle_repair_station: 4, recycling: 4, post_box: 4, water_point: 4,
    grit_bin: 4, luggage_locker: 4, photo_booth: 4, vacuum_cleaner: 4,
    give_box: 4, device_charging_station: 4, hunting_stand: 4
  };
  var POI_PRIO_DEFAULT = 3;

  /* 「大きなお店」も同じ作法で規模順にする（表に無い shop は 2） */
  var SHOP_PRIO = {
    department_store: 0, mall: 0, supermarket: 0, home_improvement: 0,
    doityourself: 0, furniture: 0, car: 0, motorcycle: 0, electronics: 0,
    trade: 0, wholesale: 0, garden_centre: 0, hardware: 0, variety_store: 0,
    books: 0, sports: 0, toys: 0, department: 0,
    convenience: 1, clothes: 1, shoes: 1, bakery: 1, butcher: 1,
    greengrocer: 1, florist: 1, chemist: 1, drugstore: 1, optician: 1,
    jewelry: 1, bicycle: 1, pet: 1, alcohol: 1, beverages: 1,
    mobile_phone: 1, computer: 1, appliance: 1
  };
  var SHOP_PRIO_DEFAULT = 2;

  /* 🔒 §30-21-2 の格の表（施設・公園）。POI_PRIO と**同じ作法**
   * （小さいほど先に出る・表に無い物は既定）。
   * 🔴 判定は osm.js pointCat が焼いた `sub`（'キー:値'）。表示文字では判定しない（注意②）。
   * 正典: 公園・駅・団地・変電所／発電所・浄水場＝0／運動場・工場・川・橋＝1／他＝2 */
  var FACILITY_PRIO = {
    /* 0 = 公園・駅・団地・変電所／発電所・浄水場 */
    'leisure:park': 0, 'leisure:garden': 0, 'leisure:nature_reserve': 0,
    'railway:station': 0, 'railway:halt': 0, 'public_transport:station': 0,
    'landuse:residential': 0,
    'power:substation': 0, 'power:plant': 0, 'power:generator': 0,
    'man_made:water_works': 0, 'man_made:wastewater_plant': 0,
    /* 1 = 運動場・工場・川・橋 */
    'leisure:sports_centre': 1, 'leisure:stadium': 1, 'leisure:pitch': 1,
    'leisure:track': 1, 'leisure:swimming_pool': 1, 'leisure:golf_course': 1,
    'leisure:sports_hall': 1, 'leisure:fitness_centre': 1, 'leisure:water_park': 1,
    'man_made:works': 1, 'landuse:industrial': 1, 'landuse:quarry': 1,
    'man_made:bridge': 1,
    'waterway:river': 1, 'waterway:stream': 1, 'waterway:canal': 1,
    'waterway:riverbank': 1, 'natural:water': 1
  };
  var FACILITY_PRIO_DEFAULT = 2;

  /* 🔒 §30-21-2 の格の表（建物名）。
   * 正典: 公共の建物・ホテル・商業ビル＝0／事務所・倉庫＝1／マンション・棟名＝2 */
  var BUILDING_PRIO = {
    /* 0 = 公共の建物・ホテル・商業ビル */
    'building:public': 0, 'building:civic': 0, 'building:government': 0,
    'building:school': 0, 'building:university': 0, 'building:college': 0,
    'building:kindergarten': 0, 'building:hospital': 0, 'building:train_station': 0,
    'building:transportation': 0, 'building:fire_station': 0, 'building:museum': 0,
    'building:hotel': 0, 'tourism:hotel': 0, 'tourism:motel': 0, 'tourism:guest_house': 0,
    'building:commercial': 0, 'building:retail': 0, 'building:supermarket': 0,
    'building:mall': 0,
    /* 1 = 事務所・倉庫 */
    'building:office': 1, 'building:warehouse': 1, 'building:industrial': 1,
    'building:manufacture': 1, 'building:service': 1
    /* 2（既定）= マンション・棟名（building:apartments / residential / yes …） */
  };
  var BUILDING_PRIO_DEFAULT = 2;

  /** 分類ごとの優先順位（小さいほど先に出る）。0 固定の分類は距離だけで並ぶ */
  function namePrio(cat, it) {
    if (cat === 'public') {
      var p = POI_PRIO[it.sub];
      return (p === undefined) ? POI_PRIO_DEFAULT : p;
    }
    if (cat === 'shop') {
      var s = SHOP_PRIO[it.sub];
      return (s === undefined) ? SHOP_PRIO_DEFAULT : s;
    }
    if (cat === 'facility') {
      var f = FACILITY_PRIO[it.sub];
      return (f === undefined) ? FACILITY_PRIO_DEFAULT : f;
    }
    if (cat === 'building') {
      var g = BUILDING_PRIO[it.sub];
      return (g === undefined) ? BUILDING_PRIO_DEFAULT : g;
    }
    /* 道路名は「枠の中にその道が何本の way として入っているか」を規模の代わりに使う。
     * 主要道ほど枠内に長く伸びるので way 数が多い（§23-5-a の名寄せの副産物）。 */
    if (cat === 'road') {
      var w = it.ways || 1;
      return (w >= 8) ? 0 : (w >= 3 ? 1 : 2);
    }
    return 0;   // 交差点名・会社名・バス停は距離だけで並べる（数が少ない）
  }

  /**
   * 2つの名称が「同じ場所にある同じ物」か（🔒 2026-09-04 是正2）。
   * a/b は {p:{lat,lng}, name:string}。
   */
  function sameSpotName(a, b) {
    var d = GSI.distanceMeters(a.p, b.p);
    if (d <= NAME_DUP_M) return true;
    if (d > NAME_DUP_SUB_M) return false;
    var s = a.name, t = b.name;
    if (s === t) return true;
    // 短い方が長い方に丸ごと入っているか（「愛知県庁」⊂「愛知県庁内郵便局」）
    if (s.length > t.length) { var w = s; s = t; t = w; }
    if (s.length < NAME_DUP_SUB_MIN) return false;
    return t.indexOf(s) >= 0;
  }

  /* 近接判定の前ふるい（60m ぶんの緯度差＋1.2倍の余裕）。
   * 基準集合は数百件になるので、総当たりの前に矩形で落として距離計算を減らす。 */
  var NAME_DUP_DLAT = NAME_DUP_SUB_M * 1.2 / 110574;

  /** すでに残すと決めた名称のどれかと同じ場所か */
  function hitsKeptSpot(kept, cand) {
    var cosLat = Math.cos(cand.p.lat * Math.PI / 180);
    var dLngMax = NAME_DUP_DLAT / Math.max(0.1, Math.abs(cosLat));
    for (var i = 0; i < kept.length; i++) {
      var k = kept[i];
      if (Math.abs(k.p.lat - cand.p.lat) > NAME_DUP_DLAT) continue;
      if (Math.abs(k.p.lng - cand.p.lng) > dLngMax) continue;
      if (sameSpotName(k, cand)) return true;
    }
    return false;
  }

  /**
   * 🔒 §30-21-4 4（2026-09-13 Fable 裁定）: **同じ名前だけ**1つに寄せる版。
   * 建物名（棟名）は隣どうしが近い（実測「6棟」は「7棟」から 37m ＝ NAME_DUP_M 以内）
   * ので、距離で「同じ場所」とみなす §22-aq-3 ③ を掛けると別の棟が落ちてしまう。
   * 建物名だけこちらを使う＝**同名だけ**従来どおり1つに（同じ建物が node と面の
   * 両方で入っている時に効く）。
   * 🔴 含み合い（「1棟」⊂「11棟」）は見ない。棟名は短いので誤爆する。
   * 🔴 近接の前ふるい（NAME_DUP_DLAT）は残す＝枠の離れた所にある同名の別の建物
   *    （別の団地の「1棟」）は落とさない。
   */
  function hitsKeptSameName(kept, cand) {
    var cosLat = Math.cos(cand.p.lat * Math.PI / 180);
    var dLngMax = NAME_DUP_DLAT / Math.max(0.1, Math.abs(cosLat));
    for (var i = 0; i < kept.length; i++) {
      var k = kept[i];
      if (k.name !== cand.name) continue;
      if (Math.abs(k.p.lat - cand.p.lat) > NAME_DUP_DLAT) continue;
      if (Math.abs(k.p.lng - cand.p.lng) > dLngMax) continue;
      return true;
    }
    return false;
  }

  /**
   * 地理院由来の名称の実効距離。OSM 側（dEff = 距離 + 優先順位×150m）と
   * **同じ物差し**に揃えるため、格（0〜5・大きいほど残したい）を
   * 優先順位（0が最優先）へ 5−格 で読み替える。
   * 目標物以外（駅名など）は最優先の 0 として扱う。
   */
  function gsiNameDEff(o, opts) {
    var p = o.anchor || o.at, d = Infinity, dl;
    if (opts.home) d = GSI.distanceMeters(p, opts.home);
    if (opts.lot) { dl = GSI.distanceMeters(p, opts.lot); if (dl < d) d = dl; }
    if (!isFinite(d)) d = 0;
    var prio = (o.annoKind === 'landmark') ? (5 - GSI.annoGrade(o.annoCode)) : 0;
    return d + prio * NAME_PRIO_UNIT;
  }

  /** 段の半径(m)。null＝半径では絞らない（段5）／段1は呼ばれない */
  function nameRadiusFor(level, Rframe) {
    var cfg = NAME_LEVELS[level];
    if (!cfg || cfg.radiusFrac === null) return null;
    return Math.max(Math.min(NAME_RADIUS_MIN_M, Rframe * NAME_RADIUS_MIN_FRAC),
                    Rframe * cfg.radiusFrac);
  }

  /** 環の頂点平均（距離判定用。厳密な重心でなくてよい） */
  function ringCenter(pts) {
    var sLat = 0, sLng = 0;
    for (var i = 0; i < pts.length; i++) { sLat += pts[i].lat; sLng += pts[i].lng; }
    return { lat: sLat / pts.length, lng: sLng / pts.length };
  }

  /* 🔒 §25-4: 主役マーク（四角）の紙面最小サイズ(mm)。
   * 🔴 実体は editor.js の Editor.MARK.minMm（唯一の出どころ）。ここは
   *    ラベルの逃がし計算に使うだけなので、読めない時だけ既定 4mm に落ちる。 */
  function markMinMm() {
    var M = global.Editor && global.Editor.MARK;
    return (M && M.minMm) || 4;
  }

  function uid(p) {
    return (p || 'o') + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  }

  /* ================= 取得 ================= */

  /** 表示範囲に必要な地理院ベクトルタイルを取る */
  function fetchTiles(bounds, zoom) {
    var z = Math.min(GSI_ZOOM_MAX, Math.max(4, Math.round(zoom)));
    var a = GSI.lonLatToTile(bounds.west, bounds.north, z);
    var b = GSI.lonLatToTile(bounds.east, bounds.south, z);
    var x0 = Math.floor(a.x), x1 = Math.floor(b.x);
    var y0 = Math.floor(a.y), y1 = Math.floor(b.y);
    var n = (x1 - x0 + 1) * (y1 - y0 + 1);
    // タイルが多すぎる時はズームを落として取り直す
    while (n > 42 && z > 4) {
      z--;
      a = GSI.lonLatToTile(bounds.west, bounds.north, z);
      b = GSI.lonLatToTile(bounds.east, bounds.south, z);
      x0 = Math.floor(a.x); x1 = Math.floor(b.x);
      y0 = Math.floor(a.y); y1 = Math.floor(b.y);
      n = (x1 - x0 + 1) * (y1 - y0 + 1);
    }
    var jobs = [];
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) jobs.push(GSI.fetchTile(z, x, y));
    }
    return Promise.all(jobs).then(function (tiles) {
      return { z: z, tiles: tiles.filter(Boolean) };
    });
  }

  function toLatLngs(ring, tile, extent) {
    var out = [];
    for (var i = 0; i < ring.length; i++) {
      var ll = GSI.tileToLonLat(tile.x + ring[i][0] / extent,
                                tile.y + ring[i][1] / extent, tile.z);
      out.push({ lat: ll.lat, lng: ll.lon });
    }
    return out;
  }

  function bboxHits(pts, b) {
    var w = Infinity, e = -Infinity, s = Infinity, n = -Infinity;
    for (var i = 0; i < pts.length; i++) {
      var p = pts[i];
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
    }
    return !(e < b.west || w > b.east || n < b.south || s > b.north);
  }

  /* ================= 川（🔒 2026-09-03・トグル「川・山を入れる」の中身） ================= */

  /**
   * 水部を図形にする。**戻り値の並びがそのまま描く順**（＝3パス）:
   *   ①WA を全部塗る → ②RvrCL の帯 → ③WL の岸の線
   * 🔴 面を1枚ずつ「塗って縁取る」とタイル境界の切り口が黒い筋になるので、
   *    面は塗るだけ・岸の線は WL に任せる（道路の帯と同じ「全部→全部」の考え方）。
   * 🔴 RvrCL は style.casing に乗せる＝editor.js / export.js の run の2パスが
   *    そのまま効く（合流点が黒い塊にならない・§23-9-a の教訓）。
   */
  function collectWater(tiles, bounds, stat) {
    var W = waterStyle();
    var areas = [], rivers = [], edges = [];
    tiles.forEach(function (t) {
      var i, g, pts;
      /* ①水域面（幅のある川・池・海）。塗るだけ＝線は持たせない */
      if (t.layers.WA) {
        var A = t.layers.WA;
        for (i = 0; i < A.features.length; i++) {
          for (g = 0; g < A.features[i].geom.length; g++) {
            if (A.features[i].geom[g].length < 3) continue;
            pts = toLatLngs(A.features[i].geom[g], t, A.extent);
            if (!bboxHits(pts, bounds)) continue;
            areas.push({ id: uid('wa'), type: 'polygon', points: pts,
                         style: { fill: W.fill, w: 0 }, source: 'shozaizu' });
          }
        }
      }
      /* ②河川中心線（細い川）。グレーの帯＋黒の縁取り＝道路の白帯と同じ2本描き */
      if (t.layers.RvrCL) {
        var R = t.layers.RvrCL;
        for (i = 0; i < R.features.length; i++) {
          for (g = 0; g < R.features[i].geom.length; g++) {
            if (R.features[i].geom[g].length < 2) continue;
            pts = toLatLngs(R.features[i].geom[g], t, R.extent);
            if (!bboxHits(pts, bounds)) continue;
            rivers.push({ id: uid('rv'), type: 'path', points: pts,
                          style: { w: W.band, color: W.color,
                                   casing: true, bandColor: W.fill },
                          source: 'shozaizu' });
          }
        }
      }
      /* ③水涯線（＝水域面の岸）。ここが「黒の縁取り」の実体 */
      if (t.layers.WL) {
        var L = t.layers.WL;
        for (i = 0; i < L.features.length; i++) {
          for (g = 0; g < L.features[i].geom.length; g++) {
            if (L.features[i].geom[g].length < 2) continue;
            pts = toLatLngs(L.features[i].geom[g], t, L.extent);
            if (!bboxHits(pts, bounds)) continue;
            edges.push({ id: uid('wl'), type: 'path', points: pts,
                         style: { w: W.edge.w, color: W.edge.color },
                         source: 'shozaizu' });
          }
        }
      }
    });
    stat.waterAreas = areas.length;
    stat.waterRivers = rivers.length;
    stat.waterEdges = edges.length;
    return areas.concat(rivers, edges);
  }

  /* ================= 山（🔒 2026-09-03・同じトグルの中身） ================= */

  /**
   * 山頂付近だけ等高線を描く。
   * 🔴 山の在り処は**山名の注記**（Anno 311/312/313）。1件も無ければ**何も描かない**
   *    ＝都市部で等高線が出ることはない。
   * 🔴 間引きは `vt_alti`（標高m・実測で存在を確認）の**刻みを粗くする**方式。
   *    粗い刻みから順に試して、本数が収まる一番細かい刻みを採る。
   */
  function collectContours(tiles, bounds, Rframe, stat) {
    var C = contourStyle();
    // ① 山名（＝山頂）を集める
    var peaks = [];
    tiles.forEach(function (t) {
      var A = t.layers.Anno;
      if (!A) return;
      for (var i = 0; i < A.features.length; i++) {
        var f = A.features[i];
        if (!MOUNTAIN_ANNO[f.props.vt_code]) continue;
        if (!f.geom.length || !f.geom[0].length) continue;
        var p0 = f.geom[0][0];
        var ll = GSI.tileToLonLat(t.x + p0[0] / A.extent,
                                  t.y + p0[1] / A.extent, t.z);
        if (!bboxHits([{ lat: ll.lat, lng: ll.lon }], bounds)) continue;
        peaks.push({ lat: ll.lat, lng: ll.lon });
      }
    });
    stat.peaks = peaks.length;
    stat.contours = 0;
    if (!peaks.length) return [];        // 🔴 山が無い地域＝何も起きない

    var R = Math.max(CNTR_RADIUS_MIN_M, Rframe * CNTR_RADIUS_FRAC);
    var lat0 = (bounds.north + bounds.south) / 2;
    // ② 山頂の周りにある等高線だけ集める（標高つき）
    var cand = [];
    tiles.forEach(function (t) {
      var Cl = t.layers.Cntr;
      if (!Cl) return;
      for (var i = 0; i < Cl.features.length; i++) {
        var f = Cl.features[i];
        var alti = Number(f.props.vt_alti);
        if (!isFinite(alti)) continue;
        for (var g = 0; g < f.geom.length; g++) {
          if (f.geom[g].length < 2) continue;
          var pts = toLatLngs(f.geom[g], t, Cl.extent);
          if (!bboxHits(pts, bounds)) continue;
          var near = false;
          for (var k = 0; k < peaks.length && !near; k++) {
            if (polylineDistM(pts, peaks[k], lat0) <= R) near = true;
          }
          if (!near) continue;
          cand.push({ alti: alti, points: pts });
        }
      }
    });
    if (!cand.length) return [];
    /* ③ 標高の刻みで間引く。粗い順に試して、CNTR_TARGET に収まる
     *    一番細かい刻みを採る（山の高さ・枠の広さで本数が桁違いに変わるため）。 */
    var step = CNTR_STEPS[0], n, si, kept;
    for (si = 0; si < CNTR_STEPS.length; si++) {
      n = 0;
      for (var ci = 0; ci < cand.length; ci++) {
        if (cand[ci].alti % CNTR_STEPS[si] === 0) n++;
      }
      step = CNTR_STEPS[si];
      if (n > CNTR_TARGET) {
        // 1つ粗い刻みへ戻す（先頭で既に超えている時は保険の上限で切る）
        if (si > 0) step = CNTR_STEPS[si - 1];
        break;
      }
    }
    kept = cand.filter(function (c) { return c.alti % step === 0; });
    if (kept.length > CNTR_MAX) kept = kept.slice(0, CNTR_MAX);
    stat.contours = kept.length;
    stat.contourStep = step;
    return kept.map(function (c) {
      return { id: uid('cn'), type: 'path', points: c.points,
               style: { w: C.w, color: C.color }, source: 'shozaizu' };
    });
  }

  /* ============ 名称の自動描画（🔒 2026-09-03・§23-5 の6分類を5段階で） ============ */

  /** 使う分類が1つでもあるか（全部「なし」なら false ＝ OSM を呼ばない）。
   * 🔒 §30-40-2 4: 「自動」（段 NAME_AUTO.level）も**使う**＝取りに行く。 */
  function anyNameCat(nameLevels) {
    if (!nameLevels || !global.OSM) return false;
    for (var i = 0; i < global.OSM.CATS.length; i++) {
      if (nameCatUsed(nameLevels[global.OSM.CATS[i].id])) return true;
    }
    return false;
  }

  /** 分類ぜんぶ（🔒 §30-13-7 7: 取得する分類は段に依らない・下の fetchOsmNames 参照。
   * 🔒 §30-21-2 で6分類 → 8分類。CATS を読むだけなので足し忘れは起きない） */
  function allNameCats() {
    var cats = Object.create(null);
    global.OSM.CATS.forEach(function (c) { cats[c.id] = true; });
    return cats;
  }

  /**
   * OSM から名称を取る。
   * 🔴 **段が全部「なし」の時は取りに行かない**（無駄な通信をしない・§23-6 控えめに叩く）。
   * 🔴 **fail-soft**: 落ちても reject しない。{error} を返して作図は続けさせる（§23-6）。
   *    広すぎる範囲（4km超）を osm.js が断る `wide` も同じ扱い。
   * 🔒 §30-13-7 7（2026-09-10 Fable 裁定）: **取る物は段に依らない**。
   *    1つでも「なし」でない分類があれば **6分類ぜんぶ＋路線** を一度に取る。
   *    絞るのは描く側（buildAutoNames の offer が段1を捨てる／routeShields は
   *    道路名の段で切る）。こうしないと段を変えるたびに osm.js の
   *    catsCovered が外れて Overpass を叩き直していた（⑦の遅さの正体）。
   *    枠（bounds）が同じ間は osm.js のキャッシュに当たる＝通信しない。
   */
  function fetchOsmNames(opts) {
    if (!anyNameCat(opts.nameLevels)) return Promise.resolve(null);
    /* 🔒 §30-25-3 1（2026-09-13 オーナー指示）: 地理院タイルも Overpass も
     * **同じ取得範囲（画面∪枠＋8%）を1回で取る**。枠の外に描くかは段で決める（areaFor）。
     * 🔴 osm.js は広すぎる範囲（MAX_SPAN_M）を断るので、その時だけ枠に戻す
     *    ＝地図をうんと広げた時に名前が丸ごと消えない保険（取れる分は必ず取る）。
     * 🔴 osm.js が自前で PAD ぶん広げて取るのは従来どおり＝縁ぎわの●の取りこぼし防止。 */
    var b = opts.bounds || opts.frameBounds;
    var lim = Number(global.OSM.MAX_SPAN_M) || Infinity;
    var lat0b = (b.north + b.south) / 2;
    var spanW = GSI.distanceMeters({ lat: lat0b, lng: b.west }, { lat: lat0b, lng: b.east });
    var spanH = GSI.distanceMeters({ lat: b.south, lng: b.west }, { lat: b.north, lng: b.west });
    if ((spanW > lim || spanH > lim) && opts.frameBounds) b = opts.frameBounds;
    /* 🔒 §22-av: 路線番号（国道・都道府県道）は**道路名と同じ段**に乗せる。
     * 🔴 「乗せる」のは**出す／出さない**の話（routeShields 側で切る）。取得は
     *    上のとおり段に依らず必ず一緒に取る（実測 2026-09-06・名駅 700m 枠:
     *    413KB → 464KB ＝ +51KB）。 */
    return global.OSM.fetchNames(b, allNameCats(), { routes: true })
      .then(function (r) {
      /* 🔒 §30-21-4 1: 応答が上限に当たった（名前を省いた）かをそのまま持ち上げる。
       * 🔴 作図は止めない（省いただけ＝取れた分は全部使う）。知らせるのは一言で。 */
      return { items: r.items, roads: r.roads, routes: r.routes || [],
               truncated: !!r.truncated,
               cached: !!r.cached, ms: r.ms, bytes: r.bytes, error: null };
    }, function (e) {
      return { items: [], roads: [], routes: [], truncated: false,
               error: (e && e.kind) || 'net',
               message: (e && e.message) || '' };
    });
  }

  /**
   * 🔒 §22-aq-2 ①: 「主役の周囲は絶対」に出す交差点名を選ぶ。
   * 主役（使用の本拠・駐車場）**ごと**に最寄り CROSS_MAIN_N 件（重複は1つ）。
   *
   * @param c   分類（osm.js CATS の1行）。交差点名以外は対象外
   * @param n   その分類の段（1〜5）。段1「なし」は 0 件（利用者が切った意味を守る）
   * @param arr dEff 順に並んだ候補（{it, dHome, dLot}）
   * @return    {添字:true} … 絶対に出す候補。交差点名以外・段1・主役なしなら null
   *
   * 🔴 段を見るのは「段1か否か」だけ＝段2〜5 で**同じ集合**になる（単調性・§22-ak-4）。
   * 🔴 「最寄り N 件」であって半径ではない。地方部では最寄りの交差点名が数百m 先に
   *    なることがあり、半径だと「絶対」が空振りする（§22-aq-2 ①）。
   * 🔒 §22-aq-4: 候補は offer() が**枠の中**に限っている（枠外は出さない）ので、
   *    枠の中に交差点名が無い土地では自然に 0 件になる（落ちない）。
   */
  function crossingMustSet(c, n, arr) {
    if (!c || c.id !== CROSSING_CAT || n <= 1 || !arr.length) return null;
    var set = null;
    ['dHome', 'dLot'].forEach(function (key) {
      var order = [], i;
      for (i = 0; i < arr.length; i++) {
        if (isFinite(arr[i][key])) order.push(i);
      }
      if (!order.length) return;                 // その主役が無い（片方だけの案件）
      order.sort(function (a, b) {
        var d = arr[a][key] - arr[b][key];
        // 同距離は dEff（＝並びそのもの）で決める。並べ替えの安定性に頼らない
        return d || (arr[a].dEff - arr[b].dEff) || (a - b);
      });
      for (i = 0; i < order.length && i < CROSS_MAIN_N; i++) {
        if (!set) set = Object.create(null);
        set[order[i]] = true;                    // 重複（両方の主役の最寄り）は1つ
      }
    });
    return set;
  }

  /**
   * 🔒 §22-ar ①: 「主役に接する通り名は絶対」に出す道路名（OSM 側）を選ぶ。
   * crossingMustSet と**同じ形**。違いは2つだけ:
   *   ・対象分類が 'road'
   *   ・ROAD_MAIN_M（100m）より遠い候補は対象にしない（交差点名は半径を掛けない §22-aq-2 ①
   *     だが、道路名は正典が明示的に「100m 以内」と決めている・§22-ar ①）
   *
   * @param c   分類（osm.js CATS の1行）。道路名以外は対象外
   * @param n   その分類の段（1〜5）。段1「なし」は 0 件
   * @param arr dEff 順に並んだ候補（{it, dHome, dLot}）＝ buildAutoNames の byCat.road
   * @return    {添字:true} … 絶対に出す候補。道路名以外・段1・主役なしなら null
   */
  function roadMustSet(c, n, arr) {
    if (!c || c.id !== 'road' || n <= 1 || !arr.length) return null;
    var set = null;
    /* 🔴 mHome/mLot ＝ その道路の**真の最近点**までの距離（buildAutoNames が
     * 呼ぶ前に arr へ焼いておく・無ければ代表点の距離 dHome/dLot に落ちる）。
     * mergeRoads の代表点（表示範囲内の頂点の重心に一番近い1点）は主役の
     * すぐそばを指すとは限らないため、代表点の距離だけで判定すると
     * 「実際には100m以内なのに絶対に入らない」が起きる（§22-ar 実装メモ）。 */
    ['mHome', 'mLot'].forEach(function (key) {
      var order = [], i;
      for (i = 0; i < arr.length; i++) {
        if (isFinite(arr[i][key]) && arr[i][key] <= ROAD_MAIN_M) order.push(i);
      }
      if (!order.length) return;
      order.sort(function (a, b) {
        var d = arr[a][key] - arr[b][key];
        return d || (arr[a].dEff - arr[b].dEff) || (a - b);
      });
      for (i = 0; i < order.length && i < ROAD_MAIN_N; i++) {
        if (!set) set = Object.create(null);
        set[order[i]] = true;
      }
    });
    return set;
  }

  /**
   * 🔒 §22-as: 主役ごとに「名前のある交差点」「名前のある通り」の候補が
   * ROAD_MAIN_M 以内に1つも無いかを判定する（生成時点・件数で絞る前）。
   *
   * 🔴 判定は**段（なし含む）に一切依らない**: crossing・road が「なし」の時に
   *    「データが無い」と言うと、ユーザーが自分で切っただけなのに誤診断してしまう
   *    （§22-ar/§22-aq-2 の「絶対」はその分類の段が2以上の時しか働かないので、
   *    「近くにあれば絶対で出ているはず」という前提が崩れる）。
   *    そこで呼び出し側（generate）が**crossing・road が両方 段2以上の時だけ**呼ぶ。
   * 🔴 osm が無い（＝取得しなかった／落ちた）時にここへ来ると全部「無い」判定に
   *    なってしまうので、これも呼び出し側が osmError を見て呼ばない。
   *
   * @param osm  fetchOsmNames の戻り（{items, roads}）
   * @param opts generate の opts（home/lot を見る）
   * @param objs これまでに作った図形（地理院の道路名 annoKind:'roadname' を拾う。
   *             これは段に関わらず常に生成されている＝§22-ar 実装メモ）
   * @param fb   枠（frameBounds || bounds）。候補は offer() と同じく枠の中に限る
   * @return {home:bool, lot:bool} … true ＝ そのデータが無い
   */
  function computeMainNoName(osm, opts, objs, fb) {
    var out = { home: false, lot: false };
    var lat0 = (fb.north + fb.south) / 2;
    var items = (osm && osm.items) || [];
    var roads = (osm && osm.roads) || [];
    function hasNear(mainP) {
      var i, k, p, pts;
      for (i = 0; i < items.length; i++) {
        if (items[i].cat !== CROSSING_CAT || !items[i].name) continue;
        p = { lat: items[i].lat, lng: items[i].lng };
        if (!inBoundsLL(p, fb)) continue;
        if (GSI.distanceMeters(p, mainP) <= ROAD_MAIN_M) return true;
      }
      for (i = 0; i < roads.length; i++) {
        if (!roads[i].name || !roads[i].geom || roads[i].geom.length < 2) continue;
        pts = [];
        var inside = false;
        for (k = 0; k < roads[i].geom.length; k++) {
          var q = { lat: roads[i].geom[k].lat, lng: roads[i].geom[k].lon };
          pts.push(q);
          if (inBoundsLL(q, fb)) inside = true;
        }
        if (!inside) continue;             // 枠外だけを通る道はここでは候補にしない
        if (polylineDistM(pts, mainP, lat0) <= ROAD_MAIN_M) return true;
      }
      for (i = 0; i < objs.length; i++) {
        if (objs[i].annoKind !== 'roadname' || !objs[i].text || !objs[i].at) continue;
        if (!inBoundsLL(objs[i].at, fb)) continue;
        if (GSI.distanceMeters(objs[i].at, mainP) <= ROAD_MAIN_M) return true;
      }
      return false;
    }
    if (opts.home) out.home = !hasNear(opts.home);
    if (opts.lot) out.lot = !hasNear(opts.lot);
    return out;
  }

  /**
   * 取ってきた OSM の名称を、分類ごとに5段階で絞って text オブジェクトにする。
   * @param osm      fetchOsmNames の戻り（null なら何もしない）
   * @param opts     generate の opts
   * @param objs     いままでに作った図形（**同名の重複を落とすのに読む**）
   * @param exNames  紙に既にある手描き等の文字（app.js が渡す）
   * @param Rframe   枠の対角の半分(m)
   * @param stat     統計（分類ごとの件数を書き込む）
   * @param gsiBase  🔒 2026-09-04 是正3: 段に依らない「地図に既にある名前」の基準集合
   *                 {names:{名前:true}, spots:[{p,name}]}（generate が注記から作る）
   * @return {add:[追加する text], dropIds:{id:true}} — dropIds は
   *         近接重複で**紙から落とす**地理院由来の名称（generate が splice する）
   */
  /**
   * 🔒 §22-av: 路線番号の印（▽ 国道 / 六角形 都道府県道）を作る。
   *
   * 置き場所は §22-ar（主役に接する通り名）と同じ考え方＝**主役に一番近い枠内の点**。
   * 番号は道そのものに付く物なので●（anchor）は付けない（§18-8）。
   *
   * @param osm  fetchOsmNames の戻り（routes を持つ・null 可）
   * @param opts generate の opts（home/lot を見る）
   * @param fb   枠（frameBounds || bounds）。枠の外には出さない（§22-aq-4 と同じ）
   * @param objs これまでに作った図形（地理院 2901 の▽と番号がだぶらないよう読む）
   * @return 追加する text 図形の配列（多くても ROUTE_MAX 件）
   */
  function routeShields(osm, opts, fb, objs) {
    var routes = (osm && osm.routes) || [];
    if (!routes.length || !fb) return [];

    function mainD(p) {
      var d = Infinity, d2;
      if (opts.home) d = GSI.distanceMeters(p, opts.home);
      if (opts.lot) { d2 = GSI.distanceMeters(p, opts.lot); if (d2 < d) d = d2; }
      return isFinite(d) ? d : 0;
    }

    /* 地理院の注記から既に出ている国道番号。同じ番号を2つ出さない
     * （地理院が先に出している時は OSM 側を足さない＝先勝ち・§23-6-a と同じ作法）。 */
    var have = Object.create(null), i, j;
    for (i = 0; i < objs.length; i++) {
      if (objs[i].badge && objs[i].routeNo) {
        have[objs[i].badge + '|' + objs[i].routeNo] = true;
      }
    }

    var lat0 = (fb.north + fb.south) / 2;

    /* 印は置いたら動かさない（下記）ので、置いてはいけない所を先に決めておく。
     *   ① 枠の縁ぎわ（紙で切れる）
     *   ② 紙の付き物＝方位記号・縮尺バーの場所（重なると両方読めない）
     * 🔴 ②の位置の出どころは export.js の Exporter.furnitureZones（読むだけ・
     *    placeLabels と同じ作法・§22-am-6-1 ⑦）。枠に対する 0〜1 の矩形で返るので、
     *    枠の緯度経度へそのまま写す。 */
    var padX = (fb.east - fb.west) * ROUTE_EDGE_PAD;
    var padY = (fb.north - fb.south) * ROUTE_EDGE_PAD;
    var inner = { west: fb.west + padX, east: fb.east - padX,
                  south: fb.south + padY, north: fb.north - padY };
    var furn = [], E = global.Exporter;
    if (E && E.furnitureZones) {
      var fwM = GSI.distanceMeters({ lat: lat0, lng: fb.west },
                                   { lat: lat0, lng: fb.east });
      var fhM = GSI.distanceMeters({ lat: fb.south, lng: fb.west },
                                   { lat: fb.north, lng: fb.west });
      E.furnitureZones({ aspect: fwM / Math.max(fhM, 1e-6) }).forEach(function (z) {
        furn.push({ west: fb.west + z.x0 * (fb.east - fb.west),
                    east: fb.west + z.x1 * (fb.east - fb.west),
                    north: fb.north - z.y0 * (fb.north - fb.south),
                    south: fb.north - z.y1 * (fb.north - fb.south) });
      });
      /* 🔒 §28-3: 部品として置かれた方位記号も「置いてはいけない所」に足す
       * （§22-av-2 の 4② と同じ。印は動かさないので、選ぶ時に外すしかない）。 */
      var cl = opts.compasses || [];
      if (cl.length && global.Editor && global.Editor.compassBox) {
        var mPerMmR = fwM / 138;
        var degLat = (fb.north - fb.south) / Math.max(fhM, 1e-6);   // 1m あたりの緯度
        var degLng = (fb.east - fb.west) / Math.max(fwM, 1e-6);     // 1m あたりの経度
        cl.forEach(function (p) {
          /* 🔒 §30-37 2: 大きさは記号ごと（基準 × markScale）＝ compassRMm 1か所 */
          var cbR = global.Editor.compassBox(compassRMm(p) * mPerMmR);
          furn.push({ west: p.lng - cbR.hw * degLng, east: p.lng + cbR.hw * degLng,
                      north: p.lat - (cbR.cy - cbR.hh) * degLat,
                      south: p.lat - (cbR.cy + cbR.hh) * degLat });
        });
      }
    }
    function badSpot(p) {
      if (!inBoundsLL(p, inner)) return true;
      for (var k = 0; k < furn.length; k++) {
        var f = furn[k];
        if (p.lng >= f.west && p.lng <= f.east
            && p.lat <= f.north && p.lat >= f.south) return true;
      }
      return false;
    }

    var cand = [];
    for (i = 0; i < routes.length; i++) {
      var r = routes[i], best = null;
      for (j = 0; j < r.pts.length; j++) {
        var p = r.pts[j];
        if (badSpot(p)) continue;
        var d = mainD(p);
        if (!best || d < best.d) best = { d: d, pt: p };
      }
      if (!best) continue;                       // 枠の中を1度も通らない路線は出さない
      cand.push({ key: r.kind + '|' + r.no, kind: r.kind, no: r.no,
                  d: best.d, pt: best.pt });
    }
    // 主役に近い路線から順に採る（枠に何本も走っている時は近い方が役に立つ）
    cand.sort(function (a, b) { return a.d - b.d; });

    /* 紙に描いた道路の線（この生成で作った path）。印をこの線へ寄せる。 */
    var drawn = [];
    for (i = 0; i < objs.length; i++) {
      if (objs[i].type === 'path' && objs[i].roadRank !== undefined
          && objs[i].points && objs[i].points.length >= 2) {
        drawn.push(objs[i].points);
      }
    }

    var out = [], used = Object.create(null);
    for (i = 0; i < cand.length && out.length < ROUTE_MAX; i++) {
      var c = cand[i];
      if (have[c.key] || used[c.key]) continue;  // 同じ路線は1枚に1つだけ
      used[c.key] = true;
      if (drawn.length) {
        var sn = nearestOnWays(drawn, c.pt, lat0);
        if (sn && sn.d <= ROUTE_SNAP_M && !badSpot(sn.pt)) c.pt = sn.pt;
      }
      out.push({ id: uid('rt'), type: 'text', at: c.pt, text: c.no,
                 size: 'medium', style: { color: '#111' },
                 /* 🔴 印の形はデータで持つ。表示文字（数字）では判定しない（注意②） */
                 badge: c.kind, routeNo: c.no,
                 nameCat: 'route', nameSrc: 'osm', source: 'shozaizu' });
    }
    return out;
  }

  function buildAutoNames(osm, opts, objs, exNames, Rframe, stat, gsiBase, areaFor) {
    var lv = opts.nameLevels || {};
    stat.names = {};
    /* 🔒 §30-40-2 5: 「自動」を選んだ分類が、どの段に決まったか（分類の id → 段）。
     * 画面の1行（app.js）はこの値を読む＝表示文字では分岐しない（§26-2 注意②）。 */
    stat.nameAuto = {};
    stat.namesTotal = 0;
    stat.nameDupGsi = 0;
    stat.nameDupBase = 0;
    stat.nameDupOsm = 0;
    if (!osm || !global.OSM) return { add: [], dropIds: null };

    /* 🔴 §23-6-a の名寄せをそのまま自動描画へ: 既存 text → 地理院 → OSM の**先勝ち**。
     *   ①app.js が渡した紙の上の文字（手描き・なぞり出し・別ソース）
     *   ②地理院の注記の**全候補**（🔒 是正3・段に依らない＝下の gsiBase.names）
     *   ③いまこの生成で作った文字（役割ラベル＝使用の本拠／駐車場／距離）
     * の順に登録してから OSM を見るので、同名は必ず先に居る方が残る。
     * 🔴 ②を「厳選後に紙へ残った物」ではなく**全候補**にしたのが是正3の肝。
     *    紙に残った物だけを見ると、目標物の段（lmLevel）を動かすたびに
     *    OSM 側の出力が変わる＝分類の独立性が壊れる（§22-ak-6）。 */
    var baseNames = Object.create(null), i, kk;
    if (exNames) for (i = 0; i < exNames.length; i++) baseNames[exNames[i]] = true;
    if (gsiBase && gsiBase.names) {
      for (kk in gsiBase.names) baseNames[kk] = true;
    }
    for (i = 0; i < objs.length; i++) {
      if (objs[i].type === 'text' && objs[i].text) baseNames[objs[i].text] = true;
    }
    var baseSpots = (gsiBase && gsiBase.spots) ? gsiBase.spots : [];

    var fb = opts.frameBounds || opts.bounds;
    /* 🔒 §30-25-3 2（2026-09-13 オーナー指示）: 名前を描く範囲は**その分類の段**で決める
     * （1〜3＝枠の中／4 多め・5 全部＝取得範囲＝画面に映っている所）。
     * 🔴 範囲の出どころは generate の areaFor 1か所（建物・道路と同じ物）。
     * 🔒 §30-40-2 3: 「自動」（段 NAME_AUTO.level）は areaFor が枠を返す段＝
     *    **枠の中だけ**。自動で決めた段（下の ④）は件数と半径にしか使わない
     *    ので、ここには渡さない（自動で枠の外へ広がらない）。 */
    function areaOf(catId) { return areaFor ? areaFor(lv[catId]) : fb; }
    // 分類ごとの候補置き場と、分類ごとの同名よけ（🔴 分類をまたがない・是正3）
    var byCat = Object.create(null), seenInCat = Object.create(null);
    global.OSM.CATS.forEach(function (c) {
      byCat[c.id] = [];
      seenInCat[c.id] = Object.create(null);
    });

    function offer(it) {
      /* 🔒 §30-40-2 2: 候補集めは段の大小を見ない（「なし」だけ捨てる）。
       * 「自動」もここでは普通に集め、段は下の ④ の直前で決める。 */
      if (!nameCatUsed(lv[it.cat])) return;     // その分類は「なし」
      if (!it.name) return;
      var p = { lat: it.lat, lng: it.lng };
      /* 🔒 §22-aq-4（2026-09-05 オーナー決定「A」）: 枠の外は**分類を問わず**落とす。
       * 交差点名だけ枠外 CROSS_OUT_M まで候補に残す §22-aq-2 ② は撤回した
       * （紙では枠で切れる＝どこにも行かない線にしかならない・§18-n-4 に戻す）。 */
      // 🔒 §30-25-3 2: 枠の外を描くかは**その分類の段**で決める（areaOf 1か所）
      if (!inBoundsLL(p, areaOf(it.cat))) return;
      var dHome = opts.home ? GSI.distanceMeters(p, opts.home) : Infinity;
      var dLot = opts.lot ? GSI.distanceMeters(p, opts.lot) : Infinity;
      var dMain = Math.min(dHome, dLot);
      if (!isFinite(dMain)) dMain = 0;
      /* 🔴 実効距離＝距離＋優先順位×150m。**段に依らず1回だけ**決める。
       *    これで「半径で切る」も「件数で切る」も同じ並びの前置きになり、
       *    段の集合が必ず入れ子になる（§23-10-b の教訓＝単調性は構造で保証）。 */
      var rec = { it: it, dHome: dHome, dLot: dLot,
                  dEff: dMain + namePrio(it.cat, it) * NAME_PRIO_UNIT };
      /* 🔴 同名の重複よけは**その分類の中だけ**（是正3）。分類をまたいで名前を
       *    取り合うと、取り合う相手が居るかどうか＝**他の分類の段**で出力が変わる
       *    （実測: バス停「大津通」が段で切られて出ていないのに、道路名の
       *     「大津通」を消していた）。 */
      var seen = seenInCat[it.cat][it.name];    // 0 は「未登録」・1 以上が添字+1
      if (seen) return;                         // 同名は先に登録した1件だけ（従来どおり）
      // 🔴 地図に既にある名前（地理院・手描き）には**片方向で**負ける（段に依らない）
      if (baseNames[it.name]) { seenInCat[it.cat][it.name] = -1; return; }
      byCat[it.cat].push(rec);
      seenInCat[it.cat][it.name] = byCat[it.cat].length;
    }

    /* 🔴 分類の中は「近い＋公共性が高い」順。
     *    🔒 是正3: 分類どうしは名前を取り合わない（分類ごとに独立した候補置き場）。 */
    var items = osm.items || [];
    global.OSM.CATS.forEach(function (c) {
      if (c.id === 'road') return;              // 道路は名寄せしてから
      for (var k = 0; k < items.length; k++) {
        if (items[k].cat === c.id) offer(items[k]);
      }
    });
    // 🔒 §30-40-2 4: 道路名も「自動」を使う側に数える（nameCatUsed 1か所）
    if (nameCatUsed(lv.road) && osm.roads && osm.roads.length) {
      // 🔒 §30-25-3 2: 道路名の名寄せも道路名の段の範囲で（枠の外まで描く時は広く）
      var merged = global.OSM.mergeRoads(osm.roads, areaOf('road'));
      for (i = 0; i < merged.length; i++) offer(merged[i]);
    }

    /* ===== 🔒 2026-09-04 是正3（§22-ak-6）: 近接重複の抑制を「分類の中」に閉じる =====
     * 🔴 **大原則: 各分類の出力は、その分類の段だけで決まる**（オーナー実機報告
     *    「バス停をなしにすると出てくる交差点と消える交差点がある」）。
     *    是正2 は全 OSM 候補を1本に混ぜて潰していたため、ある分類の段を変えると
     *    **別の分類の出力が変わっていた**（実測: 交差点名を「なし」にすると
     *    バス停 標準が『名城町』→『市役所・市政資料館南・愛知県庁前』に総入れ替え）。
     *
     * 手順（Fable 決定）:
     *   ① 地理院の注記の**全候補**を段に依らず集めて「基準集合」にする
     *      （gsiBase・generate が作る。🔴 lmLevel も 川山トグルも見ない）
     *   ② OSM の各分類は、その基準集合と重なる候補を落とす（**片方向**・地理院が勝つ）
     *   ③ OSM どうしの近接重複は**同じ分類の中だけ**（分類をまたがない）
     *   ④ そのあと段で切る（従来どおり・前置き集合なので入れ子は保たれる）
     *
     * 🔒 これで「県庁前（交差点名）」と「愛知県庁前（バス停）」は**両方出る**。
     *    別の物（交差点とバス停）なので正しい。是正2 で潰したかったのは
     *    「愛知県庁／愛知県庁舎／愛知県庁本庁舎」＝**同じ施設の別名**の方で、
     *    それは③（同一分類内）で従来どおり潰れる。
     *
     * 🔴 対象は「**点に付く名前**」だけ＝ anchor を持つ地理院の名称と、
     *    OSM の `dot` が立つ分類。道路名・鉄道路線名・地名（＝線や面に付く名前）は
     *    ラベルの位置が「その物の場所」ではないので近接では潰さない（§18-8）。
     * 🔴 主役2地点のラベル（使用の本拠・駐車場）と距離ラベルは**対象外**＝
     *    `role` を持つ物は残しも潰しもしない（必ず出す・Fable 指定）。 */

    /* ②-a 地理院どうしの近接重複（＝紙に出ている地理院の名称の中だけで潰す）。
     * 🔴 ここは OSM を1件も見ない＝ OSM の段をどう動かしても地理院側は不変。 */
    var gsiKept = [], dropIds = Object.create(null), gsiCand = [];
    for (i = 0; i < objs.length; i++) {
      var go = objs[i];
      if (go.type !== 'text' || !go.text || !go.anchor || go.role) continue;
      gsiCand.push({ o: go, p: go.anchor, name: go.text,
                     dEff: gsiNameDEff(go, opts) });
    }
    gsiCand.sort(function (a, b) { return a.dEff - b.dEff; });
    for (i = 0; i < gsiCand.length; i++) {
      if (hitsKeptSpot(gsiKept, gsiCand[i])) {
        dropIds[gsiCand[i].o.id] = true;
        stat.nameDupGsi++;
      } else {
        gsiKept.push(gsiCand[i]);
      }
    }

    var out = [];
    global.OSM.CATS.forEach(function (c) {
      /* 🔒 §30-40-2 2: 「自動」（段 NAME_AUTO.level）はここではまだ段が決まらない。
       * 決まるのは近接重複（②-b/③）を落とした後（④の直前）なので、それまでは
       * 「上限いっぱいの段」として進める。この先で段の数字を見るのは
       *   ・crossingMustSet / roadMustSet … 段1「なし」かどうかだけ
       *   ・道路名の最近点の焼き込み       … 同上
       * なので、仮の段で結果は変わらない（④の件数・半径だけが段で決まる）。 */
      var auto = (nameLevelOf(lv[c.id]) === NAME_AUTO.level);
      var n = auto ? NAME_AUTO.allLevel : nameLevelOf(lv[c.id]);
      stat.names[c.id] = 0;
      if (n <= 1) return;
      var arr = byCat[c.id];
      arr.sort(function (a, b) { return a.dEff - b.dEff; });   // ②1回だけ並べる
      /* 🔒 §22-ar ①②: 道路名は「主役に最も近い点（枠内）」を真の距離・置き場所にする。
       * mergeRoads の代表点（表示範囲内の頂点の重心に一番近い1点）は主役のそばを
       * 指すとは限らないので、道路名だけ先に生ジオメトリ（osm.roads・マージ前の way）を
       * 名前で索引し、主役ごとの真の最近点を arr へ焼いておく（roadMustSet・置き場所の両方が読む）。 */
      if (c.id === 'road' && n > 1 && arr.length) {
        var lat0r = (fb.north + fb.south) / 2;
        var waysByName = Object.create(null);
        if (osm.roads) {
          for (i = 0; i < osm.roads.length; i++) {
            var rw = osm.roads[i];
            if (!rw.name || !rw.geom || rw.geom.length < 2) continue;
            var wpts = [];
            for (var gk = 0; gk < rw.geom.length; gk++) {
              wpts.push({ lat: rw.geom[gk].lat, lng: rw.geom[gk].lon });
            }
            if (!waysByName[rw.name]) waysByName[rw.name] = [];
            waysByName[rw.name].push(wpts);
          }
        }
        for (i = 0; i < arr.length; i++) {
          var ways0 = waysByName[arr[i].it.name];
          /* nearHome/nearLot ＝ {d,pt}（②の置き場所）。取れなければ null（従来の位置のまま）。
           * mHome/mLot ＝ ①の判定に使う実距離（無ければ代表点の距離 dHome/dLot に落ちる）。 */
          arr[i].nearHome = (ways0 && opts.home) ? nearestOnWays(ways0, opts.home, lat0r) : null;
          arr[i].nearLot = (ways0 && opts.lot) ? nearestOnWays(ways0, opts.lot, lat0r) : null;
          arr[i].mHome = arr[i].nearHome ? arr[i].nearHome.d : arr[i].dHome;
          arr[i].mLot = arr[i].nearLot ? arr[i].nearLot.d : arr[i].dLot;
        }
      }
      /* 🔒 §22-aq-2 ①・§22-ar ①: 主役ごとの最寄り件数＝「絶対に出す」交差点名・道路名。
       * 🔴 段に依らずここで決める（段2〜5 で同じ集合＝前置き集合になり単調性が保たれる）。
       * 🔴 近接重複（②-b/③）の**前**に決める。後だと「絶対の候補が dup かどうか」で
       *    絶対分が揺れ、枠外候補が枠内候補を潰したかどうかにも左右されるため。
       * 🔴 crossingMustSet と roadMustSet は互いに排他（c.id で分岐する）ので || でよい。 */
      var mustSet = crossingMustSet(c, n, arr) || roadMustSet(c, n, arr);
      /* ②-b/③ 近接重複を**段で切る前に1回だけ**潰す。
       * 🔴 判定に使う集合（基準集合＋この分類の候補）は段に依らないので、
       *    残る物の並びはどの段でも同じ＝段は前置きを取るだけ＝入れ子は保たれる。 */
      if (c.dot) {
        var catKept = [];
        /* 🔒 §22-aq-3 裁定（2026-09-05 Fable）: 交差点名は他分類（地理院の目標物・
         * お店・会社名・バス停・他の目印…）との近接重複の**適用外**にする。
         * 理由＝正典自身の「県庁前（交差点名）と愛知県庁前（バス停）は別の物だから
         * 両方出る」と同じ。交差点は建物の前の**道の点**であって建物ではない
         * （例: 「中央郵便局」交差点 vs 地理院目標物「名古屋中央郵便局」＝両方出す）。
         * 交差点名**どうし**の重複（catKept・同じ分類の中）は従来どおり見る。
         * 🔴 判定は nameCat（＝c.id）で行う。表示文字では判定しない（§26-2 注意②）。 */
        var skipBaseDup = (c.id === CROSSING_CAT);
        /* 🔒 §30-21-4 4（2026-09-13 Fable 裁定）: **建物名には ③ を掛けない**。
         * 団地の棟名は隣どうしが 40m 以内に並ぶので（実測「6棟」は「7棟」から 37m）、
         * 距離で「同じ場所」とみなす ③ が別々の棟を潰してしまう。
         * 建物名だけ **同名の重複だけ**を1つに寄せる（hitsKeptSameName）。
         * 🔴 判定は分類の id（c.id）で行う。表示文字では判定しない（§26-2 注意②）。 */
        var sameNameOnly = (c.id === BUILDING_CAT);
        for (i = 0; i < arr.length; i++) {
          var sp = { p: { lat: arr[i].it.lat, lng: arr[i].it.lng },
                     name: arr[i].it.name };
          if (!skipBaseDup && hitsKeptSpot(baseSpots, sp)) {   // ②地理院に負ける（片方向）
            arr[i].dup = true;
            stat.nameDupBase++;
          } else if (sameNameOnly ? hitsKeptSameName(catKept, sp)
                                  : hitsKeptSpot(catKept, sp)) {  // ③同じ分類の中の別名
            arr[i].dup = true;
            stat.nameDupOsm++;
          } else {
            catKept.push(sp);
          }
        }
      }
      /* 🔒 §30-40-2 2: 「自動」の段はここで決める ―― **枠の中に残った候補の数**
       * （近接重複を落とした後＝紙に出る見込みのある候補）を数え、
       * NAME_AUTO.allMax 以下なら allLevel・それより多ければ elseLevel。
       * 🔴 候補はもともと areaOf（＝自動は枠の中）に限ってあるので、
       *    この数がそのまま「枠の中の候補の数」になる。
       * 🔴 決めた段は下の ④（件数 cap・半径 R）にだけ効く。描く範囲は枠のまま。 */
      if (auto) {
        var nCand = 0;
        for (i = 0; i < arr.length; i++) { if (!arr[i].dup) nCand++; }
        n = (nCand <= NAME_AUTO.allMax) ? NAME_AUTO.allLevel : NAME_AUTO.elseLevel;
        stat.nameAuto[c.id] = n;
      }
      /* 🔒 §22-aq: 交差点名だけ段3以上は半径を掛けない（＝枠の中の全部が候補）。
       * 判定は分類の id（＝ nameCat）1か所で持つ。定数は NAME_LEVELS の隣。 */
      var noRadius = (c.id === CROSSING_CAT && n >= CROSSING_FRAME_FROM);
      var R = noRadius ? null : nameRadiusFor(n, Rframe);      // null＝半径では絞らない
      var cap = NAME_LEVELS[n].count;
      /* 🔒 §22-aq-2 ④: 段の件数を消費した数。**絶対分は件数に数えない**ので
       * stat.names（実際に出した数）とは別に持つ。 */
      var capUsed = 0;
      for (i = 0; i < arr.length && out.length < 4000; i++) {
        /* 🔴 近接重複で潰した候補は**飛ばすだけ**（break しない）。
         * 潰す判定は段に依らないので、残った物の並びはどの段でも同じ＝
         * 段は依然としてその並びの前置きを取るだけ＝入れ子は保たれる。 */
        if (arr[i].dup) continue;
        var must = !!(mustSet && mustSet[i]);
        if (!must) {
          /* ④件数・半径で前置きを切る。
           * 🔴 絶対分が居る時は break できない（この先に絶対分が残っているため）。
           *    集合としては同じ＝「前置き＋絶対分」なので単調性は保たれる。 */
          if (capUsed >= cap) { if (!mustSet) break; else continue; }
          if (R !== null && arr[i].dEff > R) { if (!mustSet) break; else continue; }
          capUsed++;
        }
        var it = arr[i].it;
        var atP = { lat: it.lat, lng: it.lng };
        /* 🔒 §22-ar ②: 道路名の絶対分だけ「主役に最も近い点（枠内）」へ動かす
         * （arr[i].nearHome/nearLot は上で1回だけ計算済み・選ばれた側のどちらか近い方を使う）。
         * 見つからない・枠外に出る時は**従来の位置のまま**（マージ済み代表点・報告する）。 */
        if (must && c.id === 'road') {
          var nh = arr[i].nearHome, nl = arr[i].nearLot, np;
          if (nh && nl) np = (nh.d <= nl.d) ? nh : nl;
          else np = nh || nl || null;
          if (np && inBoundsLL(np.pt, areaOf(c.id))) {
            atP = np.pt;
            stat.roadMainPlaced = (stat.roadMainPlaced || 0) + 1;
          } else {
            stat.roadMainFallback = (stat.roadMainFallback || 0) + 1;
          }
        }
        var tobj = { id: uid('nm'), type: 'text',
                     at: atP,
                     text: it.name, size: c.size || 'small',
                     style: { color: '#111' },
                     /* 🔴 分類と出どころをデータに焼く（表示文字で判定しない・注意②）。
                      * source は 'shozaizu'＝作り直しで差し替わる（なぞり出しは 'reveal'）。 */
                     nameCat: c.id, nameSrc: 'osm', source: 'shozaizu' };
        /* 🔒 §18-8 / §22-aj-2: 印を付けるのは「点に付く名前」だけ。
         * 印の種類（交差点名だけ信号機）は分類表 meta が唯一の出どころ。 */
        if (c.dot) {
          tobj.anchor = { lat: it.lat, lng: it.lng };
          /* 🔒 §30-21-2: 印は「その物ごとの印（it.mark）→ 分類の印（c.mark）」の順。
           * 信号の無い交差点・高速の出入口は it.mark='dot'＝●（信号機にしない）。 */
          var mk = it.mark || c.mark;
          if (mk && mk !== 'dot') tobj.dotStyle = mk;
        }
        out.push(tobj);
        stat.names[c.id]++;
        stat.namesTotal++;
      }
    });
    return { add: out, dropIds: dropIds };
  }

  /* ================= 生成 ================= */

  /**
   * 所在図を作る。
   * opts: {bounds, zoom, home, lot, bldgLevel:1〜5, nature:bool, metersPerPixel(lat),
   *        markStyle:'rect'|'circle', ← 主役の印の様式（既定 'rect'＝四角＋斜線・§25-4）
   *        marks:{home:{shape,color}, lot:{shape,color}}, ← 🔒 §28-14 ①-4: 形と色を
   *              **地点ごと**に指定する（渡された方が優先。無ければ markStyle）
   *        roadStyle:'line'|'band'}   ← 道路の描き方（既定 'line'＝黒線1本・§23-9）
   *   bldgLevel（🔒 §23-10）: 1=なし(既定) / 2=主役の周りだけ / 3=標準 / 4=多め / 5=全部
   *   roadStyle（🔒 §23-9）: 'line'=従来の黒線1本（既定・後方互換）
   *                          'band'=白い帯＋黒の縁取り（ヤフー式の2本描き）
   * 返り値: Promise<{objects:[], stats:{}}>
   */
  function generate(opts) {
    var bounds = opts.bounds;
    var roadStyle = (opts.roadStyle === 'band') ? 'band' : 'line';
    var roadTable = roadStyleTable(roadStyle);
    var bldgFill = bldgStyle();
    var bldgLevel = Math.max(1, Math.min(5, Number(opts.bldgLevel) || 1));
    var bldgCfg = BLDG_LEVELS[bldgLevel];
    /* 🔴 §23-10-b: 半径は D ではなく「枠の大きさ」＝ R_frame（描画範囲の対角の半分）に連動。
     * frameBounds（実際の紙面の枠）があればそれを優先、無ければ bounds（取得範囲＝
     * 枠+padding相当・runShozaizu が枠未決定でも渡す）で代用する。 */
    var bldgFrameB = opts.frameBounds || bounds;
    var bldgRframe = bldgFrameB
      ? GSI.distanceMeters({ lat: bldgFrameB.north, lng: bldgFrameB.west },
                            { lat: bldgFrameB.south, lng: bldgFrameB.east }) / 2
      : 0;
    var bldgR = bldgRadiusFor(bldgLevel, bldgRframe);  // null=段1(対象外)/段5(無制限)
    var bldgLat0 = (bounds.north + bounds.south) / 2;
    /* 🔒 §30-25-3 2（2026-09-13 オーナー指示）: **描く範囲は段で決める**。
     *   段 1〜3（なし・主役の周りだけ・標準） … 枠の中だけ（今まで通り）
     *   段 4（多め）・5（全部）              … 取得範囲の全部＝画面に映っている所
     * 🔴 出どころはこの1関数だけ（建物・道路・名前の8分類・目標物が同じ物を読む）。
     * 🔴 枠が無い生成（frameBounds なし）は取得範囲そのものが枠＝どの段でも同じ。 */
    var frameArea = opts.frameBounds || bounds;
    var SHOW_OUT_FROM = 4;                 // この段から枠の外にも描く
    function areaFor(level) {
      var n = Math.max(1, Math.min(5, Math.round(Number(level) || 1)));
      return (n >= SHOW_OUT_FROM) ? bounds : frameArea;
    }
    // 目標物（地理院の注記）の段。件数は opts.landmarks（LM_COUNT）が持つ
    var lmLevel = Math.max(1, Math.min(5, Math.round(Number(opts.lmLevel) || 1)));
    /* 🔒 2026-09-03: 道路の量も5段階。半径は建物と**同じ R_frame** に連動させる
     * （同じ枠なら「主役の周りだけ」の広さが建物と道路でそろう）。 */
    var roadLevel = Math.max(1, Math.min(5, Math.round(Number(opts.roadLevel) || 3)));
    var roadR = roadRadiusFor(roadLevel, bldgRframe);  // null=半径では絞らない
    /* 🔒 2026-09-03: 名称の6分類（§23-5）も5段階で自動描画する。
     * 🔴 タイルと OSM は**同時に**取りに行く（直列にすると待ち時間が足し算になる）。
     *    OSM は段が全部「なし」なら null を返す＝**通信そのものが起きない**。
     *    落ちても reject しない（fail-soft・§23-6）ので作図は必ず続く。 */
    /* 🔒 §30-13-5（2026-09-10）: ⑦の遅さの内訳を実測する（取得／整形／配置）。
     * 🔴 計るだけ（図には一切影響しない）。ラベルは3つとも 'shozaizu:' で始める。 */
    tStart('shozaizu:取得');
    return Promise.all([fetchTiles(bounds, opts.zoom), fetchOsmNames(opts)])
      .then(function (both) {
      tEnd('shozaizu:取得');
      tStart('shozaizu:整形');
      var got = both[0], osm = both[1];
      var objs = [], roadBuf = [], seenText = {}, seenPlace = {};
      /* 🔒 2026-09-04 是正3（§22-ak-6）: 名称の独立性の土台。
       * 「地図に既にある名前」の基準集合を**注記の全候補**から作る
       * （厳選＝段の前・トグルの前）。OSM の各分類はこれと重なる候補を落とす
       * ＝ 片方向・地理院が常に勝つ・**どの分類の段にも依存しない**。 */
      var gsiBaseNames = Object.create(null), gsiBaseSpots = [];
      var stat = { tiles: got.tiles.length, z: got.z, roads: 0, rails: 0,
                   buildings: 0, annoAll: 0, annoKept: 0, thinned: 0,
                   minRank: 0, kinds: {}, bldgLevel: bldgLevel,
                   roadLevel: roadLevel, roadStyle: roadStyle,
                   osmError: osm ? (osm.error || null) : null,
                   /* 🔒 §30-21-4 1: 名前が多すぎて Overpass の応答が上限に当たった。
                    * app.js が生成後の一言に足す（§22-as の警告と同じ仕組み）。 */
                   namesTruncated: !!(osm && osm.truncated),
                   osmUsed: !!osm };

      /* --- 🔒 2026-09-03: 川・山（トグル「川・山を入れる」の中身） ---
       * 🔴 **一番先に積む**＝道路・建物・文字の下に来る（配列順＝描画順）。
       *    水面のグレーの上に道路の白帯が乗る、が正しい重なり。 */
      /* 🔒 §30-25-3 2: 川・山は**5段階の設定を持たない**（2択のトグル）ので、
       * 描く範囲は今まで通り枠の中だけ（取得範囲が画面まで広がっても変わらない）。 */
      if (opts.nature !== false) {
        collectWater(got.tiles, frameArea, stat).forEach(function (o) { objs.push(o); });
        collectContours(got.tiles, frameArea, bldgRframe, stat)
          .forEach(function (o) { objs.push(o); });
      }

      /* --- 建物（🔒 §23-10・5段階の閾値。段1「なし」は従来のOFFと同じで生成しない） ---
       * 🔴 §23-10-b: 面積下限が「その場の分位点」になったため、道路等と違い2パスが要る。
       *    1パス目＝半径だけで候補を集める（面積はまだ見ない）。2パス目＝候補全体の
       *    面積を分位点にかけてしきい値を決め、そのしきい値（と主役近傍の例外）で確定する。 */
      if (bldgLevel >= 2) {
        var bldgCand = [];
        // 🔒 §30-25-3 2: 建物を描く範囲は建物の段で決める（4/5 は枠の外＝画面まで）
        var bldgArea = areaFor(bldgLevel);
        got.tiles.forEach(function (t) {
          if (!t.layers.BldA) return;
          var B = t.layers.BldA;
          for (var i = 0; i < B.features.length; i++) {
            var f = B.features[i];
            for (var g = 0; g < f.geom.length; g++) {
              if (f.geom[g].length < 3) continue;
              var pts = toLatLngs(f.geom[g], t, B.extent);
              if (!bboxHits(pts, bldgArea)) continue;
              var bc = ringCenter(pts);
              var dHome = opts.home ? GSI.distanceMeters(bc, opts.home) : Infinity;
              var dLot = opts.lot ? GSI.distanceMeters(bc, opts.lot) : Infinity;
              var dMain = Math.min(dHome, dLot);
              // 段2〜4: 半径の外は捨てる（段5は bldgR===null＝無制限）
              if (bldgR !== null && dMain > bldgR) continue;
              bldgCand.push({ pts: pts, dMain: dMain, area: polyAreaM2(pts, bldgLat0) });
            }
          }
        });
        var bldgThreshold = 0;
        if (bldgCfg.keepFrac) {
          var areasAsc = bldgCand.map(function (c) { return c.area; })
            .sort(function (a, b) { return a - b; });
          bldgThreshold = bldgAreaThreshold(areasAsc, bldgCfg.keepFrac);
        }
        bldgCand.forEach(function (c) {
          /* 🔴 主役2地点のすぐ近くは面積下限（分位点）を無視して全部残す（§18-r nearMain 同様）。
             🔒 §26-4-c 以降、分位点を持たないのは段5だけ（段2にも 35% が入った）。 */
          if (bldgCfg.keepFrac && c.dMain > BLDG_NEAR_MAIN_M && c.area < bldgThreshold) return;
          /* 🔒 §23-3/§23-9: 建物は**実線の輪郭のみ**（塗りは入れない）。
           * 太さ・色は Editor.MAPSTYLE.bldg が唯一の出どころ（bldgStyle）。
           * 旧値 {w:0.6,color:'#b9bfc9'} は紙で 0.114mm の薄灰＝白黒印刷で消えていた。 */
          objs.push({ id: uid('b'), type: 'polygon', points: c.pts,
                      style: { w: bldgFill.w, color: bldgFill.color },
                      source: 'shozaizu' });
          stat.buildings++;
        });
      }

      /* 🔒 §30-25-3 2: 道路は道路の段・鉄道と注記は枠（段を持たない物は今まで通り）。
       * 🔴 目標物（landmark）だけは段を持つので注記の中で別に見る。 */
      var roadArea = areaFor(roadLevel);
      var lmArea = areaFor(lmLevel);
      got.tiles.forEach(function (t) {
        var i, f, g, pts;

        /* --- 道路中心線（描画は後段。等級別に貯めてから間引きを決める） --- */
        if (t.layers.RdCL) {
          var R = t.layers.RdCL;
          for (i = 0; i < R.features.length; i++) {
            f = R.features[i];
            var rank = GSI.roadRank(f.props);
            var widthM = GSI.roadWidthM(f.props);       // §22-at・不明は undefined
            var floorU = GSI.roadFloorU(f.props);        // §22-at-2・不明は undefined
            for (g = 0; g < f.geom.length; g++) {
              if (f.geom[g].length < 2) continue;
              pts = toLatLngs(f.geom[g], t, R.extent);
              if (!bboxHits(pts, roadArea)) continue;
              roadBuf.push({ rank: rank, points: pts, widthM: widthM, floorU: floorU });
            }
          }
        }

        /* --- 鉄道（地下・トンネルは描かない） --- */
        if (t.layers.RailCL) {
          var L = t.layers.RailCL;
          for (i = 0; i < L.features.length; i++) {
            f = L.features[i];
            if (f.props.vt_railstate === '地下' ||
                f.props.vt_railstate === 'トンネル') continue;
            for (g = 0; g < f.geom.length; g++) {
              if (f.geom[g].length < 2) continue;
              pts = toLatLngs(f.geom[g], t, L.extent);
              // 🔒 §30-25-3 2: 鉄道は段を持たない＝枠の中だけ（今まで通り）
              if (!bboxHits(pts, frameArea)) continue;
              objs.push({ id: uid('r'), type: 'path', points: pts,
                          style: { w: 2.6, color: '#111', rail: true },
                          source: 'shozaizu' });
              stat.rails++;
            }
          }
        }

        /* --- 注記 --- */
        if (t.layers.Anno) {
          var A = t.layers.Anno;
          stat.annoAll += A.features.length;
          for (i = 0; i < A.features.length; i++) {
            f = A.features[i];
            /* 🔒 2026-09-04 是正3（§22-ak-6）: 名称の「基準集合」は
             * **段にもトグルにも依らない**全候補から作る。
             * 🔴 そのためここだけ nature を常に true で評価する
             *    （川・山トグルを切ると山名・河川名が候補から消え、
             *      OSM 側の出力が変わってしまうため）。 */
            var baseKind = GSI.annoKind(f.props.vt_code,
                                        { vegetation: false, nature: true });
            var kind = (opts.nature !== false) ? baseKind
              : GSI.annoKind(f.props.vt_code, { vegetation: false, nature: false });
            if (!baseKind) continue;
            var txt = f.props.vt_text;
            if (!txt || !f.geom.length || !f.geom[0].length) continue;
            // 🔒 §18-x-1: 地名は「◯丁目」を「（漢数字）」へ寄せてから扱う
            if (baseKind === 'place') txt = normPlaceName(txt);
            var p0 = f.geom[0][0];
            var ll = GSI.tileToLonLat(t.x + p0[0] / A.extent,
                                      t.y + p0[1] / A.extent, t.z);
            var at = { lat: ll.lat, lng: ll.lon };
            if (!bboxHits([at], bounds)) continue;
            /* 🔴 基準集合へは**厳選より前・段の判定より前**に入れる
             *    ＝ここが「地図に既にある名前」の唯一の出どころ（§22-ak-6 手順①）。
             *    ●が付く種別（＝点に付く名前）だけ近接判定にも使う。
             * 🔒 §30-25-3 2: 基準集合は**枠の中だけ**で作る（どの段にも依らない
             *    ＝是正3 の独立性を保つ。取得範囲が画面まで広がっても変わらない）。 */
            if (bboxHits([at], frameArea)) {
              gsiBaseNames[txt] = true;
              if (GSI.annoHasDot(baseKind, f.props.vt_code)) {
                gsiBaseSpots.push({ p: { lat: at.lat, lng: at.lng }, name: txt });
              }
            }
            if (!kind) continue;                 // 川・山トグルOFF時はここで描かない
            /* 🔒 §30-25-3 2: 描く範囲は分類の段で決める。段を持つのは目標物
             * （landmark）だけ＝それ以外（地名・道路名・鉄道名・川山）は枠の中だけ。 */
            if (!bboxHits([at], kind === 'landmark' ? lmArea : frameArea)) continue;
            // タイル跨ぎ・近接の重複を落とす
            var key = txt + '@' + at.lat.toFixed(4) + ',' + at.lng.toFixed(4);
            if (seenText[key]) continue;
            seenText[key] = true;
            /* 🔒 §18-x-1: 地名だけは**名前で**重複を落とす。
               同じ町名の2表記（210「三の丸（四）」/ 800「三の丸四丁目」）は
               座標が違うので位置つきの key では落ちない。 */
            if (kind === 'place') {
              if (seenPlace[txt]) continue;
              seenPlace[txt] = true;
            }

            /* 🔒 §18-8 / §18-j: 目標物は「●＝その場所（anchor・固定）」＋
             * 「文字＝脇（at・ドラッグ可）」の対で持つ。文字を動かしても●は動かない。
             * 🔴 どれに●を付けるかは **GSI.annoHasDot（除外リスト方式）** に任せる。
             *    ここで種別を列挙すると、新しい施設コードで●の付け忘れが起きる。
             * 🔒 §22-aa: vt_code も渡す。駅名(422)のように「分類は除外だが実体は点」
             *    という例外をコード単位で戻すため（判断は gsi.js 側に集約する）。 */
            var dot = GSI.annoHasDot(kind, f.props.vt_code);
            var tobj = { id: uid('t'), type: 'text', at: at, text: txt,
                         size: TEXT_SIZE[kind] || 'small',
                         style: { color: kind === 'place' ? '#444' : '#111' },
                         // 🔒 §18-r: 施設の「格」を後で引けるように元コードを持たせる
                         annoKind: kind, annoCode: f.props.vt_code, source: 'shozaizu' };
            /* 🔒 §22-av: 地理院の注記 2901 は**国道番号**（実測 2026-09-06: 名古屋・
             * 春日井・豊田で 19/22/41/153/155/248/301/302/419/420＝すべて国道）。
             * 数字だけだと何の番号か分からないので、逆三角形（おにぎり）の中に入れる。
             * 🔴 判定は vt_code。表示文字（数字）では判定しない（§26-2 注意②）。 */
            if (f.props.vt_code === GSI_ROUTE_NATIONAL && /^[0-9]{1,3}$/.test(txt)) {
              tobj.badge = 'national';
              tobj.routeNo = txt;
            }
            if (dot) tobj.anchor = { lat: at.lat, lng: at.lng };
            objs.push(tobj);
            stat.annoKept++;
            stat.kinds[kind] = (stat.kinds[kind] || 0) + 1;
          }
        }
      });

      /* --- 道路の自動間引き（正典 §5「広域では主要道路のみ」）＋ 5段階（2026-09-03） ---
       * 🔴 base（＝段3「標準」の等級の下限）は**全部の道路から1回だけ**出す。
       *    段ごとに出し直すと入れ子（単調性）が壊れる。 */
      var byRank = [0, 0, 0, 0, 0], maxRankPresent = 0;
      roadBuf.forEach(function (r) {
        byRank[r.rank]++;
        if (r.rank > maxRankPresent) maxRankPresent = r.rank;
      });
      var roadBase = 0;
      while (roadBase < RANK_CAP) {
        var remain = 0;
        for (var q = roadBase; q <= 4; q++) remain += byRank[q];
        if (remain <= MAX_ROADS) break;
        if (remain - byRank[roadBase] < MIN_ROADS) break;
        roadBase++;
      }
      /* 段ごとの残す条件。この2つ**だけ**で決める（＝集合が必ず入れ子になる） */
      var minRank = roadRankFloor(roadLevel, roadBase, maxRankPresent);
      stat.roadBase = roadBase;
      stat.minRank = minRank;
      var roadLat0 = bldgLat0;
      // 段1「なし」は道路を1本も描かない（roadBuf を回さない＝一番速い）
      if (roadLevel <= 1) roadBuf.length = 0;
      /* ①等級と半径の条件で候補を選ぶ（ここまでで S2 ⊂ S3 ⊂ S4' ⊂ S5 が確定） */
      var roadKeep = [];
      roadBuf.forEach(function (r) {
        if (r.rank < minRank) { stat.thinned++; return; }
        /* 段2「主役の周りだけ」＝主役2地点から roadR 以内を通る道だけ残す。
         * 段3〜5 は roadR が null なのでこの判定を通らない（＝半径は無制限）。 */
        if (roadR !== null) {
          var dMain = Infinity;
          if (opts.home) dMain = polylineDistM(r.points, opts.home, roadLat0);
          if (opts.lot) {
            var dL = polylineDistM(r.points, opts.lot, roadLat0);
            if (dL < dMain) dMain = dL;
          }
          if (dMain > roadR) { stat.thinned++; return; }
        }
        roadKeep.push(r);
      });

      /* ②段4「多め」だけ本数の上限を掛ける（段3＝従来は上限なし・段5＝全部も上限なし）。
       * 🔴 上限は**段3の本数（n3）以上**に持ち上げる。等級の高い物から順に採るので、
       *    段3 に入る道（等級 ≧ roadBase）は必ず全部この上限の中に入る＝ S3 ⊆ S4。
       *    数値（ROAD_BUDGET4）をどう変えても入れ子は壊れない＝構造での保証。
       * 🔴 採った後は**元の並び順に戻す**（描画順を変えない＝帯モードの run が崩れない）。 */
      if (roadLevel === 4) {
        var n3 = 0;
        for (var b3 = roadBase; b3 <= 4; b3++) n3 += byRank[b3];
        var budget = Math.max(n3, ROAD_BUDGET4);
        if (roadKeep.length > budget) {
          var lens = roadKeep.map(function (r) { return polylineLenM(r.points, roadLat0); });
          var order = roadKeep.map(function (r, i) { return i; });
          // 等級の高い順 → 同じ等級なら長い順（案内に効く道から採る）
          order.sort(function (a, b) {
            return (roadKeep[b].rank - roadKeep[a].rank) || (lens[b] - lens[a]);
          });
          var take = [];
          for (var ti = 0; ti < roadKeep.length; ti++) take.push(false);
          for (var ci = 0; ci < budget; ci++) take[order[ci]] = true;
          stat.thinned += roadKeep.length - budget;
          roadKeep = roadKeep.filter(function (r, i) { return take[i]; });
        }
      }

      /* ③図形にする */
      roadKeep.forEach(function (r) {
        /* 🔒 §23-9: 'line'＝黒線1本 / 'band'＝白い帯＋黒の縁取り。
         * 'band' の時だけ style.casing を立てる（画面 editor.js・紙 export.js の
         * 両方が casing を見て2本描きにする＝鉄道ハッチ st.rail と同じ作法）。
         * style.w は**外側（黒）の太さ**で、帯の太さは Editor.roadBand が算出する。 */
        var st = roadTable[r.rank] || roadTable[1];
        var rs = { w: st.w, color: st.color };
        if (st.casing) rs.casing = true;
        var rd = { id: uid('rd'), type: 'path', points: r.points,
                   style: rs, roadRank: r.rank, source: 'shozaizu' };
        // 🔒 §22-at: 幅員ランクの実距離(内部属性・表示文字ではない)。不明ランクは持たせない
        if (r.widthM) rd.widthM = r.widthM;
        // 🔒 §22-at-2: ランク別の紙の下限(内部属性)。不明ランクは持たせない＝等級の従来値のまま
        if (r.floorU) rd.floorU = r.floorU;
        objs.push(rd);
        stat.roads++;
      });

      /* --- 自宅⇄駐車場の破線・距離・2km判定（正典 §5） ---
       * 🔒 §30-22-1 6 / §30-22-6 2（2026-09-13 オーナー指示）: **同一住所（opts.same）の
       * 時は結線も直線距離も描かない**（同じ点を結ぶ長さ0の線と「約0m」は嘘の情報）。 */
      if (opts.home && opts.lot && !opts.same) {
        var m = GSI.distanceMeters(opts.home, opts.lot);
        var over = m > 2000;
        /* 🔴 a/b は **必ず座標を写す**。opts.home / opts.lot をそのまま入れると
         * 案件の points と**同じオブジェクト**を共有してしまい（2026-08-30 実測）、
         *  ・結線を掴んで動かすと**ピンごと動く**（図とピンが食い違う元）
         *  ・syncRoleObjects の「変わったか」判定が常に一致して**永久に直せない**
         *  ・保存 JSON に住所・title まで混ざる
         * という3つの不具合になっていた。 */
        objs.push({ id: uid('d'), type: 'line',
                    a: { lat: opts.home.lat, lng: opts.home.lng },
                    b: { lat: opts.lot.lat, lng: opts.lot.lng },
                    style: { w: 2.2, color: over ? '#c0392b' : '#111',
                             dash: '9 7' },
                    source: 'shozaizu', role: 'distance' });
        var mid = { lat: (opts.home.lat + opts.lot.lat) / 2,
                    lng: (opts.home.lng + opts.lot.lng) / 2 };
        objs.push({ id: uid('dl'), type: 'text', at: mid,
                    // 🔒 §18-x-5: 追従の基準（生成時の中点）。手でずらした分を保つのに使う
                    mid: { lat: mid.lat, lng: mid.lng },
                    text: fmtDist(m) + (over ? '（2km超）' : ''),
                    size: 'medium',
                    style: { color: over ? '#c0392b' : '#111' },
                    source: 'shozaizu', role: 'distance' });
        stat.distance_m = m;
        stat.over2km = over;
      }
      /* --- 使用の本拠・駐車場の主役マークとラベル ---
       * 🔒 §25-4（2026-08-29 オーナー指示）: 印は**◎（二重丸）から四角＋色＋斜線ハッチ**へ。
       * マークの形・色・大きさの定数は editor.js の Editor.MARK が唯一の出どころ
       * （Editor.makeMark が作る）。ラベル文字はそのまま残し、anchor はマークの中心に付く。
       * 🔴 旧◎の描画コードは editor.js / export.js に残してある（既存案件はそのまま開ける）。
       * 🔒 印の様式は選べる（2026-08-30 オーナー要望・opts.markStyle）:
       *    'rect'（既定）＝四角＋斜線ハッチ ／ 'circle' ＝ 従来の◎（二重丸）。
       *    ◎の時は四角を作らず、ラベルに dotStyle:'double' を付けて旧描画へ戻す。
       * 🔒 §28-14 ①-4（2026-09-07）: 形と色は**使用の本拠／駐車場ごと**に選べる
       *    （opts.marks = {home:{shape,color}, lot:{...}}・ガイダンス①が渡す）。
       *    opts.marks が無い呼び出しは従来どおり opts.markStyle で両方まとめて決まる
       *    ＝後方互換（色は Editor.MARK.kinds の既定＝本拠 赤／駐車場 オレンジ）。 */
      /* 🔒 §30-25-37 1: 印の大きさ（scale）も持ち回す（◎の輪・■の実寸に掛かる）。
       * 🔴 値の出どころは案件の points[key].mark.scale（app.js markOf → opts.marks）。 */
      var markOf = function (key) {
        var m = opts.marks && opts.marks[key];
        var sc = (global.Editor && global.Editor.clampMarkScale)
                 ? global.Editor.clampMarkScale(m && m.scale) : 1;
        /* 🔒 §30-31-1 2: ■の縦横（m）も持ち回す。無ければ undefined ＝
         * Editor.makeMark が「基準 × 大きさ」で補う（出どころは1か所のまま）。
         * 🔒 §30-35-3 4: ■の中心とピンの**ずれ**（dx_m/dy_m）も持ち回す
         *    ＝作り直しても掴んだ辺だけ伸ばした形（中心の位置）が戻らない。 */
        return { shape: (m && m.shape) ? m.shape
                        : ((opts.markStyle === 'circle') ? 'circle' : 'rect'),
                 color: (m && m.color) || null,
                 scale: sc,
                 w_m: (m && m.w_m > 0) ? m.w_m : undefined,
                 h_m: (m && m.h_m > 0) ? m.h_m : undefined,
                 dx_m: (m && isFinite(m.dx_m)) ? Number(m.dx_m) : 0,
                 dy_m: (m && isFinite(m.dy_m)) ? Number(m.dy_m) : 0 };
      };
      /* 🔒 §30-24-2（2026-09-13 オーナー指示・§30-22-1 6 の補正）: 同一住所でも
       * **文字は2つ**（「使用の本拠」と「駐車場」）。上下に並べ、別々に動かせる。
       * 印だけが1つ（本拠側の設定で描き、駐車場側は印を作らない）。 */
      var pinList = [['home', PIN_LABEL.home], ['lot', PIN_LABEL.lot]];
      pinList.forEach(function (kv) {
        var p = opts[kv[0]];
        if (!p) return;
        var want = markOf(kv[0]);
        /* 🔒 §30-22-1 6 / §30-24-2: 同一住所の時、駐車場側は印を描かない
         * （同じ場所に2つ重ねても掴めないだけ。印は本拠側の1つ＝設定も本拠側）。 */
        var shared = !!(opts.same && kv[0] === 'lot');
        var circleMark = (want.shape === 'circle') && !shared;
        /* 🔒 §30-22-1 4 (c): 「印なし（文字だけ）」＝四角も◎も描かない
         * 🔒 §30-24-1: 「多角形」＝利用者が描いた多角形が印なので◎■は描かない
         *    （多角形そのものは紙に残っている図形で、ここでは作らない）。 */
        var noMark = (want.shape === 'none') || (want.shape === 'polygon') || shared;
        var mk = null;
        if (!circleMark && !noMark && global.Editor && global.Editor.makeMark) {
          /* 🔒 §30-25-37 1: ■の実寸は「基準 × 大きさ」（Editor.markRectDims が出どころ）
           * 🔒 §30-31-1 2: 案件が縦横を持っていればそれが真実（want をそのまま渡す） */
          mk = global.Editor.makeMark(kv[0], p, uid('mk'), want.color, want.scale, want);
          objs.push(mk);
        }
        objs.push({ id: uid('lb'), type: 'text',
                    at: { lat: p.lat, lng: p.lng },
                    /* 🔒 §25-4: 文字をマークの**外**へ逃がすための控え（配置計算だけに使う）。
                     * 表示文字で種別を判定しないための持ち回しでもある（§26-2 注意②）。
                     * 🔒 §30-35-3 5: 中心の**ずれ**も控える（避ける箱はピン＋ずれで測る）。 */
                    mark: mk ? { w_m: mk.w_m, h_m: mk.h_m,
                                 dx_m: want.dx_m || 0, dy_m: want.dy_m || 0 } : null,
                    // anchor ＝ 地点そのもの（＝マークの中心）。文字は脇へ逃がす（§18-8）
                    anchor: { lat: p.lat, lng: p.lng },
                    /* 🔒 §26-2 注意②: どちらのピンの名前かを**表示文字ではなく**この印で持つ。
                     * 文字を書き換えられても追従（syncRoleObjects）が壊れない。 */
                    pinKey: kv[0],
                    /* 🔒 §25-4: 四角の時は●も◎も描かない（印は四角が担う）。
                     * ◎を選んだ時と旧データの 'double' は従来どおり二重丸で描かれる。 */
                    dotStyle: circleMark ? 'double' : 'none',
                    /* 🔒 §28-14 ①-4: ◎の色（形が四角の時は使われない）。
                     * 色の key は四角の印と同じ表（Editor.MARK.colors）。 */
                    markColor: want.color || null,
                    /* 🔒 §30-25-37 1: ◎の大きさ（輪の半径・線の太さ）。
                     * ■の時は使われない（四角が実寸で持つ）。 */
                    markScale: want.scale,
                    text: kv[1], size: 'large',
                    style: { color: '#111' },
                    /* 🔒 §30-24-5（2026-09-14 オーナー指示）: 同一住所の間は主役の
                     * 文字に引き出し線を出さない。生成直後の ensureMainLabels でも
                     * 揃うが、生成物はここだけで自己完結させる。 */
                    noLead: opts.same ? true : undefined,
                    source: 'shozaizu', role: 'pinlabel' });
      });

      /* --- 🔒 §18-r: 施設（目標物）を近い順・格の高い順に厳選する ---
       * 官庁街では施設注記が数十件出て判読不能になる（オーナー実機報告）。
       * 自宅の近く n/2 件＋駐車場の近く n/2 件だけ残す。**近くに無ければゼロのまま**。 */
      if (opts.landmarks !== undefined && opts.landmarks !== null) {
        var lmPts = [opts.home, opts.lot].filter(Boolean);
        // 🔒 §30-25-3 2: 目標物を描く範囲は目標物の段で決める（4/5 は画面まで）
        var lmAll = objs.filter(function (o) {
          return o.type === 'text' && o.annoKind === 'landmark'
              && inBoundsLL(o.anchor || o.at, lmArea);
        });
        var keepLm = Object.create(null);
        /* 🔒 2026-09-03: 3択 → 5段階になり、一番上の段「全部」が入った。
         * 「全部」＝**件数の上限も 500m の足切りも掛けない**（枠の中の目標物を全部出す）。
         * app.js が Infinity を渡す＝ pickLandmarks の per / slice に頼らない形にする。 */
        if (opts.landmarks === Infinity) {
          lmAll.forEach(function (o) { keepLm[o.id] = true; });
        } else {
          pickLandmarks(lmAll, lmPts, opts.landmarks).forEach(function (o) {
            keepLm[o.id] = true;
          });
        }
        for (var mi = objs.length - 1; mi >= 0; mi--) {
          var mo = objs[mi];
          if (mo.type === 'text' && mo.annoKind === 'landmark' && !keepLm[mo.id]) {
            objs.splice(mi, 1);
            stat.annoKept--;
          }
        }
        stat.landmarks = Object.keys(keepLm).length;
      }

      /* --- 🔒 §18-x-2: 地名も枠を決めて厳選する ---
       * 自宅の近く1・駐車場の近く1・2点の中間1・図の空いた隅1（既定4枠）。
       * 統合の結果それより少なければ少ないまま（無理に埋めない）。 */
      /* 🔒 §30-25-3 2: 地名は**5段階の設定を持たない**（枠の4枠に固定）ので、
       * 段で範囲を広げる対象にしない＝今まで通り枠の中だけ。 */
      var plLimit = (opts.places === undefined || opts.places === null) ? 4 : opts.places;
      if (plLimit >= 0) {
        var plAll = objs.filter(function (o) {
          return o.type === 'text' && o.annoKind === 'place'
              && inBoundsLL(o.anchor || o.at, opts.frameBounds);
        });
        var keepPl = Object.create(null);
        pickPlaces(plAll, opts.home, opts.lot, opts.frameBounds, plLimit)
          .forEach(function (o) { keepPl[o.id] = true; });
        for (var pi = objs.length - 1; pi >= 0; pi--) {
          var po = objs[pi];
          if (po.type === 'text' && po.annoKind === 'place' && !keepPl[po.id]) {
            objs.splice(pi, 1);
            stat.annoKept--;
          }
        }
        stat.places = Object.keys(keepPl).length;
      }

      /* --- 🔒 2026-09-03: 名称の6分類を5段階で自動描画（§23-5 / §22-ak-1 ⑦〜⑫） ---
       * 🔴 ここに置く理由は2つ:
       *   ①目標物・地名の**厳選が終わった後**なので、厳選で落ちた名前は
       *     「紙に無い名前」として OSM 側から出せる（先勝ちの相手は残った物だけ）
       *   ②ラベルの重なり回避（placeLabels）の**前**なので、自動で出した名称も
       *     他の文字と同じ規則で位置が決まる（後から足すと重なる） */
      var auto = buildAutoNames(osm, opts, objs, opts.existingNames,
                                bldgRframe, stat,
                                { names: gsiBaseNames, spots: gsiBaseSpots },
                                /* 🔒 §30-25-3 2: 分類の段 → 描く範囲（1か所） */
                                areaFor);
      /* 🔒 2026-09-04 是正2: 近接重複で負けた**地理院由来**の名称を紙から落とす。
       * 🔴 `objs` は generate のローカル配列なので splice してよい（§23-7-1 の
       *    「this.objects への代入禁止」は編集中の実配列の話で、ここは別物）。 */
      if (auto.dropIds) {
        for (var ndi = objs.length - 1; ndi >= 0; ndi--) {
          if (!auto.dropIds[objs[ndi].id]) continue;
          if (objs[ndi].annoKind === 'landmark' && stat.landmarks) stat.landmarks--;
          objs.splice(ndi, 1);
          stat.annoKept--;
        }
      }
      auto.add.forEach(function (o) { objs.push(o); });

      /* --- 🔒 §22-av: 路線番号の印（国道 ▽ / 都道府県道 六角形）---
       * 🔴 ここに置く（＝名称を足した後・placeLabels の前）理由は auto.add と同じ。
       *    後から足すと重なり回避の外に出てしまう。
       * 🔒 §22-av / §30-13-7 7: 路線番号は**道路名と同じ段**。道路名が「なし」なら
       *    印も出さない。以前は「取らない」ことで出していなかったが、取得は段に
       *    依らなくなった（fetchOsmNames）ので、ここで段を見て切る。 */
      /* 🔒 §30-25-3 2: 路線番号の印は**枠のまま**（範囲を広げない）。この関数は
       * 「紙の付き物の席」を枠の割合で作るので、枠でない矩形を渡すと席がずれる。
       * 印は紙に出す物なので、枠の外まで出す意味も無い。 */
      /* 🔒 §30-40-2 4: 「自動」も道路名を使う側（nameCatUsed 1か所） */
      var shields = nameCatUsed((opts.nameLevels || {}).road)
                  ? routeShields(osm, opts, bldgFrameB, objs) : [];
      shields.forEach(function (o) { objs.push(o); });
      stat.routeShields = shields.length;
      stat.routeShieldsGsi = objs.filter(function (o) {
        return o.badge && o.nameCat !== 'route';
      }).length;

      /* --- 🔒 §22-as: 名前のデータが無い時の案内 ---
       * 🔴 crossing・road の**両方**が段2以上の時だけ判定する。どちらかが「なし」だと
       *    「近くにあれば絶対で出ているはず」という前提（§22-aq-2/§22-ar）が崩れ、
       *    ユーザーが自分で切っただけなのに「データが無い」と誤診断してしまうため。
       * 🔴 通信に失敗した時（osmError）も判定しない（「無い」と「取れなかった」は別）。
       *    osm.items/osm.roads は失敗時に空配列を返す（fail-soft）ので、
       *    ここで判定すると必ず「無い」になってしまう＝呼ばない。 */
      // 🔒 §30-40-2 4: 「使う」判定は nameCatUsed 1か所（自動も使う側）
      var nlv = opts.nameLevels || {};
      if (!stat.osmError && nameCatUsed(nlv.crossing) && nameCatUsed(nlv.road)) {
        stat.mainNoName = computeMainNoName(osm, opts, objs, bldgFrameB);
      } else {
        stat.mainNoName = { home: false, lot: false };
      }

      /* --- ラベルの重なりを減らす（正典 §5「重なり回避」／§18-8「結線に被らない」） --- */
      // 文字は紙面で一定の大きさなので、重なり判定は「書き出す図の何割か」で見る。
      // 図の幅 (bounds の実距離) に対する比で文字の実効サイズを出す。
      var spanM = GSI.distanceMeters(
        { lat: (bounds.north + bounds.south) / 2, lng: bounds.west },
        { lat: (bounds.north + bounds.south) / 2, lng: bounds.east });
      // 🔒 §30-13-5: 整形（タイル→図形）はここまで／ここから配置（重なり回避）
      tEnd('shozaizu:整形');
      tStart('shozaizu:配置');
      var placed = placeLabels(objs, spanM, opts.home, opts.lot,
                              opts.frameBounds || null,
                              /* 🔒 §22-am-6: 枠が無い生成では取得範囲を枠の代わりにする
                               * （枠外ドロップ・はみ出し罰点は従来どおり効かせない）
                               * 🔒 §28-3: 部品の方位記号は名前が避ける障害物 */
                              { fallbackBounds: bounds,
                                /* 🔒 §30-22-2 2: 名前の位置（1=近く/2=標準/3=離す） */
                                nameGap: opts.nameGap,
                                /* 🔒 §30-24-2: 同一住所（印は1つ・文字は2つ） */
                                same: !!opts.same,
                                /* 🔒 §30-24-1: 利用者が描いた主役の多角形（印の実寸）。
                                 * 生成物ではないので app.js が渡す（描いた順） */
                                mainPolys: opts.mainPolys || [],
                                compasses: opts.compasses || [] });
      tEnd('shozaizu:配置');
      stat.labelMoved = placed.moved;
      stat.labelOnLine = placed.onLine;
      /* 🔒 §22-am-6-4 の実測用の内訳:
       * outer=引き出し線つきで空き地へ／side=●のすぐ脇（1行以内・線なし）／
       * spill=除外を全部満たす候補が無く最善へ落とした数／
       * stay=その場（道路名・地名・川山・主役） */
      stat.labelOuter = placed.outer;
      stat.labelSide = placed.side;
      stat.labelSpill = placed.spill;
      stat.labelStay = placed.stay;
      /* 🔒 §22-am-7 実測用: spill（forced）のうち結線を跨いだ数／重なりの最大値の配列 */
      stat.labelSpillCross = placed.spillCross;
      stat.labelSpillOverlap = placed.spillOverlap;

      /* 🔒 §18-n-4: 紙の枠から出てしまう注記は落とす。
       * ●（＝その場所）が枠の外にある名前は、紙では●が写らず文字だけが
       * 宙に浮く（実機では枠端で見切れて積み重なっていた）。
       * 役割つき（自宅・駐車場・距離）は必ず残す。 */
      if (placed.drop && placed.drop.length) {
        var kill = Object.create(null);
        placed.drop.forEach(function (o) { kill[o.id] = true; });
        for (var di = objs.length - 1; di >= 0; di--) {
          if (kill[objs[di].id]) objs.splice(di, 1);
        }
        stat.annoDropped = placed.drop.length;
        stat.annoKept -= placed.drop.length;
      }

      /* --- 🔒 §30-23: 枠に入った「目印」の件数 ---
       * 枠が狭すぎると周りの施設が全部枠の外に出て、紙に目印が1つも載らない
       * （オーナー実機・ZL19 の枠は横 150m ほど＝250〜500m 先の変電所・公園・団地が外）。
       * app.js が生成後の一言に足す（§22-as・§30-21-4 1 と同じ仕組み）。
       * 🔴 数えるのは**場所を指す名前**だけ＝地理院の目標物（annoKind:'landmark'）と
       *    OSM の点に付く名前（nameSrc:'osm'・公共的建物／交差点名／お店／会社／バス停／
       *    施設・公園／建物名）。道路名（road）と路線番号の印（route）は「線に付く名前」で
       *    どんなに狭い枠でも必ず出る＝目印の有無の判定にならないので**除く**。
       * 🔴 判定は annoKind / nameCat / nameSrc（データ）で行う。表示文字では分岐しない
       *    （§26-2 注意②）。位置は**●の場所**（anchor）で見る＝重なり回避で文字が
       *    外へ動いた分は枠の外に出たと数えない。 */
      var markFrameB = opts.frameBounds || bounds;
      stat.marksInFrame = objs.filter(function (o) {
        if (o.type !== 'text' || o.role) return false;
        var isLandmark = (o.annoKind === 'landmark');
        var isOsmSpot = (o.nameSrc === 'osm' && o.nameCat
                         && o.nameCat !== 'road' && o.nameCat !== 'route');
        if (!isLandmark && !isOsmSpot) return false;
        return inBoundsLL(o.anchor || o.at, markFrameB);
      }).length;

      return { objects: objs, stats: stat, zoom: got.z, minRankJa: RANK_JA[minRank] };
    }).catch(function (e) {
      /* 🔒 §30-13-7 7: 途中で失敗しても計測は必ず閉じる（finally 相当）。
       * 開いたままだと次の生成の console.time が「Timer already exists」を出す。
       * 🔴 図の結果は変えない＝そのまま投げ直す。 */
      tEndAll();
      throw e;
    });
  }

  function fmtDist(m) {
    return m >= 1000 ? '約' + (m / 1000).toFixed(2) + 'km' : '約' + Math.round(m) + 'm';
  }

  function inBoundsLL(p, b) {
    if (!b) return true;
    return p.lng >= b.west && p.lng <= b.east && p.lat >= b.south && p.lat <= b.north;
  }

  /* ---------- 地名の表記ゆれを揃える（🔒 §18-x-1） ----------
   * 地理院の注記は同じ街区を2つの書き方で持っている:
   *   vt_code 210「三の丸（四）」／vt_code 800「三の丸四丁目」
   * どちらも拾うと**同じ町名が2つ並ぶ**（実機で確認）。
   * 「◯丁目」を「（漢数字）」へ寄せてから、同名を1つに統合する。 */
  var KANJI_DIGIT = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

  function toKanjiNum(s) {
    if (/^[〇一二三四五六七八九十百千]+$/.test(s)) return s;      // すでに漢数字
    var n = parseInt(s, 10);
    if (isNaN(n) || n < 0) return s;
    if (n < 10) return KANJI_DIGIT[n];
    if (n < 100) {
      var t = Math.floor(n / 10), o = n % 10;
      return (t > 1 ? KANJI_DIGIT[t] : '') + '十' + (o ? KANJI_DIGIT[o] : '');
    }
    return String(n);
  }

  /** 「三の丸四丁目」「三の丸4丁目」→「三の丸（四）」。それ以外はそのまま */
  function normPlaceName(s) {
    var t = String(s || '').trim();
    // 全角の算用数字は半角へ寄せてから見る
    t = t.replace(/[０-９]/g, function (c) {
      return String.fromCharCode(c.charCodeAt(0) - 0xFEE0);
    });
    return t.replace(/([0-9]+|[〇一二三四五六七八九十百千]+)丁目$/, function (m, num) {
      return '（' + toKanjiNum(num) + '）';
    });
  }

  /* ---------- 地名の厳選（🔒 §18-x-2） ----------
   * 施設（§18-r）と同じ考え方で枠を決める:
   *   自宅の近く1・駐車場の近く1・2点の中間1・図の空いた隅1。
   * 🔴 統合した結果1つで足りるならそれでよい（無理に4つ埋めない）。 */
  function pickPlaces(list, home, lot, frameBounds, limit) {
    if (!(limit > 0) || !list.length) return list.slice(0, 0);
    var spots = [];
    if (home) spots.push({ lat: home.lat, lng: home.lng });
    if (lot) spots.push({ lat: lot.lat, lng: lot.lng });
    if (home && lot) {
      spots.push({ lat: (home.lat + lot.lat) / 2, lng: (home.lng + lot.lng) / 2 });
    }
    // 「図の空いた隅」＝ 4隅のうち結線から一番遠い角
    if (frameBounds) {
      var corners = [
        { lat: frameBounds.north, lng: frameBounds.west },
        { lat: frameBounds.north, lng: frameBounds.east },
        { lat: frameBounds.south, lng: frameBounds.west },
        { lat: frameBounds.south, lng: frameBounds.east }
      ];
      var best = null, bestD = -1;
      corners.forEach(function (q) {
        var d = (home && lot)
          ? Math.min(GSI.distanceMeters(q, home), GSI.distanceMeters(q, lot))
          : GSI.distanceMeters(q, spots[0] || q);
        if (d > bestD) { bestD = d; best = q; }
      });
      if (best) spots.push(best);
    }
    var seen = Object.create(null), out = [];
    spots.forEach(function (sp) {
      if (out.length >= limit) return;
      var pick = null, pd = Infinity;
      list.forEach(function (o) {
        if (seen[o.id]) return;
        var d = GSI.distanceMeters(sp, o.anchor || o.at);
        if (d < pd) { pd = d; pick = o; }
      });
      if (pick) { seen[pick.id] = true; out.push(pick); }
    });
    return out;
  }

  /* ---------- 施設（目標物）の厳選（🔒 §18-r） ----------
   * 「近さ」と「目標物の格」（GSI.annoGrade）を足したスコアで選ぶ。
   * 近さだけで選ぶと官庁街で案内に効かない名前が並び、
   * 格だけで選ぶと図の端の学校が採られる。両方を見る。 */
  var LM_NEAR_M = 500;        // ここまでを「近く」とみなす（これより遠い物は採らない）
  var LM_DIST_UNIT = 150;     // 150m 離れる ＝ 格 1つ分の不利

  /**
   * pts（自宅・駐車場）それぞれの近くから limit/pts 件ずつ採る。重複は詰める。
   * 🔴 足りなくても遠くから埋めない（オーナー指示「無ければ無しで」）。
   */
  function pickLandmarks(list, pts, limit) {
    if (!(limit > 0) || !list.length || !pts.length) return [];
    var per = Math.ceil(limit / pts.length);
    var seen = Object.create(null), chosen = [];
    pts.forEach(function (p) {
      var ranked = [];
      list.forEach(function (o) {
        var d = GSI.distanceMeters(p, o.anchor || o.at);
        if (d > LM_NEAR_M) return;
        ranked.push({ o: o, s: GSI.annoGrade(o.annoCode) - d / LM_DIST_UNIT });
      });
      ranked.sort(function (a, b) { return b.s - a.s; });
      var got = 0;
      for (var i = 0; i < ranked.length && got < per; i++) {
        if (seen[ranked[i].o.id]) continue;
        seen[ranked[i].o.id] = true;
        chosen.push(ranked[i]);
        got++;
      }
    });
    // 端数で limit を超えた時は良い順に切る
    chosen.sort(function (a, b) { return b.s - a.s; });
    return chosen.slice(0, limit).map(function (r) { return r.o; });
  }

  /**
   * 文字の位置を決める（貪欲法・正典 §5「重なり回避」＋ §18-8「結線に被らない」）。
   *
   * 変更点（§18-8）:
   *   ・文字は **anchor（●の位置）の脇**へ置く。候補は anchor の周り8方向×3距離。
   *   ・コストに「**所有者⇄駐車場の結線コリドーとの重なり＝大ペナルティ**」を入れて、
   *     基本は線の外側へ出す。結線そのもの（破線）と距離の文字も線から少し逃がす。
   *   ・完全には解けない。手直しの回数を減らせれば十分（正典 §0）。
   *
   * 計算はメートルの平面座標（東=+x／北=+y）で行う。緯度経度のまま扱うと
   * cos 補正を至る所に書くことになり、距離の比較を間違えやすい。
   *
   * 🔒 §22-am（2026-09-04）: **点に付く名前（anchor があり role が無い物）は
   *    この候補生成を使わず、枠の外帯へ出す**（placeOuter）。その場に残るのは
   *    主役・道路名・鉄道の路線名・川山（nature）・地名（place）だけ。
   *
   * opts（省略可）:
   *   only            … この配列の物**だけ**を置き直す（なぞり出しの追加・§22-am-3）。
   *                     それ以外の文字は「もう置いてある障害物」として扱う。
   *   fallbackBounds  … frameBounds が無い時に枠とみなす範囲（＝生成の取得範囲）。
   *                     🔴 枠外ドロップ・枠はみ出しの罰点には**使わない**（従来どおり
   *                     frameBounds が無ければ効かせない）。外帯の位置決めだけに使う。
   */
  function placeLabels(objs, spanM, home, lot, frameBounds, opts) {
    var labels = objs.filter(function (o) { return o.type === 'text'; });
    if (!labels.length) {
      return { moved: 0, onLine: 0, drop: [], outer: 0, side: 0, stay: 0, spill: 0,
               spillCross: 0, spillOverlap: [] };
    }
    opts = opts || {};
    /* 置き直す対象を限る（なぞり出しの1件追加）。null＝全部置く（生成） */
    var onlySet = null;
    if (opts.only && opts.only.length) {
      onlySet = Object.create(null);
      for (var oi = 0; oi < opts.only.length; oi++) {
        if (opts.only[oi]) onlySet[opts.only[oi].id] = true;
      }
    }

    // 紙面の 138mm に対する文字の高さ(mm)を、この図の実距離に換算する
    var MM = { small: 2.6, medium: 3.4, large: 4.4 };
    var lat0 = labels[0].at.lat, lng0 = labels[0].at.lng;
    var M_LAT = 110540;
    var M_LNG = 111320 * Math.cos(lat0 * Math.PI / 180);
    function toXY(p) {
      return { x: (p.lng - lng0) * M_LNG, y: (p.lat - lat0) * M_LAT };
    }
    function hM(o) { return spanM * (MM[o.size] || MM.medium) / 138; }
    /* 🔒 §18-j: 文字の幅は **em で測る**（全角1.0／半角0.55）。
     * 🔴 以前は「文字数 × 0.62」で、日本語の実幅より 38% 小さかった。
     *    その幅で「●の脇」へ逃がしていたので、**●が文字の下に潜って消えていた**
     *    （名前が長いほど深く潜る＝区役所・郵便局で●が見えない実機不具合）。 */
    function emW(s) {
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
    /* 🔒 §22-am-8 裁定2（2026-09-06 Fable 裁定）: 文字の幅は**実寸**（canvas
     * measureText＝描画と同じ）で測る。箱の幅（boxOf）・引き出し線の隙間判定
     * （edgeToward からの gap）・lead の判定・重なり判定（overlap/maxOverlap）は
     * 全部この箱の w を通して計算されるので、**ここ1か所**を直せば全部そろう。
     * > Fable「`lead` の判定と隙間が em 幅で計算され、描画は実寸幅（カタカナで
     * >  em が25%広く、lead:false なのに紙で1.5行の隙間が空いて線が無い）。
     * >  箱の幅・隙間・lead の判定も実寸幅を使う」
     * editor.js の Editor.textDrawWidth(text, size) は canvas measureText を
     * そのフォントサイズで測る＝**戻り値は size と同じ単位**になる（フォント計測は
     * サイズに比例するため）。h（文字1行の高さ・m。既定 medium で数十m程度＝
     * 極小フォントサイズにはならない範囲）をそのまま size として渡せば、
     * 戻り値もそのまま m になる。フォントは描画と同じ "Yu Gothic UI","Meiryo",
     * sans-serif 700（style.css .obj-text と同じ・editor.js 内で固定）。
     * ブラウザで測れない時（canvas 2d が無い環境）だけ従来の em 見積りに落ちる。 */
    function textW(o, h) {
      if (global.Editor && global.Editor.textDrawWidth) {
        return global.Editor.textDrawWidth(o.text, h);
      }
      return emW(o.text) * h;
    }
    /* 🔒 §22-av: 路線番号の印は数字より外側に形（▽・六角形）があるので、
     * 箱の幅も印の幅で測る（他の文字がこの形を避けられるように）。
     * 形の寸法は editor.js の badgeGeom が唯一の出どころ（画面・紙と同じ）。 */
    function wM(o, h) {
      if (o.badge && global.Editor && global.Editor.badgeGeom) {
        return global.Editor.badgeGeom(o.text, h, o.badge).hw * 2;
      }
      return textW(o, h);
    }
    /* 🔒 §22-y（2026-08-28 オーナー実機報告）: 自宅・駐車場の◎に施設の●が
     * 近いと、●のすぐ脇に建物名を置いてしまうと主役の◎・名前とごちゃつく。
     * この距離より近い施設は candidates() で大きく逃がし、editor.js の
     * 引き出し線（_drawText の anno-lead・d > size*2.2+wHalf で自動描画）に任せる。 */
    var NEAR_MAIN_M = hM({ size: 'medium' }) * 3.5;
    function boxOf(o, cx, cy) {
      var h = hM(o);
      return { cx: cx, cy: cy, w: wM(o, h), h: h };
    }

    /* 結線（所有者⇄駐車場）。コリドー＝この線から半幅 corr の帯 */
    var seg = (home && lot) ? { a: toXY(home), b: toXY(lot) } : null;
    var corr = Math.max(spanM * 0.008, hM({ size: 'medium' }) * 0.75);

    /* 🔒 §18-n-4: 紙の記載欄そのものの範囲（メートル座標の矩形）。
     * 文字はこの中に収める。枠の縁ちょうどだと白フチが切れるので少しだけ内側を狙う。 */
    var fr = null, frRaw = null;
    if (frameBounds) {
      var sw = toXY({ lat: frameBounds.south, lng: frameBounds.west });
      var ne = toXY({ lat: frameBounds.north, lng: frameBounds.east });
      frRaw = { x0: Math.min(sw.x, ne.x), x1: Math.max(sw.x, ne.x),
                y0: Math.min(sw.y, ne.y), y1: Math.max(sw.y, ne.y) };
      // 縁ぴったりだと白フチが切れるので、文字の高さ 0.35 分だけ内側を狙う
      var inset = hM({ size: 'medium' }) * 0.35;
      fr = { x0: frRaw.x0 + inset, x1: frRaw.x1 - inset,
             y0: frRaw.y0 + inset, y1: frRaw.y1 - inset };
    }
    /* 文字が紙で占める半径。
     * 🔴 箱の h は「文字の高さ」だが、実際は下の出っ張りと白フチで
     *    0.73h ほど広がる。半分（0.5h）で見ると縁で切れる（実測で1件切れた）。 */
    function halfW(b) { return b.w / 2; }
    function halfH(b) { return b.h * 0.75; }

    /** 文字の箱が枠から食み出している割合（0=完全に内側／1=まるごと外） */
    function outsideFrame(b) {
      if (!fr) return 0;
      var hw = halfW(b), hh = halfH(b);
      var ox = Math.max(0, fr.x0 - (b.cx - hw), (b.cx + hw) - fr.x1);
      var oy = Math.max(0, fr.y0 - (b.cy - hh), (b.cy + hh) - fr.y1);
      return Math.min(1, Math.max(ox / Math.max(b.w, 1e-6), oy / Math.max(b.h, 1e-6)));
    }
    /** 点が枠の中にあるか（●が写らない注記を落とす判定に使う） */
    function inFrame(p) {
      return !frRaw || (p.x >= frRaw.x0 && p.x <= frRaw.x1 &&
                        p.y >= frRaw.y0 && p.y <= frRaw.y1);
    }

    /* 置く順番: 役割つき（自宅・駐車場・距離）→ 目標物 → 道路名・鉄道名 → 地名 →
       自然地名 → 点に付く名前。**先に置いた文字を、後から来た文字が避ける**（従来の思想）。

       🔴 2026-09-04 是正4（オーナー実機報告「道路名と会社名が重なっている」）:
          旧実装はこの表を `annoKind`（地理院の分類）だけで引いていた。
          **OSM 由来の名称は `annoKind` を持たない**ので全部が最下位の 5 になり、
          同順は安定ソート＝配列順＝分類の宣言順（public, crossing, shop, office,
          bus, road）＝ **道路名が会社名より後**に置かれていた。
          実測（名駅 枠700m・段5）: 道路名が平均 77m・最大 268m も道から離れ、
          道路名がらみの重なりが 44 組。
       🔒 是正: 順位は **`annoKind` と `nameCat` の両方**を見る1つの関数で決める。
          OSM／なぞり出しの道路名は地理院の `roadname` と**同じ 2**、点に付く分類
          （public/crossing/shop/office/bus）は従来どおり 5。
       🔴 `annoKind` は地理院データの意味を持つ識別子なので、OSM 側に捏造して
          持たせない（§26-2 注意②「表示や他分類の識別子を内部識別に流用しない」）。 */
    var RANK = { landmark: 1, roadname: 2, railname: 2, place: 3, nature: 4 };
    /* 🔒 §22-av: 路線番号の印（route）も「線に付く名前」なので道路名と同じ 2 */
    var CAT_RANK = { road: 2, route: 2 };  // OSM/なぞり出しの分類 → 同じ物差しに載せる
    function placeRank(o) {
      if (o.role) return 0;
      if (o.annoKind && RANK[o.annoKind]) return RANK[o.annoKind];
      if (o.nameCat && CAT_RANK[o.nameCat]) return CAT_RANK[o.nameCat];
      return 5;
    }
    /** 道路名か（＝線に付く名前・出どころを問わない）。表示文字では判定しない
     * 🔒 §22-av: 路線番号の印（o.badge）も**その道路そのもの**を指すので同じ扱い。
     * 🔴 これが無いと、印が●を持たない普通の文字として遠くへ動かされる
     *    （実測 2026-09-06: 道路の線から 11m 浮いた）。 */
    function isRoadName(o) {
      return o.annoKind === 'roadname' || o.nameCat === 'road' || !!o.badge;
    }
    labels.sort(function (a, b) { return placeRank(a) - placeRank(b); });

    var placedBoxes = [], dots = [], moved = 0, onLine = 0, drop = [];
    labels.forEach(function (o) {
      if (o.anchor) dots.push(toXY(o.anchor));
    });

    /* ===== 🔒 §22-am-1: 何をその場に置き、何を外へ出すか =====
     * 判定は **anchor（●）を持ち role が無い**物。表示文字では判定しない（§26-2 注意②）。
     * ・道路名／鉄道の路線名／川山(nature)／地名(place) は gsi.js の ANNO_NO_DOT と
     *   osm.js の CATS（road だけ dot:false）により **anchor を持たない** ＝ 自動的にその場。
     * ・駅名(422) だけは §22-aa で anchor を持つので外へ出る（§22-am-1 の表どおり）。
     * ・出どころ（地理院／OSM／なぞり出し）は問わない。 */
    function goesOuter(o) { return !!o.anchor && !o.role; }

    /* 紙の枠の矩形（メートル座標）。ふつうは紙の枠そのもの。
     * 🔴 枠が無い生成（frameBounds なし）では取得範囲を枠とみなす。
     *    枠外ドロップ・はみ出し罰点は従来どおり**効かせない**（fr / frRaw は null のまま）。 */
    var frameRect = frRaw;
    if (!frameRect && opts.fallbackBounds) {
      var fsw = toXY({ lat: opts.fallbackBounds.south, lng: opts.fallbackBounds.west });
      var fne = toXY({ lat: opts.fallbackBounds.north, lng: opts.fallbackBounds.east });
      frameRect = { x0: Math.min(fsw.x, fne.x), x1: Math.max(fsw.x, fne.x),
                    y0: Math.min(fsw.y, fne.y), y1: Math.max(fsw.y, fne.y) };
    }
    /* 候補の距離・回廊の幅・立入禁止域の余白の物差しになる「文字1行」の高さ(m)。
     * 🔴 枠があれば **枠の幅** で測る。generate() の spanM は取得範囲（枠 +8%）の幅なので、
     *    なぞり出し（枠しか知らない・§22-am-3）と物差しがずれてしまう。
     *    枠の幅で測れば生成と実体化の2経路で**同じ置き方**になる。 */
    var hRef = (frameRect ? (frameRect.x1 - frameRect.x0) : spanM) * MM.medium / 138;
    /* 🔒 §30-22-10: 「名前の位置」の段（1=近く／2=標準／3=離す）。
     * 🔴 値は案件（c.nameGap）→ generate の opts → ここ。表は nameGapStep 1か所。 */
    var gapStep = nameGapStep(opts.nameGap);

    /* 🔒 §22-am-6-1 ⑦（§22-am-5 の furnitureZones を**そのまま残す**）: 紙の付き物
     * （方位記号＝右上・縮尺バー＝左下・出典＝右下・通し表示＝左上）の席。
     * 実測（名駅）で「東海旅客鉄道株式会社」が縮尺バーの「100m」に丸かぶりした。
     * 🔴 位置の出どころは export.js の Exporter.furnitureZones（読むだけ）。 */
    var furnRects = [];
    (function collectFurniture() {
      var E = global.Exporter;
      if (!E || !E.furnitureZones || !frameRect) return;
      var fw = frameRect.x1 - frameRect.x0, fh = frameRect.y1 - frameRect.y0;
      E.furnitureZones({ aspect: fw / Math.max(fh, 1e-6) }).forEach(function (z) {
        /* 正規化（左上原点・y下向き）→ メートル（左下原点・y上向き） */
        furnRects.push({ x0: frameRect.x0 + z.x0 * fw, x1: frameRect.x0 + z.x1 * fw,
                         y0: frameRect.y1 - z.y1 * fh, y1: frameRect.y1 - z.y0 * fh });
      });
    })();
    /* 🔒 §28-3: 方位記号は「部品」になった（自動の付き物ではない）。置かれている
     * 場所は名前が避ける**障害物**として扱う（§22-am-6-1 ⑦ と同じ席の扱い）。
     * 🔴 大きさは紙面ミリ一定なので、枠の幅 ÷ 138mm でメートルに直す
     *    （hRef＝文字1行の高さ と同じ物差し）。形の出どころは Editor.compassBox。 */
    (function collectCompasses() {
      var list = opts.compasses || [];
      if (!list.length || !global.Editor || !global.Editor.compassBox) return;
      var mPerMm = (frameRect ? (frameRect.x1 - frameRect.x0) : spanM) / 138;
      list.forEach(function (p) {
        /* 🔒 §30-37 2: 大きさは記号ごと（基準 × markScale）＝ compassRMm 1か所 */
        var cb = global.Editor.compassBox(compassRMm(p) * mPerMm);
        var q = toXY(p);
        /* compassBox の cy は画面と同じ「y 下向き」なので、メートル（y 上向き）では符号が逆 */
        furnRects.push({ x0: q.x - cb.hw, x1: q.x + cb.hw,
                         y0: q.y - cb.cy - cb.hh, y1: q.y - cb.cy + cb.hh });
      });
    })();
    /** 文字の箱が紙の付き物の席に掛かるか（掛かる候補は除外する） */
    function hitsFurniture(b) {
      var hw = halfW(b), hh = halfH(b);
      for (var i = 0; i < furnRects.length; i++) {
        if (b.cx + hw > furnRects[i].x0 && b.cx - hw < furnRects[i].x1 &&
            b.cy + hh > furnRects[i].y0 && b.cy - hh < furnRects[i].y1) return true;
      }
      return false;
    }

    /** 文字の箱と結線の隔たり(m)。箱の 3×3 の点で測った最小値 */
    function segDist(b) {
      if (!seg) return Infinity;
      var hw = halfW(b), hh = halfH(b), d = Infinity, i, j;
      for (i = -1; i <= 1; i++) {
        for (j = -1; j <= 1; j++) {
          d = Math.min(d, distToSeg(b.cx + i * hw, b.cy + j * hh, seg.a, seg.b));
        }
      }
      return d;
    }
    /** 🔒 §22-am-6-1 ②: 結線を左右 PLACE.corr 行に広げた回廊の中か（＝候補から除外） */
    function inCorridor(b) {
      return !!seg && segDist(b) < PLACE.corr * hRef;
    }
    /** 🔒 §22-am-7 裁定1: 引き出し線（●→箱の縁）が結線（本拠⇄駐車場）を跨ぐか（＝候補から除外）。
     * > Fable「結線を横切る引き出し線が残る（三の丸『市役所東』: ●が回廊の縁で東・南は
     * >  枠外・南西は回廊 → 西へ逃げて結線を跨ぐ）。結線を横切る引き出し線は罰点でなく
     * >  除外にする（『結線から離れる』の趣旨）」
     * 🔴 従来（§22-am-6）は罰点（PLACE.wCross・awayCost 内の leadCrossings の seg 判定）
     *    止まりだったので、罰点を払ってでも跨いだ。segCrossSeg は本関数より後ろで
     *    定義されているが、いずれも `function` 宣言（hoisted）なので呼び出し順は無関係。 */
    function crossesConnector(b, p) {
      if (!seg) return false;
      var t = edgeToward(b, p);
      return segCrossSeg({ x: p.x, y: p.y }, { x: t.x, y: t.y }, seg.a, seg.b);
    }
    /** 🔒 §22-am-7 裁定2: 文字の箱が、既に置いた文字（点の名前・道路名・主役ラベルの区別なし・
     * placedBoxes 全部）と重なる面積比の最大値。PLACE.overMax（0.05）超は候補から除外する。
     * > Fable「文字どうしの重なりの最大値が悪化（三の丸全部 0.089→0.743）…旧の外帯は
     * >  『座った名前との重なり＝除外』だったのに新は罰点18止まり。除外に格上げ」
     * 🔴 罰点（PLACE.wOver）は残す（0.05 以下の軽い重なりの順位付けに使う）。 */
    function maxOverlap(b) {
      var m = 0, ov;
      for (var i = 0; i < placedBoxes.length; i++) {
        ov = overlap(b, placedBoxes[i]);
        if (ov > m) m = ov;
      }
      return m;
    }
    /** 🔒 §22-am-6-2: 箱の縁のうち点 p に最も近い点（＝引き出し線が止まる所・隙間 0） */
    function edgeToward(b, p) {
      var dx = p.x - b.cx, dy = p.y - b.cy;
      var m = Math.max(Math.abs(dx) / Math.max(halfW(b), 1e-6),
                       Math.abs(dy) / Math.max(halfH(b), 1e-6));
      if (m <= 1) return { x: p.x, y: p.y };        // ●が箱の中＝線は出ない
      return { x: b.cx + dx / m, y: b.cy + dy / m };
    }

    /* ===== 🔒 §22-am-5 欠陥1（2026-09-05 Fable 裁定）: 主役の印そのものの実寸 =====
     * 直す前は主役の印の箱を**主役ラベルの `o.mark` 控え**（生成時のスナップショット）
     * だけから作っていたので、
     *   ・◎（markStyle:'circle'・§22-ao で標準になった）では `o.mark` が null ＝
     *     紙面最小 4mm の四角として扱われ、◎の実寸と違っていた
     *   ・利用者が印を掴んで大きくしても控えが古いまま
     * だった。**印の実寸から出す**（Editor.MARK の定数・◎の半径・四角の一辺）。
     * 🔴 形の判定は `role`／`type`／`o.mark` の有無で行う（表示文字では判定しない・§26-2 注意②）。
     *
     * ① 四角の印 ＝ `type:'rect' role:'mainmark'` の実体（Editor.makeMark が作る）。
     *    利用者が変えた**いまの** w_m/h_m を読む。紙面最小 Editor.MARK.minMm を下回らない。
     * ② ◎の印 ＝ 主役ラベルに四角が付いていない時（markStyle:'circle' と旧データ）。
     *    editor.js `_drawText` の ◎は 外輪の半径 ＝ 文字の高さ × 0.48（r0 = size*0.24 の2倍）。 */
    var MARK_RING_R = 0.48;            // ◎の外輪の半径 ÷ 文字の高さ（editor.js `_drawText`）
    var markBoxes = [];
    /* 🔒 §30-22-10: 主役の四角の印の半幅(m)を pinKey ごとに控える
     * （「名前の位置＝近く」で文字を印のすぐ隣へ置くために読む）。 */
    var mainMarkHw = Object.create(null);
    (function collectMarks() {
      var minM = spanM * markMinMm() / 138, i, o, c, p, hw, hh, dg;
      var hasRect = Object.create(null);       // 主役ラベルの anchor に四角が居るか
      for (i = 0; i < objs.length; i++) {
        o = objs[i];
        if (!o || o.type !== 'rect' || o.role !== 'mainmark') continue;
        c = o.center || o.origin;
        if (!c) continue;
        p = toXY(c);
        hw = Math.max(o.w_m || 0, minM) / 2;
        hh = Math.max(o.h_m || 0, minM) / 2;
        /* 回した四角は外接する軸並行の箱で見る（角が飛び出すのを取りこぼさない） */
        if (o.angle) { dg = Math.sqrt(hw * hw + hh * hh); hw = dg; hh = dg; }
        markBoxes.push({ x: p.x, y: p.y, hw: hw, hh: hh });
        if (o.markRole) { hasRect[o.markRole] = true; mainMarkHw[o.markRole] = hw; }
      }
      /* 🔒 §30-24-1: 主役の印が**多角形**の時（利用者が描いた図形なので生成物には
       * 入っていない）は、app.js が opts.mainPolys で渡す。文字は多角形の**縁**から
       * 離して置きたいので、外接する箱の半幅を印の実寸として扱う（四角の印と同じ扱い）。
       * 🔴 ピン（anchor）は最初の多角形の重心なので、半幅もその多角形の物を使う。 */
      var mps = opts.mainPolys || [];
      for (i = 0; i < mps.length; i++) {
        var mp = mps[i];
        if (!mp || !mp.points || !mp.points.length) continue;
        var xs = mp.points.map(toXY);
        var x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity;
        xs.forEach(function (q) {
          if (q.x < x0) x0 = q.x;
          if (q.x > x1) x1 = q.x;
          if (q.y < y0) y0 = q.y;
          if (q.y > y1) y1 = q.y;
        });
        var phw = Math.max((x1 - x0) / 2, minM / 2), phh = Math.max((y1 - y0) / 2, minM / 2);
        markBoxes.push({ x: (x0 + x1) / 2, y: (y0 + y1) / 2, hw: phw, hh: phh });
        var mrole = (mp.markRole === 'lot') ? 'lot' : 'home';
        // 同じ地点に多角形が何個あっても、半幅は**最初の1つ**（ピンを持つ物）で決める
        if (mainMarkHw[mrole] == null) mainMarkHw[mrole] = phw;
      }
      for (i = 0; i < labels.length; i++) {
        o = labels[i];
        if (o.role !== 'pinlabel' || !o.anchor) continue;
        p = toXY(o.anchor);
        if (o.mark && (o.mark.w_m || o.mark.h_m)) {
          /* 四角の印。実体が objs に居ればそちらが正しいので二重に足さない
           * （実体の枝は o.center ＝ピン＋ずれで測っている・§30-35-3 5）。 */
          if (o.pinKey && hasRect[o.pinKey]) continue;
          hw = Math.max(o.mark.w_m || 0, minM) / 2;
          if (o.pinKey) mainMarkHw[o.pinKey] = hw;
          /* 🔒 §30-35-3 5: 実体が無い時の箱は**ピン＋ずれ**の位置（控えの dx/dy）。
           * toXY は x＝東・y＝北のメートルなので、そのまま足せる。 */
          markBoxes.push({ x: p.x + (o.mark.dx_m || 0), y: p.y + (o.mark.dy_m || 0),
                           hw: hw,
                           hh: Math.max(o.mark.h_m || 0, minM) / 2 });
        } else {
          var r = hM(o) * MARK_RING_R;         // ◎（二重丸）の外輪
          markBoxes.push({ x: p.x, y: p.y, hw: r, hh: r });
        }
      }
      /* 🔒 §30-24-2: 同一住所は印が**1つ**（本拠側）。駐車場の文字も同じ印の
       * 縁から離して置く（半幅の出どころを揃える）。 */
      if (opts && opts.same) {
        if (mainMarkHw.home != null && mainMarkHw.lot == null) mainMarkHw.lot = mainMarkHw.home;
        else if (mainMarkHw.lot != null && mainMarkHw.home == null) mainMarkHw.home = mainMarkHw.lot;
      }
    })();

    /* 🔒 §22-at-3 欠陥2-②（2026-09-06 Fable 裁定）: 道路の帯（style.casing &&
     * widthM を持つ道路＝実距離の帯）の面を、点に付く名前の障害物にする。
     * 除外ではなく罰点（PLACE.wBand・awayCost 内）＝「帯だらけの場所で置き場が
     * 無くなる」のを避けるため。道路名（isRoadName）は placeByCands/costOf 側で
     * 置かれ awayCost を通らない＝ここでは判定不要（帯の上に乗ってよい・§22-at-3）。
     * 🔴 外幅は Editor.roadBand と**同じ式**（唯一の実装・§22-at の作法）で出す:
     *   mPerU（1Uが何mか）＝ frameWidth(m) ÷ 1000。export.js の mPerU=mpp×S を
     *   代数的に展開すると DPI・用紙の向きに依らずこの比（NOMINAL_W=1000）に
     *   一致する。§22-at-3 の指示どおり近似でよい所なのでこの1点だけ導出済みの
     *   比を使う（面積比自体も後述 bandOverlap で近似）。
     * global.Editor が無い（単体テスト等）場合は widthM をそのまま外幅に使う。 */
    var bandLines = [];
    (function collectBands() {
      var wFrame = frameRect ? (frameRect.x1 - frameRect.x0) : spanM;
      var mPerU = wFrame / 1000;
      var RB = global.Editor && global.Editor.roadBand;
      for (var i = 0; i < objs.length; i++) {
        var o = objs[i];
        if (!o || !o.style || !o.style.casing || !(o.widthM > 0) || !o.points) continue;
        var bd = RB ? RB(o, { mPerU: mPerU }) : null;
        var outerM = bd ? bd.outer * mPerU : o.widthM;
        bandLines.push({ pts: o.points.map(toXY), halfM: outerM / 2 });
      }
    })();
    /** 折れ線 pts（xy・m）と点(px,py)の最短距離。distToSeg を線分ごとに掛ける版 */
    function polylineDistXY(pts, px, py) {
      if (!pts.length) return Infinity;
      if (pts.length === 1) {
        var dx = pts[0].x - px, dy = pts[0].y - py;
        return Math.sqrt(dx * dx + dy * dy);
      }
      var best = Infinity;
      for (var i = 1; i < pts.length; i++) {
        var d = distToSeg(px, py, pts[i - 1], pts[i]);
        if (d < best) best = d;
      }
      return best;
    }
    /** 🔒 §22-at-3 欠陥2-②: 文字の箱が道路の帯の面と重なる比（0〜1・近似）。
     * 面積比を厳密には出さず、箱を3×3の点（segDist と同じ格子）に見立て、
     * 帯の線までの距離が半幅未満の点の割合を面積比の代わりに使う。 */
    function bandOverlap(b) {
      if (!bandLines.length) return 0;
      var hw = halfW(b), hh = halfH(b), hit = 0, i, j, k, x, y, d;
      for (i = -1; i <= 1; i++) {
        for (j = -1; j <= 1; j++) {
          x = b.cx + i * hw; y = b.cy + j * hh;
          for (k = 0; k < bandLines.length; k++) {
            d = polylineDistXY(bandLines[k].pts, x, y);
            if (d < bandLines[k].halfM) { hit++; break; }
          }
        }
      }
      return hit / 9;
    }

    /* 🔒 §22-am-5 欠陥1 ＋ §22-am-6-1 ①: **主役の立入禁止域**。
     * ＝ 印の箱 ＋ 主役ラベルの箱 ＋ 距離ラベルの箱 を、**PLACE.mainPad 行**
     * （🙋 仮値 4行・§22-am-5 の 1行から広げた）膨らませた領域。
     * 点に付く名前の候補は、この領域と交わる物を**除外する**（罰点ではない）。
     * > オーナー: 「全ての名称は使用の本拠から離れる、駐車場から離れる」
     * 🔴 主役ラベル・距離ラベルの箱は「置いた後」でないと分からないので、
     *    その場に置く物（stayRecs＝役割つきを含む）を置き終えてから作る。 */
    var mainZones = [];
    function addZone(cx, cy, hw, hh) {
      var pad = PLACE.mainPad * hRef;
      mainZones.push({ cx: cx, cy: cy, hw: hw + pad, hh: hh + pad });
    }
    function buildMainZones() {
      var i;
      for (i = 0; i < markBoxes.length; i++) {
        addZone(markBoxes[i].x, markBoxes[i].y, markBoxes[i].hw, markBoxes[i].hh);
      }
      for (i = 0; i < placedBoxes.length; i++) {
        if (placedBoxes[i].main) {
          addZone(placedBoxes[i].cx, placedBoxes[i].cy,
                  halfW(placedBoxes[i]), halfH(placedBoxes[i]));
        }
      }
    }
    /** 文字の箱が主役の立入禁止域と交わるか */
    function hitsMainZone(b) {
      var hw = halfW(b), hh = halfH(b);
      for (var i = 0; i < mainZones.length; i++) {
        if (Math.abs(b.cx - mainZones[i].cx) < mainZones[i].hw + hw &&
            Math.abs(b.cy - mainZones[i].cy) < mainZones[i].hh + hh) return true;
      }
      return false;
    }
    /** 線分が軸並行の矩形と交わるか（Liang-Barsky） */
    function segHitsRect(ax, ay, bx, by, cx, cy, hw, hh) {
      var dx = bx - ax, dy = by - ay, t0 = 0, t1 = 1, p, q, r;
      for (var i = 0; i < 4; i++) {
        if (i === 0) { p = -dx; q = ax - (cx - hw); }
        else if (i === 1) { p = dx; q = (cx + hw) - ax; }
        else if (i === 2) { p = -dy; q = ay - (cy - hh); }
        else { p = dy; q = (cy + hh) - ay; }
        if (p === 0) { if (q < 0) return false; continue; }
        r = q / p;
        if (p < 0) { if (r > t1) return false; if (r > t0) t0 = r; }
        else { if (r < t0) return false; if (r < t1) t1 = r; }
      }
      return true;
    }
    /** 線分どうしが交わるか */
    function segCrossSeg(a, b, c, d) {
      function cr(p, q, r) {
        return (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x);
      }
      var d1 = cr(a, b, c), d2 = cr(a, b, d), d3 = cr(c, d, a), d4 = cr(c, d, b);
      return ((d1 > 0) !== (d2 > 0)) && ((d3 > 0) !== (d4 > 0));
    }
    /** 引き出し線（●→文字の中心）が横切る「横切ってはいけない物」の数 */
    function leadCrossings(a, cx, cy) {
      var n = 0, i;
      for (i = 0; i < markBoxes.length; i++) {
        if (segHitsRect(a.x, a.y, cx, cy, markBoxes[i].x, markBoxes[i].y,
                        markBoxes[i].hw, markBoxes[i].hh)) n++;
      }
      if (seg && segCrossSeg({ x: a.x, y: a.y }, { x: cx, y: cy }, seg.a, seg.b)) n++;
      for (i = 0; i < placedBoxes.length; i++) {
        var pb = placedBoxes[i];
        if (!pb.road && !pb.main) continue;
        if (segHitsRect(a.x, a.y, cx, cy, pb.cx, pb.cy, halfW(pb), halfH(pb))) n++;
      }
      return n;
    }

    /* ===== 仕分け（§22-am-1）と、置き直さない文字の登録 ===== */
    /* 🔒 §30-25-3 4: ●（無ければ文字）が**枠の外**にある名前は「枠の中に収める」
     * 規則を受けない（枠の外にも描く段のために作られた物＝落とさない・外へ出す）。
     * 置き方は「印のすぐ隣」だけ（枠の中の文字の置き場所には一切影響しない）。 */
    /* 🔒 §30-41: distRecs＝直線距離の文字（結線にくっつけて置く・placeDistance）。 */
    var stayRecs = [], awayRecs = [], freeRecs = [], distRecs = [];
    /* 既に引かれている引き出し線（新しい線と交差させないために覚えておく）。
     * §22-am-3 のなぞり出し1件追加では、既にある文字の線もここに入る。 */
    var leads = [];
    labels.forEach(function (o) {
      var h = hM(o), w = wM(o, h);
      var base = toXY(o.anchor || o.at);

      /* 🔒 §22-am-3: なぞり出しの1件追加では、既にある文字は動かさない
       * （開いただけ・足しただけで図が動かない原則）。障害物としてだけ登録する。
       * 🔒 §22-av: 路線番号の印も**絶対に動かさない**。印は道路の線そのものを
       *    指す物なので、脇へ逃がすと隣の道に番号が付いて嘘になる（道路名の
       *    ROAD_STAY は罰点なので動く余地が残る。実測 2026-09-06: 罰点だけでは
       *    10.9m 動いて道から浮いた）。障害物としては登録するので、
       *    後から置く文字はこの印を避ける。 */
      /* 🔒 §28-5 A（2026-09-07）: **手で置いた物（source:'manual'）も動かさない**。
       * 信号機・バス停の印は人がその場所を見て置いた物なので、脇へ逃がすと嘘になる
       * （路線番号の印と同じ理屈）。障害物としては登録するので後の文字が避ける。 */
      if ((onlySet && !onlySet[o.id]) || o.badge || o.source === 'manual') {
        var at0 = toXY(o.at);
        var eb = boxOf(o, at0.x, at0.y);
        eb.road = isRoadName(o);
        eb.main = !!o.role;
        placedBoxes.push(eb);
        if (o.anchor && !o.role) {
          var ea = toXY(o.anchor);
          leads.push({ a: ea, t: edgeToward(eb, ea) });
        }
        return;
      }

      /* 🔒 §22-y: 施設（●あり・主役でない）が自宅／駐車場の◎に近いかどうか。
       * 🔴 置き方そのものは §22-am-6（主役の立入禁止域＝除外）に吸収された。
       *    この印は画面（editor.js）・紙（export.js）が「引き出し線を必ず描く」
       *    判定に使う古い作りの名残りなので、従来どおり焼いておく（後方互換）。 */
      if (o.anchor && !o.role) {
        o.nearMain = !!((home && GSI.distanceMeters(o.anchor, home) < NEAR_MAIN_M) ||
                        (lot && GSI.distanceMeters(o.anchor, lot) < NEAR_MAIN_M));
      }

      var rec = { o: o, base: base, h: h, w: w };
      /* 🔒 §18-n-4 → §30-25-3 4（2026-09-13 オーナー指示で改定）:
       * ●（無ければ文字そのもの）が紙の枠の外にある名前は、**落とさずに**
       * 枠の制約を外して置く（紙には枠の中しか出ないが、画面では枠の外も見える
       * ＝「枠の中に目印が無い」と分かって枠を決め直せる・§30-25-3 5）。
       * 🔴 段 1〜3 では枠の外の物はそもそも作られない（areaFor が切る）ので、
       *    ここへ来るのは「多め・全部」で意図して作った物だけ。
       * 🔴 役割つき（自宅・駐車場・距離）は所在図の主役なので従来どおり対象外。 */
      if (!o.role && !inFrame(base)) { freeRecs.push(rec); return; }

      /* 🔒 §30-41 1: 直線距離の文字（●なし・生成時は結線の中点）は、他の名前と
       * 同じ置き方（placeByCands→costOf）だと「結線に被る＝大ペナルティ」で線から
       * 1〜2.6 行ぶん逃がされる。結線そのものの説明なので線にくっつけて置く。
       * 🔴 判定は role と type で行う（表示文字では判定しない・§26-2 注意②）。 */
      if (o.role === 'distance' && o.type === 'text') { distRecs.push(rec); return; }

      if (goesOuter(o)) awayRecs.push(rec); else stayRecs.push(rec);
    });

    /* 🔒 §22-am-6-4 の実測用。lead＝引き出し線つき／side＝●のすぐ脇（1行以内・線なし）／
     * forced＝除外を全部満たす候補が無く「最善」へ落とした数。
     * 🔒 §22-am-7: forced になった時だけ、その最善候補の「結線を跨いだか」
     * （forcedCross）と「重なりの最大値」（forcedOverlap・件ごとの配列）を控えて報告に出す。 */
    var awayStat = { lead: 0, side: 0, forced: 0, forcedCross: 0, forcedOverlap: [] };

    /* 🔒 §30-24-2: 置き終わった主役ラベルの控え（同じ点に付く2つ目を真下へ
     * 並べるために読む）。表示文字ではなく「点が同じか」で見分ける（§26-2 注意②）。
     * 🔴 宣言は置く処理（stayRecs.forEach）より**前**に置く（var の巻き上げでは
     *    代入は走らないので、後ろで宣言すると undefined を push しに行く）。 */
    var mainLabels = [];

    /* ①その場に置く物（従来の候補生成・rank 順のまま）
     *   ＝主役（役割つき）・道路名・鉄道名・地名・川山
     * 🔒 §30-41 3: ①は2回に分ける。**主役ラベル（役割つき）→ 直線距離の文字 →
     *   他の名前（道路名・地名・川山）** の順に置く。
     *   ・主役ラベルより後 … 距離の文字が主役ラベルを埋めない（主役が最優先）
     *   ・他の名前より先 … 後から来る名前が距離の文字を避けられる（placedBoxes）
     *   🔴 labels は placeRank 順（役割つき＝0 が先頭）に並んでいるので、
     *      役割の有無で2回舐めても**元の順序は崩れない**（安定した仕分け）。 */
    stayRecs.forEach(function (rec) { if (rec.o.role) placeByCands(rec); });
    distRecs.forEach(placeDistance);
    stayRecs.forEach(function (rec) { if (!rec.o.role) placeByCands(rec); });
    /* 🔒 §22-am-5 欠陥1: 主役の立入禁止域は①の後（主役ラベル・距離ラベルを置いた後）に作る */
    buildMainZones();
    /* ②点に付く名前を「主役・結線から離れた空き地」へ（§22-am-6）。
     *   ①の道路名・主役の箱が、除外と密度と横切りの罰点に効く */
    awayRecs.forEach(placeAway);
    /* ③🔒 §30-25-3 4: 枠の外の名前は**最後に**「印のすぐ隣」へ置く。
     *   最後に置く＝枠の中の文字の置き場所に一切影響しない（障害物としても後出し）。 */
    freeRecs.forEach(function (rec) {
      finishAway(rec.o, rec.base, nearBox(rec.o, rec.base), true);
    });

    /** 従来どおりその場／anchor の脇に置く（主役・線に付く名前＝道路名・地名・川山） */
    function placeByCands(rec) {
      var o = rec.o, h = rec.h, w = rec.w, base = rec.base;
      /* 🔒 §30-24-2: 同一住所は「使用の本拠」と「駐車場」の2つの文字が**同じ点**に
       * 付く。2つ目は1つ目の**真下**へ並べる（重ねない・どちらもドラッグで動かせる）。
       * 🔴 判定は表示文字ではなく「同じ点に既に主役ラベルを置いたか」（§26-2 注意②）。 */
      if (o.role === 'pinlabel' && o.anchor) {
        var prev = mainLabelAt(base);
        if (prev) {
          var nb2 = boxOf(o, prev.box.cx,
                          prev.box.cy - (prev.box.h * 0.75 + h * 0.75 + h * 0.25));
          finishMain(o, base, nb2, !prev.lead);
          return;
        }
      }
      /* 🔒 §30-22-10: 主役ラベル（使用の本拠・駐車場）も同じ3段に従う。
       * 「近く」は印のすぐ隣に置いて終わり（§22-y の逃がし＝ candidates の pad は
       * 「離す」の時だけ効く）。引き出し線は出さない。 */
      if (gapStep === NAME_GAP_NEAR && o.role === 'pinlabel' && o.anchor) {
        finishMain(o, base, nearBox(o, base), true);
        return;
      }
      var cands = candidates(o, base, w, h);
      var best = null, bestCost = Infinity;
      for (var i = 0; i < cands.length; i++) {
        var b = boxOf(o, cands[i].x, cands[i].y);
        var c = costOf(b, cands[i].bias, o);
        if (c < bestCost) { bestCost = c; best = cands[i]; }
        if (c <= 0) break;                 // 文句なしの場所が見つかったら即決
      }
      if (!best) best = cands[0];
      var nb = boxOf(o, best.x, best.y);
      /* どの候補も枠に入りきらない時は、最後に枠の内側へ押し込む
         （🔒 §18-n-4「枠端で見切れさせない」）。枠より大きい文字は押し込めないので触らない */
      if (fr) {
        var hw = halfW(nb), hh = halfH(nb);
        var bx = best.x, by = best.y;
        if (fr.x1 - fr.x0 > hw * 2) bx = Math.min(Math.max(bx, fr.x0 + hw), fr.x1 - hw);
        if (fr.y1 - fr.y0 > hh * 2) by = Math.min(Math.max(by, fr.y0 + hh), fr.y1 - hh);
        best = { x: bx, y: by, dx: best.dx, dy: best.dy };
        nb = boxOf(o, bx, by);
      }
      /* 🔒 §30-22-11 2「標準」: 主役ラベルも「離す」の向きのまま距離を半分へ
       * （中点ではない・midStandardBox 参照）。移動量の記録（moved）は
       * 従来どおり「候補が動いたか」で数える。 */
      if (gapStep === NAME_GAP_MID && o.role === 'pinlabel' && o.anchor) {
        nb = midStandardBox(o, base, nb);
        best = { x: nb.cx, y: nb.cy, dx: best.dx, dy: best.dy };
      }
      /* 🔒 2026-09-04 是正4: 「これは道路名の箱か」を控える。
       * 道路名どうしの重なりは軽く、道路名が**他の文字**を埋めるのは重く見るため。
       * 🔒 §22-al-2: 「これは主役ラベルの箱か」も控える。道路名が主役ラベルを
       * 埋める時だけ、さらに軽い重なりで譲らせるため。 */
      nb.road = isRoadName(o);
      nb.main = !!o.role;
      placedBoxes.push(nb);
      if (seg && segPenalty(nb) > 0) onLine++;
      if (best.dx || best.dy) moved++;
      o.at = { lat: lat0 + best.y / M_LAT, lng: lng0 + best.x / M_LNG };
      /* 🔒 §22-am-7 裁定4: 主役ラベル（role 付き＝使用の本拠・駐車場・距離）にも、
       * 点の名前（placeAway）と**同じ関数**で lead の印を焼く。
       * > Fable「主役ラベル（役割つき）は lead を持たず画面と紙で線の有無が食い違い得る
       * >  （隣接・地方部で『使用の本拠』に1件）。主役ラベルにも同じ lead の印を焼く
       * >  （配置は従来どおり・線の判定だけ揃える）」
       * 🔴 配置（candidates/costOf）は変えない。置き終わった位置 nb と anchor(base) から
       *    「箱の縁までの隙間が PLACE.ringMin 行超か」だけを判定する（placeAway と同一式）。
       *    editor.js/export.js の Editor.wantLead は o.lead を最優先で読むので、これで
       *    画面（zoom依存のpx）と紙（mm依存のpx）の食い違いが消える。 */
      if (o.role) {
        var mtip = edgeToward(nb, base);
        var mgap = Math.sqrt((mtip.x - base.x) * (mtip.x - base.x) +
                             (mtip.y - base.y) * (mtip.y - base.y));
        o.lead = mgap > PLACE.ringMin * hRef * 1.02;
      }
      // 🔒 §30-24-2: 同じ点に2つ目の主役ラベルが来た時の下敷きにする
      noteMainLabel(o, base, nb);
    }

    /**
     * 🔒 §30-41 2（2026-09-21 オーナー指示「距離表示が結ぶ線から離れている。
     * くっつくくらいがいい」）: **直線距離の文字だけ**の置き方。
     *
     * 置き方 … 中点を基準に、結線に**直交する向き**へ箱の縁が線に触れるまでずらす。
     *   候補＝線の左右2側 × 線上の位置3つ（中点・中点から両端へ DIST.along）＝6つ
     *   除外＝主役の立入禁止域／枠の外／紙の付き物の席／既に置いた文字との重なり
     *   順位＝重なり（PLACE.wOver）→ 中点に近い方（行換算）→ 側の優先（DIST.sideBias）
     *   全滅なら中点の上側（除外を無視する・置かない選択肢は無い）
     * 🔴 結線の回廊（inCorridor）・結線の罰点（segPenalty／PLACE.wSeg）・結線を跨ぐ
     *    引き出し線（crossesConnector）は**この文字には掛けない**。どれも「結線から
     *    離す」ための仕掛けで、線に付くのが正しいこの文字には逆に働く
     *    （costOf ① の「結線に被る＝大ペナルティ」は他の名前の規則として残す）。
     * 🔴 置いた箱は finishMain 経由で placedBoxes に main:true で入る＝
     *    後から置く名前は従来どおりこの文字を避ける（§30-41 3）。
     * 🔴 文字は水平のまま（回転はしない・§30-41 4）。画面・紙の描画も追従
     *    （syncRoleObjects の o.mid 基準）も変えない。
     */
    function placeDistance(rec) {
      var o = rec.o, base = rec.base;
      // 結線が無い／長さ0の図では従来どおりの置き方に落とす
      if (!seg) { placeByCands(rec); return; }
      var vx = seg.b.x - seg.a.x, vy = seg.b.y - seg.a.y;
      var len = Math.sqrt(vx * vx + vy * vy);
      if (!len) { placeByCands(rec); return; }
      var ux = vx / len, uy = vy / len;        // 線の向き
      var nx = -uy, ny = ux;                   // 線に直交する向き
      var mx = (seg.a.x + seg.b.x) / 2, my = (seg.a.y + seg.b.y) / 2;   // 中点
      /* 箱の縁が線に触れるまでのずらし量。
       * 🔴 大きさは **hRef（＝枠の幅で測った「文字1行」）** で出す。hM(o) は spanM
       *    ＝取得範囲の幅で測るので、§30-25 で取得範囲が画面全体になってからは
       *    紙に刷られる実際の文字（枠の幅が基準）の **3倍近く**になる。その値で
       *    ずらすと「くっつく」どころか3行ぶん離れる（実測 53m・狙いは 20m）。
       *    PLACE の単位「文字の行」も hRef なので、ここも hRef に揃える。
       * 🔴 正典の「箱の半分の高さ」は**横向きの線**の時の値（法線が縦＝|ny|=1）。
       *    縦・斜めの線では半分の幅も効く（高さだけだと線が文字の真ん中を通る）ので、
       *    軸並行の箱を法線の向きに測った半径（支え距離）で出す。横向きの線では
       *    従来どおり「箱の半分の高さ」に一致する。 */
      /* 🔴 「紙に刷られる文字1行の高さ」の出どころは hPaper() 1か所（§30-22-10）。
       *    ここで同じ名前の変数を作ると関数を覆い隠すので、別名で受ける。 */
      var hp = hPaper(o);
      var off = Math.abs(nx) * (wM(o, hp) / 2) + Math.abs(ny) * (hp / 2) +
                DIST.gap * hRef;
      var alongs = [0, DIST.along, -DIST.along];
      var best = null, bestCost = Infinity, i, s, t, px, py, b, c, ov, cand;
      for (i = 0; i < alongs.length; i++) {
        t = alongs[i] * len;
        px = mx + ux * t; py = my + uy * t;
        for (s = -1; s <= 1; s += 2) {
          cand = { x: px + nx * off * s, y: py + ny * off * s };
          b = boxOf(o, cand.x, cand.y);
          /* 🔴 主役の立入禁止域（mainZones）は buildMainZones＝①の後に作るので、
           *    この文字を置く時点ではまだ空。順番が変わっても正しく効くよう、
           *    除外の並びは placeAway と同じ形で書いておく。 */
          if (hitsMainZone(b)) continue;                // 主役の立入禁止域
          if (outsideFrame(b) > 0) continue;            // 枠の外（§18-n-4）
          if (hitsFurniture(b)) continue;               // 紙の付き物の席
          ov = maxOverlap(b);
          if (ov > PLACE.overMax) continue;             // §22-am-7 裁定2: 文字どうしの重なり
          c = ov * PLACE.wOver +
              Math.abs(t) / Math.max(hRef, 1e-6) +      // 中点から離れるほど不利（行換算）
              distSideBias(nx * s, ny * s);
          if (c < bestCost) { bestCost = c; best = cand; }
        }
      }
      if (!best) {
        s = (ny > 1e-9 || (Math.abs(ny) <= 1e-9 && nx > 0)) ? 1 : -1;   // 中点の上側
        best = { x: mx + nx * off * s, y: my + ny * off * s };
      }
      // 後始末は主役ラベルの「近く」と同じ（引き出し線は出さない）
      finishMain(o, base, boxOf(o, best.x, best.y), true);
    }
    /** 🔒 §30-41 2: 側の優先。メートル座標は y が北＝画面の上向きなので、
     * y が正の側＝**画面で線より上**を先に。線が縦（法線が真横）なら右を先に。 */
    function distSideBias(sx, sy) {
      if (sy > 1e-9) return 0;
      if (sy < -1e-9) return DIST.sideBias;
      return sx > 0 ? 0 : DIST.sideBias;
    }

    /** 🔒 §30-22-10: 主役ラベルを「近く」に置いた時の後始末（placeByCands の尻尾と同じ）。
     * near=true は引き出し線を出さない（`lead:false` を焼く）。 */
    function finishMain(o, base, nb, near) {
      nb.road = isRoadName(o);
      nb.main = !!o.role;
      placedBoxes.push(nb);
      if (seg && segPenalty(nb) > 0) onLine++;
      moved++;
      o.at = { lat: lat0 + nb.cy / M_LAT, lng: lng0 + nb.cx / M_LNG };
      if (near) { o.lead = false; noteMainLabel(o, base, nb); return; }
      var tip = edgeToward(nb, base);
      var g = Math.sqrt((tip.x - base.x) * (tip.x - base.x) +
                        (tip.y - base.y) * (tip.y - base.y));
      o.lead = g > PLACE.ringMin * hRef * 1.02;
      noteMainLabel(o, base, nb);
    }

    function noteMainLabel(o, base, nb) {
      if (o.role !== 'pinlabel' || !o.anchor) return;
      mainLabels.push({ x: base.x, y: base.y, box: nb, lead: !!o.lead });
    }
    /** その点に既に置いた主役ラベル（1m 以内＝同じ点とみなす）。無ければ null */
    function mainLabelAt(base) {
      for (var i = 0; i < mainLabels.length; i++) {
        var m = mainLabels[i];
        if (Math.abs(m.x - base.x) < 1 && Math.abs(m.y - base.y) < 1) return m;
      }
      return null;
    }

    /**
     * 🔒 §22-am-6: 点に付く名前を「主役・結線から離れた空き地」へ置く。
     *
     * > オーナー: 「大津通の上にある信号の名前が右下にある。使用の本拠と駐車場を結ぶ線から
     * >   離して表示する必要がある。この交差点名は右下じゃなくて左上が正解」
     * >   「右上のテキストがごちゃごちゃ。中央右にスペースがある」
     *
     * 候補＝●の周り 8方向 × 距離 1〜PLACE.ringMax 行（近い環から）。枠の縁は候補の1つ。
     * 除外（罰点ではない）＝主役の立入禁止域／結線の回廊／枠の外／紙の付き物の席／
     * 自分の●を塗り潰す位置。コストの重みは PLACE 1か所。
     */
    function placeAway(rec) {
      var o = rec.o, h = rec.h, w = rec.w, base = rec.base;
      /* 🔒 §30-22-10「近く」: 外側へ・主役から離す・空き地探しは**一切掛けない**。
       * 印のすぐ隣に置いて終わり（重なりは利用者がドラッグで直す）。 */
      if (gapStep === NAME_GAP_NEAR) { finishAway(o, base, nearBox(o, base), true); return; }
      var cands = awayCands(base, w, h);
      var best = null, bestCost = Infinity, i, b, c;
      for (i = 0; i < cands.length; i++) {
        b = boxOf(o, cands[i].x, cands[i].y);
        if (hitsMainZone(b)) continue;            // ① 主役の立入禁止域
        if (inCorridor(b)) continue;              // ② 結線の回廊
        if (outsideFrame(b) > 0) continue;        // ⑦ 枠の外（§18-n-4）
        if (hitsFurniture(b)) continue;           // ⑦ 紙の付き物の席
        if (coversDot(b, base)) continue;         // 🔒 §18-j: 自分の●を文字で隠さない
        if (crossesConnector(b, base)) continue;  // 🔒 §22-am-7 裁定1: 結線を跨ぐ引き出し線
        if (maxOverlap(b) > PLACE.overMax) continue;  // 🔒 §22-am-7 裁定2: 文字どうしの重なり
        c = awayCost(b, cands[i], base);
        if (c < bestCost) { bestCost = c; best = cands[i]; }
      }
      /* どの向き・どの環でも除外から出られない時だけ、除外を無視した最善へ落ちる
       * （置かない選択肢は無い。密な図で置き場を失わないための保険）。
       * 🔒 §22-am-8 裁定1: 除外を無視するだけでは回廊・禁止域を平気で踏むので、
       * 「最善」は通常コストに違反の量（forcedCost）を足して選ぶ＝違反を量で罰する。
       * 🔒 §22-am-7: 選んだ最善候補が結線を跨いだか／重なりの最大値を報告用に控える。 */
      if (!best) {
        var fCost = Infinity;
        for (i = 0; i < cands.length; i++) {
          b = boxOf(o, cands[i].x, cands[i].y);
          c = forcedCost(b, cands[i], base);
          if (c < fCost) { fCost = c; best = cands[i]; }
        }
        if (!best) best = cands[0];
        awayStat.forced++;
        var fb = boxOf(o, best.x, best.y);
        if (crossesConnector(fb, base)) awayStat.forcedCross++;
        awayStat.forcedOverlap.push(maxOverlap(fb));
      }
      var nb = boxOf(o, best.x, best.y);
      /* 最後に枠の内側へ押し込む（🔒 §18-n-4「枠端で見切れさせない」）。
       * 枠外は除外してあるので、ここが効くのは上の保険に落ちた時だけ */
      if (fr) {
        var hw = halfW(nb), hh = halfH(nb), bx = nb.cx, by = nb.cy;
        if (fr.x1 - fr.x0 > hw * 2) bx = Math.min(Math.max(bx, fr.x0 + hw), fr.x1 - hw);
        if (fr.y1 - fr.y0 > hh * 2) by = Math.min(Math.max(by, fr.y0 + hh), fr.y1 - hh);
        nb = boxOf(o, bx, by);
      }
      /* 🔒 §30-22-11 2「標準」: 「離す」で決めた位置への向きはそのまま、
       * 印からの距離を半分に（半分が「近く」の距離より短ければ「近く」の距離・
       * midStandardBox 参照）。引き出し線は下の従来の距離規則で判定し直す。 */
      if (gapStep === NAME_GAP_MID) {
        nb = midStandardBox(o, base, nb);
      }
      finishAway(o, base, nb, false);
    }

    /** placeAway の後始末（箱の登録・at の書き戻し・引き出し線の判定）。
     * 🔒 §30-22-10: 近く（near=true）は引き出し線を**出さない**（`lead:false` を焼く）。 */
    function finishAway(o, base, nb, near) {
      nb.road = false;
      nb.main = false;
      placedBoxes.push(nb);
      if (seg && segPenalty(nb) > 0) onLine++;
      moved++;
      o.at = { lat: lat0 + nb.cy / M_LAT, lng: lng0 + nb.cx / M_LNG };
      /* 🔒 §22-am-6-2: 引き出し線は●から**文字の箱の縁**まで（隙間 0）。
       * ●から 1 行（PLACE.ringMin）以内に置けた名前＝脇置きなので線なし。
       * 🔴 判定はここ（紙の物差し）1本。画面 px の距離しきい値に任せると
       *    閲覧ズームで線が出たり消えたりする（§22-y の教訓）。
       *    `lead:false` は editor.js / export.js が「描かない」と読む印（§26-2 注意②）。 */
      var tip = edgeToward(nb, base);
      var gapM = Math.sqrt((tip.x - base.x) * (tip.x - base.x) +
                           (tip.y - base.y) * (tip.y - base.y));
      o.lead = near ? false : (gapM > PLACE.ringMin * hRef * 1.02);
      if (o.lead) awayStat.lead++; else awayStat.side++;
      leads.push({ a: base, t: tip });
    }

    /** 🔒 §30-22-10: **紙に刷られる**文字1行の高さ(m)。
     * 🔴 hM() は取得範囲（枠 +8%）で測る近似（箱の大きさ・環の幅の物差し）なので、
     *    「印のすぐ隣」だけはこちらを使う。枠の幅 ÷ 138mm が紙 1mm の実距離
     *    （export.js の PANEL_MM.w=138 × SHEET_SCALE を約すとこの比になる・hRef と同じ物差し）。 */
    function hPaper(o) {
      return (frameRect ? (frameRect.x1 - frameRect.x0) : spanM)
             * (MM[o.size] || MM.medium) / 138;
    }

    /**
     * 🔒 §30-22-10「近く」: 名前を**印のすぐ隣**に置いた時の文字の箱。
     * 規則は手で置いた印つき文字（§30-15-3／§30-15-5 規則2）とまったく同じで
     *   ずれ ＝ 印の半幅 ＋ 紙の文字高 × 0.4 ＋ 文字の半幅（上下は印の中心）。
     * 🔴 規則の出どころは `Editor.markTextOffset` の**1か所**（画面・紙・所在図で同じ）。
     *    単位は「文字の高さ」に比例するので、hPaper（紙の文字高の実距離）を
     *    渡せば戻り値もメートルになる＝紙基準（閲覧ズームに依らない）。
     * 🔴 主役の四角の印だけは実距離（w_m）なので外から半幅を渡す。
     * 🔴 右へ置くと紙の枠からはみ出す時は**左隣**（§30-15-5 規則3 と同じ考え）。
     * 🔴 登録する箱そのものは従来どおり boxOf（hM の物差し）＝障害物の帳簿は変えない。
     */
    /** 🔒 §30-22-10/12: 印の半幅(m)。「近く」（nearBox）と「標準」（midStandardBox）で
     * 同じ値を使う（唯一の出どころ）。pinlabel の主役印は mainMarkHw／o.mark の実寸を
     * 優先し、それ以外は Editor.markTextOffset（＝ markGeom）に聞く（gap=0・halfW=0で
     * 呼べば hw だけが返る）。 */
    function markHalfW(o, hp) {
      if (o.role === 'pinlabel') {
        if (o.pinKey && mainMarkHw[o.pinKey] != null) return mainMarkHw[o.pinKey];
        if (o.mark && (o.mark.w_m || o.mark.h_m)) {
          return Math.max(o.mark.w_m || 0, spanM * markMinMm() / 138) / 2;
        }
      }
      var E = global.Editor;
      /* Editor が無い時（単体テスト）は●／◎だけの素朴な見積り＝ MARK_RING_R の半分が● */
      return (E && E.markTextOffset) ? E.markTextOffset(o, hp, 0, 0, null).dx
                                      : hp * MARK_RING_R / 2;
    }

    /** 🔒 §30-35-4 3: 文字を置く基準の点（m の局所座標）。主役ラベルの■が
     * ピンからずれている（控えの dx_m/dy_m）時は■の中心を基準にする。
     * 🔴 ずれを持たない物（◎・印つき文字）はそのまま＝規則は従来どおり。 */
    function markBase(o, base) {
      if (!o || o.role !== 'pinlabel' || !o.mark || !base) return base;
      var dx = Number(o.mark.dx_m) || 0, dy = Number(o.mark.dy_m) || 0;
      return (dx || dy) ? { x: base.x + dx, y: base.y + dy } : base;
    }

    function nearBox(o, base) {
      var hp = hPaper(o), wp = wM(o, hp), mhw = markHalfW(o, hp);
      /* 🔒 §30-35-4 3: ■（主役の四角）がピンからずれている時は、文字の基準は
       * ピンではなく**■の実際の中心**（右隣＝ピン＋dx＋w/2＋隙間・左隣＝
       * ピン＋dx−w/2−隙間・上下＝ピン＋dy）。toXY は x＝東・y＝北のメートル
       * なので控えの dx_m/dy_m をそのまま足せる（§30-35-3 5 の箱と同じ作法）。 */
      base = markBase(o, base);
      var E = global.Editor;
      var off = (E && E.markTextOffset)
        ? E.markTextOffset(o, hp, wp / 2, null, mhw)
        : { dx: mhw + hp * 0.4 + wp / 2, dy: 0 };
      var cy = base.y - off.dy;            // 画面の y（下＋）→ メートル（上＋）
      var b = boxOf(o, base.x + off.dx, cy);
      /* 右がはみ出す & 左なら収まる時だけ左隣（どちらもはみ出すなら右のまま） */
      if (fr && b.cx + halfW(b) > fr.x1 && base.x - off.dx - halfW(b) >= fr.x0) {
        b = boxOf(o, base.x - off.dx, cy);
      }
      return b;
    }

    /** 🔒 §30-22-12: 標準＝「離す」で決めた位置 A への**向きはそのまま**、
     * 印の縁と文字の箱の縁の**隙間**（中心どうしの距離ではない）を「離す」の半分に
     * する（§30-22-11 2 の補正・実測で中心距離を半分にすると文字の半幅が効いて
     * ほぼ全件「近く」の下限に張り付いたため）。隙間の下限は「近く」の隙間＝
     * 紙の文字高 × 0.4（§30-15-3 と同じ値）。文字の半幅そのものは足さない
     * （オーナー「線の長さの半分」＝隙間の半分の意）。
     * 印・箱の半幅は向き u = (A-P)/|A-P| に沿って測る（ellipseR。軸に平行なら
     * wM/2 または hPaper/2 に一致する楕円近似・斜めはその中間）。印は丸い印
     * として等方に近似（markHalfW＝ nearBox と同じ値・唯一の出どころ）。
     * 計算は m 単位の局所座標（base.x/y・A の箱の中心 awayNb.cx/cy）で行い、
     * boxOf で緯度経度へ戻す。引き出し線は呼び出し側（finishAway／finishMain）が
     * 従来の距離規則でこの位置から判定し直す。 */
    function ellipseR(ux, uy, hx, hy) {
      var a = hx > 1e-9 ? ux / hx : 0, b = hy > 1e-9 ? uy / hy : 0;
      var m = Math.sqrt(a * a + b * b);
      return m > 1e-9 ? 1 / m : Math.max(hx, hy);
    }
    function midStandardBox(o, base, awayNb) {
      var ax = awayNb.cx - base.x, ay = awayNb.cy - base.y;
      var distA = Math.sqrt(ax * ax + ay * ay);
      if (distA <= 0) return nearBox(o, base);   // 離すの位置が印と同一（万一）の保険
      var ux = ax / distA, uy = ay / distA;
      var hp = hPaper(o), wp = wM(o, hp);
      var mr = markHalfW(o, hp);                   // 印の半幅（向き u・丸い印として近似）
      var boxR = ellipseR(ux, uy, wp / 2, hp / 2);  // 箱の半幅（向き u・楕円近似）
      var gA = distA - mr - boxR;                  // 離すの隙間（印の縁→箱の縁）
      var gNear = hp * 0.4;                        // 近くの隙間の下限（§30-15-3 と同じ）
      var gS = Math.max(gA / 2, gNear);
      var dist = mr + gS + boxR;
      return boxOf(o, base.x + ux * dist, base.y + uy * dist);
    }

    /** ●の周り 8方向 × 距離 1〜ringMax 行。箱の**縁**が●から gap だけ離れるように置く
     * （gap = r * hRef * AWAY_GAP_K。🔒 §30-22-11 1: 離すの隙間は ×1.5 のまま）。
     * ここは「離す」の形そのもので、近く／標準は placeAway / placeByCands が
     * 最後に位置を差し替える。 */
    function awayCands(base, w, h) {
      var out = [], hw = w / 2, hh = h * 0.75, r, d, ux, uy, reach, gap;
      for (r = PLACE.ringMin; r <= PLACE.ringMax; r++) {
        gap = r * hRef * AWAY_GAP_K;
        for (d = 0; d < DIR8.length; d++) {
          ux = DIR8[d][0]; uy = DIR8[d][1];
          /* 箱の中心から縁までの、その向きの長さ（軸並行の箱）。
           * これを足すと「箱の縁が●から gap」＝引き出し線の長さが gap になる。 */
          reach = 1 / Math.max(Math.abs(ux) / hw, Math.abs(uy) / hh);
          out.push({ x: base.x + ux * (gap + reach), y: base.y + uy * (gap + reach),
                     ux: ux, uy: uy, rows: r });
        }
      }
      return out;
    }

    /** 🔒 §22-am-6-1 ③: ●→結線の最近点の向き（＝結線の側）へ逃がすのは不利。0〜1 */
    function sideBad(base, cand) {
      if (!seg) return 0;
      var q = nearOnSeg(base.x, base.y, seg.a, seg.b);
      var vx = base.x - q.x, vy = base.y - q.y;
      var L = Math.sqrt(vx * vx + vy * vy);
      if (L < 1e-6) return 0;                    // ●が結線の上＝どちら側も無い
      return Math.max(0, -(cand.ux * vx + cand.uy * vy) / L);
    }

    /** 🔒 §22-am-6-1 ④: 候補の箱を densPad 行膨らませた範囲の「埋まり具合」0〜1。
     * 置いた文字・道路名・主役の印・紙の付き物を数える＝空いている所ほど 0 に近い。 */
    function density(b) {
      var pad = PLACE.densPad * hRef;
      var hw = halfW(b) + pad, hh = halfH(b) + pad;
      var x0 = b.cx - hw, x1 = b.cx + hw, y0 = b.cy - hh, y1 = b.cy + hh;
      var area = Math.max((x1 - x0) * (y1 - y0), 1e-6), sum = 0, i, p;
      function add(ax0, ay0, ax1, ay1) {
        var ox = Math.min(x1, ax1) - Math.max(x0, ax0);
        var oy = Math.min(y1, ay1) - Math.max(y0, ay0);
        if (ox > 0 && oy > 0) sum += ox * oy;
      }
      for (i = 0; i < placedBoxes.length; i++) {
        p = placedBoxes[i];
        add(p.cx - halfW(p), p.cy - halfH(p), p.cx + halfW(p), p.cy + halfH(p));
      }
      for (i = 0; i < markBoxes.length; i++) {
        add(markBoxes[i].x - markBoxes[i].hw, markBoxes[i].y - markBoxes[i].hh,
            markBoxes[i].x + markBoxes[i].hw, markBoxes[i].y + markBoxes[i].hh);
      }
      for (i = 0; i < furnRects.length; i++) {
        add(furnRects[i].x0, furnRects[i].y0, furnRects[i].x1, furnRects[i].y1);
      }
      return Math.min(1, sum / area);
    }

    /** 文字の箱が●を塗り潰すか（🔒 §18-j: 見えない●は無いのと同じ）。
     * 白フチ（文字高の 0.11 倍）と●の半径（0.24 倍）も見込む（従来の costOf ③ と同じ式） */
    function coversDot(b, p) {
      return Math.abs(p.x - b.cx) < b.w / 2 + b.h * 0.35 &&
             Math.abs(p.y - b.cy) < b.h * 0.73 + b.h * 0.24;
    }

    /** その候補へ引くと、既に引かれている引き出し線と交差する本数 */
    function crossLeads(a, tx, ty) {
      var n = 0;
      for (var i = 0; i < leads.length; i++) {
        if (segCrossSeg({ x: a.x, y: a.y }, { x: tx, y: ty },
                        leads[i].a, leads[i].t)) n++;
      }
      return n;
    }

    /** 🔒 §22-am-6-1 のコスト（重みは PLACE 1か所・🙋 全部仮値） */
    function awayCost(b, cand, base) {
      var c = 0, i, tip, far, ds;
      /* ⓪ 枠から食み出す（除外の保険＝全部除外に落ちた時の順位付けに残す・§18-n-4） */
      c += outsideFrame(b) * 80;
      if (seg) {
        /* ② 結線からの近さ。回廊（PLACE.corr 行）の外でも、近いほど不利にする
         *    ＝「その間の線からも離れる」（オーナー指示） */
        far = PLACE.corr * hRef * 3;
        ds = segDist(b);
        if (ds < far) c += (1 - ds / far) * PLACE.wSeg;
        c += sideBad(base, cand) * PLACE.wSide;            // ③ 結線側の向き
      }
      c += density(b) * PLACE.wDens;                       // ④ 空き地の密度
      /* ⑤ 先に置いた文字との重なり。主役ラベル（使用の本拠・駐車場・距離）を埋めるのは
       * 「見栄えが悪い」ではなく**書類として成立しない**ので特に重い（§22-al-2 と同じ考え）。 */
      for (i = 0; i < placedBoxes.length; i++) {
        c += overlap(b, placedBoxes[i]) *
             (placedBoxes[i].main ? PLACE.wOver * PLACE.wMain : PLACE.wOver);
      }
      c += cand.rows * PLACE.wLen;                         // ⑥ 引き出し線は短いほど良い
      /* ⑦ 引き出し線が主役の印・結線・道路名の箱を横切る／既にある線と交差する */
      tip = edgeToward(b, base);
      c += leadCrossings(base, tip.x, tip.y) * PLACE.wCross;
      c += crossLeads(base, tip.x, tip.y) * PLACE.wCross;
      /* ⑧ 他の●を文字で塗り潰さない（従来の costOf ③ と同じ物差し） */
      for (i = 0; i < dots.length; i++) {
        if (coversDot(b, dots[i])) c += PLACE.wDot;
      }
      /* ⑨ 🔒 §22-at-3 欠陥2-②: 道路の帯の面に乗らない（罰点・除外ではない） */
      c += bandOverlap(b) * PLACE.wBand;
      return c;
    }

    /** 🔒 §22-am-8 裁定1: 文字の箱が主役の禁止域にどれだけ食い込んでいるか（m）。
     * hitsMainZone と同じ矩形あたりから、めり込みの深さ（AABB の押し出し距離）を出す。 */
    function mainZoneDepth(b) {
      var hw = halfW(b), hh = halfH(b), m = 0, i, z, ox, oy, p;
      for (i = 0; i < mainZones.length; i++) {
        z = mainZones[i];
        ox = (z.hw + hw) - Math.abs(b.cx - z.cx);
        oy = (z.hh + hh) - Math.abs(b.cy - z.cy);
        if (ox > 0 && oy > 0) { p = Math.min(ox, oy); if (p > m) m = p; }
      }
      return m;
    }
    /** 🔒 §22-am-8 裁定1: 文字の箱が結線の回廊にどれだけ食い込んでいるか（m）。
     * inCorridor と同じ判定（segDist）から、回廊の半幅を超えた分だけを出す。 */
    function corridorDepth(b) {
      if (!seg) return 0;
      var lim = PLACE.corr * hRef, ds = segDist(b);
      return ds < lim ? (lim - ds) : 0;
    }
    /** 🔒 §22-am-8 裁定1（2026-09-06 Fable 裁定）: 全滅時（forced）だけに使う「最善」の物差し。
     * 通常コスト（awayCost）に、除外の基準（hitsMainZone/inCorridor/crossesConnector/
     * maxOverlap/outsideFrame）と同じ物差しの「違反の量」× PLACE.forced* を足す
     * （＝「違反を量で罰する」）。除外の基準を1つも超えない候補は実質 0 が足されるだけ
     * ＝通常の awayCost と同じ順位のまま。
     * > Fable「全滅時の最善（forced）が回廊・禁止域を無視する（『中部経済産業局』が
     * >  結線から1.2行の回廊内に置かれた）。forced の選び方を『違反を量で罰する』に
     * >  変える: 回廊への食い込み深さ×200／禁止域への食い込み×200／結線横切り 200／
     * >  重なり比×200／枠外比×200 を通常コストに足して最も軽い違反を選ぶ」 */
    function forcedCost(b, cand, base) {
      var c = awayCost(b, cand, base);
      c += (mainZoneDepth(b) / hRef) * PLACE.forcedMain;
      c += (corridorDepth(b) / hRef) * PLACE.forcedCorr;
      if (crossesConnector(b, base)) c += PLACE.forcedCross;
      c += maxOverlap(b) * PLACE.forcedOver;
      c += outsideFrame(b) * PLACE.forcedOut;
      return c;
    }

    /** anchor の周り（無ければその場も可）に候補を並べる */
    function candidates(o, base, w, h) {
      var out = [];
      // 右・右上・上…と8方向。先に来る向きほど好む（右横が地図の定石）
      var dirs = [[1, 0], [1, 0.8], [0, 1], [-1, 0.8], [-1, 0], [-1, -0.8],
                  [0, -1], [1, -0.8]];
      /* 🔒 §18-x-3: 自宅・駐車場の文字は◎の**すぐ脇**に置く。
       * 実機で「◎から数十px離れている」と指摘された。主役の2点は
       * 「どの◎の名前か」が一目で分かる必要があるので、環を近くに詰める。 */
      var main = (o.dotStyle === 'double' || o.role === 'pinlabel');
      // 🔒 §22-y: nearMain は pad 自体を大きく取ってあるので、環の倍率まで
      // 掛け合わせると far すぎる位置まで飛ぶ。環は控えめにしておく
      var rings = main ? [1, 1.3, 1.7] : (o.nearMain ? [1, 1.4] : [1, 1.7, 2.6]);
      /* その場（従来の位置）は **●の無い文字だけ**の候補にする。
         🔒 §18-j: ●のある文字をその場に置くと、●が必ず文字の真下に隠れる。
         「脇に置けなかったから重ねる」は許さない ―― ●は場所そのものなので、
         見えない●は無いのと同じ。 */
      if (!o.anchor) out.push({ x: base.x, y: base.y, dx: 0, dy: 0, bias: 0 });
      /* 🔒 2026-09-04 是正4: 道路名だけは「その場」から離れる候補に不利を足す。
       * 🔴 道路名は●が無い＝**文字の位置そのものが『どの道か』を指している**ので、
       *    脇へ逃がすと隣の道に名前が付いて嘘になる（実測: 名駅で最大 268m 移動）。
       * 🔴 完全固定にはしない（道路名どうしが重なると逃げ場が無くなる）。
       *    ROAD_STAY=40 は「枠の外 80・結線の真上 60 では動くが、
       *    文字の重なり 18 の1〜2枚では動かない」重み。 */
      var stay = isRoadName(o) ? ROAD_STAY : 0;
      for (var r = 0; r < rings.length; r++) {
        for (var d = 0; d < dirs.length; d++) {
          var ux = dirs[d][0], uy = dirs[d][1];
          /* 逃がす量は「文字の実半幅＋余白」。
             🔒 §18-r: 自宅・駐車場の◎は施設の●の2倍あるので、その分だけ余分に逃がす。
             🔒 §22-y（2026-08-28 オーナー指示）: 施設の余白は 1.0h/1.4h → **0.35h/0.55h**
             に詰めた。●の下に潜る心配は costOf() の「●を文字で塗り潰さない」ペナルティ
             （下記 ③）が別に効いているので、ここを詰めても●は隠れない
             （潰れそうならそちらが自動でring=1.7以降へ逃がす）。
             ただし**自宅・駐車場の◎に近い施設だけは逆に大きく逃がす**
             （nearMain・§22-y）。●のすぐ脇だと主役の◎・名前とごちゃつくため、
             editor.js の引き出し線（anno-lead）が働く距離まで最初から離す。 */
          /* 主役（◎）は半径が施設●の2倍あるので、その分（0.3h）は必ず足す。
             ただし余白そのものは 1.0h → 0.45h に詰めて近くに寄せる（§18-x-3）。
             それでも◎の外側（半径 0.48h）＋白フチは避けられる。 */
          var big = main ? h * 0.3 : 0;
          var pad = main ? h * 0.45 : (o.nearMain ? h * 2.6 : h * 0.35);
          var vert = main ? h * 0.95 : (o.nearMain ? h * 3.0 : h * 0.55);
          /* 🔒 §25-4: 主役の印は◎ではなく**四角**になったので、その半分だけ余分に逃がす。
           * 四角は紙面の最小サイズ（既定 4mm）も持つため、実寸と最小の大きい方で見る。 */
          var mkx = 0, mky = 0;
          if (main && o.mark) {
            var minM = spanM * markMinMm() / 138;
            mkx = Math.max(o.mark.w_m || 0, minM) / 2;
            mky = Math.max(o.mark.h_m || 0, minM) / 2;
          }
          var ox = ux * (w / 2 + pad + big + mkx) * rings[r];
          var oy = uy * (vert + big + mky) * rings[r];
          out.push({ x: base.x + ox, y: base.y + oy, dx: ox, dy: oy,
                     // 右上→右→上…の順に好む。遠い環ほど不利
                     // stay ＝ 道路名を道路から引き剥がす代償（是正4・0 か ROAD_STAY）
                     bias: stay + (r * 1.4) + d * 0.12 });
        }
      }
      return out;
    }

    function costOf(b, bias, o) {
      var c = bias || 0;
      /* 🔒 2026-09-04 是正4: 道路名は「その場」に留めたい（ROAD_STAY）。
       * 🔴 ところが重なりの重み 18 は**全部重なっても 18 < ROAD_STAY** なので、
       *    そのままだと道路名が先に置いた文字を**まるごと埋めたまま居座る**
       *    （実測: 順番だけ直した版で「使用の本拠 ↔ 大津通」が 0.40 重なった）。
       * 🔒 そこで道路名だけ、**自分より先に置かれた「点に付く名前」を埋める時**の
       *    重みを ROAD_STAY / ROAD_YIELD_OVERLAP に上げる
       *    ＝「もう動けない文字を ROAD_YIELD_OVERLAP 以上埋めるなら道路名が譲る」。
       *    🔴 相手が**道路名なら従来の 18 のまま**にする。道路名どうしの軽い重なりで
       *       逃がすと、逃げた先が自分の道から遠すぎて（環の幅は文字幅に比例するので
       *       長い名前で 200m 超）「別の道に名前が付く」＝もっと悪い嘘になる。
       *       実測（名駅 枠700m・段5）: 相手を選ばず重くすると道路名の平均移動が
       *       30.9m→58.5m に増え、重なりの総数も 167→178 に悪化した。
       * 🔒 §22-al-2: 相手が**主役ラベル**（使用の本拠・駐車場・距離）の時は、さらに
       *    軽い重なり（ROAD_YIELD_MAIN=2%）で道路名が譲る。主役の2つは警察が真っ先に
       *    読む箇所なので、欠けるのは「見栄えが悪い」ではなく書類として成立しない。 */
      var roadOvMain = (o && isRoadName(o)) ? (ROAD_STAY / ROAD_YIELD_MAIN) : 0;
      var roadOv = (o && isRoadName(o)) ? (ROAD_STAY / ROAD_YIELD_OVERLAP) : 0;
      /* ⓪ 紙の枠から食み出す＝最大のペナルティ（🔒 §18-n-4）。
         見切れた文字は読めないので、結線に被る（60）より強く避ける。 */
      c += outsideFrame(b) * 80;
      // ① 結線に被る＝大ペナルティ（正典 §18-8「基本は線の外側」）
      c += segPenalty(b) * 60;
      /* ② 先に置いた文字との重なり（道路名が相手によって重みが変わる・3段）:
         相手が主役ラベル → roadOvMain（最重）／相手が道路名 → 18（従来どおり）／
         それ以外 → roadOv（従来どおり）。道路名以外の文字（roadOv/roadOvMain が0）は
         従来どおり常に18のまま＝挙動は変えない。 */
      for (var i = 0; i < placedBoxes.length; i++) {
        var wOv = 18;
        if (roadOvMain && placedBoxes[i].main) wOv = roadOvMain;
        else if (roadOv && !placedBoxes[i].road) wOv = roadOv;
        c += overlap(b, placedBoxes[i]) * wOv;
      }
      /* ③ ●（目標物の位置）を文字で塗り潰さない。
         🔒 §18-j で重みを 1.2 → 12 に上げた。●が隠れるのは「少し見栄えが悪い」
         ではなく**目標物の場所が消える**＝所在図として成立しない欠陥なので、
         多少の重なりより強く避ける（結線の 60 よりは弱い）。
         白フチ（文字高の 0.11 倍）と●の半径（0.24 倍）も見込んで判定する。 */
      for (var j = 0; j < dots.length; j++) {
        if (Math.abs(dots[j].x - b.cx) < b.w / 2 + b.h * 0.35 &&
            Math.abs(dots[j].y - b.cy) < b.h * 0.73 + b.h * 0.24) {
          c += 12;
        }
      }
      return c;
    }

    /** 文字の箱が結線コリドーにどれだけ入っているか 0〜1 */
    function segPenalty(b) {
      if (!seg) return 0;
      var hit = 0, n = 0;
      for (var i = -1; i <= 1; i++) {
        for (var j = -1; j <= 1; j++) {
          var px = b.cx + i * b.w / 2 * 0.9, py = b.cy + j * b.h / 2 * 0.9;
          if (distToSeg(px, py, seg.a, seg.b) < corr) hit++;
          n++;
        }
      }
      return hit / n;
    }

    function overlap(a, b) {
      var ox = Math.min(a.cx + a.w / 2, b.cx + b.w / 2)
             - Math.max(a.cx - a.w / 2, b.cx - b.w / 2);
      var oy = Math.min(a.cy + a.h / 2, b.cy + b.h / 2)
             - Math.max(a.cy - a.h / 2, b.cy - b.h / 2);
      if (ox <= 0 || oy <= 0) return 0;
      return (ox * oy) / Math.min(a.w * a.h, b.w * b.h);
    }

    /* 🔒 §22-am-6-4 の実測用の内訳。
     * outer＝引き出し線つきで空き地へ置いた数／side＝●のすぐ脇（1行以内・線なし）／
     * stay＝その場に置いた数（主役・道路名・地名・川山）／
     * spill＝除外を全部満たす候補が無く「最善」へ落とした数。
     * 🔒 §22-am-7: spillCross＝forced のうち結線を跨いだ数／
     * spillOverlap＝forced 各件の重なりの最大値（配列・件数は spill と同じ）。 */
    return { moved: moved, onLine: onLine, drop: drop,
             // 🔒 §30-41 3: 距離の文字は stayRecs から distRecs へ移したが、
             //    実測用の「その場に置いた数」は従来と同じ数のままにする
             outer: awayStat.lead, side: awayStat.side,
             stay: stayRecs.length + distRecs.length,
             spill: awayStat.forced,
             spillCross: awayStat.forcedCross, spillOverlap: awayStat.forcedOverlap };
  }

  /** 線分 ab の上で点 p に最も近い点（🔒 §22-am-6-1 ③ の「結線の最近点」） */
  function nearOnSeg(px, py, a, b) {
    var vx = b.x - a.x, vy = b.y - a.y;
    var len2 = vx * vx + vy * vy;
    var t = len2 ? ((px - a.x) * vx + (py - a.y) * vy) / len2 : 0;
    t = Math.max(0, Math.min(1, t));
    return { x: a.x + vx * t, y: a.y + vy * t };
  }

  function distToSeg(px, py, a, b) {
    var vx = b.x - a.x, vy = b.y - a.y;
    var len2 = vx * vx + vy * vy;
    var t = len2 ? ((px - a.x) * vx + (py - a.y) * vy) / len2 : 0;
    t = Math.max(0, Math.min(1, t));
    var dx = px - (a.x + vx * t), dy = py - (a.y + vy * t);
    return Math.sqrt(dx * dx + dy * dy);
  }

  global.Shozaizu = {
    generate: generate,
    ROAD_STYLE: ROAD_STYLE,
    // 🔒 §23-9: 道路の描き方 'line'（既定）/'band'。UI・メッセージ表示で使う
    ROAD_STYLE_JA: { line: '線', band: '白帯＋黒縁' },
    RANK_JA: RANK_JA,
    // 🔒 §23-10: 建物の自動描画レベル（UI・メッセージ表示で使う）
    BLDG_LEVEL_JA: BLDG_LEVEL_JA,
    BLDG_LEVELS: BLDG_LEVELS,
    BLDG_NEAR_MAIN_M: BLDG_NEAR_MAIN_M,
    /* 🔒 2026-09-03: 道路の量の5段階（UI・メッセージ表示・単体テストで使う） */
    ROAD_LEVEL_JA: ROAD_LEVEL_JA,
    roadRadiusFor: roadRadiusFor,
    roadRankFloor: roadRankFloor,
    /* 🔒 2026-09-03（後半）: 名称6分類の5段階・川・山（UI・単体テスト・実測で使う） */
    NAME_LEVEL_JA: NAME_LEVEL_JA,
    NAME_LEVELS: NAME_LEVELS,
    /* 🔒 §30-40-2: 名前の8分類の「自動」（段の数字と決め方）。app.js は
     * 画面の段（0）と説明の文言を**この実値から**組む＝値を写さない。 */
    NAME_AUTO: NAME_AUTO,
    NAME_PRIO_UNIT: NAME_PRIO_UNIT,
    /* 🔒 2026-09-04 是正2: 近接重複の抑制（仮値・実機目視で確定） */
    NAME_DUP_M: NAME_DUP_M,
    NAME_DUP_SUB_M: NAME_DUP_SUB_M,
    /* 🔒 2026-09-04 是正4: 道路名を「その場」に留める重み（仮値・実機目視で確定） */
    ROAD_STAY: ROAD_STAY,
    ROAD_YIELD_OVERLAP: ROAD_YIELD_OVERLAP,
    /* 🔒 §22-al-2: 主役ラベルに対しては道路名がさらに軽い重なりで譲る（仮値） */
    ROAD_YIELD_MAIN: ROAD_YIELD_MAIN,
    /* 🔒 §22-am-6: 点に付く名前を「空き地」へ置く定数（🙋 仮値・1か所にまとめてある） */
    PLACE: PLACE,
    /* 🔒 §22-aq / §22-aq-2 / §22-aq-4: 交差点名の例外（🙋 仮値・実機目視で確定） */
    CROSSING_CAT: CROSSING_CAT,
    CROSSING_FRAME_FROM: CROSSING_FRAME_FROM,
    CROSS_MAIN_N: CROSS_MAIN_N,
    /* 🔒 §22-ar / §22-as: 道路名の「絶対」・データが無い時の案内（🙋 仮値・単体テストで使う） */
    ROAD_MAIN_N: ROAD_MAIN_N,
    ROAD_MAIN_M: ROAD_MAIN_M,
    _roadMustSet: roadMustSet,
    _nearestOnWays: nearestOnWays,
    _computeMainNoName: computeMainNoName,
    /* 🔒 §22-am-3: なぞり出しで実体化した名前を**同じ配置関数**に通すための入口。
     * reveal.js が { only:[新しい文字] } を渡す＝その1件だけ置き、既にある文字は
     * 動かさない（角度順に空いている所へ挿す）。 */
    placeNames: placeLabels,
    _sameSpotName: sameSpotName,
    nameRadiusFor: nameRadiusFor,
    namePrio: namePrio,
    POI_PRIO: POI_PRIO,
    SHOP_PRIO: SHOP_PRIO,
    FACILITY_PRIO: FACILITY_PRIO,
    BUILDING_PRIO: BUILDING_PRIO,
    MOUNTAIN_ANNO: MOUNTAIN_ANNO,
    CNTR_STEPS: CNTR_STEPS,
    _collectWater: collectWater,
    _collectContours: collectContours,
    _buildAutoNames: buildAutoNames,
    /* 🔒 §30-22-4 4（［道路を描く］）: 配置図の枠の近くだけ道路を引くために、
     * タイル座標 → 緯度経度 と 範囲の当たり判定を app.js からも使う。
     * 🔴 実装はこの1か所のまま（同じ幾何を2つ持たない）。 */
    _toLatLngs: toLatLngs,
    _bboxHits: bboxHits,
    /* 🔒 §23-9: 道路の描き方の表（'line'/'band'）。［道路を描く］が band を読む */
    roadStyleTable: roadStyleTable,
    /* 🔒 §30-22-1 6: 主役のラベルの文言（same＝同一住所の1つ分）。app.js も読む */
    PIN_LABEL: PIN_LABEL,
    /* 🔒 §30-22-10: 名前の位置の段（1=近く／2=標準／3=離す）。実測・確認用に出す */
    _nameGapStep: nameGapStep
  };
})(typeof window !== 'undefined' ? window : this);
