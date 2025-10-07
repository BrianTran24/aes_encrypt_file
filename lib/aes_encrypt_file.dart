
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


}
