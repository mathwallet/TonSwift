//import Foundation
//import Alamofire
//public class TonSSEClient: NSObject {
//    private var task: URLSessionDataTask?
//    private var urlSession: URLSession!
//    private var url: URL
//    var eventHandler: ((_ data: Data)-> Void)?
//    var errorHandler: ((_ error: Error)-> Void)?
//    
//    public init(url: URL) {
//        self.url = url
//        super.init()
//    }
//    
//    public func connectSSE(eventBlock: @escaping (_ data: Data)-> Void, failure: @escaping (_ error: TonError)-> Void) {
//        let configuration = URLSessionConfiguration.default
//        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
//        var request = URLRequest(url: url)
//        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
//        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
//        request.httpMethod = "GET"
//        task = urlSession.dataTask(with: request)
//        task?.resume()
//        self.eventHandler = eventBlock
//        self.errorHandler = failure
//    }
//
//    public func disconnect() {
//        task?.cancel()
//    }
//}
//
//extension TonSSEClient: URLSessionDataDelegate {
//    
//    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//        self.eventHandler?(data)
//    }
//    
//    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//           if let error = error {
//               self.errorHandler?(TonError.otherError("sse client error"))
//           }
//       }
//}
//
