#ifndef CRYPTO_ENGINE_H
#define CRYPTO_ENGINE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Function declarations
int aes_encrypt_file(const char* input_path, const char* output_path, const char* key);
int aes_encrypt_file_with_iv(const char* input_path, const char* output_path, const char* key, const char* iv_string);
int aes_decrypt_file(const char* input_path, const char* output_path, const char* key);
int aes_decrypt_file_with_iv(const char* input_path, const char* output_path, const char* key, const char* iv_string);

char* aes_encrypt_data(const char* input, size_t input_len, const char* key, size_t* output_len);
char* aes_decrypt_data(const char* input, size_t input_len, const char* key, size_t* output_len);

void free_buffer(char* buffer);

// Utility functions
long long get_file_size(const char* filename);
int generate_random_bytes(unsigned char* buffer, size_t length);

#ifdef __cplusplus
}
#endif

#endif // CRYPTO_ENGINE_H