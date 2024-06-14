import Foundation
import BigInt

/// `Slice` is a class that allows to read cell data (bits and refs), consuming it along the way.
/// Once you have done reading and want to make sure all the data is consumed, call `endParse()`.
public class ConnectSlice {

    private var bitstring: ConnectBitstring
    private var offset: Int
    private var refs: [ConnectCell]
    

    
    // MARK: - Initializers
        
    init(cell: ConnectCell) {
        bitstring = cell.bits
        offset = 0
        refs = cell.refs
    }

    /// Allows initializing with ConnectBitstring
    public init(bits: ConnectBitstring) {
        self.bitstring = bits
        self.offset = 0
        self.refs = []
    }
    
    /// Initializes ConnectSlice with a byte buffer to read the bits from.
    /// This does not parse bag-of-cells. To parse BoC, see `ConnectCell` API instead.
    public init(data: Data) {
        self.bitstring = ConnectBitstring(data: data)
        self.offset = 0
        self.refs = []
    }
    
    /// Unchecked initializer for cloning
    private init(bitstring: ConnectBitstring, offset: Int, refs: [ConnectCell]) {
        self.bitstring = bitstring
        self.offset = offset
        self.refs = refs
    }
    
    
    
    // MARK: - Metrics
    
        
    /// Remaining unread refs in this ConnectSlice.
    public var remainingRefs: Int {
        return refs.count
    }
    
    /// Remaining unread bits in this ConnectSlice.
    public var remainingBits: Int {
        return bitstring.length - offset
    }
    
    
    
    
    // MARK: - Finalization
    
    
    /// Checks if the ConnectCell is fully processed without unread bits or refs.
    public func endParse() throws {
        if remainingBits > 0 || remainingRefs > 0 {
            throw TonError.otherError("ConnectSlice is not empty")
        }
    }

    /// Converts the remaining data in the ConnectSlice to a ConnectCell.
    /// This is the same as `asConnectCell`, but reads better when you intend to read all the remaining data as a ConnectCell.
    public func loadRemainder() throws -> ConnectCell {
        return try toBuilder().endCell()
    }
    
    /// Converts the remaining data in the ConnectSlice to a ConnectCell.
    /// This is the same as `loadRemainder`, but reads better when you intend to serialize/inspect the ConnectSlice.
    public func toCell() throws -> ConnectCell {
        return try toBuilder().endCell()
    }
    
    /// Converts ConnectSlice to a ConnectBuilder filled with remaining data in this ConnectSlice.
    public func toBuilder() throws -> ConnectBuilder {
        let builder = ConnectBuilder()
        try builder.store(slice: self)
        return builder
    }
    
    /// Clones slice at its current state.
    public func clone() -> ConnectSlice {
        return ConnectSlice(bitstring: bitstring, offset: offset, refs: refs)
    }
    
    /// Returns string representation of the ConnectSlice as a ConnectCell.
    public func toString() throws -> String {
        return try loadRemainder().toString()
    }
    
    
    
    
    
    // MARK: - Loading Generic Types

    /// Loads type T that implements interface Readable
    public func loadType<T: CellCodable>() throws -> T {
        return try T.loadFrom(slice: self)
    }
    
    /// Preloads type T that implements interface Readable
    public func preloadType<T: CellCodable>() throws -> T {
        return try T.loadFrom(slice: self.clone())
    }
    
    /// Loads optional type T via closure. Function reads one bit that indicates the presence of data. If the bit is set, the closure is called to read T.
    public func loadMaybe<T>(_ closure: (ConnectSlice) throws -> T) throws -> T? {
        if try loadBoolean() {
            return try closure(self)
        } else {
            return nil
        }
    }
    
    /// Lets you attempt to read a complex data type.
    /// If parsing succeeded, the ConnectSlice is advanced.
    /// If parsing failed, the ConnectSlice remains unchanged.
    public func tryLoad<T>(_ closure: (ConnectSlice) throws -> T) throws -> T {
        let tmpslice = self.clone();
        let result = try closure(tmpslice);
        self.bitstring = tmpslice.bitstring;
        self.offset = tmpslice.offset;
        self.refs = tmpslice.refs;
        return result;
    }
    
    
    
    // MARK: - Loading Refs
    
    /// Loads a cell reference.
    public func loadRef() throws -> ConnectCell {
        if refs.isEmpty {
            throw TonError.otherError("No more references")
        }
        return refs.removeFirst()
    }
    
    /// Preloads a reference without advancing the cursor.
    public func preloadRef() throws -> ConnectCell {
        if refs.isEmpty {
            throw TonError.otherError("No more references")
        }
        return refs.first!
    }
    
    /// Loads an optional cell reference.
    public func loadMaybeRef() throws -> ConnectCell? {
        if try loadBoolean() {
            return try loadRef()
        } else {
            return nil
        }
    }
    
    /// Preloads an optional cell reference.
    public func preloadMaybeRef() throws -> ConnectCell? {
        if try preloadBit() == 1 {
            return try preloadRef()
        } else {
            return nil
        }
    }
    
    
    
    // MARK: - Loading Dictionaries
    
    
    /// Reads a dictionary from the slice.
    public func loadDict<T>() throws -> T where T: CellCodableDictionary {
        return try T.loadFrom(slice: self)
    }

    /// Reads the non-empty dictionary root directly from this slice.
    public func loadDictRoot<T>() throws -> T where T: CellCodableDictionary {
        return try T.loadRootFrom(slice: self)
    }

    
    
    
    // MARK: - Loading Bits
    
    
    /// Advances cursor by the specified numbe rof bits.
    public func skip(_ bits: Int) throws {
        if bits < 0 || offset + bits > bitstring.length {
            throw TonError.otherError("Index \(offset + bits) is out of bounds")
        }
        offset += bits
    }

    /// Load a single bit.
    public func loadBit() throws -> Bit {
        let r = try bitstring.at(offset)
        offset += 1
        return r
    }
    
    /// Load a single bit as a boolean value.
    public func loadBoolean() throws -> Bool {
        return try loadBit() == 1
    }
    
    /// Loads an optional boolean.
    public func loadMaybeBoolean() throws -> Bool? {
        if try loadBoolean() {
            return try loadBoolean()
        } else {
            return nil
        }
    }

    /// Preload a single bit without advancing the cursor.
    public func preloadBit() throws -> Bit {
        return try bitstring.at(offset)
    }

    /// Loads the specified number of bits in a `ConnectBitstring`.
    public func loadBits(_ bits: Int) throws -> ConnectBitstring {
        let r = try bitstring.substring(offset: offset, length: bits)
        offset += bits
        return r
    }

    /// Preloads the specified number of bits in a `ConnectBitstring` without advancing the cursor.
    public func preloadBits(_ bits: Int) throws -> ConnectBitstring {
        return try bitstring.substring(offset: offset, length: bits)
    }

    /// Loads whole number of bytes and returns standard `Data` object.
    public func loadBytes(_ bytes: Int) throws -> Data {
        let buf = try _preloadBuffer(bytes: bytes)
        offset += bytes * 8
        
        return buf
    }

    /// Preloads whole number of bytes and returns standard `Data` object without advancing the cursor.
    public func preloadBytes(_ bytes: Int) throws -> Data {
        return try _preloadBuffer(bytes: bytes)
    }

    

    /**
     Load bit string that was padded to make it byte alligned. Used in BOC serialization
    - parameter bytes: number of bytes to read
    */
    func loadPaddedBits(bits: Int) throws -> ConnectBitstring {
        // Check that number of bits is byte alligned
        guard bits % 8 == 0 else {
            throw TonError.otherError("Invalid number of bits")
        }
        
        // Skip padding
        var length = bits
        while true {
            if try bitstring.at(offset + length - 1) == 1 {
                length -= 1
                break
            } else {
                length -= 1
            }
        }
        
        // Read substring
        let substring = try bitstring.substring(offset: offset, length: length)
        offset += bits
        
        return substring
    }

    
    
    
    // MARK: - Loading Integers
    
    
    /**
     Load uint value
    - parameter bits: uint bits
    - returns read value as number
    */
    public func loadUint(bits: Int) throws -> UInt64 {
        return UInt64(try loadUintBig(bits: bits))
    }
    
    /**
     Load uint value as bigint
    - parameter bits: uint bits
    - returns read value as bigint
    */
    public func loadUintBig(bits: Int) throws  -> BigUInt {
        let loaded = try preloadUintBig(bits: bits)
        offset += bits
        
        return loaded
    }
    
    /**
     Load int value
    - parameter bits: int bits
    - returns read value as bigint
    */
    public func loadInt(bits: Int) throws -> Int {
        let loaded = try _preloadInt(bits: bits, offset: offset)
        offset += bits
        
        return Int(loaded)
    }
    
    /**
     Load int value as bigint
    - parameter bits: int bits
    - returns read value as bigint
    */
    public func loadIntBig(bits: Int) throws -> BigInt {
        let loaded = try _preloadBigInt(bits: bits, offset: offset)
        offset += bits
        
        return loaded
    }

    /**
     Preload uint value
    - parameter bits: uint bits
    - returns read value as number
    */
    public func preloadUint(bits: Int) throws -> UInt64 {
        return try _preloadUint(bits: bits, offset: offset)
    }

    /**
     Preload uint value as bigint
    - parameter bits: uint bits
    - returns read value as bigint
    */
    public func preloadUintBig(bits: Int) throws -> BigUInt {
        return try _preloadBigUint(bits: bits, offset: offset)
    }
    
    /**
     Load maybe uint
    - parameter bits number of bits to read
    - returns uint value or null
     */
    public func loadMaybeUint(bits: Int) throws -> UInt64? {
        if try loadBoolean() {
            return try loadUint(bits: bits)
        } else {
            return nil
        }
    }
    
    /**
     Load maybe uint
    - parameter bits number of bits to read
    - returns uint value or null
     */
    public func loadMaybeUintBig(bits: Int) throws -> BigUInt? {
        if try loadBoolean() {
            return try loadUintBig(bits: bits)
        } else {
            return nil
        }
    }

    
    
    
    
    // MARK: - Loading Variable-Length Integers
    
    
    /// Loads VarUInteger with a given `limit` in bytes.
    /// The integer must be at most `limit-1` bytes long.
    /// Therefore, `(VarUInteger 16)` accepts 120-bit number (15 bytes) and uses 4 bits to encode length prefix 0...15.
    func loadVarUint(limit: Int) throws -> UInt64 {
        if limit > 9 {
            throw TonError.otherError("VarUInteger \(limit) cannot store UInt64 (it occupies 8 bytes, so the largest type is VarUInteger 9)")
        }
        return try UInt64(self.loadVarUintBig(limit: limit))
    }

    /// Loads VarUInteger with a given `limit` in bytes.
    /// The integer must be at most `limit-1` bytes long.
    /// Therefore, `(VarUInteger 16)` accepts 120-bit number (15 bytes) and uses 4 bits to encode length prefix 0...15.
    func loadVarUintBig(limit: Int) throws -> BigUInt {
        let bytesize = limit - 1
        let prefixbits = bitsForInt(bytesize)
        let size = Int(try loadUint(bits: prefixbits))
        if size > bytesize {
            throw TonError.otherError("bytesize error")
        }
        return try loadUintBig(bits: size * 8)
    }

    

    
    
    
    
    
    // MARK: - Private methods
    
    /**
     Preload int from specific offset
    - parameter bits: bits to preload
    - parameter offset: offset to start from
    - returns read value as bigint
    */
    private func _preloadBigInt(bits: Int, offset: Int) throws -> BigInt {
        if bits == 0 {
            return 0
        }
        
        let sign = try bitstring.at(offset)
        var res = BigInt(0)
        for i in 0..<bits - 1 {
            if try bitstring.at(offset + 1 + i) == 1 {
                res += BigInt(1) << BigInt(bits - i - 1 - 1)
            }
        }
        
        if sign == 1 {
            res = res - (BigInt(1) << BigInt(bits - 1))
        }
        
        return res
    }

    private func _preloadBigUint(bits: Int, offset: Int) throws -> BigUInt {
        guard bits != 0 else { return 0 }
        
        var res = BigUInt(0)
        for i in 0..<bits {
            if try bitstring.at(offset + i) == 1 {
                res += 1 << BigUInt(bits - i - 1)
            }
        }
        
        return res
    }
    
    private func _preloadInt(bits: Int, offset: Int) throws -> Int64 {
        guard bits != 0 else { return 0 }
        
        let sign = try bitstring.at(offset)
        var res = Int64(0)
        for i in 0..<bits - 1 {
            if try bitstring.at(offset + 1 + i) == 1 {
                res += 1 << Int64(bits - i - 1 - 1)
            }
        }
        
        if sign == 1 {
            res = res - (1 << Int64(bits - 1))
        }
        
        return res
    }
    
    private func _preloadUint(bits: Int, offset: Int) throws -> UInt64 {
        guard bits != 0 else { return 0 }
        
        var res = UInt64(0)
        for i in 0..<bits {
            if try bitstring.at(offset + i) == 1 {
                res += 1 << UInt64(bits - i - 1)
            }
        }
        
        return res
    }

    private func _preloadBuffer(bytes: Int) throws -> Data {
        if let fastBuffer = try bitstring.subbuffer(offset: offset, length: bytes * 8) {
            return fastBuffer
        }
        
        var buf = Data(count: bytes)
        for i in 0..<bytes {
            buf[i] = UInt8(try _preloadUint(bits: 8, offset: offset + i * 8))
        }
        
        return buf
    }
}
