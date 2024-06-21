import Foundation
import BigInt


public struct CommonMsgInfoRelaxedInternal {
    public let ihrDisabled: Bool
    public let bounce: Bool
    public let bounced: Bool
    public let src: AnyAddress
    public let dest: ConnectAddress
    public let value: CurrencyCollection
    public let ihrFee: Coins
    public let forwardFee: Coins
    public let createdLt: UInt64
    public let createdAt: UInt32
}

public struct CommonMsgInfoRelaxedExternalOut {
    public let src: AnyAddress
    public let dest: ExternalAddress?
    public let createdLt: UInt64
    public let createdAt: UInt32
}

public enum CommonMsgInfoRelaxed: CellCodable {
    case internalInfo(info: CommonMsgInfoRelaxedInternal)
    case externalOutInfo(info: CommonMsgInfoRelaxedExternalOut)
    
    public static func loadFrom(slice: ConnectSlice) throws -> CommonMsgInfoRelaxed {
        // Internal message
        if !(try slice.loadBoolean()) {
            let ihrDisabled = try slice.loadBoolean()
            let bounce = try slice.loadBoolean()
            let bounced = try slice.loadBoolean()
            let src: AnyAddress = try slice.loadType()
            let dest: ConnectAddress = try slice.loadType()
            let value: CurrencyCollection = try slice.loadType()
            let ihrFee = try slice.loadCoins()
            let forwardFee = try slice.loadCoins()
            let createdLt = try slice.loadUint(bits: 64)
            let createdAt = UInt32(try slice.loadUint(bits: 32))
            
            return CommonMsgInfoRelaxed.internalInfo(
                info: .init(
                    ihrDisabled: ihrDisabled,
                    bounce: bounce,
                    bounced: bounced,
                    src: src,
                    dest: dest,
                    value: value,
                    ihrFee: ihrFee,
                    forwardFee: forwardFee,
                    createdLt: createdLt,
                    createdAt: createdAt
                )
            )
        }
        
        // External In message
        if !(try slice.loadBoolean()) {
            throw TonError.otherError("External In message is not possible for CommonMessageInfoRelaxed")
        } else {
            // External Out mesage
            let src: AnyAddress = try slice.loadType()
            let dest: AnyAddress = try slice.loadType()
            let createdLt = try slice.loadUint(bits: 64)
            let createdAt = UInt32(try slice.loadUint(bits: 32))
            
            return CommonMsgInfoRelaxed.externalOutInfo(
                info: .init(
                    src: src,
                    dest: try dest.asExternal(),
                    createdLt: createdLt,
                    createdAt: createdAt
                )
            )
        }
    }
    
    public func storeTo(builder: ConnectBuilder) throws {
        switch self {
        case .internalInfo(let info):
            try builder.store(bit: false)
            try builder.store(bit: info.ihrDisabled)
            try builder.store(bit: info.bounce)
            try builder.store(bit: info.bounced)
            try builder.store(info.src)
            try builder.store(AnyAddress(info.dest))
            try builder.store(info.value)
            try builder.store(coins: info.ihrFee)
            try builder.store(coins: info.forwardFee)
            try builder.store(uint: info.createdLt, bits: 64)
            try builder.store(uint: UInt64(info.createdAt), bits: 32)
            
        case .externalOutInfo(let info):
            try builder.store(bit:true)
            try builder.store(bit:true)
            try builder.store(info.src)
            try builder.store(AnyAddress(info.dest))
            try builder.store(uint: info.createdLt, bits: 64)
            try builder.store(uint: UInt64(info.createdAt), bits: 32)
        }
    }
}
