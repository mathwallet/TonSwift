//
//  Cell.swift
//  
//
//  Created by 薛跃杰 on 2023/1/3.
//

import Foundation
import CryptoSwift
import BigInt


public class Cell {
    static let reachBocMagicPrefix = Data(hex: "b5ee9c72")
    static let leanBocMagicPrefix = Data(hex: "68ff65f3")
    static let leanBocMagicPrefixCRC = Data(hex: "acc3a728")
    public var bits: BitString
    public var refs: [Cell?]
    public var refsInt: [Int64]
    public var isExotic: Bool
    public var readRefCursor: Int

    public init(cellSizeInBits: Int) {
        bits = BitString(length: cellSizeInBits)
        refs = [Self]()
        refsInt = [Int64]()
        isExotic = false
        readRefCursor = 0
    }
    
    public init(b: BitString, c: [Cell], r: Int) {
        bits = b.clone()
        refs = c
        refsInt = [Int64](repeating: Int64(0), count: r)
        isExotic = false
        readRefCursor = 0
    }
    
    public convenience init() {
        self.init(cellSizeInBits: 1023)
    }

//    public String toString() {
//        return bits.toBitString();
//    }

    public func toString() throws -> String {
        return try bits.toHex()
    }

    public func clone() -> Cell {
        let c = Cell(cellSizeInBits: 1023)
        c.bits = self.bits.clone()
        c.refs = self.refs
        c.isExotic = self.isExotic
        c.readRefCursor = self.readRefCursor
        c.refsInt = [Int64](repeating: Int64(0), count: self.refs.count)
        return c
    }

    /**
     * Loads bitString to Cell. Refs are not taken into account.
     *
     * @param hexBitString - bitString in hex
     * @return Cell
     */
    public static func fromHex(hexBitString: String) throws -> Cell {
        do {
            var _hexBitString = hexBitString
            let incomplete = hexBitString.hasSuffix("_")
            _hexBitString = _hexBitString.replacingOccurrences(of: "_", with: "")
            let b = Data(hex: hexBitString)

            let bs = BitString(length: hexBitString.count * 8)
            try bs.writeBytes(ui8s: b.bytes)

            var ba = bs.toBitArray()
            var i = ba.count - 1
            // drop last elements up to first `1`, if incomplete
            while (incomplete && !ba[i]) {
                ba.removeLast()
                i -= 1
            }
            // if incomplete, drop the 1 as well
            if (incomplete) {
                ba.removeLast()
            }
            let bss = BitString(length: ba.count)
            try bss.writeBitArray(ba: ba)

            let f = BitString(length: bss.toBitArray().count)
            try f.writeBitString(anotherBitString: bss)

            let c = TonSwift.Cell(cellSizeInBits: 1023)
            c.bits = f
            return c
        } catch (let e) {
            throw e
        }
    }

    /**
     * @param serializedBoc String in hex
     * @return List<Cell> root cells
     */
    public static func fromBoc(serializedBoc: String) throws -> Cell {
        return try deserializeBoc(serializedBoc: serializedBoc)
    }

    /**
     * @param serializedBoc Data
     * @return List<Cell> root cells
     */
    public static func fromBoc(serializedBoc: Data) throws -> Cell {
        return try deserializeBoc(serializedBoc: serializedBoc)
    }

    /**
     * Write another cell to self cell
     *
     * @param anotherCell Cell
     */
    public func writeCell(anotherCell: Cell) throws {
        // XXX we do not check that there are enough place in cell
        try bits.writeBitString(anotherBitString: anotherCell.bits)
        refs.append(contentsOf: anotherCell.refs)
    }

    public func getMaxRefs() -> Int {
        return 4
    }

    public func getFreeRefs() -> Int {
        return getMaxRefs() - refs.count
    }

    public func getUsedRefs() -> Int {
        return refs.count
    }

    func getMaxLevel() throws -> Int {
        //TODO level calculation differ for exotic cells
        var maxLevel: Int = 0
        for ref in refs {
            guard let _ref = ref, let refMaxLevel = try? _ref.getMaxLevel()  else {
                throw TonError.message("Cell refs error")
            }
            if (refMaxLevel > maxLevel) {
                maxLevel = refMaxLevel
            }
        }
        return maxLevel
    }

    func getMaxDepth() throws -> Int {
        var maxDepth: Int = 0
        if (!refs.isEmpty) {
            for ref in refs {
                guard let _ref = ref, let refMaxDepth = try? _ref.getMaxDepth() else {
                    throw TonError.message("Cell refs error")
                }
                if (refMaxDepth > maxDepth) {
                    maxDepth = refMaxDepth
                }
            }
            maxDepth += 1
        }
        return maxDepth
    }

    func getMaxDepthAsArray() throws -> Data {
        let maxDepth = try getMaxDepth()
        var d = [UInt8](repeating: UInt8(0), count: 2)
        d[1] = UInt8(maxDepth % 256)
        d[0] = UInt8(floor(Double(maxDepth) / Double(256)))
        return Data(d)
    }

    func isExplicitlyStoredHashes() -> Int {
        return 0
    }

    func getRefsDescriptor() throws -> Data {
        var d1 = [UInt8](repeating: UInt8(0), count: 1)
        let maxlevel = try getMaxLevel()
        d1[0] = UInt8((refs.count) + ((isExotic ? 1 : 0) * 8) + maxlevel * 32)
        return Data(d1)
    }

    func getBitsDescriptor() -> Data {
        var d2 = [UInt8](repeating: UInt8(0), count: 1)
        d2[0] = UInt8(ceil(Double(bits.writeCursor) / Double(8)) + floor(Double(bits.writeCursor) / Double(8)))
        return Data(d2)
    }

    func getDataWithDescriptors() throws -> Data {
        var d1 = try getRefsDescriptor()
        let d2 = getBitsDescriptor()
        let tuBits = try bits.getTopUppedArray()
        d1.append(d2)
        d1.append(tuBits)
        return d1
    }

    func getRepr() throws -> Data {
        var reprArray = try getDataWithDescriptors()
        
        for ref in refs {
            guard let _ref = ref else {
                throw TonError.message("Cell ref error")
            }
            reprArray.append(try _ref.getMaxDepthAsArray())
        }

        for ref in refs {
            guard let _ref = ref else {
                throw TonError.message("Cell ref error")
            }
            reprArray.append(try _ref.hash())
        }
        return reprArray
    }

    public func hash() throws -> Data {
        let repr = try getRepr()
        return repr.sha256()
    }

    /**
     * Recursively prints cell's content like Fift
     *
     * @return String
     */
    public func print(indent: String) throws -> String {
        var s = "\(indent)x{\(try bits.toHex())}\n"
        for ref in refs {
            guard let _ref = ref else {
                throw TonError.message("Cell ref error")
            }
            s = "\(s)\(try _ref.print(indent: "\(indent) "))"
        }
        return s
    }

    public func print() throws -> String {
        return try self.print(indent: "")
    }

    //serialized_boc#b5ee9c72 has_idx:(## 1) has_crc32c:(## 1)
    //  has_cache_bits:(## 1) flags:(## 2) { flags = 0 }
    //  size:(## 3) { size <= 4 }
    //  off_bytes:(## 8) { off_bytes <= 8 }
    //  cells:(##(size * 8))
    //  roots:(##(size * 8)) { roots >= 1 }
    //  absent:(##(size * 8)) { roots + absent <= cells }
    //  tot_cells_size:(##(off_bytes * 8))
    //  root_list:(roots * ##(size * 8))
    //  index:has_idx?(cells * ##(off_bytes * 8))
    //  cell_data:(tot_cells_size * [ uint8 ])
    //  crc32c:has_crc32c?uint32
    // = BagOfCells;

    /**
     * Convert Cell to BoC
     *
     * @param hasIdx       Bool, default true
     * @param hashCrc32    Bool, default true
     * @param hasCacheBits Bool, default false
     * @param flags        int, default 0
     * @return Data
     */
    public func toBoc(hasIdx: Bool, hashCrc32: Bool, hasCacheBits: Bool, flags: Int) throws -> Data {

        let rootCell = self

        let treeWalkResult = try rootCell.treeWalk()

        let topologicalOrder = treeWalkResult.topologicalOrderArray

        let cellsIndex: [String: UInt64] = treeWalkResult.indexHashmap

        let cellsNum = BigInt(topologicalOrder.count)

        let s = String(cellsNum, radix:2).count
        let sBytes = Int(min(ceil(Double(s) / Double(8)), 1))

        var fullSize = BigInt(0)
        var sizeIndex = [BigInt]()
        
        for cell_info in topologicalOrder {
            sizeIndex.append(fullSize)
            fullSize = fullSize + BigInt(try cell_info.cell.bocSerializationSize(cellsIndex: cellsIndex))
        }
        
        let offsetBits = String(fullSize, radix: 2).count
        let offsetBytes = UInt8(max(ceil(Double(offsetBits) / Double(8)), 1))
        
        let serialization = BitString(length: (1023 + 32 * 4 + 32 * 3) * topologicalOrder.count)
        try serialization.writeBytes(ui8s: Cell.reachBocMagicPrefix.bytes)
        try serialization.writeBitArray(ba: [hasIdx, hashCrc32, hasCacheBits])
        try serialization.writeUInt(number: BigInt(flags), bitLength: 2)
        try serialization.writeUInt(number: BigInt(sBytes), bitLength: 3)
        try serialization.writeUInt8(ui8: Int(offsetBytes) & 0xff)
        try serialization.writeUInt(number: cellsNum, bitLength: sBytes * 8)
        try serialization.writeUInt(number: BigInt(1), bitLength: sBytes * 8)
        try serialization.writeUInt(number: BigInt(0), bitLength: sBytes * 8)
        try serialization.writeUInt(number: BigInt(fullSize), bitLength: Int(offsetBytes) * 8)
        try serialization.writeUInt(number: BigInt(0), bitLength: sBytes * 8)

        if hasIdx {
            for i in 0..<topologicalOrder.count {
                try serialization.writeUInt(number: sizeIndex[i], bitLength: Int(offsetBytes) * 8)
            }
        }

        for cell_info in topologicalOrder {
            let refcell_ser = try cell_info.cell.serializeForBoc(cellsIndex: cellsIndex)
            try serialization.writeBytes(ui8s: refcell_ser.bytes)
        }

        var ser_arr = try serialization.getTopUppedArray()

        if (hashCrc32) {
            let crc32 = Utils.getCRC32ChecksumAsBytesReversed(data: ser_arr)
            ser_arr.append(crc32)
        }

        return ser_arr
    }


    public func toBoc(hasIdx: Bool, hashCrc32: Bool, hasCacheBits: Bool) throws -> Data {
        return try toBoc(hasIdx: hasIdx, hashCrc32: hashCrc32, hasCacheBits: hasCacheBits, flags: 0)
    }

    public func toBoc(hasIdx: Bool, hashCrc32: Bool) throws -> Data {
        return try toBoc(hasIdx: hasIdx, hashCrc32: hashCrc32, hasCacheBits: false, flags: 0)
    }

    public func toBoc(hasIdx: Bool) throws -> Data {
        return try toBoc(hasIdx: hasIdx, hashCrc32: true, hasCacheBits: false, flags: 0)
    }

    public func toBoc() throws -> Data {
        return try toBoc(hasIdx: true, hashCrc32: true, hasCacheBits: false, flags: 0)
    }

    public func toBocBase64() throws -> String {
        return try toBoc().bytes.toBase64()
    }

    public func toBocBase64(hasIdx: Bool) throws -> String {
        return try toBoc(hasIdx: hasIdx).bytes.toBase64()
    }

    public func toBocBase64(hasIdx: Bool, hashCrc32: Bool) throws -> String {
        return try toBoc(hasIdx: hasIdx, hashCrc32: hashCrc32).bytes.toBase64()
    }

    public func toBocBase64(hasIdx: Bool, hashCrc32: Bool, hasCacheBits: Bool) throws -> String {
        return try toBocBase64(hasIdx: hasIdx, hashCrc32: hashCrc32, hasCacheBits: hasCacheBits).bytes.toBase64()
    }

    /**
     * Convert Cell to BoC
     *
     * @param hasIdx       Bool, default true
     * @param hashCrc32    Bool, default true
     * @param hasCacheBits Bool, default false
     * @param flags        int, default 0
     * @return String in base64
     */
    public func toBocBase64(hasIdx: Bool, hashCrc32: Bool,hasCacheBits: Bool, flags: Int) throws -> String {
        return try toBoc(hasIdx: hasIdx, hashCrc32: hashCrc32, hasCacheBits: hasCacheBits, flags: flags).bytes.toBase64()
    }

    public func toHex(hasIdx: Bool, hashCrc32: Bool ,hasCacheBits: Bool, flags: Int) throws -> String {
        return try toBoc(hasIdx: hasIdx, hashCrc32: hashCrc32, hasCacheBits: hasCacheBits, flags: flags).toHexString()
    }


    public func toHex(hasIdx: Bool, hashCrc32: Bool ,hasCacheBits: Bool) throws -> String {
        return try toBoc(hasIdx: hasIdx, hashCrc32: hashCrc32, hasCacheBits: hasCacheBits, flags: 0).toHexString()
    }

    public func toHex(hasIdx: Bool) throws -> String {
        return try toBoc(hasIdx: hasIdx).toHexString()
    }

    public func toHex() throws -> String {
        return try toBoc().toHexString()
    }

    public func toBase64() throws -> String {
        return try toBoc().bytes.toBase64()
    }

    func serializeForBoc(cellsIndex: [String: UInt64]) throws -> Data {

        var reprArray = try getDataWithDescriptors()

        if (isExplicitlyStoredHashes() != 0) {
            throw TonError.message("Cell hashes explicit storing is not implemented")
        }
        for cell in refs {
            guard let _cell = cell, let hash = try? _cell.hash() else {
                throw TonError.message("Cell refs error")
            }
            let refIndexInt = BigInt(cellsIndex[hash.toHexString()]!)
            var refIndexHex = String(refIndexInt, radix: 16)
            if (refIndexHex.count % 2 != 0) {
                refIndexHex = "0\(refIndexInt)"
            }
            let reference = Data(hex: refIndexHex)
            reprArray.append(reference)
        }
        return reprArray
    }

    func bocSerializationSize(cellsIndex: [String: UInt64]) throws -> Int {
        return try serializeForBoc(cellsIndex: cellsIndex).count
    }

    func moveToTheEnd(indexHashmap: [String: UInt64], topologicalOrderArray: [TopologicalOrderArray], target: String) throws {
        let targetIndex = indexHashmap[target]
        var newIndexHashmap = indexHashmap
        for (key, value) in indexHashmap {
            if value > targetIndex! {
                newIndexHashmap[key] = value - 1
            }
        }
        newIndexHashmap[target] = UInt64(topologicalOrderArray.count) - 1
        
        var newTopologicalOrderArray = topologicalOrderArray
        let data = topologicalOrderArray[Int(targetIndex!)]
        newTopologicalOrderArray.remove(at: Int(targetIndex!))
        
        newTopologicalOrderArray.append(data)
        
        for ref in data.cell.refs {
            guard let _ref = ref, let hash = try? _ref.hash() else {
                throw TonError.message("Cell refs error")
            }
            try moveToTheEnd(indexHashmap: indexHashmap, topologicalOrderArray: topologicalOrderArray, target: hash.toHexString())
        }
    }

    /**
     * @return TreeWalkResult - topologicalOrderArray and indexHashmap
     */
    func treeWalk() throws -> TreeWalkResult {
        return try treeWalk(cell: self, topologicalOrderArray: [TopologicalOrderArray](), indexHashmap: [String : UInt64](), parentHash: "")
    }

    /**
     * @param cell                  Cell
     * @param topologicalOrderArray array of pairs: <Data cellHash, Cell Cell>
     * @param indexHashmap          cellHash: <String cellHash, Integer cellIndex>
     * @param parentHash            Uint8Array, default null, added neodiX
     * @return TreeWalkResult, topologicalOrderArray and indexHashmap
     */
    func treeWalk(cell: Cell, topologicalOrderArray: [TopologicalOrderArray], indexHashmap: [String: UInt64], parentHash: String) throws -> TreeWalkResult {
        let cellHash = try cell.hash().toHexString()
        if (indexHashmap.keys.contains(cellHash)) {
            //if (cellHash in indexHashmap){ // Duplication cell
            //it is possible that already seen cell is a child of more deep cell
            if (!parentHash.isEmpty) {
                if (indexHashmap[parentHash]! > indexHashmap[cellHash]!) {
                    try moveToTheEnd(indexHashmap: indexHashmap, topologicalOrderArray: topologicalOrderArray, target: cellHash)
                }
            }
            return TreeWalkResult(topologicalOrderArray: topologicalOrderArray, indexHashmap: indexHashmap)
        }
        var newIndexHashmap = indexHashmap
        newIndexHashmap[cellHash] = UInt64(topologicalOrderArray.count)
        var newTopologicalOrderArray = topologicalOrderArray
        newTopologicalOrderArray.append(TopologicalOrderArray(cellHash: try cell.hash(), cell: cell))

        for subCell in cell.refs {
            guard let _subCell = subCell else {
                throw TonError.message("Cell refs error")
            }
            let res = try treeWalk(cell: _subCell, topologicalOrderArray: topologicalOrderArray, indexHashmap: indexHashmap, parentHash: cellHash)
            newTopologicalOrderArray = res.topologicalOrderArray
            newIndexHashmap = res.indexHashmap
        }
        
        return TreeWalkResult(topologicalOrderArray: newTopologicalOrderArray, indexHashmap: newIndexHashmap)
    }

    public static func parseBocHeader(_ serializedBoc: Data) throws -> BocHeader {
        if serializedBoc.count < 5 {
            throw TonError.message("Not enough bytes for magic prefix")
        }
        let inputData = serializedBoc
        let prefix = serializedBoc[0..<4]
        let serializedBocs = serializedBoc
        var newSerializedBoc = serializedBocs[4..<serializedBoc.count]
        var has_idx: Int = 0
        var hash_crc32: Int = 0
        var has_cache_bits: Int = 0
        var flags: Int = 0
        var size_bytes: Int = 0
        if  Utils.compareBytes(a: prefix.bytes, b: Cell.reachBocMagicPrefix.bytes) {
            let flags_byte = Int(newSerializedBoc[0])
            has_idx = flags_byte & 128
            hash_crc32 = flags_byte & 64
            has_cache_bits = flags_byte & 32
            flags = (flags_byte & 16) * 2 + (flags_byte & 8)
            size_bytes = flags_byte % 8
        }
        
        if Utils.compareBytes(a: prefix.bytes, b: Cell.leanBocMagicPrefix.bytes) || Utils.compareBytes(a: prefix.bytes, b: self.leanBocMagicPrefixCRC.bytes) {
            has_idx = 1
            hash_crc32 = 0
            has_cache_bits = 0
            flags = 0
            size_bytes = Int(newSerializedBoc[0])
        }
        
        newSerializedBoc = newSerializedBoc[1..<newSerializedBoc.count]
        if newSerializedBoc.count < 1 + 5 * size_bytes {
            throw TonError.message("Not enough bytes for encoding cells counters")
        }
        let offset_bytes = Int(newSerializedBoc[0] & 0xff)
        
        newSerializedBoc = newSerializedBoc[1..<newSerializedBoc.count]
        let cells_num = Utils.readNBytesFromArray(count: size_bytes, ui8array: newSerializedBoc.bytes)
        newSerializedBoc = newSerializedBoc[size_bytes..<newSerializedBoc.count]
        let roots_num = Utils.readNBytesFromArray(count: size_bytes, ui8array: newSerializedBoc.bytes)
        newSerializedBoc = newSerializedBoc[size_bytes..<newSerializedBoc.count]
        let absent_num = Utils.readNBytesFromArray(count: size_bytes, ui8array: newSerializedBoc.bytes)
        newSerializedBoc = newSerializedBoc[size_bytes..<newSerializedBoc.count]
        let tot_cells_size = Utils.readNBytesFromArray(count: offset_bytes, ui8array: newSerializedBoc.bytes)
        
        if tot_cells_size < 0 {
            throw TonError.message("Cannot calculate total cell size")
        }
        newSerializedBoc = newSerializedBoc[size_bytes..<newSerializedBoc.count]
        
        
        
        if newSerializedBoc.count < roots_num * size_bytes {
            throw TonError.message("Not enough bytes for encoding root cells hashes")
        }
        var root_list = [Int]()
        
        for _ in 0 ..< Int(roots_num) {
            root_list.append(Utils.readNBytesFromArray(count: Int(size_bytes), ui8array: newSerializedBoc.bytes))
            newSerializedBoc = newSerializedBoc[size_bytes..<newSerializedBoc.count]
        }
        
        var index = [Int]()
        if has_idx != 0 {
            if newSerializedBoc.count < Int(offset_bytes) * cells_num {
                throw TonError.message("Not enough bytes for index encoding")
            }
            for _ in 0 ..< cells_num {
                index.append(Utils.readNBytesFromArray(count: Int(offset_bytes), ui8array: newSerializedBoc.bytes))
                newSerializedBoc = newSerializedBoc[Data.Index(offset_bytes)..<newSerializedBoc.count]
            }
        }
        
        if newSerializedBoc.count < tot_cells_size {
            throw TonError.message("Not enough bytes for cells data")
        }
        let cell_data = newSerializedBoc[0..<tot_cells_size]
        newSerializedBoc = newSerializedBoc[tot_cells_size..<newSerializedBoc.count]
        if hash_crc32 != 0 {
            if newSerializedBoc.count < 4 {
                throw TonError.message("Not enough bytes for crc32c hashsum")
            }
            let bocWithoutCrc = inputData[0..<inputData.count-4]
            let crcInBoc = newSerializedBoc[0..<4]
            let crc32 = Utils.getCRC32ChecksumAsBytesReversed(data: bocWithoutCrc)
            if !Utils.compareBytes(a: crc32.bytes, b: crcInBoc.bytes) {
                throw TonError.message("Crc32c hashsum mismatch")
            }
            newSerializedBoc = newSerializedBoc[4..<newSerializedBoc.count]
        }
        
        if serializedBoc.count != 0  {
            throw TonError.message("Too much bytes in BoC serialization")
        }
        let bocHeader = BocHeader(has_idx: has_idx,
                                  hash_crc32: hash_crc32,
                                  has_cache_bits: has_cache_bits,
                                  flags: flags,
                                  size_bytes: size_bytes,
                                  off_bytes: offset_bytes,
                                  cells_num: cells_num,
                                  roots_num: roots_num,
                                  absent_num: absent_num,
                                  tot_cells_size: tot_cells_size,
                                  root_list: root_list,
                                  index: index,
                                  cells_data: cell_data)
        
        return bocHeader
    }
    

    static func deserializeCellData(cellData: Data, referenceIndexSize: Int) throws -> DeserializeCellDataResult {
        if (cellData.count < 2) {
            throw TonError.message("Not enough bytes to encode cell descriptors");
        }
        let d1 = Int(cellData.bytes[0] & 0xff)
        let d2 = Int(cellData.bytes[1] & 0xff)
        var newCellData = cellData[2..<cellData.count]
        let isExotic = (d1 & 8) != 0
        let refNum = d1 % 8;
        let dataBytesize = Int(ceil(Double(d2) / Double(2)))
        let fullfilledBytes = ((d2 % 2) == 0)
        
        let cell = Cell()
        cell.isExotic = isExotic;
        if (newCellData.count < dataBytesize + referenceIndexSize * refNum) {
            throw TonError.message("Not enough bytes to encode cell data")
        }
        try cell.bits.setTopUppedArray(arr: newCellData[0..<dataBytesize], fulfilledBytes: fullfilledBytes)
        
        newCellData = newCellData[dataBytesize..<newCellData.count]
        
        for _ in 0..<refNum {
            cell.refsInt.append(Int64(Utils.readNBytesFromArray(count: referenceIndexSize, ui8array: newCellData.bytes)))
            cell.refs.append(nil)
            newCellData = newCellData[referenceIndexSize..<newCellData.count]
        }
        return DeserializeCellDataResult(cell: cell, cellsData: newCellData)
    }

    /**
     * @param serializedBoc String hex
     * @return List<Cell> root cells
     */
    private static func deserializeBoc(serializedBoc: String) throws -> Cell {
        return try deserializeBoc(serializedBoc: Data(hex: serializedBoc))
    }

    /**
     * @param serializedBoc Data bytearray
     * @return List<Cell> root cells
     */
    
    public static func deserializeBoc(serializedBoc: Data) throws -> Cell {
        let header = try parseBocHeader(serializedBoc)
        var cellsData = header.cells_data
        var cellsArray = [Cell]()
        
        for _ in 0 ..< header.cells_num {
            let dd = try deserializeCellData(cellData: cellsData, referenceIndexSize: header.size_bytes)
            cellsData = dd.cellsData
            cellsArray.append(dd.cell)
        }
        
        var ci = header.cells_num - 1
        while ci >= 0 {
            let c = cellsArray[ci]
            for ri in 0..<c.refsInt.count {
                let r = c.refsInt[ri]
                if (r < ci) {
                    throw TonError.message("Topological order is broken")
                }
                c.refs[ri] = cellsArray[Int(r)]
            }
            ci -= 1
        }

        var root_cells = [Cell]()
        for ri in header.root_list {
            root_cells.append(cellsArray[ri])
        }
        return root_cells[0]
    }
}
