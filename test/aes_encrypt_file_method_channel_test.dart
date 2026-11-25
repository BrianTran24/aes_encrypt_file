import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aes_encrypt_file/aes_encrypt_file_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelAesEncryptFile platform = MethodChannelAesEncryptFile();
  const MethodChannel channel = MethodChannel('aes_encrypt_file');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('encryptFile invokes method channel', () async {
    expect(
      await platform.encryptFile(
        inputPath: 'in.txt',
        outputPath: 'out.aes',
        key: 'secret',
      ),
      isTrue,
    );
  });
}
