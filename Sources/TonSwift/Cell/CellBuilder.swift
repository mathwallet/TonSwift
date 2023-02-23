//
//  CellBuilder.swift
//  
//
//  Created by xgblin on 2023/1/9.
//

import Foundation
import BigInt

public class CellBuilder: Cell {

    private init() {
        super.init(cellSizeInBits: 1023)
    }

    private override init(cellSizeInBits: Int) {
        super.init(cellSizeInBits: cellSizeInBits)
    }

    public static func beginCell() -> CellBuilder {
        return CellBuilder()
    }

    public static func beginCell(cellSize: Int) -> CellBuilder {
        return CellBuilder(cellSizeInBits: cellSize)
    }

    /**
     * Converts a builder into an ordinary cell.
     */
    public var endCell: CellBuilder {
        return self
    }

    public func storeBit(bit: Bool) throws -> CellBuilder {
        try checkBitsOverflow(length: 1)
        try bits.writeBit(b: bit)
        return self
    }

    public func storeBits(arrayBits: [Bool]) throws -> CellBuilder {
        try checkBitsOverflow(length: arrayBits.count)
        for bit in arrayBits {
            try bits.writeBit(b: bit)
        }
        return self
    }
//
//    public func storeBits(arrayBits: [Bool]) throws -> CellBuilder {
//        try checkBitsOverflow(length: arrayBits.length);
//        bits.writeBitArray(ba: arrayBits);
//        return self
//    }

    public func storeUint(number: Int64, bitLength: Int) throws -> CellBuilder {
        return try storeUint(number: BigInt(number), bitLength: bitLength)
    }

    public func storeUint(number: Int, bitLength: Int) throws -> CellBuilder {
        return try storeUint(number: BigInt(number), bitLength: bitLength)
    }

    public func storeUint(number: UInt8, bitLength: Int) throws -> CellBuilder {
        return try storeUint(number: BigInt(number), bitLength: bitLength)
    }

    public func storeUint(number: String, bitLength: Int) throws -> CellBuilder {
        return try storeUint(number: BigInt(number) ?? BigInt(0), bitLength: bitLength)
    }

    @discardableResult
    public func storeUint(number: BigInt, bitLength: Int) throws -> CellBuilder {
        try checkBitsOverflow(length: bitLength)
        try checkSign(i: number)
        try bits.writeUInt(number: number, bitLength: bitLength)
        return self
    }

    public func storeInt(number: Int64, bitLength: Int) throws -> CellBuilder {
        return try storeInt(number: BigInt(number), bitLength: bitLength)
    }

    public func storeInt(number: Int, bitLength: Int) throws -> CellBuilder {
        return try storeInt(number: BigInt(number), bitLength: bitLength)
    }


    public func storeInt(number: UInt8, bitLength: Int) throws -> CellBuilder {
        return try storeInt(number: BigInt(number), bitLength: bitLength)
    }

    public func storeInt(number: BigInt, bitLength: Int) throws -> CellBuilder {
        let int = 1 << bitLength - 1
        let sint = BigInt(int)
        if (number >= (BigInt(0) - sint)) && number < sint {
            try! bits.writeInt(number: number, bitLength: bitLength)
            return self
        } else {
            throw TonError.otherError("Can't store an Int, because its value allocates more space than provided.")
        }
//        if ((number.compareTo(sint.negate()) >= 0) && (number.compareTo(sint) < 0)) {
//            bits.writeInt(number, bitLength);
//            return this;
//        } else {
//            throw TonError.otherError("Can't store an Int, because its value allocates more space than provided.");
//        }
    }

    public func storeBitString(bitString: BitString) throws -> CellBuilder {
        try checkBitsOverflow(length: bitString.getUsedBits())
        try bits.writeBitString(anotherBitString: bitString)
//        bits.writeBitStringFromRead(bitString);
        return self
    }

    public func storeString(str: String) throws -> CellBuilder {
        try checkBitsOverflow(length: str.count * 8);
        try bits.writeString(value: str)
        return self
    }

    public func storeAddress(address: Address?) throws -> CellBuilder {
        try checkBitsOverflow(length: 267)
        try bits.writeAddress(address: address)
        return self
    }

    public func storeBytes(number: Data) throws -> CellBuilder {
        try checkBitsOverflow(length: number.count * 8)
        try bits.writeBytes(ui8s: number.bytes)
        return self
    }

    public func storeBytes(bytes: [UInt8]) throws -> CellBuilder {
        try checkBitsOverflow(length: bytes.count * 8)
        for byte in bytes {
            try bits.writeUInt8(ui8: Int(byte))
        }
        return self
    }

    public func storeBytes(number: Data, bitLength: Int) throws -> CellBuilder {
        try checkBitsOverflow(length: bitLength)
        try bits.writeBytes(ui8s: number.bytes)
        return self
    }


    public func storeRef(c: Cell) throws -> CellBuilder {
        try checkRefsOverflow(count: 1)
        refs.append(c)
        return self
    }

    public func storeRefs(cells: [Cell]) throws -> CellBuilder {
        try checkRefsOverflow(count: cells.count)
        refs.append(contentsOf: cells)
        return self
    }

//    public func storeRefs(Cell... cells) throws -> CellBuilder {
//        checkRefsOverflow(cells.length);
//        refs.addAll(Arrays.asList(cells));
//        return this;
//    }

    public func storeSlice(cellSlice: CellSlice) throws -> CellBuilder {
        try checkBitsOverflow(length: cellSlice.bits.getUsedBits())
        try checkRefsOverflow(count: cellSlice.refs.count)

        let cellS = try storeBitString(bitString: cellSlice.bits)

        refs.append(contentsOf: cellS.refs)
        return self
    }

    public func storeDict(dict: Cell) throws -> CellBuilder {
        let cellSlice = try storeSlice(cellSlice: CellSlice.beginParse(cell: dict))
        return cellSlice
    }

    /**
     * Stores up to 2^120-1 nano-coins in Cell
     *
     * @param coins amount in nano-coins
     * @return CellBuilder
     */
    public func storeCoins(coins: BigInt) throws -> CellBuilder {
        try bits.writeCoins(amount: coins)
        return self
    }

    public func getUsedBits() -> Int {
        return bits.getUsedBits()
    }

    public func getFreeBits() -> Int {
        return bits.getFreeBits()
    }

    func checkBitsOverflow(length: Int) throws {
        if (length > bits.getFreeBits()) {
            throw TonError.otherError("Bits overflow. Can't add \(length) bits. \(bits.getFreeBits()) bits left.")
        }
    }

    func checkSign(i: BigInt) throws {
        if (i.signum() < 0) {
            throw TonError.otherError("Integer \(i) must be unsigned")
        }
    }

    func checkRefsOverflow(count: Int) throws {
        if (count > (4 - refs.count)) {
            throw TonError.otherError("Refs overflow. Can't add \(count) refs. \(4 - refs.count) refs left.")
        }
    }
}
