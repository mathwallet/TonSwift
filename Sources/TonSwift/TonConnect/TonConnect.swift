//
//  TonConnect.swift
//
//
//  Created by 薛跃杰 on 2024/6/4.
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
        sseClient?.onEventReceived { event in
            if event.hasPrefix("event: message") {
                let resultArray = event.components(separatedBy: "data:")
                self.last_event_id = resultArray.first?.replacingOccurrences(of: "event: message\nid: ", with: "") ?? ""
                if resultArray.count > 1,
                   let result = try? JSONDecoder().decode(SSEResopnseData.self, from: resultArray[1].data(using: .utf8)!),
                   let messageData = Data(base64Encoded: result.message),
                   let decryptData = try? self.encryptService.decrypt(message: messageData, senderPublicKey: Data(hex: self.parameters.clientId))
                    {
                    do {
                        let dappRequest = try JSONDecoder().decode(TonConnectDappRequest.self, from: decryptData)
                        sseHandler(dappRequest, nil)
                    } catch let error {
                        debugPrint(error)
                    }
                    
                }
            }
        }
         
        sseClient?.sseErrorReceived{ error in
            sseHandler(nil, error)
        }
    }
    
    func sendBody(body: String) -> Promise<TonConnectResponse> {
        let rp = Promise<Data>.pending()
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
                    rp.resolver.reject(TonError.otherError("tonconnect error"))
                    return
                } else if let _data = data {
                    rp.resolver.fulfill(_data)
                }
            }
            task!.resume()
        }
        
        return rp.promise.ensure {
            task = nil
        }.map(on: queue){ (data: Data) -> TonConnectResponse in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let result = try decoder.decode(TonConnectResponse.self, from: data)
                if result.statusCode == 200 {
                    return result
                    
                }
                throw TonError.otherError(result.message)
            } catch {
                throw TonError.providerError("Parameter error or received wrong message")
            }
        }
    }
}

extension TonConnect {
    public func connect() -> Promise<TonConnectResponse> {
        return Promise<TonConnectResponse> {seal in
            let manifest = TonConnectManifest(url: URL(string: self.parameters.payload.manifestUrl))            
            let body = try TonConnectServiceBodyBuilder.buildConnectBody(keypair: keyPair,
                                                                         contract: contract,
                                                                         parameters: parameters,
                                                                         connecteEncryptService: self.encryptService,
                                                                         manifest: manifest)
            sendBody(body: body).done { response in
                seal.fulfill(response)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    public func sendTransaction(seqno: UInt64, parameters: TonConnectDappRequest.TonConnectParam) -> Promise<TonConnectResponse> {
        return Promise<TonConnectResponse> {seal in
            let sender = try ConnectAddress.parse(address)
            let body = try TonConnectServiceBodyBuilder.buildSendTransactionBody(keypair: keyPair, seqno: seqno, sender: sender, parameters: parameters, contract: contract)
            sendBody(body: body).done { response in
                seal.fulfill(response)
            }.catch { error in
                seal.reject(error)
            }
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
