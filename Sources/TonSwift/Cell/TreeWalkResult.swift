//
//  TreeWalkResult.swift
//  
//
//  Created by xgblin on 2023/1/6.
//

import Foundation

public struct TreeWalkResult {
    let topologicalOrderArray: [TopologicalOrderArray]
    let indexHashmap: [String: UInt64]
    
    public init(topologicalOrderArray: [TopologicalOrderArray], indexHashmap: [String: UInt64]) {
        self.topologicalOrderArray = topologicalOrderArray
        self.indexHashmap = indexHashmap
    }
}
