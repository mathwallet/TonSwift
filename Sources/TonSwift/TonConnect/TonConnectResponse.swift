//
//  TonConnectResponse.swift
//
//
//  Created by 薛跃杰 on 2024/6/5.
//

import Foundation

public enum ConnectEvent {
    case success(ConnectEventSuccess)
    case error(ConnectEventError)
}
public struct DeviceInfo: Encodable {
    public let platform = "iphone"
    public let appName = "Tonkeeper"
    public let appVersion = "3.4.0"
    public let maxProtocolVersion = 2
    public let features = [
        FeatureCompatible.legacy(Feature()),
        FeatureCompatible.feature(Feature())
    ]
    
    public enum FeatureCompatible: Encodable {
        case feature(Feature)
        case legacy(Feature)
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .feature(let feature):
                try container.encode(feature)
            case .legacy(let feature):
                try container.encode(feature.name)
            }
        }
    }
    
    public struct Feature: Encodable {
        public let name = "SendTransaction"
        public let maxMessages = 4
    }
    
    public init() {}
}

public enum ConnectItemReply: Encodable {
    case tonAddress(TonAddressItemReply)
    case tonProof(TonProofItemReply)
}

public enum TonProofItemReply: Encodable {
    case success(TonProofItemReplySuccess)
    case error(TonProofItemReplyError)
}

public struct TonProofItemReplySuccess: Encodable {
    public let name = "ton_proof"
    public let proof: Proof
    
    public init(proof: Proof) {
        self.proof = proof
    }
    
    public init(address: Address,
         domain: String,
         payload: String,
         privateKey: Data) {
        let timestamp = UInt64(Date().timeIntervalSince1970)
        let domain = Domain(domain: domain)
        let signature = Signature(
            address: address,
            domain: domain,
            timestamp: timestamp,
            payload: payload)
        let proof = Proof(
            timestamp: timestamp,
            domain: domain,
            signature: signature,
            payload: payload,
            privateKey: privateKey)
        
        self.init(proof: proof)
    }
    
    public struct Proof: Encodable {
        public let timestamp: UInt64
        public let domain: Domain
        public let signature: Signature
        public let payload: String
        public let privateKey: Data
    }
    
    public struct Signature: Encodable {
        public let address: Address
        public let domain: Domain
        public let timestamp: UInt64
        public let payload: String
        
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(address.toString(isUserFriendly: false), forKey: .address)
            try container.encode(domain, forKey: .domin)
            try container.encode(timestamp, forKey: .timestamp)
            try container.encode(payload, forKey: .payload)
            
        }
        enum CodingKeys: String, CodingKey {
            case address
            case domin
            case timestamp
            case payload
        }
    }
    
    public struct Domain: Encodable {
        public let lengthBytes: UInt32
        public let value: String
        
        init(domain: String) {
            let domainLength = UInt32(domain.utf8.count)
            self.value = domain
            self.lengthBytes = domainLength
        }
    }
}

public struct TonAddressItemReply: Encodable {
    public let name = "ton_addr"
    public let address: Address
    public let network: Network
    public let publicKey: Data
    public let walletStateInit: TonConnectStateInit
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(address.toString(isUserFriendly: false), forKey: .address)
        try container.encode(publicKey.toHexString(), forKey: .publicKey)
        try container.encode(walletStateInit.store().toBocBase64(), forKey: .walletStateInit)
    }
    enum CodingKeys: String, CodingKey {
        case name
        case address
        case network
        case publicKey
        case walletStateInit
    }
}

public struct TonProofItemReplyError: Encodable {
    public struct Error: Encodable {
        let message: String?
        let code: ErrorCode
    }
    public enum ErrorCode: Int, Encodable {
        case unknownError = 0
        case methodNotSupported = 400
    }
    
    public let name = "ton_proof"
    public let error: Error
}

public struct ConnectEventSuccess: Encodable {
    public struct Payload: Encodable {
        public let items: [ConnectItemReply]
        public let device: DeviceInfo
        
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(items, forKey: .items)
            try container.encode(device, forKey: .device)
        }
        
        enum CodingKeys: String, CodingKey {
            case items
            case device
        }
    }
    public let event = "connect"
    public let id = Int(Date().timeIntervalSince1970)
    public let payload: Payload
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(event, forKey: .event)
        try container.encode(event, forKey: .payload)
    }
    enum CodingKeys: String, CodingKey {
        case id
        case event
        case payload
    }
}

public struct ConnectEventError {
    public struct Payload {
        public let code: Error
        public let message: String
    }
    public enum Error: Int, Swift.Error {
        case unknownError = 0
        case badRequest = 1
        case appManifestNotFound = 2
        case appManifestContentError = 3
        case unknownApp = 100
        case userDeclinedTheConnection = 300
    }
    public let event = "connect_error"
    public let id = Int(Date().timeIntervalSince1970)
    public let payload: Payload
}
