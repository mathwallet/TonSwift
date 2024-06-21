import Foundation

public class TonSSEClient: NSObject {
    private var task: URLSessionDataTask?
    private var urlSession: URLSession!
    private var url: URL
    var eventHandler: ((Data) -> Void)?
    var errorHandler: ((TonError) -> Void)?
    public init(url: URL) {
        self.url = url
        super.init()
    }
    public func connect(eventHandler: @escaping (Data) -> Void, errorHandler: @escaping (TonError) -> Void) {
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
//        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.httpMethod = "GET"
        task = urlSession.dataTask(with: request)
        task?.resume()
        self.errorHandler = errorHandler
        self.eventHandler = eventHandler
    }

    public func disconnect() {
        task?.cancel()
    }
}

extension TonSSEClient: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let eventString = String(data: data, encoding: .utf8) else {
            return
        }
        handleEvent(eventString)
    }

    private func handleEvent(_ event: String) {
        // 解析和处理事件
        debugPrint(event)
        if event.hasPrefix("data: ") {
            let dataString = event.dropFirst(6)
            self.eventHandler?(dataString.data(using: .utf8)!)
        }
    }
}
