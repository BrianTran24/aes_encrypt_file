#ifndef FLUTTER_PLUGIN_AES_ENCRYPT_FILE_PLUGIN_H_
#define FLUTTER_PLUGIN_AES_ENCRYPT_FILE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace aes_encrypt_file {

class AesEncryptFilePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  AesEncryptFilePlugin();

  virtual ~AesEncryptFilePlugin();

  // Disallow copy and assign.
  AesEncryptFilePlugin(const AesEncryptFilePlugin&) = delete;
  AesEncryptFilePlugin& operator=(const AesEncryptFilePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace aes_encrypt_file

#endif  // FLUTTER_PLUGIN_AES_ENCRYPT_FILE_PLUGIN_H_
