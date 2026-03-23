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
Android is supported (with the FlixMedia Android SDK AAR published to `mavenLocal()`).
Debugging mode allows enabling isInspectable for WebView inspection (iOS 16.4+).
Make sure your FlixMedia SDK credentials are initialized before loading content.

## License
© FlixMedia. All rights reserved.
