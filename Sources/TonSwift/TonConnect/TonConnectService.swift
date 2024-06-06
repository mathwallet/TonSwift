//
//  TonConnectService.swift
//
//
//  Created by 薛跃杰 on 2024/6/5.
//

import Foundation
import CryptoSwift
import TweetNacl

public struct TonConnectService {
    public static func buildConnectEventSuccessResponse(keypair: TonKeypair,
                                                        wallet: TonWallet,
                                                        parameters: TonConnectParameters,
                                                        manifest: TonConnectManifest) throws -> ConnectEventSuccess {
        let successResponse = try TonConnectParameterBuilder.buildConnectEventSuccesResponse(requestPayloadItems:
                                                                                                parameters.payload.items,
                                                                                             wallet: wallet,
                                                                                             keypair: keypair,
                                                                                             manifest: manifest)
        return successResponse
    }
    
    public static func encryptSuccessResponse(successResponse: ConnectEventSuccess, 
                                              keypair: TonKeypair,
                                              parameters: TonConnectParameters) throws -> String {
          let responseData = try JSONEncoder().encode(successResponse)
          let receiverPublicKey = Data(hex: parameters.clientId)
          let nonce = try TweetNacl.NaclUtil.secureRandomData(count: 24)
          let encrypted = try TweetNacl.NaclBox.box(
            message: responseData,
            nonce: nonce,
            publicKey: receiverPublicKey,
            secretKey: keypair.secretKey)
        var response = nonce
        response.append(encrypted)
        return response.base64EncodedString()
      }
}
