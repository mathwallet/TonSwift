//
//  Options.swift
//  
//
//  Created by 薛跃杰 on 2023/1/9.
//

import Foundation
import BigInt
import TweetNacl

public struct Options {
    public let secretKey: Data? = nil
    public var publicKey: Data? = nil
    public let Key: Data? = nil
    public let wc: Int64? = nil
    public let address: Address? = nil
    public let amount: BigInt? = nil
    public var code: Cell? = nil
    public let seqno: Int64? = nil
    public let queryId: Int64? = nil
    public let highloadQueryId: BigInt? = nil
    public let payload: AnyObject? = nil
    public let sendMode: Int? = nil
    public let stateInit: Cell? = nil
    public var walletId: Int64? = nil
    public let lockupConfig: LockupConfig? = nil
    public let highloadConfig: HighloadConfig? = nil
    public let subscriptionConfig: SubscriptionInfo? = nil
    public let index: String //dns item index, sha256? = nil
    public let collectionAddress: Address // todo dns config? = nil
    public let collectionContent: Cell? = nil
    public let collectionContentUri: String? = nil
    public let collectionContentBaseUri: String? = nil
    public let dnsItemCodeHex: String? = nil
    public let adminAddress: Address? = nil
    public let jettonContentUri: String // todo jetton config? = nil
    public let jettonWalletCodeHex: String? = nil
    public let marketplaceAddress: Address? = nil
    public let nftItemAddress: Address? = nil
    public let nftItemCodeHex: String? = nil
    public let fullPrice: BigInt? = nil
    public let marketplaceFee: BigInt? = nil
    public let royaltyAddress: Address? = nil
    public let royaltyAmount: BigInt? = nil
    public let royalty: Double? = nil

    public let nftItemContentBaseUri: String? = nil

    //payments? = nil
    public let channelConfig: ChannelConfig? = nil

    public let letKeyA: Data? = nil
    public let letKeyB: Data? = nil
    public let isA: Bool? = nil
    public let myKeyPair: NaclSign.KeyPair? = nil
    public let hisPublicKey: Data? = nil
    public let excessFee: BigInt? = nil
    public let closingConfig: ClosingConfig? = nil
}
