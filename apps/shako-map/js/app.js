/* app.js — 画面の配線（正典 §3 / Step 1 骨格）
 *
 * 車庫証明 所在図・配置図メーカー
 *   案件一覧 ⇄ エディタ、住所検索、2ピン、タブ、下敷き操作、自動保存。
 *   描画の道具（正典 §4）は Step 2・3 で editor.js に載せる。
 */
(function () {
  'use strict';

  var SVGNS = 'http://www.w3.org/2000/svg';
  /* js/config.js（.gitignore 済み）。§17-b（2026-08-19）で Google 下敷きを
   * 復活させたので、また読むようになった。読むのは GOOGLE_MAPS_API_KEY だけ。 */
  var CFG = window.SHAKO_CONFIG || {};
  /* 🔴 §24-1 の用語（混ぜると事故る）:
   *   kind  ＝ 図の種類（所在図 / 配置図）
   *   sheet ＝ 提出する紙1枚。種類ごとに何枚でも持てる（案件 = 共通情報 + シート群） */
  var KINDS = ['shozaizu', 'haichizu'];
  var KIND_JA = { shozaizu: '所在図', haichizu: '配置図' };
  /* 紙の向き（🔒 §25-3・シートごとに選ぶ）。枠の面積を向きに依らず揃えるのに使う */
  var ORIENTS = ['portrait', 'landscape'];

  /* 🔒 §27-12: 保存形態は案件フォルダ1本になったので、案件一覧にあった
   * 「容量の使用率」表示としきい値は廃止した（上限そのものが無くなったため）。 */
  /* 「保存できません」トーストの連呼防止（§26-4-1・🙋 仮値）。autosave は1秒
   * debounce で走り続けるので、この間隔より短くは同じ hint を出し直さない。 */
  var SAVE_ERROR_HINT_INTERVAL_MS = 15000;

  /* 下敷きの選択肢（正典 §11-b の三分法をそのまま画面に出す）。
   * 🔴 §17（2026-08-18）で Google を全面撤去 → §17-b（2026-08-19 オーナー指示）で
   *    **下敷き2種だけ**復活させた。復活したのは「地図を見る」機能だけで、
   *    住所検索は地理院 msearch のみのまま（Google Geocoder は戻していない）。
   * 🔴 三分法は不変: なぞってよいのはオープンデータ（PLATEAU・地理院オルソ）だけ。
   *    Google は**見る・位置確認のみ**。だから並びも「なぞる用」を上に置き、
   *    Google は下に「見る用」と明記して置く。
   * 🔴 Google の2種は API キー（config.js）がある時だけ選択肢に出る（下の
   *    buildUnderlayOptions）。キーが無い環境でも他の4種で全機能が動く（§9-a）。 */
  var UNDERLAYS = [
    /* 🔒 §29-5 決定2（2026-09-08）: photoEra ＝ ⑤下敷きの〇に出す撮影時期の固定文字列。
     * 地理院 写真（gsi-photo）だけ固定値を持たない（枠の中心の z11 タイルから動的に
     * 取る・sgSyncEra 参照）。UNDERLAYS 1か所に持たせて説明文と二重管理にしない。 */
    /* 🔒 §30-22-1 2（2026-09-13 オーナー指示）: `photo: true` ＝**写真の下敷き**。
     * 枠の破線を赤にするか（青い破線は写真の上で見えにくい）の判定はこの印1か所で行う
     * （表示文字・id の並びでは判定しない・§26-2 注意②）。 */
    { id: 'plateau', label: '正射写真 PLATEAU（真上から・なぞる用）', photo: true,
      provider: 'gsi', kind: 'plateau', photoEra: '撮影 2020年',
      note: '真上から見た形に補正済みで建物が傾きません。'
          /* 🔒 §18-an: 配信範囲は実測で ZL10〜18。下限未満では要求ごと止める */
          + 'なぞって作図してよい下敷きです（対象都市のみ・ZL10〜18。広域表示では出ません）。' },
    { id: 'gsi-ort', label: '正射写真 地理院（真上から・全国・なぞる用）', photo: true,
      provider: 'gsi', kind: 'ort', photoEra: '撮影年不明（2007年以降）',
      note: '真上から見た形に補正済み。全国をカバーします。'
          + 'なぞって作図してよい下敷きです（ZL18まで）。' },
    { id: 'gsi-photo', label: '航空写真 地理院（全国）', photo: true,
      provider: 'gsi', kind: 'satellite',
      note: '全国の最新写真。オルソではありません。' },
    { id: 'gsi-pale', label: '地理院 地図（淡色）', provider: 'gsi', kind: 'roadmap',
      note: '淡色地図。所在図の下書き用。' },
    /* 🔒 §28-5 B / §28-9（Step 3・2026-09-07）: OSMFJ（tile.openstreetmap.jp）。
     * 実測で規約・URL・出典表記を確認（js/mapview.js の GSI_SOURCES.osmfj 参照）。
     * 下敷きの画像は書き出しに含まれない（下の note・§1-3）ので、紙の出典（§24-3）には足さない。 */
    /* 🔒 §28-13 決定1/決定2（2026-09-07）: **所在図の既定の下敷き**。
     * 🔴 説明文は事実に直した。OSM のラスタタイルに描かれるのは
     *    「お店・施設の名前」と「路線番号」で、**交差点名はどのスタイルにも描かれない**
     *    （交差点名を持つのは所在図生成が使う Overpass の**データ**の方。
     *     ガイダンス④の［交差点名・バス停名を地図に重ねる］がそれを重ねる）。 */
    { id: 'osmfj', label: 'OpenStreetMap', provider: 'gsi', kind: 'osmfj',
      note: 'お店・施設の名前と路線番号が分かります（所在図の既定の下敷き）。'
          + '交差点名はガイダンス④の［交差点名・バス停名を地図に重ねる］で重ねられます。'
          + '提供：OSMFJ（tile.openstreetmap.jp）・© OpenStreetMap contributors（CC-BY）。' },
    { id: 'google-photo', label: 'Google 航空写真（高精細・見る用）', photo: true,
      provider: 'google', kind: 'satellite', google: true, photoEra: '時期不明・見るだけ',
      note: '最も鮮明ですが、正射補正されていないため背の高い建物は傾いて写ります。'
          + '🔴 位置の確認だけに使ってください（なぞって作図しない・上の正射写真に切り替える）。' },
    { id: 'google-map', label: 'Google 地図（見る用）',
      provider: 'google', kind: 'roadmap', google: true,
      note: '道路地図。場所の当たりを付ける用です。'
          + '🔴 なぞって作図しないでください（作図は地理院 淡色地図で）。' }
  ];
  /**
   * 🔒 §30-22-1 2: いまの下敷きが**写真**か（地理院 写真／地理院 オルソ／PLATEAU／
   * Google 航空写真）。枠の破線の色（青／赤）を決めるのはこの1か所。
   * 🔴 下敷きを隠している時（地図OFF）は白地なので「写真ではない」＝青のまま。
   */
  function underlayIsPhoto() {
    if ($('underlayOff') && $('underlayOff').checked) return false;
    var u = underlayById($('underlaySel') ? $('underlaySel').value : '');
    return !!(u && u.photo);
  }

  function underlayById(id) {
    for (var i = 0; i < UNDERLAYS.length; i++) {
      if (UNDERLAYS[i].id === id) return UNDERLAYS[i];
    }
    return null;
  }

  var state = {
    current: null,      // 編集中の案件
    kind: 'shozaizu',   // いま編集している図の種類（シートの番号は c.active[kind]）
    map: null,
    editor: null,
    reveal: null,       // なぞり出し（§23・js/reveal.js）。ensureMap で作る
    underlayName: 'gsi',
    googleFailed: false,  // キー失効・リファラ拒否で Google を諦めた（§17-b）
    gmapsLoad: null,      // Maps JavaScript API の読み込み Promise（遅延・1回だけ）
    pins: {},           // home / lot の SVG 要素
    pinEls: {},         // その中身（◎の2円・■の四角と斜線・🔒 §28-14 ①-4）
    distEls: null,
    /* 🔒 §28-14 ①-4: マーカーの形・色を**置く前に**選んだ時の控え（画面だけ）。
       置いた瞬間に points[key].mark へ移す（onNavPinPlace）＝案件に残るのはそちら。 */
    markPick: { home: null, lot: null },
    /* 🔒 §30-24-1: **次に描く主役の多角形**の書式（太さ／色／斜線）。
       画面の状態なので案件には保存しない（何も選んでいない時に書式のアイコンを
       押すとここが変わり、次に描く多角形がこの書式で出る）。 */
    mainPolyDefault: { width: 'normal', color: 'black', hatch: true },
    /* 🔒 §30-24-1: その地点の多角形の**先頭**（＝ピンを持つ「最初に描いた物」）の id。
       画面の状態なので案件には保存しない。先頭が入れ替わった＝最初の物を消した時に
       ピンを次の物の重心へ動かすためだけに使う（syncMainPolyHead）。 */
    mainPolyHead: { home: null, lot: null },
    /* 🔒 §30-2: 案内数字の「押した」記録（画面だけ・案件に保存しない）。
       key は '図:番号'。状態から済んだか判定できない部品（道具・〇・欄・
       プレビュー）は、押した瞬間にここへ記す（sgNumDone が最後に見る）。 */
    sgHit: {},
    /* 🔒 §30-12-4 5: 「こんな時に押すボタン」の開閉。**段ごとに覚える**（同じ案件を
       開いている間だけ・案件には保存しない）。key は 図 → 段の番号（1〜12）→ 機能の key。
       値が無い＝閉じている（既定は全部閉じ）。 */
    sgMoreOpen: { shozaizu: {}, haichizu: {} },
    /* 🔒 §30-25-35 2: 配置図の下敷きの▼（#hzUnderMore）だけは**段をまたいで
       覚えない**（「次に進んだら折りたたんだ状態で」）。開いた段の番号だけを持ち、
       段が変わったら 0 に戻す＝閉じる。同じ段にいる間は開いたまま。 */
    hzUnderOpenAt: 0,
    /* 🔒 §30-28-1 2: 道具メニューの▼（印を変える／地図の名前を確かめる／
       自動・取り込み）の開閉。**同じ案件を開いている間だけ**覚える（案件には保存しない）。
       値が無い＝閉じている（既定は全部閉じ）。 */
    toolMoreOpen: {},
    /* 前回の「注意」の有無（'段:key' → 真偽）。出た**瞬間**だけ自動で開くため */
    sgMoreWarn: {},
    /* 🔒 §30-38-5 1: 「頂点の足し引き」の一言を**もう出した図形**の id。
       同じ図形を選び直しても連呼しないためだけに持つ。画面の状態なので
       案件には保存しない（案件を切り替えたら空に戻す・openCaseInner）。 */
    vertexHintFor: '',
    /* 🔒 §30-12-4 5 / §30-11-b 5: 写真を取り込んだ直後は
       ［自分で撮った写真・図面を使う］だけを自動で開く（位置合わせの案内と濃さの欄を
       見せるため）。開いたら下ろす（画面だけの合図・保存しない）。 */
    sgMoreImgNew: false,
    /* 🔒 §30-26-3 → §30-34-1: 「同じ図の紙の枠の範囲と番号の札」を出すか（既定＝出さない）。
       🔴 出すにすると**プレビューだけでなく PDF・画像・まとめにも刷られる**
          （紙の描画 Exporter.renderSheet の showFrames に入る）。
       🔴 画面の状態なので**案件には保存しない**。プレビューを閉じても、
          同じ案件を開いている間は覚えている（オーナー指示）。 */
    exOtherFrames: false,
    /* 🔒 §30-33: 配信側で見つけた**最新の版**（version.json の ver）。空＝まだ分からない。
       画面の状態なので案件には保存しない（読み直せば取り直す）。 */
    verLatest: '',
    /* 案件一覧の絞り込み（正典 §19-2/19-3/19-4）。
       🔴 画面の状態なので**保存しない**。開くたびに［進行中］・検索空・更新順に戻る */
    listQuery: '',
    listTab: 'active',  // active | done | all
    listSort: 'updated' // updated | created | caseNo
  };

  var TOOL_HINT = {
    /* 🔒 §30-38-2 5: 末尾に Alt＋クリックの一言（帯・左メニュー・ガイダンスの
     * 1行は全部この TOOL_HINT を読む＝出どころ1か所）。 */
    select: '図形をクリックで選択・ドラッグで移動。Delete で削除、Ctrl+D で複製、Ctrl+Z で戻す。'
      + 'Alt＋クリックで線に頂点を足す（頂点の上で Alt＋クリックなら消す）',
    line: '2回クリックで1本引きます（Esc で取り消し）',
    curve: '2回クリックで両端 → マウスを動かして膨らみを決め、もう1回クリックで確定',
    /* 🔒 §30-22-3 2（§18-10 を改めた）: 四角は「建物など」の四角（駐車枠の意味は持たない）。
     * 駐車枠は［駐車枠］（stamp）1つだけ。 */
    rect: 'ドラッグで四角を1つ描きます（建物・囲いなど）。選択すると辺つまみで伸縮・上のつまみで回転',
    polygon: 'クリックで頂点を足し、ダブルクリック（または Enter）で閉じます。'
      + 'Backspace または［1つ戻す］で直前の点を取り消せます',
    // 🔒 §25-5: 空欄なら地図から計算した距離が入る。実測値は「幅」欄か「表示」欄で上書き
    arrow: 'ドラッグまたは2回クリック。空欄なら地図から計算した距離、'
      + '「幅」欄に数値を入れるとその値が入ります',
    text: 'クリックした所に文字を置きます。定型文から選ぶこともできます',
    /* 🔒 §28-5 A / §28-7: 信号機・バス停は「印つき文字」を手で置く道具。
     * 名前は入れなくてよい（空のまま Enter か Esc で印だけ残る）。 */
    signal: '交差点をクリックすると信号機の印が置かれ、続けて交差点名を入れられます。'
      + '名前が要らなければ空のまま Enter（印だけ残ります）',
    bus: 'バス停の場所をクリックすると印が置かれ、続けて停留所名を入れられます。'
      + '名前が要らなければ空のまま Enter（印だけ残ります）',
    /* 🔒 §30-35-2 1・3（2026-09-15 オーナー指示）: P・木は**印だけ**（名前は聞かない）。
     * 器は信号機・バス停と同じ「印つき文字」のままなので、後から文字を付けたい時は
     * 従来の文字の編集でできる（§30-35-2 4）。 */
    parking: 'クリックした場所に P マーク（□の中に P）を置きます',
    /* 🔒 §30-25-9 / §30-35-2 1: 木も P マークと同じ（印だけ・名前は聞かない） */
    tree: 'クリックした場所に木の印を置きます',
    /* 🔒 §30-22-1 4: 主役の多角形は**この道具だけ Enter で閉じる**（§4-5 の例外） */
    /* 🔒 §30-24-1: 書式は▼「印を変える」の中にも同じ物が出る（いくつでも描ける） */
    mainpoly: '建物や土地の形にそってクリックで頂点を足し、最後に Enter（またはダブルクリック）で'
      + '囲みます。同じ場所にいくつでも描けます。線の太さ・斜線・色は、'
      + '描いた直後（左の欄）か、選んでから右の欄で変えられます',
    /* 🔒 §30-22-3 2: 来客用・車いすは駐車枠をクリックで入り切り（保管場所と同じ） */
    guest: '駐車枠をクリックすると枠の中に「来客用」が入ります。もう一度クリックで外れます',
    wheel: '駐車枠をクリックすると枠の中に車いすの印が入ります。もう一度クリックで外れます',
    eraser: 'クリックした図形を1つ消します。塊は枠1枚だけ消えます',
    number: '枠の上を押したままなぞると、通った順に連番が入ります（塊をまたいでもOK）。'
      + '1回クリックで1枠ずつ。Alt+クリックで消去',
    /* 🔒 §30-25-19: 印は太枠（＋斜線・色）だけ。「保管場所」の文字は出さない
     * （言葉が要る時は配置図⑦の［保管場所］で文字として置く・§30-25-20） */
    storage: '対象の枠をクリックすると太枠が付きます。'
      + 'もう一度クリックで外れます（複数の枠に付けられます）',
    /* 🔒 §23（なぞり出し）。下書きは書き出しに含まれない（§23-2）ことを必ず伝える */
    reveal: '地図の建物・道路が薄く見えます。押したままなぞると、'
      + 'なぞった所だけが線になります（薄い下書きは書き出されません）。'
      + '太さは［小・中・大］か [ ] キー。ズームを上げると細かい建物が出ます'
      /* 🔒 §23-5: 名称は分類を選んで薄く出し、なぞると1個まるごと図形になる */
      + '／［名称を薄く出す］で分類を選ぶと、その名称が場所ごと薄く出ます',
    /* 🔒 §25-7: 道具としての 'stamp' は［台数を指定して置く…］の窓を開いた時だけ。
     * ［枠をまとめて］は道具にならず、押した瞬間に1枠置いて［選択］に戻る。 */
    stamp: '台数と1枠の大きさを決めて［配置］を押すと地図の中央に置かれます'
      + '（［枠をまとめて］なら1枠だけ置いて、まわりの ＋ で増やせます）',
    parcel: '青い枠が土地の区画です。駐車場の区画をクリックすると外枠と地番を取り込みます'
  };

  /* 🔒 §30-38-5 1（2026-09-15 オーナー指示）: **配置図で線を選んだ時**に地図の上へ
   * 出す一言（🔴 文はここ1か所）。減らす方もこの一言に含めるだけ（別の案内は作らない）。
   * 🔒 §30-38-5 3: 所在図では出さない（自動生成の道路は帯で直す作法が違う）。 */
  var VERTEX_HINT = '線の上で Alt＋クリック＝頂点を足す／頂点の上で Alt＋クリック＝消す';
  var VERTEX_HINT_MS = 5000;

  /* ================= 道具のアイコン（🔒 §30-22-3 2・2026-09-13 オーナー指示）=======
   * > オーナー: 「道具は全部アイコン（説明はマウスオーバー）」
   * ボタンの中身は**絵だけ**・説明は title（マウスオーバー）に寄せる。
   * 🔴 絵・名前・説明の出どころは**この表1か所**。index.html 側は
   *    `data-icon="鍵"` を書くだけ（applyToolIcons が中身と title を入れる）。
   *    ＝ ガイダンス④と道具メニューで絵も説明も必ず同じになる。
   * 🔴 <svg> は stroke="currentColor" fill="none"（選択中は文字色が白になるので、
   *    絵も一緒に白へ変わる＝色を二重に持たない）。
   * 🔴 押した時の動きは従来どおり class="tool" の共通ハンドラ（data-tool）。
   *    ここは**見た目だけ**を差し替える（配線は1本も変えない）。 */
  function ico(body, extra) {
    return '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"'
      + ' fill="none" stroke="currentColor" stroke-width="1.7"'
      + ' stroke-linecap="round" stroke-linejoin="round"'
      + (extra || '') + '>' + body + '</svg>';
  }
  /**
   * 🔒 §30-30-2: 道具［木］の絵。図に入る印と**同じ関数**（Editor.treeGeom /
   * treeCanopyPath）から作る＝絵と印が食い違わない（車いす・方位記号と同じ作法）。
   * 24 の箱に上下 1 の余白を取り、全高 22 に収まる size を解いて描く。
   */
  function treeIconBody() {
    var E = window.Editor;
    if (!E || !E.treeGeom || !E.treeCanopyPath) {
      return '<path d="M12 22v-6.5"/><circle cx="12" cy="8.3" r="7.3"/>';   // 予備
    }
    var g1 = E.treeGeom(1);                 // size=1 の時の全高で size を逆算
    var size = 22 / g1.h;
    var g = E.treeGeom(size);
    var baseY = 1 + g.h;                    // 幹の下端（＝ anchor）
    return '<path d="M12 ' + baseY.toFixed(2) + 'V' + (baseY - g.trunk).toFixed(2) + '"/>'
         + '<path d="' + E.treeCanopyPath(12, baseY + g.cy, g.r) + '"/>';
  }

  var TOOL_ICONS = {
    /* --- 道路や建物、文字や線を足す・消す --- */
    select: { ja: '選択（手のひら）',
      note: '文字や線を掴んで動かす・大きさを変える。迷ったらこれ',
      svg: ico('<path d="M9 11.5V5.6a1.5 1.5 0 0 1 3 0v5.4"/>'
             + '<path d="M12 10.2a1.5 1.5 0 0 1 3 0v1.3"/>'
             + '<path d="M15 10.6a1.5 1.5 0 0 1 3 0v4.6a5.5 5.5 0 0 1-5.5 5.5h-1a4.6 4.6 0 0 1-3.9-2.1l-2.3-3.7a1.5 1.5 0 0 1 2.4-1.7L9 15.2"/>') },
    eraser: { ja: '消しゴム', note: 'いらない文字・線をクリックして消す',
      svg: ico('<path d="M5 20h14"/><path d="M15.2 4.6 20 9.4l-8.2 8.2H7.6L3.6 13.6z"/>') },
    line: { ja: '直線', note: '道路や境界を1本引く（クリック→クリック）',
      svg: ico('<path d="M6.5 17.5 17.5 6.5"/><circle cx="5" cy="19" r="1.8"/>'
             + '<circle cx="19" cy="5" r="1.8"/>') },
    curve: { ja: '曲線', note: '曲がった道路・川を引く（両端をクリック→ふくらみを決める）',
      svg: ico('<path d="M4 17.5c5 0 4-11 8-11s5 6.5 8 6.5"/>') },
    polygon: { ja: '多角形', note: '建物・敷地の形を囲う（クリックで角、Enter で確定）',
      svg: ico('<path d="M12 3.8 20 9.6 17 19H7L4 9.6z"/>') },
    rect: { ja: '四角（建物など）', note: 'ドラッグで四角を1つ描く（建物・囲いなど）',
      svg: ico('<rect x="4.2" y="6.2" width="15.6" height="11.6" rx="1"/>') },
    /* 🔒 §30-25-6 1（2026-09-13 オーナー指示）: 文字の道具は**1つだけ**にした。
     * 旧 text（「A」＋カーソルの縦棒）は廃止し、絵は下の textFree（［自由入力］）が継ぐ。 */
    /* --- 印を置く --- */
    signal: { ja: '信号機', note: '交差点に信号機の印を置く。交差点名も入れられる（空でもよい）',
      svg: ico('<rect x="3.2" y="8" width="17.6" height="8" rx="2.6"/>'
             + '<circle cx="8" cy="12" r="1.5" fill="currentColor" stroke="none"/>'
             + '<circle cx="12" cy="12" r="1.5" fill="currentColor" stroke="none"/>'
             + '<circle cx="16" cy="12" r="1.5" fill="currentColor" stroke="none"/>') },
    bus: { ja: 'バス停', note: 'バス停の印を置く。停留所名も入れられる（空でもよい）',
      svg: ico('<rect x="5.4" y="3.2" width="13.2" height="7.6" rx="1.6"/>'
             + '<path d="M12 10.8V20"/><path d="M8.2 20h7.6"/>') },
    /* 🔒 §30-35-2 3: P・木は名前を聞かない＝説明からも「名前」を外す */
    parking: { ja: 'P マーク', note: 'クリックした所に P マークを置く',
      svg: ico('<rect x="4.2" y="4.2" width="15.6" height="15.6" rx="3"/>'
             + '<path d="M9.8 16.4V7.8h3a2.7 2.7 0 0 1 0 5.4h-3"/>') },
    /* 🔒 §30-25-9 3 / §30-30-2: 木の絵は Editor.treeGeom / Editor.treeCanopyPath を
     * そのまま 24 の箱へ収めた物＝図に入る印とまったく同じ形（もこもこの樹冠も同じ数値）。
     * 🔴 大きさは treeGeom(size) の全高（trunk + 樹冠）が 22 に収まる size を解いた値。
     *    Editor が読めない時（単体テスト）だけ従来の円の絵に落ちる。 */
    tree: { ja: '木', note: 'クリックした所に木の印を置く',
      svg: ico(treeIconBody()) },
    /* --- 駐車枠 --- */
    stamp: { ja: '駐車枠', note: '押してから置きたい場所を地図でクリック。まわりの＋で増やせます',
      svg: ico('<path d="M4 4.5v15M12 4.5v15M20 4.5v15"/><path d="M4 19.5h16"/>') },
    number: { ja: '番号', note: '枠をなぞると通った順に連番が入る（Alt＋クリックで消去）',
      svg: ico('<rect x="3.5" y="6" width="17" height="12" rx="2"/>'
             + '<path d="M8.4 15V9.6L6.9 10.7"/>'
             + '<path d="M12.4 10.3a1.7 1.7 0 0 1 3 1.1c0 1.6-3 1.9-3 3.6h3.4"/>') },
    guest: { ja: '来客用', note: '駐車枠をクリックすると枠の中に「来客用」が入る（もう一度で外れる）',
      svg: ico('<circle cx="12" cy="7.2" r="3.2"/>'
             + '<path d="M5.4 20.2a6.6 6.6 0 0 1 13.2 0"/>') },
    /* 🔒 §30-22-7 5: 車いすの絵は Editor.WHEELCHAIR の数値 ×24（中心 12,12）＝
     * 図に入る印とまったく同じ形（絵と印が食い違わない）。 */
    wheel: { ja: '車いす', note: '駐車枠をクリックすると枠の中に車いすの印が入る（もう一度で外れる）',
      svg: ico('<circle cx="12.5" cy="15.4" r="7.2" stroke-width="1.7"/>'
             + '<circle cx="8.6" cy="3.4" r="2.3" fill="currentColor" stroke="none"/>'
             + '<path d="M7.9 6.5 10.6 10.8"/><path d="M8.6 8.2 14.4 9.1"/>'
             + '<path d="M10.6 10.8 14.9 12.7"/><path d="M14.9 12.7 16.8 17.3"/>'
             + '<path d="M16.8 17.3 19.4 16.8"/>') },
    stampSpec: { ja: '台数を指定して置く…', note: '台数・1枠の幅と奥行を数値で決めてまとめて置く',
      svg: ico('<path d="M3.5 4.5v10M9.5 4.5v10M15.5 4.5v10"/><path d="M3.5 14.5h12"/>'
             + '<path d="M19 16.5v5M16.5 19h5"/>') },
    /* --- 幅の矢印（🔒 §30-29-4 1）---
     * 絵＝両矢印（←→）＋両端の止め（寸法線の形）。道具そのものではなく
     * 「小さな窓を開く」ボタンに付くが、絵と説明の出どころは他と同じこの表1か所。 */
    arrow: { ja: '幅の矢印',
      note: '道路や出入口の幅を矢印で書き入れる（自動で測るか、幅を入力）',
      svg: ico('<path d="M3.6 12h16.8"/><path d="M7.2 8.4 3.6 12l3.6 3.6"/>'
             + '<path d="M16.8 8.4 20.4 12l-3.6 3.6"/>'
             + '<path d="M3.6 5.4v13.2"/><path d="M20.4 5.4v13.2"/>') },
    /* --- 文字（定型・§30-18-4 の作法） ---
     * 🔒 §30-22-8 5（2026-09-13 Fable 裁定）: **定型の文字ボタンは絵にしない**
     *    （［私道］［建物］［駐輪場］は言葉をそのまま出す＝index.html の
     *    🔒 §30-25-9 1: ［木］は定型から外れ、「印を置く」の道具（tree）になった。
     *    .sg-word。ここに絵を持たせると「言葉のボタン」と二重になる）。
     *    アイコンを持つのは［自由入力］だけ。 */
    /* 🔒 §30-25-6 2: 絵は**「A」だけ**（カーソルの縦棒は無し）＝旧 text の絵を継ぐ。
     * 文字の道具はこの1つなので、2つの絵を見分けさせる必要がそもそも無い。 */
    textFree: { ja: '自由入力', note: 'クリックした所に入力欄を出して、好きな文字を置く',
      svg: ico('<path d="M4.5 19 11 5.5 17.5 19"/><path d="M7.1 14.2h7.8"/>') },
    /* --- 紙の帯（🔒 §30-26-2）---
     * 道具ではないが、絵と説明の出どころを増やさないために同じ表に置く。
     * 絵＝A4 縦の紙（右上を折った四角）＋その上の虫眼鏡。 */
    /* 🔒 §30-27-1 1: プレビューは1つの画面になったので、開く先は「この紙から」 */
    loupe: { ja: 'この紙のプレビュー', note: 'この紙から、紙の見た目で確かめます',
      svg: ico('<path d="M4.6 2.9h8.1l4.7 4.7v13.5H4.6z"/><path d="M12.7 2.9v4.7h4.7"/>'
             + '<circle cx="11" cy="13.1" r="3.5"/><path d="M13.5 15.6 16.8 18.9"/>') }
  };

  /**
   * 🔒 §30-22-3 2: `data-icon` が付いたボタンに、表の絵と説明を入れる。
   * 🔴 中身も title もこの表が唯一の出どころ＝同じ道具が2か所に出ても必ず同じ見た目。
   * 🔒 §30-26-2: 後から作るボタン（紙の帯のルーペ）にも同じ物を入れられるよう、
   *    **1つ分**（applyToolIcon）と**全部**（applyToolIcons）に分けてある。
   */
  function applyToolIcon(b) {
    var it = b && b.dataset && TOOL_ICONS[b.dataset.icon];
    if (!it) return;
    b.innerHTML = it.svg;
    b.classList.add('ico-btn');
    b.title = it.ja + '：' + it.note;
    b.setAttribute('aria-label', it.ja);
  }
  function applyToolIcons() {
    document.querySelectorAll('[data-icon]').forEach(applyToolIcon);
  }

  var $ = function (id) { return document.getElementById(id); };

  /* ============ 定型の言葉（🔒 §30-29-1 2・2026-09-14 オーナー指示）============
   * > オーナー:「文字はボタンクリックで、A から私道、建物とか全ての既定テキストが、
   * >   エクセルやワードにあるみたいな小さいウィンドウが開いてそこで選択する感じに」
   * 🔴 **一覧の出どころはこの表1か所**（旧 index.html の #textPreset の <option> と
   *    ガイダンスの .sg-preset を1つに統合した）。言葉を増やす時はここだけ足す。
   * 🔴 index.html 側は「どの言葉を出すか」を data-words="私道,建物,駐輪場" で指定する
   *    だけ（言葉そのものは持たない）。この表に無い言葉は出さない（buildPresetRows）。
   * 🔴 押した後の作法は §30-18-4 のまま（押す → 地図をクリックした所へ置く）。 */
  var TEXT_PRESETS = [
    '私道', '建物', '駐輪場', '保管場所', '出入口', '入口', '出口',
    '道路', '公道', '歩道', '駐車場', '使用の本拠', '隣家', '店舗',
    '空地', '月極駐車場', '○○通り', '幅員　m', '入庫口の高さ　m',
    '新規', '増車', '代替（ナンバー：　）'
  ];
  /** その言葉が表にあるか（🔴 表示文字で分岐しないための唯一の照合口） */
  function isTextPreset(w) { return TEXT_PRESETS.indexOf(w) >= 0; }

  /** 定型の言葉のボタンを1つ作る（🔒 §30-29-1 2・見た目も配線も1か所） */
  function makePresetBtn(word, cls) {
    var b = document.createElement('button');
    b.type = 'button';
    b.className = 'sg-preset ' + (cls || 'sg-word');
    b.dataset.preset = word;
    b.textContent = word;
    b.title = '押してから、置きたい場所を地図でクリックします';
    return b;
  }

  /**
   * 🔒 §30-29-1 2: ガイダンスの「文字を置く」欄（所在図④・配置図④⑤⑥⑦）の
   * 言葉のボタンを **TEXT_PRESETS から組む**。index.html の
   * `<span class="sg-words" data-words="私道,建物,駐輪場">` が器。
   * 🔴 表に無い言葉は出さない（言葉の出どころを2つに割らないため）。
   */
  function buildPresetRows() {
    document.querySelectorAll('.sg-words').forEach(function (box) {
      box.innerHTML = '';
      (box.dataset.words || '').split(',').forEach(function (w) {
        var word = w.trim();
        if (!word || !isTextPreset(word)) return;
        box.appendChild(makePresetBtn(word));
      });
    });
  }

  /**
   * 🔒 §30-29-1 2: 上部バー2行目の［A］で開く**文字の選択窓**（#textPick）。
   * 1行目＝［自由入力］（A のアイコン）／続いて TEXT_PRESETS の全部／
   * 一番下は「大きさ」（#textSize そのもの＝値は1つ）。
   * 🔴 中身はここで1回だけ組む（言葉の出どころは TEXT_PRESETS）。
   */
  function buildTextPick() {
    var list = $('textPickList');
    if (!list) return;
    list.innerHTML = '';
    // 1行目＝［自由入力］（.sg-textfree の共通ハンドラが受ける）
    var free = document.createElement('button');
    free.type = 'button';
    free.className = 'sg-textfree tp-free';
    free.dataset.icon = 'textFree';
    list.appendChild(free);
    applyToolIcon(free);
    // 絵だけだと何の行か分からないので、この行にだけ言葉を添える
    var lb = document.createElement('span');
    lb.className = 'tp-free-t';
    lb.textContent = TOOL_ICONS.textFree.ja;
    free.appendChild(lb);
    free.classList.remove('ico-btn');     // 幅いっぱいの行（正方形のアイコンではない）
    // 続いて定型の言葉（表の並び順そのまま）
    var g = document.createElement('div');
    g.className = 'tp-words';
    TEXT_PRESETS.forEach(function (w) { g.appendChild(makePresetBtn(w, 'tp-w')); });
    list.appendChild(g);
  }

  /** 窓の開け閉め（🔴 状態は #textPick の hidden 1つ・別の変数を持たない） */
  function textPickSet(open) {
    var box = $('textPick'), btn = $('tbTextBtn');
    if (!box) return;
    box.hidden = !open;
    if (btn) {
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
      btn.classList.toggle('is-on', !!open);
    }
  }
  function textPickOpen() { textPickSet(true); }
  function textPickClose() { textPickSet(false); }

  /* ====== 幅の矢印の小さな窓（🔒 §30-29-4 1・2026-09-14 オーナー指示）======
   * ［幅矢印］のアイコン（#tbArrowBtn）の直下に出る。中身は2択だけ:
   *   ［自動入力］（地図の尺度から計測）／［幅を入力］＋数値の欄＋「m」
   * どちらかを押すと窓が閉じて矢印の道具になる（#textPick と同じ作法）。
   * 🔴 状態は #arrowPick の hidden 1つ・値は arrowWidth ／ state.arrowMode のまま。 */
  function arrowPickSet(open) {
    var box = $('arrowPick'), btn = $('tbArrowBtn');
    if (!box) return;
    box.hidden = !open;
    if (btn) {
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
      btn.classList.toggle('is-on', !!open);
    }
  }
  function arrowPickOpen() {
    arrowPickSet(true);
    syncArrowModeUI();            // いまのモードを窓にも映す（値の出どころは1つ）
    var el = $('apArrowW');
    if (el) el.focus();           // 「幅を入力」は打ってから押す作法なので焦点を置く
  }
  /**
   * 窓を閉じる。🔴 選ばずに閉じた（外側クリック・Esc・案件の切替）時は、
   * 打ちかけの値を**いまのモードに戻す**（自動のままなら空へ）。
   * ＝「自動なのに欄に数字が残っていて、引いたら数字が出た」を作らない。
   */
  function arrowPickClose() {
    arrowPickSet(false);
    if (state.arrowMode !== 'manual') setArrowWidth('');
  }
  function svgEl(name, attrs) {
    var n = document.createElementNS(SVGNS, name);
    for (var k in attrs) n.setAttribute(k, attrs[k]);
    return n;
  }

  /* ================= シート（§24-1） =================
   * 🔴 案件データへ触る時は必ずこの入口を通す。
   *    `c.objects.haichizu` のような直接参照はもう無い（シート配列に移った）。
   * 🔴 §26-2 注意①: シートの objects 配列は Editor.bind() と**参照を共有**する。
   *    配列そのものを差し替えたら（複製・並べ替え・削除）**必ず bindCurrentSheet()**
   *    を呼び直すこと。忘れると編集が保存されない配列に書き続ける。 */

  /** その種類のシート配列 */
  function sheetsOf(k) {
    var c = state.current;
    return (c && c.sheets && c.sheets[k]) || [];
  }

  /** その種類の「いま開いているシート」の番号（範囲外は 0 に丸める） */
  function activeIdx(k) {
    var n = sheetsOf(k).length;
    if (!n) return 0;
    var c = state.current;
    var i = Math.floor(Number(c.active && c.active[k]));
    return (isFinite(i) && i >= 0 && i < n) ? i : 0;
  }

  /** その種類の「いま開いているシート」（無ければ null） */
  function sheetOf(k) { return sheetsOf(k)[activeIdx(k)] || null; }

  /** 編集中のシート */
  function curSheet() { return sheetOf(state.kind); }

  /** その種類の「いま開いているシート」の図形（読み取り用・必ず配列を返す） */
  function objectsOf(k) {
    var s = sheetOf(k);
    return (s && s.objects) || [];
  }

  /* ================= 起動 ================= */

  /* 起動。🔴 §16-13: 何があっても**きれいな TOP ページ**に落ちる。
   * かぶせ物（3択・プレビュー）は起動時に必ず閉じてから始める。
   * 🔒 §27-12: TOP ページは「ゲート1枚」か「本体」のどちらか（renderTop が決める）。
   *    従来の「まず localStorage の一覧を出しておく」は無くなった（案件はフォルダにしか無い）。 */
  function boot() {
    try {
      closeAllOverlays();
      bindCaseList();
      bindEditor();
      Store.onSaveState(showSaveState);
      showView('list');
      /* 🔴 状態（①②③・非対応）が分かるまでは何も出さない。renderTop が出し分ける。
       *    権限をここで**要求はしない**（ユーザー操作が要る・§21-2）。 */
      renderTop();
      /* 🔒 §30-33: 新しい版の見張りを始める（版なし＝手元では何もしない）。
       * ここで転んでもアプリは動くべきなので try の中に置く。 */
      verBoot();
    } catch (e) {
      closeAllOverlays();
      try { showView('list'); } catch (e2) { /* 表示だけは必ず TOP にする */ }
      $('caseListView').hidden = false;
      $('editorView').hidden = true;
      /* 🔒 §27-12: 戻り先は案件一覧ではなく**ゲート**（フォルダを開くまで一覧は無い） */
      try { showGate('none'); } catch (e3) { /* ここで転んでも alert は出す */ }
      alert('起動時に問題が起きたため、最初の画面に戻りました（' + (e.message || e) + '）');
    }
  }

  /* ================= Google 下敷き（§17-b 復活）=================
   * 🔴 読み込みは**遅延**にした。利用者が Google の下敷きを選ぶまで
   *    maps.googleapis.com へは1件も要求を出さない（既定は PLATEAU／地理院淡色）。
   *    §17 で得た「選ばなければ Google に何も送らない」性質をそのまま残すため。
   * 🔴 外へ出るのは地図タイルの取得要求だけ。依頼者の住所・取り込み画像・
   *    図形データは従来どおり一切送らない（§1-6）。 */

  /** Google の下敷きが今使えるか（キーがあり、まだ拒否されていない） */
  function googleAvailable() {
    return !!(CFG.GOOGLE_MAPS_API_KEY || '').trim() && !state.googleFailed;
  }

  /** Maps JavaScript API を読む。読み終わるまで下敷きは白いまま（描かない）。 */
  function ensureGoogleMaps() {
    if (window.google && window.google.maps) return Promise.resolve();
    if (state.gmapsLoad) return state.gmapsLoad;
    var key = (CFG.GOOGLE_MAPS_API_KEY || '').trim();
    if (!key) return Promise.reject(new Error('API キーが設定されていません'));
    state.gmapsLoad = new Promise(function (resolve, reject) {
      var to = setTimeout(function () {
        reject(new Error('Google Maps の読み込みがタイムアウトしました'));
      }, 12000);
      window.__shakoGmapsReady = function () { clearTimeout(to); resolve(); };
      var s = document.createElement('script');
      // loading=async は Google の推奨。付けないと毎回コンソールに警告が出る
      s.src = 'https://maps.googleapis.com/maps/api/js?key='
            + encodeURIComponent(key)
            + '&callback=__shakoGmapsReady&language=ja&region=JP&v=weekly'
            + '&loading=async';
      s.async = true;
      s.onerror = function () {
        clearTimeout(to);
        reject(new Error('スクリプトの取得に失敗しました'));
      };
      document.head.appendChild(s);
    });
    return state.gmapsLoad;
  }

  /** Google の下敷きを選んだ時に呼ぶ。読み終わったら描き直すだけ。 */
  function activateGoogle() {
    ensureGoogleMaps().then(function () {
      if (state.map) state.map._render();
    }).catch(function (e) {
      googleFallback('Google 地図を読み込めませんでした。地理院タイルに切り替えます。');
      if (window.console) console.warn('[shako-map]', e && e.message);
    });
  }

  /* Google がキーを拒否した時に呼ばれる（リファラ制限外・請求無効・キー失効）。
   * スクリプト自体は読めているのでロードは成功扱いになり、地図だけがエラー表示に
   * なる。ここで地理院タイルへ落として作図を止めない（§12-a の既存方針）。 */
  window.gm_authFailure = function () {
    googleFallback('Google 地図を表示できないため、正射写真（地理院）に切り替えました'
                 + '（キーのリファラ制限・請求設定をご確認ください）');
  };

  /** Google を諦めて地理院へ戻す。選択肢からも外す。 */
  function googleFallback(msg) {
    if (state.googleFailed) return;
    state.googleFailed = true;
    buildUnderlayOptions();
    if (state.current && state.map) {
      var m = state.current.maps[state.kind];
      var u = underlayById(m.underlay);
      if (u && u.google) {
        setUnderlayChoice(u.kind === 'roadmap' ? 'gsi-pale' : 'gsi-ort');
      }
    }
    updateUnderlaySrc();
    hint(msg, 7000);
  }

  function showView(which) {
    /* 🔴 画面を切り替えたら、走っている解析の結果は捨ててダイアログも閉じる（§16-13）。
     * 「案件一覧の上に縮尺の3択が出て何も押せない」の直接原因がここだった。 */
    invalidateFillRuns();
    $('caseListView').hidden = which !== 'list';
    $('editorView').hidden = which !== 'editor';
  }

  /* ================= 案件一覧 ================= */

  function bindCaseList() {
    /* 🔒 2026-08-31 オーナー指示: 案件名を聞く prompt() は**廃止**。
       確認なしでそのまま編集画面へ入り、案件名は**空のまま**作る
       （上部バーの［案件名］欄でいつでも入れられる）。
       🔴 番号（§19-1）の自動採番は従来どおり Store.newCase() の中で1つ消費する。 */
    $('btnNewCase').addEventListener('click', function () {
      var c = Store.newCase('');
      c.name = '';                 // Store 側の既定（'無題の案件'）を使わず空で始める
      /* 🔴 §26-4-1 バグ修正: save() の戻り値を見ずに openCase していたため、
       * 保存領域が一杯だと保存されないまま editor へ進み、直後の load() が null を
       * 返して「この案件を読み込めませんでした」という誤ったエラーになっていた。
       * 失敗時は editor へ進まず、新規案件は作らなかったことにする（採番だけは
       * 消費するが、正典 §19-1 のとおり欠番は許容する）。
       * 🔴 §27-7③: save() は Promise になった（フォルダ運用ではファイルを書く）。 */
      Store.save(c).then(function (ok) {
        if (!ok) { alert(Store.lastSaveError()); return; }
        renderCaseList();
        // 🔒 §30-20: 新しい案件の時だけ「はじめに」を出す（fresh）
        openCase(c.id, { fresh: true });
      }, function (e) { alert((e && e.message) || Store.lastSaveError()); });
    });

    /* ---- 絞り込み（正典 §19-2 検索 / §19-3 タブ / §19-4 並び替え） ----
       どれも state に置くだけで案件データには書かない（保存しない） */
    $('clSearch').addEventListener('input', function () {
      state.listQuery = this.value;
      renderCaseList();
    });
    $('clSort').addEventListener('change', function () {
      state.listSort = this.value;
      renderCaseList();
    });
    document.querySelectorAll('#clTabs button').forEach(function (b) {
      b.addEventListener('click', function () {
        state.listTab = b.dataset.tab;
        document.querySelectorAll('#clTabs button').forEach(function (x) {
          x.classList.toggle('is-active', x === b);
        });
        renderCaseList();
      });
    });

    /* ---- 案件フォルダ（🔒 §27-12-2 の表）----
       ゲートの3つのボタンと、本体の上段2つ。非対応ブラウザではゲートに
       「Chrome または Edge で開いてください」だけが出て、どのボタンも出ない。 */
    $('btnGatePick').addEventListener('click', pickFolder);      // ①
    $('btnGateOther').addEventListener('click', pickFolder);     // ②の小さい方
    $('btnOtherDir').addEventListener('click', pickFolder);      // ③［別のフォルダを開く］
    /* ②［開く］。🔴 権限の要求はユーザー操作の中でしか通らない
       （§27-4 の「避けられない摩擦」・Chrome の決まり） */
    $('btnGateOpen').addEventListener('click', function () {
      FSave.requestAccess().then(function (ok) {
        if (!ok) { alert('この案件フォルダを使う許可が得られませんでした'); return; }
        return openFolderAndRender();
      }, function (e) {
        renderTop();
        alert('この案件フォルダを開けませんでした: ' + ((e && e.message) || e));
      });
    });
    /* ［再読み込み］。🔴 自動監視はしない（§27-7①）。他のパソコン・エクスプローラで
       フォルダを触った時に、押せば一覧が今の中身に揃う */
    $('btnReloadDir').addEventListener('click', function () {
      Store.refreshIndex().then(renderTop, function (e) {
        renderTop();
        alert('この案件フォルダを読み直せませんでした: ' + ((e && e.message) || e));
      });
    });

    $('btnImport').addEventListener('click', function () { $('fileImport').click(); });
    $('fileImport').addEventListener('change', function (e) {
      var f = e.target.files && e.target.files[0];
      if (!f) return;
      Store.fromFile(f).then(function (c) {
        e.target.value = '';
        afterCaseOp();          // 🔒 §27: 索引と画面を引き直す
        openCase(c.id);
      }).catch(function (err) {
        e.target.value = '';
        alert(err.message);
      });
    });
  }

  /* ================= TOP ページの状態機械（🔒 §27-12-2） =================
   * ①フォルダがまだ無い ②覚えているがまだ開いていない ③開いている ＋ 非対応。
   * ①②非対応 ＝ ゲート1枚だけ（一覧も新規も読み込みも出さない）。 */

  /** ゲートを1枚出す。which は 'none' | 'locked' | 'unsupported' */
  function showGate(which) {
    $('clMain').hidden = true;
    $('clGate').hidden = false;
    var pick = $('btnGatePick'), open = $('btnGateOpen'), other = $('btnGateOther');
    pick.hidden = open.hidden = other.hidden = true;
    if (which === 'unsupported') {
      $('gateTitle').textContent = 'このアプリは Chrome または Edge で開いてください';
      $('gateText').textContent = '案件をフォルダにファイルで保存する機能を使うため、'
        + 'Chrome または Edge が必要です。';
      return;
    }
    if (which === 'locked') {
      $('gateTitle').textContent = '案件フォルダ「' + FSave.dirName() + '」を開く';
      $('gateText').textContent = '［開く］を押すと、このフォルダの案件が一覧に出ます。';
      open.hidden = false;
      other.hidden = false;
      return;
    }
    // ①（初回）
    $('gateTitle').textContent = '案件を保存するフォルダを選んでください';
    $('gateText').textContent = 'おすすめ: ドキュメントの中に「車庫証明」というフォルダを'
      + '作って選びます（ダイアログの中で新しいフォルダを作れます）。'
      + '案件は1件1ファイルでこのフォルダに保存されます。';
    pick.hidden = false;
  }

  /** ③ 本体（案件フォルダを開いている時） */
  function showMain() {
    $('clGate').hidden = true;
    $('clMain').hidden = false;
    var el = $('clFolderName');
    el.textContent = FSave.dirName();
    el.title = '案件ファイル（.shako）・PDF・PNG はこのフォルダに入ります。'
             + '同じ名前のファイルは上書きされます';
    renderCaseList();
  }

  /**
   * TOP ページを今の状態に合わせて出し直す（🔒 §27-12-2）。
   * @returns Promise<'none'|'locked'|'open'|'unsupported'>
   * 🔴 案件一覧（renderCaseList）は③の中でだけ動く。
   */
  function renderTop() {
    if (!FSave.supported()) {
      showGate('unsupported');
      return Promise.resolve('unsupported');
    }
    return Store.folderState().then(function (st) {
      if (st === 'open') showMain(); else showGate(st);
      return st;
    }, function () {
      showGate('none');
      return 'none';
    });
  }

  /**
   * ［フォルダを選ぶ］［別のフォルダを選ぶ］［別のフォルダを開く］の共通処理。
   * 🔒 §27-12-4: **切り替えるだけ**。移動も複製もしないので確認も出さない
   *    （フォルダ選択ダイアログ自体が確認になっている）。
   */
  function pickFolder() {
    return FSave.pick().then(openFolderAndRender, function (e) {
      // ダイアログのキャンセル（AbortError）は何も言わない
      if (e && e.name === 'AbortError') return;
      return renderTop().then(function () {
        alert('フォルダを選べませんでした: ' + ((e && e.message) || e));
      });
    });
  }

  /**
   * 案件フォルダを開いて画面を引き直す（フォルダを選んだ直後・［開く］の直後）。
   * 🔴 §27-12-9: 旧データの引っ越しは**無い**。成功なら黙って③を出すだけ。
   */
  function openFolderAndRender() {
    return Store.openFolder().then(function () {
      return renderTop();
    }, function (e) {
      return renderTop().then(function () {
        alert('この案件フォルダを開けませんでした: ' + ((e && e.message) || e));
      });
    });
  }

  /* 🔴 2026-08-31 以降**未使用**（［＋ 新しい案件］の prompt() を廃止して
     案件名を空で作るようにしたため）。将来「日付で仮の名前を付ける」に戻す時の
     ために残してある。 */
  function defaultCaseName() {
    var d = new Date();
    return d.getFullYear() + '-'
      + String(d.getMonth() + 1).padStart(2, '0') + '-'
      + String(d.getDate()).padStart(2, '0') + ' の案件';
  }

  /** 絞り込みの当たり判定（正典 §19-2）。番号・案件名・住所（入力／正規化）の部分一致 */
  function matchQuery(it, q) {
    if (!q) return true;
    var hay = (it.caseNo + ' ' + it.name + ' ' + it.addrText).toLowerCase();
    return hay.indexOf(q) >= 0;
  }

  /** 並び替え（正典 §19-4）。番号順は新しい番号が上・番号なしは最後 */
  function sortCaseItems(items, how) {
    var byUpdated = function (a, b) {
      return (b.updated || '').localeCompare(a.updated || '');
    };
    return items.sort(function (a, b) {
      if (how === 'created') return (b.created || '').localeCompare(a.created || '');
      if (how === 'caseNo') {
        if (!a.caseNo && !b.caseNo) return byUpdated(a, b);
        if (!a.caseNo) return 1;
        if (!b.caseNo) return -1;
        if (a.caseNo === b.caseNo) return byUpdated(a, b);
        return b.caseNo.localeCompare(a.caseNo);
      }
      return byUpdated(a, b);          // 既定＝更新が新しい順
    });
  }

  function renderCaseList() {
    var all = Store.list();
    /* タブ（§19-3）で集合を選び、その中を検索（§19-2）で絞り、並び替える（§19-4）。
       🔴 順序が逆だと「完了タブで検索すると進行中が出る」ことになる */
    var items = all.filter(function (it) {
      if (state.listTab === 'active' && it.done) return false;
      if (state.listTab === 'done' && !it.done) return false;
      return true;
    });
    var q = (state.listQuery || '').trim().toLowerCase();
    items = sortCaseItems(items.filter(function (it) { return matchQuery(it, q); }),
                          state.listSort);

    /* 同じ番号が2件以上ある物を数える（警告色を出すだけ・止めない・§19-1）。
       🔴 数えるのは**全件**。タブで隠れている相手とぶつかっていても気づけるように */
    var noCount = {};
    all.forEach(function (it) {
      if (it.caseNo) noCount[it.caseNo] = (noCount[it.caseNo] || 0) + 1;
    });

    var ul = $('caseList');
    ul.innerHTML = '';
    var empty = $('caseListEmpty');
    empty.hidden = items.length > 0;
    empty.textContent = all.length
      ? '条件に合う案件がありません。タブや検索欄を見直してください。'
      : '案件がまだありません。「＋ 新しい案件」から始めてください。';

    items.forEach(function (it) {
      var li = document.createElement('li');
      li.className = 'cl-item' + (it.done ? ' is-done' : '');

      var main = document.createElement('div');
      main.className = 'cl-item-main';
      main.innerHTML =
        '<div class="cl-item-name">' +
          '<span class="cl-no"></span><span class="cl-nm"></span>' +
        '</div>' +
        '<div class="cl-item-meta">' +
          '<span class="' + (it.hasHome ? 'flag' : 'flag-off') + '">'
            + (it.hasHome ? '✓' : '−') + ' 使用の本拠</span>　' +
          '<span class="' + (it.hasLot ? 'flag' : 'flag-off') + '">'
            + (it.hasLot ? '✓' : '−') + ' 駐車場</span>　' +
          '図形 ' + it.objectCount + ' 個　更新 ' + fmtDate(it.updated) +
        '</div>';
      /* 🔒 2026-08-31: 新規は案件名が**空**で始まる（prompt を廃止）ので、
         一覧の行が真っ白にならないよう見た目だけ差し替える。
         🔴 これは表示だけ。データ側（it.name）は空のまま・判定にも使わない（§26-2 注意②） */
      var nmEl = main.querySelector('.cl-nm');
      nmEl.textContent = it.name || '（名称未設定）';
      if (!it.name) nmEl.classList.add('is-empty');
      var noEl = main.querySelector('.cl-no');
      noEl.textContent = it.caseNo;                 // 番号なしの旧案件は空のまま
      if (it.caseNo && noCount[it.caseNo] > 1) {    // §19-1 重複は警告色＋説明だけ
        noEl.className = 'cl-no is-dup';
        noEl.title = '同じ番号の案件があります';
      }
      main.addEventListener('click', function () { openCase(it.id); });
      li.appendChild(main);

      li.appendChild(mkBtn('開く', 'primary', function () { openCase(it.id); }));
      /* 🔒 §27-5-a の積み残しをここで是正。完了・複製・名前・削除は
       * **保存の失敗を握り潰さない**（満杯／フォルダに書けない を必ず知らせる）。
       * 🔴 §27-7②: 保存先がファイルになったのでどれも Promise を返す。 */
      /* 🔒 §19-3: 完了の指定は一覧の行とエディタのヘッダの2か所。ここは行の方 */
      li.appendChild(mkBtn(it.done ? '作成中に戻す' : '完了にする', '', function () {
        Store.setDone(it.id, !it.done).then(afterCaseOp, caseOpFailed);
      }));
      li.appendChild(mkBtn('複製', '', function () {
        Store.duplicate(it.id).then(afterCaseOp, caseOpFailed);
      }));
      li.appendChild(mkBtn('名前', '', function () {
        var n = prompt('新しい案件名', it.name);
        if (n === null) return;
        Store.rename(it.id, n.trim() || it.name).then(afterCaseOp, caseOpFailed);
      }));
      li.appendChild(mkBtn('削除', '', function () {
        if (!confirm('「' + (it.name || it.caseNo || '名称未設定の案件')
                     + '」を削除します（案件フォルダのファイルも消えます）。'
                     + '元に戻せません。よろしいですか？')) return;
        Store.remove(it.id).then(function (ok) {
          if (!ok) { caseOpFailed(new Error(Store.lastSaveError())); return; }
          // 取り込んだ画像（端末内・IndexedDB）も一緒に消す（正典 §16-3）
          if (window.ImgLay) ImgLay.deleteCase(it.id);
          afterCaseOp();
        }, caseOpFailed);
      }));
      ul.appendChild(li);
    });
    /* 🔒 §27-12: 案件の本体はフォルダのファイルなので、ここに容量の表示は無い
       （案件一覧の使用率表示は廃止。上限そのものが無くなった）。 */
  }

  /** 一覧の行の操作が成功した後（🔒 §27-12: TOP ページごと引き直す）。
      フォルダが開いたままなら本体を引き直すだけになる（folderState が 'open' を即返す） */
  function afterCaseOp() {
    return renderTop();
  }

  /** 一覧の行の操作が失敗した時（🔒 §27-5-a: 無言で戻さない） */
  function caseOpFailed(e) {
    afterCaseOp();
    alert((e && e.message) || Store.lastSaveError());
  }

  function mkBtn(label, cls, fn) {
    var b = document.createElement('button');
    b.textContent = label;
    if (cls) b.className = cls;
    b.addEventListener('click', fn);
    return b;
  }

  function fmtDate(iso) {
    if (!iso) return '—';
    var d = new Date(iso);
    return d.getFullYear() + '/' + (d.getMonth() + 1) + '/' + d.getDate()
      + ' ' + String(d.getHours()).padStart(2, '0') + ':'
      + String(d.getMinutes()).padStart(2, '0');
  }

  /* ================= エディタ ================= */

  /**
   * 幅矢印の「幅」欄（正典 §4-6）。🔒 §18-l で欄が2か所になったので必ずここを通す。
   * from='side'（右パネル）/'road'（ガイダンス⑨の道幅）/'gate'（ガイダンス⑩の出入口幅）
   * … 打っている側は書き換えない（カーソルが飛ぶ）。
   * 値が入っていれば矢印は**手入力のラベル確定済み**で置かれる。
   * 🔒 §25-5（§4-6 再改定）: 空欄で引いた矢印は**地図から計算した実距離**を出す
   *    （§22-z の「ラベルなし」は撤回。手入力があればそちらが優先される）。
   * 🔒 §18-v: 欄は3か所あるが**値は1つ**。⑧で入れた道幅が⑨の出入口幅に化けないよう、
   *    ⑧⑨へ入った時に空にして例示（プレースホルダ）だけを見せる。
   */
  /**
   * 🔒 §30-28-2 6: 幅の矢印は**道具メニューにも**配置図⑤⑥と同じ2択で出す。
   * 🔴 欄もトグルも3か所あるが**値は1つ**（state.editor.arrowWidth／state.arrowMode）。
   *    欄・トグルの一覧はこの表1か所（増やす時はここだけ足す＝NUM_START_FIELDS と同じ作法）。
   *      'side' … 道具メニュー #sideArrowMode / #arrowWidth
   *      'road' … 配置図⑤ #sgRoadMode / #sgRoadW
   *      'gate' … 配置図⑥ #sgGateMode / #sgGateW
   * 🔒 §30-29-4 1: 上部バー2行目の小さな窓（#arrowPick）の欄もこの表に足した。
   *      'pick' … 上部バー2行目の窓 #arrowPickMode / #apArrowW
   *    🔴 この欄だけ `noDisable: true`（窓は「幅を打ってから［幅を入力］を押す」
   *       作法なので、開いている間は自動の時でも打てる）。値は他と同じ1つ。
   */
  var ARROW_FIELDS = [
    { from: 'side', box: 'sideArrowMode', inp: 'arrowWidth' },
    { from: 'road', box: 'sgRoadMode', inp: 'sgRoadW' },
    { from: 'gate', box: 'sgGateMode', inp: 'sgGateW' },
    { from: 'pick', box: 'arrowPickMode', inp: 'apArrowW', noDisable: true }
  ];

  function setArrowWidth(v, from) {
    ARROW_FIELDS.forEach(function (f) {
      if (f.from === from) return;          // 打っている本人の欄は書き換えない
      var el = $(f.inp);
      if (el) el.value = v;
    });
    if (state.editor) state.editor.arrowWidth = v;
  }

  /**
   * 幅の決め方（🔒 §30-18-4・2026-09-13 オーナー指示）。
   * 「自動入力（地図の尺度から計測）」／「道幅入力（出入口の幅を入力）」の2択。
   * 🔴 **値の持ち方は今の arrowWidth のまま**（空＝自動・§25-5）。このトグルは
   *    見せ方だけで、新しい保存データは持たない（state.arrowMode＝画面の状態）。
   * 🔴 欄は⑤⑥で2つあるが値は1つ（§18-l）なので、モードも1つで両方を揃える。
   */
  function setArrowMode(m, from) {
    state.arrowMode = (m === 'manual') ? 'manual' : 'auto';
    if (state.arrowMode === 'auto') setArrowWidth('');   // 自動＝欄は空（§25-5）
    /* 🔒 §30-29-4 2: 「幅を入力」で引いた矢印には `noAuto` を付ける（＝欄が空なら
     * 何も出さない）。editor は state を見に行かないので、arrowWidth と同じ作法で
     * ここから写す（🔴 出どころは state.arrowMode 1か所・editor 側は控え）。 */
    if (state.editor) state.editor.arrowManual = (state.arrowMode === 'manual');
    syncArrowModeUI(from);
  }

  /** 4つのトグルと4つの欄を、いまのモードに合わせる（見た目だけ・🔒 §30-28-2 6） */
  function syncArrowModeUI(from) {
    var manual = (state.arrowMode === 'manual');
    ARROW_FIELDS.forEach(function (f) {
      var box = $(f.box), inp = $(f.inp);
      if (box) {
        box.querySelectorAll('input[type="radio"]').forEach(function (r) {
          r.checked = (r.value === (manual ? 'manual' : 'auto'));
          var row = r.closest('.sg-seg-i');
          if (row) row.classList.toggle('is-on', r.checked);
        });
        /* 🔒 §30-29-4 1: 窓の2つのボタンにも「いま選んでいる方」を出す
         * （ラジオではないので data-mode で見る＝表示文字で分岐しない）。 */
        box.querySelectorAll('[data-mode]').forEach(function (b) {
          b.classList.toggle('is-on', b.dataset.mode === (manual ? 'manual' : 'auto'));
        });
      }
      // 🔒 §30-29-4 1: 窓の欄（noDisable）は開いている間いつでも打てる
      if (inp && !f.noDisable) inp.disabled = !manual;
    });
    // 「幅を入力」を選んだ本人の欄には、そのまま打てるよう焦点を移す
    if (manual && from) {
      var me = ARROW_FIELDS.filter(function (f) { return f.from === from; })[0];
      var el = me && $(me.inp);
      if (el) el.focus();
    }
  }

  /**
   * 枠の番号の開始値（🔒 §30-18-2 → 🔒 §30-25-8 で**3か所**に）。欄は
   *   'side' … 上部バー2行目 #tbNumStart（🔒 §30-29-1 1: 旧・道具メニュー #numStart）
   *   'sg'   … 配置図③ #sgNumStart
   *   'sz'   … 所在図④ #sgNumStart4
   * だが**値は1つ**（state.editor.numberStart＝案件の numberCounter）。
   * 幅矢印の setArrowWidth と同じ作法（どれを変えても3つが揃う）。
   * 🔴 欄の一覧はこの表1か所（増やす時はここだけ足す）。
   */
  var NUM_START_FIELDS = [
    { from: 'side', id: 'tbNumStart' },     // 🔒 §30-29-1 1: 上部バー2行目
    { from: 'sg', id: 'sgNumStart' },
    { from: 'sz', id: 'sgNumStart4' }     // 🔒 §30-25-8: 所在図④
  ];

  function setNumberStart(v, from) {
    var n = parseInt(v, 10);
    if (isNaN(n)) return;
    if (state.editor) state.editor.numberStart = n;
    if (state.current) state.current.numberCounter = n;
    syncNumberStartUI(n, from);
  }

  /** 3つの欄に同じ値を映す（打っている本人の欄は書き換えない） */
  function syncNumberStartUI(n, from) {
    NUM_START_FIELDS.forEach(function (f) {
      if (f.from === from) return;
      var el = $(f.id);
      if (el) el.value = n;
    });
  }

  /**
   * 住所の欄（🔒 §28-2 → §30-28-2 1 → 🔒 §30-39-2 3 で**地点ごとに2か所ずつ**）。
   *   home … 'sgAddrHome'（ガイダンス①）／'sideAddrHome'（道具メニュー）
   *   lot  … 'sgAddrLot' （ガイダンス①）／'sideAddrLot' （道具メニュー）
   * 🔒 §30-39-1 1: 上部バーの欄（#addrHome）は**削除**した＝住所の欄は左メニューだけ。
   * 🔴 同じ地点の欄は**値が1つ**（どちらを打っても揃う＝ NUM_START_FIELDS と同じ作法）。
   * 🔴 欄の一覧はこの表1か所（増やす時はここだけ足す）。
   */
  var ADDR_FIELDS = {
    home: ['sgAddrHome', 'sideAddrHome'],
    lot:  ['sgAddrLot',  'sideAddrLot']
  };

  /**
   * その地点の［検索］（🔒 §30-39-2 3: **4つ**＝地点ごとに2つ）。
   * 🔴 配線（click）も止め方（searchBusy）もこの表1か所から回す。
   */
  var SEARCH_BTNS = {
    home: ['sgSearchHome', 'sideSearchHome'],
    lot:  ['sgSearchLot',  'sideSearchLot']
  };

  /** その地点の欄へ同じ値を写す（from ＝打っている本人の欄・null なら全部へ） */
  function syncAddr(key, v, from) {
    (ADDR_FIELDS[key] || []).forEach(function (id) {
      if (id === from) return;          // 打っている本人の欄は書き換えない
      var el = $(id);
      if (el) el.value = v;
    });
  }

  /**
   * 取り込み画像の濃さ（🔒 §22-ad・2026-08-28 オーナー指示）。
   * 欄は3か所（'top'=上部バー / 'side'=右パネル / 'sg'=ガイダンス⑤）あるが**値は1つ**。
   * 幅矢印の setArrowWidth と同じ作法で、動かしている本人の欄だけは書き換えない
   * （つまみを掴んだまま値を戻されるとガクつくため）。
   * v は 10〜100 の文字列/数値（%）。
   */
  function setImgOpacity(v, from) {
    var pct = syncImgOpacityUI(v, from);
    if (state.imglay) state.imglay.update({ opacity: pct / 100 });
  }

  /** 欄の見た目だけをそろえる（画像には触らない）。戻り値は丸めた %。
   *  🔒 §29 Step 7: 📷ウィザードの欄（#wzOpacity）は全廃したので3か所。 */
  function syncImgOpacityUI(v, from) {
    var pct = Math.max(10, Math.min(100, Math.round(Number(v) || 0)));
    if (from !== 'top') $('imgOpacityTop').value = pct;
    if (from !== 'side') $('imgOpacity').value = pct;
    if (from !== 'sg') $('sgImgOpacity').value = pct;
    $('imgOpacityTopVal').textContent = pct + '%';
    $('imgOpacityVal').textContent = pct + '%';
    $('sgImgOpacityVal').textContent = pct + '%';
    /* 🔒 §30-12-4 2: 配置図①の［自分で撮った写真・図面を使う］の
     * 「いま: 写真あり・濃さ 70%」も同じ値で（閉じていても見える）。 */
    if (state.nav) sgMoreSync();
    return pct;
  }

  /* ================= 所在図の設定盤（🔒 2026-09-03 オーナー指示） =================
   * 6項目を1枚の盤に並べ、**全部を案件データに保存する**（画面だけの状態を無くす）。
   *   5段階 … 目標物 lmLevel ／ 建物 bldgLevel ／ 道路 roadLevel
   *   2択   … 川・山 nature ／ 道路の描き方 roadStyle
   *   （🔒 §28-14 ①-4: 「主役の印」はガイダンス①へ移した＝この盤には無い）
   *
   * 🔒 **新規案件は全項目「標準」で始める**（値は store.js の newCase が持つ）。
   * 🔴 **既存案件は保存値をそのまま使う**（store.js の migrate が欠けた物だけ補う）。
   *    ここで既定へ丸めてはいけない＝「開いただけで図が変わる」事故になる。
   *    特に bldgLevel は旧案件に 1（なし）が保存済みなので、新規既定が3でも1のまま。
   * 🔴 段は 1〜5 の**数字**で扱う。表示文字（「標準」等）で識別しない（§26-2 注意②）。 */
  var GRADE_STD = 3;                        // 「標準」の段（全項目共通）
  /* 🔒 §30-40-2 4: 添字 0 ＝「自動」（名前の8分類だけが持てる段）。
   * 目標物・建物・道路の行は 1〜5 のままなので 0 を引くことはない。 */
  var GRADE_JA = ['自動', 'なし', '主役の周りだけ', '標準', '多め', '全部'];
  /* 🔒 §30-40-2: 「自動」の段の数字と決め方（境目の件数・決まる段）は
   * shozaizu.js の NAME_AUTO が唯一の出どころ。画面の段も説明の文言も
   * **この実値から**組む（値を文に写さない）。
   * 🔴 読めない時（shozaizu.js が無い）の保険だけ {} にしておく。 */
  var NAME_AUTO = (window.Shozaizu && Shozaizu.NAME_AUTO) || {};
  var NAME_AUTO_LV = Number(NAME_AUTO.level) || 0;

  /* 5段階の項目。key＝案件データの項目名／names＝画面のラジオの name。
   * 🔴 names を配列で持つのは「同じ値の部品が2か所に出る」時のため（§18-r-4）。
   * 🔒 §28-4（2026-09-07 Step 2）: 誘導③の目標物（navLmLv）は無くなった。
   *    ③は設定盤そのものを**部品ごと左面へ移す**方式にしたので、
   *    画面上の部品は常に1組だけ＝2か所を同期する必要がそもそも無い。
   *    （配列の仕組みは残す。将来また2か所に出す時のため） */
  var SZ_GRADES = {
    lm:   { key: 'lmLevel',   names: ['szLmLv'],   ja: '目標物' },
    bldg: { key: 'bldgLevel', names: ['szBldgLv'], ja: '建物' },
    road: { key: 'roadLevel', names: ['szRoadLv'], ja: '道路' },
    /* 🔒 2026-09-03（後半）: 名称の6分類（§23-5 / §22-ak-1 ⑦〜⑫）。
     * osm ＝ OSM の分類 id（osm.js CATS）。shozaizu.js に nameLevels として渡す
     * 🔴 「他の目印」は OSM の 'public'（amenity 全部）。地理院由来の目標物は
     *    上の lm（目標物）が担当なので**二重に出さない**（shozaizu.js 側で地理院を見ない）。 */
    nmCross:  { key: 'nameCrossLevel',  names: ['szNmCross'],  ja: '交差点名', osm: 'crossing' },
    nmShop:   { key: 'nameShopLevel',   names: ['szNmShop'],   ja: 'お店',     osm: 'shop' },
    nmOffice: { key: 'nameOfficeLevel', names: ['szNmOffice'], ja: '会社名',   osm: 'office' },
    nmBus:    { key: 'nameBusLevel',    names: ['szNmBus'],    ja: 'バス停',   osm: 'bus' },
    nmRoad:   { key: 'nameRoadLevel',   names: ['szNmRoad'],   ja: '道路名',   osm: 'road' },
    nmPoi:    { key: 'namePoiLevel',    names: ['szNmPoi'],    ja: '他の目印', osm: 'public' },
    /* 🔒 §30-21-2（2026-09-13）: 無料で取れる名前を全部取る＝新2分類。
     * 施設・公園（変電所・公園・団地・駅・川…）と 建物名（棟名を含む）。
     * 設定盤は 11項目 → 13項目（🔒 §30-21-4 5）→ 14項目（🔒 §30-22-2 3）。 */
    nmFacility: { key: 'nameFacilityLevel', names: ['szNmFacility'],
                  ja: '施設・公園', osm: 'facility' },
    nmBuilding: { key: 'nameBuildingLevel', names: ['szNmBuilding'],
                  ja: '建物名',     osm: 'building' }
  };

  /* 2択の項目。el＝チェックボックスの id／on＝checked の時の値／off＝未 checked の値。
   * bool:true は値がそのまま真偽（川・山）。
   * 🔴 szNature の意味は従来のまま（checked＝入れる）。見た目だけトグルにした（§18-ak の教訓） */
  /* 🔒 §28-14 ①-4（2026-09-07）: 「主役の印」（markStyle）はこの表から**外した**。
   * 形と色はガイダンス①で地点ごとに選ぶ（points[key].mark ＝ markOf/sgSetMark）。
   * 同じ値が2か所に出ない（§18-r-4）。c.markStyle は旧案件の後方互換で残る。 */
  var SZ_TOGGLES = {
    nature: { key: 'nature',    el: 'szNature',     bool: true,                ja: '川・山' },
    road:   { key: 'roadStyle', el: 'szRoadBand',   on: 'band',   off: 'line', ja: '道路の線' }
  };

  /* 🔒 §30-22-2 2（2026-09-13 オーナー指示）: **段数が5でない項目**の表。
   * いまは「名前の位置」（近く／標準／離す＝1〜3）だけ。作法は SZ_GRADES と同じ
   *   ①案件データが真実 ②画面のラジオを合わせる ③変えたらその場で作り直す
   * 🔴 段は数字で持ち、表示文字では識別しない（§26-2 注意②）。
   * 🔴 既定値は Store.SZ_STD.nameGap（🔒 §30-31-2 ＝1 近く）1か所。 */
  var SZ_PICKS = {
    gap: { key: 'nameGap', name: 'szNameGap', max: 3, ja: '名前の位置' }
  };

  /** いま選ばれている段（案件があれば案件の値が真実・🔒 §30-22-2 2） */
  function pickValue(which) {
    var g = SZ_PICKS[which], c = state.current, v;
    if (c) {
      v = Number(c[g.key]);
      if (v >= 1 && v <= g.max) return Math.round(v);
    }
    var el = document.querySelector('input[name="' + g.name + '"]:checked');
    v = el ? Number(el.value) : Number(SZ_STD[g.key]);
    return (v >= 1 && v <= g.max) ? Math.round(v) : Number(SZ_STD[g.key]);
  }

  /** 画面のラジオを段に合わせる（🔒 §30-22-2 2） */
  function syncPickPick(which, v) {
    var g = SZ_PICKS[which], n = Number(v);
    if (!(n >= 1 && n <= g.max)) n = Number(SZ_STD[g.key]);
    var el = document.querySelector('input[name="' + g.name + '"][value="' + n + '"]');
    if (el) el.checked = true;
  }

  /* 「標準」の値一式。［標準の設定で作る］（タスク3）と、案件がまだ無い時の既定に使う。
   * 🔒 §22-ao-②: 標準値の定義は store.js の Store.SZ_STD の**1か所だけ**に統合した
   *    （以前はここで GRADE_STD から組み立てていて、newCase / migrate と定義が3か所に
   *    分かれていた）。ここは Store.SZ_STD をそのまま指す。 */
  var SZ_STD = Store.SZ_STD;

  /** いま設定盤で選ばれている名称8分類の段（shozaizu.js の nameLevels の形にする） */
  function nameLevelsNow() {
    var out = {};
    Object.keys(SZ_GRADES).forEach(function (k) {
      var g = SZ_GRADES[k];
      if (g.osm) out[g.osm] = gradeValue(k);
    });
    return out;
  }

  /**
   * 🔒 §30-21-5 4（2026-09-13 Fable 裁定）: 設定盤・名称8分類（osm を持つ行）の
   * 段の説明文言を、shozaizu.js の実値（Shozaizu.NAME_LEVELS）から**ここ1か所**で組む。
   * 🔴 旧 HTML の固定文字（「3件まで」「8件まで」「20件まで」）は NAME_LEVELS の
   *    実値（1/3/8）とズレていた。行ごとに違う文言を書かない（表示の文言で分岐しない・
   *    注意②と同じ考え方）＝どの行も段の数字だけを見てこの1関数で組み立てる。
   */
  /* 🔒 §30-40-2 4: 添字 0 ＝「自動」（名前の8分類だけの6つ目の段） */
  var NAME_LEVEL_WORD = ['自動', 'なし', '少なめ', '標準', '多め', '全部'];
  function nameLevelTitle(level) {
    var n = Number(level);
    var word = NAME_LEVEL_WORD[n] || '';
    /* 🔒 §30-40-2 4: 「自動」の説明も**実値から組む**（NAME_AUTO の値を文に写さない）。
     * ＝「枠の中の候補が allMax 件以下の分類は allLevel の段・
     *    それより多い分類は elseLevel の段」。 */
    if (n === NAME_AUTO_LV) {
      return word + '（枠に' + NAME_AUTO.allMax + '件以下の分類は'
           + (NAME_LEVEL_WORD[NAME_AUTO.allLevel] || '')
           + '・それより多い分類は'
           + (NAME_LEVEL_WORD[NAME_AUTO.elseLevel] || '') + '）';
    }
    var cfg = window.Shozaizu && Shozaizu.NAME_LEVELS && Shozaizu.NAME_LEVELS[n];
    if (!cfg || !cfg.count) return word;                 // なし（0件）はそのまま
    if (cfg.count === Infinity) return word + '（上限なし）';
    return word + '（' + cfg.count + '件' + (n === 2 ? '・近く' : '') + '）';
  }

  /** ガイダンス③の案内文に足す「自動」の一言（🔒 §30-40-2 6・文言も実値から組む） */
  function nameAutoNote() {
    return '名前の分類の「自動」は、枠に' + NAME_AUTO.allMax + '件以下の分類を'
         + (NAME_LEVEL_WORD[NAME_AUTO.allLevel] || '') + '出し、多い分類は'
         + (NAME_LEVEL_WORD[NAME_AUTO.elseLevel] || '') + 'の量にします。';
  }

  /** 設定盤・名称8分類の全行・全段に nameLevelTitle の title を付け直す（🔒 §30-21-5 4）。
   * 複製ではなく部品は1組だけ（§28-4）なので、ここで付ければどちらの置き場所でも効く。 */
  function syncNameLevelTitles() {
    Object.keys(SZ_GRADES).forEach(function (k) {
      var g = SZ_GRADES[k];
      if (!g.osm) return;
      g.names.forEach(function (name) {
        // 🔒 §30-40-2 1: 名前の行は「自動」（gradeMin＝0）から
        for (var lv = gradeMin(k); lv <= 5; lv++) {
          var input = document.querySelector('input[name="' + name + '"][value="' + lv + '"]');
          if (!input) continue;
          var t = nameLevelTitle(lv);
          input.title = t;
          var label = document.querySelector('label[for="' + input.id + '"]');
          if (label) label.title = t;
        }
      });
    });
  }

  /* 🔒 §18-r: 段 → 実際に採る施設の件数（添字＝段）。
   * 厳選（近さ＋格・pickLandmarks）は**そのまま**で、件数だけを段で変える。
   * 段5「全部」は Infinity＝件数の上限も 500m の足切りも掛けない（shozaizu.js 側で分岐）。 */
  var LM_COUNT = [0, 0, 2, 4, 12, Infinity];

  // 🙋 仮値: この件数を超えたら生成前に確認する（実機目視で確定・§23-10）
  var BLDG_CONFIRM_N = 1000;
  /* 🙋 仮値: 道路も段5「全部」で間引きが外れるので、同じ作法で確認する（2026-09-03）。
   * 従来の自動間引きの上限 MAX_ROADS 2200 より少し上に置いてある。 */
  var ROAD_CONFIRM_N = 2500;

  /**
   * その行で選べる段の下限（🔒 §30-40-2 1）。
   * 名前の8分類（＝ osm を持つ行）だけが6つ目の「自動」（NAME_AUTO_LV）を持つ。
   * 目標物・建物・道路は従来どおり 1〜5。
   * 🔴 判定は行の定義（osm の有無）で行う。表示文字では分岐しない（§26-2 注意②）。
   */
  function gradeMin(which) {
    var g = SZ_GRADES[which];
    return (g && g.osm) ? NAME_AUTO_LV : 1;
  }

  /** ラジオ等の値を、その行で選べる段にそろえる（🔒 §30-40-2 1: 0 を捨てない） */
  function gradeClamp(which, v) {
    var n = Math.round(Number(v));
    if (!isFinite(n)) return GRADE_STD;
    return Math.max(gradeMin(which), Math.min(5, n));
  }

  /** いま選ばれている段（案件があれば**案件の値が真実**。案件が無い時だけ画面のラジオ） */
  function gradeValue(which) {
    var g = SZ_GRADES[which], c = state.current, lv, min = gradeMin(which);
    if (c) {
      lv = Number(c[g.key]);
      if (lv >= min && lv <= 5) return Math.round(lv);
    }
    var v = document.querySelector('input[name="' + g.names[0] + '"]:checked');
    lv = v ? Number(v.value) : GRADE_STD;
    return (lv >= min && lv <= 5) ? Math.round(lv) : GRADE_STD;
  }

  /** 画面のラジオを段に合わせる（同じ項目が2か所にあれば両方そろえる） */
  function syncGradePick(which, lv) {
    var g = SZ_GRADES[which], n = Number(lv);
    // 🔒 §30-40-2 4: 名前の行は「自動」（0）も合わせる（gradeMin が下限）
    if (!(n >= gradeMin(which) && n <= 5)) n = GRADE_STD;
    g.names.forEach(function (name) {
      var el = document.querySelector('input[name="' + name + '"][value="' + n + '"]');
      if (el) el.checked = true;
    });
  }

  /** いま選ばれている2択の値（案件があれば案件の値が真実） */
  function toggleValue(which) {
    var t = SZ_TOGGLES[which], c = state.current, box = $(t.el);
    if (t.bool) {
      if (c && c[t.key] !== undefined && c[t.key] !== null) return !!c[t.key];
      return box ? box.checked : !!SZ_STD[t.key];
    }
    if (c && c[t.key]) return (c[t.key] === t.on) ? t.on : t.off;
    if (box) return box.checked ? t.on : t.off;
    return SZ_STD[t.key];
  }

  /** 画面のトグルを値に合わせる（案件を開いた時・生成した時） */
  function syncTogglePick(which, v) {
    var t = SZ_TOGGLES[which], box = $(t.el);
    if (!box) return;
    box.checked = t.bool ? !!v : (v === t.on);
  }

  /**
   * 🔒 §22-ak-3（裁定）③: 生成結果は**1行に圧縮して残す**（件数は実用情報なので消さない）。
   * 後半の6項目で高さが足りなくなったため、CSS で1行に詰めて溢れた分は…にする。
   * 🔴 情報は捨てない ―― 全文は title に入れて、指を置けば読めるようにしてある。
   */
  function setSzResult(msg) {
    var el = $('szResult');
    if (!el) return;
    el.textContent = msg || '';
    if (msg) el.title = msg; else el.removeAttribute('title');
  }

  /**
   * 🔒 §22-as（2026-09-06 オーナー決定・文言確定）: 名前のデータが無い時の案内。
   * 正典の文言を**一字一句そのまま**使う（画面だけ・紙には出さない）。
   * @param mn {home:bool, lot:bool}（Shozaizu.generate の stat.mainNoName）
   */
  function mainNoNameText(mn) {
    var head = (mn.home && mn.lot) ? '使用の本拠・駐車場の'
      : mn.home ? '使用の本拠の' : '駐車場の';
    return head + '近くの交差点名・通り名は、地図データにありません。'
         + '分かる場合は、他の地図で確かめて［文字］で書き入れてください。';
  }

  /**
   * 生成結果に添える「名称が出ない理由」の一言。osmError（通信失敗）と
   * mainNoName（データが無い）は**混ぜない**（§22-as・「無い」と「取れなかった」は別）。
   * 範囲が広すぎる（'wide'）は従来どおり別枠（§22-as の対象外・呼び出し側で扱う）。
   * @return '' か、先頭に空白付きの警告文
   */
  /* 🔒 §30-23: 「枠に入った目印がほとんど無い」と言う件数の境目（これ未満で一言を足す） */
  var SZ_MARKS_MIN = 3;

  function szNameWarningText(s) {
    var w = '';
    if (s.osmError && s.osmError !== 'wide') {
      w = ' ⚠ 名前の取得に失敗しました（通信）。少し待って、もう一度［所在図を作る］を押してください。';
    } else if (!s.osmError && s.mainNoName && (s.mainNoName.home || s.mainNoName.lot)) {
      w = ' ⚠ ' + mainNoNameText(s.mainNoName);
    }
    /* 🔒 §30-21-4 1: 名前が多すぎて応答の上限に当たった時は**足す**（上の2つとは別の話。
     * 取れなかったのでも無いのでもなく「取ったが多すぎて一部を省いた」）。
     * 🔴 判定は shozaizu の stat（namesTruncated）。表示文字では分岐しない（注意②）。 */
    if (s.namesTruncated) {
      w += ' ⚠ 名前が多すぎて一部を省きました（枠を小さくすると全部出ます）';
    }
    /* 🔒 §30-23: 逆に枠が狭すぎて、周りの施設が全部枠の外へ出てしまった時も**足す**
     * （上の3つとは別の話＝取れているが紙に載らない）。
     * 🔴 判定は shozaizu の stat（marksInFrame＝枠に入った目印の件数）。
     *    表示文字列では分岐しない（注意②）。
     * 🔴 通信に失敗した時（osmError）は数えない。OSM の名前が丸ごと欠けて件数が
     *    必ず少なくなり、「枠が狭い」と誤診断してしまう（§22-as の
     *    「無い」と「取れなかった」は別、と同じ理由）。実機で 504 を踏んで確認。 */
    if (!s.osmError && typeof s.marksInFrame === 'number' && s.marksInFrame < SZ_MARKS_MIN) {
      w += ' ⚠ 枠が狭くて目印がほとんど入りません。'
         + '地図を縮小して枠を広げると、周りの施設名が出ます';
    }
    return w;
  }

  /** 設定盤の全項目を、いまの案件の値で引き直す（案件を開いた時・標準へ戻した時） */
  function syncSzPanel() {
    Object.keys(SZ_GRADES).forEach(function (k) { syncGradePick(k, gradeValue(k)); });
    Object.keys(SZ_TOGGLES).forEach(function (k) { syncTogglePick(k, toggleValue(k)); });
    // 🔒 §30-22-2 2: 段数が5でない項目（名前の位置）
    Object.keys(SZ_PICKS).forEach(function (k) { syncPickPick(k, pickValue(k)); });
  }

  /**
   * 🔒 2026-08-31: 上部バーの［保存］。自動保存を待たずにいま確定させる。
   * 保存できたことは（a）保存状態表示が「保存済 ✓」へ（Store の emit 経由）
   * （b）地図の上の一言、の2つで分かるようにしてある。
   */
  function saveNow() {
    if (!state.current) return;
    persistSheetState();          // いま見ている位置・倍率・下敷きの濃さも一緒に書き戻す
    Store.autosave(state.current); // 地図がまだ無い場合の保険（保留を必ず1つ作る）
    Store.flush();                // 保留を即確定（emit で保存状態表示が更新される）
    hint('保存しました', 2000);
  }

  /** 案件一覧へ戻る（上部の［‹ 案件一覧］と誘導⑪の［案件一覧に戻る］の共通処理） */
  function backToList() {
    /* 🔴 §27-7③: フォルダ運用では書き込みが非同期。先に一覧を出しておき、
     * 書き終わったら索引が更新された一覧へ引き直す（更新日時・図形数が古いまま
     * 残らないように）。作図側の呼び出しは今までどおり戻り値を見なくてよい。 */
    var p = Store.flush();
    closeExportPreview();      // 誘導から出したプレビューを残さない（sgCap 等の後始末込み）
    /* 🔒 §30-25-26: 一覧へ戻る時も、開いている窓は全部閉じる
     * （案件を開く／新しく作る と同じ CASE_PANELS を通る closeAllOverlays）。 */
    closeAllOverlays();
    /* 🔒 §28-6 ⑤: 保存した段は消さない（次にこの案件を開いた時に続きから） */
    navClose(true);            // 掴んだままの地図クリックを残さない（§18）
    state.current = null;
    renderCaseList();
    showView('list');
    if (p && p.then) p.then(afterCaseOp, afterCaseOp);
    /* 🔒 §30-33-1 3: 案件一覧に戻った時に新しい版があれば、自動で読み直す。
     * 🔴 案件ファイルの書き込み（flush）が終わってから開き直す
     *    （書き込みは非同期なので、待たずに開き直すと書きかけが失われる）。 */
    Promise.resolve(p).then(verAfterList, verAfterList);
  }

  function bindEditor() {
    $('btnBackToList').addEventListener('click', backToList);

    $('caseName').addEventListener('input', function () {
      if (!state.current) return;
      state.current.name = this.value;
      Store.autosave(state.current);
    });

    /* 🔒 §19-1: 案件番号は編集自由（ただの文字列）。自動採番の値を消しても構わない。
       重複しても止めない＝一覧の警告色で気づかせるだけ */
    $('caseNo').addEventListener('input', function () {
      if (!state.current) return;
      state.current.caseNo = this.value.trim();
      Store.autosave(state.current);
    });

    /* 🔴 2026-08-31 オーナー指示: エディタ側の ☑完了 は**削除**した。
       §19-3 の「指定する場所は2か所」のうち**案件一覧の行トグル**だけを残す
       （done というデータ自体は不変＝後方互換）。 */

    /* 🔒 2026-08-31: ［保存］（☑完了があった位置に新設）。
       自動保存（1秒 debounce・§8）はそのまま動かしたうえで、
       「いま確定させたい」時に押すボタン。
       判断: persistSheetState() → Store.flush() の2段にした。
       ・persistSheetState() が今の中心・倍率・下敷きの濃さを案件へ書き戻して
         autosave() を呼ぶ＝押した瞬間の見た目まで含めて保存される
       ・その autosave が必ず保留を作るので、flush() の「保留が無ければ何もしない」に
         引っかからない（＝必ず1回書き、保存状態表示も saved/error へ更新される） */
    $('btnSaveNow').addEventListener('click', saveNow);

    /* 🔒 §27-12-1 ⑤: 上部バーの［ファイルに保存］（ボタンと Store 側の書き出し関数）は
       **削除**した。案件の本体が案件フォルダの .shako そのものなので、書き出す意味が無い。
       複製・受け渡しは OS のファイル操作でやる（アプリの仕事ではない）。 */

    /* 🔒 §30-39-1 1: 上部バーの［検索］（#btnSearchHome）は**削除**した。
       ［検索］は左メニューの4つだけ（表 SEARCH_BTNS・配線はこの関数の下の方に1か所）。 */

    /* ---- 依頼文から住所を拾う（端末内処理のみ・正典 §1-6） ----
       🔴 2026-08-31 オーナー指示で上部バーの［依頼文から］ボタンを**削除**したため、
          #pastePanel は**到達不能**（開く入口が無い）になっている。
          将来復活させる可能性があるので、パネルの HTML・js/parse.js・下の
          previewPaste()/runPaste() は**残してある**。入口を1つ足せば元どおり動く。 */
    $('pasteClose').addEventListener('click', function () {
      $('pastePanel').hidden = true;
    });
    $('pasteRun').addEventListener('click', runPaste);
    $('pasteText').addEventListener('input', previewPaste);
    /* 🔒 §30-39-2 3: 欄は本拠2か所・駐車場2か所（同じ地点の値は1つ）。Enter でも検索。
     *    配線はこの1か所（ADDR_FIELDS の表を回すだけ＝処理を2つ書かない）。 */
    Object.keys(ADDR_FIELDS).forEach(function (key) {
      ADDR_FIELDS[key].forEach(function (id) {
        var el = $(id);
        if (!el) return;
        el.addEventListener('input', function () { syncAddr(key, this.value, id); });
        el.addEventListener('keydown', function (e) {
          if (e.key === 'Enter') doSearch(key);
        });
      });
    });

    document.querySelectorAll('.tab').forEach(function (t) {
      t.addEventListener('click', function () { switchKind(t.dataset.kind); });
    });

    /* シート帯（🔒 §24-1 / §24-5 / §25-3）。追加・複製・削除・並べ替え・向き・枠へ移動 */
    $('sbAdd').addEventListener('click', function () { addSheet(null); });
    // 🔒 §30-26-1: ［枠を抜出し追加］（［複製］とは別のボタン・案内が違う）
    $('sheetExtract').addEventListener('click', extractSheet);
    $('sbDup').addEventListener('click', function () { addSheet(curSheet()); });
    $('sbDel').addEventListener('click', deleteSheet);
    $('sbLeft').addEventListener('click', function () { moveSheet(-1); });
    $('sbRight').addEventListener('click', function () { moveSheet(1); });
    $('sbFix').addEventListener('click', toggleFrameFixed);
    $('sbGoFrame').addEventListener('click', goToSheetFrame);
    document.querySelectorAll('#sbOrient button').forEach(function (b) {
      b.addEventListener('click', function () { setSheetOrient(b.dataset.orient); });
    });

    buildUnderlayOptions();
    $('underlaySel').addEventListener('change', function () {
      setUnderlayChoice(this.value);
    });

    /* 🔒 §30-22-3 1: 濃さ・出し入れの出入口は setUnderlayPct 1つ
     * （上部バーもガイダンス④も同じ関数を呼ぶ＝値が2か所に割れない）。 */
    $('opacity').addEventListener('input', function () {
      setUnderlayPct(this.value);
    });

    $('underlayOff').addEventListener('change', function () {
      setUnderlayPct(this.checked ? 0 : 100);
    });

    /* ④の濃さと表示／非表示（🔒 §30-22-3 1）。上部バーと**同じ値**を書くだけ。
     * 🔒 §30-22-4 1: 同じ物が配置図の全段（#hzUnderBar）にも出るので、配線は
     *    **class 1か所**（.js-uop-range / .js-uop-show）でまとめて受ける。
     * 🔴 「表示する」に戻す時は、直前の濃さ（0 でない値）へ戻す。 */
    document.querySelectorAll('.js-uop-range').forEach(function (r) {
      r.addEventListener('input', function () { setUnderlayPct(this.value); });
    });
    document.querySelectorAll('.js-uop-show').forEach(function (c) {
      c.addEventListener('change', function () {
        setUnderlayPct(this.checked ? (state.sgUnderLastPct || SG4_UNDER_PCT) : 0);
      });
    });

    /* ---- 道具バー ---- */
    document.querySelectorAll('.tool').forEach(function (b) {
      b.addEventListener('click', function () {
        if (b.disabled || !state.editor) return;
        var t = b.dataset.tool;
        /* 🔒 §25-7 →§30-19-1: ［枠をまとめて］は道具でもパネルでもなく
         * **「押してから地図をクリックした所に1枠置く」操作**（もう一度押すとやめる）。
         * 台数を数えて入力する従来の窓は［台数を指定して置く…］に残してある。 */
        if (t === 'stamp') { toggleStampArm(); return; }
        /* 🔒 §30-22-1 4: 主役の多角形は「どちらの地点を囲むか」を持つ道具。
         * 🔴 ボタンの文字ではなく data-mkey で渡す（§26-2 注意②）。 */
        if (t === 'mainpoly') state.editor.mainPolyKey = (b.dataset.mkey === 'lot') ? 'lot' : 'home';
        state.editor.setTool(t);
        if (t === 'parcel') loadParcelCandidates();
        else state.editor.setCandidates(null);
      });
    });
    /* 🔒 §23-3: ブラシの太さ3段をワンクリック切替（キーは [ と ]） */
    document.querySelectorAll('#rvSizes .rv-size').forEach(function (b) {
      b.addEventListener('click', function () {
        if (!state.reveal) return;
        state.reveal.setSize(b.dataset.rsize);
        syncRevealSizes();
      });
    });
    /* 🔒 §23-5: 名称の分類チェック。ONにした分類だけが地図上に薄く出る */
    document.querySelectorAll('#rvNames .rv-cat').forEach(function (b) {
      b.addEventListener('change', applyNameCats);
    });
    /* 「全ての目印」＝ 上の8分類の合算チェック（§23-5 の表の最終行・🔒 §30-21-4 7 で 6→8） */
    $('rvCatAll').addEventListener('change', function () {
      var on = this.checked;
      document.querySelectorAll('#rvNames .rv-cat').forEach(function (b) {
        b.checked = on;
      });
      applyNameCats();
    });
    $('rvNameRetry').addEventListener('click', function () {
      if (state.reveal) state.reveal.retryNames();
    });
    $('btnDraft').addEventListener('click', function () {
      $('draftPanel').hidden = !$('draftPanel').hidden;
      if (!$('draftPanel').hidden) probeDraftSources();
    });
    $('dfClose').addEventListener('click', function () { $('draftPanel').hidden = true; });
    $('dfRun').addEventListener('click', runAutoDraft);
    /* ---- ［枠を図形に合わせる］（🔒 §30-29-5 3・旧 #exPanel の「図形が全部入るように」）----
     * 旧・書き出しの窓が §30-29-1 3 で廃止された時に一緒に消えてしまったので、
     * 左メニューの▼「自動・取り込み」の末尾へ**同じ処理のまま**戻した。
     * 🔴 これは「地図の表示自体を合わせる」操作。書き出し範囲は常に画面なので、
     *    画面を動かせば範囲もついてくる。 */
    if ($('btnFitAll')) {
      $('btnFitAll').addEventListener('click', function () {
        if (!state.current) return;
        var objs = objectsOf(state.kind);
        var subj = objs.filter(function (o) {
          return o.source !== 'auto' && o.source !== 'shozaizu';
        });
        var f = Exporter.fitFrame(subj.length ? subj : objs,
                                  state.current.points.lot || state.current.points.home,
                                  curAspect());   // 🔒 §25-3: この紙の向きで収める
        if (!f) { hint('まだ図形がありません', 2500); return; }
        var b = Exporter.frameBounds(f);
        state.map.fitPoints([{ lat: b.north, lng: b.west },
                             { lat: b.south, lng: b.east }], 0.05);
        /* 🔴 これは「範囲を決め直す」明示の操作なので、枠を決定済みの紙でも
         * ここでは新しい範囲を採る（決定は保ったまま中身だけ入れ替える）。 */
        var sh = curSheet();
        var ff = (sh && sh.frameFixed) ? frameFromView() : null;
        if (ff) sh.frame = ff;
        else if (!sh || !sh.frameFixed) syncFrameFromView();
        renderSheetBar();
        renderOverlay();
        Store.autosave(state.current);
        hint(KIND_JA[state.kind] + 'の図形が全部入るように表示を合わせました', 3500);
      });
    }
    /* ---- 上部バーの［プレビュー］（🔒 §30-29-1 3・旧［書き出し］）----
     * オーナー指示 2026-09-14:「上部ツールバーの書き出しボタンは『プレビュー』ボタンに
     *   名称変更。とび先も1つにまとめたプレビュー画面」。
     * 🔴 旧 #exPanel（書き出しの窓）は廃止した。PDF／画像はプレビュー画面の帯
     *    （#exPreviewBar → exPickOpen）＝出口は1つ（§30-27-1 6）。 */
    $('btnExport').addEventListener('click', function () {
      if (!state.current) return;
      // 枠の数値は「いま見えている範囲」なので、開く前に1回だけ揃えておく
      syncFrameFromView();
      ensureFrames();
      openPreview({ kind: state.kind });
    });
    /* 🔒 §30-31-3 1: 提出前チェックの窓（旧 #chkBox ＝［このまま書き出す］
     * ［戻って直す］）は廃止した。配線もここから消してある。 */
    /* 🔒 §30-20: 「はじめに」の3つのボタン。ガイダンスの2つは**上部バーの同名ボタンと
     * 同じ処理**（navStartFig）を呼ぶ＝同じ操作は同じ結果（§26-2）。
     * ［ガイダンスを使わずに作成］は閉じるだけ（何も始めない）。 */
    $('wcNavSz').addEventListener('click', function () {
      welcomeClose();
      navStartFig('shozaizu');
    });
    $('wcNavHz').addEventListener('click', function () {
      welcomeClose();
      navStartFig('haichizu');
    });
    $('wcSkip').addEventListener('click', function () { welcomeClose(); });
    // 閉じ方は3通り用意する（ボタン／背景クリック／Esc）
    $('exPreviewClose').addEventListener('click', closeExportPreview);
    $('exPreviewBox').addEventListener('click', function (e) {
      if (e.target === this) closeExportPreview();   // 外側（暗い部分）を押した時
    });
    /* 🔒 §30-26-3 → §30-34-1 3 改定: 「他の枠の範囲を表示」。枠の範囲は**紙の絵
     * そのもの**（Exporter.renderSheet）に入るようになったので、切り替えたら
     * **控えを捨てて画像を作り直す**（重ねる層はもう無い）。
     * 🔴 まとめの面は毎回描き直している（exRenderCombo）ので、同じ経路で新しくなる。 */
    $('exOtherFrames').addEventListener('change', function () {
      state.exOtherFrames = this.checked;
      var pg = state.exPager;
      if (pg) { pg.url = {}; pg.r = {}; pg.scale = {}; }
      if (!$('exPreviewBox').hidden) exPagerRender();
    });
    /* ---- 🔒 §30-27-1 2: プレビューの道しるべの行 ---- */
    $('exNavPrev').addEventListener('click', function () {
      if (state.exPager) exPagerGo(state.exPager.i - 1);
    });
    $('exNavNext').addEventListener('click', function () {
      if (state.exPager) exPagerGo(state.exPager.i + 1);
    });
    /* 図のトグル（所在図／配置図）。🔴 行き先は「その図の1枚目」＝番号で決める */
    $('exKindSw').addEventListener('change', function () {
      var pg = state.exPager;
      if (!pg) return;
      var want = this.checked ? 'haichizu' : 'shozaizu';
      for (var i = 0; i < pg.pages.length; i++) {
        if (pg.pages[i].kind === want) { exPagerGo(i); return; }
      }
      exNavRender();        // 紙が無い側は選べない（見た目を戻す）
    });
    /* ---- 🔒 §30-27-1 6 / §30-27-2: ［PDF］［画像］→ 出す紙を選ぶ窓 ----
     * 🔒 §30-31-3 1（2026-09-15 オーナー指示「所在図を作ったのに提出前チェックで
     *    配置図のエラーが出る。このエラー表示自体を無くして」）: 間に挟んでいた
     *    「提出前チェック」（旧 #chkBox・withSubmitCheck）は**廃止**。
     *    押したらすぐ紙を選ぶ窓（§30-27-2）が開く＝入口は1つのまま。 */
    $('exBarPdf').addEventListener('click', function () { exPickOpen('pdf'); });
    $('exBarPng').addEventListener('click', function () { exPickOpen('png'); });
    $('exPickClose').addEventListener('click', exPickClose);
    $('exPickCancel').addEventListener('click', exPickClose);
    $('exPickGo').addEventListener('click', exPickRun);
    $('exPick').addEventListener('click', function (e) {
      if (e.target === this) exPickClose();   // 外側（暗い部分）を押した時
    });
    /* 🔒 v6（§16-10-f）: 写真の縮尺の3択（scaleBox）は**廃止**した。
     * 認識は画像に触らないので、縮尺を人に確認する必要がなくなった。 */

    /* 🔒 §23-3: ブラシの太さは [ ] キーでも変えられる（なぞりながら持ち替える）。
     * 🔴 文字入力欄・かぶせ物の上では奪わない（§22-ae と同じ作法）。 */
    document.addEventListener('keydown', function (e) {
      if (e.key !== '[' && e.key !== ']') return;
      if (e.ctrlKey || e.metaKey || e.altKey) return;
      if (!state.reveal || !state.editor) return;
      if (state.editor.effectiveTool() !== 'reveal') return;
      if (state.editor.keysBusy && state.editor.keysBusy()) return;
      var t = e.target;
      if (t && (t.isContentEditable || t.tagName === 'INPUT'
                || t.tagName === 'TEXTAREA' || t.tagName === 'SELECT')) return;
      e.preventDefault();
      var s = state.reveal.stepSize(e.key === ']' ? 1 : -1);
      syncRevealSizes();
      hint('筆の太さ: ' + Reveal.sizeJa(s), 1400);
    });

    /* 🔒 §30-18-6 2 / §30-27-1 2: プレビューは ← → でもページを送れる
     * （かぶせが出ている間だけ・文字入力欄の上では奪わない）。
     * 🔴 紙を選ぶ窓（#exPick）が開いている間は奪わない（そちらが手前）。 */
    document.addEventListener('keydown', function (e) {
      if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return;
      if (!state.exPager || $('exPreviewBox').hidden) return;
      if (!$('exPick').hidden) return;
      if (e.ctrlKey || e.metaKey || e.altKey) return;
      var t = e.target;
      if (t && (t.isContentEditable || t.tagName === 'INPUT'
                || t.tagName === 'TEXTAREA' || t.tagName === 'SELECT')) return;
      e.preventDefault();
      exPagerGo(state.exPager.i + (e.key === 'ArrowRight' ? 1 : -1));
    });

    document.addEventListener('keydown', function (e) {
      if (e.key !== 'Escape') return;
      // 🔒 §22-ah: 動画が出ている時は動画を先に閉じる（一番手前のかぶせ物なので）
      if (!$('vidBox').hidden) {
        e.preventDefault();
        e.stopPropagation();
        vidClose();
      } else if ($('textPick') && !$('textPick').hidden) {
        /* 🔒 §30-29-1 2: 文字の選択窓は小さなポップアップ＝一番手前の扱い
         * （かぶせ物より先に閉じる。開いている間は他の窓は開けない） */
        e.preventDefault();
        e.stopPropagation();
        textPickClose();
      } else if ($('arrowPick') && !$('arrowPick').hidden) {
        /* 🔒 §30-29-4 1: 幅の矢印の窓も同じ扱い（文字の窓と並べる） */
        e.preventDefault();
        e.stopPropagation();
        arrowPickClose();
      } else if (!$('exPick').hidden) {
        /* 🔒 §30-27-2: 紙を選ぶ窓が一番手前（プレビューより先に閉じる） */
        e.preventDefault();
        e.stopPropagation();
        exPickClose();
      } else if (!$('welcomeBox').hidden) {
        // 🔒 §30-20: Esc は閉じるだけ（ガイダンスは始めない）
        e.preventDefault();
        e.stopPropagation();
        welcomeClose();
      } else if (!$('exPreviewBox').hidden) {
        e.preventDefault();
        e.stopPropagation();
        closeExportPreview();
      /* 🔒 §30-31-3 1: 提出前チェックの窓（旧 #chkBox）は廃止＝ Esc の枝も消した */
      } else if (state.edgePick) {
        e.preventDefault();
        e.stopPropagation();
        stopEdgePick();
      } else if (state.namePick) {
        // 🔒 §30-16: 拾う状態を Esc で抜ける
        e.preventDefault();
        e.stopPropagation();
        stopNamePick();
        hint('名前を図に入れるのをやめました', 2000);
      } else if (state.stampArm) {
        // 🔒 §30-19-1: ［枠をまとめて］の置く状態を Esc で抜ける（何も置かない）
        e.preventDefault();
        e.stopPropagation();
        stopStampArm();
        hint('枠を置くのをやめました', 2000);
      } else if (state.pinPlace) {
        e.preventDefault();
        e.stopPropagation();
        navPinArm(null);
        hint('マーカーの設置をやめました', 2000);
      } else if (state.plPlace) {
        // 🔒 §22-ab / §30-22-4 10: 駐車位置ラベルの「枠を待っている」状態を Esc で抜ける
        e.preventDefault();
        e.stopPropagation();
        plDisarm();                     // 案内の一言は plDisarm が戻す（⑪／小窓の両方）
        if (navOnSide()) sgRenderStatus();
        hint('駐車位置ラベルの配置をやめました', 2000);
      }
    }, true);

    /* ---- 所在図の自動生成（正典 §5） ---- */
    $('btnShozaizu').addEventListener('click', function () {
      $('szPanel').hidden = !$('szPanel').hidden;
    });
    $('szClose').addEventListener('click', function () { $('szPanel').hidden = true; });
    /* 🔒 2026-09-03 オーナー指示（タスク3）: ［標準の設定で作る］は
     * ①背景の地図を非表示 ②全項目を「標準」に戻す ③所在図を描画、の3つを行う。
     * 🔴 **調整済みの設定を捨てる動作**なので、ボタンの文言（「標準の設定で作る」）と
     *    title の2か所で先に伝えてある（無言でリセットしない）。
     * 🔴 §22-ak-3（裁定）②: 3か所目だったパネルの注意文は、後半の6項目を入れる
     *    高さを作るために消して title へ寄せた（説明文より項目を優先する）。 */
    $('szRun').addEventListener('click', function () { runShozaizuStandard(); });
    /* 🔒 2026-09-03（タスク4）: ［標準の設定で作る］の右に、既存の A4 プレビューを開くボタン。
     * 🔒 §28-5 C（Step 3）: ガイダンス④の［所在図プレビュー］（#sgPrev）も
     * **同じ関数**（runShozaizuPreview）を呼ぶ（同じ操作は同じ結果・§26-2）。 */
    $('szPrev').addEventListener('click', runShozaizuPreview);

    /* 🔒 §30-22-4 4 / 🔒 §30-25-34 1: ［地図の道路を写す］（配置図の枠の近くの
     * 道路の縁を地図から写す）。
     * 🔒 §30-29-5 3: 左メニューの▼「自動・取り込み」の先頭にも戻した
     *    （配置図④の #sgRoadAuto と**同じ関数** drawRoadsNearFrame・同じ名前と説明）。
     * 🔴 入口の一覧はこの配列1か所（増やす時はここだけ足す）。 */
    ['sgRoadAuto', 'btnRoadAuto'].forEach(function (id) {
      var b = $(id);
      if (b) b.addEventListener('click', function () { drawRoadsNearFrame(); });
    });

    /* ---- 一発生成 ---- */
    $('btnAuto').addEventListener('click', runAutoAll);

    /* ---- 駐車枠の自動敷き詰め（正典 Step 3.5 / §16-4 台数指定） ---- */
    buildFillPresets();
    $('btnFill').addEventListener('click', function () { openFillPanel(); });
    $('fillClose').addEventListener('click', function () { openFillPanel(false); });
    $('fillPreset').addEventListener('change', function () {
      var p = StampPanel.PRESETS[this.value];
      if (p && p.w) { $('fillW').value = p.w; $('fillH').value = p.h; }
    });
    // 主方式＝画像認識（読めなければ幾何配置へ自動フォールバック・正典 §16-10）
    $('fillRun').addEventListener('click', function () { runFillSmart(); });
    $('fillShowLines').addEventListener('change', function () {
      state.showRecog = this.checked;
      renderRecogLines();
    });
    // 列の向き（正典 §16-5 C）: 自動 / 辺に沿わせる / 角度手入力
    document.querySelectorAll('input[name="fillDir"]').forEach(function (r) {
      // 同じ［辺に沿わせる］をもう一度押した時も選び直せるようにする
      r.addEventListener('click', function () {
        if (this.value === 'edge' && !state.edgePick) startEdgePick();
      });
      r.addEventListener('change', function () {
        if (this.value === 'edge') startEdgePick();
        else {
          stopEdgePick();
          setDirNote((this.value === 'manual')
            ? '入力した角度で並べます（0°＝東西方向）'
            : '前面道路に沿う向きを自動で選びます');
        }
      });
    });

    /* ---- 画像の下敷き（正典 §16-3 Step 7A） ---- */
    $('btnImage').addEventListener('click', function () { openImagePanel(); });
    $('imgClose').addEventListener('click', function () { openImagePanel(false); });
    $('imgPick').addEventListener('click', function () { $('imgFile').click(); });
    $('imgFile').addEventListener('change', function (e) {
      var f = e.target.files && e.target.files[0];
      e.target.value = '';
      importImage(f);
    });
    $('imgOpacity').addEventListener('input', function () {
      setImgOpacity(this.value, 'side');
    });
    // 🔒 §22-ad: 上部バーの「画像の濃さ」（画像がある時だけ出る）
    $('imgOpacityTop').addEventListener('input', function () {
      setImgOpacity(this.value, 'top');
    });
    ['imgWidth', 'imgAngle'].forEach(function (id) {
      $(id).addEventListener('change', function () {
        var v = parseFloat(this.value);
        if (isNaN(v)) return;
        state.imglay.update(id === 'imgWidth' ? { w_m: v } : { angle: v });
        syncImagePanel();
      });
    });
    $('imgVisible').addEventListener('change', function () {
      state.imglay.update({ visible: this.checked });
      syncImagePanel();
    });
    /* 上部バーの［画像OFF］トグル（地図の下敷きとは独立・正典 §16-3 改）
     * 🔒 §22-af: 名前が「画像」→「画像OFF」になったので**意味も反転**している。
     *    チェックが入っている＝画像を消す（隣の［地図OFF］と同じ向き）。 */
    $('imgOff').addEventListener('change', function () {
      if (!state.imglay || !state.imglay.getMeta()) return;
      state.imglay.update({ visible: !this.checked });
      syncImagePanel();
    });
    $('imgLocked').addEventListener('change', function () {
      state.imglay.update({ locked: this.checked });
      syncImagePanel();
    });
    $('imgReset').addEventListener('click', function () {
      if (state.imglay.resetScreen()) hint('画像を画面の中央に戻しました', 2500);
      else hint('固定中は動きません。［固定する］を外してからお試しください', 4000);
    });
    $('imgRemove').addEventListener('click', function () {
      if (!confirm('この画像を外します（このパソコンからも消えます）。よろしいですか？')) return;
      state.imglay.remove().then(function () {
        syncImagePanel();
        if (navOnSide()) sgRender();     // 🔒 §29-1 ⑤: 濃さの欄・ボタンの文言も戻す
        hint('画像を外しました', 2500);
      });
    });
    // 地図へのドラッグ&ドロップでも取り込める（正典 §16-3）
    var mapWrap = document.querySelector('.map-wrap');
    ['dragenter', 'dragover'].forEach(function (ev) {
      mapWrap.addEventListener(ev, function (e) {
        if (!state.current) return;
        e.preventDefault();
        e.dataTransfer.dropEffect = 'copy';
        mapWrap.classList.add('is-dropping');
      });
    });
    ['dragleave', 'dragend'].forEach(function (ev) {
      mapWrap.addEventListener(ev, function () {
        mapWrap.classList.remove('is-dropping');
      });
    });
    mapWrap.addEventListener('drop', function (e) {
      if (!state.current) return;
      e.preventDefault();
      mapWrap.classList.remove('is-dropping');
      var f = e.dataTransfer.files && e.dataTransfer.files[0];
      if (f) importImage(f);
    });

    /* ---- 案件のガイダンス（正典 §18 / §28 / §29） ----
     * 🔒 §18-al: 上部バーの［🧭 所在図ガイダンス］［🧭 配置図ガイダンス］が**唯一の入口**。
     *    住所検索からの自動起動は廃止した（勝手に出ないようにする）。
     * 🔒 §29 Step 7: 📷「写真から配置図」は**同じ入口の別の段**（⑤ 下敷きと枠）。
     *    左ウィザード（#guidePanel）は全廃したので、開く器は左面ひとつだけ。 */
    /* 🔒 §30-1（2026-09-08 オーナー承認）: 入口は**2つ**（所在図／配置図）。
     * 🔴 navOpen() ではなく navStartFig()。初回は navGo() を通して段の下準備
     *    （ピン待ち受け・タブ合わせ・枠の判定）まで走らせる必要がある。
     *    その図の段が案件に保存してあればそこから、無ければ①から。 */
    $('btnNavSz').addEventListener('click', function () { navStartFig('shozaizu'); });
    $('btnNavHz').addEventListener('click', function () { navStartFig('haichizu'); });
    $('btnPhotoGuide').addEventListener('click', function () {
      if (!state.current) return;
      navStart(5);             // 配置図①（下敷きと枠）＝写真の取り込みがある段
    });
    /* 🔒 2026-09-06 オーナー指示: マーカー設置は道具メニューの一番上にも置く。
       ガイダンスを閉じていてもマーカーを置き直せる（住所検索では置かなくなったため）。 */
    $('sidePinHome').addEventListener('click', function () { navPinArm('home'); });
    $('sidePinLot').addEventListener('click', function () { navPinArm('lot'); });

    /* ---- 左面のガイダンス（🔒 §28-1 / §28-2 / §28-3） ----
     * 🔴 押した先は data-act の委譲で受ける
     *    （ボタンを作り直しても配線が切れない）。 */
    $('sgClose').addEventListener('click', function () {
      navClose();
      hint('ガイダンスを閉じました。描いた図・置いたマーカーは何も消えていません', 3500);
    });
    sgCaptionInitDrag();      // 🔒 §30-10: 字幕の［×］とドラッグ（1回だけ配線）
    /* 🔒 §30-29-1 2: ガイダンスの「文字を置く」欄の言葉のボタンを TEXT_PRESETS から
     * 組む（言葉のボタンは絵を持たないので、アイコンを入れる前でも後でもよい）。 */
    buildPresetRows();
    /* 🔒 §30-22-3 2: 道具のアイコン（絵と説明）を入れる。1回だけ・表は TOOL_ICONS */
    applyToolIcons();
    /* 🔒 §30-29-1 2: 文字の選択窓は **applyToolIcons の後**に組む
     * （applyToolIcon は innerHTML を絵で置き換えるので、先に作ると
     *  ［自由入力］の行に添えた言葉が消える）。 */
    buildTextPick();
    /* 🔒 §30-29-1 2: ［A］は「窓を開く」ボタンなので、説明だけ差し替える
     * （絵は TOOL_ICONS.textFree のまま＝出どころは1か所）。 */
    if ($('tbTextBtn')) {
      $('tbTextBtn').title = '文字を置く：よく使う言葉と［自由入力］を選びます';
      $('tbTextBtn').setAttribute('aria-label', '文字を置く');
      $('tbTextBtn').addEventListener('click', function () {
        textPickSet($('textPick').hidden);
      });
      /* 外側をクリックしたら閉じる（窓の中と［A］自身は閉じない）。
       * 🔴 stopPropagation は使わない（窓の中の .sg-preset を委譲で受けているため）。
       * 🔴 Esc は既存の keydown の並び（§30-27-2 と同じ所）で受ける。 */
      document.addEventListener('click', function (e) {
        var t = e.target;
        if (t && t.closest && (t.closest('#textPick') || t.closest('#tbTextBtn'))) return;
        textPickClose();
      });
    }
    /* 🔒 §30-29-4 1: ［幅矢印］も「窓を開く」ボタン（絵は TOOL_ICONS.arrow のまま）。
     * 2つの選択肢は道具（class="tool"）にせず、押した時に
     * モードを決める → 窓を閉じる → 矢印の道具にする、の3つをここで受ける。 */
    if ($('tbArrowBtn')) {
      $('tbArrowBtn').title = '幅の矢印：自動で測るか、幅を入力して矢印を引きます';
      $('tbArrowBtn').setAttribute('aria-label', '幅の矢印');
      $('tbArrowBtn').addEventListener('click', function () {
        if ($('arrowPick').hidden) arrowPickOpen(); else arrowPickClose();
      });
      /* 外側をクリックしたら閉じる（窓の中とアイコン自身は閉じない）。
       * 🔴 Esc は上の keydown の並び（文字の窓の次）で受ける。 */
      document.addEventListener('click', function (e) {
        var t = e.target;
        if (t && t.closest && (t.closest('#arrowPick') || t.closest('#tbArrowBtn'))) return;
        arrowPickClose();
      });
      /* 🔴 判定は data-mode（'auto' / 'manual'）だけ・表示文字では分岐しない */
      $('arrowPickMode').querySelectorAll('[data-mode]').forEach(function (b) {
        b.addEventListener('click', function () {
          setArrowMode(this.dataset.mode);      // 値は arrowWidth／state.arrowMode の1つ
          arrowPickSet(false);                  // 選んで閉じる（打った値は戻さない）
          sgRenderStatus();
          if (state.editor) state.editor.setTool('arrow');
          /* §30-18-4 と同じ一言（幅が入っていればその値・空なら測る／出さない） */
          var w = String((state.editor && state.editor.arrowWidth) || '').trim();
          if (state.arrowMode === 'manual') {
            hint(w ? ('端から端までドラッグすると「' + w + (/m$/.test(w) ? '' : 'm')
                      + '」を添えて矢印を書き込みます')
                   : '幅を入れずに引くと、矢印だけを書き込みます（あとで「表示」欄に入れられます）',
                 4500);
          } else {
            hint('端から端までドラッグすると、地図から計算した幅が入ります', 4500);
          }
        });
      });
    }
    /* 🔒 §30-12-4: 「やること」以外の部品を「こんな時に押すボタン」の箱へ移す。
     * 🔴 器を作るのは**1回だけ**（部品は index.html にある物を移す＝id も配線もそのまま）。 */
    sgBuildMore();
    /* 🔒 §30-25-35: 配置図の下敷きの▼（#hzUnderMore）は index.html に固定で置いて
     * ある（#hzUnderBar ごと段を移るので sgBuildMore は通さない）。配線はここ1回だけ。 */
    if ($('hzUnderMoreBtn')) {
      $('hzUnderMoreBtn').addEventListener('click', function () {
        hzUnderMoreSet($('hzUnderMoreBody').hidden);
      });
    }
    if ($('hzUnderMoreX')) {
      $('hzUnderMoreX').addEventListener('click', function () { hzUnderMoreSet(false); });
    }
    /* 🔒 §30-28-1 2: 道具メニューの▼（3つ）。開閉は data-tmore ／ data-tmore-x
     * （属性）で受ける＝ボタンの文字では分岐しない。描き方は sgMorePaint 1か所。 */
    document.querySelectorAll('.tools [data-tmore]').forEach(function (b) {
      b.addEventListener('click', function () {
        var w = toolMoreBox(b.dataset.tmore);
        var body = w && w.querySelector('.sg-more-body');
        if (body) toolMoreSet(b.dataset.tmore, body.hidden);
      });
    });
    document.querySelectorAll('.tools [data-tmore-x]').forEach(function (b) {
      b.addEventListener('click', function () { toolMoreSet(b.dataset.tmoreX, false); });
    });
    /* 🔒 §30-29-2: 道具メニューの「確かめる・出す」は廃止した
     * （上部バーの［プレビュー］＝openPreview 1つに寄せた）。 */
    /* 🔒 §30-2: 案内数字の「押した」記録。
     * 🔴 **捕捉（capture）で受ける**。段を進めるボタン（次へ・決定）を押すと、
     *    本来の処理が先に走って段が変わってしまい、どの図・どの番号を押したのかが
     *    分からなくなるため。番号の付け直しは処理が終わってから（setTimeout 0）。 */
    $('sideNav').addEventListener('click', function (e) {
      if (!state.nav) return;
      var el = e.target && e.target.closest && e.target.closest('[data-sgn]');
      if (!el) return;
      var fig = navFigOf(state.nav.step), i = Number(el.getAttribute('data-sgn'));
      sgMarkHit(fig, i);
      setTimeout(function () { if (state.nav) sgRenderNums(); }, 0);
    }, true);
    $('sgFoot').addEventListener('click', function (e) {
      var b = e.target && e.target.closest && e.target.closest('button[data-act]');
      if (b && !b.disabled) sgAct(b.dataset.act);
    });
    $('sgSteps').addEventListener('click', function (e) {
      var s = e.target && e.target.closest && e.target.closest('span[data-step]');
      if (!s || !state.nav) return;
      var k = Number(s.getAttribute('data-step'));
      if (!k || k >= state.nav.step) return;      // 戻る方向だけ（§28-6 ⑦）
      navGo(k, { back: true });
    });
    $('sgPinHome').addEventListener('click', function () { navPinArm('home'); });
    $('sgPinLot').addEventListener('click', function () { navPinArm('lot'); });
    /* 🔒 §30-39-2 3: ［検索］は4つ（本拠・駐車場 × ガイダンス①・道具メニュー）。
     * 欄の配線は ADDR_FIELDS の所1か所にまとめてある。ここはボタンだけ
     * （中身は doSearch(key)＝地図を動かして、その場所に◎を置く・§30-39-3）。 */
    Object.keys(SEARCH_BTNS).forEach(function (key) {
      SEARCH_BTNS[key].forEach(function (id) {
        var b = $(id);
        if (b) b.addEventListener('click', function () { doSearch(key); });
      });
    });
    /* ①: 地図の選択（🔒 §28-14 ①-3）。④の〇と**同じ出入口**（sgUnderlayPick）。
     * 2つ目の値（Google 航空写真／地理院 写真）は buildUnderlayOptions が入れる。 */
    document.querySelectorAll('#sgUnder1 input[name="sgUnder1R"]').forEach(function (r) {
      r.addEventListener('change', function () {
        if (this.checked) sgUnderlayPick(this.value);
      });
    });
    /* ①: 印の形と色（🔒 §28-14 ①-4 / §30-22-1 4〜5）。中身は sgRenderMarks が
     * 組み立てるので、ここは器への委譲だけ（形＝data-shape／色＝data-color）。
     * 🔴 器は地点ごとに2つ（本拠／駐車場）。押した先の判定は data-mk 1か所。 */
    /* 🔒 §30-24-2: ［同一住所］の直下の▼も同じ器（値は本拠の物＝ data-mk="home"） */
    /* 🔒 §30-28-2 1: 道具メニューの▼の器（#sideMarks*）も同じ委譲で受ける
     * （押した先の判定は data-mk・処理は sgSetMark 1か所）。 */
    ['sgMarksHome', 'sgMarksLot', 'sgMarksSame',
     'sideMarksHome', 'sideMarksLot', 'sideMarksSame'].forEach(function (id) {
      var box = $(id);
      if (!box) return;
      box.addEventListener('click', function (e) {
        var b = e.target.closest ? e.target.closest('button[data-mk]') : null;
        if (!b) return;
        /* 🔒 §30-25-40 1: 形（data-shape）／色（data-color）の2種だけ
         * （大きさ＝ data-scale の行は廃止・つまみと右パネルへ移した）。
         * どれが押されたかは**属性**で見る（表示文字では分岐しない）。 */
        var patch = null;
        if (b.dataset.shape) patch = { shape: b.dataset.shape };
        else if (b.dataset.color) patch = { color: b.dataset.color };
        if (patch) sgSetMark(b.dataset.mk, patch);
      });
    });
    /* ①: ［使用の本拠と駐車場が同一住所］（🔒 §30-22-1 6）。
     * 中身はマーカー設置と**同じ仕組み**（押す → 地図をクリック）＝ navPinArm。
     * 🔒 §30-28-2 1: 道具メニューの #sideSame も同じ関数を呼ぶ。 */
    ['sgSame', 'sideSame'].forEach(function (id) {
      var b = $(id);
      if (b) b.addEventListener('click', function () { navPinArm('same'); });
    });
    /* ②: 紙の向き・2地点を入れる・枠を決定。**中身は既存の関数そのまま**（§28-1 ④）
     * 🔒 §30-13-2 1: 〇2つ（旧 #sgOrient）はやめて、押すとその場で縦↔横が
     *   切り替わる普通のボタンにした。中身は⑤と同じ setSheetOrient（値は1つ）。 */
    /* 🔒 §30-14-1: ⑤（配置図①）も**同じ作り**の［紙の向きを変える］。
     * 中身は1つの関数（setSheetOrient）＝値はシートの orient 1つのまま。 */
    /* 🔒 §30-29-2: 道具メニューの「紙と枠」（#sideOriToggle / #sideFix）は廃止した。
     * 器はガイダンス②（所在図）と⑤（配置図）の2つ。2行目の「いま: …」と
     * ［枠を決定］↔［枠を決めなおす］の切替は sgSyncOrient がまとめて書く
     * （値はシートの orient / frameFixed 1つ）。 */
    ['sgOriToggle', 'sgOri5Toggle'].forEach(function (id) {
      var b = $(id);
      if (!b) return;
      b.addEventListener('click', function () {
        var sh = curSheet();
        setSheetOrient((sh && sh.orient === 'landscape') ? 'portrait' : 'landscape');
        sgSyncOrient();      // 2行目の「いま: …」を押した結果に合わせる
      });
    });
    $('sgFit').addEventListener('click', fitBothPoints);
    $('sgFix').addEventListener('click', toggleFrameFixed);
    /* ④: 表示切替の〇（🔒 §28-5 B・Step 3／🔒 §28-14 ④ で道具の上へ移設）。
     * 上部バーの #underlaySel / #underlayOff と**同じ値**を書き換えるだけ
     * （新しい状態は持たない・sgUnderlayPick 参照）。
     * 🔒 §28-14 ④: Google も**下敷きの〇**（地図・航空写真の2つ）。別タブのボタンは
     *    ④から外した（右パネルの #linkGoogle は従来どおり残っている）。 */
    document.querySelectorAll('#sgUnderlay input[name="sgUnderR"]').forEach(function (r) {
      r.addEventListener('change', function () {
        if (this.checked) sgUnderlayPick(this.value);
      });
    });
    /* ④: ［交差点名・バス停名を地図に重ねる］（🔒 §28-13 決定3・Step 4）。
     * 🔴 案件には保存しない画面の状態。図形にもならず紙にも出ない。 */
    /* 🔒 §30-28-2 9: 道具メニューの▼にも同じチェックがある（値は1つ・setNameLay）。 */
    NAME_LAY_BOXES.forEach(function (id) {
      var b = $(id);
      if (b) b.addEventListener('change', function () { setNameLay(this.checked); });
    });
    /* 🔒 §30-32-6 3: 配置図の下敷きの操作の並びの［マーカーを表示］
     * （器は #hzUnderBar の中に1つ＝段を移っても配線は1回きり）。 */
    if ($('hzPinShow')) $('hzPinShow').addEventListener('click', showPinsOnSheet);
    /* 🔒 §30-16: ［クリックした名前を図に入れる］。もう一度押すと終わる。 */
    NAME_LAY_PICKS.forEach(function (id) {
      var b = $(id);
      if (b) b.addEventListener('click', toggleNamePick);
    });
    /* 🔒 §30-13-2 所在図④-2: 本文の［所在図プレビュー］（旧 #sgPrev）は削除した。
     * ⑧は下部（#sgFoot の data-act="szPrev"）＝ sgAct が navShowPreview('shozaizu') を呼ぶ。
     * 右パネルの #szPrev は従来どおり runShozaizuPreview のまま。 */
    /* 🔒 §30-13-3: 所在図プレビューの下部ボタン（ガイダンス⑧から出した時だけ出る）。 */
    $('exPreviewFoot').addEventListener('click', function (e) {
      var b = e.target && e.target.closest && e.target.closest('button[data-exfoot]');
      if (b && !b.disabled) exFootAct(b.dataset.exfoot);
    });

    /* ---- 配置図の段（🔒 §29-1・Step 6） ----
     * 🔴 どれも**既存の関数をそのまま呼ぶ**（§28-1 ④）。新しい状態は持たない。 */
    /* ⑤: 下敷きの〇（④①と同じ唯一の出入口 sgUnderlayPick） */
    document.querySelectorAll('#sgUnder5 input[name="sgUnder5R"]').forEach(function (r) {
      r.addEventListener('change', function () {
        if (this.checked) sgUnderlayPick(this.value);
      });
    });
    /* ⑤: ［写真を取り込む］＝📷ウィザード① の［画像を選ぶ］と**同じファイル欄**。
     * 取り込みの中身（自動配置・地図OFF＋画像ON）も importImage が1か所で決める。 */
    $('sgImgPick').addEventListener('click', function () { $('imgFile').click(); });
    $('sgImgOpacity').addEventListener('input', function () {
      setImgOpacity(this.value, 'sg');
    });
    /* 🔒 §30-14-1: ⑤の紙の向きの〇2つ（#sgOrient5）は廃止した。
     * 切替は上の ['sgOriToggle','sgOri5Toggle'] の配線1か所。 */
    /* ⑤: ［駐車場に寄る］（道具メニューの #btnFocusLot と同じ関数）／［枠を決定］ */
    $('sgFocusLot').addEventListener('click', focusLot);
    $('sgFix5').addEventListener('click', toggleFrameFixed);
    /* ⑦: ［台数を指定して置く…］は上部バー2行目の #tbStampSpec と同じ窓
     *     （下の ['sgStampSpec7','sgStampSpec4','tbStampSpec'] の配線でまとめて受ける）。
     * ⑦: ［写真から枠を描く］＝旧📷ウィザード③の［車両枠を描く］と同じ関数。 */
    $('sgFillRun').addEventListener('click', sgRunFill);
    $('sgFillCount').addEventListener('keydown', function (e) {
      if (e.key === 'Enter') { e.preventDefault(); sgRunFill(); }
    });
    /* ⑦［詳しい設定］（🔒 §29-3 裁定6・旧📷ウィザードの上級オプション）。
     * 🔴 押した結果は右パネルの「枠を並べる」と同じ物へ写すだけ（処理は1本）。 */
    $('sgFillPreset').addEventListener('change', function () {
      var p = StampPanel.PRESETS[this.value];
      if (p && p.w) { $('sgFillW').value = p.w; $('sgFillH').value = p.h; }
    });
    document.querySelectorAll('input[name="sgFillDir"]').forEach(function (r) {
      function apply() {
        var box = document.querySelector('input[name="fillDir"][value="' + r.value + '"]');
        if (box) box.checked = true;
        if (r.value === 'edge') startEdgePick();
        else stopEdgePick();
      }
      r.addEventListener('change', function () { if (this.checked) apply(); });
      r.addEventListener('click', function () { if (this.checked) apply(); });
    });
    /* ③: ［標準に戻す］＝右の浮き窓の［標準の設定で作る］と**同じ関数**
     * （SZ_STD を書き戻して作り直す・§28-4）。設定盤そのものは移してきた部品なので、
     * 5段階・2択の配線はここでは何もしない（1系統のまま）。 */
    $('sgSzStd').addEventListener('click', function () { runShozaizuStandard(); });
    /* ---- 所在図の設定盤の配線（🔒 2026-09-03 の再構成） ----
     * 5段階も2択も作法は同じ:
     *   ①案件データに覚えさせる ②画面（2か所あるなら両方）をそろえる
     *   ③既に所在図があるならその場で作り直す
     * 🔴 作り直すのは source:'shozaizu' の自動生成物だけ。手で描いた図形は消えず、
     *    役割ラベル（使用の本拠・駐車場・距離）も動かない（§18-r/§18-ab の作法のまま）。 */
    Object.keys(SZ_GRADES).forEach(function (which) {
      var g = SZ_GRADES[which];
      var sel = g.names.map(function (n) { return 'input[name="' + n + '"]'; }).join(', ');
      document.querySelectorAll(sel).forEach(function (r) {
        r.addEventListener('change', function () {
          if (!this.checked) return;
          /* 🔒 §30-40-2 1: 段の丸めは gradeClamp 1か所（名前の行だけ「自動」＝0 を
           * 通す。旧コードの `Number(v) || GRADE_STD` は 0 を標準に化けさせる）。 */
          var lv = gradeClamp(which, this.value);
          if (state.current) state.current[g.key] = lv;
          syncGradePick(which, lv);            // 2か所あれば揃える（目標物）
          szSettingChanged(g.ja);
        });
      });
    });
    Object.keys(SZ_TOGGLES).forEach(function (which) {
      var t = SZ_TOGGLES[which];
      var box = $(t.el);
      if (!box) return;
      box.addEventListener('change', function () {
        var v = t.bool ? this.checked : (this.checked ? t.on : t.off);
        if (state.current) state.current[t.key] = v;
        szSettingChanged(t.ja);
      });
    });
    /* 🔒 §30-22-2 2: 段数が5でない項目（名前の位置）。作法は5段階と同じ */
    Object.keys(SZ_PICKS).forEach(function (which) {
      var g = SZ_PICKS[which];
      document.querySelectorAll('input[name="' + g.name + '"]').forEach(function (r) {
        r.addEventListener('change', function () {
          if (!this.checked) return;
          var v = Math.max(1, Math.min(g.max,
            Math.round(Number(this.value) || Number(SZ_STD[g.key]))));
          if (state.current) state.current[g.key] = v;
          syncPickPick(which, v);
          szSettingChanged(g.ja);
        });
      });
    });
    /* 🔒 §29 Step 6: 旧⑤（多角形）・旧⑥（駐車枠）・旧⑦（道路）の小ウィンドウの
     * ボタン（#navPoly / #navRect / #navStamp / #navRoadLine / #navRoadPoly /
     * #navRoadCurve）は、左面のガイダンス⑥⑦⑧の **class="tool"** のボタンへ移した
     * （道具メニューと同じ共通ハンドラが setTool と is-active を1か所で受け持つ）。
     * ここにあった配線は、押す物が無くなったので削除した。 */
    // 台数が分かっている時のための従来の窓（正典 §4-4・幅と奥行の数値指定もここ）
    // 🔒 §29-1 ⑦: ガイダンスの［台数を指定して置く…］も同じ窓
    // 🔒 §30-22-3 2: 所在図④にも［台数を指定して置く…］（#sgStampSpec4）が出る
    // 🔒 §30-25-12 2 ③: 配置図③は ▼ の中の #sgStampSpec → 行の #sgStampSpec7 へ
    ['sgStampSpec7', 'sgStampSpec4', 'tbStampSpec'].forEach(function (id) {
      var b = $(id);
      if (!b) return;
      b.addEventListener('click', function () {
        if (!state.editor) return;
        state.editor.setTool('stamp');
        state.stamp.open();
      });
    });
    // ⑨⑩ 幅矢印（正典 §18-f・🔒 §29 Step 7 で左面へ）。道具は既存の arrow をそのまま使う
    ['sgRoadArrow', 'sgGateArrow'].forEach(function (id) {
      $(id).addEventListener('click', function () {
        if (!state.editor) return;
        /* 🔒 §30-29-7 1: 「道幅入力」で欄が空でも止めない（旧・§30-18-4／§30-29-6 5 の
         * 「幅を入れてください」で止める作法を差し替え）。上部バーの窓（#tbArrowBtn・
         * 1933行目付近）と同じく、そのまま矢印の道具に入る＝矢印だけ置ける
         * （editor.js が state.arrowMode から o.noAuto:true を付ける＝§30-29-4）。 */
        state.editor.setTool('arrow');
        /* 🔒 §18-l: 幅欄に値があれば、その値を添えた（手入力ラベル確定済みの）矢印になる。
         * 値の受け渡しは既存の editor.arrowWidth ＝ 正典 §4-6 の仕組みをそのまま使う。
         * 🔒 §25-5: 空欄のまま引いた矢印は**地図から計算した距離**が入る
         * （実測値が分かったら選んで「表示」欄に手入力すると上書きできる）。
         * 🔒 §30-29-7 1: 「道幅入力」で欄が空の時は、地図から計算した距離ではなく
         *    矢印だけ（文字なし）になる（上部バーの窓と同じ一言・§30-29-4）。 */
        var w = String(state.editor.arrowWidth || '').trim();
        if (state.arrowMode === 'manual') {
          hint(w ? ('端から端までドラッグすると「' + w + (/m$/.test(w) ? '' : 'm')
                    + '」を添えて矢印を書き込みます')
                 : '幅を入れずに引くと、矢印だけを書き込みます（あとで「表示」欄に入れられます）',
               4500);
        } else {
          hint('端から端までドラッグすると、地図から計算した幅が入ります', 4500);
        }
      });
    });
    /* ⑤⑥「文字を置く」欄（🔒 §30-18-4・2026-09-13 オーナー指示）。
     * 🔴 定型は**共通ハンドラ1つ**（data-preset を読むだけ・表示文字列では分岐しない）。
     *    押した後に地図をクリックした所へ置き、1回で解除する（textPreset の作法）。
     * 🔴 旧 §22-z の［「道路」の文字を置く］（押した瞬間に地図の中央へ置く）は
     *    置き場所を選べないので廃止した（#sgRoadText / #sgGateText も無くなった）。 */
    /* 🔒 §30-29-1 2: 言葉のボタンは **TEXT_PRESETS から JS が組む**ようになったので、
     *    配線は**委譲1本**にした（後から作った物にも同じ処理が効く＝配線を増やさない）。
     * 🔴 判定は data-preset（class）だけ・表示文字では分岐しない。 */
    document.addEventListener('click', function (e) {
      var t = e.target;
      if (!t || !t.closest) return;
      var w = t.closest('.sg-preset');
      if (w) { navTextPreset(w.dataset.preset); return; }
      if (t.closest('.sg-textfree')) navTextFree();
    });
    /* ⑤⑥ 幅の決め方のトグル（🔒 §30-18-4）。値は arrowWidth 1つのまま（§18-l）。
     * 🔒 §30-28-2 6: 道具メニューの #sideArrowMode も同じ配線（表は ARROW_FIELDS）。 */
    ARROW_FIELDS.forEach(function (f) {
      var box = $(f.box);
      if (!box) return;
      box.addEventListener('change', function (e) {
        var t = e.target;
        if (!t || t.type !== 'radio') return;
        setArrowMode(t.value, f.from);
        sgRenderStatus();
      });
    });
    /* ⑪ 駐車位置ラベル（🔒 §29-1・Step 7 で左面へ）。行の中身も置き方も
     * 道具メニューの #plPanel と**同じ関数**（接頭辞だけ 'lb' / 'pl' で分ける）。 */
    $('lbAdd').addEventListener('click', function (e) {
      e.preventDefault();
      addCustomRow('lbCustom');
    });
    $('sgLabelPlace').addEventListener('click', function () { labelArm('lb'); });
    /* ⑫（🔒 §30-27-1 7）: この段は［プレビュー］［PDFにして保存］の2ボタンだけ。
     * プレビューは**唯一の画面**（配置図から見せるだけ。中のトグルで所在図も見られる）。
     * ［PDFにして保存］＝出す紙を選ぶ窓（§30-27-2）。 */
    $('sgPrevAll').addEventListener('click', function () { navShowPreview('haichizu'); });
    $('sgSavePdf').addEventListener('click', function () { exPickOpen('pdf'); });
    /* 駐車位置ラベルの小ウィンドウ（🔒 §22-ab・道具メニューから単独で使う） */
    $('btnLabelBlock').addEventListener('click', function () {
      if ($('plPanel').hidden) plOpen(); else plClose();
    });
    $('plAdd').addEventListener('click', function (e) {
      e.preventDefault();
      addCustomRow('plCustom');
    });
    $('plPlace').addEventListener('click', function () { labelArm('pl'); });
    $('plCancel').addEventListener('click', plClose);
    /* ［標準の値］（🔒 §30-22-4 10 / §30-22-6 1）。ガイダンス⑦と小ウィンドウの2か所、
     * 中身は**同じ関数**（値の出どころは LABEL_STD 1か所）。 */
    [['lbStd', 'lb'], ['plStd', 'pl']].forEach(function (kv) {
      var b = $(kv[0]);
      if (b) {
        b.addEventListener('click', function (e) {
          e.preventDefault();
          labelSetStd(kv[1]);
        });
      }
    });
    /* 多角形ツールの使い方動画（🔒 §22-ah）。かぶせの外側を押しても閉じる */
    $('vidClose').addEventListener('click', vidClose);
    $('vidBox').addEventListener('click', function (e) {
      if (e.target === this) vidClose();
    });
    // 🔒 §22-z: ⑫の［A4 プレビューを表示］は自動で出るので下部には置かない
    //    （⑫へ入る navEnterFinish() がプレビューを出す）。段の中の
    //    ［プレビュー（全部の紙）］で何度でも出し直せる
    $('dfClear').addEventListener('click', function () {
      var n = state.editor.clearGenerated();
      hint(n ? ('自動生成した ' + n + ' 個を消しました') : '自動生成した図形はありません', 3000);
    });
    /* 幅矢印の「幅」欄は道具メニューとガイダンス⑤⑥の3か所（🔒 §18-l で同期させる）。
     * 🔒 §30-28-2 6: 欄の一覧は ARROW_FIELDS 1か所（配線もこの1か所）。 */
    ARROW_FIELDS.forEach(function (f) {
      var el = $(f.inp);
      if (!el) return;
      el.addEventListener('input', function () {
        setArrowWidth(this.value, f.from);
        sgRenderStatus();
      });
    });
    /* 枠の番号の開始値は3か所（道具メニュー／配置図③／所在図④）だが値は1つ
     * （🔒 §30-18-2 → 🔒 §30-25-8）。🔴 欄の一覧は NUM_START_FIELDS 1か所。
     * 🔒 §30-25-33（2026-09-14 オーナー指示「数字を入力してそのまま駐車枠を
     *   なぞると反映されない」）: **input**（1文字ごと）で写す。change（欄を離れた
     *   時だけ）では、欄に打ってすぐ地図をなぞる操作に間に合わない。 */
    NUM_START_FIELDS.forEach(function (f) {
      var el = $(f.id);
      if (!el) return;
      el.addEventListener('input', function () { setNumberStart(this.value, f.from); });
    });
    $('textSize').addEventListener('change', function () {
      if (state.editor) state.editor.textSize = this.value;
    });
    /* 🔒 2026-08-19（正典 §16-10-d-4 / §9-j 注記）: 寸法の自動記入トグルは撤去した。
     * 寸法が図に出るのは (a)「表示」欄への手入力 (b) 図形を選んで
     * ［寸法(m)を図に出す］を入れた時だけ。書き出しも同じ規則。 */
    /* 🔒 §30-29-1 2: 旧・道具メニューの定型文の選択肢（#textPreset の <select>）は
     * 廃止した。定型は上部バー2行目の［A］→ #textPick の言葉のボタン
     * （.sg-preset の共通ハンドラ）だけ＝値は state.editor.textPreset 1つのまま。 */
    $('btnUndo').addEventListener('click', function () {
      if (state.editor) { state.editor.undo(); updateHistoryButtons(); }
    });
    $('btnRedo').addEventListener('click', function () {
      if (state.editor) { state.editor.redo(); updateHistoryButtons(); }
    });
    $('imgRemove').addEventListener('click', clearRecogLines);

    /* ---- 選択中の図形パネル ---- */
    $('propDel').addEventListener('click', function () {
      if (state.editor) state.editor.deleteSelected();
    });
    $('propDup').addEventListener('click', function () {
      if (state.editor) state.editor.duplicateSelected();
    });
    ['propW', 'propH', 'propAngle', 'propLabel', 'propShowDims', 'propCount',
     'propCellW', 'propCellH', 'propStampAngle', 'propStagger', 'propStampShowDims',
     'propArrowLabel', 'propTextValue', 'propTextSize',
     // 🔒 §25-4: 主役マークの大きさ・向き（色はボタンなので別配線）
     'propMarkW', 'propMarkH', 'propMarkAngle'].forEach(function (id) {
      $(id).addEventListener('change', applyPropInputs);
      $(id).addEventListener('keydown', function (e) {
        if (e.key === 'Enter') { e.preventDefault(); applyPropInputs(); this.blur(); }
      });
    });

    /* ---- テキストのその場入力 ---- */
    $('textInput').addEventListener('keydown', function (e) {
      if (e.key === 'Enter') { e.preventDefault(); commitTextInput(); }
      else if (e.key === 'Escape') { e.preventDefault(); hideTextInput(); }
    });
    $('textInput').addEventListener('blur', function () {
      if (!$('textBox').hidden) commitTextInput();
    });
    /* 🔒 §30-15-4: ［OK］は Enter と同じ（確定）。
     * 🔴 mousedown で既定動作を止める＝入力欄の focus を外さない。止めないと
     *    blur が先に走って、押した時にはもう確定済み（二度手間）になる。 */
    $('textOk').addEventListener('mousedown', function (e) { e.preventDefault(); });
    $('textOk').addEventListener('click', function () { commitTextInput(); });

    /* ---- ズーム操作（作図倍率） ---- */
    $('btnZoomIn').addEventListener('click', function () { stepZoom(1); });
    $('btnZoomOut').addEventListener('click', function () { stepZoom(-1); });
    $('btnFocusLot').addEventListener('click', focusLot);
    $('btnFitBoth').addEventListener('click', fitBothPoints);

    /* 🔒 §30-13-4: 窓の大きさが変われば、左面と枠の間の空きも変わる。
     * 🔴 連打を避けるため 120ms まとめてから置き直す。 */
    var capRz = null;
    window.addEventListener('resize', function () {
      /* 🔒 §30-25-10 3: プレビューの「文字の箱」も画像の表示倍率で決まるので、
       * 窓の大きさが変わったら引き直す（画像はすぐ縮むのでまとめない）。 */
      exRelayout();
      if (capRz) clearTimeout(capRz);
      capRz = setTimeout(function () { capRz = null; sgCaptionPlace(); }, 120);
    });

    /* 🔒 §27-9 持ち越し対応（オーナー指示 2026-09-04）:
     * 「保存が終わっていない時だけ、タブを閉じる/再読み込みを引き止める」。
     * beforeunload の中では非同期の完了を待てない（仕様）ので、
     * 「その場で書き込みを開始しておき、確認ダイアログが出ている間に終わらせる」
     * という考え方で実装する。保留が無ければ絶対に引き止めない
     * （保存済みなのにダイアログが出ると邪魔なだけ）。 */
    window.addEventListener('beforeunload', function (e) {
      if (!Store.hasPendingSave()) return;   // 保留無し＝何もしない（ダイアログも出さない）
      Store.flush();                         // 🔴 待てないので開始するだけ（fire-and-forget）
      e.preventDefault();                    // 確認ダイアログを出す（文面はブラウザ固定）
      e.returnValue = '';                    // 一部ブラウザはこちらも必要
    });
    /* 🔴 §27-7③: フォルダ運用の書き込みは非同期なので、beforeunload では
     * 間に合わないことがある（localStorage の同期書き込みと違う点）。
     * タブを離れた時点で確定させておけば、そのまま閉じられても失われない。
     * （ダイアログを出す仕組みとは別に、無条件の確定は引き続き併用する） */
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'hidden') Store.flush();
    });
  }

  /* 🔒 §30-5（2026-09-08 オーナー指示・🙋 仮値）: fitBothPoints の余白。
   * 旧 0.4 は引きすぎ（枠の半分近くが余白になり、必要以上に ZL が下がっていた）。
   * ここ1か所を変えれば［2地点を表示］［2つのマーカーが入るように動かす］の両方に効く。
   * この pad は fitPoints の**整数ZLの粗い探索**の当たりを付けるだけで、実際にどこまで
   * 寄せるかは下の fitBothMaximizeZoom が 0.5 刻みの梯子で決め直す。 */
  var FIT_BOTH_PAD = 0.12;

  /* 🔒 §30-23（2026-09-13 オーナー実機・岩上町147 を ZL19 で作って「ハイツ岩上」しか
   * 出ない）: **所在図の自動ズームの上限**。2地点が近いと枠が横 150m ほどまで寄り、
   * 250〜500m 先の変電所・公園・団地が枠の外＝紙に描けない。所在図は ZL16〜17
   * （1:2,000〜4,000）で作る図なので、自動で寄せるのはここまでにする。
   * 🔴 手で拡大するのは自由（ホイール・［＋］は素通り）。ここが効くのは
   *    ［2つのマーカーが入るように地図を動かす］＝ fitBothPoints の系統だけ。
   * 🔴 配置図は ZL20 で駐車場を描く図なので上限を掛けない（下の fitBothMaxZoom）。 */
  var FIT_BOTH_MAX_ZL = 17.5;

  /** いまの図で自動ズームが寄れる上限（所在図だけ §30-23 の上限が効く） */
  function fitBothMaxZoom() {
    return (state.kind === 'shozaizu') ? FIT_BOTH_MAX_ZL : Infinity;
  }

  /**
   * 2地点が**紙になる枠（青い破線）**に収まるところへ地図を動かす。
   * 道具メニューの［2地点を表示］と、ガイダンス②の
   * ［2つのマーカーが入るように地図を動かす］（🔒 §28-3・Fable 追加提案）の共通処理。
   * 🔴 §22-an「生成で勝手に動かさない」は保ったまま＝**押した時だけ**動く。
   *
   * 🔒 §28-14 ②（2026-09-07 オーナー指示）: 画面に入っているだけで枠から出ている状態を
   *   「入った」と言わない。**枠の画面px を窓として渡し**（§18-n の box）、
   *   入るまで ZL も下げる。枠は画面の半分ほどしかないので、画面基準だと必ず外れる。
   * 🔴 枠を**決定済み**の紙は、枠が地理的に固定＝地図を動かしても枠との関係は
   *   変わらない。その時は［枠を決めなおす］が先だと伝えて、画面基準で寄せるだけにする。
   */
  function fitBothPoints() {
    var c = state.current;
    if (!c) return;
    var pts = [c.points.home, c.points.lot].filter(Boolean);
    if (!pts.length) { hint('先にマーカーを置いてください', 2500); return; }
    var sh = curSheet(), box = null;
    if (sh && sh.frameFixed && sh.frame) {
      hint('枠は決定済みです。枠ごと動かすには［枠を決めなおす］を押してください', 4500);
    } else {
      try {
        var r = frameRectPx();
        if (r && r.w > 0 && r.h > 0) box = { w: r.w, h: r.h };
      } catch (e) { box = null; }
    }
    state.map.fitPoints(pts, FIT_BOTH_PAD, box);
    /* 🔒 §30-23: 粗い探索が上限より寄ってしまった時はここで引き戻す
     * （下の fitBothMaximizeZoom は box がある時しか呼ばれないので、両方で押さえる）。 */
    if (state.map.getZoom() > fitBothMaxZoom()) {
      state.map.setView(null, fitBothMaxZoom());
    }
    /* 🔒 §30-5: fitPoints は整数ZL刻みの粗い探索なので、box があり2点とも揃っている
     * 時だけ、0.5刻みの梯子で「枠に2点とも入る最大のZL」まで寄せ直す。 */
    if (box && pts.length === 2) fitBothMaximizeZoom();
    persistSheetState();
    if (state.nav) navRender();      // ガイダンス②の「枠の中か」を引き直す
  }

  /**
   * 🔒 §30-5: fitBothPoints が確定したズームから、0.5刻みの梯子（zoomLadder）を
   * 1段ずつ上げながら「枠に2点とも入るか」を試し、入る**最大**のZLで止める。
   * 判定は sgPointsInFrame と同じ（frameRectPx は画面基準＝ズームに依らない）。
   * 🔴 枠が決定済みの紙は fitBothPoints 側で box を渡さない（呼ばれない）。
   * 🔴 探索中の中間ズームは silent（change/viewend を出さない）。最後に1回だけ
   *    本発火させる＝下敷きタイルへの無駄な再要求・保存の連打を避ける。
   */
  function fitBothMaximizeZoom() {
    if (!state.map) return;
    /* 🔒 §30-23: はしごの段を上げる時に上限（所在図は ZL17.5）を超えない。
     * 上限より上の段をはしごから外す＝下の while が自然にそこで止まる。 */
    var maxZ = fitBothMaxZoom();
    var ladder = state.map.zoomLadder().filter(function (z) { return z <= maxZ; });
    if (!ladder.length) return;
    var idx = ladder.indexOf(state.map.getZoom());
    if (idx < 0) return;
    var center = state.map.getCenter();
    var last = idx;
    while (idx < ladder.length - 1) {
      state.map.setView(center, ladder[idx + 1], true);   // 判定だけ・静かに動かす
      var inf = sgPointsInFrame();
      if (inf.home === false || inf.lot === false) break;  // 枠から出た＝1段前が最大
      idx++; last = idx;
    }
    state.map.setView(center, ladder[last]);   // 確定（change/viewend を発火）
  }

  function stepZoom(d) {
    if (!state.map) return;
    state.map.setView(null, state.map.stepZoom(d));
    persistSheetState();
  }

  /** スケールバーと現在倍率の表示 */
  function updateScale() {
    if (!state.map) return;
    /* 🔒 §18-ae: 配置図では画面左下の**長さの基準（スケールバー）を出さない**。
     * 縮尺を持たない図なので、目盛りがあると「この比率で刷られる」と誤解される。
     * ZL と「1px ≒ ◯m」は作図の手がかりなので残す。 */
    var sb = document.querySelector('.map-scale .scale-bar');
    if (sb) sb.style.display = (state.kind === 'haichizu') ? 'none' : '';
    var mpp = state.map.metersPerPixel();
    // 目盛りが 60〜160px に収まる「きりのいい距離」を選ぶ
    var cands = [0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000];
    var m = cands[0];
    for (var i = 0; i < cands.length; i++) {
      if (cands[i] / mpp <= 160) m = cands[i];
    }
    var px = Math.round(m / mpp);
    $('scaleBar').style.width = px + 'px';
    $('scaleText').textContent = m >= 1000 ? (m / 1000) + 'km' : m + 'm';
    var z = state.map.getZoom();
    /* 🔒 §30-14-2: 0.25 刻みが入ったので小数1桁だと 18.25 が「ZL18.3」になる。
     * 端数のある時だけ「余分な 0 を落とした値」をそのまま出す（18.5 / 18.25）。 */
    $('zoomText').textContent = 'ZL' + (z % 1 ? String(Math.round(z * 100) / 100) : z)
      + '（1px ≒ ' + (mpp >= 1 ? mpp.toFixed(1) + 'm'
                              : (mpp * 100).toFixed(mpp < 0.05 ? 1 : 0) + 'cm') + '）';
    $('btnZoomIn').disabled = (state.map.stepZoom(1) === z);
    $('btnZoomOut').disabled = (state.map.stepZoom(-1) === z);
    var oz = state.map.underlayOverzoom || 1;
    $('overzoomNote').textContent = oz > 1.001
      ? '拡大表示中（下敷き画像は粗くなります）' : '';
  }

  function updateHistoryButtons() {
    var e = state.editor;
    $('btnUndo').disabled = !e || !e.canUndo();
    $('btnRedo').disabled = !e || !e.canRedo();
    // 作図中は「1クリック戻す」であることをボタンに出す
    var pt = e && e.canUndoPoint();
    $('btnUndo').textContent = pt ? '↶ 1つ戻す' : '↶ 戻す';
    $('btnUndo').title = pt
      ? '直前に打った点を1つ取り消します (Backspace)'
      : '元に戻す (Ctrl+Z)';
  }

  /** 選択内容に合わせて右パネルを出し入れする */
  function renderPropPanel(sel) {
    var panel = $('propPanel');
    /* 🔒 §30-25-40 4: 「印の大きさ」は**文字の欄の外**に置く（印つき文字だけでなく
     * 主役の■＝四角を選んだ時にも同じ行を出すため）＝ここで一緒に伏せる。 */
    ['propRect', 'propMark', 'propMainPoly', 'propStamp', 'propArrow', 'propText',
     'propLabelBlock', 'propMarkSize', 'propStorage'].forEach(function (id) {
      $(id).hidden = true;
    });
    if (!sel || !sel.length) { panel.hidden = true; return; }
    panel.hidden = false;

    var multi = sel.length > 1;
    $('propMulti').hidden = !multi;
    if (multi) { $('propMulti').textContent = sel.length + ' 個を選択中'; return; }

    var o = sel[0], f1 = function (v) { return (Math.round(v * 10) / 10).toFixed(1); };
    /* 🔒 §25-4: 主役マークは rect だが車両枠ではない。専用の欄を出す
     * （寸法の欄は出さない＝マークに寸法ラベルは付かない） */
    /* 🔒 §30-22-1 4: 主役の多角形（rect ではなく polygon の主役マーク）。
     * 線の太さ・色・斜線だけを出す（寸法は持たない＝四角の印と同じ考え方）。 */
    if (o.type === 'polygon' && o.role === 'mainmark') {
      $('propMainPoly').hidden = false;
      $('propMpWhat').textContent =
        (o.markRole === 'lot' ? '駐車場' : '使用の本拠') + 'の印（多角形）';
      renderPolyStyle(o);
      return;
    }
    if (o.type === 'rect' && o.role === 'mainmark') {
      $('propMark').hidden = false;
      $('propMarkWhat').textContent =
        (o.markRole === 'lot' ? '駐車場' : '使用の本拠') + 'の印（所在図）';
      /* 🔒 §30-31-1 3: 幅／奥行は**案件の points[key].mark.w_m/h_m** が出どころ
       * （辺つまみ・右パネルの欄・紙の■が全部この値を読む）。 */
      var mkDim = markOf(mainMarkKeyOf(o) || 'home');
      $('propMarkW').value = f1(mkDim.w_m);
      $('propMarkH').value = f1(mkDim.h_m);
      $('propMarkAngle').value = Math.round(o.angle || 0);
      renderMarkColors(o);
    } else if (o.type === 'rect') {
      $('propRect').hidden = false;
      $('propW').value = f1(o.w_m);
      $('propH').value = f1(o.h_m);
      $('propAngle').value = Math.round(o.angle || 0);
      $('propLabel').value = o.labelOverride || '';
      $('propShowDims').checked = (o.showDims !== false);
    } else if (o.type === 'stampGroup') {
      $('propStamp').hidden = false;
      $('propCount').value = o.count;
      $('propCellW').value = f1(o.cell_w_m);
      $('propCellH').value = f1(o.cell_h_m);
      $('propStampAngle').value = Math.round(o.angle || 0);
      $('propStagger').value = (Math.round((o.stagger_m || 0) * 10) / 10).toFixed(1);
      $('propStampShowDims').checked = (o.showDims !== false);
    } else if (o.type === 'arrow') {
      $('propArrow').hidden = false;
      $('propArrowLabel').value = o.label || '';
      /* 🔒 §30-29-4 2: 「幅を入力」で引いた矢印（noAuto）は空欄でも計算しないので、
       * 例示（プレースホルダ）もその矢印に合わせる（判定は o.noAuto だけ）。 */
      $('propArrowLabel').placeholder = o.noAuto ? '空欄=数字を出さない' : '空欄=地図から計算';
    } else if (o.type === 'text') {
      $('propText').hidden = false;
      $('propTextValue').value = o.text || '';
      $('propTextSize').value = o.size || 'medium';
      /* 🔒 §30-22-3 3: いまの大きさ（紙のミリ）。右下のつまみで変わる連続値。 */
      $('propTextMm').textContent = '紙に刷られる高さ: 約 '
        + (Math.round(Editor.textMm(o) * 10) / 10).toFixed(1)
        + ' mm（文字の右下のつまみをドラッグしても変えられます）';
    } else if (o.type === 'labelBlock') {
      $('propLabelBlock').hidden = false;
      $('propLbLines').textContent = (o.lines || []).join(' / ');
    }
    /* 🔒 §30-25-18 4 / §30-25-40 4: 印の大きさ（印つき文字4種と、主役の◎・■）。
     * 出すか伏せるかは renderMarkSize の中で決める（対象の判定は1か所）。 */
    renderMarkSize(o);
    /* 🔒 §30-22-4 9: 保管場所マークの書式（色／斜線／太線）。
     * 印そのものは選べない（枠に付く物）ので、**付いている図形を選んだ時**に出す。 */
    if (storageOf(o)) {
      $('propStorage').hidden = false;
      renderStorageFmt(o);
    }
  }

  /* 🔒 §30-25-18 4（2026-09-14 オーナー指示）: 右パネルの「印の大きさ」。
   * 🔴 値の出どころは**印の右下のつまみと同じ1か所**（印つき文字＝図形の
   *    `markScale` ／ 主役の◎・■＝案件の `points[key].mark.scale`）。
   *    上下限は Editor.clampMarkScale が持つ（ここには書かない）。 */
  /* 🔒 §30-25-40 4: ▼「印を変える」の行は廃止。この表を読むのは**右パネルだけ**
   * （印つき文字4種と、主役の印＝◎・■の両方に同じ4段が出る）。 */
  var MARK_SIZE_BTNS = [{ ja: '小', v: 0.7 }, { ja: '標準', v: 1 },
                        { ja: '大', v: 1.5 }, { ja: '特大', v: 2 }];

  /**
   * 🔒 §30-25-40 4: その図形が**主役の印**（◎＝主役の文字／■＝主役の四角）なら
   * どちらの地点の物かを返す（そうでなければ null）。
   * 🔴 主役の印かどうかの判定は Editor.mainMarkKeyOf 1か所（role / dotStyle /
   *    markRole で見る）。主役の文字の地点は pinKeyOf（旧案件の保険つき）。
   */
  function mainMarkKeyOf(o) {
    if (!o || !window.Editor || !Editor.mainMarkKeyOf) return null;
    var k = Editor.mainMarkKeyOf(o);
    if (!k) return null;
    return (o.type === 'text') ? pinKeyOf(o) : k;
  }

  /** 🔒 §30-25-40 4: いま「大きさを変えられる印」が付いている主役か
   *  （◎か■の時だけ。印なし・多角形には大きさが無いので行を出さない）。 */
  function mainMarkSizableKey(o) {
    var k = mainMarkKeyOf(o);
    if (!k) return null;
    var sh = markOf(k).shape;
    return (sh === 'circle' || sh === 'rect') ? k : null;
  }

  /**
   * 印の大きさの行（右パネル）。対象は2種類:
   *   ・印つき文字4種（信号機・バス停・P・木）＝値は図形の markScale
   *   ・🔒 §30-25-40 4 主役の印（◎・■）＝値は案件の points[key].mark.scale
   */
  function renderMarkSize(o) {
    var box = $('propMarkSize');
    if (!box) return;
    var mainKey = mainMarkSizableKey(o);
    var isMark = !!mainKey
              || !!(window.Editor && Editor.keepsMark && Editor.keepsMark(o));
    box.hidden = !isMark;
    if (!isMark) return;
    // 🔴 読む値の出どころ: 主役＝ markOf(key).scale ／ 印つき文字＝ markScale
    var cur = mainKey ? markOf(mainKey).scale : Editor.markScaleOf(o);
    var fmt = $('propMarkSizeFmt');
    fmt.innerHTML = '';
    var row = document.createElement('div');
    row.className = 'prop-row';
    var k = document.createElement('span');
    k.className = 'prop-row-k';
    k.textContent = '印の大きさ';
    row.appendChild(k);
    MARK_SIZE_BTNS.forEach(function (b) {
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'fmt-btn' + (Math.abs(cur - b.v) < 0.005 ? ' is-on' : '');
      btn.textContent = b.ja;
      btn.title = '印の大きさ: ' + b.ja;
      btn.addEventListener('click', function () {
        if (!state.editor) return;
        /* 🔒 §30-25-40 4: 主役の印は**つまみとまったく同じ口**を通す
         * （値の出どころは points[key].mark.scale 1か所）。 */
        if (mainKey) setMainMarkScale(mainKey, b.v);
        else state.editor.applyMarkScale(o, b.v);
        renderPropPanel(state.editor.getSelected());
        updateHistoryButtons();
      });
      row.appendChild(btn);
    });
    fmt.appendChild(row);
    /* 🔒 §30-31-1 1: ■（四角の印）だけは**辺のつまみ**で縦・横を別々に変えられる
     * ので、その一言を足す（◎・印つき文字には辺つまみが無い）。
     * 🔴 形の判定は markOf(key).shape 1か所（表示文字では分岐しない）。 */
    var isRectMark = !!(mainKey && markOf(mainKey).shape === 'rect');
    $('propMarkScaleNow').textContent = 'いまの印の大きさ: '
      + (Math.round(cur * 100) / 100) + ' 倍'
      + '（印の右下のつまみをドラッグしても変えられます'
      + (isRectMark ? '。4辺のつまみなら縦・横だけを変えられます' : '') + '）';
  }

  /** その図形に付いている保管場所マークの書式（無ければ null・🔒 §30-22-4 9） */
  function storageOf(o) {
    if (!o || !o.storage) return null;
    var conf = Editor.storageConf;
    if (o.type === 'stampGroup') {
      var keys = Object.keys(o.storage);
      for (var i = 0; i < keys.length; i++) {
        if (o.storage[keys[i]]) return conf(o.storage[keys[i]]);
      }
      return null;
    }
    return conf(o.storage);
  }

  /**
   * 🔒 §30-22-1 4 / §30-24-1: 主役の多角形の「線の太さ・斜線・線の色」。
   * 🔴 出す所は**2か所**（①の▼「印を変える」の中 ／ 右パネル #propMpStyle）だが、
   *    組み立てはこの1関数（保管場所マークの storageFmtRows と同じ作法）。
   * 🔴 値の出どころは Editor.POLY_W / Editor.INK（editor.js の1か所）。
   * 🔒 §30-24-1: 文字のボタンではなく**アイコン**（線の太さの絵・斜線の絵・色の丸）。
   * @param box   入れ物
   * @param cur   いまの値 {width,color,hatch}
   * @param apply patch を受け取って値を変える関数
   */
  function polyFmtRows(box, cur, apply) {
    if (!box || !cur) return;
    box.innerHTML = '';
    var row = function (label) {
      var d = document.createElement('div');
      d.className = 'prop-row';
      var s = document.createElement('span');
      s.className = 'prop-row-k';
      s.textContent = label;
      d.appendChild(s);
      box.appendChild(d);
      return d;
    };
    var btn = function (on, title, svg, fn) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'fmt-btn fmt-ico' + (on ? ' is-on' : '');
      b.title = title;
      b.setAttribute('aria-label', title);
      b.innerHTML = '<svg viewBox="0 0 26 16" width="26" height="16" aria-hidden="true">'
        + svg + '</svg>';
      b.addEventListener('click', fn);
      return b;
    };
    var rw = row('線の太さ');
    (Editor.POLY_W || []).forEach(function (w) {
      rw.appendChild(btn((cur.width || 'normal') === w.key, '線の太さ: ' + w.ja,
        '<line x1="3" y1="8" x2="23" y2="8" stroke="currentColor" stroke-linecap="round"'
        + ' stroke-width="' + w.w + '"/>',
        function () { apply({ width: w.key }); }));
    });
    var rh = row('斜線');
    [[true, '入れる'], [false, '入れない']].forEach(function (kv) {
      rh.appendChild(btn((cur.hatch !== false) === kv[0], '斜線を' + kv[1],
        '<rect x="3.5" y="2.5" width="19" height="11" fill="none" stroke="currentColor"'
        + ' stroke-width="1.2"/>'
        + (kv[0] ? '<path d="M5 13L10 3M11 13L16 3M17 13L22 3" stroke="currentColor"'
                 + ' stroke-width="1.1" fill="none"/>' : ''),
        function () { apply({ hatch: kv[0] }); }));
    });
    var rc = row('線の色');
    (Editor.INK || []).forEach(function (c) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'mark-color' + ((cur.color || 'black') === c.key ? ' is-on' : '');
      b.style.background = c.hex;
      b.title = '線の色: ' + c.ja;
      b.setAttribute('aria-label', '線の色 ' + c.ja);
      b.addEventListener('click', function () { apply({ color: c.key }); });
      rc.appendChild(b);
    });
  }

  /** その図形の書式（polyFmtRows に渡す形） */
  function polyFmtOf(o) {
    return { width: o.widthKey || 'normal', color: o.inkColor || 'black',
             hatch: o.hatch !== false };
  }

  /** 🔒 §30-24-1: いま選んでいる主役の多角形（key を渡すとその地点の物だけ） */
  function selectedMainPoly(key) {
    if (!state.editor) return null;
    var sel = state.editor.getSelected();
    for (var i = 0; i < sel.length; i++) {
      var o = sel[i];
      if (o && o.role === 'mainmark' && o.type === 'polygon'
          && (!key || (o.markRole || 'home') === key)) return o;
    }
    return null;
  }

  /**
   * 🔒 §30-24-1: 書式を反映する。**選んでいる多角形があればそれに**、
   * 何も選んでいなければ「次に描く多角形の既定」（画面の状態）に効く。
   */
  function applyPolyFmt(o, patch) {
    if (o && state.editor) {
      state.editor.applyMainPolyProps(o, patch);
      renderPropPanel(state.editor.getSelected());
      updateHistoryButtons();
    } else {
      if (patch.width) state.mainPolyDefault.width = patch.width;
      if (patch.color) state.mainPolyDefault.color = patch.color;
      if (patch.hatch !== undefined) state.mainPolyDefault.hatch = !!patch.hatch;
      if (state.editor) state.editor.mainPolyDefault = state.mainPolyDefault;
    }
    sgRenderMarks();
  }

  /** 右パネル（選んだ多角形の書式） */
  function renderPolyStyle(o) {
    polyFmtRows($('propMpStyle'), polyFmtOf(o), function (patch) {
      applyPolyFmt(o, patch);
    });
  }

  /** ①の▼の中（選んでいる多角形 → 無ければ次に描く多角形の既定） */
  function renderPolyFmt(box, key) {
    var o = selectedMainPoly(key);
    polyFmtRows(box, o ? polyFmtOf(o) : state.mainPolyDefault, function (patch) {
      applyPolyFmt(o, patch);
    });
  }

  /**
   * 🔒 §30-22-4 9: 保管場所マークの書式（色／斜線／太線）の3行。
   * 🔴 出す所は**2か所**（右パネル #propStorageFmt ＝選んだ印の書式／
   *    配置図⑦ #sgStorageFmt ＝これから置く印の既定）だが、**組み立てはこの1関数**。
   *    違うのは「いまの値（cur）」と「押した時にすること（apply）」だけ。
   * @param box  入れ物
   * @param cur  いまの値（Editor.storageConf の形）
   * @param apply patch を受け取って値を変える関数
   */
  function storageFmtRows(box, cur, apply) {
    if (!box || !cur) return;
    box.innerHTML = '';
    var row = function (label) {
      var d = document.createElement('div');
      d.className = 'prop-row';
      var s = document.createElement('span');
      s.className = 'prop-row-k';
      s.textContent = label;
      d.appendChild(s);
      box.appendChild(d);
      return d;
    };
    var rc = row('色');
    (Editor.INK || []).forEach(function (c) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'mark-color' + (cur.color === c.key ? ' is-on' : '');
      b.style.background = c.hex;
      b.title = c.ja;
      b.setAttribute('aria-label', c.ja);
      b.addEventListener('click', function () { apply({ color: c.key }); });
      rc.appendChild(b);
    });
    [['斜線', 'hatch', '入れる', '入れない'],
     ['太線', 'bold', 'する', 'しない']].forEach(function (r) {
      var d = row(r[0]);
      [[r[2], true], [r[3], false]].forEach(function (kv) {
        var b = document.createElement('button');
        b.type = 'button';
        b.className = 'fmt-btn' + (cur[r[1]] === kv[1] ? ' is-on' : '');
        b.textContent = kv[0];
        b.addEventListener('click', function () {
          var patch = {};
          patch[r[1]] = kv[1];
          apply(patch);
        });
        d.appendChild(b);
      });
    });
  }

  /** 右パネル: 選んだ図形に付いている保管場所マークの書式（🔒 §30-22-4 9） */
  function renderStorageFmt(o) {
    storageFmtRows($('propStorageFmt'), storageOf(o), function (patch) {
      state.editor.applyStorageProps(o, patch);
      renderPropPanel(state.editor.getSelected());
      updateHistoryButtons();
      sgRenderStorageFmt();     // ⑦の欄も同じ見た目に揃える
    });
  }

  /**
   * 🔒 §30-22-4 9 ＋ §30-22-7 4: 配置図⑦の「保管場所マークの書式」。
   * 🔴 ここで決めた書式は**これから置く印の既定**（Editor.storageDefault）。
   * 🔴 それだけだと「変えても画面が何も変わらない」ので、**いま編集中の紙に
   *    置いてある保管場所マークにも同じ書式を掛ける**（他の紙には触らない）。
   */
  function sgRenderStorageFmt() {
    if (!window.Editor || !Editor.storageDefault) return;
    /* 🔒 §30-28-2 7: 器は2か所（配置図⑦ #sgStorageFmt ／ 道具メニュー
     * #sideStorageFmt）だが、組み立ても値も1か所（storageFmtRows ＋ storageDefault）。
     * 🔴 器の一覧はこの表1か所。 */
    ['sgStorageFmt', 'sideStorageFmt'].forEach(function (id) {
      storageFmtRows($(id), Editor.storageDefault(), function (patch) {
        Editor.storageDefault(patch);
        applyStorageFmtHere(patch);
        sgRenderStorageFmt();
        if (state.editor) renderPropPanel(state.editor.getSelected());
      });
    });
  }

  /** いま編集中の紙に置いてある保管場所マーク全部に書式を掛ける（🔒 §30-22-4 9） */
  function applyStorageFmtHere(patch) {
    var ed = state.editor;
    if (!ed) return 0;
    var n = 0;
    (ed.objects || []).slice().forEach(function (o) {
      if (o && o.storage && ed.applyStorageProps(o, patch)) n++;
    });
    if (n) { updateHistoryButtons(); Store.autosave(state.current); }
    return n;
  }

  /**
   * 主役マークの色ボタン（🔒 §25-4 赤／オレンジ／黄）。
   * 新しい大きなUIは作らず、右パネルの選択中の図形の欄に3つ並べるだけにする。
   */
  function renderMarkColors(o) {
    var box = $('propMarkColors');
    box.innerHTML = '';
    (Editor.MARK.colors || []).forEach(function (c) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'mark-color' + (o.markColor === c.key ? ' is-on' : '');
      b.style.background = c.hex;
      b.title = c.ja;
      b.setAttribute('aria-label', c.ja);
      b.addEventListener('click', function () {
        var s = state.editor.getSelected();
        if (s.length !== 1 || s[0].role !== 'mainmark') return;
        state.editor.applyMarkProps(s[0], { markColor: c.key });
        /* 🔒 §28-14 ①-4 / §18-r-4: 色の真実は points[key].mark。ここで直した時も
         * そちらへ書き戻す（ガイダンス①の〇と食い違わせない・全シートも揃う）。 */
        var key = (s[0].markRole === 'lot') ? 'lot' : 'home';
        if (state.current && state.current.points[key]) {
          sgSetMark(key, { color: c.key });
        }
        renderPropPanel(state.editor.getSelected());
        updateHistoryButtons();
      });
      box.appendChild(b);
    });
  }

  function applyPropInputs() {
    if (!state.editor) return;
    var sel = state.editor.getSelected();
    if (sel.length !== 1) return;
    var o = sel[0], num = function (id) {
      var v = parseFloat($(id).value);
      return isNaN(v) ? undefined : v;
    };
    if (o.type === 'rect' && o.role === 'mainmark') {
      /* 🔒 §30-31-1 3: 幅／奥行の欄は**案件の points[key].mark.w_m/h_m** を
       * 読み書きする（辺つまみとまったく同じ口＝ setMainMarkDims 1か所）。
       * 向きだけは図形の値（applyMarkProps）。
       * 🔴 3つの欄は**先に全部読む**。applyMarkProps の commit() が右パネルを
       *    引き直すので、後から読むと打ち込んだ値が元に戻ってしまう。 */
      var mw = num('propMarkW'), mh = num('propMarkH'), ma = num('propMarkAngle');
      state.editor.applyMarkProps(o, { angle: ma });
      var mk = mainMarkKeyOf(o);
      if (mk) setMainMarkDims(mk, mw, mh);
    } else if (o.type === 'rect') {
      state.editor.applyRectProps(o, {
        w_m: num('propW'), h_m: num('propH'), angle: num('propAngle'),
        labelOverride: $('propLabel').value.trim(),
        showDims: $('propShowDims').checked
      });
    } else if (o.type === 'stampGroup') {
      state.editor.applyStampProps(o, {
        count: num('propCount'), cell_w_m: num('propCellW'),
        cell_h_m: num('propCellH'), angle: num('propStampAngle'),
        stagger_m: num('propStagger'),
        showDims: $('propStampShowDims').checked
      });
    } else if (o.type === 'arrow') {
      state.editor.applyArrowProps(o, { label: $('propArrowLabel').value });
    } else if (o.type === 'text') {
      state.editor.applyTextProps(o, {
        text: $('propTextValue').value, size: $('propTextSize').value
      });
    }
    renderPropPanel(state.editor.getSelected());
    updateHistoryButtons();
  }

  /* ---------- 自動下書き（正典 §11-b レーンA） ---------- */

  var mojProbed = false;
  function probeDraftSources() {
    if (mojProbed) return;
    mojProbed = true;
    $('dfNote').textContent = '法務省データの配信を確認しています…';
    AutoDraft.probeMoj().then(function (r) {
      $('dfNote').textContent = r.ok
        ? '筆界は整備済みの地域でのみ出ます（全国の約半分は未整備・都市部に多い）。'
        : '⚠ 法務省データの配信に接続できません。道路縁と建物だけ生成できます。';
      $('dfParcel').disabled = !r.ok;
      if (!r.ok) $('dfParcel').checked = false;
    });
  }

  function runAutoDraft() {
    if (!state.current || !state.editor) return;
    var bounds = state.map.getBounds();
    var want = { roads: $('dfRoads').checked, buildings: $('dfBldg').checked };
    var wantParcel = $('dfParcel').checked && !$('dfParcel').disabled;
    if (!want.roads && !want.buildings && !wantParcel) {
      hint('生成する物を1つ以上選んでください', 2500);
      return;
    }
    $('dfRun').disabled = true;
    $('dfNote').textContent = 'オープンデータを取得しています…';

    var jobs = [
      (want.roads || want.buildings)
        ? AutoDraft.fetchGsiShapes(bounds, want)
        : Promise.resolve({ roads: [], buildings: [] }),
      wantParcel ? AutoDraft.fetchParcels(bounds) : Promise.resolve([])
    ];

    Promise.all(jobs).then(function (res) {
      var shapes = res[0], parcels = res[1], objs = [];
      state.roadWidths = shapes.widths || [];   // 幅員の参考値（Step 3.5 で使う）
      shapes.roads.forEach(function (pts) {
        objs.push(AutoDraft.toPath(pts, { w: 1.6, color: '#444' }));
      });
      shapes.buildings.forEach(function (pts) {
        objs.push(AutoDraft.toPolygon(pts, { w: 1.4, color: '#666' }));
      });
      parcels.forEach(function (p) {
        var o = AutoDraft.toPolygon(p.points, { w: 1.2, color: '#555' });
        o.chiban = p.chiban;
        objs.push(o);
      });

      // 引いた状態で実行すると街区ごと取り込んでしまう。数が多い時は確認する
      if (objs.length > 200) {
        var ok = confirm('この範囲だと ' + objs.length + ' 個の図形が作られます。\n'
          + '配置図には多すぎるかもしれません。\n\n'
          + '［キャンセル］して駐車場に寄ってから実行し直すこともできます。\n'
          + 'このまま作りますか？');
        if (!ok) {
          $('dfNote').textContent = '中止しました。駐車場に寄ってから実行すると必要な分だけになります。';
          return;
        }
      }
      state.editor.addGenerated(objs);
      updateHistoryButtons();

      var msg = [];
      if (want.roads) msg.push('道路縁 ' + shapes.roads.length);
      if (want.buildings) msg.push('建物 ' + shapes.buildings.length);
      if (wantParcel) msg.push('筆界 ' + parcels.length);
      $('dfNote').textContent = msg.join(' / ') + ' を生成しました。'
        + (wantParcel ? parcelNote(parcels) : '');
      hint(msg.join(' / ') + ' を下書きしました', 4000);
      noteDraftAttribution(wantParcel && parcels.length > 0);
    }).catch(function (e) {
      $('dfNote').textContent = '取得に失敗しました: ' + (e.message || e);
    }).then(function () {
      $('dfRun').disabled = false;
    });
  }

  /**
   * 出典表記を覚えさせる（書き出し時に図の隅へ入れる・Step 4）。
   * 🔒 §24-3（Step 6）: 出典は**シートごと**に、その紙で使ったデータ源だけを持つ。
   * 🔴 案件まるごとに付けると、地理院データを1枚も使っていない配置図の紙にまで
   *    「出典：国土地理院…」が刷られる（＝使っていない出典を載せる嘘になる）。
   * sheet を省略すると、いま編集している紙に付ける。
   */
  function noteDraftAttribution(usedMoj, sheet) {
    var c = state.current;
    var sh = sheet || curSheet();
    if (!c || !sh) return;
    if (!Array.isArray(sh.attributions)) sh.attributions = [];
    function add(s) { if (sh.attributions.indexOf(s) < 0) sh.attributions.push(s); }
    add(GSI.ATTRIBUTION);
    if (usedMoj) add(AutoDraft.MOJ_ATTR);
    Store.autosave(c);
  }

  /* ---------- 書き出し（正典 §7） ---------- */

  /**
   * 書き出し範囲 = **いま画面に見えている範囲**（オーナー指示 2026-08-16）。
   * 画面で見えている物がそのまま出るのが一番わかりやすい。
   * 画面の外に描かれている物は出さない。
   *
   * 紙（A4 1枚の作図領域）と画面は形が違うので、両方は一致しない。
   * **画面の外は出さない**方針なので、画面の内側に収まる最大の枠を採る。
   * その枠は地図の上に線で表示するので、何が出るかは見たままわかる。
   */
  /**
   * 枠の縦横比（幅/高さ）。🔒 §25-3「A4 縦か横かを選ぶ ＝ 枠の形が決まる」。
   * 🔒 §24-3（Step 6）: 1図1ページになったので、枠の形 ＝ **A4 1枚の作図領域**の形。
   * 🔴 値は export.js の pageLayout（紙の余白・見出し帯・欄外まで含む唯一の定義）
   *    から取る。ここで別の数字を持つと「画面の枠と紙の形が違う」に逆戻りする
   *    （§24-4-b 持ち越し3）。A4縦 ≒ 0.739 ／ A4横 ≒ 1.629。
   */
  function orientAspect(orient) {
    return Exporter.orientAspect(orient === 'landscape' ? 'landscape' : 'portrait');
  }

  /** 編集中シートの枠の縦横比 */
  function curAspect() {
    var s = curSheet();
    return orientAspect(s && s.orient);
  }

  /**
   * 🔒 §24-4-d（2026-08-31 オーナー指示）: 枠は「**同じ1枚の紙を回した物**」。
   *   ① 地図エリアいっぱいに広げない（上下左右に余裕を残す）
   *   ② **A4縦と A4横で紙の面積が同じ**（向きを変えただけで急に大きく／小さくならない）
   *
   * 🔴 直す前の作り: 「画面に収まる最大の矩形」だったので
   *    ・A4縦 は常に**画面の高さいっぱい**（余裕ゼロ）
   *    ・A4横 は同じ高さで幅だけ広い ＝ 面積が 2.2 倍
   *    になり、「同じ紙を回した」感が全く無かった（実測 1188×707 の地図エリアで
   *    縦 526.8×707＝372,437px² / 横 1165.7×707＝824,156px²）。
   *
   * 🙋 仮値: FRAME_FILL＝地図エリアに対して紙が占める率（上下左右の余裕）。
   *    0.85 なら地図エリアが横長のとき「A4縦の高さ ＝ 短辺の 85%」になる。
   *    ここ1か所を変えれば両方の向きが同じだけ変わる（面積が共通なので）。
   */
  var FRAME_FILL = 0.85;

  /**
   * その画面に置ける「紙1枚」の面積（px²）。**向きに依らない1つの値**。
   * 両方の向きが FRAME_FILL の箱に収まる必要があるので、収まりの**小さい方**を採る。
   * これで縦・横どちらも必ず画面内に入り、かつ面積が完全に一致する。
   */
  function paperAreaPx(sz) {
    var bw = sz.w * FRAME_FILL, bh = sz.h * FRAME_FILL;
    var area = Infinity;
    ORIENTS.forEach(function (o) {
      var asp = orientAspect(o);
      var w = bw, h = bw / asp;
      if (h > bh) { h = bh; w = bh * asp; }
      area = Math.min(area, w * h);
    });
    return area;
  }

  /** 指定の縦横比で「紙1枚」を画面中央に置いた矩形（px） */
  function frameRectPxFor(asp) {
    var s = state.map.size();
    var a = paperAreaPx(s);
    var fw = Math.sqrt(a * asp), fh = fw / asp;
    return { x: (s.w - fw) / 2, y: (s.h - fh) / 2, w: fw, h: fh };
  }

  /** いま編集中の紙の向きで、画面上の紙1枚の矩形（px） */
  function frameRectPx() { return frameRectPxFor(curAspect()); }

  /** いま見えている枠 → 保存する枠。
   *  🔴 画面がまだ組まれていない（幅0）間は **null** を返す。
   *     ここで枠を作ると w_m が最小値 3m の「豆粒の枠」になり、
   *     その紙が白紙で書き出される（実測で踏んだ・mapview の fitPoints にも同じ用心がある）。
   *     呼ぶ側は null なら**既存の枠をそのまま残す**こと。 */
  function frameFromView() {
    var mv = state.map;
    if (!mv) return null;
    var sz = mv.size();
    if (!sz.w || !sz.h) return null;
    var r = frameRectPx();
    var center = mv.unproject(r.x + r.w / 2, r.y + r.h / 2);
    var a = mv.unproject(r.x, r.y + r.h / 2);
    var b = mv.unproject(r.x + r.w, r.y + r.h / 2);
    /* 🔴 center は必ず**新しい座標オブジェクト**にする（§25-4-b 申し送りの根治）。
     * 案件のピン（points.lot 等）と同じオブジェクトを共有すると、枠を動かした
     * つもりでピンが黙って動く／保存 JSON に住所が混ざる、という事故になる。 */
    return { center: { lat: center.lat, lng: center.lng },
             w_m: Math.max(3, GSI.distanceMeters(a, b)),
             aspect: curAspect() };
  }

  /**
   * シート1枚の枠を求める（無ければ作れるだけ作る）。
   * 🔒 §24-3（Step 6）: 書き出しは**全シート**が対象になったので、
   *    「いま見ている紙」以外の枠もここで必ず答えられるようにする。
   * 優先順位: ①いま編集中で枠が未決定なら画面（§9-i「見えている枠の中が出る」）
   *           ②保存してある枠（枠を決定した紙はこれ・🔒 §24-2-3）
   *           ③その紙の表示位置(center/zoom)から復元 ④ピンの周り
   */
  function frameForSheet(k, sh) {
    var c = state.current;
    if (!c || !sh) return null;
    if (k === state.kind && sh === sheetOf(k) && !sh.frameFixed) {
      var fv = frameFromView();
      if (fv) return fv;                     // 画面が無い間は下の手段へ落ちる
    }
    if (sh.frame && sh.frame.center && sh.frame.w_m) return sh.frame;
    var asp = orientAspect(sh.orient);
    if (sh.center && state.map) {
      var mpp = 40075016.686 * Math.cos(sh.center.lat * Math.PI / 180)
              / (256 * Math.pow(2, sh.zoom));
      /* 🔒 §24-4-d: 画面いっぱいではなく「その画面に置ける紙1枚」の幅で復元する。
         こうすると、この紙を開いた時に見える枠と同じ物になる（画面と保存値の一致）。 */
      var r = frameRectPxFor(asp);
      return { center: { lat: sh.center.lat, lng: sh.center.lng },
               w_m: Math.max(10, r.w * mpp), aspect: asp };
    }
    var p = (k === 'haichizu') ? c.points.lot : (c.points.home || c.points.lot);
    // 🔴 ピンの座標は**コピー**して渡す（§25-4-b 申し送り。参照共有を作らない）
    return p ? { center: { lat: p.lat, lng: p.lng },
                 w_m: k === 'haichizu' ? 60 : 600, aspect: asp } : null;
  }

  /** その種類の「いま開いているシート」の枠 */
  function frameForKind(k) { return frameForSheet(k, sheetOf(k)); }

  /** 枠が未設定のシートに枠を作る（🔒 §24-3: 全シートが書き出し対象なので全部見る） */
  function ensureFrames() {
    if (!state.current) return;
    KINDS.forEach(function (k) {
      sheetsOf(k).forEach(function (sh) {
        if (sh.frame && sh.frame.center && sh.frame.w_m) return;
        var f = frameForSheet(k, sh);
        if (f) sh.frame = f;
      });
    });
  }

  /**
   * 表示中のシートの枠を、いまの画面で更新する。
   * 🔒 §24-2-3: 枠を「決定」したシート（frameFixed）は**画面に追従しない**。
   *    決めた紙面の中で地図だけを自由に動かして仕上げられるようにするため。
   */
  function syncFrameFromView() {
    if (!state.current || !state.map) return;
    var sh = curSheet();
    if (!sh || sh.frameFixed) return;
    var f = frameFromView();
    if (f) sh.frame = f;          // 画面が無い間は前の枠を壊さない
  }

  /** 決定済みの枠を、いまの画面のピクセル矩形に直す（画面外にはみ出してもよい） */
  function fixedFrameRectPx(frame) {
    var b = Exporter.frameBounds(frame);
    var nw = state.map.project(b.north, b.west);
    var se = state.map.project(b.south, b.east);
    return { x: nw.x, y: nw.y, w: se.x - nw.x, h: se.y - nw.y };
  }

  /**
   * 🔒 §26-4-e ＋ §28-10 裁定6（2026-09-06 Fable）: **白紙かどうかの判定はここ1か所**。
   * 🔴 方位記号（type:'compass'）は［枠を決定］で自動的に置かれる**付き物**なので、
   *    それしか無い紙は「白紙」＝書き出さない。数に入れると「白紙＋方位記号だけ」の
   *    ページが提出物に混ざる（Step 1 で方位記号を部品にした副作用）。
   * 🔴 一覧の件数表示・書き出し・プレビュー・PNG の枚数が食い違わないよう、
   *    数えるのも判定するのもこの2つの関数だけを使う。
   */
  function sheetDrawCount(sh) {
    var objs = (sh && sh.objects) || [];
    var n = 0;
    for (var i = 0; i < objs.length; i++) {
      if (objs[i] && objs[i].type !== 'compass') n++;
    }
    return n;
  }
  function sheetHasDrawing(sh) { return sheetDrawCount(sh) > 0; }

  /* 🔒 §30-29-1 3: renderExportInfo()（旧 #exPanel の
   * 「何枚目・図形 N 個・縮尺」の一覧）は廃止した。
   * 紙ごとの件は紙の帯（.ed-sheetbar）とプレビュー画面の
   * 見出し（exPagerRender）・出す紙を選ぶ窓（exPickRender）が出す。 */
  /**
   * その図の縮尺を出してよいか（正典 §16-10-f-3 / 🔒 §18-ae）。
   * 🔒 §18-ae: **配置図は常に縮尺を出さない**（画面の 1:N・スケールバー、
   *    紙面のスケールバー・1:N・縮尺の目安すべて）。
   *    🔴 配置図は取り込み画像を下敷きにすることがあり、§16-10-f で
   *       画像を実寸に合わせない（名目値のまま）と決めている。
   *       画像の無い時だけ縮尺を出すと「出たり出なかったり・値がズレる」ので、
   *       **配置図は一律で出さない**方が嘘が無く分かりやすい（オーナー判断）。
   * 所在図は地理院データから既知の縮尺で作り、§18-n で枠を固定しているので従来どおり出す。
   */
  function sheetScaleUnknown(k) {
    if (k === 'haichizu') return true;
    var c = state.current;
    if (!c || !c.maps[k]) return false;
    var im = c.maps[k].image;
    return !!(im && im.imgId);
  }

  /* 🔒 §30-22-4 11 で廃止: `sheetNorthUnknown(k)`（配置図には方位記号を置かない）。
   * §18-ag の理由（取り込み画像を回すので図の上が北とは限らない）は、
   * 方位記号が「紙の付き物」だった頃の話。いまは**消せる部品**なので、
   * 置いた上で利用者が消す／動かす方に改めた（判定そのものを取り除いた）。 */

  /**
   * 🔒 §28-3: ［枠を決定］した紙の**右上**に方位記号の部品を1個置く。
   * 置いたあとはドラッグで動かせる・消しゴムで消せる（ふつうのオブジェクト）。
   * 🔴 既に方位記号がある紙には**2つ目を置かない**（§28-3）。
   * 🔴 旧案件（方位記号なし）に**自動では足さない**（§25-4-7 と同じ作法）
   *    ＝ 呼ぶのは［枠を決定］の操作からだけ。
   * @returns true＝置いた
   */
  /* 🔒 §30-22-4 11（2026-09-13 オーナー指示）: **配置図にも方位記号を自動で置く**。
   * 🔴 §18-ag「向きが分からない図には出さない」を改めた（sheetNorthUnknown は
   *    紙の付き物だった頃の判定で、いまの方位記号は**ドラッグで回せない代わりに
   *    消せる部品**）。配置図も枠を決めた時点では地図と同じ北上なので、置いた上で
   *    利用者が消す／動かす方が実務に合う、というのがオーナーの判断。
   * 🔴 残りの条件は §28-3 のまま（枠を決めた時だけ・既にあれば置かない）。 */
  /* 🔒 §30-32-4（2026-09-15 オーナー報告「配置図に方位が出ていない！」）:
   * 原因は「既に方位記号があれば置かない」の**判定が枠を見ていなかった**こと。
   * ［枠を抜出し追加］／［複製］で作った紙（§30-26-1・addSheet(src)）は、
   * 元の紙の方位記号を**位置ごと**写す。抜き出した紙は元より狭い枠なので、
   * 写した方位記号は新しい枠の**外**に居る（実測: 枠 x 323.6〜776.4 に対して
   * 方位記号 x=840・y=-50）。そこへ［枠を決定］を押しても「もうある」と見なして
   * 何もしないので、画面にも紙にも方位記号が出ないまま、という筋。
   * 直し: 枠の**中**にあれば置かない（今までどおり）。枠の外に居る時は
   * 2つ目を足さずに**その1つを枠の右上へ移す**（§28-3「1枚に1つ」は保つ）。 */
  function placeCompass(kind, sh) {
    if (!sh || !sh.frame) return false;
    if (!window.Editor || !Editor.makeCompass || !Exporter.compassSpot) return false;
    var objs = sh.objects || [];
    var b = Exporter.frameBounds(sh.frame);
    var had = null;
    for (var i = 0; i < objs.length; i++) {
      if (objs[i] && objs[i].type === 'compass') { had = objs[i]; break; }
    }
    // 枠の中にもう居る＝何もしない（§28-3「2つ目は置かない」）
    if (had && inFrameBounds(had.at, b)) return false;
    var spot = Exporter.compassSpot(Exporter.frameAspect(sh.frame));
    var at = { lat: b.north - spot.y * (b.north - b.south),
               lng: b.west + spot.x * (b.east - b.west) };
    /* 🔴 §23-7-1: 配列は**差し替えない**（bind が state.current と参照を共有している）。
     *    push で足す。編集中のシートなら editor.objects と同じ配列なのでそのまま映る。 */
    var live = !!(state.editor && state.editor.objects === objs);
    if (live) state.editor.snapshot();
    if (had) had.at = at;                      // 枠の外に居た1つを右上へ移す
    else objs.push(Editor.makeCompass(at));
    if (live) {
      state.editor.commit();
      updateHistoryButtons();
    }
    return true;
  }

  /** 🔒 §30-32-4: その点が枠（frameBounds の返り値）の中か */
  function inFrameBounds(at, b) {
    if (!at || !b) return false;
    return at.lat <= b.north && at.lat >= b.south
        && at.lng >= b.west && at.lng <= b.east;
  }

  /* ========== 🔒 §30-22-4 4 / §30-25-22: ［道路を描く］（配置図）==========
   * 配置図の**枠の近く**（枠＋周囲 ROADAUTO_PAD_M）の道路を自動で置く。
   *
   * 🔒 §30-25-22（2026-09-14 オーナー指示「幅の直し方は縁をドラッグだけ。両端で
   *    別々に動くように。多角形ツールで描いてくれれば修正が楽。点はせいぜい3個」）:
   *    **白帯＋黒縁の帯はもう作らない**。道路の**両側の縁**を、それぞれ独立した
   *    線の図形（多角形ツールが Enter で確定した物と同じ `type:'path'`）として置く。
   *      ・片側ずつ別の図形 ＝ 頂点をドラッグすれば**片側だけ**動く（幅の修正）
   *      ・中は透明（帯が無い）＝ 下敷きの写真・地図がそのまま見える
   *      ・交差点は**開ける**（他の道路の帯の面に入る区間を切り落とす）
   *      ・点は両端＋途中1点の**最大3点**
   * 🔴 置いた物は普通の図形（消しゴムで消せる・選んで動かせる・紙にもそのまま出る）。
   * 🔴 押すたびに前回の自動分（source:'roadauto'）だけを消して描き直す
   *    ＝ 手で描いた物・所在図から持ってきた物には触らない。
   * 🔴 幅は「縁の位置そのもの」なので、縁の図形に `widthM` は持たせない（§30-25-22 6）。
   * 🔴 使うのは地理院ベクトルタイル（RdCL）だけ。Overpass は使わない。
   * 🔴 所在図の自動生成の道路（帯）は**今のまま**（shozaizu.js は触らない）。 */
  var ROADAUTO_PAD_M = 30;      // 枠の外へ広げる距離(m)
  var ROADAUTO_Z = 16;          // 地理院ベクトルタイルの最大ズーム（17 以上は 404）
  /* 🔒 §30-25-22 2/3: 縁の作り方の数値（単位はすべてメートル）。
   * 🔴 値の出どころはこの表1か所。 */
  var ROADAUTO_W_UNKNOWN = 4.2; // 幅員ランクが分からない道路の幅(m)
  var ROADAUTO_STEP_M = 0.5;    // 縁を標本化する間隔（交差点の開け方の分解能）
  var ROADAUTO_MIN_RUN_M = 1;   // これより短い切れ端は捨てる
  var ROADAUTO_DP_M = 0.3;      // Douglas–Peucker の許容
  var ROADAUTO_MAX_PTS = 3;     // 1本の縁に打つ点の上限（両端＋途中1点）
  /* 🔒 §30-38-1 1: 端と端がこの距離(m)以内なら「接している」＝1本に繋ぐ。 */
  var ROADAUTO_JOIN_M = 1.5;
  /* 🔒 §30-38-4 2: タイルの境などで**二重になった縁**を1本にするための物差し。
   * 両端がそれぞれこの距離(m)以内（順・逆どちらでも）で、長さの差が
   * ROADAUTO_DUP_RATE 以内なら同じ縁と見なす。 */
  var ROADAUTO_DUP_M = 0.5;
  var ROADAUTO_DUP_RATE = 0.1;  // 長さの差（長い方に対する割合）
  /* 同じ道路が複数の地物に分かれている継ぎ目（一直線に続く所）で縁が切れないよう、
   * 帯の面は「ほんの少し内側」を中と見なす。交差点の開き方はこの分だけ狭くなる。 */
  var ROADAUTO_CUT_EPS_M = 0.2;
  var ROADAUTO_CELL_M = 8;      // 帯の面を引くための格子の目
  var roadAutoBusy = false;

  /* ---- 🔒 §30-25-22: 縁を作るための幾何（メートルの平面で解く）----
   * 枠の中心の緯度で 緯度経度 ⇄ メートル の換算を1回だけ決める
   * （扱うのは枠＋30m の範囲だけなので、この平面近似で十分）。 */
  function raPlane(lat0, lng0) {
    var kx = 111320 * Math.cos(lat0 * Math.PI / 180), ky = 111320;
    if (!(kx > 1)) kx = 1;                    // 極に近い時の保険
    return {
      kx: kx, ky: ky,
      to: function (p) { return { x: (p.lng - lng0) * kx, y: (lat0 - p.lat) * ky }; },
      back: function (q) { return { lat: lat0 - q.y / ky, lng: lng0 + q.x / kx }; }
    };
  }

  /** 点と線分の距離の2乗（メートルの平面） */
  function raD2Seg(p, a, b) {
    var vx = b.x - a.x, vy = b.y - a.y;
    var L2 = vx * vx + vy * vy;
    var t = (L2 > 0) ? ((p.x - a.x) * vx + (p.y - a.y) * vy) / L2 : 0;
    if (t < 0) t = 0; else if (t > 1) t = 1;
    var dx = p.x - (a.x + vx * t), dy = p.y - (a.y + vy * t);
    return dx * dx + dy * dy;
  }

  /** 折れ線の長さ(m) */
  function raLen(line) {
    var L = 0;
    for (var i = 0; i + 1 < line.length; i++) {
      L += Math.hypot(line[i + 1].x - line[i].x, line[i + 1].y - line[i].y);
    }
    return L;
  }

  /** 線分を矩形で切る（Liang–Barsky）。まるごと外なら null */
  function raClipSeg(a, b, R) {
    var t0 = 0, t1 = 1, dx = b.x - a.x, dy = b.y - a.y;
    var pq = [[-dx, a.x - R.x0], [dx, R.x1 - a.x], [-dy, a.y - R.y0], [dy, R.y1 - a.y]];
    for (var i = 0; i < 4; i++) {
      var p = pq[i][0], q = pq[i][1];
      if (p === 0) { if (q < 0) return null; continue; }
      var r = q / p;
      if (p < 0) { if (r > t1) return null; if (r > t0) t0 = r; }
      else { if (r < t0) return null; if (r < t1) t1 = r; }
    }
    if (!(t1 > t0)) return null;
    return [{ x: a.x + dx * t0, y: a.y + dy * t0 },
            { x: a.x + dx * t1, y: a.y + dy * t1 }];
  }

  /** 折れ線を矩形で切る（🔒 §30-25-22 2 手順1）。中に入っている区間の配列 */
  function raClip(pts, R) {
    var out = [], cur = null;
    for (var i = 0; i + 1 < pts.length; i++) {
      var seg = raClipSeg(pts[i], pts[i + 1], R);
      if (!seg) { cur = null; continue; }
      var last = cur && cur[cur.length - 1];
      if (last && Math.abs(last.x - seg[0].x) < 1e-6 && Math.abs(last.y - seg[0].y) < 1e-6) {
        cur.push(seg[1]);
      } else {
        cur = [seg[0], seg[1]];
        out.push(cur);
      }
    }
    return out;
  }

  /** 折れ線を d だけ横へずらした折れ線（角は隣り合う法線の平均・🔒 §30-25-22 2 手順2） */
  function raOffset(line, d) {
    var i, pts = [line[0]];
    for (i = 1; i < line.length; i++) {         // 同じ点の続きは落とす
      var q = pts[pts.length - 1];
      if (Math.hypot(line[i].x - q.x, line[i].y - q.y) > 1e-6) pts.push(line[i]);
    }
    var n = pts.length;
    if (n < 2) return null;
    var segN = [];
    for (i = 0; i + 1 < n; i++) {
      var dx = pts[i + 1].x - pts[i].x, dy = pts[i + 1].y - pts[i].y;
      var L = Math.hypot(dx, dy);
      segN.push({ x: -dy / L, y: dx / L });
    }
    var out = [];
    for (i = 0; i < n; i++) {
      var a = segN[Math.max(0, i - 1)], b = segN[Math.min(segN.length - 1, i)];
      var nx = a.x + b.x, ny = a.y + b.y, L2 = Math.hypot(nx, ny);
      if (!(L2 > 1e-6)) { nx = b.x; ny = b.y; L2 = 1; }   // 折り返し（180°）の保険
      out.push({ x: pts[i].x + nx / L2 * d, y: pts[i].y + ny / L2 * d });
    }
    return out;
  }

  /** 折れ線を step ごとに標本化（両端は必ず入る・🔒 §30-25-22 2 手順3） */
  function raSample(line, step) {
    var out = [line[0]];
    for (var i = 0; i + 1 < line.length; i++) {
      var a = line[i], b = line[i + 1];
      var L = Math.hypot(b.x - a.x, b.y - a.y);
      var n = Math.max(1, Math.ceil(L / step));
      for (var k = 1; k <= n; k++) {
        out.push({ x: a.x + (b.x - a.x) * k / n, y: a.y + (b.y - a.y) * k / n });
      }
    }
    return out;
  }

  /**
   * 🔒 §30-25-22 3: 「他の道路の帯の面」の索引（格子）。
   * 面＝その道路の中心線から 幅/2 以内。1点ずつ全部の道路を見ると遅いので、
   * 辺を格子の目へ入れておき、標本の点は同じ目の辺だけを見る。
   * @param roads [{line:[平面の点], half:m}]
   */
  function raBandIndex(roads) {
    var cell = ROADAUTO_CELL_M, map = {}, all = [];
    roads.forEach(function (r, ri) {
      var half = r.half - ROADAUTO_CUT_EPS_M;
      if (!(half > 0)) return;
      var h2 = half * half;
      for (var i = 0; i + 1 < r.line.length; i++) {
        var a = r.line[i], b = r.line[i + 1];
        var seg = { ri: ri, a: a, b: b, h2: h2 };
        var x0 = Math.floor((Math.min(a.x, b.x) - r.half) / cell);
        var x1 = Math.floor((Math.max(a.x, b.x) + r.half) / cell);
        var y0 = Math.floor((Math.min(a.y, b.y) - r.half) / cell);
        var y1 = Math.floor((Math.max(a.y, b.y) + r.half) / cell);
        if ((x1 - x0 + 1) * (y1 - y0 + 1) > 400) { all.push(seg); continue; }
        for (var cx = x0; cx <= x1; cx++) {
          for (var cy = y0; cy <= y1; cy++) {
            var k = cx + ',' + cy;
            (map[k] || (map[k] = [])).push(seg);
          }
        }
      }
    });
    return { cell: cell, map: map, all: all };
  }

  /** その点が「他の道路の帯の面」の中か（自分の道路 skipRi は見ない） */
  function raInBand(idx, p, skipRi) {
    var i, list = idx.map[Math.floor(p.x / idx.cell) + ',' + Math.floor(p.y / idx.cell)];
    if (list) {
      for (i = 0; i < list.length; i++) {
        if (list[i].ri === skipRi) continue;
        if (raD2Seg(p, list[i].a, list[i].b) < list[i].h2) return true;
      }
    }
    for (i = 0; i < idx.all.length; i++) {
      if (idx.all[i].ri === skipRi) continue;
      if (raD2Seg(p, idx.all[i].a, idx.all[i].b) < idx.all[i].h2) return true;
    }
    return false;
  }

  /** 帯の面に入る点を除き、外の連続区間だけに分ける（短い切れ端は捨てる） */
  function raSplit(samples, idx, skipRi) {
    var runs = [], cur = null;
    for (var i = 0; i < samples.length; i++) {
      if (raInBand(idx, samples[i], skipRi)) { cur = null; continue; }
      if (!cur) { cur = []; runs.push(cur); }
      cur.push(samples[i]);
    }
    return runs.filter(function (r) {
      return r.length >= 2 && raLen(r) >= ROADAUTO_MIN_RUN_M;
    });
  }

  /** Douglas–Peucker（許容 tol・メートル） */
  function raDP(pts, i0, i1, tol) {
    var best = -1, bi = -1;
    for (var i = i0 + 1; i < i1; i++) {
      var d = raD2Seg(pts[i], pts[i0], pts[i1]);
      if (d > best) { best = d; bi = i; }
    }
    if (bi > 0 && best > tol * tol) {
      var l = raDP(pts, i0, bi, tol), r = raDP(pts, bi, i1, tol);
      return l.slice(0, l.length - 1).concat(r);
    }
    return [pts[i0], pts[i1]];
  }

  /** 🔒 §30-25-22 2 手順4: 間引いて**最大3点**（両端＋最も外れた途中1点）にする */
  function raSimplify(run) {
    if (run.length <= 2) return run;
    var dp = raDP(run, 0, run.length - 1, ROADAUTO_DP_M);
    if (dp.length <= ROADAUTO_MAX_PTS) return dp;
    var a = run[0], b = run[run.length - 1], best = -1, bi = -1;
    for (var i = 1; i < run.length - 1; i++) {
      var d = raD2Seg(run[i], a, b);
      if (d > best) { best = d; bi = i; }
    }
    return (bi > 0) ? [a, run[bi], b] : [a, b];
  }

  /**
   * 🔒 §30-25-22 1: 縁の線の**太さ・色**＝いまの黒縁の既定。
   * 🔴 数値は写さず `Editor.roadBand` から取る（帯の外幅 − 中身 の半分＝縁の太さ）。
   *    mPerU を 0 で渡す＝実距離による太りを掛けない「等級の既定」を読む。
   */
  function raEdgeStyle(st) {
    var bd = (window.Editor && Editor.roadBand)
      ? Editor.roadBand({ style: { casing: true, w: st.w, color: st.color } },
                        { mPerU: 0 })
      : null;
    if (!bd) return { w: st.w, color: st.color };
    var w = (bd.inner > 0) ? (bd.outer - bd.inner) / 2 : bd.outer;
    return { w: Math.round(w * 100) / 100, color: bd.outerColor };
  }

  /**
   * 🔒 §30-38-4 2: タイルの境などで**二重になった縁**を1本にする（繋ぐ前の下ごしらえ）。
   * 同じ縁と見なす条件＝両端がそれぞれ ROADAUTO_DUP_M 以内（順方向・逆方向どちらでも）
   * かつ長さの差が ROADAUTO_DUP_RATE 以内。
   * 🔴 元の配列も中の図形も書き換えない（残す物をそのまま並べた**写し**を返す）。
   */
  function raDropDup(made, plane) {
    var n = made.length;
    if (n < 2) return made;
    var D2 = ROADAUTO_DUP_M * ROADAUTO_DUP_M, i;
    /* 端の位置と長さ（メートルの平面）を先に出しておく */
    var info = [];
    for (i = 0; i < n; i++) {
      var pts = made[i].points, mp = pts.map(plane.to);
      info.push({ a: mp[0], b: mp[mp.length - 1], len: raLen(mp) });
    }
    /* 近い物だけ見るための格子（両端とも登録する＝向きが逆でも拾える） */
    var cell = Math.max(ROADAUTO_DUP_M * 2, 1), grid = {};
    function gput(p, v) {
      var gk = Math.floor(p.x / cell) + ',' + Math.floor(p.y / cell);
      (grid[gk] || (grid[gk] = [])).push(v);
    }
    for (i = 0; i < n; i++) { gput(info[i].a, i); gput(info[i].b, i); }
    function near2(p, q) {
      var dx = p.x - q.x, dy = p.y - q.y;
      return dx * dx + dy * dy <= D2;
    }
    var drop = [], out = [];
    for (i = 0; i < n; i++) drop[i] = false;
    for (i = 0; i < n; i++) {
      if (drop[i]) continue;
      var mine = info[i];
      var cx = Math.floor(mine.a.x / cell), cy = Math.floor(mine.a.y / cell), dx, dy, t;
      for (dx = -1; dx <= 1; dx++) {
        for (dy = -1; dy <= 1; dy++) {
          var list = grid[(cx + dx) + ',' + (cy + dy)];
          if (!list) continue;
          for (t = 0; t < list.length; t++) {
            var j2 = list[t];
            if (j2 <= i || drop[j2]) continue;
            var o2 = info[j2];
            var same = (near2(mine.a, o2.a) && near2(mine.b, o2.b))
                    || (near2(mine.a, o2.b) && near2(mine.b, o2.a));
            if (!same) continue;
            var big = Math.max(mine.len, o2.len);
            if (big > 0 && Math.abs(mine.len - o2.len) > big * ROADAUTO_DUP_RATE) continue;
            drop[j2] = true;                   // 後から来た方を捨てる
          }
        }
      }
    }
    for (i = 0; i < n; i++) if (!drop[i]) out.push(made[i]);
    return out;
  }

  /**
   * 🔒 §30-38-1 → §30-38-4（2026-09-15 オーナー指示「線が触れている所は全て
   * 多角形ツールに。交差点付近の線を動かすのに2つの線を動かす必要が出る。
   * 都市部では□が多く描かれるがそれでよい」）: 作った縁のうち**端と端が接している物**を
   * 1本の線に繋ぐ。
   *   ・先に**二重の縁**を消す（raDropDup・§30-38-4 2）
   *   ・繋ぐ条件は「端どうしの距離が ROADAUTO_JOIN_M 以内」だけ（§30-38-4 1 で
   *     「同じ roadRank」「相手が1本だけ」の2つを外した）。**距離の近い組から
   *     順に1対1**で組む（各端は1回だけ・自分の反対の端は相手にしない＝貪欲）
   *   ・繋ぎ目の頂点は2つの端の中点
   *   ・**輪になったら多角形**（§30-38-4 3・type:'polygon'・塗りなし）＝街区が□になる
   * 🔴 §30-25-22 の「1本の縁は最大3点」は**そのまま保つ**（繋ぐのは最後の仕上げで、
   *    縁そのものの作り方は変えていない）。
   * @param made  縁の図形の配列（この配列も中の図形も書き換えない）
   * @param plane raPlane（緯度経度 ⇄ メートル）
   * @return 繋いだ後の図形の配列（繋がなかった縁は元の図形のまま入る）
   */
  function raJoinRuns(made, plane) {
    var src = raDropDup(made, plane);          // 🔒 §30-38-4 2: 二重の縁を先に消す
    var n = src.length;
    if (n < 2) return src;
    var J2 = ROADAUTO_JOIN_M * ROADAUTO_JOIN_M, i, k;
    /* --- ① 端の表（端の番号 ＝ 縁の番号×2 ＋ 0:先頭 / 1:末尾）--- */
    var ends = [];
    for (i = 0; i < n; i++) {
      var pts = src[i].points;
      ends.push({ i: i, p: plane.to(pts[0]) });
      ends.push({ i: i, p: plane.to(pts[pts.length - 1]) });
    }
    /* --- ② 近い端だけを見るための格子（総当たりだと本数の2乗になる）--- */
    var cell = Math.max(ROADAUTO_JOIN_M, 0.5), grid = {};
    for (k = 0; k < ends.length; k++) {
      var gk = Math.floor(ends[k].p.x / cell) + ',' + Math.floor(ends[k].p.y / cell);
      (grid[gk] || (grid[gk] = [])).push(k);
    }
    /* --- ③ 🔒 §30-38-4 1: JOIN_M 以内の組を全部作り、**近い順**に1対1で組む
     *   （等級は見ない。各端は1回だけ使う・自分の反対の端は相手にしない）--- */
    var pairs = [];
    for (k = 0; k < ends.length; k++) {
      var en = ends[k];
      var cx = Math.floor(en.p.x / cell), cy = Math.floor(en.p.y / cell), dx, dy, t;
      for (dx = -1; dx <= 1; dx++) {
        for (dy = -1; dy <= 1; dy++) {
          var list = grid[(cx + dx) + ',' + (cy + dy)];
          if (!list) continue;
          for (t = 0; t < list.length; t++) {
            var k2 = list[t];
            if (k2 <= k) continue;             // 組は1回だけ数える
            // 自分の縁のもう一方の端は相手にしない（1本だけで輪を作らない）
            if (ends[k2].i === en.i) continue;
            var ddx = ends[k2].p.x - en.p.x, ddy = ends[k2].p.y - en.p.y;
            var d2 = ddx * ddx + ddy * ddy;
            if (d2 <= J2) pairs.push({ a: k, b: k2, d: d2 });
          }
        }
      }
    }
    pairs.sort(function (p, q) { return p.d - q.d; });
    var link = [];
    for (k = 0; k < ends.length; k++) link[k] = -1;
    for (k = 0; k < pairs.length; k++) {
      var pr = pairs[k];
      if (link[pr.a] >= 0 || link[pr.b] >= 0) continue;   // 使った端は候補から外す
      link[pr.a] = pr.b; link[pr.b] = pr.a;
    }
    /* --- ④ 鎖をたどって1本にまとめる。
     *   pass 0 ＝ 端が空いている縁を頭にした鎖（ふつうの道）
     *   pass 1 ＝ 残り（＝ぐるりと輪になっている所）＝ 🔒 §30-38-4 3 で多角形にする */
    var used = [], out = [];
    for (i = 0; i < n; i++) used[i] = false;
    for (var pass = 0; pass < 2; pass++) {
      for (i = 0; i < n; i++) {
        if (used[i]) continue;
        var start = 0;
        if (pass === 0) {
          if (link[i * 2] < 0) start = 0;
          else if (link[i * 2 + 1] < 0) start = 1;
          else continue;                       // 両端とも繋がっている＝輪（pass 1 で）
        }
        var seq = [], ci = i, ce = start, ring = false;
        while (true) {
          seq.push({ i: ci, e: ce });
          used[ci] = true;
          var pk = link[ci * 2 + (1 - ce)];    // 入った端の反対側から出る
          if (pk < 0) break;
          var ni = Math.floor(pk / 2), ne = pk % 2;
          if (used[ni]) {
            // 先頭の縁の「入った端」へ戻ってきた＝輪（🔒 §30-38-4 3）
            if (ni === i && ne === start) ring = true;
            break;
          }
          ci = ni; ce = ne;
        }
        out.push(raMergeSeq(seq, src, plane, out.length, ring));
      }
    }
    return out;
  }

  /**
   * 🔒 §30-38-1 2〜3 / §30-38-4 3: 鎖（入った端の並び）を1本の図形にする。
   * 繋ぎ目の頂点が前後の点とほぼ一直線（ずれが ROADAUTO_DP_M 以下）なら落とす
   * ＝ 真っすぐな道は何本繋いでも2点・曲がり角は残る（全体の点の上限は設けない）。
   * @param ring 輪になっている（先頭の端と末尾の端が組んでいる）＝ `type:'polygon'` にする。
   *   輪の時は先頭と末尾も**同じ規則**で中点にまとめ、一直線の判定は最後→最初の辺も見る。
   */
  function raMergeSeq(seq, made, plane, serial, ring) {
    var head = made[seq[0].i];
    if (seq.length === 1 && !ring) return head;   // 繋がなかった縁はそのまま
    var pts = [], joints = {}, s, q, j;
    for (s = 0; s < seq.length; s++) {
      var o = made[seq[s].i];
      q = (seq[s].e === 0) ? o.points.slice() : o.points.slice().reverse();
      if (!pts.length) { pts = q; continue; }
      var last = pts[pts.length - 1];
      // 繋ぎ目の頂点は2つの端の中点（🔒 §30-38-1 1）
      pts[pts.length - 1] = { lat: (last.lat + q[0].lat) / 2,
                              lng: (last.lng + q[0].lng) / 2 };
      joints[pts.length - 1] = true;
      for (j = 1; j < q.length; j++) pts.push(q[j]);
    }
    /* 🔒 §30-38-4 3: 輪の繋ぎ目（末尾 → 先頭）も他の繋ぎ目と同じ中点に。
     * 多角形は最後の点と最初の点が辺で結ばれるので、重なる1点は落とす。 */
    if (ring && pts.length >= 3) {
      var p0 = pts[0], pz = pts[pts.length - 1];
      pts[0] = { lat: (p0.lat + pz.lat) / 2, lng: (p0.lng + pz.lng) / 2 };
      pts.pop();
      joints[0] = true;
    }
    var mp = pts.map(plane.to), tol2 = ROADAUTO_DP_M * ROADAUTO_DP_M;
    var keep = [], keepM = [];
    var lo = ring ? 0 : 1, hi = ring ? pts.length : pts.length - 1;
    if (!ring) { keep.push(pts[0]); keepM.push(mp[0]); }
    for (j = lo; j < hi; j++) {
      var pv = keepM.length ? keepM[keepM.length - 1]
                            : mp[(j - 1 + pts.length) % pts.length];
      var nx = mp[(j + 1) % pts.length];
      if (joints[j] && raD2Seg(mp[j], pv, nx) <= tol2) continue;
      keep.push(pts[j]); keepM.push(mp[j]);
    }
    if (!ring) keep.push(pts[pts.length - 1]);
    // 減らしすぎて多角形にならない時は間引かない（保険）
    if (ring && keep.length < 3) keep = pts;
    var obj = {
      id: 'ra' + Date.now().toString(36) + 'j' + serial.toString(36),
      /* 🔒 §30-38-4 3: 輪は多角形（`closed` は持たせない＝多角形ツールが
       * Shift+Enter で閉じた物と同じ型）。輪でなければ従来どおり path。 */
      type: ring ? 'polygon' : 'path',
      points: keep,
      // 書式・ランクは先頭の縁の物（🔒 §30-38-1 2 / §30-38-4 1）
      style: head.style, roadRank: head.roadRank, source: 'roadauto'
    };
    if (!ring) obj.closed = false;
    return obj;
  }

  /**
   * 🔒 §30-38-4 5: ［地図の道路を写す］が終わった時の一言（**文はここ1か所**）。
   * N は輪（多角形）も含めた本数。
   */
  function raDoneMsg(n) {
    return '枠の近くの道路の線を ' + n + ' 本描きました'
         + '（角は1つの頂点です。線の上で Alt＋クリックすると頂点が増えます）';
  }

  function drawRoadsNearFrame() {
    var c = state.current, sh = curSheet();
    if (!c || !sh || !state.editor) return Promise.resolve(0);
    if (roadAutoBusy) return Promise.resolve(0);
    var f = sh.frame || frameFromView();
    if (!f) {
      hint('先に枠を決めてください（枠の近くの道路を描きます）', 3000);
      return Promise.resolve(0);
    }
    if (!window.GSI || !window.Exporter || !window.Shozaizu) return Promise.resolve(0);
    var b = Exporter.frameBounds(f);
    // 枠の外へ 30m 広げる（緯度は一定・経度は cos(緯度) で伸ばす）
    var dLat = ROADAUTO_PAD_M / 111320;
    var dLng = ROADAUTO_PAD_M
             / (111320 * Math.max(1e-6, Math.cos(f.center.lat * Math.PI / 180)));
    var bounds = { west: b.west - dLng, east: b.east + dLng,
                   south: b.south - dLat, north: b.north + dLat };

    roadAutoBusy = true;
    hint('枠の近くの道路を取りに行っています…', 0);
    return GSI.fetchTiles(bounds, ROADAUTO_Z).then(function (tiles) {
      var table = Shozaizu.roadStyleTable('band');
      /* --- ① 中心線を集めて枠＋30m で切る（🔒 §30-25-22 2 手順1）--- */
      var plane = raPlane(f.center.lat, f.center.lng);
      var c0 = plane.to({ lat: bounds.north, lng: bounds.west });
      var c1 = plane.to({ lat: bounds.south, lng: bounds.east });
      var R = { x0: Math.min(c0.x, c1.x), x1: Math.max(c0.x, c1.x),
                y0: Math.min(c0.y, c1.y), y1: Math.max(c0.y, c1.y) };
      var roads = [];
      tiles.forEach(function (t) {
        var RL = t.layers && t.layers.RdCL;
        if (!RL) return;
        for (var i = 0; i < RL.features.length; i++) {
          var ft = RL.features[i];
          var rank = GSI.roadRank(ft.props);
          // §22-at の幅（vt_rnkwidth → 実距離）。分からない道路は既定の幅
          var widthM = GSI.roadWidthM(ft.props) || ROADAUTO_W_UNKNOWN;
          for (var gi = 0; gi < ft.geom.length; gi++) {
            if (ft.geom[gi].length < 2) continue;
            var pts = Shozaizu._toLatLngs(ft.geom[gi], t, RL.extent);
            if (!Shozaizu._bboxHits(pts, bounds)) continue;
            var mpts = pts.map(plane.to);
            raClip(mpts, R).forEach(function (line) {
              if (line.length >= 2 && raLen(line) > 0.05) {
                roads.push({ line: line, half: widthM / 2, rank: rank });
              }
            });
          }
        }
      });
      /* --- ② 交差点を開けるための「帯の面」の索引（🔒 §30-25-22 2 手順3）--- */
      var idx = raBandIndex(roads);
      /* --- ③ 左右の縁 → 交差点で切る → 間引く → 図形にする --- */
      var made = [];
      roads.forEach(function (r, ri) {
        var st = table[r.rank] || table[1];
        var es = raEdgeStyle(st);
        [1, -1].forEach(function (sgn) {
          var ed = raOffset(r.line, sgn * r.half);
          if (!ed) return;
          raSplit(raSample(ed, ROADAUTO_STEP_M), idx, ri).forEach(function (run) {
            var q = raSimplify(run);
            if (q.length < 2) return;
            made.push({
              id: 'ra' + Date.now().toString(36) + made.length.toString(36),
              type: 'path', closed: false,
              points: q.map(function (p) { return plane.back(p); }),
              /* 🔒 §30-25-22 1: 太さ・色は黒縁の既定（raEdgeStyle）。
               * 🔴 casing は付けない＝帯（白塗り）を描かない＝中は透明。 */
              style: { w: es.w, color: es.color },
              roadRank: r.rank, source: 'roadauto'
            });
          });
        });
      });
      /* --- ④ 🔒 §30-38-1: 端と端が接している縁を1本の線に繋ぐ --- */
      var joined = raJoinRuns(made, plane);
      var objs = sh.objects || (sh.objects = []);
      var ed2 = state.editor, live = (ed2.objects === objs);
      if (live) ed2.snapshot();
      // 前回の自動分だけ消す（🔴 配列は差し替えず splice だけ・§23-7-1）
      for (var k = objs.length - 1; k >= 0; k--) {
        if (objs[k] && objs[k].source === 'roadauto') objs.splice(k, 1);
      }
      /* 🔒 §30-25-4: 道路は一番下（描く順・当たり判定）。並びの上でも先頭へ入れて
       * おく（Editor.isRoad が source:'roadauto' を道路として数える）。 */
      for (var m = joined.length - 1; m >= 0; m--) objs.unshift(joined[m]);
      if (live) { ed2.selection = []; ed2.commit(); updateHistoryButtons(); }
      Store.autosave(c);
      // 🔒 §30-38-1 4 / §30-38-4 5: 案内の本数は**繋いだ後**の本数（輪も1本と数える）
      hint(joined.length
        ? raDoneMsg(joined.length)
        : 'この枠の近くには道路のデータがありませんでした', 6000);
      return joined.length;
    }).catch(function (err) {
      hint('道路を取りに行けませんでした（' + (err && err.message ? err.message : '通信エラー') + '）', 5000);
      return 0;
    }).then(function (n) {
      roadAutoBusy = false;
      return n;
    });
  }

  /**
   * そのシートの出典表記（🔒 §24-3「シートごとに、そのシートで使ったデータ源だけ」）。
   * 🔴 旧データ（Step 5 まで）は案件に1つだけ持っていた。store.js の migrate が
   *    読み込み時にシートへ配ってから消すので、ここに来る時は既にシート持ち。
   *    それでも念のため案件側を見に行く（配り漏れがあっても出典が消えない方を採る）。
   */
  function sheetAttrs(sh) {
    if (sh && Array.isArray(sh.attributions)) return sh.attributions;
    var c = state.current;
    return (c && c.attributions) || [];
  }

  /**
   * 書き出す紙の一覧（🔒 §24-3 / §25-3: **1図1ページ**）。
   * 所在図シート×N →  配置図シート×N の順に、**全シート**を1枚ずつ返す。
   * 縦横は紙ごとに違ってよい（PDF は混在したまま出す）。
   *
   * 🔴 §22 / §24-3 課金カウント: **カウントは案件単位**。ここで枚数が何枚になっても
   *    1案件 ＝ 1件のまま。§22-6 のカウント実装を足す人は、
   *    **この配列の length（枚数）で数えてはいけない**（書き出し1回＝1件の判定は
   *    2地点100m／前回から30日のルール §22-2b で行う）。
   *
   * 🔒 §26-4-e: **図形が1個も無いシートは出さない**（白紙のページが提出物に混ざる）。
   *    🔒 §28-10 裁定6: 方位記号だけの紙も白紙（判定は sheetHasDrawing 1か所）。
   *    除いた枚数は state.pagesSkipped に置き、PDF/PNG の結果表示で伝える。
   *    🔴 通し表示（所在図 1/2）は**残った紙で採番し直す**。除いた番号を飛ばすと
   *       「1/3 と 3/3 だけがある」提出物になり、抜けたように見える。
   *
   * 🔒 §30-26-2: `sheetId` を渡すと**その紙1枚だけ**（紙の帯のルーペ＝この紙の
   *    プレビュー）。🔴 絞るのは**最後**＝通し表示（所在図 2/3）は絞る前の数え方の
   *    まま出す（「1/1」と出ると何枚目の紙なのか分からなくなる）。
   */
  /**
   * 🔒 §30-34-1（2026-09-15 オーナー指示「出すにした場合、1 も全体を枠とみなして、
   * 左上に 1 ということで出してほしい。いまは 2 だけ表示されており、なぜ 2？と
   * なりかねない」）: その紙に刷る「枠の範囲と番号の札」の一覧を作る。
   * @param kind    'shozaizu' | 'haichizu'
   * @param sheetId その紙の id（この紙が own＝自分）
   * @return [{frame, label, own}]（同じ図の紙**ぜんぶ**・番号は紙の帯と同じ i+1）
   * 🔴 白紙の紙も入れる（番号は紙の帯と揃える＝書き出しで白紙を除いても札はずれない）。
   * 🔴 「自分」の判定は**紙の id**（表示している文字や番号では判定しない）。
   * 🔴 枠が作れない紙は飛ばす（描きようがない）。
   */
  function frameMarksFor(kind, sheetId) {
    var out = [];
    sheetsOf(kind).forEach(function (sh, i) {
      if (!sh) return;
      var f = frameForSheet(kind, sh);
      if (!f) return;
      out.push({ frame: f, label: String(i + 1), own: sh.id === sheetId });
    });
    return out;
  }

  function pagesForExport(only, sheetId) {
    // 表示中のシートは必ず「いまの画面」を使う。
    // ズームやパンをした後に古い枠で出さないため（オーナー指摘 2026-08-16）。
    syncFrameFromView();
    ensureFrames();
    var out = [], skipped = 0;
    KINDS.forEach(function (k) {
      /* 🔒 §30-13-3: only を渡すとその種類の紙だけ（所在図プレビューの
       * ［PDF保存］［画像保存］＝所在図の紙だけ）。白紙の枚数も同じ絞りで数える。 */
      if (only && k !== only) return;
      var kept = sheetsOf(k).filter(function (sh) {
        // 🔒 §28-10 裁定6: 方位記号（compass）しか無い紙も白紙（判定は1か所）
        if (sheetHasDrawing(sh)) return true;
        skipped++;
        return false;
      });
      kept.forEach(function (sh, i) {
        out.push({
          kind: k, kindJa: KIND_JA[k], index: i + 1, total: kept.length,
          // 🔒 §30-26-2/3: どの紙か（ルーペの絞り込み・他の枠の「自分を除く」で使う）
          sheetId: sh.id,
          orient: sh.orient === 'landscape' ? 'landscape' : 'portrait',
          objects: sh.objects || [],
          frame: frameForSheet(k, sh),
          attributions: sheetAttrs(sh),
          noScale: sheetScaleUnknown(k),
          /* 🔒 §30-34-1 3: 他の紙の枠の範囲＋番号の札。**出どころはここ1か所**
           * （プレビューも PDF も画像もまとめも、この frameMarks を紙の描画へ渡す）。 */
          frameMarks: frameMarksFor(k, sh.id)
        });
      });
    });
    state.pagesSkipped = skipped;
    // 🔒 §30-26-2: 絞るのは最後（通し表示は絞る前の数え方のまま）
    if (sheetId) {
      return out.filter(function (p) { return p.sheetId === sheetId; });
    }
    return out;
  }

  /** 🔒 §26-4-e: 白紙で除いた枚数の一言（無ければ空文字） */
  function skippedNote() {
    return state.pagesSkipped
      ? '（図形が無い白紙のシート ' + state.pagesSkipped + ' 枚は除きました）' : '';
  }

  /* ===== 🔒 §30-32-3（2026-09-15 オーナー指示「保存すると所在図のファイルに
   * 上書きして所在図が消える。ファイル名に図とページ番号と時間を追加。
   * 毎回上書きはだめ、絶対違うファイルとして保存」）=====
   * 書き出しのファイル名は **exportFileName 1関数**（PDF・画像・まとめの全経路が
   * ここを通る＝出口は1つ）。旧 baseFileName ＋ pageSuffix の置き換え。
   *   案件番号_図と紙_日時.拡張子
   *   例 2026-003_所在図1_20260915-1432.pdf
   *      2026-003_所在図1-2_配置図1_20260915-1432.pdf
   *      2026-003_まとめ_20260915-1432.pdf
   *      2026-003_配置図2_20260915-1432.png（画像は紙ごと1枚）
   * 🔴 同じ名前が案件フォルダにあれば FSave が `-2` `-3` を付ける（上書きしない）。
   */

  /** 日時（分まで・ローカル時刻）。🔴 形の出どころはこの1か所 */
  function exportStamp() {
    var d = new Date(), p2 = function (n) { return String(n).padStart(2, '0'); };
    return d.getFullYear() + p2(d.getMonth() + 1) + p2(d.getDate())
         + '-' + p2(d.getHours()) + p2(d.getMinutes());
  }

  /**
   * ファイル名の「図と紙」の部分。選んだ紙を**図ごとにまとめる**
   * （所在図1／所在図1-2／所在図1-2_配置図1）。
   * @param {Array} pick 出す紙の一覧（pagesForExport の形）
   */
  function exportSheetPart(pick) {
    var list = pick || [], order = [], byKind = {};
    list.forEach(function (p) {
      if (!p) return;
      var ja = p.kindJa;
      if (!byKind[ja]) { byKind[ja] = []; order.push(ja); }
      byKind[ja].push(p.index);
    });
    if (!order.length) return '図';
    return order.map(function (ja) { return ja + byKind[ja].join('-'); }).join('_');
  }

  /**
   * 書き出しのファイル名（🔒 §30-32-3 2「出どころは1関数」）。
   * @param {Array} pick 出す紙の一覧（画像は1枚ぶんの配列・まとめは null でよい）
   * @param {string} kind 'combo' ＝ まとめ（1枚）。それ以外は pick から作る
   * @param {string} ext  'pdf' / 'png'（点は付けない）
   */
  function exportFileName(pick, kind, ext) {
    var c = state.current;
    /* 🔒 §19-1: 案件番号があればファイル名の**先頭**に付ける。
       紙ファイル・受付簿・請求と1本の線でつながるのが本件の主目的。
       🔴 番号が空の案件は別の案件と名前が並ぶので、案件名を頭に置く。 */
    var head = Store.filePrefix(c) || (Store.safeName(c && c.name) + '_');
    var what = (kind === 'combo') ? 'まとめ' : exportSheetPart(pick);
    return head + what + '_' + exportStamp() + '.' + ext;
  }

  /* 🔒 §21-1: 書き出し（PDF / PNG）の保存口は**ここ1本**。
     案件フォルダへ直行し、権限拒否・書き込み失敗ならダウンロードへ落ちる（救済）。
     振り分けは FSave（js/fsave.js）の仕事。
     @returns Promise<{mode,dir,name,failed}> */
  function saveBlob(blob, filename) {
    return FSave.saveBlob(filename, blob);
  }

  /** 🔒 §21-1 / §27-12-3: 保存結果のヒントと、書き出しパネルへ足す一言。
      案件フォルダへ書けたら「保存しました: <フォルダ名>/<ファイル名>」、
      書けなかった時は「ダウンロードに保存しました」（救済）を出す。
      PNG のように複数枚を一度に出す経路があるので、配列も受ける（§21-1 の④）。 */
  function saveWhere(rs) {
    var list = (rs && rs.length !== undefined) ? rs : (rs ? [rs] : []);
    if (!list.length) return '';
    var failed = list.filter(function (r) { return r.mode !== 'folder' && r.failed; });
    if (failed.length) {
      hint('案件フォルダに書けなかったので、ダウンロードに保存しました', 6000);
      return '（案件フォルダに書けなかったので、ダウンロードに保存しました）';
    }
    var inDir = list.filter(function (r) { return r.mode === 'folder'; });
    if (!inDir.length) return '';
    var where = inDir.map(function (r) { return r.dir + '/' + r.name; }).join('　');
    hint('保存しました: ' + where);
    return '（' + where + ' に保存しました）';
  }

  /** done(メッセージ, 成功したか) は誘導⑪から結果を受け取るために使う（§18-f）
   *  🔴 §22: 書き出しで何ページ出ても課金は**案件単位**（pagesForExport の注記参照）
   *  🔒 §30-27-2: `only` の代わりに **紙の一覧（pick）** を渡せる口を足した
   *     （PDF・画像の窓でチェックした紙だけを出す）。並びは pagesForExport のまま
   *     ＝所在図→配置図・番号順。渡さなければ従来どおり（only の絞りだけ）。 */
  function exportPDF(done, only, pick) {
    if (!state.current) return;
    /* 🔒 §21-2: フォルダの権限はクリック（ユーザー操作）の中で先に取っておく。
       PDF の組み立てに時間がかかると、後から requestPermission が通らなくなる */
    FSave.prepare();
    /* 🔒 §30-29-1 3: 経過と結果の一言は**出す紙を選ぶ窓**（#exPickMsg）と
     * プレビューの帯（#exBarMsg）が出す＝done() 1本に寄せた
     * （旧 #exPanel の #exResult / #exPdf の disabled は窓ごと廃止）。 */
    setTimeout(function () {
      var blob, pages;
      try {
        // 🔒 §30-13-3: only='shozaizu' なら所在図だけ／🔒 §30-27-2: pick があればそれ
        pages = pick || pagesForExport(only);
        /* 🔒 §26-4-e: 白紙を除いた結果1枚も残らない時は、buildPDF の
           「枠が未設定です」ではなく本当の理由を伝える。 */
        if (!pages.length) {
          finish('書き出せる図がありません。'
                 + (state.pagesSkipped ? skippedNote() : '') + '先に図を作ってください。', false);
          return;
        }
        // 🔒 §24-3: 所在図・配置図の全シートを1図1ページで出す（縦横混在可）
        /* 🔒 §30-34-1 1: トグル「他の枠の範囲を表示」が ON なら紙にも刷る
         * （プレビューで見えている絵と紙が同じになる）。 */
        var doc = Exporter.buildPDF(pages, { name: state.current.name,
                                             showFrames: state.exOtherFrames });
        blob = doc.output('blob');
      } catch (e) {
        finish('失敗しました: ' + (e.message || e), false);
        return;
      }
      // 🔒 §21-1: 保存は saveBlob() 1本（フォルダ直行／失敗時はダウンロード）
      // 🔒 §30-32-3: 名前は exportFileName 1か所（選んだ紙が名前に出る・毎回別名）
      saveBlob(blob, exportFileName(pages, null, 'pdf')).then(function (r) {
        finish('PDF を保存しました（' + pages.length + ' ページ・'
               + (blob.size / 1048576).toFixed(2) + ' MB）。'
               + skippedNote() + saveWhere(r), true);
      });
    }, 30);

    function finish(msg, ok) {
      if (typeof done === 'function') done(msg, ok);
    }
  }

  /** 🔒 §24-3: PNG は**シートごとに1枚**。ファイル名に種類と番号を入れる
   *  🔒 §30-27-2: `pick`（紙の一覧）を渡せる口は exportPDF と同じ */
  function exportPNG(done, only, pick) {
    if (!state.current) return;
    FSave.prepare();                       // 🔒 §21-2（exportPDF と同じ理由）
    // 🔒 §30-29-1 3: 経過と結果の一言は done() 1本（exportPDF と同じ）
    setTimeout(function () {
      var jobs = [];
      try {
        // 🔒 §30-13-3 / 🔒 §30-27-2（pick があればチェックした紙だけ）
        (pick || pagesForExport(only)).forEach(function (p) {
          if (!p.frame) return;
          var r = Exporter.renderSheet({
            objects: p.objects, frame: p.frame, orient: p.orient,
            attributions: p.attributions,     // 🔒 §24-3 出典はシートごと
            noScale: p.noScale,
            /* 🔒 §26-4-e: PNG は見出し帯を持たない1枚画なので、通し表示を
               図の中（左上）に入れる。PDF は帯に入るので渡さない（二重にしない）。 */
            pageMark: Exporter.pageMark(p),
            // 🔒 §30-34-1 1: 他の枠の範囲＋番号の札（トグルが ON の時だけ）
            frameMarks: p.frameMarks, showFrames: state.exOtherFrames
          });
          /* 🔒 §21-1: canvas.toBlob → saveBlob（フォルダ直行／失敗時はダウンロード）。
             フォルダ保存は非同期なので、全枚数の結果が揃うまで待ってから報告する */
          jobs.push(new Promise(function (resolve) {
            r.canvas.toBlob(function (blob) {
              // 🔒 §30-32-3: 画像は紙ごと1枚（名前も紙1枚ぶん・毎回別名）
              saveBlob(blob, exportFileName([p], null, 'png')).then(resolve);
            }, 'image/png');
          }));
        });
      } catch (e) {
        finish('失敗しました: ' + (e.message || e), false);
        return;
      }
      if (!jobs.length) {
        finish('0 枚の PNG を保存しました。' + skippedNote(), false);
        return;
      }
      Promise.all(jobs).then(function (rs) {
        finish(rs.length + ' 枚の PNG を保存しました。'
               + skippedNote() + saveWhere(rs), true);
      });
    }, 30);

    function finish(msg, ok) {
      if (typeof done === 'function') done(msg, ok);
    }
  }

  /* ================= プレビューで文字だけ動かす（🔒 §30-25-10） =================
   * オーナー指示 2026-09-13:「所在図プレビューの画面で、テキストだけ移動や
   * サイズ調整ができるように。その案内を一番上に」。
   * 作り: 紙の画像の上に**透明な層**を重ね、`renderSheet` が返す文字の箱
   *   （r.textBoxes・canvas px）に合わせて掴める枠を並べる。
   * 🔴 箱の出どころは描画と同じ1か所（別に見積もると画像と枠がずれる）。
   * 🔴 触れるのは文字（type:'text'）だけ。線・印・枠はここでは動かせない。
   * 🔴 結果は案件の図形そのもの（o.at / o.sizeMm）に入る＝閉じた後の地図・
   *    書き出しにそのまま効く。1操作＝snapshot＋commit（Ctrl+Z で戻る）。
   * 🔴 まとめ描き（renderCombined）は対象外（showCombinedPreview は層を付けない）。 */

  /** 層の置き直し（画像の読み込み・窓の大きさ変更で呼ぶ）。プレビューごとに作り直す */
  var exPlacers = [];
  function exRelayout() {
    for (var i = 0; i < exPlacers.length; i++) {
      try { exPlacers[i](); } catch (e) {}
    }
  }
  function exPlacersReset() { exPlacers.length = 0; }

  /* ---- 🔒 §30-26-3 → §30-34-1 3 改定: 「他の枠の範囲を表示」 ----
   * トグル（#exOtherFrames）が ON の時、同じ図の紙の枠（赤の破線＋白い縁）と
   * 番号の札を出す。自分の紙にも札を出す（自分の枠＝作図領域そのもの・線は
   * 引かない）。
   * 🔴 旧版はプレビューの画像の上に SVG を重ねていた（exFrameLayer /
   *    exOtherFrameRects / .ex-framelayer）ため、PDF・PNG にすると消えていた。
   *    今は **紙の描画（Exporter.renderSheet の frameMarks / showFrames）1本**で
   *    描く＝プレビューで見えている絵と紙が必ず同じになる。
   * 🔴 札の一覧の出どころは pagesForExport が付ける frameMarks 1か所
   *    （frameMarksFor）。見た目の値は export.js の FRAME_MARK 1か所。 */
  /** トグルの見た目を state に合わせる（閉じても覚えている＝§30-26-3 1） */
  function exFrameSwitchSync() {
    var sw = $('exOtherFrames');
    if (sw) sw.checked = !!state.exOtherFrames;
  }

  /**
   * 🔒 §30-25-10 6 → §30-25-16 改定: 案内は**紙の器の外**（見出しのすぐ下の行）。
   * 🔴 文は index.html の #exPreviewTip が持つ。ここは**出し入れするだけ**
   *    （器に足すと .is-nav の nowrap で紙が押しつぶされる）。
   * @param show true＝出す／false＝隠す
   */
  function exTextTip(show) {
    var p = $('exPreviewTip');
    if (p) p.hidden = !show;
  }

  /** その紙の中から id の図形を探す（紙の配列が写しでも本体を書けるように） */
  function exFindObj(p, id) {
    var i, list = (p && p.objects) || [];
    for (i = 0; i < list.length; i++) if (list[i] && list[i].id === id) return list[i];
    var sheets = sheetsOf(p && p.kind);
    for (var s = 0; s < sheets.length; s++) {
      var objs = (sheets[s] && sheets[s].objects) || [];
      for (i = 0; i < objs.length; i++) if (objs[i] && objs[i].id === id) return objs[i];
    }
    return null;
  }

  /** その文字の紙面ミリ（連続値が無ければ3段の既定。表は Exporter 1か所） */
  function exTextMm(o) {
    if (window.Editor && Editor.textMm) return Editor.textMm(o);
    var T = (window.Exporter && Exporter.SHEET_TEXT_MM) || { medium: 3.4 };
    return (o && o.sizeMm > 0) ? o.sizeMm : (T[o && o.size] || T.medium);
  }
  function exClampMm(mm) {
    if (window.Editor && Editor.clampTextMm) return Editor.clampTextMm(mm);
    return Math.max(1.2, Math.min(30, Math.round(mm * 100) / 100));
  }

  /**
   * 1枚の紙に「文字だけ動かす」層をかぶせる。
   * 🔒 §30-32-2: **駐車位置ラベルの塊（labelBlock）も同じ層で動かせる**
   *   （ドラッグで塊＝`at` だけ／矢印の先 `arrowTo` は動かさない・右下のつまみで `scale`）。
   * @param fig <figure>（中に img が入っている・position:relative）
   * @param img その <img>
   * @param p   その紙（pagesForExport の1件。kind / objects / frame / orient）
   * @param r0  Exporter.renderSheet の返り値（canvas・textBoxes・labelBoxes・place）
   * @param onRedraw 描き直した後に新しい dataURL を渡す（ページ送りの控えの更新）
   */
  function exTextLayer(fig, img, p, r0, onRedraw) {
    if (!window.Exporter || !p || !p.frame || !fig || !img) return;
    var layer = document.createElement('div');
    layer.className = 'ex-textlayer';
    fig.appendChild(layer);
    var cur = r0;
    /* 紙に刷られる幅(mm) ÷ canvas の幅(px)。まとめ描きの paperMm 上書きにも効く */
    var SS = (window.Exporter && Exporter.SHEET_SCALE > 0) ? Exporter.SHEET_SCALE : 1;

    function mmPerCanvasPx() {
      return (cur.place && cur.place.w > 0 && cur.canvas.width > 0)
        ? cur.place.w / cur.canvas.width : 0;
    }
    /** 表示px ÷ canvas px */
    function viewK() {
      return (img.clientWidth > 0 && cur.canvas.width > 0)
        ? img.clientWidth / cur.canvas.width : 0;
    }

    function place() {
      var k = viewK();
      if (!k) return;
      layer.style.left = (img.offsetLeft + img.clientLeft) + 'px';
      layer.style.top = (img.offsetTop + img.clientTop) + 'px';
      layer.style.width = img.clientWidth + 'px';
      layer.style.height = img.clientHeight + 'px';
      var kids = layer.children;
      for (var i = 0; i < kids.length; i++) {
        var b = kids[i]._box;
        if (!b) continue;
        kids[i].style.left = (b.x * k) + 'px';
        kids[i].style.top = (b.y * k) + 'px';
        kids[i].style.width = Math.max(8, b.w * k) + 'px';
        kids[i].style.height = Math.max(8, b.h * k) + 'px';
      }
    }
    exPlacers.push(place);
    img.addEventListener('load', place);

    /** 動かした後に、その紙だけ描き直す（他の紙は触らない） */
    function redraw() {
      try {
        cur = Exporter.renderSheet({
          objects: p.objects, frame: p.frame, orient: p.orient,
          attributions: p.attributions, noScale: p.noScale, dpi: 96,
          // 🔒 §30-34-1 3: 描き直しても他の枠の範囲が消えないように同じ口を通す
          frameMarks: p.frameMarks, showFrames: state.exOtherFrames
        });
      } catch (e) { return; }
      var url = cur.canvas.toDataURL('image/png');
      img.src = url;
      if (typeof onRedraw === 'function') onRedraw(url, cur);
      build();
    }

    function start(e, box, d, sizing) {
      if (e.button !== 0) return;
      var o = exFindObj(p, box.id);
      if (!o || !o.at) return;
      e.preventDefault();
      e.stopPropagation();
      var target = e.currentTarget;
      try { target.setPointerCapture(e.pointerId); } catch (err) {}
      d.classList.add('is-grab');
      /* 🔴 いま editor が読み込んでいる紙なら履歴に載せる（Ctrl+Z で戻る）。
       * 別の紙は editor の履歴に入れられないので、直接書いて保存だけする。 */
      var live = !!(state.editor && state.editor.objects === p.objects);
      if (live) state.editor.snapshot();
      var k = viewK(), mpp = mmPerCanvasPx();
      var x0 = e.clientX, y0 = e.clientY;
      var at0 = { lat: o.at.lat, lng: o.at.lng };
      var mm0 = exTextMm(o);
      /* 🔒 §30-32-2: 駐車位置ラベルの塊は「紙のミリ」ではなく**倍率（scale）**で
       * 大きさが決まる（画面の右下のつまみと同じ値・同じ範囲）。 */
      var isLabel = (o.type === 'labelBlock');
      var sc0 = isLabel ? (Editor.clampLabelScale ? Editor.clampLabelScale(o.scale) : (o.scale || 1)) : 1;
      var diag0 = Math.max(8, Math.hypot(box.w * k, box.h * k));
      var moved = false;

      function toMm(dPx) { return (k > 0) ? dPx / k * mpp : 0; }

      function onMove(ev) {
        var dx = ev.clientX - x0, dy = ev.clientY - y0;
        if (!moved && Math.abs(dx) + Math.abs(dy) < 2) return;
        moved = true;
        if (sizing && isLabel) {
          /* 掴んだ時の対角を基準に、引いた分だけ倍率を上げ下げする
           * （画面のつまみ＝editor の lbSize と同じ理屈・丸めと上下限も同じ1か所）。 */
          var dd = Math.hypot(box.w * k + dx, box.h * k + dy);
          var sc = Editor.clampLabelScale
            ? Editor.clampLabelScale(sc0 * (dd / diag0)) : sc0;
          o.scale = sc;
          d.style.transformOrigin = 'top left';   // at ＝ 塊の左上（labelBlockGeom）
          d.style.transform = 'scale(' + (sc / (sc0 || 1)).toFixed(3) + ')';
        } else if (sizing) {
          /* 紙に刷られる高さ（mm）を縦の動きぶん増やす。o.sizeMm は
           * 「記載欄基準の mm」なので SHEET_SCALE で割って戻す（textPx と同じ単位）。 */
          var mm = exClampMm(mm0 + toMm(dy) / SS);
          o.sizeMm = mm;
          d.style.transform = 'scale(' + (mm / (mm0 || 1)).toFixed(3) + ')';
        } else {
          var dd = Exporter.paperDeltaToLatLng(p.frame, p.orient, toMm(dx), toMm(dy));
          o.at.lat = at0.lat + dd.dLat;
          o.at.lng = at0.lng + dd.dLng;
          d.style.transform = 'translate(' + dx + 'px,' + dy + 'px)';
        }
      }
      function onUp() {
        target.removeEventListener('pointermove', onMove);
        target.removeEventListener('pointerup', onUp);
        target.removeEventListener('pointercancel', onUp);
        d.classList.remove('is-grab');
        d.style.transform = '';
        if (!moved) {                       // 動かしていない＝履歴に残さない
          if (live && state.editor.undoStack.length) state.editor.undoStack.pop();
          return;
        }
        if (live) state.editor.commit();    // 描き直し＋保存（change）
        else Store.autosave(state.current);
        state.exTextDirty = true;
        redraw();
        updateHistoryButtons();
      }
      target.addEventListener('pointermove', onMove);
      target.addEventListener('pointerup', onUp);
      target.addEventListener('pointercancel', onUp);
    }

    function build() {
      while (layer.firstChild) layer.removeChild(layer.firstChild);
      /* 🔒 §30-32-2: 掴める的は2種（文字の箱／駐車位置ラベルの塊の箱）。
       * 🔴 どちらも箱の出どころは renderSheet（描画と同じ1か所）。作り方も同じ。 */
      var boxes = (cur.textBoxes || []).concat(cur.labelBoxes || []);
      boxes.forEach(function (b) {
        var d = document.createElement('div');
        d.className = 'ex-textbox';
        d.dataset.id = b.id;
        d._box = b;
        d.title = 'ドラッグで動かす／右下のつまみで大きさを変える';
        var h = document.createElement('div');
        h.className = 'ex-texthandle';
        d.appendChild(h);
        d.addEventListener('pointerdown', function (e) { start(e, b, d, false); });
        h.addEventListener('pointerdown', function (e) { start(e, b, d, true); });
        layer.appendChild(d);
      });
      place();
    }
    build();
  }

  /* ============ 🔒 §30-27-1: プレビュー画面は1つ ============
   * オーナー指示 2026-09-14:「プレビュー画面は1つでいい。所在図と配置図はトグル切替。
   *   1つのプレビュー画面を全てが使えば、そこで1を見る、2を見る、切り替えができ、
   *   次のページボタンが右端にあれば連続でどんどん確認できる」。
   * 入口（所在図④⑧・配置図⑧・紙の帯のルーペ・上部バー［書き出し］・まとめ描き）は
   * 全部 openPreview() を呼ぶ。渡すのは「どの図のどの紙から見せるか」だけ。
   * 🔴 ページの並びは pagesForExport() 1本（所在図→配置図・番号順）。
   *    条件を満たす時だけ、末尾に「まとめ（1枚）」の面が1つ付く（§30-18-6 2 の条件）。 */

  /** まとめ（1枚）の面か（🔴 判定は番号だけ＝表示文字では分岐しない） */
  function exIsCombo(i) {
    var pg = state.exPager;
    return !!(pg && pg.combo && i === pg.pages.length);
  }
  /** その番号の図の種類（まとめの面は null） */
  function exKindAt(i) {
    var pg = state.exPager;
    if (!pg || i < 0 || i >= pg.pages.length) return null;
    return pg.pages[i].kind;
  }
  /** 最後の面の番号（まとめの面があればその番号） */
  function exLastIndex() {
    var pg = state.exPager;
    if (!pg) return 0;
    return pg.pages.length + (pg.combo ? 1 : 0) - 1;
  }

  /**
   * プレビューを開く（🔒 §30-27-1 1）。
   * @param o.kind     その図の1枚目から見せる（'shozaizu' / 'haichizu'）
   * @param o.sheetId  その紙から見せる（紙の帯のルーペ・§30-26-2）
   * @param o.combined まとめ（1枚）の面から見せる（条件を満たす時だけ）
   * @param o.foot     所在図④⑧から出した時だけ true（下部の行き先ボタン列・§30-13-3）
   * @param o.nav      ガイダンスの左面を隠さない置き方にする（§18-f）
   */
  function openPreview(o) {
    o = o || {};
    if (!state.current) return;
    var list = pagesForExport().filter(function (p) { return !!p.frame; });
    var inf = sgComboInfo();          // 🔴 まとめられるかの判定は sgComboInfo 1か所
    if (!list.length) {
      hint('書き出せる図がありません。先に図を作ってください。', 3500);
      return;
    }
    var i = 0, k;
    if (o.combined && inf.ok) {
      i = list.length;                                   // 末尾＝まとめの面
    } else if (o.sheetId) {
      for (k = 0; k < list.length; k++) {
        if (list[k].sheetId === o.sheetId) { i = k; break; }
      }
    } else if (o.kind) {
      for (k = 0; k < list.length; k++) {
        if (list[k].kind === o.kind) { i = k; break; }
      }
    }
    state.exPager = {
      pages: list, i: i, url: {}, r: {}, scale: {},
      combo: !!inf.ok, comboInfo: inf,
      /* 🔴 まとめの面には図の種類が無いので、直前に見ていた図を覚えておく
       * （トグルと紙の札はこの値で決まる）。 */
      kindNow: (i < list.length) ? list[i].kind : list[0].kind
    };
    if (o.nav) navPreviewFrame();     // 🔒 §18-f: 左面（ガイダンス）を隠さない置き方
    /* 🔒 §30-13-3: 下部の行き先ボタン列は**所在図ガイダンス⑧から出した時だけ**。 */
    var foot = $('exPreviewFoot');
    if (foot) {
      foot.hidden = !o.foot;
      $('exPreviewFootMsg').textContent = '';
    }
    $('exBarMsg').textContent = '';
    exKindNoteHide();                 // 🔒 §30-27-1 3: 開いた直後は帯を出さない
    $('exPreviewBox').hidden = false;
    /* 🔒 §30-13-3: プレビューを出している間は字幕を隠す（紙面に重ならないように）。
     * 🔴 reset=true＝閉じた時に同じ文をまた出せるようにする（§30-10）。 */
    sgCaptionHide(true);
    exPagerRender();
    // 誘導から出した時は下部のボタンを押し続けたいので、焦点を奪わない
    if (!state.navPreview) $('exPreviewClose').focus();
  }

  /** 🔒 §30-27-1 3: 「配置図に切り替わりました」の薄い帯（約3秒）。
   *  🔴 文は KIND_JA の表から作る（表示文字では分岐しない）。消えるのは CSS の transition。 */
  var exKindNoteT = 0, exKindNoteT2 = 0;
  function exKindNoteShow(kind) {
    var el = $('exKindNote');
    if (!el || !KIND_JA[kind]) return;
    clearTimeout(exKindNoteT);
    clearTimeout(exKindNoteT2);
    el.textContent = KIND_JA[kind] + 'に切り替わりました';
    el.setAttribute('data-kind', kind);
    el.hidden = false;
    // [hidden] は display:none なので、外してから .is-on を付ける（transition が効く）
    requestAnimationFrame(function () { el.classList.add('is-on'); });
    exKindNoteT = setTimeout(function () {
      el.classList.remove('is-on');
      exKindNoteT2 = setTimeout(function () { el.hidden = true; }, 400);
    }, 3000);
  }
  function exKindNoteHide() {
    var el = $('exKindNote');
    if (!el) return;
    clearTimeout(exKindNoteT);
    clearTimeout(exKindNoteT2);
    el.classList.remove('is-on');
    el.hidden = true;
  }

  function closeExportPreview() {
    var was = !$('exPreviewBox').hidden;
    $('exPreviewBox').hidden = true;
    $('exPreviewBox').classList.remove('is-nav');
    if ($('exPreviewFoot')) $('exPreviewFoot').hidden = true;
    // 🔒 §30-27-1 2/6: 道しるべの行と［PDF］［画像］の帯も畳む
    if ($('exPreviewNav')) $('exPreviewNav').hidden = true;
    if ($('exPreviewBar')) $('exPreviewBar').hidden = true;
    exKindNoteHide();                   // 🔒 §30-27-1 3
    sideFront(false);
    state.navPreview = false;
    state.exPager = null;               // 🔒 §30-18-6 2: ページ送りも仕切り直す
    $('exPreviewBody').innerHTML = '';   // 画像を抱えたままにしない
    exTextTip(false);                   // 🔒 §30-25-16: 案内も隠す
    exPlacersReset();                   // 🔒 §30-25-10: 層の置き直しも捨てる
    /* 🔒 §30-25-10 4: プレビューで文字を動かしたら、地図にもそのまま効く。
     * 別の紙を動かした時は editor が描き直していないので、閉じた時に1回引き直す。 */
    if (state.exTextDirty) {
      state.exTextDirty = false;
      if (state.editor) state.editor.render();
    }
    /* 🔒 §30-13-3: 閉じたら字幕を戻す（所在図④なら⑧の文）。
     * 🔴 番号と字幕の出どころは sgRenderNums 1か所（ここで文を書かない）。
     * 🔒 §30-13-7 3: ここも「字幕を出す時」＝置き場所を引き直す契機（同じ文でも）。 */
    if (was && state.nav && navOnSide()) { sgCap.replace = true; sgRenderNums(); }
  }

  /**
   * 🔒 §29 Step 7: ガイダンスから出したプレビューは**左面を隠さない**。
   * かぶせ（.ex-preview は z-index 60 の全面）より左面を前に出して、
   * ⑫の［PDF］［画像］を押しながら紙面を見られるようにする。
   * 🔴 小ウィンドウ時代の .nav-panel.is-front と同じ役目（器が左面に変わっただけ）。
   */
  function sideFront(on) {
    var el = document.querySelector('.side');
    if (el) el.classList.toggle('is-front', !!on);
  }

  /* ---------- 所在図の自動生成（正典 §5） ---------- */

  /**
   * 所在図の書き出し範囲を決める。
   * 🔴 §22-an（2026-09-04 オーナー指示）: 枠が未確定の紙は、**いまの画面（中心・ZL）を
   *    動かさずそのまま枠にする**。生成のたびに ZL を自動調整していたのが真因の不具合
   *    （住所検索で ZL17 になったのに［標準の設定で作る］を押すと ZL16 に変わる）を
   *    直すため、以前ここにあった fitPoints / setView(…, 16) / widenFrameToMin の
   *    呼び出しは撤去した。§26-4-a（裁定1・枠が狭い時に最小300mまで広げる）も、
   *    その原因だった fitPoints の寄り過ぎが無くなったので合わせて廃止。
   * 🔴 使用の本拠と駐車場が離れていて片方が枠の外に切れても、案内は出さず何もしない
   *    （B1・オーナー決定＝シートを分けて描く前提。枠外の主役は描かれないだけで
   *    §18-n-4 と同じ扱い）。
   */
  function frameShozaizu() {
    var c = state.current;
    var sh = sheetOf('shozaizu');
    /* 🔒 §26-4-b（裁定2）: ユーザーが明示的に［枠を決定］した紙は、生成が壊さない。
     * 🔴 決定済み（frameFixed）ならその枠の bounds をそのまま使う
     *    （runShozaizu が返り値の frame で解く）。 */
    if (sh && sh.frameFixed && sh.frame && sh.frame.center && sh.frame.w_m) {
      return sh.frame;
    }
    var pts = [c.points.home, c.points.lot].filter(Boolean);
    if (!pts.length) return null;
    // 書き出し範囲はいまの画面そのもの（④のプレビュー・⑪・上部の書き出しで同じ物を使う）
    var f = frameFromView();
    /* 🔴 §24-4: 誘導（§18）は従来どおり動かす。枠が**未決定**の紙は、生成が
     * 枠を決める工程なので、ここで作った枠を入れて画面追従のままにする。 */
    if (sh && f) { sh.frame = f; sh.frameFixed = false; }
    return f || (sh && sh.frame) || null;
  }

  /**
   * 枠（center/w_m/aspect）を画面の「紙1枚」に映した時のズーム値。
   * 🔒 §26-4-b: 決定済みの枠で生成する時は、地図がどこまで寄っていても
   *    **紙に載る範囲の細かさ**でタイルを取るために使う（地図のズームを使うと、
   *    引いた状態なら粗すぎ・寄せた状態なら fetchTiles の枚数ガードで falling back する）。
   */
  function zoomForFrame(f) {
    var mv = state.map;
    if (!mv) return 16;
    if (!f || !f.w_m || !f.center) return mv.getZoom();
    var r = frameRectPxFor(Exporter.frameAspect(f));
    if (!r.w) return mv.getZoom();
    var mpp = f.w_m / r.w;
    var z = Math.log(40075016.686 * Math.cos(f.center.lat * Math.PI / 180)
                     / (256 * mpp)) / Math.LN2;
    return isFinite(z) ? mv.snapZoom(z) : mv.getZoom();
  }

  /**
   * 設定盤の項目を1つ変えた後の共通処理（🔒 2026-09-03）。
   * 案件へ保存し、既に所在図があるならその場で作り直す。
   * 🔴 まだ所在図が空の案件では作り直さない（設定だけ覚える）。空の図に対して
   *    毎回タイルを取りに行くのは待たせるだけで、ユーザーの意図でもない。
   */
  function szSettingChanged(ja) {
    if (!state.current) return;
    Store.autosave(state.current);
    if (!navHasShozaizu()) return;
    var busy = (ja || '設定') + 'を変えて作り直しています…';
    setSzResult(busy);
    navSetStatus(busy);
    runShozaizu(true).then(function (res) {
      navSetStatus(navSzResultText(res));
    });
  }

  /**
   * 🔒 2026-09-03 オーナー指示（タスク3）: ［標準の設定で作る］。
   * ①背景の地図を非表示にする ②全項目を「標準」にする ③所在図を描画する。
   * 🔴 ②は**調整済みの設定を捨てる**動作。ボタンの文言（「標準の設定で作る」）と
   *    title で先に伝えてある（無言でリセットしない・§22-ak-3 でパネルの注意文は
   *    後半の6項目のために title へ寄せた）。個別に変えた時の
   *    「その場で作り直す」作法（szSettingChanged）は従来どおり残している。
   */
  function runShozaizuStandard() {
    var c = state.current;
    if (!c) return Promise.resolve(null);
    if (state.kind !== 'shozaizu') switchKind('shozaizu');
    setUnderlayOffState(true);                 // ①（§18-x-4 と同じ「白地で見る」）
    Object.keys(SZ_STD).forEach(function (k) { c[k] = SZ_STD[k]; });   // ②
    syncSzPanel();
    Store.autosave(c);
    return runShozaizu();                      // ③
  }

  /**
   * 所在図を作る。silent=true で通知を出さない。
   * 🔒 §18-ab: 生成は**常に前回の自動生成物を差し替える**（重ねる選択肢は廃止した）。
   *    手で描いた図形は source が違うので、この差し替えでは消えない。
   */
  function runShozaizu(silent) {
    var c = state.current;
    if (!c) return Promise.resolve(null);
    if (state.kind !== 'shozaizu') switchKind('shozaizu');
    if (!c.points.home && !c.points.lot) {
      /* 🔒 §30-39-4 4: 促し方を新しい作法（住所を検索すると◎が置かれる）に合わせる */
      setSzResult('先にマーカーを置いてください（左の住所の欄に住所を入れて'
        + '［検索］を押すと、その場所に◎が置かれます）。');
      return Promise.resolve(null);
    }
    if (!c.points.home) {
      setSzResult('使用の本拠の住所も入れると、2地点間の距離と2km判定が出ます。');
    }
    /* 🔒 §18-r: 目標物の件数を切り替えた時、**役割ラベル（自宅・駐車場・距離）は動かさない**。
     * 枠が変わっていない＝同じ図の作り直しの時だけ、前回の文字の位置を引き継ぐ
     * （枠が変わった時は位置ごと作り直すのが正しい）。 */
    var prevSheet = sheetOf('shozaizu');
    var prevFrame = (prevSheet && prevSheet.frame)
      ? JSON.parse(JSON.stringify(prevSheet.frame)) : null;
    /* 🔒 §30-25-28 4: ①でマーカーを置いた時に作った主役の文字は「前回の生成の
     * 位置」ではない。**まだ一度も生成していない紙**では位置を引き継がず、
     * 生成に「名前の位置」の規則どおり置かせる（手で動かした文字は userMoved で
     * 文字ごと残るので、こちらの経路には乗らない）。
     * 🔴 判定は「主役の印と文字**以外**の生成物があるか」＝表示文字では分岐しない。 */
    var wasGenerated = state.editor.objects.some(function (o) {
      return o && o.source === 'shozaizu'
          && o.role !== 'pinlabel' && o.role !== 'mainmark';
    });
    var roleAt = Object.create(null);
    state.editor.objects.forEach(function (o) {
      if (o.type === 'text' && o.role && o.source === 'shozaizu') {
        if (o.role === 'pinlabel' && !wasGenerated) return;
        roleAt[o.role + ':' + o.text] = { lat: o.at.lat, lng: o.at.lng };
      }
    });

    var frame = frameShozaizu();
    var sameFrame = !!(prevFrame && frame && prevFrame.w_m === frame.w_m
      && prevFrame.center.lat === frame.center.lat
      && prevFrame.center.lng === frame.center.lng);

    $('szRun').disabled = true;
    sgSzBusy(true);          // 🔒 §28-4: ガイダンス③の設定盤を灰色にする
    setSzResult('国土地理院のデータを取得しています…');

    /* 🔒 2026-09-03: 設定盤の6項目は**全部を案件に覚えさせる**（画面だけの状態を作らない）。
     * 作り直し・再読込のどちらでも同じ図が出る。
     * 🔴 値の出どころは案件データ（無い時だけ画面）。ここで既定へ丸めないので、
     *    既存案件の bldgLevel:1 等はそのまま保たれる（後方互換）。 */
    /* 🔒 §28-14 ①-4: 主役の印の形は設定盤から外れた（ガイダンス①・地点ごと）。
     * ここでは案件の値をそのまま持ち回るだけ（旧案件の後方互換のため生成にも渡す）。 */
    var markStyle = (c.markStyle === 'rect') ? 'rect' : 'circle';
    var roadStyle = toggleValue('road');
    var nature = toggleValue('nature');
    var lmLevel = gradeValue('lm');
    var bldgLevel = gradeValue('bldg');
    var roadLevel = gradeValue('road');
    c.roadStyle = roadStyle;
    c.nature = nature;
    // 🔴 5段階は表から一括で書き戻す（名称6分類を足した時の入れ忘れを構造で防ぐ）
    Object.keys(SZ_GRADES).forEach(function (k) {
      c[SZ_GRADES[k].key] = gradeValue(k);
    });
    // 🔒 §30-22-2 2: 段数が5でない項目（名前の位置）も同じ作法で書き戻す
    Object.keys(SZ_PICKS).forEach(function (k) {
      c[SZ_PICKS[k].key] = pickValue(k);
    });
    // 🔒 2026-09-03（後半）: 名称6分類の段（§23-5）。全部「なし」なら OSM を叩かない
    var nameLevels = nameLevelsNow();
    syncSzPanel();

    /* 🔴 §18-z: 生成は非同期なので、走っている最中にもう一度呼ばれると
     * 「2回消して2回足す」＝二重になる。後から始まった方だけを採用する。 */
    state.szRunSeq = (state.szRunSeq || 0) + 1;
    var runToken = state.szRunSeq;

    var mv = state.map;
    // 書き出す枠の範囲そのもので作る（少しだけ外側も拾って端を欠けさせない）
    var fb = frame ? Exporter.frameBounds(frame) : mv.getBounds();
    /* 🔒 §30-25-3 1（2026-09-13 オーナー指示）: **取得範囲＝画面に映っている範囲と
     * 枠の範囲の和＋8%**。地理院タイルも Overpass も同じ範囲を1回で取る。
     * 🔴 段（多め・全部）を選ぶと枠の外にも描けるようにするための「材料」。
     *    どこまで描くかは shozaizu.js の areaFor（段ごと）が決める（§30-25-3 2）。
     * 🔴 取得範囲は**画面より広げない**（Overpass の重さ・§30-25-3 5）。 */
    var vb = mv.getBounds();
    var ub = { west: Math.min(fb.west, vb.west), east: Math.max(fb.east, vb.east),
               south: Math.min(fb.south, vb.south), north: Math.max(fb.north, vb.north) };
    var padLat = (ub.north - ub.south) * 0.08;
    var padLng = (ub.east - ub.west) * 0.08;
    var genBounds = { west: ub.west - padLng, east: ub.east + padLng,
                      south: ub.south - padLat, north: ub.north + padLat };
    /* 🔒 §26-4-b: 枠が決定済みの紙は地図を動かしていないので、
     * タイルの倍率は**枠から**出す（地図のズームで取ると粗すぎ／細かすぎになる）。
     * 🔴 §22-an: 未決定の紙はいまの画面そのものが枠（frameShozaizu が地図を動かさない）
     *    なので、地図のズームをそのまま使えばよい（従来どおり）。 */
    var prevFixedSheet = sheetOf('shozaizu');
    var genZoom = (prevFixedSheet && prevFixedSheet.frameFixed && frame)
      ? zoomForFrame(frame) : mv.getZoom();
    return Shozaizu.generate({
      bounds: genBounds,
      // 🔒 §18-n-4: 文字を紙の枠内に収めるため、記載欄そのものの範囲も渡す
      frameBounds: frame ? fb : null,
      zoom: genZoom,
      home: c.points.home, lot: c.points.lot,
      /* 🔒 §30-22-1 6 / §30-22-6 2: 同一住所＝印もラベルも1つ・結線と距離は描かない */
      same: !!c.points.same,
      /* 🔒 §30-22-2 2: 名前の位置（1=近く／2=標準／3=離す）。案件に保存される */
      nameGap: pickValue('gap'),
      // 🔒 §23-10: 建物の自動描画（1=なし〜5=全部）。旧 szBldg の bool は廃止
      bldgLevel: bldgLevel,
      // 🔒 2026-09-03: 道路の量も5段階（1=なし〜5=全部）。3=標準＝従来の自動間引き
      roadLevel: roadLevel,
      nature: nature,
      /* 🔒 §18-r: 施設（目標物）の件数。段 → 件数は LM_COUNT の表で引く
       * （段5「全部」は Infinity＝上限も距離の足切りも無し）。厳選そのものは従来のまま */
      landmarks: LM_COUNT[lmLevel],
      /* 🔒 §30-25-3 2: 「描く範囲」を段で決めるため、件数だけでなく**段そのもの**も渡す
       * （4=多め・5=全部 は枠の外＝画面に映っている所まで描く）。 */
      lmLevel: lmLevel,
      // 🔒 §25-4: 主役の印の様式（'rect'＝四角＋斜線 / 'circle'＝◎）。案件に保存される
      markStyle: markStyle,
      /* 🔒 §28-14 ①-4: 主役の印の形と色は**地点ごと**（ガイダンス①で選ぶ）。
       * markStyle は旧案件の後方互換で残してある（marks が優先・shozaizu.js 側）。 */
      marks: marksForGen(),
      /* 🔒 §30-24-1: 主役の印が多角形の時、文字はその**縁**から離して置く。
       * 多角形は利用者が描いた図形（生成物ではない）のでここで渡す（描いた順）。 */
      mainPolys: ['home', 'lot'].reduce(function (acc, k) {
        return acc.concat(Editor.mainPolysOf(state.editor.objects, k)
          .map(function (o) {
            return { markRole: (o.markRole || 'home'),
                     points: o.points.map(function (p) {
                       return { lat: p.lat, lng: p.lng };
                     }) };
          }));
      }, []),
      // 🔒 §23-9: 道路の描き方（'line'＝黒線1本 / 'band'＝白帯＋黒縁）。案件に保存される
      roadStyle: roadStyle,
      /* 🔒 2026-09-03（後半・§23-5）: 名称6分類の段。
       * 🔴 全部「なし」なら shozaizu.js は OSM を**呼ばない**（通信そのものが起きない）。 */
      nameLevels: nameLevels,
      /* 🔴 同名の重複を出さないための「紙に既にある文字」（§23-6-a の先勝ち）。
       * 自動生成物（source:'shozaizu'）はこの後まるごと差し替わるので数えない。
       * 手描き・なぞり出した名称（source:'reveal'）は残るので必ず渡す。 */
      existingNames: state.editor.objects.filter(function (o) {
        return o.type === 'text' && o.text && o.source !== 'shozaizu';
      }).map(function (o) { return o.text; }),
      /* 🔒 §28-3: 部品として置かれた方位記号（type:'compass'）は、名前・路線番号の印が
       * 避ける**障害物**として渡す（旧・自動の方位記号は furnitureZones の席だった）。 */
      /* 🔒 §30-37 2: 大きさ（倍率 markScale）も渡す＝箱を記号ごとの大きさで取る */
      compasses: state.editor.objects.filter(function (o) {
        return o.type === 'compass' && o.at;
      }).map(function (o) {
        return { lat: o.at.lat, lng: o.at.lng, markScale: o.markScale };
      }),
      metersPerPixel: function (lat) { return mv.metersPerPixel(lat); }
    }).then(function (res) {
      // 追い越された生成は捨てる（§18-z の二重防止）
      if (runToken !== state.szRunSeq) return res;

      /* 🔒 §23-10: 建物が極端な件数（密集地で「全部」段等）になる時は、
       * 図形を作る前に確認する（app.js 自動下書きの「200個確認」と同じ作法・§11-b）。
       * 🙋 仮値 BLDG_CONFIRM_N=1000（実機目視で確定）。
       * キャンセルした時に既存の図が消えないよう、この確認は
       * 「前回の自動生成物を消す」より**前**に置く。 */
      /* 🔒 2026-09-03: 道路も段5「全部」で間引きが外れるので、同じ作法で確認する。
       * 🙋 仮値 ROAD_CONFIRM_N=2500（従来の自動間引きの上限 2200 の少し上）。 */
      var heavy = [];
      if (res.stats.buildings > BLDG_CONFIRM_N) {
        heavy.push('建物が ' + res.stats.buildings + ' 個');
      }
      if (res.stats.roads > ROAD_CONFIRM_N) {
        heavy.push('道路が ' + res.stats.roads + ' 本');
      }
      if (heavy.length) {
        var ok = confirm(heavy.join('・') + ' になります。\n'
          + '密集地では図が線で埋まってしまうかもしれません。\n\n'
          + '［キャンセル］して段階を下げる・範囲を狭めることもできます。\n'
          + 'このまま作りますか？');
        if (!ok) {
          setSzResult(heavy.join('・') + ' と多いため中止しました。'
            + '段階を下げるか、範囲を狭めてから実行してください。');
          return null;
        }
      }

      /* 前回の自動生成物を消してから作り直す（正典 §5 再生成）。
       * 🔒 §18-ab: ［手で足した図形を残す］は廃止したので、**常に差し替え**。
       * 🔴 手で描いた図形は source が 'shozaizu' ではないので**ここでは絶対に消えない**。
       *    （廃止したチェックの実効は「前回の自動生成を重ねる」だけで、
       *      自宅・駐車場・距離が二重三重に増える原因だった＝§18-z の実測）
       * 🔒 §23-10: 旧実装は生成の**前**に消していたが、それだと上の確認で
       *    ［キャンセル］した時に図が空になる。生成が確定してから消すよう動かした。 */
      var n = 0;
      /* 🔒 §30-25-28 4: 手で動かした／大きさを変えた主役の文字（userMoved）が
       * 残っている地点。生成物の同じ文字は捨てる（重複させない・判定は pinKey）。 */
      var keptMain = {};
      state.editor.snapshot();
      for (var i = state.editor.objects.length - 1; i >= 0; i--) {
        var od = state.editor.objects[i];
        if (od.source !== 'shozaizu') continue;
        /* 🔒 §30-24-1: 主役の**多角形**は利用者が手で描いた印（生成物ではない）。
         * 作り直しで消さない（消すと囲んだ土地の形が毎回消えてしまう）。 */
        if (od.role === 'mainmark' && od.type === 'polygon') continue;
        /* 🔒 §30-25-28 4（2026-09-14 オーナー指示）: 手で動かした主役の文字も
         * 「利用者が触った物」＝多角形と同じ扱いで消さず・置き直さず残す。 */
        if (od.role === 'pinlabel' && od.type === 'text' && od.userMoved) {
          keptMain[pinKeyOf(od)] = true;
          continue;
        }
        state.editor.objects.splice(i, 1); n++;
      }
      if (n) state.editor.commit();

      // 役割ラベルは前回の位置のまま（§18-r。件数を変えても主役の文字は動かさない）
      if (sameFrame) {
        res.objects.forEach(function (o) {
          if (o.type !== 'text' || !o.role) return;
          var at = roleAt[o.role + ':' + o.text];
          if (at) o.at = { lat: at.lat, lng: at.lng };
        });
      }
      /* 🔒 §30-25-28 4: 残した主役の文字と同じ地点の生成物は載せない
       * （判定は pinKey＝表示文字では分岐しない・§26-2 注意②）。 */
      var fresh = res.objects.filter(function (o) {
        return !(o && o.type === 'text' && o.role === 'pinlabel'
                 && keptMain[pinKeyOf(o)]);
      });
      state.editor.addGenerated(fresh);
      /* 🔒 §30-24-3: 作り直しの後は「使用の本拠」「駐車場」の文字が必ず1つずつある
       * （生成側は地点が無いと作らない＝片方が消える経路の出口）。 */
      ensureMainLabels();
      updateHistoryButtons();
      var s = res.stats;
      /* 🔒 §23-9 / 2026-09-03: 道路は「段の名前・描き方」を添える */
      var parts = ['道路 ' + s.roads + '（' + GRADE_JA[roadLevel]
                     + '・' + Shozaizu.ROAD_STYLE_JA[roadStyle] + '）',
                   '鉄道 ' + s.rails, '名称 ' + s.annoKept];
      // 🔒 §23-10: 建物は件数に段の名前を添える（なしの時は元々 s.buildings が 0）
      if (s.buildings) parts.push('建物 ' + s.buildings + '（' + GRADE_JA[bldgLevel] + '）');
      var msg = parts.join(' / ') + ' を生成しました。';
      /* 🔴 間引きの内訳。等級で切った時だけ等級名を出す（段2は半径でも落とすので、
       *    minRank が 0 のまま thinned > 0 になり得る＝旧コードは空文字を出していた）。 */
      if (s.thinned) {
        msg += '（' + (s.minRank >= 1 ? Shozaizu.RANK_JA[s.minRank] + '以上に' : '')
             + '間引き ' + s.thinned + '本）';
      } else if (s.roads && roadLevel >= GRADE_STD) {
        /* 🔴 1本も間引いていない＝**この枠の道路はもう全部描いてある**。
         * この時に段を「多め」「全部」へ上げても本数は増えないので、
         * 黙っていると「5段階が効いていない」と誤解される（§23-10-b と同じ轍）。
         * データの上限に当たっていることを言葉で伝える。 */
        msg += '（この枠の道路はすべて描いています。段を上げても増えません）';
      }
      if (s.over2km) msg += ' ⚠ 直線距離が 2km を超えています。';
      // 🔒 §18-r: 施設は近くから選んだ件数を出す（0 でも異常ではない）
      if (s.landmarks !== undefined) {
        msg += ' 施設 ' + s.landmarks + ' 件。';
        if (!s.landmarks && LM_COUNT[lmLevel] > 0) {
          msg += ' 2地点の近くに目標物がありませんでした。';
        }
      }
      if (!s.annoKept) msg += ' この地域は目標物の名称が入っていません（道路のみの図になります）。';
      /* 🔒 2026-09-03（後半）: 川・山（トグルの中身）と名称6分類の結果を添える */
      if (s.waterAreas || s.waterRivers || s.waterEdges) {
        msg += ' 川 ' + ((s.waterAreas || 0) + (s.waterRivers || 0)
                       + (s.waterEdges || 0)) + '。';
      }
      if (s.contours) {
        msg += ' 等高線 ' + s.contours + '（標高 ' + s.contourStep + 'm ごと・山名 '
             + s.peaks + ' 件の周り）。';
      }
      if (s.namesTotal) {
        msg += ' 名称の自動描画 ' + s.namesTotal + '（'
             + Object.keys(SZ_GRADES).filter(function (k) {
                 return SZ_GRADES[k].osm && s.names[SZ_GRADES[k].osm];
               }).map(function (k) {
                 return SZ_GRADES[k].ja + ' ' + s.names[SZ_GRADES[k].osm];
               }).join('・') + '）。';
      }
      /* 🔒 §30-40-2 5: 「自動」を選んだ分類が、どの段に決まったかを添える
       * （例「自動: 交差点名・バス停＝全部／お店・道路名＝標準」）。
       * 🔴 判定は stat の段の数字（s.nameAuto）。表示文字では分岐しない（注意②）。
       * 🔴 分類名は SZ_GRADES[].ja・段の名前は GRADE_JA＝どちらも1か所から引く。 */
      if (s.nameAuto) {
        var byLv = Object.create(null);           // 段 → その段に決まった分類名
        Object.keys(SZ_GRADES).forEach(function (k) {
          var g = SZ_GRADES[k];
          if (!g.osm || s.nameAuto[g.osm] === undefined) return;
          var lvA = s.nameAuto[g.osm];
          (byLv[lvA] = byLv[lvA] || []).push(g.ja);
        });
        // 上の段（＝たくさん出た分類）から並べる
        var lvKeys = Object.keys(byLv).sort(function (a, b) { return Number(b) - Number(a); });
        if (lvKeys.length) {
          msg += ' 自動: ' + lvKeys.map(function (lvk) {
            return byLv[lvk].join('・') + '＝' + GRADE_JA[Number(lvk)];
          }).join('／') + '。';
        }
      }
      /* 🔴 fail-soft（§23-6）: OSM が取れなくても作図は止めない。
       * 黙って名称が消えると「効いていない」と誤解されるので必ず言葉にする。
       * 🔒 §22-as: 通信失敗（osmError・'wide' 以外）と「データが無い」（mainNoName）は
       *    混ぜない。'wide'（範囲が広すぎる）は従来どおりの文言のまま。 */
      if (s.osmError === 'wide') {
        msg += ' ⚠ 範囲が広すぎて名称（交差点名・お店・会社・バス停・道路名）は取りに行けません。';
      } else {
        msg += szNameWarningText(s);
      }
      setSzResult(msg);
      noteDraftAttribution(false);
      /* 🔒 §23-6（ODbL）: OSM 由来の名称を**実際に紙へ出した時だけ**出典を足す */
      if (s.namesTotal) noteOsmAttribution(sheetOf('shozaizu'));
      if (!silent) {
        var szHint = parts.join(' / ') + ' で所在図を作りました' + szNameWarningText(s);
        hint(szHint, szNameWarningText(s) ? 7000 : 4500);
      }
      return res;
    }).catch(function (e) {
      setSzResult('生成に失敗しました: ' + (e.message || e));
      return null;
    }).then(function (r) {
      $('szRun').disabled = false;
      sgSzBusy(false);       // 🔒 §28-4: 描き直しが終わったら設定盤を戻す
      return r;
    });
  }

  /* ---------- 一発生成（所在図＋配置図の下書きをまとめて） ---------- */

  function runAutoAll() {
    var c = state.current;
    if (!c) return;
    if (!c.points.lot) {
      // 🔒 §30-39-4 4: 促し方を新しい作法（住所を検索すると◎が置かれる）に合わせる
      hint('先に駐車場のマーカーを置いてください（左の「駐車場住所」の欄に住所を入れて［検索］）', 4000);
      return;
    }
    $('btnAuto').disabled = true;
    var log = [];
    function say(s) { $('autoStatus').textContent = s; }

    say('所在図を作成中…');
    runShozaizu(true).then(function (r) {
      if (r) log.push('所在図: 道路' + r.stats.roads + '・名称' + r.stats.annoKept);

      // --- 配置図 ---
      say('配置図の下書きを取得中…');
      switchKind('haichizu');
      state.map.setView(c.points.lot, Math.max(20, state.map.getZoom()));
      return new Promise(function (res) { setTimeout(res, 600); });
    }).then(function () {
      // 一発生成では駐車場の地点が分かっているので、画面ではなく
      // その点を中心にした一定範囲で探す（画面が狭いと筆界を取り逃す）
      var wide = radiusBounds(c.points.lot, 160);
      return Promise.all([
        AutoDraft.fetchGsiShapes(state.map.getBounds(), { roads: true, buildings: false }),
        AutoDraft.fetchParcels(wide)
      ]);
    }).then(function (r) {
      var shapes = r[0], parcels = r[1], objs = [];
      state.roadWidths = shapes.widths || [];
      shapes.roads.forEach(function (pts) {
        objs.push(AutoDraft.toPath(pts, { w: 1.6, color: '#444' }));
      });
      // 探すのは広く、描くのは駐車場の周りだけ（遠くの筆まで描くと図が埋まる）
      var lot = c.points.lot;
      var near = radiusBounds(lot, 70);
      var drawn = 0;
      parcels.forEach(function (p) {
        var ctr = AutoDraft.centroid(p.points);
        if (ctr.lng < near.west || ctr.lng > near.east ||
            ctr.lat < near.south || ctr.lat > near.north) return;
        var o = AutoDraft.toPolygon(p.points, { w: 1.2, color: '#555' });
        o.chiban = p.chiban;
        objs.push(o);
        drawn++;
      });
      state.editor.addGenerated(objs);
      log.push('配置図: 道路縁' + shapes.roads.length + '・筆界' + drawn);

      // --- 駐車場の敷地を推定して枠を並べる ---
      say('駐車枠を配置中…');
      var usable = parcels.filter(function (p) {
        var a = AutoDraft.areaM2(p.points);
        return a >= 20 && a <= 20000;
      });
      var hit = null;
      // まず地点を含む筆（入れ子なら小さい方）
      usable.forEach(function (p) {
        if (!AutoDraft.pointInPolygon(lot, p.points)) return;
        var a = AutoDraft.areaM2(p.points);
        if (!hit || a < hit.a) hit = { p: p, a: a };
      });
      // 含む筆が無ければ、住所検索の誤差を見込んで一番近い筆を採る
      if (!hit) {
        var bd = Infinity;
        usable.forEach(function (p) {
          var d = GSI.distanceMeters(lot, AutoDraft.centroid(p.points));
          if (d < bd && d <= 40) { bd = d; hit = { p: p, a: AutoDraft.areaM2(p.points) }; }
        });
        if (hit) log.push('（地点を含む筆が無いため約' + Math.round(bd) + 'm隣の筆を採用）');
      }
      if (!hit) {
        log.push('敷地: 駐車場地点の筆界が見つからず（枠は手動で）');
        return finishAuto(log, false);
      }
      var poly = AutoDraft.toPolygon(hit.p.points, { w: 2.4, color: '#111' });
      poly.source = 'parcel';
      poly.chiban = hit.p.chiban;
      state.editor.addGenerated([poly]);

      var roads = state.editor.objects.filter(function (o) {
        return o.type === 'path' && o.source === 'auto';
      }).map(function (o) { return o.points; });

      var res = Layout.fillParking(hit.p.points, roads, {
        cell_w_m: 2.5, cell_h_m: 5.0, aisle_m: 5.0, margin_m: 0.3
      });
      if (res && res.count) {
        state.editor.addFilledCells(res.cells,
          { cell_w_m: res.cell_w_m, cell_h_m: res.cell_h_m, number: true });
        log.push('敷地: ' + Math.round(hit.a) + 'm²'
          + (hit.p.chiban ? '（地番' + hit.p.chiban + '）' : '')
          + ' に ' + res.count + '枠');
      } else {
        log.push('敷地: ' + Math.round(hit.a) + 'm² は取り込んだが枠が入らず');
      }

      var extras = [];
      var meas = Layout.measureFrontRoadWidth(hit.p.points, roads, 60);
      if (meas) {
        extras.push({ id: 'w' + Date.now().toString(36), type: 'arrow',
          a: meas.from, b: meas.to, label: null,
          style: { w: 2, color: '#111' }, source: 'fill' });
        log.push('前面道路 約' + meas.width_m.toFixed(1) + 'm を実測（要確認）');
      }
      var ent = Layout.guessEntrance(hit.p.points, roads, 4);
      if (ent) {
        extras.push({ id: 'e' + Date.now().toString(36), type: 'text',
          at: ent.at, text: '出入口', size: 'medium',
          h_m: Editor.TEXT_PX.medium * state.map.metersPerPixel(ent.at.lat),
          style: { color: '#111' }, source: 'fill' });
      }
      if (extras.length) state.editor.addGenerated(extras);
      noteDraftAttribution(parcels.length > 0);
      return finishAuto(log, true);
    }).catch(function (e) {
      say('');
      hint('一発生成に失敗しました: ' + (e.message || e), 6000);
    }).then(function () {
      $('btnAuto').disabled = false;
      updateHistoryButtons();
    });
  }

  /** ある地点を中心に半径 m の範囲 */
  function radiusBounds(p, m) {
    var dLat = m / 110540;
    var dLng = m / (111320 * Math.cos(p.lat * Math.PI / 180));
    return { west: p.lng - dLng, east: p.lng + dLng,
             south: p.lat - dLat, north: p.lat + dLat };
  }

  function finishAuto(log, ok) {
    $('autoStatus').textContent = ok ? '生成しました' : '一部は手動で';
    setTimeout(function () { $('autoStatus').textContent = ''; }, 6000);
    hint(log.join(' ／ '), 9000);
    Store.flush();
  }

  /* ---------- 駐車枠の自動敷き詰め（正典 §9 Step 3.5 / §15-a） ---------- */

  function buildFillPresets() {
    var sel = $('fillPreset');
    sel.innerHTML = '';
    Object.keys(StampPanel.PRESETS).forEach(function (k) {
      var p = StampPanel.PRESETS[k];
      var o = document.createElement('option');
      o.value = k;
      o.textContent = p.w ? (p.label + '  ' + p.w + '×' + p.h + 'm') : p.label;
      sel.appendChild(o);
    });
    sel.value = 'normal';
    /* 🔴 1枠の幅・奥行だけは実値を入れる。ここは**プリセット選択の現在値を映す欄**
     * （fillPreset を変えると書き換わる）なので、空欄だと選択と食い違って見える。 */
    $('fillW').value = 2.5;
    $('fillH').value = 5.0;
    /* 🔒 修正4（オーナー指示 2026-08-30）: 車路幅・余白は「素の既定値が
     * 打ち込んであるだけ」の欄。実テキストを入れず**影文字（placeholder）**に任せる。
     * 空欄のまま実行しても runFill の num('fillAisle', 5.0) / num('fillMargin', 0.3)
     * が従来と同じ既定値を使うので、動きは一切変わらない。 */
  }

  /** 敷き詰めの対象になる多角形（選択中のもの、無ければ取り込んだ敷地）
   * 🔒 §22-ac: **開いた線（path）も敷地として扱う**（オーナー決定）。
   * 🔴 Enter の既定が「閉じずに確定」に変わり、手で描いた輪郭は path になったため。
   *    面として使う時だけ内部で閉じて扱う（最後の点と最初の点を結ぶ）ので、
   *    見た目は開いたまま・敷き詰めは従来どおり効く。 */
  function isFillArea(o) {
    return (o.type === 'polygon' || o.type === 'path')
      && o.points && o.points.length >= 3;
  }
  function fillTargetPolygon() {
    if (!state.editor) return null;
    var sel = state.editor.getSelected().filter(isFillArea);
    if (sel.length) return sel[0];
    var parcels = state.editor.objects.filter(function (o) {
      return o.type === 'polygon' && o.source === 'parcel';
    });
    if (parcels.length) return parcels[parcels.length - 1];
    // 写真から配置図の流れでは、手で描いた外周がそのまま敷地になる（正典 §16-2②）。
    // 選択が外れていても最後に描いた多角形を拾う（自動生成の建物は除く）
    var drawn = state.editor.objects.filter(function (o) {
      // 🔒 §22-ag: ⑦で引いた道路（source:'road'）は敷地ではないので拾わない
      // 🔒 §23: なぞり出した線（source:'reveal'）も敷地ではない（建物の輪郭など）
      return isFillArea(o) && o.source !== 'auto' && o.source !== 'shozaizu'
        && o.source !== 'road' && o.source !== 'reveal';
    });
    if (drawn.length) return drawn[drawn.length - 1];
    return null;
  }

  function syncFillTarget() {
    var poly = fillTargetPolygon();
    if (!poly) {
      $('fillTarget').textContent =
        '敷地の外枠がありません。［敷地］で取り込むか、［多角形］で囲んでから実行してください。';
      $('fillRun').disabled = true;
      return;
    }
    var a = Math.round(AutoDraft.areaM2(poly.points));
    $('fillTarget').textContent = '対象の敷地: 約 ' + a.toLocaleString() + ' m²'
      + (poly.source === 'parcel' ? '（取り込んだ筆界）' : '（描いた外枠）');
    $('fillRun').disabled = false;
  }

  /* ---- 列の向きを敷地の辺で指定する（正典 §16-5 C） ----
   * 押してから敷地の辺をクリックすると、その辺の方位で枠を並べる。
   * 同じ辺をもう一度クリックすると +90°（辺に直角）に切り替わる。 */

  /** 向きの案内は右パネルとガイダンス⑦［詳しい設定］の両方に出す（どちらからでも使える） */
  function setDirNote(text) {
    $('fillDirNote').textContent = text;
    $('sgFillDirNote').textContent = text;
  }

  function startEdgePick() {
    var poly = fillTargetPolygon();
    if (!poly) {
      setDirNote('先に敷地の外枠を選んでください。');
      return;
    }
    if (state.edgePick) return;
    state.edgePick = true;
    setDirNote('地図で敷地の辺をクリックしてください（同じ辺をもう一度で +90°）');
    $('map').style.cursor = 'crosshair';
    // 地図・描画エンジンより先に受け取るため、親要素の capture で拾う
    document.querySelector('.map-wrap')
      .addEventListener('pointerdown', onEdgePick, true);
  }

  /** 辺の選び直しを終える（選んだ向きは残す）。
   *  🔴 掴んだままにすると地図クリックを全部横取りしてしまうので、
   *     並べた直後・パネルを閉じた時・Esc で必ず外す。 */
  function stopEdgePick() {
    if (!state.edgePick) return;
    state.edgePick = false;
    $('map').style.cursor = '';
    document.querySelector('.map-wrap')
      .removeEventListener('pointerdown', onEdgePick, true);
    if (state.edgeSel) {
      setDirNote('辺の向き '
        + Math.round(((state.edgeSel.deg % 180) + 180) % 180) + '° で並べます'
        + '（選び直すには［辺に沿わせる］をもう一度押してください）');
    }
  }

  function onEdgePick(e) {
    if (!state.edgePick || !state.map) return;
    var r = $('map').getBoundingClientRect();
    var px = e.clientX - r.left, py = e.clientY - r.top;
    if (px < 0 || py < 0 || px > r.width || py > r.height) return;   // パネル上は無視
    e.preventDefault();
    e.stopPropagation();
    var poly = fillTargetPolygon();
    if (!poly) return;
    var hit = nearestEdge(poly, px, py);
    if (!hit) return;
    var key = poly.id + ':' + hit.index;
    var deg = Math.atan2(hit.b.y - hit.a.y, hit.b.x - hit.a.x) * 180 / Math.PI;
    // 同じ辺を続けて押したら直角に振る
    var quarter = (state.edgeSel && state.edgeSel.key === key)
      ? (state.edgeSel.quarter + 1) % 2 : 0;
    deg = deg + quarter * 90;
    state.edgeSel = { key: key, quarter: quarter, deg: deg };
    setDirNote('辺の向き ' + Math.round(((deg % 180) + 180) % 180)
      + '° で並べます（同じ辺をもう一度クリックで +90°／Esc でやめる）');
    hint('列の向きを ' + Math.round(((deg % 180) + 180) % 180) + '° にしました', 2500);
  }

  /** 多角形のうち、画面座標に一番近い辺 */
  function nearestEdge(poly, px, py) {
    var pts = poly.points.map(function (p) {
      return state.map.project(p.lat, p.lng);
    });
    var best = null;
    for (var i = 0; i < pts.length; i++) {
      var a = pts[i], b = pts[(i + 1) % pts.length];
      var vx = b.x - a.x, vy = b.y - a.y;
      var L = vx * vx + vy * vy;
      var t = L ? ((px - a.x) * vx + (py - a.y) * vy) / L : 0;
      t = Math.max(0, Math.min(1, t));
      var d = Math.hypot(px - (a.x + t * vx), py - (a.y + t * vy));
      if (!best || d < best.d) best = { d: d, index: i, a: a, b: b };
    }
    return best;
  }

  /** 枠を並べる向き（度）。自動なら undefined */
  function fillAngleDeg() {
    var mode = (document.querySelector('input[name="fillDir"]:checked') || {}).value;
    if (mode === 'edge') return state.edgeSel ? state.edgeSel.deg : undefined;
    if (mode === 'manual') {
      /* 🔒 修正4: 角度欄は影文字（placeholder）にしたので**空欄＝0°**として扱う。
       * 従来この欄には value="0" が実テキストで入っていたので、
       * 触らずに実行した時の結果は今までと同じ（0°）になる。 */
      var v = parseFloat($('fillAngle').value);
      return isNaN(v) ? 0 : v;
    }
    return undefined;
  }

  /* ---------- 画像認識で枠を描く（正典 §16-10・主方式） ----------
   * 幾何配置（§16-4 runFill）は**フォールバック**として残す。
   * 🔴 認識は完全ローカル。かけてよいのは本人・お客様の権利がある画像だけ。 */

  /** 権利の確認（案件ごとに1回）。いいえ＝幾何配置に回す */
  function ensureImageConsent() {
    var c = state.current;
    if (!c) return false;
    if (c.imageConsent) return true;
    var ok = confirm('この画像はご自身・お客様が撮影した、権利上問題のないものですか？\n\n'
      + '［OK］ 画像を解析して白線から駐車枠を描きます（解析はこのパソコンの中だけで行います）\n'
      + '［キャンセル］ 解析はせず、外周と台数から均等割りで描きます\n\n'
      + '※ Google マップ等の画面コピーには解析をかけないでください。');
    if (ok) { c.imageConsent = true; Store.autosave(c); }
    return ok;
  }

  /** 認識が使える状態か（画像があって外周がある） */
  function canRecognize() {
    return !!(state.imglay && state.imglay.hasImage() && state.imglay.img
              && fillTargetPolygon());
  }

  function fillBusy(on) {
    $('fillRun').disabled = !!on;
    // 🔒 §29-1 ⑦: ガイダンス⑦の［写真から枠を描く］も同じ間だけ固める
    var b = $('sgFillRun');
    if (b) b.disabled = !!on;
  }

  /* ---------- 解析を「いまの画面の1回」に結びつける（🔴 §16-13 重大バグ対策） ----------
   * 認識には数秒かかる。その間に［案件一覧］へ戻る・別の案件を開く・タブを替えると、
   * 完了時のダイアログが**案件一覧の上に出て画面全体が操作不能**になった（オーナー実機報告）。
   * 実行のたびに「案件id・シート・画面の世代」を控え、続きを実行する前に必ず照合する。
   * 🔴 この情報は**メモリだけ**。保存しないので、開き直しに引きずられない。 */

  function fillContext() {
    return { caseId: state.current ? state.current.id : null,
             kind: state.kind, gen: state.viewGen || 0 };
  }

  /** その実行がまだ有効か（同じ案件・同じ図・編集画面が出ている）。
   *  シート（紙）を移った時は invalidateFillRuns が gen を進めるので、それで弾かれる */
  function fillAlive(ctx) {
    return !!(ctx && state.current && ctx.caseId === state.current.id
              && ctx.kind === state.kind && ctx.gen === (state.viewGen || 0)
              && !$('editorView').hidden);
  }

  /** 画面が変わった＝走っている解析の結果は捨てる */
  function invalidateFillRuns() {
    state.viewGen = (state.viewGen || 0) + 1;
    state.fillAuto = null;
    fillBusy(false);
  }

  /** 🔒 §30-25-26: 案件を開く／新しく作る／一覧へ戻る のどれでも閉じる窓の一覧。
   * 上部バー・道具メニューから hidden で出し入れしている窓（index.html で
   * class="stamp-panel" が付いている物を全部・書き出し窓・
   * はじめに・プレビュー）を集めた1か所。
   * 🔴 新しい窓を足す時はまずここに id を足す（closeAllOverlays 側は直さない）。
   * welcomeBox（はじめに）も一度ここで閉じる。openCaseInner が最後にまた開き直す
   * （opt.fresh の時だけ・§30-20 の作法のまま）。 */
  /* 🔒 §30-31-3 1: 旧 'chkBox'（提出前チェック）はこの一覧からも消した（窓ごと廃止）。 */
  var CASE_PANELS = ['welcomeBox', 'exPreviewBox',
    'exPick',                       // 🔒 §30-27-2: PDF・画像の窓
    'stampPanel', 'plPanel', 'draftPanel', 'fillPanel', 'imgPanel', 'szPanel',
    'pastePanel',
    'textPick',        // 🔒 §30-29-1 2: 文字の選択窓
    'arrowPick'];      // 🔒 §30-29-4 1: 幅の矢印の窓

  /** かぶせ物を全部閉じる（案件を開く／新しく作る／一覧へ戻る 共通の安全網） */
  function closeAllOverlays() {
    // 🔒 §22-ah: 動画は pause も要るので専用の閉じ方を通す（他より先に）
    vidClose();
    // 🔒 §22-ab: 駐車位置ラベルの小ウィンドウも畳む（2クリック待ちも解除する）
    // 🔒 §22-ao-①: 所在図の設定盤（szPanel）も案件をまたいで持ち越さない
    // 🔒 §30-20: 「はじめに」も安全網に入れる（出すのは openCaseInner の最後）
    // 🔒 §30-25-26: 閉じる窓の一覧は CASE_PANELS の1か所
    CASE_PANELS.forEach(function (id) {
      var el = $(id);
      if (el) el.hidden = true;
    });
    textPickClose();     // 🔒 §30-29-1 2: 文字の選択窓も案件をまたいで持ち越さない
    arrowPickClose();    // 🔒 §30-29-4 1: 幅の矢印の窓も同じ（打ちかけの値も戻す）
    plDisarm();
    /* 🔒 §30-25-26: fillPanel／imgPanel は隠すだけでは足りない。
     * 「辺に沿わせる」の2クリック待ち（.map-wrap の pointerdown 乗っ取り）と
     * 画像のつまみ表示（ImgLay.adjust）は窓の hidden とは別の状態なので、
     * ここで一緒に解除しないと、次の案件の地図クリックを乗っ取ったままになる。 */
    stopEdgePick();
    if (state.imglay) state.imglay.setAdjust(false);
    // ガイダンスから出したプレビューの置き方も戻す（§18-f）
    $('exPreviewBox').classList.remove('is-nav');
    sideFront(false);
    state.navPreview = false;
    // 🔒 §30-31-3 1: state.pendingExport（提出前チェックの待ち）は廃止した
    state.exPager = null;        // 🔒 §30-27-1: 面の控えは案件をまたいで持ち越さない
    state.exPick = null;         // 🔒 §30-27-2: 窓の選択も同じ
  }

  /** いまの画像の置き方（認識へ渡す） */
  function imgPlacement() {
    var m = state.imglay.getMeta();
    return { center: m.center, w_m: m.w_m, angle: m.angle, ratio: state.imglay.ratio };
  }

  /**
   * 認識する（R2・正典 §16-10-j）。
   * 🔴 検出器の内部は**ピクセルだけ**でメートルを持たないので、
   *   取り込み倍率が何倍でも同じ結果になる。v4〜v6 の「ものさしを何通りも試す」
   *   仕掛けは不要になったので撤去した（あれが縮尺補正とゴミ解の温床だった）。
   * 🔴 画像にも外周にも触れない（§16-10-f の画像不可侵は継続）。
   */
  function recognizeSmart(poly, target) {
    return Recognize.detect({
      image: state.imglay.img, placement: imgPlacement(),
      polygonLL: poly.points, targetCount: target, angleHintDeg: fillAngleDeg(),
      onProgress: function (p) {
        setFillNote('画像を解析しています… ' + Math.round(p * 100) + '%');
      }
    }).then(function (res) { return { res: res, tried: [] }; });
  }

  /**
   * 主方式: 画像の白線・停まっている車を読み取って枠を描く。
   * 🔒 v4（§16-10-d-2）: **無言のフォールバックを作らない**。
   *   認識を実行しない／できない経路では必ず理由を出す。
   */
  function runFillSmart(after, ctx) {
    // 🔴 この実行が「いまの画面・いまの案件」の物かを最後まで確かめ続ける（§16-13）
    ctx = ctx || fillContext();
    var done = function () { if (after) after(); };
    var poly = fillTargetPolygon();
    if (!poly) {
      syncFillTarget();
      setFillNote('敷地の外周が見つかりません。'
        + '［多角形］で駐車場の外周を囲んで Enter で確定してから実行してください。');
      done(); return;
    }
    /* 画像の読み込み中は、終わってから自動で実行する（§16-10-d-2）。
     * 🔴 この「待って自動実行」は**いま押した1回だけ**の約束（メモリ内・保存しない）。
     *    画面を離れた・別の案件を開いた・ウィザードを閉じた時点で破棄する（§16-13）。 */
    if (state.imgLoading) {
      setFillNote('画像を読み込んでいます。読み込みが終わり次第、自動で解析します…');
      state.fillAuto = ctx;
      Promise.resolve(state.imgLoad).then(function () {
        if (state.fillAuto !== ctx || !fillAlive(ctx)) return;   // 画面を離れた＝やらない
        state.fillAuto = null;
        setTimeout(function () {
          if (fillAlive(ctx)) runFillSmart(after, ctx);
        }, 0);
      });
      return;
    }
    if (!$('fillRecognize').checked) {
      runFill();
      setFillNote($('fillResult').textContent
        + '（［画像の白線を読み取って描く］が外れているので、'
        + '外周と台数から均等割りで描きました）');
      done(); return;
    }
    var il = state.imglay;
    if (!il || !il.hasImage()) {
      runFill();
      setFillNote($('fillResult').textContent
        + (il && il.missing
            ? '（この案件の画像はこのパソコンにありません。同じ画像を取り込み直すと読み取れます）'
            : '（取り込んだ画像がないので、外周と台数から均等割りで描きました）'));
      done(); return;
    }
    if (!ensureImageConsent()) {
      runFill();
      setFillNote('権利の確認がとれないため、画像は解析せず均等割りで描きました。');
      done(); return;
    }

    var cnt = parseInt(String($('fillCount').value).trim(), 10);
    var target = (!isNaN(cnt) && cnt > 0) ? cnt : null;
    setFillNote('画像を解析しています…');
    fillBusy(true);

    recognizeSmart(poly, target).then(function (a) {
      fillBusy(false);
      // 🔴 解析中に画面を離れていたら**何も描かず・何も出さない**（§16-13）
      if (!fillAlive(ctx)) { done(); return; }
      var res = a.res;
      if (!res || !res.ok || !res.cells.length) {
        // 白線も車も読めない（砂利・ロープの月極など）→ 幾何配置へ（理由つき＋診断）
        runFill();
        setFillNote($('fillResult').textContent
          + '（画像からは枠を読み取れませんでした: ' + reasonJa(res && res.reason)
          + diagNote(res, a) + '。均等割りで描いています）');
        done(); return;
      }
      // 🔒 v6（§16-10-f）: 画像も外周も動かさない。読み取った位置にそのまま描くだけ
      drawRecognized(res, target, { diag: diagNote(res, a) });
      done();
    }).catch(function (e) {
      fillBusy(false);
      if (!fillAlive(ctx)) { done(); return; }   // 画面を離れていたら描かない（§16-13）
      runFill();
      setFillNote('解析に失敗したため均等割りで描きました（' + (e.message || e) + '）');
      done();
    });
  }

  /* ---------- 認識結果を図形にする（v6・正典 §16-10-f「画像不可侵」） ----------
   * 🔴 **画像にも外周にも触らない**。読み取った位置・大きさのまま四角を置くだけ。
   *   v4 の縮尺自動較正（画像 w_m の書き換え）と3択ダイアログは廃止した。
   *   オーナー実機で「勝手に拡大された」上に、弱い検出（車由来の2枠）の周期で
   *   画像を 2.31 倍にして幾何を壊し、検出ゼロ同然になっていた（§16-15 に機序）。
   *   このアプリは元々「寸法は実測を手入力・図は大まかでよい」（§0 / §4-3）。 */

  function drawRecognized(res, target, opt) {
    opt = opt || {};
    state.editor.addFilledCells(res.cells, {
      cell_w_m: res.pitch_m || 2.5,
      cell_h_m: res.depth_m || 5.0,
      number: $('fillNumber').checked
    });

    // 認識の根拠を見せる（白線=緑・車両=橙。§16-10-b-6 / §16-10-c-5 / v4=消さない）
    showRecogLines(res.segments, true, res.vehicles);

    var rec = Recognize.reconcile(res, target);
    var byGroup = (res.groups || []).map(function (g) {
      return g.lines + '本/' + g.cells + '枠(' + Math.round(g.angleDeg) + '°)';
    }).join('、');
    var msg = rec.note
      + '（検出した白線 ' + res.lineCount + '本'
      + ((res.groups || []).length > 1 ? '・' + res.groups.length + 'グループ' : '')
      + '：' + byGroup + ' ／ 枠の間隔 ' + res.pitch_m.toFixed(2)
      + '・奥行 ' + res.depth_m.toFixed(1) + '（図の上の長さ））';
    if (res.vehicleCells) {
      msg += '車両らしき根拠で描いた枠が ' + res.vehicleCells + ' 個あります'
        + (res.largeCells ? '（うち大型 ' + res.largeCells + ' 個）' : '')
        + '。停まっている物が車でなければ消しゴムで消してください。';
    }
    msg += '写真の大きさは変えていません。寸法は実測値を「表示」欄に入れてください。'
      + 'いらない枠は消しゴムで1枚ずつ消せます。';
    if (opt.diag) msg += ' ' + opt.diag;          // 診断行は毎回出す（§16-10-g-5）
    setFillNote(msg);
    hint(rec.note, 6000);
    updateHistoryButtons();
    stopEdgePick();
  }

  /**
   * 診断行（正典 §16-10-g-5）。**毎回**結果メッセージの末尾に1行足す。
   * オーナーが実機で失敗した時、この文言を貼るだけでどの分岐かを特定できる
   * （画像は端末の外に出ない。出るのは角度・長さ・候補の数値だけ）。
   */
  function diagNote(res, a) {
    var d = res && res.diag;
    var t = (a && a.tried) || [];
    var s2 = [];
    if (d && d.adopted && d.adopted.length) {
      s2.push('採用角度 ' + d.adopted.map(function (x) {
        return x.deg + '°(辺と' + x.gap + '°/線分' + x.segMed + ')';
      }).join('、'));
    } else if (d && d.quality) {
      s2.push('主グループ ' + d.quality.angle + '°(辺と' + d.quality.edgeGap
        + '°)・線分長中央値 ' + d.quality.segMed + '・本数 ' + d.quality.lines);
    }
    if (d && d.anchors) s2.push('外周の向き ' + d.anchors.join('/') + '°');
    if (d && d.top && d.top.length) {
      s2.push('候補 ' + d.top.map(function (x) { return x[0] + '°:' + x[1]; }).join('、'));
    }
    if (d) s2.push('探索' + d.rounds + 'ラウンド');
    if (t.length > 1) {
      s2.push('ものさし ' + t.map(function (x) {
        return x.unit.toFixed(2) + '→' + x.cells + '枠';
      }).join('、'));
    }
    return s2.length ? ('［診断］' + s2.join(' ／ ')) : '';
  }

  /* ---------- 認識に使った線の可視化（正典 §16-10-b-6 / v4=§16-10-d-3） ----------
   * 「なぜここに枠が出たのか」を利用者が確かめられるようにする。
   * 🔒 v4: **消灯しない**。実行後は出しっぱなしにし、
   *   ウィザード［完了］／道具の切り替え／次の実行 まで表示を続ける
   *   （数秒で消える方式は「見逃すと何も出なかったように見える」と実機で判明）。 */

  function showRecogLines(segs, show, vehicles) {
    state.recogSegs = segs || [];
    state.recogVehicles = vehicles || [];
    $('fillShowLines').disabled = !(state.recogSegs.length || state.recogVehicles.length);
    if (show) {
      $('fillShowLines').checked = true;
      state.showRecog = true;
      // どの道具の時に描いたかを覚えておく（道具を変えたら消す）
      state.recogTool = state.editor ? state.editor.tool : null;
    }
    renderRecogLines();
  }

  /** ハイライトを消す（ウィザード完了・道具変更・画像を外した時） */
  function clearRecogLines() {
    state.recogSegs = [];
    state.recogVehicles = [];
    state.recogTool = null;
    state.showRecog = false;
    $('fillShowLines').checked = false;
    $('fillShowLines').disabled = true;
    renderRecogLines();
  }


  function renderRecogLines() {
    if (!state.map) return;
    var L = state.recogLayer;
    if (!L) {
      L = state.recogLayer = document.createElementNS(SVGNS, 'g');
      L.setAttribute('class', 'recog-layer');
      state.map.overlay.appendChild(L);
    }
    while (L.firstChild) L.removeChild(L.firstChild);
    if (!state.showRecog) return;
    // 車両在駐を根拠に描いた枠（橙の点線）
    (state.recogVehicles || []).forEach(function (v) {
      var c = state.map.project(v.center.lat, v.center.lng);
      var mpp = state.map.metersPerPixel(v.center.lat);
      var hw = v.w_m / mpp / 2, hh = v.h_m / mpp / 2;
      var ca = Math.cos(v.angleDeg * Math.PI / 180), sa = Math.sin(v.angleDeg * Math.PI / 180);
      var pts = [[-hw, -hh], [hw, -hh], [hw, hh], [-hw, hh]].map(function (p) {
        return (c.x + p[0] * ca - p[1] * sa).toFixed(1) + ','
             + (c.y + p[0] * sa + p[1] * ca).toFixed(1);
      }).join(' ');
      var poly = document.createElementNS(SVGNS, 'polygon');
      poly.setAttribute('points', pts);
      poly.setAttribute('class', 'recog-veh');
      L.appendChild(poly);
    });
    if (!state.recogSegs || !state.recogSegs.length) return;
    state.recogSegs.forEach(function (s) {
      var a = state.map.project(s.a.lat, s.a.lng);
      var b = state.map.project(s.b.lat, s.b.lng);
      var el = document.createElementNS(SVGNS, 'line');
      el.setAttribute('x1', a.x.toFixed(1)); el.setAttribute('y1', a.y.toFixed(1));
      el.setAttribute('x2', b.x.toFixed(1)); el.setAttribute('y2', b.y.toFixed(1));
      el.setAttribute('class', 'recog-line');   // 白線根拠＝緑（CSS）
      L.appendChild(el);
    });
  }

  function reasonJa(r) {
    if (r === 'low-quality') {
      return '白線の手応えが弱く、傾いた枠を並べる恐れがあるので描きませんでした';
    }
    if (r === 'no-image-in-polygon') return '外周の中に画像がありません';
    if (r === 'no-painted-lines') return '塗装された白線が見つかりません';
    if (r === 'no-periodic-signal') return '等間隔の線が見つかりません';
    if (r === 'no-pitch' || r === 'no-lines') return '白線らしい列が見つかりません';
    if (r === 'weak-signal') return '線の写りが弱く判別できません';
    if (r === 'no-continuous-line') return '続いた白線が見つかりません';
    if (r === 'no-cells') return '枠にできる間隔がありません';
    return r || '検出できず';
  }

  /** 結果の案内は右パネルとガイダンス⑦の両方に出す */
  function setFillNote(text) {
    $('fillResult').textContent = text;
    /* 🔒 §29-1 ⑦: 左面のガイダンス⑦（駐車枠）にも同じ結果を出す。
     * 🔴 文言は1つ（ここが唯一の出どころ）。器が増えても言う事は同じ。 */
    var el = $('sgFillNote');
    if (el) { el.textContent = text; el.hidden = !text; }
  }

  function runFill() {
    var poly = fillTargetPolygon();
    if (!poly) { syncFillTarget(); return; }
    var num = function (id, d) {
      var v = parseFloat($(id).value);
      return isNaN(v) ? d : v;
    };
    var cnt = parseInt(String($('fillCount').value).trim(), 10);
    var opts = {
      cell_w_m: num('fillW', 2.5), cell_h_m: num('fillH', 5.0),
      aisle_m: num('fillAisle', 5.0), margin_m: num('fillMargin', 0.3),
      // 空欄なら従来どおり敷地いっぱいに並べる（後方互換・正典 §16-4）
      targetCount: (!isNaN(cnt) && cnt > 0) ? cnt : undefined,
      angle: fillAngleDeg()
    };

    // 前面道路は自動下書きで作った道路縁を使う（無ければ向きは敷地の形から決まる）
    var roads = state.editor.objects.filter(function (o) {
      return o.type === 'path' && o.source === 'auto';
    }).map(function (o) { return o.points; });

    var res = Layout.fillParking(poly.points, roads, opts);
    if (!res || !res.count) {
      setFillNote('この敷地には枠が入りませんでした。'
        + '枠サイズや車路幅を小さくしてお試しください。');
      return;
    }

    state.editor.addFilledCells(res.cells, {
      cell_w_m: res.cell_w_m, cell_h_m: res.cell_h_m,
      number: $('fillNumber').checked
    });

    var extras = [];
    // 出入口を推定して矢印＋文字で置く
    if ($('fillEntrance').checked) {
      var ent = Layout.guessEntrance(poly.points, roads, 4);
      if (ent) {
        var mpp = state.map.metersPerPixel(ent.at.lat);
        extras.push({
          id: 'e' + Date.now().toString(36), type: 'text', at: ent.at,
          text: '出入口', size: 'medium',
          h_m: Editor.TEXT_PX.medium * mpp,
          style: { color: '#111' }, source: 'fill'
        });
      }
    }
    // 前面道路の幅員。属性値ではなく道路縁の線から実測して矢印を置く。
    // 🔒 §25-5: ラベルは空のまま置く＝2端点から計算した距離がそのまま値として出る
    // （実測値が分かったら「表示」欄に手入力して上書きする）。
    if ($('fillWidth').checked) {
      var meas = Layout.measureFrontRoadWidth(poly.points, roads, 60);
      if (meas) {
        extras.push({
          id: 'w' + Date.now().toString(36), type: 'arrow',
          a: meas.from, b: meas.to, label: null,
          style: { w: 2, color: '#111' }, source: 'fill'
        });
      }
    }
    if (extras.length) state.editor.addGenerated(extras);

    var msg = res.count + ' 枠を並べました（'
      + res.rows + ' 列・向き ' + Math.round(res.angleDeg) + '°）。';
    if (res.narrowed) {
      msg += '台数に合わせて枠幅を ' + res.narrowed.toFixed(1) + 'm に詰めました。';
    }
    if (res.shortBy) msg += '⚠ ' + res.shortBy + '台分描画できませんでした。';
    if (res.tooFew) {
      msg += '⚠ 敷地に対して台数が少ないようです（台数・枠サイズ・外周を確認してください）。';
    }
    msg += 'いらない枠は消しゴムで1枚ずつ消せます。';
    stopEdgePick();          // 並べたら地図の操作を作図へ返す
    setFillNote(msg);
    hint(res.shortBy
      ? (res.shortBy + '台分描画できませんでした（' + res.count + '枠を配置）')
      : (res.count + ' 枠を自動で並べました'), res.shortBy ? 6000 : 4000);
    updateHistoryButtons();
  }

  /* ---------- 画像の下敷き（正典 §16-3 Step 7A） ---------- */

  function openImagePanel(open) {
    if (open === undefined) open = $('imgPanel').hidden;
    $('imgPanel').hidden = !open;
    if (state.imglay) state.imglay.setAdjust(open);
    // 右側のパネルは1つずつ（同じ場所に出るので重ねない）
    if (open) { $('fillPanel').hidden = true; stopEdgePick(); syncImagePanel(); }
  }

  function openFillPanel(open) {
    if (open === undefined) open = $('fillPanel').hidden;
    $('fillPanel').hidden = !open;
    if (open) {
      openImagePanel(false);
      $('fillPanel').hidden = false;
      syncFillTarget();
    } else { stopEdgePick(); }
  }

  function syncImagePanel() {
    var il = state.imglay;
    if (!il) return;
    var m = il.getMeta();
    $('imgCtrls').hidden = !(m && il.hasImage());
    $('imgPick').textContent = m ? '別の画像に差し替える' : '画像を取り込む';
    // 上部バーの［画像］トグルは、画像があるシートでだけ出す
    $('imgToggleWrap').hidden = !(m && il.hasImage());
    // 🔒 §22-ad: 上部バーの「画像の濃さ」も同じ条件で出す（画像が無い時は場所を取らない）
    $('imgOpacityWrap').hidden = !(m && il.hasImage());
    // 🔒 §22-af: ［画像OFF］なので「見えていない時にチェックが入る」（意味が反転）
    if (m) $('imgOff').checked = (m.visible === false);
    // 🔒 §29-1 ⑤: ガイダンス⑤の写真まわり（濃さの欄・ボタンの文言）も同じ条件で出す
    sgSyncImg();
    if (il.missing) {
      $('imgNote').textContent =
        '⚠ この案件には画像の配置が保存されていますが、画像そのものはこのパソコンにありません'
        + '（画像はこのパソコンの中にのみ保存されます）。同じ画像をもう一度取り込んでください。';
    } else if (m && m.locked) {
      $('imgNote').textContent = '固定済みです。画像は地図と一緒に動きます。'
        + '「地図OFF＋画像ON」にすると、画像だけを見ながらなぞれます。';
    } else if (m) {
      $('imgNote').textContent = '画像は画面に貼り付いています。'
        + '地図の方をドラッグ・ズームして画像の下に合わせてください。'
        + '合ったら［固定する］を押すと、以後は画像が地図に追従します。';
    } else {
      $('imgNote').textContent = '駐車場の写真・図面を地図に重ねて位置合わせします。'
        + '画像は画面に貼り付き、地図の方を動かして合わせます。';
    }
    if (!m) return;
    /* 🔒 §22-ad: 濃さの欄は3か所（上部バー・右パネル・写真ウィザード）。
     * 🔴 ここは**表示をそろえるだけ**（imglay.update を呼ぶと保存が毎回走る）。 */
    syncImgOpacityUI(Math.round((m.opacity === undefined ? 0.7 : m.opacity) * 100));
    $('imgWidth').value = (Math.round(m.w_m * 10) / 10).toFixed(1);
    $('imgAngle').value = Math.round(m.angle || 0);
    $('imgVisible').checked = m.visible !== false;
    $('imgLocked').checked = !!m.locked;
    $('imgReset').disabled = !!m.locked;      // 固定中は画面に貼り付いていない
    $('imgHint').textContent = m.locked
      ? '固定中です。位置を直すには［固定する］のチェックを外してください。'
      : '地図をドラッグして合わせます。画像の微調整は中央の＋・四隅・上のつまみ'
        + '（［選択］の道具の時だけ出ます）。';
  }

  function importImage(file) {
    if (!state.current || !state.imglay) return;
    if (!file) return;
    if (!/^image\/(jpeg|png)$/.test(file.type)) {
      hint('JPEG か PNG の画像を選んでください', 4000);
      return;
    }
    $('imgNote').textContent = '画像を読み込んでいます…';
    /* 🔒 §29-1 ⑤: ガイダンス⑤（下敷きと枠）の［写真を取り込む］は
     * 旧📷ウィザード①と**同じ結果**にする（画面いっぱいに自動配置＋地図OFF＋画像ON）。
     * 🔴 判断はここ1か所。段の番号で分岐するのはこの1行だけにする。 */
    var inWizard = navAtStep(5);
    state.imgLoading = true;
    state.imgLoad = state.imglay.importFile(file, state.current.id, state.kind)
      .then(function () {
      state.imgLoading = false;
      // ガイダンス⑤の間は左面だけで進める（右のパネルは開かない）
      if (!inWizard) openImagePanel(true);
      // 🔒 v4（§16-6 ①）: ⑤では自動配置＋地図OFF＋画像ON。位置合わせは不要
      if (inWizard) autoPlaceImage();
      /* 🔒 §30-12-4 5: 取り込んだ直後は［自分で撮った写真・図面を使う］だけを
       * 自動で開く（位置合わせの案内・濃さの欄）。開いたら下ろす。 */
      if (inWizard) state.sgMoreImgNew = true;
      syncImagePanel();
      // 🔒 §29-1 ⑤: ガイダンス⑤の濃さの欄・ボタンの文言・状態の一言も引き直す
      if (navOnSide()) sgRender();
      // 三分法の注記（正典 §11-b / §16-3）。取り込むたびに出す
      hint(inWizard
        ? '取り込みました。写真を画面いっぱいに置き、地図を消しました／'
          + 'ご自身・お客様の画像はなぞってOK・Googleマップ等の画面コピーは位置確認のみ'
        : '取り込みました。地図の方を動かして画像に合わせ、［固定する］を押してください／'
          + 'ご自身・お客様の画像はなぞってOK・Googleマップ等の画面コピーは位置確認のみ', 9000);
    }).catch(function (e) {
      state.imgLoading = false;
      $('imgNote').textContent = '取り込めませんでした: ' + (e.message || e);
    });
  }

  /* ---------- 写真から配置図（正典 §16-6） ----------
   * 🔒 §29 Step 7（2026-09-08）: **左ウィザード（#guidePanel・WZ①〜④）は全廃した**。
   *   ①取り込み → ガイダンス⑤（下敷きと枠）
   *   ②外周をなぞる → ガイダンス⑥（土地の輪郭）
   *   ③台数を入れて枠を描く → ガイダンス⑦（写真から自動で描く＋［詳しい設定］）
   *   ④仕上げ（消しゴム・番号・保管場所マーク） → ガイダンス⑦の「仕上げ」の道具
   * 道具メニューの［📷 写真から配置図］は、ガイダンスを⑤で開く入口になった。
   * 取り込んだ画像は⑤で**自動配置**（地図OFF＋画像ON・画面いっぱい・縮尺は仮）し、
   * 縮尺は⑦の描画時に「枠幅≈2.5m」を物差しに自動較正する（§16-10-d-1）。
   * 地図への位置合わせは右パネル［画像］に**任意機能**として残してある。 */

  /**
   * 取り込んだ画像を画面いっぱいに自動配置する（正典 §16-6 ①・v4）。
   * 位置＝駐車場のピン付近（画面外・未設定なら画面の中央）。**縮尺は仮**でよい
   * （③の描画時に「枠幅≈2.5m」を物差しに自動較正する＝§16-10-d-1）。
   * 地図に**固定**して置くので、拡大・移動しても写真と外周の関係がずれない。
   */
  function autoPlaceImage() {
    var il = state.imglay, c = state.current;
    if (!il || !il.hasImage() || !state.map) return false;
    var size = state.map.size();
    var at = (c && c.points && c.points.lot)
      ? { lat: c.points.lot.lat, lng: c.points.lot.lng } : state.map.getCenter();
    var p = state.map.project(at.lat, at.lng);
    // ピンが画面の外なら画面の中央へ（手が届かない所に置かない）
    if (p.x < 0 || p.y < 0 || p.x > size.w || p.y > size.h) at = state.map.getCenter();
    var mpp = state.map.metersPerPixel(at.lat);
    var w_m = Math.max(2, size.w * 0.8 * mpp);      // 画面幅の8割
    /* 🔒 v6（§16-10-f）: 縮尺は**名目**のまま。認識も書き出しも画像を実寸に
     * 合わせようとしない（図は大まかでよく、寸法は実測を手入力する＝§0/§4-3）。 */
    il.update({ center: at, w_m: w_m, angle: 0, visible: true, locked: true });
    setUnderlayOffState(true);                      // 地図OFF＋画像ON
    syncImagePanel();
    return true;
  }

  /**
   * 🔒 §30-22-3 1（2026-09-13 オーナー指示）: 下敷きの濃さ（0〜100%）を変える
   * **唯一の出入口**。上部バーのスライダー・［地図OFF］・ガイダンス④の濃さと
   * 表示切替は、どこを触ってもここを通る＝値は1つ（case の underlayOpacity）。
   */
  function setUnderlayPct(pct) {
    var p = Math.max(0, Math.min(100, Math.round(Number(pct) || 0)));
    $('opacity').value = p;
    $('opacityVal').textContent = p + '%';
    $('underlayOff').checked = (p === 0);
    applyOpacity(p / 100);
    persistSheetState();
    sgSyncUnderlay();        // 🔒 §28-5 B / §30-22-3 1: ①④⑤の〇・濃さ・切替も追従
  }

  /** いまの下敷きの濃さ（%）。値の出どころは上部バーの #opacity 1か所 */
  function underlayPct() {
    return Math.max(0, Math.min(100, Math.round(Number($('opacity').value) || 0)));
  }

  /** 上部バーの［地図OFF］を切り替える（ウィザードから自動で操作する用） */
  function setUnderlayOffState(off) {
    var box = $('underlayOff');
    if (box.checked === off) return;
    setUnderlayPct(off ? 0 : 100);
  }

  /**
   * 🔒 §30-35-1 2: 案内帯だけが出す「操作キーの文」。
   * 多角形（polygon）と主役の多角形（mainpoly）は、使い方1行（TOOL_HINT）より
   * **確定のしかた**を手元（画面の下）で見せたいので、この表の文に差し替える。
   * 🔴 表はここ1か所・読むのは updateDrawBadge だけ（左メニューの1行・ガイダンスの
   *    `.js-toolhint` は従来どおり TOOL_HINT を読む）。
   * 🔴 polygon は「必ず閉じる」（ウィザードの外周＝ polygonMustClose）かどうかで
   *    文が変わるので、値ではなく関数で持つ。
   */
  var BADGE_KEYS = {
    // 🔒 §22-ac: Enter は「閉じずに確定」が既定。閉じたい時だけ Shift+Enter
    polygon: function (ed) {
      return (ed && ed.polygonMustClose)
        ? 'クリック＝頂点／Enter＝確定（外周は必ず閉じます）／Backspace＝1点戻す'
        : 'クリック＝頂点／Enter＝確定（閉じません）／Shift+Enter＝閉じて確定／Backspace＝1点戻す';
    },
    // 🔒 §30-22-1 4: 主役の多角形は**この道具だけ Enter で閉じる**（§4-5 の例外）
    mainpoly: function () {
      return 'クリック＝頂点／Enter（またはダブルクリック）＝閉じて確定／Backspace＝1点戻す';
    }
  };

  /**
   * 道具の案内帯（🔒 §30-35-1・旧「作図中の操作ヒント帯」）。
   * 道具を持っている間（`select` 以外）は地図の下中央にその道具の文をずっと出す。
   * 🔴 文の出どころは TOOL_HINT（左メニューの1行・ガイダンスと同じ）1か所。
   *    多角形・主役の多角形だけ BADGE_KEYS の操作キーの文に差し替える。
   * 🔴 Ctrl を押している間は effectiveTool() が 'select' を返す＝帯は消える。
   */
  function updateDrawBadge() {
    var el = $('drawBadge');
    var t = state.editor ? state.editor.effectiveTool() : 'select';
    var key = (t && t !== 'select') ? BADGE_KEYS[t] : null;
    // 🔒 §30-35-1 4: TOOL_HINT に無い物（道具にならないボタン）は帯を出さない
    var msg = (t && t !== 'select') ? (key ? key(state.editor) : (TOOL_HINT[t] || '')) : '';
    el.hidden = !msg;
    if (!msg) return;
    el.textContent = msg;
    // 書き出し枠の案内と重ならないように上へ逃がす
    var up = !$('frameHint').hidden;
    el.classList.toggle('is-up', up);
    /* 🔒 §30-35-4 1: 帯（幅 900px まで）は右下の出典表記（#mapAttr・地理院1行／
       OSMFJ 2行）に掛かる。出典の高さを測って**出典の上**に置く（高さ＋8px・
       下限 12px）。枠の案内（is-up）がある時はさらに +32px。
       🔴 測れない時（#mapAttr が無い／高さ 0）は CSS の値（12px／44px）に任せる。 */
    var attr = $('mapAttr');
    var ah = attr ? attr.offsetHeight : 0;
    el.style.bottom = ah ? (Math.max(12, ah + 8) + (up ? 32 : 0)) + 'px' : '';
  }

  /** ⑦［詳しい設定］の初期値を埋める（枠サイズの一覧と、右パネルからの写し取り）。
   *  🔴 1度だけ効く（人が入れた値は上書きしない）。 */
  function sgFillPrefsInit() {
    if (!$('sgFillPreset').options.length) {
      Object.keys(StampPanel.PRESETS).forEach(function (k) {
        var p = StampPanel.PRESETS[k];
        var o = document.createElement('option');
        o.value = k;
        o.textContent = p.w ? (p.label + '  ' + p.w + '×' + p.h + 'm') : p.label;
        $('sgFillPreset').appendChild(o);
      });
      $('sgFillPreset').value = 'normal';
    }
    if (!$('sgFillW').value) {
      $('sgFillW').value = $('fillW').value;
      $('sgFillH').value = $('fillH').value;
      $('sgFillAisle').value = $('fillAisle').value;
      $('sgFillMargin').value = $('fillMargin').value;
    }
  }

  /**
   * 🔒 §29-1 ⑦: ガイダンス⑦の［写真から枠を描く］。
   * 🔴 中身は wzRunFill（旧📷ウィザード③の［車両枠を描く］と同じ関数）。
   *    ⑦の欄を「枠を並べる」パネルへ写してから runFillSmart を呼ぶ＝処理は1本。
   */
  function sgRunFill() {
    if (!state.editor) return;
    sgFillPrefsInit();                      // ［詳しい設定］の既定を埋める（初回だけ効く）
    setFillNote('写真を読み取って枠を描いています…');
    wzRunFill();
  }

  /** ⑦の欄（台数＋［詳しい設定］）を「枠を並べる」パネルへ写して実行する */
  function wzRunFill() {
    sgFillPrefsInit();
    ['W', 'H', 'Aisle', 'Margin'].forEach(function (k) {
      $('fill' + k).value = $('sgFill' + k).value;
    });
    $('fillCount').value = String($('sgFillCount').value || '').trim();
    var dir = (document.querySelector('input[name="sgFillDir"]:checked') || {}).value || 'auto';
    var r = document.querySelector('input[name="fillDir"][value="' + dir + '"]');
    if (r) r.checked = true;
    $('fillAngle').value = $('sgFillAngle').value;
    // ここでは番号・出入口・幅員は付けない（正典 §16-1 の三原則）
    ['fillNumber', 'fillEntrance', 'fillWidth'].forEach(function (id) {
      $(id).checked = false;
    });
    runFillSmart(function () {
      // 🔒 §29-1 ⑦: 枠の数・［次へ］の可否を引き直す
      if (navOnSide()) sgRenderStatus();
    });
  }

  /* ================= 案件のガイダンス（正典 §18 / §28 / §29） =========
   * ①マーカー →②所在図の枠 →③文字の量 →④描き足し →⑤下敷きと枠 →⑥土地の輪郭
   * →⑦駐車枠 →⑧道路 →⑨道路幅 →⑩出入口 →⑪駐車位置ラベル →⑫表示・保存 の全12段。
   * 🔒 §28-1 / §29（Step 7・2026-09-08）: 器は**左面のガイダンス（#sideNav）ひとつだけ**。
   *    地図の左上に出していた小ウィンドウ（#navPanel）と 📷 左ウィザード（#guidePanel）は
   *    どちらも全廃した。
   * 🔒 §28-6 ⑤: 進行状態（段の番号）は案件に保存する（navSaveStep / navResume）。
   * 🔒 §18-f の共通則:
   *    ・［戻る］は下部のボタン列の**左**
   *    ・足跡は**戻る方向だけ**クリックで移動できる
   *    ・戻る／足跡ジャンプは**表示だけ**が戻る。作った図形・データは一切消さない
   */

  /* 段の見出し（左面の #sgTitle に出る文言）。
   * 🔴 案内文は **SG_TEXT が唯一の出どころ**（見出しと本文を2か所に持たない）。
   * 🔒 §29-1（2026-09-07 オーナー承認・Step 6）: **⑤「下敷きと枠」を新設**した。
   *    初心者が最初につまずくのは「どの写真の上に描くのか」「どこが紙になるのか」なので、
   *    配置図の作図（輪郭・枠・道路）より前に1段置いた。
   * 🔴 これで従来の⑤〜⑪は**⑥〜⑫へ1つ後ろへずれた**（全12段）。
   *    保存済みの案件（旧番号）は store.js の migrate が navStepVer で読み替える。
   * 🔒 §30-1（2026-09-08 オーナー承認）: 入口が**図ごとに2つ**になったので、
   *    段の**見出しの番号は図ごとに①から**振り直す（所在図①〜④／配置図①〜⑧）。
   * 🔴 中の通し番号（1〜12）は変えない。番号は「表示のためだけ」に navDisp が作る
   *    ＝処理・保存・判定はすべて通し番号のままで、表示文字では分岐しない（§26-2 注意②）。 */
  var NAV = [
    { name: 'マーカーを置く' },
    { name: '所在図の枠を決める' },
    { name: '文字の量' },
    { name: '描き足し' },
    { name: '下敷きと枠' },
    { name: '土地の輪郭' },
    { name: '駐車枠を描く' },
    { name: '道路を書く' },
    { name: '道路幅を書き込む' },
    { name: '出入口を書き込む' },
    { name: '駐車位置ラベル作成' },
    { name: '所在図・配置図の表示' }
  ];

  /* ---- 図ごとの番号（🔒 §30-1 / §30-2）----
   * 🔴 丸数字はここ1か所（①〜㉕まで＝配置図の案内数字の最大が㉕）。 */
  var CIRC = '①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳㉑㉒㉓㉔㉕';
  /** 通し番号 n（1〜12）が所在図と配置図のどちらの段か */
  function navFigOf(n) { return (n <= Store.NAV_FIG_LAST.shozaizu) ? 'shozaizu' : 'haichizu'; }
  /** 通し番号 n → その図の中での段の番号（配置図は n−4） */
  function navDisp(n) {
    return (n <= Store.NAV_FIG_LAST.shozaizu) ? n : n - Store.NAV_FIG_LAST.shozaizu;
  }
  /** その図の段の番号 d → 通し番号（navDisp の逆） */
  function navStepOf(fig, d) {
    return (fig === 'haichizu') ? d + Store.NAV_FIG_LAST.shozaizu : d;
  }
  /** 丸数字（1〜25）。範囲外は素の数字にする（落とさない） */
  function circ(i) { return (i >= 1 && i <= CIRC.length) ? CIRC.charAt(i - 1) : String(i); }
  /** 段の見出し（例: ⑤ 下敷きと枠 → 配置図では「① 下敷きと枠」） */
  function navTitle(n) { return circ(navDisp(n)) + ' ' + NAV[n - 1].name; }
  /** その図の呼び名（見出し・案内文に出す） */
  function figName(fig) { return (fig === 'haichizu') ? '配置図' : '所在図'; }

  /* 🔒 §28-1（2026-09-06 オーナー指示）: 段は**左面のガイダンス面**（.side が
   * まるごと切り替わる）で出す。
   * 🔒 §28-10 裁定2: Step 2 で 2 → 4（③④を左面へ）。
   * 🔒 §29 Step 6: 4 → 8（配置図の⑤〜⑧を左面へ）。
   * 🔒 §29 Step 7: 8 → **12**＝**全段が左面**。小ウィンドウ（#navPanel）は全廃した。
   *    この定数は「左面で出す最後の段」の意味のまま残してある（＝全段）。 */
  var NAV_SIDE_LAST = 12;
  function navOnSide() { return !!state.nav && state.nav.step <= NAV_SIDE_LAST; }
  /** いまガイダンスがその段を出しているか（🔒 §29: 段の番号での分岐はここ経由で1行に） */
  function navAtStep(n) { return !!state.nav && state.nav.step === n; }

  /**
   * ガイダンスを始める（上部バーの［🧭 所在図ガイダンス］［🧭 配置図ガイダンス］から・🔒 §18-al）。
   * @param step 開きたい段（省略＝続きから／初回は①）。
   *   🔒 §29 Step 7: 道具メニューの［📷 写真から配置図］が **5** を渡す
   *   （＝⑤ 下敷きと枠。旧・左ウィザード①「写真を取り込む」の置き換え）。
   */
  function navStart(step) {
    if (!state.nav) { navGo(step || 1); return; }
    if (step && state.nav.step !== step) {
      navGo(step, { back: state.nav.step > step });
      return;
    }
    navOpen();
  }

  /**
   * 🔒 §30-1（2026-09-08 オーナー承認）: 入口は**図ごとに2つ**
   * （上部バーの［🧭 所在図ガイダンス］［🧭 配置図ガイダンス］）。
   * 押した方の図の**①**から始める。その図の段が案件に保存してあればそこから。
   * 🔴 タブの切り替えは navGo が段の番号から決める（①〜④＝所在図／⑤〜⑫＝配置図）
   *    ので、ここでは段を決めるだけ。
   */
  function navStartFig(fig) {
    if (!state.current) return;
    navStart(navStepOf(fig, navSavedDisp(fig) || 1));
  }

  /* ---------- はじめに（🔒 §30-20） ----------
   * ［新しい案件］で作図画面に切り替わった**直後だけ**出すかぶせ。
   * 3つのボタンは「上部バーの同名ボタンと同じ処理」＝ navStartFig を呼ぶだけ
   * （同じ操作は同じ結果・§26-2）。
   * 🔴 覚えるのは「次回から表示しない」だけ。案件には保存しない（このパソコンの設定）。
   *    キーの名前は §19-7 の shakomap.* に揃える（store.js の KEY_LAST / KEY_SEQ と同族）。
   * 🔴 利用者に見える文言に「ブラウザ／端末」は使わない（正典 §30-20）。 */
  var KEY_SKIP_WELCOME = 'shakomap.skipWelcome';

  function welcomeSkipped() {
    try { return localStorage.getItem(KEY_SKIP_WELCOME) === '1'; }
    catch (e) { return false; }       // 読めない時は「覚えていない」＝出す
  }

  function welcomeOpen() {
    if (welcomeSkipped()) return;
    $('wcNoMore').checked = false;    // 前に開いた時のチェックを持ち越さない
    $('welcomeBox').hidden = false;
  }

  /** 閉じる（3つのボタン・Esc の共通の出口）。チェックが入っていれば以後出さない */
  function welcomeClose() {
    if ($('welcomeBox').hidden) return;
    if ($('wcNoMore').checked) {
      try { localStorage.setItem(KEY_SKIP_WELCOME, '1'); }
      catch (e) { /* 覚えられないだけ。操作は止めない */ }
    }
    $('welcomeBox').hidden = true;
  }

  /** 案件に保存してあるその図の段（無ければ 0）。🔒 §30-1: nav:{shozaizu,haichizu} */
  function navSavedDisp(fig) {
    var nv = state.current && state.current.nav;
    var d = nv && Math.round(Number(nv[fig]));
    return (d >= 1 && d <= Store.NAV_FIG_LAST[fig]) ? d : 0;
  }

  function navOpen() {
    if (!state.nav) state.nav = { step: 1, polyBase: navPolyCount() };
    navShowHost();
    navRender();
  }

  /** ガイダンスの器を出す（🔒 §29 Step 7: 器は左面ひとつだけになった） */
  function navShowHost() { sgShow(navOnSide()); }

  /** ガイダンス面（左面）の出し入れ。閉じると道具メニューが戻る（何も消えない） */
  function sgShow(on) {
    var aside = document.querySelector('.side');
    $('sideNav').hidden = !on;
    if (aside) aside.classList.toggle('is-guide', !!on);
    /* 🔒 §28-4 / §28-7: 所在図の設定盤（14項目・🔒 §30-21-4 5: 11→13・🔒 §30-22-2 3: →14）は**部品ごと**行き来する。
     * ガイダンス中＝③の中／ガイダンス外＝右の浮き窓（同じ設定が2か所に出ない）。 */
    szSetHost(!!on);
    /* 幅が変わる＝地図の大きさが変わるが、mapview は ResizeObserver で
     * 自分で追随する（枠・オーバーレイもそこから引き直される）ので何もしない。 */
  }

  /**
   * 手順へ進む／戻る。ここで**表示**（タブ・地図）だけを手順に合わせる。
   * 🔒 §18-f: 図形・データには一切触らない。opt.back（戻る・足跡ジャンプ）の時は
   *    地図の寄せ直しもしない（手直し中の見え方を勝手に変えないため）。
   */
  function navGo(n, opt) {
    opt = opt || {};
    n = Math.max(1, Math.min(NAV.length, n));
    if (!state.nav) state.nav = { step: n, polyBase: 0 };
    var prev = state.nav.step;
    state.nav.step = n;
    // 🔒 §30-10: 段を離れたら前の字幕は消す（新しい段の字幕は sgRenderNums が出す）
    if (prev !== n) sgCaptionHide(true);
    // 🔒 §30-16: 段を移ったら拾う状態は終わる（④のボタンの状態なので）
    if (prev !== n) stopNamePick();
    // 🔒 §30-19-1: ［枠をまとめて］の置く状態も段をまたがない（配置図③のボタンの状態）
    if (prev !== n) stopStampArm();
    // 🔒 §28-1 / §29 Step 7: 器は左面のガイダンス面ひとつだけ
    navShowHost();
    if (n !== 1) navPinArm(null);
    if (n !== 12) state.nav.saved = false;
    // ガイダンスから出したプレビューは、その段を離れたら閉じる
    if (n !== 12 && n !== 4 && state.navPreview) closeExportPreview();

    /* 🔒 §28-3: ①〜④は**所在図の段**（②は「所在図の枠を決める」）。
     * 🔴 ⑤以降から足跡で戻ると配置図タブのままだったので、②の［枠を決定］が
     *    配置図の紙を決めてしまう（方位記号も置かれない）。①②も所在図へ揃える。 */
    if (n <= 4) {
      if (state.current && state.kind !== 'shozaizu') switchKind('shozaizu');
    }
    /* 🔒 §18-z: 戻る操作（［戻る］ボタン・足跡クリック）をしたら、
     * ②→③で自動で入れた［地図OFF］を**解除して地図を見せる**。
     * 「地図が消えた」と迷わせないため。入れ直すのは手で自由にできる。
     * 対象は所在図側の手順（①〜④）だけ＝配置図タブの下敷きには触らない。
     * 🔒 §22-z（2026-08-28 オーナー指示）: ただし**③だけは対象外**。
     * 🔴 ③は「所在図のパーツだけを見る画面」なので、入ってくる方向
     *    （②から進む／④から戻る／⑦から足跡で飛ぶ）によらず必ず地図OFFにする。
     *    ①②は地図を見ながらマーカーを置く段なので従来どおり解除する。 */
    if (opt.back && n <= 4 && n !== 3 && state.current && state.kind === 'shozaizu') {
      setUnderlayOffState(false);
    }
    /* 🔒 §22-z: ③へ入ったら方向によらず地図OFF（上のコメントの続き）。
     * ②→③は navRunShozaizu() が生成前に OFF にしているが、
     * ④から戻った時・⑦から足跡で飛んだ時はそこを通らないので、ここで揃える。 */
    if (n === 3 && state.current && state.kind === 'shozaizu') {
      setUnderlayOffState(true);
    }
    if (n >= 5 && state.current) {
      if (state.kind !== 'haichizu') switchKind('haichizu');
      /* 🔒 §30-7 A(2)（2026-09-08 オーナー指示）: ⑤（下敷きと枠）に入ったら配置図側の
       * 下敷きを必ず表示にする。所在図③で地図OFFにした状態が配置図に引き継がれて
       * 「写真が出ない」に見えるため。濃さは種類ごと（§24-1・c.maps[kind]）なので
       * ここは配置図側（state.kind はもう 'haichizu'）だけに効き、所在図側には触れない。
       * 濃さが 0（＝地図OFF）の時だけ既定値（100%）へ戻す。進む／戻る（opt.back）の
       * どちらで⑤へ来ても揃える。 */
      if (n === 5 && $('underlayOff').checked) {
        setUnderlayOffState(false);
      }
      /* 🔒 §29 Step 6: 配置図の1段目は⑤「下敷きと枠」になった。
       * 進んで初めて配置図側へ入った時だけ駐車場マーカー中心・ZL20（正典 §18-9）。
       * 🔴 ⑤には［駐車場に寄る］も置いてあるので、あとから何度でも自分で寄せ直せる。
       * 🔴 戻ってきた時（opt.back・prev>=5）は動かさない（手直し中の見え方を変えない）。 */
      if (n === 5 && !opt.back && prev < 5) {
        var p = state.current.points.lot || state.current.points.home;
        if (p) { state.map.setView(p, 20); persistSheetState(); }
      }
      /* 🔒 §29: 土地の輪郭は⑥（旧⑤）。ここから増えた多角形だけを「輪郭が描けた」と
       * 数えるので、段に入った時点の数を控える（navOnObjects が使う）。 */
      if (n === 6) {
        state.nav.polyBase = navPolyCount();
        /* 🔒 §30-14-3（2026-09-10 オーナー指示）: **動画は自動で出さない**。
         * 字幕の中の［多角形ツールの使い方動画を見る］を押した時だけ出す
         * （§22-ah の自動再生と「次からは再生しない」の印は廃止した）。 */
      }
      /* 🔒 §22-ag: ⑧（旧⑦）に入った時点で既にある図形の id を控える。
       * ここから増えた多角形だけを「道路」として印を付ける（navStampRoads）。
       * 🔴 控えないと⑥の土地の輪郭まで道路の印が付いてしまう。
       * 🔴 戻ってきた時も取り直すが、前回の訪問で印を付けた道路は
       *    source:'road' を持っているので数え直しでも消えない。 */
      if (n === 8 && prev !== 8) {
        state.nav.roadSeen = {};
        objectsOf('haichizu').forEach(function (o) {
          state.nav.roadSeen[o.id] = true;
        });
      }
    }
    /* 手順が変わったら前の段の状態表示は消す（③の生成結果だけは④へ持ち越す）。 */
    if (prev !== n && !(prev === 3 && n === 4)) navSetStatus('');
    /* 手順が変わったら道具は「選択」に戻す。
       🔴 前の段の道具（⑨の文字など）を握ったまま次の段へ行くと、
          地図をクリックした瞬間に意図しない図形が置かれる。 */
    if (prev !== n && state.editor) state.editor.setTool('select');
    /* 🔒 §18-v: ⑨（道幅）・⑩（出入口の幅）へ入ったら幅の欄を空にする（🔒 §29 で改番）。
       ⑨で入れた 6m がそのまま⑩の出入口の幅として矢印に付く事故を防ぐ。
       🔒 §25-5: 空欄のまま引いた矢印は地図から計算した距離が入る（手入力があればそちら優先）。 */
    /* 🔒 §30-18-4: 決め方のトグルも「自動入力」へ戻す（欄が空＝自動と同じ意味） */
    if (prev !== n && (n === 9 || n === 10)) setArrowMode('auto');
    /* ⑪の凡例（4項目）は 🔒 §18-l で**カスタム行なし**から始める
       （［＋ 項目を追加］を押した分だけ行が増える）。行そのものは1度だけ作る。 */
    if (n === 11) labelBuildRows('lb');
    /* 段を離れたら2クリック待ちは解除する（⑪の［配置］を握ったまま先へ行かない） */
    if (n !== 11) plDisarm();
    if (n === 12) navEnterFinish();
    // 🔒 §28-6 ⑤: 段を案件に覚えさせる（F5・開き直しで①へ戻されない）
    navSaveStep();
    navRender();
    /* 🔒 §30-25-32（2026-09-14 オーナー指示「次へで進めても表示位置が下のまま。
     * 常に上に戻るように」）: **段を移った時だけ**左面を一番上へ戻す
     * （［次へ］［戻る］・足跡クリックの全部がここを通る。段の中の▼の開閉では
     * 通らない＝戻さない）。面を組み直した後に呼ぶ。 */
    if (prev !== n) sgScrollTop();
  }

  /**
   * 🔒 §30-25-32: 左のガイダンス面のスクロールを一番上へ。
   * 🔴 実際にスクロールしているのは #sideNav を包む `.side`（style.css の
   *    `overflow-y: auto`）。面そのものが将来スクロールする作りになっても効くよう
   *    両方を 0 にする（呼ぶ所は navGo の1か所）。
   */
  function sgScrollTop() {
    var host = $('sideNav');
    if (!host) return;
    host.scrollTop = 0;
    var box = host.closest ? host.closest('.side') : host.parentNode;
    if (box) box.scrollTop = 0;
  }

  /**
   * 🔒 §28-6 ⑤（オーナー承認 2026-09-06）: いまの段を案件に保存する。
   * 案件を開いた時、保存された段があればその段でガイダンスを開く（navResume）。
   * 🔴 保存するのは**段の番号だけ**。図形・データには一切触らない（§18-f のまま）。
   */
  function navSaveStep() {
    var c = state.current;
    if (!c) return;
    /* 🔒 §30-1: 保存する形は**図ごと**（nav: {shozaizu: n, haichizu: n}）。
     * 🔴 いま出している段の図だけを書き換え、もう片方の図の段はそのまま残す
     *    （所在図を④まで進めてから配置図へ移っても、所在図の続きは覚えている）。 */
    if (state.nav) {
      var fig = navFigOf(state.nav.step), d = navDisp(state.nav.step);
      if (c.nav && c.nav[fig] === d && c.navStepVer === Store.NAV_STEP_VER) return;
      if (!c.nav) c.nav = {};
      c.nav[fig] = d;
      /* 🔒 §29 Step 6 / §30-1: 段の番号は**いまの版**で保存する。
       * 🔴 これを付けないと、旧番号で保存された案件と見分けが付かず、
       *    開くたびに migrate が読み替えて段が進んでしまう。 */
      c.navStepVer = Store.NAV_STEP_VER;
    } else {
      /* ガイダンスを自分で閉じた時は両方の図の段を忘れる（従来と同じ作法）。
       * 🔴 案件一覧へ戻る・別の案件を開く時は navClose(true) なのでここへ来ない。 */
      if (c.nav === undefined && c.navStepVer === undefined) return;
      delete c.nav;
      delete c.navStepVer;
    }
    Store.autosave(c);
  }

  /**
   * 🔒 §28-6 ⑤: 案件を開いた時に、保存された段からガイダンスを再開する。
   * 保存が無ければ何もしない（＝従来どおり道具メニューのまま）。
   */
  function navResume() {
    var c = state.current;
    if (!c || !c.nav) return;
    /* 🔒 §30-1: 段は図ごとに覚えている。開き直した時に**どちらの案内を出すか**は
     * 「いま開いているタブの図」。両方に段がある時は**所在図**を先に出す
     * （所在図 → 配置図の順に作るので、続きは所在図側から見せるのが正しい）。 */
    var sz = navSavedDisp('shozaizu'), hz = navSavedDisp('haichizu');
    var fig = (sz && hz) ? 'shozaizu'
            : (navSavedDisp(state.kind) ? state.kind : (sz ? 'shozaizu' : 'haichizu'));
    var d = navSavedDisp(fig);
    if (!d) return;
    var n = navStepOf(fig, d);
    state.nav = { step: n, polyBase: navPolyCount() };
    /* 🔴 navGo は通さない（進んだ時の副作用＝⑤の寄せ直し・⑥の動画・⑫のプレビューを
     *    「開いただけ」で起こさない）。器を出して描くだけにする。
     * 🔴 ただし**図の種類だけ**は段に合わせる（①〜④＝所在図／⑤〜＝配置図）。
     *    ここを揃えないと「⑤ 下敷きと枠」の案内が出ているのに所在図タブ、になる。 */
    var want = (n >= 5) ? 'haichizu' : 'shozaizu';
    if (state.kind !== want) switchKind(want);
    navShowHost();
    navRender();
  }

  /* 🔒 §30-12-2 2（2026-09-09）: ガイダンス面の青は **data-sgstate="next" だけ**が
   * 出す（＝出どころ1つ・青は常に1つ）。§22-z の「最後に押した道具ボタンを青く保つ」
   * navPickTool は、次に押す番号とは別の青をもう1つ作ってしまうので**やめた**。
   * 🔴 §22-z が直したかった「固定の class="primary" が選択中に見える」問題は、
   *    その固定 primary を index.html から外したこと自体で解消している。
   *    押した番号は✓になり、青は次の番号へ動く＝どこまで進んだかはそれで分かる。 */

  /**
   * 🔒 §30-18-4（2026-09-13 オーナー指示）: ⑤⑥の「文字を置く」欄の定型ボタン。
   * 押した後に**地図をクリックした所**へ置く（1回で解除）。
   * 🔴 仕組みは1つ ＝ state.editor.textPreset を立てて文字道具にするだけ。
   *    置く処理も解除も editor の 'text' を受ける1か所（§22-ab）がやる。
   * 🔴 旧 §22-z の「押した瞬間に地図の中央へ置く」は、置き場所を選べないので廃止。
   * 🔒 §30-29-1 2: 上部バー2行目の［A］→ #textPick の言葉のボタンも**ここへ来る**
   *    （共通ハンドラ1つ・言葉の出どころは TEXT_PRESETS 1か所）。
   */
  function navTextPreset(text) {
    if (!state.editor || !text) return;
    textPickClose();          // 🔒 §30-29-1 2: 選んだら窓は閉じる
    state.editor.textPreset = text;
    state.editor.setTool('text');
    hint('地図上をクリックすると「' + text + '」を置きます', 4000);
  }

  /** 🔒 §30-18-4: ［自由に入力…］＝文字道具（クリックした所に入力欄・§30-15-4 の OK 付き） */
  function navTextFree() {
    if (!state.editor) return;
    textPickClose();          // 🔒 §30-29-1 2
    state.editor.textPreset = '';
    state.editor.setTool('text');
    hint('地図上をクリックすると、文字の入力欄が出ます', 4000);
  }

  /**
   * 🔒 §25-7（2026-08-29 オーナー指示）: ［枠をまとめて］は1枠だけ置く
   * （台数を数えて入力させない）。
   * 🔒 §30-19-1（2026-09-13 改定）: **押した瞬間に置く**のはやめて、
   *    押した後に**地図をクリックした所**へ置く（→ startStampArm）。
   * 枠の大きさ・並べ方は［台数を指定して置く…］の窓で最後に選んだ物を引き継ぐ。
   * 🔴 道具は［選択］に戻す（§22-z-5 の作法）。置いた枠をそのまま掴んで直せる。
   * @param origin {lat,lng}＝置く場所。省略時は地図の中央（従来の呼び方）
   */
  function placeStampOne(origin) {
    if (!state.editor || !state.map) return;
    var s = (state.stamp && state.stamp.state) || {};
    var o = state.editor.placeStamp({
      count: 1,
      origin: origin || null,
      cell_w_m: s.w || 2.5, cell_h_m: s.h || 5.0,
      direction: s.direction || 'row'
    });
    /* 🔒 §30-19-1: 置いた塊を選んだまま［選択］へ戻す（±・回転がすぐ使える）。
     * 🔴 placeStamp → _pushNew が selection を立てる。setTool は 'select' の時だけ
     *    選択を残して 'select' を鳴らし直すので、ここで選び直す必要はない。 */
    if (o) state.editor.selection = [o.id];
    state.editor.setTool('select');
    if (state.stamp) state.stamp.close();
    updateHistoryButtons();
    hint('枠を1つ置きました。まわりの ＋ を押すとその向きに枠が増えます'
       + '（矢印キーでも増減／Shift＋矢印で回転）', 6000);
  }

  /* ---------- 🔒 §30-19-1: ［枠をまとめて］の「置く状態」 ----------
   * オーナー:「枠をまとめて ボタンを押したら即設置ではなく、クリックで設置に」
   * 🔴 状態（state.stampArm）は**画面の状態**。案件には保存しない。
   * 🔴 地図クリックの拾い方は §30-16 の拾う状態（startNamePick）と**同じ作法**
   *    ＝ .map-wrap の capture で pointerdown / click を先取りする。 */

  /** ［枠をまとめて］2か所（道具メニュー・配置図③）の押された見た目を揃える */
  function syncStampArmBtn() {
    document.querySelectorAll('.tool[data-tool="stamp"]').forEach(function (b) {
      b.classList.toggle('is-on', !!state.stampArm);
    });
  }

  function toggleStampArm() {
    if (state.stampArm) {
      stopStampArm();
      hint('枠を置くのをやめました', 2000);
      return;
    }
    startStampArm();
  }

  function startStampArm() {
    if (state.stampArm) return;
    if (!state.editor || !state.map) return;
    state.stampArm = true;
    $('map').style.cursor = 'crosshair';
    var wrap = document.querySelector('.map-wrap');
    wrap.addEventListener('pointerdown', onStampArmDown, true);
    wrap.addEventListener('click', onStampArmClick, true);
    syncStampArmBtn();
    hint('枠を置く場所を地図でクリックしてください（Esc でやめる）', 0);
  }

  /** 置く状態を終える。🔴 掴んだままにすると地図クリックを全部横取りしてしまう */
  function stopStampArm() {
    if (!state.stampArm) return;
    state.stampArm = false;
    $('map').style.cursor = '';
    var wrap = document.querySelector('.map-wrap');
    wrap.removeEventListener('pointerdown', onStampArmDown, true);
    wrap.removeEventListener('click', onStampArmClick, true);
    syncStampArmBtn();
    hintHide();                  // 出しっぱなしにしていた案内を消す
  }

  function onStampArmDown(e) {
    if (!state.stampArm || !state.map) return;
    if (e.button !== 0) return;                     // 中ボタン等の従来のパンは残す
    if (!$('spaceBadge').hidden) return;            // スペース＝一時パンには譲る
    if (!state.map.el.contains(e.target)) return;   // 地図の外（＋−ボタン等）は素通し
    var r = $('map').getBoundingClientRect();
    var px = e.clientX - r.left, py = e.clientY - r.top;
    if (px < 0 || py < 0 || px > r.width || py > r.height) return;
    e.preventDefault();
    e.stopPropagation();                            // 左ドラッグの地図パンを飲む
    var ll = state.map.unproject(px, py);
    stopStampArm();                                 // 先に解いてから置く（1回で終わる）
    placeStampOne(ll);
  }

  /** pointerdown を止めても click は届くので、こちらも飲む */
  function onStampArmClick(e) {
    if (!state.stampArm || !state.map) return;
    if (!state.map.el.contains(e.target)) return;
    e.stopPropagation();
  }

  /** ［戻る］。表示だけが戻る（作った図形・データは一切消さない・🔒 §18-f） */
  function navBack() {
    if (!state.nav) return;
    var n = state.nav.step;
    if (n <= 1) return;
    navGo(n - 1, { back: true });
  }

  /** 保存中などボタンを固めたい時 */
  function navBusy(on) {
    Array.prototype.forEach.call($('sgFoot').querySelectorAll('button'),
      function (b) { b.disabled = !!on; });
  }

  /**
   * ガイダンスを閉じる。
   * @param keepStep true＝案件に保存した段は**消さない**（案件一覧へ戻る・
   *   別の案件を開く時。次に開いた時に続きから再開できるように・🔒 §28-6 ⑤）。
   *   利用者が自分で［×］／［ガイダンスを閉じる］を押した時だけ消す。
   */
  function navClose(keepStep) {
    /* 🔒 §29 Step 7: ⑫から出したプレビューはガイダンスの一部なので一緒に閉じる。
     * 🔴 閉じないと、ガイダンスが消えたのに全面のかぶせだけが残る
     *    （左面を前に出す .is-front も付いたままになる）。図・保存には触らない。 */
    if (state.navPreview) closeExportPreview();
    sgShow(false);               // 🔒 §28-1: 左面は道具メニューへ戻す（何も消えない）
    // 🔒 §30-17-2: ガイダンスを閉じたら図ごとの色（緑）も外す
    document.body.classList.remove('sg-hz');
    sgCaptionHide(true);         // 🔒 §30-3: 字幕もここで消す（次の行動が無くなるので）
    stopNamePick();              // 🔒 §30-16: 拾う状態もガイダンスと一緒に終わる
    stopStampArm();              // 🔒 §30-19-1: 枠を置く状態も一緒に終わる
    state.nav = null;
    if (!keepStep) navSaveStep();
    navPinArm(null);
    plDisarm();                  // ⑪の2クリック待ちを握ったままにしない
  }

  /** 輪郭とみなす図形の数。開いたまま確定（Shift+Enter＝path）も人が描いた物なら数える。
   *  自動下書きの道路縁（source:'auto'）は輪郭ではないので数えない */
  function navPolyCount() {
    var objs = objectsOf('haichizu');
    return objs.filter(function (o) {
      if (!o.points || o.points.length < 3) return false;
      return o.type === 'polygon' || (o.type === 'path' && !o.source);
    }).length;
  }

  /** 図形が増えた時に呼ぶ。
   *  🔒 §30-25-11（2026-09-13 オーナー指示）: 配置図②で多角形を Enter で確定しても
   *  **勝手に次の段へ進まない**（旧 §18-p の自動送りは廃止）。一言だけ出して、
   *  進むのは一番下の［次へ］。②の［次へ］の済み判定（多角形1つ以上）は今のまま。 */
  function navOnObjects() {
    if (!state.nav) return;
    navStampRoads();
    /* 🔒 §29 Step 6: 土地の輪郭は⑥（旧⑤）、駐車枠は⑦（旧⑥） */
    if (state.nav.step === 6 && navPolyCount() > (state.nav.polyBase || 0)) {
      state.nav.polyBase = navPolyCount();       // 同じ多角形で何度も言わない
      hint('輪郭を確定しました。よければ［次へ］を押してください', 3500);
    }
    if (state.nav.step >= 5) sgRenderStatus();
    /* 🔒 §30-31-3 2: ⑧（step 12）の「提出前チェック」の一覧は廃止したので、
     * 図形が変わった時に数え直す物は無い。 */
  }

  /**
   * 🔒 §22-ag: ⑧（旧⑦）で新しく描いた多角形の線に **source:'road'** の印を付ける。
   * 🔴 印が無いと、多角形で引いた道路が⑥の土地の輪郭と**見分けが付かない**ので
   *    ①道路として数えられない（進捗表示が出ない）
   *    ②敷き詰めの敷地として誤って拾われる（fillTargetPolygon）
   *    の2つが起きる。§22-ac で Enter が path を作るようになって表面化した。
   * 🔴 「⑧に入った時点で既にあった図形」は対象外にする（roadSeen）。
   *    全部を舐めると⑥の輪郭まで道路として印が付いてしまう。
   */
  function navStampRoads() {
    if (!state.current || state.nav.step !== 8) return;
    var seen = state.nav.roadSeen || {};
    objectsOf('haichizu').forEach(function (o) {
      if (o.source || seen[o.id]) return;
      if ((o.type === 'path' || o.type === 'polygon') && o.points && o.points.length >= 2) {
        o.source = 'road';
      }
    });
  }

  /** 駐車枠の数（⑦の状態の一言・［次へ］の条件・🔒 §29-1）。
   *  🔒 §25-4: 主役マーク（role:'mainmark' の四角）は駐車枠ではないので数えない。 */
  function navFrameCount() {
    return objectsOf('haichizu').filter(function (o) {
      return (o.type === 'rect' && o.role !== 'mainmark') || o.type === 'stampGroup';
    }).length;
  }

  /** ⑧で引いた道路の本数（直線・曲線＋多角形で引いた物・🔒 §22-ag／§29 で改番） */
  function navRoadCount() {
    var objs = objectsOf('haichizu');
    return objs.filter(function (o) {
      // 🔒 §18-t: 手で引いた直線・曲線。自動下書きの道路縁は数えない
      if ((o.type === 'line' || o.type === 'curve') && o.source !== 'auto') return true;
      /* 🔒 §30-25-22 5: ［道路を描く］が置いた**縁の線**（type:'path'）も道路として
       * 数える（押した人にとっては「道路を描いた」ので、⑥の済み判定が立つ）。 */
      return (o.type === 'path' || o.type === 'polygon')
          && (o.source === 'road' || o.source === 'roadauto');
    }).length;
  }

  /* ---- 多角形ツールの使い方動画（🔒 §22-ah → §30-14-3 で出し方を変更） ----
   * 🔒 §30-14-3（2026-09-10 オーナー指示）: 段に入った時の**自動再生をやめた**。
   *   字幕の中の［多角形ツールの使い方動画を見る］（SG_NUM[].btn）を押した時だけ出す。
   * 🔴 押した時だけ出るので「次からは再生しない」の印（localStorage）は要らなくなった
   *   ＝ VID_SKIP_KEY / vidSkipped / #vidSkip は廃止した。 */
  function vidOpen() {
    var box = $('vidBox'), v = $('vidPlayer');
    box.hidden = false;
    try { v.currentTime = 0; } catch (e) { /* まだ読めていない時は無視 */ }
    vidTryPlay(v);
  }

  /**
   * 🔴 preload="none" にしてあるので、**開いた直後の play() はデータ待ちで失敗する**
   * （実測: readyState が 0 のまま拒否され、動画が止まったまま出ていた）。
   * 読み込めた時点で1回だけ再挑戦する。それでも駄目なら（音付きの自動再生禁止など）
   * 黙って諦める＝再生ボタンを押せば見られる状態で残す。
   */
  function vidTryPlay(v) {
    var p = v.play();
    if (!p || !p.catch) return;
    p.catch(function () {
      v.addEventListener('canplay', function once() {
        v.removeEventListener('canplay', once);
        var p2 = v.play();
        if (p2 && p2.catch) p2.catch(function () { /* 自動再生できなくても止めない */ });
      });
    });
  }

  function vidClose() {
    var box = $('vidBox'), v = $('vidPlayer');
    if (box.hidden) return;
    box.hidden = true;
    try { v.pause(); } catch (e) { /* 再生前に閉じた時 */ }
  }

  /* ---- 駐車位置ラベル（🔒 §22-ab／🔒 §29-1 ⑪） ----
   * 出す所は**2か所**（ガイダンス⑪＝接頭辞 'lb' ／ 道具メニューの小ウィンドウ＝'pl'）。
   * 🔴 入力の中身（LABEL_ROWS）も置き方も**同じ関数**。違うのは接頭辞と案内の出し先だけ。
   * 🔒 §29 Step 7: ⑪の「対象を自動で見つけて自動で置く」（旧 navPasteLabel）は廃止し、
   *    どちらの入口も**2クリックで人が決める**に揃えた（§18-ap「必ず自分で置く」と同じ考え）。
   * 🔴 1クリック目＝矢印の先（対象の駐車枠）／2クリック目＝ラベルを置く場所。 */

  /** 定型4行を1度だけ作る。pre は 'lb'（ガイダンス⑪）/ 'pl'（小ウィンドウ） */
  function labelBuildRows(pre) {
    var box = $(pre + 'Rows');
    if (!box || box.childElementCount) return;      // 1度だけ作る
    box.innerHTML = labelRowsHTML(pre);
    /* 🔒 §30-22-4 10: 前回入れた値を最初から入れておき、変えたら覚え直す */
    labelFillLast(pre);
    LABEL_ROWS.forEach(function (r) {
      var inp = $(pre + r.key);
      if (inp) inp.addEventListener('change', function () { labelLastSave(pre); });
    });
  }

  /* ---- 長さ・幅の「前に入れた値」（🔒 §30-22-4 10・2026-09-13 オーナー指示）----
   * 🔴 この PC の設定（§19-7 の shakomap.* に揃える）。**案件には保存しない**
   *    ＝案件を移しても付いていかない／案件データは太らない。
   * 🔴 読み書きは必ず try/catch（保存領域が使えない環境でも図は作れる）。 */
  var LABEL_LAST_KEY = 'shakomap.labelLast';
  /* 🔒 §30-22-6 1（オーナー回答）: ［標準の値］は 5.5m×2.5m（§30-22-4 10 の 5.0 を訂正） */
  var LABEL_STD = { Len: '5.5', Wid: '2.5' };

  function labelLastLoad() {
    try {
      var s = localStorage.getItem(LABEL_LAST_KEY);
      var o = s ? JSON.parse(s) : null;
      return (o && typeof o === 'object') ? o : {};
    } catch (e) { return {}; }
  }
  function labelLastSave(pre) {
    var o = {};
    LABEL_ROWS.forEach(function (r) {
      var inp = $(pre + r.key);
      if (inp) o[r.key] = String(inp.value || '').trim();
    });
    try { localStorage.setItem(LABEL_LAST_KEY, JSON.stringify(o)); } catch (e) { /* 使えなくてよい */ }
  }
  /** 空の欄にだけ前回の値を入れる（人が入れた値は上書きしない） */
  function labelFillLast(pre) {
    var last = labelLastLoad();
    LABEL_ROWS.forEach(function (r) {
      var inp = $(pre + r.key);
      if (!inp || inp.value) return;
      if (last[r.key]) inp.value = last[r.key];
    });
  }
  /** ［標準の値］＝長さ 5.5m・幅 2.5m を入れる（🔒 §30-22-6 1） */
  function labelSetStd(pre) {
    Object.keys(LABEL_STD).forEach(function (k) {
      var inp = $(pre + k), on = $(pre + k + 'On');
      if (inp) inp.value = LABEL_STD[k];
      if (on) on.checked = true;
    });
    labelLastSave(pre);
    labelHint(pre, '標準の値（長さ ' + LABEL_STD.Len + 'm・幅 '
      + LABEL_STD.Wid + 'm）を入れました');
  }

  /* 🔒 §30-25-36 2（2026-09-14 オーナー指示）: ［配置］の名前は［保管場所ラベル配置］。
   * 🔴 名前の出どころはこの1か所（ガイダンス⑦の字幕・案内の一言・SG_NUM の label が
   *    ここを読む。ボタンそのものの文字は index.html の #sgLabelPlace / #plPlace）。 */
  var LABEL_PLACE_JA = '保管場所ラベル配置';

  /** 案内の一言（⑪＝#lbHint ／ 小ウィンドウ＝#plHint） */
  function labelHint(pre, msg) {
    var el = $(pre + 'Hint');
    if (el) el.textContent = msg;
  }

  function plOpen() {
    if (!state.current || !state.editor) return;
    labelBuildRows('pl');
    /* 🔴 小ウィンドウは .stamp-panel の共通位置（左上）に重なって出るので、
     * 先に塊スタンプの方を閉じる。2枚重なるとボタンが押せなくなる */
    if (state.stamp) state.stamp.close();
    $('plPanel').hidden = false;
    /* 🔒 §30-25-36 2: 名前は LABEL_PLACE_JA。
     * 🔒 §30-22-4 10: 置き方はワンクリック（plDisarm の一言と同じ文にそろえる）。 */
    labelHint('pl', '［' + LABEL_PLACE_JA + '］のあと、対象の駐車枠をクリックします。');
  }

  function plClose() {
    $('plPanel').hidden = true;
    plDisarm();
  }

  /** ［配置］→ 2クリック待ちに入る。pre は 'lb'（ガイダンス⑪）/ 'pl'（小ウィンドウ） */
  function labelArm(pre) {
    if (!state.current || !state.editor || !state.map) return;
    var lines = labelLinesFrom(pre);
    if (lines.length < 2) {
      labelHint(pre, '⚠ チェックを入れて数値を入力してください');
      return;
    }
    labelLastSave(pre);          // 🔒 §30-22-4 10: 入れた値を覚える
    state.plPlace = { pre: pre, lines: lines };
    $('map').style.cursor = 'crosshair';
    // 地図・描画エンジンより先に受け取る（①マーカー設置と同じ作法）
    document.querySelector('.map-wrap')
      .addEventListener('pointerdown', onPlPlaceClick, true);
    labelHint(pre, '対象の駐車枠をクリックしてください');
    hint('ラベルを付ける駐車枠をクリックしてください（Esc でやめる）', 4000);
    if (navOnSide()) sgRenderStatus();
  }

  function plDisarm() {
    if (!state.plPlace) return;
    // 🔒 §30-25-36 2: 名前は LABEL_PLACE_JA（index.html の初期文言と同じ）
    labelHint(state.plPlace.pre, '［' + LABEL_PLACE_JA + '］のあと、対象の駐車枠をクリックします。');
    state.plPlace = null;
    $('map').style.cursor = '';
    document.querySelector('.map-wrap')
      .removeEventListener('pointerdown', onPlPlaceClick, true);
  }

  function onPlPlaceClick(e) {
    if (!state.plPlace || !state.map || !state.current) return;
    /* パネル・左面の上のクリックは地図ではない（掴んだままだと操作不能になる）。
     * 🔒 §29 Step 7: ⑪は左面（.side）にあるので、そちらも除ける。 */
    if (e.target && e.target.closest
        && e.target.closest('.stamp-panel, .side')) return;
    var r = $('map').getBoundingClientRect();
    var px = e.clientX - r.left, py = e.clientY - r.top;
    if (px < 0 || py < 0 || px > r.width || py > r.height) return;
    e.preventDefault();
    e.stopPropagation();
    var pre = state.plPlace.pre;
    /* 🔒 §30-22-4 10（2026-09-13 オーナー指示）: ［配置］は**ワンクリック**。
     * 対象の駐車枠をクリックしたら、その枠の**右上（枠の外・紙で 6mm）**に
     * ラベルを置き、矢印の先はその枠の中心にする（2回目のクリックは無い）。
     * 🔴 対象は駐車枠だけ（塊の1枠 or 単独の四角）。主役マークは対象外（§25-4）。 */
    var spot = labelSpotAt(px, py);
    if (!spot) {
      labelHint(pre, '⚠ 駐車枠の上をクリックしてください');
      hint('ラベルを付ける駐車枠の上をクリックしてください（Esc でやめる）', 3000);
      return;
    }
    var lines = state.plPlace.lines;
    plDisarm();
    // 置いた直後にそのまま掴んで動かせるように「選択」にしておく
    state.editor.setTool('select');
    state.editor.addLabelBlock({ at: spot.at, arrowTo: spot.arrowTo, lines: lines });
    updateHistoryButtons();
    if (pre === 'pl') plClose();
    else if (navOnSide()) sgRenderStatus();          // ⑪の「ラベル n 個」を引き直す
    hint('塊はドラッグで移動・右下のつまみで大きさ・矢印の先だけ別に動かせます', 5000);
  }

  /**
   * 🔒 §30-22-4 10: クリックした所の駐車枠から「ラベルの置き場所」を決める。
   * @return {at, arrowTo} か null（駐車枠でなければ null）
   */
  function labelSpotAt(px, py) {
    var ed = state.editor;
    if (!ed || !state.map) return null;
    var corners = null;
    var cell = ed.hitStampCell ? ed.hitStampCell(px, py) : null;
    if (cell) {
      corners = ed.stampCellCorners(cell.group, cell.index);
    } else {
      var o = ed.hitObject(px, py);
      // 🔒 §25-4: 主役マークは車両枠ではないので対象外（保管場所マークと同じ扱い）
      if (o && o.type === 'rect' && o.role !== 'mainmark') corners = ed.rectCorners(o);
    }
    if (!corners || !corners.length) return null;
    var maxX = -Infinity, minY = Infinity, cx = 0, cy = 0;
    corners.forEach(function (p) {
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      cx += p.x; cy += p.y;
    });
    cx /= corners.length; cy /= corners.length;
    var gap = paperMmToPx(LABEL_GAP_MM);
    return { at: state.map.unproject(maxX + gap, minY - gap),
             arrowTo: state.map.unproject(cx, cy) };
  }

  /* 枠の外へ置く間隔（紙のミリ・🔒 §30-22-4 10「枠の外・6mm 相当」） */
  var LABEL_GAP_MM = 6;

  /**
   * 紙の mm → いまの画面の px（🔴 換算は「枠の画面幅 ÷ 枠が紙に刷られる幅」1か所）。
   * 🔴 紙の幅は export.js の placeOnPage が唯一の出どころ（余白・見出し帯こみ）。
   */
  function paperMmToPx(mm) {
    var k = paperMmPxNow();
    return mm * (k > 0 ? k : 3);
  }

  /**
   * 🔒 §30-25-7: **紙に刷られる 1mm が、いまの画面で何 px か**。
   * 🔴 換算は「枠の画面幅 ÷ 枠が紙に刷られる幅」のこの1か所（paperMmToPx も
   *    editor へ挿す frameMmPx もここを読む）。紙の幅は export.js の placeOnPage が
   *    唯一の出どころ（余白・見出し帯こみ）＝数値を app.js に書き写さない。
   * @return px/mm（枠や画面が無ければ null）
   */
  function paperMmPxNow() {
    var sh = curSheet();
    if (!sh || !state.map || !window.Exporter) return null;
    var r = (sh.frameFixed && sh.frame) ? fixedFrameRectPx(sh.frame) : frameRectPx();
    var asp = sh.frame ? Exporter.frameAspect(sh.frame) : curAspect();
    var place = Exporter.placeOnPage(sh.orient === 'landscape' ? 'landscape' : 'portrait', asp);
    if (!r || !(r.w > 0) || !place || !(place.w > 0)) return null;
    return r.w / place.w;
  }

  /* ---- ①マーカーの設置（地図クリックで置く） ---- */

  /** key を渡すと「次の地図クリックでそのマーカーを置く」状態にする。null で解除 */
  function navPinArm(key) {
    var wrap = document.querySelector('.map-wrap');
    if (state.pinPlace && (!key || state.pinPlace !== key)) {
      wrap.removeEventListener('pointerdown', onNavPinPlace, true);
      state.pinPlace = null;
      $('map').style.cursor = '';
    }
    if (!key || state.pinPlace === key) { navRenderPins(); return; }
    state.pinPlace = key;
    $('map').style.cursor = 'crosshair';
    // 地図・描画エンジンより先に受け取る（辺クリックと同じ作法・§16-7）
    wrap.addEventListener('pointerdown', onNavPinPlace, true);
    /* 🔒 §25-1: マーカーの呼び名は「使用の本拠」（ボタンの文言と揃える）。
     * 🔒 §30-22-1 6: 'same'＝本拠と駐車場を**同じ場所に1つ**置く。 */
    hint(armLabel(key) + 'のマーカーを置く場所を地図でクリックしてください', 4000);
    navRenderPins();
  }

  /** 主役のラベルの文言（🔒 §30-22-1 6: 出どころは Shozaizu.PIN_LABEL 1か所） */
  function pinLabel(key) {
    var T = (window.Shozaizu && Shozaizu.PIN_LABEL) || {};
    return T[key] || '';
  }

  /** これから置く物の呼び名（🔒 §30-24-2: 同一住所は2地点ぶんを1回で置く） */
  function armLabel(key) {
    return (key === 'same')
      ? (pinLabel('home') + 'と' + pinLabel('lot')) : pinLabel(key);
  }

  function onNavPinPlace(e) {
    if (!state.pinPlace || !state.map || !state.current) return;
    // パネルの上のクリックは地図ではない（掴んだままだと操作不能になる）
    if (e.target && e.target.closest && e.target.closest('.stamp-panel')) return;
    var r = $('map').getBoundingClientRect();
    var px = e.clientX - r.left, py = e.clientY - r.top;
    if (px < 0 || py < 0 || px > r.width || py > r.height) return;
    e.preventDefault();
    e.stopPropagation();
    var key = state.pinPlace;
    var ll = state.map.unproject(px, py);
    /* 🔒 §30-22-1 6（2026-09-13 オーナー指示）: ［使用の本拠と駐車場が同一住所］は
     * **1回のクリックで2地点を同じ場所に置く**（印もラベルも紙には1つ出る）。
     * 🔴 印の設定は本拠側を採る（§30-22-1 6）ので、駐車場側にも同じ物を写す。 */
    if (key === 'same') {
      placeSamePoint(ll);
      return;
    }
    placePointAt(key, ll);
    hint(pinLabel(key) + 'マーカーを置きました', 2500);
  }

  /**
   * 🔒 §30-39-3 1（2026-09-19 オーナー指示）: **緯度経度を受けて、その地点の
   * マーカーを作る（既にあれば置き直す）**。呼ぶのは2か所:
   *   ・［○○マーカー設置］→ 地図クリック（onNavPinPlace）
   *   ・住所検索（doSearch）＝検索した場所に◎を置く
   * 規則（同一住所の解除・文字・印・追従・自動保存）を2つ書かないため、
   * 「地点を作る」処理はここ1本だけにする。
   * 🔴 置いた後の一言（hint）は**呼ぶ側**が出す（置き方で文が違う）。
   */
  function placePointAt(key, ll) {
    var c = state.current;
    if (!c) return;
    /* 🔒 §30-24-2（2026-09-13 オーナー指示）: 同一住所の状態でどちらかを置き直した
     * 時は、**共有していた印は置かなかった方の役目として残す**
     * （置いた方はこれから新しく作る）。 */
    if (c.points.same) leaveSamePoint(key);
    var cur = c.points[key] || {};
    c.points[key] = {
      lat: ll.lat, lng: ll.lng,
      label: pinLabel(key),
      /* 🔒 §30-39-3 3: 住所の記録は**欄の値**（本拠・駐車場とも欄がある）。
         欄が空の時は、既に持っている住所（案件を開き直した時・依頼文から
         拾った時）をそのまま残す。 */
      address: addrOf(key) || cur.address || '',
      title: cur.title,
      /* 🔒 §28-14 ①-4: マーカーの形と色。置く前に①で選んでいればそれを移す */
      mark: cur.mark || state.markPick[key] || undefined
    };
    if (!c.points[key].mark) delete c.points[key].mark;
    state.markPick[key] = null;
    /* 🔒 §30-22-1 6: どちらかを置き直したら「同一住所」は外れる */
    c.points.same = false;
    navPinArm(null);
    /* 🔒 §30-24-3: 置き直しでも文字は必ず1つずつある
     * （leaveSamePoint が置いた方の文字を取り除いた直後の出口でもある）。
     * 🔒 §30-25-28 1（2026-09-14 オーナー指示）: **マーカーを置いた瞬間**が
     * 文字を作る契機（白紙でも作る）。続けて applyMarkChoice が■（四角の印）を
     * 文字の直前へ作る＝置いた直後から「印＋文字」が揃い、どちらも動かせる。 */
    ensureMainLabels();
    applyMarkChoice(key);
    /* 🔒 §30-32-5: **多角形を先に描いてからマーカーを置いた**時も◎を出さない
     * （印の種類は「その地点の紙に多角形があるか」で決まる＝順番に依らない）。 */
    syncMarkShapeFromPolys();
    refreshPoints();
    sgRenderMarks();         // ▼は本拠・駐車場の2つへ戻る（§30-24-2）
    Store.autosave(c);
    navRender();
  }

  /**
   * 🔒 §30-22-1 6 / §30-22-6 2（2026-09-13 オーナー指示）: 使用の本拠と駐車場を
   * **同じ場所に1つ**置く。2地点の値は同じ座標になり、`points.same` が立つ。
   * 🔒 §30-24-2: 紙に出るのは**印1つ＋文字2つ**（「使用の本拠」と「駐車場」を
   *    上下に並べる・どちらもドラッグで動かせる）。
   * 🔴 結線と直線距離は描かない（生成側 opts.same／追従側 syncRoleObjects）。
   */
  function placeSamePoint(ll) {
    var c = state.current;
    var h = c.points.home || {}, l = c.points.lot || {};
    /* 印の設定は**本拠側を採る**（§30-22-1 6）。まだ置いていない時は①の控え。 */
    var mk = h.mark || state.markPick.home || l.mark || state.markPick.lot || null;
    /* 🔒 §30-24-2（2026-09-13 オーナー指示）: それまでに②③で置いた物
     * （◎■・多角形・文字）は**全部消してから**置く（確認は出さない）。
     * 🔴 消す前に控えを取るので ［戻す］（Ctrl+Z）で元に戻せる。 */
    if (state.editor) state.editor.snapshot();
    var wiped = clearMainMarks(['home', 'lot']);
    if (wiped.length && state.editor) state.editor.commit();
    /* 多角形は今ぜんぶ消えたので、印の種類が「多角形」のままだと印が無くなる＝◎へ戻す */
    if (mk && mk.shape === 'polygon') mk = { shape: 'circle', color: mk.color };
    ['home', 'lot'].forEach(function (key) {
      var cur = c.points[key] || {};
      c.points[key] = {
        lat: ll.lat, lng: ll.lng,
        label: pinLabel(key),
        // 🔒 §30-39-3 3: 住所の記録は欄の値（空なら今まで持っていた住所を残す）
        address: addrOf(key) || cur.address || '',
        title: cur.title,
        mark: mk ? { shape: mk.shape, color: mk.color } : undefined
      };
      if (!c.points[key].mark) delete c.points[key].mark;
      state.markPick[key] = null;
    });
    c.points.same = true;
    navPinArm(null);
    /* 🔒 §30-24-3: 全部消した後の紙に、文字を2つ（本拠・駐車場）置き直す
     * （正典 §30-24-2「全部消してから置く」）。消した紙は白紙と見分けが付かない
     * ので、どの紙だったかを clearMainMarks から受け取って渡す。
     * その後 applyMarkChoice が印（◎／■）を文字の前へ作る＝消える経路の出口。 */
    /* 🔒 §30-25-28 1: 置いた瞬間が契機なので**必ず**両方を通す（作った数で
     * 分岐しない＝文字が既にある紙でも印を引き直す）。 */
    ensureMainLabels(wiped);
    applyMarkChoice('home');
    applyMarkChoice('lot');
    // 🔒 §30-32-5: 同一住所の直後も同じ規則（多角形が残っていれば◎を出さない）
    syncMarkShapeFromPolys();
    refreshPoints();
    sgRenderMarks();         // ▼は［同一住所］の直下の1つだけになる（§30-24-2）
    Store.autosave(c);
    hint('使用の本拠と駐車場を同じ場所に置きました（結線と直線距離は出ません）', 3500);
    navRender();
  }

  /**
   * 🔒 §30-32-6（2026-09-15 オーナー指示「配置図で駐車場マーカーを消すと所在図でも
   * 消える。配置図でのみ消えるように」）: 消しゴムで**画面のピン**をクリックした時の
   * 振り分け。**判定は「いまどちらの図の紙か」だけ**（表示文字では分岐しない）。
   *   ・所在図の紙 … 地点そのものを消す（removePoint・§30-32-1）
   *   ・配置図の紙 … **その紙のピンの表示だけ**を消す（地点は残る＝所在図は変わらない）
   * 🔴 地点（points[key]）は案件の値で、所在図の生成と［駐車場に寄る］が読む。
   *    配置図のピンは紙に刷られない画面上の目印なので、紙ごとに消せる方が実務に合う。
   */
  function erasePinAt(key) {
    return (state.kind === 'haichizu') ? hidePinOnSheet(key) : removePoint(key);
  }

  /**
   * 🔒 §30-32-6 3: **その紙だけ**画面のピンを消す（`sheet.pinHidden[key]`）。
   * 🔴 地点は消さない（所在図の主役の印・結線・［駐車場に寄る］はそのまま）。
   * 🔴 抜き出した紙・複製した紙には写る（addSheet が pinHidden も写す）。
   */
  function hidePinOnSheet(key) {
    var c = state.current, sh = curSheet();
    if (!c || !sh || !c.points[key]) return false;
    if (!sh.pinHidden) sh.pinHidden = {};
    /* 🔒 §30-24-2: 同一住所の時は画面のピンが1つ（本拠側）＝両方を消したことにする */
    var keys = c.points.same ? ['home', 'lot'] : [key];
    var n = 0;
    keys.forEach(function (kk) { if (!sh.pinHidden[kk]) { sh.pinHidden[kk] = true; n++; } });
    if (!n) return false;
    renderOverlay();
    sgSyncPinShow();
    Store.autosave(c);
    hint('この紙のマーカーを消しました（［マーカーを表示］で戻せます）', 3500);
    return true;
  }

  /** 🔒 §30-32-6 3: ［マーカーを表示］。その紙で消したピンを全部戻す */
  function showPinsOnSheet() {
    var sh = curSheet();
    if (!sh || !sh.pinHidden) return;
    ['home', 'lot'].forEach(function (kk) { delete sh.pinHidden[kk]; });
    renderOverlay();
    sgSyncPinShow();
    Store.autosave(state.current);
    hint('この紙のマーカーを表示に戻しました', 2500);
  }

  /** 🔒 §30-32-6 3: その紙でピンを消しているか（描画とボタンの出し入れが読む1か所） */
  function pinHiddenOn(sh, key) {
    return !!(sh && sh.pinHidden && sh.pinHidden[key]);
  }

  /** 🔒 §30-32-6 3: ［マーカーを表示］は**消した紙にいる時だけ**出す */
  function sgSyncPinShow() {
    var b = $('hzPinShow');
    if (!b) return;
    var sh = curSheet();
    b.hidden = !(state.kind === 'haichizu'
                 && (pinHiddenOn(sh, 'home') || pinHiddenOn(sh, 'lot')));
  }

  /**
   * 🔒 §30-32-1（2026-09-15 オーナー指示「配置図ガイダンスで駐車場マーカーを
   * 消したい。所在図でも配置図でも、マーカーも消しゴムで普通に消せるように」）:
   * **その地点（`points[key]`）を消す**。
   * 入口は2つ（①画面のピン本体を消しゴムでクリック ②紙のその地点の主役の印・
   * 文字を消しゴムでクリック）だが、消し方はこの1関数。
   *   ・`points[key] = null`（同一住所なら**両方**＝印1つ文字2つで1組なので）
   *   ・所在図・配置図の**全紙**からその地点の役割オブジェクトを取り除く
   *     （`role:'mainmark'` で markRole が一致／`role:'pinlabel'` で地点が一致／
   *      結線と直線距離 `role:'distance'`）
   *   ・ガイダンスの✓・「いま:」・番号の青も引き直す
   * 🔴 確認は出さない（置き直せばよい・§30-32-1 2）。
   * 🔴 ピンは案件の値なので **Ctrl+Z の対象外**（§30-32-1 2）＝履歴には載せない
   *    （載せると「印だけ戻って地点が無い」半端な取り消しになる）。
   * 🔴 配列は差し替えず splice だけ（§23-7-1 / §26-2 注意①）。
   * @param {'home'|'lot'} key
   * @returns true＝消した
   */
  function removePoint(key) {
    var c = state.current;
    if (!c || (key !== 'home' && key !== 'lot')) return false;
    if (!c.points[key]) return false;
    /* 🔒 §30-24-2: 同一住所は「印1つ＋文字2つ」で1組。片方だけ消すと中途半端な
     * 組が残るので、両方まとめて消して same を外す。 */
    var keys = c.points.same ? ['home', 'lot'] : [key];
    var n = 0;
    KINDS.forEach(function (k) {
      sheetsOf(k).forEach(function (sh) {
        var objs = sh.objects || [];
        for (var i = objs.length - 1; i >= 0; i--) {
          var o = objs[i];
          if (!o) continue;
          var mine = (o.role === 'mainmark' && keys.indexOf(o.markRole || 'home') >= 0)
                  || (o.role === 'pinlabel' && o.type === 'text'
                      && keys.indexOf(pinKeyOf(o)) >= 0)
                  /* 結線と直線距離は2地点が揃っている時の物（片方が消えたら要らない） */
                  || (o.role === 'distance');
          if (mine) { objs.splice(i, 1); n++; }
        }
      });
    });
    keys.forEach(function (kk) {
      c.points[kk] = null;
      state.markPick[kk] = null;
      state.mainPolyHead[kk] = null;
    });
    c.points.same = false;
    navPinArm(null);                 // 置きかけだった時は解除（カーソルも戻す）
    if (n && state.editor) state.editor.render();
    refreshPoints();                 // ← ピンの表示（renderOverlay）もここで引き直す
    navRenderPins();                 // ✓ が外れる（ガイダンス①・道具メニュー）
    sgRenderMarks();                 // ▼「印の形と色」の器（同一住所が外れる）
    if (navOnSide()) { sgRenderNums(); sgRenderStatus(); }
    Store.autosave(c);
    hint('マーカーを消しました。置き直せます', 3000);
    navRender();
    return true;
  }

  /**
   * 🔒 §30-24-2: その地点の主役の印（◎・四角・多角形）と文字を紙から取り除く。
   * 🔴 消すのは自動生成物・主役の印だけ（source:'shozaizu' ＋ role で判定）。
   * 🔴 配列は差し替えず splice だけ（§23-7-1 / §26-2 注意①）。
   * @param {Array} keys 'home' / 'lot'
   * @returns 消した紙の一覧（🔒 §30-24-3: 「置き直す紙」でもある。全部消した紙は
   *          白紙と見分けが付かなくなるので、ensureMainLabels へそのまま渡す）
   */
  function clearMainMarks(keys) {
    var hit = [];
    sheetsOf('shozaizu').forEach(function (sh) {
      var objs = sh.objects || [], n = 0;
      for (var i = objs.length - 1; i >= 0; i--) {
        var o = objs[i];
        if (!o || o.source !== 'shozaizu') continue;
        var mine = (o.role === 'mainmark' && keys.indexOf(o.markRole || 'home') >= 0)
               || (o.role === 'pinlabel' && o.type === 'text'
                   && keys.indexOf(pinKeyOf(o)) >= 0);
        if (mine) { objs.splice(i, 1); n++; }
      }
      if (n) hit.push(sh);
    });
    return hit;
  }

  /**
   * 🔒 §30-24-2（2026-09-13 オーナー指示）: 同一住所をやめる。
   * ・`same` を外す
   * ・共有していた印（◎■・四角・多角形）は**押さなかった方の役目**として残す
   *   （markRole を付け替える。せっかく描いた多角形を捨てない）
   * ・押した方の文字は、これから置き直すので取り除く
   * @param {'home'|'lot'} pressed 押した方（これから新しく置く地点）
   */
  function leaveSamePoint(pressed) {
    var c = state.current;
    if (!c || !c.points.same) return;
    var keep = (pressed === 'home') ? 'lot' : 'home';
    var shared = markOf('home');          // 同一の間の印の設定（本拠側＝1つの値）
    if (state.editor) state.editor.snapshot();
    var n = 0;
    sheetsOf('shozaizu').forEach(function (sh) {
      var objs = sh.objects || [];
      for (var i = objs.length - 1; i >= 0; i--) {
        var o = objs[i];
        if (!o || o.source !== 'shozaizu') continue;
        if (o.role === 'mainmark') { o.markRole = keep; n++; }
        else if (o.role === 'pinlabel' && o.type === 'text' && pinKeyOf(o) === pressed) {
          objs.splice(i, 1); n++;
        }
      }
    });
    c.points.same = false;
    if (c.points[keep]) c.points[keep].mark = { shape: shared.shape, color: shared.color };
    /* 押した方には印が1つも無い（全部 keep へ渡した）ので、多角形のままにしない */
    if (c.points[pressed]) {
      c.points[pressed].mark = {
        shape: (shared.shape === 'polygon') ? 'circle' : shared.shape,
        color: shared.color
      };
    }
    if (n && state.editor) state.editor.commit();
  }

  function navOkMarkers() {
    var c = state.current;
    if (!c || !c.points.home || !c.points.lot) return;
    navPinArm(null);
    navGo(2);
  }

  /* ---- ②③④ 所在図 ---- */

  /** 所在図が中身を持っているか（自動生成物が残っているか） */
  function navHasShozaizu() {
    var objs = objectsOf('shozaizu');
    return objs.some(function (o) { return o.source === 'shozaizu'; });
  }

  /** ②［確認する］→ 生成して③へ */
  function navRunShozaizu() {
    if (!state.current) return;
    navBusy(true);
    navSetStatus('所在図を作っています…');
    /* 🔒 §18-x-4: ③の確認は**白地**でないとできない（線画が写真に埋もれる）。
     * 所在図タブの［地図OFF］を自動で入れる。手で戻すのは自由。
     * 🔴 下敷きの濃さはシートごとに保存されるので、配置図タブ側は影響を受けない。 */
    if (state.kind !== 'shozaizu') switchKind('shozaizu');
    setUnderlayOffState(true);
    // 2地点が余白付きで収まる倍率への自動調節は runShozaizu → frameShozaizu が行う
    runShozaizu(true).then(function (res) {
      navGo(3);
      navBusy(false);
      // 🔒 §28-4: ③は左面なので、結果の一言は左面の状態欄にも入る（navSetStatus）
      navSetStatus(navSzResultText(res));
    });
  }

  /**
   * ②［後にする］。🔒 §18-f: **確認を省くだけで所在図は裏で作る**
   * （⑪で所在図の欄が空にならないように）。失敗しても先へは進める。
   */
  function navSkipShozaizu() {
    if (!state.current) return;
    if (navHasShozaizu()) {              // すでに作ってあるなら作り直さない
      navGo(5);
      // 🔒 §30-1: 番号は図ごとになった（⑫＝配置図の⑧ 表示・保存）
      navSetStatus('所在図はすでに作られています（配置図の⑧ 表示・保存で確認できます）');
      return;
    }
    navBusy(true);
    navSetStatus('所在図を裏で作っています…（確認は後でできます）');
    runShozaizu(true).then(function (res) {
      navGo(5);
      navBusy(false);
      // 🔒 §30-1: 番号は図ごと（⑫＝配置図の⑧／②＝所在図の②）
      navSetStatus(res
        ? '所在図は裏で作りました（' + navSzResultText(res)
          + '）。配置図の⑧ 表示・保存で確認できます'
        : '⚠ 所在図は作れませんでした。所在図ガイダンスの②へ戻って'
          + '［確認する］で作り直せます');
    });
  }

  function navSzResultText(res) {
    if (!res || !res.stats) return $('szResult').textContent || '';
    var s = res.stats;
    /* 🔒 §22-as: 誘導③でも同じ案内文を出す（'wide' は従来どおり別枠・扱わない） */
    var warn = (s.osmError === 'wide') ? '' : szNameWarningText(s);
    return '道路 ' + s.roads + ' / 鉄道 ' + s.rails + ' / 名称 ' + s.annoKept
      + ' を生成しました' + (s.over2km ? '　⚠ 直線距離が 2km を超えています' : '') + warn;
  }

  /* 🔒 §28-8 Step 2: 旧③の［所在図確定／プレビュー表示］（navFixShozaizu）は削除した。
   * 枠は②の［枠を決定］で決まり（§28-3）、④のプレビューは Step 3 が入れる。
   * 書き出し直前の枠合わせ（syncFrameFromView / ensureFrames）は
   * pagesForExport / navEnterFinish が従来どおり行うので抜けは無い。 */

  /* ---- ⑪ 駐車位置ラベル（labelBlock） ---- */

  /* 🔒 §22-ab: 駐車位置ラベルの入力行は**ガイダンス⑪と道具メニューの小ウィンドウの2か所**。
   * 定義をここ1つに集約し、ID の接頭辞（'lb'=⑪ / 'pl'=小ウィンドウ）だけを変える。
   * 🔴 表をコピーして2か所に置くと、項目を足した時に片方だけ直す事故が起きる。 */
  var LABEL_ROWS = [
    { key: 'Len', label: '長さ',         unit: 'm', on: true,  ph: '例）5',   mode: 'decimal' },
    { key: 'Wid', label: '幅',           unit: 'm', on: true,  ph: '例）2.4', mode: 'decimal' },
    { key: 'No',  label: '駐車枠番号',   unit: '番', on: false, ph: '例）5',   mode: 'numeric',
      lineLabel: '駐車枠' },
    { key: 'Ht',  label: '入庫口の高さ', unit: 'm', on: false, ph: '例）2',   mode: 'decimal' }
  ];

  /** 定型4行の HTML を作る。pre は ID の接頭辞（'lb' / 'pl'） */
  function labelRowsHTML(pre) {
    return LABEL_ROWS.map(function (r) {
      return '<label class="nav-lb">'
        + '<input type="checkbox" id="' + pre + r.key + 'On"'
        + (r.on ? ' checked' : '') + '>'
        + '<span class="lb-k">' + r.label + '</span>'
        + '<input type="text" id="' + pre + r.key + '" class="num" inputmode="'
        + r.mode + '" placeholder="' + r.ph + '">'
        + '<span class="unit">' + r.unit + '</span>'
        + '</label>';
    }).join('');
  }

  /** 自由記入の行を1つ足す。wrapId は 'lbCustom' / 'plCustom' */
  function addCustomRow(wrapId) {
    var wrap = $(wrapId);
    var row = document.createElement('label');
    row.className = 'nav-lb';
    row.innerHTML = '<input type="checkbox" checked>'
      + '<input type="text" class="lb-name" placeholder="項目名">'
      + '<input type="text" class="lb-val" placeholder="値（単位も）">'
      + '<button type="button" class="lb-del" title="この行を消す">✕</button>';
    row.querySelector('.lb-del').addEventListener('click', function (e) {
      e.preventDefault();
      wrap.removeChild(row);
    });
    wrap.appendChild(row);
    return row;
  }

  /**
   * 凡例 → ラベルの行。1行目は見出し「保管場所」。
   * 🔒 §18-f: 単位は数値欄の右に固定表示し、**文字列にも自動で付ける**
   * （オーナー提供の見本 assets/guide/label.png の文言に合わせる）
   * pre = ID の接頭辞（'lb'=ガイダンス⑪ / 'pl'=道具メニューの小ウィンドウ・🔒 §22-ab）
   */
  function labelLinesFrom(pre) {
    var lines = ['保管場所'];
    LABEL_ROWS.forEach(function (r) {
      var on = $(pre + r.key + 'On'), inp = $(pre + r.key);
      if (!on || !inp || !on.checked) return;
      var v = inp.value.trim();
      if (!v) return;
      lines.push((r.lineLabel || r.label) + '：' + v + r.unit);
    });
    Array.prototype.forEach.call($(pre + 'Custom').querySelectorAll('.nav-lb'),
      function (row) {
        var on = row.querySelector('input[type="checkbox"]');
        var nm = row.querySelector('.lb-name').value.trim();
        var vl = row.querySelector('.lb-val').value.trim();
        if (!on.checked || (!nm && !vl)) return;
        lines.push(nm ? (nm + '：' + vl) : vl);
      });
    return lines;
  }

  /** 置いてある塊ラベルの数（⑪の状態の一言・🔒 §29-1 ⑪） */
  function navLabelCount() {
    return objectsOf('haichizu').filter(function (o) {
      return o.type === 'labelBlock';
    }).length;
  }

  /* ---- ⑫ 表示・保存 ---- */

  /**
   * ガイダンスから出すプレビュー。**左面（ガイダンス）を隠さない**置き方にする。
   * 🔒 §29 Step 7: 位置の基準は小ウィンドウの右端から**地図領域の左端**へ移した
   * （器が左面になったので、地図の左端＝左面の右端になる）。
   */
  function navShowPreview(only) {
    if (!state.current) return;
    /* 🔒 §30-27-1 1: プレビューは**1つの画面**。ここは「その図から見せる」だけを頼む。
     * 🔒 §30-13-3: 所在図⑧から出した時だけ下部の行き先ボタン列を付ける。 */
    openPreview({ kind: only, foot: only === 'shozaizu', nav: true });
  }

  /** かぶせの置き方だけ（中身は呼んだ側が入れる）。🔴 まとめ・ページ送りも同じ置き方 */
  function navPreviewFrame() {
    state.navPreview = true;
    var box = $('exPreviewBox');
    var wrap = document.querySelector('.map-wrap');
    sideFront(true);
    box.classList.add('is-nav');
    // 地図領域の左端まで空ける（左面の幅が変わっても崩れない）
    box.style.setProperty('--nav-gap',
      Math.round(wrap ? wrap.getBoundingClientRect().left : 360) + 'px');
  }

  /* ---- 所在図と配置図をまとめて（🔒 §30-18-6 2・2026-09-13 オーナー指示）----
   * トグル2択: 「所在図と配置図を1枚にまとめる」／「別々で表示」。
   * 🔴 まとめられる条件＝所在図・配置図が**1枚ずつ**で**紙の向きが同じ**。
   *    満たさない時は「別々で表示」に固定して一言を出す（判定はここ1か所）。 */

  /** いまの紙の顔ぶれ（まとめられるか・どの紙か）。🔴 数え方は pagesForExport 1本 */
  function sgComboInfo() {
    var pages = pagesForExport();
    var sz = pages.filter(function (p) { return p.kind === 'shozaizu'; });
    var hz = pages.filter(function (p) { return p.kind === 'haichizu'; });
    return {
      pages: pages, a: sz[0] || null, b: hz[0] || null,
      ok: sz.length === 1 && hz.length === 1 && sz[0].orient === hz[0].orient
    };
  }

  /* 🔒 §30-27-1 7: 旧「まとめる／別々」の2択（comboMode / state.comboMode /
   * sgComboSync / comboPreview / showCombinedPreview / showPagerPreview / comboSavePDF）は
   * 廃止した。まとめはプレビュー画面の**最後の札**（openPreview の combo）と、
   * PDF・画像の窓の**チェック1つ**（exPick の one）になった。
   * 🔴 「まとめられるか」の判定は sgComboInfo().ok だけ（従来と同じ1か所）。 */

  /**
   * 🔒 §30-27-1 2: プレビューの道しるべの行を引き直す。
   * ［‹］→ 図のトグル（紙が無い側は選べない）→ その図の紙の札 →
   * 条件を満たす時だけ「まとめ（1枚）」の札 →［次のページ ›］。
   */
  function exNavRender() {
    var pg = state.exPager, nav = $('exPreviewNav');
    if (!nav) return;
    if (!pg) { nav.hidden = true; return; }
    nav.hidden = false;
    var last = exLastIndex();
    $('exNavPrev').disabled = (pg.i <= 0);
    $('exNavNext').disabled = (pg.i >= last);
    // 図のトグル（🔴 どちらの図に紙があるかは pages の中身だけで決まる）
    var has = {};
    KINDS.forEach(function (k) {
      has[k] = pg.pages.some(function (p) { return p.kind === k; });
    });
    var sw = $('exKindSw');
    sw.checked = (pg.kindNow === 'haichizu');
    sw.disabled = !(has.shozaizu && has.haichizu);
    // その図の紙の札（いま見ている紙が濃い）
    var tabs = $('exNavTabs');
    tabs.innerHTML = '';
    pg.pages.forEach(function (p, i) {
      if (p.kind !== pg.kindNow) return;
      var t = document.createElement('button');
      t.type = 'button';
      t.className = 'ex-pager-tab' + (i === pg.i ? ' is-now' : '');
      t.textContent = String(p.index);
      t.title = p.kindJa + ' ' + p.index + '/' + p.total;
      t.addEventListener('click', function () { exPagerGo(i); });
      tabs.appendChild(t);
    });
    // 🔒 §30-27-1 5: 「まとめ（1枚）」は条件を満たす時だけ、札の**最後**に付く
    if (pg.combo) {
      var c = document.createElement('button');
      c.type = 'button';
      c.className = 'ex-pager-tab' + (exIsCombo(pg.i) ? ' is-now' : '');
      c.textContent = 'まとめ（1枚）';
      c.title = '所在図と配置図を1枚にまとめた面';
      c.addEventListener('click', function () { exPagerGo(pg.pages.length); });
      tabs.appendChild(c);
    }
  }

  /** まとめ（1枚）の面を描く（🔴 描き方は Exporter.renderCombined 1か所） */
  function exRenderCombo(body, pg) {
    var inf = pg.comboInfo, r;
    try {
      // 🔒 §30-34-1 3: まとめの面にも同じトグルが効く（各面の renderSheet へ通る）
      r = Exporter.renderCombined({ a: inf.a, b: inf.b, dpi: 96,
                                    showFrames: state.exOtherFrames });
    } catch (e) {
      var msg = document.createElement('p');
      msg.className = 'ex-preview-foot-msg';
      msg.textContent = '失敗しました: ' + (e.message || e);
      body.appendChild(msg);
      return;
    }
    /* 🔒 §30-25-10 1: まとめ描きは**見るだけ**（文字を動かす層は付けない）。
     * 🔒 §30-25-16: 案内（文字だけ動かせます）も出さない。 */
    exTextTip(false);
    var fig = document.createElement('figure');
    var cap = document.createElement('figcaption');
    var sz = r.parts[0] && r.parts[0].r;
    cap.textContent = '所在図と配置図をまとめて（'
      + (r.orient === 'landscape' ? 'A4横' : 'A4縦') + ' 1ページ）'
      + (sz && sz.scaleN ? '　所在図 1:' + sz.scaleN.toLocaleString() : '');
    var img = new Image();
    img.src = r.canvas.toDataURL('image/png');
    fig.appendChild(cap);
    fig.appendChild(img);
    body.appendChild(fig);
    /* 🔒 §30-26-3 4 → §30-34-1 3: まとめ描きにも同じトグルが効く。重ねる層は廃止し、
     * **それぞれの面の renderSheet** が自分の図の枠と札を描く（上の showFrames）。 */
  }

  /**
   * 🔒 §30-27-1 2: いま見ている面を1つだけ描く（画像は1度作ったら pg.url に控える）。
   * 🔴 道しるべの行・案内・［PDF］［画像］の帯は**面が変わるたびにここで引き直す**。
   */
  function exPagerRender() {
    var pg = state.exPager;
    if (!pg) return;
    var body = $('exPreviewBody');
    body.innerHTML = '';
    exPlacersReset();             // 🔒 §30-25-10: 前回の層の置き直しは捨てる
    exFrameSwitchSync();          // 🔒 §30-26-3: どの面でも同じトグル
    exNavRender();                // 🔒 §30-27-1 2: 道しるべの行
    $('exPreviewBar').hidden = false;   // 🔒 §30-27-1 6: ［PDF］［画像］は常時
    if (exIsCombo(pg.i)) { exRenderCombo(body, pg); return; }

    var p = pg.pages[pg.i];
    if (!p) return;
    if (!pg.url[pg.i]) {
      var r = Exporter.renderSheet({
        objects: p.objects, frame: p.frame, orient: p.orient,
        attributions: p.attributions, noScale: p.noScale, dpi: 96,
        // 🔒 §30-34-1 3: 他の枠の範囲＋番号の札は**紙の絵そのもの**に入る
        frameMarks: p.frameMarks, showFrames: state.exOtherFrames
      });
      pg.url[pg.i] = r.canvas.toDataURL('image/png');
      pg.scale[pg.i] = r.scaleN;
      // 🔒 §30-25-10: 文字の箱（textBoxes）も控える＝札で戻っても掴める
      pg.r[pg.i] = r;
    }
    var fig = document.createElement('figure');
    var cap = document.createElement('figcaption');
    // 🔒 §18-ae: 縮尺を持たない図（配置図）には比率を出さない
    cap.textContent = p.kindJa + ' ' + p.index + '/' + p.total
      + '（' + (p.orient === 'landscape' ? 'A4横' : 'A4縦') + '）'
      + (pg.scale[pg.i] ? '  1:' + pg.scale[pg.i].toLocaleString() : '');
    var img = new Image();
    img.src = pg.url[pg.i];
    fig.appendChild(cap);
    fig.appendChild(img);
    // 🔒 §30-25-16: 案内は見出しのすぐ下の行（紙の器には足さない）
    exTextTip(true);
    body.appendChild(fig);
    /* 🔒 §30-25-10: 文字だけ動かす層。描き直したら**その面の控えを更新**する
     * （札で戻ってきた時に古い画像が出ないように）。 */
    var idx = pg.i;
    exTextLayer(fig, img, p, pg.r[idx], function (url, r2) {
      pg.url[idx] = url;
      pg.r[idx] = r2;
      pg.scale[idx] = r2.scaleN;
    });
    /* 🔒 §30-26-3 → §30-34-1 3: 他の紙の枠と番号の札は**紙の絵そのもの**に入る
     * （上の renderSheet の frameMarks / showFrames）。重ねる層はもう無い。 */
  }

  /**
   * 面を移る（札・トグル・‹ ›・← → から。範囲外は何もしない）。
   * 🔒 §30-27-1 2: 次のページは**所在図の最後から配置図の1へ続く**（並びが
   *    pagesForExport のままなので、番号を1つ進めるだけでそうなる）。
   * 🔒 §30-27-1 3: 図が変わった時（自動でも手でも）だけ約3秒の帯を出す。
   */
  function exPagerGo(i) {
    var pg = state.exPager;
    if (!pg || i < 0 || i > exLastIndex() || i === pg.i) return;
    var before = pg.kindNow;
    pg.i = i;
    var now = exKindAt(i);
    if (now) pg.kindNow = now;        // まとめの面は直前の図のまま
    exPagerRender();
    if (now && before && now !== before) exKindNoteShow(now);
  }

  /* ================= 🔒 §30-27-2: PDF・画像の小さな窓（出す紙を選ぶ） =================
   * オーナー指示 2026-09-14:「PDF 出力はボタンで小さいウィンドウ。初期状態はいま
   *   表示されている項目のみチェック。所在図と配置図でチェック、どちらもチェック
   *   すれば一括で1つの PDF」。
   * 🔴 ［PDF］［画像］はこの窓を開くだけ＝**直接「全部の紙」を出す経路は無い**（出口は1つ）。
   * 🔴 判定は紙の id（data-sheet）と図の種類（data-kind）だけ（表示文字では分岐しない）。
   * 🔴 件数の数え方は §22 のまま（書き出し1回で1件）。保存は saveBlob 1本（§21-1）。 */

  /** チェックされている枚数（まとめは1） */
  function exPickCount() {
    var pk = state.exPick;
    if (!pk) return 0;
    if (pk.one) return 1;
    return pk.pages.filter(function (p) { return !!pk.sel[p.sheetId]; }).length;
  }

  /** 開く。mode='pdf'（PDF）／'png'（画像） */
  function exPickOpen(mode) {
    if (!state.current) return;
    var list = pagesForExport().filter(function (p) { return !!p.frame; });
    var inf = sgComboInfo();          // 🔴 まとめられるかの判定は1か所
    if (!list.length) {
      hint('書き出せる図がありません。先に図を作ってください。', 3500);
      return;
    }
    var pdf = (mode !== 'png');
    var pk = { mode: pdf ? 'pdf' : 'png', pages: list, combo: !!inf.ok,
               comboInfo: inf, sel: {}, one: false };
    state.exPick = pk;
    /* 🔒 §30-27-2 2: 最初は**いま見ている紙だけ**にチェック。
     * プレビューを出していない時（上部バーの［書き出し］から）は編集中の紙。 */
    var pg = state.exPager, open = !$('exPreviewBox').hidden;
    if (open && pg && exIsCombo(pg.i) && pk.combo) {
      pk.one = true;
    } else {
      var cur = curSheet();
      var id = (open && pg && pg.pages[pg.i]) ? pg.pages[pg.i].sheetId
             : (cur ? cur.id : null);
      var hit = list.filter(function (p) { return p.sheetId === id; }).length;
      pk.sel[hit ? id : list[0].sheetId] = true;
    }
    // 🔴 見出しと実行ボタンの文は「どちらの窓か」で決まる（mode 1か所）
    $('exPickTitle').textContent = pdf ? 'PDFにして保存' : '画像を保存';
    $('exPickGo').textContent = pdf ? 'PDFにして保存' : '画像を保存';
    $('exPickNote').hidden = pdf;     // 🔒 §30-27-2 4: 注意書きは画像の時だけ
    $('exPickMsg').textContent = '';
    $('exPick').hidden = false;
    exPickRender();
    $('exPickGo').focus();
  }

  function exPickClose() {
    $('exPick').hidden = true;
    state.exPick = null;
  }

  /** 窓の中身を引き直す（区画の見出し・紙の札・まとめ・実行ボタンの可否） */
  function exPickRender() {
    var pk = state.exPick;
    if (!pk) return;
    var body = $('exPickBody');
    body.innerHTML = '';
    KINDS.forEach(function (k) {
      var rows = pk.pages.filter(function (p) { return p.kind === k; });
      if (!rows.length) return;       // 🔒 §30-27-2 1: 白紙・紙の無い図は出さない
      var sec = document.createElement('div');
      sec.className = 'ex-pick-sec';
      sec.setAttribute('data-kind', k);
      // 区画の見出し＝その図の紙を全部（半端な時は indeterminate）
      var h = document.createElement('label');
      h.className = 'ex-pick-h';
      var ha = document.createElement('input');
      ha.type = 'checkbox';
      ha.setAttribute('data-all', k);
      var on = rows.filter(function (p) { return !!pk.sel[p.sheetId]; }).length;
      ha.checked = (on === rows.length);
      ha.indeterminate = (on > 0 && on < rows.length);
      ha.addEventListener('change', function () {
        var v = this.checked;
        rows.forEach(function (p) {
          if (v) pk.sel[p.sheetId] = true; else delete pk.sel[p.sheetId];
        });
        if (v) pk.one = false;        // 🔒 §30-27-2 3: 紙を入れると「まとめる」は外れる
        exPickRender();
      });
      h.appendChild(ha);
      h.appendChild(document.createTextNode(KIND_JA[k]));
      sec.appendChild(h);
      rows.forEach(function (p) {
        var lb = document.createElement('label');
        lb.className = 'ex-pick-i';
        var cb = document.createElement('input');
        cb.type = 'checkbox';
        cb.setAttribute('data-sheet', p.sheetId);
        cb.setAttribute('data-kind', p.kind);
        cb.checked = !!pk.sel[p.sheetId];
        cb.addEventListener('change', function () {
          if (this.checked) { pk.sel[p.sheetId] = true; pk.one = false; }
          else delete pk.sel[p.sheetId];
          exPickRender();
        });
        var no = document.createElement('b');
        no.className = 'ex-pick-no';
        no.textContent = String(p.index);
        var sub = document.createElement('span');
        sub.className = 'ex-pick-sub';
        // 🔴 1:N は Exporter.scaleFor 1か所（描かずに出す・§30-15-5 規則2）
        var n = p.noScale ? null : Exporter.scaleFor(p.frame, p.orient);
        sub.textContent = (p.orient === 'landscape' ? 'A4横' : 'A4縦')
          + (n ? '　1:' + n.toLocaleString() : '');
        lb.appendChild(cb);
        lb.appendChild(no);
        lb.appendChild(sub);
        sec.appendChild(lb);
      });
      body.appendChild(sec);
    });
    /* 🔒 §30-27-2 3: 「所在図と配置図を1枚にまとめる」は窓の中の1つのチェック。
     * 条件（1枚ずつ・同じ向き）を満たす時だけ選べる。 */
    var cl = document.createElement('label');
    cl.className = 'ex-pick-combo' + (pk.combo ? '' : ' is-off');
    var cc = document.createElement('input');
    cc.type = 'checkbox';
    cc.setAttribute('data-combo', '1');
    cc.checked = !!pk.one;
    cc.disabled = !pk.combo;
    cc.addEventListener('change', function () {
      pk.one = this.checked;
      if (pk.one) pk.sel = {};        // 選ぶと他の紙のチェックは外れる
      exPickRender();
    });
    cl.appendChild(cc);
    cl.appendChild(document.createTextNode('所在図と配置図を1枚にまとめる'));
    if (!pk.combo) {
      var why = document.createElement('span');
      why.className = 'ex-pick-sub';
      why.textContent = '　（所在図・配置図が1枚ずつで、紙の向きが同じ時だけ選べます）';
      cl.appendChild(why);
    }
    body.appendChild(cl);
    // 🔒 §30-27-2 6: 何もチェックしていない時は押せない＋一言
    var n2 = exPickCount();
    $('exPickGo').disabled = !n2;
    $('exPickWhy').hidden = !!n2;
  }

  /** ［PDFにして保存］／［画像を保存］。🔴 保存口は saveBlob 1本（§21-1） */
  function exPickRun() {
    var pk = state.exPick;
    if (!pk || !exPickCount()) return;
    $('exPickGo').disabled = true;
    if (pk.one) {
      // 🔒 §30-27-2 3: まとめは buildCombinedPDF（1ページ・別口）
      FSave.prepare();                 // 🔒 §21-2: 権限はクリックの中で取る
      $('exPickMsg').textContent = 'PDF を作成しています…';
      setTimeout(function () {
        var blob;
        try {
          // 🔒 §30-34-1 1: まとめの PDF にも他の枠の範囲＋番号の札を刷る
          blob = Exporter.buildCombinedPDF({ a: pk.comboInfo.a, b: pk.comboInfo.b,
                                             showFrames: state.exOtherFrames })
                   .doc.output('blob');
        } catch (e) {
          exPickDone('失敗しました: ' + (e.message || e), false);
          return;
        }
        // 🔒 §30-18-6 2 / §30-32-3: まとめの PDF は図と紙の代わりに「まとめ」
        saveBlob(blob, exportFileName(null, 'combo', 'pdf')).then(function (r) {
          exPickDone('PDF を保存しました（1 ページ・'
            + (blob.size / 1048576).toFixed(2) + ' MB）。' + saveWhere(r), true);
        });
      }, 30);
      return;
    }
    /* 🔴 並びは pagesForExport のまま（所在図→配置図・番号順）＝チェックで絞るだけ。
     * PDF は1つにまとめて（1紙1ページ・§24-3）、画像は1枚ずつ PNG（§30-27-2 4）。 */
    var pages = pk.pages.filter(function (p) { return !!pk.sel[p.sheetId]; });
    $('exPickMsg').textContent =
      (pk.mode === 'pdf' ? 'PDF' : '画像') + ' を作成しています…';
    var fn = (pk.mode === 'pdf') ? exportPDF : exportPNG;
    fn(function (m, ok) { exPickDone(m, ok); }, null, pages);
  }

  /**
   * 書き出しの結果を出す。
   * 🔒 §30-31-4（2026-09-15 オーナー指示）: **保存できたら紙を選ぶ窓を閉じる**
   * （プレビュー画面は開いたまま・結果の一言は帯 #exBarMsg に出す）。
   * 🔴 失敗した時は窓を閉じない＝理由は窓の中（#exPickMsg）に出して、
   *    もう一度押せるように［PDFにして保存］を戻す。
   * 🔴 一言の文言は exportPDF / exportPNG の finish() 1か所（ここでは作らない）。
   */
  function exPickDone(m, ok) {
    if (ok) {
      exPickClose();
      if ($('exBarMsg')) $('exBarMsg').textContent = m;
      /* プレビューを開かずに（配置図⑧の［PDFにして保存］から）出した時は帯が
       * 見えないので、同じ一言をその場の案内としても出す。 */
      if ($('exPreviewBox').hidden) hint(m, 6000);
    } else {
      if ($('exPickMsg')) $('exPickMsg').textContent = m;
      if ($('exPickGo')) $('exPickGo').disabled = !exPickCount();
    }
    /* 🔒 §30-27-1 7: 配置図⑯（PDFにして保存）の済みは従来どおり state.nav.saved。
     * 🔴 印を付けるのは**配置図⑫（step 12）にいる時だけ**（所在図から出した
     *    書き出しで⑯が済みになってしまわないように）。 */
    if (ok && state.nav && state.nav.step === 12 && !state.nav.saved) {
      state.nav.saved = true;
      navRender();
    }
  }

  /**
   * 🔒 §30-13-3: 所在図プレビューの下部ボタン。
   * 🔴 中身は**既存の関数をそのまま呼ぶ**（§28-1 ④）。新しい保存経路は作らない。
   * 🔒 §30-27-1 6: ［PDF保存］［画像保存］は帯（#exPreviewBar → exPickOpen）へ移した
   *    ＝ここは行き先のボタンだけ。
   *   配置図ガイダンスへ進む … プレビューを閉じて配置図①（段5）へ
   *   案件一覧に戻る       … ⑫の［案件一覧に戻る］と同じ backToList
   *   戻る                 … プレビューを閉じるだけ（④のまま・頭の×と同じ）
   */
  function exFootAct(act) {
    switch (act) {
      case 'toHz': closeExportPreview(); navGo(5); break;
      case 'toList': backToList(); break;
      case 'back': closeExportPreview(); break;
    }
  }

  /**
   * ⑫へ入った時。枠を確定してプレビューを出す。
   * 🔒 §30-31-3 2: 「提出前チェック」の一覧（旧 #sgChkBox / sgRenderCheck）は廃止。
   *    この段は［プレビュー］［PDFにして保存］の2ボタンだけ（§30-27-1 7）。
   */
  function navEnterFinish() {
    var c = state.current;
    if (!c) return;
    syncFrameFromView();
    ensureFrames();
    // 🔒 §30-18-6 1: ⑧のプレビューと保存は**配置図だけ**
    navShowPreview('haichizu');
  }

  /* 🔒 §30-27-1 7: 旧 navSave（⑫の下部から「配置図の紙を全部」出す経路）は廃止した。
   * ⑫の［PDFにして保存］（#sgSavePdf）は exPickOpen('pdf') ＝**出す紙を選ぶ窓**を開く。
   * ⑯の済み（state.nav.saved）は exPickDone が付ける（印の付け方は従来と同じ）。 */

  /* ---- 描画 ---- */

  /** 🔒 §29 Step 7: 器は左面ひとつだけ（小ウィンドウは全廃） */
  function navRender() {
    if (!state.nav) return;
    sgRender();
  }

  /**
   * 段の「状態の一言」（左面 #sgStatus）。生成・保存などの**処理側はここへ書く**。
   * 🔴 処理側が「どこへ書くか」を判断しない（出し先は1か所）。
   */
  function navSetStatus(msg) {
    var el = $('sgStatus');
    if (el) el.textContent = msg;
  }

  /* 🔒 2026-09-06: マーカー設置ボタンは**2か所**にある
     （道具メニューの一番上 ／ 左面のガイダンス①・§28-2）。
     どこから押しても同じ navPinArm() を呼ぶので、見た目も必ず両方を揃える。 */
  var PIN_BTN = {
    home: ['sidePinHome', 'sgPinHome'],
    lot:  ['sidePinLot',  'sgPinLot']
  };

  function navRenderPins() {
    var c = state.current, has = c ? c.points : {};
    // 🔒 §25-1: 図の上の呼び名は「使用の本拠」（index.html の初期文言と揃える）
    ['home', 'lot'].forEach(function (key) {
      var txt = (has[key] ? '✓ ' : '')
        + (key === 'home' ? '使用の本拠' : '駐車場') + 'マーカー設置';
      PIN_BTN[key].forEach(function (id) {
        var b = $(id);
        if (!b) return;
        b.classList.toggle('is-armed', state.pinPlace === key);
        b.textContent = txt;
      });
    });
    /* 🔒 §30-22-1 6: ［使用の本拠と駐車場が同一住所］は2行のボタンなので
     * textContent を書き換えない（1行目だけに✓を付ける）。 */
    /* 🔒 §30-28-2 1: ［同一住所］もガイダンス①と道具メニューの2か所（見た目は同じ） */
    ['sgSame', 'sideSame'].forEach(function (id) {
      var sb = $(id);
      if (!sb) return;
      sb.classList.toggle('is-armed', state.pinPlace === 'same');
      var t = sb.querySelector('b');
      if (t) {
        t.textContent = (has.same ? '✓ ' : '') + '使用の本拠と駐車場が同一住所';
      }
    });
  }

  function navBothPins() {
    var c = state.current;
    return !!(c && c.points.home && c.points.lot);
  }

  /* ===== 🔒 §28-14 ①-4（2026-09-07 オーナー指示）: マーカーの形と色 =====
   * 形は**今ある2種**（◎ 二重丸／■ 四角に斜線＝ §25-4-a の markStyle）、
   * 色は**今ある3種**（Editor.MARK.colors の 赤・オレンジ・黄）。新しい形・色は作らない。
   * データ: points[key].mark = {shape:'circle'|'rect', color:'red'|'orange'|'yellow'}。
   * 🔴 mark を持たない旧案件は**従来どおり**（案件の markStyle ＋ MARK.kinds の色）。
   * 🔴 値の出どころはガイダンス①**だけ**（設定盤の「主役の印」は撤去・§18-r-4）。
   * 🔴 画面のピン（renderOverlay）と紙の印（role:'mainmark' の四角・所在図の◎）が
   *    同じこの値を見る。 */
  /* 🔒 §30-22-1 4 (c)（2026-09-13 オーナー指示）: **「印なし（文字だけ）」を足した**
   * （多角形で土地の形を囲んだ時など、丸や四角の印が邪魔になる場合のため）。
   * 'none' は印を描かず「使用の本拠」の文字だけを置く。 */
  /* 🔒 §30-24-1（2026-09-13 オーナー指示）: **多角形も印の種類の1つ**。
   * 'polygon' は◎■を描かず（画面のピンの丸・紙の四角・所在図の◎の全部）、
   * 文字（「使用の本拠」「駐車場」）だけが残る。
   * 🔴 pick:false ＝ ①の形のボタンには出さない（押して選ぶ物ではなく、
   *    ［多角形で描く］で描いた結果そうなる状態）。 */
  var MARK_SHAPES = [
    { key: 'circle',  sym: '◎', ja: '◎ 二重丸' },
    { key: 'rect',    sym: '■', ja: '■ 四角に斜線' },
    { key: 'none',    sym: 'ー', ja: '印なし（文字だけ）' },
    { key: 'polygon', sym: '⬠', ja: '多角形', pick: false }
  ];

  /** 色の key が今ある3種のどれか（一覧は Editor.MARK.colors の1か所） */
  function markColorOk(k) {
    var cs = (Editor.MARK && Editor.MARK.colors) || [];
    for (var i = 0; i < cs.length; i++) { if (cs[i].key === k) return true; }
    return false;
  }

  /**
   * その地点のマーカーの形と色。
   * 優先順: ①案件の points[key].mark ②まだ置いていない時の選択（state.markPick）
   *         ③従来の既定（案件の markStyle ＋ Editor.MARK.kinds の色）＝後方互換
   */
  function markOf(key) {
    var c = state.current;
    var kinds = (Editor.MARK && Editor.MARK.kinds) || {};
    var def = kinds[key] || kinds.home || { color: 'red' };
    var m = (c && c.points[key] && c.points[key].mark) || state.markPick[key] || null;
    /* 🔒 §30-22-1 4 (c): 形は MARK_SHAPES の key（'circle'/'rect'/'none'）1か所で判定する */
    var ok = false;
    if (m) MARK_SHAPES.forEach(function (s) { if (s.key === m.shape) ok = true; });
    var shape = ok ? m.shape : ((c && c.markStyle === 'rect') ? 'rect' : 'circle');
    var color = (m && markColorOk(m.color)) ? m.color : def.color;
    /* 🔒 §30-25-37 1: 印の大きさ（既定 1・0.5〜3）。旧案件は持たない＝1。
     * 🔴 上下限の出どころは Editor.clampMarkScale 1か所（ここには書かない）。 */
    var scale = Editor.clampMarkScale ? Editor.clampMarkScale(m && m.scale) : 1;
    /* 🔒 §30-31-1 2: ■（四角の印）の**縦横**（実距離 m）。
     * 🔴 無い時の既定は Editor.markRectDims（基準 MARK.kinds × 倍率）1か所。
     *    持っている案件はその値がそのまま真実＝長方形が開き直しでも保たれる。 */
    var dim = Editor.markRectDims ? Editor.markRectDims(key, scale)
            : { w_m: def.w_m || 10, h_m: def.h_m || 10 };
    return { shape: shape, color: color, scale: scale,
             w_m: markDim(m && m.w_m, dim.w_m),
             h_m: markDim(m && m.h_m, dim.h_m),
             /* 🔒 §30-35-3 2: ■の中心とピンの**ずれ**（東・北の実距離 m・既定 0）。
              * 辺つまみで掴んだ辺だけ伸ばすと中心がピンから外れるので、その分を
              * 案件が持つ（旧案件は持たない＝0）。 */
             dx_m: markOff(m && m.dx_m),
             dy_m: markOff(m && m.dy_m) };
  }

  /** 🔒 §30-31-1 2: 保存された縦横（m）を読む（数値でなければ既定）。丸めは3桁 */
  function markDim(v, def) {
    var n = Number(v);
    return (isFinite(n) && n > 0) ? Math.round(n * 1000) / 1000 : def;
  }

  /** 🔒 §30-35-3 2: 保存されたずれ（m）を読む（数値でなければ 0）。丸めは3桁。
   *  🔴 縦横（markDim）と違い **0 も負も正しい値**なので符号で捨てない。 */
  function markOff(v) {
    var n = Number(v);
    return isFinite(n) ? Math.round(n * 1000) / 1000 : 0;
  }

  /** 🔒 §30-31-1 2 / §30-35-3 2: 案件へ入れる印の器
   *  （形・色・大きさ・縦横・中心のずれ）を写す1か所 */
  function markCopy(m) {
    return { shape: m.shape, color: m.color, scale: m.scale,
             w_m: m.w_m, h_m: m.h_m, dx_m: m.dx_m, dy_m: m.dy_m };
  }

  /**
   * 🔒 §30-25-37: 印の値（形・色・大きさ）を書き換える時の**組み立て1か所**。
   * 🔴 どれか1つを変えても他の2つを落とさない（scale を持たない patch でも保つ）。
   * 🔒 §30-31-1 2: ■の縦横（w_m/h_m）も同じ器に入る。
   *    ・patch に w_m/h_m があればそれが真実（辺つまみ・右パネルの欄）
   *    ・大きさ（scale）だけを変えた時は**同じ比率**で縦横に掛ける（角のつまみ）
   *      ＝長方形の比を保ったまま拡大縮小できる
   * 🔒 §30-35-3 2: 中心のずれ（dx_m/dy_m）も同じ器。patch にあればそれが真実で、
   *    無ければ今の値のまま（大きさを変えてもずれは動かさない＝印はその場にある）。
   */
  function markNext(key, patch) {
    var cur = markOf(key);
    var sc = (patch && patch.scale !== undefined) ? patch.scale : cur.scale;
    // 🔴 上下限（0.5〜3）の出どころは Editor.clampMarkScale 1か所
    if (Editor.clampMarkScale) sc = Editor.clampMarkScale(sc);
    var r = (cur.scale > 0) ? (sc / cur.scale) : 1;
    var hasOff = function (k) { return patch && patch[k] !== undefined; };
    return { shape: (patch && patch.shape) || cur.shape,
             color: (patch && patch.color) || cur.color,
             scale: sc,
             w_m: markDim(patch && patch.w_m, markDim(cur.w_m * r, cur.w_m)),
             h_m: markDim(patch && patch.h_m, markDim(cur.h_m * r, cur.h_m)),
             dx_m: hasOff('dx_m') ? markOff(patch.dx_m) : cur.dx_m,
             dy_m: hasOff('dy_m') ? markOff(patch.dy_m) : cur.dy_m };
  }

  /** 生成に渡す形（両地点ぶん・shozaizu.js の opts.marks） */
  function marksForGen() {
    return { home: markOf('home'), lot: markOf('lot') };
  }

  /** その主役ラベルがどちらの地点の物か（🔒 §26-2 注意②: 新しい物は pinKey で見る。
   *  文字での判定は旧データ用の保険＝ '自宅' は §25-1 の改名前の文言） */
  function pinKeyOf(o) {
    if (o.pinKey === 'home' || o.pinKey === 'lot') return o.pinKey;
    return (o.text === '自宅' || o.text === '使用の本拠') ? 'home' : 'lot';
  }

  /**
   * ①で形・色を選んだ時。案件に覚えさせ、画面のピンと**既に生成してある印**を直す。
   * 🔴 マーカーをまだ置いていない時は置き場が無いので画面の控え（state.markPick）に持ち、
   *    置いた瞬間に points[key].mark へ移す（onNavPinPlace）。
   */
  function sgSetMark(key, patch) {
    var c = state.current;
    if (!c) return;
    var cur = markOf(key);
    /* 🔒 §30-25-37 2: 形・色に**大きさ（scale）**が加わった。組み立ては markNext 1か所 */
    var next = markNext(key, patch);
    if (next.shape === cur.shape && next.color === cur.color
        && next.scale === cur.scale
        && next.w_m === cur.w_m && next.h_m === cur.h_m) return;
    if (c.points[key]) c.points[key].mark = next;
    else state.markPick[key] = next;
    /* 🔒 §30-22-1 6: 同一住所の時は印は1つ（本拠側の設定を採る）。
     * 値が2か所に割れないよう、もう一方の地点にも同じ物を写しておく。
     * 🔒 §30-31-1 2: 写す中身は markCopy 1か所（縦横も一緒に持っていく）。 */
    if (c.points.same && c.points.home && c.points.lot) {
      c.points.home.mark = markCopy(next);
      c.points.lot.mark = markCopy(next);
    }
    /* 🔒 §30-24-3: 印の種類を変えても文字は必ず1つずつ。
     * 🔴 applyMarkChoice の**前**に呼ぶ（文字が無い紙には印も作られないので、
     *    先に文字を戻してから印を引き直す）。 */
    ensureMainLabels();
    applyMarkChoice(key);
    /* 🔒 §30-24-2: 同一住所はもう一方も同じ値（印は本拠側の1つ）＝両方を引き直す */
    if (c.points.same) applyMarkChoice(key === 'home' ? 'lot' : 'home');
    sgRenderMarks();
    renderOverlay();
    Store.autosave(c);
  }

  /**
   * 🔒 §30-25-40 2〜4: 主役の印（◎・■）の**大きさ**を変える1か所。
   * 値の出どころは案件の `points[key].mark.scale`（形・色と同じ器）で、
   * 紙の印（applyMarkChoice）も画面のピン（syncPinLook）もそこから引き直す。
   * 🔴 呼ぶ所は2つだけ: 印の右下のつまみ（editor.onMainMarkScale）と
   *    右パネルの［小／標準／大／特大］。どちらも同じ値を書く。
   * @param {'home'|'lot'} key
   * @param {number} scale 倍率（上下限は markNext ＝ Editor.clampMarkScale が丸める）
   * @param {{live:boolean}} opts live＝ドラッグの途中（保存は指を離した時に1回）
   */
  function setMainMarkScale(key, scale, opts) {
    var c = state.current;
    if (!c || (key !== 'home' && key !== 'lot')) return false;
    var live = !!(opts && opts.live);
    var cur = markOf(key).scale;
    // 🔴 形・色を落とさない（組み立ては markNext 1か所）
    var next = markNext(key, { scale: scale });
    if (next.scale !== cur) {
      if (c.points[key]) c.points[key].mark = next;
      else state.markPick[key] = next;
      /* 🔒 §30-22-1 6 / §30-24-2: 同一住所の時は印は1つ（本拠側の値）＝両方に写す
       * （値が2か所に割れない・sgSetMark と同じ作法）。 */
      if (c.points.same && c.points.home && c.points.lot) {
        c.points.home.mark = markCopy(next);
        c.points.lot.mark = markCopy(next);
      }
      applyMarkChoice(key);                    // 紙の◎（markScale）・■（w_m/h_m）
      if (c.points.same) applyMarkChoice(key === 'home' ? 'lot' : 'home');
      renderOverlay();                         // 画面のピンも同じ倍率に
    }
    if (!live) Store.autosave(c);
    return true;
  }

  /**
   * 🔒 §30-31-1 2（2026-09-15 オーナー指示「①の□マーカー、4辺を自由に調節したい」）:
   * 主役の■の**縦横（実距離 m）**を変える1か所。
   * 値の出どころは案件の `points[key].mark.w_m / h_m`（形・色・大きさと同じ器）で、
   * 紙の■（applyMarkChoice）がそこから引き直す。
   * 🔴 呼ぶ所は2つだけ: ■の辺つまみ（editor.onMainMarkDims）と
   *    右パネルの幅／奥行の欄（applyPropInputs）。どちらも同じ値を書く。
   * 🔒 §30-35-3 1・3（2026-09-15 オーナー指示）: 辺つまみは**掴んだ辺だけ**伸びる
   *    ＝中心がピンからずれる。editor が中心（緯度経度）も渡してきた時は、
   *    ピンとの差を m に直して `dx_m/dy_m` へ書く（換算は Editor.offsetMeters 1か所）。
   *    右パネルの欄は中心を渡さない＝ずれは今のまま（中心は動かない）。
   * @param {'home'|'lot'} key
   * @param {number} w_m 幅(m)・省略や 0 以下は今の値のまま
   * @param {number} h_m 奥行(m)・同上
   * @param {{lat:number,lng:number}} [center] ■の中心（省略＝ずれは変えない）
   */
  function setMainMarkDims(key, w_m, h_m, center) {
    var c = state.current;
    if (!c || (key !== 'home' && key !== 'lot')) return false;
    var cur = markOf(key);
    var patch = { w_m: w_m, h_m: h_m };
    /* 🔒 §30-35-3 3: 中心が来たらピンとの差＝ずれ。ピンがまだ無い（地点を置いて
     * いない）時は基準が無いので、ずれは触らない。 */
    if (center && c.points[key] && Editor.offsetMeters) {
      var off = Editor.offsetMeters(c.points[key], center);
      patch.dx_m = off.dx_m;
      patch.dy_m = off.dy_m;
    }
    // 🔴 組み立ては markNext 1か所（形・色・大きさを落とさない）
    var next = markNext(key, patch);
    if (next.w_m === cur.w_m && next.h_m === cur.h_m
        && next.dx_m === cur.dx_m && next.dy_m === cur.dy_m) return false;
    if (c.points[key]) c.points[key].mark = next;
    else state.markPick[key] = next;
    // 🔒 §30-22-1 6 / §30-24-2: 同一住所は本拠側の値を両方に（markCopy 1か所）
    if (c.points.same && c.points.home && c.points.lot) {
      c.points.home.mark = markCopy(next);
      c.points.lot.mark = markCopy(next);
    }
    applyMarkChoice(key);                      // 紙の■（w_m/h_m）を引き直す
    if (c.points.same) applyMarkChoice(key === 'home' ? 'lot' : 'home');
    renderOverlay();
    Store.autosave(c);
    return true;
  }

  /**
   * 既に生成してある主役の印を、いまの選択に**その場で**合わせる（🔒 §28-14 ①-4）。
   * 作り直さない（syncRoleObjects と同じ「追従」の作法。手で描いた図形も文字位置も残る）。
   *   ・◎ → ■: その紙にラベルの**直前**へ四角（Editor.makeMark）を差し込む
   *   ・■ → ◎: その紙の四角を取り除き、ラベルを dotStyle:'double' に戻す
   *   ・色: 四角の markColor / style.color と、◎の markColor を書き換える
   * 🔴 配列は**差し替えない**（push/splice だけ・§23-7-1 / §26-2 注意①）。
   * 🔴 §24-1: ピンは案件レベルの唯一の真実なので**所在図の全シート**に効かせる。
   */
  function applyMarkChoice(key) {
    var c = state.current;
    if (!c) return 0;
    var want = markOf(key), p = c.points[key], changed = 0;
    /* 🔒 §30-24-2: 同一住所の時、印は**本拠側の1つ**だけ（駐車場側は文字だけ）。
     * 生成（shozaizu.js）と同じ規則をここでも守る＝同じ場所に印が2つ重ならない。 */
    if (c.points.same && key === 'lot') {
      /* 🔒 §30-31-1 2: 縦横も落とさずに写す（器の形を1つに保つ＝ markCopy と同じ中身）
       * 🔒 §30-35-3 2: 中心のずれ（dx_m/dy_m）も一緒に運ぶ */
      want = markCopy({ shape: 'none', color: want.color, scale: want.scale,
                        w_m: want.w_m, h_m: want.h_m,
                        dx_m: want.dx_m, dy_m: want.dy_m });
    }
    var hex = Editor.markHex ? Editor.markHex({ markColor: want.color }) : '';
    sheetsOf('shozaizu').forEach(function (sh) {
      var objs = sh.objects || [];
      var lb = null, rect = null, polys = [], i, o;
      for (i = 0; i < objs.length; i++) {
        o = objs[i];
        if (!o || o.source !== 'shozaizu') continue;
        if (o.type === 'text' && o.role === 'pinlabel' && pinKeyOf(o) === key) lb = o;
        else if (o.role === 'mainmark' && (o.markRole || 'home') === key) {
          if (o.type === 'polygon') polys.push(o);   // 🔒 §30-24-1: 何個でもある
          else rect = o;
        }
      }
      if (!lb && !rect && !polys.length) return;  // この紙には主役の印がまだ無い
      /* 🔒 §30-24-1: ◎／■／印なしを選んだら、その地点の多角形は**全部**取り除く
       * （印の種類は1つ）。多角形にするのは［多角形で描く］の側の仕事。
       * 🔴 配列は差し替えず splice だけ（§23-7-1 / §26-2 注意①）。 */
      if (want.shape !== 'polygon' && polys.length) {
        polys.forEach(function (pg) {
          var atG = objs.indexOf(pg);
          if (atG >= 0) { objs.splice(atG, 1); changed++; }
        });
        polys.length = 0;
      }
      if (want.shape === 'rect') {
        if (!rect && p && Editor.makeMark) {
          /* 🔒 §30-25-37 1: 実寸は「基準 × 大きさ」（Editor.markRectDims が出どころ）
           * 🔒 §30-31-1 2: 案件が縦横（want.w_m/h_m）を持っていればそれが真実 */
          rect = Editor.makeMark(key, p, undefined, want.color, want.scale, want);
          var at = lb ? objs.indexOf(lb) : -1;
          if (at >= 0) objs.splice(at, 0, rect); else objs.push(rect);
          changed++;
        } else if (rect) {
          if (rect.markColor !== want.color) {
            rect.markColor = want.color;
            rect.style = rect.style || {};
            if (hex) rect.style.color = hex;
            changed++;
          }
          /* 🔒 §30-25-37 3: 大きさを変えたら**その場で引き直す**（作り直さない）。
           * 🔒 §30-31-1 2: 実寸の出どころは案件の points[key].mark.w_m/h_m
           *    （＝ markOf が返す want.w_m/h_m。持たない案件は「基準 × 大きさ」）。
           *    倍率（markScale）は◎と紙の下限のために一緒に写す。 */
          if (rect.w_m !== want.w_m || rect.h_m !== want.h_m
              || rect.markScale !== want.scale) {
            rect.w_m = want.w_m; rect.h_m = want.h_m; rect.markScale = want.scale;
            changed++;
          }
          /* 🔒 §30-35-3 4: **中心のずれ**も引き直す（縦横と同じ器・同じ規則）。
           * 中心＝ピン＋ずれ。ピンが無い紙は触らない（syncRoleObjects が面倒を見る）。 */
          if (p && rect.center && Editor.offsetLatLng) {
            var wc = Editor.offsetLatLng(p, want.dx_m, want.dy_m);
            if (rect.center.lat !== wc.lat || rect.center.lng !== wc.lng) {
              rect.center = { lat: wc.lat, lng: wc.lng };
              changed++;
            }
          }
        }
      } else if (rect) {
        var at2 = objs.indexOf(rect);
        if (at2 >= 0) { objs.splice(at2, 1); changed++; }
        rect = null;
      }
      if (lb) {
        var wantDot = (want.shape === 'circle') ? 'double' : 'none';
        if (lb.dotStyle !== wantDot) { lb.dotStyle = wantDot; changed++; }
        if (lb.markColor !== want.color) { lb.markColor = want.color; changed++; }
        /* 🔒 §30-25-37 1: ◎の大きさは主役ラベルの markScale（§30-25-18 と同じ名前）。
         * 🔴 出どころは案件の points[key].mark.scale 1つ＝ここで文字へ写すだけ。
         *    形を◎↔■↔多角形に変えても scale は保つ（ここで毎回書き直す）。 */
        if (lb.markScale !== want.scale) { lb.markScale = want.scale; changed++; }
        /* 🔒 §25-4: 文字を印の外へ逃がすための控え（次の作り直しで使う）。
         * 四角が無くなったら null に戻す（◎の実寸は shozaizu.js が別途出す）。
         * 🔒 §30-35-3 5: **中心のずれ**も控える（文字よけの箱はピン＋ずれで測る）。 */
        var wm = rect ? { w_m: rect.w_m, h_m: rect.h_m,
                          dx_m: want.dx_m, dy_m: want.dy_m } : null;
        var mkKey = function (v) {
          return v ? (v.w_m + 'x' + v.h_m + '@' + (v.dx_m || 0) + ',' + (v.dy_m || 0)) : '';
        };
        var had = mkKey(lb.mark);
        var now = mkKey(wm);
        if (had !== now) { lb.mark = wm; changed++; }
      }
    });
    if (changed) {
      if (state.kind === 'shozaizu' && state.editor) state.editor.render();
      Store.autosave(c);
    }
    return changed;
  }

  /* 🔒 §30-24-3: 作り直した主役ラベルを真下へずらす量。紙の1行 ≒ 4.4mm ＝
   * 紙幅 210mm の 2.1% ＝ 枠の実幅（w_m）の 2.1%。
   * 🔴 store.js の splitSameLabel（旧案件の1つの文字を2つに割る）と**同じ規則**。 */
  var MAIN_LABEL_ROW = 0.021;

  /**
   * 🔒 §30-24-3（2026-09-13 オーナー実機「使用の本拠・駐車場の文字がなぜか消える」）:
   * 主役ラベル（「使用の本拠」「駐車場」）は**印の種類・置き直し・作り直しに
   * 関わらず必ず1つずつある**。消えていたら作り直す。
   *
   * 🔴 呼ぶ所は4つだけ（正典 §30-24-3 の「消える経路」の出口）:
   *    ①生成の直後 ②印の種類を変えた後 ③同一住所の後（＋同一住所をやめた後）
   *    ④案件を開いた後。
   *    図形が変わるたび（change）には**呼ばない**＝消しゴムで消した文字が
   *    その場で生え直すと消せなくなるため。
   * 🔒 §30-25-28 1（2026-09-14 オーナー指示「マーカー設置した時から動かせるように」）:
   *    作るのは**所在図の紙なら白紙でも**（旧: 「もう主役の物が載っている紙」だけ）。
   *    マーカーを置いた直後（onNavPinPlace / placeSamePoint）にも呼ぶので、
   *    生成（③）を待たずに文字が出る＝最初からドラッグ・つまみで直せる。
   *    置き場所は**印の右隣**（名前の位置「近く」と同じ規則＝Editor.markTextAt）。
   * 🔴 印は作らない（◎■は applyMarkChoice が、多角形は利用者が描く）。
   * 🔴 配列は差し替えず push / splice だけ（§23-7-1 / §26-2 注意①）。
   * @param {Array} [force] 使わない（§30-25-28 で白紙も対象になった。
   *        呼ぶ側の「消した紙」の受け渡しは残してあるが判定には効かない）
   * @returns 作った数
   */
  function ensureMainLabels(force) {
    var c = state.current;
    if (!c) return 0;
    var made = 0;
    /* 🔒 §30-24-5: noLead を揃えた回数（label 新規作成とは別に数える。
     * `made` の意味＝「作った文字の数」を変えないため）。 */
    var noLeadChanged = 0;
    /* 🔒 §30-25-28 1: 「印の右隣」を解けるのは**いま開いている所在図の紙**だけ
     * （editor は1枚の紙にしか結ばれていない・縮尺もその紙の物）。他の紙は
     * 従来どおり地点そのものに置き、生成（③）が正しい場所へ並べ直す。 */
    var curSh = (state.kind === 'shozaizu' && state.editor) ? curSheet() : null;
    sheetsOf('shozaizu').forEach(function (sh) {
      var objs = sh.objects || [];
      var i, o;
      var have = { home: null, lot: null }, mark = { home: null, lot: null };
      for (i = 0; i < objs.length; i++) {
        o = objs[i];
        if (!o || o.source !== 'shozaizu') continue;
        if (o.type === 'text' && o.role === 'pinlabel') have[pinKeyOf(o)] = o;
        else if (o.role === 'mainmark' && o.type !== 'polygon') {
          mark[(o.markRole || 'home')] = o;
        }
      }
      ['home', 'lot'].forEach(function (key) {
        var p = c.points[key];
        if (!p || have[key]) return;     // 地点が無い／文字はもうある
        var want = markOf(key);
        /* 🔒 §30-24-2: 同一住所の駐車場側は印を持たない（印は本拠側の1つ）。
         * 🔒 §30-24-1: 多角形・印なしは◎を描かない。 */
        var shared = !!(c.points.same && key === 'lot');
        var circleMark = (want.shape === 'circle') && !shared;
        var rect = mark[key] || null;
        /* 🔒 §30-25-28 1: ■を選んでいて四角がまだ紙に無い（マーカーを置いた直後）
         * 時は、これから applyMarkChoice が作る四角の**実寸**を先に読む
         * ＝文字を最初から■の右隣に置ける。値の出どころは Editor.makeMark
         * （＝ Editor.MARK 表）1か所なので、後で作られる四角と必ず同じ寸法になる。 */
        /* 🔒 §30-35-3 5: 控えには中心の**ずれ**（dx_m/dy_m）も入れる
         * ＝ applyMarkChoice が持つ控えと中身が同じ（器を1つに保つ）。 */
        var mkSize = rect ? { w_m: rect.w_m, h_m: rect.h_m,
                              dx_m: want.dx_m, dy_m: want.dy_m } : null;
        if (!mkSize && want.shape === 'rect' && !shared && Editor.makeMark) {
          /* 🔒 §30-25-37 1: 実寸は「基準 × 大きさ」（後で作られる四角と同じ寸法に）
           * 🔒 §30-31-1 2: 案件が縦横を持っていればそれ（＝ want をそのまま渡す） */
          var prov = Editor.makeMark(key, p, undefined, want.color, want.scale, want);
          mkSize = { w_m: prov.w_m, h_m: prov.h_m,
                     dx_m: want.dx_m, dy_m: want.dy_m };
        }
        /* 真下へずらす基準は、同じ地点に既にある相方の文字（無ければ地点そのもの）。
         * 枠が無い紙は 400m を仮に置く（store.js の splitSameLabel と同じ）。 */
        var other = have[key === 'home' ? 'lot' : 'home'];
        var wM = (sh.frame && sh.frame.w_m) || 400;
        var dLat = (wM * MAIN_LABEL_ROW) / 111320;
        var samePt = !!(other && other.at && other.anchor
                        && Math.abs(other.anchor.lat - p.lat) < 1e-9
                        && Math.abs(other.anchor.lng - p.lng) < 1e-9);
        var at = samePt ? { lat: other.at.lat - dLat, lng: other.at.lng }
                        : { lat: p.lat, lng: p.lng };
        var lb = {
          id: 'lb' + Date.now().toString(36) + Math.random().toString(36).slice(2, 7),
          type: 'text', at: at,
          mark: mkSize,
          anchor: { lat: p.lat, lng: p.lng },
          pinKey: key,
          dotStyle: circleMark ? 'double' : 'none',
          markColor: want.color || null,
          // 🔒 §30-25-37 1: ◎の大きさ（出どころは points[key].mark.scale＝markOf）
          markScale: want.scale,
          text: pinLabel(key), size: 'large',
          style: { color: '#111' },
          source: 'shozaizu', role: 'pinlabel'
        };
        /* 🔒 §30-25-28 1: 置き場所は**印の右隣**（名前の位置「近く」と同じ規則）。
         * 🔴 規則の出どころは Editor.markTextAt / markSide の1か所（右がはみ出す
         *    時は左隣）。 */
        if (curSh === sh) {
          if (samePt) {
            /* 同じ地点の2つ目（同一住所）は相方の**真下へ1行**。
             * 🔴 1行の高さの出どころは editor の textPx（＝いま画面に描かれている
             *    文字の高さ）1か所。枠がまだ決まっていない紙（マーカーを置いた
             *    直後の①）では紙の物差し（MAIN_LABEL_ROW）が実距離に化けず、
             *    2つの文字がぴたりと重なってしまうため（実測・§30-25-28）。 */
            var op = state.map.project(other.at.lat, other.at.lng);
            var row = Math.max(6, state.editor.textPx(lb)) * 1.15;
            var ll = state.map.unproject(op.x, op.y + row);
            lb.at = { lat: ll.lat, lng: ll.lng };
          } else {
            var np = state.editor.markTextAt(lb, lb.text,
                                             state.editor.markSide(lb, lb.text));
            if (np) lb.at = { lat: np.lat, lng: np.lng };
          }
        }
        /* 印のすぐ後ろへ入れる（生成と同じ並び＝印の上に文字が乗らない） */
        var at2 = rect ? objs.indexOf(rect) : -1;
        if (at2 >= 0) objs.splice(at2 + 1, 0, lb); else objs.push(lb);
        have[key] = lb;
        made++;
      });
      /* 🔒 §30-24-5（2026-09-14 オーナー指示）: 同一住所の間だけ、主役の2つの文字
       * には引き出し線を描かない（noLead）。値の出どころはここ1か所。
       * 既にある文字にも、この呼び出しで今つくった文字にも同じ値を揃える。 */
      var wantNoLead = !!(c.points && c.points.same);
      ['home', 'lot'].forEach(function (key) {
        var lb = have[key];
        if (!lb) return;
        if (wantNoLead) { if (!lb.noLead) { lb.noLead = true; noLeadChanged++; } }
        else if (lb.noLead) { delete lb.noLead; noLeadChanged++; }
      });
    });
    if (made || noLeadChanged) {
      if (state.kind === 'shozaizu' && state.editor) state.editor.render();
      Store.autosave(c);
    }
    return made;
  }

  /**
   * ①の「印の形と色」（形3つ＋色3つ）を組み立てる。値は markOf が真実。
   * 🔒 §30-22-1 4〜5: 器は**地点ごとに1つ**（#sgMarksHome / #sgMarksLot）＝
   *    それぞれの［○○マーカー設置］の直下の ▼ の中に入る。
   */
  function sgRenderMarks() {
    var cols = (Editor.MARK && Editor.MARK.colors) || [];
    var isSame = !!(state.current && state.current.points.same);
    /* 🔒 §30-24-2: 器は3つ（本拠／駐車場／同一住所）。同一住所の▼は本拠と
     * **同じ値**（points.home.mark）を出す＝値が2か所に割れない。 */
    /* 🔒 §30-28-2 1: 道具メニューの▼「印を変える」にも**同じ器**を出す
     * （#sideMarksHome / #sideMarksLot / #sideMarksSame）。器の一覧はこの表1か所。 */
    [['home', 'sgMarksHome'], ['lot', 'sgMarksLot'], ['home', 'sgMarksSame'],
     ['home', 'sideMarksHome'], ['lot', 'sideMarksLot'], ['home', 'sideMarksSame']]
    .forEach(function (kv) {
      var box = $(kv[1]);
      if (!box) return;
      var cur = markOf(kv[0]);
      var shapes = MARK_SHAPES.filter(function (s) { return s.pick !== false; })
      .map(function (s) {
        return '<button type="button" class="mk-shape'
          + (cur.shape === s.key ? ' is-on' : '') + '" data-mk="' + kv[0]
          + '" data-shape="' + s.key + '" title="' + s.ja + '">' + s.sym + '</button>';
      }).join('');
      var colors = cols.map(function (cc) {
        return '<button type="button" class="mark-color'
          + (cur.color === cc.key ? ' is-on' : '') + '" data-mk="' + kv[0]
          + '" data-color="' + cc.key + '" style="background:' + cc.hex
          + '" title="' + cc.ja + '" aria-label="' + cc.ja + '"></button>';
      }).join('');
      /* 🔒 §30-25-40 1（2026-09-14 オーナー指示「左メニューの印の大きさの選択肢は
       * 無くす」）: ここに「印の大きさ」の行は**出さない**。大きさは印の右下の
       * つまみ（◎＝主役の文字／■＝主役の四角）と右パネルで変える。 */
      box.innerHTML = '<div class="sg-mk"><span class="sg-mk-sh">' + shapes + '</span>'
        + '<span class="mark-colors">' + colors + '</span></div>';
    });
    /* 🔒 §30-24-1: 多角形の書式（太さ・斜線・色）は**多角形を描いた後だけ**出す
     * （▼の中・右パネルと同じ部品）。 */
    [['home', 'sgMpFmtHome'], ['lot', 'sgMpFmtLot'], ['home', 'sgMpFmtSame'],
     ['home', 'sideMpFmtHome'], ['lot', 'sideMpFmtLot'], ['home', 'sideMpFmtSame']]
    .forEach(function (kv) {
      var box = $(kv[1]);
      if (!box) return;
      var on = (markOf(kv[0]).shape === 'polygon');
      box.hidden = !on;
      if (on) renderPolyFmt(box, kv[0]);
    });
    /* 🔒 §30-22-1 6 / §30-24-2: 同一住所の時は印が1つ（本拠側の設定）なので、
     * ▼は［同一住所］の直下の1つだけを出し、本拠・駐車場の▼は出さない
     * （触っても効かない物・同じ値が2か所に出る物を見せない）。
     * 🔒 §30-28-2 1: 道具メニューの▼は1つなので、**中の区画**を同じ規則で出し分ける。 */
    var wH = sgMoreBox(1, 'markHome'), wL = sgMoreBox(1, 'markLot'),
        wS = sgMoreBox(1, 'markSame');
    if (wH) wH.hidden = isSame;
    if (wL) wL.hidden = isSame;
    if (wS) wS.hidden = !isSame;
    [['sideMarkHome', isSame], ['sideMarkLot', isSame], ['sideMarkSame', !isSame]]
    .forEach(function (kv) {
      var el = $(kv[0]);
      if (el) el.hidden = kv[1];
    });
    /* 🔒 §30-11: マーカーの種類は「やること」ではないのでバッジは付かない。
     * 🔒 §30-12-4 2: ボタンの「いま: ◎赤」を引き直す。 */
    if (state.nav) sgMoreSync();
  }

  /* ==================== 左面のガイダンス（🔒 §28 / §29）====================
   * §28-1 ③ 共通の骨格（毎段この並び）:
   *   足跡（済んだ段だけ押せる）／見出し／説明文／操作部品／
   *   状態の一言／［戻る］［次へ］。［次へ］が押せない時は理由を平文で下に出す。
   * 🔴 中身は**既存の関数をそのまま呼ぶ**（navPinArm / doSearch / setSheetOrient /
   *    toggleFrameFixed / navRunShozaizu / setTool / importImage / wzRunFill /
   *    setArrowWidth / labelArm / exportPDF / exportPNG）。
   *    ガイダンスは「別の画面」ではなく「同じ機能の案内つきの入口」（§28-1 ④）。
   * 🔒 §29-1: 足跡は**2段**（上＝所在図①〜④／下＝配置図⑤〜⑫）。
   * 🔒 §29 Step 7: ⑨〜⑫もここへ移した＝**全12段が左面**（小ウィンドウは全廃）。
   * 🔒 §30-1（2026-09-08）: 入口が図ごとに2つになったので、足跡も**その図の分だけ**
   *    1行で出す（所在図①〜④／配置図①〜⑧）。番号は navDisp が作る。 */
  var SG_STEPS = [
    { n: 1, name: 'マーカー' },
    { n: 2, name: '枠' },
    { n: 3, name: '文字の量' },
    { n: 4, name: '描き足し' },
    /* ここから配置図（🔒 §29-1）。名前は足跡に収まる短さで */
    { n: 5,  name: '下敷き' },
    /* 🔒 §30-22-4 3: ③の名前は「多角形（土地の輪郭や建物）」。足あとは8段が1行に
     * 並ぶので、名前の**頭**（多角形）だけを出す（ボタンと字幕は正式名のまま）。 */
    { n: 6,  name: '多角形' },
    { n: 7,  name: '駐車枠' },
    { n: 8,  name: '道路' },
    { n: 9,  name: '道路幅' },
    { n: 10, name: '出入口' },
    { n: 11, name: 'ラベル' },
    { n: 12, name: '保存' }
  ];
  var SG_TEXT = {
    1: '使用の本拠（会社・自宅）と駐車場の場所を、地図の上に置きます。'
     + '2つとも置けたら［次へ］に進めます。',
    2: '紙に入れる範囲（青い破線）を決めます。決めてから所在図を作ります。',
    /* 🔒 §28-4 の案内文（案）をそのまま */
    3: 'ここでは、まとめて描く文字の量を変えられます。'
     + '各項目を変えるとすぐに描き直されるので、ちょうどよい設定にしてください。'
     /* 🔒 §30-40-2 6: 「自動」の一言。件数も段の名前も実値から組む（nameAutoNote） */
     + nameAutoNote()
     + 'まずは描画の量を決めてから、1つ1つの手直し（消す・動かす・文字を足す）は'
     + '次の④で行います。',
    /* 🔒 §28-5 B / §28-8 Step 3: 正典の文言そのまま（Step 2 は仮の文で保留していた） */
    4: '地図を見ながら、足りない道路・道路名・交差点名・建物を自分で描き足します。'
     + '用途に合わせて下敷きの地図を切り替えられます。',
    /* 🔒 §29-1: 以下は配置図の段。案内文は「何をする段か」「どのボタンで」
     * 「終わったら何が起きるか」の3文に揃える（§29-1 末尾）。 */
    5: 'ここからは配置図（駐車場の図）です。まず何の上に描くかを決めます。'
     + '下敷きの地図を選ぶか、お手元の写真を取り込み、［駐車場に寄る］で'
     + '駐車場を大きく写してください。'
     + '青い破線が紙になる範囲です。［枠を決定］を押すと範囲が決まり、'
     + 'あとは地図だけを動かして中を仕上げられます。',
    /* 🔒 §30-25 夜間確認: 「確定すると自動で次の③へ進みます」は §30-25-11 で
     * 廃止した自動遷移の説明のまま残っていた（実際は一番下の［次へ］で進む）。 */
    6: '駐車場の土地の輪郭（外周）を描きます。'
     + '［多角形］を押して、敷地の角を順にクリックし、最後に Enter で確定します。'
     + 'よければ一番下の［次へ］で③（駐車枠）へ進みます。',
    /* 🔒 §30-25 夜間確認: ［駐車枠（四角）］は §30-25-12 でこの段から消え、
     * ［写真から枠を描く］も §30-22-4 7 で配置図③から隠された（案内文だけ古いままだった）。 */
    7: '輪郭の中に駐車枠を描きます。'
     + '1枠ずつなら［駐車枠］を押して地図をクリック、同じ枠が並ぶなら［枠をまとめて］、'
     + '台数と1枠の寸法が決まっているなら［台数を指定して置く…］が使えます。'
     + '対象の枠には［保管場所マーク］を付けてください（提出に要ります）。',
    8: '駐車場の前の道路を描きます。'
     + 'まっすぐな縁は［直線］、角の丸い道は［曲線］、'
     + '何度も折れ曲がる縁は［多角形］で一筆に引けます。'
     + '道路が無い駐車場もあるので、この段は飛ばしても構いません。',
    /* 🔒 §29 Step 7: ⑨〜⑫。3文（何をする段か／どのボタンで／終わったら何が起きるか）。 */
    9: '前面道路の幅を書き入れます。'
     + '道幅を入れて［幅矢印］を押し、道路の端から端までドラッグしてください。'
     + '引いた矢印には数値が付き、そのまま紙に出ます（空欄なら地図から計算した幅）。',
    10: '駐車場の出入口の場所と幅を書き入れます。'
     + '幅を入れて［幅矢印］でドラッグし、［出入口（文字）］で文字を置きます。'
     + '「出入口」の文字と幅は、警察に出す配置図でよく見られる所です。',
    /* 🔒 §30-25-36 2: ボタン名は［保管場所ラベル配置］（出どころは LABEL_PLACE_JA）。
     * 🔒 §30-22-4 10: 置き方はワンクリック（対象の駐車枠をクリックするだけ）。 */
    11: '「保管場所」の寸法などを1つの塊にして図に置きます。'
     + 'チェックと数値を入れて［保管場所ラベル配置］を押し、'
     + '対象の駐車枠をクリックしてください。'
     + '置いた塊は矢印つきで枠を指し、あとからドラッグで動かせます。',
    /* 🔒 §30-31-3 2: 「提出前チェック」の案内は消した（一覧ごと廃止）。 */
    12: '提出する紙面です。図1つにつき A4 1ページ（縦・横は紙ごと）で、'
     + '所在図・配置図の全部の紙が出ます。'
     + '［プレビュー］で見た目を確かめ、［PDFにして保存］で案件のフォルダに保存できます。'
  };

  /**
   * 🔒 §28-4 / §28-7: 所在図の設定盤（14項目・🔒 §30-21-4 5: 11→13・🔒 §30-22-2 3: →14）の置き場を切り替える。
   * 🔴 **複製ではなく部品ごと移す**（同じ id・同じ配線が動く＝値が2か所に割れない）。
   *    ガイダンス中は③の中（#sgSzSet）、ガイダンス外は右の浮き窓（#szSetHome）。
   * 🔴 §28-1 ①: ガイダンス中は右の浮き窓そのものを出さない。
   */
  function szSetHost(toGuide) {
    var set = $('szSet'), want = $(toGuide ? 'sgSzSet' : 'szSetHome');
    if (!set || !want) return;
    if (set.parentNode !== want) want.appendChild(set);
    if (toGuide) $('szPanel').hidden = true;
    syncNameLevelTitles();       // 🔒 §30-21-5 4: 段の title を実値で付け直す
  }

  /** 🔒 §28-4 / §28-6 ③: 描き直している間は設定盤を灰色にして「描き直しています…」 */
  function sgSzBusy(on) {
    var box = $('sgSzSet'), msg = $('sgSzBusy');
    if (box) box.classList.toggle('is-busy', !!on);
    if (msg) msg.hidden = !on;
    var std = $('sgSzStd');
    if (std) std.disabled = !!on;
  }

  /** 足跡の1行ぶん（🔒 §30-1: いま案内している図の段だけ）。ken は行の見出し */
  function sgStepsRow(list, n, ken) {
    return '<div class="sg-srow"><span class="sg-sk">' + ken + '</span>'
      + list.map(function (s) {
        var cls = (s.n === n) ? 'is-now' : (s.n < n ? 'is-done' : '');
        var mark = circ(navDisp(s.n));
        return '<span class="' + cls + '" data-step="' + s.n + '"'
          + (s.n < n
              ? ' title="' + mark + ' ' + s.name + ' へ戻る（描いた図は消えません）"' : '')
          + '>' + mark + ' ' + s.name + '</span>';
      }).join('') + '</div>';
  }

  function sgRender() {
    if (!state.nav) return;
    var n = state.nav.step;
    /* 足跡（🔒 §28-6 ⑦: 済んだ段だけ押せる・名前は短く）。
     * 🔒 §30-1: 入口が図ごとに2つになったので、足跡も**いま案内している図の分だけ**
     *    1行で出す（所在図①〜④／配置図①〜⑧）。もう片方の図へは
     *    ④の［配置図ガイダンスへ］／配置図①の［所在図ガイダンスへ］で行き来する。 */
    var fig = navFigOf(n);
    /* 🔒 §30-17-2: 図ごとの「進む」色。配置図の間だけ body に sg-hz を付けて
     * CSS 変数（--sg-go 系）を緑へ差し替える。🔴 判定は navFigOf だけ（1か所）。 */
    document.body.classList.toggle('sg-hz', fig === 'haichizu');
    $('sgSteps').innerHTML = sgStepsRow(
      SG_STEPS.filter(function (s) { return navFigOf(s.n) === fig; }), n, figName(fig));
    /* 🔒 §30-12-1: ガイダンスの目指す所。足あとの直下に出す。
     * 🔴 文言はここ1か所（色の名前と図の名前だけ差し替える・🔒 §30-17-2）。
     * 🔒 §30-22-4 2（2026-09-13 オーナー指示）: **配置図は最初に開いた時の1回だけ**
     *    （同じ案件で2回目からは出さない）。所在図は今までどおり全段で常に出す。
     * 🔴 覚えるのは画面の状態（案件を開いている間）＝案件には保存しない。 */
    var aimShow = true;
    if (fig === 'haichizu') {
      aimShow = !state.hzAimShown;
      state.hzAimShown = true;
    }
    $('sgAim').textContent = aimShow
      ? ((fig === 'haichizu' ? '緑色' : '青色')
         + 'に強調されたボタンを順に押していくと、'
         + figName(fig) + 'が出来上がります。')
      : '';
    $('sgAim').hidden = !aimShow;
    $('sgTitle').textContent = navTitle(n);
    $('sgText').textContent = SG_TEXT[n] || '';
    for (var k = 1; k <= SG_STEPS.length; k++) {
      var body = $('sgS' + k);
      if (body) body.hidden = (k !== n);
    }
    /* 🔒 §30-22-4 1: 下敷きの操作（器は1つ）を、いまの段の一番上へ**移す** */
    hzUnderBarTo(n);
    /* 🔒 §30-25-23: 常設の道具の帯（器は1つ）も、いまの段へ**移す**。
     * 🔴 hzUnderBarTo の後＝配置図は #hzUnderBar が .sg-uop-row ごと段へ
     *    移った後でないと、その段の中に .sg-uop-row がまだ無い。 */
    sgToolStripTo(n);
    /* 🔒 §28-14 ①: 地図の〇（上部バーと1つのデータ）とマーカーの種類（形・色）を
     * いまの値で引き直す（案件を開いた直後・マーカーを置いた直後もここを通る）。 */
    if (n === 1) { sgSyncUnderlay(); sgRenderMarks(); }
    if (n === 2) sgSyncOrient();
    // 🔒 §28-4: ③の設定盤は案件の値で引き直す（案件を開いた直後もここを通る）
    if (n === 3) { szSetHost(true); syncSzPanel(); }
    // 🔒 §28-5 A: ④の「使い方1行」は、いま持っている道具の物を出す
    // 🔒 §28-5 B（Step 3）: ④の下敷き〇も、いまの上部バーの値に合わせて出す
    // 🔒 §30-22-3 1: ④へ入った時の下敷き（OpenStreetMap・濃さ 50%）
    if (n === 4) { sgEnter4Underlay(); sgSyncToolHint(); sgSyncUnderlay(); sgSyncEra(); }
    /* 🔒 §29-1 ⑤: 下敷きの〇・紙の向き・［枠を決定］の文言・写真の濃さを引き直す
     * （どれも上部バー／シート帯と**同じ値**を見るだけ・新しい状態は持たない）。 */
    if (n === 5) { sgSyncOrient(); sgSyncImg(); }
    /* 🔒 §30-22-4 1: 下敷きの〇・濃さ・撮影時期・PLATEAU の一言は**配置図の全段**
     * （器が段ごとに移るので、どの段でもいまの値に合わせる）。 */
    if (fig === 'haichizu') { sgSyncUnderlay(); sgSyncEra(); sgSyncPlateauNote(); }
    // 🔒 §29-1 ⑥〜⑧: 選択中の道具の「使い方1行」（④と同じ出どころ）
    if (n >= 6) sgSyncToolHint();
    // 🔒 §30-22-4 9: ⑦の保管場所マークの書式（新しく置く印の既定）
    if (n === 11) sgRenderStorageFmt();
    // 🔒 §29 Step 7 ⑪: 凡例の4行は1度だけ作る（段へ入る前に開いても空にしない）
    if (n === 11) labelBuildRows('lb');
    /* 🔒 §30-27-1 7: 「まとめる／別々」の2択は廃止（まとめの可否は PDF・画像の窓の中
     * ＝ sgComboInfo().ok を exPickRender が読む）。
     * 🔒 §30-31-3 2: ⑧（step 12）の「提出前チェック」の一覧も廃止した。 */
    navRenderPins();             // ✓ と押している間の色を2か所で揃える（§18-ap）
    sgRenderFoot(n);
    sgRenderStatus();
    /* 🔒 §30-12-4: 「こんな時に押すボタン」の開閉（段ごとに覚えた値・既定は閉じ）と
     * 「いま: …」。中の部品を組み終えてから（値は部品の状態を見るため）。 */
    sgMoreEnter(n);
    // 🔒 §30-2 / §30-3: 案内数字（左肩のバッジ）と字幕は、面を組み終えてから
    /* 🔒 §30-13-7 2/3: 面を組み直したここは「字幕を出す時」＝置き場所を引き直す契機
     * （同じ文でも引き直す・段を移る途中の古い置き場所を残さない）。 */
    sgCap.replace = true;
    sgRenderNums();
    /* 🔒 §30-22-1 1: 枠を出すか（①では出さない）は**段で決まる**ので、
     * 段を移った時にも地図の上を引き直す（地図を動かすまで古いままにしない）。 */
    if (state.map && state.current) renderOverlay();
  }

  /* 🔒 §30-31-3 2（2026-09-15 オーナー指示）: 配置図⑧の「提出前チェック」の一覧
   * （旧 #sgChkBox / sgRenderCheck）は**出さない**。所在図だけを作った時に
   * 配置図の「出入口が無い」等が並ぶのは当然で、案内として要らないため
   * （判定の haichizuIssues も、書き出し前の窓と一緒に廃止した）。 */

  /** 🔒 §28-5 A: 選択中の道具の「使い方1行」（道具メニューの #toolHint と同じ出どころ）。
   *  🔒 §29: 出す所が④⑦⑧の3か所になったので、class で全部まとめて入れる（文言は1つ）。 */
  function sgSyncToolHint() {
    var t = (state.editor && state.editor.tool) || 'select';
    var txt = TOOL_HINT[t] || '';
    document.querySelectorAll('#sideNav .js-toolhint').forEach(function (el) {
      el.textContent = txt;
    });
  }

  /**
   * 🔒 §29-1 ⑤: 取り込んだ写真まわりの見た目を引き直す。
   * 🔴 濃さの欄は**4か所目**（上部バー・右パネル・📷ウィザード・ここ）だが
   *    値は1つ（syncImgOpacityUI が唯一の出どころ）。ここは出し入れだけ。
   */
  function sgSyncImg() {
    var wrap = $('sgImgOpWrap'), pick = $('sgImgPick'), il = state.imglay;
    if (!wrap || !pick) return;
    var has = !!(il && il.hasImage());
    wrap.hidden = !has;
    pick.textContent = has ? '別の写真に差し替える' : '写真を取り込む';
    if (!has) { if (state.nav) sgMoreSync(); return; }
    var m = il.getMeta();
    if (m) syncImgOpacityUI(Math.round((m.opacity === undefined ? 0.7 : m.opacity) * 100));
    /* 🔒 §30-12-4 2: ボタンの「いま: 写真あり・濃さ …」も引き直す */
    if (state.nav) sgMoreSync();
  }

  /**
   * 下部のボタン列（段ごとに組み立て直す。押した先は data-act の委譲で受ける）。
   * 🔒 §30-12-2 2: ガイダンス面では**固定の primary を付けない**。青は
   *    data-sgstate="next"（sgRenderNums）だけが出す＝青の出どころは1つ。
   *    保存後の［案件一覧に戻る］だけは番号が無いので primary のまま。
   */
  function sgRenderFoot(n) {
    var back = { act: 'back', label: '‹ 戻る', cls: 'sg-back' };
    var spec;
    if (n === 1) {
      spec = [{ act: 'next', label: '次へ ›', disabled: !navBothPins() }];
    } else if (n === 2) {
      var fixed = sgFrameFixed();
      spec = [back,
        { act: 'szYes', label: '確認する（所在図を作る）', disabled: !fixed },
        /* 🔒 §18-f: 「確認を後にするだけで所在図は裏で作る」逃げ道は残す
         * （⑪で所在図の欄が空にならないため）。主役は［確認する］のまま */
        { act: 'szNo', label: 'あとで確認する ›', cls: 'ghost' }];
    } else if (n === 3) {
      // 🔒 §28-4: 量が決まったら④（1つ1つの描き足し）へ
      spec = [back, { act: 'next', label: '決定 ›' }];
    } else if (n === 4) {
      /* 🔒 §30-13-2 所在図④-2: 下部は［‹ 戻る］［所在図プレビュー］の2つだけ。
       * 🔴 ［配置図ガイダンスへ］は削除した（行き先はプレビュー下部の
       *    ［配置図ガイダンスへ進む］＝§30-13-3 に移した）。 */
      spec = [back, { act: 'szPrev', label: '所在図プレビュー' }];
    } else if (n === 5) {
      /* 🔒 §29-1 ⑤: 枠が決まるまで進めない（何が紙になるか決まっていない）。
       * 🔒 §30-1: 配置図の①なので［戻る］は置かず、代わりに
       *    ［所在図ガイダンスへ］の小さな文字リンクを左に置く（図をまたぐ移動）。 */
      spec = [{ act: 'toSz', label: '所在図ガイダンスへ', cls: 'sg-link' },
              { act: 'next', label: '次へ ›', disabled: !sgFrameFixed() }];
    } else if (n === 6) {
      /* 🔒 §29-1 ⑥: 輪郭が1つ要る。
       * 🔒 §30-25-11: 確定しても自動では進まない（進むのはこの［次へ］だけ）。 */
      spec = [back, { act: 'next', label: '次へ ›', disabled: !fillTargetPolygon() }];
    } else if (n === 7) {
      // 🔒 §29-1 ⑦: 駐車枠が1つ以上
      spec = [back, { act: 'next', label: '次へ ›', disabled: !navFrameCount() }];
    } else if (n === 12) {
      /* 🔒 §18-ao: ［ガイダンスを閉じる］= ガイダンスを閉じるだけ（データには一切触れない）。
         🔴 旧名「完了」から改名（§19-3・2026-08-22）。「完了」は案件ステータスの
         語になったため、閉じる操作に使うと「案件が完了になる」と誤読される。
         保存せず閉じたい人・保存後に編集を続けたい人の両方の出口として、
         保存前後どちらの状態にも置く。主役は保存系のまま（無印）。 */
      /* 🔒 §30-27-1 7: 保存のボタンは段の中の［PDFにして保存］（#sgSavePdf）1つだけ
       * （下部からは外した＝同じ事をする青いボタンが2つ並ばないように）。 */
      var closeBtn = { act: 'close', label: 'ガイダンスを閉じる' };
      spec = state.nav.saved
        ? [back, { act: 'toList', label: '案件一覧に戻る', cls: 'primary' }, closeBtn]
        : [back, closeBtn];
    } else {
      // 🔒 §29-1 ⑧⑨⑩⑪: 道路・道路幅・出入口・ラベルは任意（条件なし）
      spec = [back, { act: 'next', label: '次へ ›' }];
    }
    $('sgFoot').innerHTML = spec.map(function (b) {
      return '<button type="button" data-act="' + b.act + '"'
        + ' class="' + (b.cls || '') + '"'
        + (b.disabled ? ' disabled' : '') + '>' + b.label + '</button>';
    }).join('');
    // 🔒 §28-1 ③: 押せない理由を**平文で**ボタンの下に出す
    var why = sgWhyText(n);
    $('sgWhy').textContent = why;
    $('sgWhy').hidden = !why;
  }

  function sgAct(act) {
    if (!state.nav) return;
    switch (act) {
      case 'back': navBack(); break;
      case 'next': navGo(state.nav.step + 1); break;
      case 'szYes':
        navSetStatus('所在図を作っています…');
        navRunShozaizu();        // 生成 → ③へ
        break;
      case 'szNo': navSkipShozaizu(); break;
      /* 🔒 §30-13-2 所在図④-2 / §30-13-3: ⑧＝所在図だけのプレビュー。
       * 下部のボタン（PDF保存・画像保存・配置図ガイダンスへ進む…）はここから出した時だけ出る。 */
      case 'szPrev': navShowPreview('shozaizu'); break;
      /* 🔒 §30-1: 配置図①から所在図の案内へ戻る（保存された段・無ければ①）。
       * 🔴 図をまたぐ移動なので「戻る」扱い＝地図の寄せ直しはしない（§18-f）。 */
      case 'toSz': navGo(navStepOf('shozaizu', navSavedDisp('shozaizu') || 1),
                         { back: true }); break;
      /* 🔒 §30-27-1 7: ⑫の savePdf / savePng は廃止（段の中の［PDFにして保存］
       * ＝ exPickOpen('pdf') 1つに寄せた）。 */
      case 'toList': backToList(); break;
      // 🔒 §18-ao/§19-3: 閉じる＝ガイダンスを閉じるだけ（［🧭 所在図ガイダンス］［🧭 配置図ガイダンス］で出し直せる）
      case 'close': navClose(); break;
    }
  }

  /* ============ 案内数字（🔒 §30-2 / §30-11）と字幕（🔒 §30-12-3）============
   * オーナー指示（🔒 §30-12-1）: 「青色に強調されたボタンを順に押していくと、
   * 所在図が出来上がります。」＝**やること**にだけ番号を付け、次に押す1つを青くする。
   *
   * 🔴 番号の表は**ここ1か所**。番号の割り当ては §30-11 の表（所在図①〜⑧・
   *    配置図①〜⑯＝🔒 §30-25-31 で②の［次へ］が増えて⑮→⑯）、
   *    字幕の指示文は §30-12-3 の表。画面（バッジ）も字幕も、この表だけを読む。
   * 各項目:
   *   step     … 中の通し番号（1〜12）。表示の番号（①〜⑯）は配列の添字
   *   sel      … その番号が指す**押す部品**（文字列 or 配列。同じ番号が複数の部品を
   *              指すことがある＝配置図⑯「PDF／画像」）
   *   label    … その番号の短い名前（§30-11 の表の見出し・読む人のための控え。
   *              🔒 §30-12-3 で字幕は say だけになったので画面には出ない）
   *   say      … 字幕の指示文（🔒 §30-12-3 の表の文言をそのまま・1か所）
   *   btn      … 字幕の箱の中（文の下）に出す小さなボタン（🔒 §30-14-3）。
   *              { label: 見せる文字, act: SG_CAP_ACT の鍵 }。持たない番号には出ない
   *   optional … 押さなくても進める部品（番号を薄く出し、次の指し先にしない）
   *   done()   … 済んだかを**既存の状態から**判定する。無い項目は「押した瞬間に済み」
   *              （state.sgHit・画面だけの記録で案件には保存しない）
   */

  /** ⑬保管場所マークの有無（🔒 §30-25-31 で⑫→⑬。⑦の状態の一言と同じ数え方・🔒 §16-5 A） */
  function sgHasStorage() {
    return objectsOf('haichizu').some(function (o) {
      return (o.type === 'rect' && o.storage)
          || (o.type === 'stampGroup' && o.storage && Object.keys(o.storage).length);
    });
  }
  /* 🔒 §30-11（2026-09-09）: ［「出入口」の文字を置く］は「やること」から外れた
   * （やることは幅矢印だけ）ので、その済み判定 sgHasGateText は削除した。 */
  /** その段の［次へ］が済んだ＝もう先の段にいる（🔒 §30-2「済んだ」の判定） */
  function sgPast(k) { return function () { return !!(state.nav && state.nav.step > k); }; }

  var SG_NUM = {
    /* ---- 所在図①〜⑧（🔒 §30-11 の表・「やること」だけ／say は §30-12-3 の表） ---- */
    shozaizu: [null,
      /* 🔒 §30-39-4（2026-09-19 オーナー指示）: ①＝本拠の検索・②＝駐車場の検索。
       * 検索すると◎が置かれるので、済み判定はその地点があるかで見る。
       * 🔴 ［○○マーカー設置］は**番号なし**（§30-39-4 4）＝住所で見つからない時・
       *    置き直したい時の手置き。案内数字は［検索］に付く。 */
      { step: 1, sel: '#sgSearchHome', label: '使用の本拠住所を検索',
        /* 🔒 §30-25-23 4: 最初の案内に「いつでも選択に戻れる」の一言を足す */
        say: '使用の本拠の住所を入力し、／［検索］を押してください。'
           + '／その場所に使用の本拠の◎マーカーが置かれます'
           + '／／住所で見つからない時は［使用の本拠マーカー設置］を押してから地図をクリック'
           + '／／描いた物を動かしたい時は、上の［選択］をいつでも押せます',
        done: function () { return !!(state.current && state.current.points.home); } },
      /* 🔒 §30-13-1: ②④⑤⑦⑧の指示文はこの表で差し替え済み（§30-12-3 の表の上書き）。
       * 🔒 §30-17-1: さらに改行の印「／」・行間つき改行の印「／／」を入れた（表が正）。 */
      { step: 1, sel: '#sgSearchLot', label: '駐車場住所を検索',
        say: '駐車場の住所を入力し、／［検索］を押してください。'
           + '／その場所に駐車場の◎マーカーが置かれます'
           + '／／住所で見つからない時や置き直したい時は、'
           + '／［駐車場マーカー設置］を押してから地図をクリック',
        done: function () { return !!(state.current && state.current.points.lot); } },
      { step: 1, sel: '#sgFoot button[data-act="next"]', label: '次へ', fin: true,
        say: 'マーカーの設置場所はドラッグで修正できます。／／よければ［次へ］を押してください',
        done: sgPast(1) },
      { step: 2, sel: '#sgFix', label: '枠を決定',
        say: '青い枠の中が所在図として紙に出ます。／よければ［枠を決定］を押してください。'
           + '／／紙の向きを変えると2つのマーカーが見やすくなります。'
           + '／また［2つのマーカーが入るように地図を動かす］を押すと、'
           + '／自動でズームレベルを調整します'
           /* 🔒 §30-23: 枠が狭いと周りの目印が枠の外に出て紙に載らない */
           + '／拡大しすぎると周りの目印が枠に入りません',
        done: sgFrameFixed },
      { step: 2, sel: '#sgFoot button[data-act="szYes"]', label: '確認する', fin: true,
        say: '［確認する］を押してください。／所在図を自動で作ります（数秒かかります）',
        done: sgPast(2) },
      { step: 3, sel: '#sgFoot button[data-act="next"]', label: '決定', fin: true,
        say: '文字の量がちょうどよければ［決定］を押してください。／／次で細かい修正ができます。'
           + '／交差点を増やしたり、文字の位置や建物名の位置を動かしたりできます。'
           + '／／ここでは、80％完成を目指してください',
        done: sgPast(3) },
      /* 🔒 §30-13-2 所在図④-2/3: ⑧は**下部の［所在図プレビュー］**。
       * 🔒 §30-25-29（2026-09-14 オーナー指示）: 押したら薄い色（済み）にする。
       * 🔴 done() を持たせない＝「押した記録」（state.sgHit・sgMarkHit）で済みになる
       *    ＝鍵の作法は他の番号と同じ1か所。⑧は最後の番号なので次の青は無い。
       *    プレビューを閉じても薄いまま（案件を開き直すと sgResetHits で戻る）。 */
      { step: 4, sel: '#sgFoot button[data-act="szPrev"]', label: '所在図プレビュー', fin: true,
        say: '左メニューの「文字や線を足す・消す・動かす」を開くと、／文字の位置や'
           + '建物名の位置を動かせる選択ツール、／必要のない文字や線を消す消しゴムツール、'
           + '／文字を追記する文字ツールが使えます。／／直線ツールで道路を描く、'
           + '四角ツールで建物を描くこともできます。／／「下敷きの地図を変える」と、'
           + '地図から得られる情報を元に／書き加えることができます。'
           + '／／できあがったら［所在図プレビュー］を押してください' }
    ],
    /* ---- 配置図①〜⑯（同上・🔒 §30-25-31 で②の［次へ］が増えて⑮→⑯） ---- */
    haichizu: [null,
      /* 🔒 §30-17-1: ①の文は「駐車場を枠内に入れ…」の段落を足した（表が正）。
       * 🔒 §30-22-4 5（2026-09-13 オーナー指示）: 配置図の字幕は**改行を減らす**
       *   （「／」は文の区切り2〜3か所まで・「／／」は1段落まで）。🔴 文言は変えない。 */
      { step: 5, sel: '#sgFix5', label: '枠を決定',
        /* 🔒 §30-25-23 4: 最初の案内に「いつでも選択に戻れる」の一言を足す */
        say: '青い枠の中が紙に出ます。／よければ［枠を決定］を押してください。'
           + '／／駐車場を枠内に入れ、必要であれば公道やその他構造物を枠内に'
           + '入れてください。／この枠内が紙に出ます'
           + '／／描いた物を動かしたい時は、上の［選択］をいつでも押せます',
        done: sgFrameFixed },
      { step: 5, sel: '#sgFoot button[data-act="next"]', label: '次へ', fin: true,
        say: '［次へ］を押してください', done: sgPast(5) },
      /* 🔴 §30-12-2 2: 青はボタン本体に出すので、指す先は器（.sg-tools）ではなく
       *    ［多角形］のボタンそのもの。 */
      /* 🔒 §30-14-3: ③の指示文（正典の文そのまま）＋字幕の中のボタン
       *   ［多角形ツールの使い方動画を見る］（btn＝この表の1か所だけ）。 */
      /* 🔒 §30-22-4 5: 「／」は3か所・「／／」は1段落まで（文言はそのまま）。
       * 🔒 §30-25-12 2 ②（2026-09-13 オーナー指示）: 道具は所在図④と同じアイコン部品に
       *   なった＝指す先は `.tool[data-tool="polygon"]`、呼び名は［多角形］。 */
      { step: 6, sel: '#sgS6 .tool[data-tool="polygon"]',
        label: '多角形',
        say: '［多角形］を押してから、駐車場の敷地の角を順にクリックし、'
           + '最後に Enter を押してください。／／マウスホイールで拡大すると描きやすいです。'
           + '地図をドラッグして駐車場の枠を描きやすくできます。'
           + '／多角形の頂点を修正したい場合は、バックスペースキーで戻れます。'
           + '／植え込みや木、駐車場の土地にある構造物を描きたい場合は、'
           + '次のガイダンスで描きます。／まずは駐車場の土地を囲います',
        btn: { label: '多角形ツールの使い方動画を見る', act: 'vidPolygon' },
        done: function () { return !!navPolyCount(); } },
      /* 🔒 §30-25-31（2026-09-14 オーナー指示）: 輪郭を描き終えたら［次へ］にも
       * 番号を付ける（多角形を1つ描くと④が緑＝次に押す物になる）。
       * 🔴 これで配置図の案内数字は全部で⑯になり、以降の番号が1つずつ後ろへずれた。 */
      { step: 6, sel: '#sgFoot button[data-act="next"]', label: '次へ', fin: true,
        say: '輪郭が描けたら［次へ］を押してください', done: sgPast(6) },
      /* 🔒 §30-14-4: ⑤の指示文（正典の文そのまま）。
       * 🙋 ［駐車枠を描くツールの使い方を見る］はオーナーが動画を撮ってから
       *    同じ仕組み（btn）で足す。今は文章だけ。 */
      /* 🔒 §30-25-12 2 ③（2026-09-13 オーナー指示）: ［駐車枠（四角）］は消し、
       * 所在図④と同じ［駐車枠］（data-tool="stamp"・押してから地図をクリック）を指す。 */
      { step: 7, sel: '#sgS7 .tool[data-tool="stamp"]', label: '駐車枠',
        say: 'ここでは駐車枠を描きます。／［駐車枠］を押してから、'
           + '地図の置きたい場所をクリックしてください。'
           + '／／まわりに出る ＋ を押すと、その向きに枠が増えます',
        done: function () { return !!navFrameCount(); } },
      /* 🔒 §30-18-2: ［保管場所マーク］は配置図⑦（step 11）へ移した。
       * ⑥は「枠が描けたら［次へ］」（🔒 §30-25-31 で⑤→⑥）。 */
      { step: 7, sel: '#sgFoot button[data-act="next"]', label: '次へ', fin: true,
        say: '枠が描けたら［次へ］を押してください', done: sgPast(7) },
      /* 🔒 §30-18-1／30-18-3: ⑦（🔒 §30-25-31 で⑥→⑦）は「どれか1つ」の番号＝
       * 同じ番号を3つのボタンに付け、
       * 3つとも**薄い色**（one:true → data-sgone → CSS）。済み判定は道路の線が1本以上
       * （直線・多角形・曲線のどれでも navRoadCount が数える）。 */
      /* 🔒 §30-25-34 2（2026-09-14 オーナー指示「強調表示されていない。薄くてよい。
       * よく使うはず」）: ［地図の道路を写す］も「どれか1つ」の仲間に入れる＝
       * 4つとも同じ番号・薄い緑。済み＝道路の線が1本以上（navRoadCount は
       * source:'roadauto' の縁も数える・§30-25-24 1）。 */
      { step: 8, one: true, label: '地図の道路を写す／直線／多角形／曲線（前面道路）',
        /* 🔒 §30-25-12 2 ④: 3つとも所在図④と同じアイコン部品になった */
        sel: ['#sgRoadAuto',
              '#sgS8 .tool[data-tool="line"]',
              '#sgS8 .tool[data-tool="polygon"]',
              '#sgS8 .tool[data-tool="curve"]'],
        /* 🔒 §30-38-5 2: 頂点を足せることを1行足す（文の置き場所はこの表1か所） */
        say: '［地図の道路を写す］を押すと、枠のまわりの道路が線で入ります。'
           + '／ずれていれば線の角をドラッグで直してください。'
           + '／描いた線の上で Alt＋クリックすると頂点が増え、形を直せます'
           + '／／手で描くなら［直線］［多角形］［曲線］のどれかで前面道路の縁を描きます',
        done: function () { return !!navRoadCount(); } },
      /* 🔒 §30-38-7 1: ⑧でも頂点を足せることをもう一度案内する（オーナー指示） */
      { step: 8, sel: '#sgFoot button[data-act="next"]', label: '次へ', fin: true,
        say: '地図の道路を写した場合、枠のまわりの道路幅を変更できます。'
           + '／Alt＋クリックで線に頂点を足し（頂点の上で Alt＋クリックなら消す）道路の形を柔軟に変更できます。'
           + '／／よければ［次へ］を押してください', done: sgPast(8) },
      /* 🔒 §30-18-4: ⑨⑪（🔒 §30-25-31 で⑧⑩→⑨⑪）の指示文はトグル
       * （自動入力／幅入力）と文字を置く欄を案内する */
      { step: 9, sel: '#sgRoadArrow', label: '幅矢印（道路幅）',
        /* 🔒 §30-22-4 6: 文字の定型は言葉のボタン（［道路］［公道］…）になったので
         * 文中の呼び名もそれに合わせる（ボタンの文字と字幕を食い違わせない）。 */
        /* 🔒 §30-29-7 2: 末尾に「幅を入れなければ矢印だけ」の一言を足す
         * （「幅を入れてください」で止める作法を差し替えたため）。 */
        say: '道幅は「自動入力」か「道幅入力」を選び、／［幅矢印］を押して'
           + '道路の端から端まで引いてください（2回クリックでもドラッグでも引けます）。'
           + '／／道路の文字は下の［道路］などで置けます'
           + '／／幅の数字を入れなければ、矢印だけが入ります'
           + '（後から矢印を選んで「表示」欄に数字を入れられます）' },
      { step: 9, sel: '#sgFoot button[data-act="next"]', label: '次へ', fin: true,
        say: '［次へ］を押してください', done: sgPast(9) },
      { step: 10, sel: '#sgGateArrow', label: '幅矢印（出入口）',
        /* 🔒 §30-29-7 2: 末尾に「幅を入れなければ矢印だけ」の一言を足す（⑨と同じ） */
        say: '出入口の幅は「自動入力」か「出入口の幅を入力」を選び、／［幅矢印］を押して'
           + '出入口の端から端まで引いてください（2回クリックでもドラッグでも引けます）。'
           + '／／出入口の文字は下の［出入口］などで置けます'
           + '／／幅の数字を入れなければ、矢印だけが入ります'
           + '（後から矢印を選んで「表示」欄に数字を入れられます）' },
      { step: 10, sel: '#sgFoot button[data-act="next"]', label: '次へ', fin: true,
        say: '［次へ］を押してください', done: sgPast(10) },
      /* 🔒 §30-18-5: ⑬［保管場所マーク］（🔒 §30-25-31 で⑫→⑬）は
       * 配置図③からこの段（配置図⑦）へ移した */
      { step: 11, sel: '#sgS11 .sg-tool[data-tool="storage"]', label: '保管場所マーク',
        say: '［保管場所マーク］を押してから、／借りる枠をクリックしてください',
        done: sgHasStorage },
      /* 🔒 §30-22-4 10（2026-09-13 オーナー指示）: ［配置］は**ワンクリック**
       * （対象の駐車枠をクリックすると、その枠の右上にラベルが置かれる）。 */
      /* 🔒 §30-25-36 2: ボタン名は［保管場所ラベル配置］（LABEL_PLACE_JA が出どころ） */
      { step: 11, sel: '#sgLabelPlace', label: LABEL_PLACE_JA,
        say: '長さ・幅の数値を入れてから［' + LABEL_PLACE_JA + '］を押し、'
           + '／対象の駐車枠をクリックしてください（ラベルはドラッグで動かせます）',
        done: function () { return !!navLabelCount(); } },
      { step: 11, sel: '#sgFoot button[data-act="next"]', label: '次へ', fin: true,
        say: '［次へ］を押してください', done: sgPast(11) },
      /* 🔒 §30-12-7 2: ⑯（🔒 §30-25-31 で⑮→⑯）は［PDFにして保存］**だけ**を指す
       * （青は常に1つ）。
       * 🔒 §30-27-1 7: 番号の行き先は**段の中の**［PDFにして保存］（#sgSavePdf）。
       *    下部の savePdf / savePng は廃止した。
       * 済み判定は従来どおり state.nav.saved＝画像で保存しても✓になる（exPickDone）。 */
      { step: 12, sel: '#sgSavePdf',
        label: 'PDFにして保存',
        say: '［PDFにして保存］を押すと、出す紙を選ぶ窓が開きます。'
           + '／所在図と配置図を1つの PDF にまとめることもできます。これで完成です。'
           + '／／画像で出したい時は、［プレビュー］を開いて下の［画像］を押してください',
        done: function () { return !!(state.nav && state.nav.saved); } }
    ]
  };
  /* 🔒 §30-12-3 の表の最後の行（保存後）。字幕はここ1か所から出る。 */
  var SG_SAY_SAVED = '完成です。／［案件一覧に戻る］を押してください';

  /* ============ 「こんな時に押すボタン」（🔒 §30-12-4）============
   * 押さなくても図が出来る機能は、**1機能＝1つのボタン**にする。
   * 折りたたみ（<details>）と「付録」の語は §30-12 で廃止した
   * （オーナー: 「クリックで展開する事がまったく分かりにくい」「『付録』は辞めよう」）。
   *
   * 見た目（§30-12-4 1〜3）:
   *   ボタン本体 … 横いっぱい・白地・灰枠・角丸。中は3行
   *     1行目 title（太字）＋右端「開く ▼」／「閉じる ▲」
   *     2行目 when（灰・どんな時に押すか）
   *     3行目 「いま: …」（now() を持つ機能だけ・閉じていても見える）
   *   箱     … ボタンの真下（薄い地色・枠線が繋がる）。一番下にも小さく「閉じる ▲」
   *
   * 🔴 文言はここ1か所（§30-12-5 の表から）。
   *   key   … 開閉を覚える鍵（段の中で一意）
   *   title … 利用者がしたい事の名前
   *   when  … どんな時に押すか
   *   now() … 今の値（無い機能は行を出さない）
   *   warn()… 注意（出た瞬間の1回だけ自動で開く・§30-11-b 5）
   *   sel   … 箱へ**移す**部品（index.html の物・複製しない＝id も配線もそのまま）
   * 🔴 並びは index.html の並び（§30-12-5）がそのまま出る
   *    （ボタンは sel の1つ目の部品があった場所へ挿す）。
   */

  /** 今の印の形と色（①の「いま:」）。値の出どころは markOf 1か所。
   * 🔒 §30-22-1 4〜5: ▼が地点ごとになったので、1地点ぶんだけを返す。
   * 🔒 §30-22-1 4 (c): 多角形で囲んである時はそれを言う（形と色の欄より強い情報）。 */
  function sgNowMarkText(key) {
    var cs = (Editor.MARK && Editor.MARK.colors) || [];
    /* 🔒 §30-24-1: 印の種類が「多角形」なら、形と色（◎■）より強い情報なのでそれを言う */
    if (markOf(key).shape === 'polygon') return '多角形（建物や土地の形で囲んである）';
    var m = markOf(key), sym = '', col = '';
    MARK_SHAPES.forEach(function (s) { if (s.key === m.shape) sym = s.ja; });
    cs.forEach(function (c) { if (c.key === m.color) col = c.ja; });
    /* 🔒 §30-25-40 1: 大きさの言葉は出さない（形と色だけ）。
     * 大きさは印の右下のつまみ・右パネルで変える物になった。 */
    return (m.shape === 'none') ? sym : (sym + '・' + col);
  }

  /** 🔒 §30-22-1 4: その地点の主役の印が多角形か（所在図のどれかの紙にあれば真） */
  function sgHasMainPoly(key) {
    return sheetsOf('shozaizu').some(function (sh) {
      return (sh.objects || []).some(function (o) {
        return o && o.role === 'mainmark' && o.type === 'polygon'
            && (o.markRole || 'home') === key;
      });
    });
  }

  /**
   * 🔒 §30-24-1 / 🔒 §30-32-5（2026-09-15 オーナー指示「本拠・駐車場を多角形で
   * 描いた場合、印は自動で無しに。いま基本◎になっているから、多角形で描いたのに
   * ◎が出る」）: 主役の多角形の有無と印の種類を**双方向**に揃える。
   *   ・その地点の紙に主役の多角形が**ある**間は印の種類＝'polygon'（◎■を描かない）
   *   ・多角形が**全部消えたら**◎へ戻す（印が1つも無い状態を作らない）
   * 🔴 順番に関わらず同じ結果にするため、呼ぶ契機は4つ（§30-32-5 2）:
   *    ①図形が変わった時（editor の change＝消しゴム・Delete・戻す・描いた）
   *    ②マーカーを置いた直後（onNavPinPlace）
   *    ③同一住所を置いた直後（placeSamePoint）
   *    ④案件を開いた直後（openCase）
   * 🔴 書き先は案件の points[key].mark（まだ置いていない地点は画面の控え markPick）
   *    の1か所＝組み立ては markNext。
   * 🔴 ■・印なしは触らない（多角形が無い時に◎へ戻すのは「多角形だった時」だけ）。
   * 🔒 §30-36（不具合の直し・2026-09-15）: **同一住所の時は home だけ**を評価する。
   *    同一住所の▼で描く多角形は markRole:'home' なので lot 側には多角形が無く、
   *    lot を評価すると「◎」と判定される → 同一住所の写し（本拠側の値を両方へ）で
   *    home の印まで◎に戻る → 直後の applyMarkChoice('home') が「印が多角形でない
   *    なら多角形を全部取り除く」（§30-24-1）で、いま描いた多角形を消していた。
   *    写し（両方へ）と applyMarkChoice の呼び方は従来どおり。
   */
  function syncMarkShapeFromPolys() {
    var c = state.current;
    if (!c) return 0;
    var n = 0;
    (c.points.same ? ['home'] : ['home', 'lot']).forEach(function (key) {
      var want = sgHasMainPoly(key) ? 'polygon' : 'circle';
      var now = markOf(key).shape;
      if (now === want) return;
      if (want === 'circle' && now !== 'polygon') return;   // ■・印なしはそのまま
      var p = c.points[key];
      // 🔒 §30-25-37 3: 形が変わっても大きさ（scale）・縦横は保つ（markNext が組み立てる）
      var next = markNext(key, { shape: want });
      if (p) p.mark = next; else state.markPick[key] = next;
      /* 🔒 §30-24-2: 同一住所の時は印が1つ（本拠側）＝値を両方へ写す */
      if (c.points.same && c.points.home && c.points.lot) {
        c.points.home.mark = markCopy(next);
        c.points.lot.mark = markCopy(next);
      }
      applyMarkChoice(key);
      if (c.points.same) applyMarkChoice(key === 'home' ? 'lot' : 'home');
      n++;
    });
    if (n) { sgRenderMarks(); renderOverlay(); Store.autosave(c); }
    return n;
  }

  /**
   * 🔒 §30-24-1（正典「最初の物を消したら次の物の重心へ」）: その地点の多角形の
   * **先頭**（＝ピンを持つ「最初に描いた物」）が入れ替わったら、ピンを新しい先頭の
   * 重心へ動かす。
   * 🔴 「入れ替わった」は**先頭の id**で見る。重心がずれただけ（＝ドラッグ）の時は
   *    editor の syncMarkPin が既にピンを動かしているので、ここでは何もしない
   *    （二重に動かすと2つ目以降が先頭の上へ飛ぶ）。
   * 🔴 並び（どれが先頭か）の出どころは Editor.mainPolysOf 1か所。
   * 🔴 見るのは**いま開いている所在図の紙**（change はその紙でしか起きない）。
   *    先頭の id の控えは画面の状態（state.mainPolyHead）で、案件には保存しない。
   */
  function syncMainPolyHead() {
    var c = state.current;
    if (!c || !state.editor || !Editor.mainPolysOf) return 0;
    var objs = objectsOf('shozaizu'), n = 0;
    ['home', 'lot'].forEach(function (key) {
      var list = Editor.mainPolysOf(objs, key);
      var head = list.length ? list[0] : null;
      var prev = state.mainPolyHead[key];
      state.mainPolyHead[key] = head ? head.id : null;
      if (!head || !prev || prev === head.id) return;   // 先頭は変わっていない
      var ctr = Editor.polyCentroid(head.points);
      var p = c.points[key];
      if (!ctr || !p || (ctr.lat === p.lat && ctr.lng === p.lng)) return;
      if (state.editor.movePin(key, ctr.lat, ctr.lng)) n++;
    });
    return n;
  }

  /* 🔒 §30-14-1: 「いま: A4 縦」を▼の3行目に出す sgNowOrientText は用が無くなった
   * （②⑤とも［紙の向きを変える］の2行目＝sgSyncOrient が書く）ので削除した。 */

  /**
   * 今の下敷き（①④⑤の「いま:」）＋写真なら撮影時期。
   * 🔴 名前は UNDERLAYS の label（唯一の出どころ・🔒 §30-11-b 6）。撮影時期も
   *    sgSyncEra と同じ値（固定は UNDERLAYS.photoEra・地理院 写真だけ eraState.gsiPhoto）。
   */
  function sgNowUnderText() {
    if ($('underlayOff') && $('underlayOff').checked) return '地図なし';
    var id = $('underlaySel') ? $('underlaySel').value : '';
    var u = underlayById(id);
    if (!u) return '';
    var era = sgEraTextOf(id);
    return u.label + (era ? ('・' + era) : '');
  }

  /** 取り込んだ写真の有無と濃さ（⑤の「いま:」）。値は imglay のメタ1か所 */
  function sgNowImgText() {
    var il = state.imglay;
    if (!(il && il.hasImage())) return '';
    var m = il.getMeta() || {};
    return '写真あり・濃さ '
      + Math.round((m.opacity === undefined ? 0.7 : m.opacity) * 100) + '%';
  }

  /** その下敷きの撮影時期の文言（無い＝地図系なら空）。sgSyncEra と同じ出どころ */
  function sgEraTextOf(id) {
    if (id === 'gsi-photo') return eraState.gsiPhoto || '';
    var u = underlayById(id);
    return (u && u.photoEra) || '';
  }

  /* 🔒 §30-22-4 1 で廃止: sgEraUnknown（▼「下敷きの写真を変える」を自動で開く条件）。
   * 下敷きの操作は常に見えている（#hzUnderBar）ので「開く条件」そのものが要らない。
   * 撮影時期は〇の行にそのまま出る（sgSyncEra）・PLATEAU 範囲外も行の中の一言。 */

  var SG_MORE = {
    shozaizu: {
      1: [
        { key: 'map', title: '地図を変える',
          when: 'マーカーを置く場所が分かりにくいとき'
              + '（道路名やバス停の名前なら OpenStreetMap、お店や建物の名前なら Google マップ）',
          now: sgNowUnderText, sel: ['#sgMoreSzMap'] },
        /* 🔒 §30-22-1 4〜5（2026-09-13 オーナー指示）: 印の設定は**地点ごと**の▼にして、
         * それぞれの［○○マーカー設置］の**直下**へ置く（旧・共通の1つは廃止）。 */
        { key: 'markHome', title: '使用の本拠の印を変える',
          when: '紙に出る印を変えたいとき（形と色／建物や土地の形を多角形で囲む／印なし）',
          now: function () { return sgNowMarkText('home'); },
          sel: ['#sgMoreSzMarkHome'] },
        { key: 'markLot', title: '駐車場の印を変える',
          when: '紙に出る印を変えたいとき（形と色／建物や土地の形を多角形で囲む／印なし）',
          now: function () { return sgNowMarkText('lot'); },
          sel: ['#sgMoreSzMarkLot'] },
        /* 🔒 §30-24-2（2026-09-13 オーナー指示）: ［同一住所］の直下にも▼。
         * 値は本拠の物（印は1つ）＝同一住所の間はこの▼だけを出す。 */
        { key: 'markSame', title: '印を変える',
          when: '紙に出る印を変えたいとき（形と色／建物や土地の形を多角形で囲む／印なし）',
          now: function () { return sgNowMarkText('home'); },
          sel: ['#sgMoreSzMarkSame'] }
      ],
      /* 🔒 §30-13-2 所在図②: 紙の向きは「こんな時に押すボタン」をやめて、
       * ［紙の向きを変える］＝押すとその場で縦↔横が切り替わる普通のボタンにした
       * （#sgOriToggle・index.html）。②に▼は1つも無い。 */
      2: [],
      /* 🔒 §30-13-2 所在図③: ▼「文字や線を1つずつ直す」は削除
       * （設定盤＋［標準に戻す］＋⑦［決定］だけ）。 */
      3: [],
      /* 🔒 §30-11-b 9: 所在図は写真をなぞらないので「時期不明」は注意にあたらない
       *   ＝ warn は持たない（自動で開くのは配置図①だけ）。 */
      4: [
        { key: 'under', title: '下敷きの地図を変える',
          when: '地理院の写真や Google マップと見比べて確かめたいとき',
          now: sgNowUnderText, sel: ['#sgMoreSzUnder'] },
        { key: 'name', title: '交差点名・バス停名を地図に重ねる',
          when: '名前が合っているか確かめたいとき（見るだけ・紙には出ません）',
          sel: ['#sgMoreSzName'] },
        { key: 'tools', title: '文字や線を足す・消す・動かす',
          when: '自動で描いた図を手直ししたいとき', sel: ['#sgMoreSzTools'] }
      ]
    },
    haichizu: {
      5: [
        /* 🔒 §30-22-4 1（2026-09-13 オーナー指示）: ▼「下敷きの写真を変える」は廃止。
         * 下敷きの操作（種類の〇・濃さ・表示／非表示）は**全段の一番上**に常に出す
         * （器 #hzUnderBar・hzUnderBarTo が段ごとに移す）＝畳まれていて気付かない、
         * 他の段では触れない、という詰まりが両方なくなる。
         * 🔴 §30-11-b 5: 「写真を取り込んだ直後」は**注意ではなく一度きりの合図**
         *   （state.sgMoreImgNew）で、開くのは下の 'img' の方。 */
        { key: 'img', title: '自分で撮った写真・図面を使う',
          when: '現地の写真や図面を持っているとき',
          now: sgNowImgText, sel: ['#sgMoreHzImg'] }
        /* 🔒 §30-14-1: ▼「紙の向きを変える」は廃止（所在図②と同じ
         * ［紙の向きを変える］＝ #sgOri5Toggle を①［枠を決定］の上に置いた）。 */
      ],
      /* 🔒 §30-12-5 配置図②: 注記1本だけなので「こんな時に押すボタン」を作らない */
      /* 🔒 §30-25-12 2 ③（2026-09-13 オーナー指示）: ▼「枠をまとめて置く」
       * （#sgMoreHzStamp）と ▼「枠に番号を付ける」（#sgMoreHzNum）は**廃止**した。
       * 中身（［駐車枠］［番号］［開始番号］［台数を指定して置く…］）はそのまま
       * 「駐車枠」の行に出ている＝所在図④とまったく同じ部品・同じ並び。
       * 🔒 §30-22-4 7: ▼「写真から自動で枠を描く」も消してある（器 #sgMoreHzFill は
       *   hidden のまま残す＝📷 の取り込み・右パネル「枠を並べる」の配線を落とさない）。 */
      7: [],
      /* 🔒 §30-18-3: ▼「曲がった道を描く」は廃止（［直線］［多角形］［曲線］の横並びへ） */
      8: [],
      /* 🔒 §30-18-4／30-18-5: ▼「見本を見る」は廃止。見本（<img class="sg-guide">）は
       * 段の**先頭に常時**出す（index.html の並びがそのまま出る）。 */
      9: [],
      10: [],
      11: []
    }
  };

  /** その段の一覧（無い段は空配列） */
  function sgMoreList(n) { return (SG_MORE[navFigOf(n)] || {})[n] || []; }
  /** その機能の器（ボタン＋箱の入れ物） */
  function sgMoreBox(n, key) { return document.getElementById('sgMore_' + n + '_' + key); }

  /**
   * 🔒 §30-12-4 6: 器を作り、対象の部品を**移す**（1回だけ・bind から呼ぶ）。
   * 🔴 移動なので id も付いている listener もそのまま。閉じている間（hidden）も
   *    値を書く同期（sgSyncUnderlay / sgSyncEra / sgSyncOrient / sgRenderMarks /
   *    szSetHost / syncImgOpacityUI）は従来どおり動く。
   */
  function sgBuildMore() {
    ['shozaizu', 'haichizu'].forEach(function (fig) {
      Object.keys(SG_MORE[fig]).forEach(function (k) {
        var n = Number(k);
        SG_MORE[fig][n].forEach(function (spec) {
          var els = [];
          spec.sel.forEach(function (s) {
            var el = document.querySelector(s);
            if (el) els.push(el);
          });
          if (!els.length || !els[0].parentNode) return;
          var wrap = document.createElement('div');
          wrap.className = 'sg-more-w';
          wrap.id = 'sgMore_' + n + '_' + spec.key;
          /* 🔒 §30-12-4 1〜2: 見た目は本物のボタン。中は3行。
           * 🔴 <button> の中は <span>（block）で組む（<div> は入れられない）。 */
          var btn = document.createElement('button');
          btn.type = 'button';
          btn.className = 'sg-more';
          btn.setAttribute('aria-expanded', 'false');
          btn.innerHTML =
            '<span class="sg-more-h"><b class="sg-more-t"></b>'
            + '<i class="sg-more-a">開く ▼</i></span>'
            + '<span class="sg-more-when"></span>'
            + '<span class="sg-more-now" hidden></span>';
          btn.querySelector('.sg-more-t').textContent = spec.title;
          btn.querySelector('.sg-more-when').textContent = spec.when;
          var body = document.createElement('div');
          body.className = 'sg-more-body';
          body.hidden = true;
          wrap.appendChild(btn);
          wrap.appendChild(body);
          /* 🔴 器は**1つ目の部品があった場所へ**先に挿す（＝index.html の並び＝
           * §30-12-5 の順がそのまま出る）。その後で部品を箱へ移す。 */
          els[0].parentNode.insertBefore(wrap, els[0]);
          /* 部品は index.html にある物を**移す**（複製しない） */
          els.forEach(function (el) { body.appendChild(el); });
          var x = document.createElement('button');
          x.type = 'button';
          x.className = 'sg-more-x';
          x.textContent = '閉じる ▲';
          body.appendChild(x);
          btn.addEventListener('click', function () {
            sgMoreSet(n, spec.key, body.hidden);
          });
          x.addEventListener('click', function () { sgMoreSet(n, spec.key, false); });
        });
      });
    });
  }

  /** 開閉を変える（覚える＝段ごと・案件には保存しない・🔒 §30-12-4 5） */
  function sgMoreSet(n, key, open) {
    var fig = navFigOf(n);
    if (!state.sgMoreOpen[fig][n]) state.sgMoreOpen[fig][n] = {};
    state.sgMoreOpen[fig][n][key] = !!open;
    sgMoreApply(n, key, !!open);
    /* 人が触ったら、写真の一度きりの合図は下ろす（また開き直さない） */
    if (n === 5 && key === 'img') state.sgMoreImgNew = false;
  }

  /**
   * ▼の器（.sg-more-w）1つに開閉を映す。
   * 🔒 §30-25-35: 配置図の下敷きの▼（#hzUnderMore・index.html に固定で置いた物）も
   *    同じ見た目にするため、開閉の描き方は**この1か所**にまとめてある。
   */
  function sgMorePaint(w, open) {
    if (!w) return;
    var btn = w.querySelector('.sg-more'), body = w.querySelector('.sg-more-body');
    if (!btn || !body) return;
    body.hidden = !open;
    btn.setAttribute('aria-expanded', open ? 'true' : 'false');
    w.classList.toggle('is-open', !!open);
    btn.querySelector('.sg-more-a').textContent = open ? '閉じる ▲' : '開く ▼';
  }

  /** 画面に開閉を映す（値は state 側が持つ） */
  function sgMoreApply(n, key, open) {
    sgMorePaint(sgMoreBox(n, key), open);
  }

  /**
   * 🔒 §30-12-4 2: 「いま: …」を引き直し、注意がある時はその機能だけ自動で開く。
   * 🔴 値を書くだけ（開閉は覚えた物を尊重する。閉じている物を勝手に閉じ直さない）。
   */
  function sgMoreSync() {
    if (!state.nav || !navOnSide()) return;
    var n = state.nav.step;
    sgMoreList(n).forEach(function (spec) {
      var w = sgMoreBox(n, spec.key);
      if (!w) return;
      var row = w.querySelector('.sg-more-now');
      var v = spec.now ? (spec.now() || '') : '';
      row.textContent = v ? ('いま: ' + v) : '';
      /* 🔒 §30-22-4 1: 配置図①の「いま: …⚠ PLATEAU の範囲外」は廃止した
       * （▼が無くなり、下敷きの〇が常に見えている＝一言は〇の行の中に出る）。 */
      row.hidden = !v;
      /* 🔒 §30-11-b 5: 注意で開くのは**出た瞬間の1回だけ**（出っぱなしの注意で
       * 毎回開き直すと、読んだあと閉じられなくなるため）。 */
      var wk = n + ':' + spec.key;
      var warn = spec.warn ? !!spec.warn() : false;
      if (warn && !state.sgMoreWarn[wk] && w.querySelector('.sg-more-body').hidden) {
        sgMoreSet(n, spec.key, true);
      }
      state.sgMoreWarn[wk] = warn;
    });
    /* 🔒 §30-11-b 5: 写真を取り込んだ直後は、注意とは別の一度きりの合図で
     * ［自分で撮った写真・図面を使う］だけを開く。 */
    if (state.sgMoreImgNew && n === 5 && sgMoreBox(5, 'img')) {
      state.sgMoreImgNew = false;
      sgMoreSet(5, 'img', true);
    }
    /* 🔒 §30-25-35 1: 配置図の下敷きの▼（#hzUnderMore）の「いま: …」も同じ契機で */
    hzUnderMoreSync();
  }

  /** 段に入った時の開閉（覚えた値・無ければ閉じ）。sgRender から */
  function sgMoreEnter(n) {
    var fig = navFigOf(n), mem = state.sgMoreOpen[fig][n] || {};
    sgMoreList(n).forEach(function (spec) {
      sgMoreApply(n, spec.key, !!mem[spec.key]);
    });
    sgMoreSync();
  }

  /** 案件を開いた時は開閉を仕切り直す（🔒 §30-12-4 5「案件には保存しない」） */
  function sgResetMore() {
    state.sgMoreOpen = { shozaizu: {}, haichizu: {} };
    state.sgMoreWarn = {};
    state.sgMoreImgNew = false;
    /* 🔒 §30-25-35 2: 配置図の下敷きの▼も仕切り直す（案件には保存しない） */
    state.hzUnderOpenAt = 0;
    /* 🔒 §30-22-3 1: ④の「下敷きを出す」の1回だけの仕掛けも案件をまたいで残さない */
    state.sg4Under = false;
    /* 🔒 §30-22-4 2: 配置図の「緑色に強調された…」の1行も案件ごとに仕切り直す */
    state.hzAimShown = false;
    /* 🔒 §30-28-1 2: 道具メニューの▼も案件をまたいで残さない（全部閉じへ戻す） */
    state.toolMoreOpen = {};
    toolMoreApply();
  }

  /** その番号が指す部品（無ければ空配列＝落とさない） */
  function sgNumEls(it) {
    var sels = Array.isArray(it.sel) ? it.sel : [it.sel];
    var out = [];
    sels.forEach(function (s) {
      var el = document.querySelector(s);
      if (el) out.push(el);
    });
    return out;
  }

  /** その番号そのものが済んだか。done() があればそれ、無ければ「押した」記録（🔒 §30-2） */
  function sgNumSelfDone(fig, i) {
    var it = SG_NUM[fig][i];
    if (!it) return false;
    if (it.done) return !!it.done();
    return !!state.sgHit[fig + ':' + i];
  }

  /**
   * その番号は済んだか。
   * 🔒 §30-12-2 3「飛ばした番号は済み扱い」: 同じ段でそれより**後ろ**の番号
   * （optional でない物）が済んでいれば、この番号も済みにする（住所検索をせずに
   * マーカーを置いた等。順に押すのが前提だが、飛ばしても青が先へ進む）。
   * 🔴 判定は SG_NUM の中身だけで行う（表示文字列では分岐しない）。
   */
  function sgNumDone(fig, i) {
    var it = SG_NUM[fig][i];
    if (!it) return false;
    if (sgNumSelfDone(fig, i)) return true;
    var list = SG_NUM[fig] || [];
    for (var j = i + 1; j < list.length; j++) {
      var b = list[j];
      if (!b || b.step !== it.step || b.optional) continue;
      if (sgNumSelfDone(fig, j)) return true;
    }
    return false;
  }

  /** いまの段で**次に押すべき番号**（任意の部品は指さない）。無ければ 0 */
  function sgNextNum(fig, step) {
    var list = SG_NUM[fig] || [];
    for (var i = 1; i < list.length; i++) {
      if (!list[i] || list[i].step !== step || list[i].optional) continue;
      if (!sgNumDone(fig, i)) return i;
    }
    return 0;
  }

  /* 🔒 §30-12-3（2026-09-09）: 字幕から「この段は終わりです」を廃止したので、
   * その出し分けの判定 sgHasPlainTodo は用が無くなった＝削除した。 */

  /**
   * 🔒 §30-2: いまの段の押す部品に番号バッジを付け直す。
   * 🔴 バッジは**属性だけ**（data-sgnum / data-sgstate）で、中身は CSS の ::before が出す。
   *    部品の中身（textContent・innerHTML）を書き換える所（navRenderPins・sgSyncOrient・
   *    sgRenderMarks）があるので、子要素を足す作りにすると消えてしまう。
   */
  function sgRenderNums() {
    if (!state.nav || !navOnSide()) return;
    var n = state.nav.step, fig = navFigOf(n), list = SG_NUM[fig] || [];
    document.querySelectorAll('#sideNav [data-sgnum]').forEach(function (el) {
      el.removeAttribute('data-sgnum');
      el.removeAttribute('data-sgstate');
      el.removeAttribute('data-sgn');
      el.removeAttribute('data-sgone');    // 🔒 §30-18-1「どれか1つ」の印
    });
    var next = sgNextNum(fig, n);
    for (var i = 1; i < list.length; i++) {
      if (!list[i] || list[i].step !== n) continue;
      var done = sgNumDone(fig, i);
      var st = done ? 'done' : (i === next ? 'next' : (list[i].optional ? 'opt' : 'todo'));
      /* 済んだ番号は薄い✓（正典 §30-2）。番号の役目は終わっているので数字は出さない */
      var txt = done ? '✓' : circ(i);
      /* 🔒 §30-18-1: 「どれか1つ」の番号（配置図⑦・🔒 §30-25-31 で⑥→⑦）は、
       * 同じ番号を3つのボタンに付け、
       * 3つとも**薄い色**で強調する（「青は常に1つ」の例外＝どれを押してもよい）。
       * 🔴 色分けは data-sgone を見る CSS 1か所（表示文字列では分岐しない）。 */
      var one = !!list[i].one;
      sgNumEls(list[i]).forEach(function (el) {
        el.setAttribute('data-sgnum', txt);
        el.setAttribute('data-sgstate', st);
        el.setAttribute('data-sgn', i);     // 押した記録の逆引き用（表示には使わない）
        if (one) el.setAttribute('data-sgone', '1');
      });
    }
    sgCaptionSync(fig, next);
  }

  /** 押した記録（判定できない部品の「済んだ」）。🔴 案件には保存しない画面の状態 */
  function sgMarkHit(fig, i) {
    if (!(i >= 1)) return;
    state.sgHit[fig + ':' + i] = true;
  }
  /** 案件を開いた時・ガイダンスを閉じた時は記録を仕切り直す */
  function sgResetHits() { state.sgHit = {}; }

  /* ---- 字幕（🔒 §30-12-3 / §30-10）----
   * 地図の上部中央。**番号＋指示文だけ**（左に大きく〇数字＝l1／右に指示文＝l2）。
   * 「次は」も「この段は終わりです」も言わない（§30-12-3）。
   * 🔒 §30-10: **自動では消えない**（「読んでる間に消えてしまう」というオーナー指摘）。
   *    ［×］（#sgCapClose）で閉じる。字幕全体をつかんでドラッグで動かせる
   *    （動かせるのはその字幕だけ・sgCaptionInitDrag）。次の字幕はまた既定位置
   *    （地図上部中央）に出る＝新しい文を出すたびに left/top を既定へ戻す。
   * **同じ文は連続で出さない**（地図を動かすたびに出ないように）。
   * 🔴 下部の hint() は残す（エラー・結果用）。字幕は「次の行動」だけに使う（§30-3）。 */
  /* replace ＝「この次の sgCaptionShow は、同じ文でも置き場所を引き直す」印。
   * 🔒 §30-13-7 3: 面を組み直す時（sgRender）とプレビューを閉じた時だけ立てる。
   * 🔴 sgCaptionShow は**地図を動かすたびに**も通る（renderOverlay →
   *    sgRenderStatus → sgRenderNums）ので、印なしで置き直すと枠に合わせて
   *    字幕が飛ぶ＝裁定 3 が禁じた「地図の移動が契機になる」状態になる。 */
  /* 🔒 §30-25-1 2: say（印つきの元の文）も控える。横長／縦長で組み方が変わるので、
   * sgCaptionPlace が置き場所を決めた後に文を組み直せるようにする。 */
  var sgCap = { last: '', replace: false, say: '' };

  /* 🔒 §30-14-3: 字幕の中のボタンが押された時にすることの表（鍵は SG_NUM[].btn.act）。
   * 🔴 ここ1か所。表示文字列では分岐しない。 */
  var SG_CAP_ACT = {
    vidPolygon: function () { vidOpen(); }
  };

  /* ---- 字幕の改行と行間（🔒 §30-17-1・2026-09-13 オーナー指示）----
   * 指示文（SG_NUM[].say）の中の印:
   *   「／」  … 改行だけ（<br>）
   *   「／／」… 改行＋行間（段落＝<span class="sg-cap-p">・行間 .55em は CSS）
   * 🔴 文言はデータ（SG_NUM[].say）のまま。ここは**印を描き方に変える**だけ。
   * 🔴 行間が付くのは A4 縦の縦長の箱（.is-side）だけ。横長では 0（CSS の1か所）。
   * 🔴 下に長くなる時は sgCaptionPlace が .is-tight（行間 0）→ .is-flow（改行も外す）
   *    の順に削る（高さを測ってから）。 */
  var SG_CAP_BR = '／';          // 改行の印
  var SG_CAP_PARA = '／／';      // 行間つき改行の印

  /** innerHTML に入れる前のエスケープ（🔴 文言は利用者に見える文字なので必ず通す） */
  function sgEsc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  /**
   * 指示文（印つき）→ 表示用の HTML（段落の箱と <br> だけ・🔒 §30-17-1）
   * 🔒 §30-25-1 2（2026-09-13 オーナー指示）: **横長の箱（.is-wide）では改行を減らす**。
   *   wide … 「／」は改行せず**全角空白1つ**（文がくっつかないように）。
   *          「／／」は段落のまま（改行・行間 0）
   *   flow … さらに「／／」も外して**1段落**にする（sgCaptionPlace の削り (a)）
   * 🔴 文言はデータ（SG_NUM[].say）のまま。ここは印を描き方に変えるだけ。
   */
  function sgSayHtml(say, wide, flow) {
    var s = String(say == null ? '' : say);
    if (wide && flow) {
      var flat = [];
      s.split(SG_CAP_PARA).forEach(function (para) {
        para.split(SG_CAP_BR).forEach(function (t) { flat.push(sgEsc(t)); });
      });
      return '<span class="sg-cap-p">' + flat.join('　') + '</span>';
    }
    return s.split(SG_CAP_PARA)
      .map(function (para) {
        return '<span class="sg-cap-p">'
          + para.split(SG_CAP_BR).map(sgEsc).join(wide ? '　' : '<br>')
          + '</span>';
      })
      .join('');
  }

  /**
   * 字幕を出す。
   * @param l1  左の〇数字（無い時は空）
   * @param l2  指示文
   * @param btn 文の下に出す小さなボタン { label, act }（🔒 §30-14-3・無ければ出さない）
   */
  function sgCaptionShow(l1, l2, btn) {
    var box = $('sgCaption');
    if (!box) return;
    /* 🔒 §30-13-3: 書き出しプレビューを出している間は字幕を出さない（紙面に重ねない）。
     * 🔴 last は書き換えずに戻る＝閉じた時（closeExportPreview → sgRenderNums）に
     *    同じ文がそのまま出る。 */
    if (!$('exPreviewBox').hidden) return;
    var replace = sgCap.replace;
    sgCap.replace = false;            // 印は1回だけ効く
    var key = l1 + '\n' + (l2 || '') + '\n' + ((btn && btn.act) || '');
    /* 同じ文は連続で出さない。
     * 🔴 §30-13-4: ただし**面を組み直した時だけは置き場所を引き直す**。段を移る途中は
     *    「紙を切り替える前の地図（前の紙のズーム）」で1度呼ばれ、そのあと同じ文で
     *    もう1度呼ばれる経路があるので、ここで戻ってしまうと古い地図で決めた
     *    置き場所が残る（§30-13-7 2）。
     * 🔴 §30-13-7 3: 印が無い時（＝地図を動かして通っただけ）は**何もしない**。 */
    if (key === sgCap.last) { if (replace) sgCaptionPlace(); return; }
    sgCap.last = key;
    $('sgCapL1').textContent = l1 || '';
    $('sgCapL1').hidden = !l1;      // 番号が無い時（保存後の一言）は数字の枠も出さない
    /* 🔒 §30-17-1: 指示文は「／」で改行・「／／」で改行＋行間にして描く
     * （中身は sgSayHtml が組む＝エスケープ済み）。
     * 🔒 §30-25-1 2: 横長の箱かどうかは sgCaptionPlace が決めるので、元の文を控えて
     *    あちらで組み直す（ここでは縦長の組み方で一度描いておく）。 */
    sgCap.say = l2 || '';
    $('sgCapL2').innerHTML = sgSayHtml(l2);
    $('sgCapL2').hidden = !l2;
    /* 🔒 §30-14-3: 文の下の小さなボタン（持っている番号だけ）。
     * 🔴 何をするかは data-act（SG_CAP_ACT の鍵）で持つ＝文字列では分岐しない。 */
    var brow = $('sgCapBtnRow'), bbtn = $('sgCapBtn');
    if (brow && bbtn) {
      var ok = !!(btn && btn.label && SG_CAP_ACT[btn.act]);
      bbtn.textContent = ok ? btn.label : '';
      if (ok) bbtn.dataset.act = btn.act; else delete bbtn.dataset.act;
      brow.hidden = !ok;
    }
    /* 🔒 §30-10: 次の字幕は固定位置（地図上部中央）に出す。前の字幕を
     * ドラッグして動かしていても、新しい文になったら既定位置へ戻す
     * （動かした位置は「その字幕だけ」に効く・sgCaptionInitDrag が付ける
     * .is-moved と inline left/top を外すと CSS の既定位置に戻る）。 */
    box.classList.remove('is-moved');
    box.style.left = '';
    box.style.top = '';
    box.hidden = false;
    sgCaptionPlace();               // 🔒 §30-13-4: 出したらすぐ置き場所を決める
  }

  /* 🔒 §30-13-4（2026-09-10 オーナー指示）: 字幕の置き場所。
   *   A4 縦 … 左面と枠の**間**（地図領域の左側の空き）に縦長の箱で大きく
   *           （左 8px・上 8px・幅＝空き−24px）。空きが足りなければ下へ落とす
   *   A4 横 … 上・中央のまま横長に（最大幅＝地図領域の 92%・上 8px）
   * 🔴 利用者がドラッグで動かした字幕（.is-moved）は動かさない（§30-10）。
   *    次の字幕（sgCaptionShow）で .is-moved が外れ、また既定の置き方に戻る。
   * 🔴 判定は「地図領域の左端から枠の左端までの空き」だけ（表示文字列では分岐しない）。
   * 🔒 §30-13-7 3: 呼ぶ契機は **sgCaptionShow・窓の大きさ（resize）・紙の向き
   *    （setSheetOrient／sgSyncOrient）・枠の決定／解除（toggleFrameFixed）** だけ。
   *    地図の移動終わり（viewend）では**呼ばない**（枠を決めた後に地図を動かすと
   *    字幕が枠に合わせて飛ぶため）。 */
  var SG_CAP_SIDE_MIN = 220;   // 🙋 仮値: これ未満の空きには縦長の箱を置かない
  var SG_CAP_SIDE_PAD = 24;    // 空きの内側に取る余白（左 8px ＋ 枠との間 16px）
  var SG_CAP_TOP = 8;          // 字幕の上（CSS の top: 8px と同じ値）
  /* 🔒 §30-25-1 1: 横長の箱（.is-wide）の左右の余白。幅＝地図領域の幅 − これ×2 */
  var SG_CAP_WIDE_PAD = 8;
  /* 🔒 §30-25-1 3: 横長の箱が枠に触らない隙間（枠の上端−これ／枠の下端＋これ） */
  var SG_CAP_FRAME_GAP = 8;

  /**
   * 🔒 §30-13-4（2026-09-10 オーナー指示）／🔒 §30-25-1（2026-09-13 オーナー指示）:
   *   A4 縦で左の空きが足りる … 縦長の箱（.is-side・左 8px・幅＝空き−24px、最大 360px）
   *   それ以外（A4 横・空き 220px 未満） … **横長の箱（.is-wide）**
   *     左 8px・上 8px・幅＝地図領域の幅−16px。〇数字の**右から**文が始まる
   *     （CSS の `.is-wide i { flex: 1 1 0 }`）。「／」は改行せず全角空白（sgSayHtml）
   * 🔴 判定に使うのは枠の矩形だけ（表示文字列では分岐しない）。
   */
  function sgCaptionPlace() {
    var box = $('sgCaption');
    if (!box || box.hidden) return;
    if (box.classList.contains('is-moved')) return;
    var wrap = box.parentElement;
    if (!wrap) return;
    var wrapR = wrap.getBoundingClientRect();
    /* 枠の矩形（決定済み＝固定枠／未決定＝画面中央の紙1枚）。🔒 §30-25-1 4 */
    var sh = curSheet(), fr = null;
    if (sh && state.map) {
      try {
        fr = (sh.frameFixed && sh.frame) ? fixedFrameRectPx(sh.frame) : frameRectPx();
      } catch (e) { fr = null; }
    }
    // fr.x ＝ 地図領域の左端から枠の左端までの空き（#map は .map-wrap に inset:0）
    var side = !!(sh && sh.orient !== 'landscape' && fr && fr.x >= SG_CAP_SIDE_MIN);
    var wide = !side;                                   // 🔒 §30-25-1 1
    var w = side ? Math.min(fr.x - SG_CAP_SIDE_PAD, 360)  // 🔒 §30-13-8 3: 最大 360px
                 : Math.max(160, wrapR.width - SG_CAP_WIDE_PAD * 2);
    /* 行間・改行は毎回いったん元に戻してから測る（前の段の削り方を引きずらない） */
    box.classList.remove('is-tight');
    box.classList.remove('is-flow');
    box.classList.remove('is-below');
    box.classList.toggle('is-side', side);
    box.classList.toggle('is-wide', wide);
    box.style.top = '';
    box.style.width = Math.round(w) + 'px';

    /** 文を組み直す（横長なら「／」は全角空白・flow なら「／／」も外す）*/
    function say(flow) {
      var l2 = $('sgCapL2');
      if (l2 && !l2.hidden) l2.innerHTML = sgSayHtml(sgCap.say, wide, flow);
    }
    say(false);

    if (wide) {
      /* 🔒 §30-25-1 3: 箱の下端が**枠の上端−8px** より下なら
       *   (a) 「／／」も外して1段落 → (b) 枠の下の空きに入るなら下へ → (c) 上のまま */
      if (!fr) return;
      var top0 = wrapR.top;
      var bottomPx = function () { return box.getBoundingClientRect().bottom - top0; };
      var limitTop = fr.y - SG_CAP_FRAME_GAP;
      if (bottomPx() <= limitTop) return;
      box.classList.add('is-flow');
      say(true);                                        // (a)
      if (bottomPx() <= limitTop) return;
      var h = box.getBoundingClientRect().height;       // (b)
      var below = fr.y + fr.h;
      if (wrapR.height - below >= h + SG_CAP_FRAME_GAP * 2) {
        box.classList.add('is-below');
        box.style.top = Math.round(below + SG_CAP_FRAME_GAP) + 'px';
      }
      return;                                           // (c) 触るのは許容（ドラッグで動く）
    }

    /* 🔒 §30-17-1「下に長くなる時は削る」（縦長の箱）: 箱の高さが地図領域の高さ−16px を
     * 超えたら、まず行間を 0（.is-tight）に。それでも超えたら改行も外して
     * 普通の折り返しだけ（.is-flow）にする。🔴 描いた後に測る。 */
    var limit = wrapR.height - SG_CAP_TOP * 2;
    if (!(limit > 0)) return;
    if (box.getBoundingClientRect().height <= limit) return;
    box.classList.add('is-tight');
    if (box.getBoundingClientRect().height <= limit) return;
    box.classList.add('is-flow');
  }

  /**
   * 字幕を消す。
   * @param reset true＝**次に同じ文が来たらまた出す**（段を離れた時・ガイダンスを
   *   閉じた時）。false（［×］で消した時）＝同じ文はもう出さない。
   * 🔒 §30-11-b 4: 「こんな時に押すボタン」の中の部品には番号が無いので、
   *   触っても次に押す番号は変わらない＝出るとしても**同じ文**になる。［×］で
   *   last を消していると、その同じ文がそれを触るたびに戻ってきてしまうため。
   */
  function sgCaptionHide(reset) {
    var box = $('sgCaption');
    if (reset) sgCap.last = '';
    if (box) {
      box.hidden = true;
      box.classList.remove('is-moved');
      box.classList.remove('is-side');    // 🔒 §30-13-4: 置き方も仕切り直す
      box.classList.remove('is-tight');   // 🔒 §30-17-1: 行間・改行の削りも仕切り直す
      box.classList.remove('is-flow');
      box.classList.remove('is-wide');    // 🔒 §30-25-1: 横長の箱と「枠の下へ」も
      box.classList.remove('is-below');
      box.style.left = '';
      box.style.top = '';
      box.style.width = '';
    }
  }

  /**
   * 🔒 §30-10: 字幕をドラッグで動かせるようにする（1回だけ配線・bindEditor から呼ぶ）。
   * つかむ所＝字幕全体。地図の操作へ伝えない（stopPropagation）。
   * ［×］は閉じるだけ（sgCaptionHide）。
   */
  function sgCaptionInitDrag() {
    var box = $('sgCaption');
    if (!box) return;
    var closeBtn = $('sgCapClose');
    if (closeBtn) {
      closeBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        sgCaptionHide();
      });
    }
    /* 🔒 §30-14-3: 文の下の小さなボタン。押しても字幕のドラッグは始まらない
     * （pointerdown を止める）。何をするかは data-act → SG_CAP_ACT の1か所。 */
    var capBtn = $('sgCapBtn');
    if (capBtn) {
      capBtn.addEventListener('pointerdown', function (e) { e.stopPropagation(); });
      capBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        var fn = SG_CAP_ACT[this.dataset.act];
        if (fn) fn();
      });
    }
    var dragging = false, offX = 0, offY = 0, wrap = null;
    box.addEventListener('pointerdown', function (e) {
      if (closeBtn && (e.target === closeBtn || closeBtn.contains(e.target))) return;
      wrap = box.parentElement;
      if (!wrap) return;
      var r = box.getBoundingClientRect(), wr = wrap.getBoundingClientRect();
      // いまの見た目位置をそのまま left/top（px）に固定してから動かす
      // （既定は left:50%+transform のセンタリングなので、切替時に位置が飛ばないように）
      box.style.left = (r.left - wr.left) + 'px';
      box.style.top = (r.top - wr.top) + 'px';
      box.classList.add('is-moved');
      offX = e.clientX - r.left;
      offY = e.clientY - r.top;
      dragging = true;
      box.classList.add('is-dragging');
      e.stopPropagation();
      e.preventDefault();
      try { box.setPointerCapture(e.pointerId); } catch (err) {}
    });
    box.addEventListener('pointermove', function (e) {
      if (!dragging || !wrap) return;
      e.stopPropagation();
      var wr = wrap.getBoundingClientRect();
      var x = e.clientX - wr.left - offX;
      var y = e.clientY - wr.top - offY;
      // 画面外へ完全に出ないように軽く収める
      var maxX = Math.max(0, wr.width - box.offsetWidth);
      var maxY = Math.max(0, wr.height - box.offsetHeight);
      x = Math.max(0, Math.min(maxX, x));
      y = Math.max(0, Math.min(maxY, y));
      box.style.left = x + 'px';
      box.style.top = y + 'px';
    });
    function endDrag(e) {
      if (!dragging) return;
      dragging = false;
      box.classList.remove('is-dragging');
      try { box.releasePointerCapture(e.pointerId); } catch (err) {}
    }
    box.addEventListener('pointerup', endDrag);
    box.addEventListener('pointercancel', endDrag);
  }

  /**
   * 次に押す番号を字幕にする（段に入った時・番号の操作が済んだ時にここを通る）。
   * 🔒 §30-12-3: 形は「〇数字（左に大きく）＋指示文」だけ。「次は」も
   *   「この段は終わりです」も言わない。文言は SG_NUM[].say の1か所から出る。
   */
  function sgCaptionSync(fig, next) {
    if (!state.nav || !navOnSide()) return;
    var it = next ? SG_NUM[fig][next] : null;
    if (it) {
      sgCaptionShow(circ(next), it.say, it.btn);   // 🔒 §30-14-3: 文の下のボタン
      return;
    }
    /* 番号が全部済んだ段＝配置図⑧で保存まで終わった時（§30-12-3 の表「保存後」）。
     * 🔴 その他の「番号が尽きた」状態は起こらない（各段の最後は fin の番号）。 */
    if (state.nav.saved) sgCaptionShow('', SG_SAY_SAVED);
  }

  /** この紙の枠が決まっているか（②の［確認する］の条件・🔒 §28-3） */
  function sgFrameFixed() {
    var sh = curSheet();
    return !!(sh && sh.frameFixed && sh.frame);
  }

  /** 2つのマーカーが**いま見えている枠**の中にあるか。無い点は null */
  function sgPointsInFrame() {
    var c = state.current, sh = curSheet();
    if (!c || !sh || !state.map) return { home: null, lot: null };
    var r;
    try {
      r = (sh.frameFixed && sh.frame) ? fixedFrameRectPx(sh.frame) : frameRectPx();
    } catch (e) { return { home: null, lot: null }; }
    var out = { home: null, lot: null };
    ['home', 'lot'].forEach(function (k) {
      var p = c.points[k];
      if (!p) return;
      var s = state.map.project(p.lat, p.lng);
      out[k] = (s.x >= r.x && s.x <= r.x + r.w && s.y >= r.y && s.y <= r.y + r.h);
    });
    return out;
  }

  /** 状態の一言（毎段この位置・🔒 §28-1 ③） */
  function sgRenderStatus() {
    if (!state.nav || !navOnSide()) return;
    var n = state.nav.step;
    /* 🔒 §28-4: ③④の一言は**処理側が入れた文言**（生成結果・§22-as の案内）。
     * 地図を動かすたびに書き換えて消してしまわない（navRenderStatus と同じ作法）。 */
    /* 🔒 §30-22-1 4: ①の▼の「いま: …」は印の形（多角形で囲んだか）で変わるので、
     * 図形が変わるたびに通るここで引き直す（sgMoreSync は3件だけなので軽い）。 */
    if (n === 1) { $('sgStatus').textContent = sgStatus1(); sgMoreSync(); }
    else if (n === 2) $('sgStatus').textContent = sgStatus2();
    /* 🔒 §29-1: 配置図の段（⑤〜⑪）の一言は navStatusText が唯一の出どころ。
     * 🔴 ⑫は**書き出しの結果**（🔒 §30-27-2 では PDF・画像の窓が出す）を
     *    上書きしないので除く。 */
    else if (n >= 5 && n !== 12) $('sgStatus').textContent = navStatusText(n);
    /* 枠の中に入った・輪郭や枠が増えたら［次へ］の可否が変わるので、
     * 理由文だけでなくボタン列も引き直す（地図を動かすたびにここを通る）。 */
    if (n >= 5) sgSyncFootDisabled(n);
    var why = sgWhyText(n);
    $('sgWhy').textContent = why;
    $('sgWhy').hidden = !why;
    /* 🔒 §30-2 / §30-3: 済んだかの判定は既存の状態（マーカー・枠・図形の数）から
     * 引くので、状態の一言を引き直すここでも番号と字幕を合わせる。
     * 🔴 字幕は**文が変わった時だけ**出る（同じ文は連続で出さない）ので、
     *    地図を動かすたびに出っぱなしにはならない。 */
    sgRenderNums();
  }

  /**
   * ［次へ］の押せる／押せないだけを更新する（🔒 §29-1）。
   * 🔴 sgRenderFoot（作り直し）を毎回呼ぶと、押している最中のボタンが差し替わって
   *    クリックが落ちる。ここは disabled 属性を付け外しするだけにする。
   */
  function sgSyncFootDisabled(n) {
    var b = $('sgFoot').querySelector('button[data-act="next"]');
    if (!b) return;
    var ok = (n === 5) ? sgFrameFixed()
           : (n === 6) ? !!fillTargetPolygon()
           : (n === 7) ? !!navFrameCount()
           : true;
    b.disabled = !ok;
  }

  function sgStatus1() {
    var c = state.current;
    if (!c) return '';
    if (state.pinPlace) return '地図をクリックして置いてください';
    /* 🔒 §30-22-1 6: 同一住所の時は1地点しか無い（結線も距離も出ない） */
    if (c.points.same) return '✓ 使用の本拠・駐車場（同一）';
    var h = !!c.points.home, l = !!c.points.lot;
    if (!h && !l) return 'まだどちらのマーカーも置かれていません';
    if (!h) return '使用の本拠のマーカーがまだ置かれていません';
    if (!l) return '駐車場のマーカーがまだ置かれていません';
    var d = GSI.distanceMeters(c.points.home, c.points.lot);
    if (d < 5) {
      return '⚠ 2つのマーカーが同じ場所です。駐車場マーカーを実際の場所へ置いてください';
    }
    return '✓ 使用の本拠　✓ 駐車場　直線距離 ' + fmtDist(d)
      + (d > 2000 ? '（⚠ 2km を超えています）' : '（2km以内）');
  }

  function sgStatus2() {
    var inf = sgPointsInFrame();
    var out = [];
    if (inf.home === false) out.push('使用の本拠');
    if (inf.lot === false) out.push('駐車場');
    /* 🔒 §30-5: 「入った」時は今のZLを添える（§22-aj と同じ書式）。
     * 🔒 §30-14-2: ZL18 以上は 0.25 刻みなので小数第2位まで出す。 */
    var zl = (state.map && !(inf.home === null && inf.lot === null))
      ? ('（ZL' + (Math.round(state.map.getZoom() * 100) / 100) + '）') : '';
    var head = out.length ? ('⚠ ' + out.join('と') + 'が枠の外です' + zl)
      : (inf.home === null && inf.lot === null) ? 'マーカーがありません'
      : ('✓ 2つとも枠の中です' + zl);
    return head + (sgFrameFixed()
      ? '／枠は決定済み（地図だけ動かせます）'
      : '／枠はまだ決めていません（地図を動かすと枠も動きます）');
  }

  /**
   * ⑤（下敷きと枠）の状態の一言（🔒 §29-1）。
   * 「枠が決まったか」が主役。ついでに写真の有無と倍率も言う
   * （［駐車場に寄る］を押したかどうかが見て分かるように）。
   */
  function sgStatus5() {
    var out = [sgFrameFixed()
      ? '✓ 枠は決定済み（地図だけ動かせます）'
      : '枠はまだ決めていません（地図を動かすと枠も動きます）'];
    if (state.map) {
      // 🔒 §22-aj / §30-14-2: ZL14 以上は 0.5、ZL18 以上は 0.25 刻み＝小数第2位まで
      out.push('倍率 ZL' + (Math.round(state.map.getZoom() * 100) / 100));
    }
    if (state.imglay && state.imglay.hasImage()) out.push('✓ 写真あり');
    return out.join('／');
  }

  /** ［次へ］／［確認する］が押せない理由（平文・🔒 §28-1 ③） */
  function sgWhyText(n) {
    var c = state.current;
    if (n === 1) {
      if (navBothPins()) return '';
      var miss = [];
      if (!(c && c.points.home)) miss.push('使用の本拠');
      if (!(c && c.points.lot)) miss.push('駐車場');
      /* 🔒 §30-39-4 4: 促し方を新しい作法（住所を検索すると◎が置かれる）に合わせる */
      return miss.join('と') + 'のマーカーがまだ置かれていません'
        + '（住所を入れて［検索］を押すと、その場所に◎が置かれます）';
    }
    if (n === 2 || n === 5) {
      /* 🔒 §28-3 / §29-1 ⑤: どちらも「この枠の中が紙に出る」を決める段 */
      if (sgFrameFixed()) return '';
      return '先に［枠を決定］を押してください（この枠の中が紙に出ます）';
    }
    if (n === 6) {
      if (fillTargetPolygon()) return '';
      return '外周を描いて Enter で確定してください'
        + '（［多角形］を押してから、敷地の角を順にクリックします）';
    }
    if (n === 7) {
      if (navFrameCount()) return '';
      return '駐車枠を1つ以上描いてください'
        /* 🔒 §30-25 夜間確認: ［駐車枠（四角）］は §30-25-12 で消え、今は
         * ［駐車枠］を押してから地図をクリックする作法（ドラッグではない）。 */
        + '（［駐車枠］を押してから地図をクリック、または［枠をまとめて］で1つ置けます）';
    }
    /* 🔒 §28-4 / §28-5 / §29-1 ⑧⑨⑩⑪⑫: ③④⑧⑨⑩⑪⑫の［決定］［次へ］は
     * いつでも押せる（量も描き足しも道路も幅もラベルも「これで良し」を決めるのは人）。 */
    return '';
  }

  /** ②⑤の［紙の向きを変える］と［枠を決定］を、いまの紙（シート）の状態に合わせる。
   *  🔒 §29-1 / §30-14-1: ボタンは②と⑤の2か所にあるが、値は1つ
   *  （シートの orient / frameFixed）。 */
  function sgSyncOrient() {
    var sh = curSheet();
    var o = (sh && sh.orient === 'landscape') ? 'landscape' : 'portrait';
    /* 🔒 §30-13-2 1 / §30-14-1: ②⑤の［紙の向きを変える］の2行目
     * 「いま: A4 縦 → 押すと A4 横」。🔴 値の出どころはシートの orient 1か所。 */
    var otxt = 'いま: ' + (o === 'landscape' ? 'A4 横 → 押すと A4 縦'
                                             : 'A4 縦 → 押すと A4 横');
    /* 🔒 §30-29-2: 道具メニューの #sideOriToggleNow は廃止（器は②⑤の2つ） */
    ['sgOriToggleNow', 'sgOri5ToggleNow'].forEach(function (id) {
      var ot = $(id);
      if (ot) ot.textContent = otxt;
    });
    var fixed = sgFrameFixed();
    /* 🔒 §18-ag: ②（所在図）は［枠を決定］で方位記号が置かれるが、
     * ⑤（配置図）は置かれない。title の文言だけ器ごとに変える。
     * 🔒 §30-29-2: 道具メニューの #sideFix は廃止した。 */
    ['sgFix', 'sgFix5'].forEach(function (id) {
      var b = $(id);
      if (!b) return;
      // 🔒 §30-14-1: 決定した後の文言は「枠を決めなおす」（②⑤とも同じ）
      b.textContent = fixed ? '枠を決めなおす' : '枠を決定';
      /* 🔒 §30-17-3: 決定した後の［枠を決めなおす］は**薄い色**（存在は分かるが
       * 進むボタンと同じ濃さにしない）。色は §30-17-2 の変数（図で青／緑）。
       * 🔴 決定前は next（濃い色）になり得るので印は外す。 */
      b.classList.toggle('is-redo', fixed);
      var withCompass = (id === 'sgFix');   // 🔒 §30-29-2: #sideFix は廃止
      b.title = fixed
        ? ('枠の決定をやめて、地図を動かすと枠も動く状態に戻します'
           + (withCompass ? '（方位記号は残ります）' : ''))
        : 'いま見えている枠でこの紙の範囲を決めます（決めたあとは地図だけ動かせます）';
    });
    sgMoreSync();     // 🔒 §30-12-4 2: ボタンの「いま: A4 縦」も同じ値で
    sgCaptionPlace(); // 🔒 §30-13-4: 紙の向きが変わると字幕の置き場所も変わる
  }

  /**
   * 🔒 §30-22-4 1（2026-09-13 オーナー指示）: 下敷きの操作（種類の〇・濃さ・
   * 表示／非表示）を**配置図の全段の一番上**に出す。
   * 🔴 器（#hzUnderBar）は**1つだけ**。段に入るたびに、その段の本体（.sg-body）の
   *    先頭へ**移す**（複製しない＝id も配線も1組のまま）。
   * 🔴 §29-5 の2段落の案内（#hzUnderNote）は①（下敷きと枠）だけに出す。
   * 🔴 所在図の段では何もしない（器は配置図①に置いたまま・見えない）。
   */
  function hzUnderBarTo(n) {
    var bar = $('hzUnderBar');
    if (!bar) return;
    if (navFigOf(n) !== 'haichizu') return;
    var body = $('sgS' + n);
    if (body && body.firstChild !== bar) body.insertBefore(bar, body.firstChild);
    var note = $('hzUnderNote');
    if (note) note.hidden = (n !== 5);
    /* 🔒 §30-25-35 2: ▼「下敷きの地図を変える」は**段を移るたびに閉じる**。
     * 🔴 開いた状態は「どの段で開いたか」だけを画面の状態で持つ（sgMoreOpen には
     *    入れない＝段をまたいで覚えない）。同じ段にいる間は開いたまま。 */
    if (state.hzUnderOpenAt !== n) state.hzUnderOpenAt = 0;
    sgMorePaint($('hzUnderMore'), state.hzUnderOpenAt === n);
    hzUnderMoreSync();
  }

  /** 🔒 §30-25-35 1: ▼の3行目「いま: …」（値の出どころは sgNowUnderText 1か所） */
  function hzUnderMoreSync() {
    var w = $('hzUnderMore');
    if (!w) return;
    var row = w.querySelector('.sg-more-now');
    if (!row) return;
    var v = sgNowUnderText() || '';
    row.textContent = v ? ('いま: ' + v) : '';
    row.hidden = !v;
  }

  /** 🔒 §30-25-35: ▼の開閉（開いた段の番号だけを覚える＝段を移ると閉じる） */
  function hzUnderMoreSet(open) {
    state.hzUnderOpenAt = open ? ((state.nav && state.nav.step) || 0) : 0;
    sgMorePaint($('hzUnderMore'), !!open);
  }

  /* ===== 🔒 §30-28-1 2: 道具メニューの▼（3つだけ）=====
   * 🔴 見た目はガイダンス面の▼と**同じ**（描くのは sgMorePaint 1か所）。
   * 🔴 開いた状態は**同じ案件を開いている間だけ**覚える（案件には保存しない）。
   * 🔴 どの▼かは data-tmore（属性）で見る＝表示文字では分岐しない。 */
  var TOOL_MORE_KEYS = ['mark', 'name', 'auto'];

  function toolMoreBox(key) { return $('sideMore_' + key); }

  function toolMoreSet(key, open) {
    state.toolMoreOpen[key] = !!open;
    sgMorePaint(toolMoreBox(key), !!open);
  }

  /** 覚えている開閉を画面に映す（案件を開いた直後・全部閉じ） */
  function toolMoreApply() {
    TOOL_MORE_KEYS.forEach(function (k) {
      sgMorePaint(toolMoreBox(k), !!state.toolMoreOpen[k]);
    });
  }

  /**
   * 🔒 §30-25-23（2026-09-14 オーナー指示）: 常設の道具の帯（［選択］［消しゴム］）を
   * 1つだけの器（#sgToolStrip）で持ち、段に入るたびに**その段へ移す**
   * （hzUnderBarTo と同じ作法・複製しない＝ id も配線も1組のまま）。
   * 🔴 置き場所（§30-25-23 2）: その段に「下敷きの濃さ」があれば、それを包む
   *    `.sg-uop-row` の先頭（＝同じ行の左側）。無い段は `.sg-body` の先頭に単独で。
   * 🔴 呼び出しは必ず hzUnderBarTo(n) の**後**（配置図は #hzUnderBar が段ごとに
   *    .sg-uop-row ごと移った**後**でないと、その段の中に .sg-uop-row が無い）。
   */
  function sgToolStripTo(n) {
    var strip = $('sgToolStrip');
    if (!strip) return;
    var body = $('sgS' + n);
    if (!body) return;
    var row = body.querySelector('.sg-uop-row');
    if (row) {
      if (row.firstChild !== strip) row.insertBefore(strip, row.firstChild);
    } else if (body.firstChild !== strip) {
      body.insertBefore(strip, body.firstChild);
    }
  }

  /* 🔒 §30-22-3 1（2026-09-13 オーナー指示）: ④（描き足し）へ入った時の下敷き。
   * ③の確認は白地（地図OFF・§18-x-4）で行うので、そのまま④へ来ると
   * 「地図を見ながら描き足す」段なのに地図が無い。OSM を薄く（50%）出す。 */
  var SG4_UNDER_PCT = 50;
  var SG4_UNDER_ID = 'osmfj';
  function sgEnter4Underlay() {
    var c = state.current;
    /* 🔴 案件を開いている間**1回だけ**（そのあと利用者が選び直した物は尊重する）。
     * 🔴 案件に保存された濃さがある（＝0 でない）ならそれを使う＝勝手に変えない。 */
    if (!c || state.sg4Under || state.kind !== 'shozaizu') return;
    state.sg4Under = true;
    if (underlayPct() > 0) return;
    setUnderlayChoice(SG4_UNDER_ID);
    setUnderlayPct(SG4_UNDER_PCT);
  }

  /**
   * 🔒 §28-5 B（Step 3）: ④の下敷き〇を1つ選ぶ。
   * 🔴 **新しい状態は持たない**。上部バーの #underlaySel / #underlayOff を
   *    書き換えるだけ（1つのデータ）。'off' だけは下敷きIDを変えず地図を隠すだけ
   *    （直前まで選んでいた下敷きを覚えたまま、また表示に戻すとそこへ戻る）。
   */
  function sgUnderlayPick(v) {
    if (!state.current) return;
    if (v === 'off') {
      setUnderlayOffState(true);
    } else {
      setUnderlayChoice(v);
      setUnderlayOffState(false);
    }
    sgSyncUnderlay();
  }

  /**
   * ④の〇を、いまの下敷き（上部バー #underlaySel / #underlayOff）に合わせる。
   * 🔴 逆方向（上部バーを直接変えた時も④が追従）は #underlaySel・#underlayOff・
   *    #opacity の change/input ハンドラと setUnderlayChoice からここを呼ぶ。
   * 上部バーの値が〇に無い項目（PLATEAU・Google 本体等）の時はどれも選ばれない
   *    （④の〇は所在図向けの4択＋Googleボタンだけの絞り込みなので、それでよい）。
   */
  function sgSyncUnderlay() {
    var v = ($('underlayOff') && $('underlayOff').checked) ? 'off'
          : ($('underlaySel') ? $('underlaySel').value : '');
    /* 🔒 §30-22-3 1 / §30-22-4 1: 濃さのスライダーと表示／非表示（所在図④と
     * 配置図の全段 #hzUnderBar）も**同じ値**に合わせる。
     * 🔴 0 でない濃さは控えておく（「表示する」に戻した時にそこへ戻す）。 */
    var pct = underlayPct();
    if (pct > 0) state.sgUnderLastPct = pct;
    document.querySelectorAll('.js-uop-range').forEach(function (r) { r.value = pct; });
    document.querySelectorAll('.js-uop-val').forEach(function (b) {
      b.textContent = pct + '%';
    });
    document.querySelectorAll('.js-uop-show').forEach(function (c) {
      c.checked = (pct > 0);
    });
    /* 🔒 §30-22-1 2: 下敷きが変われば枠の破線の色も変わる（写真＝赤） */
    if (state.frameEls && state.frameEls.rect) {
      state.frameEls.rect.classList.toggle('is-photo', underlayIsPhoto());
    }
    /* 🔒 §28-14 ①-3: ①の〇（2つ）も同じ値を見る。今の下敷きが2つのどちらでも
     * ない時は、どれも選ばれない（①の〇は「よく使う2つ」の近道なのでそれでよい）。
     * 🔒 §29-1 ⑤ / §29-5-a 裁定2: 配置図の〇（4つ）も同じ。写真を取り込んで
     *    地図OFFにした時はどれも選ばれない（それが正しい＝地図を出していない）。 */
    document.querySelectorAll('#sgUnderlay input[name="sgUnderR"], '
      + '#sgUnder1 input[name="sgUnder1R"], '
      + '#sgUnder5 input[name="sgUnder5R"]').forEach(function (r) {
      r.checked = (r.value === v);
    });
    sgMoreSync();     // 🔒 §30-12-4 2: ボタンの「いま: 航空写真 …」も同じ値で
  }

  /* ================= §29-5 決定2: 下敷きの〇に出す撮影時期 ================= */
  /* 🔴 z11 は必ず cyberjapandata の方（maps.gsi.go.jp は CORS が通らない・実測済み。
   *    正典 §29-5 末尾の実測メモ参照）。地理院 写真（gsi-photo）だけ地域差があるので
   *    取りに行く。他の3種は UNDERLAYS[id].photoEra の固定文字列を出すだけ。 */
  var GSI_PHOTO_ERA_URL = 'https://cyberjapandata.gsi.go.jp/xyz/seamlessphoto_spec/11/{x}/{y}.geojson';
  var ERA_DEBOUNCE_MS = 800;
  /* 案件内のメモリキャッシュ（保存しない・openCaseInner で clear）。
   * key = 'x,y'（z11 タイル整数） → Promise<GeoJSON|null>（null＝取得失敗） */
  var eraTileCache = new Map();
  /* gsiPhoto ＝ 地理院 写真の撮影時期の文言（🔒 §30-12-4 2: ボタンの「いま:」にも出す。
   * '' ＝まだ分からない・'時期不明' ＝取れなかった＝注意なので自動で開く）。 */
  var eraState = { tileKey: null, timer: null, gsiPhoto: '' };

  /** 点がポリゴンの外周（穴は無視・🔒 §29-5 決定2）に入っているか（レイキャスト法） */
  function pointInRing(pt, ring) {
    var x = pt[0], y = pt[1], inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      var xi = ring[i][0], yi = ring[i][1], xj = ring[j][0], yj = ring[j][1];
      var hit = ((yi > y) !== (yj > y))
        && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (hit) inside = !inside;
    }
    return inside;
  }

  /**
   * GeoJSON の features[] から、center を含む面の「撮影年月」を拾う（無ければ null）。
   * 🔴 実測（2026-09-08・名古屋 z11/1802/810）: この撮影期間レイヤは面が**重なる**
   *    （例: 2020年8月～9月の広い面の中に、2024年4月の狭い面が入れ子）。
   *    features[] は実測でどのタイルも撮影年の**古い→新しい順**だったので、
   *    含む面が複数ある時は**最後（＝一番新しい）を採用**する（先勝ちだと重なりの
   *    下敷きになった古い日付を拾ってしまい、実際に見えている写真と食い違う）。
   *    正典 §29-5 は「中心点を含む Polygon」とだけ書いており複数一致の扱いは
   *    未規定 → 判断はここに記録（報告にも書く）。
   */
  function eraFromGeoJSON(geo, center) {
    if (!geo || !Array.isArray(geo.features) || !center) return null;
    var pt = [center.lng, center.lat];
    var out = null;
    for (var i = 0; i < geo.features.length; i++) {
      var g = geo.features[i] && geo.features[i].geometry;
      // 🔴 想定外の形（Polygon 以外・座標欠落）は静かに読み飛ばす（fail-soft）
      if (!g || g.type !== 'Polygon' || !g.coordinates || !g.coordinates[0]) continue;
      if (pointInRing(pt, g.coordinates[0])) {
        var v = geo.features[i].properties && geo.features[i].properties['撮影年月'];
        if (v) out = String(v);       // 上書きしていく＝最後に見つかった物が残る
      }
    }
    return out;
  }

  /** z11 の1タイルを取得（案件内キャッシュ・同じタイルは再取得しない） */
  function fetchEraTile(x, y) {
    var key = x + ',' + y;
    if (eraTileCache.has(key)) return eraTileCache.get(key);
    var url = GSI_PHOTO_ERA_URL.replace('{x}', x).replace('{y}', y);
    var p = fetch(url).then(function (r) {
      if (!r.ok) throw new Error('撮影年月の取得に失敗しました (' + r.status + ')');
      return r.json();
    }).catch(function (e) {
      console.warn('地理院 写真の撮影年月レイヤを取得できませんでした', e);
      return null;      // fail-soft: 呼び側は「時期不明」にする
    });
    eraTileCache.set(key, p);
    return p;
  }

  function setEraSpan(id, text) {
    var el = $(id);
    if (el) el.textContent = text || '';
  }

  /** 枠の中心（未決定なら地図の中心）。§29-5 決定2「枠が未決定なら地図の中心」。
   *  🔴 sh.frame は syncFrameFromView（'viewend'）で未決定の間も画面の枠中心に
   *     追従しているので、決定の有無に関わらずまず frame.center を見ればよい。 */
  function sgEraCenter() {
    var sh = curSheet();
    if (sh && sh.frame && sh.frame.center) return sh.frame.center;
    return state.map ? state.map.getCenter() : null;
  }

  /**
   * fetchEraTile の結果から、その時の center に当たる「撮影年月」を出す（通信はしない）。
   * 🔴 呼んだ後にさらに別のタイルへ動いていたら、この結果は捨てる（新しい呼び出しが書く）。
   */
  function applyEraResult(key, center) {
    var xy = key.split(',');
    fetchEraTile(Number(xy[0]), Number(xy[1])).then(function (geo) {
      if (!(navAtStep(4) || navAtStep(5)) || eraState.tileKey !== key) return;
      var v = eraFromGeoJSON(geo, center || sgEraCenter());
      var t = v ? ('・撮影 ' + v) : '・時期不明';
      setEraSpan('sgEraGsiPhoto', t);
      setEraSpan('sgEraGsiPhoto4', t);      // 🔒 §30-4: ④も同じ値
      /* 🔒 §30-12-4 2: ボタンの「いま:」にも同じ値を出す（閉じていても見える）。
       * 🔴 表示文字を読み直さず、ここで持った値（eraState.gsiPhoto）を見る。 */
      eraState.gsiPhoto = v ? ('撮影 ' + v) : '時期不明';
      sgMoreSync();
    });
  }

  /**
   * ④⑤の下敷きの〇に撮影時期を出す（🔒 §29-5 決定2・§29-5-a 裁定2・§30-4）。
   * PLATEAU・Google・地理院 正射写真は UNDERLAYS の固定文字列。地理院 写真だけ
   * 枠中心の z11 タイルを取得して「撮影年月」を拾う。
   * 🔴 通信（fetchEraTile）はタイルが変わった時だけ・地図を動かすたびには投げない
   *    （800ms デバウンス）。**ただし同じタイルの中でも中心は動く**（1タイルに複数の
   *    撮影日の面が入っていることがある・実測 z11/1803/810 で2面）ので、タイルが
   *    同じでも既に取得済みなら通信なしでその場で引き直す（fail-soft の対象外＝
   *    ローカル計算のみ）。
   * 🔒 §30-4（2026-09-08）: ④（所在図・地理院 写真／Google 航空写真だけ。④に
   *    PLATEAU／正射の〇は無い＝§28-14）でも同じ関数を呼ぶ。地図系（地図なし／
   *    OpenStreetMap／地理院 地図／Google 地図）の行には出さない＝そもそも
   *    .sg-era の器を置いていない。
   */
  function sgSyncEra() {
    /* 🔒 §30-22-4 1: 下敷きの〇は**配置図の全段**に出る（#hzUnderBar が段ごとに移る）
     * ので、所在図④と配置図のどの段でも撮影時期を引き直す。 */
    if (!(navAtStep(4) || (state.nav && navFigOf(state.nav.step) === 'haichizu'))) return;
    var pl = underlayById('plateau'), gp = underlayById('google-photo'), ort = underlayById('gsi-ort');
    setEraSpan('sgEraPlateau', pl && ('・' + pl.photoEra));
    setEraSpan('sgEraGooglePhoto', gp && ('・' + gp.photoEra));
    setEraSpan('sgEraGooglePhoto4', gp && ('・' + gp.photoEra));   // 🔒 §30-4: ④
    setEraSpan('sgEraGsiOrt', ort && ('・' + ort.photoEra));

    var center = sgEraCenter();
    if (!center) {
      eraState.tileKey = null;
      eraState.gsiPhoto = '';
      setEraSpan('sgEraGsiPhoto', '');
      setEraSpan('sgEraGsiPhoto4', '');
      sgMoreSync();
      return;
    }
    var t = GSI.lonLatToTile(center.lng, center.lat, 11);
    var x = Math.floor(t.x), y = Math.floor(t.y);
    var key = x + ',' + y;
    eraState.tileKey = key;

    if (eraTileCache.has(key)) {
      // 🔴 このタイルは取得済み（通信なし）。中心がタイル内の別の面へ動いていれば
      //    その値へ引き直す（＝取得は「タイルが変わった時だけ」のまま守れている）
      applyEraResult(key, center);
      return;
    }
    // 新しいタイル＝取得が要る。地図を動かすたびには投げない（800ms デバウンス）
    setEraSpan('sgEraGsiPhoto', '');           // 別の場所へ動いた間は前の値を出さない
    setEraSpan('sgEraGsiPhoto4', '');
    eraState.gsiPhoto = '';
    sgMoreSync();
    if (eraState.timer) clearTimeout(eraState.timer);
    eraState.timer = setTimeout(function () {
      eraState.timer = null;
      applyEraResult(key, null);   // 取得完了時の中心を改めて sgEraCenter() で見る
    }, ERA_DEBOUNCE_MS);
  }

  /**
   * ［所在図プレビュー］（§28-4 の右パネル #szPrev）。
   * 🔒 §30-13-2: ④の本文にあった #sgPrev は削除した（⑧は下部の data-act="szPrev"
   *    ＝ navShowPreview('shozaizu')。左面を隠さず下部ボタンが付く形）。
   */
  function runShozaizuPreview() {
    if (!state.current) return;
    if (state.kind !== 'shozaizu') switchKind('shozaizu');
    // 枠が未決定の紙は「いま見えている範囲」が紙になる（§7）。決定済みなら触らない
    syncFrameFromView();
    ensureFrames();
    openPreview({ kind: 'shozaizu' });   // 🔒 §30-27-1 1: プレビューは1つの画面
  }

  function navStatusText(n) {
    var c = state.current;
    var objs = objectsOf('haichizu');
    if (n === 1) {
      if (state.pinPlace) return '地図をクリックして置いてください';
      if (!navBothPins()) return '';
      // 相互補完（§18-3）で同じ住所を入れた直後は 2点が同じ場所になる
      if (GSI.distanceMeters(c.points.home, c.points.lot) < 5) {
        return '⚠ 2つのマーカーが同じ場所です。駐車場マーカーを実際の場所へ置いてください';
      }
      return '✓ 2つのマーカーが置かれています（ドラッグで微調整できます）';
    }
    /* 🔒 §29-1（Step 6）: ⑤は「下敷きと枠」（新設）。枠が決まったかを言う */
    if (n === 5) return sgStatus5();
    if (n === 6) {
      return navPolyCount() ? '✓ 輪郭があります（描き直すと次へ進みます）'
                            : '多角形ツールで角を順にクリック → Enter で確定';
    }
    if (n === 7) {
      /* 🔒 §25-4: 主役マーク（role:'mainmark' の四角）は駐車枠ではないので数えない。
       * 生成先が所在図なので普通は混ざらないが、複製・貼り付けで持ち込まれても
       * 「駐車枠 1 個」と誤って達成にしないため、ここでも明示的に外す。 */
      var frames = navFrameCount();
      /* 🔒 §29-1 ⑦ / §16-5 A: 提出物として要るのは「対象の枠がどれか分かる印」なので、
       * 枠の数と一緒に**保管場所マークの有無**も必ず言う（付け忘れが一番多い）。 */
      var mark = objs.some(function (o) {
        return (o.type === 'rect' && o.storage)
            || (o.type === 'stampGroup' && o.storage
                && Object.keys(o.storage).length);
      });
      return frames
        ? ('✓ 駐車枠 ' + frames + ' 個（保管場所マーク: '
           + (mark ? 'あり' : 'なし') + '）')
        /* 🔒 §30-25 夜間確認: 同上（［駐車枠（四角）］は廃止済み） */
        : '［駐車枠］を押してから地図をクリック、または［枠をまとめて］で一度に置けます';
    }
    if (n === 8) {
      // 🔒 §22-ag: 直線・曲線に加え、多角形で引いた道路（source:'road'）も数える
      var roads = navRoadCount();
      return roads ? ('✓ 道路の線 ' + roads + ' 本')
                   : '［直線］［多角形］［曲線］のどれかで、道路の縁をなぞってください';
    }
    if (n === 9) {
      /* 🔒 §25-5: 矢印は手入力が無くても地図から計算した数値が必ず入る
       * （＝紙にも出る）ので、ラベルの有無で数えず**矢印そのもの**を数える。 */
      var arrows = objs.filter(function (o) { return o.type === 'arrow'; }).length;
      if (arrows) return '✓ 数値の入った矢印 ' + arrows + ' 本';
      // 🔒 §18-l: 道幅欄に値があれば、引いた矢印にその値がそのまま入る
      var w = $('sgRoadW').value.trim();
      // 🔒 §30-30-3 3: §30-29-7 の🙋（古い一言）の直し。「空欄のまま引くと地図から
      // 計算した幅が入ります」→ 空欄でも矢印だけ引ける仕様（§30-29-7）に合わせる
      return w ? ('道幅 ' + w + (/m$/.test(w) ? '' : 'm') + ' を添えて矢印を書き込みます')
               : '幅の矢印がまだありません（幅を入れなければ矢印だけが入ります）';
    }
    if (n === 10) {
      var gate = objs.some(function (o) {
        return (o.type === 'text' && /出入/.test(o.text || ''))
            || (o.type === 'arrow' && /出入/.test(o.label || ''));
      });
      if (!gate) return '「出入口」の文字がまだありません';
      // 🔒 §18-v: 幅欄に値があれば、引いた矢印にその値がそのまま入る（⑨と同じ）
      var gw = $('sgGateW').value.trim();
      return gw ? ('✓ 「出入口」あり／幅 ' + gw + (/m$/.test(gw) ? '' : 'm')
                   + ' を添えて矢印を書き込みます')
                : '✓ 「出入口」が入っています';
    }
    /* 🔒 §29-1 ⑪（Step 7）: 置いた塊ラベルの数。
     * 🔒 §30-22-4 10: ［配置］はワンクリック（対象の駐車枠をクリックするだけ）。 */
    if (n === 11) {
      if (state.plPlace) return '対象の駐車枠を地図でクリックしてください';
      var labels = navLabelCount();
      return labels ? ('✓ ラベル ' + labels + ' 個')
                    : ('チェックと数値を入れて［' + LABEL_PLACE_JA
                       + '］→ 対象の駐車枠をクリックします');   // 🔒 §30-25-36 2
    }
    return '';
  }

  /* ---------- 提出前チェック（正典 §16-5 B） ----------
   * 🔒 §30-31-3（2026-09-15 オーナー指示「プレビューまで進んで PDF を押すと、
   *    所在図を作ったのに提出前チェックで配置図のエラーが出る。このエラー表示自体を
   *    無くして。配置図でもこの案内は必要ない」）: **表示しない**。
   * 🔴 判定（旧 haichizuIssues）・書き出し前の窓（旧 withSubmitCheck / #chkBox）・
   *    配置図⑧の一覧（旧 sgRenderCheck / #sgChkBox）を丸ごと廃止した
   *    ＝残しておくと「使っていない判定」が2か所目の真実になるため。 */

  /** 筆界が取れなかった時の理由を切り分けて伝える */
  function parcelNote(list) {
    if (list.length) return '';
    return (list.nearbyTotal > 0)
      ? '（この付近に筆界データはありますが、いま表示している範囲には掛かっていません。'
        + '少し引くか地図を動かしてお試しください）'
      : '（この地域は筆界が未整備のようです。都市部に多く、全国の約半分が該当します）';
  }

  /** 敷地ツール: 画面内の筆界を候補として薄く出す */
  function loadParcelCandidates() {
    if (!state.editor) return;
    hint('土地の区画を読み込んでいます…', 2000);
    AutoDraft.fetchParcels(state.map.getBounds()).then(function (list) {
      state.editor.setCandidates(list);
      hint(list.length
        ? (list.length + ' 区画を表示しました。駐車場の区画をクリックしてください')
        : ('区画が見つかりません' + parcelNote(list)), 6000);
    }).catch(function (e) {
      hint('区画の取得に失敗しました: ' + (e.message || e), 5000);
    });
  }

  /* ---------- テキストのその場入力（正典 §4-8） ---------- */

  /* 🔒 §30-15-5 規則3: 入力欄を地図の中に収める時の縁の余白(px) */
  var EDGE_PAD = 4;
  var textReq = null;
  function openTextInput(req) {
    textReq = req;
    /* 🔒 §30-15-4: 入力欄は器（#textBox＝入力欄＋［OK］）ごと置く。
     * 出す／隠す／位置の判定は**器**を見る（入力欄そのものではない）。 */
    var box = $('textBox'), inp = $('textInput');
    var r = $('map').getBoundingClientRect(), wrap = $('map').parentNode.getBoundingClientRect();
    var ox = r.left - wrap.left, oy = r.top - wrap.top;
    /* 🔒 §30-15-3: 信号機・バス停を置いた直後は、入力欄を**印の右隣**に出す。
     * クリック位置の真ん中に出すと印が入力欄の下に隠れて、置けたのかが分からない。
     * 🔴 置き場所の規則は editor.js の markSlot **1か所**（確定した文字と同じ場所）。
     *    既に動かした文字の編集・ふつうの文字は null が返る＝従来どおり。 */
    var slot = (req.obj && state.editor.markSlot) ? state.editor.markSlot(req.obj) : null;
    box.classList.toggle('is-mark', !!slot);
    box.classList.remove('is-mark-left');
    req.side = null;
    inp.value = req.obj ? (req.obj.text || '')
                        : (state.editor.textPreset || '');
    box.hidden = false;                          // 器の実寸を測るので先に出す
    if (slot) {
      box.style.left = (slot.x + ox) + 'px';     // 左端＝印の右端＋隙間
      box.style.top = (slot.y + oy) + 'px';      // 上下の中心＝印（板）の中心
      /* 🔒 §30-15-5 規則3: 右隣だと地図の右端をはみ出す時は**左隣**に出す
       * （出せないと［OK］が画面の外に隠れて押せない）。
       * 🔴 側を決めるのはここ**1か所**。確定した文字（commitText）は
       *    この答え（req.side）をそのまま受け取るので、入力欄と文字が必ず同じ側。 */
      var bw = box.offsetWidth, bh = box.offsetHeight;
      var mw = $('map').clientWidth, mh = $('map').clientHeight;
      var over = (slot.x + bw > mw - EDGE_PAD);
      var side = (over && (slot.xl - bw >= EDGE_PAD
                           || slot.xl > mw - slot.x)) ? 'left' : 'right';
      var lx;
      if (side === 'left') {
        // 器の右端＝印の左端−隙間。左へはみ出す分だけ戻す（translate(-100%) の分を足す）
        lx = Math.max(slot.xl, EDGE_PAD + bw);
        box.classList.add('is-mark-left');
      } else {
        lx = Math.max(EDGE_PAD, Math.min(slot.x, mw - bw - EDGE_PAD));
      }
      // 上下も地図の中へ（中心そろえなので、はみ出す分だけ中心を寄せる）
      var cy = Math.max(bh / 2 + EDGE_PAD, Math.min(slot.y, mh - bh / 2 - EDGE_PAD));
      box.style.left = (lx + ox) + 'px';
      box.style.top = (cy + oy) + 'px';
      req.side = side;
    } else {
      var p = state.map.project(req.at.lat, req.at.lng);
      box.style.left = (p.x + ox) + 'px';
      box.style.top = (p.y + oy) + 'px';
    }
    inp.focus();
    inp.select();
  }
  function commitTextInput() {
    var box = $('textBox'), inp = $('textInput');
    if (box.hidden || !textReq) return;
    var val = inp.value;
    box.hidden = true;
    var req = textReq;
    textReq = null;
    // 🔒 §30-15-5 規則3: 入力欄が左隣に出ていたら、確定した文字も左隣へ
    var o = state.editor.commitText(req.obj, req.at, val, $('textSize').value, req.side);
    updateHistoryButtons();
    // 定型文は1回で解除（続けて同じ物を置きたい時は選び直す）
    // 🔒 §30-29-1 2: 値の置き場所は state.editor.textPreset 1つだけ（選択肢は廃止）
    state.editor.textPreset = '';
    /* 🔒 §30-15-6: 文字道具（req.obj なし）で置いた時は選択道具に戻す。
     * 印つき文字（req.obj あり＝信号機・バス停）・既存文字の編集は道具が
     * 既に select（placeMark／ダブルクリック編集で先に select 済み）なので
     * ここは素通りする（表示文字列でなく道具の状態で分ける・空で取消した時も同じ）。
     * commitText は新規を置いた時だけオブジェクトを返す＝選び直す（§30-16-4 と同じ作法。
     * setTool('select') 自体は選択を消さないが、_pushNew の後に念のため明示する）。 */
    if (state.editor.tool === 'text') {
      if (o) state.editor.selection = [o.id];
      state.editor.setTool('select');
    }
  }
  function hideTextInput() {
    var box = $('textBox');
    /* 🔒 §30-15-6: 選択道具への引き戻しは**実際に入力欄が開いていた Esc**の
     * 時だけ行う。on('tool') は道具の持ち替えのたびに（text 道具へ入る時も
     * 含めて）このただの後片付け関数を無条件で呼ぶので、開いてもいない
     * 入力欄を理由に判定すると、文字道具そのものへ切り替えられなくなる
     * （setTool('text') の直後に this.tool==='text' の状態でここへ来るため）。 */
    var wasOpen = !box.hidden;
    box.hidden = true;
    textReq = null;
    /* Esc／空欄で取り消した時も選択道具に戻す（1回1個の作法。続けて置きたい
     * 時は道具をもう一度押す）。既存文字の編集中の Esc は道具が既に select
     * なのでここは素通りする。
     * 🔴 on('tool') がここを呼ぶ側でもあるが、setTool('select') した2周目は
     *    box が既に hidden＝wasOpen が false でこの条件が外れる＝無限に呼び合わない。 */
    if (wasOpen && state.editor.tool === 'text') state.editor.setTool('select');
  }

  /* 案件を開く。🔴 §16-13: 復元に失敗しても**きれいな TOP ページ**に落ちる
   * （壊れた保存状態を読んでも、かぶせ物が残って操作不能にならない）。
   * 🔴 §27-7②: **ここだけが非同期**（案件フォルダのファイルを1件読む）。
   *    読み終えた案件オブジェクトを openCaseInner へ渡す形にして、
   *    openCaseInner の中身＝作図側のコードは一切変えない。 */
  /* @param opt.fresh 🔒 §30-20: ［新しい案件］から来た＝作図画面に入った直後に
   *   「はじめに」を出す。既存の案件を開いた時（一覧・取り込み）は渡さない。 */
  function openCase(id, opt) {
    function bail(msg) {
      closeAllOverlays();
      state.current = null;
      showView('list');
      renderTop();               // 🔒 §27-12: 戻り先はフォルダの状態しだい
      alert(msg);
    }
    Store.loadAsync(id).then(function (c) {
      if (!c) { alert('この案件を読み込めませんでした'); renderTop(); return; }
      try {
        openCaseInner(c, opt);
      } catch (e) {
        bail('この案件を開けませんでした（' + (e.message || e) + '）');
      }
    }, function (e) {
      bail('この案件を読み込めませんでした（' + ((e && e.message) || e) + '）');
    });
  }

  function openCaseInner(c, opt) {
    if (!c) { alert('この案件を読み込めませんでした'); renderTop(); return; }
    navClose(true);              // ガイダンスも案件ごとに仕切り直す（正典 §18）
                                 // 🔒 §28-6 ⑤: 前の案件の段は消さない
    closeAllOverlays();          // 前の画面のダイアログを持ち込まない
    state.current = c;
    state.kind = 'shozaizu';
    /* 🔒 §23-6: OSM のキャッシュは**案件内**。別の案件は別の土地なので持ち越さない
     * （持ち越しても当たらないだけだが、古い範囲を抱えたままにしない） */
    if (window.OSM) OSM.clearCache();
    /* 🔒 §30-13-5: 地理院ベクトルタイルのキャッシュも同じ理由で案件ごとに捨てる
     * （設定を変えるたびに取り直していたのが⑦の遅さの主因・gsi.js のメモリキャッシュ）。 */
    if (window.GSI && GSI.clearCache) GSI.clearCache();
    // 🔒 §29-5 決定2: 撮影時期のタイルキャッシュも同じ理由で案件ごとに仕切り直す
    eraTileCache.clear();
    eraState.tileKey = null;
    if (eraState.timer) { clearTimeout(eraState.timer); eraState.timer = null; }

    $('caseName').value = c.name;
    $('caseNo').value = c.caseNo || '';      // 番号なしの旧案件は空欄（手で入れられる・§19-1）
    /* 🔴 2026-08-31: エディタの ☑完了 は削除（done は案件一覧の行トグルで指定する）。
       c.done のデータ自体は今までどおり読み書きされる＝旧案件・JSON 往復は不変 */
    /* 🔒 §30-39-2 3 / §30-39-3 3: 案件を開いたら、本拠・駐車場の住所を欄へ戻す
     * （地点ごとに2か所＝ガイダンス①／道具メニュー・写す先は表 ADDR_FIELDS 1か所）。
     * 🔴 上部バーの欄は §30-39-1 1 で削除したので、戻す先は左メニューだけ。 */
    Object.keys(ADDR_FIELDS).forEach(function (key) {
      syncAddr(key, (c.points[key] && c.points[key].address) || '', null);
    });
    // 🔒 §28-14 ①-4: 置く前のマーカーの種類の控えは案件をまたいで残さない
    state.markPick = { home: null, lot: null };
    // 🔒 §30-38-5 1: 「頂点の足し引き」の一言も案件をまたいで残さない
    state.vertexHintFor = '';

    showView('editor');
    ensureMap();
    state.editor.setTool('select');
    /* 🔒 §26-4-e: 名称の分類チェックは案件をまたいで残さない（全OFFへ戻す）。
     * 🔴 残ったままだと、案件を開いた直後に**意図しない OSM 取得**が走る
     *    （§23-6 の「控えめに叩く」に反する）。画面状態なので JSON は不変。 */
    resetNameCats();
    /* 🔒 §28-13 決定3: ④の重ね表示も案件をまたいで残さない（画面の状態）。
     * 🔴 残ったままだと案件を開いた直後に意図しない OSM 取得が走る（§23-6）。 */
    resetNameLay();
    /* 🔒 §30-19-1: ［枠をまとめて］の置く状態も案件をまたいで残さない（画面の状態） */
    stopStampArm();
    /* 🔒 §30-2: 案内数字の「押した」記録も案件をまたいで残さない
     * （画面だけの状態。案件には保存しない＝別の案件では①から案内し直す）。 */
    sgResetHits();
    /* 🔒 §30-12-4 5: 「こんな時に押すボタン」の開閉も案件をまたいで残さない
     * （開くと全部閉じに戻る）。撮影時期の控えも土地が変わるので捨てる。 */
    sgResetMore();
    eraState.gsiPhoto = '';
    state.editor.numberStart = c.numberCounter || 1;
    syncNumberStartUI(state.editor.numberStart);   // 2つの開始番号の欄（🔒 §30-18-2）
    setArrowWidth($('arrowWidth').value);       // 2つの幅欄を揃える（§18-l）
    /* 🔒 §30-18-4: 幅の決め方は案件に保存しない画面の状態。開いた時は「自動入力」
     * （ただし依頼文から拾った幅などで値が入っていれば「道幅入力」側に合わせる）。 */
    setArrowMode($('arrowWidth').value.trim() ? 'manual' : 'auto');
    /* 🔒 2026-09-03: 所在図の設定盤（6項目）を**案件の保存値から**引き直す。
     * 🔴 既存案件の値をここで既定へ丸めない＝開いただけで図が変わらない。 */
    syncSzPanel();
    bindCurrentSheet();                         // 🔒 §24-1: いま開いているシートの図形
    renderSheetBar();                           // シート帯（何の図の何枚目か）
    applySheetToMap();
    /* 🔒 §30-24-1: 多角形の「先頭」の控えは案件をまたいで残さない（画面の状態）。
     * 残っていると、開いた直後の最初の change でピンが勝手に動く。 */
    state.mainPolyHead = { home: null, lot: null };
    /* 🔒 §30-24-3: 前に文字が消えたまま保存された案件を、開いた時に直す
     * （文字は印の種類・置き直し・作り直しに関わらず必ず1つずつある）。 */
    ensureMainLabels();
    /* 🔒 §30-32-5: 開いた案件でも「多角形があれば印は多角形」を揃える
     * （前の版で◎のまま保存された案件を開いた時に◎が出てしまうため）。 */
    syncMarkShapeFromPolys();
    refreshPoints();
    /* 🔒 §30-28-1 1: 道具メニューにもガイダンスと同じ部品が出るので、
     * 案件を開いた時点で**ガイダンスの外でも**引き直す（✓印・印の形と色・
     * 多角形の書式・保管場所マークの書式）。値の出どころは今までどおり1か所。 */
    navRenderPins();
    sgRenderMarks();
    sgRenderStorageFmt();
    /* 🔒 §28-6 ⑤: 前に開いていた段からガイダンスを再開する（無ければ道具メニュー）。
     * 🔴 画面（シート・地図）を組み終えてから呼ぶ＝②の枠の判定が正しく出る。 */
    navResume();
    showSaveState('saved');
    /* 🔒 §30-20: ［新しい案件］で入った直後だけ「はじめに」を出す。
     * 🔴 画面を組み終えた**最後**に出す（closeAllOverlays が先に走るため）。 */
    if (opt && opt.fresh) welcomeOpen();
    /* 🔒 §30-33-1 4: 既に新しい版を見つけていれば、開いた瞬間から上部バーに案内を出す */
    verSyncNote();
  }

  function ensureMap() {
    if (state.map) { state.map._onResize(); return; }
    // maxZoom 23: 下敷き画像の限界(地理院・PLATEAU とも ZL18)を超えて寄れるようにする。
    // 画像は粗くなるが、作図に必要な画面上の大きさが得られる（オーナー指摘 2026-08-16）
    /* 🔒 §18-ao: fineFrom 18.5 = ZL18.5・19.5 を刻みに追加（作図の主戦場 18〜20 が
     *    1段2倍ずつ飛んで「ちょうどいい寄り」に合わせられなかった）
     * 🔒 2026-09-02 オーナー指示: **fineFrom を 14 へ拡大**。所在図の広域側
     *    （ZL14〜18）も 0.5 刻みにして、紙の枠にちょうど収まる寄りを選べるようにする。
     *    ラダーは 5,6…13, 14, 14.5, 15 …23（14 未満は従来どおり1刻み）。
     * 🔒 §30-14-2（2026-09-10 オーナー指示）: **ZL18 以上は 0.25 刻み**の2段目を追加。
     *    ラダーは 5…13, 14, 14.5 …17.5, 18, 18.25, 18.5 …23。
     *    ホイール・［＋］［−］・fitBothMaximizeZoom は全部この1本のはしごを使う。 */
    state.map = new MapView($('map'), { minZoom: 5, maxZoom: 23,
                                        fineFrom: 14, fineFrom2: 18, fineStep2: 0.25 });
    state.map.on('change', function () {
      renderOverlay();
      $('mapAttr').textContent = state.map.attribution();
      updateUnderlaySrc();
      updateGoogleLink();
      updateScale();
      schedulePlateauCheck();      // 🔒 §26-4-e: 対象外地域なら一言出す
    });
    state.map.on('viewend', function () {
      persistSheetState();
      // 書き出し範囲は「いま見えている枠の中」。地図を動かしたら追従させる
      syncFrameFromView();
      // 🔒 §29-5 決定2 / §30-4: ④⑤にいる間、枠の中心が動いたら撮影時期を引き直す（自身が navAtStep で絞る）
      sgSyncEra();
      /* 🔒 §30-13-7 3: ここでは**字幕を置き直さない**。枠を決めた後に地図を
       * 動かすと、枠の位置に合わせて字幕が飛んでしまうため（枠の破線と字幕が
       * 重なっても害はない）。置き直しの契機は sgCaptionShow・窓の大きさ・
       * 紙の向き（setSheetOrient／sgSyncOrient）・枠の決定／解除だけ。 */
    });
    // 描画エンジン（正典 §4/§6）。ピンより先に作ってレイヤーを下に敷く
    state.editor = new Editor(state.map);

    /* 🔒 §25-4 / §18-x-5（2026-08-30 オーナー実機報告）:
     * 主役マークの四角を掴んで動かしたら、動かすのは**ピンそのもの**。
     * ピンが動けば syncRoleObjects（refreshPoints 経由）が四角・役割ラベル・
     * 結線・距離ラベルを一式追従させる ＝ 四角だけが単独でさまようことがない。
     * 戻り値 false（ピンが無い）の時は editor 側がふつうの四角として動かす。 */
    /* 🔒 §30-24-1: 次に描く多角形の書式（画面の状態）。値は state 側が持ち、
     * editor は描く時に読むだけ（値の出どころを2つに割らない）。 */
    state.editor.mainPolyDefault = state.mainPolyDefault;

    state.editor.movePin = function (key, lat, lng, opts) {
      var c = state.current;
      if (!c) return false;
      /* 🔒 §30-35-3 6: ■の本体を掴んで動かした時（fromMark）に editor が渡すのは
       * **■の新しい中心**。中心はピン＋ずれ（dx_m/dy_m）なので、その分だけ戻した所が
       * ピン＝ずれを保ったまま一式が付いてくる（掴んだ時の動きは従来のまま）。
       * 🔴 多角形の重心から呼ぶ経路（syncMarkPin）は fromMark を渡さない＝従来どおり。 */
      if (opts && opts.fromMark && c.points[key] && Editor.offsetLatLng) {
        var mo = markOf(c.points.same ? 'home' : key);
        if (mo.dx_m || mo.dy_m) {
          var q = Editor.offsetLatLng({ lat: lat, lng: lng }, -mo.dx_m, -mo.dy_m);
          lat = q.lat; lng = q.lng;
        }
      }
      /* 🔒 §30-24-1: 多角形で囲む＝**その地点の印を置いた**ということ
       * （多角形は印の種類の1つ）。マーカーをまだ置いていない時は、
       * 多角形の重心にその地点を作る。作らないと「使用の本拠」の文字が
       * 出ない（＝オーナー報告「多角形を使うと文字が消える」）。 */
      if (!c.points[key]) {
        c.points[key] = {
          lat: lat, lng: lng, label: pinLabel(key),
          address: ADDR_EL[key] ? $(ADDR_EL[key]).value.trim() : '',
          mark: state.markPick[key] || undefined
        };
        if (!c.points[key].mark) delete c.points[key].mark;
        state.markPick[key] = null;
        c.points[key].moved = true;
        refreshPoints();
        navRender();
        Store.autosave(c);
        return true;
      }
      var p = c.points[key];
      p.lat = lat; p.lng = lng;
      p.moved = true;          // 住所検索の位置から手で動かした印（ピンのドラッグと同じ）
      /* 🔒 §30-22-1 6: 同一住所の間は2地点は同じ場所。主役の印（四角・多角形）を
       * 掴んで動かした時も、もう一方を置き去りにしない（ピンのドラッグと同じ作法）。 */
      if (c.points.same) {
        var other = c.points[key === 'home' ? 'lot' : 'home'];
        if (other) { other.lat = lat; other.lng = lng; other.moved = true; }
      }
      refreshPoints();
      return true;
    };

    /* 🔒 §30-25-40 2〜3: 主役の印（◎・■）の右下のつまみ。editor は値を図形へ
     * 直接書かず**この口**へ渡す＝書き先は案件の points[key].mark.scale 1か所。
     * 🔴 どちらの地点かは図形から読み直す（旧案件の主役ラベルは pinKey を持たない
     *    ことがあるので、保険つきの pinKeyOf を通す＝ mainMarkKeyOf）。
     * 🔴 ドラッグ中（done:false）は保存しない＝指を離した時に1回だけ書く。 */
    state.editor.onMainMarkScale = function (key, scale, opts) {
      var o = opts && opts.obj;
      var k = (o && mainMarkKeyOf(o)) || key;
      return setMainMarkScale(k, scale, { live: !(opts && opts.done) });
    };

    /* 🔒 §30-31-1 2: 主役の■の**辺つまみ**（縦横を別々に）。つまみと同じ作法で、
     * editor は図形へ書いた縦横を**この口**へ渡す＝書き先は案件の
     * points[key].mark.w_m / h_m 1か所（紙の■も同じ値から引き直す）。
     * 🔴 呼ばれるのは指を離した時だけ（ドラッグ中は図形の値で見た目を追う）。 */
    /* 🔒 §30-35-3 3: 掴んだ辺だけ伸びる＝中心がピンからずれるので、
     * editor は**■の中心（緯度経度）も**渡す（ずれを m に直すのはこちら側）。 */
    state.editor.onMainMarkDims = function (key, w_m, h_m, center) {
      return setMainMarkDims(key, w_m, h_m, center);
    };

    /* 🔒 §30-32-1: 消しゴムが**その地点の部品**（主役の印・主役の文字）に当たった時。
     * editor は「地点の部品に当たった」と言うだけで、どちらの地点かの判定
     * （pinKeyOf ＝旧案件の保険つき）と消し方（removePoint）はこちら1か所。
     * 🔒 §30-32-7 3（補正）: 主役の**多角形**はここへ渡って来ない（editor.js の
     * isPointPart が type!=='polygon' で弾く＝除外判定はあちら1か所だけに置く。
     * ここで o.type を見て多角形を弾く判定は重複させない）。 */
    state.editor.onErasePoint = function (o) {
      if (!o) return false;
      /* 🔒 §30-32-6 2〜3: 地点ごと消すのは**所在図の紙**だけ。配置図の紙では
       * ふつうの図形として1個だけ消す（false を返す＝editor が従来どおり消す）。 */
      if (state.kind !== 'shozaizu') return false;
      var key = null;
      if (o.role === 'mainmark') key = (o.markRole === 'lot') ? 'lot' : 'home';
      else if (o.role === 'pinlabel' && o.type === 'text') key = pinKeyOf(o);
      return key ? removePoint(key) : false;
    };

    state.editor.on('change', function () {
      if (!state.current) return;
      Store.autosave(state.current);
      updateHistoryButtons();
      /* 🔒 §18-ah: **図形が変わったら必ずピンの見せ方も引き直す**。
       * 🔴 これが無いと、所在図を生成した直後（役割オブジェクトが増えた瞬間）に
       *    ピンの表示が古いまま残り、③で「自宅・駐車場・距離」が二重に見える。
       *    renderOverlay は地図が動いた時にしか走らないので、
       *    生成直後に画面を触らないと直らなかった（実測: 1px 動かすと直った）。 */
      renderOverlay();
      // ドラッグで伸縮・回転した結果を右パネルの数値にも反映する
      renderPropPanel(state.editor.getSelected());
      /* 🔒 §30-24-1: 「最初に描いた多角形」を消したら、ピンを次の物の重心へ動かす
       * （消しゴム・Delete・戻す のどれでも通る1か所・syncMarkShapeFromPolys の手前）。 */
      syncMainPolyHead();
      /* 🔒 §30-24-1: 主役の多角形を全部消したら印の種類を◎へ戻す
       * （消しゴム・Delete・戻す のどれでも通る1か所）。 */
      syncMarkShapeFromPolys();
      navOnObjects();          // 🔒 §30-25-11: 一言を出すだけ（自動では進まない）
      /* 🔒 §28-13 決定3: 重ね表示は「紙に無い名前」だけを出すので、
       * 図形が変わったら引き直す（文字を消したらその名前がまた薄く出る）。 */
      if (state.namelay) state.namelay.invalidate();
    });
    state.editor.on('select', function (sel) {
      renderPropPanel(sel);
      vertexHintOnSelect(sel);     // 🔒 §30-38-5 1: 配置図で線を選んだ時の一言
      /* 🔒 §30-24-1: ①の▼の中の書式は「選んでいる多角形」に効くので、
       * 選択が変わったら引き直す（右パネルと同じ値・同じ部品）。
       * 🔒 §30-28-2 1: 道具メニューの▼にも同じ書式が出るので、ガイダンスの
       *    外でも引き直す（器が無ければ sgRenderMarks は何もしない）。 */
      sgRenderMarks();
    });
    /* 🔒 §30-24-1（2026-09-13 オーナー指示）: ［多角形で描く］で囲んだら、
     * その地点の**印の種類が「多角形」**になる（◎■は描かない・文字は残る）。
     * 🔴 印の真実は案件（points[key].mark）1か所。editor は「描いた」とだけ言う。 */
    state.editor.on('mainpoly', function (ev) {
      var c = state.current;
      if (!c || !ev) return;
      var key = (ev.key === 'lot') ? 'lot' : 'home';
      // 🔒 §30-25-37 3: 多角形にしても大きさ（scale）は保つ（markNext が組み立てる）
      var next = markNext(key, { shape: 'polygon' });
      if (c.points[key]) c.points[key].mark = next;
      else state.markPick[key] = next;
      /* 🔒 §30-24-2: 同一住所の時は印が1つ（本拠側）＝値を両方に写す */
      if (c.points.same && c.points.home && c.points.lot) {
        c.points.home.mark = { shape: 'polygon', color: next.color, scale: next.scale };
        c.points.lot.mark = { shape: 'polygon', color: next.color, scale: next.scale };
      }
      /* 🔒 §30-24-3: 多角形にしても「使用の本拠」「駐車場」の文字は必ずある
       * （オーナー実機「多角形を使うと文字が消える」の出口）。
       * 🔴 applyMarkChoice の**前**に呼ぶ（文字が無いと印の引き直しが素通りする）。 */
      ensureMainLabels();
      applyMarkChoice(key);            // 残っていた◎／■を取り除き、文字を印なしに
      if (c.points.same) applyMarkChoice(key === 'home' ? 'lot' : 'home');
      sgRenderMarks();
      renderOverlay();
      Store.autosave(c);
    });
    // 作図中は「戻す」が1クリック取り消しになるので、状態を追従させる
    state.editor.on('draft', function () {
      updateHistoryButtons();
      updateDrawBadge();
    });
    state.editor.on('hint', function (t) { hint(t, 4500); });
    state.editor.on('tool', function (t) {
      document.querySelectorAll('.tool').forEach(function (b) {
        b.classList.toggle('is-active', b.dataset.tool === t);
      });
      /* 🔒 §23-7-b: スペースの一時パンは**全ての道具で共通**なので、
       * 道具にかかわらず必ず末尾に添える（覚える事を1つにする）。 */
      $('toolHint').textContent = (TOOL_HINT[t] || '')
        + (t === 'select' ? '' : '　／ Ctrl を押している間は選択になります')
        + '　／ スペースを押している間は地図を動かせます';
      // 🔒 §28-5 A: ガイダンス④の「使い方1行」も同じ出どころで揃える
      sgSyncToolHint();
      if (t !== 'stamp' && state.stamp) state.stamp.close();
      if (t !== 'parcel') state.editor.setCandidates(null);
      /* 🔒 §28-13 決定3: なぞり出しの道具を持っている間は重ね表示を止める。
       * 🔴 曇り下書きが同じ交差点名・バス停名を（実体化できる候補として）出すので、
       *    重ねたままだと同じ名前が2つ並んで見える。切替の状態（on）は保つので、
       *    道具を離せばそのまま戻る。 */
      if (state.namelay) state.namelay.setSuppressed(t === 'reveal');
      /* 🔒 §23-2: 曇り下書きは**なぞり出しの道具を持っている間だけ**出す。
       * 道具を離れたら消える（作図の邪魔をしない）。 */
      if (state.reveal) {
        state.reveal.setActive(t === 'reveal');
        var rs = $('rvSizes');
        if (rs) rs.hidden = (t !== 'reveal');
        // 🔒 §23-5: 名称の分類チェックも道具を持っている間だけ出す
        var rn = $('rvNames');
        if (rn) rn.hidden = (t !== 'reveal');
        if (t === 'reveal') { syncRevealSizes(); renderNameStat(); }
      }
      // 認識のハイライトは道具を持ち替えるまで出しっぱなし（正典 §16-10-d-3）
      if (state.recogTool && t !== state.recogTool) clearRecogLines();
      // 作図の道具を持っている間は、画像のつまみを引っ込めて作図を優先する
      if (state.imglay) state.imglay.setToolOk(t === 'select');
      updateDrawBadge();
      hideTextInput();
      // 🔒 §30-16: 他の道具を選んだら拾う状態は終わる（道具の取り合いを作らない）
      stopNamePick();
      // 🔒 §30-19-1: ［枠をまとめて］の置く状態も同じ（地図クリックの取り合いを作らない）
      stopStampArm();
    });
    // Ctrl を押している間は「選択」として振る舞う（作図中でも掴める）
    state.editor.on('ctrl', function (on) {
      $('ctrlBadge').hidden = !on;
      updateDrawBadge();
      /* 🔒 §30-29-1 1: ［選択］は上部バー2行目にも出るので、範囲を .side に
       * 絞らない（is-active と同じ document 全体＝出どころ1か所）。 */
      document.querySelectorAll('.tool[data-tool="select"]').forEach(function (b) {
        b.classList.toggle('is-temp', on);
      });
    });
    /* 🔒 §23-7-b: スペースを押している間は「一時パン」。道具は変わらないので
     * 道具ボタンの見た目は触らず、バッジとカーソル（editor 側）だけで伝える。
     * 🔴 なぞり出し中はブラシの輪を消すため曇り層を描き直す。 */
    state.editor.on('space', function (on) {
      $('spaceBadge').hidden = !on;
      if (state.reveal && state.reveal.active) state.reveal.invalidate();
    });
    // 階段モード（塊の枠をドラッグしてずらす）
    state.editor.on('stagger', function (on) {
      $('skewBadge').hidden = !on;
      $('map').style.cursor = on ? 'ns-resize' : '';
    });
    state.editor.on('parcel', function (c) {
      hint(c.chiban ? ('地番 ' + c.chiban + ' を取り込みました') : '敷地を取り込みました', 4000);
      noteDraftAttribution(true);
    });
    // 番号カウンターを画面と往復させる（正典 §4-7「抜け番は書き換えて再開」）
    state.editor.on('number', function (n) {
      syncNumberStartUI(n);      // 🔒 §30-18-2: 欄は2か所・値は1つ
      if (state.current) { state.current.numberCounter = n; Store.autosave(state.current); }
    });
    /* 🔒 §22-ab（2026-08-28 オーナー指示）: **定型文を選んでいる時は入力欄を出さず、
     * クリックした場所にそのまま確定して置く**。
     * 🔴 「テキストを定型文で選んでいるのに編集できる必要が無いし、テキスト確定の
     *    動作は必要ない」（オーナー）。⑧⑨の［道路を置く］［出入口を置く］と同じ考え方。
     * 既存の文字を選び直した時（req.obj あり）は編集なので従来どおり入力欄を出す。 */
    state.editor.on('text', function (req) {
      var preset = state.editor.textPreset;
      if (preset && !req.obj) {
        var o = state.editor.commitText(null, req.at, preset, $('textSize').value);
        updateHistoryButtons();
        // 定型文は1回で解除（従来の commitTextInput と同じ作法）
        state.editor.textPreset = '';
        /* 🔒 §30-15-6: 定型の文字を置いた時も自由入力と同じく選択道具へ戻す */
        if (state.editor.tool === 'text') {
          if (o) state.editor.selection = [o.id];
          state.editor.setTool('select');
        }
        return;
      }
      openTextInput(req);
    });

    /* 🔒 §25-7/§25-8: 矢印キーは「増減／回転」に使うようになった。
     * 文字のその場入力や、かぶせ物（A4プレビュー・使い方動画）が
     * 出ている間は**矢印キーに手を出さない**。
     * 🔴 文字入力欄・スライダーは editor.js 側でも弾いているが、
     *    「見えているが focus が外れている入力欄」はここでしか判らない。
     * 🔒 §30-31-3 1: 旧 #chkBox（提出前チェック）は廃止＝この一覧からも外した。 */
    state.editor.keysBusy = function () {
      return !$('textBox').hidden || !$('vidBox').hidden
          || !$('exPreviewBox').hidden
          || !$('exPick').hidden           // 🔒 §30-27-2: 紙を選ぶ窓も同じ扱い
          || !$('welcomeBox').hidden;      // 🔒 §30-20: 「はじめに」も同じ扱い
    };

    /* 🔒 §30-15-5 規則2: 印つき文字の置き場所を**紙の物差し**で解くための縁。
     * editor はシートを知らないので、いま編集している紙の縮尺 1:N をここで渡す
     * （keysBusy / movePin と同じ作法）。枠が未定の紙は null ＝画面px に落ちる。 */
    state.editor.paperScale = function () {
      var sh = curSheet();
      if (!sh || !sh.frameFixed || !sh.frame || !window.Exporter) return null;
      return Exporter.scaleFor(sh.frame, sh.orient);
    };

    /* 🔒 §30-25-7（2026-09-13 オーナー実機「ZL を変えたらテキストの大きさも
     * 一緒に変わるべき」）: 紙のミリ → 画面px の換算率を editor へ渡す。
     * 🔴 editor の中の mm（SHEET_TEXT_MM・MARK.hatchMm・COMPASS.rMm…）は
     *    「記載欄 138mm 基準の mm」で、紙には SHEET_SCALE 倍で刷られる。
     *    だから **紙1mmのpx（paperMmPxNow）× SHEET_SCALE** を渡すと、
     *    画面の「文字 ÷ 枠」＝ 紙の「文字 ÷ 図」＝ 紙と同じ見え方になる。
     * 🔴 枠や画面がまだ無い時は null ＝ editor 側の定数（SHEET_MM_PX）に落ちる。 */
    state.editor.frameMmPx = function () {
      if (!window.Exporter || !(Exporter.SHEET_SCALE > 0)) return null;
      var k = paperMmPxNow();
      return (k > 0) ? k * Exporter.SHEET_SCALE : null;
    };

    /* 🔒 §23（なぞり出し・Step 7）。曇り下書きの canvas は下敷きと SVG の間に入る。
     * 🔴 実体化物は普通のオブジェクト（source:'reveal'）なので、以後はドラッグ・
     *    消しゴム・undo・保存が既存どおり効く。所在図の作り直しでも消えない
     *    （あちらが消すのは source==='shozaizu' だけ）。 */
    state.reveal = new Reveal(state.map, state.editor);
    state.editor.reveal = state.reveal;
    state.reveal.onReveal = function (n, info) {
      info = info || {};
      // 出典（§24-3）はシートごと。地理院ベクトルタイルを使ったので必ず足す
      noteDraftAttribution(false);
      /* 🔒 §23-6（ODbL）: OSM 由来の名称を1個でも紙に載せたら、
       * **そのシートの出典**に「© OpenStreetMap contributors」を足す。
       * 書き出しは Produced Work なので、出典表記さえ入れば商用可。 */
      if (info.osm) noteOsmAttribution();
      updateHistoryButtons();
      var parts = [];
      if (n) parts.push(n + ' 本の線');
      if (info.names) parts.push(info.names + ' 個の名称');
      if (!parts.length) return;
      hint('なぞった所を ' + parts.join('と')
           + 'にしました（選択・消しゴム・Ctrl+Z が効きます）', 2600);
    };
    /* 🔴 §23-6 fail-soft: 取得の状態は画面に出す。落ちた時も
     * 「いまは名称が取れない」と分かるだけで、作図は止めない。 */
    state.reveal.onNames = function () { renderNameStat(); };
    syncRevealSizes();

    /* 🔒 §28-13 決定3（Step 4）: ガイダンス④の［交差点名・バス停名を地図に重ねる］。
     * 🔴 これは**見るだけ**の層。editor.objects には1個も足さない＝紙にも出ないし
     *    案件にも保存しない（画面の状態）。データは所在図生成と同じ OSM（Overpass）。 */
    state.namelay = new NameLay(state.map, state.editor);
    state.namelay.onStatus = function (st) { renderNameLayStat(st); };

    state.stamp = new StampPanel(state.editor);

    /* 画像の下敷き（正典 §16-3）。地図と描画レイヤーの間に入る。
     * 画像そのものは IndexedDB（端末内）で、案件には配置メタだけ入れる。 */
    state.imglay = new ImgLay(state.map);
    state.imglay.on('change', function () {
      if (!state.current) return;
      state.current.maps[state.kind].image = state.imglay.getMeta();
      Store.autosave(state.current);
    });
    state.imglay.on('edit', function () { syncImagePanel(); });

    buildPins();

    // 手元確認用の足がかり（本番ドメインでは生やさない）
    if (location.hostname === 'localhost' || location.hostname === '127.0.0.1') {
      window.SHAKO_DEBUG = state;
    }
  }

  /**
   * 現在のシートの保存済み表示状態を地図へ反映する。
   * 🔴 §24-1 の分担: 下敷き（種類・濃さ・取り込み画像）は**種類ごと・案件で共有**（c.maps[kind]）、
   *    位置とズームは**シート1枚ごと**（sheet.center / sheet.zoom）。
   */
  function applySheetToMap() {
    var c = state.current;
    if (!c || !state.map) return;
    var m = c.maps[state.kind];
    var sh = curSheet();

    // 下敷きの種類
    var u = resolveUnderlay(m.underlay);
    m.underlay = u.id;
    state.underlayName = u.provider;
    $('underlaySel').value = u.id;
    $('underlayNote').textContent = u.note || '';
    state.map.setUnderlay(u.provider, u.kind);
    state.map.setUnderlayKind(u.kind);
    if (u.provider === 'google') activateGoogle();

    // 透明度
    var o = m.underlayOpacity === undefined ? 1 : m.underlayOpacity;
    $('opacity').value = Math.round(o * 100);
    $('opacityVal').textContent = Math.round(o * 100) + '%';
    $('underlayOff').checked = (o === 0);
    applyOpacity(o);

    // 画像の下敷きはタブ別（正典 §16-3）
    if (state.imglay) {
      // 画像の読み込みは非同期。ウィザードの再開判定・認識の実行はこれを待つ
      state.imgLoading = true;
      state.imgLoad = state.imglay.load(m.image || null, c.id, state.kind)
        .then(function () { state.imgLoading = false; syncImagePanel(); })
        .catch(function () { state.imgLoading = false; });
    }

    // 位置（シートごと・§24-1）。シートを切り替えるとその紙の場所へ戻る
    var center = (sh && sh.center) || c.points.lot || c.points.home;
    var zoom = sh ? sh.zoom : undefined;
    if (center) {
      state.map.setView(center, zoom, true);
    } else {
      state.map.setView(null, zoom, true);
    }
    state.map._render();
    renderOverlay();
    /* 🔴 上の setView は silent（viewend の副作用を避けるため "change" を発火しない）。
     * だが Editor.render() は map.on('change', ...) にしか繋がっていない（editor.js）ので、
     * このままだと直前の bind() 時点の古いズーム/中心のまま描画パーツが取り残される
     * （案件を開いた直後・所在図⇄配置図タブ切替の直後に「縮んで見える」実機不具合の原因）。
     * ここで明示的に呼び直して、保存済みズームに合わせて引き直す。 */
    if (state.editor) state.editor.render();
    $('mapAttr').textContent = state.map.attribution();
    updateUnderlaySrc();
    updateGoogleLink();
    updateScale();
    sgSyncUnderlay();               // 🔒 §28-5 B: シート切替・案件を開いた時も④の〇を合わせる
    schedulePlateauCheck();        // 🔒 §26-4-e
  }

  function updateUnderlaySrc() {
    var el = $('underlaySrc');
    var s = (state.map && state.map.attribution()) || '';
    // Google はアダプタが '' を返す（帰属は地図画像の中に出るため）
    if (state.underlayName === 'google') {
      s = 'Google マップ（帰属表示は地図の中に出ます）'
        + '\n🔴 この下敷きは見る・位置確認のみ。なぞって作図しないでください（§11-b）。';
    }
    // 正典 §1-3 の核心。利用者にもはっきり見えるようにしておく。
    s += '\n下敷きの地図・写真は書き出しに含まれません。';
    el.style.whiteSpace = 'pre-line';
    var warn = false;
    if (state.googleFailed) {
      s += '\n⚠ Google 地図を表示できませんでした。キーのリファラ制限・請求設定をご確認ください。';
      warn = true;
    }
    /* 🔒 §26-4-e: PLATEAU は対象都市の外に配信タイルが無い（§18-am）。
     * 黙って灰色のままだと「アプリが壊れた」に見えるので、はっきり伝えて
     * 代わりの下敷き（地理院オルソ）を案内する。 */
    if (state.plateauOut) {
      s += '\n⚠ この場所は PLATEAU オルソの対象地域ではありません（写真が配信されていません）。'
         + '［正射写真 地理院オルソ］に切り替えてください。';
      warn = true;
    }
    el.style.color = warn ? 'var(--warn)' : '';
    el.textContent = s;
    sgSyncPlateauNote();      // 🔒 §30-7 A(3): ⑤の PLATEAU 行にも同じ判定を映す
  }

  /**
   * 🔒 §30-7 A(3)（2026-09-08 オーナー指示）: PLATEAU を選んでいて、いまの枠の範囲に
   * PLATEAU の写真が無い時、⑤の PLATEAU の説明行に一言出す（勝手に切り替えない）。
   * 🔴 判定は既存の state.plateauOut（schedulePlateauCheck・§26-4-e）をそのまま使う。
   *    上部バーの警告（updateUnderlaySrc 内）と同じ出どころ・呼ぶ側もそこ1か所。
   */
  function sgPlateauOut() {
    var c = state.current, m = c && c.maps.haichizu;
    return !!(state.plateauOut && state.kind === 'haichizu'
              && m && m.underlay === 'plateau');
  }
  function sgSyncPlateauNote() {
    var el = $('sgPlateauOutNote');
    if (!el) return;
    el.hidden = !sgPlateauOut();
    /* 🔒 §30-12-5 配置図①-3: この一言は［下敷きの写真を変える］の箱の中にあるので、
     * 出た時はその機能だけ自動で開く（閉じたままだと見えないため）。 */
    sgMoreSync();
  }

  /* 🔒 §26-4-e: PLATEAU の対象外地域の判定。
   * 🔴 タイルの読み込みは非同期なので、地図が止まってから少し待って数える。
   *    ZL10 未満は1枚も要求しない（total=0）ので「対象外」とは言わない。
   * 🙋 仮値 700ms（実機目視で確定）。 */
  var PLATEAU_CHECK_MS = 700;
  function schedulePlateauCheck() {
    if (state.plateauTimer) clearTimeout(state.plateauTimer);
    state.plateauTimer = setTimeout(function () {
      state.plateauTimer = null;
      var cov = state.map ? state.map.underlayCoverage() : null;
      var out = !!(cov && cov.kind === 'plateau' && cov.total > 0
                   && cov.ok === 0 && cov.miss === cov.total);
      if (state.plateauOut !== out) {
        state.plateauOut = out;
        updateUnderlaySrc();
      }
    }, PLATEAU_CHECK_MS);
  }

  /* 下敷きの濃さ・OFF は**地図だけ**に効く（正典 §16-3 改）。
   * 取り込んだ画像は独立の［画像］トグルで出し入れする。
   * 標準の使い方＝位置合わせ→固定→「地図OFF＋画像ON」でなぞる。 */
  function applyOpacity(o) {
    if (state.map) state.map.setUnderlayOpacity(o);
    $('map').style.background = o === 0 ? '#fff' : '#e8eaee';
  }

  function buildUnderlayOptions() {
    var sel = $('underlaySel');
    /* 🔴 選択中の値を控えてから作り直す（2026-09-07 §28-13 Step 4 で発見・既存不具合）。
     * `innerHTML=''` で option を捨てると select の値が先頭（PLATEAU）に落ちるので、
     * Google の認証失敗でここを通った時、**地図は OSM のままなのに上部バーは
     * PLATEAU** という食い違いが出ていた。④の〇は上部バーの値を見るので、
     * この食い違いはそのままガイダンスにも移る。 */
    var keep = sel.value;
    sel.innerHTML = '';
    UNDERLAYS.forEach(function (u) {
      // キーが無い／拒否された時は Google の2種を出さない（§17-b）
      if (u.google && !googleAvailable()) return;
      var o = document.createElement('option');
      o.value = u.id;
      o.textContent = u.label;
      sel.appendChild(o);
    });
    /* 消えた選択肢（Google を外した時のその値）でなければ選び直す。
     * 消えていた時は呼び出し側（googleFallback）が setUnderlayChoice で入れ替える。 */
    if (keep) sel.value = keep;
    /* 🔒 §28-13 決定4 / §28-14 ④: ガイダンス④の〇も**同じ判断**で出し入れする（1か所）。
     * キーが無い／拒否された環境では Google の2つを出さない。
     * 🔒 §29-1 ⑤: 配置図の⑤（Google 航空写真の1つ）も同じ判断で出し入れする。 */
    /* 🔒 §30-22-1 3: ガイダンス①の［Google 航空写真］（#sgU1Photo）も同じ判断で出し入れ */
    var ok = googleAvailable();
    document.querySelectorAll('#sgUnderlay .gopt, #sgUnder5 .gopt, #sgUnder1 .gopt')
      .forEach(function (g) { g.hidden = !ok; });
    /* 🔒 §30-10: ガイダンス①の2つ目の〇。キーがあれば Google マップ、
     * 無ければ地理院 地図（淡色）に**自動で差し替える**。①は場所を探す段なので
     * 地図でよい（航空写真は要らない）。撮影時期は地図系なので出さない
     * （sgSyncEra は④・⑤だけを見る・ここへは触れない）。
     * 🔴 判断はここ1か所（googleAvailable）。表示文字では分岐しない（§26-2 注意②）。 */
    var r1 = $('sgU1Map'), n1 = $('sgU1MapName'), t1 = $('sgU1MapNote');
    if (r1 && n1 && t1) {
      r1.value = ok ? 'google-map' : 'gsi-pale';
      n1.textContent = ok ? 'Google マップ' : '地理院 地図（淡色）';
      t1.textContent = ok
        ? '道路名・お店が一番詳しい。🔴 Google の規約で、この地図から'
          + '写し取る（なぞる）ことはできません。見て参考にするだけ'
        : '道路・建物の形。文字は少なめで見やすい';
      sgSyncUnderlay();          // 値が変わったので〇の入り／切りを合わせ直す
    }
  }

  /** 保存値を選択肢 id に直す。
   *  旧形式 'satellite'/'roadmap' も受ける（過去の案件を開いた時に
   *  「下敷きが無い」にならないように）。
   *  🔴 Google で保存された案件は、キーが無い／拒否された環境では
   *     地理院の近い物へ落とす（§12-a のフォールバック方針）。 */
  function resolveUnderlay(v) {
    var u = underlayById(v);
    if (u && u.google && !googleAvailable()) {
      u = underlayById(u.kind === 'roadmap' ? 'gsi-pale' : 'gsi-ort');
    }
    if (u) return u;
    if (v === 'roadmap') return underlayById('gsi-pale');
    return underlayById('gsi-ort');      // 'satellite' 等
  }

  function setUnderlayChoice(id) {
    if (!state.current) return;
    var u = resolveUnderlay(id);
    state.current.maps[state.kind].underlay = u.id;
    state.underlayName = u.provider;
    $('underlaySel').value = u.id;
    $('underlayNote').textContent = u.note || '';
    state.map.setUnderlay(u.provider, u.kind);
    state.map.setUnderlayKind(u.kind);
    if (u.provider === 'google') activateGoogle();
    $('mapAttr').textContent = state.map.attribution();
    // 🔒 §26-4-e: 下敷きを替えたら前の判定は捨てて数え直す
    state.plateauOut = false;
    updateUnderlaySrc();
    updateScale();
    schedulePlateauCheck();
    sgSyncUnderlay();      // 🔒 §28-5 B: ④の〇も追従（1つのデータ・唯一の出入口）
    /* 🔒 §30-35-4 1: 下敷きが替わると出典の行数（＝高さ）が変わる（地理院1行／
       OSMFJ 2行）ので、道具の案内帯の置き場所も測り直す。 */
    updateDrawBadge();
    Store.autosave(state.current);
  }

  /**
   * 🔴 §26-2 注意① の唯一の出入口。Editor は bind した配列を**その場で書き換える**
   * （this.objects への代入はしない）ので、シートを移った・配列を差し替えた時は
   * ここを必ず通す。通し忘れると、編集が保存されない配列に書き続ける。
   */
  function bindCurrentSheet() {
    var sh = curSheet();
    if (!sh) return;
    state.editor.bind(sh.objects);
    /* 🔒 §24-1 / §23-3: なぞり出しの実体化物は**そのシート固有**。
     * 区間帳簿もシートごとに分けないと、別の紙でなぞった区間が「もう出ている」
     * 扱いになって浮き出なくなる。 */
    if (state.reveal) state.reveal.setSheet(sh.id);
    updateHistoryButtons();
  }

  /** ブラシ3段の選択状態を画面に反映（🔒 §23-3） */
  function syncRevealSizes() {
    var cur = state.reveal ? state.reveal.size : 'medium';
    document.querySelectorAll('#rvSizes .rv-size').forEach(function (b) {
      b.classList.toggle('is-active', b.dataset.rsize === cur);
    });
  }

  /* ---------- 名称の分類なぞり出し（🔒 §23-5 / §23-6・Step 8） ----------
   * 分類チェックの ON/OFF を Reveal へ渡すだけ。どの名称をどこに出すか・
   * 名寄せ・取得は reveal.js / osm.js の仕事（app は配線に徹する）。
   * 🔴 チェックの状態は**案件データに入れない**（画面の状態なので JSON は不変）。 */

  /** 🔒 §26-4-e: 分類チェックを全OFFへ戻す（案件を開いた時） */
  function resetNameCats() {
    document.querySelectorAll('#rvNames .rv-cat').forEach(function (b) {
      b.checked = false;
    });
    if ($('rvCatAll')) $('rvCatAll').checked = false;
    applyNameCats();
  }

  /**
   * 交差点名・バス停名の重ね表示（🔒 §28-13 決定3）。
   * 🔒 §30-28-2 9: 出す所は**2か所**（所在図④の▼ ／ 道具メニューの▼）だが、
   *    値は1つ（state.namelay.on）。欄・ボタン・一言の一覧はこの表1か所。
   */
  var NAME_LAY_BOXES = ['sgNameLay', 'sideNameLay'];
  var NAME_LAY_STATS = ['sgNameLayStat', 'sideNameLayStat'];
  var NAME_LAY_PICKS = ['sgNamePick', 'sideNamePick'];

  /** 重ね表示の入り切り（チェックはどちらを触っても両方が揃う） */
  function setNameLay(on) {
    NAME_LAY_BOXES.forEach(function (id) {
      var b = $(id);
      if (b) b.checked = !!on;
    });
    if (state.namelay) state.namelay.setOn(!!on);
    // 🔒 §30-16: 重ね表示を OFF にしたら拾う状態も終わる（拾う物が無くなるので）
    if (!on) stopNamePick();
    syncNamePickBtn();
  }

  /** 🔒 §28-13 決定3: 重ね表示を OFF へ戻す（案件を開いた時・画面の状態） */
  function resetNameLay() {
    stopNamePick();                 // 🔒 §30-16: 拾う状態も持ち越さない
    setNameLay(false);
    renderNameLayStat({ on: false });
  }

  /** チェックの現状を集めて Reveal に渡す */
  function applyNameCats() {
    var cats = {}, all = true, any = false;
    document.querySelectorAll('#rvNames .rv-cat').forEach(function (b) {
      if (b.checked) { cats[b.dataset.cat] = true; any = true; }
      else all = false;
    });
    $('rvCatAll').checked = all && any;
    if (state.reveal) state.reveal.setNameCats(cats);
    renderNameStat();
  }

  /**
   * 取得の状態と件数を出す。
   * 🔴 §23-6: 取得に失敗しても**名称だけ**が出ないだけで作図は続く。
   *    「今は名称が取れない」と分かる表示を必ず出す（黙って消えない）。
   */
  function renderNameStat() {
    var box = $('rvNameStat'), btn = $('rvNameRetry');
    if (!box || !state.reveal) return;
    var s = state.reveal.nameStats();
    if (!s.on) { box.hidden = true; btn.hidden = true; return; }
    box.hidden = false;
    var warn = false, msg;
    if (s.osm.state === 'loading') {
      msg = '名称を取りに行っています…';
    } else if (s.osm.state === 'error') {
      warn = true;
      msg = 'いまは名称の一部（交差点名・お店・会社・バス停・細かい道路名）が'
          + '取れません。作図はそのまま続けられます。';
    } else if (s.osm.state === 'wide') {
      warn = true;
      msg = '範囲が広すぎて名称を取りに行けません。少し拡大してください。';
    } else {
      msg = '薄く出ている名称 ' + s.shown + ' 個（なぞると1個まるごと図形になります）';
      /* 重なって出せなかった分は黙って消さない。拡大すれば出ると伝える（§23-5） */
      if (s.hidden) msg += '／重なって出せない ' + s.hidden + ' 個は拡大すると出ます';
    }
    box.textContent = msg;
    box.classList.toggle('is-warn', warn);
    btn.hidden = !warn;
  }

  /**
   * 🔒 §28-13 決定3: ④の重ね表示の状態（切替の横の一言）。
   * 🔴 §23-6 fail-soft のとおり、取れない時も作図は止めない。
   *    ここは黙って何も描かない代わりに「今は出ません」とだけ伝える
   *    （再試行ボタンは付けない＝なぞり出しと違い、押す理由が無い見るだけの層）。
   */
  function renderNameLayStat(st) {
    var msg = '';
    if (st && st.on) {
      if (st.state === 'loading') msg = '取得中…';
      else if (st.state === 'error') {
        msg = 'いまは交差点名・バス停名を取れません（作図はそのまま続けられます）';
      } else if (st.state === 'wide') msg = '範囲が広すぎます。少し拡大してください';
      else {
        msg = '重ねて表示中：' + st.shown + ' 個'
          + '（この文字は図に入りません・書き出しにも出ません）';
      }
    }
    /* 🔒 §30-28-2 9: 一言の出し先は2か所（所在図④ ／ 道具メニューの▼）だが
     * 文面の出どころはこの1か所。 */
    NAME_LAY_STATS.forEach(function (id) {
      var box = $(id);
      if (!box) return;
      box.hidden = !msg;
      box.textContent = msg;
    });
  }

  /* ---------- 🔒 §30-16: 重ねた交差点名・バス停名をクリックで図に入れる ----------
   * オーナー:「交差点名・バス停名を地図に重ねる のチェックをした後に、クリックで
   * バス停名を表示できるボタンが欲しい」＝ なぞって表示を、ここでは**1個ずつ**適用する。
   * 🔴 拾う状態（state.namePick）は**画面の状態**。案件には保存しない。
   * 🔴 図に入る物は印つき文字（§28-7）。作るのは editor.placeNamed の1か所。 */

  /** ボタンの出方を重ね表示のチェックに合わせる（OFF なら押せない） */
  function syncNamePickBtn() {
    var on = !!(state.namelay && state.namelay.on);
    /* 🔒 §30-28-2 9: ボタンは2か所（所在図④ ／ 道具メニューの▼）だが値は1つ */
    NAME_LAY_PICKS.forEach(function (id) {
      var b = $(id);
      if (!b) return;
      b.disabled = !on;
      b.title = on ? '押してから、地図に薄く出ている交差点名・バス停名をクリックすると'
                   + '、その名前が図に入ります'
                   : '先に上のチェックを入れてください';
      b.classList.toggle('is-on', !!state.namePick);
    });
  }

  function toggleNamePick() {
    if (state.namePick) { stopNamePick(); return; }
    startNamePick();
  }

  function startNamePick() {
    if (state.namePick) return;
    if (!state.namelay || !state.namelay.on) return;
    state.namePick = true;
    $('map').style.cursor = 'crosshair';
    /* 地図・描画エンジンより**先**に受け取るため、親要素の capture で拾う
     * （§16-5 C の［辺に沿わせる］startEdgePick と同じ作法）。 */
    var wrap = document.querySelector('.map-wrap');
    wrap.addEventListener('pointerdown', onNamePickDown, true);
    wrap.addEventListener('click', onNamePickClick, true);
    syncNamePickBtn();
    hint('図に入れたい交差点名・バス停名をクリック。'
       + '終わるには Esc か、もう一度このボタン', 0);
  }

  /** 拾う状態を終える。🔴 掴んだままにすると地図クリックを全部横取りしてしまう */
  function stopNamePick() {
    if (!state.namePick) return;
    state.namePick = false;
    $('map').style.cursor = '';
    var wrap = document.querySelector('.map-wrap');
    wrap.removeEventListener('pointerdown', onNamePickDown, true);
    wrap.removeEventListener('click', onNamePickClick, true);
    syncNamePickBtn();
    hintHide();                  // 出しっぱなしにしていた案内を消す
  }

  function onNamePickDown(e) {
    if (!state.namePick || !state.map) return;
    if (e.button !== 0) return;                     // 中ボタン等の従来のパンは残す
    if (!$('spaceBadge').hidden) return;            // スペース＝一時パンには譲る
    if (!state.map.el.contains(e.target)) return;   // 地図の外（＋−ボタン等）は素通し
    var r = $('map').getBoundingClientRect();
    var px = e.clientX - r.left, py = e.clientY - r.top;
    if (px < 0 || py < 0 || px > r.width || py > r.height) return;
    /* 🔒 §30-16-1: 拾えなかった時も**何もしない**（選択の解除・マーカー設置・
     * 地図の移動を起こさない）ので、拾えても拾えなくてもここで止める。 */
    e.preventDefault();
    e.stopPropagation();
    pickNameAt(px, py);
  }

  /** pointerdown を止めても click は届くので、こちらも飲む（幅矢印の2点目よけ） */
  function onNamePickClick(e) {
    if (!state.namePick || !state.map) return;
    if (!state.map.el.contains(e.target)) return;
    e.stopPropagation();
  }

  function pickNameAt(px, py) {
    var hit = state.namelay && state.namelay.hitName(px, py);
    if (!hit) { hint('近くに名前がありません', 1800); return; }
    /* 🔒 §30-16-1: 分類 → 印の種類。表示文字列ではなく分類 id で分ける（§26-2 注意②） */
    var kind = (hit.cat === 'bus') ? 'bus' : 'signal';
    var o = state.editor.placeNamed(kind, { lat: hit.lat, lng: hit.lng }, hit.name);
    if (!o) return;
    /* 🔒 §23-6（ODbL）: OSM 由来の名称を紙に載せたら、その紙に出典を足す */
    noteOsmAttribution();
    /* 入れた名前は重ね表示から消える（「紙に既にある名前は重ねない」の既存規則）。
     * editor の 'change' でも invalidate は走るが、順番に依らず必ず引き直す。 */
    if (state.namelay) state.namelay.invalidate();
    updateHistoryButtons();
    /* 🔒 §30-16-4: 入れたら拾う状態を解いて選択道具に戻し、入れた文字を選んだ
     * 状態にする（すぐドラッグで場所を直せる）。§30-19-1（placeStampOne）と
     * 同じ作法。placeNamed → _pushNew が既に selection を立てているが明示しておく。 */
    stopNamePick();
    state.editor.selection = [o.id];
    state.editor.setTool('select');
    hint('「' + hit.name + '」を図に入れました。ドラッグで場所を直せます', 2500);
  }

  /**
   * 🔒 §23-6（ODbL）: OSM を使った紙にだけ出典を足す。
   * §24-3 のとおり出典は**シート単位**なので、いま編集している紙に入れる。
   */
  function noteOsmAttribution(sheet) {
    var c = state.current, sh = sheet || curSheet();
    if (!c || !sh || !window.OSM) return;
    if (!Array.isArray(sh.attributions)) sh.attributions = [];
    if (sh.attributions.indexOf(OSM.ATTRIBUTION) < 0) {
      sh.attributions.push(OSM.ATTRIBUTION);
    }
    Store.autosave(c);
  }

  /* ---------- シート帯（🔒 §24-1 / §24-5 / §25-2 / §25-3） ----------
   * 追加・複製・削除・並べ替え・切替＋A4の向き。
   * 🔴 シート配列を触る操作は全部この節にまとめる。objects の配列を差し替えた時は
   *    必ず bindCurrentSheet() を通すこと（§26-2 注意①）。 */

  /** シート帯を描き直す。いま何の図の何枚目を作っているかを常時表示する（§25-2） */
  function renderSheetBar() {
    var c = state.current;
    var bar = $('edSheetBar');
    if (!bar) return;
    if (!c) { bar.hidden = true; return; }
    bar.hidden = false;
    // 図の種類は画面全体の色にも効かせる（どこを見ても取り違えない・§25-2）
    $('editorView').setAttribute('data-kind', state.kind);
    document.querySelectorAll('.tab').forEach(function (t) {
      t.classList.toggle('is-active', t.dataset.kind === state.kind);
    });

    var list = sheetsOf(state.kind);
    var idx = activeIdx(state.kind);
    $('sbNow').textContent = KIND_JA[state.kind]
      + (list.length > 1 ? ' ' + (idx + 1) + '/' + list.length + '枚目' : '');

    /* 🔒 §30-26-2（2026-09-14 オーナー指示）: 紙は「番号＋ルーペ」のひと組。
     * 番号を押す＝その紙へ切り替え（今までどおり）／ルーペを押す＝その紙だけの
     * プレビュー。紙が1枚でも組は出す（1＋ルーペ）。 */
    var chips = $('sbChips');
    chips.innerHTML = '';
    list.forEach(function (s, i) {
      var wrap = document.createElement('span');
      wrap.className = 'sheet-chip' + (i === idx ? ' is-active' : '');
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'sheet-no';
      b.textContent = String(i + 1);
      /* 🔒 §28-10 裁定6: 数え方は書き出しの一覧と同じ（sheetDrawCount）。
         方位記号だけの紙は「図形 0 個」＝そのまま白紙として書き出されない紙。 */
      b.title = KIND_JA[state.kind] + ' ' + (i + 1) + '枚目'
        + '（' + (s.orient === 'landscape' ? 'A4横' : 'A4縦') + '・図形 '
        + sheetDrawCount(s) + ' 個）';
      b.addEventListener('click', function () { selectSheet(i); });
      var lp = document.createElement('button');
      lp.type = 'button';
      lp.className = 'sheet-loupe';
      // 🔴 絵と説明は TOOL_ICONS.loupe の1か所（applyToolIcon が入れる）
      lp.dataset.icon = 'loupe';
      applyToolIcon(lp);
      lp.addEventListener('click', function () { previewSheet(s); });
      wrap.appendChild(b);
      wrap.appendChild(lp);
      chips.appendChild(wrap);
    });

    var cur = list[idx];
    document.querySelectorAll('#sbOrient button').forEach(function (b) {
      b.classList.toggle('is-active', cur && b.dataset.orient === cur.orient);
    });
    $('sbDel').disabled = list.length <= 1;   // 最後の1枚は消させない
    $('sbLeft').disabled = idx <= 0;
    $('sbRight').disabled = idx >= list.length - 1;
    var fixed = !!(cur && cur.frameFixed && cur.frame);
    $('sbFix').textContent = fixed ? '枠を決め直す' : '枠を決定';
    $('sbFix').classList.toggle('is-on', fixed);
    $('sbGoFrame').hidden = !fixed;           // 決めていない間は枠＝画面なので不要
    /* 🔒 §24-2-3/§24-4-d: 「いま枠がどちらの動き方をしているか」を必ず言葉でも出す
       （枠の線だけだと、決定前後の違いが分からないというオーナー報告への対応） */
    $('sbNote').textContent = fixed
      ? '枠は固定中（地図だけ動かせます）'
      : '枠は画面につきます（地図を動かすと枠も動きます）';
    /* 🔒 §28-3: ガイダンス②の〇（A4縦/横）と［枠を決定］も同じ値に揃える
       ＝どちらから触っても同じ結果（§26-2「同じ操作は同じ結果」） */
    sgSyncOrient();
    // 🔒 §29-5 決定2: 枠の決定/解除・紙の切替で枠の中心が変わるので撮影時期も引き直す
    sgSyncEra();
    if (navOnSide()) { sgRenderFoot(state.nav.step); sgRenderStatus(); }
  }

  /** シート（紙）を切り替える。🔴 図形の配列が変わるので bind をやり直す */
  function selectSheet(i) {
    var c = state.current;
    if (!c) return;
    var list = sheetsOf(state.kind);
    if (i < 0 || i >= list.length || i === activeIdx(state.kind)) return;
    invalidateFillRuns();             // 解析結果は紙をまたがない（§16-13 と同じ理由）
    persistSheetState();              // いまの紙の位置・ズームを控える
    c.active[state.kind] = i;
    bindCurrentSheet();
    renderSheetBar();
    applySheetToMap();
    renderOverlay();
    updateScale();
    Store.autosave(c);
    hint(KIND_JA[state.kind] + ' ' + (i + 1) + '枚目に切り替えました', 2200);
  }

  /** 図形の id（🔒 値の出どころは1か所。editor.js の uid と同じ形） */
  function newObjId() {
    return 'o' + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
  }

  /**
   * 紙を1枚足す（src を渡すと複製・🔒 §24-5「前の枚を写して微調整する逃げ道」）。
   * 🔴 複製は**深いコピー**。浅くすると図形オブジェクトを2枚で共有してしまい、
   *    片方を直すともう片方も変わる＝§24-1「完全に独立」が壊れる。
   * 🔒 §30-26-1: opt.extract＝［枠を抜出し追加］から。**紙の作り方は同じ**で、
   *    違うのは押した後の案内（字幕とガイダンスの段）だけ。
   */
  function addSheet(src, opt) {
    var c = state.current;
    if (!c) return;
    persistSheetState();
    var list = sheetsOf(state.kind);
    var at = activeIdx(state.kind);
    var init;
    if (src) {
      init = JSON.parse(JSON.stringify({
        orient: src.orient, center: src.center, zoom: src.zoom,
        frame: src.frame, objects: src.objects,
        // 写した図形は同じデータ源から来ているので出典も一緒に写す（🔒 §24-3）
        attributions: src.attributions || [],
        // 🔒 §30-32-6 3: 消したマーカーの表示も写す（抜き出した紙にはコピーされる）
        pinHidden: src.pinHidden || {}
      }));
      /* 図形の id も振り直す。同じ id が別の紙に居ても今は害が無いが、
         複数枚をまとめて扱う Step 6 以降で取り違えの種になる。
         🔴 source / role / pinKey / markRole はそのまま（§30-26-1 2）＝
            写した紙でも役割オブジェクトの追従・掃除が紙ごとに効く。 */
      init.objects.forEach(function (o) { o.id = newObjId(); });
    } else {
      // 新しい紙は「いま見えている場所」から始める（続けて描き始められる）
      init = { orient: (list[at] && list[at].orient) || 'portrait',
               center: state.map ? state.map.getCenter() : null,
               zoom: state.map ? state.map.getZoom() : undefined,
               frame: null, objects: [] };
    }
    var sh = Store.newSheet(state.kind, init);   // id は必ず新しく振られる
    list.splice(at + 1, 0, sh);
    c.active[state.kind] = at + 1;
    bindCurrentSheet();
    renderSheetBar();
    applySheetToMap();
    renderOverlay();
    // 🔒 §24-3: 書き出しは全シートなので、枚数が変わったら一覧も出し直す
    Store.autosave(c);
    var did = (opt && opt.extract) ? '抜き出しました'
            : (src ? '複製しました' : '追加しました');
    hint(KIND_JA[state.kind] + ' を1枚' + did
      + '（' + (at + 2) + '/' + list.length + '枚目）', 3200);
    // 🔒 §30-26-1 4: 押した直後の案内（字幕＋「枠を決める」の段へ）
    if (opt && opt.extract) afterExtractSheet();
  }

  /* ---- 🔒 §30-26-1（2026-09-14 オーナー指示）: ［枠を抜出し追加］ ----
   * > 「広い駐車場は4つに分割して抜き出せば、それぞれが A4 で出るので文字が大きくなる」
   * 紙の作り方は addSheet(src) 1本（＝［複製］と同じ deep copy の経路）。
   * 違うのは**押した後の案内**だけ＝ここに閉じ込める。 */

  /** 押した直後の字幕（番号なし）。🔴 文の出どころはこの1か所（「／」＝改行） */
  var SG_EXTRACT_SAY = 'この紙は、いまの紙の中身を写した新しい紙です。'
    + '／広い駐車場の一部を大きく出したい時に使います。'
    + '／／地図を寄せて、出したい範囲で［枠を決定］してください。'
    + '／この紙で直した文字や印は、元の紙には影響しません';

  /* その図の「枠を決める」段（その図の中での番号）。
   * 🔴 所在図は②「所在図の枠を決める」／配置図は①「下敷きと枠」＝図ごとに違う。
   *    通し番号への読み替えは navStepOf 1本（NAV の番号を直に書かない）。 */
  var FRAME_DISP = { shozaizu: 2, haichizu: 1 };
  function frameStepOf(kind) { return navStepOf(kind, FRAME_DISP[kind] || 1); }

  function afterExtractSheet() {
    /* ガイダンス中なら、その図の「枠を決める」の段へ移る（§30-26-1 4）。
     * 🔴 navGo は段を移る時に前の字幕を消すので、**字幕はそのあと**に出す。
     * 🔴 入り方は必ず「戻る」扱い（back:true）。navGo は配置図①へ**進んで**入った時に
     *    駐車場マーカー中心・ZL20 へ寄せ直すので、そのまま呼ぶと抜き出した紙が
     *    元の紙と違う場所で開いてしまう（§30-26-1 2「表示は元の紙と同じ中心・ズーム」）。 */
    if (state.nav) {
      var n = frameStepOf(state.kind);
      if (state.nav.step !== n) navGo(n, { back: true });
    }
    sgCaptionShow('', SG_EXTRACT_SAY);
  }

  /** ［枠を抜出し追加］。🔴 紙を作るのは addSheet 1本 */
  function extractSheet() {
    var src = curSheet();
    if (!state.current || !src) return;
    addSheet(src, { extract: true });
  }

  /**
   * 🔒 §30-26-2: 紙の帯のルーペ＝**その紙**のプレビュー。
   * 🔒 §30-27-1 1: 出す画面は他と同じ1つ（違うのは「どの紙から見せるか」だけ）。
   *    他の紙は札と［次のページ ›］でそのまま見に行ける。
   */
  function previewSheet(sh) {
    if (!state.current || !sh) return;
    // 図形が1個も無い紙は書き出されない（§26-4-e）＝空のプレビューを出さない
    if (!sheetHasDrawing(sh)) {
      hint('この紙にはまだ図形がありません（図を描いてから確かめてください）', 3200);
      return;
    }
    openPreview({ kind: state.kind, sheetId: sh.id });
  }

  function deleteSheet() {
    var c = state.current;
    if (!c) return;
    var list = sheetsOf(state.kind);
    if (list.length <= 1) {
      hint('最後の1枚は削除できません', 2500);
      return;
    }
    var i = activeIdx(state.kind);
    var n = sheetDrawCount(list[i]);   // 🔒 §28-10 裁定6: 数え方は1か所
    if (!confirm(KIND_JA[state.kind] + ' ' + (i + 1) + '枚目を削除します（図形 '
                 + n + ' 個）。元に戻せません。よろしいですか？')) return;
    list.splice(i, 1);
    c.active[state.kind] = Math.min(i, list.length - 1);
    bindCurrentSheet();
    renderSheetBar();
    applySheetToMap();
    renderOverlay();
    Store.autosave(c);
    hint(KIND_JA[state.kind] + ' を1枚削除しました', 2800);
  }

  /** 並べ替え（いまの紙を前／後ろへ）。d = -1 / +1 */
  function moveSheet(d) {
    var c = state.current;
    if (!c) return;
    var list = sheetsOf(state.kind);
    var i = activeIdx(state.kind), j = i + d;
    if (j < 0 || j >= list.length) return;
    var tmp = list[i]; list[i] = list[j]; list[j] = tmp;
    c.active[state.kind] = j;
    // 🔴 中身は動いていない（同じシート object のまま）ので bind は据え置きでよいが、
    //    取り違えを防ぐため入口を1つに保つ（§26-2 注意①）
    bindCurrentSheet();
    renderSheetBar();
    Store.autosave(c);
    hint(KIND_JA[state.kind] + ' の順番を入れ替えました（' + (j + 1) + '枚目）', 2500);
  }

  /** 🔒 §25-3: A4の向きを紙ごとに決める。枠の形がその場で変わる */
  function setSheetOrient(orient) {
    var c = state.current;
    var sh = curSheet();
    if (!c || !sh) return;
    orient = (orient === 'landscape') ? 'landscape' : 'portrait';
    if (sh.orient === orient) return;
    sh.orient = orient;
    if (sh.frameFixed && sh.frame) {
      /* 🔒 §24-4-d: 決めた枠は**中心と紙の面積**を保ったまま向きだけ変える
       * （決定は解かない＝決め直しを強いない・Fable 助言）。
       * 🔴 直す前は `aspect` だけ書き換えて w_m を据え置いていたので、
       *    A4縦→A4横で紙の面積が asp縦/asp横 ＝ 0.452 倍に縮んでいた
       *    ＝ オーナー報告「A4横の枠が小さい」の正体（実測 372,447→168,313 px²）。
       * 紙の面積は w_m² / aspect なので、面積を保つ w_m は √(new/old) 倍。 */
      var oldAsp = Exporter.frameAspect(sh.frame);
      var newAsp = orientAspect(orient);
      sh.frame.w_m = sh.frame.w_m * Math.sqrt(newAsp / oldAsp);
      sh.frame.aspect = newAsp;
    } else {
      syncFrameFromView();        // 向きが変われば枠の形も変わる（画面から採り直す）
    }
    renderSheetBar();
    renderOverlay();              // 枠の線を新しい形で引き直す
    Store.autosave(c);
    // 🔒 §30-13-4: 紙の向きが変わると枠の形＝左の空きも変わる（字幕の置き場所の契機）
    sgCaptionPlace();
    hint('この紙は ' + (orient === 'landscape' ? 'A4 横' : 'A4 縦') + ' で出します', 2600);
  }

  /**
   * 🔒 §24-2-3「地図の移動と枠の移動の両方が簡単にできる」。
   * 決めていない間は **枠＝画面**（地図を動かせば枠も動く＝枠の移動）。
   * ［枠を決定］すると枠が地図に固定され、以後は**地図だけ**を動かして
   * その紙の中を仕上げられる（＝地図の移動）。もう一度押すと画面追従に戻る。
   */
  function toggleFrameFixed() {
    var c = state.current, sh = curSheet();
    if (!c || !sh) return;
    var f = frameFromView();          // null＝画面がまだ無い（枠は壊さない）
    if (sh.frameFixed) {
      sh.frameFixed = false;
      if (f) sh.frame = f;
      hint('枠を画面に戻しました（見えている枠の中が書き出されます）', 3000);
    } else {
      if (f) sh.frame = f;            // いま見えている枠でそのまま決める
      if (!sh.frame) { hint('画面の準備ができていません。少し待ってからもう一度お試しください', 3000); return; }
      sh.frameFixed = true;
      /* 🔒 §28-3: 枠を決めたら方位記号を枠の右上に**部品**として置く
       * （ガイダンスの②からでもシート帯からでも同じ関数＝同じ結果・§26-2）。 */
      var put = placeCompass(state.kind, sh);
      hint('この場所・この縮尺で枠を決めました。'
         + (put ? '方位記号を枠の右上に置きました（ドラッグで動かせます）。' : '')
         + 'あとは地図を自由に動かして中を仕上げられます', 4200);
    }
    renderSheetBar();
    renderOverlay();
    Store.autosave(c);
    // 🔒 §30-13-4: 枠の決定／解除で枠の位置が変わる（字幕の置き場所の契機）
    sgCaptionPlace();
  }

  /**
   * ［駐車場に寄る］。駐車場マーカーを中心に、枠を描ける大きさまで寄せる。
   * 🔒 §29-1 ⑤: ボタンは**2か所**（道具メニュー #btnFocusLot ／ ガイダンス⑤ #sgFocusLot）
   *    にあるが中身は1つ（§26-2「同じ操作は同じ結果」）。
   * 🔴 いまが既に 21 より大きい時は下げない（寄り過ぎを直す道具ではない）。
   */
  function focusLot() {
    var p = state.current && (state.current.points.lot || state.current.points.home);
    if (!p || !state.map) { hint('先にマーカーを置いてください', 2500); return; }
    state.map.setView(p, Math.max(state.map.getZoom(), 21));
    persistSheetState();
    if (navOnSide()) sgRenderStatus();
  }

  /** 決めた枠が画面いっぱいに入るところへ地図を戻す（枠そのものは動かさない） */
  function goToSheetFrame() {
    var sh = curSheet();
    if (!sh || !sh.frame || !state.map) { hint('この紙にはまだ枠がありません', 2500); return; }
    var b = Exporter.frameBounds(sh.frame);
    /* 枠と同じ形の窓に収める。
     * 🔒 Step 6（§24-4-b 持ち越し3）: 枠の投影が 0.7% 縦長だったのを直したので、
     *    3% のはみ出し許容は要らなくなった（「ZL16 に 0.6% 足りずに ZL15 へ落ちた」
     *    の 0.6% がまさにこのズレ）。
     * 🔴 0 にはしない: ぴったり同じ大きさの比較は浮動小数の丸めで落ちることがあり、
     *    落ちると**1段=半分**まで引いてしまう。0.5% は保険であって歪みの補正ではない。 */
    state.map.fitPoints([{ lat: b.north, lng: b.west },
                         { lat: b.south, lng: b.east }], -0.005, frameRectPx());
    syncFrameFromView();          // 固定中なら何もしない（枠は動かない）
    renderOverlay();
    hint('この紙の枠の場所へ戻りました', 2500);
  }

  /** 図の種類（所在図⇄配置図）を切り替える */
  function switchKind(kind) {
    if (!state.current || kind === state.kind) return;
    invalidateFillRuns();          // 別の図へ移ったら解析の結果は捨てる（§16-13）
    persistSheetState();
    state.kind = kind;
    // 種類ごと・シートごとに図形は完全に独立（🔒 §24-1）
    bindCurrentSheet();
    renderSheetBar();
    applySheetToMap();
    // 🔒 §18-ah: タブを移ったらピンの見せ方も引き直す（配置図では常に見える）
    renderOverlay();
    updateScale();
  }

  /** 現在の表示状態を案件データへ書き戻す（位置＝シート／濃さ＝種類ごと・§24-1） */
  function persistSheetState() {
    if (!state.current || !state.map) return;
    var sh = curSheet();
    if (sh) {
      sh.center = state.map.getCenter();
      sh.zoom = state.map.getZoom();
    }
    state.current.maps[state.kind].underlayOpacity = state.map.getUnderlayOpacity();
    Store.autosave(state.current);
  }

  /* ---------- 住所検索 ---------- */

  /* 🔒 §30-39-2 3（2026-09-19 オーナー指示）: 住所の欄は**本拠と駐車場の2つ**に戻した
     （🔴 §28-14 ①-1「住所の欄は使用の本拠だけ」はこの指示で改めた）。
     🔴 同じ地点の欄は表 ADDR_FIELDS で値が揃っているので、読むのはどれでも同じ
        ＝ここは「読む時の代表の欄」を1か所に決めておくだけ。 */
  var ADDR_EL = { home: 'sgAddrHome', lot: 'sgAddrLot' };

  /** その地点の住所の欄の値（🔒 §30-39-3 3: 住所の記録はこの値） */
  function addrOf(key) {
    var el = ADDR_EL[key] ? $(ADDR_EL[key]) : null;
    return el ? el.value.trim() : '';
  }
  /* 🔒 2026-08-31: 上部バーの項目名を「使用の本拠住所」に変えたので、
     メッセージの呼び名も揃える（§25-1 の「図の上の呼び名は使用の本拠」と同じ語）。
     🔴 ここは**表示用の辞書**で、識別には使っていない（§26-2 注意②） */
  var ADDR_JA = { home: '使用の本拠', lot: '駐車場' };
  var SEARCH_ZOOM = 17;                       // 検索後に寄る倍率（正典 §18-4）

  /**
   * 住所検索（正典 §18-2〜4）。相手は 'home'（使用の本拠）／'lot'（駐車場）。
   *
   * 🔒 §30-39-3（2026-09-19 オーナー指示）: **検索したら、その場所に◎を置く**。
   *   住所を検索 → 地図をその場所へ（ZL17・§18-4）→ その地点のマーカーを置く。
   *   既に置いてあれば置き直す（検索結果へ動く）。
   *   🔴 置き方は［○○マーカー設置］→ 地図クリックと**同じ関数**（placePointAt）
   *      ＝同一住所の解除・文字・印・追従・自動保存の規則が同じ。
   *   🔴 §18-ap／§28-14 ①-1／2026-09-06 の「検索でマーカーは置かない」は
   *      この指示で**改めた**。ジオコーダの結果は番地までなので、置いた◎は
   *      ドラッグで直せることを一言で促す（§30-39-3 2）。
   */
  function doSearch(key) {
    if (!state.current) return;
    // 🔴 分岐は key で（表示文字では分岐しない）
    key = (key === 'lot') ? 'lot' : 'home';
    var el = $(ADDR_EL[key]);
    var q = addrOf(key);
    if (!q) {
      searchMsg(ADDR_JA[key] + 'の住所を入力してください', true);
      if (el) el.focus();
      return;
    }

    searchMsg('検索中…', false, true);   // 途中経過なので地図の上には出さない
    searchBusy(true);

    GSI.geocode(q).then(function (res) {
      if (!res || !res.length) {
        searchMsg(ADDR_JA[key] + 'の住所が見つかりません', true);
        return;
      }
      // 見つかった場所へ寄る（ZL17・§18-4）
      var ll = { lat: res[0].lat, lng: res[0].lng };
      state.map.setView(ll, SEARCH_ZOOM);
      // 🔒 §30-39-3 1: その場所にマーカーを置く（手で置く時とまったく同じ関数）
      placePointAt(key, ll);
      searchMsg(ADDR_JA[key] + 'マーカーを置きました。位置がずれていれば'
        + 'マーカーをドラッグで直してください');
      persistSheetState();      // 中で Store.autosave も呼ぶ
      /* 誘導①の表示（状態の一言）を引き直す。
         navRender() は誘導が閉じていれば何もしない（先頭で早期 return） */
      if (state.nav) navRender();
      /* 🔒 §18-al: 住所検索での誘導の自動起動は**廃止**（2026-08-22 オーナー指示）。
       * 誘導は上部バーの［🧭 所在図ガイダンス］［🧭 配置図ガイダンス］を押した時だけ出す。 */
    }).catch(function (e) {
      searchMsg(e.message || '検索に失敗しました', true);
    }).then(function () {
      searchBusy(false);
    });
  }

  /* 🔒 §30-39-2 3: 止めるのは［検索］**4つ全部**（本拠・駐車場 × ガイダンス①・
     道具メニュー）。どの欄から検索しても、終わるまで全部を止める。 */
  function searchBusy(on) {
    Object.keys(SEARCH_BTNS).forEach(function (key) {
      SEARCH_BTNS[key].forEach(function (id) {
        var b = $(id);
        if (b) b.disabled = on;
      });
    });
  }

  /* ---------- 依頼文からの住所抽出（正典 §9 Step 6） ---------- */

  function previewPaste() {
    var r = AddrParse.extract($('pasteText').value);
    var box = $('pasteFound');
    if (!r.all.length) {
      box.innerHTML = '<span class="none">住所らしい記述が見つかりません</span>';
      return;
    }
    var rows = [
      ['使用の本拠', r.home && r.home.address],
      ['駐車場', r.lot && r.lot.address]
    ];
    if (r.extras.stallNo) rows.push(['区画', r.extras.stallNo + ' 番']);
    if (r.extras.roadWidth) rows.push(['幅員', r.extras.roadWidth + ' m']);
    if (r.extras.height) rows.push(['高さ', r.extras.height + ' m']);
    box.innerHTML = rows.map(function (kv) {
      return '<div class="row"><span class="k">' + kv[0] + '</span><span class="'
        + (kv[1] ? 'v' : 'none') + '">' + (kv[1] || '見つかりません') + '</span></div>';
    }).join('');
    return r;
  }

  function runPaste() {
    var r = AddrParse.extract($('pasteText').value);
    if (!r.home && !r.lot) {
      searchMsg('住所を拾えませんでした。手で入力してください。', true);
      return;
    }
    /* 🔒 §30-39-3 5: 拾えた住所は**本拠・駐車場の両方の欄**へ入れる
       （写す先は表 ADDR_FIELDS 1か所）。地点は作らない＝置くのは［検索］か手置き。 */
    if (r.home) syncAddr('home', r.home.address, null);
    if (r.lot) syncAddr('lot', r.lot.address, null);
    // 区画番号が書いてあれば連番の開始に使う（正典 §4-7）
    if (r.extras.stallNo && state.editor) {
      var n = parseInt(r.extras.stallNo, 10);
      if (!isNaN(n)) {
        state.editor.numberStart = n;
        syncNumberStartUI(n);        // 🔒 §30-18-2: 欄は2か所・値は1つ
        if (state.current) state.current.numberCounter = n;
      }
    }
    // 依頼文から拾った幅員は両方の欄へ入れる（§18-l）
    // 🔒 §30-18-4: 値が入るので幅の決め方も「道幅入力」側にしておく
    if (r.extras.roadWidth) { setArrowMode('manual'); setArrowWidth(r.extras.roadWidth); }
    $('pastePanel').hidden = true;
    searchMsg('依頼文から住所を入れました。内容を確かめて［検索］を押してください。');
    hint('拾った内容は必ずご確認ください（自動判定です）', 4500);
  }

  /**
   * 検索結果の一言。🔒 §30-39-1 2（2026-09-19 オーナー指示）: 上部バーの欄
   * （#searchMsg）を削除したので、出し先は**地図の上の hint() だけ**
   * ＝ここは hint へ流すだけの1本（DOM は触らない）。
   * 🔴 呼び方は従来どおり（s／isErr／quiet）。
   *    quiet ＝「検索中…」のような、すぐ次の文で上書きされる途中経過＝出さない。
   * 🔴 判定は**引数**で渡す（文面での判定は増やさない＝§26-2 注意②）
   */
  function searchMsg(s, isErr, quiet) {
    if (s && !quiet) hint(s, isErr ? 5000 : 3500);
  }

  /* ---------- ピンと距離 ---------- */

  /* 🔒 §30-25-37 1: 画面のピンの◎の半径（px）。文字の縦位置（y）もここから出す
   * ＝印を大きくしても文字との隙間が変わらない。🔴 値の出どころはこの1か所。 */
  var PIN_R = 8;

  function buildPins() {
    var svg = state.map.overlay;

    state.distEls = {
      line: svgEl('path', { class: 'dist-line' }),
      label: svgEl('text', { class: 'dist-label' })
    };
    svg.appendChild(state.distEls.line);
    svg.appendChild(state.distEls.label);

    ['home', 'lot'].forEach(function (key) {
      var g = svgEl('g', { class: 'pin pin-' + key + ' hit' });
      /* ◎（二重丸）の形。🔒 §30-25-37 1: 半径は PIN_R（文字の y もここから出す） */
      var body = svgEl('circle', { class: 'pin-body', r: PIN_R });
      var core = svgEl('circle', { class: 'pin-core', r: 3.4 });
      /* 🔒 §28-14 ①-4: ■（四角に斜線）の形。紙の主役マーク（四角＋45°の斜線ハッチ）と
       * 同じ見た目を画面でも出す。斜線は x+y=k（k=-8,0,8）の3本＝四角の中で閉じる。 */
      var box = svgEl('rect', { class: 'pin-box', x: -8, y: -8, width: 16, height: 16 });
      var hat = svgEl('path', { class: 'pin-hatch',
        d: 'M-8 8L8 -8M-8 0L0 -8M0 8L8 0' });
      g.appendChild(body);
      g.appendChild(core);
      g.appendChild(box);
      g.appendChild(hat);
      var t = svgEl('text', { class: 'pin-label', y: 26 });
      // 🔒 §30-22-1 6: 文言は PIN_LABEL 1か所（同一住所の時は renderOverlay が差し替える）
      t.textContent = pinLabel(key);
      g.appendChild(t);
      /* 🔒 §30-24-2: 同一住所の時は文字が**2つ**（「使用の本拠」と「駐車場」）。
       * 画面のピンは1つなので、2行目をここに用意して同じ場所に並べる
       * （紙では別々の文字なのでドラッグで動かせる）。 */
      var t2 = svgEl('text', { class: 'pin-label', y: 40 });
      t2.textContent = pinLabel('lot');
      t2.style.display = 'none';
      g.appendChild(t2);
      svg.appendChild(g);
      state.pins[key] = g;
      state.pinEls[key] = { body: body, core: core, box: box, hatch: hat,
                            label: t, label2: t2 };
      makePinDraggable(g, key);
    });
  }

  /**
   * 🔒 §30-30-3 1: その地点の主役の印（■／◎／多角形）が、いま開いている所在図の
   * 紙に**既にある**か（role:'mainmark' の rect／polygon＝markRole で見る、または
   * role:'pinlabel' の文字＝◎は文字が dotStyle:'double' で持つので文字の有無で見る）。
   * 🔴 判定は pinKey／markRole（表示文字では分岐しない・§26-2 注意②）。
   * 🔴 所在図の紙だけを見る（§18-ab の onPaper と同じ範囲）。配置図タブでは常に false
   *    ＝ 配置図には紙の印が無いので、画面のピンが唯一の見た目のまま（今のまま）。
   */
  function mainMarkOnPaper(key) {
    if (state.kind !== 'shozaizu') return false;
    var objs = objectsOf('shozaizu');
    for (var i = 0; i < objs.length; i++) {
      var o = objs[i];
      if (!o || o.source !== 'shozaizu') continue;
      if ((o.type === 'rect' || o.type === 'polygon') && o.role === 'mainmark'
          && (o.markRole || 'home') === key) return true;
      if (o.type === 'text' && o.role === 'pinlabel' && pinKeyOf(o) === key) return true;
    }
    return false;
  }

  /**
   * 画面のピンの見た目を、①で選んだ形と色に合わせる（🔒 §28-14 ①-4）。
   * 🔴 紙の印（役割オブジェクト）とは別の物なので、ここでは**表示だけ**を切り替える
   *    （形・色の真実は points[key].mark ＝ markOf）。
   */
  function syncPinLook(key) {
    var e = state.pinEls[key];
    if (!e) return;
    var m = markOf(key);
    var hex = Editor.markHex ? Editor.markHex({ markColor: m.color }) : '';
    var circle = (m.shape === 'circle');
    /* 🔒 §30-22-1 4 (c): 「印なし（文字だけ）」は◎も■も出さない
     * （文字だけが残る＝紙と同じ見え方。文字は掴めるのでピンは動かせる）。
     * 🔒 §30-24-1: 「多角形」も同じ（囲んだ多角形が印なので、丸も四角も出さない。
     *    ピンは多角形の重心＝見えない基準点。文字だけが見える）。 */
    var none = (m.shape === 'none') || (m.shape === 'polygon');
    e.body.style.display = (circle && !none) ? '' : 'none';
    e.core.style.display = (circle && !none) ? '' : 'none';
    e.box.style.display = (circle || none) ? 'none' : '';
    e.hatch.style.display = (circle || none) ? 'none' : '';
    /* 🔒 §30-25-37 1: 画面のピンの見た目にも同じ倍率を掛ける（紙の◎■と揃える）。
     * 🔴 4つの絵はどれも原点（0,0）が中心なので scale(s) だけで済む。
     * 🔴 文字は拡大しない（読みにくくなるだけ）。代わりに**印の縁からの隙間を保つ**
     *    位置へ下げる（PIN_R=8 が◎の半径・16px が四角の一辺＝ buildPins と同じ値）。 */
    var s = m.scale || 1;
    var tr = (Math.abs(s - 1) < 0.005) ? '' : ('scale(' + s + ')');
    e.body.setAttribute('transform', tr);
    e.core.setAttribute('transform', tr);
    e.box.setAttribute('transform', tr);
    e.hatch.setAttribute('transform', tr);
    if (e.label) e.label.setAttribute('y', (PIN_R * s + 18).toFixed(1));
    if (e.label2) e.label2.setAttribute('y', (PIN_R * s + 32).toFixed(1));
    /* 🔒 §30-24-2: 同一住所の時は文字が2つ（「使用の本拠」と「駐車場」）。
     * 画面のピンは1つなので上下に並べて出す（紙でも別々の文字）。 */
    var isSame = !!(state.current && state.current.points.same);
    if (e.label) e.label.textContent = pinLabel(key);
    if (e.label2) e.label2.style.display = isSame ? '' : 'none';
    /* 🔒 §30-30-3 1: **■が紙と二重に見える不具合の直し**。
     * 原因: 紙の■（`role:'mainmark'` の四角＋斜線ハッチ）と画面のピンの■
     * （このすぐ下で `box.style.stroke` に色を入れる所）が同じ場所に重なって
     * 描かれていた。`.pin.is-quiet`（renderOverlay の onPaper・pinlabel の有無だけで
     * 判定）は body/box/hatch を fill・stroke ともに transparent にする CSS を
     * 持っているが、**ここで色を inline style に入れると CSS のクラス指定より
     * inline が必ず勝つ**ので、is-quiet が付いていても色が残って二重に見えていた
     * （◎ は紙の◎と同じ位置・同じ太さの輪なので重なっても目立たなかっただけで、
     * 実質は同じ穴があった）。
     * 直し: 紙にその地点の主役の印が**既にある間**（mainMarkOnPaper）は、
     * 色を入れずに透明のまま止める＝旧: 「◎の時だけ四角側を隠す」だった判定
     * （circle||none）を「紙にもう印がある（■・多角形も含む）」の1つの判定に広げた。
     * 🔴 `display:none` にはしない（掴むための透明な当たりが消え、§30-25-24 9
     *    「画面のピン本体を掴んでピンが動く」が壊れるため）。要素は残したまま
     *    fill/stroke を transparent・pointer-events を all にする
     *    （＝ `.pin.is-quiet` と同じ考え方を、CSS の勝ち負けに頼らずここで担保する）。 */
    var onPaper = mainMarkOnPaper(key);
    var parts = [e.body, e.core, e.box, e.hatch];
    if (onPaper) {
      parts.forEach(function (el) {
        el.style.fill = 'transparent';
        el.style.stroke = 'transparent';
        el.style.pointerEvents = 'all';
      });
      return;
    }
    parts.forEach(function (el) {
      el.style.fill = '';
      el.style.stroke = '';
      el.style.pointerEvents = '';
    });
    if (!hex) return;
    e.body.style.stroke = hex;
    e.core.style.fill = hex;
    e.box.style.stroke = hex;
    e.hatch.style.stroke = hex;
  }

  function makePinDraggable(g, key) {
    var dragging = false;
    g.addEventListener('pointerdown', function (e) {
      if (!state.current || !state.current.points[key]) return;
      /* 🔒 §26-4-e: なぞり出し中はピンを掴まない。
       * 🔴 筆が太いと駐車場・使用の本拠のピンの上を通るだけで地点が動いてしまう
       *    （案件の唯一の真実なので、動くと結線・距離・主役マークまで一斉にずれる）。
       *    ここで止めずに素通しすると、そのまま筆のストロークになる。 */
      if (state.editor && state.editor.tool === 'reveal') return;
      /* 🔒 §30-32-1: 消しゴムの時は**掴まずに消す**（所在図でも配置図でも、
       * 画面のピン本体をクリックすればその地点が消える）。
       * 🔴 消し方は removePoint 1か所（紙の印をクリックした時と同じ結果）。 */
      if (state.editor && state.editor.tool === 'eraser') {
        e.stopPropagation();
        e.preventDefault();
        erasePinAt(key);
        return;
      }
      e.stopPropagation();
      e.preventDefault();
      dragging = true;
      state.map.inputLocked = true;
      g.classList.add('dragging');
      try { g.setPointerCapture(e.pointerId); } catch (err) {}
    });
    g.addEventListener('pointermove', function (e) {
      if (!dragging) return;
      e.stopPropagation();
      var rect = state.map.el.getBoundingClientRect();
      var ll = state.map.unproject(e.clientX - rect.left, e.clientY - rect.top);
      var p = state.current.points[key];
      p.lat = ll.lat; p.lng = ll.lng;
      p.moved = true;          // 住所検索の位置から手で動かした印
      /* 🔒 §30-22-1 6: 同一住所の間は2地点は**同じ場所**（画面のピンも1つ）。
       * 掴んで動かした時は、もう一方も一緒に動かす（食い違わせない）。 */
      if (state.current.points.same) {
        var other = state.current.points[key === 'home' ? 'lot' : 'home'];
        if (other) { other.lat = ll.lat; other.lng = ll.lng; other.moved = true; }
      }
      renderOverlay();
      refreshPoints();
    });
    function end(e) {
      if (!dragging) return;
      dragging = false;
      state.map.inputLocked = false;
      g.classList.remove('dragging');
      try { g.releasePointerCapture(e.pointerId); } catch (err) {}
      Store.autosave(state.current);
    }
    g.addEventListener('pointerup', end);
    g.addEventListener('pointercancel', end);
  }

  /** 🔒 §30-22-1 1: いま枠を隠す段か（所在図①＝マーカーを置く段だけ） */
  function sgFrameHidden() {
    return !!(state.nav && navOnSide() && state.nav.step === 1);
  }

  /** 書き出し範囲を地図の上に描く（正典 §4-10）。外側は薄く覆う */
  function renderExportFrame() {
    var svg = state.map.overlay;
    var g = state.frameEls;
    if (!g) {
      var NS = 'http://www.w3.org/2000/svg';
      g = state.frameEls = {
        mask: document.createElementNS(NS, 'path'),
        /* 🔒 §30-25-30 3: 色の破線の**下に敷く白い縁**（同じ矩形を2本描く）。
         * 色の線より先に入れる＝下になる。値は style.css の --frame-* 1か所。 */
        halo: document.createElementNS(NS, 'rect'),
        rect: document.createElementNS(NS, 'rect')
      };
      g.mask.setAttribute('class', 'frame-mask');
      g.halo.setAttribute('class', 'frame-halo');
      g.rect.setAttribute('class', 'frame-rect');
      svg.appendChild(g.mask);
      svg.appendChild(g.halo);
      svg.appendChild(g.rect);
    }
    /* 🔒 §24-2-3: 枠は**案件を開いている間ずっと**出す。
     * 🔴 直す前は「書き出しパネルを開いている間」か「枠を決定した紙」だけ出していた。
     *    そのため［枠を決め直す］を押した瞬間に枠が画面から消え、
     *    その状態で A4縦/A4横 を押しても**見た目が何も変わらない**
     *    ＝ オーナー報告「枠を決定・決め直すの動作が異常」「縦横を切り替えても
     *    枠が切り替わらない」の正体（実機で再現）。
     *    紙の中を仕上げる道具である以上、紙の縁は常に見えていないといけない。
     * 外側の覆いは、決めていない間（＝まだ場所を探している間）は薄くして
     * 作図の邪魔をしない（is-soft）。 */
    var sh = curSheet();
    var fixed = !!(sh && sh.frameFixed && sh.frame);
    /* 🔒 §30-22-1 1（2026-09-13 オーナー指示）: **所在図①（マーカーを置く段）では
     * 枠の破線を出さない**（枠を決めるのは②なので、①で枠を見せても意味が無く、
     * 「この中に入れないといけないのか」と誤解させる）。②に入れば出る／①へ戻れば消える。
     * 🔴 覆い（frame-mask）も一緒に消す＝破線だけ消すと「薄い四角」が残って
     *    枠に見えてしまう（消す目的を果たさない）。 */
    var show = !!(state.current && sh) && !sgFrameHidden();
    /* 🔒 §30-29-1 3: 旧 state.showFrame（［書き出し］の窓を開いている間）は
     * 廃止した。枠は常に破線で見えているので、強調（外側の濃い覆いと帯）は
     * 【枠を決定した紙】だけ。 */
    var strong = fixed;
    /* 🔒 §30-22-1 2: 写真の下敷きの時だけ枠の破線を**赤**にする（決定後の枠も同じ）。
     * 色そのものは CSS の変数 1か所（--frame-ink / .frame-rect.is-photo）。 */
    g.rect.classList.toggle('is-photo', underlayIsPhoto());
    g.mask.style.display = show ? '' : 'none';
    g.rect.style.display = show ? '' : 'none';
    g.halo.style.display = show ? '' : 'none';   // 🔒 §30-25-30 3
    g.mask.classList.toggle('is-soft', !strong);
    /* 🔒 §30-29-1 3: 帯（説明）は【枠を決定した紙】の間だけ＝文も1つ
     * （旧・書き出しの窓を開いている間に出していた「地図を動かすと枠も動きます」は、
     *  その窓ごと廃止したので出る場面が無い）。 */
    $('frameHint').hidden = !(show && strong);
    $('frameHint').textContent =
      'この枠の中が書き出されます（枠は固定中。地図だけ動かせます）';
    if (!show) { g.lastRectPx = null; return; }   // §24-6: 他枠の札の位置計算に使う値も消しておく

    /* 決めていない枠は**いまの画面**から直接引く（保存値を描くと更新し忘れでずれる）。
       決めた枠は保存値を画面へ投影して引く（地図を動かしても紙の位置は動かない）。 */
    var s = state.map.size();
    var r = fixed ? fixedFrameRectPx(sh.frame) : frameRectPx();
    var x = r.x, y = r.y, w = r.w, h = r.h;
    g.rect.setAttribute('x', x.toFixed(1));
    g.rect.setAttribute('y', y.toFixed(1));
    g.rect.setAttribute('width', w.toFixed(1));
    g.rect.setAttribute('height', h.toFixed(1));
    // 🔒 §30-25-30 3: 白い縁は色の線と**まったく同じ矩形**（ずれない）
    g.halo.setAttribute('x', x.toFixed(1));
    g.halo.setAttribute('y', y.toFixed(1));
    g.halo.setAttribute('width', w.toFixed(1));
    g.halo.setAttribute('height', h.toFixed(1));
    // 画面全体から枠を抜いた形（外側を薄く覆う）
    g.mask.setAttribute('d',
      'M0 0H' + s.w + 'V' + s.h + 'H0Z'
      + 'M' + x.toFixed(1) + ' ' + y.toFixed(1)
      + 'h' + w.toFixed(1) + 'v' + h.toFixed(1) + 'h' + (-w).toFixed(1) + 'Z');
    g.mask.setAttribute('fill-rule', 'evenodd');
    // 🔒 §24-6: 編集中の枠の番号札（renderSiblingFrames）はこの矩形を使って置く
    g.lastRectPx = { x: x, y: y, w: w, h: h };
  }

  /**
   * 🔒 §24-6（オーナー指示 2026-09-06）: 同じ種類の他のシートの枠を、地図の上に全部見せる。
   * 観光地図の「市街地拡大地図はここ」の要領＝いま何枚目を編集しているかが枠だけで分かる。
   * - 他の枠＝薄い青の破線＋左上に番号の札（白地・青枠）。編集中の枠にも番号の札
   *   （塗りつぶしの青）を足す＝線は renderExportFrame() のまま変えない
   * - シートが1枚だけ／別の種類／`frame` 未設定のシート（一度も生成も決定もしていない）は出さない
   * - 画面専用。紙（Exporter.renderSheet）には出さない＝ここでしか描かない
   * - 🙋 §24-6 規則6: 札だけ pointer-events:auto でクリック可＝そのシートに切り替える。
   *   枠そのもの（is-sibling）は pointer-events:none のまま＝規則5「見えるだけ」を守る
   */
  function renderSiblingFrames() {
    var svg = state.map.overlay;
    var g = state.frameEls;
    if (!g) return;                              // renderExportFrame() が直前に必ず作る
    if (!g.siblings) g.siblings = [];             // [{rect, badge:{g,rect,text}}]
    if (!g.activeBadge) {
      var bg = svgEl('g', { class: 'frame-badge is-active' });
      var br = svgEl('rect', { rx: 4, ry: 4 });
      var bt = svgEl('text', { 'text-anchor': 'middle' });
      bg.appendChild(br);
      bg.appendChild(bt);
      svg.appendChild(bg);
      g.activeBadge = { g: bg, rect: br, text: bt };
    }

    var sh = curSheet();
    var show = !!(state.current && state.map && sh && g.lastRectPx);
    var list = show ? sheetsOf(state.kind) : [];
    var curIdx = activeIdx(state.kind);
    var many = show && list.length > 1;   // §24-6 規則1: 1枚しか無ければ何も出ない

    // 自分以外の枚数ぶんだけ枠・札の要素を用意する（増減したら作り直す）
    var wanted = many ? list.length - 1 : 0;
    while (g.siblings.length < wanted) {
      // 🔒 §30-25-30 3: 白い縁 → 色の破線 の順で入れる（白が下）
      var sha = svgEl('rect', { class: 'frame-halo' });
      var sr = svgEl('rect', { class: 'frame-rect is-sibling' });
      var sbg = svgEl('g', { class: 'frame-badge' });
      var sbr = svgEl('rect', { rx: 4, ry: 4 });
      var sbt = svgEl('text', { 'text-anchor': 'middle' });
      sbg.appendChild(sbr);
      sbg.appendChild(sbt);
      svg.appendChild(sha);
      svg.appendChild(sr);
      svg.appendChild(sbg);
      g.siblings.push({ halo: sha, rect: sr,
                        badge: { g: sbg, rect: sbr, text: sbt } });
    }
    while (g.siblings.length > wanted) {
      var extra = g.siblings.pop();
      if (extra.halo) svg.removeChild(extra.halo);
      svg.removeChild(extra.rect);
      svg.removeChild(extra.badge.g);
    }

    if (!many) { g.activeBadge.g.style.display = 'none'; return; }

    g.activeBadge.g.style.display = '';
    placeFrameBadge(g.activeBadge, g.lastRectPx, curIdx + 1);

    var slot = 0;
    list.forEach(function (sh2, i) {
      if (i === curIdx) return;
      var pair = g.siblings[slot++];
      // §24-6 規則3: frame が無いシート（未生成・未決定）は出さない
      var ok = sh2.frame && sh2.frame.center && sh2.frame.w_m;
      if (!ok) {
        pair.rect.style.display = 'none';
        pair.halo.style.display = 'none';       // 🔒 §30-25-30 3
        pair.badge.g.style.display = 'none';
        pair.badge.g.onclick = null;
        return;
      }
      var r2 = fixedFrameRectPx(sh2.frame);
      pair.rect.style.display = '';
      pair.rect.setAttribute('x', r2.x.toFixed(1));
      pair.rect.setAttribute('y', r2.y.toFixed(1));
      pair.rect.setAttribute('width', r2.w.toFixed(1));
      pair.rect.setAttribute('height', r2.h.toFixed(1));
      // 🔒 §30-25-30 3: 白い縁は同じ矩形
      pair.halo.style.display = '';
      pair.halo.setAttribute('x', r2.x.toFixed(1));
      pair.halo.setAttribute('y', r2.y.toFixed(1));
      pair.halo.setAttribute('width', r2.w.toFixed(1));
      pair.halo.setAttribute('height', r2.h.toFixed(1));
      pair.badge.g.style.display = '';
      placeFrameBadge(pair.badge, r2, i + 1);
      // 🙋 §24-6 規則6: 札のクリックでそのシートへ切り替える
      pair.badge.g.onclick = (function (idx) {
        return function () { selectSheet(idx); };
      })(i);
    });
  }

  /** 番号の札（rect+text）を枠の左上の内側に置く（renderSiblingFrames 専用） */
  function placeFrameBadge(b, r, n) {
    var label = String(n);
    var w = 12 + 9 * label.length, h = 18;
    var x = r.x + 4, y = r.y + 4;
    b.rect.setAttribute('x', x.toFixed(1));
    b.rect.setAttribute('y', y.toFixed(1));
    b.rect.setAttribute('width', w);
    b.rect.setAttribute('height', h);
    b.text.textContent = label;
    b.text.setAttribute('x', (x + w / 2).toFixed(1));
    b.text.setAttribute('y', (y + h / 2 + 4.2).toFixed(1));
  }

  function renderOverlay() {
    if (!state.current || !state.map) return;
    var c = state.current;
    renderExportFrame();
    renderSiblingFrames();
    renderRecogLines();
    /* 🔒 §30-32-6 3: ［マーカーを表示］は「消した紙にいる時だけ」＝紙・図が変わる
     * たびに引き直す。ここ（画面を引き直す1か所）に置けば取りこぼしが無い。 */
    sgSyncPinShow();
    /* 🔒 §28-3（Fable 追加提案）: ②の「2つとも枠の中か」は**常時判定**。
     * 地図を動かすたびに枠も判定も動くので、枠を引くのと同じ場所で引き直す。 */
    if (navOnSide()) sgRenderStatus();

    /* 🔒 §18-ab: 所在図に**役割オブジェクト（◎・自宅／駐車場・結線・距離）が
     * あるなら、画面だけのピン表示は引っ込める**。
     * 🔴 ③で「自宅・駐車場・距離が二重」に見えていたのは、
     *    画面用のピン（.pin-label / .dist-line / .dist-label）と
     *    生成した役割オブジェクトが**同じ物を2回描いていた**ため
     *    （紙＝④は役割オブジェクトしか描かないので1組で正常だった＝実測で確認）。
     * ピンは**掴むための当たり判定として残す**（◎の位置＝ピンの位置なので、
     * そのままドラッグでき、§18-x-5 の追従で◎が付いてくる）。
     * 生成前（①②）は役割物が無いので従来どおりピンが見える。配置図タブも従来どおり。 */
    /* 🔒 §30-24-1: 引っ込めるのは「同じ物が紙にもある時」だけ。
     * 🔴 主役の多角形（role:'mainmark'）は利用者が描いた印で、文字はまだ紙に無い。
     *    これも「役割あり」と数えていたため、多角形を描いた瞬間に画面から
     *    「使用の本拠」の文字が消えていた（オーナー報告の一部）。
     * 🔒 §30-25-28 2（2026-09-14 オーナー指示）: 判定は**その紙に主役の文字が
     *    あるか**の1か所（pinKey ごと）。マーカーを置いた瞬間に紙の文字ができる
     *    ので、画面のピンの文字は置いた瞬間から出さない＝二重に見えない。
     *    紙の文字を消しゴムで消せば、画面のピンの文字がまた出る。 */
    var onPaper = { home: false, lot: false };
    if (state.kind === 'shozaizu') {
      objectsOf('shozaizu').forEach(function (o) {
        if (o && o.source === 'shozaizu' && o.type === 'text'
            && o.role === 'pinlabel') onPaper[pinKeyOf(o)] = true;
      });
    }
    /* 結線と直線距離の画面表示は、**生成した結線（role:'distance'）がある間**は出さない
     * （紙の物と二重になる）。文字とは別の判定＝主役の文字ができても距離は消えない。 */
    var hasDistObj = state.kind === 'shozaizu' && objectsOf('shozaizu').some(
      function (o) { return o && o.source === 'shozaizu' && o.role === 'distance'; });

    /* 🔒 §30-22-1 6: 同一住所の時は**画面のピンも1つ**（駐車場の分は出さない）。
     * 2つ重ねると掴めない・文字が二重になるだけで良いことが何も無い。 */
    var oneSpot = !!c.points.same;
    /* 🔒 §30-32-6 3: その紙で消したピンは出さない（地点は残っている＝所在図は無事）。
     * 🔴 判定の出どころは pinHiddenOn 1か所（ボタンの出し入れも同じ物を読む）。 */
    var shPin = curSheet();
    ['home', 'lot'].forEach(function (key) {
      var g = state.pins[key], p = c.points[key];
      if (!g) return;
      if (!p || (oneSpot && key === 'lot') || pinHiddenOn(shPin, key)) {
        g.style.display = 'none'; return;
      }
      g.style.display = '';
      /* 🔒 §30-25-28 2: 同一住所の時は画面のピンが1つで文字が2つ（本拠・駐車場）。
       * どちらの文字も紙にある時だけ引っ込める。 */
      g.classList.toggle('is-quiet',
        oneSpot ? (onPaper.home && onPaper.lot) : onPaper[key]);
      syncPinLook(key);          // 🔒 §28-14 ①-4: ①で選んだ形と色にする
      var s = state.map.project(p.lat, p.lng);
      g.setAttribute('transform', 'translate(' + s.x.toFixed(1) + ','
        + s.y.toFixed(1) + ')');
    });

    /* 2点間の破線と距離は所在図でのみ出す（正典 §5）。役割物があるならそちらに任せる。
     * 🔒 §30-22-1 6: 同一住所の時は**描かない**（長さ0の線と「約0m」は嘘の情報）。 */
    var show = !hasDistObj && !oneSpot && state.kind === 'shozaizu'
             && c.points.home && c.points.lot;
    var d = state.distEls;
    if (!show) {
      d.line.style.display = 'none';
      d.label.style.display = 'none';
      return;
    }
    d.line.style.display = '';
    d.label.style.display = '';
    var a = state.map.project(c.points.home.lat, c.points.home.lng);
    var b = state.map.project(c.points.lot.lat, c.points.lot.lng);
    var meters = GSI.distanceMeters(c.points.home, c.points.lot);
    var over = meters > 2000;
    d.line.setAttribute('d', 'M' + a.x.toFixed(1) + ' ' + a.y.toFixed(1)
      + 'L' + b.x.toFixed(1) + ' ' + b.y.toFixed(1));
    d.line.setAttribute('class', 'dist-line' + (over ? ' over' : ''));
    d.label.setAttribute('x', ((a.x + b.x) / 2).toFixed(1));
    d.label.setAttribute('y', ((a.y + b.y) / 2 - 8).toFixed(1));
    d.label.setAttribute('class', 'dist-label' + (over ? ' over' : ''));
    d.label.textContent = fmtDist(meters);
  }

  function fmtDist(m) {
    return m >= 1000 ? '約' + (m / 1000).toFixed(2) + 'km' : '約' + Math.round(m) + 'm';
  }

  /**
   * 所在図の「役割オブジェクト」をピンに追従させる（🔒 §18-x-5 / §25-4）。
   * 対象: 主役マークの四角（◎）・「使用の本拠／駐車場」の文字・結線の破線・距離の文字。
   * 🔴 これらは生成した瞬間の座標に**焼き込まれて**いたので、
   *    ③のあとにマーカーを置き直しても図が古い場所を指したままだった。
   *    §5「ピンを動かすと線・距離は自動追従」を役割オブジェクト全部に広げる。
   * 🔒 2026-08-30（オーナー実機報告）で**ピンが唯一の真実**と決めた:
   *    四角を掴んだら editor.movePin がピンを動かし、ここで一式が付いてくる。
   *    片方の四角を消しても、残った側の追従はこの関数が独立に面倒を見る。
   * 手でずらした文字は「基準点からのずれ」を保ったまま一緒に動く。
   * 返り値: 動かした数（0 なら何もしていない）
   */
  function syncRoleObjects() {
    var c = state.current;
    if (!c) return 0;
    /* 🔴 §24-1: ピンは案件レベルの唯一の真実なので、追従は**所在図の全シート**に効かせる
     * （2枚目・3枚目の所在図に生成した主役マーク・結線も一緒に動く）。
     * 開いていないシートも直すが、描き直すのは表示中のシートだけでよい。 */
    var objs = [];
    sheetsOf('shozaizu').forEach(function (s) {
      objs = objs.concat(s.objects || []);
    });
    var home = c.points.home, lot = c.points.lot;
    var moved = 0;
    /* 🔒 §30-22-1 6 / §30-22-6 2: 同一住所になったら、**前に生成してある結線と
     * 直線距離を取り除く**（作り直さなくてもその場で正しくなる＝追従の作法）。
     * 🔴 配列は差し替えず splice だけ（§23-7-1 / §26-2 注意①）。
     * 🔴 消すのは自動生成物（source:'shozaizu'）の role:'distance' だけ。 */
    if (c.points.same) {
      sheetsOf('shozaizu').forEach(function (s) {
        var arr = s.objects || [];
        for (var i = arr.length - 1; i >= 0; i--) {
          if (arr[i] && arr[i].source === 'shozaizu' && arr[i].role === 'distance') {
            arr.splice(i, 1);
            moved++;
          }
        }
      });
      if (moved) objs = objs.filter(function (o) { return !(o && o.role === 'distance'); });
    }
    var same = function (a, b) {
      return a && b && a.lat === b.lat && a.lng === b.lng;
    };

    /* 🔒 §30-24-1: 主役の**多角形**。ピンの位置は「最初に描いた多角形」の重心なので、
     * その重心がピンに乗るように動かし、同じ地点の2つ目以降（建物と土地など）は
     * **同じ量だけ**一緒に動かす（互いの位置関係を崩さない）。
     * 🔴 並び（＝どれが最初か）の出どころは Editor.mainPolysOf 1か所。
     * 🔴 1つだけ掴んで動かした時は editor 側で動き終わっていて、
     *    ここでは「重心＝ピン」がもう成り立つので何もしない（行ったり来たりしない）。 */
    sheetsOf('shozaizu').forEach(function (s) {
      ['home', 'lot'].forEach(function (key) {
        var list = Editor.mainPolysOf(s.objects || [], key);
        if (!list.length) return;
        var pp = c.points[key];
        var ctr = Editor.polyCentroid(list[0].points);
        if (!pp || !ctr || same(ctr, pp)) return;
        var dLa = pp.lat - ctr.lat, dLn = pp.lng - ctr.lng;
        list.forEach(function (g) {
          (g.points || []).forEach(function (q) { q.lat += dLa; q.lng += dLn; });
        });
        moved++;
      });
    });

    objs.forEach(function (o) {
      if (o.source !== 'shozaizu') return;

      /* ⓪主役マークの四角（🔒 §25-4）。◎の代わりの印なので◎と同じ扱いで追従させる。
       * 🔒 §30-35-3 4: 中心＝**ピン＋ずれ**（辺つまみで掴んだ辺だけ伸ばした分）。
       *    ずれの出どころは案件の points[key].mark.dx_m/dy_m（markOf 1か所）で、
       *    m ⇄ 緯度経度の換算は Editor.offsetLatLng 1か所。
       * 🔴 同一住所の時は印が1つ（本拠側の値）＝ずれも本拠側を読む（§30-24-2）。 */
      if (o.role === 'mainmark' && o.center) {
        var mkKey = (o.markRole === 'lot') ? 'lot' : 'home';
        var mp = (mkKey === 'lot') ? lot : home;
        if (!mp) return;
        var mOff = markOf(c.points.same ? 'home' : mkKey);
        var want = Editor.offsetLatLng
                 ? Editor.offsetLatLng(mp, mOff.dx_m, mOff.dy_m) : mp;
        if (same(o.center, want)) return;
        o.center = { lat: want.lat, lng: want.lng };
        moved++;
        return;
      }

      /* ⓪-2 主役の**多角形**は、この上の「紙1枚ずつ・地点ごと」のまとまりで
       * 動かし終わっている（🔒 §30-24-1）。ここでは触らない。 */
      if (o.role === 'mainmark' && o.points) return;

      // ①◎（または四角）と名前（anchor＝地点そのもの・at＝文字。ずれは保つ）
      if (o.role === 'pinlabel' && o.type === 'text' && o.anchor) {
        /* 🔒 §26-2 注意②: どちらのピンかは **pinKey**（新しく生成した物）で見る。
         * 表示文字での判定は旧データ用の保険（'自宅' は §25-1 改名前の文言）。
         * 文字は利用者が書き換えられるので、pinKey がある物は文字を見ない。 */
        var p = o.pinKey ? c.points[o.pinKey]
              : ((o.text === '自宅' || o.text === '使用の本拠') ? home : lot);
        if (!p || same(o.anchor, p)) return;
        var dLat = o.at.lat - o.anchor.lat, dLng = o.at.lng - o.anchor.lng;
        o.anchor = { lat: p.lat, lng: p.lng };
        o.at = { lat: p.lat + dLat, lng: p.lng + dLng };
        moved++;
        return;
      }

      if (!home || !lot) return;

      // ②結線の破線
      if (o.role === 'distance' && o.type === 'line') {
        if (same(o.a, home) && same(o.b, lot)) return;
        o.a = { lat: home.lat, lng: home.lng };
        o.b = { lat: lot.lat, lng: lot.lng };
        var over = GSI.distanceMeters(home, lot) > 2000;
        o.style = o.style || {};
        o.style.color = over ? '#c0392b' : '#111';
        moved++;
        return;
      }

      // ③距離の文字（mid＝中点の控え。手でずらした分は保つ）
      if (o.role === 'distance' && o.type === 'text') {
        var mid = { lat: (home.lat + lot.lat) / 2, lng: (home.lng + lot.lng) / 2 };
        var base = o.mid || mid;
        if (same(base, mid) && o.mid) return;
        var oLat = o.at.lat - base.lat, oLng = o.at.lng - base.lng;
        o.at = { lat: mid.lat + oLat, lng: mid.lng + oLng };
        o.mid = { lat: mid.lat, lng: mid.lng };
        var m = GSI.distanceMeters(home, lot);
        var over2 = m > 2000;
        o.text = fmtDist(m) + (over2 ? '（2km超）' : '');
        o.style = o.style || {};
        o.style.color = over2 ? '#c0392b' : '#111';
        moved++;
      }
    });

    if (moved) {
      // 表示中が所在図なら描き直す（配置図タブなら次に開いた時に反映される）
      if (state.kind === 'shozaizu' && state.editor) state.editor.render();
      Store.autosave(c);
    }
    return moved;
  }

  function refreshPoints() {
    var c = state.current;
    if (!c) return;
    syncRoleObjects();               // 🔒 §18-x-5: ◎・結線・距離をピンに追従させる
    $('ptHome').textContent = ptText(c.points.home);
    $('ptLot').textContent = ptText(c.points.lot);

    var el = $('distInfo');
    /* 🔒 §30-22-1 6: 同一住所の時に「直線距離 約0m」は嘘なので出さない */
    if (c.points.same) {
      el.textContent = '使用の本拠と駐車場は同一住所です（直線距離は出ません）';
      el.className = 'dist-info';
    } else if (c.points.home && c.points.lot) {
      var m = GSI.distanceMeters(c.points.home, c.points.lot);
      var over = m > 2000;
      el.textContent = '直線距離 ' + fmtDist(m)
        + (over ? '（⚠ 2kmを超えています）' : '（2km以内）');
      el.className = 'dist-info' + (over ? ' over' : '');
    } else {
      el.textContent = '';
      el.className = 'dist-info';
    }
    renderOverlay();
  }

  function fmtLL(p) {
    return p.lat.toFixed(5) + ', ' + p.lng.toFixed(5);
  }

  function ptText(p) {
    if (!p) return '未設定';
    return (p.title || fmtLL(p)) + (p.moved ? '（手動調整）' : '');
  }

  /* 別タブで通常の Google マップを開くだけのリンク（正典 §17-4）。
   * API も SDK も使っていない＝アプリは Google に何も要求しない。
   * 高精細な航空写真を「見る」作業はここから先＝アプリの外で行う。 */
  function updateGoogleLink() {
    if (!state.map) return;
    var ctr = state.map.getCenter();
    var z = Math.round(state.map.getZoom());
    var href = 'https://www.google.com/maps/@' + ctr.lat.toFixed(6)
      + ',' + ctr.lng.toFixed(6) + ',' + z + 'z';
    /* 🔒 §28-14 ④: ガイダンス④の「別タブで見る」ボタンは外した（Google も下敷きの
     * 〇として後ろに写す）。別タブのリンクは右パネルのこれ1つだけ（§17-4）。 */
    $('linkGoogle').href = href;
  }

  /* ================= 🔒 §30-33 新しい版への更新 =================
   * オーナー指示 2026-09-15:「必ず案件一覧に戻ってもらおう。案件一覧に戻ると
   *   『最新版になりました』と出ればいい」。
   *
   * 仕組み（正典 §30-33-1）:
   *   1. 配信（pages.yml）がコミット番号を version.json と window.SHAKO_VER に書く
   *   2. アプリは**数分ごと**と**案件一覧に戻った時**に version.json を
   *      cache:'no-store' で取りに行き、動いている版と比べる
   *   3. 案件一覧に戻った時に新しければ index.html?v=<番号> で開き直す
   *      （キャッシュを飛び越える）。開き直した後は上に「最新版になりました」
   *   4. 案件を開いている間に見つけたら、上部バーの更新案内（#verNote）だけ出す
   *      （中身は常に自動保存なので、一覧に戻れば失う物はない）
   *
   * 🔴 通信できない・version.json が無い・手元（版なし）では**何もしない**。
   *    ここが原因でアプリが止まることは無い（例外は外へ出さない）。 */

  var VER_URL = 'version.json';
  var VER_CHECK_MS = 5 * 60 * 1000;   // 版を見に行く間隔（5分）
  var VER_DONE_MS = 5000;             // 「最新版になりました」を出しておく長さ

  /** いま動いている版。空文字＝版なし（手元・配信で置き換えられていない）。
   * 🔴 '__SHAKO_VER__' は**配信で置換されていない印**（表示文字列ではない）。 */
  function verRunning() {
    var v = window.SHAKO_VER;
    if (typeof v !== 'string' || !v || v.indexOf('__') === 0) return '';
    return v;
  }

  /** 配信側の最新の版を取りに行く。取れなければ '' に解決する（失敗しても止めない） */
  function verFetchLatest() {
    return new Promise(function (resolve) {
      try {
        fetch(VER_URL, { cache: 'no-store' }).then(function (r) {
          if (!r || !r.ok) { resolve(''); return; }
          r.json().then(function (j) {
            resolve((j && typeof j.ver === 'string') ? j.ver : '');
          }, function () { resolve(''); });
        }, function () { resolve(''); });
      } catch (e) { resolve(''); }
    });
  }

  /** 新しい版がある？（版なし・まだ分からない・同じ版 なら false） */
  function verIsNewer() {
    var run = verRunning();
    return !!(run && state.verLatest && state.verLatest !== run);
  }

  /** 版を見に行って控える。戻り値＝新しい版があるか */
  function verCheck() {
    if (!verRunning()) return Promise.resolve(false);   // 版なし＝何もしない
    return verFetchLatest().then(function (v) {
      if (v) state.verLatest = v;
      verSyncNote();
      return verIsNewer();
    });
  }

  /** 上部バーの更新案内の出し入れ（案件を開いている時だけ出す）。
   * 🔴 窓ではないので closeAllOverlays / CASE_PANELS には入れない
   *    （案件を切り替えても、新しい版がある事実は変わらない）。 */
  function verSyncNote() {
    $('verNote').hidden = !(state.current && verIsNewer());
  }

  /** 最新の版で開き直す（?v= でキャッシュを飛び越える） */
  function verGoLatest() {
    location.href = 'index.html?v=' + encodeURIComponent(state.verLatest);
  }

  /** 数分ごとの見回り。一覧を見ている時は失う物がないのでその場で開き直す */
  function verTick() {
    verCheck().then(function (newer) {
      if (!newer) return;
      if (state.current) verSyncNote();
      else verGoLatest();
    });
  }

  /** 案件一覧へ戻った後（保存が終わってから）。新しければ開き直す（§30-33-1 3） */
  function verAfterList() {
    if (verIsNewer()) { verGoLatest(); return; }
    verCheck().then(function (newer) { if (newer) verGoLatest(); });
  }

  /** 起動時。開き直した直後の一言・URL の後始末・見回りの開始 */
  function verBoot() {
    var q = new URLSearchParams(location.search).get('v') || '';
    /* 利用者に見せる URL は .../shako-map/ のまま（?v= は仕組みの都合） */
    if (q) {
      history.replaceState(null, '', location.pathname.replace(/index\.html$/, ''));
    }
    /* ?v= で開き直して、いま動いているのが**その版**になった＝入れ替わった */
    if (q && q === verRunning()) {
      $('verDone').hidden = false;
      setTimeout(function () { $('verDone').hidden = true; }, VER_DONE_MS);
    }
    /* 開いた直後に古い HTML を掴んでいたら開き直す。
     * 🔴 q === state.verLatest の時は開き直さない＝いま開き直したばかりで
     *    配信側がまだ追いついていない時に、無限に開き直さないための守り。 */
    verCheck().then(function (newer) {
      if (newer && q !== state.verLatest) verGoLatest();
    });
    setInterval(verTick, VER_CHECK_MS);
  }

  /* ---------- 補助 ---------- */

  var hintTimer = null;
  /**
   * 地図の下に一言出す。
   * @param ms 出しておく長さ(ms)。🔒 §30-16: **0 なら消さない**
   *   （拾う状態のように「終わるまで出しておきたい」案内。hintHide で消す）
   */
  function hint(text, ms) {
    var el = $('mapHint');
    el.textContent = text;
    el.classList.add('show');
    if (hintTimer) { clearTimeout(hintTimer); hintTimer = null; }
    if (ms === 0) return;
    hintTimer = setTimeout(function () { el.classList.remove('show'); },
                           ms || 3000);
  }
  /** 出しっぱなしの一言を消す（🔒 §30-16: 拾う状態を終えた時） */
  function hintHide() {
    if (hintTimer) { clearTimeout(hintTimer); hintTimer = null; }
    $('mapHint').classList.remove('show');
  }

  /**
   * 🔒 §30-38-5 1: **配置図**で頂点を足せる図形（多角形・線・直線。自動の道路の縁も
   * 含む）を選んだら、頂点の足し引きの一言を出す。
   * 🔴 選んだ図形が**変わった時だけ**（同じ図形を選び直しても連呼しない）。
   * 🔴 対象かどうかの判定は `Editor.canAddVertex` 1か所（editor.js）。
   * 🔒 §30-38-5 3: 所在図では出さない。
   */
  function vertexHintOnSelect(sel) {
    if (state.kind !== 'haichizu') return;
    if (!sel || sel.length !== 1) return;
    var o = sel[0];
    if (!window.Editor || !Editor.canAddVertex || !Editor.canAddVertex(o)) return;
    if (state.vertexHintFor === o.id) return;
    state.vertexHintFor = o.id;
    hint(VERTEX_HINT, VERTEX_HINT_MS);
  }

  /* §26-4-1 バグ修正: showSaveState('error') は上部バーの小さな文字だけだったので
   * 気づけず、作図した内容が保存されないまま失われる恐れがあった（正典 §8）。
   * 保存に失敗した時だけ、地図上の hint() トーストでも知らせる。
   * 🔴 autosave は1秒 debounce で走り続けるので、同じ状態が続く間は
   * SAVE_ERROR_HINT_INTERVAL_MS より短い間隔では連呼しない。 */
  var lastSaveErrorHintAt = 0;
  function showSaveState(s) {
    var el = $('saveState');
    if (s === 'saved') { el.textContent = '保存済 ✓'; el.className = 'save-state saved'; }
    else if (s === 'dirty') { el.textContent = '保存中…'; el.className = 'save-state dirty'; }
    else {
      el.textContent = '保存できません'; el.className = 'save-state error';
      var now = Date.now();
      if (now - lastSaveErrorHintAt >= SAVE_ERROR_HINT_INTERVAL_MS) {
        lastSaveErrorHintAt = now;
        /* 🔒 §27-4: 保存先で理由が違う（localStorage 満杯 ／ フォルダに書けない）。
         * 握り潰さず、何が起きたかを Store から取って出す。
         * 🔴 文言はそれだけで完結しているので「保存できませんでした。」を前に足さない
         *    （足すと「保存できませんでした。保存先フォルダに書き込めませんでした」と重なる）。 */
        hint(Store.lastSaveError(), 8000);
      }
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else { boot(); }
})();
