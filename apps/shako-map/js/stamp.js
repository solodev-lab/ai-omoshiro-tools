/* stamp.js — 塊スタンプ（四角並べ）パネル（正典 §4-4）
 *
 * 車庫証明 所在図・配置図メーカー
 * 「向き・台数・1枠サイズ」をプレビューを見ながら決めて、[配置] で地図中央に置く。
 * 置いた後は普通のオブジェクトなので、ドラッグ移動・回転・全体伸縮・コピーができる。
 */
(function (global) {
  'use strict';

  // 枠サイズのプリセット（正典 §4-4）
  var PRESETS = {
    normal: { label: '普通車', w: 2.5, h: 5.0 },
    kei: { label: '軽', w: 2.0, h: 3.6 },
    large: { label: '大型', w: 3.0, h: 6.5 },
    custom: { label: 'カスタム', w: null, h: null }
  };

  /* 🔒 修正4（オーナー指示 2026-08-30）: 台数欄は**影文字（placeholder）**にして
   * 実テキストを入れない（一度消してから打ち直す手間をなくす）。
   * 空欄＝この既定値＝**従来の初期値と同じ 5台**。index.html の placeholder
   * 「例）5」と title「空欄のままなら 5台で置きます」もこの値に揃えてある。 */
  var DEFAULT_COUNT = 5;

  function $(id) { return document.getElementById(id); }

  function StampPanel(editor) {
    this.editor = editor;
    this.el = $('stampPanel');
    // 既定は「横に並べる」（枠が縦長で左右に並ぶ・最も多い形）
    this.state = { preset: 'normal', count: DEFAULT_COUNT, direction: 'row',
                   w: 2.5, h: 5.0 };
    this._build();
  }

  StampPanel.prototype.open = function () {
    this.el.hidden = false;
    /* 🔒 修正4: 開くたびに台数欄は空（影文字）に戻す。
     * 見えている物（影文字の 5）と実際に置かれる台数を必ず一致させるため、
     * 内部の既定値も 5 に戻す（見えない前回値が効く、を作らない）。 */
    $('stampCount').value = '';
    this.state.count = DEFAULT_COUNT;
    this._sync();
  };
  StampPanel.prototype.close = function () { this.el.hidden = true; };
  StampPanel.prototype.isOpen = function () { return !this.el.hidden; };

  StampPanel.prototype._build = function () {
    var self = this;

    // プリセット
    var sel = $('stampPreset');
    sel.innerHTML = '';
    Object.keys(PRESETS).forEach(function (k) {
      var p = PRESETS[k];
      var o = document.createElement('option');
      o.value = k;
      o.textContent = p.w ? (p.label + '  ' + p.w + '×' + p.h + 'm') : p.label;
      sel.appendChild(o);
    });
    sel.value = 'normal';
    sel.addEventListener('change', function () {
      self.state.preset = this.value;
      var p = PRESETS[this.value];
      if (p.w) { self.state.w = p.w; self.state.h = p.h; }
      self._sync();
    });

    /* 🔒 修正4: 空欄＝既定(5台)。欄の中身は**書き戻さない**
     * （書き戻すと消した瞬間に 5 が復活して、また消す羽目になる＝今回の苦情の元）。
     * 上限60を超えた入力だけ、打ち終わり(change)に丸めた値を見せる。 */
    $('stampCount').addEventListener('input', function () {
      var n = parseInt(this.value, 10);
      self.state.count = isNaN(n) ? DEFAULT_COUNT : Math.max(1, Math.min(60, n));
      self._sync();
    });
    $('stampCount').addEventListener('change', function () {
      var n = parseInt(this.value, 10);
      if (!isNaN(n) && n !== self.state.count) this.value = self.state.count;
    });
    $('stampW').addEventListener('input', function () {
      var v = parseFloat(this.value);
      if (!isNaN(v) && v > 0) { self.state.w = v; self.state.preset = 'custom'; $('stampPreset').value = 'custom'; }
      self._sync();
    });
    $('stampH').addEventListener('input', function () {
      var v = parseFloat(this.value);
      if (!isNaN(v) && v > 0) { self.state.h = v; self.state.preset = 'custom'; $('stampPreset').value = 'custom'; }
      self._sync();
    });
    // 並べ方は図をクリックして選ぶ（言葉より形で分かるように）
    this.el.querySelectorAll('.stamp-choice').forEach(function (b) {
      b.addEventListener('click', function () {
        self.state.direction = b.dataset.dir;
        self._sync();
      });
    });

    $('stampPlace').addEventListener('click', function () {
      self.editor.placeStamp({
        count: self.state.count, cell_w_m: self.state.w,
        cell_h_m: self.state.h, direction: self.state.direction
      });
      self.editor.setTool('select');
      self.close();
    });
    $('stampCancel').addEventListener('click', function () {
      self.close();
      self.editor.setTool('select');
    });
  };

  StampPanel.prototype._sync = function () {
    var s = this.state;
    // 🔒 修正4: 台数欄には書き戻さない（open() だけが空に戻す）
    $('stampW').value = s.w;
    $('stampH').value = s.h;
    /* 🔒 §18-ad: プリセット（普通車・軽・大型）を選んでいる間、幅・奥行は
     * **「表示」であって入力欄ではない**。読み取り専用にして枠線と背景を消し、
     * 「ここで入れるのは台数だけ」と一目で分かるようにする。
     * カスタムを選んだ時だけ従来どおりの入力欄に戻る。 */
    var custom = (s.preset === 'custom');
    [$('stampW'), $('stampH')].forEach(function (el) {
      if (!el) return;
      el.readOnly = !custom;
      el.classList.toggle('is-fixed', !custom);
      el.title = custom ? '' : '枠サイズで「カスタム」を選ぶと編集できます';
    });
    this.el.querySelectorAll('.stamp-choice').forEach(function (b) {
      b.classList.toggle('is-active', b.dataset.dir === s.direction);
    });
    var total = (s.direction === 'col')
      ? { w: s.w, h: s.h * s.count } : { w: s.w * s.count, h: s.h };
    $('stampTotal').textContent = '全体 ' + total.w.toFixed(1) + ' × '
      + total.h.toFixed(1) + ' m';
    this._preview();
  };

  /**
   * 並べ方を2つとも図で見せる（正典 §4-4「プレビューを見ながら」）。
   * 言葉だけだと「縦列/横列」がどちらの形か伝わらず、
   * 「この形にはできない」と思われてしまうため、両方の形を出して選ばせる。
   */
  StampPanel.prototype._preview = function () {
    this._drawFig($('stampFigRow'), 'row');
    this._drawFig($('stampFigCol'), 'col');
  };

  StampPanel.prototype._drawFig = function (box, dir) {
    if (!box) return;
    var s = this.state;
    var W = box.clientWidth || 96, H = 84, PAD = 7;
    var col = (dir === 'col');
    var n = Math.min(s.count, 6);          // 図では多くても6枠まで
    var totW = col ? s.w : s.w * n;
    var totH = col ? s.h * n : s.h;
    var k = Math.min((W - PAD * 2) / totW, (H - PAD * 2) / totH);
    var cw = s.w * k, ch = s.h * k;
    var ox = (W - totW * k) / 2, oy = (H - totH * k) / 2;
    var on = (dir === s.direction);
    var stroke = on ? '#1a56c4' : '#9aa3b0';

    var parts = ['<svg width="' + W + '" height="' + H + '" aria-hidden="true">'];
    for (var i = 0; i < n; i++) {
      var x = ox + (col ? 0 : i * cw);
      var y = oy + (col ? i * ch : 0);
      parts.push('<rect x="' + x.toFixed(1) + '" y="' + y.toFixed(1) +
                 '" width="' + cw.toFixed(1) + '" height="' + ch.toFixed(1) +
                 '" fill="' + (on ? 'rgba(26,86,196,.08)' : 'none') +
                 '" stroke="' + stroke + '" stroke-width="1.4"/>');
    }
    if (s.count > n) {
      parts.push('<text x="' + (W - 6) + '" y="' + (H - 4) +
                 '" text-anchor="end" font-size="10" fill="' + stroke +
                 '">…' + s.count + '台</text>');
    }
    parts.push('</svg>');
    box.innerHTML = parts.join('');
  };

  StampPanel.PRESETS = PRESETS;
  global.StampPanel = StampPanel;
})(typeof window !== 'undefined' ? window : this);
