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

// Wraps calls to AppsFlyerTracker in order to log them in both Google Analytics for Firebase and
// AppsFlyer.
@interface AppsFlyerTrackerWrapper : NSObject
// Wraps calls to [AppsFlyerTracker sharedTracker].
+ (AppsFlyerTrackerWrapper *)sharedTracker NS_SWIFT_NAME(shared());

// Wraps calls to the AppsFlyerTracker customerUserId property.
@property(nonatomic, strong, setter=setCustomerUserID:) NSString *customerUserID;
// Wraps calls to the AppsFlyerTracker currencyCode property.
@property(nonatomic, strong) NSString *currencyCode;
// Wraps calls to the AppsFlyerTracker appsFlyerDevKey property.
@property(nonatomic, strong, setter=setAppsFlyerDevKey:) NSString *appsFlyerDevKey;
// Wraps calls to the AppsFlyerTracker minTimeBetweenSessions property.
@property(atomic) NSUInteger minTimeBetweenSessions;
// Wraps calls to the AppsFlyerTracker deviceTrackingDisabled property.
@property BOOL deviceTrackingDisabled;

// Wraps calls to [AppsFlyerTracker trackEvent:withValue:].
- (void)trackEvent:(NSString *)eventName withValue:(NSString *)value __attribute__((deprecated));
// Wraps calls to [AppsFlyerTracker trackEvent:withValues:].
- (void)trackEvent:(NSString *)eventName withValues:(NSDictionary *)values;

// Wraps calls to [AppsFlyerTracker registerUninstall:].
- (void)registerUninstall:(NSData *)deviceToken;

@end
