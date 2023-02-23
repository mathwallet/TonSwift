import XCTest
import BigInt
@testable import TonSwift

final class TonSwiftTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
    }
    
    func testKeypairExample() throws {
        let keypair = try TonKeypair(seed: Data(hex: "d2a351c1dcb250fd5380eb4ce3e1d2594c575398fa8d0dadc3987346d5ba453e"))
        let contract = try TonWallet(walletVersion: WalletVersion.v4R2, options: Options(publicKey: keypair.publicKey, wc: Int64(0))).create()
        print(keypair.publicKey.toHexString())
        print(keypair.secretKey.toHexString())
        print(try! contract.createStateInit().stateInit.toBocBase64())
        print(try! contract.getAddress().toString(isUserFriendly: true, isUrlSafe: true, isBounceable: true))
    }
    
    func testClickExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let client = TonClient(url: URL(string: "https://toncenter.com")!,apiKey: "")
                let result = try client.getSeqno(address: "EQCVuwSIBGJU0fY4Waw4K2kakJAMayY-E4COTv-L3pfTNVgs").wait()
                debugPrint(result)
                
                reqeustExpectation.fulfill()
            } catch {
                //debugPrint(error.localizedDescription)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testEstimateFeeExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let client = TonClient(url: URL(string: "https://toncenter.com/")!,apiKey: "")
                let keypair = try TonKeypair(seed: Data(hex: "d2a351c1dcb250fd5380eb4ce3e1d2594c575398fa8d0dadc3987346d5ba453e"))
                let contract: WalletContract = try TonWallet(walletVersion: WalletVersion.v4R2, options: Options(publicKey: keypair.publicKey)).create() as! WalletContract
                let externalMessage = try contract.createSignedTransferMessagePayloadString(secretKey: Data(count: 64), address: "EQCBlo5osdqQWEc4YRVaMB7DcP5PVm1qKknAmkttUIclyhgS", amount: BigInt("1000000"), seqno: 9, payload: "123")
                let result = try client.getEstimateFee(from: try contract.getAddress().toString(isUserFriendly: true, isUrlSafe: true, isBounceable: true), externalMessage: externalMessage).wait()
                debugPrint(result)
            } catch let error {
                debugPrint(error)
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)

    }
    
    func testFtTokenExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let client = TonClient(url: URL(string: "https://toncenter.com")!,apiKey: "")
                let result = try client.getJettonWalletAddress(ownerAddress: "EQCVuwSIBGJU0fY4Waw4K2kakJAMayY-E4COTv-L3pfTNVgs", mintAddress: "EQBlqsm144Dq6SjbPI4jjZvA1hqTIP3CvHovbIfW_t-SCALE").wait()
                let balance = try client.getAddressBalance(address: result).wait()
                debugPrint(result)
                debugPrint(balance)
            } catch let error {
                debugPrint(error)
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)

    }

    
    func testTransactionExample() throws {
        do {
            let keypair = try TonKeypair(seed: Data(hex: "d2a351c1dcb250fd5380eb4ce3e1d2594c575398fa8d0dadc3987346d5ba453e"))
            let contract: WalletContract = try TonWallet(walletVersion: WalletVersion.v4R2, options: Options(publicKey: keypair.publicKey)).create() as! WalletContract
            let signedMessage = try contract.createSignedTransferMessagePayloadString(secretKey: keypair.secretKey, address: "EQCBlo5osdqQWEc4YRVaMB7DcP5PVm1qKknAmkttUIclyhgS", amount: BigInt("1000000"), seqno: 9, payload: "123")
            debugPrint(try signedMessage.message.toBocBase64())
        } catch let error {
            debugPrint(error)
        }
    }
    
}
