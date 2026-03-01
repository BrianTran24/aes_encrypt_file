import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

const _kKeyLength = 32;
const _kIvLength = 16;

/// Prepares a 32-byte AES-256 key from [key], matching the native logic:
/// - exactly 32 bytes → use as-is
/// - < 32 bytes       → zero-pad to 32 bytes
/// - > 32 bytes       → SHA-256 hash
Uint8List prepareKey(String key) {
  final bytes = utf8.encode(key);
  if (bytes.length == _kKeyLength) return Uint8List.fromList(bytes);
  if (bytes.length < _kKeyLength) {
    final padded = Uint8List(_kKeyLength);
    padded.setRange(0, bytes.length, bytes);
    return padded;
  }
  return Uint8List.fromList(sha256.convert(bytes).bytes);
}

/// Prepares a 16-byte IV from [iv], matching the native logic:
/// - exactly 16 bytes → use as-is
/// - < 16 bytes       → zero-pad to 16 bytes
/// - > 16 bytes       → first 16 bytes of SHA-256 hash
Uint8List prepareIv(String iv) {
  final bytes = utf8.encode(iv);
  if (bytes.length == _kIvLength) return Uint8List.fromList(bytes);
  if (bytes.length < _kIvLength) {
    final padded = Uint8List(_kIvLength);
    padded.setRange(0, bytes.length, bytes);
    return padded;
  }
  return Uint8List.fromList(sha256.convert(bytes).bytes.sublist(0, _kIvLength));
}

// Single shared secure-random instance — avoids repeated construction cost.
final _random = Random.secure();

/// Generates a cryptographically random 16-byte IV.
Uint8List randomIv() {
  return Uint8List.fromList(List.generate(_kIvLength, (_) => _random.nextInt(256)));
}

/// AES-256-CTR encrypt/decrypt using PointyCastle (pure Dart).
///
/// AES-CTR is symmetric — the same function is used for both encryption
/// and decryption.  Output length equals input length (stream cipher, no
/// padding).
Uint8List aesCtrCrypt(Uint8List input, Uint8List key, Uint8List iv) {
  final cipher = SICStreamCipher(AESEngine());
  cipher.init(true, ParametersWithIV(KeyParameter(key), iv));
  final output = Uint8List(input.length);
  cipher.processBytes(input, 0, input.length, output, 0);
  return output;
}
