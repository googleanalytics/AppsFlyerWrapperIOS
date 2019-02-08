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

#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <FirebaseCore/FIRAnalyticsConfiguration.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "AppsFlyerGoogleAnalyticsAdapter.h"
#import "GoogleAnalyticsAdapter.h"

@interface GoogleAnalyticsAdapter ()
- (NSString *)sanitizeName:(NSString *)name
                 maxLength:(int)maxLength
              defaultValue:(NSString *)defaultValue
             reservedNames:(NSArray<NSString *> *)reservedNames;
- (NSString *)mapName:(NSString *)name mappings:(NSDictionary<NSString *, NSString *> *)mappings;
@end

@interface GoogleAnalyticsAdapterTests : XCTestCase
@property(nonatomic, strong) id analyticsMock;
@property(nonatomic, strong) id analyticsConfigMock;
@property(nonatomic, strong) GoogleAnalyticsAdapter *adapter;
@end

@implementation GoogleAnalyticsAdapterTests

- (void)setUp {
  [super setUp];
  self.analyticsMock = OCMClassMock([FIRAnalytics class]);
  self.analyticsConfigMock = OCMPartialMock([FIRAnalyticsConfiguration sharedInstance]);
  self.adapter = [[GoogleAnalyticsAdapter alloc]
      initWithSdkAdapter:[[AppsFlyerGoogleAnalyticsAdapter alloc] init]];
}

- (void)tearDown {
  self.analyticsMock = nil;
  self.analyticsConfigMock = nil;
  self.adapter = nil;
  [super tearDown];
}

- (void)testLogEvent {
  [self.adapter logEventWithName:@"test_event" parameters:nil];
  [self verifyEventWithName:@"test_event" parameters:nil];
}

- (void)testLogEventWithNilName {
  [self.adapter logEventWithName:nil parameters:nil];
  [self verifyEventWithName:@"af_unnamed_event" parameters:nil];
}

- (void)testLogEventWithParameters {
  NSArray *array = @[ @5, @3, @2 ];
  [self.adapter logEventWithName:@"event"
                      parameters:@{@"param1" : @5, @"param2" : @"str", @"param3" : array}];
  [self verifyEventWithName:@"event"
                 parameters:@{@"param1" : @5, @"param2" : @"str", @"param3" : [array description]}];
}

- (void)testLogEventWithSetApiWrapper {
  [self.adapter logEventWithName:@"event" parameters:@{@"api_wrapper" : @"other_val"}];
  [self verifyEventWithName:@"event" parameters:@{@"af_api_wrapper" : @"other_val"}];
}

- (void)testLogEventWithJustEnoughParameters {
  NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
  for (int i = 0; i < 24; i++) {
    parameters[[NSString stringWithFormat:@"param%d", i]] =
        [NSString stringWithFormat:@"value%d", i];
  }
  [self.adapter logEventWithName:@"event" parameters:parameters];
  [self verifyEventWithName:@"event" parameters:parameters];
}

- (void)testLogEventWithTooManyParameters {
  NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
  for (int i = 0; i < 25; i++) {
    parameters[[NSString stringWithFormat:@"param%d", i]] =
        [NSString stringWithFormat:@"value%d", i];
  }
  [self.adapter logEventWithName:@"event" parameters:parameters];
  OCMVerify([self.analyticsMock logEventWithName:@"event"
                                      parameters:[OCMArg checkWithBlock:^BOOL(id obj) {
                                        NSDictionary *parameters = (NSDictionary *)obj;
                                        return parameters.count == 25 &&
                                               [parameters[@"api_wrapper"] isEqual:@"af"];
                                      }]]);
}

- (NSString *)unicodeStringWithCharacter:(NSString *)character length:(int)length {
  NSMutableString *string = [NSMutableString string];
  for (int i = 0; i < length; i++) {
    [string appendString:character];
  }
  return [string copy];
}

- (void)testLogEventWithMultipleCodePointEmoji {
  NSString *name = [self unicodeStringWithCharacter:@"𠜎" length:41];
  [self.adapter logEventWithName:name
                      parameters:@{
                        [self unicodeStringWithCharacter:@"𠜎" length:41] :
                            [self unicodeStringWithCharacter:@"😽" length:101]
                      }];

  [self verifyEventWithName:[self unicodeStringWithCharacter:@"𠜎" length:40]
                 parameters:@{
                   [self unicodeStringWithCharacter:@"𠜎" length:40] :
                       [self unicodeStringWithCharacter:@"😽" length:100]
                 }];
}

- (void)testSetUserID {
  [self.adapter setUserID:@"test_id"];
  OCMVerify([self.analyticsMock setUserID:@"test_id"]);
}

- (void)testSetAnalyticsCollectionEnabled {
  [self.adapter setAnalyticsCollectionEnabled:YES];
  OCMVerify([self.analyticsConfigMock setAnalyticsCollectionEnabled:YES]);
}

- (void)testSetSessionTimeoutDuration {
  [self.adapter setSessionTimeoutInterval:50];
  OCMVerify([self.analyticsConfigMock setSessionTimeoutInterval:50]);
}

- (void)testSanitizeName {
  NSString *sanitizedName = [self.adapter sanitizeName:@"name"
                                             maxLength:100
                                          defaultValue:nil
                                         reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"name");

  sanitizedName = [self.adapter sanitizeName:@"_name"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"af__name");
}

- (void)testSanitizeEmptyName {
  NSString *sanitizedName = [self.adapter sanitizeName:nil
                                             maxLength:100
                                          defaultValue:@"empty_name"
                                         reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"empty_name");

  sanitizedName = [self.adapter sanitizeName:@""
                                   maxLength:100
                                defaultValue:@"empty_name"
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"empty_name");

  sanitizedName = [self.adapter sanitizeName:@" "
                                   maxLength:100
                                defaultValue:@"empty_name"
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, nil);

  sanitizedName = [self.adapter sanitizeName:@"     "
                                   maxLength:100
                                defaultValue:@"empty_name"
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, nil);
}

- (void)testSanitizeRestrictedPrefix {
  NSString *sanitizedName = [self.adapter sanitizeName:@"ga_name"
                                             maxLength:100
                                          defaultValue:nil
                                         reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"af_ga_name");

  sanitizedName = [self.adapter sanitizeName:@"firebase_name"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"af_firebase_name");

  sanitizedName = [self.adapter sanitizeName:@"google_name"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"af_google_name");

  sanitizedName = [self.adapter sanitizeName:@"GA_name"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"af_GA_name");

  sanitizedName = [self.adapter sanitizeName:@"Firebase_name"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"af_Firebase_name");

  sanitizedName = [self.adapter sanitizeName:@"Google_name"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"af_Google_name");
}

- (void)testSanitizeNameWithTruncation {
  NSString *sanitizedName = [self.adapter sanitizeName:@"name"
                                             maxLength:4
                                          defaultValue:nil
                                         reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"name");

  sanitizedName = [self.adapter sanitizeName:@"name"
                                   maxLength:3
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"nam");

  sanitizedName = [self.adapter sanitizeName:@"ga_name"
                                   maxLength:7
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"af_ga_n");
}

- (void)testSanitizeNameWithInvalidCharacter {
  NSString *sanitizedName = [self.adapter sanitizeName:@"name?"
                                             maxLength:100
                                          defaultValue:nil
                                         reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"name_");

  sanitizedName = [self.adapter sanitizeName:@"name?!?!"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"name_");

  sanitizedName = [self.adapter sanitizeName:@"my-name"
                                   maxLength:7
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"my_name");

  sanitizedName = [self.adapter sanitizeName:@"my-!?!*name?"
                                   maxLength:7
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"my_name");

  sanitizedName = [self.adapter sanitizeName:@"ga!name"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"af_ga_name");

  sanitizedName = [self.adapter sanitizeName:@"!a" maxLength:9 defaultValue:nil reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"af__a");

  sanitizedName = [self.adapter sanitizeName:@"!@#$%^&*()"
                                   maxLength:9
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, nil);

  sanitizedName = [self.adapter sanitizeName:@"!@#$%^&*()"
                                   maxLength:8
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, nil);

  sanitizedName = [self.adapter sanitizeName:@"!_!" maxLength:9 defaultValue:nil reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, nil);

  sanitizedName = [self.adapter sanitizeName:@"!_a!"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"af___a_");
}

- (void)testSanitizeNameWithReservedNames {
  NSString *sanitizedName = [self.adapter sanitizeName:@"name"
                                             maxLength:100
                                          defaultValue:nil
                                         reservedNames:@[ @"name" ]];
  XCTAssertEqualObjects(sanitizedName, @"af_name");

  sanitizedName = [self.adapter sanitizeName:@"name"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[]];
  XCTAssertEqualObjects(sanitizedName, @"name");

  sanitizedName = [self.adapter sanitizeName:@"name"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[ @"restricted_name" ]];
  XCTAssertEqualObjects(sanitizedName, @"name");

  sanitizedName = [self.adapter sanitizeName:@"name"
                                   maxLength:100
                                defaultValue:nil
                               reservedNames:@[ @"Name" ]];
  XCTAssertEqualObjects(sanitizedName, @"name");
}

- (void)testMappedNames {
  NSDictionary *map = @{
    @"name1" : @"mapped1",
    @"name2" : @"mapped2",
  };

  XCTAssertEqualObjects([self.adapter mapName:@"name1" mappings:map], @"mapped1");
  XCTAssertEqualObjects([self.adapter mapName:@"name2" mappings:map], @"mapped2");
  XCTAssertEqualObjects([self.adapter mapName:@"name3" mappings:map], @"name3");
}

- (void)verifyEventWithName:(NSString *)name parameters:(NSDictionary<NSString *, id> *)parameters {
  NSMutableDictionary *allParameters =
      !parameters ? [NSMutableDictionary dictionary] : [parameters mutableCopy];
  // Wrapper sets the api_wrapper string on all events.
  allParameters[@"api_wrapper"] = @"af";
  OCMVerify([self.analyticsMock logEventWithName:name parameters:allParameters]);
}

@end
