//
//  File.swift
//  
//
//  Created by xgblin on 2023/1/30.
//

import Foundation
import BIP39swift
import CryptoSwift
import CommonCrypto

public struct Mnemonics {
    static public func random() -> String? {
        guard let mnemonic = try? BIP39.generateMnemonics(bitsOfEntropy: 256) else{
            return nil
        }
        return mnemonic
    }
    
    static public func seedFromMmemonics(_ mnemonics: String, saltString: String, password: String = "", language: BIP39Language = BIP39Language.english) -> Data? {
        let valid = toEntropy(mnemonics: mnemonics) != nil
        if (!valid) {
            return nil
        }
        guard let mnemData = mnemonics.decomposedStringWithCompatibilityMapping.data(using: .utf8) else {return nil}
        let salt = saltString + password
        guard let saltData = salt.decomposedStringWithCompatibilityMapping.data(using: .utf8) else {return nil}
        guard let seedArray = try? PKCS5.PBKDF2(password: mnemData.bytes, salt: saltData.bytes, iterations: 2048, keyLength: 64, variant: HMAC.Variant.sha512).calculate() else {return nil}
        let seed = Data(seedArray)
        return seed
    }
    
    static public func toEntropy(mnemonics: String) -> Data? {
        guard let mnemData = mnemonics.decomposedStringWithCompatibilityMapping.data(using: .utf8) else {return nil}
        let key = "HmacSHA512".data(using: .utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA512), key.bytes, key.count, mnemData.bytes, mnemData.count, &digest)
        return Data(digest)
    }
}
