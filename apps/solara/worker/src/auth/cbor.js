/**
 * Apple App Attest CBOR subset デコーダ。
 *
 * App Attest が使う CBOR は以下に限定されるので、フル仕様 (RFC 8949) は実装しない:
 *   - major 0: unsigned int (0..2^32-1)
 *   - major 2: byte string (Uint8Array で返す、最大 2^32 bytes)
 *   - major 3: text string (string で返す、UTF-8)
 *   - major 4: array (Array で返す)
 *   - major 5: map (plain object で返す、key は string のみサポート)
 *
 * 不要 (App Attest で出現しない):
 *   - major 1 (negative int) / 6 (tag) / 7 (special: float, true/false, null)
 *   - 2^32 を超える長さの byte/text (App Attest の receipt は ~5KB、cert ~1KB、authData ~200B)
 *   - 8 byte length encoding (additional info 27)
 *
 * Reference implementation: node-app-attest (MIT, Copyright (c) 2024 David Übelacker)
 * https://github.com/uebelack/node-app-attest
 *
 * Buffer 非依存 (Workers 互換、Uint8Array のみ)。
 */

const TEXT_DECODER = new TextDecoder('utf-8', { fatal: true });

/**
 * バイト列から 1 個の CBOR 値を decode し、消費したバイト数とともに返す。
 * 内部実装、外部からは decodeFirst を使う。
 */
function decodeAt(bytes, offset) {
  if (offset >= bytes.length) {
    throw new CborError(`unexpected end of input at offset ${offset}`);
  }
  const initial = bytes[offset];
  const major = initial >> 5;
  const info = initial & 0x1f;

  // additional info → 値の本体 / 長さ
  let arg;
  let cursor;
  if (info < 24) {
    arg = info;
    cursor = offset + 1;
  } else if (info === 24) {
    if (offset + 1 >= bytes.length) throw new CborError('truncated 1-byte length');
    arg = bytes[offset + 1];
    cursor = offset + 2;
  } else if (info === 25) {
    if (offset + 2 >= bytes.length) throw new CborError('truncated 2-byte length');
    arg = (bytes[offset + 1] << 8) | bytes[offset + 2];
    cursor = offset + 3;
  } else if (info === 26) {
    if (offset + 4 >= bytes.length) throw new CborError('truncated 4-byte length');
    // unsigned 32bit, big endian
    arg =
      (bytes[offset + 1] * 0x1000000) +
      ((bytes[offset + 2] << 16) | (bytes[offset + 3] << 8) | bytes[offset + 4]);
    cursor = offset + 5;
  } else {
    // info 27 (8-byte) / 28-30 (reserved) / 31 (indefinite)
    throw new CborError(`unsupported additional info ${info} at offset ${offset}`);
  }

  if (major === 0) {
    return { value: arg, next: cursor };
  }
  if (major === 2) {
    if (cursor + arg > bytes.length) throw new CborError(`byte string overflows input (need ${arg} at ${cursor})`);
    const slice = bytes.slice(cursor, cursor + arg);
    return { value: slice, next: cursor + arg };
  }
  if (major === 3) {
    if (cursor + arg > bytes.length) throw new CborError(`text string overflows input (need ${arg} at ${cursor})`);
    const slice = bytes.subarray(cursor, cursor + arg);
    let str;
    try {
      str = TEXT_DECODER.decode(slice);
    } catch (_err) {
      throw new CborError(`invalid UTF-8 in text string at offset ${cursor}`);
    }
    return { value: str, next: cursor + arg };
  }
  if (major === 4) {
    const arr = new Array(arg);
    let pos = cursor;
    for (let i = 0; i < arg; i++) {
      const { value, next } = decodeAt(bytes, pos);
      arr[i] = value;
      pos = next;
    }
    return { value: arr, next: pos };
  }
  if (major === 5) {
    const obj = {};
    let pos = cursor;
    for (let i = 0; i < arg; i++) {
      const k = decodeAt(bytes, pos);
      if (typeof k.value !== 'string') {
        throw new CborError(`map key is not a string at offset ${pos} (major ${(bytes[pos] >> 5)})`);
      }
      const v = decodeAt(bytes, k.next);
      obj[k.value] = v.value;
      pos = v.next;
    }
    return { value: obj, next: pos };
  }
  throw new CborError(`unsupported major type ${major} at offset ${offset}`);
}

export class CborError extends Error {
  constructor(message) {
    super(message);
    this.name = 'CborError';
  }
}

/**
 * 入力バイト列 (Uint8Array) から最初の CBOR 値を decode して返す。
 * 入力末尾に余分なバイトが残っていた場合はエラーにする (Apple App Attest は単一トップレベル値前提)。
 *
 * @param {Uint8Array} bytes
 * @returns {*} decoded value
 */
export function decodeFirst(bytes) {
  if (!(bytes instanceof Uint8Array)) {
    throw new CborError('input must be Uint8Array');
  }
  const { value, next } = decodeAt(bytes, 0);
  if (next !== bytes.length) {
    throw new CborError(`extra ${bytes.length - next} bytes after top-level CBOR value`);
  }
  return value;
}
