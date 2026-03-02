import 'dart:typed_data';

/// Abstract base class for AES encryption/decryption on bytes.
abstract class AesCryptoBase {
  /// Encrypts [plainBytes] using AES-256-CTR with the given [keyBytes] and
  /// [ivBytes].  Returns the raw ciphertext (without an IV prefix).
  Future<Uint8List> encryptBytes(
    Uint8List plainBytes,
    Uint8List keyBytes,
    Uint8List ivBytes,
  );

  /// Decrypts [cipherBytes] using AES-256-CTR with the given [keyBytes] and
  /// [ivBytes].  [cipherBytes] must not include the IV prefix.
  Future<Uint8List> decryptBytes(
    Uint8List cipherBytes,
    Uint8List keyBytes,
    Uint8List ivBytes,
  );
}
