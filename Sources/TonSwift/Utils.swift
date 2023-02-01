//
//  Utils.swift
//  
//
//  Created by 薛跃杰 on 2023/1/3.
//

import Foundation
import CryptoSwift
import TweetNacl

public struct Utils {
    public init() {}
    
    public static func readNBytesFromArray(count: Int, ui8array: [UInt8]) -> Int {
        var res:Int = 0;
        for i in 0 ..< count {
            res *= 256
            res += Int(ui8array[i] & 0xff)
        }
        return res
    }
    
    public static func getCRC32ChecksumAsBytesReversed(data: Data) -> Data {
        let crc32c = Checksum.crc32c(data.bytes)
        let intCrcBytes = withUnsafeBytes(of: crc32c.bigEndian, Array.init)
        return Data(intCrcBytes.reversed())
    }

    public static func getCRC16ChecksumAsBytes(data: Data) -> Data {
        let crc16c = Checksum.crc16(data.bytes)
        return Data(intToByteArray(value: Int(crc16c)))
    }
    
    public static func intToByteArray(value: Int) -> [UInt8] {
         return [UInt8(value >> 8), UInt8(value)]
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
