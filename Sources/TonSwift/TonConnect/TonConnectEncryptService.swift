//
//  TonConnectService.swift
//
//
//  Created by 薛跃杰 on 2024/6/5.
//

import Foundation
import CryptoSwift
import TweetNacl

public struct TonConnectEncryptService {
    public let sessionId: String
    public let publicKey: Data
    public let privateKey: Data
    
    init() {
        let (publickey, privateKey) = try! TweetNacl.NaclBox.keyPair()
        self.sessionId = publickey.toHexString()
        self.publicKey = publickey
        self.privateKey = privateKey
    }
    
    func encryptSuccessResponse(successResponse: ConnectEventSuccess,
                                parameters: TonConnectParameters) throws -> String {
        let responseData = try JSONEncoder().encode(successResponse)
        let receiverPublicKey = Data(hex: parameters.clientId)
        let encrypted = try encrypt(message: responseData, receiverPublicKey: receiverPublicKey)
        return encrypted.base64EncodedString()
    }
    
    func encrypt(message: Data, receiverPublicKey: Data) throws -> Data {
        let nonce = try TweetNacl.NaclUtil.secureRandomData(count: 24)
        let encrypted = try TweetNacl.NaclBox.box(
            message: message,
            nonce: nonce,
            publicKey: receiverPublicKey,
            secretKey: self.privateKey)
        return nonce + encrypted
    }
}
