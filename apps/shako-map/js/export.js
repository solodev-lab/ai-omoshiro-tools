/* export.js — 書き出し（正典 §7 / Step 4）
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * 🔴 書き出すのは**描画レイヤーだけ**。下敷きの地図・航空写真は一切含めない
 *    （正典 §1-3。この一線がツール全体の権利設計の根拠）。
 *
 * 画面は SVG、書き出しは canvas。描く元のオブジェクトは同じ1つのモデル
 * （正典 §6「レンダラ2系統・モデル1つ」）。だから画面で見た図がそのまま出る。
 */
(function (global) {
  'use strict';

  /* 旧・様式風A4横の記載欄1枠（幅×高さ mm）。
     🔴 §25-3 で「A4横1枚に所在図＋配置図」は**廃止**した（→ 下の PAGE 一式）。
     この値が残っているのは2つの理由だけ:
       ① aspect を持たない**旧データの枠**は、当時この形で切られていたので
          そのまま読む必要がある（frameAspect の既定値）
       ② 文字・線の mm 値が「この幅の紙で見えていた大きさ」を基準に決まっている
          （SHEET_SCALE） */
  var PANEL_MM = { w: 138, h: 160 };
  var ASPECT = PANEL_MM.w / PANEL_MM.h;
  var DPI = 300;
  // 線の太さの基準。画面で 2px の線が、この幅の紙面で同じ見え方になるようにする
  var NOMINAL_W = 1000;
  /* 文字は紙面での大きさ(mm)で決める。ズームや作図時の倍率に影響されない。
     3.4mm ≒ 9.6pt で、Step 0 の実測（300dpi で 9.4pt は読める）を満たす。
     🔴 実際に紙へ出る大きさは SHEET_SCALE 倍（下記）。 */
  var SHEET_TEXT_MM = { small: 2.6, medium: 3.4, large: 4.4 };

  /* ================= 紙面（🔒 §24-3 / §25-3「1図1ページ」） =================
   *
   * 従来（Step 5 まで）: A4横1枚に「所在図記載欄 138×160mm」と「配置図記載欄」を
   * 並べて刷っていた。§25-3 でこの方式は**廃止**。図1つ ＝ 紙1ページになった。
   * 紙の向き（A4縦／A4横）はシートごとにユーザーが決める（§24-1）。
   *
   * 🔴 §24-4-b 持ち越し2 の直し方（これが Step 6 の肝のひとつ）:
   *    文字・線は「紙面ミリ」で決める規則（§9-g）なのに、ミリ→ピクセルの換算に
   *    **PANEL_MM.w（＝縦の紙の幅）固定**を使っていた。A4横は紙が広いので同じ mm 値が
   *    1.16 倍のピクセルになり、**横の紙だけ文字が約16%大きく**刷られていた。
   *    → 換算は「紙 1mm が何ピクセルか（pxmm）」1本に統一する。pxmm は dpi だけで
   *      決まり**向きに依らない**ので、縦でも横でも文字の物理サイズが必ず一致する。
   */
  var A4 = { w: 210, h: 297 };      // mm
  var MARGIN_MM = 10;               // 紙の四辺の余白
  var HEAD_MM = 12;                 // 見出し帯（表題 ＋「所在図 1/3」の通し表示）
  var HEAD_GAP_MM = 2;              // 見出しと図の間
  var FOOT_MM = 8;                  // 欄外（縮尺の目安）

  function pageSize(orient) {
    return (orient === 'landscape') ? { w: A4.h, h: A4.w } : { w: A4.w, h: A4.h };
  }

  /** その向きの紙と「作図領域（図が載る箱）」。単位は mm・原点は紙の左上 */
  function pageLayout(orient) {
    var p = pageSize(orient);
    var box = {
      x: MARGIN_MM,
      y: MARGIN_MM + HEAD_MM + HEAD_GAP_MM,
      w: p.w - MARGIN_MM * 2,
      h: p.h - MARGIN_MM * 2 - HEAD_MM - HEAD_GAP_MM - FOOT_MM
    };
    return { page: p, box: box, aspect: box.w / box.h };
  }

  /**
   * 🔒 §25-3: A4の向き → 枠（書き出し範囲）の縦横比。
   * 🔴 **枠と紙面の比率をここ1か所で一致させる**（§24-4-b 持ち越し3）。
   *    画面の枠・保存する frame.aspect・紙の作図領域が全部この値で揃う。
   */
  function orientAspect(orient) { return pageLayout(orient).aspect; }

  /** 箱の中に aspect の図を収める（はみ出させず・中央へ）。返り値は mm 矩形 */
  function fitBox(box, aspect) {
    var w = box.w, h = w / aspect;
    if (h > box.h) { h = box.h; w = h * aspect; }
    return { x: box.x + (box.w - w) / 2, y: box.y + (box.h - h) / 2, w: w, h: h };
  }

  /** その向き・その縦横比の図が、紙に実際に刷られる mm 矩形 */
  function placeOnPage(orient, aspect) {
    return fitBox(pageLayout(orient).box, aspect);
  }

  /* 文字・線の mm 値は「従来の記載欄（幅 138mm）で見えていた大きさ」を基準に持つ。
     1図1ページで作図領域が A4縦 190mm 幅まで広がったので、同じ**見え方**を保つよう
     一律に拡大する（＝紙が大きくなったぶん文字も大きく刷る。3.4mm → 4.68mm ≒ 13pt）。
     🔴 この倍率は**向きに依らない1つの定数**にすること。向きごとに変えると
        縦と横で文字の物理サイズが変わる（§24-4-b 持ち越し2 の再発）。 */
  var SHEET_SCALE = pageLayout('portrait').box.w / PANEL_MM.w;   // ≒ 1.377

  /** 紙 1mm あたりの出力ピクセル数（向きに依らない） */
  function pxPerMm(dpi) { return (dpi || DPI) / 25.4; }

  /* ================= 投影（画面と同じ Web メルカトル） ================= */

  function mercX(lng) { return (lng + 180) / 360; }
  function mercY(lat) {
    var s = Math.sin(lat * Math.PI / 180);
    s = Math.max(-0.9999, Math.min(0.9999, s));
    return 0.5 - Math.log((1 + s) / (1 - s)) / (4 * Math.PI);
  }
  /** mercY の逆。Y(0..1) → 緯度 */
  function invMercY(y) {
    return (2 * Math.atan(Math.exp((0.5 - y) * 2 * Math.PI)) - Math.PI / 2)
           * 180 / Math.PI;
  }
  /* 赤道の周長(m)。地図の1ピクセル≒何メートルかの基準（mapview.js と同じ値） */
  var EQUATOR_M = 40075016.686;
  /** 緯度 lat での「投影1単位(world)あたりの実距離(m)」 */
  function metersPerUnit(lat) {
    return EQUATOR_M * Math.cos(lat * Math.PI / 180);
  }

  /**
   * 書き出し範囲(中心＋横の実距離) → 緯度経度の矩形。
   * 🔒 §24-1/§25-3: 枠は A4 の向きを持つ（frame.aspect ＝ 幅/高さ）。
   * 🔴 aspect を持たない旧データは従来どおり記載欄の縦比（138/160）で読む。
   *    紙面レイアウトそのものの刷新（1図1ページ・複数ページPDF）は Step 6。
   */
  function frameAspect(frame) {
    var a = frame && Number(frame.aspect);
    return (isFinite(a) && a > 0.05 && a < 20) ? a : ASPECT;
  }

  /**
   * 枠 → 緯度経度の矩形。
   * 🔴 §24-4-b 持ち越し3 の直し方: 高さを「緯度1度＝110540m」で出していたため、
   *    メルカトルに投影すると指定 aspect より **0.7% 縦長**になっていた
   *    （紙の箱に入れると 0.7% だけ横に伸びる＝円が楕円になる。［枠へ移動］が
   *      1段ズームを外すのを避けるために 3% のはみ出しを許していた原因もこれ）。
   *    正しくは「投影した高さ＝投影した幅 ÷ aspect」。緯度は mercY の逆関数で戻す。
   *    こうすると**画面の枠・保存した枠・紙の図が完全に同じ形**になる。
   */
  function frameBounds(frame) {
    var asp = frameAspect(frame);
    var w = frame.w_m;
    // 投影(world 0..1)での幅と高さ。中心緯度の実距離 w_m を投影の長さに直す
    var dx = w / metersPerUnit(frame.center.lat);
    var dy = dx / asp;
    var yc = mercY(frame.center.lat);
    var north = invMercY(yc - dy / 2), south = invMercY(yc + dy / 2);
    var dLng = dx * 360 / 2;
    return { west: frame.center.lng - dLng, east: frame.center.lng + dLng,
             south: south, north: north,
             // 高さの実距離（南北の地上距離）。参考値なので緯度差から出す
             w_m: w, h_m: (north - south) * (EQUATOR_M / 360) };
  }

  function makeProjector(b, outW, outH) {
    var x0 = mercX(b.west), x1 = mercX(b.east);
    var y0 = mercY(b.north), y1 = mercY(b.south);
    return function (lat, lng) {
      return { x: (mercX(lng) - x0) / (x1 - x0) * outW,
               y: (mercY(lat) - y0) / (y1 - y0) * outH };
    };
  }

  /* ================= 図形を canvas に描く ================= */

  /** 紙面ミリ → 出力ピクセル（pxmm ＝ 紙1mm あたりのピクセル数） */
  function textPx(o, pxmm) {
    return mmPx(SHEET_TEXT_MM[o.size] || SHEET_TEXT_MM.medium, pxmm);
  }

  /**
   * 文字列の幅を em で見積もる（🔒 §18-j）。全角＝1.0em／半角・英数＝0.55em。
   * 🔴 **文字数 × 定数では日本語の幅を測れない**。
   *    「文字数×0.62」で見積もっていた頃は、日本語の実幅（＝文字数×1.0）に対して
   *    38% も小さく、所在図のラベルを●の脇へ逃がしたつもりが**文字の下に●が潜って
   *    消える**という不具合になっていた（§18-j の実測）。
   *    ここが唯一の実装で、editor.js（画面）・shozaizu.js（配置計算）も
   *    実行時にこれを呼ぶ。片方だけ直すと画面と紙で形がずれるため増やさない。
   */
  function textEmWidth(s) {
    var w = 0, t = s || '';
    for (var i = 0; i < t.length; i++) {
      var c = t.charCodeAt(i);
      w += (c < 0x100 || (c >= 0xFF61 && c <= 0xFF9F)) ? 0.55 : 1;
    }
    return w;
  }

  /**
   * 寸法・番号などの補助文字の大きさ（🔒 §18-v）。**紙面ミリ**で決める。
   * 🔴 従来は「線の太さの倍率 S（= 出力幅 / 1000）」を文字にも掛けていた。
   *    300dpi では S≒1.63 なので 12*S ≒ 20px ＝ **1.7mm** にしかならず、
   *    画面（枠 488px に 12px ＝ 紙面 3.4mm 相当）の半分の大きさで刷られていた
   *    ＝ 実機で「4m・5m が豆粒で読めない」の正体。
   *    正典 §9-g「文字は紙面で一定の大きさ」の原則どおり mm 基準に直す。
   *    🔴 方位記号・スケールバー・出典（枠の外の飾り）は図面の寸法表記ではないので
   *       従来の S 基準のまま（他の飾りと大きさの釣り合いが崩れるため）。
   */
  var LABEL_MM = { dim: 3.4, storage: 3.4, number: 4.4 };
  /**
   * 紙面ミリ → 出力ピクセル。
   * 🔴 §24-4-b 持ち越し2: 以前は `mm / PANEL_MM.w * outW`（縦の紙の幅で割る）だった。
   *    A4横は outW が広いので、同じ mm 指定が **1.16 倍のピクセル**になっていた
   *    ＝ 横の紙だけ文字が大きく出る不具合。pxmm（紙1mm のピクセル数）で掛けるだけに
   *    すると、向きにも図の大きさにも左右されず物理サイズが決まる。
   */
  function mmPx(mm, pxmm) {
    return Math.max(6, mm * SHEET_SCALE * (pxmm || pxPerMm(DPI)));
  }
  /**
   * 線の太さの倍率 S（画面 2px の線が紙で何ピクセルになるか）。
   * 従来は「出力幅 ÷ 1000」＝ 記載欄 138mm の 1/1000 ＝ 0.138mm を 1 単位にしていた。
   * 同じ太さのまま**向きに依らない**ようにするため mm 基準へ直す
   * （300dpi・A4縦なら従来と同じ 2.24。従来の A4横は 3.27 で 46% 太かった）。
   */
  function lineScale(pxmm) {
    return (PANEL_MM.w / NOMINAL_W) * SHEET_SCALE * (pxmm || pxPerMm(DPI));
  }

  /* ---------- 道路の「白帯＋黒縁」（🔒 §23-9） ----------
   * 寸法の決め方は editor.js の Editor.roadBand が**唯一の実装**。
   * ここは読むだけ（export.js を単体で読み込んだ時だけ黒1本に落ちる）。
   * ＝ 画面と紙で必ず同じ形になる（Editor.MARK / markConf と同じ作法）。 */
  function roadBandOf(o, ctx) {
    return (global.Editor && global.Editor.roadBand) ? global.Editor.roadBand(o, ctx) : null;
  }
  function isCasingRoad(o) {
    return !!(o && (o.type === 'path' || o.type === 'polygon')
              && o.style && o.style.casing && o.points && o.points.length >= 2
              && roadBandOf(o));
  }

  /**
   * 🔒 §23-9: 連続する道路を**塊まるごと2パス**（全部の黒縁 → 全部の白帯）で描く。
   * 1本ずつ黒→白と描くと次の道路の黒縁が前の白帯に乗り、交差点が黒くぶつ切りになる。
   * 画面（editor.js `_drawRoadRun`）と同じ手順・同じ寸法。
   * 🔒 §22-at: mPerU（1Uが表す実距離(m)）を渡し、widthM を持つ道路の外幅に反映する。
   */
  function drawRoadRun(g, run, proj, S, mPerU) {
    var ctx = { mPerU: mPerU };
    var bds = run.map(function (o) { return roadBandOf(o, ctx); });
    g.save();
    g.lineCap = 'round';
    g.lineJoin = 'round';
    g.setLineDash([]);
    run.forEach(function (o, i) {                    // パス1: 黒の縁取り
      tracePts(g, o.points, proj, o.type !== 'path');
      g.strokeStyle = bds[i].outerColor;
      g.lineWidth = Math.max(0.6, bds[i].outer * S);
      g.stroke();
    });
    run.forEach(function (o, i) {                    // パス2: 白い帯
      if (!(bds[i].inner > 0)) return;
      tracePts(g, o.points, proj, o.type !== 'path');
      g.strokeStyle = bds[i].innerColor;
      g.lineWidth = Math.max(0.6, bds[i].inner * S);
      g.stroke();
    });
    g.restore();
  }

  function drawObjects(g, objects, proj, S, mpp, pxmm) {
    // S = 線の太さの倍率、mpp = 1px あたりの実距離(m)
    // 🔒 §22-at: 1U が表す実距離(m) = 出力px何個ぶんか(S) × 1pxの実距離(mpp)
    var mPerU = mpp * S;
    /* 🔒 §22-at-3 欠陥2-①: 文字（drawOneObject の case 'text' が引き出し線・
     * ●・アイコンごと描く）は道路の帯・川・建物より**必ず後**に描く。画面
     * （editor.js render）と同じ理屈・同じ分け方（objects の並びには触らない）。 */
    var texts = [];
    for (var i = 0; i < objects.length; i++) {
      var o = objects[i];
      if (o.type === 'text') { texts.push(o); continue; }
      if (isCasingRoad(o)) {
        var run = [];
        while (i < objects.length && isCasingRoad(objects[i])) { run.push(objects[i]); i++; }
        i--;
        drawRoadRun(g, run, proj, S, mPerU);
        continue;
      }
      drawOneObject(g, o, proj, S, mpp, pxmm);
    }
    for (var ti = 0; ti < texts.length; ti++) {
      drawOneObject(g, texts[ti], proj, S, mpp, pxmm);
    }
  }

  function drawOneObject(g, o, proj, S, mpp, pxmm) {
    {
      var st = o.style || {};
      g.save();
      g.lineCap = 'round';
      g.lineJoin = 'round';
      g.strokeStyle = st.color || '#111';
      g.lineWidth = Math.max(0.6, (st.w || 2) * S);

      switch (o.type) {
        case 'line': {
          var a = proj(o.a.lat, o.a.lng), b2 = proj(o.b.lat, o.b.lng);
          if (st.dash) g.setLineDash(st.dash.split(' ').map(function (v) {
            return parseFloat(v) * S; }));
          g.beginPath(); g.moveTo(a.x, a.y); g.lineTo(b2.x, b2.y); g.stroke();
          break;
        }
        case 'curve': {
          var p0 = proj(o.a.lat, o.a.lng), pc = proj(o.c.lat, o.c.lng),
              p1 = proj(o.b.lat, o.b.lng);
          g.beginPath(); g.moveTo(p0.x, p0.y);
          g.quadraticCurveTo(pc.x, pc.y, p1.x, p1.y); g.stroke();
          break;
        }
        case 'polygon':
        case 'path': {
          if (!o.points || o.points.length < 2) break;
          var closed = (o.type !== 'path');
          if (st.rail) {
            // 鉄道は白黒ハッチ（正典 §5）
            tracePts(g, o.points, proj, closed);
            g.lineWidth = (st.w || 2.6) * S; g.strokeStyle = '#111'; g.stroke();
            tracePts(g, o.points, proj, closed);
            g.lineWidth = (st.w || 2.6) * S * 0.62; g.strokeStyle = '#fff';
            g.setLineDash([7 * S, 7 * S]); g.stroke();
          } else {
            if (st.dash) g.setLineDash(st.dash.split(' ').map(function (v) {
              return parseFloat(v) * S; }));
            tracePts(g, o.points, proj, closed);
            /* 🔒 2026-09-03: st.fill を持つ図形だけ塗る（＝水域面 WA・§23-9 の
             * 明示的な例外）。画面（editor.js `_drawPolygon`）と同じ規則:
             * 塗りだけで線を持たない物（st.w が 0）は stroke しない。 */
            if (st.fill) {
              g.fillStyle = st.fill;
              g.fill();
              if (!(st.w > 0)) break;
            }
            g.stroke();
          }
          break;
        }
        case 'rect': {
          drawRect(g, o, proj, S, mpp, pxmm);
          break;
        }
        case 'stampGroup': {
          drawStamp(g, o, proj, S, mpp, pxmm);
          break;
        }
        case 'arrow': {
          /* 🔒 §25-5（2026-08-29・§4-6 再改定）: 矢印は**必ず値つきで紙に出す**。
           * 手入力があればそれ、無ければ地図から計算した実距離（arrowText）。
           * 🔴 旧規則「ラベル未確定の矢印は紙に出さない」は、参考値が薄字表示
           *    だった時代の物。自動値は提出物に載せる値そのものになった
           *    （立入できない所・広い道路は地図上で計算して記載する実務）。 */
          drawArrow(g, o, proj, S, mpp, pxmm);
          break;
        }
        case 'text': {
          var tp = proj(o.at.lat, o.at.lng);
          var tsz = textPx(o, pxmm);
          // 🔒 §18-8: 目標物の●（anchor）は紙にも同じ規則で出す
          if (o.anchor) drawAnchor(g, proj(o.anchor.lat, o.anchor.lng), tp, o, tsz, S);
          // 🔒 §22-av: 路線番号の印（国道 ▽ / 都道府県道 六角形）を数字の下に敷く
          if (o.badge) drawBadge(g, tp, o, tsz, S);
          drawText(g, tp, o.text, tsz, st.color || '#111', S);
          break;
        }
        case 'labelBlock': {
          // 🔒 §18-f 駐車位置ラベル: 駐車位置ラベルの塊。画面（editor.js）と同じ形で紙にも出す
          drawLabelBlock(g, o, proj, S, pxmm);
          break;
        }
        case 'compass': {
          // 🔒 §28-3: 方位記号は「部品」。自動では描かず、置かれた場所に出す
          drawCompass(g, o, proj, S, pxmm);
          break;
        }
      }
      g.restore();
    }
  }

  function tracePts(g, pts, proj, closed) {
    g.beginPath();
    for (var i = 0; i < pts.length; i++) {
      var p = proj(pts[i].lat, pts[i].lng);
      if (i === 0) g.moveTo(p.x, p.y); else g.lineTo(p.x, p.y);
    }
    if (closed) g.closePath();
  }

  /* 交差点名の信号機アイコン（🔒 2026-09-02）。寸法は editor.js の
   * Editor.signalGeom が**唯一の出どころ**（Editor.MARK / roadBand と同じ作法）。
   * ここは読むだけ（export.js 単体で読み込まれた時だけ既定に落ちる）。 */
  var SIGNAL_FALLBACK = { w: 1.25, h: 0.55, r: 0.13, gap: 0.375, rx: 0.16, lw: 1.6 };
  function signalGeom(size) {
    if (global.Editor && global.Editor.signalGeom) return global.Editor.signalGeom(size);
    var K = SIGNAL_FALLBACK;
    return { w: size * K.w, h: size * K.h, r: size * K.r,
             gap: size * K.gap, rx: size * K.rx, lw: K.lw };
  }
  /* バス停の標識アイコン（🔒 2026-09-04）。寸法は editor.js の
   * Editor.busStopGeom が**唯一の出どころ**（signalGeom と同じ作法）。
   * ここは読むだけ（export.js 単体で読み込まれた時だけ既定に落ちる）。 */
  var BUSSTOP_FALLBACK = { bw: 0.42, bh: 0.68, rx: 0.10, pole: 0.32, foot: 0.50, lw: 1.6 };
  function busStopGeom(size) {
    if (global.Editor && global.Editor.busStopGeom) return global.Editor.busStopGeom(size);
    var K = BUSSTOP_FALLBACK;
    return { bw: size * K.bw, bh: size * K.bh, rx: size * K.rx,
             pole: size * K.pole, foot: size * K.foot, lw: K.lw,
             h: size * (K.pole + K.bh) };
  }
  /** 角丸矩形のパス（canvas 標準の roundRect は環境差があるので自前で引く） */
  function roundRectPath(g, x, y, w, h, r) {
    r = Math.max(0, Math.min(r, w / 2, h / 2));
    g.beginPath();
    g.moveTo(x + r, y);
    g.lineTo(x + w - r, y);
    g.arcTo(x + w, y, x + w, y + r, r);
    g.lineTo(x + w, y + h - r);
    g.arcTo(x + w, y + h, x + w - r, y + h, r);
    g.lineTo(x + r, y + h);
    g.arcTo(x, y + h, x, y + h - r, r);
    g.lineTo(x, y + r);
    g.arcTo(x, y, x + r, y, r);
    g.closePath();
  }

  /* 引き出し線（🔒 §22-am-2 / §22-am-6-2）。太さ・破線は editor.js の Editor.LEAD が
   * **唯一の出どころ**（Editor.SIGNAL / busStopGeom と同じ作法）。
   * ここは読むだけ（export.js 単体で読み込まれた時だけ既定に落ちる）。 */
  var LEAD_FALLBACK = { w: 1.1, dash: [3, 2], hHalf: 0.5, pad: 0.11 };
  function leadConf() {
    return (global.Editor && global.Editor.LEAD) || LEAD_FALLBACK;
  }
  /* 🔒 §22-am-6-2: ●から**文字の箱の縁**まで（隙間 0）。幾何も editor.js が出どころ */
  function leadStop(dx, dy, d, wHalf, size) {
    if (global.Editor && global.Editor.leadStop) {
      return global.Editor.leadStop(dx, dy, d, wHalf, size);
    }
    if (!(d > 0)) return 0;
    var K = LEAD_FALLBACK;
    var hw = wHalf + size * K.pad, hh = size * (K.hHalf + K.pad);
    var m = Math.max(Math.abs(dx) / d / hw, Math.abs(dy) / d / hh);
    return m > 0 ? Math.min(1 / m, d) : 0;
  }
  /** 🔒 §22-am-6-2: 引き出し線の終点を出すための文字の半幅（実際に描かれる幅の半分） */
  function leadTextHalf(g, text, sizePx, o) {
    // 🔒 §22-av: 印つき（路線番号）は印の半幅（画面と同じ関数で出す）
    if (o && o.badge && global.Editor && global.Editor.drawHalfWidth) {
      return global.Editor.drawHalfWidth(o, sizePx);
    }
    if (global.Editor && global.Editor.textDrawWidth) {
      return global.Editor.textDrawWidth(text, sizePx) / 2;
    }
    var old = g.font;
    g.font = '700 ' + sizePx + 'px "Yu Gothic UI","Meiryo",sans-serif';
    var w = g.measureText(text || '').width;
    g.font = old;
    return (w > 0 ? w : textEmWidth(text) * sizePx) / 2;
  }
  /** 🔒 §22-am-6-2: 線を描くか。判定も editor.js が出どころ（画面と紙で必ず同じ） */
  function wantLead(o, d, wHalf, size, near) {
    if (global.Editor && global.Editor.wantLead) {
      return global.Editor.wantLead(o, d, wHalf, size, near);
    }
    if (!(d > 0.5)) return false;
    if (o.lead === true) return true;
    if (o.lead === false) return false;
    return d > size * 2.2 + wHalf || (o.nearMain && d > near);
  }

  /**
   * 目標物の●（正典 §18-8）。位置は anchor で固定、文字（at）だけが動く。
   * 文字が離れている時は細い引き出し線でつなぐ（画面と同じ規則）。
   */
  function drawAnchor(g, a, p, o, sizePx, S) {
    var dx = p.x - a.x, dy = p.y - a.y;
    var d = Math.sqrt(dx * dx + dy * dy);
    /* 🔒 §18-j / §22-am-6-2: 文字の半幅は**実際に描かれる幅**で測る（画面と同じ関数）。
     * em の見積りだとカタカナで 25% 広く出て、線が文字の手前で止まる。 */
    var wHalf = leadTextHalf(g, o.text, sizePx, o);
    g.save();
    /* 🔒 §22-am-2 ⑥（2026-09-04）: 判定は editor.js `_drawText` と**同じ関数**にする。
     * 🔴 直す前はここに `o.nearMain` の枝が無く、画面には出ている引き出し線が
     *    紙に出ていなかった（§22-y の実装が画面側だけだった取りこぼし）。
     * 🔒 §22-am-6-2: いまは shozaizu.js が付ける印（o.lead）が答えで、
     *    印を持たない古いデータだけ距離しきい値に落ちる＝画面と紙で必ず同じ線になる。 */
    if (wantLead(o, d, wHalf, sizePx, 4 * S)) {
      var LD = leadConf();
      /* 🔒 §22-am-6-2: 文字の箱の縁で止める（隙間 0）。画面（editor.js）と同じ幾何 */
      var stop = leadStop(dx, dy, d, wHalf, sizePx);
      g.strokeStyle = '#6b7280';
      g.lineWidth = Math.max(0.6, LD.w * S);
      g.setLineDash([LD.dash[0] * S, LD.dash[1] * S]);
      g.beginPath();
      g.moveTo(a.x, a.y);
      g.lineTo(p.x - dx / d * stop, p.y - dy / d * stop);
      g.stroke();
      g.setLineDash([]);
    }
    var color = (o.style && o.style.color) || '#111';
    var r = Math.max(1.6, sizePx * 0.24);
    /* 🔒 §25-4: 新しい主役ラベルは dotStyle:'none'。印は四角＋斜線ハッチ（rect）が
     * 担うので●は紙にも描かない（引き出し線は上で描き終わっている）。 */
    if (o.dotStyle === 'none') { g.restore(); return; }
    /* 🔒 2026-09-02: 交差点名は●ではなく**信号機**（横長の角丸矩形＋3灯）。
     * 画面（editor.js）・薄出し（reveal.js）と同じ Editor.signalGeom を読むので
     * 3か所とも同じ形になる。輪郭は線だけ（§23-9）＝ 1.6U ＝ 300dpi で 0.304mm。
     * 🔴 旧データ（dotStyle 無し）は下の●に落ちる＝紙でも●のまま（後方互換）。 */
    if (o.dotStyle === 'signal') {
      var sg = signalGeom(sizePx);
      g.lineWidth = Math.max(0.8, sg.lw * S);
      g.strokeStyle = color;
      roundRectPath(g, a.x - sg.w / 2, a.y - sg.h / 2, sg.w, sg.h, sg.rx);
      g.stroke();
      g.fillStyle = color;
      for (var sgi = -1; sgi <= 1; sgi++) {
        g.beginPath();
        g.arc(a.x + sgi * sg.gap, a.y, sg.r, 0, Math.PI * 2);
        g.fill();
      }
      g.restore();
      return;
    }
    /* 🔒 2026-09-04: バス停は標識アイコン（角丸矩形の板＋ポール＋逆さT字の足）。
     * 画面（editor.js）・薄出し（reveal.js）と同じ Editor.busStopGeom を読むので
     * 3か所とも同じ形になる。塗りは一切なし（§23-9）。anchor（a）は足の接地点。
     * 🔴 旧データ（dotStyle 無し）は下の●に落ちる＝紙でも●のまま（後方互換）。 */
    if (o.dotStyle === 'bus') {
      var bg = busStopGeom(sizePx);
      var footY = a.y, poleTopY = footY - bg.pole, boardTopY = poleTopY - bg.bh;
      g.lineWidth = Math.max(0.8, bg.lw * S);
      g.strokeStyle = color;
      g.lineCap = 'round';
      g.beginPath();
      g.moveTo(a.x - bg.foot / 2, footY);
      g.lineTo(a.x + bg.foot / 2, footY);
      g.stroke();
      g.beginPath();
      g.moveTo(a.x, footY);
      g.lineTo(a.x, poleTopY);
      g.stroke();
      roundRectPath(g, a.x - bg.bw / 2, boardTopY, bg.bw, bg.bh, bg.rx);
      g.stroke();
      g.restore();
      return;
    }
    /* 🔒 §18-r: 自宅・駐車場は**二重丸（◎）で施設●の約2倍**（画面 editor.js と同じ形）。
     * 白黒印刷でも主役の2地点が一目で分かるようにする。
     * 🔴 この枝は**旧データ用に残す**（既存案件はそのまま二重丸で刷れる・§25-4-7）。 */
    if (o.dotStyle === 'double' || o.role === 'pinlabel') {
      var rr = r * 2;
      /* 🔒 §28-14 ①-4: ◎も色を選べる（形2種×色3種）。色の key は o.markColor で、
       * 四角の印と**同じ表**（Editor.MARK.colors）を読む。持っていない旧データは
       * 従来どおり文字と同じ色（黒）で刷る＝後方互換。 */
      var dHex = o.markColor ? markHex(o) : color;
      g.beginPath();
      g.arc(a.x, a.y, rr, 0, Math.PI * 2);
      g.fillStyle = '#fff';
      g.fill();
      g.lineWidth = Math.max(1, 2.2 * S);
      g.strokeStyle = dHex;
      g.stroke();
      g.beginPath();
      g.arc(a.x, a.y, rr * 0.45, 0, Math.PI * 2);
      g.fillStyle = dHex;
      g.fill();
      g.restore();
      return;
    }
    g.beginPath();
    g.arc(a.x, a.y, r, 0, Math.PI * 2);
    g.fillStyle = color;
    g.fill();
    g.lineWidth = Math.max(0.8, 1.3 * S);
    g.strokeStyle = '#fff';
    g.stroke();
    g.restore();
  }

  /** 白フチ付きの文字（航空写真が無くても図面上で読みやすい・正典 §4） */
  /**
   * 🔒 §22-av: 路線番号の印を紙へ描く。形は editor.js の badgeGeom が唯一の出どころ
   * （画面と紙で必ず同じ形になる）。白で塗ってから黒で縁取る＝下の道路の線を隠す。
   */
  function drawBadge(g, p, o, sizePx, S) {
    if (!global.Editor || !global.Editor.badgeGeom) return;
    var bg = global.Editor.badgeGeom(o.text, sizePx, o.badge);
    g.save();
    g.beginPath();
    for (var i = 0; i < bg.pts.length; i++) {
      var x = p.x + bg.pts[i][0], y = p.y + bg.pts[i][1];
      if (i) g.lineTo(x, y); else g.moveTo(x, y);
    }
    g.closePath();
    g.fillStyle = '#fff';
    g.fill();
    g.lineWidth = Math.max(0.8, 1.6 * S);
    g.lineJoin = 'round';
    g.strokeStyle = '#111';
    g.stroke();
    g.restore();
  }

  function drawText(g, p, text, sizePx, color, S) {
    if (!text) return;
    g.save();
    g.font = '700 ' + sizePx.toFixed(1) + 'px "Yu Gothic UI","Meiryo",sans-serif';
    g.textAlign = 'center';
    g.textBaseline = 'middle';
    g.lineWidth = Math.max(1.5, sizePx * 0.22);
    g.strokeStyle = '#fff';
    g.lineJoin = 'round';
    g.strokeText(text, p.x, p.y);
    g.fillStyle = color;
    g.fillText(text, p.x, p.y);
    g.restore();
  }

  /* ---------- 駐車位置ラベルの塊（正典 §18-f 駐車位置ラベル） ----------
   * editor.js の labelBlockGeom / _drawLabelBlock と同じ規則で描く。
   * 幅の見積りは共通の textEmWidth（§18-j）を使う。 */
  function labelBlockGeom(o, proj, pxmm) {
    var p = proj(o.at.lat, o.at.lng);
    var size = Math.max(6, textPx(o, pxmm) * (o.scale || 1));
    var lh = size * 1.5, pad = size * 0.45;
    var lines = o.lines || [];
    var maxEm = 0;
    lines.forEach(function (t) { maxEm = Math.max(maxEm, textEmWidth(t)); });
    return { x: p.x, y: p.y, size: size, lh: lh, pad: pad, lines: lines,
             w: Math.max(size * 2, maxEm * size + pad * 2),
             h: Math.max(size, lines.length * lh) + pad * 2 };
  }

  function boxEdgePoint(b, t, gap) {
    var cx = b.x + b.w / 2, cy = b.y + b.h / 2;
    var dx = t.x - cx, dy = t.y - cy;
    var len = Math.sqrt(dx * dx + dy * dy);
    if (!len) return { x: cx, y: cy };
    var s = Math.min(dx ? (b.w / 2) / Math.abs(dx) : Infinity,
                     dy ? (b.h / 2) / Math.abs(dy) : Infinity);
    var e = (gap || 0) / len;
    return { x: cx + dx * (s + e), y: cy + dy * (s + e) };
  }

  function drawLabelBlock(g, o, proj, S, pxmm) {
    if (!o.at) return;
    var b = labelBlockGeom(o, proj, pxmm);
    var st = o.style || {};
    var color = st.color || '#111';

    if (o.arrowTo) {
      var t = proj(o.arrowTo.lat, o.arrowTo.lng);
      var s0 = boxEdgePoint(b, t, b.size * 0.3);
      g.save();
      g.strokeStyle = color;
      g.lineWidth = Math.max(0.6, (st.w || 2) * S);
      g.beginPath(); g.moveTo(s0.x, s0.y); g.lineTo(t.x, t.y); g.stroke();
      var ang = Math.atan2(t.y - s0.y, t.x - s0.x), L = Math.max(5, b.size * 0.8);
      [-0.42, 0.42].forEach(function (d) {
        var e2 = ang + Math.PI + d;
        g.beginPath();
        g.moveTo(t.x, t.y);
        g.lineTo(t.x + Math.cos(e2) * L, t.y + Math.sin(e2) * L);
        g.stroke();
      });
      g.restore();
    }

    g.save();
    g.font = '700 ' + b.size.toFixed(1) + 'px "Yu Gothic UI","Meiryo",sans-serif';
    g.textAlign = 'left';
    g.textBaseline = 'middle';
    g.lineWidth = Math.max(1.5, b.size * 0.22);
    g.strokeStyle = '#fff';
    g.lineJoin = 'round';
    b.lines.forEach(function (line, i) {
      var x = b.x + b.pad, y = b.y + b.pad + b.lh * (i + 0.5);
      g.strokeText(line, x, y);
      g.fillStyle = color;
      g.fillText(line, x, y);
    });
    g.restore();
  }

  /* ---------- 主役マーク（🔒 §25-4 使用の本拠・駐車場） ----------
   * 定数（最小の紙面サイズ・ハッチ間隔・色）は editor.js の Editor.MARK が
   * **唯一の出どころ**。ここは読むだけ（単体で読み込まれた時だけ既定に落ちる）。 */
  var MARK_FALLBACK = { minMm: 4, hatchMm: 1.6, hatchW: 1.3, strokeW: 1.8,
                        colors: [{ key: 'red', hex: '#c0392b' }] };
  function markConf() {
    return (global.Editor && global.Editor.MARK) || MARK_FALLBACK;
  }
  function markHex(o) {
    var cs = markConf().colors || [];
    for (var i = 0; i < cs.length; i++) {
      if (cs[i].key === o.markColor) return cs[i].hex;
    }
    return (o.style && o.style.color) || MARK_FALLBACK.colors[0].hex;
  }

  function rectCorners(o, proj, mpp, pxmm) {
    var c = proj(o.center.lat, o.center.lng);
    var hw = (o.w_m / mpp) / 2, hh = (o.h_m / mpp) / 2;
    /* 🔒 §25-4: 主役マークは紙面での最小サイズを保証する
     * （広域の所在図で建物サイズの四角が消えないように。画面 editor.js と同じ規則）。 */
    if (o.role === 'mainmark') {
      var min = mmPx(markConf().minMm, pxmm) / 2;
      if (hw < min) hw = min;
      if (hh < min) hh = min;
    }
    var a = (o.angle || 0) * Math.PI / 180;
    var ca = Math.cos(a), sa = Math.sin(a);
    return [[-hw, -hh], [hw, -hh], [hw, hh], [-hw, hh]].map(function (p) {
      return { x: c.x + p[0] * ca - p[1] * sa, y: c.y + p[0] * sa + p[1] * ca };
    });
  }

  /**
   * 45°の斜線ハッチ（🔒 §25-4）。四角の中だけを clip して平行線を引く。
   * 🔴 べた塗りにしない ―― 白黒コピーでも斜線として残り、下の道路・建物も透ける。
   * 画面（SVG の pattern・patternTransform rotate(45)）と同じ見た目になるよう、
   * 線の間隔・太さは同じ mm 値から出す。
   */
  function drawHatch(g, c, hex, S, pxmm) {
    var sp = mmPx(markConf().hatchMm, pxmm);
    var minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
    c.forEach(function (p) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    });
    g.save();
    g.beginPath();
    g.moveTo(c[0].x, c[0].y);
    for (var i = 1; i < 4; i++) g.lineTo(c[i].x, c[i].y);
    g.closePath();
    g.clip();
    g.strokeStyle = hex;
    g.lineWidth = Math.max(0.6, (markConf().hatchW || 1.3) * S);
    g.setLineDash([]);
    /* 45°（右下がり）の線 x + y = k を、外接箱を覆う範囲で引く */
    var k0 = minX + minY, k1 = maxX + maxY;
    var span = (maxX - minX) + (maxY - minY);
    for (var k = k0; k <= k1; k += sp) {
      g.beginPath();
      g.moveTo(k - maxY - span, maxY + span);
      g.lineTo(k - minY + span, minY - span);
      g.stroke();
    }
    g.restore();
  }

  function drawRect(g, o, proj, S, mpp, pxmm) {
    var c = rectCorners(o, proj, mpp, pxmm);
    /* 🔒 §25-4: 主役マークは斜線ハッチ＋細い輪郭。
     * 🔴 寸法ラベル・番号・保管場所マークは付けない（車両枠とは別物）。 */
    if (o.role === 'mainmark') {
      var hex = markHex(o);
      drawHatch(g, c, hex, S, pxmm);
      g.beginPath();
      g.moveTo(c[0].x, c[0].y);
      for (var m = 1; m < 4; m++) g.lineTo(c[m].x, c[m].y);
      g.closePath();
      g.strokeStyle = hex;
      g.lineWidth = Math.max(0.8, ((o.style && o.style.w) || markConf().strokeW) * S);
      g.stroke();
      return;
    }
    g.beginPath();
    g.moveTo(c[0].x, c[0].y);
    for (var i = 1; i < 4; i++) g.lineTo(c[i].x, c[i].y);
    g.closePath();
    g.stroke();
    // 保管場所マーク（正典 §16-5 A）。画面と同じ見た目で紙にも出す
    if (o.storage) drawStorage(g, c, proj(o.center.lat, o.center.lng), S, pxmm);

    // 寸法ラベル（正典 §4-3）。自動の寸法は showDims で出し分けるが、
    // 利用者が入れた値(labelOverride)は OFF でも必ず紙に出す。
    var ctr = proj(o.center.lat, o.center.lng);
    if (o.showDims !== false) {
      dimLabel(g, c[0], c[1], ctr, fmtM(o.w_m), o, 'w', S, mpp, pxmm);
      dimLabel(g, c[1], c[2], ctr, fmtM(o.h_m), o, 'h', S, mpp, pxmm);
    } else if (o.labelOverride) {
      if (o.w_m >= o.h_m) dimLabel(g, c[0], c[1], ctr, fmtM(o.w_m), o, 'w', S, mpp, pxmm);
      else dimLabel(g, c[1], c[2], ctr, fmtM(o.h_m), o, 'h', S, mpp, pxmm);
    }

    if (o.number != null) {
      drawText(g, ctr, String(o.number), mmPx(LABEL_MM.number, pxmm), '#111', S);
    }
  }

  /** 保管場所の太枠＋ラベル（画面 editor.js の _drawStorage と同じ形） */
  function drawStorage(g, c, ctr, S, pxmm) {
    g.save();
    g.lineWidth = 5 * S;
    g.strokeStyle = '#111';
    g.beginPath();
    g.moveTo(c[0].x, c[0].y);
    for (var i = 1; i < 4; i++) g.lineTo(c[i].x, c[i].y);
    g.closePath();
    g.stroke();
    var mid = { x: (c[2].x + c[3].x) / 2, y: (c[2].y + c[3].y) / 2 };
    var vx = mid.x - ctr.x, vy = mid.y - ctr.y;
    var len = Math.hypot(vx, vy) || 1;
    var szS = mmPx(LABEL_MM.storage, pxmm);
    drawText(g, { x: mid.x + vx / len * szS * 1.15, y: mid.y + vy / len * szS * 1.15 },
             '保管場所', szS, '#111', S);
    g.restore();
  }

  function dimLabel(g, p0, p1, ctr, txt, o, which, S, mpp, pxmm) {
    if (o.labelOverride) {
      if (which === 'w' && o.w_m >= o.h_m) txt = o.labelOverride;
      else if (which === 'h' && o.h_m > o.w_m) txt = o.labelOverride;
    }
    var mx = (p0.x + p1.x) / 2, my = (p0.y + p1.y) / 2;
    var vx = mx - ctr.x, vy = my - ctr.y;
    var len = Math.hypot(vx, vy) || 1;
    var szD = mmPx(LABEL_MM.dim, pxmm);
    var off = szD * 1.08;
    var lx = mx + vx / len * off, ly = my + vy / len * off;
    var ang = Math.atan2(p1.y - p0.y, p1.x - p0.x);
    if (ang > Math.PI / 2 || ang < -Math.PI / 2) ang += Math.PI;
    g.save();
    g.translate(lx, ly);
    g.rotate(ang);
    drawText(g, { x: 0, y: 0 }, txt, szD, '#111', S);
    g.restore();
  }

  function drawStamp(g, o, proj, S, mpp, pxmm) {
    var cw = o.cell_w_m / mpp, ch = o.cell_h_m / mpp;
    var col = (o.direction !== 'row');
    var a = (o.angle || 0) * Math.PI / 180;
    var ca = Math.cos(a), sa = Math.sin(a);
    var c = proj(o.origin.lat, o.origin.lng);
    var skip = o.skip || [];
    var st = (o.stagger_m || 0) / mpp;      // 階段状のずらし（画面と同じ計算）
    var first = null;
    for (var i = 0; i < o.count; i++) {
      if (skip.indexOf(i) >= 0) continue;
      var off = i - (o.count - 1) / 2;
      var lx = col ? off * st : off * cw;
      var ly = col ? off * ch : off * st;
      var pts = [[-cw / 2, -ch / 2], [cw / 2, -ch / 2],
                 [cw / 2, ch / 2], [-cw / 2, ch / 2]].map(function (p) {
        var x = lx + p[0], y = ly + p[1];
        return { x: c.x + x * ca - y * sa, y: c.y + x * sa + y * ca };
      });
      g.beginPath();
      g.moveTo(pts[0].x, pts[0].y);
      for (var k = 1; k < 4; k++) g.lineTo(pts[k].x, pts[k].y);
      g.closePath();
      g.stroke();
      var mid = { x: (pts[0].x + pts[2].x) / 2, y: (pts[0].y + pts[2].y) / 2 };
      if (!first) first = { pts: pts, mid: mid };
      if (o.storage && o.storage[i]) drawStorage(g, pts, mid, S, pxmm);
      var num = o.numbers && o.numbers[i];
      if (num != null) drawText(g, mid, String(num), mmPx(LABEL_MM.number, pxmm), '#111', S);
    }
    /* 1枠の代表寸法。🔒 v4（§16-10-d-4）: 自動では出さず、
     * 画面で［寸法(m)を図に出す］を入れた塊だけ紙にも出す（画面と同じ規則）。 */
    if (first && o.showDims !== false) {
      var p0 = first.pts[0], p1 = first.pts[1];
      var ang = Math.atan2(p1.y - p0.y, p1.x - p0.x);
      if (ang > Math.PI / 2 || ang < -Math.PI / 2) ang += Math.PI;
      g.save();
      g.translate((p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
      g.rotate(ang);
      var szG = mmPx(LABEL_MM.dim, pxmm);
      drawText(g, { x: 0, y: -szG * 0.83 },
               fmtM(o.cell_w_m) + '×' + fmtM(o.cell_h_m), szG, '#111', S);
      g.restore();
    }
  }

  function drawArrow(g, o, proj, S, mpp, pxmm) {
    var a = proj(o.a.lat, o.a.lng), b = proj(o.b.lat, o.b.lng);
    g.beginPath(); g.moveTo(a.x, a.y); g.lineTo(b.x, b.y); g.stroke();
    var L = 9 * S;
    [[a, b], [b, a]].forEach(function (pair) {
      var p = pair[0], q = pair[1];
      var ang = Math.atan2(q.y - p.y, q.x - p.x);
      [-0.5, 0.5].forEach(function (d) {
        var e = ang + d;
        g.beginPath();
        g.moveTo(p.x, p.y);
        g.lineTo(p.x + Math.cos(e) * L, p.y + Math.sin(e) * L);
        g.stroke();
      });
    });
    var mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2;
    /* 🔒 §25-5: 手入力があればそれを優先、無ければ2端点の実距離（小数1桁）。
     * editor.js の Editor.arrowText と**同じ規則**（画面と紙で同じ値を出す）。 */
    var txt = arrowText(o);
    if (txt) {
      var szA = mmPx(LABEL_MM.dim, pxmm);
      drawText(g, { x: mx, y: my - szA * 0.67 }, txt, szA, '#111', S);
    }
  }

  /** 幅矢印に出す文字（§25-5）。editor.js の Editor.arrowText と同じ規則 */
  function arrowText(o) {
    if (o.label) return o.label;
    if (!o.a || !o.b || typeof GSI === 'undefined') return '';
    return fmtM(GSI.distanceMeters(o.a, o.b));
  }

  function fmtM(m) { return (Math.round(m * 10) / 10).toFixed(1) + 'm'; }

  /* ================= 飾り（スケール・出典） ================= */

  /**
   * 🔒 §28-3: 方位記号（北矢印）。**部品として置かれた物だけ**を描く
   * （自動で右上に描く drawNorth は §28-7 で廃止した）。
   * 形の出どころは editor.js の Editor.compassGeom＝画面と紙で同じ点列。
   * 大きさは紙面ミリで一定（Editor.COMPASS.rMm）＝旧 drawNorth の 17S と同じ。
   */
  var COMPASS_FALLBACK = { rMm: 2.346, lw: 2 };
  function compassConf() {
    return (global.Editor && global.Editor.COMPASS) || COMPASS_FALLBACK;
  }
  function drawCompass(g, o, proj, S, pxmm) {
    if (!o.at || !global.Editor || !global.Editor.compassGeom) return;
    var p = proj(o.at.lat, o.at.lng);
    var cg = global.Editor.compassGeom(mmPx(compassConf().rMm, pxmm));
    g.save();
    g.strokeStyle = '#111'; g.fillStyle = '#111';
    g.lineWidth = Math.max(0.6, cg.lw * S);
    g.lineJoin = 'round';
    g.beginPath();
    for (var i = 0; i < cg.pts.length; i++) {
      var x = p.x + cg.pts[i][0], y = p.y + cg.pts[i][1];
      if (i) g.lineTo(x, y); else g.moveTo(x, y);
    }
    g.closePath();
    g.fill();
    drawText(g, { x: p.x, y: p.y + cg.labelY }, 'N', cg.labelSize, '#111', S);
    g.restore();
  }

  /**
   * 🔒 §22-am（2026-09-04）: **紙の付き物が居座る場所**（縮尺バー・出典・通し表示）。
   * 名前の配置（shozaizu.js）がここを避ける。**位置の出どころはこのファイル**
   * （Editor.SIGNAL と同じ作法で、使う側は読むだけ）。
   * 🔴 drawScaleBar / 出典 / pageMark の描画位置を直したら、ここも直すこと。
   * 🔒 §28-3/§28-7: **方位記号の矩形は外した**（自動で描かなくなった＝席を取らない）。
   *    部品として置かれた方位記号は「付き物」ではなく**障害物**として避ける
   *    （shozaizu.js が opts.compasses から箱を作る・§22-av-2 の 4② も同じ）。
   *
   * 単位のからくり: 線幅倍率 S は図の幅の **1/1000**（lineScale の NOMINAL_W）。
   * だから「S 何個ぶん」は幅に対する割合そのもの。縦は aspect（＝幅/高さ）を掛けて
   * 高さに対する割合へ直す。返り値は図を 0〜1 に正規化した矩形（原点＝左上・y は下向き）。
   *
   * @param opts {aspect, noScale, attrLines, pageMark}
   */
  function furnitureZones(opts) {
    opts = opts || {};
    var asp = opts.aspect || 1;          // 図の 幅/高さ
    var u = 1 / NOMINAL_W;               // S 1つ ＝ 図の幅の 1/1000
    var z = [];
    if (!opts.noScale) {
      // drawScaleBar: 左端 22S・棒は最大 0.26W・y0 = H-26S・その上に数字（12S）
      z.push({ x0: 18 * u, x1: 0.29, y0: 1 - 52 * u * asp, y1: 1 });
    }
    var n = (opts.attrLines === undefined) ? 2 : opts.attrLines;
    if (n > 0) {
      // 出典: 右下・右詰め・行送り 13S・最下行のベースラインが H-8S
      z.push({ x0: 0.60, x1: 1, y0: 1 - (20 + 13 * (n - 1)) * u * asp, y1: 1 });
    }
    if (opts.pageMark !== false) {
      // §26-4-e 通し表示（PNG だけ）: 左上 (10S, 8S)・12S・「所在図 1/2」程度
      z.push({ x0: 0, x1: 0.12, y0: 0, y1: 30 * u * asp });
    }
    return z;
  }

  /**
   * 🔒 §28-3: ［枠を決定］で方位記号の部品を置く席（枠の右上）。旧 drawNorth が
   * 自動で描いていた場所と同じ（中心 W-42S・46S）＝見た目が変わらない。
   * 枠を 0〜1 に正規化した位置で返す（原点＝左上・y は下向き）。
   */
  function compassSpot(aspect) {
    var u = 1 / NOMINAL_W;
    return { x: 1 - 42 * u, y: 46 * u * (aspect || 1) };
  }

  function drawScaleBar(g, W, H, S, mpp) {
    var cands = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000];
    var maxPx = W * 0.26, m = cands[0];
    for (var i = 0; i < cands.length; i++) {
      if (cands[i] / mpp <= maxPx) m = cands[i];
    }
    var px = m / mpp;
    var x0 = 22 * S, y0 = H - 26 * S;
    g.save();
    g.strokeStyle = '#111'; g.lineWidth = 2 * S;
    g.beginPath();
    g.moveTo(x0, y0 - 5 * S); g.lineTo(x0, y0 + 5 * S);
    g.moveTo(x0, y0); g.lineTo(x0 + px, y0);
    g.moveTo(x0 + px, y0 - 5 * S); g.lineTo(x0 + px, y0 + 5 * S);
    g.stroke();
    drawText(g, { x: x0 + px / 2, y: y0 - 12 * S },
             m >= 1000 ? (m / 1000) + 'km' : m + 'm', 12 * S, '#111', S);
    g.restore();
  }

  /** 紙面での縮尺 1:N */
  function scaleDenominator(frame_w_m, panelWmm) {
    return Math.round(frame_w_m * 1000 / panelWmm);
  }

  /* ================= 1枚を描く ================= */

  /**
   * 図を1枚描く（＝紙1ページに載る図そのもの。見出し・欄外は buildPDF の仕事）。
   * opts: {objects, frame, orient, attributions:[], dpi, noScale, pageMark}
   *   pageMark（🔒 §26-4-e）: 「所在図 1/2」を**図の中の左上**へ刷る。
   *   PDF は見出し帯に同じ物が入るので渡さない（PNG 提出の事務所のための逃げ道）。
   * 返り値: {canvas, mpp, scaleN, bounds, place(mm), page(mm), orient, sheetWmm}
   *
   * 🔒 §24-3/§25-3: 紙は A4 1枚・図はその作図領域いっぱい。
   * 🔴 文字と線は **紙の実寸(mm)** で決める。canvas の幅で割り算しないこと
   *    （向きで紙幅が違うので、割ると横だけ文字が大きくなる＝§24-4-b 持ち越し2）。
   */
  function renderSheet(opts) {
    var b = frameBounds(opts.frame);
    var dpi = opts.dpi || DPI;
    var asp = frameAspect(opts.frame);
    // 向きは呼び出し側（シートの orient）が本当の答え。無ければ枠の形から推す
    var orient = opts.orient === 'landscape' ? 'landscape'
               : opts.orient === 'portrait' ? 'portrait'
               : (asp >= 1 ? 'landscape' : 'portrait');
    var lay = pageLayout(orient);
    /* 紙のどこに何 mm で刷られるか。枠の比率が作図領域と一致していれば箱いっぱい
     * （＝はみ出しも余白の偏りも無い）。旧データで比率が違う枠だけ中央に収める */
    var place = fitBox(lay.box, asp);
    var pxmm = pxPerMm(dpi);
    var outW = Math.max(32, Math.round(place.w * pxmm));
    var outH = Math.max(32, Math.round(place.h * pxmm));
    var cv = document.createElement('canvas');
    cv.width = outW; cv.height = outH;
    var g = cv.getContext('2d');

    g.fillStyle = '#fff';
    g.fillRect(0, 0, outW, outH);

    var proj = makeProjector(b, outW, outH);
    var mpp = b.w_m / outW;              // 1px あたりの実距離
    var S = lineScale(pxmm);             // 線の太さの倍率（向きに依らない）

    g.save();
    g.beginPath();
    g.rect(0, 0, outW, outH);
    g.clip();
    drawObjects(g, opts.objects || [], proj, S, mpp, pxmm);
    g.restore();

    /* 🔒 §28-3/§28-7（2026-09-06 オーナー指示）: **方位記号の自動描画は廃止**した。
     * 方位記号は［枠を決定］で置かれる**部品**（type:'compass'）で、上の
     * drawObjects が置かれた場所に描く。§18-ag「向きが確かな図にだけ出す」は
     * **部品を置く条件**（所在図だけ・配置図には置かない）として app.js に残る。 */
    /* 🔒 v4（正典 §16-6 ③）: 写真の縮尺が未較正の図では**縮尺バーを出さない**。
     * 嘘の縮尺を紙に載せないため（1:N も呼び出し側で省く）。 */
    if (!opts.noScale) drawScaleBar(g, outW, outH, S, mpp);

    /* 🔒 §26-4-e: 通し表示（所在図 1/2）。PNG は帯を持たないので図の中へ入れる。
     * 置き場所は**左上**＝縮尺バー（左下）・出典（右下）と当たらない。 */
    if (opts.pageMark) {
      g.save();
      g.font = '700 ' + (12 * S).toFixed(1) + 'px "Yu Gothic UI","Meiryo",sans-serif';
      g.textAlign = 'left';
      g.textBaseline = 'top';
      g.lineWidth = 3 * S;
      g.lineJoin = 'round';
      g.strokeStyle = '#fff';                 // 図に重なっても読めるよう白で縁取る
      g.strokeText(opts.pageMark, 10 * S, 8 * S);
      g.fillStyle = '#111';
      g.fillText(opts.pageMark, 10 * S, 8 * S);
      g.restore();
    }

    // 出典表記（正典 §5・§11-b。法務省/地理院とも「加工して作成」が要る）
    var attrs = (opts.attributions || []).slice();
    if (attrs.length) {
      g.save();
      g.font = (10 * S).toFixed(1) + 'px "Yu Gothic UI","Meiryo",sans-serif';
      g.fillStyle = '#333';
      g.textAlign = 'right';
      g.textBaseline = 'bottom';
      attrs.forEach(function (t, i) {
        g.fillText(t, outW - 8 * S, outH - 8 * S - (attrs.length - 1 - i) * 13 * S);
      });
      g.restore();
    }

    return { canvas: cv, mpp: mpp, bounds: b, noScale: !!opts.noScale,
             orient: orient,
             place: place, page: lay.page, sheetWmm: place.w,
             /* 1:N は**実際に紙へ刷られる幅**で出す（作図領域が広がったので
                従来の 138mm 固定のままだと 1.4 倍ずれた数字になる） */
             scaleN: opts.noScale ? null : scaleDenominator(b.w_m, place.w) };
  }

  /* ================= PDF（🔒 §24-3: 1シート＝1ページ） ================= */

  /** 帯（見出し・欄外）を1枚の画像として作る。
   *  🔴 文字は canvas に描いてから貼る＝フォント埋め込みを避ける（正典 §2 全面ラスタ）。 */
  function stripCanvas(wmm, hmm, draw) {
    var cv = document.createElement('canvas');
    cv.width = Math.max(8, Math.round(wmm / 25.4 * DPI));
    cv.height = Math.max(8, Math.round(hmm / 25.4 * DPI));
    var g = cv.getContext('2d');
    g.fillStyle = '#fff';
    g.fillRect(0, 0, cv.width, cv.height);
    draw(g, cv.width, cv.height, cv.height / hmm);   // 最後の引数 ＝ px/mm
    return cv;
  }

  /** ページ番号の表示（🔒 §24-3「所在図 1/3」）。1枚だけでも同じ形で入れる */
  function pageMark(p) {
    return (p.kindJa || '') + ' ' + (p.index || 1) + '/' + (p.total || 1);
  }

  /**
   * 🔒 §24-3 / §25-3: **1シート＝1ページ**の PDF を組む。
   * pages: [{kind, kindJa, index, total, orient, objects, frame,
   *          attributions, noScale}]（所在図の全シート → 配置図の全シート）
   * meta:  {name}（🔴 案件名は紙に刷らない。依頼者の氏名が入るため・§20-7）
   *
   * 🔴 §22 / §24-3 課金カウント: **カウントは案件単位**。ここで何ページ出ても
   *    1案件 ＝ 1件のまま数える。将来 §22-6 のカウントを実装する人は、
   *    **pages.length（枚数）で数えてはいけない**。
   */
  function buildPDF(pages, meta) {
    var ctor = global.jspdf && global.jspdf.jsPDF;
    if (!ctor) throw new Error('PDF ライブラリを読み込めませんでした');
    var list = (pages || []).filter(function (p) { return p && p.frame; });
    if (!list.length) throw new Error('書き出せる図がありません（枠が未設定です）');

    var doc = null;
    list.forEach(function (p) {
      var r = renderSheet({
        objects: p.objects, frame: p.frame, orient: p.orient,
        attributions: p.attributions,       // 🔒 §24-3 出典はシートごと
        noScale: !!p.noScale
      });
      if (!doc) {
        doc = new ctor({ orientation: r.orient, unit: 'mm',
                         format: 'a4', compress: true });
      } else {
        doc.addPage('a4', r.orient);        // 🔒 §24-3: 縦横の混在を許す
      }

      // 見出し帯（左＝表題／右＝通し表示）
      var head = stripCanvas(r.page.w - MARGIN_MM * 2, HEAD_MM,
        function (g, W, H) {
          g.fillStyle = '#111';
          g.font = '700 ' + Math.round(H * 0.52) + 'px "Yu Gothic UI","Meiryo",sans-serif';
          g.textAlign = 'left'; g.textBaseline = 'middle';
          g.fillText('保管場所の' + (p.kindJa || ''), 0, H * 0.58);
          g.font = Math.round(H * 0.42) + 'px "Yu Gothic UI","Meiryo",sans-serif';
          g.textAlign = 'right';
          g.fillText(pageMark(p), W, H * 0.60);
        });
      doc.addImage(head.toDataURL('image/png'), 'PNG',
                   MARGIN_MM, MARGIN_MM, r.page.w - MARGIN_MM * 2, HEAD_MM,
                   undefined, 'FAST');

      // 図（作図領域いっぱい）＋ その外周の枠線
      doc.addImage(r.canvas.toDataURL('image/png'), 'PNG',
                   r.place.x, r.place.y, r.place.w, r.place.h, undefined, 'FAST');
      doc.setDrawColor(17);
      doc.setLineWidth(0.4);
      doc.rect(r.place.x, r.place.y, r.place.w, r.place.h);

      /* 欄外に縮尺の目安（正典 §7）。縮尺を持たない図には**一切載せない**（🔒 §18-ae）。
       * 🔴 「縮尺の設定なし」とも刷らない（配置図は常に縮尺なしなので毎回邪魔になる）。 */
      if (r.scaleN) {
        var foot = stripCanvas(r.page.w - MARGIN_MM * 2, FOOT_MM - 2,
          function (g, W, H) {
            g.fillStyle = '#444';
            g.font = Math.round(H * 0.62) + 'px "Yu Gothic UI","Meiryo",sans-serif';
            g.textAlign = 'right'; g.textBaseline = 'middle';
            g.fillText('縮尺の目安  1:' + r.scaleN.toLocaleString(), W, H * 0.55);
          });
        doc.addImage(foot.toDataURL('image/png'), 'PNG',
                     MARGIN_MM, r.page.h - MARGIN_MM - (FOOT_MM - 2),
                     r.page.w - MARGIN_MM * 2, FOOT_MM - 2, undefined, 'FAST');
      }
    });
    return doc;
  }

  /* ================= 書き出し範囲枠 ================= */

  /** 図形が収まる枠を作る（正典 §4-10 既定は描画物にフィット）。
   *  aspect を渡すとその向き（A4縦/横・§25-3）で収める */
  function fitFrame(objects, fallbackCenter, aspect) {
    var asp = frameAspect({ aspect: aspect });
    var pts = [];
    (objects || []).forEach(function (o) {
      if (o.center) pts.push(o.center);
      if (o.origin) pts.push(o.origin);
      if (o.at) pts.push(o.at);
      if (o.arrowTo) pts.push(o.arrowTo);      // 塊ラベルの矢印の先（§18-f 駐車位置ラベル）
      if (o.a) pts.push(o.a);
      if (o.b) pts.push(o.b);
      if (o.points) o.points.forEach(function (p) { pts.push(p); });
    });
    if (!pts.length) {
      return fallbackCenter
        ? { center: { lat: fallbackCenter.lat, lng: fallbackCenter.lng },
            w_m: 120, aspect: asp }
        : null;
    }
    var w = Infinity, e = -Infinity, s = Infinity, n = -Infinity;
    pts.forEach(function (p) {
      if (p.lng < w) w = p.lng;
      if (p.lng > e) e = p.lng;
      if (p.lat < s) s = p.lat;
      if (p.lat > n) n = p.lat;
    });
    var center = { lat: (s + n) / 2, lng: (w + e) / 2 };
    /* 🔴 縦横比の判定は**投影した長さ**で行う（§24-4-b 持ち越し3 と同じ理由）。
     * 緯度差×110540 で高さを測ると 0.7% ずれ、frameBounds と別の答えになる。 */
    var K = metersPerUnit(center.lat);
    var wM = (e - w) / 360 * K;
    var hM = (mercY(s) - mercY(n)) * K;
    // 縦横比を合わせて、はみ出さない方を採る
    var need = Math.max(wM, hM * asp) * 1.12;
    return { center: center, w_m: Math.max(20, need), aspect: asp };
  }

  function boundsOf(frame) { return frameBounds(frame); }

  global.Exporter = {
    PANEL_MM: PANEL_MM, ASPECT: ASPECT, DPI: DPI,
    frameAspect: frameAspect,                    // 枠の縦横比（§25-3 A4縦/横）
    orientAspect: orientAspect,                  // 🔒 A4の向き → 枠＝紙面の比率
    pageLayout: pageLayout,                      // 紙と作図領域（mm）
    placeOnPage: placeOnPage,                    // 図が刷られる mm 矩形
    SHEET_SCALE: SHEET_SCALE,
    textEmWidth: textEmWidth,
    /* 🔒 §22-am: 紙の付き物（縮尺バー・出典・通し表示）が居座る場所。
     * shozaizu.js の名前の配置が読む（位置の出どころはこのファイル1か所）。
     * 🔒 §28-7: 方位記号は部品になったのでここには**含まない**。 */
    furnitureZones: furnitureZones,
    // 🔒 §28-3: ［枠を決定］で方位記号を置く席（枠の右上・app.js が読む）
    compassSpot: compassSpot,
    renderSheet: renderSheet,
    pageMark: pageMark,                          // 🔒 §26-4-e: PNG にも通し表示
    buildPDF: buildPDF,
    fitFrame: fitFrame,
    frameBounds: boundsOf,
    scaleDenominator: scaleDenominator
  };
})(typeof window !== 'undefined' ? window : this);
