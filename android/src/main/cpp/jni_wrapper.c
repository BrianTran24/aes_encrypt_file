#include <jni.h>
#include <string.h>
#include "crypto_engine.h"

// JNI wrapper for nativeEncryptFile
JNIEXPORT jint JNICALL
Java_com_example_aes_1encrypt_1file_AesEncryptFilePlugin_nativeEncryptFile(
    JNIEnv *env,
    jobject thiz,
    jstring inputPath,
    jstring outputPath,
    jstring key,
    jstring iv) {
    
    // Convert Java strings to C strings
    const char *input_path_str = (*env)->GetStringUTFChars(env, inputPath, NULL);
    const char *output_path_str = (*env)->GetStringUTFChars(env, outputPath, NULL);
    const char *key_str = (*env)->GetStringUTFChars(env, key, NULL);
    const char *iv_str = NULL;
    
    // Check if IV is provided
    if (iv != NULL) {
        iv_str = (*env)->GetStringUTFChars(env, iv, NULL);
    }
    
    // Call the native encryption function with IV
    int result = aes_encrypt_file_with_iv(input_path_str, output_path_str, key_str, iv_str);
    
    // Release the strings
    (*env)->ReleaseStringUTFChars(env, inputPath, input_path_str);
    (*env)->ReleaseStringUTFChars(env, outputPath, output_path_str);
    (*env)->ReleaseStringUTFChars(env, key, key_str);
    if (iv_str != NULL) {
        (*env)->ReleaseStringUTFChars(env, iv, iv_str);
    }
    
    return result;
}

// JNI wrapper for nativeDecryptFile
JNIEXPORT jint JNICALL
Java_com_example_aes_1encrypt_1file_AesEncryptFilePlugin_nativeDecryptFile(
    JNIEnv *env,
    jobject thiz,
    jstring inputPath,
    jstring outputPath,
    jstring key,
    jstring iv) {
    
    // Convert Java strings to C strings
    const char *input_path_str = (*env)->GetStringUTFChars(env, inputPath, NULL);
    const char *output_path_str = (*env)->GetStringUTFChars(env, outputPath, NULL);
    const char *key_str = (*env)->GetStringUTFChars(env, key, NULL);
    const char *iv_str = NULL;
    
    // Check if IV is provided
    if (iv != NULL) {
        iv_str = (*env)->GetStringUTFChars(env, iv, NULL);
    }
    
    // Call the native decryption function with IV
    int result = aes_decrypt_file_with_iv(input_path_str, output_path_str, key_str, iv_str);
    
    // Release the strings
    (*env)->ReleaseStringUTFChars(env, inputPath, input_path_str);
    (*env)->ReleaseStringUTFChars(env, outputPath, output_path_str);
    (*env)->ReleaseStringUTFChars(env, key, key_str);
    if (iv_str != NULL) {
        (*env)->ReleaseStringUTFChars(env, iv, iv_str);
    }
    
    return result;
}

// JNI wrapper for nativeGetFileSize
JNIEXPORT jlong JNICALL
Java_com_example_aes_1encrypt_1file_AesEncryptFilePlugin_nativeGetFileSize(
    JNIEnv *env,
    jobject thiz,
    jstring path) {
    
    // Convert Java string to C string
    const char *path_str = (*env)->GetStringUTFChars(env, path, NULL);
    
    // Call the native get file size function
    long long result = get_file_size(path_str);
    
    // Release the string
    (*env)->ReleaseStringUTFChars(env, path, path_str);
    
    return (jlong)result;
}
