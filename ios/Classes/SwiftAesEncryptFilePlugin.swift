import Flutter
import UIKit

// This file exists to ensure proper Objective-C/Swift interoperability
// The actual plugin implementation is in AesEncryptFilePlugin.m
public class SwiftAesEncryptFilePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Delegate to the Objective-C implementation
    AesEncryptFilePlugin.register(with: registrar)
  }
}
