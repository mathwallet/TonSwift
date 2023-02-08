//
//  TonKeyPair.swift
//  
//
//  Created by xgblin on 2022/12/19.
//

import Foundation
import BIP39swift
//import BIP32Swift
import TweetNacl

public struct TonKeypair {
    public var secretKey: Data
    public var publicKey: Data
    
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
        guard let mnemonicSeed = Mnemonics.seedFromMmemonics(mnemonics, saltString: "TON default seed") else {
            throw Error.invalidMnemonic
        }
//        let (seed, _) = TonKeypair.ed25519DeriveKey(path: path, seed: mnemonicSeed)
        try self.init(seed: mnemonicSeed)
    }
    
    public static func randomKeyPair() throws -> TonKeypair {
        guard let mnemonic = try? BIP39.generateMnemonics(bitsOfEntropy: 256) else{
            throw TonKeypair.Error.invalidMnemonic
        }
        return try TonKeypair(mnemonics: mnemonic)
    }
    
//    public static func ed25519DeriveKey(path: String, seed: Data) -> (key: Data, chainCode: Data) {
//        return NaclSign.KeyPair.deriveKey(path: path, seed: seed)
//    }
//
//    public static func ed25519DeriveKey(path: String, key: Data, chainCode: Data) -> (key: Data, chainCode: Data) {
//        return NaclSign.KeyPair.deriveKey(path: path, key: key, chainCode: chainCode)
//    }
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
