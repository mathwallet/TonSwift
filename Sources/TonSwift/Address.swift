//
//  Address.swift
//  
//
//  Created by xgblin on 2022/12/19.
//

import Foundation
import BigInt

public class Address {

    private static let bounceable_tag: UInt8 = 0x11
    private static let non_bounceable_tag: UInt8 = 0x51
    private static let test_flag: Int = 0x80

    public var wc: UInt8
    public var hashPart: Data
    public var isTestOnly: Bool
    public var isUserFriendly: Bool
    public var isBounceable: Bool
    public var isUrlSafe: Bool = false

    public init() {
        wc = UInt8(0)
        hashPart = Data()
        isTestOnly = false
        isUserFriendly = false
        isBounceable = false
        isUrlSafe = false
    }
    
    public init?(addressStr: String) {
        if (addressStr.isEmpty) {
            return nil
        }
         
        var address = addressStr
        if (!address.contains(":")) {
            if (address.contains("-") || address.contains("_")) {
                isUrlSafe = true
                //convert to unsafe URL
                address = address.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            } else {
                isUrlSafe = false
            }
        }
        let arr = address.components(separatedBy: ":")
        if arr.count > 1 {

            if (arr.count != 2) {
                return nil
            }

            let wcInternal = Int(arr[0])

            if (wcInternal != 0 && wcInternal != -1) {
                return nil
            }

            var hex = arr[1]
            if (hex.count != 64) {
                if (hex.count == 63) {
                    hex = "0" + hex
                } else {
                    return nil
                }
            }

            isUserFriendly = false
            wc = UInt8(wcInternal ?? 0)
            hashPart = Data(hex: hex)
            isTestOnly = false
            isBounceable = false
        } else {
            isUserFriendly = true
            guard let parseResult = Address.parseFriendlyAddress(addressString: address) else {
                return nil
            }
            wc = parseResult.wc
            hashPart = parseResult.hashPart
            isTestOnly = parseResult.isTestOnly
            isBounceable = parseResult.isBounceable
        }
    }
    
    public init?(address: Address?) {
        guard let _address = address else {
            return nil
        }

        wc = _address.wc
        hashPart = _address.hashPart
        isTestOnly = _address.isTestOnly
        isUserFriendly = _address.isUserFriendly
        isBounceable = _address.isBounceable
        isUrlSafe = _address.isUrlSafe

    }

    public static func of(addressStr: String) throws -> Address? {
        return Address(addressStr: addressStr)
    }

    public static func of(address: Address) throws -> Address? {
        return Address(address: address)
    }

    public func toDecimal() -> String {
        let bigInt = BigInt(hashPart.toHexString(), radix: 16) ?? BigInt(0)
        return String(bigInt, radix: 10)
    }

    public func toHex() -> String {
        return hashPart.toHexString()
    }

    public func toString() -> String {
        return toString(isUserFriendly: isUserFriendly, isUrlSafe: isUrlSafe, isBounceable: isBounceable, isTestOnly: isTestOnly);
    }

    public func toString(isUserFriendly: Bool) -> String {
        return toString( isUserFriendly: isUserFriendly, isUrlSafe: self.isUrlSafe)
    }

    public func toString(isUserFriendly: Bool, isUrlSafe: Bool) -> String {
        return toString(isUserFriendly: isUserFriendly, isUrlSafe: isUrlSafe, isBounceable: self.isBounceable)
    }

    public func toString(isUserFriendly: Bool, isUrlSafe: Bool, isBounceable: Bool) -> String {
        return toString(isUserFriendly: isUserFriendly, isUrlSafe: isUrlSafe, isBounceable: isBounceable, isTestOnly: self.isTestOnly)
    }

    public func toString(isUserFriendly: Bool,
                           isUrlSafe: Bool,
                           isBounceable: Bool,
                           isTestOnly: Bool) -> String {

        if (!isUserFriendly) {
            return "\(wc):\(hashPart.toHexString())"
        } else {
            var tag = isBounceable ? Address.bounceable_tag : Address.non_bounceable_tag
            if (isTestOnly) {
                tag |= UInt8(Address.test_flag)
            }

            var addr = [UInt8](repeating: UInt8(0), count: 34)
            var addressWithChecksum = [UInt8](repeating: UInt8(0), count: 36)
            addr[0] = UInt8(tag)
            addr[1] = UInt8(wc)

            addr.replaceSubrange(2...33, with: hashPart[0..<32])

            let crc16 = Utils.getCRC16ChecksumAsBytes(data: Data(addr))
            
            addressWithChecksum.replaceSubrange(0..<34, with: addr[0..<34])
            addressWithChecksum.replaceSubrange(34..<36, with: crc16[0..<2])

            var addressBase64 = addressWithChecksum.toBase64()

            if (isUrlSafe) {
                let s = Data(addressWithChecksum).base64EncodedString()
                addressBase64 = s.replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
            }
            return addressBase64
        }
    }

    public static func isValid(address: Address) -> Bool {
        if let _ = try? Address.of(address: address) {
            return true
        } else {
            return false
        }
    }

    public static func parseFriendlyAddress(addressString: String) -> Address? {
        if (addressString.count != 48) {
            return nil
        }
        let base64Bytes = [UInt8](base64: addressString)
        if (base64Bytes.count != 36) { // 1byte tag + 1byte workchain + 32 bytes hash + 2 byte crc
            return nil
        }

        let addr = Array<UInt8>(base64Bytes[0..<34])
        let crc = Array<UInt8>(base64Bytes[34..<36])

        let calculatedCrc16 = Utils.getCRC16ChecksumAsBytes(data: Data(addr)).bytes
        if (!(calculatedCrc16[0] == crc[0] && calculatedCrc16[1] == crc[1])) {
            return nil
        }
        var tag = UInt8(addr[0] & 0xff)
        var isTestOnlyPart = false
        var isBounceablePart = false

        if ((tag & UInt8(test_flag)) != 0) {
            isTestOnlyPart = true
            tag = UInt8(tag ^ UInt8(test_flag))
        }
        if ((tag != bounceable_tag) && (tag != non_bounceable_tag)) {
            return nil
        }

        isBounceablePart = tag == bounceable_tag

        var workchain: Int = 0
        if ((addr[1] & 0xff) == 0xff) {
            workchain = -1
        } else {
            workchain = Int(addr[1])
        }
        if (workchain != 0 && workchain != -1) {
            return nil
        }

        let hashP = addr[2..<34]

        let parsedAddress = Address()
        parsedAddress.wc = UInt8(workchain)
        parsedAddress.hashPart = Data(hashP)
        parsedAddress.isTestOnly = isTestOnlyPart
        parsedAddress.isBounceable = isBounceablePart

        return parsedAddress
    }
}

