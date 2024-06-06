//
//  TonConnect.swift
//
//
//  Created by 薛跃杰 on 2024/6/4.
//

import Foundation

public class TonConnect {
    
    public static let shared = TonConnect()
    
    private var url: URL
    
    private var session: URLSession
    
    private var task: URLSessionDataTask?
    
    private init?(urlString: String = "https://bridge.tonapi.io/bridge") {
        guard let url = URL(string: urlString) else {
            return nil
        }
        self.url = url
        self.session = URLSession(configuration: .default)
    }
    
    public func connect(parameters: TonConnectParameters, keypair: TonKeypair, wallet: TonWallet) throws {
        // 创建一个 URLRequest
        var request = URLRequest(url: url)
        let manifest = TonConnectManifest(url: URL(string: parameters.payload.manifestUrl))
        let successResponse = try TonConnectService.buildConnectEventSuccessResponse(keypair: keypair, wallet: wallet, parameters: parameters, manifest: manifest)
        let body = try TonConnectService.encryptSuccessResponse(successResponse: successResponse, keypair: keypair, parameters: parameters)
        
//        let httpbody = .init(stringli)
        
        
        
//        request.httpBody = body
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        task = session.dataTask(with: request) { data, response, error in
            if let _error = error {
                
            } else if let _data = data {
                
            }
        }
        task!.resume()
    }
    
    public func disConnect() {
        if let _task = task {
            _task.cancel()
        }
    }
}
