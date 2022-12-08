# ZERO10SDK

`ZERO10SDK` is an iOS framework that allows integrating the [ZERO10 try-on technology](https://zero10.app/) into your app. With this feature, your users will be able to try on clothes before buying, and make stunning content for their social networks. We use this framework in the [ZERO10 iOS app](https://apps.apple.com/us/app/zero10-ar-fashion-platform/id1580413828).

<!-- TOC -->

- [Demo iOS App](#demo-ios-app)
- [Getting Started](#getting-started)
    - [Installation](#installation)
        - [Swift Package Manager](#swift-package-manager)
        - [Framework](#framework)
    - [Usage](#usage)
        - [Allow your app to use the camera](#step-0.-allow-your-app-to-use-the-camera)
        - [Create a `TryOnSession` object](#step-1.-create-a-tryonsession-object)
        - [Add an entry point](#step-2.-add-an-entry-point)
        - [Customize the SDK](#step-3.-customize-the-sdk)

<!-- /TOC -->

## Demo App
To simplify the integration process, we prepared a sample project that you can find in this repo. The sample project uses a trial API key and includes 10 demo garments. The trial API key and the demo garments can be used for internal testing, but **should not be used in production**.

To use `ZERO10SDK` in production, send us a message [hi@zero10.app](mailto:hi@zero10.app).

1. We'll provide you with an **API key for use in production**
1. We'll help you to develop the **3D models of your garments**

## Getting Started
To enhance your app with the ZERO10 try-on, you need to
* **install the `ZERO10SDK`** (by adding it as an SPM package or by embedding the framework in your Xcode project)
* **initialize and customize the `ZERO10SDK`** (check the API key, download the 3D models of the garments and the Machine Learning models)
* **create an entry point in your app** (e.g., add a launch button that opens the ZERO10 try-on);

We'll walk you through the these steps.

### Installation

Add the `ZERO10SDK` to your project either as an SPM package or by embedding the framework in your Xcode project.

#### Swift Package Manager

Add the `ZERO10SDK` package to your Xcode project.

```
https://github.com/zero10-app/zero10-sdk.git
```

#### Framework

1. Download the latest version of the `ZERO10SDK` framework with the link from [`Package.swift`](https://github.com/zero10-app/ios/blob/main/junk/ZERO10DemoApp/zero10-sdk-spm/Package.swift).
2. Add **ZERO10SDK.xcframework** to your project in Xcode.
3. Embed this framework in the main bundle of your project.

### Usage

#### Step 0. Allow your app to use the camera

Add the `NSCameraUsageDescription` key to **Info.plist**

#### Step 1. Create a `TryOnSession` object
First, you need to create a `TryOnSession` object. You'll use this object to configure the `ZERO10SDK`.
```swift
let apiKey = /* insert here your api key */
let config = TryOnSessionConfiguration(apiKey: apiKey)
let session = TryOnSession(with: config)
```
Now that you have created a `TryOnSession`, you need to initialize it. 
The initialization consists of two steps.
1. Downloading the Computer Vision models
2. Getting the list of available 3D garments

To download the CV models, run the following code. It takes up to 5 seconds with a stable internet connection.
```swift
tryOnSession.prepare { result in
    switch result {
        case .success:
        // session is ready for using
        case .failure:
        // preparation failed
    }
}
```
To retrieve the list of available 3D garments, run the following code.
```swift
tryOnSession.receiveCollections { result in
    switch result {
        case .success(let collections):
        // save collections for future use
        case .failure:
        // collections are not ready
    }
}
```

#### Step 2. Add an entry point
Now that you have successfully initialized and configured the `ZERO10SDK`, you need to add a button that opens the ZERO10 camera. The following code opens the ZERO10 try-on sheet, where users can choose between the real-time and photo virtual try-on.
```swift
let garments = garmentCollections
    .flatMap(\.items)
    .enumerated()
    .map { index, garment in
        DisplaybleGarment(isAvailable: true, wrappedGarment: garment, index: index)
    }
let tryOnData = CameraTryOnData(garments: garments, selectedIndex: 0)
let viewController = TryOnSheetViewController.makeTryOnSheetViewController(tryOnData: tryOnData)
viewController.delegate = self // viewController have to adopt `TryOnSheetViewControllerDelegate` protocol
bottomSheetPresenter.present(
    viewController,
    from: self,
    background: .translucent,
    backgroundCornerRadius: 24.0
)
```
