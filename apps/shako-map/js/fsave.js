/* fsave.js — 保存先フォルダ（正典 §21 段階A ＋ §27 案件のファイル本体化）
 *
 * 車庫証明 所在図・配置図メーカー
 *   案件一覧で選んだフォルダへ、書き出し（.shako / PDF / PNG）を直行させる。
 *   🔴 保存先はこの端末の中だけ。こちらのサーバーへ案件データは一切行かない（§1-6 / §20）。
 *
 * 責務は2系統ある（🔴 混ぜないこと・§27-8）:
 *   ① 書き出し   … saveBlob(name, blob) が「フォルダへ書く」／「未設定・非対応・
 *                  権限拒否・書き込み失敗ならダウンロードへ落とす」を一手に引き受ける（§21-1）
 *   ② 案件の本体 … listCases / readCase / writeCase / deleteCase（§27-8）。
 *                  🔴 こちらは**ダウンロードのフォールバックを持たない**。
 *                  失敗は例外で上へ返し、store.js が保存失敗として知らせる（§27-4）。
 *                  ダウンロードに落とすと `案件 (1).shako` が増え続けて本体にならない（§27-3）。
 *
 * 🔴 段階B（共有フォルダの上書き前の更新警告）は実装しない（§21-4 は構想）。
 */
(function (global) {
  'use strict';

  /* 🔴 §21-2: 画像の DB（imglay.js の 'shakomap'）とは**別の小さな DB**にする。
   *    既存 DB のバージョンを上げると、画像側の onupgradeneeded を巻き込むため。 */
  var DB_NAME = 'shakomap-fs';
  var DB_VER = 1;
  var STORE = 'handles';
  var KEY_DIR = 'exportDir';            // 保存先フォルダのハンドル1本だけ

  var current = null;     // FileSystemDirectoryHandle か null（メモリ側の現在値）
  var ready = null;       // 起動時の復元 Promise（1回だけ走らせる）

  /* ================= 対応判定（§21-2 feature detect） ================= */

  /**
   * File System Access API が使えるか。
   * 🔴 Chrome / Edge のみ。Firefox・Safari は false → 呼ぶ側は UI 自体を出さず、
   *    従来どおりダウンロードだけになる（本アプリは PC 専用・§3 なので実質カバー）。
   */
  function supported() {
    return typeof global.showDirectoryPicker === 'function' && !!global.indexedDB;
  }

  /* ================= IndexedDB（ハンドルの永続化・§21-2） ================= */

  function openDB() {
    return new Promise(function (resolve, reject) {
      if (!global.indexedDB) { reject(new Error('この環境では案件フォルダを覚えられません')); return; }
      var req = indexedDB.open(DB_NAME, DB_VER);
      req.onupgradeneeded = function () {
        var db = req.result;
        if (!db.objectStoreNames.contains(STORE)) db.createObjectStore(STORE);
      };
      req.onsuccess = function () { resolve(req.result); };
      req.onerror = function () { reject(req.error || new Error('この環境では案件フォルダを覚えられません')); };
    });
  }

  function tx(mode, fn) {
    return openDB().then(function (db) {
      return new Promise(function (resolve, reject) {
        var t = db.transaction(STORE, mode);
        var out = fn(t.objectStore(STORE));
        t.oncomplete = function () { db.close(); resolve(out && out.result); };
        t.onerror = function () { db.close(); reject(t.error); };
      });
    });
  }

  /* ハンドルは構造化複製でそのまま IndexedDB に入る（localStorage には入らない・§21-2） */
  function putHandle(h) {
    return tx('readwrite', function (s) { s.put(h, KEY_DIR); });
  }
  function getHandle() {
    return tx('readonly', function (s) { return s.get(KEY_DIR); });
  }
  function delHandle() {
    return tx('readwrite', function (s) { s.delete(KEY_DIR); });
  }

  /**
   * 起動時の復元。🔴 ここでは権限を**確認しない**（§21-2）。
   * リロード後の権限は 'prompt' に落ちるのが普通で、保存操作の中で取り直す設計。
   * 失敗しても表に出さない（保存先が未設定なだけ＝従来のダウンロードで動く）。
   */
  function load() {
    if (ready) return ready;
    ready = (supported() ? getHandle() : Promise.resolve(null))
      .then(function (h) {
        current = (h && typeof h.getFileHandle === 'function') ? h : null;
        return current;
      })
      .catch(function () { current = null; return null; });
    return ready;
  }

  /* ================= 権限（§21-2） ================= */

  /**
   * readwrite 権限を確かめ、必要なら要求する。
   * 🔴 requestPermission は**ユーザー操作の中**でしか通らない（ブラウザの要求仕様）。
   *    だから起動時ではなく、保存ボタンの click から呼ぶ（prepare / saveBlob）。
   * 🔴 権限 API を持たないハンドル（OPFS の疑似ハンドル＝§21-3 の自動検証）は
   *    そのまま書ける物として扱う。
   */
  function ensurePermission(h) {
    return Promise.resolve().then(function () {
      if (!h || typeof h.queryPermission !== 'function') return 'granted';
      return h.queryPermission({ mode: 'readwrite' });
    }).then(function (st) {
      if (st === 'granted') return true;
      if (!h || typeof h.requestPermission !== 'function') return false;
      return h.requestPermission({ mode: 'readwrite' }).then(function (s2) {
        return s2 === 'granted';
      });
    }).catch(function () { return false; });   // 拒否・活性化切れはフォールバックへ
  }

  /**
   * 保存ボタンの click 直後に呼んでおく（§21-2）。
   * PDF の組み立てに数秒かかると click の活性化が切れて requestPermission が
   * 通らなくなるので、重い処理を始める**前**に権限を取っておく。
   * 🔴 戻り値は待たなくてよい（待たなくても saveBlob 側でもう一度確かめる）。
   */
  function prepare() {
    return load().then(function (h) {
      return h ? ensurePermission(h) : false;
    }).catch(function () { return false; });
  }

  /* ================= 書き出し（§21-1） ================= */

  /** 従来どおりのアンカーダウンロード。フォールバック先はここ1つだけ */
  function download(name, blob, failed) {
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = name;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    setTimeout(function () { URL.revokeObjectURL(a.href); }, 1500);
    return { mode: 'download', dir: '', name: name, failed: !!failed };
  }

  /* getFileHandle(create:true) → createWritable → write → close（§21-2）。
     🔴 案件本体（.shako）は同名を**上書き**する（それが保存の意味）。
        createWritable は既定で中身を空にしてから開くので、短い内容で上書きしても
        前の内容が残らない。
     🔒 §30-32-3: **書き出し（PDF/画像）は上書きしない**。呼ぶ側が uniq:true を
        渡すと、同名が既にある時は `-2` `-3` … を付けた名前で書く。 */
  function writeInto(h, name, blob) {
    return h.getFileHandle(name, { create: true }).then(function (fh) {
      return fh.createWritable();
    }).then(function (w) {
      return w.write(blob).then(function () { return w.close(); });
    });
  }

  /* 🔒 §30-32-3: 名前を「点の前」と「拡張子」に割る（最後の点で切る・点が無ければ全部） */
  function splitExt(name) {
    var i = String(name).lastIndexOf('.');
    return (i > 0) ? { stem: name.slice(0, i), ext: name.slice(i) }
                   : { stem: String(name), ext: '' };
  }

  /**
   * 🔒 §30-32-3（オーナー指示「毎回上書きはだめ、絶対違うファイルとして保存」）:
   * そのフォルダで**まだ使われていない名前**を返す。
   * 同名があれば `-2` `-3` … を付ける。99 まで埋まっていたら最後の保険として
   * 時刻（時分秒）を足す（必ず別名になる＝上書きだけは絶対にしない）。
   * 🔴 「あるか」は getFileHandle(create:false) が NotFoundError を投げるかで見る。
   *    それ以外の理由で失敗した時は**その名前を使わない**（消してよいとは限らない）
   *    で次の候補へ進む、ではなく元の名前を返す（書き込み側が失敗を拾う）。
   */
  function uniqueName(h, name) {
    var s = splitExt(name);
    function exists(n) {
      return h.getFileHandle(n, { create: false })
              .then(function () { return true; }, function () { return false; });
    }
    function step(i) {
      var n = (i === 1) ? name : (s.stem + '-' + i + s.ext);
      if (i > 99) {
        var d = new Date(), p2 = function (v) { return String(v).padStart(2, '0'); };
        return Promise.resolve(s.stem + '-'
          + p2(d.getHours()) + p2(d.getMinutes()) + p2(d.getSeconds()) + s.ext);
      }
      return exists(n).then(function (yes) { return yes ? step(i + 1) : n; });
    }
    return step(1).catch(function () { return name; });
  }

  /**
   * 保存の入口（書き出しの全経路がここを通る・§21-1）。
   * @returns Promise<{mode:'folder'|'download', dir, name, failed}>
   *   mode='folder'   … 保存先フォルダへ直行できた
   *   mode='download' … ダウンロードへ落ちた（failed=true なら書き込み失敗・権限拒否、
   *                     failed=false なら「そもそも保存先が未設定／非対応」）
   * 🔴 例外は投げない。呼ぶ側は結果を見てヒントを出すだけでよい。
   */
  function saveBlob(name, blob) {
    return load().then(function (h) {
      if (!h) return download(name, blob, false);        // 未設定・非対応＝従来どおり
      return ensurePermission(h).then(function (ok) {
        if (!ok) return download(name, blob, true);      // 権限拒否 → フォールバック
        /* 🔒 §30-32-3: 書き出しは**既存ファイルを絶対に上書きしない**。
         * 同名があれば -2 -3 … を付けた名前で書き、その名前を結果で返す
         * （一言「保存しました: フォルダ/ファイル名」も実物の名前になる）。 */
        return uniqueName(h, name).then(function (n2) {
          return writeInto(h, n2, blob).then(function () {
            return { mode: 'folder', dir: h.name, name: n2, failed: false };
          }, fallback);
        }, fallback);
        function fallback() {
          /* フォルダを消された・USB を抜かれた・ディスクが一杯 等。
             作図を止めずダウンロードへ切り替える（§21-1） */
          return download(name, blob, true);
        }
      });
    }).catch(function () {
      return download(name, blob, true);
    });
  }

  /* ================= 設定 UI から呼ぶ（§21-1） ================= */

  /** 現在のフォルダ名（未設定なら ''）。UI の表示用 */
  function dirName() { return current ? current.name : ''; }

  /**
   * ［フォルダを選ぶ］。🔴 本物のダイアログが要る＝自動検証できない（§21-3）ので、
   * ここは薄くしておき、選んだ後の処理は useHandle に寄せる。
   * キャンセルは AbortError で reject される（呼ぶ側で握りつぶす）。
   */
  function pick() {
    if (!supported()) return Promise.reject(new Error('この環境では案件フォルダを選べません'));
    /* 🔒 §27-3: `startIn:'downloads'` ＝ ダイアログの**初期位置**をダウンロード
     * フォルダにする。オーナーの「フォルダ未設定ならダウンロードフォルダへ」の意図は
     * これで実現する（許可の無いフォルダへ黙って書くことはブラウザにできない）。
     * 🔴 startIn を知らない実装で TypeError になっても困るので、素の呼び出しへ落ちる。 */
    var p;
    try {
      p = global.showDirectoryPicker({ mode: 'readwrite', startIn: 'downloads' });
    } catch (e) {
      p = global.showDirectoryPicker({ mode: 'readwrite' });
    }
    return Promise.resolve(p).then(useHandle);
  }

  /**
   * ハンドルを保存先として採用する（pick の後半）。
   * 🔴 §21-3 の自動検証では、OPFS（navigator.storage.getDirectory()）が返す
   *    同型の FileSystemDirectoryHandle をここへ注入して、書き込み・上書き・
   *    失敗経路をダイアログ無しで実測する。
   */
  function useHandle(h) {
    current = h || null;
    ready = Promise.resolve(current);          // 復元待ちを済んだ物に差し替える
    return (current ? putHandle(current) : delHandle())
      .catch(function () { /* 覚えられなくても今回の保存は使える */ })
      .then(function () { return current; });
  }

  /* 🔒 §27-12: 旧［解除］用の clear() は削除した。案件フォルダを「無い状態」に戻す
     操作は無く、あるのは［別のフォルダを開く］（＝ pick で置き換える）だけ。 */

  /* ================= 案件の本体（🔒 §27-8） =================
   * 🔴 ここは書き出し（saveBlob）とは**別系統**。ダウンロードへ落とさず、
   *    失敗は例外で返す。呼ぶのは store.js だけ（§27-7）。 */

  var CASE_EXT = '.shako';

  /** 案件ファイルか（🔴 旧 .shako.json も拾う＝過去のバックアップを見捨てない・§20-8） */
  function isCaseFile(name) {
    var n = String(name || '').toLowerCase();
    return n.slice(-6) === CASE_EXT || n.slice(-11) === '.shako.json';
  }

  /**
   * 権限の今の状態を返す（🔴 要求はしない＝起動時に呼べる・§27-4）。
   * @returns Promise<'none'|'granted'|'prompt'|'denied'>
   *   'none' … フォルダ未設定・非対応
   */
  function permissionState() {
    return load().then(function (h) {
      if (!h) return 'none';
      if (typeof h.queryPermission !== 'function') return 'granted';  // OPFS の疑似ハンドル
      return h.queryPermission({ mode: 'readwrite' });
    }).catch(function () { return 'none'; });
  }

  /**
   * 権限を要求する（🔴 **ユーザー操作の中からだけ**呼べる・ブラウザの仕様）。
   * 案件一覧の［フォルダを使えるようにする］から呼ぶ（§27-4）。
   */
  function requestAccess() {
    return load().then(function (h) {
      return h ? ensurePermission(h) : false;
    }).catch(function () { return false; });
  }

  /** 権限を確かめてハンドルを返す。だめなら例外（🔴 案件系はここで止める） */
  function dir() {
    return load().then(function (h) {
      if (!h) throw new Error('案件フォルダが選ばれていません');
      return ensurePermission(h).then(function (ok) {
        if (!ok) throw new Error('案件フォルダを使う許可がありません');
        return h;
      });
    });
  }

  /**
   * フォルダ内の案件ファイルを列挙する（§27-8）。
   * @returns Promise<[{name, handle}]>
   * 🔴 `values()` は非同期イテレータ。for-await を使わず手で回す（ES5 のまま保つ）。
   */
  function listCases() {
    return dir().then(function (h) {
      if (typeof h.values !== 'function') {
        throw new Error('この案件フォルダの中身を読めません');
      }
      var out = [];
      var it = h.values();
      function step() {
        return it.next().then(function (r) {
          if (r.done) return out;
          var e = r.value;
          if (e && e.kind === 'file' && isCaseFile(e.name)) {
            out.push({ name: e.name, handle: e });
          }
          return step();
        });
      }
      return step();
    });
  }

  /** 1件読む（文字列で返す）。無ければ例外（§27-8） */
  function readCase(name) {
    return dir().then(function (h) {
      return h.getFileHandle(name, { create: false });
    }).then(function (fh) {
      return fh.getFile();
    }).then(function (f) { return f.text(); });
  }

  /**
   * 1件書く（**上書き**・§27-8）。
   * 🔴 saveBlob と違い、失敗してもダウンロードへ落とさない（例外を投げる）。
   *    createWritable は既定で中身を空にしてから開くので、短い内容で上書きしても
   *    前の内容は残らない。
   */
  function writeCase(name, text) {
    return dir().then(function (h) {
      return writeInto(h, name, new Blob([text], { type: 'application/json' }));
    }).then(function () { return true; });
  }

  /** 1件消す（§27-8）。すでに無い場合も成功として扱う */
  function deleteCase(name) {
    return dir().then(function (h) {
      return h.removeEntry(name);
    }).then(function () { return true; }, function (e) {
      if (e && e.name === 'NotFoundError') return true;
      throw e;
    });
  }

  global.FSave = {
    supported: supported,
    ready: load,                 // 起動時の復元（権限は確認しない・§21-2）
    dirName: dirName,
    pick: pick, useHandle: useHandle,
    prepare: prepare,            // 保存ボタンの click 直後に呼ぶ（§21-2）
    saveBlob: saveBlob,          // 書き出しの全経路がここを通る（§21-1）
    /* ---- 案件の本体（🔒 §27-8）。呼ぶのは store.js だけ ---- */
    permissionState: permissionState,
    requestAccess: requestAccess,
    isCaseFile: isCaseFile,
    listCases: listCases, readCase: readCase,
    writeCase: writeCase, deleteCase: deleteCase
  };
})(typeof window !== 'undefined' ? window : this);
