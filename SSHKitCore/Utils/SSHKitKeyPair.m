//
//  SSHKitKeyPair.m
//  SSHKitCore
//
//  Created by Yang Yubo on 12/24/14.
//
//
#import "SSHKitCore+Protected.h"
#import "SSHKitKeyPair.h"

@implementation SSHKitKeyPair

+ (instancetype)keyPairFromFilePath:(NSString *)path withAskPass:(SSHKitAskPassBlock)askPass error:(NSError **)errPtr {
    return [self parserFromContent:path isBase64:NO withAskPass:askPass error:errPtr];
}

+ (instancetype)keyPairFromBase64:(NSString *)base64 withAskPass:(SSHKitAskPassBlock)askPass error:(NSError **)errPtr {
    return [self parserFromContent:base64 isBase64:YES withAskPass:askPass error:errPtr];
}


+ (instancetype)parserFromContent:(NSString *)content isBase64:(BOOL)isBase64 withAskPass:(SSHKitAskPassBlock)askPass error:(NSError **)errPtr {
    if (!content.length) {
        if (errPtr) *errPtr = [NSError errorWithDomain:SSHKitCoreErrorDomain
                                                  code:SSHKitErrorIdentityParseFailure
                                              userInfo:@{ NSLocalizedDescriptionKey : @"Content of private key is empty" }];
        return nil;
    }
    
    int ret = 0;
    SSHKitKeyPair *parser = [[SSHKitKeyPair alloc] init];
    
    // import private key
    if (isBase64) {
        ret = ssh_pki_import_privkey_base64(content.UTF8String, NULL, auth_callback, (__bridge void *)(askPass), &parser->_privateKey);
    } else {
        ret = ssh_pki_import_privkey_file(content.UTF8String, NULL, auth_callback, (__bridge void *)(askPass), &parser->_privateKey);
    }
    
    switch (ret) {
        case SSH_OK:
            // success, try extract publickey
            break;
            
        case SSH_EOF:
            if (errPtr) *errPtr = [NSError errorWithDomain:SSHKitCoreErrorDomain
                                                      code:SSHKitErrorIdentityParseFailure
                                                  userInfo:@{
                                                             NSLocalizedDescriptionKey : @"Private key file doesn't exist or permission denied",
                                                             NSLocalizedRecoverySuggestionErrorKey : @"Please try again or import another private key."
                                                             }];
            return nil;
            
        default:
            if (errPtr) *errPtr = [NSError errorWithDomain:SSHKitCoreErrorDomain
                                                      code:SSHKitErrorIdentityParseFailure
                                                  userInfo:@{
                                                             NSLocalizedDescriptionKey : @"Could not parse private key",
                                                             NSLocalizedRecoverySuggestionErrorKey : @"Please try again or import another private key."
                                                             }];
            return nil;
    }
    
    // extract public key from private key
    ret = ssh_pki_export_privkey_to_pubkey(parser->_privateKey, &parser->_publicKey);
    
    
    switch (ret) {
        case SSH_OK:
            // success
            break;
            
        default:
            if (errPtr) *errPtr = [NSError errorWithDomain:SSHKitCoreErrorDomain
                                                      code:SSHKitErrorIdentityParseFailure
                                                  userInfo:@{ NSLocalizedDescriptionKey : @"Could not extract public key from private key" }];
            return nil;;
    }
    
    return parser;
}

- (void)dealloc {
    if (_publicKey) {
        ssh_key_free(_publicKey);
    }
    if (_privateKey) {
        ssh_key_free(_privateKey);
    }
}

static int auth_callback(const char *prompt, char *buf, size_t len, int echo, int verify, void *userdata) {
    if (!userdata) {
        return SSH_ERROR;
    }
    
    SSHKitAskPassBlock handler = (__bridge SSHKitAskPassBlock)userdata;
    
    if (!handler) {
        return SSH_ERROR;
    }
    
    NSString *password = handler();
    NSUInteger length = [password lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
    if (length && length<len) {
        strcpy(buf, password.UTF8String);
        return SSH_OK;
    }
    
    return SSH_ERROR;
}

@end
