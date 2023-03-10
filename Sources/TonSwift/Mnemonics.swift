//
//  File.swift
//  
//
//  Created by xgblin on 2023/1/30.
//

import Foundation
import BIP39swift
import CommonCrypto


public struct Mnemonics {
    
    public static func generate(wordsCount: Int, password: String) -> String {
        var mnemonicArray: [String] = []
        while true {
            mnemonicArray = []
            let rnd = [Int](repeating: 0, count: wordsCount).map({ _ in Int.random(in: 0..<Int.max) })
            for i in 0..<wordsCount {
                mnemonicArray.append(BIP39Language.english.words[rnd[i] % (BIP39Language.english.words.count - 1)])
            }
            let mnemonic =  mnemonicArray.joined(separator: " ")
            
            if password.count > 0 {
                if !isPasswordNeeded(mnemonic: mnemonic) {
                    continue
                }
            }
            
            if !isBasicSeed(entropy: toEntropy(mnemonics: mnemonic, key: password)) {
                continue
            }
            
            break
        }
        return mnemonicArray.joined(separator: " ")
    }
    
    public static func isValid(_ mnemonics: String, password: String) -> Bool {
        let mnemonicArr = mnemonics.components(separatedBy: " ")
        guard mnemonicArr.count <= 24 else {return false}
        for word in mnemonicArr {
            if !BIP39Language.english.words.contains(word) {
                return false
            }
        }
        let entropy = toEntropy(mnemonics: mnemonics, key: password)
        return isBasicSeed(entropy: entropy)
    }
    
    public static func isBasicSeed(entropy: Data) -> Bool {
        let saltData = "TON seed version".data(using: .utf8)!
        let seed = pbkdf2Sha512(phrase: entropy, salt: saltData, iterations: max(1, 100000 / 256))
        return seed[0] == 0
    }
    
    static public func seedFromMmemonics(_ mnemonics: String, saltString: String, password: String = "", language: BIP39Language = BIP39Language.english) -> Data? {
        let entropy = toEntropy(mnemonics: mnemonics, key: "")
        let saltData = "TON default seed".data(using: .utf8)!
        return Data(pbkdf2Sha512(phrase: entropy, salt: saltData))
    }
    
    public static func isPasswordNeeded(mnemonic: String) -> Bool {
        let entropy = toEntropy(mnemonics: mnemonic,key:"")
        return isPasswordSeed(entropy: entropy) && !isBasicSeed(entropy: entropy)
    }
    
    public static func isPasswordSeed(entropy: Data) -> Bool {
        let saltData = "TON default seed".data(using: .utf8)!
        let seed = pbkdf2Sha512(phrase: entropy, salt: saltData, iterations: 1)
        return seed[0] == 1
    }
    
    static public func toEntropy(mnemonics: String, key: String) -> Data {
        return hmacSha512(phrase: mnemonics, password: key)
    }

    public static func pbkdf2Sha512(phrase: Data, salt: Data, iterations: Int = 100000, keyLength: Int = 64) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: keyLength)
        
        _ = bytes.withUnsafeMutableBytes { (outputBytes: UnsafeMutableRawBufferPointer) in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                phrase.map({ Int8(bitPattern: $0) }),
                phrase.count,
                [UInt8](salt),
                salt.count,
                CCPBKDFAlgorithm(kCCPRFHmacAlgSHA512),
                UInt32(iterations),
                outputBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                keyLength
            )
        }
        
        return bytes
    }
    
    public static func hmacSha512(phrase: String, password: String) -> Data {
        let count = Int(CC_SHA512_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: count)
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA512),
               phrase,
               phrase.count,
               password,
               password.count,
               &digest)
        
        return Data(bytes: digest, count: count)
    }
}
