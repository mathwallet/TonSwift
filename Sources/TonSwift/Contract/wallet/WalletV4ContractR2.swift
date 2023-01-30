//
//  WalletV4ContractR2.swift
//  
//
//  Created by 薛跃杰 on 2023/1/29.
//

import Foundation
import BigInt

public class WalletV4ContractR2: WalletContract {
    public var address: Address?
    
    public static let V4_R1_CODE_HEX = "B5EE9C72410214010002D4000114FF00F4A413F4BCF2C80B010201200203020148040504F8F28308D71820D31FD31FD31F02F823BBF264ED44D0D31FD31FD3FFF404D15143BAF2A15151BAF2A205F901541064F910F2A3F80024A4C8CB1F5240CB1F5230CBFF5210F400C9ED54F80F01D30721C0009F6C519320D74A96D307D402FB00E830E021C001E30021C002E30001C0039130E30D03A4C8CB1F12CB1FCBFF1011121302E6D001D0D3032171B0925F04E022D749C120925F04E002D31F218210706C7567BD22821064737472BDB0925F05E003FA403020FA4401C8CA07CBFFC9D0ED44D0810140D721F404305C810108F40A6FA131B3925F07E005D33FC8258210706C7567BA923830E30D03821064737472BA925F06E30D06070201200809007801FA00F40430F8276F2230500AA121BEF2E0508210706C7567831EB17080185004CB0526CF1658FA0219F400CB6917CB1F5260CB3F20C98040FB0006008A5004810108F45930ED44D0810140D720C801CF16F400C9ED540172B08E23821064737472831EB17080185005CB055003CF1623FA0213CB6ACB1FCB3FC98040FB00925F03E20201200A0B0059BD242B6F6A2684080A06B90FA0218470D4080847A4937D29910CE6903E9FF9837812801B7810148987159F31840201580C0D0011B8C97ED44D0D70B1F8003DB29DFB513420405035C87D010C00B23281F2FFF274006040423D029BE84C600201200E0F0019ADCE76A26840206B90EB85FFC00019AF1DF6A26840106B90EB858FC0006ED207FA00D4D422F90005C8CA0715CBFFC9D077748018C8CB05CB0222CF165005FA0214CB6B12CCCCC973FB00C84014810108F451F2A7020070810108D718FA00D33FC8542047810108F451F2A782106E6F746570748018C8CB05CB025006CF165004FA0214CB6A12CB1FCB3FC973FB0002006C810108D718FA00D33F305224810108F459F2A782106473747270748018C8CB05CB025005CF165003FA0213CB6ACB1F12CB3FC973FB00000AF400C9ED54696225E5"
    
    public init?(options: Options) {
        super.init()
        self.options = options
        do {
            self.options?.code = try TonSwift.Cell.fromBoc(serializedBoc: TonSwift.WalletV4ContractR2.V4_R1_CODE_HEX)
            if let _ = options.walletId {} else {
                self.options?.walletId = 698983191 + options.wc!
            }
        } catch {
            return nil
        }
    }
    
    public override func getName() -> String {
        return "v4R2"
    }
    
    public override func  getOptions() -> Options {
        return options!
    }
    public override func getAddress() throws -> Address {
        if let _address = address {
            return _address
        } else {
            let stateInit = try createStateInit()
            return stateInit.address
        }
    }
    
    public override func createDataCell() throws -> Cell {
        let cell = CellBuilder.beginCell()
        let _ = try cell.storeUint(number: BigInt.zero, bitLength: 32)
        let _ = try cell.storeUint(number: BigInt(getOptions().walletId!), bitLength: 32)
        let _ = try cell.storeBytes(bytes: getOptions().publicKey!.bytes)
        let _ = try cell.storeUint(number: BigInt.zero, bitLength: 1) //plugins dict empty
        return cell.endCell
    }
    
    public override  func createSigningMessage(seqno: Int64) throws -> Cell  {
        return try createSigningMessage(seqno: seqno, withoutOp:false)
    }
    
    /**
     * @param seqno     Int64
     * @param withoutOp Bool
     * @return Cell
     */
    
    public func createSigningMessage(seqno: Int64, withoutOp: Bool) throws -> Cell {
        
        let message = CellBuilder.beginCell()
        
        let _ = try message.storeUint(number: BigInt(getOptions().walletId!), bitLength: 32)
        
        if (seqno == 0) {
            for _ in 0..<32 {
                let _ = try message.storeBit(bit: true)
            }
        } else {
            let timeInterval = Date().timeIntervalSince1970
            let timestamp = Int64(floor(timeInterval / 1e3))
            let _ = try message.storeUint(number: BigInt(timestamp + 60), bitLength: 32)
        }
        
        let _ = try message.storeUint(number: BigInt(seqno), bitLength: 32)
        
        if (!withoutOp) {
            try message.storeUint(number: BigInt.zero, bitLength: 8) // op
        }
        
        return message.endCell
    }
    
    //    /**
    //     * Deploy and install/assigns subscription plugin.
    //     * One can also deploy plugin separately and later install into the wallet. See installPlugin().
    //     *
    //     * @param params NewPlugin
    //     */
    //    public func deployAndInstallPlugin(tonlib:Tonlib, NewPlugin params) {
    //
    //        Cell signingMessage = createSigningMessage(params.seqno, true)
    //        signingMessage.bits.writeUint(BigInt.ONE, 8) // op
    //        signingMessage.bits.writeInt(BigInt(params.pluginWc), 8)
    //        signingMessage.bits.writeCoins(params.amount) // plugin balance
    //        signingMessage.refs.add(params.stateInit)
    //        signingMessage.refs.add(params.body)
    //        ExternalMessage extMsg = createExternalMessage(signingMessage, params.secretKey, params.seqno, false)
    //
    //        tonlib.sendRawMessage(extMsg.message.toBocBase64(false))
    //    }
    
    public func createPluginStateInit() throws -> Cell {
        // code = boc in hex format, result of fift commands:
        //      "subscription-plugin-code.fif" include
        //      2 boc+>B dup Bx. cr
        // boc of subscription contract
        let code = try TonSwift.Cell.fromBoc(serializedBoc: "B5EE9C7241020F01000262000114FF00F4A413F4BCF2C80B0102012002030201480405036AF230DB3C5335A127A904F82327A128A90401BC5135A0F823B913B0F29EF800725210BE945387F0078E855386DB3CA4E2F82302DB3C0B0C0D0202CD06070121A0D0C9B67813F488DE0411F488DE0410130B048FD6D9E05E8698198FD201829846382C74E2F841999E98F9841083239BA395D497803F018B841083AB735BBED9E702984E382D9C74688462F863841083AB735BBED9E70156BA4E09040B0A0A080269F10FD22184093886D9E7C12C1083239BA39384008646582A803678B2801FD010A65B5658F89659FE4B9FD803FC1083239BA396D9E40E0A04F08E8D108C5F0C708210756E6B77DB3CE00AD31F308210706C7567831EB15210BA8F48305324A126A904F82326A127A904BEF27109FA4430A619F833D078D721D70B3F5260A11BBE8E923036F82370708210737562732759DB3C5077DE106910581047103645135042DB3CE0395F076C2232821064737472BA0A0A0D09011A8E897F821064737472DB3CE0300A006821B39982100400000072FB02DE70F8276F118010C8CB055005CF1621FA0214F40013CB6912CB1F830602948100A032DEC901FB000030ED44D0FA40FA40FA00D31FD31FD31FD31FD31FD307D31F30018021FA443020813A98DB3C01A619F833D078D721D70B3FA070F8258210706C7567228018C8CB055007CF165004FA0215CB6A12CB1F13CB3F01FA02CB00C973FB000E0040C8500ACF165008CF165006FA0214CB1F12CB1FCB1FCB1FCB1FCB07CB1FC9ED54005801A615F833D020D70B078100D1BA95810088D721DED307218100DDBA028100DEBA12B1F2E047D33F30A8AB0FE5855AB4")
        let wallet = try getAddress()
        guard let _options = options, let subscriptionConfig = _options.subscriptionConfig else {
            throw TonError.message("contract options nil")
        }
        let data = try createPluginDataCell(wallet: wallet,
                                            beneficiary: subscriptionConfig.beneficiary,
                                            amount: subscriptionConfig.subscriptionFee,
                                            period: subscriptionConfig.period,
                                            startTime: subscriptionConfig.startTime,
                                            timeOut: subscriptionConfig.timeOut,
                                            lastPaymentTime: subscriptionConfig.lastPaymentTime,
                                            lastRequestTime: subscriptionConfig.lastRequestTime,
                                            failedAttempts: subscriptionConfig.failedAttempts,
                                            subscriptionId: subscriptionConfig.subscriptionId)
        return try createStateInit(code: code, data: data)
    }
    
    public func createPluginBody() throws -> Cell {
        let body = CellBuilder.beginCell() // mgsBody in simple-subscription-plugin.fc is not used
        let l = BigInt("706c7567", radix: 16) ?? BigInt(0)
        let r = BigInt("80000000", radix: 16) ?? BigInt(0)
        let _ = try body.storeUint(number: l + r , bitLength: 32)
        return body.endCell
    }
    
    public func createPluginSelfDestructBody() throws -> Cell {
        return try CellBuilder.beginCell().storeUint(number: 0x64737472, bitLength: 32).endCell
    }
    
    /**
     * @param params    DeployedPlugin,
     * @param isInstall Bool install or uninstall
     */
    func setPlugin(params: DeployedPlugin, isInstall: Bool) throws -> ExternalMessage {
        
        let signingMessage = try createSigningMessage(seqno: params.seqno, withoutOp: true)
        try signingMessage.bits.writeUInt(number: isInstall ? BigInt(2) : BigInt(3), bitLength: 8)
        try signingMessage.bits.writeInt(number: BigInt(params.pluginAddress.wc), bitLength: 8)
        try signingMessage.bits.writeBytes(ui8s: params.pluginAddress.hashPart.bytes)
        try signingMessage.bits.writeCoins(amount: params.amount)
        try signingMessage.bits.writeUInt(number: BigInt(params.queryId), bitLength: 64)
        
        return try createExternalMessage(signingMessage: signingMessage,
                                         secretKey: params.secretKey,
                                         seqno: params.seqno,
                                         dummySignature: false)
    }
    
    /**
     * Installs/assigns plugin into wallet-v4
     *
     * @param params DeployedPlugin
     */
    public func installPlugin(params: DeployedPlugin) throws -> ExternalMessage {
        return try setPlugin(params: params, isInstall: true)
    }
    
    /**
     * Uninstalls/removes plugin from wallet-v4
     *
     * @param params DeployedPlugin
     */
    public func removePlugin(params: DeployedPlugin) throws -> ExternalMessage {
        return try setPlugin(params: params, isInstall: false)
    }
    
    
    //    /**
    //     * @return subwallet-id Int64
    //     */
    //    public func getWalletId(Tonlib tonlib) -> Int64 {
    //
    //        Address myAddress = getAddress()
    //        RunResult result = tonlib.runMethod(myAddress, "get_subwallet_id")
    //        TvmStackEntryNumber subWalletId = (TvmStackEntryNumber) result.getStack().get(0)
    //
    //        return subWalletId.getNumber().Int64Value()
    //    }
    //
    //        public Data getPublicKey(Tonlib tonlib) {
    //            Address myAddress = getAddress()
    //            RunResult result = tonlib.runMethod(myAddress, "get_public_key")
    //            TvmStackEntryNumber pubKey = (TvmStackEntryNumber) result.getStack().get(0)
    //
    //            return pubKey.getNumber().toByteArray()
    //        }
    
    /**
     * @param pluginAddress Address
     * @return Bool
     */
    //        public Bool isPluginInstalled(Tonlib tonlib, Address pluginAddress) {
    //            String hashPart = new BigInt(pluginAddress.hashPart).toString()
    //
    //            Address myAddress = getAddress()
    //
    //            Deque<String> stack = new ArrayDeque<>()
    //            stack.offer("[num, " + pluginAddress.wc + "]")
    //            stack.offer("[num, " + hashPart + "]")
    //
    //            RunResult result = tonlib.runMethod(myAddress, "is_plugin_installed", stack)
    //            TvmStackEntryNumber resultNumber = (TvmStackEntryNumber) result.getStack().get(0)
    //
    //            return resultNumber.getNumber().Int64Value() != 0
    //        }
    //
    //        /**
    //         * @return List<String> plugins addresses
    //         */
    //        public List<String> getPluginsList(Tonlib tonlib) {
    //            List<String> r = new ArrayList<>()
    //            Address myAddress = getAddress()
    //            RunResult result = tonlib.runMethod(myAddress, "get_plugin_list")
    //            TvmStackEntryList list = (TvmStackEntryList) result.getStack().get(0)
    //            for (Object o : list.getList().getElements()) {
    //                TvmStackEntryTuple t = (TvmStackEntryTuple) o
    //                TvmTuple tuple = t.getTuple()
    //                TvmStackEntryNumber wc = (TvmStackEntryNumber) tuple.getElements().get(0) // 1 byte
    //                TvmStackEntryNumber addr = (TvmStackEntryNumber) tuple.getElements().get(1) // 32 bytes
    //                r.add(wc.getNumber() + ":" + addr.getNumber().toString(16).toUpperCase())
    //            }
    //            return r
    //        }
    //
    //        /**
    //         * Get subscription data of the specified plugin
    //         *
    //         * @return TvmStackEntryList
    //         */
    //        public SubscriptionInfo getSubscriptionData(Tonlib tonlib, Address pluginAddress) {
    //
    //            RunResult result = tonlib.runMethod(pluginAddress, "get_subscription_data")
    //            if (result.getExit_code() == 0) {
    //                return parseSubscriptionData(result.getStack())
    //            } else {
    //                throw new Error("Error executing get_subscription_data. Exit code " + result.getExit_code())
    //
    //            }
    //        }
    
    public func createPluginDataCell(wallet: Address,
                                     beneficiary: Address,
                                     amount: BigInt,
                                     period: Int64,
                                     startTime: Int64,
                                     timeOut: Int64,
                                     lastPaymentTime: Int64,
                                     lastRequestTime: Int64,
                                     failedAttempts: Int64,
                                     subscriptionId: Int64) throws -> Cell {
        
        let cell = CellBuilder.beginCell()
        let _ = try cell.storeAddress(address: wallet)
        let _ = try cell.storeAddress(address: beneficiary)
        let _ = try cell.storeCoins(coins: amount)
        let _ = try cell.storeUint(number:BigInt(period) , bitLength: 32)
        let _ = try cell.storeUint(number: BigInt(startTime), bitLength: 32)
        let _ = try cell.storeUint(number: BigInt(timeOut), bitLength: 32)
        let _ = try cell.storeUint(number: BigInt(lastPaymentTime), bitLength: 32)
        let _ = try cell.storeUint(number: BigInt(lastRequestTime), bitLength: 32)
        let _ = try cell.storeUint(number: BigInt(failedAttempts), bitLength: 8)
        let _ = try cell.storeUint(number: BigInt(subscriptionId), bitLength: 32)
        return cell.endCell
    }
    
    //        private SubscriptionInfo parseSubscriptionData(List subscriptionData) {
    //            TvmStackEntryTuple walletAddr = (TvmStackEntryTuple) subscriptionData.get(0)
    //            TvmStackEntryNumber wc = (TvmStackEntryNumber) walletAddr.getTuple().getElements().get(0)
    //            TvmStackEntryNumber hash = (TvmStackEntryNumber) walletAddr.getTuple().getElements().get(1)
    //            TvmStackEntryTuple beneficiaryAddr = (TvmStackEntryTuple) subscriptionData.get(1)
    //            TvmStackEntryNumber beneficiaryAddrWc = (TvmStackEntryNumber) beneficiaryAddr.getTuple().getElements().get(0)
    //            TvmStackEntryNumber beneficiaryAddrHash = (TvmStackEntryNumber) beneficiaryAddr.getTuple().getElements().get(1)
    //            TvmStackEntryNumber amount = (TvmStackEntryNumber) subscriptionData.get(2)
    //            TvmStackEntryNumber period = (TvmStackEntryNumber) subscriptionData.get(3)
    //            TvmStackEntryNumber startTime = (TvmStackEntryNumber) subscriptionData.get(4)
    //            TvmStackEntryNumber timeOut = (TvmStackEntryNumber) subscriptionData.get(5)
    //            TvmStackEntryNumber lastPaymentTime = (TvmStackEntryNumber) subscriptionData.get(6)
    //            TvmStackEntryNumber lastRequestTime = (TvmStackEntryNumber) subscriptionData.get(7)
    //
    //            Int64 now = System.currentTimeMillis() / 1000
    //            Bool isPaid = ((now - lastPaymentTime.getNumber().Int64Value()) < period.getNumber().Int64Value())
    //            Bool paymentReady = !isPaid & ((now - lastRequestTime.getNumber().Int64Value()) > timeOut.getNumber().Int64Value())
    //
    //            TvmStackEntryNumber failedAttempts = (TvmStackEntryNumber) subscriptionData.get(8)
    //            TvmStackEntryNumber subscriptionId = (TvmStackEntryNumber) subscriptionData.get(9)
    //
    //            return SubscriptionInfo.builder()
    //                    .walletAddress(Address.of(wc.getNumber() + ":" + hash.getNumber().toString(16)))
    //                    .beneficiary(Address.of(beneficiaryAddrWc.getNumber() + ":" + beneficiaryAddrHash.getNumber().toString(16)))
    //                    .subscriptionFee(amount.getNumber())
    //                    .period(period.getNumber().Int64Value())
    //                    .startTime(startTime.getNumber().Int64Value())
    //                    .timeOut(timeOut.getNumber().Int64Value())
    //                    .lastPaymentTime(lastPaymentTime.getNumber().Int64Value())
    //                    .lastRequestTime(lastRequestTime.getNumber().Int64Value())
    //                    .isPaid(isPaid)
    //                    .isPaymentReady(paymentReady)
    //                    .failedAttempts(failedAttempts.getNumber().Int64Value())
    //                    .subscriptionId(subscriptionId.getNumber().Int64Value())
    //                    .build()
    //        }
}
