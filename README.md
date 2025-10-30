# AES Encrypt File

A high-performance Flutter plugin for AES-256 file encryption and decryption, optimized with native C/C++ implementations for maximum speed and efficiency.

## 🚀 Features

- **High Performance**: Native C/C++ implementation using OpenSSL (Android) and CommonCrypto (iOS)
- **AES-256-CTR Encryption**: Industry-standard encryption with Counter mode
- **Large File Support**: Optimized with 256KB buffer for efficient processing of large files
- **Low Memory Footprint**: Streaming encryption/decryption without loading entire files into memory
- **Cross-Platform**: Full support for Android and iOS
- **Simple API**: Easy-to-use Flutter interface for encryption and decryption operations

## 📊 Performance

### Key Performance Characteristics

- **Algorithm**: AES-256-CTR (Counter mode)
- **Buffer Size**: 256KB for optimal I/O performance
- **Memory Usage**: Low and consistent - processes files in chunks
- **Speed**: Native C implementation provides significant performance advantages over pure Dart

### Benchmark Results

Based on the example app with real-world testing:

| File Size | Operation | Time (Typical) | Memory Peak Increase |
|-----------|-----------|----------------|---------------------|
| 10 MB     | Encrypt   | ~100-200ms     | < 5 MB              |
| 10 MB     | Decrypt   | ~100-200ms     | < 5 MB              |
| 100 MB    | Encrypt   | ~1-2s          | < 10 MB             |
| 100 MB    | Decrypt   | ~1-2s          | < 10 MB             |

*Note: Actual performance varies based on device hardware and file characteristics*

### Why Native C Implementation?

- **Speed**: 3-10x faster than pure Dart implementations
- **Memory Efficiency**: Streaming approach with fixed buffer size
- **Battle-tested Libraries**: Uses OpenSSL (Android) and CommonCrypto (iOS)
- **Compiler Optimizations**: -O3 optimization level for maximum performance

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  aes_encrypt_file: ^0.0.4
```

Then run:

```bash
flutter pub get
```

## 🔧 Usage

### Basic Encryption

```dart
import 'package:aes_encrypt_file/aes_encrypt_file.dart';

final aesEncryptFile = AesEncryptFile();

// Encrypt a file
final success = await aesEncryptFile.encryptFile(
  inputPath: '/path/to/input/file.mp4',
  outputPath: '/path/to/output/encrypted_file.mp4',
  key: 'mySecretKey12345',
  iv: 'mySecretIV',  // Optional: if not provided, random IV will be generated
);

if (success) {
  print('File encrypted successfully!');
}
```

### Basic Decryption

```dart
import 'package:aes_encrypt_file/aes_encrypt_file.dart';

final aesEncryptFile = AesEncryptFile();

// Decrypt a file
final success = await aesEncryptFile.decryptFile(
  inputPath: '/path/to/encrypted_file.mp4',
  outputPath: '/path/to/decrypted_file.mp4',
  key: 'mySecretKey12345',
  iv: 'mySecretIV',  // Optional: uses IV from encrypted file if not provided
);

if (success) {
  print('File decrypted successfully!');
}
```

### Complete Example with Error Handling

```dart
import 'dart:io';
import 'package:aes_encrypt_file/aes_encrypt_file.dart';
import 'package:path_provider/path_provider.dart';

Future<void> encryptVideoExample() async {
  final aesEncryptFile = AesEncryptFile();
  
  try {
    // Get app directory
    final directory = await getApplicationDocumentsDirectory();
    final inputPath = '${directory.path}/original_video.mp4';
    final encryptedPath = '${directory.path}/encrypted_video.mp4';
    
    // Check if input file exists
    if (!await File(inputPath).exists()) {
      print('Input file does not exist');
      return;
    }
    
    // Encrypt the file
    final stopwatch = Stopwatch()..start();
    final success = await aesEncryptFile.encryptFile(
      inputPath: inputPath,
      outputPath: encryptedPath,
      key: 'mySecretKey12345',
      iv: 'mySecretIV',
    );
    stopwatch.stop();
    
    if (success) {
      final encryptedFile = File(encryptedPath);
      final fileSize = await encryptedFile.length();
      print('Encryption successful!');
      print('Time: ${stopwatch.elapsedMilliseconds}ms');
      print('Encrypted file size: $fileSize bytes');
      print('Saved to: $encryptedPath');
    } else {
      print('Encryption failed');
    }
  } catch (e) {
    print('Error during encryption: $e');
  }
}
```

### Monitoring Performance

```dart
import 'dart:io';
import 'package:aes_encrypt_file/aes_encrypt_file.dart';

Future<void> encryptWithMonitoring() async {
  final aesEncryptFile = AesEncryptFile();
  
  // Monitor time
  final stopwatch = Stopwatch()..start();
  
  // Monitor memory (if available on platform)
  final startMemory = ProcessInfo.currentRss;
  
  final success = await aesEncryptFile.encryptFile(
    inputPath: '/path/to/input.mp4',
    outputPath: '/path/to/output.mp4',
    key: 'mySecretKey12345',
  );
  
  stopwatch.stop();
  final endMemory = ProcessInfo.currentRss;
  
  if (success) {
    print('Time: ${stopwatch.elapsedMilliseconds}ms');
    print('Memory used: ${(endMemory - startMemory) / 1024 / 1024} MB');
  }
}
```

## 🔑 Key Management

### Key Requirements

- **Key Length**: The plugin accepts keys of any length:
  - If key is exactly 32 bytes: used as-is
  - If key is less than 32 bytes: padded with zeros
  - If key is more than 32 bytes: SHA-256 hash is used
  
- **IV (Initialization Vector)**: Optional parameter
  - If provided: must be a string (automatically processed to 16 bytes)
  - If not provided: random IV is generated and stored in the encrypted file

### Security Best Practices

```dart
// ❌ BAD: Hardcoded keys
const key = 'mySecretKey12345';

// ✅ GOOD: Generate secure random key
import 'dart:math';
import 'dart:convert';

String generateSecureKey() {
  final random = Random.secure();
  final values = List<int>.generate(32, (i) => random.nextInt(256));
  return base64.encode(values);
}

// ✅ GOOD: Store keys securely
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'encryption_key', value: generateSecureKey());
final key = await storage.read(key: 'encryption_key');
```

## 🏗️ Architecture

### Native Implementation

**Android**: 
- Uses OpenSSL library for AES encryption
- Compiled with -O3 optimization for maximum performance
- JNI wrapper for Flutter integration

**iOS**:
- Uses CommonCrypto framework (built into iOS)
- Compiled with -O3 optimization
- Objective-C bridge for Flutter integration

### Encryption Process

1. **Key Preparation**: Input key is processed to 32 bytes (AES-256)
2. **IV Handling**: Either use provided IV or generate random IV
3. **File Processing**: Read input file in 256KB chunks
4. **Encryption**: AES-256-CTR mode encryption on each chunk
5. **Output**: Write encrypted data to output file (IV prepended if generated)

## 📱 Platform Support

| Platform | Supported | Implementation |
|----------|-----------|----------------|
| Android  | ✅        | OpenSSL (C)    |
| iOS      | ✅        | CommonCrypto (C) |
| Web      | ❌        | Not supported  |
| Desktop  | ❌        | Not yet supported |

### iOS Build Configuration

This plugin works **without CocoaPods** on Flutter 3.24+ (Swift Package Manager support). For Flutter versions < 3.24, the plugin includes a `.podspec` file for backwards compatibility. The plugin has no external dependencies and uses only built-in iOS frameworks (CommonCrypto for encryption, Security for random number generation).

## 🔍 API Reference

### `AesEncryptFile`

Main class for encryption and decryption operations.

#### `encryptFile`

Encrypts a file using AES-256-CTR.

```dart
Future<bool> encryptFile({
  required String inputPath,
  required String outputPath,
  required String key,
  String? iv,
})
```

**Parameters:**
- `inputPath` (required): Path to the file to encrypt
- `outputPath` (required): Path where encrypted file will be saved
- `key` (required): Encryption key (any length, processed to 32 bytes)
- `iv` (optional): Initialization vector (any length, processed to 16 bytes)

**Returns:** `true` if encryption succeeds, `false` otherwise

#### `decryptFile`

Decrypts a file that was encrypted with AES-256-CTR.

```dart
Future<bool> decryptFile({
  required String inputPath,
  required String outputPath,
  required String key,
  String? iv,
})
```

**Parameters:**
- `inputPath` (required): Path to the encrypted file
- `outputPath` (required): Path where decrypted file will be saved
- `key` (required): Decryption key (must match encryption key)
- `iv` (optional): Initialization vector (if not provided, reads from file)

**Returns:** `true` if decryption succeeds, `false` otherwise

## 🛠️ Advanced Configuration

### Buffer Size Optimization

The plugin uses a 256KB buffer by default, which is optimized for most use cases. If you need to modify this for specific requirements, you can fork the repository and adjust the `BUFFER_SIZE` constant in the native code:

```c
// android/src/main/cpp/crypto_engine.c
// ios/Classes/crypto_engine.c
#define BUFFER_SIZE (256 * 1024)  // Adjust as needed
```

## ❓ FAQ

**Q: What encryption algorithm is used?**  
A: AES-256 in CTR (Counter) mode.

**Q: Can I encrypt files larger than available RAM?**  
A: Yes! The plugin uses streaming encryption with a fixed buffer size, so memory usage is constant regardless of file size.

**Q: Is it compatible with other AES implementations?**  
A: Yes, as long as they use AES-256-CTR with the same key and IV handling.

**Q: Why is the encrypted file slightly larger?**  
A: The IV (16 bytes) is prepended to the encrypted file when auto-generated.

**Q: Can I use this for real-time encryption?**  
A: Yes, the native implementation is fast enough for real-time use cases.

## 📄 License

This project is licensed under the BSD-3-Clause License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🐛 Issues

If you encounter any issues, please file them on the [GitHub issue tracker](https://github.com/BrianTran24/aes_encrypt_file/issues).

## 📚 Additional Resources

- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [CommonCrypto Documentation](https://developer.apple.com/documentation/security/commoncrypto)
- [AES Encryption Standard](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)
- [CTR Mode Overview](https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Counter_(CTR))
