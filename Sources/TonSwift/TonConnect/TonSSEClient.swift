import Foundation

class TonSSEClient: NSObject {
    private var task: URLSessionDataTask?
    private var urlSession: URLSession!
    private var eventReceivedHandler: ((TonSSEClientResponse) -> Void)?
    private var errorHandler: ((TonError) -> Void)?
    private var eventStreamURL: URL
    
    init(url: URL) {
        self.eventStreamURL = url
        let configuration = URLSessionConfiguration.default
        super.init()
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func onEventReceived(_ handler: @escaping (TonSSEClientResponse) -> Void) {
        self.eventReceivedHandler = handler
    }
    
    func sseErrorReceived(_ handler: @escaping (TonError) -> Void) {
        self.errorHandler = handler
    }
    
    func startListening() {
        var request = URLRequest(url: eventStreamURL)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        self.task = urlSession.dataTask(with: request)
        self.task?.resume()
    }
    
    func stopListening() {
        self.task?.cancel()
    }
}

// 扩展 SSEClient 以符合 URLSessionDataDelegate
extension TonSSEClient: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let eventString = String(data: data, encoding: .utf8) {
            if eventString.hasPrefix("event: message") {
                let resultArray = eventString.components(separatedBy: "data:")
                let id = resultArray.first?.replacingOccurrences(of: "event: message\nid: ", with: "") ?? ""
                if resultArray.count > 1 {
                    let messageData = resultArray[1].data(using: .utf8)
                    eventReceivedHandler?(TonSSEClientResponse.message(id, messageData))
                }
            } else if eventString.hasPrefix("event: heartbeat") {
                eventReceivedHandler?(TonSSEClientResponse.heartBeat)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        errorHandler?(TonError.otherError("sse error"))
    }
}

public enum TonSSEClientResponse {
    case heartBeat
    case message(String, Data?)
}
