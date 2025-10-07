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



  Future<bool> encryptFile({required String inputPath, required String outputPath, required String key, String? iv});

  Future<bool> decryptFile({required String inputPath, required String outputPath, required String key, String? iv});

}
