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

#import "AppsFlyerGoogleAnalyticsAdapter.h"
#import <AppsFlyerLib/AppsFlyerTracker.h>
#import <FirebaseAnalytics/FirebaseAnalytics.h>

@interface AppsFlyerGoogleAnalyticsAdapter ()
@property(nonatomic, strong) NSString *sanitizedNamePrefix;
@property(nonatomic, strong) NSString *wrapperParameterValue;
@property(nonatomic, strong) NSString *emptyEventName;
@property(nonatomic, strong) NSString *emptyParameterName;
@property(nonatomic, strong) NSString *emptyUserPropertyName;
@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *eventMap;
@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *parameterMap;
@end

@implementation AppsFlyerGoogleAnalyticsAdapter

- (instancetype)init {
  self = [super init];
  if (self) {
    _sanitizedNamePrefix = @"af_";
    _wrapperParameterValue = @"af";
    _emptyEventName = @"af_unnamed_event";
    _emptyParameterName = @"af_unnamed_parameter";
    _emptyUserPropertyName = @"af_unnamed_user_property";

    _eventMap = @{
      AFEventLevelAchieved : kFIREventLevelUp,
      AFEventAddPaymentInfo : kFIREventAddPaymentInfo,
      AFEventAddToCart : kFIREventAddToCart,
      AFEventAddToWishlist : kFIREventAddToWishlist,
      AFEventTutorial_completion : kFIREventTutorialComplete,
      AFEventInitiatedCheckout : kFIREventBeginCheckout,
      AFEventPurchase : kFIREventEcommercePurchase,
      AFEventSearch : kFIREventSearch,
      AFEventSpentCredits : kFIREventSpendVirtualCurrency,
      AFEventAchievementUnlocked : kFIREventUnlockAchievement,
      AFEventContentView : kFIREventViewItem,
      AFEventShare : kFIREventShare,
      AFEventLogin : kFIREventLogin
    };

    _parameterMap = @{
      AFEventParamLevel : kFIRParameterLevel,
      AFEventParamScore : kFIRParameterScore,
      AFEventParamSuccess : kFIRParameterSuccess,
      AFEventParamPrice : kFIRParameterPrice,
      AFEventParamContentType : kFIRParameterContentType,
      AFEventParamContentId : kFIRParameterItemID,
      AFEventParamCurrency : kFIRParameterCurrency,
      AFEventParamQuantity : kFIRParameterQuantity,
      AFEventParamRegistrationMethod : kFIRParameterMethod,
      AFEventParamSearchString : kFIRParameterSearchTerm,
      AFEventParamDateA : kFIRParameterStartDate,
      AFEventParamDateB : kFIRParameterEndDate,
      AFEventParamDestinationA : kFIRParameterOrigin,
      AFEventParamDestinationB : kFIRParameterDestination,
      AFEventParamEventStart : kFIRParameterStartDate,
      AFEventParamEventEnd : kFIRParameterEndDate,
      AFEventParamRevenue : kFIRParameterValue
    };
  }

  return self;
}

@end
