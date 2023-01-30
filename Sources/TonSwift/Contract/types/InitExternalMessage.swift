//
//  InitExternalMessage.swift
//  
//
//  Created by 薛跃杰 on 2023/1/29.
//

import Foundation

public struct InitExternalMessage {
    public let address: Address
    public let message: Cell
    public let body: Cell
    public let signingMessage: Cell
    public let stateInit: Cell
    public let code: Cell
    public let data: Cell
}
 
