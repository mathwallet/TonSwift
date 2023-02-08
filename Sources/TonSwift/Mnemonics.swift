//
//  File.swift
//  
//
//  Created by xgblin on 2023/1/30.
//

import Foundation
import BIP39swift
import CryptoSwift
import JOSESwift
import Security.SecRandom

public struct Mnemonics {
    
    public static func generate(count: Int, password: String) -> String {
        var words = [String]()
        for _ in 0..<count {
            var index = -1
            while (index > 2047 || index < 0) {
                if let number = try? secureRandomNumber() {
                    index = Int(number)
                }
            }
            print(index)
            words.append(BIP39Language.english.words[index])
        }
        
        return words.joined(separator: " ")
    }
    
    private static func secureRandomNumber() throws -> UInt32 {
        var randomNumber: UInt32 = 0
        try withUnsafeMutablePointer(to: &randomNumber) {
                  try $0.withMemoryRebound(to: UInt8.self, capacity: 2) { (randomBytes: UnsafeMutablePointer<UInt8>) -> Void in
                      guard (SecRandomCopyBytes(kSecRandomDefault, 2, randomBytes) == 0) else {
                          throw TonError.unknow
                      }
                  }
              }
        return randomNumber
    }
    
    public static func isValid(_ mnemonics: String, password: String) -> Bool {
        let mnemonicArr = mnemonics.components(separatedBy: " ")
        guard mnemonicArr.count <= 24 else {return false}
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
    
    public static func isPasswordNeeded(mnemonic: String) -> Bool {
        guard let entropy = toEntropy(mnemonics: mnemonic,key:"") else {return false}
        return isPasswordSeed(entropy: entropy) && !isBasicSeed(entropy: entropy)
    }
    
    public static func isPasswordSeed(entropy: Data) -> Bool {
        guard let seed = try? PKCS5.PBKDF2(password: entropy.bytes, salt: "TON fast seed version".data(using: .utf8)!.bytes, iterations: 1, keyLength: 32, variant: HMAC.Variant.sha512).calculate() else {return false}
        return seed[0] == 1
    }
    
    static public func toEntropy(mnemonics: String, key: String) -> Data? {
        guard let mnemData = mnemonics.decomposedStringWithCompatibilityMapping.data(using: .utf8) else {return nil}
        guard let keyData = key.data(using: .utf8) else {return nil}
        let hmac:Authenticator = HMAC(key: mnemData.bytes, variant: .sha2(.sha512))
        guard let ent = try? hmac.authenticate(keyData.bytes) else {return nil }
        return Data(ent)
    }
}
