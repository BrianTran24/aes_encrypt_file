import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'aes_encrypt_file_method_channel.dart';

abstract class AesEncryptFilePlatform extends PlatformInterface {
  /// Constructs a AesEncryptFilePlatform.
  AesEncryptFilePlatform() : super(token: _token);

  static final Object _token = Object();

  static AesEncryptFilePlatform _instance = MethodChannelAesEncryptFile();

  /// The default instance of [AesEncryptFilePlatform] to use.
  ///
  /// Defaults to [MethodChannelAesEncryptFile].
  static AesEncryptFilePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AesEncryptFilePlatform] when
  /// they register themselves.
  static set instance(AesEncryptFilePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Encrypts the file at [inputPath] and writes the result to [outputPath].
  Future<bool> encryptFile({required String inputPath, required String outputPath, required String key, String? iv});

  /// Decrypts the file at [inputPath] and writes the result to [outputPath].
  Future<bool> decryptFile({required String inputPath, required String outputPath, required String key, String? iv});

  /// Encrypts [plainBytes] and returns `[16-byte IV][ciphertext]`.
  ///
  /// When [iv] is provided it is used as the IV; otherwise a random IV is
  /// generated.  The IV is always prepended to the returned bytes so that
  /// [decryptBytes] can reconstruct it without out-of-band information.
  Future<Uint8List> encryptBytes({required Uint8List plainBytes, required String key, String? iv});

  /// Decrypts [cipherBytes] (format: `[16-byte IV][ciphertext]`) and returns
  /// the original plaintext.
  ///
  /// When [iv] is provided it is used as the IV and the first 16 bytes of
  /// [cipherBytes] are still skipped (they were written by [encryptBytes]).
  Future<Uint8List> decryptBytes({required Uint8List cipherBytes, required String key, String? iv});

}
