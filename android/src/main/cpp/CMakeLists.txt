cmake_minimum_required(VERSION 3.18.1)

project("native_crypto")

# Enable 16KB page size support for Android 15+ compatibility
# Ensure proper alignment for 16KB pages
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")

# Add linker flags for 16KB page size compatibility
# This ensures the native library is compatible with devices using 16KB pages
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384")

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