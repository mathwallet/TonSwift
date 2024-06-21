//
//  TonConnectTransferMessageBuilder.swift
//
//
//  Created by 薛跃杰 on 2024/6/19.
//

import Foundation
import BigInt

public struct TonConnectTransferBuilder {
    public static func createRequestTransactionBoc(contract: ConnectContract,
                                                   keyPair: TonKeypair,
                                                   seqno: UInt64,
                                                   parameters: TonConnectDappRequest.TonConnectParam) async throws  -> String{
        let payloads = parameters.messages.map { message in
            TonConnectTransferMessageBuilder.Payload(
                value: BigInt(integerLiteral: message.amount),
                recipientAddress: message.address,
                stateInit: message.stateInit,
                payload: message.payload)
        }
        return try TonConnectTransferMessageBuilder.sendTonConnectTransfer(
            contract: contract,
            keyPair: keyPair,
            seqno: seqno,
            payloads: payloads,
            sender: parameters.from)
    }
}

public struct TonConnectTransferMessageBuilder {
  
  public struct Payload {
    let value: BigInt
    let recipientAddress: ConnectAddress
    let stateInit: String?
    let payload: String?
    
    public init(value: BigInt,
                recipientAddress: ConnectAddress,
                stateInit: String?,
                payload: String?) {
      self.value = value
      self.recipientAddress = recipientAddress
      self.stateInit = stateInit
      self.payload = payload
    }
  }
  
  public static func sendTonConnectTransfer(contract: ConnectContract,
                                            keyPair: TonKeypair,
                                            seqno: UInt64,
                                            payloads: [Payload],
                                            sender: ConnectAddress? = nil) throws -> String {
    let messages = try payloads.map { payload in
      var stateInit: ConnectStateInit?
      if let stateInitString = payload.stateInit {
          stateInit = try ConnectStateInit.loadFrom(
          slice: try ConnectCell
            .fromBase64(src: stateInitString)
            .toSlice()
        )
      }
      var body: ConnectCell = .empty
      if let messagePayload = payload.payload {
        body = try ConnectCell.fromBase64(src: messagePayload)
      }
      return MessageRelaxed.internal(
        to: payload.recipientAddress,
        value: payload.value.magnitude,
        bounce: false,
        stateInit: stateInit,
        body: body)
    }
    return try ExternalMessageTransferBuilder
      .externalMessageTransfer(
        contract: contract,
        sender: sender ?? (contract.address),
        keyPair: keyPair,
        seqno: seqno, internalMessages: { sender in
          messages
        })
  }
}


public struct ExternalMessageTransferBuilder {
  public static func externalMessageTransfer(contract: ConnectContract,
                                             sender: ConnectAddress,
                                             keyPair: TonKeypair,
                                             sendMode: SendMode = .walletDefault(),
                                             seqno: UInt64,
                                             internalMessages: (_ sender: ConnectAddress) throws -> [MessageRelaxed]) throws -> String {
    let internalMessages = try internalMessages(sender)
    let transferData = WalletTransferData(
      seqno: seqno,
      messages: internalMessages,
      sendMode: sendMode,
      timeout: nil)
    let transfer = try contract.createTransfer(args: transferData)
      let signedData = try keyPair.signData(data: transfer.endCell().hash())
    let body = ConnectBuilder()
    try body.store(data: signedData)
    try body.store(transfer)
    let transferCell = try body.endCell()
    
    let externalMessage = ConnectMessage.external(to: sender,
                                           stateInit: contract.stateInit,
                                           body: transferCell)
    let cell = try ConnectBuilder().store(externalMessage).endCell()
    return try cell.toBoc().base64EncodedString()
  }
}
