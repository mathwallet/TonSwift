//
//  TonConnectUrlParser.swift
//
//
//  Created by xgblin on 2024/6/4.
//

import Foundation

public struct TonConnectUrlParser {
    public static func parseString(_ urlString: String) -> TonConnectParameters? {
        guard let url = URL(string: urlString),
              let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let v = urlComponents.queryItems?.first(where: { $0.name == "v" })?.value,
              let id = urlComponents.queryItems?.first(where: { $0.name == "id" })?.value,
              let r = urlComponents.queryItems?.first(where: { $0.name == "r" })?.value,
              let rdata = r.data(using: .utf8),
              let payload = try? JSONDecoder().decode(TonConnectRequestPayload.self, from: rdata) else {
            return nil
        }
        return TonConnectParameters(version: v, clientId: id, payload: payload)
    }
}

