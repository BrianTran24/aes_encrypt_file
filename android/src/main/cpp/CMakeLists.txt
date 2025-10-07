cmake_minimum_required(VERSION 3.18.1)

project("native_crypto")

# Find log library
find_library(log-lib log)

# Set OpenSSL paths based on Android ABI
set(OPENSSL_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/openssl/${ANDROID_ABI})
set(OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/openssl/include)
set(OPENSSL_CRYPTO_LIBRARY ${OPENSSL_ROOT_DIR}/libcrypto.a)
set(OPENSSL_SSL_LIBRARY ${OPENSSL_ROOT_DIR}/libssl.a)

# Check if OpenSSL libraries exist, if not provide helpful error message
if(NOT EXISTS ${OPENSSL_CRYPTO_LIBRARY})
    message(FATAL_ERROR 
        "OpenSSL libraries not found at ${OPENSSL_ROOT_DIR}\n"
        "Please run the setup script to download OpenSSL libraries:\n"
        "  cd android && sh download_openssl.sh\n"
    )
endif()

include_directories(${OPENSSL_INCLUDE_DIR})

add_library(
        native_crypto
        SHARED
        crypto_engine.c
        jni_wrapper.c
)

target_link_libraries(
        native_crypto
        ${OPENSSL_CRYPTO_LIBRARY}
        ${OPENSSL_SSL_LIBRARY}
        android
        log
        ${log-lib}
)