package com.example.aes_encrypt_file

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class AesEncryptFilePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "aes_encrypt_file")
        channel.setMethodCallHandler(this)

        // Load native library
        System.loadLibrary("native_crypto")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "encryptFile" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                val key = call.argument<String>("key")
                val iv = call.argument<String>("iv")

                if (inputPath != null && outputPath != null && key != null) {
                    Thread {
                        try {
                            val success = nativeEncryptFile(inputPath, outputPath, key, iv)
                            result.success(success == 0)
                        } catch (e: Exception) {
                            result.error("ENCRYPT_FAILED", e.message, null)
                        }
                    }.start()
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing required parameters", null)
                }
            }
            "decryptFile" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                val key = call.argument<String>("key")
                val iv = call.argument<String>("iv")

                if (inputPath != null && outputPath != null && key != null) {
                    Thread {
                        try {
                            val success = nativeDecryptFile(inputPath, outputPath, key, iv)
                            result.success(success == 0)
                        } catch (e: Exception) {
                            result.error("DECRYPT_FAILED", e.message, null)
                        }
                    }.start()
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing required parameters", null)
                }
            }
            "getFileSize" -> {
                val path = call.arguments as? String
                if (path != null) {
                    Thread {
                        try {
                            val size = nativeGetFileSize(path)
                            result.success(size)
                        } catch (e: Exception) {
                            result.error("SIZE_ERROR", e.message, null)
                        }
                    }.start()
                } else {
                    result.error("INVALID_PATH", "File path is required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // Native method declarations
    private external fun nativeEncryptFile(inputPath: String, outputPath: String, key: String, iv: String?): Int
    private external fun nativeDecryptFile(inputPath: String, outputPath: String, key: String, iv: String?): Int
    private external fun nativeGetFileSize(path: String): Long
}/** AesEncryptFilePlugin */
