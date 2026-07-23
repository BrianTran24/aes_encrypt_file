import Flutter
import UIKit

public class AesEncryptFilePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "aes_encrypt_file", binaryMessenger: registrar.messenger())
    let instance = AesEncryptFilePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "encryptFile":
      handleEncryptFile(call, result: result)
    case "decryptFile":
      handleDecryptFile(call, result: result)
    case "getFileSize":
      handleGetFileSize(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleEncryptFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let inputPath = args["inputPath"] as? String,
          let outputPath = args["outputPath"] as? String,
          let key = args["key"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required parameters", details: nil))
      return
    }
    let iv = args["iv"] as? String

    DispatchQueue.global(qos: .userInitiated).async {
      let success: Int32
      if let iv = iv, !iv.isEmpty {
        success = crypto_encrypt_file_with_iv(inputPath, outputPath, key, iv)
      } else {
        success = crypto_encrypt_file(inputPath, outputPath, key)
      }

      DispatchQueue.main.async {
        if success == 0 {
          result(true)
        } else {
          result(FlutterError(code: "ENCRYPT_FAILED", message: "Encryption failed with code: \(success)", details: nil))
        }
      }
    }
  }

  private func handleDecryptFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let inputPath = args["inputPath"] as? String,
          let outputPath = args["outputPath"] as? String,
          let key = args["key"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required parameters", details: nil))
      return
    }
    let iv = args["iv"] as? String

    DispatchQueue.global(qos: .userInitiated).async {
      let success: Int32
      if let iv = iv, !iv.isEmpty {
        success = crypto_decrypt_file_with_iv(inputPath, outputPath, key, iv)
      } else {
        success = crypto_decrypt_file(inputPath, outputPath, key)
      }

      DispatchQueue.main.async {
        if success == 0 {
          result(true)
        } else {
          result(FlutterError(code: "DECRYPT_FAILED", message: "Decryption failed with code: \(success)", details: nil))
        }
      }
    }
  }

  private func handleGetFileSize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let path = call.arguments as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Path is required", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let size = crypto_get_file_size(path)
      DispatchQueue.main.async {
        if size >= 0 {
          result(size)
        } else {
          result(FlutterError(code: "SIZE_ERROR", message: "Failed to get file size", details: nil))
        }
      }
    }
  }
}
