import Flutter
import UIKit

// Swift wrapper needed because modern Flutter iOS projects use Swift by default
// and require Swift plugin registration to avoid MissingPluginException.
// This class delegates to the Objective-C implementation in AesEncryptFilePlugin.m
// which contains the actual encryption logic using CommonCrypto.
public class SwiftAesEncryptFilePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Create method channel with the same name
    let channel = FlutterMethodChannel(name: "aes_encrypt_file", binaryMessenger: registrar.messenger())
    // Create instance of the Objective-C plugin and register it as the method call handler
    let instance = AesEncryptFilePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
}
