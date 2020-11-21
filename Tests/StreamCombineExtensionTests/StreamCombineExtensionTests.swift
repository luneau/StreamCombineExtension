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
    fileprivate func openOutput(outputStream : OutputStream, dataQueue : PassthroughSubject<Data,Never>) -> AnyCancellable {
        return outputStream.openPublisher(dataPublisher: dataQueue.eraseToAnyPublisher()).sink(
            receiveCompletion: {
                print ($0) }
            , receiveValue: { event,dataSent in
                switch event {
                case .openCompleted:
                    self.writeData(queue: dataQueue)
                //case .hasSpaceAvailable:
                //    break
                default:
                    break
                }
                
            })
    }
    func testStreamData() throws {
        
        let expectation = XCTestExpectation(description: "stream data")
        let dataQueue = PassthroughSubject<Data,Never>()
        
       
        let capacity = 1
        var outputStream : OutputStream? = nil
        var inputStream : InputStream? = nil
        var resultString = ""
       
        Stream.getBoundStreams(withBufferSize: capacity, inputStream: &inputStream, outputStream: &outputStream)
        var cancellable : AnyCancellable? = nil
        let cancellableOut : AnyCancellable? = inputStream?.openPublisher().sink(
            receiveCompletion: {
                print ($0) }
            , receiveValue: { [self] event,dataReceived in
                switch event {
                case .openCompleted:
                    cancellable = self.openOutput(outputStream:outputStream!,dataQueue:dataQueue)
                case .hasBytesAvailable:
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
        cancellable?.cancel()
        cancellableOut?.cancel()
    }
    

    static var allTests = [
        ("testStreamData", testStreamData),
    ]
}
