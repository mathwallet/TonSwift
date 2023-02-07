//
//  File.swift
//  
//
//  Created by xgblin on 2023/1/30.
//

import Foundation
import BIP39swift
import CryptoSwift

public struct Mnemonics {
    
    public static func isValid(_ mnemonics: String, password: String) -> Bool {
        let mnemonicArr = mnemonics.components(separatedBy: " ")
        guard mnemonicArr.count < 24 else {return false}
        for word in mnemonicArr {
            if !BIP39Language.english.words.contains(word) {
                return false
            }
        }
        guard let entropy = toEntropy(mnemonics: mnemonics, key: password) else { return false}
        return isBasicSeed(entropy: entropy)
    }
    
    public static func isBasicSeed(entropy: Data) -> Bool {
        let saltData = "TON seed version".data(using: .utf8)!
        guard let seedArray = try? PKCS5.PBKDF2(password: entropy.bytes, salt: saltData.bytes, iterations: 390, variant: HMAC.Variant.sha512).calculate() else {return false}
        return seedArray[0] == 0
    }
    
    static public func seedFromMmemonics(_ mnemonics: String, saltString: String, password: String = "", language: BIP39Language = BIP39Language.english) -> Data? {
        guard let entropy = toEntropy(mnemonics: mnemonics, key: "") else { return nil}
        let salt = saltString + password
        guard let saltData = salt.decomposedStringWithCompatibilityMapping.data(using: .utf8) else {return nil}
        guard let seedArray = try? PKCS5.PBKDF2(password: entropy.bytes, salt: saltData.bytes, iterations: 100000, keyLength: 32, variant: HMAC.Variant.sha512).calculate() else {return nil}
        let seed = Data(seedArray)
        return seed
    }
    
    static public func toEntropy(mnemonics: String, key: String) -> Data? {
        guard let mnemData = mnemonics.data(using: .utf8) else {return nil}
        guard let keyData = key.data(using: .utf8) else {return nil}
        let hmac:Authenticator = HMAC(key: mnemData.bytes, variant: .sha2(.sha512))
        guard let ent = try? hmac.authenticate(keyData.bytes) else {return nil }
        return Data(ent)
    }
}
