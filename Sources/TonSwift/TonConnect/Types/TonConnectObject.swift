//
//  TonConnectResponse.swift
//
//
//  Created by 薛跃杰 on 2024/6/5.
//

import Foundation
import TweetNacl
import CryptoSwift

public enum ConnectEvent: Encodable {
    case success(ConnectEventSuccess)
    case error(ConnectEventError)
}

public struct ConnectEventSuccess: Encodable {
    public struct Payload: Encodable {
        public let items: [ConnectItemReply]
        public let device: DeviceInfo
    }
    public let event = "connect"
    public let id = Int(Date().timeIntervalSince1970)
    public let payload: Payload
}

public struct ConnectEventError: Encodable {
    public struct Payload: Encodable {
        public let code: Error
        public let message: String
    }
    
    public enum Error: Int, Encodable {
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

public struct DeviceInfo: Encodable {
    let platform = "iphone"
    let appName = "Tonkeeper"
    let appVersion = "3.4.0"
    let maxProtocolVersion = 2
    let features = [Feature()]
    
    struct Feature: Encodable {
        let name = "SendTransaction"
        let maxMessages = 4
    }
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
    public init(proof: Proof) {
        self.proof = proof
    }
    
    public init(address: ConnectAddress,
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
    
    public struct Signature {
        public let address: ConnectAddress
        public let domain: Domain
        public let timestamp: UInt64
        public let payload: String
    }
    
    public struct Domain: Encodable {
        public let lengthBytes: UInt32
        public let value: String
        
        public init(domain: String) {
          let domainLength = UInt32(domain.utf8.count)
          self.value = domain
          self.lengthBytes = domainLength
        }
    }
    
    public let name = "ton_proof"
    public let proof: Proof
}

public struct TonAddressItemReply: Encodable {
    public let name = "ton_addr"
    public let address: ConnectAddress
    public let network: Network
    public let publicKey: Data
    public let walletStateInit: ConnectStateInit
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

public enum SendTransactionResponse {
    case success(SendTransactionResponseSuccess)
    case error(SendTransactionResponseError)
}
public struct SendTransactionResponseSuccess: Encodable {
    let result: String
    let id: String
}
public struct SendTransactionResponseError: Encodable {
    struct Error: Encodable {
        let code: ErrorCode
        let message: String
    }
    
    public enum ErrorCode: Int, Encodable {
        case unknownError = 0
        case badRequest = 1
        case unknownApp = 10
        case userDeclinedTransaction = 300
        case methodNotSupported = 400
    }
    
    let id: String
    let error: Error
}

// MARK: - Encodable

extension ConnectEvent {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .success(let success):
            try container.encode(success)
        case .error(let error):
            try container.encode(error)
        }
    }
}

extension ConnectItemReply {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .tonAddress(let address):
            try container.encode(address)
        case .tonProof(let proof):
            try container.encode(proof)
        }
    }
}

extension TonProofItemReply {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .success(let success):
            try container.encode(success)
        case .error(let error):
            try container.encode(error)
        }
    }
}

extension TonAddressItemReply {
    enum CodingKeys: String, CodingKey {
        case name
        case address
        case network
        case publicKey
        case walletStateInit
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(address.toRaw(), forKey: .address)
        try container.encode("\(network.rawValue)", forKey: .network)
        try container.encode(publicKey.hexString(), forKey: .publicKey)
        
        let builder = ConnectBuilder()
        try walletStateInit.storeTo(builder: builder)
        try container.encode(
            builder.endCell().toBoc().base64EncodedString(),
            forKey: .walletStateInit)
    }
}

extension TonProofItemReplySuccess.Signature {
    func data() -> Data {
        var data = "ton-proof-item-v2/".data(using: .utf8)!
        let addressWorkchain = UInt32(bigEndian: UInt32(address.workchain))
        let addressWorkchainData = withUnsafeBytes(of: addressWorkchain) { a in
            Data(a)
        }
        data.append(addressWorkchainData)
        
        let addressHash = address.hash
        data.append(addressHash)
        
        let domainLength = withUnsafeBytes(of: UInt32(littleEndian: domain.lengthBytes)) { a in
            Data(a)
        }
        data.append(domainLength)
        
        let domainValue = domain.value.data(using: .utf8)!
        data.append(domainValue)
        
        let timestamp = withUnsafeBytes(of: UInt64(littleEndian: timestamp)) { a in
            Data(a)
        }
        data.append(timestamp)
        
        let payload = payload.data(using: .utf8)!
        data.append(payload)
        
        return data
    }
}

extension TonProofItemReplySuccess.Proof {
    enum CodingKeys: String, CodingKey {
        case timestamp
        case domain
        case signature
        case payload
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(domain, forKey: .domain)
        
        let signatureMessageData = signature.data()
        let signatureMessage = signatureMessageData.sha256()
        let prefixData = Data(hex: "ffff")
        guard let tonConnectData = "ton-connect".data(using: .utf8) else {
            return
        }
        let signatureData = (prefixData + tonConnectData + signatureMessage).sha256()
        let signature = try TweetNacl.NaclSign.signDetached(
            message: signatureData,
            secretKey: privateKey
        )
        try container.encode(signature, forKey: .signature)
        try container.encode(payload, forKey: .payload)
    }
}

extension SendTransactionResponse: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .success(let success):
            try container.encode(success)
        case .error(let error):
            try container.encode(error)
        }
    }
}
