import XCTest
import Combine
@testable import StreamCombineExtension

final class StreamCombineExtensionTests: XCTestCase {
    let testString = "testttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttesttestttesttesttest"
    let stopString = "stop"
    fileprivate func writeData(queue : PassthroughSubject<Data,Never>) {
        queue.send(testString.data(using: .utf8)!)
        queue.send(stopString.data(using: .utf8)!)
        
    }
    
    fileprivate func openOutput(outputStream : OutputStream, dataQueue : PassthroughSubject<Data,Never>? = nil) -> AnyCancellable {
        let publisher = dataQueue != nil ? outputStream.openPublisher(dataPublisher: dataQueue!) : outputStream.openPublisher()
        let queue = publisher.subject()
        return publisher.sink(
            receiveCompletion: {
                print ($0) }
            , receiveValue: { event,dataSent in
                switch event {
                case .openCompleted:
                    self.writeData(queue: queue!)
                default:
                    break
                }
                
            })
    }
    func testStreamData() throws {
        
        let expectation = XCTestExpectation(description: "stream data")
        let dataQueue = PassthroughSubject<Data,Never>()
        
       
        let capacity = 3
        var outputStream : OutputStream? = nil
        var inputStream : InputStream? = nil
        var resultString = ""
       
        Stream.getBoundStreams(withBufferSize: capacity, inputStream: &inputStream, outputStream: &outputStream)
        var cancellableOut : AnyCancellable? = nil
        let cancellableIn : AnyCancellable? = inputStream?.openPublisher().sink(
            receiveCompletion: {
                print ($0) }
            , receiveValue: { [self] event,dataReceived in
                switch event {
                case .openCompleted:
                    cancellableOut = self.openOutput(outputStream:outputStream!,dataQueue:dataQueue)
                case .dataReceived:
                    guard let dataReceived = dataReceived else { return }
                    resultString.append(String(data: dataReceived, encoding: .utf8)!)
                    if resultString == testString {
                      resultString = ""
                    }
                    if resultString == stopString {
                      expectation.fulfill()
                    }
                default:
                    break
                }
                
            })
        
        wait(for: [expectation], timeout: 100.0)
        cancellableOut?.cancel()
        cancellableIn?.cancel()
    }
    func testStreamData2() throws {
        
        let expectation = XCTestExpectation(description: "stream data2")
       
        let capacity = 3
        var outputStream : OutputStream? = nil
        var inputStream : InputStream? = nil
        var resultString = ""
       
        Stream.getBoundStreams(withBufferSize: capacity, inputStream: &inputStream, outputStream: &outputStream)
        var cancellableOut : AnyCancellable? = nil
        let cancellableIn : AnyCancellable? = inputStream?.openPublisher().sink(
            receiveCompletion: {
                print ($0) }
            , receiveValue: { [self] event,dataReceived in
                switch event {
                case .openCompleted:
                    cancellableOut = self.openOutput(outputStream:outputStream!)
                case .dataReceived:
                    guard let dataReceived = dataReceived else { return }
                    resultString.append(String(data: dataReceived, encoding: .utf8)!)
                    if resultString == testString {
                      resultString = ""
                    }
                    if resultString == stopString {
                      expectation.fulfill()
                    }
                default:
                    break
                }
                
            })
        
        wait(for: [expectation], timeout: 100.0)
        cancellableOut?.cancel()
        cancellableIn?.cancel()
    }

    static var allTests = [
        ("testStreamData", testStreamData),
    ]
}
