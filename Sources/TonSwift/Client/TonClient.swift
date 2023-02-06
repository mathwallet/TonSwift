//
//  TonClient.swift
//  
//
//  Created by xgblin on 2023/2/3.
//

import Foundation
import PromiseKit

public class TonClient: TonClientBase {
    
    public func getChainInfo() -> Promise<ChainInfoResult> {
        return send(method: "getMasterchainInfo")
    }
    
    public func getAddressInfo(address: String) -> Promise<AddressInfoResult> {
        return send(method: "getAddressInformation", params: ["address": address])
    }
    
    public func getWalletInfo(address: String) -> Promise<WalletInfoResult> {
        return send(method: "getWalletInformation", params: ["address": address])
    }
    
    public func getSeqno(address: String) -> Promise<Int64> {
        return Promise{ seal in
            runGetMethod(address: address, method: "seqno").done { (result:TonSeqnoResult) in
                seal.fulfill(result.seqno)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func getAddressBalance(address: String) -> Promise<String> {
        return send(method: "getAddressBalance", params: ["address": address])
    }

    public func sendBoc(base64: String) -> Promise<String> {
        return send(method: "sendBoc", params: ["boc": base64])
    }
    
}
