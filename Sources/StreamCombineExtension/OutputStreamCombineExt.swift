//
//  OutputStreamCombineExt.swift
//
//
//  Created by Sébastien Luneau on 19/11/2020.
//  Copyright © 2020 Sébastien Luneau. All rights reserved.
//

import Foundation
import Combine



final class OutputStreamSubscription<SubscriberType: Subscriber>: NSObject, StreamDelegate, Subscription, Subscriber where SubscriberType.Input == (StreamEvent, Int), SubscriberType.Failure == Error  {
    
    // MARK: - Subscription : write data
    
    public var subscriber: SubscriberType?
    private let outputStream: OutputStream
    private let runloop : RunLoop
    private let mode: RunLoop.Mode
    private var dataBuffer : Publishers.Buffer<AnyPublisher<Data, Never>>? = nil
    private var data : Data? = nil
    private var offset = 0
    
    init(subscriber: SubscriberType, outputStream: OutputStream, dataBuffer : Publishers.Buffer<AnyPublisher<Data, Never>>, in aRunLoop: RunLoop,
         forMode mode: RunLoop.Mode, bufferSize : Int) {
        self.subscriber = subscriber
        self.outputStream = outputStream
        self.runloop = aRunLoop
        self.mode = mode
        self.dataBuffer = dataBuffer
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
            let _ = subscriber?.receive( (.dataSent, bytesWritten))
            return
        } else {
            subscription?.request(.max(1))
        }
    }
    
    func cancel() {
        outputStream.close()
        outputStream.remove(from: runloop, forMode: mode)
        dataBuffer = nil
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

public final class OutputStreamPublisher : Publisher {
    
    public typealias Output =  (StreamEvent, Int)
    public typealias Failure = Error
    
    private let outputStream: OutputStream
    private let runloop : RunLoop
    private let mode: RunLoop.Mode
    private let dataPublisher : AnyPublisher<Data,Never>
    private let dataSubject : PassthroughSubject<Data,Never>?
    private let bufferSize : Int
    
    init<S>(outputStream: OutputStream , dataPublisher : S, in aRunLoop: RunLoop,
            forMode mode: RunLoop.Mode, bufferSize : Int) where S: Publisher , S.Output == Data, S.Failure == Never {
        self.outputStream = outputStream
        self.dataPublisher = dataPublisher.eraseToAnyPublisher()
        self.runloop = aRunLoop
        self.mode = mode
        self.bufferSize = bufferSize
        self.dataSubject = dataPublisher as?  PassthroughSubject<Data,Never>
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Failure, S.Input == Output {
        let subscription = OutputStreamSubscription(subscriber: subscriber, outputStream: outputStream, dataBuffer : dataPublisher.buffer(size: bufferSize, prefetch: .byRequest, whenFull: .dropNewest), in : runloop,
                                                    forMode : mode, bufferSize : bufferSize)
        subscriber.receive(subscription: subscription)
    }
    public func subject() -> PassthroughSubject<Data,Never>? {
        return dataSubject
    }
    public func queue(data : Data) {
        dataSubject?.send(data)
    }
}



// MARK: - open stream the publisher provide lifecycle informations
extension OutputStream {
    
    public func openPublisher<S>(dataPublisher : S, in aRunLoop: RunLoop = RunLoop.current,
                                 forMode mode: RunLoop.Mode = .default, bufferSize : Int = 1024) -> OutputStreamPublisher  where S: Publisher , S.Output == Data, S.Failure == Never {
        return OutputStreamPublisher(outputStream : self , dataPublisher : dataPublisher , in : aRunLoop,
                                     forMode : mode, bufferSize : bufferSize)
    }
    
    public func openPublisher(in aRunLoop: RunLoop = RunLoop.current,
                              forMode mode: RunLoop.Mode = .default, bufferSize : Int = 1024) -> OutputStreamPublisher{
        let subject = PassthroughSubject<Data,Never>()
        return openPublisher(dataPublisher: subject, in: aRunLoop, forMode: mode, bufferSize: bufferSize)
    }
}
