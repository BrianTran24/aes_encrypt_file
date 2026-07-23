# Publishing Guide for aes_encrypt_file v0.0.13

## Prerequisites

1. **Pub.dev Account**: Create an account at [pub.dev](https://pub.dev)
2. **Authentication**: Configure credentials using:
   ```bash
   dart pub token add https://pub.dev
   ```

## Steps to Publish

### 1. Verify Everything is Ready

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

## What's Included in v0.0.11

### Added
- Comprehensive README documentation with API reference and examples
- Performance benchmarking information and guidelines
- Advanced configuration guide for buffer size optimization
- FAQ section addressing common questions
- Contributing and issue reporting guidelines
- Detailed architecture documentation
- Security best practices guide for key management

### Changed
- Improved project description in pubspec.yaml
- Enhanced documentation URLs in pubspec.yaml
- Refined API documentation for better clarity
- Updated SDK constraint to ^3.3.0 for inline-class support

### Fixed
- Documentation formatting and structure
- Type handling in web implementation
- Unnecessary imports

## Package Contents

- **Native Implementation**: C/C++ encryption engines for Android (OpenSSL) and iOS (CommonCrypto)
- **Web Support**: Pure Dart implementation using PointyCastle for web platform
- **High Performance**: 256KB buffer for efficient large file handling
- **Cross-platform**: Full support for Android, iOS, and Web

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
│   └── src/main/cpp/ (Native C code + OpenSSL binaries)
├── ios/
│   └── Classes/ (Native Objective-C + CommonCrypto bridge)
├── pubspec.yaml (Package configuration)
├── README.md (Full documentation)
├── CHANGELOG.md (Version history)
└── LICENSE (MIT License)
```

The following are excluded via `.pubignore`:
- Build artifacts and cache files
- IDE configuration files
- Example app
- Git configuration

## After Publishing

1. Tag the release in Git:
   ```bash
   git tag v0.0.13
   git push origin v0.0.13
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
Update the version in pubspec.yaml and try again.

