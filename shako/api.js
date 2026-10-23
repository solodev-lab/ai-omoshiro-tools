/* 車庫証明 所在図・配置図メーカー 公開ページ共通（紹介ページ・invoice・thanks）
   Worker の URL・販売スイッチ（/v1/mode）・通信・プラン表を 1 か所にまとめる。
   外部スクリプトは読み込まない。 */
(function () {
  'use strict';
  var DEFAULT_API = 'https://shako-api.solodev-lab.com';
  var q = new URLSearchParams(location.search);
  var isLocal = /^(localhost|127\.0\.0\.1|\[::1\])$/.test(location.hostname);

  /* 🔧 手元の確認用の上書きは localhost／127.0.0.1 で開いた時だけ効く（公開サイトでは効かない）
     ?api=http://127.0.0.1:8787  … Worker の向き先
     ?mode=test|open|closed       … /v1/mode の返事を仮に差し替える */
  var SHAKO_API = DEFAULT_API;
  if (isLocal && /^https?:\/\//.test(q.get('api') || '')) SHAKO_API = q.get('api').replace(/\/+$/, '');

  var NETERR = '通信できませんでした。時間をおいてお試しください';

  /* プラン表（§31-3 の表と同じ。値は Worker の plan／cycle と同じ文字列） */
  var PLANS = [
    { id: 'light',      name: 'ライト',           m: 3300,  y: 33000,  qm: '月10件',  qy: '年120件',  seats: '1台' },
    { id: 'standard',   name: 'スタンダード',     m: 8800,  y: 88000,  qm: '月50件',  qy: '年600件',  seats: '2台' },
    { id: 'pro',        name: 'プロ',             m: 18000, y: 180000, qm: '月200件', qy: '年2,400件', seats: '3台' },
    { id: 'office_std', name: '事務所スタンダード', m: 33000, y: 330000, qm: '月600件', qy: '年7,200件', seats: '5台' },
    { id: 'office_pro', name: '事務所プロ',       m: 58000, y: 580000, qm: '無制限',  qy: '無制限',   seats: '台数無制限' }
  ];

  function plan(id) {
    for (var i = 0; i < PLANS.length; i++) if (PLANS[i].id === id) return PLANS[i];
    return null;
  }
  function yen(n) { return Number(n).toLocaleString('ja-JP') + '円'; }

  function withTimeout(ms) {
    if (typeof AbortController === 'undefined') return { signal: undefined, done: function () {} };
    var c = new AbortController();
    var t = setTimeout(function () { c.abort(); }, ms);
    return { signal: c.signal, done: function () { clearTimeout(t); } };
  }

  /* 販売スイッチ。失敗したら 'closed'（§31-9）。 */
  function mode() {
    var ov = isLocal ? q.get('mode') : null;
    if (ov === 'test' || ov === 'open' || ov === 'closed') return Promise.resolve(ov);
    var to = withTimeout(8000);
    return fetch(SHAKO_API + '/v1/mode', { method: 'GET', signal: to.signal })
      .then(function (r) { to.done(); return r.ok ? r.json() : null; })
      .then(function (j) { return (j && (j.sale === 'test' || j.sale === 'open')) ? j.sale : 'closed'; })
      .catch(function () { to.done(); return 'closed'; });
  }
  /* 申し込みの画面を出してよいか（test は URL に ?sale=test がある時だけ） */
  function saleUsable(m) { return m === 'open' || (m === 'test' && q.get('sale') === 'test'); }

  /* POST JSON。通信できなければ reject。返事は {ok, status, data} */
  function post(path, body) {
    var to = withTimeout(30000);
    return fetch(SHAKO_API + path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body || {}),
      signal: to.signal
    }).then(function (r) {
      to.done();
      return r.json().catch(function () { return {}; }).then(function (d) {
        return { ok: r.ok, status: r.status, data: d || {} };
      });
    }, function (e) { to.done(); throw e; });
  }

  function copy(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(text);
    }
    return new Promise(function (resolve, reject) {
      try {
        var ta = document.createElement('textarea');
        ta.value = text; ta.setAttribute('readonly', ''); ta.style.position = 'fixed'; ta.style.opacity = '0';
        document.body.appendChild(ta); ta.select();
        var ok = document.execCommand('copy');
        document.body.removeChild(ta);
        ok ? resolve() : reject(new Error('copy'));
      } catch (e) { reject(e); }
    });
  }

  /* 申し込み時の入力を invoice.html へ渡す（メール・事務所名は URL に載せず、このタブの sessionStorage で渡す） */
  function stash(obj) { try { sessionStorage.setItem('shako.apply', JSON.stringify(obj)); } catch (e) {} }
  function unstash() { try { return JSON.parse(sessionStorage.getItem('shako.apply') || 'null'); } catch (e) { return null; } }
  function unstashClear() { try { sessionStorage.removeItem('shako.apply'); } catch (e) {} }

  window.Shako = {
    API: SHAKO_API, LOCAL: isLocal, NETERR: NETERR, PLANS: PLANS, plan: plan, yen: yen,
    mode: mode, saleUsable: saleUsable, post: post, copy: copy,
    stash: stash, unstash: unstash, unstashClear: unstashClear,
    query: q
  };
})();
