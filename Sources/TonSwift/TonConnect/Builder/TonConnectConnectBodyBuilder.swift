//
//  TonConnectConnectBodyBuilder.swift
//
//
//  Created by 薛跃杰 on 2024/6/5.
//

import Foundation
import CryptoSwift
import BigInt

public struct  TonConnectConnectBodyBuilder {
    
    static func buildConnectBody(requestPayloadItems: [TonConnectRequestPayload.Item],
                                 contract: ConnectContract,
                                 keypair: TonKeypair,
                                 connecteEncryptService: TonConnectEncryptService,
                                 parameters: TonConnectParameters,
                                 manifest: TonConnectManifest) throws -> String {
        
        let replyItems = requestPayloadItems.compactMap { item in
            switch item {
            case .tonAddress:
                return ConnectItemReply.tonAddress(.init(
                    address: contract.address,
                    network: Network.mainnet,
                    publicKey: keypair.publicKey,
                    walletStateInit: contract.stateInit)
                )
            case .tonProof(let payload):
                return ConnectItemReply.tonProof(.success(.init(
                    address: contract.address,
                    domain: manifest.host,
                    payload: payload,
                    privateKey: keypair.secretKey
                )))
            case .unknown:
                return nil
            }
        }
        let successEvent = ConnectEventSuccess(
            payload: .init(items: replyItems,
                           device: .init())
        )
        let encrypted = try connecteEncryptService.encryptSuccessResponse(successResponse: successEvent, parameters: parameters)
        return encrypted
    }
    
    public static func buildSendTransactionResponseSuccess(
        boc: String,
        id: String,
        clientId: String,
        connecteEncryptService: TonConnectEncryptService
    ) throws -> String {
        let response = SendTransactionResponse.success(
            .init(result: boc,
                  id: id)
        )
        let transactionResponseData = try JSONEncoder().encode(response)
        let receiverPublicKey = Data(hex: clientId)
        let encryptedTransactionResponse = try connecteEncryptService.encrypt(
            message: transactionResponseData,
            receiverPublicKey: receiverPublicKey
        )
        return encryptedTransactionResponse.base64EncodedString()
    }
}
