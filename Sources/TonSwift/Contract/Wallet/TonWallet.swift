//
//  Wallet.swift
//  
//
//  Created by xgblin on 2023/1/29.
//

import Foundation

public struct TonWallet {
    let options: Options
    let walletVersion: WalletVersion
    
    public init (walletVersion : WalletVersion, options : Options) {
        self.walletVersion = walletVersion
        self.options = options
    }
//    public init (walletVersion : WalletVersion) {
//        self.walletVersion = walletVersion
//        self.options = Options.builder().build()
//    }
    
    public func create() throws -> Contract {
        switch walletVersion {
        case .jettonWallet:
            return try JettonWalletContract(options: options)!
        default:
            return try WalletV4ContractR2(options: options)!
        }
    }
    
}
