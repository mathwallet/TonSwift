//
//  TonConnectManifest.swift
//
//
//  Created by 薛跃杰 on 2024/6/5.
//

import Foundation

public struct TonConnectManifest: Codable, Equatable {
    public let url: URL?
    public let name: String
    public let iconUrl: URL?
    public let termsOfUseUrl: URL?
    public let privacyPolicyUrl: URL?
    
    init(url: URL?, name: String = "", iconUrl: URL? = nil, termsOfUseUrl: URL? = nil, privacyPolicyUrl: URL? = nil) {
        self.url = url
        self.name = name
        self.iconUrl = iconUrl
        self.termsOfUseUrl = termsOfUseUrl
        self.privacyPolicyUrl = privacyPolicyUrl
    }
    
    public var host: String {
        url?.host ?? ""
    }
}
