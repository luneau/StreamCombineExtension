# StreamCombineExtension
Swift extensions for OutputStream and InputStream, using Combine instead of classic stream delegate mechanism.  

# Installation

## CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for CocoaProjects.
To integrate RxBluetoothKit into your Xcode project using CocoaPods specify it in your `Podfile`:
```ruby
pod 'StreamCombineExtension', :git => 'https://github.com/luneau/StreamCombineExtension.git'
```
Then, run the following command:
`$ pod install`

## Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.
To integrate RxBluetoothKit into your Xcode project using Carthage  specify it in your `Cartfile`:
```swift
github "luneau/StreamCombineExtension.git"
```
Then, run `carthage update` to build framework and drag `StreamCombineExtension.framework` into your Xcode project.

## Swift Package Manager

Versions >= 5.3 of the library integrate with the Swift Package Manager. In order to do that please specify our project as one of your dependencies in `Package.swift` file.

## Files ...
there is only 2 important files, so it's quite easy to integrate without a package manager
InputStreamCombineExt.swift
OutStreamCombineExt.swift

# Getting Started
```swift

```
# Requirements

- iOS 13.0+
- OSX 10.15+
- watchOS 6.0+
- tvOS 13.0+
- Xcode 11.4+
 
 ## Swift versions
 Swift 5.2
