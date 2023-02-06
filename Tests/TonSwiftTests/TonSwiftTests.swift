import XCTest
@testable import TonSwift

final class TonSwiftTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        let keypair = try TonKeypair(mnemonics: "speak intact staff better relief amount bamboo marble scrap advance dice legal alter portion mean father law coffee income moral resource pull there slice", path: "")
        do {
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
                let client = TonClient(url: URL(string: "https://toncenter.com/api/v2/jsonRPC")!)
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
}
