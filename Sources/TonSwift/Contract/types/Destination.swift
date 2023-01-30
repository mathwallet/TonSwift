//
//  Destination.swift
//  
//
//  Created by 薛跃杰 on 2023/1/9.
//

import Foundation
import BigInt

public struct Destination {
    public let mode: UInt8
    public let address: Address
    public let amount: BigInt
}
