//
//  TonError.swift
//  
//
//  Created by 薛跃杰 on 2023/1/6.
//

import Foundation

public enum TonError: LocalizedError {
    case message(String)
    case unknow
    
    public var errorDescription: String? {
        switch self {
        case .message(let message):
            return message
        case .unknow:
            return "unknow"
        }
    }
    
}
