//
//  File.swift
//  
//
//  Created by 薛跃杰 on 2023/1/30.
//

import Foundation
import BIP39swift
import CryptoSwift

extension BIP39 {
    static public func seedFromMmemonics(_ mnemonics: String, saltString: String, password: String = "", language: BIP39Language = BIP39Language.english) -> Data? {
        let valid = BIP39.mnemonicsToEntropy(mnemonics, language: language) != nil
        if (!valid) {
            return nil
        }
        guard let mnemData = mnemonics.decomposedStringWithCompatibilityMapping.data(using: .utf8) else {return nil}
        let salt = saltString + password
        guard let saltData = salt.decomposedStringWithCompatibilityMapping.data(using: .utf8) else {return nil}
        guard let seedArray = try? PKCS5.PBKDF2(password: mnemData.bytes, salt: saltData.bytes, iterations: 100000, keyLength: 64, variant: HMAC.Variant.sha512).calculate() else {return nil}
        let seed = Data(seedArray)
        return seed
    }
}
