/* mvt.js — Mapbox Vector Tile (MVT) decoder, dependency-free.
 *
 * 車庫証明 所在図・配置図メーカー
 * 国土地理院ベクトルタイル(.pbf)を素の JS だけで読むための最小デコーダ。
 * ビルド無し・外部ライブラリ無しの方針(正典 §2)のため、@mapbox/vector-tile や
 * pbf は使わず自前で持つ。
 *
 * 使い方:
 *   const layers = MVT.decode(new Uint8Array(arrayBuffer));
 *   // layers = { RdCL: {extent, features:[...]}, Anno: {...}, ... }
 *   // feature = { id, type, props, geom }
 *   //   type: 1=point 2=line 3=polygon
 *   //   geom: [[ [x,y], ... ], ...]  ← タイル内部座標(0..extent)
 */
(function (global) {
  'use strict';

  /* ---------- protobuf reader ---------- */
  function Reader(buf, pos, end) {
    this.buf = buf;
    this.pos = pos || 0;
    this.end = end === undefined ? buf.length : end;
  }

  Reader.prototype.varint = function () {
    // 32bit を超える値も壊れないよう、上位バイトは乗算で積む
    var result = 0, shift = 0, b;
    do {
      b = this.buf[this.pos++];
      result += (b & 0x7f) * Math.pow(2, shift);
      shift += 7;
    } while (b & 0x80);
    return result;
  };

  Reader.prototype.svarint = function () {
    var n = this.varint();
    return (n % 2) ? -(n + 1) / 2 : n / 2; // zigzag
  };

  Reader.prototype.bytes = function () {
    var n = this.varint();
    var b = this.buf.subarray(this.pos, this.pos + n);
    this.pos += n;
    return b;
  };

  Reader.prototype.string = function () {
    return utf8(this.bytes());
  };

  Reader.prototype.float = function () {
    var v = new DataView(this.buf.buffer, this.buf.byteOffset + this.pos, 4)
      .getFloat32(0, true);
    this.pos += 4;
    return v;
  };

  Reader.prototype.double = function () {
    var v = new DataView(this.buf.buffer, this.buf.byteOffset + this.pos, 8)
      .getFloat64(0, true);
    this.pos += 8;
    return v;
  };

  Reader.prototype.skip = function (wire) {
    if (wire === 0) this.varint();
    else if (wire === 1) this.pos += 8;
    else if (wire === 2) {
      // `this.pos += this.varint()` は不可。JS は左辺 this.pos を先に読むため、
      // varint() が pos を進めた分だけ戻ってしまい以降が全部ずれる。
      var n = this.varint();
      this.pos += n;
    } else if (wire === 5) this.pos += 4;
    else throw new Error('MVT: bad wire type ' + wire);
  };

  var _dec = (typeof TextDecoder !== 'undefined')
    ? new TextDecoder('utf-8') : null;
  function utf8(bytes) {
    if (_dec) return _dec.decode(bytes);
    var s = '';
    for (var i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
    return decodeURIComponent(escape(s));
  }

  /* ---------- MVT value ---------- */
  function readValue(buf) {
    var r = new Reader(buf), key, tag, wire;
    while (r.pos < r.end) {
      key = r.varint(); tag = key >> 3; wire = key & 7;
      if (tag === 1 && wire === 2) return r.string();
      if (tag === 2 && wire === 5) return r.float();
      if (tag === 3 && wire === 1) return r.double();
      if (tag === 4 && wire === 0) return r.varint();
      if (tag === 5 && wire === 0) return r.varint();
      if (tag === 6 && wire === 0) return r.svarint();
      if (tag === 7 && wire === 0) return !!r.varint();
      r.skip(wire);
    }
    return null;
  }

  /* ---------- layer ---------- */
  function readLayer(buf) {
    var r = new Reader(buf);
    var name = null, extent = 4096, version = 1;
    var keys = [], values = [], featureBufs = [];
    while (r.pos < r.end) {
      var key = r.varint(), tag = key >> 3, wire = key & 7;
      if (tag === 1 && wire === 2) name = r.string();
      else if (tag === 15 && wire === 0) version = r.varint();
      else if (tag === 5 && wire === 0) extent = r.varint();
      else if (tag === 3 && wire === 2) keys.push(r.string());
      else if (tag === 4 && wire === 2) values.push(readValue(r.bytes()));
      else if (tag === 2 && wire === 2) featureBufs.push(r.bytes());
      else r.skip(wire);
    }

    var features = [];
    for (var f = 0; f < featureBufs.length; f++) {
      var fr = new Reader(featureBufs[f]);
      var id = null, tagIdx = [], gtype = 0, stop, len;
      while (fr.pos < fr.end) {
        var k2 = fr.varint(), t = k2 >> 3, w = k2 & 7;
        if (t === 1 && w === 0) id = fr.varint();
        else if (t === 2 && w === 2) {
          // 長さを先に読んでから pos を足す。1式に書くと pos が先に評価され
          // stop が長さバイト分だけ手前になり、以降の読みが全部ずれる。
          len = fr.varint(); stop = fr.pos + len;
          while (fr.pos < stop) tagIdx.push(fr.varint());
        } else if (t === 3 && w === 0) gtype = fr.varint();
        else fr.skip(w);   // geometry(tag4) は readFeatureGeometry で別読み
      }
      var props = {};
      for (var p = 0; p + 1 < tagIdx.length; p += 2) {
        props[keys[tagIdx[p]]] = values[tagIdx[p + 1]];
      }
      features.push({ id: id, type: gtype, props: props, geom: null,
                      _raw: featureBufs[f] });
    }
    return { name: name, extent: extent, version: version, features: features };
  }

  /* geometry は「command integer(uint)」と「パラメータ(zigzag)」が交互に並ぶ。
   * まとめて svarint 読みすると壊れるので、コマンドを解釈しながら読む。 */
  function readFeatureGeometry(rawFeature) {
    var fr = new Reader(rawFeature);
    while (fr.pos < fr.end) {
      var k = fr.varint(), t = k >> 3, w = k & 7;
      if (t === 4 && w === 2) {
        var glen = fr.varint(), stop = fr.pos + glen;   // 順序に注意(上と同じ)
        var x = 0, y = 0, out = [], cur = null;
        while (fr.pos < stop) {
          var ci = fr.varint(), cmd = ci & 0x7, count = ci >> 3, i;
          if (cmd === 1) {
            for (i = 0; i < count; i++) {
              x += fr.svarint(); y += fr.svarint();
              if (cur && cur.length) out.push(cur);
              cur = [[x, y]];
            }
          } else if (cmd === 2) {
            for (i = 0; i < count; i++) {
              x += fr.svarint(); y += fr.svarint();
              if (cur) cur.push([x, y]);
            }
          } else if (cmd === 7) {
            if (cur && cur.length) cur.push([cur[0][0], cur[0][1]]);
          }
        }
        if (cur && cur.length) out.push(cur);
        return out;
      }
      fr.skip(w);
    }
    return [];
  }

  function decode(bytes) {
    var r = new Reader(bytes), out = {};
    while (r.pos < r.end) {
      var key = r.varint(), tag = key >> 3, wire = key & 7;
      if (tag === 3 && wire === 2) {
        var L = readLayer(r.bytes());
        for (var i = 0; i < L.features.length; i++) {
          var f = L.features[i];
          f.geom = readFeatureGeometry(f._raw);
          delete f._raw;
        }
        out[L.name] = L;
      } else r.skip(wire);
    }
    return out;
  }

  global.MVT = { decode: decode };
})(typeof window !== 'undefined' ? window : this);
