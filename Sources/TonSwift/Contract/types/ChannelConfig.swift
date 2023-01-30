//
//  ChannelConfig.swift
//  
//
//  Created by 薛跃杰 on 2023/1/9.
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
