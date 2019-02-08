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

#import "GoogleAnalyticsAdapter.h"
#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <FirebaseCore/FIRAnalyticsConfiguration.h>

@implementation GoogleAnalyticsAdapter {
  id<SdkAdapter> _sdkAdapter;
  NSArray<NSString *> *_reservedEventNames;
  NSArray<NSString *> *_reservedParameterNames;
  NSArray<NSString *> *_reservedNamePrefixes;
  NSString *_wrapperParameterName;
  int _maxParameterCount;
  int _maxParameterNameLength;
  int _maxParameterStringValueLength;
  int _maxEventNameLength;
  int _maxUserIDValueLength;
  NSCharacterSet *_restrictedCharacters;
  NSCharacterSet *_permittedCharactersNoUnderscore;
  NSCharacterSet *_permittedStartingCharacters;
}

- (instancetype)initWithSdkAdapter:(id<SdkAdapter>)adapter {
  self = [super init];
  if (self) {
    _sdkAdapter = adapter;
    _reservedNamePrefixes = @[ @"firebase_", @"ga_", @"google_" ];
    _reservedEventNames = @[
      @"ad_activeview",
      @"ad_click",
      @"ad_exposure",
      @"ad_impression",
      @"ad_query",
      @"adunit_exposure",
      @"app_clear_data",
      @"app_exception",
      @"app_install",
      @"app_remove",
      @"app_update",
      @"app_upgrade",
      @"dynamic_link_app_open",
      @"dynamic_link_app_update",
      @"dynamic_link_first_open",
      @"error",
      @"first_open",
      @"first_visit",
      @"in_app_purchase",
      @"notification_dismiss",
      @"notification_foreground",
      @"notification_open",
      @"notification_receive",
      @"notification_send",
      @"os_update",
      @"screen_view",
      @"session_start",
      @"user_engagement"
    ];
    _wrapperParameterName = @"api_wrapper";
    _reservedParameterNames = @[ _wrapperParameterName ];
    _maxParameterCount = 25;
    _maxParameterNameLength = 40;
    _maxParameterStringValueLength = 100;
    _maxEventNameLength = 40;
    _maxUserIDValueLength = 256;

    NSMutableCharacterSet *permittedCharacters = [NSCharacterSet letterCharacterSet].mutableCopy;
    // Non-base characters are included with the letter character set, but are not permitted.
    NSCharacterSet *invertedNonBaseCharacterSet = [NSCharacterSet nonBaseCharacterSet].invertedSet;
    [permittedCharacters formIntersectionWithCharacterSet:invertedNonBaseCharacterSet];
    // Non-base letters are allowed at the start of the string.
    _permittedStartingCharacters = [permittedCharacters copy];

    // Numbers are allowed, just not at the start.
    [permittedCharacters formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    _permittedCharactersNoUnderscore = [permittedCharacters copy];

    // Underscores are allowed, but not at the start.
    [permittedCharacters
        formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"_"]];

    _restrictedCharacters = permittedCharacters.invertedSet;
  }
  return self;
}

- (void)logEventWithName:(NSString *)rawName
              parameters:(nullable NSDictionary<NSString *, id> *)rawParameters {
  NSString *name = [self sanitizeName:[self mapName:rawName mappings:_sdkAdapter.eventMap]
                            maxLength:_maxEventNameLength
                         defaultValue:_sdkAdapter.emptyEventName
                        reservedNames:_reservedEventNames];
  if (!name.length) {
    NSLog(@"Event %@ sanitized to '_'. Dropping event.", rawName);
    return;
  }

  NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
  parameters[_wrapperParameterName] = [_sdkAdapter wrapperParameterValue];
  for (id key in rawParameters) {
    if (parameters.count >= _maxParameterCount) {
      break;
    }
    if (![key isKindOfClass:[NSString class]]) {
      NSLog(@"Parameter name is not a string: %@. Dropping param.", key);
      continue;
    }
    NSString *sanitizedName = [self sanitizeName:[self mapName:key
                                                      mappings:_sdkAdapter.parameterMap]
                                       maxLength:_maxParameterNameLength
                                    defaultValue:_sdkAdapter.emptyParameterName
                                   reservedNames:_reservedParameterNames];
    if (!sanitizedName.length) {
      NSLog(@"Parameter %@ sanitized to '_'. Dropping param.", key);
      continue;
    }

    id value = [self sanitizeParameterValue:rawParameters[key]];
    if (value) {
      parameters[sanitizedName] = value;
    }
  }
  [FIRAnalytics logEventWithName:name parameters:parameters];
}

- (void)setUserPropertyString:(NSString *)value forName:(NSString *)name {
  [FIRAnalytics setUserPropertyString:value forName:name];
}

- (void)setAnalyticsCollectionEnabled:(BOOL)enabled {
  FIRAnalyticsConfiguration *config = [FIRAnalyticsConfiguration sharedInstance];
  [config setAnalyticsCollectionEnabled:enabled];
  [[FIRAnalyticsConfiguration sharedInstance] setAnalyticsCollectionEnabled:enabled];
}

- (void)setUserID:(NSString *)userID {
  [FIRAnalytics setUserID:userID];
}

- (void)setSessionTimeoutInterval:(NSTimeInterval)sessionTimeoutInterval {
  [[FIRAnalyticsConfiguration sharedInstance] setSessionTimeoutInterval:sessionTimeoutInterval];
}

- (NSString *)sanitizeName:(NSString *)name
                 maxLength:(int)maxLength
              defaultValue:(NSString *)defaultValue
             reservedNames:(NSArray<NSString *> *)reservedNames {
  if (name.length == 0) {
    return defaultValue;
  }

  // Replace all non-permitted character sequences with an underscore.
  NSArray<NSString *> *components =
      [name componentsSeparatedByCharactersInSet:_restrictedCharacters];

  NSMutableString *mutableSanitizedName = [NSMutableString string];
  BOOL nonEmptyPrevious = YES;
  for (int i = 0; i < components.count; i++) {
    NSString *component = components[i];
    // Subsequent empty strings should not result in "_" being appended.
    if (nonEmptyPrevious && (i > 0 || component.length == 0)) {
      [mutableSanitizedName appendString:@"_"];
    }
    [mutableSanitizedName appendString:component];
    nonEmptyPrevious = component.length;
  }
  NSString *sanitizedName = [mutableSanitizedName copy];

  // If there is no non-underscore character, don't send the event.
  if ([sanitizedName rangeOfCharacterFromSet:_permittedCharactersNoUnderscore].location ==
      NSNotFound) {
    return nil;
  }

  BOOL startsWithAllowedCharacter =
      [sanitizedName rangeOfCharacterFromSet:_permittedStartingCharacters].location == 0;
  if (!startsWithAllowedCharacter || [reservedNames containsObject:sanitizedName] ||
      [self nameStartsWithReservedPrefix:sanitizedName]) {
    // If a name starts with a reserved prefix, is a reserved name, or starts with a non-alphabetic
    // character, attach the prefix at the beginning.
    sanitizedName =
        [NSString stringWithFormat:@"%@%@", _sdkAdapter.sanitizedNamePrefix, sanitizedName];
  }

  return [self trimString:sanitizedName toLength:maxLength];
}

- (BOOL)nameStartsWithReservedPrefix:(NSString *)name {
  NSString *lowercaseName = [name lowercaseString];
  for (NSString *prefix in _reservedNamePrefixes) {
    if ([lowercaseName hasPrefix:prefix]) {
      return YES;
    }
  }
  return NO;
}

- (NSString *)mapName:(NSString *)name mappings:(NSDictionary<NSString *, NSString *> *)mappings {
  return mappings[name] ? mappings[name] : name;
}

- (NSString *)trimString:(NSString *)string toLength:(int)length {
  if ([self stringLength:string] <= length) {
    return string;
  }

  const size_t byteLength = length * sizeof(UTF32Char);

  uint8_t *trimmedValueUTF32Bytes = malloc(byteLength);
  if (!trimmedValueUTF32Bytes) {
    NSLog(@"Error trimming %@ to length %d", string, length);
    return [string substringToIndex:length];
  }

  [string getBytes:trimmedValueUTF32Bytes
           maxLength:byteLength
          usedLength:NULL
            encoding:NSUTF32LittleEndianStringEncoding
             options:0
               range:NSMakeRange(0, string.length)
      remainingRange:NULL];

  NSString *trimmedValue = [[NSString alloc] initWithBytesNoCopy:trimmedValueUTF32Bytes
                                                          length:byteLength
                                                        encoding:NSUTF32LittleEndianStringEncoding
                                                    freeWhenDone:NO];
  free(trimmedValueUTF32Bytes);

  if (!trimmedValue) {
    NSLog(@"Error trimming %@ to length %d", string, length);
    return [string substringToIndex:length];
  }

  return trimmedValue;
}

- (NSUInteger)stringLength:(NSString *)string {
  return [string lengthOfBytesUsingEncoding:NSUTF32LittleEndianStringEncoding] / sizeof(UTF32Char);
}

- (id)sanitizeParameterValue:(id)object {
  if ([object isKindOfClass:[NSNumber class]]) {
    return object;
  }
  if ([object isKindOfClass:[NSString class]]) {
    return [self trimString:object toLength:_maxParameterStringValueLength];
  }
  if ([object respondsToSelector:@selector(description)]) {
    return [self trimString:[object description] toLength:_maxParameterStringValueLength];
  }

  return nil;
}

@end
