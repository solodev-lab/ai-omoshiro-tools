/* autodraft.js — 配置図の自動下書き（正典 §9 Step 3 / §11-b）
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * オープンデータから「編集できる図形」を起こす。写真のトレースではないので
 * 権利上クリーン（正典 §11-b の三分法・レーンA）。
 *   ・道路縁   RdEdg  国土地理院ベクトルタイル（全国）
 *   ・建物外形 BldA   国土地理院ベクトルタイル（全国）
 *   ・筆界+地番 fude  法務省 登記所備付地図（取れる地域のみ・約半分は任意座標で未整備）
 *
 * 生成物はすべて普通のオブジェクトなので、ドラッグで直せる・消せる
 * （正典 §5「自動の線がドラッグで直せればOK」と同じ思想）。
 */
(function (global) {
  'use strict';

  // 法務省地図XMLアダプトプロジェクト(amx-a)の変換版。Range 取得・CORS 可を実測確認済み。
  // 公式配信ではないので、落ちても本体が動かなくなることはない作りにする。
  var MOJ_URL = 'https://data.source.coop/smartmaps/amx-2024-04/MojMap_amx_2024.pmtiles';
  var MOJ_ZOOM = 16;
  var GSI_ZOOM = 16;
  var MOJ_ATTR = '出典：法務省 登記所備付地図データ（加工して作成）';

  var _moj = null;
  function moj() {
    if (!_moj) _moj = new PMTiles(MOJ_URL);
    return _moj;
  }

  /* ---------- タイル座標 → 緯度経度 ---------- */
  function featureToLatLngs(ring, tile, extent) {
    var out = [];
    for (var i = 0; i < ring.length; i++) {
      var wx = tile.x + ring[i][0] / extent;
      var wy = tile.y + ring[i][1] / extent;
      var ll = GSI.tileToLonLat(wx, wy, tile.z);
      out.push({ lat: ll.lat, lng: ll.lon });
    }
    return out;
  }

  /**
   * 図形が範囲に掛かるか。外接矩形どうしの重なりで見る。
   * 「頂点が範囲内にあるか」で判定してはいけない:
   *   ・範囲を横切るだけの長い道路（頂点は両方とも範囲外）
   *   ・範囲より大きい敷地（頂点が全部範囲外）
   * が丸ごと漏れる。
   */
  function inBounds(pts, b) {
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

  /** 取得範囲を少し広げる。画面ぎりぎりだと隣接道路が入らないため */
  function padBounds(b, ratio, minMeters) {
    var dLat = (b.north - b.south) * ratio;
    var dLng = (b.east - b.west) * ratio;
    var midLat = (b.north + b.south) / 2;
    var minLat = (minMeters || 0) / 110540;
    var minLng = (minMeters || 0) / (111320 * Math.cos(midLat * Math.PI / 180));
    dLat = Math.max(dLat, minLat);
    dLng = Math.max(dLng, minLng);
    return { west: b.west - dLng, east: b.east + dLng,
             south: b.south - dLat, north: b.north + dLat };
  }

  /** 画面の範囲を覆うタイル添字 */
  function tileRange(bounds, z) {
    var a = GSI.lonLatToTile(bounds.west, bounds.north, z);
    var b = GSI.lonLatToTile(bounds.east, bounds.south, z);
    return { x0: Math.floor(a.x), x1: Math.floor(b.x),
             y0: Math.floor(a.y), y1: Math.floor(b.y) };
  }

  /* ================= 国土地理院ベクトル ================= */

  /**
   * 道路縁と建物外形を取る。
   * 返り値: { roads: [[latlng,...]], buildings: [[latlng,...]] }
   */
  function fetchGsiShapes(rawBounds, want) {
    // 画面の外側も少し拾う（前面道路が画面ぎりぎりでも入るように）
    var bounds = padBounds(rawBounds, 0.35, 40);
    var r = tileRange(bounds, GSI_ZOOM), jobs = [];
    for (var x = r.x0; x <= r.x1; x++) {
      for (var y = r.y0; y <= r.y1; y++) jobs.push(GSI.fetchTile(GSI_ZOOM, x, y));
    }
    return Promise.all(jobs).then(function (tiles) {
      var roads = [], buildings = [], widths = [];
      tiles.forEach(function (t) {
        if (!t) return;
        // 道路中心線は描かないが、幅員(vt_width=cm)だけ拾って参考値に使う
        if (t.layers.RdCL) {
          var C = t.layers.RdCL;
          C.features.forEach(function (f) {
            var wcm = f.props && f.props.vt_width;
            if (!wcm) return;
            f.geom.forEach(function (g) {
              if (!g.length) return;
              var pts = featureToLatLngs(g, t, C.extent);
              if (!inBounds(pts, bounds)) return;
              var mid = pts[Math.floor(pts.length / 2)];
              widths.push({ at: mid, width_m: wcm / 100,
                            rank: f.props.vt_rnkwidth || '',
                            ctg: f.props.vt_rdctg || '' });
            });
          });
        }
        if (want.roads && t.layers.RdEdg) {
          var L = t.layers.RdEdg;
          L.features.forEach(function (f) {
            f.geom.forEach(function (g) {
              if (g.length < 2) return;
              var pts = featureToLatLngs(g, t, L.extent);
              if (inBounds(pts, bounds)) roads.push(pts);
            });
          });
        }
        if (want.buildings && t.layers.BldA) {
          var B = t.layers.BldA;
          B.features.forEach(function (f) {
            f.geom.forEach(function (g) {
              if (g.length < 3) return;
              var pts = featureToLatLngs(g, t, B.extent);
              if (inBounds(pts, bounds)) buildings.push(pts);
            });
          });
        }
      });
      return { roads: roads, buildings: buildings, widths: widths };
    });
  }

  /* ================= 法務省 筆界 ================= */

  /**
   * 筆ポリゴンを取る。返り値: [{points:[latlng], chiban, props}]
   * データが無い地域では空配列（都市部は未整備が多い・正典 §11-b）。
   */
  function fetchParcels(rawBounds) {
    var bounds = padBounds(rawBounds, 0.35, 40);
    var r = tileRange(bounds, MOJ_ZOOM), jobs = [];
    var p = moj();
    for (var x = r.x0; x <= r.x1; x++) {
      for (var y = r.y0; y <= r.y1; y++) {
        (function (tx, ty) {
          jobs.push(p.getTile(MOJ_ZOOM, tx, ty).then(function (buf) {
            return buf ? { z: MOJ_ZOOM, x: tx, y: ty, buf: buf } : null;
          }).catch(function () { return null; }));
        })(x, y);
      }
    }
    return Promise.all(jobs).then(function (tiles) {
      var out = [], seen = {}, nearby = 0;
      tiles.forEach(function (t) {
        if (!t) return;
        var layers;
        try { layers = MVT.decode(t.buf); } catch (e) { return; }
        var L = layers.fude;
        if (!L) return;
        // 範囲外も含めた総数。0 なら「未整備」、多いのに範囲内が0なら「範囲外」
        nearby += L.features.length;
        L.features.forEach(function (f) {
          if (!f.geom.length) return;
          var g = f.geom[0];
          if (g.length < 3) return;
          var pts = featureToLatLngs(g, t, L.extent);
          if (!inBounds(pts, bounds)) return;
          var pr = f.props || {};
          var chiban = pr['地番'] || '';
          // タイル跨ぎの重複を落とす
          var key = chiban + '@' + pts[0].lat.toFixed(6) + ',' + pts[0].lng.toFixed(6);
          if (seen[key]) return;
          seen[key] = true;
          out.push({ points: pts, chiban: chiban, props: pr });
        });
      });
      out.nearbyTotal = nearby;    // 近隣タイルにあった筆の総数
      return out;
    });
  }

  /** 法務省データが使えるか（配信の生死確認を兼ねる） */
  function probeMoj() {
    return moj().header().then(function (h) {
      return { ok: true, minZoom: h.minZoom, maxZoom: h.maxZoom };
    }).catch(function (e) {
      return { ok: false, error: e.message };
    });
  }

  /* ================= 図形への変換 ================= */

  function uid() {
    return 'o' + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  }

  /** 折れ線（道路縁）。開いた線なので path 型で作る */
  function toPath(points, style) {
    return { id: uid(), type: 'path', points: points, closed: false,
             style: style || { w: 1.6, color: '#333' }, source: 'auto' };
  }
  /** 閉じた輪郭（建物・筆界） */
  function toPolygon(points, style) {
    return { id: uid(), type: 'polygon', points: points,
             style: style || { w: 1.6, color: '#333' }, source: 'auto' };
  }

  /** 点列の重心（地番ラベルを置く位置）
   *
   * 🔴 生の緯度経度のまま多角形公式に入れてはいけない。
   *    経度137・緯度35 どうしの積の差から 1e-8 程度の値を取り出すことになり、
   *    倍精度でも桁落ちで**数十メートルずれる**（実測でそうなった）。
   *    先頭の点を原点に引いてから計算し、最後に足し戻す。
   */
  function centroid(pts) {
    var o = pts[0];
    var a = 0, cx = 0, cy = 0;
    for (var i = 0; i < pts.length; i++) {
      var p = pts[i], q = pts[(i + 1) % pts.length];
      var px = p.lng - o.lng, py = p.lat - o.lat;
      var qx = q.lng - o.lng, qy = q.lat - o.lat;
      var f = px * qy - qx * py;
      a += f; cx += (px + qx) * f; cy += (py + qy) * f;
    }
    if (Math.abs(a) < 1e-18) {
      var sx = 0, sy = 0;
      pts.forEach(function (p) { sx += p.lng - o.lng; sy += p.lat - o.lat; });
      return { lat: o.lat + sy / pts.length, lng: o.lng + sx / pts.length };
    }
    a *= 0.5;
    return { lat: o.lat + cy / (6 * a), lng: o.lng + cx / (6 * a) };
  }

  /** 多角形の内外判定（敷地クリック用） */
  function pointInPolygon(pt, pts) {
    var inside = false;
    for (var i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      var xi = pts[i].lng, yi = pts[i].lat, xj = pts[j].lng, yj = pts[j].lat;
      if (((yi > pt.lat) !== (yj > pt.lat)) &&
          (pt.lng < (xj - xi) * (pt.lat - yi) / (yj - yi) + xi)) inside = !inside;
    }
    return inside;
  }

  /** 面積(m2)。おおよそで良い（正典 §0）。重心と同じ理由で局所座標に直してから計算する */
  function areaM2(pts) {
    if (pts.length < 3) return 0;
    var o = pts[0];
    var mx = 111320 * Math.cos(o.lat * Math.PI / 180), my = 110540;
    var a = 0;
    for (var i = 0; i < pts.length; i++) {
      var p = pts[i], q = pts[(i + 1) % pts.length];
      var px = (p.lng - o.lng) * mx, py = (p.lat - o.lat) * my;
      var qx = (q.lng - o.lng) * mx, qy = (q.lat - o.lat) * my;
      a += px * qy - qx * py;
    }
    return Math.abs(a / 2);
  }

  global.AutoDraft = {
    MOJ_URL: MOJ_URL,
    MOJ_ATTR: MOJ_ATTR,
    fetchGsiShapes: fetchGsiShapes,
    fetchParcels: fetchParcels,
    probeMoj: probeMoj,
    toPath: toPath,
    toPolygon: toPolygon,
    centroid: centroid,
    pointInPolygon: pointInPolygon,
    areaM2: areaM2
  };
})(typeof window !== 'undefined' ? window : this);
