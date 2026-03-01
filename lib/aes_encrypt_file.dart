
import 'dart:typed_data';

import 'aes_encrypt_file_platform_interface.dart';

class AesEncryptFile {

   Future<bool> encryptFile({
    required String inputPath,
    required String outputPath,
    required String key,
    String? iv,
  }) {
    return AesEncryptFilePlatform.instance.encryptFile(
      inputPath: inputPath,
      outputPath: outputPath,
      key: key,
      iv: iv,
    );
  }

  Future<bool> decryptFile({
    required String inputPath,
    required String outputPath,
    required String key,
    String? iv,
  }) {
    return AesEncryptFilePlatform.instance.decryptFile(
      inputPath: inputPath,
      outputPath: outputPath,
      key: key,
      iv: iv,
    );
  }

  /// Encrypts [plainBytes] and returns `[16-byte IV][ciphertext]`.
  ///
  /// Works on all platforms: WebCrypto on web, PointyCastle (pure Dart)
  /// on Android/iOS.  Output is wire-compatible with [encryptFile].
  Future<Uint8List> encryptBytes({
    required Uint8List plainBytes,
    required String key,
    String? iv,
  }) {
    return AesEncryptFilePlatform.instance.encryptBytes(
      plainBytes: plainBytes,
      key: key,
      iv: iv,
    );
  }

  /// Decrypts [cipherBytes] (format: `[16-byte IV][ciphertext]`) and returns
  /// the original plaintext.
  ///
  /// Works on all platforms: WebCrypto on web, PointyCastle (pure Dart)
  /// on Android/iOS.  Accepts ciphertext produced by [encryptBytes] or
  /// [encryptFile].
  Future<Uint8List> decryptBytes({
    required Uint8List cipherBytes,
    required String key,
    String? iv,
  }) {
    return AesEncryptFilePlatform.instance.decryptBytes(
      cipherBytes: cipherBytes,
      key: key,
      iv: iv,
    );
  }

}
