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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import <AppsFlyerLib/AppsFlyerTracker.h>
#import "AppsFlyerTrackerWrapper.h"
#import "GoogleAnalyticsAdapter.h"

@interface AppsFlyerTrackerWrapper ()
- (instancetype)initWithAppsFlyer:(AppsFlyerTracker *)tracker
                  googleAnalytics:(GoogleAnalyticsAdapter *)analyticsAdapter;
@end

@interface AppsFlyerTrackerWrapperTests : XCTestCase
@property(nonatomic, strong) id appsFlyerMock;
@property(nonatomic, strong) id googleAnalyticsMock;
@property(nonatomic, strong) AppsFlyerTrackerWrapper *tracker;
@end

@implementation AppsFlyerTrackerWrapperTests

- (void)setUp {
  [super setUp];

  self.appsFlyerMock = OCMClassMock([AppsFlyerTracker class]);
  self.googleAnalyticsMock = OCMClassMock([GoogleAnalyticsAdapter class]);
  self.tracker = [[AppsFlyerTrackerWrapper alloc] initWithAppsFlyer:self.appsFlyerMock
                                                    googleAnalytics:self.googleAnalyticsMock];
}

- (void)tearDown {
  self.appsFlyerMock = nil;
  self.googleAnalyticsMock = nil;
  self.tracker = nil;

  [super tearDown];
}

- (void)testSetCustomerUserId {
  NSString *userID = @"customer_id1";
  self.tracker.customerUserID = userID;
  OCMVerify([self.appsFlyerMock setCustomerUserID:userID]);
  OCMVerify([self.googleAnalyticsMock setUserID:userID]);
}

- (void)testCustomerUserId {
  OCMStub([self.appsFlyerMock customerUserID]).andReturn(@"customer_id2");
  NSString *userID = self.tracker.customerUserID;
  OCMVerify([self.appsFlyerMock customerUserID]);
  XCTAssertEqual(userID, @"customer_id2");
}

- (void)testSetCurrencyCode {
  NSString *currency = @"GBP";
  self.tracker.currencyCode = currency;
  OCMVerify([self.appsFlyerMock setCurrencyCode:currency]);
}

- (void)testCurrencyCode {
  OCMStub([self.appsFlyerMock currencyCode]).andReturn(@"GBP");
  NSString *currency = self.tracker.currencyCode;
  OCMVerify([self.appsFlyerMock currencyCode]);
  XCTAssertEqual(currency, @"GBP");
}

- (void)testSetAppsFlyerDevKey {
  NSString *appsFlyerDevKey = @"this-is-a-dev-key";
  self.tracker.appsFlyerDevKey = appsFlyerDevKey;
  OCMVerify([self.appsFlyerMock setAppsFlyerDevKey:appsFlyerDevKey]);
  OCMVerify([self.googleAnalyticsMock setUserPropertyString:@"this-is-a-dev-key"
                                                    forName:@"af_dev_key"]);
}

- (void)testAppsFlyerDevKey {
  OCMStub([self.appsFlyerMock appsFlyerDevKey]).andReturn(@"this-is-a-dev-key");
  NSString *appsFlyerDevKey = self.tracker.appsFlyerDevKey;
  OCMVerify([self.appsFlyerMock appsFlyerDevKey]);
  XCTAssertEqual(appsFlyerDevKey, @"this-is-a-dev-key");
}

- (void)testSetMinTimeBetweenSessions {
  NSUInteger time = 50;
  self.tracker.minTimeBetweenSessions = time;
  OCMVerify([self.appsFlyerMock setMinTimeBetweenSessions:time]);
  OCMVerify([self.googleAnalyticsMock setSessionTimeoutInterval:time]);
}

- (void)testMinTimeBetweenSessions {
  OCMStub([self.appsFlyerMock minTimeBetweenSessions]).andReturn(50);
  NSUInteger time = self.tracker.minTimeBetweenSessions;
  OCMVerify([self.appsFlyerMock minTimeBetweenSessions]);
  XCTAssertEqual(time, 50);
}

- (void)testSetDeviceTrackingDisabled {
  self.tracker.deviceTrackingDisabled = YES;
  OCMVerify([self.appsFlyerMock setDeviceTrackingDisabled:YES]);
  OCMVerify([self.googleAnalyticsMock setAnalyticsCollectionEnabled:NO]);
}

- (void)testDeviceTrackingDisabled {
  OCMStub([self.appsFlyerMock deviceTrackingDisabled]).andReturn(YES);
  XCTAssertTrue(self.tracker.deviceTrackingDisabled);
  OCMVerify([self.appsFlyerMock deviceTrackingDisabled]);
}

- (void)testTrackEventWithParameters {
  NSString *eventName = @"test_event";
  NSDictionary *parameters = @{@"param1" : @"val1", @"param2" : @5};
  [self.tracker trackEvent:eventName withValues:parameters];
  OCMVerify([self.appsFlyerMock trackEvent:eventName withValues:parameters]);
  OCMVerify([self.googleAnalyticsMock logEventWithName:eventName parameters:parameters]);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)testTrackEventWithValue {
  NSString *eventName = @"test_event";
  NSString *value = @"val";
  NSDictionary *parameters = @{@"value" : value};
  [self.tracker trackEvent:eventName withValue:value];
  OCMVerify([self.appsFlyerMock trackEvent:eventName withValue:value]);
  OCMVerify([self.googleAnalyticsMock logEventWithName:eventName parameters:parameters]);
}
#pragma clang diagnostic pop

- (void)testRegisterUninstall {
  [self.tracker registerUninstall:nil];
  OCMVerify([self.appsFlyerMock registerUninstall:nil]);
  OCMVerify([self.googleAnalyticsMock logEventWithName:@"uninstall" parameters:nil]);
}

@end
