//
//  TonConnectDappRequest.swift
//
//
//  Created by 薛跃杰 on 2024/6/19.
//

import Foundation

public struct TonConnectDappRequest: Decodable {
    public enum Method: String, Decodable {
        case sendTransaction
    }
    
    public struct TonConnectParam: Decodable {
        let messages: [TonConnectMessage]
        let validUntil: TimeInterval
        let from: ConnectAddress?
        
        enum CodingKeys: String, CodingKey {
            case messages
            case validUntil = "valid_until"
            case from
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            messages = try container.decode([TonConnectMessage].self, forKey: .messages)
            validUntil = try container.decode(TimeInterval.self, forKey: .validUntil)
            from = try ConnectAddress.parse(try container.decode(String.self, forKey: .from))
        }
    }
    
    public struct TonConnectMessage: Decodable {
        let address: ConnectAddress
        let amount: Int64
        let stateInit: String?
        let payload: String?
        
        enum CodingKeys: String, CodingKey {
            case address
            case amount
            case stateInit
            case payload
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            address = try ConnectAddress.parse(try container.decode(String.self, forKey: .address))
            amount = Int64(try container.decode(String.self, forKey: .amount)) ?? 0
            stateInit = try container.decodeIfPresent(String.self, forKey: .stateInit)
            payload = try container.decodeIfPresent(String.self, forKey: .payload)
        }
    }
    
    public let method: Method
    public let params: [TonConnectParam]
    public let id: String
    
    enum CodingKeys: String, CodingKey {
        case method
        case params
        case id
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        method = try container.decode(Method.self, forKey: .method)
        id = try container.decode(String.self, forKey: .id)
        let paramsArray = try container.decode([String].self, forKey: .params)
        let jsonDecoder = JSONDecoder()
        params = paramsArray.compactMap {
            guard let data = $0.data(using: .utf8) else { return nil }
            return try? jsonDecoder.decode(TonConnectParam.self, from: data)
        }
    }
}
