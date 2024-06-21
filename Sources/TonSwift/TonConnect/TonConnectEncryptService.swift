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
//        let (publickey, privateKey) = try! TweetNacl.NaclBox.keyPair()
//        self.sessionId = publickey.toHexString()
//        self.publicKey = publickey
//        self.privateKey = privateKey
        self.sessionId = "bb0524183d655c9b74ff8123a4ffb0f5f50167fc12fa9c86c7602ebf195e0d56"
        self.publicKey = Data(hex: "bb0524183d655c9b74ff8123a4ffb0f5f50167fc12fa9c86c7602ebf195e0d56")
        self.privateKey = Data(hex: "82b9348b63a947b157354a62a602fdf5e76f6184940262a3c46eb19e1f187a05")
    }
    
    func encryptSuccessResponse(successResponse: ConnectEventSuccess,
                                parameters: TonConnectParameters) throws -> String {
        let responseData = try JSONEncoder().encode(successResponse)
        let receiverPublicKey = Data(hex: parameters.clientId)
        let encrypted = try encrypt(message: responseData, receiverPublicKey: receiverPublicKey)
        return encrypted.base64EncodedString()
    }
    
    func encrypt(message: Data, receiverPublicKey: Data) throws -> Data {
//        let nonce = try TweetNacl.NaclUtil.secureRandomData(count: 24)
        let nonce = Data(hex: "919fba28e5caed869c8af82a31ba478867fc05eb358ba176")
        let encrypted = try TweetNacl.NaclBox.box(
            message: message,
            nonce: nonce,
            publicKey: receiverPublicKey,
            secretKey: self.privateKey)
        return nonce + encrypted
    }
}
