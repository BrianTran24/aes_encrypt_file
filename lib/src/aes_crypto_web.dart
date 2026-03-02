import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'aes_crypto_base.dart';

// ---------------------------------------------------------------------------
// JS interop bindings for window.crypto.subtle (WebCrypto)
// ---------------------------------------------------------------------------

/// Opaque handle to a CryptoKey returned by importKey.
extension type CryptoKey._(JSObject _) implements JSObject {}

/// SubtleCrypto interface exposed by window.crypto.subtle.
extension type SubtleCrypto._(JSObject _) implements JSObject {
  external JSPromise<CryptoKey> importKey(
    JSString format,
    JSObject keyData,
    JSObject algorithm,
    JSBoolean extractable,
    JSArray<JSString> keyUsages,
  );

  external JSPromise<JSArrayBuffer> encrypt(
    JSObject algorithm,
    CryptoKey key,
    JSObject data,
  );

  external JSPromise<JSArrayBuffer> decrypt(
    JSObject algorithm,
    CryptoKey key,
    JSObject data,
  );
}

/// window.crypto
extension type Crypto._(JSObject _) implements JSObject {
  external SubtleCrypto get subtle;
}

@JS('crypto')
external Crypto get _jsCrypto;

// ---------------------------------------------------------------------------
// Helper: build the AES-CTR algorithm objects using dart:js_interop_unsafe
// ---------------------------------------------------------------------------

/// Builds the AES-CTR WebCrypto algorithm descriptor.
///
/// [counter] is the 16-byte initial counter value (= the IV used by the
/// native AES-256-CTR implementation on Android/iOS).  [length] 128 means
/// the full 128-bit block is used as the counter, matching OpenSSL's CTR
/// mode behaviour.
JSObject _aesCtrAlgorithm(Uint8List counter) {
  final obj = JSObject();
  obj.setProperty('name'.toJS, 'AES-CTR'.toJS);
  obj.setProperty('counter'.toJS, counter.toJS);
  obj.setProperty('length'.toJS, 128.toJS);
  return obj;
}

JSObject _aesCtrKeyAlgorithm() {
  final obj = JSObject();
  obj.setProperty('name'.toJS, 'AES-CTR'.toJS);
  return obj;
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

/// Flutter Web AES-CTR implementation backed by `window.crypto.subtle`.
///
/// Uses the browser's native WebCrypto engine and is wire-compatible with
/// the native AES-256-CTR implementation used on Android and iOS (OpenSSL /
/// CommonCrypto), given the same key and IV.
class AesCryptoImpl extends AesCryptoBase {
  @override
  Future<Uint8List> encryptBytes(
    Uint8List plainBytes,
    Uint8List keyBytes,
    Uint8List ivBytes,
  ) async {
    final key = await _importKey(keyBytes, ['encrypt']);
    final algorithm = _aesCtrAlgorithm(ivBytes);
    final cipherBuffer =
        await _jsCrypto.subtle.encrypt(algorithm, CryptoKey._(key), plainBytes.toJS).toDart;
    return cipherBuffer.toDart.asUint8List();
  }

  @override
  Future<Uint8List> decryptBytes(
    Uint8List cipherBytes,
    Uint8List keyBytes,
    Uint8List ivBytes,
  ) async {
    final key = await _importKey(keyBytes, ['decrypt']);
    final algorithm = _aesCtrAlgorithm(ivBytes);
    final plainBuffer =
        await _jsCrypto.subtle.decrypt(algorithm, CryptoKey._(key), cipherBytes.toJS).toDart;
    return plainBuffer.toDart.asUint8List();
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Future<JSObject> _importKey(Uint8List keyBytes, List<String> usages) async {
    final algorithm = _aesCtrKeyAlgorithm();
    final usagesJs = <JSString>[for (final u in usages) u.toJS].toJS;
    return _jsCrypto.subtle
        .importKey(
          'raw'.toJS,
          keyBytes.toJS,
          algorithm,
          false.toJS,
          usagesJs,
        )
        .toDart;
  }
}
