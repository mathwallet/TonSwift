//
//  ClosingConfig.swift
//  
//
//  Created by xgblin on 2023/1/9.
//

import Foundation
import BigInt

public struct ClosingConfig {
    let quarantineDuration: UInt64
    let misbehaviorFine: BigInt
    let conditionalCloseDuration: UInt64
}
