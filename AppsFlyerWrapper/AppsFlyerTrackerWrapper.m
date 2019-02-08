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

#import "AppsFlyerTrackerWrapper.h"
#import <AppsFlyerLib/AppsFlyerTracker.h>
#import "AppsFlyerGoogleAnalyticsAdapter.h"
#import "GoogleAnalyticsAdapter.h"

@implementation AppsFlyerTrackerWrapper {
  AppsFlyerTracker *_tracker;
  GoogleAnalyticsAdapter *_googleAnalytics;
  NSString *_currencyCode;
  NSString *_defaultCurrency;
}

+ (AppsFlyerTrackerWrapper *)sharedTracker {
  static AppsFlyerTrackerWrapper *sharedTracker = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedTracker = [[self alloc] init];
  });

  return sharedTracker;
}

- (instancetype)init {
  return [self
      initWithAppsFlyer:[AppsFlyerTracker sharedTracker]
        googleAnalytics:[[GoogleAnalyticsAdapter alloc]
                            initWithSdkAdapter:[[AppsFlyerGoogleAnalyticsAdapter alloc] init]]];
}

- (instancetype)initWithAppsFlyer:(AppsFlyerTracker *)tracker
                  googleAnalytics:(GoogleAnalyticsAdapter *)analyticsAdapter {
  self = [super init];
  if (self) {
    _tracker = tracker;
    _googleAnalytics = analyticsAdapter;
    _defaultCurrency = @"USD";
  }

  return self;
}

- (void)setCustomerUserID:(NSString *)customerUserID {
  [_googleAnalytics setUserID:customerUserID];
  _tracker.customerUserID = customerUserID;
}

- (NSString *)customerUserID {
  return _tracker.customerUserID;
}

- (void)trackEvent:(NSString *)eventName withValues:(NSDictionary *)values {
  NSMutableDictionary *gaValues = [values mutableCopy];
  if (gaValues && !gaValues[AFEventParamCurrency] && gaValues[AFEventParamRevenue]) {
    gaValues[AFEventParamCurrency] = _currencyCode ? _currencyCode : _defaultCurrency;
  }
  [_googleAnalytics logEventWithName:eventName parameters:[gaValues copy]];
  [_tracker trackEvent:eventName withValues:values];
}

- (void)trackEvent:(NSString *)eventName withValue:(NSString *)value {
  [_googleAnalytics logEventWithName:eventName parameters:@{@"value" : value}];
  [_tracker trackEvent:eventName withValue:value];
}

- (void)setMinTimeBetweenSessions:(NSUInteger)timeout {
  [_googleAnalytics setSessionTimeoutInterval:timeout];
  _tracker.minTimeBetweenSessions = timeout;
}

- (NSUInteger)minTimeBetweenSessions {
  return _tracker.minTimeBetweenSessions;
}

- (void)setCurrencyCode:(NSString *)currencyCode {
  _currencyCode = currencyCode;
  _tracker.currencyCode = currencyCode;
}

- (NSString *)currencyCode {
  return _tracker.currencyCode;
}

- (void)setDeviceTrackingDisabled:(BOOL)deviceTrackingDisabled {
  [_googleAnalytics setAnalyticsCollectionEnabled:!deviceTrackingDisabled];
  _tracker.deviceTrackingDisabled = deviceTrackingDisabled;
}

- (BOOL)deviceTrackingDisabled {
  return _tracker.deviceTrackingDisabled;
}

- (void)registerUninstall:(NSData *)deviceToken {
  [_googleAnalytics logEventWithName:@"uninstall" parameters:nil];
  [_tracker registerUninstall:deviceToken];
}

@end
