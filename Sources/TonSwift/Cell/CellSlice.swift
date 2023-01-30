//
//  CellSlice.swift
//  
//
//  Created by 薛跃杰 on 2023/1/9.
//

import Foundation
import BigInt

public class CellSlice {

    var bits: BitString
    var refs: [Cell]

    private init() {
        bits = BitString(length: 0)
        refs = [Cell]()
    }

    private init(bits: BitString, refs: [Cell]) {
        self.bits = bits.clone()
        self.refs = refs
    }

    public static func beginParse(cell: Cell) -> CellSlice {
        return CellSlice(bits: cell.bits, refs: cell.refs.map{ $0! })
    }


    public func clone() -> CellSlice {
        return CellSlice(bits: self.bits, refs: self.refs)
    }

    public func sliceToCell() -> Cell {
        return Cell(b: bits, c: refs, r: refs.count)
    }

    public func endParse() throws {
        if (bits.readCursor != bits.getUsedBits()) {
            throw TonError.message("readCursor: \(bits.readCursor) != bits.length: \(bits.getUsedBits())")
        }
    }

    public func loadRefX() throws -> Cell {
        return try loadRef()
    }

    public func loadMaybeX() throws -> Cell? {
        let maybe = try loadBit()
        if (!maybe) {
            return nil
        }
        return Cell(b: bits, c: refs, r: refs.count)
    }

    public func loadMaybeRefX() throws -> Cell? { // test, loadMaybeRefX(slice, parser) {
        let maybe = try loadBit()
        if (!maybe) {
            return nil
        }
        return try loadRefX()
    }

    public func loadEither() -> Cell { // test, loadEither(slice, parser_x, parser_y) {
        return Cell(b: bits, c: refs, r: refs.count)
//        if (loadBit()) {
//            return Cell(b: bits, c: refs, r: refs.count) // parser_x
//        } else {
//            return Cell(b: bits, c: refs, r: refs.count) //parser_y
//        }
    }

    public func loadEitherXorRefX() throws -> Cell {
        if (try loadBit()) {
            return Cell(b: bits, c: refs, r: refs.count)
        } else {
            return try loadRefX()
        }
    }

    public func loadUnary() throws -> Int {
        let pfx = try loadBit()
        if (!pfx) {
            // unary_zero
            return 0
        } else {
            // unary_succ
            let x = try loadUnary()
            return x + 1
        }
    }

    /**
     * Check whether slice was read to the end
     */
    public func isSliceEmpty() -> Bool {
        return bits.readCursor == bits.writeCursor;
    }

    public func loadRefs(count: Int) throws -> [Cell] {
        var result = [Cell]()
        for _ in 0..<count {
            let cell = try loadRef()
            result.append(cell)
        }
        return result
    }

    /**
     * Loads the first reference from the slice.
     */
    public func loadRef() throws -> Cell {

        try checkRefsOverflow()
        let cell = refs[0]
        refs.remove(at: 0)
        return cell
    }

    public func skipRefs(length: Int) -> CellSlice {
        if (length > 0) {
            refs.removeSubrange(0..<length)
//            subList(0, length).clear()
        }
        return self
    }

    /**
     * Loads the reference from the slice at current position without moving refs cursor
     */
    public func preloadRef() throws -> Cell {
        try checkRefsOverflow()
        return refs[0]
    }

    public func preloadRefs(count: Int) -> [Cell] {
        var result = [Cell]()
        for i in 0..<count {
            result.append(refs[i])
        }
        return result
    }

//    public TonHashMap loadDict(int n, Function<BitString, Object> keyParser, Function<Cell, Object> valueParser) -> TonHashMap {
//        TonHashMap x = new TonHashMap(n);
//        x.deserialize(this, keyParser, valueParser);
//        /*
//        Cell c = this.sliceToCell();
//        x.loadHashMapX2Y(c, keyParser, valueParser);
//
//        bits = c.bits;
//        refs = c.refs;
//        */
//        // move readRefCursor
//        refs.remove(0);
//        refs.remove(0);
////        for (int i = 0; i < this.bits.readref; i++) {
////            refs.remove(0);
////        }
//
//        return x;
//    }

//    public TonHashMapE loadDictE(int n, Function<BitString, Object> keyParser, Function<Cell, Object> valueParser) {
//        boolean isEmpty = !this.loadBit();
//        if (isEmpty) {
//            return new TonHashMapE(n);
//        } else {
//            TonHashMapE hashMap = new TonHashMapE(n);
//            hashMap.deserialize(CellSlice.beginParse(this.loadRef()), keyParser, valueParser);
//            return hashMap;
//        }
//    }
//
//    public TonPfxHashMap loadDictPfx(int n, Function<BitString, Object> keyParser, Function<Cell, Object> valueParser) {
//        TonPfxHashMap x = new TonPfxHashMap(n);
//        x.deserialize(this, keyParser, valueParser);
//        return x;
//    }
//
//
//    public TonPfxHashMapE loadDictPfxE(int n, Function<BitString, Object> keyParser, Function<Cell, Object> valueParser) {
//        boolean isEmpty = !this.loadBit();
//        if (isEmpty) {
//            return new TonPfxHashMapE(n);
//        } else {
//            TonPfxHashMapE hashMap = new TonPfxHashMapE(n);
//            hashMap.deserialize(CellSlice.beginParse(this.loadRef()), keyParser, valueParser);
//            return hashMap;
//        }
//    }

    /**
     * Preloads dict (HashMap) without modifying the actual cell slice.
     *
     * @param n           - dict key size
     * @param keyParser   - key deserializor
     * @param valueParser - value deserializor
     * @return TonHashMap - dict
     */
//    public TonHashMap preloadDict(int n, Function<BitString, Object> keyParser, Function<Cell, Object> valueParser) {
//        TonHashMap x = new TonHashMap(n);
//        x.deserialize(this.clone(), keyParser, valueParser);
//        return x;
//    }

    /**
     * Preloads dict (HashMapE) without modifying the actual cell slice.
     *
     * @param n           - dict key size
     * @param keyParser   - key deserializor
     * @param valueParser - value deserializor
     * @return TonHashMap - dict
     */
//    public TonHashMap preloadDictE(int n, Function<BitString, Object> keyParser, Function<Cell, Object> valueParser) {
//        boolean isEmpty = !this.preloadBit();
//        if (isEmpty) {
//            return new TonHashMap(n);
//        } else {
//            TonHashMap x = new TonHashMap(n);
//            CellSlice cs = this.clone();
//            cs.skipBit();
////            Cell c = this.sliceToCell();
////            c.loadBit();
////            Cell dict = c.readRef();
////            skipBit();
//            x.deserialize(CellSlice.beginParse(cs.loadRef()), keyParser, valueParser);
//            return x;
//        }
//    }

//    public TonHashMapE loadDictE(int n, Function<Cell, Object> keyParser, Function<Cell, Object> valueParser) {
//
//        TonHashMapE hashMap = new TonHashMapE(n);
//        Cell c = this.loadRef();
//        hashMap.loadHashMapX2Y(c, keyParser, valueParser);
//        return hashMap;
//    }

//    public func skipDictE() -> CellSlice {
//        let isEmpty = loadBit()
//        return isEmpty ? skipRefs(length: 1) : self
//    }
//
//    /**
//     * TODO - skip without traversing the actual hashmap
//     */
//    public func skipDict(dictKeySize: Int) -> CellSlice {
//        loadDict(dictKeySize,
//                k -> CellBuilder.beginCell().endCell(),
//                v -> CellBuilder.beginCell().endCell())
//        return self
//    }

    public func loadBit() throws -> Bool {
        try checkBitsOverflow(length: 1)
        return bits.readBit()
    }

    public func preloadBit() throws -> Bool {
        try checkBitsOverflow(length: 1)
        return bits.prereadBit();
    }

    public func skipBits(length: Int) throws -> CellSlice {
        try checkBitsOverflow(length: length)
        bits.readCursor += length
        return self
    }

    public func skipBit() throws -> CellSlice {
        try checkBitsOverflow(length: 1)
        bits.readCursor += 1
        return self
    }

    public func skipUint(length: Int) throws -> CellSlice {
        return try skipBits(length: length)
    }

    public func skipInt(length: Int) throws -> CellSlice{
        return try skipBits(length: length)
    }

    /**
     * @param length in bits
     * @return byte array
     */
    public func loadBytes(length: Int) throws -> Data {
        try checkBitsOverflow(length: length)
        let bitString = try bits.readBits(n: length)
        return bitString.toByteArray()
    }

    public func loadString(length: Int) throws -> String {
        try checkBitsOverflow(length: length)
        let bitString = try bits.readBits(n: length)
        guard let string = String(data: bitString.toByteArray(), encoding: .utf8) else {
            throw TonError.message("bits error")
        }
        return string
    }

    public func loadBits(length: Int) throws -> BitString {
        try checkBitsOverflow(length: length)
        return try bits.readBits(n: length)
    }

    public func preloadBits(length: Int) throws -> BitString {
        try checkBitsOverflow(length: length)
        let n = bits.toBitArray()[bits.readCursor..<bits.readCursor + length]
        //        Arrays.copyOfRange(bits.toBitArray(), bits.readCursor, bits.readCursor + length);
        let result = BitString(length: length)
        for b in n{
            try result.writeBit(b: b)
        }
        return result
    }

    public func loadInt(length: Int) throws -> BigInt {
        return try bits.readInt(bitLength: length)
    }

    public func loadUint(length: Int) throws -> BigInt {
        try checkBitsOverflow(length: length)
        if length == 0  {
            return BigInt(0)
        }
        let i = try loadBits(length: length)
        guard let int = BigInt(i.toBitString(), radix: 2) else {
            throw TonError.message("length loadUint error")
        }
        return int
    }

    public func preloadInt(bitLength: Int) throws -> BigInt {
        let savedBits = bits.clone()
        do {
            let result = try loadInt(length: bitLength)
            bits = savedBits
            return result
        } catch let e {
            bits = savedBits
            throw e
        }
    }

    public func preloadUint(bitLength: Int) throws -> BigInt {
        let savedBits = bits.clone()
        do {
            let result = try loadUint(length: bitLength)
            bits = savedBits
            return result
        } catch let e {
            bits = savedBits
            throw e
        }
    }

    public func loadUintLEQ(n: BigInt) throws -> BigInt {
        let result = try loadUint(length: n.bitWidth)
        if (result > n) {
            throw TonError.message("Cannot load {<= x}: encoded number is too high");
        }
        return result
    }

    /**
     * Loads unsigned integer less than n by reading minimal number of bits encoding n-1
     * <p>
     * #<= p
     */
    public func loadUintLess(n: BigInt) throws -> BigInt {
        return try loadUintLEQ(n: (n - BigInt(1)))
    }

    /**
     * Loads VarUInteger
     * <p>
     * var_uint$_ {n:#} len:(#< n) value:(uint (len * 8)) = VarUInteger n;
     */
    public func loadVarUInteger(n: BigInt) throws -> BigInt {
        let len = try loadUintLess(n: n)
        if (len == BigInt(0)) {
            return BigInt(0)
        } else {
            let length = len * BigInt(8)
            return try loadUint(length: Int(length.description) ?? 0)
        }
    }

    /**
     * Loads coins amount
     * <p>
     * nanograms$_ amount:(VarUInteger 16) = Grams;
     */
    public func loadCoins() throws -> BigInt {
        return try loadVarUInteger(n: BigInt(16))
    }

    public func preloadCoins() throws -> BigInt {
        let savedBits = bits.clone()
        do {
            let result = try loadVarUInteger(n: BigInt(16))
            bits = savedBits
            return result
        } catch let e {
            bits = savedBits
            throw e
        }
    }

    public func skipCoins() throws -> BigInt {
        return try loadVarUInteger(n: BigInt(16))
    }

    func checkBitsOverflow(length: Int) throws {
        if (bits.readCursor + length > bits.writeCursor) {
            throw TonError.message("Bits overflow. Can't load \(length)  bits. \(bits.getFreeBits())  bits left.")
        }
    }

    func checkRefsOverflow() throws {
        if (refs.isEmpty) {
            throw TonError.message("Refs overflow.")
        }
    }

    public func toString() -> String {
        return bits.toBitString()
    }

    public func loadAddress() throws -> Address? {
        let i = try preloadUint(bitLength: 2)
        if (i == 0) {
            let _ = try skipBits(length: 2)
            return nil
        }
        let _ = try loadBits(length: 2)
        let _ = try loadBits(length: 1)
        let workchain = try loadInt(length: 8)
        let hashPart = try loadUint(length: 256)
        let hashPartString = String(hashPart, radix: 16).replacingOccurrences(of: " ", with: "0")
        let address = "\(workchain):\(hashPartString)"
        return try Address.of(addressStr: address)
    }
}
