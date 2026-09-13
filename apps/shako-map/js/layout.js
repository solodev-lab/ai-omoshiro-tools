/* layout.js — 駐車枠の自動敷き詰め（正典 §9 Step 3.5 / §15-a）
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * 設計の前提（正典 §15-a）:
 *   駐車枠は画像から「読み取る」のではなく、敷地形状から「計算して並べる」。
 *   航空写真の解像度では白線が1画素未満で読めないうえ、行政書士は契約書から
 *   区画番号を既に知っているため、図面に要るのは「区画が並んでいて対象はここ」
 *   と示すこと。正確な写しである必要はない（正典 §0）。
 *
 * やること:
 *   敷地の多角形 → 前面道路に一番近い辺を基準線に取る
 *   → その向きに合わせて枠を格子状に並べ、敷地の外に出る枠を捨てる
 *   → 通路(車路)の幅を確保し、列数に応じて片側/両側配置を決める
 */
(function (global) {
  'use strict';

  var DEFAULT = {
    cell_w_m: 2.5,      // 枠の幅（普通車）
    cell_h_m: 5.0,      // 枠の奥行
    aisle_m: 5.0,       // 車路の幅
    margin_m: 0.3       // 敷地境界からの余白
  };

  // 台数に足りない時に枠幅を詰める下限（正典 §16-4: 2.5→2.4→2.3→2.2m）
  var NARROW_MIN = 2.2;
  // 「収まりの悪さ」を比べる時の余白の刻み(m)。
  // 同じくらいの余白は同点として扱い、入口からの距離で決める（正典 §16-4-1）
  var CLEAR_BUCKET_M = 0.25;

  /* ================= 平面直角座標への変換 =================
   * 敷地は数十メートルなので、基準点まわりの局所平面で計算して十分。 */

  function makeFrame(originLatLng) {
    var lat0 = originLatLng.lat, lng0 = originLatLng.lng;
    var mx = 111320 * Math.cos(lat0 * Math.PI / 180);
    var my = 110540;
    return {
      toXY: function (p) {
        return { x: (p.lng - lng0) * mx, y: -(p.lat - lat0) * my };
      },
      toLL: function (q) {
        return { lat: lat0 - q.y / my, lng: lng0 + q.x / mx };
      }
    };
  }

  /* ================= 多角形の基本操作 ================= */

  function centroidXY(pts) {
    var a = 0, cx = 0, cy = 0;
    for (var i = 0; i < pts.length; i++) {
      var p = pts[i], q = pts[(i + 1) % pts.length];
      var f = p.x * q.y - q.x * p.y;
      a += f; cx += (p.x + q.x) * f; cy += (p.y + q.y) * f;
    }
    if (Math.abs(a) < 1e-9) {
      var sx = 0, sy = 0;
      pts.forEach(function (p) { sx += p.x; sy += p.y; });
      return { x: sx / pts.length, y: sy / pts.length };
    }
    a *= 0.5;
    return { x: cx / (6 * a), y: cy / (6 * a) };
  }

  function areaXY(pts) {
    var a = 0;
    for (var i = 0; i < pts.length; i++) {
      var p = pts[i], q = pts[(i + 1) % pts.length];
      a += p.x * q.y - q.x * p.y;
    }
    return Math.abs(a / 2);
  }

  function pointInPoly(pt, pts) {
    var inside = false;
    for (var i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      var xi = pts[i].x, yi = pts[i].y, xj = pts[j].x, yj = pts[j].y;
      if (((yi > pt.y) !== (yj > pt.y)) &&
          (pt.x < (xj - xi) * (pt.y - yi) / (yj - yi) + xi)) inside = !inside;
    }
    return inside;
  }

  function distPointSeg(p, a, b) {
    var vx = b.x - a.x, vy = b.y - a.y;
    var L = vx * vx + vy * vy;
    var t = L ? ((p.x - a.x) * vx + (p.y - a.y) * vy) / L : 0;
    t = Math.max(0, Math.min(1, t));
    return Math.hypot(p.x - (a.x + t * vx), p.y - (a.y + t * vy));
  }

  /** 多角形を内側へ縮める（余白の確保）。単純な重心方向スケールで足りる */
  function shrink(pts, m) {
    if (!m) return pts.slice();
    var c = centroidXY(pts);
    var area = areaXY(pts);
    if (area <= 0) return pts.slice();
    // 等価半径から縮小率を出す（凸凹があっても実用上問題ない粗さ）
    var r = Math.sqrt(area / Math.PI);
    var k = Math.max(0.55, (r - m) / r);
    return pts.map(function (p) {
      return { x: c.x + (p.x - c.x) * k, y: c.y + (p.y - c.y) * k };
    });
  }

  /* ================= 基準となる辺を選ぶ ================= */

  /**
   * 前面道路に最も近い辺を探す。道路が無ければ一番長い辺を使う。
   * roadsXY: [[{x,y},...], ...]
   * 返り値: {a, b, angle}  angle は「枠の奥行き方向」= 道路に直交する向き
   */
  function chooseBaseEdge(poly, roadsXY) {
    var best = null;
    for (var i = 0; i < poly.length; i++) {
      var a = poly[i], b = poly[(i + 1) % poly.length];
      var len = Math.hypot(b.x - a.x, b.y - a.y);
      if (len < 1) continue;
      var mid = { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 };
      var d = Infinity;
      for (var r = 0; r < roadsXY.length; r++) {
        var line = roadsXY[r];
        for (var k = 0; k + 1 < line.length; k++) {
          var dd = distPointSeg(mid, line[k], line[k + 1]);
          if (dd < d) d = dd;
        }
      }
      // 道路が近いほど良い。同程度なら長い辺を優先する
      var score = (d === Infinity) ? (1e6 - len) : (d * 10 - len);
      if (!best || score < best.score) {
        best = { a: a, b: b, len: len, dist: d, score: score };
      }
    }
    if (!best) return null;
    // 道路に沿う向き
    var ang = Math.atan2(best.b.y - best.a.y, best.b.x - best.a.x);
    return { a: best.a, b: best.b, alongAngle: ang,
             roadDist: best.dist, len: best.len };
  }

  /* ================= 敷き詰め ================= */

  /**
   * 敷地の多角形に枠を並べる。
   * opts: {cell_w_m, cell_h_m, aisle_m, margin_m, angle(度・任意),
   *        targetCount(台数・任意)}
   *
   * targetCount を渡すと「その台数ちょうど」に寄せる（正典 §16-4）:
   *   容量 ≥ N … 収まりの悪い枠から削って N にする
   *   容量 < N … 枠幅を 0.1m ずつ 2.2m まで詰めて再試行する
   *   それでも足りない … 入る分だけ置き shortBy に不足数を入れる
   *   容量 > N×1.5 … tooFew を立てる（敷地に対して台数が少ない）
   *
   * 返り値: {cells:[{center:{lat,lng}, angleDeg}], rows, angleDeg, count,
   *          capacity, shortBy, tooFew, narrowed, ...}
   */
  function fillParking(polyLL, roadsLL, opts) {
    opts = opts || {};
    var cw0 = opts.cell_w_m || DEFAULT.cell_w_m;
    var ch = opts.cell_h_m || DEFAULT.cell_h_m;
    var aisle = (opts.aisle_m === undefined) ? DEFAULT.aisle_m : opts.aisle_m;
    var margin = (opts.margin_m === undefined) ? DEFAULT.margin_m : opts.margin_m;
    var target = (opts.targetCount > 0) ? Math.round(opts.targetCount) : null;

    if (!polyLL || polyLL.length < 3) return null;
    var frame = makeFrame(polyLL[0]);
    var poly = polyLL.map(frame.toXY);
    var roads = (roadsLL || []).map(function (line) { return line.map(frame.toXY); });

    if (areaXY(poly) < cw0 * ch * 0.9) return null;

    // 枠の向き: 指定が無ければ前面道路に沿わせる
    var base = chooseBaseEdge(poly, roads);
    var along = (opts.angle !== undefined)
      ? (opts.angle * Math.PI / 180)
      : (base ? base.alongAngle : 0);

    // 道路向きそのままと、90度振った場合の両方を試して枠が多い方を採る
    var candidates = (opts.angle !== undefined) ? [along]
      : [along, along + Math.PI / 2];

    // 台数を指定された時だけ、足りなければ枠幅を詰めて試し直す
    var widths = [cw0], w;
    if (target) {
      for (w = Math.round((cw0 - 0.1) * 10) / 10; w >= NARROW_MIN - 1e-9;
           w = Math.round((w - 0.1) * 10) / 10) {
        widths.push(w);
      }
    }

    var best = null, usedW = cw0;
    for (var i = 0; i < widths.length; i++) {
      var got = solveWidth(poly, candidates, widths[i], ch, aisle, margin);
      if (got && (!best || got.cells.length > best.cells.length)) {
        best = got; usedW = widths[i];
      }
      if (best && (!target || best.cells.length >= target)) break;
    }
    if (!best) return null;

    var capacity = best.cells.length;
    var cells = best.cells;
    // 容量が多い時は「収まりの悪い枠」から削って台数に合わせる
    if (target && capacity > target) {
      var ent = base ? { x: (base.a.x + base.b.x) / 2,
                         y: (base.a.y + base.b.y) / 2 } : null;
      cells = trimCells(cells, poly, ent, capacity - target,
                        usedW, ch, best.ang);
    }
    var rowSet = {};
    cells.forEach(function (c) { rowSet[c.row] = true; });

    return {
      cells: cells.map(function (c) {
        return { center: frame.toLL(c), angleDeg: best.angleDeg };
      }),
      angleDeg: best.angleDeg,
      rows: Object.keys(rowSet).length,
      count: cells.length,
      capacity: capacity,
      targetCount: target,
      shortBy: target ? Math.max(0, target - cells.length) : 0,
      // 敷地に対して台数が少なすぎないか（正典 §16-4-4）
      tooFew: !!(target && capacity > target * 1.5),
      narrowed: (usedW < cw0 - 1e-9) ? usedW : null,
      cell_w_m: usedW, cell_h_m: ch, aisle_m: aisle, margin_m: best.margin,
      roadDist: base ? base.roadDist : null,
      baseEdge: base ? [frame.toLL(base.a), frame.toLL(base.b)] : null
    };
  }

  /** ある枠幅での最良の敷き詰め（余白を詰めながら向きを試す） */
  function solveWidth(poly, candidates, cw, ch, aisle, margin) {
    // 1台分ぎりぎりの敷地（自宅の駐車スペース等）は余白を取ると入らなくなる。
    // 枠が1つも入らなければ余白を詰めて試し直す。
    var best = null, usedMargin = margin;
    var marginTries = [margin, margin / 2, 0];
    for (var mi = 0; mi < marginTries.length && !best; mi++) {
      var inner = shrink(poly, marginTries[mi]);
      if (areaXY(inner) < cw * ch * 0.9) continue;
      candidates.forEach(function (ang) {
        var r = layoutAt(inner, ang, cw, ch, aisle);
        if (r && (!best || r.cells.length > best.cells.length)) best = r;
      });
      if (best) usedMargin = marginTries[mi];
    }
    if (best) best.margin = usedMargin;
    return best;
  }

  /**
   * 台数に合わせて「収まりの悪い枠」から削る（正典 §16-4-1）。
   * 削る順は ①外周への余白が最少 ②入口（前面道路）から最遠。
   *
   * ※オーナー指示は「一番不鮮明な車両駐車枠を削除」だが、画像認識を使わない
   *   v1 では写真の鮮明さは判定できない。「収まりの悪さ」を代理指標にする。
   */
  function trimCells(cells, poly, ent, dropN, cw, ch, ang) {
    var ca = Math.cos(ang), sa = Math.sin(ang);
    var scored = cells.map(function (c, i) {
      var clear = Infinity;
      [[-cw / 2, -ch / 2], [cw / 2, -ch / 2],
       [cw / 2, ch / 2], [-cw / 2, ch / 2]].forEach(function (o) {
        var p = { x: c.x + o[0] * ca - o[1] * sa,
                  y: c.y + o[0] * sa + o[1] * ca };
        var d = distToPolyEdge(p, poly);
        if (d < clear) clear = d;
      });
      return { i: i, clear: clear,
               ent: ent ? Math.hypot(c.x - ent.x, c.y - ent.y) : 0 };
    });
    scored.sort(function (a, b) {
      var ba = Math.round(a.clear / CLEAR_BUCKET_M);
      var bb = Math.round(b.clear / CLEAR_BUCKET_M);
      if (ba !== bb) return ba - bb;              // 余白が少ない方から削る
      if (a.ent !== b.ent) return b.ent - a.ent;  // 次に入口から遠い方
      return a.i - b.i;
    });
    var drop = {};
    for (var k = 0; k < dropN && k < scored.length; k++) drop[scored[k].i] = true;
    return cells.filter(function (c, i) { return !drop[i]; });
  }

  /** 点から多角形の外周までの最短距離 */
  function distToPolyEdge(p, poly) {
    var d = Infinity;
    for (var i = 0; i < poly.length; i++) {
      var dd = distPointSeg(p, poly[i], poly[(i + 1) % poly.length]);
      if (dd < d) d = dd;
    }
    return d;
  }

  /**
   * 指定した向きで格子を敷く。
   *
   * 車路の考え方（実際の月極駐車場に合わせる）:
   *   1組 = [枠の列][枠の列][車路] で奥行 2*ch + aisle。
   *   手前の列は敷地の入口側から、奥の列はその後ろの車路から出入りする。
   *   つまり**奥の列を置くには、その後ろに車路の余地が要る**。
   *   敷地が浅い時（1組ぶんの奥行が無い）は、前面道路が車路の代わりになるので
   *   車路を取らずに1列だけ置く。
   */
  function layoutAt(inner, ang, cw, ch, aisle) {
    var ca = Math.cos(-ang), sa = Math.sin(-ang);
    var c = centroidXY(inner);
    function toLocal(p) {
      var dx = p.x - c.x, dy = p.y - c.y;
      return { x: dx * ca - dy * sa, y: dx * sa + dy * ca };
    }
    function toGlobal(lx, ly) {
      return { x: c.x + (lx * ca + ly * sa), y: c.y + (-lx * sa + ly * ca) };
    }

    var loc = inner.map(toLocal);
    var minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
    loc.forEach(function (p) {
      if (p.x < minX) minX = p.x; if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y; if (p.y > maxY) maxY = p.y;
    });
    var availW = maxX - minX, availH = maxY - minY;
    if (availW < cw || availH < ch) return null;

    /* --- 列の位置（余りは左右に等分して中央寄せ） --- */
    var nCols = Math.floor(availW / cw + 1e-6);
    if (nCols < 1) return null;
    var x0 = minX + (availW - nCols * cw) / 2;

    /* --- 行の位置 --- */
    var rowsRel = [], y = 0, idx = 0;
    var shallow = availH < (ch * 2 + aisle);
    if (shallow) {
      rowsRel.push(ch / 2);                       // 前面道路を車路として使う
    } else {
      while (rowsRel.length < 60) {
        var isSecond = (idx % 2 === 1);
        // 奥の列は後ろに車路が要る
        var need = isSecond ? (y + ch + aisle) : (y + ch);
        if (need > availH + 1e-6) break;
        rowsRel.push(y + ch / 2);
        y += ch;
        if (isSecond) y += aisle;
        idx++;
      }
    }
    if (!rowsRel.length) return null;
    // 使った奥行を敷地の中央に寄せる
    var used = rowsRel[rowsRel.length - 1] + ch / 2;
    var yOff = (availH - used) / 2;

    /* --- 枠を置く。境界ちょうどで弾かれないよう内側へ少し寄せて判定する --- */
    var ex = Math.min(cw, ch) * 0.04;
    var cells = [], rows = 0;
    rowsRel.forEach(function (ry, ri) {
      var cy = minY + yOff + ry, placed = 0;
      for (var i = 0; i < nCols; i++) {
        var cx = x0 + i * cw + cw / 2;
        var ok = true;
        for (var k = 0; k < 4 && ok; k++) {
          var ox = (k === 0 || k === 3) ? (-cw / 2 + ex) : (cw / 2 - ex);
          var oy = (k < 2) ? (-ch / 2 + ex) : (ch / 2 - ex);
          var g = toGlobal(cx + ox, cy + oy);
          if (!pointInPoly(g, inner)) ok = false;
        }
        if (!ok) continue;
        var p = toGlobal(cx, cy);
        p.row = ri;                      // 台数調整で列を数え直すため
        cells.push(p);
        placed++;
      }
      if (placed) rows++;
    });

    if (!cells.length) return null;
    /* 🔴 枠の向きは並べた向き（+ang）そのもの。
     *    以前は -ang を返していたため、傾いた敷地では枠だけが逆向きに傾いて
     *    列と揃わなかった（実測: 列の並び 120°に対し枠が 240°）。 */
    return { cells: cells, rows: rows, ang: ang,
             angleDeg: ((ang * 180 / Math.PI) % 360 + 360) % 360 };
  }

  /* ================= 出入口の推定 ================= */

  /**
   * 敷地の辺のうち道路に最も近い箇所を出入口とみなす。
   * 返り値: {at:{lat,lng}, angleDeg, width_m}
   */
  function guessEntrance(polyLL, roadsLL, widthM) {
    if (!polyLL || polyLL.length < 3 || !roadsLL || !roadsLL.length) return null;
    var frame = makeFrame(polyLL[0]);
    var poly = polyLL.map(frame.toXY);
    var roads = roadsLL.map(function (l) { return l.map(frame.toXY); });
    var base = chooseBaseEdge(poly, roads);
    if (!base || base.roadDist === Infinity) return null;
    var mid = { x: (base.a.x + base.b.x) / 2, y: (base.a.y + base.b.y) / 2 };
    return {
      at: frame.toLL(mid),
      angleDeg: ((base.alongAngle * 180 / Math.PI) % 360 + 360) % 360,
      width_m: widthM || Math.min(4, base.len)
    };
  }

  /* ================= 前面道路の幅を実測する =================
   * 地理院の RdCL には vt_width という属性があるが、公式スタイルが描画用の
   * 幅パラメータとして使っており（rnkwidth 由来の定数と同じ枠）、実幅(m)では
   * ない。矛盾する値も実際に出る（vt_width=391 なのに rnkwidth="3m未満"）。
   * 法定書類に推測値を書くわけにはいかないので、**道路縁の線から幾何的に測る**。
   *
   * 出入口から道路側へ細い探り線を伸ばし、最初に横切る道路縁と、その先で
   * もう一度横切る道路縁の間隔を幅とみなす。
   */
  function measureRoadWidth(entranceLL, awayFromLL, roadEdgesLL, maxM) {
    if (!roadEdgesLL || !roadEdgesLL.length) return null;
    maxM = maxM || 40;
    var frame = makeFrame(entranceLL);
    var o = { x: 0, y: 0 };
    var away = frame.toXY(awayFromLL);
    var len = Math.hypot(away.x, away.y);
    if (len < 1e-6) return null;
    // 敷地の重心と反対の向き（＝道路の方）へ伸ばす
    var dx = -away.x / len, dy = -away.y / len;
    var edges = roadEdgesLL.map(function (l) { return l.map(frame.toXY); });

    var hits = [];
    for (var e = 0; e < edges.length; e++) {
      var line = edges[e];
      for (var k = 0; k + 1 < line.length; k++) {
        var t = raySegment(o, dx, dy, line[k], line[k + 1]);
        if (t !== null && t >= 0 && t <= maxM) hits.push(t);
      }
    }
    if (hits.length < 2) return null;
    hits.sort(function (a, b) { return a - b; });
    // 最初の2本の間隔を道路幅とみなす
    var w = hits[1] - hits[0];
    if (w < 1.0 || w > 40) return null;
    return {
      width_m: w,
      from: frame.toLL({ x: dx * hits[0], y: dy * hits[0] }),
      to: frame.toLL({ x: dx * hits[1], y: dy * hits[1] })
    };
  }

  /**
   * 前面道路の幅を安定して測る。
   * 1点だけで射線を飛ばすと、敷地の形や道路の切れ目で外すことがあるので、
   * 道路に面した辺の上を数点サンプルして、測れた値の中央値を採る。
   */
  function measureFrontRoadWidth(polyLL, roadsLL, maxM) {
    if (!polyLL || polyLL.length < 3 || !roadsLL || !roadsLL.length) return null;
    var frame = makeFrame(polyLL[0]);
    var poly = polyLL.map(frame.toXY);
    var roads = roadsLL.map(function (l) { return l.map(frame.toXY); });
    var base = chooseBaseEdge(poly, roads);
    if (!base) return null;

    var c = centroidXY(poly);
    var ctrLL = frame.toLL(c);
    var results = [];
    // 辺の内側寄りを 5 点サンプル（端は隣地に外れやすいので避ける）
    [0.2, 0.35, 0.5, 0.65, 0.8].forEach(function (t) {
      var p = { x: base.a.x + (base.b.x - base.a.x) * t,
                y: base.a.y + (base.b.y - base.a.y) * t };
      var m = measureRoadWidth(frame.toLL(p), ctrLL, roadsLL, maxM || 60);
      if (m) results.push(m);
    });
    if (!results.length) return null;
    results.sort(function (a, b) { return a.width_m - b.width_m; });
    return results[Math.floor(results.length / 2)];      // 中央値
  }

  /** 原点から (dx,dy) 方向の半直線と線分の交差。交点までの距離を返す */
  function raySegment(o, dx, dy, a, b) {
    var ex = b.x - a.x, ey = b.y - a.y;
    var den = dx * ey - dy * ex;
    if (Math.abs(den) < 1e-9) return null;
    var t = ((a.x - o.x) * ey - (a.y - o.y) * ex) / den;
    var u = ((a.x - o.x) * dy - (a.y - o.y) * dx) / den;
    if (t < 0 || u < 0 || u > 1) return null;
    return t;
  }

  global.Layout = {
    measureRoadWidth: measureRoadWidth,
    measureFrontRoadWidth: measureFrontRoadWidth,
    DEFAULT: DEFAULT,
    fillParking: fillParking,
    guessEntrance: guessEntrance,
    _makeFrame: makeFrame,
    _areaXY: areaXY,
    _centroidXY: centroidXY
  };
})(typeof window !== 'undefined' ? window : this);
