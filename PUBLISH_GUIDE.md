# Publishing Guide for aes_encrypt_file v0.0.14

## Prerequisites

1. **Pub.dev Account**: Create an account at [pub.dev](https://pub.dev)
2. **Authentication**: Configure credentials using:
   ```bash
   dart pub token add https://pub.dev
   ```

## Steps to Publish

### 1. Verify Everything is Ready

```bash
# Check for any outstanding issues
flutter pub publish --dry-run
```

Expected output should show:
- `Package has 0 warnings.`
- No analyze errors
- All files ready for publication

### 2. Ensure Git is Clean
```bash
git status
# Should show: "nothing to commit, working tree clean"
```

### 3. Publish to pub.dev
```bash
flutter pub publish
```

This will:
- Validate your package one more time
- Ask for confirmation
- Upload to pub.dev

### 4. Wait for Processing
The package will appear on pub.dev within a few minutes. You can monitor at:
https://pub.dev/packages/aes_encrypt_file

## What's Included in v0.0.14

### Added
- Swift Package Manager (SPM) support for iOS (`ios/aes_encrypt_file/Package.swift`)
- Updated documentation for cross-platform support (Android, iOS, macOS, Windows, Web) and SPM

### Changed
- Migrated iOS plugin layout to Swift Package Manager structure (`ios/aes_encrypt_file/Sources/...`)
- Synced package version to `0.0.14` across `pubspec.yaml` and podspecs
- Fixed license and file path references in `README.md`

## Package Contents

- **Native Implementation**: C/C++ encryption engines for Android (OpenSSL), iOS & macOS (CommonCrypto), and Windows (BCrypt)
- **Web Support**: WebCrypto API / Pure Dart fallback using PointyCastle for web platform
- **High Performance**: 256KB buffer for efficient large file handling
- **Cross-platform**: Full support for Android, iOS, macOS, Windows, and Web

## Files Published

The package publishes the following directory structure:
```
├── lib/
│   ├── aes_encrypt_file.dart (Main API)
│   ├── aes_encrypt_file_method_channel.dart (Platform channel)
│   ├── aes_encrypt_file_platform_interface.dart (Interface)
│   ├── aes_encrypt_file_web.dart (Web implementation)
│   └── src/
│       ├── aes_crypto_base.dart
│       ├── aes_crypto_web.dart
│       └── crypto_utils.dart
├── android/
│   └── src/main/ (Kotlin plugin + Native C code + OpenSSL binaries)
├── ios/
│   ├── aes_encrypt_file.podspec
│   └── aes_encrypt_file/ (Swift Package Manager + Native CommonCrypto C engine)
├── macos/
│   └── aes_encrypt_file.podspec
├── windows/
│   └── Native C++ BCrypt implementation
├── pubspec.yaml (Package configuration)
├── README.md (Full documentation)
├── CHANGELOG.md (Version history)
└── LICENSE (MIT License)
```

The following are excluded via `.pubignore`:
- Build artifacts and cache files
- IDE configuration files
- Example app
- Internal release notes (`PUBLISH_GUIDE.md`, `RELEASE_SUMMARY.md`)
- Git configuration

## After Publishing

1. Tag the release in Git:
   ```bash
   git tag v0.0.14
   git push origin v0.0.14
   ```

2. Update GitHub release notes
3. Announce the release on relevant channels

## Support

- **GitHub**: https://github.com/BrianTran24/aes_encrypt_file
- **Issues**: https://github.com/BrianTran24/aes_encrypt_file/issues
- **Pub.dev**: https://pub.dev/packages/aes_encrypt_file

## Troubleshooting

### "Package has warnings"
Run `flutter pub publish --dry-run` to see what warnings exist and fix them before publishing.

### Authentication errors
Re-authenticate with: `dart pub token add https://pub.dev`

### Version already exists
Update the version in `pubspec.yaml` and try again.
