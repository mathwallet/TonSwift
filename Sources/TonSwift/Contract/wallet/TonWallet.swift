//
//  Wallet.swift
//  
//
//  Created by 薛跃杰 on 2023/1/29.
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
        return try WalletV4ContractR2(options: options)!
//        switch walletVersion {
//        case .simpleR1:
//            <#code#>
//        case .simpleR2:
//            <#code#>
//        case .simpleR3:
//            <#code#>
//        case .v2R1:
//            <#code#>
//        case .v2R2:
//            <#code#>
//        case .v3R1:
//            <#code#>
//        case .v3R2:
//            <#code#>
//        case .v4R2:
//            <#code#>
//        case .lockup:
//            <#code#>
//        case .dnsCollection:
//            <#code#>
//        case .dnsItem:
//            <#code#>
//        case .jettonMinter:
//            <#code#>
//        case .jettonWallet:
//            <#code#>
//        case .nftCollection:
//            <#code#>
//        case .payments:
//            <#code#>
//        case .highload:
//            <#code#>
//        }
    }
    
}
