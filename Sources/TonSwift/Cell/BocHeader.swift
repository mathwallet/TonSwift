//
//  BocHeader.swift
//  
//
//  Created by 薛跃杰 on 2023/1/5.
//

import Foundation

public struct BocHeader {
    let has_idx: Int
    let hash_crc32: Int
    let has_cache_bits: Int
    let flags: Int
    let size_bytes: Int
    let off_bytes: Int
    let cells_num: Int
    let roots_num: Int
    let absent_num: Int
    let tot_cells_size: Int
    let root_list: [Int]
    let index: [Int]
    let cells_data: Data
}
