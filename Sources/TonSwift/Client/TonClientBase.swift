//
//  TonProviderBase.swift
//  
//
//  Created by xgblin on 2023/2/3.
//

import Foundation
import PromiseKit

public class TonClientBase {
    public var url: URL
    private var session: URLSession
    var apiKey: String
    
    public init(url: URL, apiKey: String) {
        self.url = url
        self.session = URLSession(configuration: .default)
        self.apiKey = apiKey
    }
    
    public func sendRPC<T: Codable>(method: String, params: [String: Any]? = nil) -> Promise<T> {
        let parameters = [
            "id": 1,
            "jsonrpc": "2.0",
            "method": method,
            "params": params ?? [String: Any]()
        ] as [String : Any]
        return POST(path: "/api/v2/jsonRPC", parameters: parameters, headers: ["X-API-Key" : self.apiKey])
    }
    
    public func runGetMethod<T: Codable>(address: String, method: String, params: [Any] = [Any]()) -> Promise<T> {
        let parameters = [
            "address": address,
            "method": method,
            "stack": params
        ] as [String : Any]
        return sendRPC(method: "runGetMethod", params: parameters)
    }
    
    public func GET<T: Codable>(path: String, parameters: [String: Any]? = nil) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "ton.get")
        queue.async {
            var getUrl = self.url.appendingPathComponent(path)
            if let p = parameters, !p.isEmpty {
                var urlComponents = URLComponents(url: getUrl, resolvingAgainstBaseURL: true)!
                var items = urlComponents.queryItems ?? []
                items += p.map({ URLQueryItem(name: $0, value: "\($1)") })
                urlComponents.queryItems = items
                getUrl = urlComponents.url!
            }
            
            //            debugPrint("GET \(url)")
            var urlRequest = URLRequest(url: getUrl, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
            urlRequest.httpMethod = "GET"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            
            task = self.session.dataTask(with: urlRequest){ (data, response, error) in
                guard error == nil else {
                    rp.resolver.reject(error!)
                    return
                }
                guard data != nil else {
                    rp.resolver.reject(TonError.providerError("Node response is empty"))
                    return
                }
                rp.resolver.fulfill(data!)
            }
            task?.resume()
        }
        return rp.promise.ensure(on: queue) {
            task = nil
        }.map(on: queue){ (data: Data) throws -> T in
            //            debugPrint(String(data: data, encoding: .utf8) ?? "")
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let result = try decoder.decode(TonRPCResult<T>.self, from: data)
                guard result.ok == true else {
                    throw TonError.otherError(result.error!)
                }
                guard let data = result.result else {
                    throw TonError.unknow
                }
                return data
            } catch {
                throw TonError.providerError("Parameter error or received wrong message")
            }
        }
    }
    
    public func POST<T: Codable>(path: String, parameters: [String : Any]? = nil, headers: [String: String] = [:]) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "ton.post")
        queue.async {
            do {
                let postUrl = self.url.appendingPathComponent(path)
                var urlRequest = URLRequest(url: postUrl, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
                urlRequest.httpMethod = "POST"
                
                for key in headers.keys {
                    urlRequest.setValue(headers[key], forHTTPHeaderField: key)
                }
                if !headers.keys.contains("Content-Type") {
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
                if !headers.keys.contains("Accept") {
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                }
                if let p = parameters {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: p)
                    //debugPrint(p)
                }
                //            debugPrint(body?.toHexString() ?? "")
                
                task = self.session.dataTask(with: urlRequest){ (data, response, error) in
                    guard error == nil else {
                        rp.resolver.reject(error!)
                        return
                    }
                    guard data != nil else {
                        rp.resolver.reject(TonError.providerError("Node response is empty"))
                        return
                    }
                    rp.resolver.fulfill(data!)
                }
                task?.resume()
            } catch {
                rp.resolver.reject(error)
            }
        }
        
        return rp.promise.ensure(on: queue) {
            task = nil
        }.map(on: queue) { (data: Data) throws -> T in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let result = try decoder.decode(TonRPCResult<T>.self, from: data)
                guard result.ok == true else {
                    if let errorStr = result.error {
                        throw TonError.otherError(errorStr)
                    }
                    throw TonError.unknow
                }
                guard let data = result.result else {
                    throw TonError.unknow
                }
                return data
            } catch let error {
                throw error
            }
        }
    }
}

extension TonClientBase {
    public func GET<T: Codable>(urlString: String, parameters: [String: Any]? = nil, headers: [String: String] = [:]) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "ton.get")
        queue.async {
            guard var getUrl = URL(string: urlString) else {
                rp.resolver.reject(TonError.providerError("url error"))
                return
            }
            if let p = parameters, !p.isEmpty {
                var urlComponents = URLComponents(url: getUrl, resolvingAgainstBaseURL: true)!
                var items = urlComponents.queryItems ?? []
                items += p.map({ URLQueryItem(name: $0, value: "\($1)") })
                urlComponents.queryItems = items
                getUrl = urlComponents.url!
            }
            
            //            debugPrint("GET \(url)")
            var urlRequest = URLRequest(url: getUrl, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
            urlRequest.httpMethod = "GET"
            for key in headers.keys {
                urlRequest.setValue(headers[key], forHTTPHeaderField: key)
            }
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            
            task = self.session.dataTask(with: urlRequest){ (data, response, error) in
                guard error == nil else {
                    rp.resolver.reject(error!)
                    return
                }
                guard data != nil else {
                    rp.resolver.reject(TonError.providerError("Node response is empty"))
                    return
                }
                rp.resolver.fulfill(data!)
            }
            task?.resume()
        }
        return rp.promise.ensure(on: queue) {
            task = nil
        }.map(on: queue){ (data: Data) throws -> T in
            //            debugPrint(String(data: data, encoding: .utf8) ?? "")
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                guard let result = try? decoder.decode(T.self, from: data) else {
                    throw TonError.unknow
                }
                return result
            } catch {
                throw TonError.providerError("Parameter error or received wrong message")
            }
        }
    }
    
    public func POST<T: Codable>(urlString: String, parameters: [String : Any]? = nil, headers: [String: String] = [:]) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "ton.post")
        queue.async {
            do {
                guard let postUrl = URL(string: urlString) else {
                    rp.resolver.reject(TonError.providerError("url error"))
                    return
                }
                var urlRequest = URLRequest(url: postUrl, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
                urlRequest.httpMethod = "POST"
                
                for key in headers.keys {
                    urlRequest.setValue(headers[key], forHTTPHeaderField: key)
                }
                if !headers.keys.contains("Content-Type") {
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
                if !headers.keys.contains("Accept") {
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                }
                if let p = parameters {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: p)
                    //debugPrint(p)
                }
                //            debugPrint(body?.toHexString() ?? "")
                
                task = self.session.dataTask(with: urlRequest){ (data, response, error) in
                    guard error == nil else {
                        rp.resolver.reject(error!)
                        return
                    }
                    guard data != nil else {
                        rp.resolver.reject(TonError.providerError("Node response is empty"))
                        return
                    }
                    rp.resolver.fulfill(data!)
                }
                task?.resume()
            } catch {
                rp.resolver.reject(error)
            }
        }
        
        return rp.promise.ensure(on: queue) {
            task = nil
        }.map(on: queue) { (data: Data) throws -> T in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                guard let result = try? decoder.decode(T.self, from: data) else {
                    throw TonError.unknow
                }
                return result
            } catch let error {
                throw error
            }
        }
    }
}
