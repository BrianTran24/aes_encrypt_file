// import 'package:flutter_test/flutter_test.dart';
// import 'package:aes_encrypt_file/aes_encrypt_file.dart';
// import 'package:aes_encrypt_file/aes_encrypt_file_platform_interface.dart';
// import 'package:aes_encrypt_file/aes_encrypt_file_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockAesEncryptFilePlatform
//     with MockPlatformInterfaceMixin
//     implements AesEncryptFilePlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final AesEncryptFilePlatform initialPlatform = AesEncryptFilePlatform.instance;
//
//   test('$MethodChannelAesEncryptFile is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelAesEncryptFile>());
//   });
//
//   test('getPlatformVersion', () async {
//     AesEncryptFile aesEncryptFilePlugin = AesEncryptFile();
//     MockAesEncryptFilePlatform fakePlatform = MockAesEncryptFilePlatform();
//     AesEncryptFilePlatform.instance = fakePlatform;
//
//     expect(await aesEncryptFilePlugin.getPlatformVersion(), '42');
//   });
// }
