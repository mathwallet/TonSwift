//
//  ChannelConfig.swift
//  
//
//  Created by xgblin on 2023/1/9.
//

import Foundation
import BigInt

public struct ChannelConfig {
    let channelId: BigInt
    let addressA: Address
    let addressB: Address
    let initBalanceA: BigInt
    let initBalanceB: BigInt
}
