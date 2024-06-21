//
//  ConnectWalletV4R2.swift
//
//
//  Created by 薛跃杰 on 2024/6/19.
//

import Foundation

public class ConnectContract: WalletV4 {
    public init(seqno: Int64 = 0,
                workchain: Int8 = 0,
                publicKey: Data,
                walletId: UInt32? = nil,
                addressString: String
    ) {
        let code = try! ConnectCell.fromBoc(src: Data(base64Encoded: "te6ccgECFAEAAtQAART/APSkE/S88sgLAQIBIAIDAgFIBAUE+PKDCNcYINMf0x/THwL4I7vyZO1E0NMf0x/T//QE0VFDuvKhUVG68qIF+QFUEGT5EPKj+AAkpMjLH1JAyx9SMMv/UhD0AMntVPgPAdMHIcAAn2xRkyDXSpbTB9QC+wDoMOAhwAHjACHAAuMAAcADkTDjDQOkyMsfEssfy/8QERITAubQAdDTAyFxsJJfBOAi10nBIJJfBOAC0x8hghBwbHVnvSKCEGRzdHK9sJJfBeAD+kAwIPpEAcjKB8v/ydDtRNCBAUDXIfQEMFyBAQj0Cm+hMbOSXwfgBdM/yCWCEHBsdWe6kjgw4w0DghBkc3RyupJfBuMNBgcCASAICQB4AfoA9AQw+CdvIjBQCqEhvvLgUIIQcGx1Z4MesXCAGFAEywUmzxZY+gIZ9ADLaRfLH1Jgyz8gyYBA+wAGAIpQBIEBCPRZMO1E0IEBQNcgyAHPFvQAye1UAXKwjiOCEGRzdHKDHrFwgBhQBcsFUAPPFiP6AhPLassfyz/JgED7AJJfA+ICASAKCwBZvSQrb2omhAgKBrkPoCGEcNQICEekk30pkQzmkD6f+YN4EoAbeBAUiYcVnzGEAgFYDA0AEbjJftRNDXCx+AA9sp37UTQgQFA1yH0BDACyMoHy//J0AGBAQj0Cm+hMYAIBIA4PABmtznaiaEAga5Drhf/AABmvHfaiaEAQa5DrhY/AAG7SB/oA1NQi+QAFyMoHFcv/ydB3dIAYyMsFywIizxZQBfoCFMtrEszMyXP7AMhAFIEBCPRR8qcCAHCBAQjXGPoA0z/IVCBHgQEI9FHyp4IQbm90ZXB0gBjIywXLAlAGzxZQBPoCFMtqEssfyz/Jc/sAAgBsgQEI1xj6ANM/MFIkgQEI9Fnyp4IQZHN0cnB0gBjIywXLAlAFzxZQA/oCE8tqyx8Syz/Jc/sAAAr0AMntVA==")!)[0]
        let address = try! ConnectAddress.parse(addressString)
        super.init(code:code, seqno: seqno, workchain: workchain, publicKey: publicKey, walletId: walletId, address: address)
    }
}

/// Internal WalletV4 implementation. Use specific revision `WalletV4R1` instead.
public class WalletV4 {
    public let seqno: Int64
    public let workchain: Int8
    public let publicKey: Data
    public let walletId: UInt32
    public let code: ConnectCell
    public let address: ConnectAddress
    
    fileprivate init(code: ConnectCell,
                     seqno: Int64 = 0,
                     workchain: Int8 = 0,
                     publicKey: Data,
                     walletId: UInt32? = nil,
                     address: ConnectAddress
    ) {
        self.code = code
        self.seqno = seqno
        self.workchain = workchain
        self.publicKey = publicKey
        self.address = address
        if let walletId {
            self.walletId = walletId
        } else {
            self.walletId = 698983191 + UInt32(workchain)
        }
    }
    
    public var stateInit: ConnectStateInit {
        let data = try! ConnectBuilder()
            .store(uint: 0, bits: 32) // initial seqno = 0
            .store(uint: self.walletId, bits: 32)
            .store(data: publicKey)
            .store(dict: Set<CompactAddress>()) // initial plugins list = []
            .endCell()
        
        return ConnectStateInit(code: self.code, data: data)
    }
    
    public func createTransfer(args: WalletTransferData) throws -> ConnectBuilder {
        guard args.messages.count <= 4 else {
            throw TonError.otherError("Maximum number of messages in a single transfer is 4")
        }
        
        let signingMessage = try ConnectBuilder().store(uint: walletId, bits: 32)
        let defaultTimeout = UInt64(Date().timeIntervalSince1970) + 60 // Default timeout: 60 seconds
        try signingMessage.store(uint: args.timeout ?? defaultTimeout, bits: 32)
        
        try signingMessage.store(uint: args.seqno, bits: 32)
        try signingMessage.store(uint: 0, bits: 8) // Simple order
        for message in args.messages {
            try signingMessage.store(uint: UInt64(args.sendMode.rawValue), bits: 8)
            try signingMessage.store(ref: try ConnectBuilder().store(message))
        }
        
        return signingMessage
    }
}
