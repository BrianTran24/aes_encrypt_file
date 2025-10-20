import Flutter
import UIKit

// Swift wrapper needed because modern Flutter iOS projects use Swift by default
// and require Swift plugin registration to avoid MissingPluginException.
// This class delegates to the Objective-C implementation in AesEncryptFilePlugin.m
// which contains the actual encryption logic using CommonCrypto.
public class SwiftAesEncryptFilePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Delegate to the Objective-C implementation
    AesEncryptFilePlugin.register(with: registrar)
  }
}
