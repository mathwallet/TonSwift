//
//  BitStringParser.swift
//  
//
//  Created by 薛跃杰 on 2023/1/12.
//

import Foundation

public struct BitStringParser {
    var bitString: BitString
    var key: String {
        return "\(bitString.array.toHexString()),\(bitString.writeCursor),\(bitString.readCursor),\(bitString.length)"
    }
    init(bitString: BitString) {
        self.bitString = bitString
    }
    init(key: String) {
        let variables = key.components(separatedBy: ",")
        bitString = BitString(array: Data(hex: variables[0] ?? "0x"), writeCursor: Int(variables[1] ?? "0")!, readCursor: Int(variables[2] ?? "0")!, length: Int(variables[3] ?? "0")!)
    }
}
