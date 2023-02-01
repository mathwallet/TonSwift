import XCTest
@testable import TonSwift

final class TonSwiftTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        let keypair = try TonKeypair(seed: Data(hex: "d2a351c1dcb250fd5380eb4ce3e1d2594c575398fa8d0dadc3987346d5ba453e"))
        do {
            let contract = try WalletV4ContractR2(options: Options(publicKey: keypair.publicKey, wc: Int64(0)))
            debugPrint(try contract!.getAddress().toString())
        } catch let e {
            print(e)
        }
        
    }
}
