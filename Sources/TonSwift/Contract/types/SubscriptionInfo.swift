//
//  SubscriptionInfo.swift
//  
//
//  Created by 薛跃杰 on 2023/1/9.
//

import Foundation
import BigInt

public struct SubscriptionInfo {
    public let walletAddress: Address
    public let beneficiary: Address
    public let subscriptionFee: BigInt
    public let period: Int64
    public let startTime: Int64
    public let timeOut: Int64
    public let lastPaymentTime: Int64
    public let lastRequestTime: Int64
    public let isPaid: Bool
    public let isPaymentReady: Bool
    public let failedAttempts: Int64
    public let subscriptionId: Int64
}
