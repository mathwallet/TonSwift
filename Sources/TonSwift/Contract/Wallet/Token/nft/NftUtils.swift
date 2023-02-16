//
//  NftUtils.swift
//  
//
//  Created by xgblin on 2023/2/14.
//

import Foundation
import BigInt

public struct NftUtils {
    public static let SNAKE_DATA_PREFIX = 0x00
    public static let CHUNK_DATA_PREFIX = 0x01
    public static let ONCHAIN_CONTENT_PREFIX = 0x00
    public static let OFFCHAIN_CONTENT_PREFIX = 0x01
    
    public static func serializeUri(uri: String) -> Data? {
        return uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.data(using: .utf8)
    }
    
    public static func parseUri(data: Data) -> String {
        let uriStr = String(data: data, encoding: .utf8) ?? ""
        return uriStr.removingPercentEncoding ?? ""
    }
    
    public static func createOffchainUriCell(uri: String) throws -> Cell {
        let cell = CellBuilder.beginCell()
        let _ = try cell.storeUint(number: OFFCHAIN_CONTENT_PREFIX, bitLength: 8)
        let _ = try cell.storeBytes(bytes: uri.data(using: .utf8)!.bytes)
        return cell.endCell
    }

    public static func parseOffchainUriCell(cell: Cell) throws -> String {
        if ((cell.bits.toByteArray()[0] & 0xFF) != OFFCHAIN_CONTENT_PREFIX) {
            throw TonError.otherError("no OFFCHAIN_CONTENT_PREFIX")
        }
        
        var length = 0
        var c: Cell = cell
        var cisNil = false
        while (cisNil == false) {
            length += c.bits.toByteArray().count
            if (c.getUsedRefs() != 0) {
                c = c.refs[0]!
                cisNil = false
            } else {
                cisNil = true
            }
        }
        
        var bytes = Data(count: length)
        length = 0
        c = cell
        cisNil = false
        while (cisNil == false) {
            bytes = Data(c.bits.toByteArray()[0..<length])
            length += c.bits.toByteArray().count
            if (c.getUsedRefs() != 0) {
                c = c.refs[0]!
                cisNil = false
            } else {
                bytes = Data(c.bits.toByteArray()[0..<length])
                cisNil = true
            }
        }
        return parseUri(data: Data(bytes[1..<bytes.count]))
    }
    
    public static func createOnchainDataCell(name: String, description: String) throws -> Cell {
        let cell = CellBuilder.beginCell()
        let _ = try cell.storeUint(number: ONCHAIN_CONTENT_PREFIX, bitLength: 8)
        let _ = try cell.storeBytes(bytes: name.data(using: .utf8)!.bytes)
        let _ = try cell.storeString(str: description)
        return cell.endCell
    }
    

    public static func readIntFromBitString(bs: BitString, cursor: Int, bits: Int) -> BigInt {
        var n = BigInt.zero
        for i in 0..<bits {
            n = n * BigInt(2)
            n = n + (bs.getNValue(n: cursor + i) ? BigInt(1) : BigInt.zero)
        }
        return n
    }
    

    public static func parseAddress(cell: Cell) -> Address? {
        var result = ""
        var n = readIntFromBitString(bs: cell.bits, cursor: 3, bits: 8)
        if n > BigInt(127) {
            n = n - BigInt(256)
        }
        let hashPart = readIntFromBitString(bs: cell.bits, cursor: 3 + 8, bits: 256)
        if ("\(String(n, radix: 10)):\(String(hashPart, radix: 16))" == "0:0") {
            return nil
        }
        let partStr = String(hashPart, radix: 16).description
        let array = Array<String>(repeating: "0", count: 64 - partStr.count)
        let leftedString = "\(array.joined())\(partStr)"
        result = "\(String(n, radix: 10)):\(leftedString)"
        
        return Address(addressStr: result)
    }
}
