import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'aes_encrypt_file_platform_interface.dart';

/// An implementation of [AesEncryptFilePlatform] that uses method channels.
class MethodChannelAesEncryptFile extends AesEncryptFilePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('aes_encrypt_file');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> decryptFile({required String inputPath, required String outputPath, required String key, String? iv}) async{
    try {
      final Map<String, dynamic> args = {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'key': key,
      };
      if (iv != null) {
        args['iv'] = iv;
      }
      final bool result = await methodChannel.invokeMethod('decryptFile', args);
      return result;
    } on PlatformException catch (e) {
      print('Decryption failed: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> encryptFile({required String inputPath, required String outputPath, required String key, String? iv}) async{
    try {
      final Map<String, dynamic> args = {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'key': key,
      };
      if (iv != null) {
        args['iv'] = iv;
      }
      final bool result = await methodChannel.invokeMethod('encryptFile', args);
      return result;
    } on PlatformException catch (e) {
      print('Encryption failed: ${e.message}');
      return false;
    }
    throw UnimplementedError();
  }

  @override
  Future<int> getFileSize(String path) async{
    try {
      final int size = await methodChannel.invokeMethod('getFileSize', path);
      return size;
    } on PlatformException catch (e) {
      print('Get file size failed: ${e.message}');
      return -1;
    }
  }
}
