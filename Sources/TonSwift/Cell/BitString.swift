//
//  BitString.swift
//  
//
//  Created by xgblin on 2023/1/5.
//

import Foundation
import BigInt

public class BitString {
    public var array: Data
    public var writeCursor: Int
    public var readCursor: Int
    public var length: Int

    public init(array: Data, writeCursor: Int, readCursor: Int, length: Int) {
        self.array = array
        self.writeCursor = writeCursor
        self.readCursor = readCursor
        self.length = length
    }
    
    public init(bs: BitString) throws {
        array = Data()
        writeCursor = 0
        readCursor = 0
        length = 0
        for i in bs.readCursor..<bs.writeCursor {
            try writeBit(b: bs.getNValue(n: i))
        }
    }

    /**
     * Create BitString limited by length
     *
     * @param length Int    length of BitString in bits
     */
    public init(length: Int) {
        self.array = Data(repeating:0, count: Int(ceil(Double(length) / Double(8))))
        self.writeCursor = 0
        self.readCursor = 0
        self.length = length
    }

    /**
     * Return free bits, that derives from total length minus bits written
     *
     * @return Int
     */
    public func getFreeBits() -> Int {
        return length - writeCursor
    }

    /**
     * Returns used bits, i.e. last position of writeCursor
     *
     * @return Int
     */
    public func getUsedBits() -> Int {
        return writeCursor
    }

    /**
     * @return Int
     */
    public func getUsedBytes() -> Int {
        return Int(ceil(Double(writeCursor) / Double(8)))
    }

    /**
     * Return bit's value at position n
     *
     * @param n Int
     * @return Bool    bit value at position `n`
     */
    public func getNValue(n: Int) -> Bool {
        return (array[(n / 8)] & (1 << (7 - (n % 8)))) > 0
    }

    /**
     * Check if bit at position n is reachable
     *
     * @param n Int
     */
    private func checkRange(n: Int) -> Bool {
        if (n > length) {
            return false
        }
        return true
    }

    /**
     * Set bit value to 1 at position n
     *
     * @param n Int
     */
    func on(n: Int) throws {
        guard checkRange(n: n) else {
            throw TonError.otherError("BitString overflow")
        }
        array[(n / 8)] |= 1 << (7 - (n % 8))
    }

    /**
     * Set bit value to 0 at position n
     *
     * @param n Int
     */
    func off(n: Int) throws {
        guard checkRange(n: n) else {
            throw TonError.otherError("BitString overflow")
        }
        array[(n / 8)] &= ~(1 << (7 - (n % 8)))
    }

    /**
     * Toggle bit value at position n
     *
     * @param n Int
     */
    func toggle(n: Int) throws {
        guard checkRange(n: n) else {
            throw TonError.otherError("BitString overflow")
        }
        array[(n / 8)] ^= 1 << (7 - (n % 8))
    }

    /**
     * Write bit and increase cursor
     *
     * @param b Bool
     */
    public func writeBit(b: Bool) throws {
//        if (b) {
//            try on(n: writeCursor)
//        } else {
//            try off(n: writeCursor)
//        }
//        writeCursor += 1
        try writeBit(value: b ? 1:0)
    }
    
    public func writeBit(value: Int) throws {
        if writeCursor > array.count * 8 {
            throw TonError.otherError("BitBuilder overflow")
        }
        
        if value > 0 {
            array[writeCursor / 8] |= 1 << (7 - (writeCursor % 8));
        }
        
        writeCursor += 1
    }

    /**
     * Write bit and increase cursor
     *
     * @param u UInt8
     */
    func writeBit(u: UInt8) throws {
        if (u > 0) {
            try on(n: writeCursor)
        } else {
            try off(n: writeCursor)
        }
        writeCursor += 1
    }

    /**
     * @param ba Bool[]
     */
    public func writeBitArray(ba: [Bool]) throws {
        for b in ba {
           try writeBit(b: b)
        }
    }

    /**
     * @param ds Data
     */
    public func writeBitArray(ds: Data) throws {
        for d in ds {
            try writeBit(u: UInt8(d))
        }
    }

    /**
     * Write unsigned Int
     *
     * @param number    BigInt
     * @param bitLength Int size of uInt in bits
     */
    public func writeUInt(number: BigInt, bitLength: Int) throws {
        if number < 0 {
            throw TonError.otherError("Unsigned number cannot be less than 0")
        }
        if (bitLength == 0 || (number.magnitude.bitWidth > bitLength)) {
            if (number == 0) {
                return
            }
            throw TonError.otherError("bitLength is too small for number, got number= \(number), bitLength= \(bitLength)")
        }

        var s = String(number, radix: 2)

        if (s.count != bitLength) {
            for _ in 0..<bitLength - s.count {
                s = "0" + s
            }
        }
        for i in 0..<bitLength {
            let index = s.index(s.startIndex, offsetBy: i)
            let char = s[index]
            try writeBit(b: char == "1")
        }
    }

    /**
     * Write unsigned Int
     *
     * @param number    value
     * @param bitLength size of uInt in bits
     */
    public func writeUInt(number: Int64, bitLength: Int) throws {
        try writeUInt(number: BigInt(number), bitLength: bitLength)
    }

    /**
     * Write signed Int
     *
     * @param number    BigInt
     * @param bitLength Int size of Int in bits
     */
    public func writeInt(number: BigInt, bitLength: Int) throws {
        if (bitLength == 1) {
            if (number == -1) {
                try writeBit(b: true)
                return
            }
            if (number == 0) {
                try writeBit(b: false)
                return
            }
            throw TonError.otherError("bitLength is too small for number");
        } else {
            if (number.signum() == -1) {
                try writeBit(b: true);
                let b = BigInt(2)
                let nb = b.power(bitLength - 1)
                try writeUInt(number: nb + number, bitLength: bitLength - 1)
            } else {
                try writeBit(b: false)
                try writeUInt(number: number, bitLength: bitLength - 1)
            }
        }
    }

    /**
     * Write unsigned 8-bit Int
     *
     * @param ui8 Int
     */
    public func writeUInt8(ui8: Int) throws {
        try writeUInt(number: BigInt(ui8), bitLength: 8)
    }

    /**
     * Write array of unsigned 8-bit Ints
     *
     * @param ui8 Data
     */
    public func writeBytes(ui8s: [UInt8]) throws {
        for ui8 in ui8s {
            try writeUInt8(ui8: Int(ui8) & 0xff)
        }
    }

    /**
     * Write UTF-8 string
     *
     * @param value String
     */
    public func writeString(value: String) throws {
        try writeBytes(ui8s: value.data(using: .utf8)!.bytes)
    }

    /**
     * @param amount positive BigInt in nano-coins
     */
    public func writeCoins(amount: BigInt) throws {
        if (amount.signum() == -1) {
            throw TonError.otherError("Coins value must be positive.")
        }

        if (amount == 0) {
            try writeUInt(number: BigInt(0), bitLength: 4)
        } else {
            let bytesSize = Int(ceil(Double(amount.magnitude.bitWidth) / Double(8)))
            if (bytesSize >= 16) {
                throw TonError.otherError("Amount is too big. Maximum amount 2^120-1");
            }
            try writeUInt(number: BigInt(bytesSize), bitLength: 4)
            try writeUInt(number: BigInt(amount), bitLength: bytesSize * 8)
        }
    }

    /**
     * Appends BitString with Address
     * addr_none$00 = MsgAddressExt;
     * addr_std$10
     * anycast:(Maybe Anycast)
     * workchain_id:Int8
     * address:uInt256 = MsgAddressInt;
     *
     * @param address Address
     */
    public func writeAddress(address: Address?) throws {
        if let _address = address {
            try writeUInt(number: BigInt(2), bitLength: 2)
            try writeUInt(number: BigInt.zero, bitLength: 1);
            try writeInt(number: BigInt(_address.wc), bitLength: 8)
            try writeBytes(ui8s: _address.hashPart.bytes)
        } else {
            try writeUInt(number: BigInt(0), bitLength: 2)
        }
    }

    /**
     * Write another BitString to this BitString
     *
     * @param anotherBitString BitString
     */
    public func writeBitString(anotherBitString: BitString) throws {
        for i in anotherBitString.readCursor..<anotherBitString.writeCursor {
            try writeBit(b: anotherBitString.getNValue(n: i))
        }
    }

    /**
     * Read one bit without moving readCursor
     *
     * @return true or false
     */
    public func prereadBit() -> Bool{
        return getNValue(n: readCursor)
    }

    /**
     * Read one bit and moves readCursor forward by one position
     *
     * @return true or false
     */
    public func readBit() -> Bool {
        let result = getNValue(n: readCursor)
        readCursor += 1
        return result
    }

    /**
     * Read n bits from the BitString
     *
     * @param n Integer
     * @return BitString with length n read from original Bitstring
     */
    public func preReadBits(n: Int) throws -> BitString {
        let oldReadCursor = readCursor
        let result = BitString(length: n)
        for _ in 0..<n {
            try result.writeBit(b: readBit())
        }
        readCursor = oldReadCursor
        return result
    }

    /**
     * Read n bits from the BitString
     *
     * @param n Integer
     * @return BitString with length n read from original Bitstring
     */
    public func readBits(n: Int) throws -> BitString {
        let result = BitString(length: n)
        for _ in 0..<n {
            try result.writeBit(b: readBit())
        }
        return result
    }

    /**
     * Read bits of bitLength without moving readCursor, i.e. modifying BitString
     *
     * @param bitLength length in bits
     * @return BigInt
     */
    public func preReadUInt(bitLength: Int) throws -> BigInt {
        let oldReadCursor = readCursor

        if (bitLength < 1) {
            throw TonError.otherError("Incorrect bitLength")
        }
        var s = ""
        for _ in 0..<bitLength {
            if readBit() {
                s.append("1")
            } else {
                s.append("0")
            }
        }
        readCursor = oldReadCursor
        return BigInt(s,radix: 2)!
    }

    /**
     * Read unsigned Int of bitLength
     *
     * @param bitLength Int bitLength Size of uInt in bits
     * @return BigInt
     */
    public func readUInt(bitLength: Int) throws -> BigInt {
        if (bitLength < 1) {
            throw TonError.otherError("Incorrect bitLength")
        }
        var s = ""
        for _ in 0..<bitLength {
            if readBit() {
                s.append("1");
            } else {
                s.append("0");
            }
        }
        return BigInt(s,radix: 2)!
    }

    /**
     * Read signed Int of bitLength
     *
     * @param bitLength Int bitLength Size of signed Int in bits
     * @return BigInt
     */
    public func readInt(bitLength: Int) throws -> BigInt {
        if (bitLength < 1) {
            throw TonError.otherError("Incorrect bitLength");
        }

        let sign = readBit()
        if (bitLength == 1) {
            return sign ? BigInt("-1") : BigInt(0)
        }

        var number = try readUInt(bitLength: bitLength - 1)
        if sign {
            let b = BigInt(2)
            let nb = b.power(bitLength - 1)
            number = number - nb
        }
        return number
    }

    public func readUInt8() throws -> BigInt {
        return try readUInt(bitLength: 8)
    }

    public func readUInt16() throws -> BigInt {
        return try readUInt(bitLength: 16)
    }

    public func readUInt32() throws -> BigInt{
        return try readUInt(bitLength: 32)
    }

    public func readUInt64() throws -> BigInt {
        return try readUInt(bitLength: 64)
    }

    public func readInt8() throws -> BigInt {
        return try readInt(bitLength: 8)
    }

    public func readInt16() throws -> BigInt {
        return try readInt(bitLength: 16)
    }

    public func readInt32() throws -> BigInt {
        return try readInt(bitLength: 32)
    }

    public func readInt64() throws -> BigInt {
        return try readInt(bitLength: 64)
    }

    public func readAddress() throws -> Address? {
        let i = try preReadUInt(bitLength: 2)
        if i.isZero  {
            let _ = try readBits(n: 2)
            return nil
        }
        let _ = try readBits(n: 2)
        let _ = try readBits(n: 1)
        let workchain = try readInt(bitLength: 8).description
        let hashPart = try readUInt(bitLength: 256)
        let address = "\(workchain):\(String(hashPart, radix: 10).replacingOccurrences(of: " ", with: "0"))"
        return Address(addressStr: address)
    }

    public func readString(length: Int) throws -> String {
        let bitString = try readBits(n: length)
        return String(data: bitString.array, encoding: .utf8)!
    }

    /**
     * @param length in bits
     * @return byte array
     */
    public func readBytes(length: Int) throws -> Data {
        let bitString = try readBits(n: length)
        return bitString.toByteArray()
    }

    /**
     * @return hex string
     */
    public func toString() -> String {
        return toBitString()
    }

    /**
     * @return BitString from 0 to writeCursor
     */
    public func toBitString() -> String {
        var s = ""
        for i in 0..<writeCursor {
            let bit = getNValue(n: i) ? "1" : "0"
            s.append(bit)
        }
        return s
    }

    /**
     * @return BitString from current position to writeCursor
     */
    public func getBitString() -> String {
        var s = ""
        for i in readCursor..<writeCursor {
            let bit = getNValue(n: i) ? "1" : "0"
            s.append(bit)
        }
        return s
    }

    public func toByteArray() -> Data {
        return array
    }

    public func toBitArray() -> [Bool] {
        var result = [Bool]()
        for i in readCursor..<writeCursor {
            result[i] = getNValue(n: i)
        }
        return result
    }

    public func toZeroOneArray() -> [Int] {
        var result = [Int]()
        for i in readCursor..<writeCursor {
            result[i] = getNValue(n: i) ? 1 : 0;
        }
        return result
    }

    public func clone() -> BitString {
        let result = BitString(length: 0)
        result.array = array
        result.length = length
        result.writeCursor = writeCursor
        result.readCursor = readCursor
        return result
    }

    public func cloneFrom(from: Int) -> BitString {
        let result = BitString(length: 0)
        result.array = array[from..<array.count]
        result.length = length
        result.writeCursor = writeCursor - (from * 8)
        result.readCursor = readCursor
        return result;
    }

    public func cloneClear() -> BitString {
        let result = BitString(length: 0)
        result.array = array
        result.length = length
        result.writeCursor = 0
        result.readCursor = 0
        return result
    }

    /**
     * like Fift
     *
     * @return String
     */
    public func toHex() throws -> String {
        if writeCursor % 4 == 0 {
            let arr = array[0..<Int(ceil(Double(writeCursor)/Double(8)))]
            let s = arr.toHexString().uppercased()
            if writeCursor % 8 == 0 {
                return s
            } else {
                return String(s.dropLast(1))
            }
        } else {
            let temp = clone()
            try temp.writeBit(b: true)
            while (temp.writeCursor % 4 != 0) {
                try temp.writeBit(b:false)
            }
            return "\(try temp.toHex().uppercased())_"
        }
    }

    public func setTopUppedArray(arr: Data, fulfilledBytes: Bool) throws {
        length = arr.count * 8
        array = arr
        writeCursor = length

        if !(fulfilledBytes || (length == 0)) {
            var foundEndBit = false
            for _ in 0..<7 {
                writeCursor -= 1
                if getNValue(n: writeCursor) {
                    foundEndBit = true
                    try off(n: writeCursor)
                    break
                }
            }
            if !foundEndBit {
                throw TonError.otherError("Incorrect TopUppedArray")
            }
        }
    }

    public func getTopUppedArray() throws -> Data {
        let ret = clone()
        let ceilInt = Int(ceil(Double(ret.writeCursor)/Double(8)))
        var tu = ceilInt * 8 - ret.writeCursor
        if tu > 0 {
            tu = tu - 1;
            try ret.writeBit(b: true)
            while (tu > 0) {
                tu = tu - 1;
                try ret.writeBit(b: false)
            }
        }
        ret.array = ret.array[0..<Int(ceil(Double(ret.writeCursor)/Double(8)))]
        return ret.array
    }
}
