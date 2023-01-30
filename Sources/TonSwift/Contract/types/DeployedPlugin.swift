//
//  DeployedPlugin.swift
//  
//
//  Created by 薛跃杰 on 2023/1/30.
//

import Foundation
import BigInt

public struct DeployedPlugin {
    public let secretKey: Data
    public let seqno: Int64
    public let pluginAddress: Address
    public let amount: BigInt
    public let queryId: Int
}
