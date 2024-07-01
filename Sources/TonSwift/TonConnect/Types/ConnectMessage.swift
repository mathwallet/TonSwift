//
//  ConnectMessage.swift
//
//
//  Created by xgblin on 2024/6/20.
//
import Foundation

/*
 Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L147
 message$_ {X:Type} info:CommonMsgInfo
                    init:(Maybe (Either StateInit ^StateInit))
                    body:(Either X ^X) = Message X;
 */

public struct ConnectMessage: CellCodable {
    public let info: CommonMsgInfo
    public let stateInit: ConnectStateInit?
    public let body: ConnectCell
    
    public static func loadFrom(slice: ConnectSlice) throws -> ConnectMessage {
        let info = try CommonMsgInfo.loadFrom(slice: slice)
        
        var stateInit: ConnectStateInit? = nil
        if try slice.loadBoolean() {
            if !(try slice.loadBoolean()) {
                stateInit = try ConnectStateInit.loadFrom(slice: slice)
            } else {
                stateInit = try ConnectStateInit.loadFrom(slice: try slice.loadRef().beginParse())
            }
        }
        
        var body: ConnectCell
        if try slice.loadBoolean() {
            body = try slice.loadRef()
        } else {
            body = try slice.loadRemainder()
        }
        
        return ConnectMessage(info: info, stateInit: stateInit, body: body)
    }
    
    public func storeTo(builder: ConnectBuilder) throws {
        try builder.store(info)
        
        if let stateInit {
            try builder.store(bit: 1)
            let initCell = try ConnectBuilder().store(stateInit)
            
            // check if we fit the cell inline with 2 bits for the stateinit and the body
            if let space = builder.fit(initCell.metrics), space.bitsCount >= 2 {
                try builder.store(bit: 0)
                try builder.store(initCell)
            } else {
                try builder.store(bit: 1)
                try builder.store(ref:initCell)
            }
        } else {
            try builder.store(bit:0)
        }
        
        if let space = builder.fit(body.metrics), space.bitsCount >= 1 {
            try builder.store(bit: 0)
            try builder.store(body.toBuilder())
        } else {
            try builder.store(bit: 1)
            try builder.store(ref:body)
        }
    }
    
    public static func external(to: ConnectAddress, stateInit: ConnectStateInit?, body: ConnectCell = .empty) -> ConnectMessage {
        return ConnectMessage(
            info: .externalInInfo(
                info: CommonMsgInfoExternalIn(
                    src: nil,
                    dest: to,
                    importFee: Coins(0)
                )
            ),
            stateInit: stateInit,
            body: body
        )
    }
    
}
