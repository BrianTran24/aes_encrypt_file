#include "crypto_engine.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/evp.h>
#include <openssl/aes.h>
#include <openssl/rand.h>
#include <openssl/err.h>
#include <openssl/sha.h>

#define BUFFER_SIZE (256 * 1024)  // 256KB buffer for better performance
#define AES_KEY_LENGTH 32         // AES-256
#define IV_LENGTH 16              // AES block size

// Prepare 32-byte key from input (matching iOS and Dart implementations)
static void prepare_key(const char* input_key, unsigned char* output_key) {
    size_t key_len = strlen(input_key);
    
    if (key_len == AES_KEY_LENGTH) {
        // Key is exactly 32 bytes, use as-is
        memcpy(output_key, input_key, AES_KEY_LENGTH);
    } else if (key_len < AES_KEY_LENGTH) {
        // Key is less than 32 bytes, pad with zeros
        memcpy(output_key, input_key, key_len);
        memset(output_key + key_len, 0, AES_KEY_LENGTH - key_len);
    } else {
        // Key is more than 32 bytes, use SHA-256 hash
        SHA256((const unsigned char*)input_key, key_len, output_key);
    }
}

// Prepare 16-byte IV from input string
static void prepare_iv(const char* input_iv, unsigned char* output_iv) {
    size_t iv_len = strlen(input_iv);
    
    if (iv_len == IV_LENGTH) {
        // IV is exactly 16 bytes, use as-is
        memcpy(output_iv, input_iv, IV_LENGTH);
    } else if (iv_len < IV_LENGTH) {
        // IV is less than 16 bytes, pad with zeros
        memcpy(output_iv, input_iv, iv_len);
        memset(output_iv + iv_len, 0, IV_LENGTH - iv_len);
    } else {
        // IV is more than 16 bytes, use first 16 bytes of SHA-256 hash
        unsigned char hash[32];
        SHA256((const unsigned char*)input_iv, iv_len, hash);
        memcpy(output_iv, hash, IV_LENGTH);
    }
}

// Encrypt file using AES-256-CTR
int aes_encrypt_file(const char* input_path, const char* output_path, const char* key) {
    return aes_encrypt_file_with_iv(input_path, output_path, key, NULL);
}

// Encrypt file using AES-256-CTR with optional IV
int aes_encrypt_file_with_iv(const char* input_path, const char* output_path, const char* key, const char* iv_string) {
    FILE* input_file = fopen(input_path, "rb");
    FILE* output_file = fopen(output_path, "wb");

    if (!input_file || !output_file) {
        if (input_file) fclose(input_file);
        if (output_file) fclose(output_file);
        return -1;
    }

    // Prepare 32-byte key
    unsigned char prepared_key[AES_KEY_LENGTH];
    prepare_key(key, prepared_key);

    // Prepare or generate IV
    unsigned char iv[IV_LENGTH];
    if (iv_string != NULL && strlen(iv_string) > 0) {
        // Use provided IV string
        prepare_iv(iv_string, iv);
    } else {
        // Generate random IV
        if (RAND_bytes(iv, IV_LENGTH) != 1) {
            fclose(input_file);
            fclose(output_file);
            return -2;
        }
    }

    // Write IV to output file
    fwrite(iv, 1, IV_LENGTH, output_file);

    // Setup OpenSSL context
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        fclose(input_file);
        fclose(output_file);
        return -3;
    }

    // Initialize encryption
    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_ctr(), NULL,
                           prepared_key, iv) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        fclose(input_file);
        fclose(output_file);
        return -4;
    }

    // Encrypt file in chunks
    unsigned char in_buffer[BUFFER_SIZE];
    unsigned char out_buffer[BUFFER_SIZE + AES_BLOCK_SIZE];
    int bytes_read;
    int out_length;
    long long total_encrypted = 0;

    while ((bytes_read = fread(in_buffer, 1, BUFFER_SIZE, input_file)) > 0) {
        if (EVP_EncryptUpdate(ctx, out_buffer, &out_length, in_buffer, bytes_read) != 1) {
            EVP_CIPHER_CTX_free(ctx);
            fclose(input_file);
            fclose(output_file);
            return -5;
        }
        fwrite(out_buffer, 1, out_length, output_file);
        total_encrypted += bytes_read;
    }

    // Finalize encryption
    if (EVP_EncryptFinal_ex(ctx, out_buffer, &out_length) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        fclose(input_file);
        fclose(output_file);
        return -6;
    }
    fwrite(out_buffer, 1, out_length, output_file);

    // Cleanup
    EVP_CIPHER_CTX_free(ctx);
    fclose(input_file);
    fclose(output_file);

    return 0; // Success
}

// Decrypt file using AES-256-CTR
int aes_decrypt_file(const char* input_path, const char* output_path, const char* key) {
    FILE* input_file = fopen(input_path, "rb");
    FILE* output_file = fopen(output_path, "wb");

    if (!input_file || !output_file) {
        if (input_file) fclose(input_file);
        if (output_file) fclose(output_file);
        return -1;
    }

    // Read IV from input file
    unsigned char iv[IV_LENGTH];
    if (fread(iv, 1, IV_LENGTH, input_file) != IV_LENGTH) {
        fclose(input_file);
        fclose(output_file);
        return -2;
    }

    // Prepare 32-byte key
    unsigned char prepared_key[AES_KEY_LENGTH];
    prepare_key(key, prepared_key);

    // Setup OpenSSL context
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        fclose(input_file);
        fclose(output_file);
        return -3;
    }

    // Initialize decryption
    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_ctr(), NULL,
                           prepared_key, iv) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        fclose(input_file);
        fclose(output_file);
        return -4;
    }

    // Decrypt file in chunks
    unsigned char in_buffer[BUFFER_SIZE];
    unsigned char out_buffer[BUFFER_SIZE + AES_BLOCK_SIZE];
    int bytes_read;
    int out_length;
    long long total_decrypted = 0;

    while ((bytes_read = fread(in_buffer, 1, BUFFER_SIZE, input_file)) > 0) {
        if (EVP_DecryptUpdate(ctx, out_buffer, &out_length, in_buffer, bytes_read) != 1) {
            EVP_CIPHER_CTX_free(ctx);
            fclose(input_file);
            fclose(output_file);
            return -5;
        }
        fwrite(out_buffer, 1, out_length, output_file);
        total_decrypted += bytes_read;
    }

    // Finalize decryption
    if (EVP_DecryptFinal_ex(ctx, out_buffer, &out_length) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        fclose(input_file);
        fclose(output_file);
        return -6;
    }
    fwrite(out_buffer, 1, out_length, output_file);

    // Cleanup
    EVP_CIPHER_CTX_free(ctx);
    fclose(input_file);
    fclose(output_file);

    return 0; // Success
}

// Decrypt file using AES-256-CTR with custom IV support
int aes_decrypt_file_with_iv(const char* input_path, const char* output_path, const char* key, const char* iv_string) {
    FILE* input_file = fopen(input_path, "rb");
    FILE* output_file = fopen(output_path, "wb");

    if (!input_file || !output_file) {
        if (input_file) fclose(input_file);
        if (output_file) fclose(output_file);
        return -1;
    }

    // Prepare IV
    unsigned char iv[IV_LENGTH];
    if (iv_string != NULL && strlen(iv_string) > 0) {
        // Use provided IV string (for decrypting files encrypted with custom IV)
        prepare_iv(iv_string, iv);
    } else {
        // Read IV from input file (standard behavior)
        if (fread(iv, 1, IV_LENGTH, input_file) != IV_LENGTH) {
            fclose(input_file);
            fclose(output_file);
            return -2;
        }
    }

    // Prepare 32-byte key
    unsigned char prepared_key[AES_KEY_LENGTH];
    prepare_key(key, prepared_key);

    // Setup OpenSSL context
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        fclose(input_file);
        fclose(output_file);
        return -3;
    }

    // Initialize decryption
    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_ctr(), NULL,
                           prepared_key, iv) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        fclose(input_file);
        fclose(output_file);
        return -4;
    }

    // Decrypt file in chunks
    unsigned char in_buffer[BUFFER_SIZE];
    unsigned char out_buffer[BUFFER_SIZE + AES_BLOCK_SIZE];
    int bytes_read;
    int out_length;
    long long total_decrypted = 0;

    // If IV was provided (not read from file), we need to skip the IV in the file
    // Actually, if custom IV is provided, we assume the entire file is encrypted data
    // If no IV is provided, we already read it from the file above

    while ((bytes_read = fread(in_buffer, 1, BUFFER_SIZE, input_file)) > 0) {
        if (EVP_DecryptUpdate(ctx, out_buffer, &out_length, in_buffer, bytes_read) != 1) {
            EVP_CIPHER_CTX_free(ctx);
            fclose(input_file);
            fclose(output_file);
            return -5;
        }
        fwrite(out_buffer, 1, out_length, output_file);
        total_decrypted += bytes_read;
    }

    // Finalize decryption
    if (EVP_DecryptFinal_ex(ctx, out_buffer, &out_length) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        fclose(input_file);
        fclose(output_file);
        return -6;
    }
    fwrite(out_buffer, 1, out_length, output_file);

    // Cleanup
    EVP_CIPHER_CTX_free(ctx);
    fclose(input_file);
    fclose(output_file);

    return 0; // Success
}

// Encrypt data in memory
char* aes_encrypt_data(const char* input, size_t input_len, const char* key, size_t* output_len) {
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (!ctx) return NULL;

    // Prepare 32-byte key
    unsigned char prepared_key[AES_KEY_LENGTH];
    prepare_key(key, prepared_key);

    unsigned char iv[IV_LENGTH];
    RAND_bytes(iv, IV_LENGTH);

    // Initialize encryption
    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_ctr(), NULL,
                           prepared_key, iv) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }

    // Allocate output buffer (input_len + IV + padding)
    size_t out_size = input_len + IV_LENGTH + AES_BLOCK_SIZE;
    char* output = (char*)malloc(out_size);
    if (!output) {
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }

    // Copy IV to output
    memcpy(output, iv, IV_LENGTH);

    int out_length1, out_length2;
    char* data_out = output + IV_LENGTH;

    // Encrypt data
    if (EVP_EncryptUpdate(ctx, (unsigned char*)data_out, &out_length1,
                          (const unsigned char*)input, input_len) != 1) {
        free(output);
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }

    if (EVP_EncryptFinal_ex(ctx, (unsigned char*)data_out + out_length1, &out_length2) != 1) {
        free(output);
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }

    *output_len = IV_LENGTH + out_length1 + out_length2;
    EVP_CIPHER_CTX_free(ctx);

    return output;
}

// Utility function to free buffers
void free_buffer(char* buffer) {
    if (buffer) {
        free(buffer);
    }
}

// Get file size
long long get_file_size(const char* filename) {
    FILE* file = fopen(filename, "rb");
    if (!file) return -1;

    fseek(file, 0, SEEK_END);
    long long size = ftell(file);
    fclose(file);

    return size;
}