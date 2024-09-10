//
//  TonKeyPair.swift
//  
//
//  Created by xgblin on 2022/12/19.
//

import Foundation
import BIP39swift
import TweetNacl

public struct TonKeypair {
    public var secretKey: Data
    public var publicKey: Data
    public var mnemonics: String?
    
    public init(secretKey: Data) throws {
        self.secretKey = secretKey
        let pubKey = try NaclSign.KeyPair.keyPair(fromSecretKey: secretKey).publicKey
        self.publicKey = pubKey
    }
    
    public init(seed: Data) throws {
        let secretKey = try NaclSign.KeyPair.keyPair(fromSeed: seed[0..<32]).secretKey
        try self.init(secretKey: secretKey)
    }
    
    public init(mnemonics: String) throws {
        guard let mnemonicSeed = Mnemonics.seedFromMmemonics(mnemonics) else {
            throw Error.invalidMnemonic
        }
        try self.init(seed: mnemonicSeed)
        self.mnemonics = mnemonics
    }
    
    public static func randomKeyPair() throws -> TonKeypair {
        let mnemonics = Mnemonics.generate()
        return try TonKeypair(mnemonics: mnemonics)
    }
}

// MARK: - Sign&Verify
extension TonKeypair {
    public func signData(data: Data) throws -> Data {
        return try NaclSign.signDetached(message: data, secretKey: secretKey)
    }
    
    public func signVerify(message: Data, signature: Data) -> Bool {
        guard let ret = try? NaclSign.signDetachedVerify(message: message, sig: signature, publicKey: publicKey) else {
            return false
        }
        return ret
    }
}

// MARK: Error

extension TonKeypair {
    public enum Error: String, LocalizedError {
        case invalidMnemonic
        case invalidDerivePath
        case unknown
        
        public var errorDescription: String? {
            return "TonKeypair.Error.\(rawValue)"
        }
    }
}
