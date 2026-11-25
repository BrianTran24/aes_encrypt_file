# Summary of Changes for v0.0.14 Release

## Major Features

### 1. Swift Package Manager (SPM) Support for iOS
- Added `ios/aes_encrypt_file/Package.swift` for Flutter Swift Package Manager integration.
- Restructured iOS sources into `ios/aes_encrypt_file/Sources/aes_encrypt_file` (Swift plugin) and `ios/aes_encrypt_file/Sources/aes_encrypt_file_c` (native CommonCrypto C engine).
- Maintained backward compatibility with CocoaPods via `ios/aes_encrypt_file.podspec`.

### 2. Documentation & Metadata Improvements
- Updated `README.md` to reflect all supported platforms (Android, iOS, macOS, Windows, Web), SPM support, updated file paths, and MIT License.
- Updated `PUBLISH_GUIDE.md` and excluded internal markdown guides from pub.dev archive via `.pubignore`.

## Files Modified

### 1. **pubspec.yaml**
- ✅ Bumped version to `0.0.14`

### 2. **CHANGELOG.md**
- ✅ Added v0.0.14 release notes documenting iOS Swift Package Manager support and documentation updates.

### 3. **ios/aes_encrypt_file.podspec** & **macos/aes_encrypt_file.podspec**
- ✅ Updated versions to `0.0.14` to match the package version.

### 4. **README.md**
- ✅ Updated installation version to `^0.0.14`.
- ✅ Synced feature list and architecture sections with macOS, Windows, and iOS SPM support.
- ✅ Fixed license reference to MIT License.

## Breaking Changes
None.

## Dependencies
No new external dependencies.
