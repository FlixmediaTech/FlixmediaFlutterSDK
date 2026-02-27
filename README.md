# FlixMedia Flutter Plugin

The **FlixMedia Flutter Plugin** provides access to the FlixMedia SDK inside Flutter apps (iOS and Android).  
It allows you to display syndicated product content directly in Flutter using a simple widget.

## Features
- Fetches syndicated HTML content from the FlixMedia SDK.
- Displays content inside a Flutter `InAppWebView`.
- Automatic height adjustment based on content.
- Reports visible viewport metrics to the SDK for analytics and tracking.
- Supports parameterized product requests (`mpn`, `ean`, `distId`, `isoCode`, `flIsoCode`).

## Requirements
- Flutter 3.0+  
- iOS **15.6** or later  
- Android minSdk **21**+  
- Xcode 15+  
- Swift 5  

## Installation
1. Copy the **`flix_inpage`** plugin folder into your Flutter project (at the same level as your app folder).  
2. In your pubspec.yaml, add the plugin using a local path:
```
dependencies:
  flutter:
    sdk: flutter
  flix_inpage:
    path: ../flix_inpage
```
3. Android support is available, but requires the FlixMedia Android SDK **AAR** to be published to your local Maven repository (`mavenLocal`) before building (the plugin resolves `com.flixmedia:flixmediasdk:1.0.4` from `mavenLocal()`).

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

## Usage
The plugin exposes a widget:

**FlixInpageHtmlView**

Displays syndicated product content in a Flutter app.
Accepts productParams (map with mpn, ean, distId, isoCode, flIsoCode) and optional baseURL.
Example:

```
    FlixInpageHtmlView(
        productParams: {
        "mpn": "lego_10297",
        "ean": "cache001",
        "distributorId": 6,
        "isoCode": "it",
        "flIsoCode": "en",
        },
        baseURL: "https://www.example.com",
    )
```

## Notes
Android is supported (with the FlixMedia Android SDK AAR published to `mavenLocal()`).
Debugging mode allows enabling isInspectable for WebView inspection (iOS 16.4+).
Make sure your FlixMedia SDK credentials are initialized before loading content.

## License
© FlixMedia. All rights reserved.
