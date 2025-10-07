#ifndef CRYPTO_ENGINE_H
#define CRYPTO_ENGINE_H

#include <stdio.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// File operations
int crypto_encrypt_file(const char* input_path, const char* output_path, const char* key);
int crypto_encrypt_file_with_iv(const char* input_path, const char* output_path, const char* key, const char* iv_string);
int crypto_decrypt_file(const char* input_path, const char* output_path, const char* key);
int crypto_decrypt_file_with_iv(const char* input_path, const char* output_path, const char* key, const char* iv_string);


#ifdef __cplusplus
}
#endif

#endif // CRYPTO_ENGINE_H