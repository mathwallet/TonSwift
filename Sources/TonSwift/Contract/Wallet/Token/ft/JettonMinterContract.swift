//
//  Contract.swift
//  
//
//  Created by xgblin on 2023/2/14.
//

import Foundation
import BigInt

public class JettonMinterContract: Contract {

    public static let JETTON_MINTER_CODE_HEX = "B5EE9C7241020B010001ED000114FF00F4A413F4BCF2C80B0102016202030202CC040502037A60090A03EFD9910E38048ADF068698180B8D848ADF07D201800E98FE99FF6A2687D007D206A6A18400AA9385D47181A9AA8AAE382F9702480FD207D006A18106840306B90FD001812881A28217804502A906428027D012C678B666664F6AA7041083DEECBEF29385D71811A92E001F1811802600271812F82C207F97840607080093DFC142201B82A1009AA0A01E428027D012C678B00E78B666491646580897A007A00658064907C80383A6465816503E5FFE4E83BC00C646582AC678B28027D0109E5B589666664B8FD80400FE3603FA00FA40F82854120870542013541403C85004FA0258CF1601CF16CCC922C8CB0112F400F400CB00C9F9007074C8CB02CA07CBFFC9D05008C705F2E04A12A1035024C85004FA0258CF16CCCCC9ED5401FA403020D70B01C3008E1F8210D53276DB708010C8CB055003CF1622FA0212CB6ACB1FCB3FC98042FB00915BE200303515C705F2E049FA403059C85004FA0258CF16CCCCC9ED54002E5143C705F2E049D43001C85004FA0258CF16CCCCC9ED54007DADBCF6A2687D007D206A6A183618FC1400B82A1009AA0A01E428027D012C678B00E78B666491646580897A007A00658064FC80383A6465816503E5FFE4E840001FAF16F6A2687D007D206A6A183FAA904051007F09"

    var address: Address?

    /**
     * @param options Options
     */
    public init?(options: Options) throws {
        super.init()
        self.options = options
        self.options!.wc = 0
        if let _address = options.address {
            self.address = _address
        }
        if let _ = options.code {} else {
            self.options?.code = try TonSwift.Cell.fromBoc(serializedBoc: JettonMinterContract.JETTON_MINTER_CODE_HEX)
        }
    }

    public func getName() -> String {
        return "jettonMinter"
    }
    
    public override func getOptions() -> Options {
        return options!
    }

    public override func getAddress() throws -> Address {
        if let _address = self.address {
            return _address
        } else {
            let stateInit = try createStateInit()
            return stateInit.address
        }
    }

    /**
     * @return Cell cell - contains jetton data cell
     */
    public override func createDataCell() throws -> Cell {
        let cell = CellBuilder.beginCell()
        let _ = try cell.storeCoins(coins: BigInt.zero)
        let _ = try cell.storeAddress(address: options!.adminAddress)
        let _ = try cell.storeRef(c: NftUtils.createOffchainUriCell(uri: options!.jettonContentUri ?? ""))
        let _ = try cell.storeRef(c: Cell.fromBoc(serializedBoc: options!.jettonWalletCodeHex ?? ""))
        return cell.endCell
    }

    /**
     * @param queryId      long
     * @param destination  Address
     * @param amount       BigInteger
     * @param jettonAmount BigInteger
     * @return Cell
     */
    public func createMintBody(queryId: Int64, destination: Address, amount: BigInt, jettonAmount: BigInt) throws -> Cell {
        return try createMintBody(queryId: queryId, destination: destination, amount: amount, jettonAmount: jettonAmount, fromAddress: nil, responseAddress: nil, forwardAmount: BigInt.zero)
    }

    /**
     * @param queryId         long
     * @param destination     Address
     * @param amount          BigInteger
     * @param jettonAmount    BigInteger
     * @param fromAddress     Address
     * @param responseAddress Address
     * @param forwardAmount   BigInteger
     * @return Cell
     */
    public func createMintBody(queryId: Int64, destination: Address, amount: BigInt, jettonAmount: BigInt, fromAddress: Address?, responseAddress: Address?, forwardAmount: BigInt) throws -> Cell {
        let body = CellBuilder.beginCell()
        let _ = try body.storeUint(number: 21, bitLength: 32) // OP mint
        let _ = try body.storeUint(number: queryId, bitLength: 64) // query_id, default 0
        let _ = try body.storeAddress(address: destination)
        let _ = try body.storeCoins(coins: amount)

        let transferBody = CellBuilder.beginCell() // internal transfer
        let _ = try transferBody.storeUint(number: 0x178d4519, bitLength: 32) // internal_transfer op
        let _ = try transferBody.storeUint(number:queryId,bitLength: 64) // default 0
        let _ = try transferBody.storeCoins(coins: jettonAmount)
        let _ = try transferBody.storeAddress(address: fromAddress) // from_address
        let _ = try transferBody.storeAddress(address: responseAddress) // response_address
        let _ = try transferBody.storeCoins(coins: forwardAmount) // forward_amount
        let _ = try transferBody.storeBit(bit: false) // forward_payload in self slice, not separate cell

        let _ = try body.storeRef(c: transferBody)

        return body
    }

    /**
     * @param queryId         long
     * @param newAdminAddress Address
     * @return Cell
     */
    public func createChangeAdminBody(queryId: Int64, newAdminAddress: Address?) throws -> Cell{
        guard let _ = newAdminAddress else {
            throw TonError.otherError("Specify newAdminAddress")
        }

        let body = CellBuilder.beginCell()
        let _ = try body.storeUint(number: 3, bitLength: 32) // OP
        let _ = try body.storeUint(number: queryId, bitLength: 64) // query_id
        let _ = try body.storeAddress(address: newAdminAddress)
        return body
    }

    /**
     * @param jettonContentUri: String
     * @param queryId           long
     * @return Cell
     */
    public func createEditContentBody(jettonContentUri: String, queryId: Int64) throws -> Cell {
        let body = CellBuilder.beginCell()
        let _ = try body.storeUint(number: 4, bitLength: 32) // OP change content
        let _ = try body.storeUint(number: queryId, bitLength: 64) // query_id
        let _ = try body.storeRef(c: NftUtils.createOffchainUriCell(uri: jettonContentUri))
        return body
    }
}
