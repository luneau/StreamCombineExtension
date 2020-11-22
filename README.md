
# StreamCombineExtension
Swift extensions for OutputStream and InputStream, using Combine instead of classic stream delegate mechanism.  

 I wrote this code extension to fit my simple needs : Have straight forward read/write stream using combine.

 It helped me to better appreciate Combine API

# Installation

## CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for CocoaProjects.
To integrate StreamCombineExtension into your Xcode project using CocoaPods specify it in your `Podfile`:
```ruby
pod 'StreamCombineExtension', :git => 'https://github.com/luneau/StreamCombineExtension.git'
```
Then, run the following command:
`$ pod install`

## Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.
To integrate StreamCombineExtension into your Xcode project using Carthage  specify it in your `Cartfile`:
```swift
github "luneau/StreamCombineExtension.git"
```
Then, run `carthage update` to build framework and drag `StreamCombineExtension.framework` into your Xcode project.

## Swift Package Manager

Versions >= 5.3 of the library integrate with the Swift Package Manager.

## Files ...
there is only 3 important files, so it's quite easy to integrate without a package manager
InputStreamCombineExt.swift
OutStreamCombineExt.swift
StreamEventCombineExt.swift

# Getting Started

basic imputStream handling

```swift
let cancellableIn : AnyCancellable = inputStream.openPublisher().sink(
    receiveCompletion: {
        print ($0) }
    , receiveValue: { [self] event,dataReceived in
        switch event {
        case .openCompleted:
           ... do something
        case .dataReceived:
            guard let dataReceived = dataReceived else { return }
            ... do something with data
        default:
            break
        }
        
    })
    ...
    cancellableIn.cancel() // cleanUp and close the Stream
```

basic output source handling handling

```swift
fileprivate func writeData(queue : PassthroughSubject<Data,Never>) {
    queue.send(testString.data(using: .utf8)!)
    queue.send(stopString.data(using: .utf8)!)
    
}

fileprivate func openOutput(outputStream : OutputStream, dataQueue : PassthroughSubject<Data,Never>) -> AnyCancellable {
    return outputStream.openPublisher(dataPublisher: dataQueue.eraseToAnyPublisher()).sink(
        receiveCompletion: {
            print ($0) }
        , receiveValue: { [weak self] event,dataSent in
            switch event {
            case .openCompleted:
                self?.writeData(queue: dataQueue)
            default:
                break
            }
            
        })
}
```
Beware ! the StreamEvent handling are dispatched on the current Runtime of the caller you may want to change it by passing the desired Runtime.
  
  This implementation of OutputStream uses a PassthroughSubject to write out datas, internally it will buffered it, you may want to changed the size of the buffer depending on your use case.

# Requirements

- iOS 13.0+
- OSX 10.15+
- watchOS 6.0+
- tvOS 13.0+
- Xcode 11.4+
 
 ## Swift versions
 Swift 5.2

# Future Plan
- [ ] add support for OpenCombine and/or XCombine for pre iOS 13 platforms
- [ ] add support for linux/android/others
