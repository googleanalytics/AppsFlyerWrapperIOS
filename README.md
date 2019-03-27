# Google Analytics for Firebase Wrapper for AppsFlyer

_Copyright (c) 2019 Google Inc. All rights reserved._

The __Google Analytics for Firebase__ wrapper for AppsFlyer allows developers to
easily send information to both the AppsFlyer and Google Analytics for Firebase
backends.

## Using the Wrapper

In order to use the AppsFlyer wrapper:

1.  [Follow the steps here](https://firebase.google.com/docs/analytics/ios/start)
    to set up the Google Analytics for Firebase SDK in your app.
2.  Copy the source files inside the AppsFlyerWrapper directory (ignoring
    subdirectories) into your project.
3.  Replace supported references to `[AppsFlyerTracker sharedInstance]` with
    `[AppsFlyerTrackerWrapper sharedInstance]`;

Some methods are not supported by the wrapper. For these methods, directly call
the base implementation in `[AppsFlyerTracker sharedInstance]`.

### Supported Methods

The following API methods and properties are supported in the AppsFlyer wrapper.
Use the wrapper by replacing `[AppsFlyerTracker sharedTracker]` in these
instances with `[AppsFlyerTrackerWrapper sharedTracker]`:

#### Methods

*   `[[AppsFlyerTracker sharedTracker] registerUninstall:]`
*   `[[AppsFlyerTracker sharedTracker] trackEvent: withValue:]`
*   `[[AppsFlyerTracker sharedTracker] trackEvent: withValues:]`

#### Properties

*   `[AppsFlyerTracker sharedTracker].currencyCode`
*   `[AppsFlyerTracker sharedTracker].customerUserID`
*   `[AppsFlyerTracker sharedTracker].deviceTrackingDisabled`
*   `[AppsFlyerTracker sharedTracker].minTimeBetweenSessions`

### Using With Swift

In order to use the AppsFlyer wrapper with a Swift project, make sure your
project has a
[bridging header](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/importing_objective-c_into_swift).
In the bridging header file, add the line `#import "AppsFlyerTrackerWrapper.h"`.
This will allow you to use AppsFlyerTrackerWrapper like a normal Swift class.
