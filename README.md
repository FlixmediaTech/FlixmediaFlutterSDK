# FlixMedia Flutter SDK

The **FlixMedia Flutter SDK** provides access to the FlixMedia SDK inside Flutter apps (iOS and Android).  
It allows you to display syndicated product content directly in Flutter using a simple widget.

## Features
- Fetches syndicated HTML content from the FlixMedia SDK.
- Displays content inside a Flutter `InAppWebView`.
- Automatic height adjustment based on content.
- Reports visible viewport metrics to the SDK for analytics and tracking.
- Supports parameterized product requests (`mpn`, `ean`, `distId`/`distributorId`, `isoCode`, `flIsoCode`, `brand`, `title`, `price`, `currency`).
- Supports sending app-side log events to Flix tracking (`callLogFromApp`).

## Requirements
- Flutter 3.35+ with Dart 3.9+ (Flutter 3.44+ for Swift Package Manager)
- iOS **15.6** or later  
- Android minSdk **21**+  
- Xcode 26.5+ (FlixMediaSDK 1.0.7 is built with Swift 6.3.2)

## Installation
1. Download and extract the **`flix_inpage`** package from Releases section
2. Copy the **`flix_inpage`** plugin folder into your Flutter project (at the same level as your app folder).  
3. In your pubspec.yaml, add the plugin using a local path:
```
dependencies:
  flutter:
    sdk: flutter
  flix_inpage:
    path: ../flix_inpage
```

### iOS: Swift Package Manager

The plugin supports Swift Package Manager and CocoaPods. With Flutter 3.44 or
later, SPM is enabled by default. Flutter discovers
`ios/flix_inpage/Package.swift` automatically; do not add FlixMediaSPM manually
to the app's Xcode project.

Set the app's iOS deployment target to **15.6** or later, then run:

```sh
flutter pub get
flutter build ios --no-codesign
```

SPM downloads FlixMediaSDK **1.0.7** from
[FlixMediaSPM](https://github.com/FlixmediaTech/FlixMediaSPM) using an exact
version, so the first build requires access to GitHub. CocoaPods uses the same
SDK version bundled with this plugin.

The plugin uses **`flutter_inappwebview: 6.2.0-beta.3`**, including its matching
**`flutter_inappwebview_ios: 1.2.0-beta.3`** implementation with SPM support.
The 6.1.5 facade is incompatible with the newer platform interface, so the
WebView packages are upgraded together. This is a prerelease on both iOS and
Android; include JavaScript handlers, scrolling, links, and media playback in
your app's regression testing. No application-level `dependency_overrides`
are required.

### iOS: CocoaPods

The `.podspec` remains supported. For Flutter 3.35–3.43, use CocoaPods. To use
CocoaPods on newer Flutter versions, set this in the **app's** `pubspec.yaml`:

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

Set both the Xcode deployment target and the `ios/Podfile` platform to iOS 15.6
or later. The Dart API is the same with either package manager.

## Initialization
Before rendering any content, you must initialize the SDK with your FlixMedia credentials.
Update your **main.dart**:

```
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlixBridge.initialize(
    username: 'your-username',
    password: 'your-password',
  );
  runApp(const MaterialApp(home: HomePage()));
}
```

Alternatively, initialize the SDK with a retailer-provided token provider. Use this when your app receives Flix access tokens from your backend instead of using a username and password in the app.

```
import 'package:flix_inpage/flix_inpage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlixBridge.initializeWithTokenProvider(
    tokenProvider: () async {
      final token = await retailerBackend.fetchFlixToken();

      return FlixTokenResult(
        idToken: token.idToken,
        expiresAt: token.expiresAt, // Unix timestamp in seconds or ISO-8601 string.
      );
    },
    useSandbox: false,
  );

  runApp(const MaterialApp(home: HomePage()));
}
```

The SDK calls `tokenProvider` during initialization. If the native iOS/Android SDK reports that the token expired while loading content, the Flutter SDK calls the same provider again and forwards the refreshed token automatically.

## Usage
The plugin exposes a widget:

**FlixInpageHtmlView**

Displays syndicated product content in a Flutter app.

| Parameter | Description |
|---|---|
| `productParams` | Map with product parameters. See full list below |
| `baseURL` | Base URL passed to the SDK request |
| `parentScrollController` | `ScrollController` of the parent `SingleChildScrollView` — enables SDK-initiated scroll-to-position |
| `controller` | `FlixInpageHtmlViewController` for programmatic control (e.g. `callLogFromApp`) |
| `onError` | Callback invoked when the SDK request or WebView fails |

Supported `productParams` keys:

| Key | Description |
|---|---|
| `mpn` | Manufacturer part number |
| `ean` | EAN code |
| `distId` | Distributor ID |
| `isoCode` | Country code |
| `flIsoCode` | Content language code |
| `brand` | Product brand |
| `title` | Product title |
| `price` | Product price (string or number) |
| `currency` | Currency code, e.g. `USD` |

Example:

```
FlixInpageHtmlView(
    productParams: {
        "mpn": "lego_10297",
        "ean": "cache001",
        "distributorId": 6,
        "isoCode": "it",
        "flIsoCode": "en",
        "brand": "LEGO",
        "title": "Boutique Hotel",
        "price": 199.99,
        "currency": "EUR",
    },
    baseURL: "https://www.example.com",
    onError: (error) {
        debugPrint("FlixInpage error: $error");
    },
)
```

## Logger / tracking logs
To send app-side log messages to the Flix tracking bridge, pass a controller and call `callLogFromApp`.

```
final flixController = FlixInpageHtmlViewController();

FlixInpageHtmlView(
  controller: flixController,
  productParams: {
    "mpn": "lego_10297",
    "distributorId": 6,
    "isoCode": "it",
    "flIsoCode": "en",
  },
);

await flixController.callLogFromApp("cartButtonTapped");
```

## Notes
Android uses the FlixMedia Android SDK from Maven.
Debugging mode allows enabling isInspectable for WebView inspection (iOS 16.4+).
Make sure your FlixMedia SDK credentials are initialized before loading content.

## License
© FlixMedia. All rights reserved.
