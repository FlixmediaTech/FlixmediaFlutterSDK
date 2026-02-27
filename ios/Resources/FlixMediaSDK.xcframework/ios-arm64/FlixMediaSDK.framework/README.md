# FlixMedia iOS SDK (XCFramework)

The **FlixMedia iOS SDK** embeds syndicated product content (images, videos, rich HTML) into iOS apps. It provides:
- A ready-to-use SwiftUI view (**FlixWebView**) for in-app rendering.
- A low-level method to obtain raw HTML when you prefer your own web view.

---

## Features
- Automatic HTML retrieval and rendering of product content.
- Dynamic height adjustment to match content.
- Loading state callbacks: `loading`, `loaded`, `error`.
- Optional height change notifications for seamless layouts.
- Thread-safe initialization and access (actor-based core).

---

## What’s Included
- `FlixMedia.xcframework`
- Public types:
  - `FlixMedia` (SDK entry point)
  - `FlixWebView` (SwiftUI wrapper over `WKWebView`)
  - `FlixWebViewLogger` (optional JS log bridge)
  - `WebViewConfiguration` (immutable configuration)
  - `ProductRequestParameters` (product identifiers & locale)
  - `WebViewState` (loading state enum)
  - `FlixMediaError` (error enum)

---

## Requirements
- iOS 15.0 or later
- Xcode 15+
- Swift 5.9+

---

## Installation (XCFramework)
1. Add `FlixMedia.xcframework` to your app target (**Embed & Sign** recommended).
2. If using Swift Package Manager with a **binary target**, point to your hosted `.xcframework.zip` and its checksum.
3. Clean build folder and rebuild the app.

> Note: The XCFramework itself does not require a provisioning profile; your **app** provides signing.

---

## Initialization
- Initialize the SDK once (typically at app start) using your Flix credentials.
- The SDK securely caches an ID token; if present and valid, re-authentication is skipped.
- Use `useSandbox: true` to target the **alpha** environment (defaults to production).

```swift
import FlixMediaSDK

Task {
    try await FlixMedia.shared.initialize(
        username: "<your-username>",
        password: "<your-password>",
        useSandbox: false
    )
}
```

---

## Displaying Content
You have two integration paths:
- **FlixWebView** (recommended): A SwiftUI view that loads and renders syndicated content, manages height automatically, and surfaces loading/error states.
- **Raw HTML**: Obtain the HTML string and render it in your own `WKWebView` or custom web view when you need full control (e.g., non-SwiftUI stacks, complex containers).

```swift
let params = ProductRequestParameters(
    mpn: "ABC-123",
    ean: "1234567890123",
    distId: "your-dist-id",
    isoCode: "en",
    flIsoCode: "US",
    brand: "Brand",
    title: "Product Title",
    price: "199.99",
    currency: "USD"
)

let config = WebViewConfiguration(
    productParams: params,
    baseURL: URL(string: "https://example.com")!
)

FlixWebView(
    configuration: config,
    onHeightChange: { height in
        // Update your layout if needed
    },
    onStateChange: { state in
        // loading / loaded / error
    }
)
```

---

## Configuration Model
- **ProductRequestParameters**
  - `mpn` – Manufacturer Part Number
  - `ean` – EAN/UPC code
  - `distId` – Distributor/Retailer identifier
  - `isoCode`
  - `flIsoCode`
  - `brand`
  - `title`
  - `price`
  - `currency`
- **WebViewConfiguration**
  - `productParams` – The parameters above
  - `baseURL` – Base URL for resolving relative assets/links in HTML

---

## Loading States
- `WebViewState.loading` – Content is being prepared.
- `WebViewState.loaded` – Content is ready.
- `WebViewState.error(Error)` – A recoverable error occurred; you can present an error UI.

---

## Error Handling
`FlixMediaError` may surface in failures, including:
- `unauthorized`, `missingCredentials`, `notInitialized`
- `invalidStatusCode(Int)`, `serverError(message:)`
- Token lifecycle: `emptyToken`, `tokenNotFound`, `refreshFailed`
- Transport/format: `invalidResponse`, `malformedURL`

---

## Privacy & Tracking
- The SDK uses AppTrackingTransparency to access the IDFA when authorized.
- If tracking is not authorized, it falls back to IDFV.

---

## External Links
- Link taps inside `FlixWebView` show a confirmation alert and open in Safari when confirmed.

---

## Troubleshooting
- **No content appears**: Verify credentials, product parameters, and network access.
- **Unexpected layout**: Check container constraints and ensure the parent layout updates on height changes.
- **Errors after app relaunch**: Re-initialize before requesting content; stale tokens are handled, but the SDK must be initialized first.

---

## Building the XCFramework
If you are working with the SDK source, you can generate the XCFramework using the provided script:

```bash
./build_xcframework.sh
```

---

## License
© FlixMedia. All rights reserved.
