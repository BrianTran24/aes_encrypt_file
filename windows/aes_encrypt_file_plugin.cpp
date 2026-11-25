#include "aes_encrypt_file_plugin.h"
#include "crypto_engine_windows.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <thread>

namespace aes_encrypt_file {

// static
void AesEncryptFilePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "aes_encrypt_file",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<AesEncryptFilePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

AesEncryptFilePlugin::AesEncryptFilePlugin() {}

AesEncryptFilePlugin::~AesEncryptFilePlugin() {}

void AesEncryptFilePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method_name = method_call.method_name();

  if (method_name == "encryptFile" || method_name == "decryptFile") {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("INVALID_ARGUMENTS", "Arguments must be a map.");
      return;
    }

    auto input_it = args->find(flutter::EncodableValue("inputPath"));
    auto output_it = args->find(flutter::EncodableValue("outputPath"));
    auto key_it = args->find(flutter::EncodableValue("key"));

    if (input_it == args->end() || output_it == args->end() || key_it == args->end()) {
      result->Error("INVALID_ARGUMENTS", "Missing required parameters.");
      return;
    }

    const auto* input_path = std::get_if<std::string>(&input_it->second);
    const auto* output_path = std::get_if<std::string>(&output_it->second);
    const auto* key = std::get_if<std::string>(&key_it->second);

    if (!input_path || !output_path || !key) {
      result->Error("INVALID_ARGUMENTS", "Invalid parameter types.");
      return;
    }

    std::string iv_str;
    auto iv_it = args->find(flutter::EncodableValue("iv"));
    if (iv_it != args->end()) {
      if (const auto* iv_val = std::get_if<std::string>(&iv_it->second)) {
        iv_str = *iv_val;
      }
    }

    std::string in_copy = *input_path;
    std::string out_copy = *output_path;
    std::string key_copy = *key;
    bool is_encrypt = (method_name == "encryptFile");
    auto shared_result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));

    std::thread([in_copy, out_copy, key_copy, iv_str, is_encrypt, shared_result]() {
      int code = is_encrypt
                     ? CryptoEngine::DoEncryptFile(in_copy, out_copy, key_copy, iv_str)
                     : CryptoEngine::DoDecryptFile(in_copy, out_copy, key_copy, iv_str);
      if (code == 0) {
        shared_result->Success(flutter::EncodableValue(true));
      } else {
        shared_result->Error(
            is_encrypt ? "ENCRYPT_FAILED" : "DECRYPT_FAILED",
            (is_encrypt ? "Encryption failed with code: " : "Decryption failed with code: ") + std::to_string(code));
      }
    }).detach();
  } else if (method_name == "getFileSize") {
    const auto* path = std::get_if<std::string>(method_call.arguments());
    if (!path) {
      result->Error("INVALID_ARGUMENTS", "File path is required.");
      return;
    }

    std::string path_copy = *path;
    auto shared_result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));

    std::thread([path_copy, shared_result]() {
      int64_t size = CryptoEngine::GetFileSize(path_copy);
      if (size >= 0) {
        shared_result->Success(flutter::EncodableValue(size));
      } else {
        shared_result->Error("SIZE_ERROR", "Failed to get file size.");
      }
    }).detach();
  } else {
    result->NotImplemented();
  }
}

}  // namespace aes_encrypt_file
