import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'aes_encrypt_file_platform_interface.dart';
import 'src/aes_crypto_web.dart';

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
      final keyBytes = _prepareKey(key);
      final ivBytes = iv != null ? _prepareIv(iv) : _randomIv();

      final encryptedBytes =
          await _crypto.encryptBytes(inputBytes, keyBytes, ivBytes);

      // Prepend the 16-byte IV to the ciphertext — identical to the native
      // format written by the Android/iOS implementations.
      final output = Uint8List(16 + encryptedBytes.length);
      output.setRange(0, 16, ivBytes);
      output.setRange(16, output.length, encryptedBytes);

      _virtualFileSystem[outputPath] = output;
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
      final keyBytes = _prepareKey(key);

      final Uint8List ivBytes;
      final Uint8List cipherBytes;

      if (iv != null) {
        // Derive IV from the provided string; skip the 16-byte header that
        // was written during encryption (matching native behaviour).
        ivBytes = _prepareIv(iv);
        cipherBytes = inputBytes.sublist(16);
      } else {
        // Read IV from the first 16 bytes of the file.
        ivBytes = inputBytes.sublist(0, 16);
        cipherBytes = inputBytes.sublist(16);
      }

      final decryptedBytes =
          await _crypto.decryptBytes(cipherBytes, keyBytes, ivBytes);

      _virtualFileSystem[outputPath] = decryptedBytes;
      return true;
    } catch (e, st) {
      dev.log('decryptFile failed: $e', name: 'AesEncryptFileWeb', error: e, stackTrace: st);
      return false;
    }
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

  /// Prepares a 32-byte AES key from [key], matching the native logic:
  /// - exactly 32 bytes  → use as-is
  /// - < 32 bytes        → zero-pad to 32 bytes
  /// - > 32 bytes        → SHA-256 hash
  static Uint8List _prepareKey(String key) {
    final bytes = utf8.encode(key);
    if (bytes.length == 32) return Uint8List.fromList(bytes);
    if (bytes.length < 32) {
      final padded = Uint8List(32);
      padded.setRange(0, bytes.length, bytes);
      return padded;
    }
    return Uint8List.fromList(sha256.convert(bytes).bytes);
  }

  /// Prepares a 16-byte IV from [iv], matching the native logic:
  /// - exactly 16 bytes  → use as-is
  /// - < 16 bytes        → zero-pad to 16 bytes
  /// - > 16 bytes        → first 16 bytes of SHA-256 hash
  static Uint8List _prepareIv(String iv) {
    final bytes = utf8.encode(iv);
    if (bytes.length == 16) return Uint8List.fromList(bytes);
    if (bytes.length < 16) {
      final padded = Uint8List(16);
      padded.setRange(0, bytes.length, bytes);
      return padded;
    }
    return Uint8List.fromList(sha256.convert(bytes).bytes.sublist(0, 16));
  }

  /// Generates a cryptographically random 16-byte IV.
  static Uint8List _randomIv() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
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
