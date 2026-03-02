import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'aes_encrypt_file_platform_interface.dart';
import 'src/crypto_utils.dart';

/// An implementation of [AesEncryptFilePlatform] that uses method channels.
class MethodChannelAesEncryptFile extends AesEncryptFilePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('aes_encrypt_file');


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
    } on PlatformException {
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
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<Uint8List> encryptBytes({
    required Uint8List plainBytes,
    required String key,
    String? iv,
  }) async {
    try {
      final keyBytes = prepareKey(key);
      final ivBytes = iv != null ? prepareIv(iv) : randomIv();
      final ciphertext = aesCtrCrypt(plainBytes, keyBytes, ivBytes);
      // Prepend the 16-byte IV — identical to the native file format.
      final output = Uint8List(16 + ciphertext.length);
      output.setRange(0, 16, ivBytes);
      output.setRange(16, output.length, ciphertext);
      return output;
    } catch (e, st) {
      dev.log('encryptBytes failed: $e', name: 'MethodChannelAesEncryptFile', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<Uint8List> decryptBytes({
    required Uint8List cipherBytes,
    required String key,
    String? iv,
  }) async {
    try {
      final keyBytes = prepareKey(key);
      final Uint8List ivBytes;
      final Uint8List data;
      if (iv != null) {
        ivBytes = prepareIv(iv);
        data = cipherBytes.sublist(16);
      } else {
        ivBytes = cipherBytes.sublist(0, 16);
        data = cipherBytes.sublist(16);
      }
      return aesCtrCrypt(data, keyBytes, ivBytes);
    } catch (e, st) {
      dev.log('decryptBytes failed: $e', name: 'MethodChannelAesEncryptFile', error: e, stackTrace: st);
      rethrow;
    }
  }

}
