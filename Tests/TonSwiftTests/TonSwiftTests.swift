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
        let keypair = try TonKeypair(mnemonics: "hurry client bike finish produce track present similar excuse heart toast unusual guard praise copy left ski giggle online hurdle yard mountain pony mutual")
        let contract = try TonWallet(walletVersion: WalletVersion.v4R2, options: Options(publicKey: keypair.publicKey, wc: Int64(0))).create()
        print(keypair.publicKey.toHexString())
        print(keypair.secretKey.toHexString())
        print(try! contract.createStateInit().stateInit.toBocBase64())
        print(try! contract.getAddress().toString(isUserFriendly: true, isUrlSafe: true, isBounceable: false))
    }
    
    func testBip39KeypairExample() throws {
        let keypair = try TonKeypair(mnemonics: "arrest salad layer vessel milk record tone cereal physical accident brave vanish", path: "m/44'/607'/0'")
        let contract = try TonWallet(walletVersion: WalletVersion.v4R2, options: Options(publicKey: keypair.publicKey, wc: Int64(0))).create()
        XCTAssertTrue("UQAWguGRJyDl1pX-m2cfrtTDoAiWV47M78vWGVPX7stXPDju" == (try! contract.getAddress().toString(isUserFriendly: true, isUrlSafe: true, isBounceable: false)))
    }
    
    func testClickExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let client = TonClient(url: URL(string: "https://toncenter.com")!,apiKey: "98823dc6054d27fb4608f63c98fdc02f2dfaf3fe6b683e02ca5e9f6939758049")
                let result = try client.getSeqno(address: "EQCVuwSIBGJU0fY4Waw4K2kakJAMayY-E4COTv-L3pfTNVgs").wait()
                debugPrint(result)
                
                reqeustExpectation.fulfill()
            } catch {
                debugPrint(error.localizedDescription)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testEstimateFeeExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let client = TonClient(url: URL(string: "https://toncenter.com/")!,apiKey: "98823dc6054d27fb4608f63c98fdc02f2dfaf3fe6b683e02ca5e9f6939758049")
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
            
            if let data = Data(base64Encoded: "09l3o5W6gtJ++L4d1GORXNWaVdy7XqTLERsjaG42HdC6BtRdG2WlWknfMOGHjkWZxlk4EtW+ZI3yYtG6JQRBioO47sUEIV0I2E2uV8Wu2kJB0TBWjzMmr0l/SBQrwTrs8SsXXlvRZh78U+nxQLKE8xxVVmHJV98on38Gm67LsLV5vEaxQa48WwQk77TSpNehsKb1gq+mliyJWNC2KmdFAGDkkIgWK5WOFWJ1WWrYM4crvmDALW+wNcLjyKZzTbsICgstbyxddDmSQ8TQwGNwGlxgmio9UAETNSlC4+FjGJTlnbdSoGLZQbEd9vJryHfirMZkk0FFvzzcbScsxyjjx5twVHfjswD1vG4puwRy3mb3oZZcycJKU7PWr8EXMaIT0nLFd2NZ5v1hUMXLXpWnSqTreFRbt+DjawYOjB9TjQJ7ZMCv3KEAPAzV8fUNwnIJzpo3xpazNGuI2/xz4kBxbmCjGmGg0m/R0xr7ES+BBZUyo1NymKgCe48fvLf1g8xKzCqfkuAAErzgXqbbUTlQWmufmwGizjASFx9Fu6hoHGjeYR8dAazAnVSY+exLaQuqAFDSz/WCYWPyqKtnt4LDx+u5iGc+sPpgNGxMQC7MPRjdP3quB+JEyeTcy6fHaFKff7wWPOTRe8HepHpOPzPs9WJ95+zzXXwRZtPTUQ1p6Q=="), let app = try? JSONDecoder().decode(TonConnectDappRequest.self, from: data) {
                debugPrint(app.method)
                debugPrint(app.id)
            }
            
            
            let keypair = try TonKeypair(seed: Data(hex: "d2a351c1dcb250fd5380eb4ce3e1d2594c575398fa8d0dadc3987346d5ba453e"))
            let contract: WalletContract = try TonWallet(walletVersion: WalletVersion.v4R2, options: Options(publicKey: keypair.publicKey)).create() as! WalletContract
            let signedMessage = try contract.createSignedTransferMessagePayloadString(secretKey: keypair.secretKey, address: "EQCBlo5osdqQWEc4YRVaMB7DcP5PVm1qKknAmkttUIclyhgS", amount: BigInt("1000000"), seqno: 56, payload: "")
            debugPrint(try signedMessage.message.toBocBase64(hasIdx: false))
        } catch let error {
            debugPrint(error)
        }
    }
    
    func testTonConnectTestExample() throws {
        do {
            let par = TonConnectUrlParser.parseString("tc://?v=2&id=e9d18662a93e4bf10476683be6d820addff73daf8764c452dbdbbd34c9198b15&r=%7B%22manifestUrl%22%3A%22https%3A%2F%2Fton-connect.github.io%2Fdemo-dapp-with-react-ui%2Ftonconnect-manifest.json%22%2C%22items%22%3A%5B%7B%22name%22%3A%22ton_addr%22%7D%2C%7B%22name%22%3A%22ton_proof%22%2C%22payload%22%3A%22eyJhbGciOiJIUzI1NiJ9.eyJwYXlsb2FkIjoiMjExZTQwMzA3MDUzZWY3M2Q2NzY3MWUwZjM2ZDAyNjQ4ZDA3MDQyZDlhOTk0NjNkNmFhZWU4YWU2M2NiMzdhZiIsImlhdCI6MTcxOTIxNzEwMSwiZXhwIjoxNzE5MjE4MDAxfQ.UMk3DRbbuLAePDyPO_NRO1nTDz9hSF6GEEEQKDKDFEQ%22%7D%5D%7D&ret=none")!
            let keypair = try TonKeypair(mnemonics: "")
            let wallet = TonWallet(walletVersion: WalletVersion.v4R2, options: Options(publicKey: keypair.publicKey))
            let address = try wallet.create().getAddress().toString(isUserFriendly: true, isUrlSafe: true, isBounceable: false)
            let contract = ConnectContract(publicKey: keypair.publicKey, addressString: address)
            let reqeustExpectation = expectation(description: "Tests")
            DispatchQueue.global().async {
                do {
                    let connect = TonConnect(parameters: par, keyPair: keypair, address: try wallet.create().getAddress().toString(isUserFriendly: false))
                    connect.connect { isConnect,result  in
                        let body = try! TonConnectServiceBodyBuilder.buildSendTransactionBody(keypair: keypair, seqno: UInt64(1111), sender: try! ConnectAddress.parse(address), parameters: result!.params.first!, contract: contract)
                        debugPrint(body)
                    } failure: { error in
                        
                    }
                } catch let error {
                    debugPrint(error)
                }
            }
            wait(for: [reqeustExpectation], timeout: 300)
        } catch let error {
            debugPrint(error)
        }
    }
}
