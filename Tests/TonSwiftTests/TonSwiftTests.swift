import XCTest
@testable import TonSwift

final class TonSwiftTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        let keypair = try TonKeypair.randomKeyPair()
        print(keypair.mnemonics!)
        print("publickey: \(keypair.publicKey.toHexString())")
        print("secrtkey: \(keypair.secretKey.toHexString())")
    }
}
