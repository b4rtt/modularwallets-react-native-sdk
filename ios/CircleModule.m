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

RCT_EXPORT_METHOD(sendUserOperation:(NSString *)accountAddress
                  to:(NSString *)to
                  value:(NSString *)value
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  
  // Call the Swift implementation
  [[CircleModuleSwift shared] sendUserOperationWithAccountAddress:accountAddress
                                                          to:to
                                                          value:value
                                                          resolver:resolve
                                                          rejecter:reject];
}

@end 