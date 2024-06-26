//
//  TonConnectUrlParser.swift
//
//
//  Created by 薛跃杰 on 2024/6/4.
//

import Foundation

public struct TonConnectUrlParser {
    public static func parseString(_ urlString: String, success: @escaping (_ parameters: TonConnectParameters, _ manifestResult: ManifestResult) -> Void, failure: @escaping (_ error: TonError) -> Void) {
        guard let url = URL(string: urlString),
              let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let v = urlComponents.queryItems?.first(where: { $0.name == "v" })?.value,
              let id = urlComponents.queryItems?.first(where: { $0.name == "id" })?.value,
              let r = urlComponents.queryItems?.first(where: { $0.name == "r" })?.value,
              let rdata = r.data(using: .utf8),
              let payload = try? JSONDecoder().decode(TonConnectRequestPayload.self, from: rdata) else {
            failure(TonError.otherError("connect url error"))
            return
        }
        let parameters = TonConnectParameters(version: v, clientId: id, payload: payload)
        TonConnect.maniFest(path: payload.manifestUrl).done { manifestResult in
            success(parameters, manifestResult)
        }.catch { error in
            let _error = error as! TonError
            failure(_error)
        }
    }
}

