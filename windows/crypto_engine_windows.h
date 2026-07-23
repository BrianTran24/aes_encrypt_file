#ifndef CRYPTO_ENGINE_WINDOWS_H
#define CRYPTO_ENGINE_WINDOWS_H

#include <string>
#include <vector>

namespace aes_encrypt_file {

class CryptoEngine {
public:
    static int DoEncryptFile(const std::string& input_path, const std::string& output_path, const std::string& key, const std::string& iv_string = "");
    static int DoDecryptFile(const std::string& input_path, const std::string& output_path, const std::string& key, const std::string& iv_string = "");

private:
    static bool PrepareKey(const std::string& key, std::vector<unsigned char>& prepared_key);
    static bool PrepareIv(const std::string& iv_string, std::vector<unsigned char>& output_iv);
    static bool GenerateRandomIv(std::vector<unsigned char>& iv);
    static std::wstring Utf8ToUtf16(const std::string& utf8_str);
};

} // namespace aes_encrypt_file

#endif // CRYPTO_ENGINE_WINDOWS_H