#include "crypto_engine.h"
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <time.h>
#include <CommonCrypto/CommonCrypto.h>
#include <Security/Security.h>

#define BUFFER_SIZE (256 * 1024)  // 256KB buffer for better performance
#define AES_KEY_LENGTH 32         // AES-256
#define IV_LENGTH 16              // AES block size

// Prepare 32-byte key from input (matching Android implementation)
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
        CC_SHA256(input_key, (CC_LONG)key_len, output_key);
    }
}

// Prepare 16-byte IV from input string (matching Android implementation)
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
        CC_SHA256(input_iv, (CC_LONG)iv_len, hash);
        memcpy(output_iv, hash, IV_LENGTH);
    }
}

// AES-256-CTR encryption using CommonCrypto
int crypto_encrypt_file(const char* input_path, const char* output_path, const char* key) {
    return crypto_encrypt_file_with_iv(input_path, output_path, key, NULL);
}

// AES-256-CTR encryption using CommonCrypto with optional IV
int crypto_encrypt_file_with_iv(const char* input_path, const char* output_path, const char* key, const char* iv_string) {
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
        if (SecRandomCopyBytes(kSecRandomDefault, IV_LENGTH, iv) != 0) {
            fclose(input_file);
            fclose(output_file);
            return -2;
        }
    }

    // Write IV to output file
    if (fwrite(iv, 1, IV_LENGTH, output_file) != IV_LENGTH) {
        fclose(input_file);
        fclose(output_file);
        return -3;
    }

    // Create cryptor for AES-256-CTR
    CCCryptorRef cryptor = NULL;
    CCCryptorStatus status = CCCryptorCreateWithMode(
        kCCEncrypt,
        kCCModeCTR,
        kCCAlgorithmAES,
        ccNoPadding,
        iv,
        prepared_key,
        AES_KEY_LENGTH,
        NULL,  // tweak (not used in CTR mode)
        0,     // tweak length
        0,     // num rounds (0 = default)
        kCCModeOptionCTR_BE,  // CTR mode with big-endian counter
        &cryptor
    );

    if (status != kCCSuccess || !cryptor) {
        fclose(input_file);
        fclose(output_file);
        return -4;
    }

    // Encrypt file in chunks
    unsigned char in_buffer[BUFFER_SIZE];
    unsigned char out_buffer[BUFFER_SIZE];
    size_t bytes_read;
    size_t data_out_moved;

    while ((bytes_read = fread(in_buffer, 1, BUFFER_SIZE, input_file)) > 0) {
        status = CCCryptorUpdate(
            cryptor,
            in_buffer,
            bytes_read,
            out_buffer,
            BUFFER_SIZE,
            &data_out_moved
        );

        if (status != kCCSuccess) {
            CCCryptorRelease(cryptor);
            fclose(input_file);
            fclose(output_file);
            return -5;
        }

        if (fwrite(out_buffer, 1, data_out_moved, output_file) != data_out_moved) {
            CCCryptorRelease(cryptor);
            fclose(input_file);
            fclose(output_file);
            return -6;
        }
    }

    // Finalize encryption
    status = CCCryptorFinal(
        cryptor,
        out_buffer,
        BUFFER_SIZE,
        &data_out_moved
    );

    if (status != kCCSuccess) {
        CCCryptorRelease(cryptor);
        fclose(input_file);
        fclose(output_file);
        return -7;
    }

    if (data_out_moved > 0) {
        fwrite(out_buffer, 1, data_out_moved, output_file);
    }

    // Cleanup
    CCCryptorRelease(cryptor);
    fclose(input_file);
    fclose(output_file);
    return 0;
}

// AES-256-CTR decryption using CommonCrypto (same as encryption in CTR mode)
int crypto_decrypt_file(const char* input_path, const char* output_path, const char* key) {
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

    // Create cryptor for AES-256-CTR (decryption is same as encryption in CTR mode)
    CCCryptorRef cryptor = NULL;
    CCCryptorStatus status = CCCryptorCreateWithMode(
        kCCDecrypt,  // Use decrypt for CTR mode
        kCCModeCTR,
        kCCAlgorithmAES,
        ccNoPadding,
        iv,
        prepared_key,
        AES_KEY_LENGTH,
        NULL,  // tweak (not used in CTR mode)
        0,     // tweak length
        0,     // num rounds (0 = default)
        kCCModeOptionCTR_BE,  // CTR mode with big-endian counter
        &cryptor
    );

    if (status != kCCSuccess || !cryptor) {
        fclose(input_file);
        fclose(output_file);
        return -3;
    }

    // Decrypt file in chunks
    unsigned char in_buffer[BUFFER_SIZE];
    unsigned char out_buffer[BUFFER_SIZE];
    size_t bytes_read;
    size_t data_out_moved;

    while ((bytes_read = fread(in_buffer, 1, BUFFER_SIZE, input_file)) > 0) {
        status = CCCryptorUpdate(
            cryptor,
            in_buffer,
            bytes_read,
            out_buffer,
            BUFFER_SIZE,
            &data_out_moved
        );

        if (status != kCCSuccess) {
            CCCryptorRelease(cryptor);
            fclose(input_file);
            fclose(output_file);
            return -4;
        }

        if (fwrite(out_buffer, 1, data_out_moved, output_file) != data_out_moved) {
            CCCryptorRelease(cryptor);
            fclose(input_file);
            fclose(output_file);
            return -5;
        }
    }

    // Finalize decryption
    status = CCCryptorFinal(
        cryptor,
        out_buffer,
        BUFFER_SIZE,
        &data_out_moved
    );

    if (status != kCCSuccess) {
        CCCryptorRelease(cryptor);
        fclose(input_file);
        fclose(output_file);
        return -6;
    }

    if (data_out_moved > 0) {
        if (fwrite(out_buffer, 1, data_out_moved, output_file) != data_out_moved) {
            CCCryptorRelease(cryptor);
            fclose(input_file);
            fclose(output_file);
            return -7;
        }
    }

    // Cleanup
    CCCryptorRelease(cryptor);
    fclose(input_file);
    fclose(output_file);
    return 0;
}

// Decrypt file using AES-256-CTR with custom IV support
int crypto_decrypt_file_with_iv(const char* input_path, const char* output_path, const char* key, const char* iv_string) {
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

    // Create cryptor for AES-256-CTR (decryption is same as encryption in CTR mode)
    CCCryptorRef cryptor = NULL;
    CCCryptorStatus status = CCCryptorCreateWithMode(
        kCCDecrypt,  // Use decrypt for CTR mode
        kCCModeCTR,
        kCCAlgorithmAES,
        ccNoPadding,
        iv,
        prepared_key,
        AES_KEY_LENGTH,
        NULL,  // tweak (not used in CTR mode)
        0,     // tweak length
        0,     // num rounds (0 = default)
        kCCModeOptionCTR_BE,  // CTR mode with big-endian counter
        &cryptor
    );

    if (status != kCCSuccess || !cryptor) {
        fclose(input_file);
        fclose(output_file);
        return -3;
    }

    // Decrypt file in chunks
    unsigned char in_buffer[BUFFER_SIZE];
    unsigned char out_buffer[BUFFER_SIZE];
    size_t bytes_read;
    size_t data_out_moved;

    while ((bytes_read = fread(in_buffer, 1, BUFFER_SIZE, input_file)) > 0) {
        status = CCCryptorUpdate(
            cryptor,
            in_buffer,
            bytes_read,
            out_buffer,
            BUFFER_SIZE,
            &data_out_moved
        );

        if (status != kCCSuccess) {
            CCCryptorRelease(cryptor);
            fclose(input_file);
            fclose(output_file);
            return -4;
        }

        if (fwrite(out_buffer, 1, data_out_moved, output_file) != data_out_moved) {
            CCCryptorRelease(cryptor);
            fclose(input_file);
            fclose(output_file);
            return -5;
        }
    }

    // Finalize decryption
    status = CCCryptorFinal(
        cryptor,
        out_buffer,
        BUFFER_SIZE,
        &data_out_moved
    );

    if (status != kCCSuccess) {
        CCCryptorRelease(cryptor);
        fclose(input_file);
        fclose(output_file);
        return -6;
    }

    if (data_out_moved > 0) {
        fwrite(out_buffer, 1, data_out_moved, output_file);
    }

    // Cleanup
    CCCryptorRelease(cryptor);
    fclose(input_file);
    fclose(output_file);
    return 0;
}

//int64_t crypto_get_file_size(const char* file_path) {
//    struct stat st;
//    if (stat(file_path, &st) == 0) {
//        return st.st_size;
//    }
//    return -1;
//}
//
//char* crypto_encrypt_data(const char* data, int64_t data_len, const char* key, int64_t* output_len) {
//    if (!data || data_len <= 0 || !key) {
//        return NULL;
//    }
//
//    size_t key_len = strlen(key);
//    if (key_len == 0) {
//        return NULL;
//    }
//
//    // Allocate output buffer: header (5 bytes) + encrypted data
//    char* output = malloc(data_len + 5);
//    if (!output) {
//        return NULL;
//    }
//
//    // Write header
//    uint8_t* header = (uint8_t*)output;
//    header[0] = 1; // version
//    uint32_t* key_len_ptr = (uint32_t*)(header + 1);
//    *key_len_ptr = (uint32_t)key_len;
//
//    char* data_out = output + 5;
//
//    // XOR encryption
//    size_t key_index = 0;
//    for (int64_t i = 0; i < data_len; i++) {
//        data_out[i] = data[i] ^ key[key_index];
//        key_index = (key_index + 1) % key_len;
//    }
//
//    *output_len = data_len + 5;
//    return output;
//}
//
//char* crypto_decrypt_data(const char* data, int64_t data_len, const char* key, int64_t* output_len) {
//    if (!data || data_len <= 5 || !key) {
//        return NULL;
//    }
//
//    // Read header
//    const uint8_t* header = (const uint8_t*)data;
//    uint8_t version = header[0];
//    const uint32_t* key_len_ptr = (const uint32_t*)(header + 1);
//    uint32_t stored_key_len = *key_len_ptr;
//
//    if (version != 1) {
//        return NULL;
//    }
//
//    size_t actual_key_len = strlen(key);
//    if (stored_key_len != actual_key_len) {
//        return NULL;
//    }
//
//    int64_t encrypted_data_len = data_len - 5;
//    const char* encrypted_data = data + 5;
//
//    // Allocate output buffer
//    char* output = malloc(encrypted_data_len);
//    if (!output) {
//        return NULL;
//    }
//
//    // XOR decryption
//    size_t key_index = 0;
//    for (int64_t i = 0; i < encrypted_data_len; i++) {
//        output[i] = encrypted_data[i] ^ key[key_index];
//        key_index = (key_index + 1) % actual_key_len;
//    }
//
//    *output_len = encrypted_data_len;
//    return output;
//}
//
//void crypto_free_buffer(char* buffer) {
//    if (buffer) {
//        free(buffer);
//    }
//}
//
//int crypto_generate_key(char* key_buffer, int key_length) {
//    if (!key_buffer || key_length <= 0) {
//        return -1;
//    }
//
//    // Simple random generation (use proper crypto RNG in production)
//    for (int i = 0; i < key_length; i++) {
//        key_buffer[i] = (char)(arc4random_uniform(256));
//    }
//
//    return 0;
//}
//
//int crypto_calculate_checksum(const char* data, int64_t data_len, char* checksum_buffer) {
//    if (!data || !checksum_buffer) {
//        return -1;
//    }
//
//    // Simple checksum for demo
//    uint8_t checksum = 0;
//    for (int64_t i = 0; i < data_len; i++) {
//        checksum ^= data[i];
//    }
//
//    snprintf(checksum_buffer, 3, "%02x", checksum);
//    return 0;
//}
//
//double crypto_benchmark_encryption(int data_size) {
//    if (data_size <= 0) {
//        return -1.0;
//    }
//
//    // Generate test data
//    char* test_data = malloc(data_size);
//    char* key = "benchmark_key_1234567890";
//
//    if (!test_data) {
//        return -1.0;
//    }
//
//    for (int i = 0; i < data_size; i++) {
//        test_data[i] = (char)(i % 256);
//    }
//
//    clock_t start = clock();
//
//    // Perform encryption
//    int64_t output_len;
//    char* encrypted = crypto_encrypt_data(test_data, data_size, key, &output_len);
//
//    clock_t end = clock();
//    double duration = ((double)(end - start)) / CLOCKS_PER_SEC;
//
//    if (encrypted) {
//        crypto_free_buffer(encrypted);
//    }
//    free(test_data);
//
//    return duration;
//}