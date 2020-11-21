//
//  OutputStreamCombineExt.swift
//
//
//  Created by Sébastien Luneau on 19/11/2020.
//  Copyright © 2020 Sébastien Luneau. All rights reserved.
//

import Foundation
import Combine



final class OutputStreamSubscription<SubscriberType: Subscriber>: NSObject, StreamDelegate, Subscription, Subscriber where SubscriberType.Input == (Stream.Event, Int), SubscriberType.Failure == Error  {
    
    // MARK: - Subscription : write data
    
    public var subscriber: SubscriberType?
    private let outputStream: OutputStream
    private let runloop : RunLoop
    private let mode: RunLoop.Mode
    private var dataPublisher : AnyPublisher<Data,Never>? = nil
    private var dataBuffer : Publishers.Buffer<AnyPublisher<Data, Never>>? = nil
    private var data : Data? = nil
    private var offset = 0
    
    init(subscriber: SubscriberType, outputStream: OutputStream, dataPublisher : AnyPublisher<Data,Never>, in aRunLoop: RunLoop,
         forMode mode: RunLoop.Mode) {
        self.subscriber = subscriber
        self.outputStream = outputStream
        self.dataPublisher = dataPublisher
        self.runloop = aRunLoop
        self.mode = mode
        self.dataBuffer = dataPublisher.buffer(size: 1024, prefetch: .byRequest, whenFull: .dropNewest)
    }
    
    func request(_ demand: Subscribers.Demand) {
        outputStream.delegate = self
        outputStream.schedule(in: runloop, forMode: mode)
        outputStream.open()
    }
    
    func stream(_ aStream: Stream,
                handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            dataBuffer?.subscribe(self)
            let _ = subscriber?.receive( (.openCompleted, 0))
        case .endEncountered:
            subscriber?.receive(completion: .finished)
        case .errorOccurred:
            subscriber?.receive(completion: .failure(aStream.streamError!))
        case .hasBytesAvailable: break
        case .hasSpaceAvailable:
            sendData()
        default:
            break
        }
    }
    
    func sendData() {
        guard outputStream.hasSpaceAvailable else { return }
        guard let data = data else { return }
        if offset < data.count {
            let bytesWritten = data.withUnsafeBytes{ (rawBufferPointer: UnsafeRawBufferPointer) -> Int in
                let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
                return outputStream.write(bufferPointer.baseAddress! + offset , maxLength: data.count - offset)
            }
           
            offset += bytesWritten
            let _ = subscriber?.receive( (.hasSpaceAvailable, bytesWritten))
            return
        } else {
            subscription?.request(.max(1))
        }
    }
    
    func cancel() {
        outputStream.close()
        outputStream.remove(from: runloop, forMode: mode)
        dataBuffer = nil
        dataPublisher = nil
        subscriber = nil
        outputStream.delegate = nil
    }
    
    
    // MARK: - Subscriber : data provider protocol
    typealias Input = Data
    typealias Failure = Never
    var subscription: Subscription? = nil
    
    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.max(1))
    }
    func receive(_ input: Input) -> Subscribers.Demand {
        self.data = input
        offset = 0
        sendData()
        return .none
    }
    func receive(completion: Subscribers.Completion<Never>) {
    }
}

struct OutputStreamPublisher : Publisher {
    
    typealias Output =  (Stream.Event, Int)
    typealias Failure = Error
    
    private let outputStream: OutputStream
    private let runloop : RunLoop
    private let mode: RunLoop.Mode
    private let dataPublisher : AnyPublisher<Data,Never>
    
    init(outputStream: OutputStream , dataPublisher : AnyPublisher<Data,Never>, in aRunLoop: RunLoop,
         forMode mode: RunLoop.Mode) {
        self.outputStream = outputStream
        self.dataPublisher = dataPublisher
        self.runloop = aRunLoop
        self.mode = mode
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Self.Failure, S.Input == Self.Output {
        let subscription = OutputStreamSubscription(subscriber: subscriber, outputStream: outputStream, dataPublisher : dataPublisher, in : runloop,
                                                    forMode : mode)
        subscriber.receive(subscription: subscription)
    }
}

// MARK: - open stream the publisher provide lifecycle informations
extension OutputStream {
    func openPublisher(dataPublisher : AnyPublisher<Data,Never> , in aRunLoop: RunLoop = RunLoop.current,
                       forMode mode: RunLoop.Mode = .default) -> AnyPublisher< (Stream.Event, Int),Error> {
        return OutputStreamPublisher(outputStream : self , dataPublisher : dataPublisher , in : aRunLoop,
                                     forMode : mode).eraseToAnyPublisher()
    }
}
