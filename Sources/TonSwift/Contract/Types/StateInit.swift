//
//  StateInit.swift
//  
//
//  Created by xgblin on 2023/1/9.
//

import Foundation

public struct StateInit {
    public let stateInit: Cell
    public let address: Address
    public let code: Cell
    public let data: Cell
}

public struct TonConnectStateInit {
    var code: Cell
    var data: Cell
    
    func store() throws -> Cell {
        let builder = CellBuilder.beginCell()
        let _ = try builder.storeBit(bit: false)
        let _ = try builder.storeBit(bit: false)
        let _ = try builder.storeMaybe(ref: code)
        let _ = try builder.storeMaybe(ref: data)
        return builder
    }
}
