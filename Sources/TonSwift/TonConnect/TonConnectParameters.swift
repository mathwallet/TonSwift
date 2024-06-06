//
//  TonConnectParameters.swift
//
//
//  Created by 薛跃杰 on 2024/6/4.
//

import Foundation

public struct TonConnectParameters {
    public let version: String
    public let clientId: String
    public let payload: TonConnectRequestPayload
}

public struct TonConnectRequestPayload: Decodable {
  public enum Item: Decodable {
    case tonAddress
    case tonProof(payload: String)
    case unknown
    
    public enum CodingKeys: CodingKey {
      case name
      case payload
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let name = try container.decode(String.self, forKey: .name)
      switch name {
      case "ton_addr":
        self = .tonAddress
      case "ton_proof":
        let payload = try container.decode(String.self, forKey: .payload)
        self = .tonProof(payload: payload)
      default:
        self = .unknown
      }
    }
  }
  
  public let manifestUrl: String
  public let items: [Item]
  
  public init(manifestUrl: String, items: [Item]) {
    self.manifestUrl = manifestUrl
    self.items = items
  }
}
