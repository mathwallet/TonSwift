//
//  TonConnectParameterBuilder.swift
//
//
//  Created by 薛跃杰 on 2024/6/5.
//

import Foundation

public struct TonConnectParameterBuilder {
    static func buildConnectEventSuccesResponse(requestPayloadItems: [TonConnectRequestPayload.Item],
                                                wallet: TonWallet,
                                                keypair: TonKeypair,
                                                manifest: TonConnectManifest) throws -> ConnectEventSuccess {
        let contract = try wallet.create()
        let address = try contract.getAddress()
        
        let replyItems = try requestPayloadItems.compactMap { item in
            switch item {
        case .tonAddress:
          return ConnectItemReply.tonAddress(.init(
            address: address,
            network: Network.mainnet,
            publicKey: keypair.publicKey,
            walletStateInit: try contract.createTonConnectStateInit())
          )
        case .tonProof(let payload):
          return ConnectItemReply.tonProof(.success(.init(
            address: address,
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
      return successEvent
    }
}
