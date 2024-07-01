//
//  Utils.swift
//  
//
//  Created by xgblin on 2023/1/3.
//

import Foundation
import CryptoSwift
import TweetNacl
import CommonCrypto
import BigInt

fileprivate let alphabet = "abcdefghijklmnopqrstuvwxyz234567"

public struct Utils {
    public init() {}
    
    public static func readNBytesFromArray(count: Int, ui8array: [UInt8]) -> Int {
        var res: Int = 0
        for i in 0 ..< count {
            res *= 256
            res += Int(ui8array[i] & 0xff)
        }
        return res
    }
    
    public static func crc32c(source: Data) -> Data {
        let poly: UInt32 = 0x82f63b78
        var crc: UInt32 = 0 ^ 0xffffffff
        
        for i in 0..<source.count {
            crc ^= UInt32(source[i])
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
        }
        crc = crc ^ 0xffffffff

        var res = Data(count: 4)
        res.withUnsafeMutableBytes { (resPointer: UnsafeMutableRawBufferPointer) -> Void in
            resPointer.storeBytes(of: crc.littleEndian, as: UInt32.self)
        }
        
        return res
    }
    
    public static func getCRC32ChecksumAsBytesReversed(data: Data) -> Data {
        let crc32c = Checksum.crc32c(data.bytes)
        let intCrcBytes = withUnsafeBytes(of: crc32c.bigEndian, Array.init)
        return Data(intCrcBytes.reversed())
    }
    
    public static func getCRC16ChecksumAsInt(data: Data) -> Int {
        var crc: Int = 0x0000;
        let polynomial: Int = 0x1021;
        for b in data.bytes {
            for i in 0..<8 {
                let bit = ((b >> (7 - i) & 1) == 1)
                let c15 = ((crc >> 15 & 1) == 1)
                crc = crc << 1
                if (UInt8(c15 ? 1 : 0) ^ UInt8(bit ? 1 : 0)) == UInt8(1) {
                    crc = crc ^ polynomial
                }
            }
        }

        crc = crc & 0xffff
        return crc;
    }

    public static func getCRC16ChecksumAsBytes(data: Data) -> Data {
        let crc16c = getCRC16ChecksumAsInt(data: data)
        return Data(intToByteArray(value: crc16c))
    }
    
    public static func intToByteArray(value: Int) -> [UInt8] {
        var intV = value
        let valueBytes: Data = Data(bytes: &intV, count: 8)
        return [valueBytes[1],valueBytes[0]]
    }
    
    public static func compareBytes(a: [UInt8], b: [UInt8]) -> Bool {
        return a.elementsEqual(b)
    }
    
    public static func signData(prvKey: Data, data: Data) throws -> Data {
         var signature = Data()
         if (prvKey.count == 64) {
             signature = try TweetNacl.NaclSign.signDetached(message: data, secretKey: prvKey)
         } else {
             let keyPair = try TweetNacl.NaclSign.KeyPair.keyPair(fromSecretKey: prvKey)
             signature = try TweetNacl.NaclSign.signDetached(message: data, secretKey: keyPair.secretKey)
         }
         return signature
     }
}

public extension Data {
    mutating func writeInt32LE(_ value: Int32) {
        self.append(contentsOf: Swift.withUnsafeBytes(of: value.littleEndian) { Array($0)})
    }
    
    mutating func writeInt32BE(_ value: Int32) {
        self.append(contentsOf: Swift.withUnsafeBytes(of: value.bigEndian) { Array($0)})
    }
    
    mutating func writeInt64LE(_ value: Int64) {
        self.append(contentsOf: Swift.withUnsafeBytes(of: value.littleEndian) { Array($0)})
    }
    
    func toBase32() -> String {
        let length = self.count
        var bits = 0
        var value = 0
        var output = ""
        
        for i in 0..<length {
            value = (value << 8) | Int(self[i])
            bits += 8
            
            while bits >= 5 {
                output.append(alphabet[alphabet.index(alphabet.startIndex, offsetBy: (value >> (bits - 5)) & 31)])
                bits -= 5
            }
        }
        if bits > 0 {
            output.append(alphabet[alphabet.index(alphabet.startIndex, offsetBy: (value << (5 - bits)) & 31)])
        }
        return output
    }
}

public enum BitsMode {
    case int
    case uint
}

extension BigInt {
    public func bitsCount(mode: BitsMode) throws -> Int {
        let v = self
        switch mode {
        case .int:
            // Corner case for zero or -1 value
            if v == 0 || v == -1 {
                return 1
            }
            
            let v2 = v > 0 ? v : -v
            return v2.bitWidth + 1 // Sign bit
        case .uint:
            if v < 0 {
                throw TonError.otherError("Value is negative. Got \(self)")
            }
            
            return v.bitWidth
        }
    }
}

extension Int {
    public func bitsCount(mode: BitsMode) throws -> Int {
        return try BigInt(self).bitsCount(mode: mode)
    }
}

extension String {
    public func fromBase32() throws -> Data {
        let cleanedInput = self.lowercased()
        let length = cleanedInput.count
        var bits = 0
        var value = 0
        
        var index = 0
        var output = Data(capacity: (length * 5 / 8) | 0)
        
        for i in cleanedInput.indices {
            let char = try readChar(alphabet: alphabet, char: cleanedInput[i])
            value = (value << 5) | char
            bits += 5
            
            if bits >= 8 {
                output[index] = UInt8((value >> (bits - 8)) & 255)
                index += 1
                bits -= 8
            }
        }
        return output
    }
}

extension Data {
    func crc16Data() -> Data {
        let poly: UInt32 = 0x1021
        var reg: UInt32 = 0
        var message = self
        message.append(0)
        message.append(0)
        
        for byte in message {
            var mask: UInt8 = 0x80
            while mask > 0 {
                reg <<= 1
                if byte & mask != 0 {
                    reg += 1
                }
                
                mask >>= 1
                if reg > 0xffff {
                    reg &= 0xffff
                    reg ^= poly
                }
            }
        }
        
        let highByte = UInt8(reg / 256)
        let lowByte = UInt8(reg % 256)
        
        return Data([highByte, lowByte])
    }
    
    func crc32cData() -> Data {
        let poly: UInt32 = 0x82f63b78
        var crc: UInt32 = 0 ^ 0xffffffff
        
        for i in 0..<self.count {
            crc ^= UInt32(self[i])
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
            crc = ((crc & 1) != 0) ? (crc >> 1) ^ poly : crc >> 1
        }
        crc = crc ^ 0xffffffff

        var res = Data(count: 4)
        res.withUnsafeMutableBytes { (resPointer: UnsafeMutableRawBufferPointer) -> Void in
            resPointer.storeBytes(of: crc.littleEndian, as: UInt32.self)
        }
        
        return res
    }
}

public func readChar(alphabet: String, char: Character) throws -> Int {
    if let idx = alphabet.firstIndex(of: char) {
        return alphabet.distance(from: alphabet.startIndex, to: idx)
    } else {
        throw TonError.otherError("Invalid character found: \(char)")
    }
}
