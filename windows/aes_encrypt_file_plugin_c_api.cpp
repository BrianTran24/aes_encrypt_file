#include "include/aes_encrypt_file/aes_encrypt_file_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "aes_encrypt_file_plugin.h"

void AesEncryptFilePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  aes_encrypt_file::AesEncryptFilePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

void AesEncryptFilePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  AesEncryptFilePluginCApiRegisterWithRegistrar(registrar);
}
