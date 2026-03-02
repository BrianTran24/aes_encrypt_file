import 'dart:developer' as dev;
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'aes_encrypt_file_platform_interface.dart';
import 'src/aes_crypto_web.dart';
import 'src/crypto_utils.dart';

/// Flutter Web implementation of [AesEncryptFilePlatform].
///
/// Encryption and decryption use the browser's native WebCrypto engine
/// (AES-256-CTR), producing output that is wire-compatible with the
/// Android (OpenSSL) and iOS (CommonCrypto) native implementations.
///
/// **File I/O on web**
///
/// Because browsers do not expose a writable local filesystem, this
/// implementation maintains an in-memory virtual filesystem
/// (`_virtualFileSystem`).  The caller should:
///
/// * Pre-load source bytes under the desired `inputPath` key via
///   [storeVirtualFile] before calling [encryptFile] / [decryptFile], **or**
/// * Pass a URL (http:/https:/blob:) as `inputPath`; the implementation will
///   fetch the bytes automatically.
///
/// Encrypted / decrypted output is stored in [_virtualFileSystem] under
/// `outputPath`.  Retrieve the bytes with [getVirtualFile].
class AesEncryptFileWeb extends AesEncryptFilePlatform {
  static void registerWith(Registrar registrar) {
    AesEncryptFilePlatform.instance = AesEncryptFileWeb();
  }

  final _crypto = AesCryptoImpl();

  /// In-memory virtual filesystem keyed by the path string.
  static final Map<String, Uint8List> _virtualFileSystem = {};

  /// Stores [bytes] under [path] so they can be used as input to
  /// [encryptFile] or [decryptFile].
  static void storeVirtualFile(String path, Uint8List bytes) {
    _virtualFileSystem[path] = bytes;
  }

  /// Returns the bytes previously written to [path], or `null` if absent.
  static Uint8List? getVirtualFile(String path) {
    return _virtualFileSystem[path];
  }

  // -------------------------------------------------------------------------
  // Platform interface
  // -------------------------------------------------------------------------

  @override
  Future<bool> encryptFile({
    required String inputPath,
    required String outputPath,
    required String key,
    String? iv,
  }) async {
    try {
      final inputBytes = await _readFile(inputPath);
      final encryptedBytes = await encryptBytes(plainBytes: inputBytes, key: key, iv: iv);
      _virtualFileSystem[outputPath] = encryptedBytes;
      return true;
    } catch (e, st) {
      dev.log('encryptFile failed: $e', name: 'AesEncryptFileWeb', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<bool> decryptFile({
    required String inputPath,
    required String outputPath,
    required String key,
    String? iv,
  }) async {
    try {
      final inputBytes = await _readFile(inputPath);
      final decryptedBytes = await decryptBytes(cipherBytes: inputBytes, key: key, iv: iv);
      _virtualFileSystem[outputPath] = decryptedBytes;
      return true;
    } catch (e, st) {
      dev.log('decryptFile failed: $e', name: 'AesEncryptFileWeb', error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<Uint8List> encryptBytes({
    required Uint8List plainBytes,
    required String key,
    String? iv,
  }) async {
    final keyBytes = prepareKey(key);
    final ivBytes = iv != null ? prepareIv(iv) : randomIv();
    final ciphertext = await _crypto.encryptBytes(plainBytes, keyBytes, ivBytes);
    // Prepend the 16-byte IV — identical to the native file format.
    final output = Uint8List(16 + ciphertext.length);
    output.setRange(0, 16, ivBytes);
    output.setRange(16, output.length, ciphertext);
    return output;
  }

  @override
  Future<Uint8List> decryptBytes({
    required Uint8List cipherBytes,
    required String key,
    String? iv,
  }) async {
    final keyBytes = prepareKey(key);
    final Uint8List ivBytes;
    final Uint8List data;
    if (iv != null) {
      // Derive IV from the provided string; skip the 16-byte header that
      // was written during encryption (matching native behaviour).
      ivBytes = prepareIv(iv);
      data = cipherBytes.sublist(16);
    } else {
      // Read IV from the first 16 bytes of the payload.
      ivBytes = cipherBytes.sublist(0, 16);
      data = cipherBytes.sublist(16);
    }
    return _crypto.decryptBytes(data, keyBytes, ivBytes);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Reads bytes for [path].
  ///
  /// Resolution order:
  /// 1. In-memory virtual filesystem.
  /// 2. HTTP / HTTPS / blob fetch via the browser's `fetch` API.
  Future<Uint8List> _readFile(String path) async {
    final cached = _virtualFileSystem[path];
    if (cached != null) return cached;
    return _fetchBytes(path);
  }

  /// Fetches [url] and returns its body as a [Uint8List].
  static Future<Uint8List> _fetchBytes(String url) async {
    final response = await _jsFetch(url.toJS).toDart;
    final buffer = await response.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  }
}

// ---------------------------------------------------------------------------
// JS interop — fetch API
// ---------------------------------------------------------------------------

/// Minimal binding to the browser [Response] object returned by `fetch`.
extension type _Response._(JSObject _) implements JSObject {
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

@JS('fetch')
external JSPromise<_Response> _jsFetch(JSString url);
