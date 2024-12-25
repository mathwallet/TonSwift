//
//  TonConnect.swift
//
//
//  Created by xgblin on 2024/6/4.
//

import Foundation
import PromiseKit

public class TonConnect {
    
    private let bridgeUrl: String
    
    private let address: String
    
    private let keyPair: TonKeypair
    
    private let parameters: TonConnectParameters
    
    private let contract: ConnectContract
    
    private let encryptService: TonConnectEncryptService
    
    private var last_event_id: String?
    
    private var sseClient: TonSSEClient?
    
    public init(bridgeUrl: String = "https://bridge.tonapi.io/bridge", parameters: TonConnectParameters, keyPair: TonKeypair, address: String) {
        self.bridgeUrl = bridgeUrl
        self.parameters = parameters
        self.address = address
        self.keyPair = keyPair
        self.contract = ConnectContract(publicKey: keyPair.publicKey, addressString: address)
        self.encryptService = TonConnectEncryptService()
        self.last_event_id = nil
        self.sseClient = nil
    }
    
    public func sse(sseHandler: @escaping (_ result: TonConnectDappRequest?, _ error: TonError?) -> Void) {
        let url = URL(string: "\(self.bridgeUrl)/events?client_id=\(self.encryptService.publicKey.toHexString())\((last_event_id != nil) ? "&last_event_id=\(last_event_id!)" : "")")!
        self.sseClient = TonSSEClient(url: url)
        sseClient?.startListening()
        sseClient?.onEventReceived { eventResponse in
            switch eventResponse {
            case .heartBeat:
                break
            case .message(let string, let data):
                if let _data = data {
                    self.last_event_id = string
                    if let result = try? JSONDecoder().decode(SSEResopnseData.self, from: _data),
                       let messageData = Data(base64Encoded: result.message),
                       let decryptData = try? self.encryptService.decrypt(message: messageData, senderPublicKey: Data(hex: self.parameters.clientId)) {
                        do {
                            let dappRequest = try JSONDecoder().decode(TonConnectDappRequest.self, from: decryptData)
                            sseHandler(dappRequest, nil)
                        } catch let error {
                            sseHandler(nil, TonError.otherError(error.localizedDescription))
                        }
                    }
                }
            }
        }
         
        sseClient?.sseErrorReceived{ error in
            sseHandler(nil, error)
        }
    }
    
    func sendBody(body: String, success: @escaping (_ response: TonConnectResponse) -> Void, failure: @escaping (_ error: TonError) -> Void) {
        var task: URLSessionTask? = nil
        let session = URLSession(configuration: .default)
        let queue = DispatchQueue(label: "ton.post")
        queue.async {
            let url = URL(string: "\(self.bridgeUrl)/message?client_id=\(self.encryptService.publicKey.toHexString())&to=\(self.parameters.clientId)&ttl=300")!
            var request = URLRequest(url: url)
            request.addValue("text/plain", forHTTPHeaderField: "contentType")
            request.httpMethod = "POST"
            request.httpBody = body.data(using: .utf8)
            task = session.dataTask(with: request) { data, response, error in
                if let _ = error {
                    failure(TonError.otherError("tonconnect error"))
                    return
                } else if let _data = data {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    do {
                        let result = try decoder.decode(TonConnectResponse.self, from: _data)
                        if result.statusCode == 200 {
                            success(result)
                            return
                        }
                        failure(TonError.otherError(result.message))
                    } catch {
                            failure(TonError.providerError("Parameter error or received wrong message"))
                    }
                }
            }
            task!.resume()
        }
    }
    
    public static func maniFest(path: String) -> Promise<ManifestResult> {
        let (promise, seal) = Promise<ManifestResult>.pending()
        var task: URLSessionTask? = nil
        let session = URLSession(configuration: .default)
        let queue = DispatchQueue(label: "ton.manifest")
        queue.async {
            guard let getUrl = URL(string: path) else {
                seal.reject(TonError.providerError("Wrong manifesturl"))
                return
            }
            
            var urlRequest = URLRequest(url: getUrl, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
            urlRequest.httpMethod = "GET"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            task = session.dataTask(with: urlRequest){ (data, response, error) in
                if error != nil {
                    seal.reject(TonError.providerError(error!.localizedDescription))
                    return
                }
                if data != nil {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    do {
                        let result = try decoder.decode(ManifestResult.self, from: data!)
                        seal.fulfill(result)
                    } catch {
                        seal.reject(TonError.providerError("Parameter error Manifest"))
                    }
                } else {
                    seal.reject(TonError.providerError("maniFest error"))
                }
            }
            task?.resume()
        }
        return promise
    }
}

extension TonConnect {
    public func connect(success: @escaping (_ isConnect: Bool?,_ result: TonConnectDappRequest?) -> Void, failure: @escaping (_ error: TonError) -> Void) {
        do {
            let manifest = TonConnectManifest(url: URL(string: self.parameters.payload.manifestUrl))
            let body = try TonConnectServiceBodyBuilder.buildConnectBody(keypair: keyPair,
                                                                         contract: contract,
                                                                         parameters: parameters,
                                                                         connecteEncryptService: self.encryptService,
                                                                         manifest: manifest)
            sendBody(body: body) { response in
                success(true, nil)
                self.sse { result, error in
                    if let _result = result {
                        self.last_event_id = _result.id
                        success(nil, _result)
                    } else if let _error = error {
                        failure(_error)
                    } else {
                        failure(TonError.otherError("tonconnect error"))
                    }
                }
            } failure: { error in
                failure(error)
            }
        } catch let error {
            failure(error as! TonError)
        }
    }
    
    public func cancelRequest(success: @escaping (_ result: Bool) -> Void, failure: @escaping (_ error: TonError) -> Void) {
        do {
            let body = try TonConnectServiceBodyBuilder.buildCancelBody(keypair: keyPair, id: self.last_event_id ?? "", clientId: parameters.clientId, connecteEncryptService: self.encryptService)
            sendBody(body: body) { response in
                success(true)
            } failure: { error in
                failure(error)
            }
        } catch let error {
            failure(TonError.otherError(error.localizedDescription))
        }
    }
    
    public func confirmRequest(boc: String, success: @escaping (_ result: Bool) -> Void, failure: @escaping (_ error: TonError) -> Void) {
        do {
            let body = try TonConnectServiceBodyBuilder.buildCancelBody(keypair: keyPair, id: self.last_event_id ?? "", clientId: parameters.clientId, connecteEncryptService: self.encryptService)
            sendBody(body: body) { response in
                success(true)
            } failure: { error in
                failure(error)
            }
        } catch let error {
            failure(TonError.otherError(error.localizedDescription))
        }
    }
    
}

public struct SSEResopnse: Decodable {
    public let event: String
    public let id: Int?
    public let data: SSEResopnseData?
}

public struct SSEResopnseData: Decodable {
    public let from: String
    public let message: String
}

public struct ManifestResult: Decodable {
    public let url: String
    public let name: String
    public let iconUrl: String?
    public let termsOfUseUrl: String?
    public let privacyPolicyUrl: String?
}
