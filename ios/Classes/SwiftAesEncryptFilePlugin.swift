import Flutter
import UIKit

public class SwiftAesEncryptFilePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Delegate registration to Objective-C implementation
    AesEncryptFilePlugin.register(with: registrar)
  }
}
