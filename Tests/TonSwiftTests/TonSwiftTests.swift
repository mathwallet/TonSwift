import XCTest
import BigInt
@testable import TonSwift

final class TonSwiftTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        var aa = Mnemonics.generate(count: 24, password: "")
        let ss = Mnemonics.isValid(aa, password:"")
        do {
            let keypair = try TonKeypair.randomKeyPair()
            let contract = try WalletV4ContractR2(options: Options(publicKey: keypair.publicKey, wc: Int64(0)))
            debugPrint(try contract!.getAddress().toString(isUserFriendly: true, isUrlSafe: true, isBounceable: true))
        } catch let e {
            print(e)
        }
    }
    
    func testClickExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let client = TonClient(url: URL(string: "https://toncenter.com/")!)
                let result = try client.getChainInfo().wait()
                debugPrint(result)
                
                reqeustExpectation.fulfill()
            } catch {
                //debugPrint(error.localizedDescription)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testAddressExample() throws {
        do {
            let address = Address(addressStr: "EQCBlo5osdqQWEc4YRVaMB7DcP5PVm1qKknAmkttUIclyhgS")
        } catch {
            
        }
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
