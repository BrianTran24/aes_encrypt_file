#import "AesEncryptFilePlugin.h"
#import "crypto_engine.h"

@implementation AesEncryptFilePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
            methodChannelWithName:@"aes_encrypt_file"
                  binaryMessenger:[registrar messenger]];
    AesEncryptFilePlugin* instance = [[AesEncryptFilePlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (NSString *)resolvePath:(NSString *)path {
    if ([path hasPrefix:@"/"]) {
        return path;
    } else if ([path hasPrefix:@"documents://"]) {
        NSString *fileName = [path substringFromIndex:@"documents://".length];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        return [documentsDirectory stringByAppendingPathComponent:fileName];
    } else {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        return [documentsDirectory stringByAppendingPathComponent:path];
    }
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"encryptFile" isEqualToString:call.method]) {
        [self handleEncryptFile:call result:result];
    }
    else if ([@"decryptFile" isEqualToString:call.method]) {
        [self handleDecryptFile:call result:result];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)handleEncryptFile:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary* arguments = call.arguments;
    NSString* inputPath = arguments[@"inputPath"];
    NSString* outputPath = arguments[@"outputPath"];
    NSString* key = arguments[@"key"];
    NSString* iv = arguments[@"iv"];

    if (!inputPath || !outputPath || !key) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS"
                                   message:@"Missing required parameters"
                                   details:nil]);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* resolvedInputPath = [self resolvePath:inputPath];
        NSString* resolvedOutputPath = [self resolvePath:outputPath];

        int success;
        if (iv && iv.length > 0) {
            success = crypto_encrypt_file_with_iv([resolvedInputPath UTF8String],
                                                   [resolvedOutputPath UTF8String],
                                                   [key UTF8String],
                                                   [iv UTF8String]);
        } else {
            success = crypto_encrypt_file([resolvedInputPath UTF8String],
                                          [resolvedOutputPath UTF8String],
                                          [key UTF8String]);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (success == 0) {
                result(@(YES));
            } else {
                result([FlutterError errorWithCode:@"ENCRYPT_FAILED"
                                           message:[NSString stringWithFormat:@"Encryption failed with code: %d", success]
                                           details:nil]);
            }
        });
    });
}

- (void)handleDecryptFile:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary* arguments = call.arguments;
    NSString* inputPath = arguments[@"inputPath"];
    NSString* outputPath = arguments[@"outputPath"];
    NSString* key = arguments[@"key"];
    NSString* iv = arguments[@"iv"];

    if (!inputPath || !outputPath || !key) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS"
                                   message:@"Missing required parameters"
                                   details:nil]);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* resolvedInputPath = [self resolvePath:inputPath];
        NSString* resolvedOutputPath = [self resolvePath:outputPath];

        int success;
        if (iv && iv.length > 0) {
            success = crypto_decrypt_file_with_iv([resolvedInputPath UTF8String],
                                                   [resolvedOutputPath UTF8String],
                                                   [key UTF8String],
                                                   [iv UTF8String]);
        } else {
            success = crypto_decrypt_file([resolvedInputPath UTF8String],
                                          [resolvedOutputPath UTF8String],
                                          [key UTF8String]);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (success == 0) {
                result(@(YES));
            } else {
                result([FlutterError errorWithCode:@"DECRYPT_FAILED"
                                           message:[NSString stringWithFormat:@"Decryption failed with code: %d", success]
                                           details:nil]);
            }
        });
    });
}
@end