//
//  TonError.swift
//  
//
//  Created by xgblin on 2023/2/6.
//

import Foundation

public enum TonError: LocalizedError {
    case providerError(String)
    case keyError(String)
    case otherEror(String)
    case resoultError(String, String)
    case unknow
    
    public var errorDescription: String? {
        switch self {
        case .providerError(let message):
            return message
        case .keyError(let message):
            return message
        case .otherEror(let message):
            return message
        case .resoultError(_, let message):
            return message
        case .unknow:
            return "unknow"
        }
    }
}
