import Foundation

struct ADNLAddress {
    static func parseFriendly(_ src: String) throws -> ADNLAddress {
        if src.count != 55 {
            throw TonError.otherError("Invalid address")
        }

        let decoded = try "f\(src)".fromBase32()
        if decoded[0] != 0x2d {
            throw TonError.otherError("Invalid address")
        }

        let gotHash = decoded[33...].bytes
        let hash = Data(decoded[0..<33].bytes).crc16Data()
        if !hash.bytes.elementsEqual(gotHash) {
            throw TonError.otherError("Invalid address")
        }

        return try ADNLAddress(address: Data(decoded[1..<33].bytes))
    }

    static func parseRaw(_ src: String) throws -> ADNLAddress {
        let data = Data(base64Encoded: src)
        
        return try ADNLAddress(address: data!)
    }

    let address: Data
    
    init(address: Data) throws {
        if address.count != 32 {
            throw TonError.otherError("Invalid address")
        }
        
        self.address = address
    }
    
    func toRaw() -> String {
        return address.map { String(format: "%02X", $0) }.joined().uppercased()
    }

    func toString() -> String {
        var data = Data([0x2D]) + self.address
        let hash = data.crc16Data()
        data = data + hash
        
        return String(data.toBase32().dropFirst())
    }

}

// MARK: - Equatable
extension ADNLAddress: Equatable {
    static func == (lhs: ADNLAddress, rhs: ADNLAddress) -> Bool {
        return lhs.address == rhs.address
    }
}
