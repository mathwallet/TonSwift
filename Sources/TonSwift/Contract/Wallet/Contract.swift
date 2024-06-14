//
//  Contract.swift
//  
//
//  Created by xgblin on 2023/1/9.
//

import Foundation
import BigInt

public class Contract {
    public var options: Options? = nil
    
    public func getOptions() -> Options? {
        return options
    }

    public func getAddress() throws -> Address {
        return Address()
    }

    /**
     * @return Cell containing contact code
     */
    public func createCodeCell() throws -> Cell {
        guard let code = getOptions()?.code else {
            throw TonError.otherError("Contract: options.code is not defined")
        }
        return code
    }

    /**
     * Method to override
     *
     * @return {Cell} cell contains contract data
     */

    public func createDataCell() throws -> Cell {
        return Cell()
    }

    /**
     * Message StateInit consists of initial contract code, data and address in a blockchain
     *
     * @return StateInit
     */
    public func createStateInit() throws -> StateInit {
        let codeCell = try createCodeCell()
        let dataCell = try createDataCell()
        let stateInit = try createStateInit(code: codeCell, data: dataCell)
        
        let stateInitHash = try stateInit.hash()
        let address = try Address.of(addressStr:"\(self.options?.wc ?? 0):\(stateInitHash.toHexString())" )
        return StateInit(stateInit: stateInit, address: address!, code: codeCell, data: dataCell)
    }
    
    public func createTonConnectStateInit(walletId: UInt32, publicKey: Data) throws -> ConnectStateInit {
        let code = try! ConnectCell.fromBoc(src: Data(base64Encoded: "te6cckECFQEAAvUAART/APSkE/S88sgLAQIBIAIDAgFIBAUE+PKDCNcYINMf0x/THwL4I7vyY+1E0NMf0x/T//QE0VFDuvKhUVG68qIF+QFUEGT5EPKj+AAkpMjLH1JAyx9SMMv/UhD0AMntVPgPAdMHIcAAn2xRkyDXSpbTB9QC+wDoMOAhwAHjACHAAuMAAcADkTDjDQOkyMsfEssfy/8REhMUA+7QAdDTAwFxsJFb4CHXScEgkVvgAdMfIYIQcGx1Z70ighBibG5jvbAighBkc3RyvbCSXwPgAvpAMCD6RAHIygfL/8nQ7UTQgQFA1yH0BDBcgQEI9ApvoTGzkl8F4ATTP8glghBwbHVnupEx4w0kghBibG5juuMABAYHCAIBIAkKAFAB+gD0BDCCEHBsdWeDHrFwgBhQBcsFJ88WUAP6AvQAEstpyx9SEMs/AFL4J28ighBibG5jgx6xcIAYUAXLBSfPFiT6AhTLahPLH1Iwyz8B+gL0AACSghBkc3Ryuo41BIEBCPRZMO1E0IEBQNcgyAHPFvQAye1UghBkc3Rygx6xcIAYUATLBVjPFiL6AhLLassfyz+UEDRfBOLJgED7AAIBIAsMAFm9JCtvaiaECAoGuQ+gIYRw1AgIR6STfSmRDOaQPp/5g3gSgBt4EBSJhxWfMYQCAVgNDgARuMl+1E0NcLH4AD2ynftRNCBAUDXIfQEMALIygfL/8nQAYEBCPQKb6ExgAgEgDxAAGa3OdqJoQCBrkOuF/8AAGa8d9qJoQBBrkOuFj8AAbtIH+gDU1CL5AAXIygcVy//J0Hd0gBjIywXLAiLPFlAF+gIUy2sSzMzJcfsAyEAUgQEI9FHypwIAbIEBCNcYyFQgJYEBCPRR8qeCEG5vdGVwdIAYyMsFywJQBM8WghAF9eEA+gITy2oSyx/JcfsAAgBygQEI1xgwUgKBAQj0WfKn+CWCEGRzdHJwdIAYyMsFywJQBc8WghAF9eEA+gIUy2oTyx8Syz/Jc/sAAAr0AMntVEap808=")!)[0]
        let data = try! ConnectBuilder()
            .store(uint: 0, bits: 32) // initial seqno = 0
            .store(uint: walletId, bits: 32)
            .store(data: publicKey)
            .store(dict: Set<CompactAddress>()) // initial plugins list = []
            .endCell()
        return ConnectStateInit(code: code, data: data)
    }

    // split_depth:(Maybe (## 5))
    // special:(Maybe TickTock)
    // code:(Maybe ^Cell)
    // data:(Maybe ^Cell)
    // library:(Maybe ^Cell) = StateInit;

    /**
     * Message StateInit consists of initial contract code, data and address in a blockchain.
     * Argments library, splitDepth and ticktock in state init is not yet implemented.
     *
     * @param code       Cell
     * @param data       Cell
     * @param library    nil
     * @param splitDepth nil
     * @param ticktock   nil
     * @return Cell
     */
    public func createStateInit(code: Cell?, data: Cell?, library: Cell?, splitDepth: Cell?, ticktock: Cell?) throws -> Cell {
        
        if library != nil {
            throw TonError.otherError("Library in state init is not implemented")
            
        }
        
        if splitDepth != nil {
            throw TonError.otherError("Split depth in state init is not implemented")
        }
        
        if ticktock != nil  {
            throw TonError.otherError("Ticktock in state init is not implemented")
        }

        let stateInit = CellBuilder.beginCell()
//        stateInit.storeBits(arrayBits: [splitDepth != nil, ticktock != nil, code != nil, data != nil, library != nil])
        var codeUnnil = false
        var dataUnnil = false
        if code != nil {
            codeUnnil = true
        }
        if data != nil {
            dataUnnil = true
        }
        let _ = try stateInit.storeBits(arrayBits: [splitDepth != nil, ticktock != nil, codeUnnil, dataUnnil, library != nil])

        if codeUnnil {
            let _ = try stateInit.storeRef(c: code!)
        }
        if dataUnnil {
            let _ = try stateInit.storeRef(c: data!)
        }
        if let _library = library {
            let _ = try stateInit.storeRef(c: _library)
        }

        return stateInit.endCell
    }

    public func createStateInit(code: Cell, data: Cell) throws -> Cell {
        return try createStateInit(code: code, data: data, library: nil, splitDepth: nil, ticktock: nil)
    }

    // extra_currencies$_ dict:(HashmapE 32 (VarUInteger 32))
    // = ExtraCurrencyCollection;
    // currencies$_ grams:Grams other:ExtraCurrencyCollection
    // = CurrencyCollection;

    //int_msg_info$0 ihr_disabled:Bool bounce:Bool
    //src:MsgAddressInt dest:MsgAddressInt
    //value:CurrencyCollection ihr_fee:Grams fwd_fee:Grams
    //created_lt:uint64 created_at:uint32 = CommonMsgInfo;

    /**
     * @param dest               Address
     * @param gramValue          BigInt, 0
     * @param ihrDisabled        Bool, true
     * @param bounce             Bool, nil
     * @param bounced            Bool, false
     * @param src                Address, nil
     * @param currencyCollection nil,
     * @param ihrFees            number, 0
     * @param fwdFees            number, 0
     * @param createdLt          number, 0
     * @param createdAt          number, 0
     * @return Cell
     */
    static func createInternalMessageHeader(dest: Address,
                                            gramValue: BigInt,
                                            ihrDisabled: Bool,
                                            bounce: Bool?,
                                            bounced: Bool,
                                            src: Address?,
                                            currencyCollection: Data?,
                                            ihrFees: BigInt,
                                            fwdFees: BigInt,
                                            createdLt: BigInt,
                                            createdAt: BigInt) throws -> Cell {

        let message = CellBuilder.beginCell()
        let _ = try message.storeBit(bit: false)
        let _  = try message.storeBit(bit: ihrDisabled)

        if let _bounce = bounce {
            let _  = try message.storeBit(bit: _bounce)
        } else {
            let _  = try message.storeBit(bit: dest.isBounceable)
        }
        let _  = try message.storeBit(bit: bounced);
        let _  = try message.storeAddress(address: src)
        let _  = try message.storeAddress(address: dest)
        let _  = try message.storeCoins(coins: gramValue)
        guard let _currencyCollection = currencyCollection, _currencyCollection.count == 0 else {
            throw TonError.otherError("Currency collections are not implemented yet")
        }
        let _  = try message.storeBit(bit: _currencyCollection.count != 0)
        let _  = try message.storeCoins(coins: ihrFees)
        let _  = try message.storeCoins(coins: fwdFees)
        let _  = try message.storeUint(number: createdLt, bitLength: 64)
        let _  = try message.storeUint(number: createdAt, bitLength: 32)
        return message.endCell
    }

    func createInternalMessageHeader(dest: String,
                                     gramValue: BigInt,
                                     ihrDisabled: Bool,
                                     bounce: Bool,
                                     bounced: Bool,
                                     src: Address,
                                     currencyCollection: Data,
                                     ihrFees: BigInt,
                                     fwdFees: BigInt,
                                     createdLt: BigInt,
                                     createdAt: BigInt) throws -> Cell {
        return try Contract.createInternalMessageHeader(dest: Address.of(addressStr: dest)!,
                                           gramValue: gramValue,
                                           ihrDisabled: ihrDisabled,
                                           bounce: bounce,
                                           bounced: bounced,
                                           src: src,
                                           currencyCollection: currencyCollection,
                                           ihrFees: ihrFees,
                                           fwdFees: fwdFees,
                                           createdLt: createdLt,
                                           createdAt: createdAt)
    }

    static func createInternalMessageHeader(dest: Address, gramValue: BigInt) throws -> Cell {
        return try createInternalMessageHeader(dest: dest,
                                    gramValue: gramValue,
                                    ihrDisabled: true,
                                    bounce: nil,
                                    bounced: false,
                                    src: nil,
                                    currencyCollection: Data(),
                                    ihrFees: BigInt.zero,
                                    fwdFees: BigInt.zero,
                                    createdLt: BigInt.zero,
                                    createdAt: BigInt.zero)
    }

    static func createInternalMessageHeader(dest: String, gramValue: BigInt) throws -> Cell {
        return try createInternalMessageHeader(dest: Address.of(addressStr: dest)!,
                                    gramValue: gramValue,
                                    ihrDisabled: true,
                                    bounce: nil,
                                    bounced: false,
                                    src: nil,
                                    currencyCollection: nil,
                                    ihrFees: BigInt.zero,
                                    fwdFees: BigInt.zero,
                                    createdLt: BigInt.zero,
                                    createdAt: BigInt.zero)
    }

    /**
     * Message header
     * ext_in_msg_info$10 src:MsgAddressExt dest:MsgAddressInt import_fee:Grams = CommonMsgInfo;
     *
     * @param dest      Address
     * @param src       Address
     * @param importFee BigInt
     * @return Cell
     */
    static func createExternalMessageHeader(dest: Address, src: Address?, importFee: BigInt) throws -> Cell {
        let message = CellBuilder.beginCell()
        let _ = try message.storeUint(number: BigInt(2), bitLength: 2) //bit $10
        let _ = try message.storeAddress(address: src)
        let _ = try message.storeAddress(address: dest)
        let _ = try message.storeCoins(coins: importFee)
        return message
    }

    /**
     * @param dest      String
     * @param src       Address
     * @param importFee number
     * @return Cell
     */
    static func createExternalMessageHeader(dest: String, src: Address, importFee: BigInt) throws -> Cell {
        return try createExternalMessageHeader(dest: Address.of(addressStr: dest)!, src: src, importFee: importFee)
    }

    /**
     * @param dest      String
     * @param src       String
     * @param importFee BigInt
     * @return Cell
     */
    static func createExternalMessageHeader(dest: String, src: String, importFee: BigInt) throws -> Cell {
        return try createExternalMessageHeader(dest: Address.of(addressStr: dest)!, src: Address.of(addressStr: src)!, importFee: importFee)
    }

    static func createExternalMessageHeader(dest: Address) throws -> Cell {
        return try createExternalMessageHeader(dest: dest, src: nil, importFee: BigInt.zero)
    }

    static func createExternalMessageHeader(dest: String) throws -> Cell {
        return try createExternalMessageHeader(dest: Address.of(addressStr: dest)!, src: nil, importFee: BigInt.zero)
    }

    //tblkch.pdf, page 57

    /**
     * Create CommonMsgInfo contains header, stateInit, body
     *
     * @param header    Cell
     * @param stateInit Cell
     * @param body      Cell
     * @return Cell
     */
    static func createCommonMsgInfo(header: Cell, stateInit: Cell?, body: Cell?) throws -> Cell {
        let commonMsgInfo = CellBuilder.beginCell()

        try commonMsgInfo.writeCell(anotherCell: header)

        if let _stateInit = stateInit {
            let _ = try commonMsgInfo.storeBit(bit: true)
            
            if (commonMsgInfo.getFreeBits() - 1 >= _stateInit.bits.getUsedBits()) {
                let _ = try commonMsgInfo.storeBit(bit: false)
                try commonMsgInfo.writeCell(anotherCell: _stateInit)
            } else {
                let _ = try commonMsgInfo.storeBit(bit: true)
                let _ = try commonMsgInfo.storeRef(c: _stateInit)
            }
        } else {
            let _ = try commonMsgInfo.storeBit(bit: false)
        }

        if let _body = body {
            if ((commonMsgInfo.getFreeBits() >= _body.bits.getUsedBits()) && commonMsgInfo.getFreeRefs() >= _body.getUsedRefs()) {
                let _ = try commonMsgInfo.storeBit(bit: false)
                try commonMsgInfo.writeCell(anotherCell: _body)
            } else {
                let _ = try commonMsgInfo.storeBit(bit: true)
                let _ = try commonMsgInfo.storeRef(c: _body)
            }
        } else {
            let _ = try commonMsgInfo.storeBit(bit: false)
        }
        return commonMsgInfo.endCell
    }

    /**
     * Create CommonMsgInfo without body and stateInit
     *
     * @param header Cell
     * @return Cell
     */
    static func createCommonMsgInfo(header: Cell) throws -> Cell {
        return try createCommonMsgInfo(header: header, stateInit: nil, body: nil)
    }
}
