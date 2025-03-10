#import "CircleModule.h"
#import <React/RCTLog.h>
#import <React/RCTConvert.h>

// Import the Swift header
#import "CircleModularWalletsReactNative-Swift.h"

@implementation CircleModule

RCT_EXPORT_MODULE();

// Required for RCTEventEmitter
- (NSArray<NSString *> *)supportedEvents {
  return @[@"CircleModuleEvent"];
}

// Export methods to JavaScript
RCT_EXPORT_METHOD(createUser:(NSString *)userName
                  clientKey:(NSString *)clientKey
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  
  // Call the Swift implementation
  [[CircleModuleSwift shared] createUserWithUserName:userName
                                          clientKey:clientKey
                                          resolver:resolve
                                          rejecter:reject];
}

RCT_EXPORT_METHOD(loginUser:(NSString *)userName
                  clientKey:(NSString *)clientKey
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  
  // Call the Swift implementation
  [[CircleModuleSwift shared] loginUserWithUserName:userName
                                        clientKey:clientKey
                                        resolver:resolve
                                        rejecter:reject];
}

RCT_EXPORT_METHOD(createSmartAccount:(NSString *)clientKey
                  clientUrl:(NSString *)clientUrl
                  chain:(NSString *)chain
                  credential:(NSDictionary *)credential
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  
  // Call the Swift implementation
  [[CircleModuleSwift shared] createSmartAccountWithClientKey:clientKey
                                                  clientUrl:clientUrl
                                                  chain:chain
                                                  credential:credential
                                                  resolver:resolve
                                                  rejecter:reject];
}

RCT_EXPORT_METHOD(sendUserOperation:(NSString *)accountId
                  to:(NSString *)to
                  value:(NSString *)value
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  
  // Call the Swift implementation
  [[CircleModuleSwift shared] sendUserOperationWithAccountId:accountId
                                                          to:to
                                                          value:value
                                                          resolver:resolve
                                                          rejecter:reject];
}

// Memory management methods
RCT_EXPORT_METHOD(releaseCredential:(NSString *)credentialId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  
  // Call the Swift implementation
  [[CircleModuleSwift shared] releaseCredential:credentialId
                                       resolver:resolve
                                       rejecter:reject];
}

RCT_EXPORT_METHOD(releaseAccount:(NSString *)accountId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  
  // Call the Swift implementation
  [[CircleModuleSwift shared] releaseAccount:accountId
                                    resolver:resolve
                                    rejecter:reject];
}

@end 