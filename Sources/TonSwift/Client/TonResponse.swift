//
//  TonResponse.swift
//  
//
//  Created by xgblin on 2023/2/3.
//

import Foundation
import BigInt

public struct TonRPCResult<T: Codable>: Codable {
    public let ok: Bool
    public let error: String?
    public let result: T?
    public let jsonrpc: String?
    public let id: String?
}

public struct ChainInfoResult: Codable {
    public let last: LastResult
    public let stateRootHash: String
    public var seqno: Int64 {
        return last.seqno
    }
    public var rootHash: String {
        return last.rootHash
    }
    public var fileHash: String {
        return last.fileHash
    }
    
    public struct LastResult: Codable {
        public let workchain: Int
        public let shard: String
        public let seqno: Int64
        public let rootHash: String
        public let fileHash: String
    }
}

public struct AddressInfoResult: Codable {
    public let type: Bool
    public let balance: String
    public let code: String
    public let data: String
    public let state: String
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case balance
        case code
        case data
        case state
    }
}

public struct WalletInfoResult: Codable {
    public let wallet: Bool
    public let balance: String
    public let accountState: String
    public let walletType: String
    public let seqno: Int64
}

public struct TonSeqnoResult: Codable {
    public let type: String
    public let gasUsed: Int
    public let stack: [[String]]
    public let exitCode: Int
    public let extra: String
    
    public var seqno: Int64 {
        let stacks = stack[0]
        let seqnoStr = stacks[1].replacingOccurrences(of: "0x", with: "")
        return Int64(seqnoStr, radix: 16) ?? Int64(0)
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case gasUsed
        case stack
        case exitCode
        case extra = "@extra"
    }
}
