import Foundation
import CryptoSwift

public struct ConnectAddress: Hashable, Codable {
    public let workchain: Int8
    public let hash: Data
    
    /// Initializes address from raw components.
    public init(workchain: Int8, hash: Data) {
        self.workchain = workchain
        self.hash = hash
    }
    
    /// Generates a test address
    public static func mock(workchain: Int8, seed: String) -> Self {
        return ConnectAddress(workchain: workchain, hash: Data(seed.utf8).sha256())
    }

    /// Parses address from any format
    public static func parse(_ source: String) throws -> ConnectAddress {
        if source.firstIndex(of: ":") == nil {
            return try FriendlyAddress(string: source).address
        } else {
            return try parse(raw: source)
        }
    }
    
    /// Initializes address from the raw format `<workchain>:<hash>` (decimal workchain, hex-encoded hash part)
    public static func parse(raw: String) throws -> ConnectAddress {
        let parts = raw.split(separator: ":");
        guard parts.count == 2 else {
            throw TonError.otherError("Raw ConnectAddress is malformed: should be in the form `<workchain number>:<hex>`")
        }
        guard let wc = Int8(parts[0], radix: 10) else {
            throw TonError.otherError("Raw ConnectAddress is malformed: workchain must be a decimal integer")
        }
        let hash = Data(hex: String(parts[1]))
        return ConnectAddress(workchain: wc, hash: hash)
    }

    /// Returns raw format of the address: `<workchain>:<hash>` (decimal workchain, hex-encoded hash part)
    public func toRaw() -> String {
        return "\(workchain):\(hash.hexString())"
    }
    
    /// Returns raw format of the address: `<workchain>:<hash>` (decimal workchain, hex-encoded hash part)
    public func toFriendly(testOnly: Bool = false, bounceable: Bool = BounceableDefault) -> FriendlyAddress {
        return FriendlyAddress(address: self, testOnly: testOnly, bounceable: bounceable)
    }
    
    /// Shortcut for constructing FriendlyAddress with all the options.
    public func toString(urlSafe: Bool = true, testOnly: Bool = false, bounceable: Bool = BounceableDefault) -> String {
        return self.toFriendly(testOnly: testOnly, bounceable: bounceable).toString(urlSafe: urlSafe)
    }
}

// MARK: - Equatable
extension ConnectAddress: Equatable {
    public static func == (lhs: ConnectAddress, rhs: ConnectAddress) -> Bool {
        if lhs.workchain != rhs.workchain {
            return false
        }
        
        return lhs.hash == rhs.hash
    }
}

/// ```
/// anycast_info$_ depth:(#<= 30) { depth >= 1 }
///                rewrite_pfx:(bits depth)        = Anycast;
/// addr_std$10 anycast:(Maybe Anycast)
///             workchain_id:int8
///             address:bits256                    = MsgAddressInt;
/// addr_var$11 anycast:(Maybe Anycast)
///             addr_len:(## 9)
///             workchain_id:int32
///             address:(bits addr_len)            = MsgAddressInt;
/// ```
extension ConnectAddress: CellCodable, StaticSize {
    
    public static var bitWidth: Int = 267
    
    public func storeTo(builder b: ConnectBuilder) throws {
        try b.store(uint: 2, bits: 2) // $10
        try b.store(uint: 0, bits: 1)
        try b.store(int: self.workchain, bits: 8)
        try b.store(data: self.hash)
    }
    
    public static func loadFrom(slice: ConnectSlice) throws -> ConnectAddress {
        return try slice.tryLoad { s in
            let type = try s.loadUint(bits: 2)
            if type != 2 {
                throw TonError.otherError("Unsupported ConnectAddress type: expecting internal address `addr_std$10`")
            }
            
            // No Anycast supported
            let anycastPrefix = try s.loadUint(bits: 1);
            if anycastPrefix != 0 {
                throw TonError.otherError("Invalid ConnectAddress: anycast not supported")
            }

            // Read address
            let wc = Int8(try s.loadInt(bits: 8))
            let hash = try s.loadBytes(32)

            return ConnectAddress(workchain: wc, hash: hash)
        }
    }
}

/// The most compact address encoding that's often used within smart contracts: workchain + hash.
public struct CompactAddress: Hashable, CellCodable, StaticSize {
    public static var bitWidth: Int = 8 + 256
    public let inner: ConnectAddress
    
    init(_ inner: ConnectAddress) {
        self.inner = inner
    }
    
    public func storeTo(builder b: ConnectBuilder) throws {
        try b.store(int: inner.workchain, bits: 8)
        try b.store(data: inner.hash)
    }
    
    public static func loadFrom(slice: ConnectSlice) throws -> CompactAddress {
        return try slice.tryLoad { s in
            let wc = Int8(try s.loadInt(bits: 8))
            let hash = try s.loadBytes(32)
            return CompactAddress(ConnectAddress(workchain: wc, hash: hash))
        }
    }
}

