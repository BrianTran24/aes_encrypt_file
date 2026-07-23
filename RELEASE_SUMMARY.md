# Summary of Changes for v0.0.13 Release

## Major Features

### 1. macOS Support
- Implemented native AES-256-CTR encryption/decryption using Apple's **CommonCrypto** framework.
- High-performance C engine shared with iOS for consistency.

### 2. Windows Support
- Implemented native AES-256-CTR encryption/decryption using Windows **BCrypt** (CNG) API.
- Native C++ implementation with optimized file streaming.

## Files Modified

### 1. **pubspec.yaml**
- ✅ Bumped version to `0.0.13`

### 2. **CHANGELOG.md**
- ✅ Added v0.0.13 release notes documenting macOS and Windows support.

### 3. **ios/aes_encrypt_file.podspec** & **macos/aes_encrypt_file.podspec**
- ✅ Updated versions to `0.0.13` to match the package version.

### 4. **README.md**
- ✅ Updated installation version to `^0.0.13`.
- ✅ Updated Platform Support matrix to include macOS and Windows.
- ✅ Added Architecture details for macOS (CommonCrypto) and Windows (BCrypt).

## Validation Results

✅ **Dart Analyze**: No errors or warnings
✅ **Pub Validation**: Dry-run verification passed
✅ **Native Build**: macOS and Windows implementations verified in example app

## Breaking Changes
None.

## Dependencies
No new external dependencies. Windows implementation uses system `bcrypt.lib`.
