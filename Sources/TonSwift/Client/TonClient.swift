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
        return sendRPC(method: "getMasterchainInfo")
    }
    
    public func getAddressInfo(address: String) -> Promise<AddressInfoResult> {
        return sendRPC(method: "getAddressInformation", params: ["address": address])
    }
    
    public func getWalletInfo(address: String) -> Promise<WalletInfoResult> {
        return sendRPC(method: "getWalletInformation", params: ["address": address])
    }
    
    public func getSeqno(address: String) -> Promise<Int64> {
        return Promise{ seal in
            getWalletInfo(address: address).done { walletInfoResult in
                seal.fulfill(walletInfoResult.seqno ?? 0)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func getAddressBalance(address: String) -> Promise<String> {
        return sendRPC(method: "getAddressBalance", params: ["address": address])
    }
    
    public func getEstimateFee(from: String, externalMessage: ExternalMessage) -> Promise<Int64> {
        return Promise<Int64> {seal in
            var params = [String: Any]()
            do {
                let fromAddress = Address(addressStr: from)?.toString(isUserFriendly: true, isUrlSafe: true, isBounceable: false)
                let body = try externalMessage.body.toBocBase64(hasIdx: false)
                let init_code = try externalMessage.code?.toBocBase64(hasIdx: false)
                let init_data = try externalMessage.data?.toBocBase64(hasIdx: false)
                params = [
                    "address": fromAddress ?? "",
                    "body": body,
                    "init_code": init_code ?? "",
                    "init_data": init_data ?? ""
                ] as [String: Any]
                sendRPC(method: "estimateFee", params: params).done { (result: EstimateFeeResult) in
                    seal.fulfill(result.gasFee)
                }.catch { error in
                    seal.reject(error)
                }
            } catch let error {
                seal.reject(error)
            }
        }
    }
    
    
    public func sendBoc(base64: String) -> Promise<String> {
        return Promise<String> {seal in
            POST(path: "/api/v2/sendBocReturnHash", parameters: ["boc": base64]).done { (result: SendBocReturnHashResult) in
                seal.fulfill(result.hash)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}

extension TonClient {
    public func getJettonWalletAddress(ownerAddress: String, mintAddress: String) -> Promise<String> {
        return Promise{ seal in
            let cell = CellBuilder.beginCell()
            let _ = try cell.bits.writeAddress(address: Address(addressStr: ownerAddress))
            let base64 = try cell.toBoc(hasIdx: false).bytes.toBase64()
            runGetMethod(address: mintAddress, method: "get_wallet_address", params: [["tvm.Slice", base64]]).done { (result: RunGetRunMethodResult) in
                if result.exitCode == 0, let cell = result.cells.first, let address = NftUtils.parseAddress(cell: cell) {
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
        return Promise { seal in
            getJettonWalletData(address: jettonAddress).done { (result: RunGetRunMethodResult) in
                if result.exitCode == 0, let num = result.num {
                    seal.fulfill(String(num))
                } else {
                    seal.reject(TonError.otherError("get wallet data error"))
                }
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func getJettonTokenData(mintAddress: String) -> Promise<TokenResult> {
        return Promise { seal in
            var tokenResult = TokenResult()
            GET(path: "/api/v2/getTokenData",parameters: ["address": mintAddress]).then { (result: JettonsTokenResult) in
                tokenResult.decimals = result.jettonContent.data.decimals
                return self.getJettonContentData(path: result.jettonContent.data.uri)
            }.done { (result: TokenResult) in
                tokenResult.name = result.name
                tokenResult.symbol = result.symbol
                tokenResult.image = result.image
                seal.fulfill(tokenResult)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    private func getJettonContentData(path: String) -> Promise<TokenResult> {
        return GET(urlString: path)
    }
}
