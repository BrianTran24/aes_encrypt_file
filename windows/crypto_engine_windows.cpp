#include "crypto_engine_windows.h"
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <bcrypt.h>
#include <vector>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <filesystem>

#pragma comment(lib, "bcrypt.lib")

namespace aes_encrypt_file {

const size_t BUFFER_SIZE = 256 * 1024; // 256KB
const size_t AES_KEY_LENGTH = 32;      // AES-256
const size_t IV_LENGTH = 16;           // AES block size

std::wstring CryptoEngine::Utf8ToUtf16(const std::string& utf8_str) {
    if (utf8_str.empty()) return std::wstring();
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, utf8_str.c_str(), (int)utf8_str.size(), NULL, 0);
    std::wstring utf16_str(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, utf8_str.c_str(), (int)utf8_str.size(), &utf16_str[0], size_needed);
    return utf16_str;
}

bool CryptoEngine::PrepareKey(const std::string& key, std::vector<unsigned char>& prepared_key) {
    prepared_key.resize(AES_KEY_LENGTH);
    if (key.length() == AES_KEY_LENGTH) {
        memcpy(prepared_key.data(), key.c_str(), AES_KEY_LENGTH);
        return true;
    } else if (key.length() < AES_KEY_LENGTH) {
        memcpy(prepared_key.data(), key.c_str(), key.length());
        memset(prepared_key.data() + key.length(), 0, AES_KEY_LENGTH - key.length());
        return true;
    } else {
        BCRYPT_ALG_HANDLE hAlg = NULL;
        BCRYPT_HASH_HANDLE hHash = NULL;
        NTSTATUS status = BCryptOpenAlgorithmProvider(&hAlg, BCRYPT_SHA256_ALGORITHM, NULL, 0);
        if (status != 0) return false;

        status = BCryptCreateHash(hAlg, &hHash, NULL, 0, NULL, 0, 0);
        if (status == 0) {
            status = BCryptHashData(hHash, (PUCHAR)key.c_str(), (ULONG)key.length(), 0);
            if (status == 0) {
                status = BCryptFinishHash(hHash, prepared_key.data(), (ULONG)prepared_key.size(), 0);
            }
            BCryptDestroyHash(hHash);
        }
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return status == 0;
    }
}

bool CryptoEngine::PrepareIv(const std::string& iv_string, std::vector<unsigned char>& output_iv) {
    output_iv.resize(IV_LENGTH);
    if (iv_string.length() == IV_LENGTH) {
        memcpy(output_iv.data(), iv_string.c_str(), IV_LENGTH);
        return true;
    } else if (iv_string.length() < IV_LENGTH) {
        memcpy(output_iv.data(), iv_string.c_str(), iv_string.length());
        memset(output_iv.data() + iv_string.length(), 0, IV_LENGTH - iv_string.length());
        return true;
    } else {
        std::vector<unsigned char> hash(32);
        BCRYPT_ALG_HANDLE hAlg = NULL;
        BCRYPT_HASH_HANDLE hHash = NULL;
        NTSTATUS status = BCryptOpenAlgorithmProvider(&hAlg, BCRYPT_SHA256_ALGORITHM, NULL, 0);
        if (status != 0) return false;

        status = BCryptCreateHash(hAlg, &hHash, NULL, 0, NULL, 0, 0);
        if (status == 0) {
            status = BCryptHashData(hHash, (PUCHAR)iv_string.c_str(), (ULONG)iv_string.length(), 0);
            if (status == 0) {
                status = BCryptFinishHash(hHash, hash.data(), (ULONG)hash.size(), 0);
                memcpy(output_iv.data(), hash.data(), IV_LENGTH);
            }
            BCryptDestroyHash(hHash);
        }
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return status == 0;
    }
}

bool CryptoEngine::GenerateRandomIv(std::vector<unsigned char>& iv) {
    iv.resize(IV_LENGTH);
    NTSTATUS status = BCryptGenRandom(NULL, iv.data(), (ULONG)iv.size(), BCRYPT_USE_SYSTEM_PREFERRED_RNG);
    return status == 0;
}

int CryptoEngine::DoEncryptFile(const std::string& input_path, const std::string& output_path, const std::string& key, const std::string& iv_string) {
    std::filesystem::path p_input(Utf8ToUtf16(input_path));
    std::filesystem::path p_output(Utf8ToUtf16(output_path));

    // Ensure parent directory exists for output file
    try {
        if (p_output.has_parent_path()) {
            std::filesystem::create_directories(p_output.parent_path());
        }
    } catch (...) {
        return -11; // Directory creation failed
    }

    std::ifstream is(p_input, std::ios::binary);
    if (!is) return -1; // Failed to open input file

    std::ofstream os(p_output, std::ios::binary);
    if (!os) return -11; // Failed to open output file

    std::vector<unsigned char> prepared_key;
    if (!PrepareKey(key, prepared_key)) return -3;

    std::vector<unsigned char> iv;
    if (!iv_string.empty()) {
        if (!PrepareIv(iv_string, iv)) return -3;
    } else {
        if (!GenerateRandomIv(iv)) return -2;
    }

    os.write(reinterpret_cast<const char*>(iv.data()), IV_LENGTH);

    BCRYPT_ALG_HANDLE hAlg = NULL;
    BCRYPT_KEY_HANDLE hKey = NULL;
    NTSTATUS status = BCryptOpenAlgorithmProvider(&hAlg, BCRYPT_AES_ALGORITHM, NULL, 0);
    if (status != 0) return -4;

    status = BCryptSetProperty(hAlg, BCRYPT_CHAINING_MODE, (PUCHAR)BCRYPT_CHAIN_MODE_ECB, sizeof(BCRYPT_CHAIN_MODE_ECB), 0);
    if (status != 0) {
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return -4;
    }

    status = BCryptGenerateSymmetricKey(hAlg, &hKey, NULL, 0, prepared_key.data(), (ULONG)prepared_key.size(), 0);
    if (status != 0) {
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return -4;
    }

    std::vector<unsigned char> in_buffer(BUFFER_SIZE);
    std::vector<unsigned char> out_buffer(BUFFER_SIZE);
    std::vector<unsigned char> current_iv = iv;
    std::vector<unsigned char> counter_block(IV_LENGTH);

    while (is) {
        is.read(reinterpret_cast<char*>(in_buffer.data()), BUFFER_SIZE);
        std::streamsize bytes_read = is.gcount();
        if (bytes_read <= 0) break;

        for (size_t i = 0; i < (size_t)bytes_read; i += IV_LENGTH) {
            size_t block_len = std::min(IV_LENGTH, (size_t)bytes_read - i);

            ULONG cbResult = 0;
            status = BCryptEncrypt(hKey, current_iv.data(), IV_LENGTH, NULL, NULL, 0, counter_block.data(), IV_LENGTH, &cbResult, 0);
            if (status != 0) {
                BCryptDestroyKey(hKey);
                BCryptCloseAlgorithmProvider(hAlg, 0);
                return -5;
            }

            for (size_t j = 0; j < block_len; ++j) {
                out_buffer[i + j] = in_buffer[i + j] ^ counter_block[j];
            }

            // Increment IV (128-bit counter, big-endian)
            for (int j = (int)IV_LENGTH - 1; j >= 0; --j) {
                if (++current_iv[j] != 0) break;
            }
        }
        os.write(reinterpret_cast<const char*>(out_buffer.data()), bytes_read);
    }

    BCryptDestroyKey(hKey);
    BCryptCloseAlgorithmProvider(hAlg, 0);
    return 0;
}

int CryptoEngine::DoDecryptFile(const std::string& input_path, const std::string& output_path, const std::string& key, const std::string& iv_string) {
    std::filesystem::path p_input(Utf8ToUtf16(input_path));
    std::filesystem::path p_output(Utf8ToUtf16(output_path));

    // Ensure parent directory exists for output file
    try {
        if (p_output.has_parent_path()) {
            std::filesystem::create_directories(p_output.parent_path());
        }
    } catch (...) {
        return -11; // Directory creation failed
    }

    std::ifstream is(p_input, std::ios::binary);
    if (!is) return -1; // Failed to open input file

    std::ofstream os(p_output, std::ios::binary);
    if (!os) return -11; // Failed to open output file

    std::vector<unsigned char> iv(IV_LENGTH);
    if (!iv_string.empty()) {
        if (!PrepareIv(iv_string, iv)) return -3;
        is.seekg(IV_LENGTH, std::ios::beg); // Skip IV in file
    } else {
        is.read(reinterpret_cast<char*>(iv.data()), IV_LENGTH);
        if (is.gcount() != IV_LENGTH) return -2;
    }

    std::vector<unsigned char> prepared_key;
    if (!PrepareKey(key, prepared_key)) return -3;

    BCRYPT_ALG_HANDLE hAlg = NULL;
    BCRYPT_KEY_HANDLE hKey = NULL;
    NTSTATUS status = BCryptOpenAlgorithmProvider(&hAlg, BCRYPT_AES_ALGORITHM, NULL, 0);
    if (status != 0) return -4;

    status = BCryptSetProperty(hAlg, BCRYPT_CHAINING_MODE, (PUCHAR)BCRYPT_CHAIN_MODE_ECB, sizeof(BCRYPT_CHAIN_MODE_ECB), 0);
    if (status != 0) {
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return -4;
    }

    status = BCryptGenerateSymmetricKey(hAlg, &hKey, NULL, 0, prepared_key.data(), (ULONG)prepared_key.size(), 0);
    if (status != 0) {
        BCryptCloseAlgorithmProvider(hAlg, 0);
        return -4;
    }

    std::vector<unsigned char> in_buffer(BUFFER_SIZE);
    std::vector<unsigned char> out_buffer(BUFFER_SIZE);
    std::vector<unsigned char> current_iv = iv;
    std::vector<unsigned char> counter_block(IV_LENGTH);

    while (is) {
        is.read(reinterpret_cast<char*>(in_buffer.data()), BUFFER_SIZE);
        std::streamsize bytes_read = is.gcount();
        if (bytes_read <= 0) break;

        for (size_t i = 0; i < (size_t)bytes_read; i += IV_LENGTH) {
            size_t block_len = std::min(IV_LENGTH, (size_t)bytes_read - i);

            ULONG cbResult = 0;
            status = BCryptEncrypt(hKey, current_iv.data(), IV_LENGTH, NULL, NULL, 0, counter_block.data(), IV_LENGTH, &cbResult, 0);
            if (status != 0) {
                BCryptDestroyKey(hKey);
                BCryptCloseAlgorithmProvider(hAlg, 0);
                return -5;
            }

            for (size_t j = 0; j < block_len; ++j) {
                out_buffer[i + j] = in_buffer[i + j] ^ counter_block[j];
            }

            // Increment IV (128-bit counter, big-endian)
            for (int j = (int)IV_LENGTH - 1; j >= 0; --j) {
                if (++current_iv[j] != 0) break;
            }
        }
        os.write(reinterpret_cast<const char*>(out_buffer.data()), bytes_read);
    }

    BCryptDestroyKey(hKey);
    BCryptCloseAlgorithmProvider(hAlg, 0);
    return 0;
}

} // namespace aes_encrypt_file