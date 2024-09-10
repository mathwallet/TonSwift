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
    
    static let DEFAULT_ITERATIONS = 100000
    
    // Default salt for PBKDF2 used to generate seed
    static let DEFAULT_SALT = "TON default seed"
    
    // Number of PBKDF2 iterations used to check, if mnemonic phrase is valid
    static let DEFAULT_BASIC_ITERATIONS = 390
    
    // Default salt used to check mnemonic phrase validity
    static let DEFAULT_BASIC_SALT = "TON seed version"
    
    // Number of PBKDF2 iterations used to check, if mnemonic phrase requires a password
    static let DEFAULT_PASSWORD_ITERATIONS = 1
    
    // Default salt used to check, if mnemonic phrase requires a password
    static let DEFAULT_PASSWORD_SALT = "TON fast seed version"
    
    public static func generate(wordsCount: Int = 24, password: String = "", language: BIP39Language = BIP39Language.english) -> String {
        var mnemonicArray: [String] = []
        while true {
            mnemonicArray = []
            let rnd = [Int](repeating: 0, count: wordsCount).map({ _ in Int.random(in: 0..<Int.max) })
            for i in 0..<wordsCount {
                mnemonicArray.append(language.words[rnd[i] % (language.words.count - 1)])
            }
            let mnemonic =  mnemonicArray.joined(separator: " ")
            
            if password.count > 0 {
                if !isPasswordNeeded(mnemonic: mnemonic, password: password) {
                    continue
                }
            }
            
            if !isBasicSeed(entropy: mmemonicsToEntropy(mnemonic, password: password)) {
                continue
            }
            
            break
        }
        return mnemonicArray.joined(separator: " ")
    }
    
    public static func isValid(_ mnemonics: String, password: String = "", language: BIP39Language = BIP39Language.english) -> Bool {
        let mnemonicArr = mnemonics.components(separatedBy: " ")
        for word in mnemonicArr {
            if !language.words.contains(word) {
                return false
            }
        }
        let entropy = mmemonicsToEntropy(mnemonics, password: password)
        return isBasicSeed(entropy: entropy)
    }
    
    public static func isBasicSeed(entropy: Data) -> Bool {
        let saltData = DEFAULT_BASIC_SALT.data(using: .utf8)!
        let seed = pbkdf2Sha512(phrase: entropy, salt: saltData, iterations: DEFAULT_BASIC_ITERATIONS)
        return seed[0] == 0
    }
    
    static public func seedFromMmemonics(_ mnemonics: String, password: String = "") -> Data? {
        let entropy = mmemonicsToEntropy(mnemonics, password: password)
        let saltData = DEFAULT_SALT.data(using: .utf8)!
        return Data(pbkdf2Sha512(phrase: entropy, salt: saltData, iterations: DEFAULT_ITERATIONS))
    }
    
    public static func isPasswordNeeded(mnemonic: String, password: String = "") -> Bool {
        let entropy = mmemonicsToEntropy(mnemonic, password: password)
        return isPasswordSeed(entropy: entropy) && !isBasicSeed(entropy: entropy)
    }
    
    public static func isPasswordSeed(entropy: Data) -> Bool {
        let saltData = DEFAULT_PASSWORD_SALT.data(using: .utf8)!
        let seed = pbkdf2Sha512(phrase: entropy, salt: saltData, iterations: DEFAULT_PASSWORD_ITERATIONS)
        return seed[0] == 1
    }
    
    static public func mmemonicsToEntropy(_ mnemonics: String, password: String) -> Data {
        return hmacSha512(phrase: mnemonics, password: password)
    }

    public static func pbkdf2Sha512(phrase: Data, salt: Data, iterations: Int, keyLength: Int = 64) -> [UInt8] {
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
