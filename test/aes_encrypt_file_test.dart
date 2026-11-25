import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:aes_encrypt_file/aes_encrypt_file.dart';
import 'package:aes_encrypt_file/aes_encrypt_file_platform_interface.dart';
import 'package:aes_encrypt_file/aes_encrypt_file_method_channel.dart';

void main() {
  final AesEncryptFilePlatform initialPlatform = AesEncryptFilePlatform.instance;

  test('$MethodChannelAesEncryptFile is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAesEncryptFile>());
  });

  test('encryptBytes and decryptBytes roundtrip', () async {
    final plugin = AesEncryptFile();
    final plain = Uint8List.fromList('Hello AES-256-CTR'.codeUnits);
    final encrypted = await plugin.encryptBytes(
      plainBytes: plain,
      key: 'mySecretKey12345',
    );
    expect(encrypted.length, plain.length + 16);

    final decrypted = await plugin.decryptBytes(
      cipherBytes: encrypted,
      key: 'mySecretKey12345',
    );
    expect(decrypted, plain);
  });
}
