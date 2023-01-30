//
//  WalletContract.swift
//  
//
//  Created by 薛跃杰 on 2023/1/29.
//

import Foundation
import BigInt
import TweetNacl

public class WalletContract : Contract {
    
    public func getName() -> String {
        return ""
    }
    
    /**
     * Method to override
     *
     * @return Cell cell, contains wallet data
     */
    public override func createDataCell() throws -> Cell {
        let cell = CellBuilder.beginCell()
        let _ = try cell.storeUint(number: BigInt.zero, bitLength: 32) // seqno
        let _ = try cell.storeBytes(bytes: self.getOptions()!.publicKey!.bytes)
        return cell
    }
    
    /**
     * @param seqno long
     * @return Cell
     */
    func createSigningMessage(seqno: Int64) throws -> Cell {
        return try CellBuilder.beginCell().storeUint(number: BigInt(seqno), bitLength: 32).endCell
    }
    
    /**
     * External message for initialization
     *
     * @param secretKey byte[] nacl.KeyPair.secretKey
     * @return InitExternalMessage
     */
    func  createInitExternalMessage(secretKey: Data) throws -> InitExternalMessage {
        let publicKey = getOptions()?.publicKey ?? Data()
        if (publicKey.count == 0) {
            let keyPair = try TonKeypair(secretKey: secretKey)
            self.options?.publicKey = keyPair.publicKey
        }
        
        let stateInit = try createStateInit()
        
        let signingMessage = try createSigningMessage(seqno: 0)
        let signature = try TweetNacl.NaclSign.signDetached(message: try signingMessage.hash(), secretKey: secretKey)
        
        let body = CellBuilder.beginCell()
        let _ = try body.storeBytes(bytes: signature.bytes)
        try body.writeCell(anotherCell: signingMessage)
        
        let header = try Contract.createExternalMessageHeader(dest: stateInit.address)
        
        let externalMessage = try Contract.createCommonMsgInfo(header: header, stateInit: stateInit.stateInit, body: body.endCell)
        
        return InitExternalMessage(address: stateInit.address,
                                   message: externalMessage,
                                   body: body,
                                   signingMessage: signingMessage,
                                   stateInit: stateInit.stateInit,
                                   code: stateInit.code,
                                   data: stateInit.data)
    }
    
    /**
     * @param signingMessage Cell
     * @param secretKey      byte[]  nacl.KeyPair.secretKey
     * @param seqno          long
     * @param dummySignature boolean, flag to specify whether to use signature based on private key or fill the space with zeros.
     * @return ExternalMessage
     */
    func createExternalMessage(signingMessage: Cell,
                               secretKey: Data,
                               seqno: Int64,
                               dummySignature: Bool) throws -> ExternalMessage { // todo func false
        var signature = Data()
        if (dummySignature) {
            signature = Data(count: 64)
        } else {
            let data = try signingMessage.hash()
            signature = try Utils.signData(prvKey: secretKey, data: data)
        }
        
        let body = CellBuilder.beginCell()
        let _ = try body.storeBytes(number: signature)
        try body.writeCell(anotherCell: signingMessage)
        
        var stateInit: Cell? = nil
        var code: Cell? = nil
        var data: Cell? = nil
        
        if (seqno == 0) {
            if let _ = getOptions()?.publicKey {} else {
                let keyPair = try TonKeypair(secretKey: secretKey)
                self.options?.publicKey = keyPair.publicKey
            }
            let deploy = try createStateInit()
            stateInit = deploy.stateInit
            code = deploy.code
            data = deploy.data
        }
        
        let selfAddress = try getAddress()
        let header = try Contract.createExternalMessageHeader(dest: selfAddress)
        let resultMessage = try Contract.createCommonMsgInfo(header: header, stateInit: stateInit, body: body.endCell)
        
        return ExternalMessage(address: selfAddress,
                               message: resultMessage,
                               body: body,
                               signature: signature,
                               signingMessage: signingMessage,
                               stateInit: stateInit,
                               code: code,
                               data: data)
    }
    
    /**
     * @param secretKey      byte[]  nacl.KeyPair.secretKey
     * @param address        Address destination
     * @param amount         BigInteger in nano-coins
     * @param seqno          long
     * @param payload        Cell, null
     * @param sendMode       byte, 3
     * @param dummySignature boolean, false
     * @param stateInit      Cell, null
     * @return ExternalMessage
     */
    func createTransferMessage(secretKey: Data,
                               address: Address,
                               amount: BigInt,
                               seqno: Int64,
                               payload: Cell?,
                               sendMode: UInt8,
                               dummySignature: Bool,
                               stateInit: Cell?) throws -> ExternalMessage {
        
        let orderHeader = try Contract.createInternalMessageHeader(dest: address, gramValue: amount)
        let order = try Contract.createCommonMsgInfo(header: orderHeader, stateInit: stateInit, body: payload)
        let signingMessage = try createSigningMessage(seqno: seqno)
        try signingMessage.bits.writeUInt8(ui8: Int(sendMode & 0xff))
        signingMessage.refs.append(order)
        
        return try createExternalMessage(signingMessage: signingMessage, secretKey: secretKey, seqno: seqno, dummySignature: dummySignature)
    }
    
    /**
     * @param secretKey byte[]  nacl.KeyPair.secretKey
     * @param address   Address
     * @param amount    BigInteger in nano-coins
     * @param seqno     long
     * @return ExternalMessage
     */
    func createTransferMessage(secretKey: Data,
                               address: Address,
                               amount: BigInt,
                               seqno: Int64,
                               payload:Cell) throws -> ExternalMessage {
        return try createTransferMessage(secretKey: secretKey, address: address, amount: amount, seqno: seqno, payload: payload, sendMode: UInt8(3), dummySignature: false, stateInit: nil)
    }
    
    /**
     * @param secretKey byte[]  nacl.KeyPair.secretKey
     * @param address   Address
     * @param amount    BigInteger in nano-coins
     * @param seqno     long
     * @return ExternalMessage
     */
    func createTransferMessage(secretKey: Data,
                               address: Address,
                               amount: BigInt,
                               seqno: Int64) throws -> ExternalMessage {
        return try createTransferMessage(secretKey: secretKey, address: address, amount: amount, seqno: seqno, payload: nil, sendMode: UInt8(3), dummySignature: false, stateInit: nil)
    }
    
    /**
     * @param secretKey byte[]  nacl.KeyPair.secretKey
     * @param address   String
     * @param amount    BigInteger in nano-coins
     * @param seqno     long
     * @return ExternalMessage
     */
    func createTransferMessage(secretKey: Data,
                               address: String,
                               amount: BigInt,
                               seqno: Int64) throws ->ExternalMessage {
        guard let addr = try? Address.of(addressStr: address) else {
            throw TonError.message("address error")
        }
        return try createTransferMessage(secretKey: secretKey, address: addr, amount: amount, seqno: seqno, payload: nil, sendMode: UInt8(3), dummySignature: false, stateInit: nil)
    }
    
    /**
     * @param secretKey      byte[] nacl.KeyPair.secretKey
     * @param address        String
     * @param amount         BigInteger in nano-coins
     * @param seqno          long
     * @param payload        Cell
     * @param sendMode       byte, 3
     * @param dummySignature boolean, false
     * @param stateInit      Cell, null
     * @return ExternalMessage
     */
    func createTransferMessage(secretKey: Data,
                               address: String,
                               amount: BigInt,
                               seqno: Int64,
                               payload: Cell,
                               sendMode: UInt8,
                               dummySignature: Bool,
                               stateInit: Cell) throws ->ExternalMessage {
        guard let addr = try? Address.of(addressStr: address) else {
            throw TonError.message("address error")
        }
        return try createTransferMessage(secretKey: secretKey, address: addr, amount: amount, seqno: seqno, payload: payload, sendMode: sendMode, dummySignature: dummySignature, stateInit: stateInit)
    }
    
    /**
     * @param secretKey      byte[]  nacl.KeyPair.secretKey
     * @param address        Address
     * @param amount         BigInteger in nano-coins
     * @param seqno          long
     * @param payload        byte[]
     * @param sendMode       byte, 3
     * @param dummySignature boolean, false
     * @param stateInit      Cell, null
     * @return ExternalMessage
     */
    
    func createTransferMessage(secretKey: Data,
                               address: Address,
                               amount: BigInt,
                               seqno: Int64,
                               payload: Data,
                               sendMode: UInt8,
                               dummySignature: Bool,
                               stateInit: Cell) throws ->ExternalMessage {
        let payloadCell = try CellBuilder.beginCell().storeBytes(bytes: payload.bytes).endCell
        
        return try createTransferMessage(secretKey: secretKey, address: address, amount: amount, seqno: seqno, payload: payloadCell, sendMode: sendMode, dummySignature: dummySignature, stateInit: stateInit)
    }
    
    /**
     * @param secretKey      byte[]  nacl.KeyPair.secretKey
     * @param address        String
     * @param amount         BigInteger in nano-coins
     * @param seqno          long
     * @param payload        byte[]
     * @param sendMode       byte, 3
     * @param dummySignature boolean, false
     * @param stateInit      Cell, null
     * @return ExternalMessage
     */
    func createTransferMessage(secretKey: Data,
                               address: String,
                               amount: BigInt,
                               seqno: Int64,
                               payload: Data,
                               sendMode: UInt8,
                               dummySignature: Bool,
                               stateInit: Cell) throws ->ExternalMessage {
        guard let addr = try? Address.of(addressStr: address) else {
            throw TonError.message("address error")
        }
        return try createTransferMessage(secretKey: secretKey, address: addr, amount: amount, seqno: seqno, payload: payload, sendMode: sendMode, dummySignature: dummySignature, stateInit: stateInit)
    }
    
    /**
     * @param secretKey      byte[]  nacl.KeyPair.secretKey
     * @param address        Address
     * @param amount         BigInteger in nano-coins
     * @param seqno          long
     * @param payload        String
     * @param sendMode       byte, func 3
     * @param dummySignature boolean, false
     * @param stateInit      Cell, null
     * @return ExternalMessage
     */
    func createTransferMessage(secretKey: Data,
                               address: Address,
                               amount: BigInt,
                               seqno: Int64,
                               payload: String,
                               sendMode: UInt8,
                               dummySignature: Bool,
                               stateInit: Cell) throws -> ExternalMessage  {
        
        let payloadCell = CellBuilder.beginCell()
        
        if (payload.count > 0) {
            let _ = try payloadCell.storeUint(number: BigInt.zero, bitLength: 32)
            let _ = try payloadCell.storeString(str: payload)
            return try createTransferMessage(secretKey: secretKey, address: address, amount: amount, seqno: seqno, payload: payloadCell, sendMode: sendMode, dummySignature: dummySignature, stateInit: stateInit)
        } else {
            return try createTransferMessage(secretKey: secretKey, address: address, amount: amount, seqno: seqno, payload: nil, sendMode: sendMode, dummySignature: dummySignature, stateInit: stateInit)
        }
    }
    
    /**
     * @param secretKey      byte[]  nacl.KeyPair.secretKey
     * @param address        String
     * @param amount         BigInteger in nano-coins
     * @param seqno          long
     * @param payload        String
     * @param sendMode       byte
     * @param dummySignature boolean
     * @param stateInit      Cell
     * @return ExternalMessage
     */
    func createTransferMessage(secretKey: Data,
                               address: String,
                               amount: BigInt,
                               seqno: Int64,
                               payload: String,
                               sendMode: UInt8,
                               dummySignature: Bool,
                               stateInit: Cell) throws -> ExternalMessage {
        guard let addr = try? Address.of(addressStr: address) else {
            throw TonError.message("address error")
        }
        return try createTransferMessage(secretKey: secretKey, address: addr, amount: amount, seqno: seqno, payload: payload, sendMode: sendMode, dummySignature: dummySignature, stateInit: stateInit)
    }
    
    /**
     * Get current seqno
     *
     * @return long
     */
//    func getSeqno(tonlib: Tonlib) -> Int64 {
//
//        if (NSStringFromClass(self) == "SimpleWalletContractR1") {
//            throw TonError.message("simple wallet of revsion 1 does not have seqno method")
//        }
//
//        let myAddress = getAddress()
//        RunResult result = tonlib.runMethod(myAddress, "seqno")
//        if (result.getExit_code() != 0) {
//            throw new Error("method seqno returned an exit code " + result.getExit_code())
//        }
//
//        let seqno = (TvmStackEntryNumber) result.getStack().get(0)
//
//        return seqno.getNumber().longValue()
//    }
}
