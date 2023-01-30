//
//  DeserializeCellDataResult.swift
//  
//
//  Created by 薛跃杰 on 2023/1/6.
//

import Foundation

public struct DeserializeCellDataResult {
    let cell: Cell
    let cellsData: Data

    public init(cell: Cell, cellsData: Data) {
        self.cell = cell;
        self.cellsData = cellsData;
    }
}
