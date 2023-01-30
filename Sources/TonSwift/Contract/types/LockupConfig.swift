//
//  LockupConfig.swift
//  
//
//  Created by 薛跃杰 on 2023/1/9.
//

import Foundation
import BigInt

public struct LockupConfig {
    /**
     * Creation of new locked/restricted packages is only allowed by owner of this (second) public key
     */
    public let configPublicKey: String
    /**
     * Whitelist of allowed destinations
     */
    public let allowedDestinations: [String]

    public let totalRestrictedValue: BigInt
    public let totalLockedalue: BigInt
}
