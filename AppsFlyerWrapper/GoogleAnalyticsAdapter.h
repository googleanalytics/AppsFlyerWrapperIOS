// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
// in compliance with the License. You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under the License
// is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
// or implied. See the License for the specific language governing permissions and limitations under
// the License.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Specifies how events and parameters for a given SDK should be mapped to events and parameters in
// the Google Analytics for Firebase SDK.
@protocol SdkAdapter <NSObject>
- (NSString *)sanitizedNamePrefix;
- (NSString *)wrapperParameterValue;
- (NSString *)emptyEventName;
- (NSString *)emptyParameterName;
- (NSString *)emptyUserPropertyName;
- (NSDictionary<NSString *, NSString *> *)eventMap;
- (NSDictionary<NSString *, NSString *> *)parameterMap;
@end

// Translates SDK-specified calls and events into a format suitable for the Google Analytics for
// Firebase SDK.
@interface GoogleAnalyticsAdapter : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSdkAdapter:(id<SdkAdapter>)adapter;
- (void)logEventWithName:(nullable NSString *)name
              parameters:(nullable NSDictionary<NSString *, id> *)parameters;
- (void)setUserPropertyString:(nullable NSString *)value forName:(nullable NSString *)name;
- (void)setUserID:(nullable NSString *)userID;
- (void)setAnalyticsCollectionEnabled:(BOOL)enabled;
- (void)setSessionTimeoutInterval:(NSTimeInterval)sessionTimeoutInterval;
@end

NS_ASSUME_NONNULL_END
