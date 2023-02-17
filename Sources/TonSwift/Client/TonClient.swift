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
            runGetMethod(address: address, method: "seqno").done { (result: RunGetRunMethodResult) in
                seal.fulfill(result.num ?? 0)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func getAddressBalance(address: String) -> Promise<String> {
        return send(method: "getAddressBalance", params: ["address": address])
    }
    
    public func getEstimateFee(externalMessage: ExternalMessage) -> Promise<String> {
        var params = [String: Any]()
        if let body = try? externalMessage.body.toBoc(hasIdx: false).toHexString(),
           let init_code = try? externalMessage.code?.toBoc(hasIdx: false).toHexString(),
           let init_data = try? externalMessage.data?.toBoc(hasIdx: false).toHexString() {
            params = [
                "address": externalMessage.address.toString(isUserFriendly: true, isUrlSafe: true, isBounceable: false),
                "body": body,
                "init_code": init_code,
                "init_data": init_data,
                "ignore_chksig": true
            ]
        }
        return send(method: "estimateFee", params: params)
    }
    
    
    public func sendBoc(base64: String) -> Promise<String> {
        return send(method: "sendBoc", params: ["boc": base64])
    }
    
}

extension TonClient {
    public func getJettonWalletAddress(ownerAddress: String, mintAddress: String) -> Promise<String> {
        return Promise{ seal in
            let cell = CellBuilder.beginCell()
            let _ = try cell.bits.writeAddress(address: Address(addressStr: ownerAddress))
            let base64 = try cell.toBoc(hasIdx: false).bytes.toBase64()
            runGetMethod(address: mintAddress, method: "get_wallet_address", params: [["tvm.Slice", base64]]).done { (result: RunGetRunMethodResult) in
                if let cell = result.cells.first, let address = NftUtils.parseAddress(cell: cell) {
                    seal.fulfill(address.toString(isUserFriendly: true, isUrlSafe: true, isBounceable: true))
                } else {
                    seal.reject(TonError.otherError("get wallet address error"))
                }
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func getJettonWalletData(address: String) -> Promise<RunGetRunMethodResult> {
        return runGetMethod(address: address, method: "get_wallet_data")
    }
    
    public func getJettonWalletBalance(jettonAddress: String) -> Promise<String> {
        return Promise{ seal in
            getJettonWalletData(address: jettonAddress).done { (result: RunGetRunMethodResult) in
                if let num = result.num {
                    seal.fulfill(String(num))
                } else {
                    seal.reject(TonError.otherError("get wallet data error"))
                }
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}
