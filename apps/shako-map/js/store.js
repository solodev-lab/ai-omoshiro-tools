/* store.js — 案件データと保存（正典 §8 / §27-12 案件フォルダ1本化）
 *
 * 車庫証明 所在図・配置図メーカー
 * 🔒 §27-12: 案件の本体は**案件フォルダの中の .shako（1件1ファイル）だけ**。
 *    localStorage に案件は置かない（残すのは KEY_LAST / KEY_SEQ のような小さな設定だけ）。
 *    🔴 §27-12-9: 旧 localStorage 案件は**移さない・起動時に黙って消す**（オーナー決定）。
 * 🔴 データは利用者のパソコンの中だけで完結する。
 *    依頼者の住所情報をサーバーへ送る処理は作らない（正典 §1-6）。
 */
(function (global) {
  'use strict';

  var SCHEMA = 1;
  /* 🔒 §27-12-1 ⑥: 案件データは localStorage に置かない。
     🔴 §27-12-9: 旧形式のキー（索引と案件本体）は**読まない・移さない**。
        起動時に purgeOldKeys() が黙って消すためだけに名前を持つ。 */
  var OLD_KEY_INDEX = 'shakomap.index';   // 旧: 案件idの配列
  var OLD_KEY_CASE = 'shakomap.case.';    // 旧: + id
  var KEY_LAST = 'shakomap.last';         // 最後に開いた案件id（残す小さな設定）
  /* 案件番号の採番カウンタ {年: 最後に使った番号}（正典 §19-1 が名前で指定）。
     🔴 他のキーと接頭辞が違うが、正典の指定どおりにする */
  /* 🔴 §19-1 の正典は当初 'shako.caseSeq' と書いたが、他のキー（shakomap.*）と
   * 接頭辞を揃えるため 'shakomap.caseSeq' へ統一した
   * （正典 §19-1 も追記済み・2026-08-22）。 */
  var KEY_SEQ = 'shakomap.caseSeq';

  /* 🔒 §29 Step 6（2026-09-07）: ガイダンスの段の**番号の版**。
   * 🔴 ⑤に「下敷きと枠」を新設したので、旧⑤〜⑪は⑥〜⑫へ1つ後ろへずれた。
   *    保存済みの案件は旧番号（版なし）なので、migrate が 5 以上を +1 して
   *    この版を書く＝2度目からは読み替えない印になる。
   * 🔴 これから段を増やす／並べ替える時も、番号を動かすなら必ず版を上げること。
   *
   * 🔒 §30-1（2026-09-08 オーナー承認）: ガイダンスの入口が**図ごとに2つ**になり、
   *    段の番号も図ごとに①から振り直した（所在図①〜④／配置図①〜⑧）。
   *    保存する形も1つの通し番号（navStep）から **nav: {shozaizu, haichizu}** へ変えた
   *    ので版を 2 → **3** に上げる。読み替えは migrate が1か所で行う:
   *      版なし（旧11段）→ 5以上を +1 して12段へ → 図ごとへ分解
   *      版2（12段の通し番号）→ 1〜4 は shozaizu / 5〜12 は haichizu の n−4
   *    🔴 読み替えた後、旧フィールド `navStep` は消す（同じ意味の値を2か所に置かない）。 */
  var NAV_STEP_VER = 3;
  var NAV_STEPS = 12;                     // 段の総数（app.js の NAV.length と一致）
  /* 図ごとの段の数（🔒 §30-1）。app.js の NAV の並び（①〜④＝所在図／⑤〜⑫＝配置図）と
   * 対応する。範囲外の値は読み込みで捨てる（落とさない）。 */
  var NAV_FIG_LAST = { shozaizu: 4, haichizu: 8 };

  /** 通し番号（1〜12）→ 図ごとの段 {shozaizu|haichizu: n}（🔒 §30-1） */
  function navFromStep(ns) {
    if (!(ns >= 1 && ns <= NAV_STEPS)) return null;
    return (ns <= NAV_FIG_LAST.shozaizu)
      ? { shozaizu: ns }
      : { haichizu: ns - NAV_FIG_LAST.shozaizu };
  }

  /** 図ごとの段の値を検算する（範囲外・数値でない物は捨てる・🔒 §30-1） */
  function normalizeNav(nv) {
    if (!nv || typeof nv !== 'object') return null;
    var out = {};
    Object.keys(NAV_FIG_LAST).forEach(function (k) {
      var v = Math.round(Number(nv[k]));
      if (v >= 1 && v <= NAV_FIG_LAST[k]) out[k] = v;
    });
    return (out.shozaizu || out.haichizu) ? out : null;
  }

  /* 🔒 2026-09-03: 名称の自動描画6分類（§23-5）の案件フィールド名。
   * 🔴 newCase と migrate の**両方が同じ表を読む**＝片方に足し忘れる事故を防ぐ。
   *    並びは画面（設定盤）の並びと同じ。app.js の SZ_GRADES とも対応する。 */
  var NAME_LEVEL_KEYS = ['nameCrossLevel', 'nameShopLevel', 'nameOfficeLevel',
                         'nameBusLevel', 'nameRoadLevel', 'namePoiLevel'];

  /* 🔒 §22-ao-②（2026-09-04 オーナー指示）: 所在図の設定盤・標準値の定義を1か所に統合。
   * 🔴 以前は newCase の既定・migrate の欠損補完・app.js の SZ_STD の3か所に
   *    同じ値がバラバラに書かれていた。ここが**唯一の出どころ**で、他の2か所は
   *    これを読むだけにする（app.js は Store.SZ_STD をそのまま指す）。
   * 値は §22-ao の表のとおり（主役の印＝◎／建物なし／お店・会社名は主役の周りだけ／
   * 道路名は多め／他の目印はなし／残りは標準）。 */
  /* 🔒 §28-14 ①-4（2026-09-07）: **markStyle はこの表から外した**。
   * 主役の印の形（と色）はガイダンス①で地点ごとに選ぶ物になり
   * （points[key].mark = {shape,color}）、所在図の設定盤の項目ではなくなったため。
   * ［標準に戻す］（runShozaizuStandard）が印の形を勝手に戻さないのも、これで正しい。
   * 🔴 c.markStyle 自体は**旧案件の後方互換のために残す**（下の MARK_STYLE_STD）。 */
  var SZ_STD = {
    nature: true, roadStyle: 'line',
    lmLevel: 3, bldgLevel: 1, roadLevel: 3,
    nameCrossLevel: 3, nameShopLevel: 2, nameOfficeLevel: 2,
    nameBusLevel: 3, nameRoadLevel: 4, namePoiLevel: 1
  };
  /* 印の形の既定（🔒 §22-ao ＝◎）。points[key].mark を持たない案件は今もこれで描く。 */
  var MARK_STYLE_STD = 'circle';

  /* 図の種類（＝所在図か配置図か）。🔴 シート（＝紙1枚）とは別の概念。
     §24-1 で「案件 ＝ 共通情報 ＋ 所在図シート×N ＋ 配置図シート×N」になったので、
     この2語を混ぜないこと（kind=種類 / sheet=紙1枚）。 */
  var KINDS = ['shozaizu', 'haichizu'];

  /* ---------- 既定値 ---------- */

  /**
   * 図の種類ごとの「下敷き設定」（🔒 §24-1: 下敷き設定は**案件レベルで共有**する）。
   * 🔴 §24-1 のシート制で、**位置（center/zoom）・枠（frame）・図形（objects）は
   *    ここに置かない**。それらはシート1枚ずつが独立して持つ（c.sheets[kind][i]）。
   *    旧案件の maps.*.center/zoom/frame は migrate がシートへ吸い上げてから消す。
   */
  function defaultMap(kind) {
    return {
      /* 下敷きの選択肢 id（app.js の UNDERLAYS）。旧 'satellite'/'roadmap' も読める。
       * §17（2026-08-18）で Google を撤去したので既定はオープンデータ側。
       * 🔒 §28-13 決定1（2026-09-07 オーナー指示「初期表示の地図は Google か
       *    OpenStreetMap にしたい」）: **所在図の既定を 'gsi-pale' → 'osmfj' に**。
       *    店・施設の名前と路線番号が見えている方が、所在図の描き足し（§28-5）に効く。
       * 🔴 ここは**新しく作る案件**にしか効かない。既存案件は保存値のまま開く
       *    （migrate は underlay を書き替えない・§17-b の作法）。
       * 🔒 §30-7 A（2026-09-08 オーナー指示）: **配置図の既定を 'plateau' → 'gsi-photo' に**。
       *    PLATEAU は名古屋市内のみ（対象都市限定・§11-b）で範囲外だと写真が出ない。
       *    地理院 写真（全国・場所ごとに最新）なら PLATEAU と同じか新しい撮影で外れが無い。 */
      underlay: kind === 'haichizu' ? 'gsi-photo' : 'osmfj',
      underlayOpacity: 1
    };
  }

  // 配置図は駐車枠をなぞる作業なので最初から寄せる（ZL21 で 2.5m ≒ 41px）
  function defaultZoom(kind) { return kind === 'haichizu' ? 21 : 16; }

  function newSheetId() {
    return 's' + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  }

  /**
   * シート1枚 ＝ 提出する紙1枚（🔒 §24-1）。所在図・配置図とも複数枚持てる。
   * 🔴 シートは**完全に独立**させる（オーナーの洞察・§24-1）:
   *    高いZLで描き込んだ細部が低いZLの図に残ると「必要以上に細かい図」になるため、
   *    共有キャンバス＋枠だけ複数、という案は採らない。
   * 各シートが独立に持つ物は §24-1 のとおり3つ:
   *    ①A4の向き（orient）②枠（frame＝どこをどの縮尺で切り取るか）③図形（objects）
   *    ＋ 実装上の付帯として「そのシートを編集していた時の地図の位置」（center/zoom）。
   */
  function newSheet(kind, init) {
    init = init || {};
    return {
      id: newSheetId(),
      // ①A4の向き。枠の縦横比がこれで決まる（🔒 §25-3「枠を設定した時に向きが決まる」）
      orient: init.orient === 'landscape' ? 'landscape' : 'portrait',
      // 地図の表示位置（シートを開き直した時にその場所へ戻すため）
      center: init.center ? { lat: init.center.lat, lng: init.center.lng } : null,
      zoom: (typeof init.zoom === 'number' && isFinite(init.zoom))
            ? init.zoom : defaultZoom(kind),
      // ②枠 {center:{lat,lng}, w_m, aspect}
      frame: init.frame || null,
      /* 枠を「決定」したか（🔒 §24-2-3）。
         false ＝ 従来どおり画面に追従（§9-i「見えている枠の中が出る」）。
         true  ＝ 枠は地図に固定され、以後は地図だけを自由に動かせる。
         これで「地図を動かす」と「枠を動かす」の両方が簡単にできる。 */
      frameFixed: !!init.frameFixed,
      // ③図形（このシート固有）
      objects: Array.isArray(init.objects) ? init.objects : [],
      /* 出典表記（🔒 §24-3「シートごとに、そのシートで使ったデータ源だけ」）。
         🔴 案件レベルに1つだけ持っていると、地理院データを使っていない配置図の紙にも
            「出典：国土地理院…」が刷られてしまう。紙ごとに持つのが正しい。 */
      attributions: Array.isArray(init.attributions) ? init.attributions.slice() : []
    };
  }

  /** 欠けた項目を寛容に補う（読み込み用）。🔴 配列の同一性は保つ（その場で直す） */
  function normalizeSheet(kind, s) {
    if (!s || typeof s !== 'object') return newSheet(kind);
    if (!s.id) s.id = newSheetId();
    if (s.orient !== 'landscape') s.orient = 'portrait';
    if (typeof s.zoom !== 'number' || !isFinite(s.zoom)) s.zoom = defaultZoom(kind);
    if (!s.center || typeof s.center.lat !== 'number') s.center = null;
    if (!s.frame || !s.frame.center || !s.frame.w_m) s.frame = null;
    /* 🔒 §25-3/§24-3（Step 6）: 枠は A4 の向きの比率（aspect）を必ず持つ。
     * 旧データ（Step 5 より前）は aspect が無く、当時の記載欄の形 138:160 で
     * 切られていた。そのまま残すと「画面の枠＝A4の形／紙の枠＝記載欄の形」の
     * 二重になり、紙に白い帯が出る。→ 読み込み時にその紙の向きの比率を入れる。
     * 🔴 幅(w_m)は触らないので、**横に写っていた物は1つも欠けない**
     *    （縦がわずかに広がるだけ＝足す方向にしか動かない）。 */
    if (s.frame) {
      var a = Number(s.frame.aspect);
      if (!(isFinite(a) && a > 0.05 && a < 20)) {
        s.frame.aspect = (global.Exporter && global.Exporter.orientAspect)
          ? global.Exporter.orientAspect(s.orient) : 138 / 160;
      }
    }
    s.frameFixed = !!s.frameFixed && !!s.frame;   // 枠が無いのに固定は有り得ない
    if (!Array.isArray(s.attributions)) s.attributions = [];   // 出典（§24-3）
    if (!Array.isArray(s.objects)) s.objects = [];
    /* 🔴 null など「オブジェクトでない要素」だけ落とす。描画側（editor.js /
     * export.js）は図形が必ずオブジェクトである前提で書かれており、1個でも
     * null が混ざるとその案件が**開けなくなる**（実測で確認）。
     * 🔴 type が無いだけの物は落とさない（描画側が黙って読み飛ばすので害が無く、
     *    「旧データを失わない」§24-4 の方を優先する）。 */
    for (var i = s.objects.length - 1; i >= 0; i--) {
      var o = s.objects[i];
      if (!o || typeof o !== 'object') s.objects.splice(i, 1);
    }
    return s;
  }

  /* 新規案件の最初の地図（正典 §18-1）。名古屋城・ZL8。
     🔴 defaultMap ではなく newCase だけに入れる。defaultMap は古い案件の
        欠けた項目を補う時にも使うので、そちらに入れると既存案件の表示が飛ぶ。 */
  var FIRST_VIEW = { lat: 35.1856, lng: 136.8998 };
  var FIRST_ZOOM = 8;

  /** 案件id だけを作る。🔴 newCase は番号を1つ消費するので、複製・取り込みの
      「id を新しくするだけ」の用途は必ずこちらを使う（正典 §19-1） */
  function newId() {
    return 'c' + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  }

  function newCase(name) {
    var now = new Date().toISOString();
    var maps = { shozaizu: defaultMap('shozaizu'), haichizu: defaultMap('haichizu') };
    var c = {
      v: SCHEMA,
      id: newId(),
      caseNo: nextCaseNo(),                // 案件番号 YYYY-NNN（正典 §19-1）
      name: name || '無題の案件',
      created: now,
      updated: now,
      done: false,                         // 完了ステータス（正典 §19-3・既定＝作成中）
      points: { home: null, lot: null },   // {lat,lng,label,address,title}
      maps: maps,                          // 下敷き設定（種類ごと・案件レベルで共有）
      /* 🔒 §24-1 シート制。新規案件は「所在図1枚＋配置図1枚」から始める */
      sheets: {
        shozaizu: [newSheet('shozaizu',
          { center: { lat: FIRST_VIEW.lat, lng: FIRST_VIEW.lng }, zoom: FIRST_ZOOM })],
        haichizu: [newSheet('haichizu')]
      },
      active: { shozaizu: 0, haichizu: 0 },  // 種類ごとの「いま開いているシート」
      numberCounter: 1
    };
    /* ===== 所在図の設定盤（🔒 2026-09-03 オーナー指示・§5/§18-r/§23-9/§23-10）=====
       川・山(nature) / 道路の描き方(roadStyle) / 目標物(lmLevel) /
       建物(bldgLevel) / 道路(roadLevel) / 名称6分類(NAME_LEVEL_KEYS)。
       🔒 §28-14 ①-4: 主役の印(markStyle) はガイダンス①へ移したのでこの表には無い
       （migrate が旧案件のために既定を補うだけ）。
       🔒 **新規案件は全項目「標準」で始める**＝値は Store.SZ_STD をコピーするだけ
       （§22-ao-②: 標準値の定義は SZ_STD の1か所に統合。ここに個別の数値は書かない）。
       🔴 既存案件は保存値を尊重する（migrate は欠けている物だけ SZ_STD で補う）。
          開いただけで勝手に「標準」へ書き換えてはいけない。 */
    Object.keys(SZ_STD).forEach(function (k) { c[k] = SZ_STD[k]; });
    return c;
  }

  /* ---------- 案件番号（年-連番・正典 §19-1） ---------- */

  function padNo(n) { return String(n).padStart(3, '0'); }  // 1000 件超は自然に4桁

  /** 一覧に居る同じ年の連番の最大。手で書き換えた番号は YYYY-NNN 形式の物だけ見る。
      🔴 §27-3: 見る先は「今の保存先」の一覧（フォルダ運用ならフォルダの索引）。 */
  function maxCaseNoOfYear(year) {
    var mx = 0;
    list().forEach(function (it) {
      var m = it.caseNo && /^(\d{4})-(\d+)$/.exec(String(it.caseNo));
      if (!m || Number(m[1]) !== year) return;
      var n = Number(m[2]);
      if (n > mx) mx = n;
    });
    return mx;
  }

  /**
   * 次の案件番号を1つ払い出す（カウンタも進める）。年は作成日のローカル年。
   * 🔴 次番号 = max(保存カウンタ, 一覧に居る同年の最大) + 1。
   *    カウンタだけだと JSON 取り込みで大きい番号が来た時に衝突し、一覧の最大だけだと
   *    「最新を削除→次の新規が同じ番号を使い回す」事故が起きる。
   *    台帳は欠番を許し・番号は使い回さない（正典 §19-1）。
   */
  function nextCaseNo() {
    var year = new Date().getFullYear();
    var seq = readJSON(KEY_SEQ, {}) || {};
    var saved = Number(seq[year]) || 0;
    var used = maxCaseNoOfYear(year);
    var n = (saved > used ? saved : used) + 1;
    seq[year] = n;
    writeJSON(KEY_SEQ, seq);              // 書けなくても番号は返す（作図は止めない）
    return year + '-' + padNo(n);
  }

  /* ---------- localStorage ---------- */

  function readJSON(key, fallback) {
    try {
      var s = localStorage.getItem(key);
      return s ? JSON.parse(s) : fallback;
    } catch (e) { return fallback; }
  }

  function writeJSON(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
      return true;
    } catch (e) {
      // 容量超過。自動削除はしない（正典 §8）。呼び出し側へ知らせる。
      return false;
    }
  }

  /** 検索用の住所文字列（自宅・駐車場の address＝入力住所 と title＝正規化住所・§19-2） */
  function addrText(points) {
    var out = [];
    ['home', 'lot'].forEach(function (k) {
      var p = points && points[k];
      if (!p) return;
      if (p.address) out.push(p.address);
      if (p.title) out.push(p.title);
    });
    return out.join(' ');
  }

  /**
   * 一覧に出す図形の総数。🔴 list() は migrate を通していない**生の JSON**を見るので、
   * 旧形式（objects.shozaizu）とシート形式（sheets.shozaizu[].objects）の両方を数える。
   */
  function countObjects(c) {
    var n = 0;
    KINDS.forEach(function (k) {
      var arr = c.sheets && c.sheets[k];
      if (Array.isArray(arr)) {
        arr.forEach(function (s) { n += (s && s.objects && s.objects.length) || 0; });
      } else if (c.objects && Array.isArray(c.objects[k])) {
        n += c.objects[k].length;          // 旧形式（まだ一度も開いていない案件）
      }
    });
    return n;
  }

  /** 案件1件から一覧行の要約を作る（localStorage・フォルダの両方で共用・§27-7） */
  function summarize(c) {
    return {
      id: c.id, name: c.name, created: c.created, updated: c.updated,
      caseNo: c.caseNo || '',            // 案件番号（無ければ空欄・§19-1）
      done: !!c.done,                    // 完了ステータス（§19-3）
      addrText: addrText(c.points),      // 絞り込みの当たり先（§19-2）
      hasHome: !!(c.points && c.points.home),
      hasLot: !!(c.points && c.points.lot),
      objectCount: countObjects(c)
    };
  }

  function byUpdatedDesc(a, b) {
    return (b.updated || '').localeCompare(a.updated || '');
  }

  /* 🔴 §27-12-9: 旧形式（localStorage に案件本体を置いていた頃）のキーを**黙って消す**。
   * 移さない・数えない・何も表示しない（オーナー決定「過去のデータはもう忘れて。全部消してよい」）。
   * 案件を localStorage へ読み書きする関数はもう無い。読み込み時に1回だけ走る。 */
  function purgeOldKeys() {
    try {
      var doomed = [];
      for (var i = 0; i < localStorage.length; i++) {
        var k = localStorage.key(i);
        if (k === OLD_KEY_INDEX || (k && k.indexOf(OLD_KEY_CASE) === 0)) doomed.push(k);
      }
      doomed.forEach(function (k) { localStorage.removeItem(k); });
    } catch (e) { /* 消せなくても害は無い（読まないので） */ }
  }
  purgeOldKeys();

  /* 「最後に開いた案件」（KEY_LAST）は §27-12-1 ⑥ で残す小さな設定。
     🔴 満杯でも投げないように包む（覚えられないだけで作図は止めない） */
  function rememberLast(id) {
    try { localStorage.setItem(KEY_LAST, id); } catch (e) { /* 覚えられないだけ */ }
  }
  function forgetLast(id) {
    try {
      if (localStorage.getItem(KEY_LAST) === id) localStorage.removeItem(KEY_LAST);
    } catch (e) { /* 何もしない */ }
  }

  function lastOpenedId() { return localStorage.getItem(KEY_LAST); }

  /* ================= 案件フォルダ＝案件の本体（🔒 §27 / §27-12） =================
   *
   * 🔒 §27-2 A案: **案件の本体は .shako ファイル**、localStorage は索引と設定だけ。
   * 🔒 §27-12: 保存形態はこれ**1本だけ**（localStorage 運用は廃止）。索引が無い間は
   *    一覧も保存も動かない（app.js がゲートを出して案件フォルダを開かせる）。
   * 🔴 §27-7 の要点（波及を最小にする形）:
   *   ① 一覧は「索引」だけをメモリに持つ ＝ list() は**同期のまま**（波及なし）
   *   ② 非同期になるのは「案件を開く時（loadAsync）」と「一覧を作る時（refreshIndex）」だけ
   *   ③ autosave / flush は fire-and-forget のまま。書き込み先が変わるだけ
   *   ④ 開いている案件の本体はメモリ（app.js の state.current）。編集中に読み直さない
   */

  /* 索引（メモリ）。null ＝ まだ作っていない（＝ 案件フォルダが開かれていない）。
     entry: {sum:<summarize の戻り>, file:<フォルダ内のファイル名>} */
  var fidx = null;          // [entry]
  var fbyId = null;         // id → entry
  var lastError = '';       // 直近の保存失敗の理由（app.js が文言に使う）

  /** 案件フォルダが開いているか（＝索引がある） */
  function folderMode() { return !!fidx; }

  function noop() {}

  /** 索引を捨てる（権限切れ・読み直しの失敗）。以後は一覧も保存も動かない */
  function dropIndex() { fidx = null; fbyId = null; }

  function indexOfCase(id) { return (fbyId && fbyId[id]) || null; }

  /**
   * 案件ファイル名（🔒 §27-8）。`<番号>_<案件名>.shako`。
   * 使えない文字の扱いは書き出し名（filePrefix / safeName・§19-1）と同じ規則。
   * 🔴 同じ番号＋同じ名前の別案件があると**上書きで片方が消える**ので、
   *    索引に「別の id が既に使っている」名前を見つけたら ` (2)` を足して避ける。
   */
  function caseFileName(c) {
    var base = filePrefix(c) + safeName(c.name);
    var name = base + '.shako';
    var used = function (n) {
      if (!fidx) return false;
      for (var i = 0; i < fidx.length; i++) {
        if (fidx[i].file === n && fidx[i].sum.id !== c.id) return true;
      }
      return false;
    };
    for (var k = 2; used(name) && k < 1000; k++) name = base + ' (' + k + ').shako';
    return name;
  }

  /** 索引の1件を作り直す（書き込みのたびに呼ぶ・§27-7①） */
  function upsertIndex(c, file) {
    if (!fidx) return;
    var e = fbyId[c.id];
    if (!e) { e = { sum: null, file: file }; fidx.push(e); fbyId[c.id] = e; }
    e.sum = summarize(c);
    e.file = file;
  }

  function dropFromIndex(id) {
    if (!fidx) return;
    var e = fbyId[id];
    if (!e) return;
    delete fbyId[id];
    var i = fidx.indexOf(e);
    if (i >= 0) fidx.splice(i, 1);
  }

  /**
   * フォルダの .shako を全部読んで索引を作り直す（§27-7①）。
   * 🔴 自動監視はしない。［再読み込み］か、フォルダを選び直した時だけ走る。
   * 🔴 壊れたファイル1個で一覧が真っ白にならないよう、読めない物は飛ばす。
   */
  function refreshIndex() {
    if (!global.FSave || !global.FSave.supported()) {
      dropIndex();
      return Promise.resolve(false);
    }
    return global.FSave.listCases().then(function (files) {
      var list2 = [], byId = Object.create(null);
      var i = 0;
      function step() {
        if (i >= files.length) {
          fidx = list2; fbyId = byId;
          return true;
        }
        var f = files[i++];
        return global.FSave.readCase(f.name).then(function (text) {
          var c = JSON.parse(text);
          if (!c || typeof c !== 'object' || !c.points
              || !(c.objects || c.sheets)) throw new Error('形式が違います');
          if (!c.id) c.id = newId();
          /* 🔴 同じ id のファイルが2つある（利用者がエクスプローラで複製した等）。
           * 後から見つかった方に**索引の中だけで**新しい id を与えて、両方とも
           * 開けるようにする。ファイルはこの時点では書き換えない（開いて保存した
           * 時に初めて新 id で書かれる＝取り込み fromFile と同じ考え方・§19-1）。 */
          if (byId[c.id]) c.id = newId();
          var e = { sum: summarize(c), file: f.name };
          list2.push(e); byId[c.id] = e;
        }, noop).then(step, function () { return step(); });
      }
      return Promise.resolve().then(step);
    }).then(null, function (e) {
      /* 🔒 §27-12: フォルダの中身を読めない（消された・権限が切れた・USB を抜かれた）＝
       * **索引を持たない**。古い一覧を出したままにせず、TOP をゲートへ戻して
       * ［開く］や［別のフォルダを開く］で正しい状態から入り直せるようにする。 */
      dropIndex();
      throw e;
    });
  }

  /**
   * TOP ページの状態を返す（🔒 §27-12-2 の表）。起動時と、画面を引き直すたびに呼ぶ。
   * @returns Promise<'none'|'locked'|'open'>
   *   'none'   … 案件フォルダをまだ選んでいない（＝①のゲート）
   *   'locked' … 覚えてはいるが権限が granted でない（＝②のゲート・［開く］が要る）
   *   'open'   … 索引を作れた（＝③の本体）
   * 🔴 権限をここで**要求はしない**（ユーザー操作の中でしか通らない・§21-2/§27-4）。
   * 🔴 すでに索引がある時は作り直さない（毎回フォルダを全部読み直さないため）。
   *    フォルダの中身を取り込み直すのは［再読み込み］＝ refreshIndex()。
   */
  function folderState() {
    if (!global.FSave || !global.FSave.supported()) {
      dropIndex();
      return Promise.resolve('none');
    }
    if (folderMode()) return Promise.resolve('open');
    return global.FSave.permissionState().then(function (st) {
      if (st === 'none') { dropIndex(); return 'none'; }
      if (st !== 'granted') { dropIndex(); return 'locked'; }
      return refreshIndex().then(function () { return 'open'; },
                                 function () { dropIndex(); return 'locked'; });
    }, function () { dropIndex(); return 'none'; });
  }

  /**
   * 案件フォルダを開く（🔒 §27-12-6）。フォルダを選んだ／［開く］を押した直後に呼ぶ。
   * 索引を作るだけ（🔴 §27-12-9: 旧データの引っ越しは無い）。
   * @returns Promise<void>（失敗は reject・索引は捨てる）
   */
  function openFolder() {
    return refreshIndex().then(noop, function (e) {
      dropIndex();
      throw e;
    });
  }

  /* 書き込みは1本の鎖に並べる（🔴 自動保存と改名が重なると
     「新名で書く前に旧名を消す」順が崩れて案件が消え得る・§27-8） */
  var chain = Promise.resolve();
  function enqueue(fn) {
    var p = chain.then(fn, fn);
    chain = p.then(noop, noop);
    return p;
  }

  function saveToFolder(c) {
    return enqueue(function () {
      var e = indexOfCase(c.id);
      var oldFile = e ? e.file : null;
      var file = caseFileName(c);
      var text = JSON.stringify(c, null, 1);
      return global.FSave.writeCase(file, text).then(function () {
        /* 🔴 順序は「新名で書く → 旧名を消す」。逆にすると失敗した時に案件が消える */
        if (oldFile && oldFile !== file) {
          return global.FSave.deleteCase(oldFile).then(noop, noop);
        }
      }).then(function () {
        upsertIndex(c, file);
        rememberLast(c.id);       // 小さな設定だけは localStorage に残す（§27-12-1 ⑥）
        lastError = '';
        return true;
      }, function (err) {
        lastError = MSG_FOLDER_FAIL + '（' + ((err && err.message) || err) + '）';
        return false;
      });
    });
  }

  /* ---------- 案件の入口（呼ぶ側はここだけ見る） ---------- */

  /** 一覧（🔴 同期のまま・§27-7①）＝ メモリの索引。フォルダ未開なら空配列（§27-12-6） */
  function list() {
    if (!folderMode()) return [];
    return fidx.map(function (e) { return e.sum; }).sort(byUpdatedDesc);
  }

  /** 案件を1件読む（🔴 ここだけ非同期・§27-7②）。無ければ null で解決 */
  function loadAsync(id) {
    if (!folderMode()) return Promise.resolve(null);
    var e = indexOfCase(id);
    if (!e) return Promise.resolve(null);
    return global.FSave.readCase(e.file).then(function (text) {
      var c = migrate(JSON.parse(text));
      if (!c) return null;
      /* 🔴 索引側の id を正とする（同じ id のファイルが2つあった時に
       *    refreshIndex が振り直しているため・上の注記参照）。 */
      c.id = id;
      return c;
    });
  }

  /**
   * 保存（🔴 常に Promise<boolean> を返す・§27-7③）。
   * 失敗しても例外は投げない。理由は lastSaveError() で取れる。
   */
  function save(c) {
    if (!c || !c.id) return Promise.resolve(false);
    /* 🔒 §27-12-6: 保存先は案件フォルダだけ。開かれていなければ握り潰さず false。
     * （③以外では保存の呼び出し自体が起きないはずだが、無言で捨てない） */
    if (!folderMode()) {
      lastError = MSG_NO_FOLDER;
      return Promise.resolve(false);
    }
    c.updated = new Date().toISOString();
    return saveToFolder(c);
  }

  /** 削除（案件フォルダのファイルも消える）。@returns Promise<boolean> */
  function remove(id) {
    if (!folderMode()) {
      lastError = MSG_NO_FOLDER;
      return Promise.resolve(false);
    }
    /* 🔴 ファイル名は書き込みの鎖の中で確定させる（改名の途中で消すと
     *    「消えたはずの旧名が残り、新名が消える」ことになる・§27-8） */
    return enqueue(function () {
      var e = indexOfCase(id);
      if (!e) return true;
      return global.FSave.deleteCase(e.file).then(function () {
        dropFromIndex(id);
        forgetLast(id);
        return true;
      }, function (err) {
        lastError = MSG_FOLDER_FAIL + '（' + ((err && err.message) || err) + '）';
        return false;
      });
    });
  }

  /* 🔒 §27-5-a の積み残しをここで直す。duplicate / rename / setDone は
   * save() の失敗を握り潰していた（満杯だと「複製したのに増えない」等が無言で起きる）。
   * 🔴 保存先がファイルになって save() が非同期になったので、3つとも
   *    **Promise を返し、失敗は reject する**。呼ぶ側（案件一覧の行のボタン）は
   *    .then(renderCaseList, 失敗を知らせる) と書くだけでよい。 */

  function saved(c) {
    return save(c).then(function (ok) {
      if (!ok) throw new Error(lastSaveError());
      return c;
    });
  }

  function duplicate(id) {
    return loadAsync(id).then(function (src) {
      if (!src) throw new Error('元の案件を読み込めませんでした');
      var c = JSON.parse(JSON.stringify(src));
      c.id = newId();
      c.caseNo = nextCaseNo();               // 複製は新しい番号（正典 §19-1）
      c.name = src.name + ' の複製';
      // シートの id も振り直す（案件をまたいで同じ id が並ばないように・§24-1）
      KINDS.forEach(function (k) {
        (c.sheets[k] || []).forEach(function (s) { s.id = newSheetId(); });
      });
      c.created = c.updated = new Date().toISOString();
      return saved(c);
    });
  }

  function rename(id, name) {
    return loadAsync(id).then(function (c) {
      if (!c) throw new Error('この案件を読み込めませんでした');
      c.name = name;
      return saved(c);       // 🔴 フォルダ運用ではファイル名も変わる（旧名は消える）
    });
  }

  /** 完了ステータスの切り替え（一覧の行トグル用・正典 §19-3） */
  function setDone(id, done) {
    return loadAsync(id).then(function (c) {
      if (!c) throw new Error('この案件を読み込めませんでした');
      c.done = !!done;
      return saved(c);
    });
  }

  /* ---------- 自動保存（debounce・正典 §8 / §27-7③） ---------- */

  var timer = null, pending = null, listeners = [];

  /* 🔴 §27-9 持ち越しの解消: 書き込みが実際に進行中か（save() を呼んでから
   * その Promise が解決するまで）を持つ。debounce の `timer` だけでは
   * 「タイマーは0で発火済み・でも書き込みはまだ終わっていない」区間が漏れる
   * （フォルダ運用はファイル書き込みが非同期なのでこの区間が無視できない）。
   * 「保留」＝ `timer`（まだ送っていない編集がある）または `inflight`
   * （送った書き込みがまだ終わっていない）のどちらか。 */
  var inflight = null;

  /* 🙋 仮値（§27-4「3〜5秒＋変更がある時だけ」）。ファイル書き込みは重いので3秒。
     🔒 §27-12: 保存先は案件フォルダだけになったので間隔も1つ（分岐なし）。 */
  var DEBOUNCE_MS = 3000;

  function onSaveState(fn) { listeners.push(fn); }
  function emit(state) {
    listeners.forEach(function (fn) { fn(state); });
  }

  /** 保存の1回分。🔴 fire-and-forget（結果は onSaveState で知らせる・§27-7③）。
      戻り値の Promise は「一覧へ戻る時／タブを閉じる時に書き終わりを待つ」為の物。 */
  function runSave(c) {
    var p = save(c).then(function (ok) {
      if (inflight === p) inflight = null;
      emit(ok ? 'saved' : 'error');
      return ok;
    }, function () {
      if (inflight === p) inflight = null;
      emit('error');
      return false;
    });
    inflight = p;
    return p;
  }

  function autosave(c) {
    pending = c;
    emit('dirty');
    if (timer) clearTimeout(timer);
    timer = setTimeout(function () {
      timer = null;
      var c2 = pending;
      pending = null;
      runSave(c2);
    }, DEBOUNCE_MS);
  }

  /** 保留中の保存を即座に確定する（画面を離れる時など）。
      🔴 タイマー待ちが無くても、直前の書き込みがまだ進行中ならそれを返す
      （§27-9 持ち越し対応・beforeunload が「書き終わるまで待つ」為の土台）。
      @returns Promise */
  function flush() {
    if (timer) {
      clearTimeout(timer);
      timer = null;
      var c2 = pending;
      pending = null;
      return runSave(c2);
    }
    if (inflight) return inflight;
    return Promise.resolve(true);
  }

  /** 保留があるか（🔴 §27-9 持ち越し対応・beforeunload 専用）。
      true ＝ まだ送っていない編集がある、または送った書き込みが終わっていない。
      false ＝ 何も保留していない（＝タブを閉じても失う物が無い）。 */
  function hasPendingSave() {
    return !!timer || !!inflight;
  }

  /* ---------- 案件ファイルの取り込み ----------
   * 🔒 §27-12-1 ⑤: 案件を1ファイルに書き出す関数（エディタの［ファイルに保存］）は**削除**した。
   *    案件の本体がフォルダにあるので、複製や受け渡しは OS のファイル操作でやる。
   *    取り込み（fromFile）は残す＝他のパソコンから貰った .shako を案件フォルダへ入れる経路。 */

  function fromFile(file) {
    return new Promise(function (resolve, reject) {
      var r = new FileReader();
      r.onload = function () {
        var c;
        try {
          /* 🔴 形式の判定は migrate の**前**に行う（migrate はシート配列を必ず作るので、
             後から見ると何を読ませても「形式が合っている」ことになってしまう）。
             旧形式（objects）・シート形式（sheets）のどちらでも受ける（§24-4 / §20-8）。 */
          var raw = JSON.parse(r.result);
          if (!raw || typeof raw !== 'object' || !raw.points
              || !(raw.objects || raw.sheets)) throw new Error('形式が違います');
          c = migrate(raw);
          /* 取り込みは常に新しい案件として扱う（既存を壊さない）。
             🔴 案件番号は書いてあれば**そのまま**・無ければ空欄のまま。勝手に振らない
             （正典 §19-1）。同じ番号になっても止めず、一覧の警告色で気づかせる */
          c.id = newId();
          c.updated = new Date().toISOString();
        } catch (e) {
          reject(new Error('この JSON は読み込めませんでした: ' + e.message));
          return;
        }
        /* 🔴 §26-4-1 バグ修正: save() の戻り値を見ずに resolve していたため、
         * 保存領域が一杯だと「取り込みは成功したのに開けない
         * （＝案件を読み込めませんでした）」という誤ったエラーになっていた。
         * 🔴 §27: save() は Promise になった（フォルダ運用ではファイル書き込み）。
         * 失敗の理由は lastSaveError() から取る（満杯／フォルダに書けない）。 */
        save(c).then(function (ok) {
          if (!ok) { reject(new Error(lastSaveError())); return; }
          resolve(c);
        }, function (e) { reject(e); });
      };
      r.onerror = function () { reject(new Error('ファイルを読めませんでした')); };
      r.readAsText(file);
    });
  }

  function safeName(s) {
    return String(s || '案件').replace(/[\\/:*?"<>|]/g, '_').slice(0, 60);
  }

  /** 書き出しファイル名の先頭（正典 §19-1）。番号があれば「2026-081_」・無ければ空。
      紙ファイル・受付簿・請求と1本の線でつなぐのが目的なので3種とも同じ前置きにする */
  function filePrefix(c) {
    var no = c && c.caseNo ? safeName(c.caseNo) : '';
    return no ? no + '_' : '';
  }

  /* ---------- スキーマ移行 ---------- */

  /**
   * 🔒 §24-4 後方互換: 旧形式（objects.shozaizu / maps.*.frame …）を
   * **シート配列へ吸い上げる**。旧案件・旧 .shako は「所在図1枚＋配置図1枚」になる。
   *
   * 🔴 本関数の唯一の要件は「旧データを1つも失わないこと」。そのために:
   *   ・その種類のシートがまだ無ければ、旧 objects/maps から**シート1枚**を作る
   *   ・すでにシートがあるのに旧 objects も残っている（ありえない混成データ）時は、
   *     捨てずに**末尾のシートとして足す**。取りこぼしを作らない
   *   ・吸い上げた旧フィールドは消す。二重の真実（同じ図形が2か所）を残さないため
   */
  function migrateSheets(c) {
    var legacy = c.objects || {};
    if (!c.sheets || typeof c.sheets !== 'object') c.sheets = {};
    if (!c.active || typeof c.active !== 'object') c.active = {};
    KINDS.forEach(function (k) {
      var arr = Array.isArray(c.sheets[k]) ? c.sheets[k] : null;
      var m = (c.maps && c.maps[k]) || {};
      var old = Array.isArray(legacy[k]) ? legacy[k] : null;
      if (!arr || !arr.length) {
        // 旧形式 → シート1枚。位置・枠・図形をそのまま引き継ぐ（§24-4）
        arr = [newSheet(k, { center: m.center || null, zoom: m.zoom,
                             frame: m.frame || null, objects: old || [] })];
      } else if (old && old.length) {
        arr.push(newSheet(k, { objects: old }));
      }
      // 欠け・壊れは全シートまとめてここで直す
      for (var i = 0; i < arr.length; i++) arr[i] = normalizeSheet(k, arr[i]);
      /* 出典表記をシートへ配る（🔒 §24-3・Step 6）。
         旧データは案件に1つだけ持っていた。**消さずに全シートへ写す**
         （出典は載せ漏れの方が害が大きいので、多い側へ倒す）。
         🔴 配り終えたら案件側は消す＝二重の真実を作らない（§24-4-a と同じ作法）。 */
      if (Array.isArray(c.attributions) && c.attributions.length) {
        arr.forEach(function (s) {
          if (!Array.isArray(s.attributions) || !s.attributions.length) {
            s.attributions = c.attributions.slice();
          }
        });
      }
      c.sheets[k] = arr;
      // 吸い上げ済み。maps に残しておくと「どちらが正か」が分からなくなる
      if (c.maps && c.maps[k]) {
        delete c.maps[k].center;
        delete c.maps[k].zoom;
        delete c.maps[k].frame;
      }
      var n = c.sheets[k].length;
      var ai = Math.floor(Number(c.active[k]));
      c.active[k] = (isFinite(ai) && ai >= 0 && ai < n) ? ai : 0;
    });
    delete c.objects;
    delete c.attributions;      // シートへ配り終えた（🔒 §24-3）
  }

  /**
   * 役割オブジェクト（主役マーク・使用の本拠／駐車場の文字・結線・距離）の重複掃除。
   * 🔒 §18-z: これらは**1組だけ**。過去に二重で保存された案件を開いた時にここで直す。
   * 🔴 §24-1: シートは独立なので、掃除も**シート1枚ずつ**行う
   *    （まとめて掃除すると、2枚目の所在図の主役マークが1枚目のと衝突して消える）。
   */
  function dedupeRoleObjects(list) {
    var seen = Object.create(null);
    for (var i = list.length - 1; i >= 0; i--) {
      var o = list[i];
      if (!o || o.source !== 'shozaizu' || !o.role) continue;
      /* 使用の本拠と駐車場は同じ role なので、どちらかを鍵に足して見分ける。
       * 距離は文言が変わるので見ない。
       * 🔒 §26-2 注意②: ラベルは pinKey（新しく生成した物）を優先し、
       *    無い旧データだけ表示文字で見分ける。
       * 🔒 §25-4: 主役マーク（role:'mainmark' の四角）も2個で1組なので、
       * 🔴 markRole（'home'/'lot'）を鍵に混ぜないと**片方が消える**。 */
      var key = o.role + '|' + o.type
              + '|' + (o.role === 'pinlabel' ? (o.pinKey || o.text || '') : '')
              + '|' + (o.markRole || '');
      if (seen[key]) list.splice(i, 1);
      else seen[key] = true;
    }
  }

  /** 図形1個の欠けを寛容に補う（読み込みで落とさない） */
  function normalizeObject(o) {
    if (!o) return;                    // 壊れたファイルで落ちない
    if (o.type === 'text') {
      if (!o.size) o.size = 'medium';
      if (o.h_m !== undefined) delete o.h_m;
    }
    /* 駐車位置ラベルの塊（正典 §18-f 駐車位置ラベル・v1 の途中で足した type）。
       🔴 欠けた項目は寛容に補う。at が無い物は置き場所が決まらないので、
          矢印の先（arrowTo）を借りて画面に出す（読み込みで落とさない）。 */
    if (o.type === 'labelBlock') {
      if (!o.lines || !o.lines.length) o.lines = ['保管場所'];
      if (!o.size) o.size = 'medium';
      if (!o.scale || !isFinite(o.scale)) o.scale = 1;
      if (!o.style) o.style = { color: '#111', w: 2 };
      if (!o.at && o.arrowTo) o.at = { lat: o.arrowTo.lat, lng: o.arrowTo.lng };
    }
  }

  function migrate(c) {
    if (!c) return null;
    if (!c.v) c.v = SCHEMA;
    // 将来 v2 以降が出たらここで段階的に変換する
    /* 🔒 §19-5: caseNo / done は SCHEMA 1 のままの**追加フィールド**。
       無い旧案件・旧 JSON は「番号なし（空欄）・作成中」に寄せるだけ（勝手に採番しない） */
    if (typeof c.caseNo !== 'string') c.caseNo = c.caseNo ? String(c.caseNo) : '';
    c.done = !!c.done;
    if (!c.points) c.points = { home: null, lot: null };
    if (!c.maps) c.maps = { shozaizu: defaultMap('shozaizu'),
                            haichizu: defaultMap('haichizu') };
    KINDS.forEach(function (k) {
      if (!c.maps[k]) c.maps[k] = defaultMap(k);
      if (c.maps[k].underlayOpacity === undefined) c.maps[k].underlayOpacity = 1;
      /* §17 で Google を撤去した時はここで 'google-photo'→'gsi-ort' /
       * 'google-map'→'gsi-pale' と書き替えていたが、§17-b（2026-08-19）で
       * 下敷き2種が戻ったので**読み替えをやめた**。キーが無い環境での
       * 読み替えは app.js の resolveUnderlay が受け持つ（保存値は壊さない）。 */
    });
    /* 🔒 §24-4: ここで旧形式をシート配列へ吸い上げる（これ以降 c.objects は無い） */
    migrateSheets(c);
    if (!c.numberCounter) c.numberCounter = 1;
    /* 🔒 §25-4: 主役の印の様式は SCHEMA 1 のままの**追加フィールド**。
       🔴 保存済みの値（'circle' / 'rect' のどちらか）は**そのまま通す**。値が無い
          （＝この設定盤より前の旧案件）時だけ既定で補う。
          以前は `!== 'circle'` なら 'rect' に丸めていたため、既定を 'circle' に
          変えると保存済みの 'rect' まで 'circle' に化ける逆転バグがあった。
       🔒 §28-14 ①-4: 形と色は points[key].mark = {shape,color} が正になったが、
          **それを持たない案件はこの値で描く**（後方互換）ので消さない。 */
    if (c.markStyle !== 'circle' && c.markStyle !== 'rect') c.markStyle = MARK_STYLE_STD;
    /* 🔒 §28-14 ①-4: 地点ごとの印（形・色）。
       🔴 中身の妥当性（'circle'/'rect' と色の key）は app.js の markOf() が
          Editor.MARK を見て確かめる（色の一覧を2か所に書かない）。ここでは
          **形の無い / 壊れた値を捨てる**だけにして、保存値は極力そのまま通す。 */
    ['home', 'lot'].forEach(function (pk) {
      var p = c.points && c.points[pk];
      if (!p) return;
      if (p.mark && typeof p.mark === 'object') {
        if (p.mark.shape !== 'circle' && p.mark.shape !== 'rect') delete p.mark.shape;
      } else if (p.mark !== undefined) {
        delete p.mark;
      }
    });
    /* 🔒 §23-10: 建物の自動描画レベルも SCHEMA 1 のままの**追加フィールド**（1〜5）。
       値が無い（範囲外を含む）時だけ SZ_STD.bldgLevel で補う。既存の値はそのまま。 */
    if (!(Number(c.bldgLevel) >= 1 && Number(c.bldgLevel) <= 5)) c.bldgLevel = SZ_STD.bldgLevel;
    else c.bldgLevel = Math.round(Number(c.bldgLevel));
    /* 🔒 §23-9: 道路の描き方も SCHEMA 1 のままの**追加フィールド**。
       保存済みの値（'line' / 'band' のどちらか）はそのまま通す。値が無い時だけ補う。 */
    if (c.roadStyle !== 'band' && c.roadStyle !== 'line') c.roadStyle = SZ_STD.roadStyle;
    /* 🔒 2026-09-03（所在図パネルの再構成）: ここから下は**今回足した設定**。
       🔴 値が無い時だけ SZ_STD で補う（§22-ao-②）。既に値がある既存案件はそのまま
          ＝「開いただけで図が変わる」事故にならない。 */
    if (!(Number(c.lmLevel) >= 1 && Number(c.lmLevel) <= 5)) c.lmLevel = SZ_STD.lmLevel;
    else c.lmLevel = Math.round(Number(c.lmLevel));
    if (!(Number(c.roadLevel) >= 1 && Number(c.roadLevel) <= 5)) c.roadLevel = SZ_STD.roadLevel;
    else c.roadLevel = Math.round(Number(c.roadLevel));
    c.nature = (c.nature === undefined || c.nature === null) ? SZ_STD.nature : !!c.nature;
    /* 🔒 2026-09-03（後半）: 名称の自動描画6分類。
       🔴 §22-ao-②: 値が無い時だけ SZ_STD の該当キー（項目ごとに段が違う）で補う。
          既に値がある既存案件はそのまま（開いただけで図が変わらない原則は不変）。 */
    NAME_LEVEL_KEYS.forEach(function (k) {
      if (!(Number(c[k]) >= 1 && Number(c[k]) <= 5)) c[k] = SZ_STD[k];
      else c[k] = Math.round(Number(c[k]));
    });
    /* 🔒 §28-6 ⑤（2026-09-06 オーナー承認）: ガイダンスの段。
       SCHEMA 1 のままの**追加フィールド**なので、無い案件（＝この機能より前の
       旧案件）は「無い」ままにする＝開いた時は従来どおり道具メニューのまま。
       🔴 範囲外・数値でない値は捨てるだけ（読み込みで落とさない）。

       🔒 §29 Step 6（2026-09-07）: ⑤に「下敷きと枠」を新設したので、
       **旧⑤〜⑪は⑥〜⑫へ1つ後ろへずれた**（全12段）。
       🔴 保存済みの案件は旧番号なので、`navStepVer` を持たない物だけ
          「5 以上を +1」して読み替え、読み替えた印として NAV_STEP_VER を書く。
          印を書かないと、開くたびに +1 されて段がどんどん進んでしまう。
       🔴 ①〜④（所在図の段）は番号が変わっていないので触らない。

       🔒 §30-1（2026-09-08）: 段は**図ごと**（nav: {shozaizu, haichizu}）になった。
       読み替えは1回だけ通る（読み替えた印＝navStepVer 3）:
         ・版3 …… そのまま検算するだけ
         ・版2 …… 通し番号 1〜12 を図ごとへ分解（5〜12 → haichizu の n−4）
         ・版なし … 旧11段なので 5 以上を +1 してから同じ分解
       🔴 分解が済んだら旧フィールド `navStep` は消す（値が2か所に割れないように）。 */
    if (Number(c.navStepVer) === NAV_STEP_VER) {
      c.nav = normalizeNav(c.nav);
    } else if (c.navStep !== undefined) {
      var ns = Math.round(Number(c.navStep));
      // 版なし（旧11段）だけ +1。版2（12段）は既に今の通し番号なので触らない
      if (Number(c.navStepVer) !== 2 && ns >= 5) ns += 1;
      c.nav = navFromStep(ns);
    } else {
      c.nav = normalizeNav(c.nav);        // 版が無いのに nav だけある物も検算はする
    }
    delete c.navStep;                     // 旧フィールドは残さない（🔒 §30-1）
    if (c.nav) c.navStepVer = NAV_STEP_VER;
    else { delete c.nav; delete c.navStepVer; }   // 段が無いのに印だけ残らないように
    // 旧版はテキストの大きさを実寸メートル(h_m)で持っていた。作図時のズームに
    // 左右されて書き出しが壊れるので、size クラスだけを使う形へ寄せる。
    // 🔴 §24-1: 掃除も補完も**シート1枚ずつ**（シートは互いに独立）
    KINDS.forEach(function (k) {
      c.sheets[k].forEach(function (s) {
        if (k === 'shozaizu') dedupeRoleObjects(s.objects);
        s.objects.forEach(normalizeObject);
      });
    });
    return c;
  }

  /* 案件フォルダへ書けなかった時の文言（🔒 §27-4「書き込み失敗を握り潰さない」）。
   * フォルダを消された・USB を抜かれた・権限が切れた・ディスク満杯 など。 */
  var MSG_FOLDER_FAIL = '案件フォルダに書き込めませんでした。フォルダが移動・削除'
    + 'されていないかご確認ください';

  /* 案件フォルダが開かれていない（🔒 §27-12-6）。③以外では保存の呼び出し自体が
   * 起きないはずだが、握り潰さずにこの理由を返す。 */
  var MSG_NO_FOLDER = '案件フォルダが開かれていません';

  /** 直近の保存失敗の理由（app.js が文言に使う・§27-4） */
  function lastSaveError() {
    return lastError || (folderMode() ? MSG_FOLDER_FAIL : MSG_NO_FOLDER);
  }

  global.Store = {
    SCHEMA: SCHEMA,
    KINDS: KINDS,                                  // 図の種類（§24-1・シートとは別）
    SZ_STD: SZ_STD,                                // 所在図設定盤の標準値（§22-ao-②・唯一の定義）
    NAV_STEP_VER: NAV_STEP_VER,                    // §29/§30-1: ガイダンスの段の番号の版
    NAV_STEPS: NAV_STEPS,                          // §29: 段の総数（12）
    NAV_FIG_LAST: NAV_FIG_LAST,                    // §30-1: 図ごとの段の数（所在図4／配置図8）
    newCase: newCase, defaultMap: defaultMap,
    newSheet: newSheet, normalizeSheet: normalizeSheet,   // シート制（§24-1）
    list: list, loadAsync: loadAsync, save: save, remove: remove,
    duplicate: duplicate, rename: rename, lastOpenedId: lastOpenedId,
    setDone: setDone, nextCaseNo: nextCaseNo,     // §19-1 / §19-3
    autosave: autosave, flush: flush, onSaveState: onSaveState,
    hasPendingSave: hasPendingSave,               // §27-9: beforeunload 用
    fromFile: fromFile, safeName: safeName,
    filePrefix: filePrefix,
    /* ---- 案件フォルダ（🔒 §27 / §27-12）。保存形態はこれ1本だけ ---- */
    folderState: folderState,      // TOP ページの状態（'none' | 'locked' | 'open'）
    openFolder: openFolder,        // フォルダを選んだ／［開く］の直後（索引を作るだけ）
    refreshIndex: refreshIndex,    // ［再読み込み］（自動監視はしない・§27-7①）
    folderMode: folderMode,
    caseFileName: caseFileName,    // 一覧の「ファイル名」表示用
    lastSaveError: lastSaveError,
    MSG_FOLDER_FAIL: MSG_FOLDER_FAIL            // §27-4: フォルダに書けない時の文言
  };
})(typeof window !== 'undefined' ? window : this);
