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

// Prepare 32-byte key from input (matching Android & iOS implementation)
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

// Prepare 16-byte IV from input string (matching Android & iOS implementation)
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

// AES-256-CTR decryption using CommonCrypto
int crypto_decrypt_file(const char* input_path, const char* output_path, const char* key) {
    return crypto_decrypt_file_with_iv(input_path, output_path, key, NULL);
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
        // Skip the IV in the encrypted file since it was written during encryption
        if (fseek(input_file, IV_LENGTH, SEEK_SET) != 0) {
            fclose(input_file);
            fclose(output_file);
            return -2;
        }
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

int64_t crypto_get_file_size(const char* file_path) {
    struct stat st;
    if (stat(file_path, &st) == 0) {
        return (int64_t)st.st_size;
    }
    return -1;
}
