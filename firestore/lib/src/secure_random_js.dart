import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

/// The crypto object read on `globalThis`.
@JS('globalThis.crypto')
external _Crypto? get _globalCrypto;

extension type _Crypto._(JSObject _) implements JSObject {
  external JSAny getRandomValues(JSTypedArray array);
}

/// A cryptographically secure random generator.
///
/// [Random.secure] in dart2js reads `self.crypto`, which throws in node
/// ("Value of "this" must be of type nullish or must be the global object"):
/// the node preamble (dart test -p node, build_node) makes `self` an
/// `Object.create(globalThis)` and the node `crypto` getter rejects it. The
/// same crypto object is then read on `globalThis`.
Random newSecureRandom() {
  try {
    return Random.secure();
  } catch (_) {
    var crypto = _globalCrypto;
    if (crypto == null) {
      rethrow;
    }
    return _GlobalCryptoRandom(crypto);
  }
}

/// 2^32, `1 << 32` is 0 on the web.
const _uint32Range = 0x100000000;

/// Random from `crypto.getRandomValues`.
class _GlobalCryptoRandom implements Random {
  _GlobalCryptoRandom(this._crypto);

  final _Crypto _crypto;

  int _nextUint32() {
    var values = Uint32List(1).toJS;
    _crypto.getRandomValues(values);
    return values.toDart[0];
  }

  @override
  int nextInt(int max) {
    if (max < 1 || max > _uint32Range) {
      throw RangeError.range(max, 1, _uint32Range, 'max');
    }
    // Rejection sampling, no modulo bias.
    var limit = _uint32Range - _uint32Range % max;
    while (true) {
      var value = _nextUint32();
      if (value < limit) {
        return value % max;
      }
    }
  }

  @override
  bool nextBool() => nextInt(2) == 0;

  /// 53 random bits (26 + 27).
  @override
  double nextDouble() =>
      (nextInt(1 << 26) * 134217728 + nextInt(1 << 27)) / 9007199254740992;
}
