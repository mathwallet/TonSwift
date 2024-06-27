//
//  TonConnectServiceBodyBuilder.swift
//
//
//  Created by 薛跃杰 on 2024/6/20.
//

import Foundation
import BigInt

public struct TonConnectServiceBodyBuilder {
    
    public static func buildConnectBody(keypair: TonKeypair,
                                        contract: ConnectContract,
                                        parameters: TonConnectParameters,
                                        connecteEncryptService: TonConnectEncryptService,
                                        manifest: TonConnectManifest) throws -> String {
        let body = try TonConnectConnectBodyBuilder.buildConnectBody(requestPayloadItems:
                                                                        parameters.payload.items,
                                                                     contract: contract,
                                                                     keypair: keypair,
                                                                     connecteEncryptService: connecteEncryptService,
                                                                     parameters: parameters,
                                                                     manifest: manifest)
        return body
    }
    
    
    public static func buildCancelBody(keypair: TonKeypair,
                                           id: String,
                                           clientId: String,
                                           connecteEncryptService: TonConnectEncryptService) throws -> String {
        let body = try TonConnectConnectBodyBuilder.buildCancelRequestBody(id: id, clientId: clientId, connecteEncryptService: connecteEncryptService)
        return body
    }
    
    public static func buildConfirmBody(keypair: TonKeypair,
                                        boc: String,
                                        id: String,
                                        clientId: String,
                                        connecteEncryptService: TonConnectEncryptService) throws -> String {
        let body = try TonConnectConnectBodyBuilder.buildConfirmRequestBody(id: id, boc: boc, clientId: clientId, connecteEncryptService: connecteEncryptService)
        return body
    }
    
    public static func buildSendTransactionBody(keypair: TonKeypair,
                                                seqno: UInt64,
                                                sender: ConnectAddress,
                                                parameters: TonConnectDappRequest.TonConnectParam,
                                                contract: ConnectContract) throws -> String {
        let payloads = parameters.messages.map { message in
            TonConnectTransferMessageBuilder.Payload(
                value: BigInt(integerLiteral: message.amount),
                recipientAddress: message.address,
                stateInit: message.stateInit,
                payload: message.payload)
        }
        let body = try TonConnectTransferMessageBuilder.sendTonConnectTransfer(contract: contract,
                                                                               keyPair: keypair,
                                                                               seqno: seqno,
                                                                               payloads: payloads,
                                                                               sender: sender)
        return body
    }
}
