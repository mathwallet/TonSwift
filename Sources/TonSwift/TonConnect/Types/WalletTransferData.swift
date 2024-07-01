//
//  WalletTransferData.swift
//
//
//  Created by xgblin on 2024/6/19.
//

import Foundation

public struct WalletTransferData {
    public let seqno: UInt64
    public let messages: [MessageRelaxed]
    public let sendMode: SendMode
    public let timeout: UInt64?
    
    public init(seqno: UInt64,
                messages: [MessageRelaxed],
                sendMode: SendMode,
                timeout: UInt64?) {
        self.seqno = seqno
        self.messages = messages
        self.sendMode = sendMode
        self.timeout = timeout
    }
}
