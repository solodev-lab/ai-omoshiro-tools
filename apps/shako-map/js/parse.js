/* parse.js — 依頼文から住所などを拾う（正典 §9 Step 6 / §15 レーンC）
 *
 * 車庫証明 所在図・配置図メーカー
 *
 * 🔴 端末の中だけで完結させる。依頼者の住所を外部へ送らない（正典 §1-6）。
 *    そのため LLM やクラウドAPIは使わず、正規表現だけで拾う。
 *    拾えたものは「候補」として出し、採用するかは人が決める。
 */
(function (global) {
  'use strict';

  var PREF = '北海道|青森県|岩手県|宮城県|秋田県|山形県|福島県|茨城県|栃木県|群馬県'
    + '|埼玉県|千葉県|東京都|神奈川県|新潟県|富山県|石川県|福井県|山梨県|長野県'
    + '|岐阜県|静岡県|愛知県|三重県|滋賀県|京都府|大阪府|兵庫県|奈良県|和歌山県'
    + '|鳥取県|島根県|岡山県|広島県|山口県|徳島県|香川県|愛媛県|高知県|福岡県'
    + '|佐賀県|長崎県|熊本県|大分県|宮崎県|鹿児島県|沖縄県';

  // 住所の本体。丁目・番地・号や漢数字も拾えるようにする
  var BODY = '[^\\s、。,，\\n\\r]{1,40}?[市区町村郡][^\\s、。,，\\n\\r]{0,40}';
  var TAIL = '[0-9０-９一二三四五六七八九十丁目番地号\\-ー－‐−の\\s]{0,24}';

  var RE_ADDR = new RegExp('(?:' + PREF + ')' + BODY + TAIL, 'g');
  // 都道府県が省略された書き方（「春日井市鳥居松町1-1」）も一応拾う。
  // 「自宅は名古屋市…」のように前に文が付くので、市区町村名の手前は
  // 漢字・ひらがな混じりの短い塊に限る（助詞や見出しを巻き込まないため）。
  var RE_ADDR_NOPREF = new RegExp('[一-龥ァ-ヶー]{1,8}?[市区町村]'
    + '[^\\s、。,，\\n\\r]{0,30}' + TAIL, 'g');

  // 行頭に付きがちな見出し語（拾った文字列から落とす）
  var RE_LABEL = /^(?:.*?(?:使用の本拠の位置|保管場所の位置|使用の本拠|保管場所|現住所|申請者住所|所有者住所|会社所在地|事業所|住所地|本店|自宅|駐車場|車庫|住所)\s*[:：はのが]?\s*)/;
  // 末尾に続く説明文（「…の月極を借りました」等）を落とす
  var RE_TRAILING = /(?:です|でございます|になります|の?月極.*|を借り.*|付近.*|近く.*|内.*)$/;

  // どちらの住所かを示す手がかり
  var HINT_HOME = ['使用の本拠', '本拠の位置', '本拠', '自宅', '住所地', '現住所',
                   '申請者住所', '所有者住所', '会社所在地', '本店', '事業所'];
  var HINT_LOT = ['保管場所', '駐車場', '車庫', '保管場所の位置', '駐車位置',
                  '月極', 'パーキング'];

  function normalize(s) {
    return String(s || '')
      .replace(/[０-９]/g, function (c) {   // 全角数字 → 半角
        return String.fromCharCode(c.charCodeAt(0) - 0xFEE0);
      })
      .replace(/[－‐-―−]/g, '-') // 各種ダッシュ → ハイフン
      .replace(/　/g, ' ');
  }

  function tidy(a) {
    var s = String(a);
    // 都道府県から始まっていなければ、手前の見出しや助詞を落とす
    if (!new RegExp('^(?:' + PREF + ')').test(s)) s = s.replace(RE_LABEL, '');
    s = s.replace(RE_TRAILING, '');
    return s.replace(/[-\s、。]+$/, '').replace(/\s{2,}/g, ' ').trim();
  }

  /** 行ごとに見て、手がかり語の近くにある住所を優先して選ぶ */
  function extract(raw) {
    var text = normalize(raw);
    var lines = text.split(/[\n\r]+/);
    var found = [];

    lines.forEach(function (line) {
      var hits = line.match(RE_ADDR) || [];
      if (!hits.length) {
        // 都道府県なしの行も見る（ただし手がかり語がある行に限る）
        var hinted = HINT_HOME.concat(HINT_LOT).some(function (h) {
          return line.indexOf(h) >= 0;
        });
        if (hinted) hits = line.match(RE_ADDR_NOPREF) || [];
      }
      hits.forEach(function (a) {
        var addr = tidy(a);
        if (addr.length < 5) return;
        var before = line.slice(0, line.indexOf(a));
        var kind = null;
        // 同じ行の住所より前にある語を手がかりにする
        HINT_LOT.forEach(function (h) { if (before.indexOf(h) >= 0) kind = 'lot'; });
        HINT_HOME.forEach(function (h) { if (before.indexOf(h) >= 0) kind = 'home'; });
        if (!kind) {
          HINT_LOT.forEach(function (h) { if (line.indexOf(h) >= 0) kind = kind || 'lot'; });
          HINT_HOME.forEach(function (h) { if (line.indexOf(h) >= 0) kind = kind || 'home'; });
        }
        found.push({ address: addr, kind: kind, line: line.trim() });
      });
    });

    // 重複を落とす
    var seen = {}, uniq = [];
    found.forEach(function (f) {
      if (seen[f.address]) return;
      seen[f.address] = true;
      uniq.push(f);
    });

    var home = null, lot = null;
    uniq.forEach(function (f) {
      if (f.kind === 'home' && !home) home = f;
      if (f.kind === 'lot' && !lot) lot = f;
    });
    // 手がかりが無ければ、出てきた順に自宅→駐車場とみなす
    var rest = uniq.filter(function (f) { return f !== home && f !== lot; });
    if (!home && rest.length) home = rest.shift();
    if (!lot && rest.length) lot = rest.shift();

    return { home: home, lot: lot, all: uniq, extras: extractExtras(text) };
  }

  /** 区画番号など、図面に使える付随情報 */
  function extractExtras(text) {
    var out = {};
    var m = text.match(/(?:区画|車室|No\.?|NO\.?|番号)\s*[:：]?\s*([0-9]{1,4})\s*番?/);
    if (m) out.stallNo = m[1];
    var w = text.match(/幅員\s*[:：]?\s*([0-9]+(?:\.[0-9]+)?)\s*m/i);
    if (w) out.roadWidth = w[1];
    var h = text.match(/(?:高さ|入庫口)\s*[:：]?\s*([0-9]+(?:\.[0-9]+)?)\s*m/i);
    if (h) out.height = h[1];
    return out;
  }

  global.AddrParse = { extract: extract, normalize: normalize };
})(typeof window !== 'undefined' ? window : this);
