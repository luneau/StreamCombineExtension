//
//  InputStreamCombineExt.swift
//  
//
//  Created by Sébastien Luneau on 19/11/2020.
//  Copyright © 2020 Sébastien Luneau. All rights reserved.
//

import Foundation
import Combine


// MARK: - Peripheral : Read Characteristic publisher

final class InputStreamSubscription<SubscriberType: Subscriber>: NSObject, StreamDelegate, Subscription where SubscriberType.Input == (Stream.Event,Data?), SubscriberType.Failure == Error  {
    
    public var subscriber: SubscriberType?
    private let inputStream: InputStream
    private let runloop : RunLoop
    private let mode: RunLoop.Mode
    
    let bufferSize : Int
    var buffer : Array<UInt8>
    
    init(subscriber: SubscriberType, inputStream: InputStream, in aRunLoop: RunLoop,
         forMode mode: RunLoop.Mode, bufferSize : Int) {
        self.subscriber = subscriber
        self.inputStream = inputStream
        self.runloop = aRunLoop
        self.mode = mode
        self.bufferSize = bufferSize
        buffer = Array<UInt8>(repeating: 0, count: bufferSize)
    }
    
    func request(_ demand: Subscribers.Demand) {
        inputStream.delegate = self
        inputStream.schedule(in: runloop, forMode: mode)
        inputStream.open()
        if inputStream.hasBytesAvailable {
            readData()
        }
        
    }
    
    func stream(_ aStream: Stream,
                handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            let _ = subscriber?.receive((.openCompleted, nil))
        case .endEncountered:
            subscriber?.receive(completion: .finished)
        case .errorOccurred:
            subscriber?.receive(completion: .failure(aStream.streamError!))
        case .hasBytesAvailable:
           readData()
        case .hasSpaceAvailable: break
        default:
            break
        }
    }
    func readData ()
    {

        let len = inputStream.read(&buffer, maxLength: bufferSize)
        if len > 0 {
            let _ = subscriber?.receive((.hasBytesAvailable, Data(bytes: buffer, count: len)))
        }
    }
    
    func cancel() {
        inputStream.close()
        inputStream.remove(from: runloop, forMode: mode)
        subscriber = nil
        inputStream.delegate = nil
    }
}

struct InputStreamPublisher : Publisher {
    
    typealias Output = (Stream.Event,Data?)
    typealias Failure = Error
    
    private let inputStream: InputStream
    private let runloop : RunLoop
    private let mode: RunLoop.Mode
    let bufferSize : Int
    
    init(inputStream: InputStream, in aRunLoop: RunLoop,
         forMode mode: RunLoop.Mode , bufferSize : Int ) {
        self.inputStream = inputStream
        self.runloop = aRunLoop
        self.mode = mode
        self.bufferSize = bufferSize
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Self.Failure, S.Input == Self.Output {
        let subscription = InputStreamSubscription(subscriber: subscriber, inputStream: inputStream, in : runloop,
                                                   forMode : mode, bufferSize : bufferSize )
        subscriber.receive(subscription: subscription)
    }
}

// MARK: - state publisher
extension InputStream {
    func openPublisher( in aRunLoop: RunLoop = RunLoop.current,
                        forMode mode: RunLoop.Mode = .default , bufferSize : Int = 4096) ->  AnyPublisher<(Stream.Event,Data?),Error> {
        return InputStreamPublisher(inputStream : self, in : aRunLoop,
                                    forMode : mode, bufferSize: bufferSize).eraseToAnyPublisher()
    }
}
