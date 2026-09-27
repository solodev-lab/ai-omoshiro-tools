/* gsinotice.js — 国土地理院の告知（住所検索の停止・メンテ等）を案件一覧に出す
 *
 * 🔒 §30-46 B（2026-09-26 オーナー決定）:
 *   地理院地図と同じ告知（CONFIG.TOPMESSAGE）を、ページを開いた時に1回だけ
 *   取りに行き、「検索」が絡む・日付がまだ過ぎていない時だけ帯を出す。
 * 🔴 実行しない（eval・script タグでの読み込みは禁止）＝文字として読み、
 *    正規表現で MESSAGE の値だけを取り出す。表示は textContent のみ。
 * 🔴 読めない・形が変わった・時間切れは黙って何も出さない（案内も失敗文も無し）。
 */
(function (global) {
  'use strict';

  var SETTING_URL = 'https://maps.gsi.go.jp/js/setting.js';
  var FETCH_TIMEOUT_MS = 10000;

  // 🔒 §30-46 B-6: 文面はオーナー承認済み（見出し・本文・足す文の3つ）。
  var TITLE = 'ⓘ 国土地理院からのお知らせ';
  var SUFFIX = 'この間は住所の［検索］が使えないことがあります。'
    + 'Google マップなどで場所を確かめて、地図をクリックしてマーカーを置けます。';

  /* 地理院の告知は頭にアイコン用の <span class="i">i</span> を持つ。
     タグだけ外すと「i」の1文字が残るので、この span は中身ごと外す */
  function stripTags(s) {
    return String(s)
      .replace(/<span[^>]*class=["']?i["']?[^>]*>[\s\S]*?<\/span>/gi, '')
      .replace(/<[^>]*>/g, '');
  }

  /** setting.js は文字列リテラル内のエスケープ（\' 等）をそのまま含むので外す */
  function unescapeJsString(s) {
    return String(s).replace(/\\(.)/g, function (_, c) {
      return (c === 'n') ? '\n' : c;
    });
  }

  function toHalfWidthDigits(s) {
    return String(s).replace(/[０-９]/g, function (c) {
      return String.fromCharCode(c.charCodeAt(0) - 0xFEE0);
    });
  }

  /**
   * 文中の「M月D日」がすべて今日より前なら true（＝出さない）。
   * 日付が1つも無ければ false（＝出す）。年は書かれていないので今年として扱う。
   */
  function allDatesPast(text, today) {
    var re = /([0-9０-９]{1,2})月([0-9０-９]{1,2})日/g;
    var m, found = false;
    var y = today.getFullYear();
    var todayOnly = new Date(y, today.getMonth(), today.getDate());
    while ((m = re.exec(text))) {
      var mo = parseInt(toHalfWidthDigits(m[1]), 10);
      var da = parseInt(toHalfWidthDigits(m[2]), 10);
      if (!mo || !da) continue;
      found = true;
      var d = new Date(y, mo - 1, da);
      if (d.getTime() >= todayOnly.getTime()) return false;   // 今日以降が1つでもある＝「まだ」
    }
    return found;
  }

  /** setting.js の文字列から CONFIG.TOPMESSAGE の MESSAGE 値を取り出す（最後の代入を採る） */
  function extractMessage(text) {
    var re = /CONFIG\.TOPMESSAGE\s*=\s*\{[\s\S]*?MESSAGE:\s*'((?:[^'\\]|\\.)*)'/g;
    var m, last = null;
    while ((m = re.exec(text))) last = m[1];
    return last;
  }

  function render(box, msg) {
    box.textContent = '';
    var h = document.createElement('div');
    h.className = 'gsi-notice-title';
    h.textContent = TITLE;
    var body = document.createElement('div');
    body.className = 'gsi-notice-body';
    body.textContent = msg;
    var suf = document.createElement('div');
    suf.className = 'gsi-notice-body';
    suf.textContent = SUFFIX;
    box.appendChild(h);
    box.appendChild(body);
    box.appendChild(suf);
    box.hidden = false;
  }

  function boot() {
    var box = document.getElementById('gsiNotice');
    if (!box) return;
    var ctrl = (typeof AbortController !== 'undefined') ? new AbortController() : null;
    var timer = ctrl ? setTimeout(function () { ctrl.abort(); }, FETCH_TIMEOUT_MS) : null;
    fetch(SETTING_URL, ctrl ? { signal: ctrl.signal } : undefined)
      .then(function (r) {
        if (!r.ok) throw new Error('bad status');
        return r.text();
      })
      .then(function (text) {
        var raw = extractMessage(text);
        if (!raw) return;
        var msg = stripTags(unescapeJsString(raw)).trim();
        if (!msg) return;
        if (msg.indexOf('検索') === -1) return;
        if (allDatesPast(msg, new Date())) return;
        render(box, msg);
      })
      .catch(function () { /* 🔒 §30-46 B-4: 黙って何も出さない */ })
      .then(function () { if (timer) clearTimeout(timer); });
  }

  global.GsiNotice = { boot: boot };

  boot();   // ページを開いた時に1回だけ
})(window);
