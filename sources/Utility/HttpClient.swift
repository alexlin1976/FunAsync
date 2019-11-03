//
//  HttpClient.swift
//  FunAsync
//
//  Created by Alex Lin on 2019/10/15.
//  Copyright © 2019 Fisheep. All rights reserved.
//

import UIKit

public enum RequestMethod: Int {
    case post
    case get

    fileprivate func toString() -> String? {
        switch self {
        case .post:
            return "POST"
        case .get:
            return "GET"
        }
    }
}

class HttpClient {
    public static let shared: HttpClient = HttpClient()
    
    private func isNumeric(_ value: Any) -> Bool {
        let numericTypes: [Any.Type] = [Int.self, Int8.self, Int16.self, Int32.self, Int64.self, UInt.self, UInt8.self, UInt16.self, UInt32.self, UInt64.self, Double.self, Float.self, Float32.self, Float64.self, Decimal.self, NSNumber.self, NSDecimalNumber.self]
        return numericTypes.contains { $0 == Mirror(reflecting: value).subjectType }
    }
    
    private func convert(any value:Any) -> String? {
        if let value = value as? String {
            return value
        }
        else if isNumeric(value) {
            return "\(value)"
        }
        else {
            return nil
        }
    }

    private func getQueryItems(from params:[String:Any]) -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        let _ = params.map {
            if let value = convert(any: $1) {
                let item = URLQueryItem(name: $0, value: value)
                queryItems.append(item)
            }
            else if let array = $1 as? [Any] {
                for value in array {
                    if let value = convert(any: value) {
                        let item = URLQueryItem(name: $0, value: value)
                        queryItems.append(item)
                    }
                }
            }
        }
        return queryItems
    }

    func request(urlSession: URLSession = URLSession.shared, urlString:String, parameters params:[String:Any], timeoutList:[Int], method:RequestMethod, reqObj: WebRequest, completion:((Data?,Int,Error?)->Void)?)
    {
        requestCore(urlSession: urlSession, urlString: urlString, parameters: params, timeoutList: timeoutList, method: method, reqObj: reqObj, success: {
            if let completion = completion {
                completion($0, $1, nil)
            }
        }) {
            if let competion = completion {
                competion(nil, $1, $0)
            }
        }
    }
    
    private func requestCore(urlSession: URLSession, urlString:String, parameters params:[String:Any], timeoutList:[Int], method:RequestMethod, reqObj: WebRequest? = nil, success:((Data?,Int)->Void)?, failure:((Error?,Int)->Void)?) {
        guard var reqUrl = URLComponents(string: urlString) else { return }
        var queryItems = reqUrl.queryItems ?? []
        queryItems += getQueryItems(from: params)
        reqUrl.queryItems = queryItems
        
        guard let reqString = reqUrl.string, let url = URL(string: reqString) else { return }
        requestCore(urlSession: urlSession, url: url, timeoutList: timeoutList, timeoutIndex: 0, method: method, reqObj: reqObj, success: success, failure:failure)
    }
    
    private func requestCore(urlSession: URLSession, url:URL, timeoutList:[Int], timeoutIndex: Int, method:RequestMethod, reqObj: WebRequest? = nil, success:((Data?, Int)->Void)?, failure:((Error?,Int)->Void)?) {
        var urlReq = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        urlReq.httpMethod = method.toString()
        urlReq.timeoutInterval = TimeInterval(timeoutList[timeoutIndex])
        
        let task = urlSession.dataTask(with: urlReq) { [weak self] (data, response, error) in
            let _ = reqObj  // retain the request object in closure
            guard let self = self else { return }
            var statusCode: Int = 0
            if let response = response as? HTTPURLResponse {
                statusCode = response.statusCode
            }
            
            let hasError = error != nil || statusCode >= 400
            if hasError {
                if let nsError = error as NSError? {
                    if statusCode == 0 {
                        statusCode = nsError.code
                    }
                    if nsError.code == NSURLErrorTimedOut && timeoutIndex < timeoutList.count - 1 {
                        self.requestCore(urlSession: urlSession, url: url, timeoutList: timeoutList, timeoutIndex: timeoutIndex + 1, method: method, success: success, failure: failure)
                        return
                    }
                }
            }
            
            if hasError {
                if let failure = failure {
                    failure(error, statusCode)
                }
                return
            }
            
            if let success = success {
                success(data, statusCode)
            }
        }
        task.resume()
    }

}
