//
//  FunasyncWebRequest.swift
//  FunAsync
//
//  Created by Alex Lin on 2019/10/13.
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

    fileprivate func request(with urlString:String, parameters params:[String:Any], timeoutList:[Int], method:RequestMethod, reqObj: FunasyncWebRequest, completion:((Data?,Int,Error?)->Void)?)
    {
        requestCore(with: urlString, parameters: params, timeoutList: timeoutList, method: method, reqObj: reqObj, success: {
            if let completion = completion {
                completion($0, $1, nil)
            }
        }) {
            if let competion = completion {
                competion(nil, $1, $0)
            }
        }
    }
    
    private func requestCore(with urlString:String, parameters params:[String:Any], timeoutList:[Int], method:RequestMethod, reqObj: FunasyncWebRequest? = nil, success:((Data?,Int)->Void)?, failure:((Error?,Int)->Void)?) {
        guard var reqUrl = URLComponents(string: urlString) else { return }
        var queryItems = reqUrl.queryItems ?? []
        queryItems += getQueryItems(from: params)
        reqUrl.queryItems = queryItems
        
        guard let reqString = reqUrl.string, let url = URL(string: reqString) else { return }
        requestCore(with: url, timeoutList: timeoutList, timeoutIndex: 0, method: method, reqObj: reqObj, success: success, failure:failure)
    }
    
    private var reqObjHolder: [FunasyncWebRequest] = []
    private func requestCore(with url:URL, timeoutList:[Int], timeoutIndex: Int, method:RequestMethod, reqObj: FunasyncWebRequest? = nil, success:((Data?, Int)->Void)?, failure:((Error?,Int)->Void)?) {
        var urlReq = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        urlReq.httpMethod = method.toString()
        urlReq.timeoutInterval = TimeInterval(timeoutList[timeoutIndex])
        
        if let reqObj = reqObj {
            if !reqObjHolder.contains(reqObj) {
                reqObjHolder.append(reqObj)
            }
        }

        let task = URLSession.shared.dataTask(with: urlReq) { [weak self] (data, response, error) in
            
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
                        self.requestCore(with: url, timeoutList: timeoutList, timeoutIndex: timeoutIndex + 1, method: method, success: success, failure: failure)
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


public class FunasyncWebRequest: NSObject, FunAsyncBaseProtocol {
    var data: Data?
    var statusCode: Int = 0
    var error: Error?
    
    var nextSequence: SubsequenceProtocol?
    var subscribCloure: ((Any?)->Void)?
    var catchClosure: ((Error)->Void)?
    
    var queue: DispatchQueue?
    
    public init(urlString:String, parameters params:[String:Any] = [:], timeoutList:[Int] = [3, 6, 10, 30], method:RequestMethod = .post) {
        super.init()
        self.doHttpRequest(urlString: urlString, parameters: params, timeoutList: timeoutList, method: method)
    }
    
    public func map<T>(closure: @escaping (Data)->T?) -> Subsequence<Data,T> {
        let wrss = Subsequence(webReq: self, closure: closure)
        nextSequence = wrss
        return wrss
    }
    
    public func jsonResponse() -> Subsequence<Data,Any> {
        let wrss = Subsequence<Data,Any>(webReq: self) { (data) -> Any? in
            return try? JSONSerialization.jsonObject(with: data, options: [])
        }
        nextSequence = wrss
        return wrss
    }
    
    public func decode<T>(type:T.Type) -> Subsequence<Data,T> where T : Decodable {
        let wrss = Subsequence<Data,T>(webReq: self) { (data) -> T? in
            return try? JSONDecoder().decode(type, from: data)
        }
        nextSequence = wrss
        return wrss
    }
    
    public func subscribe(closure: @escaping (Any?)->Void) {
        subscribCloure = closure
        guard let data = data else {
            if let closure = catchClosure, let error = error {
                closure(error)
            }
            return
        }
        
        var subscribedData: Any?
        if let processor = nextSequence {
            subscribedData = processor.process(data: data)
        }
        else {
            subscribedData = data
        }
        if let queue = queue {
            queue.async {
                closure(subscribedData)
            }
        }
        else {
            closure(subscribedData)
        }
    }
    
    public func catchError(closure: @escaping (Error?) -> Void) -> FunAsyncBaseProtocol {
        catchClosure = closure
        
        if let error = error {
            closure(error)
        }
        return self
    }
    
    public func observe(on queue: DispatchQueue) ->FunAsyncBaseProtocol {
        self.queue = queue
        return self
    }

    private func doHttpRequest(urlString:String, parameters params:[String:Any], timeoutList:[Int], method:RequestMethod)
    {
        HttpClient.shared.request(with: urlString, parameters: params, timeoutList: timeoutList, method: method, reqObj: self) { [weak self] (data, statusCode, error) in
            guard let self = self else { return }
            self.data = data
            self.statusCode = statusCode
            self.error = error
            
            if let closure = self.subscribCloure {
                self.subscribe(closure: closure)
            }
        }
    }
        
    public class Subsequence<SRC,DST> : SubsequenceProtocol {
        var mapClosure: (SRC)->DST?
        let webReq: FunasyncWebRequest
        
        var nextSequence: SubsequenceProtocol?
        
        public init(webReq: FunasyncWebRequest, closure: @escaping (SRC)->DST?) {
            self.webReq = webReq
            self.mapClosure = closure
        }
        
        public func map<T>(clousre: @escaping (DST)->T?) -> Subsequence<DST,T> {
            let wrss = Subsequence<DST,T>(webReq: webReq, closure: clousre)
            nextSequence = wrss
            return wrss
        }
        
        public func subscribe(closure: @escaping (Any?)->Void) {
            let _ = webReq.subscribe(closure: closure)
        }
        
        public func process(data: Any) -> Any? {
            guard let srcData = data as? SRC else { return nil }
            let result = mapClosure(srcData)
            if let nextSequence = nextSequence, let result = result {
                return nextSequence.process(data: result)
            }
            return result
        }
        
        public func observe(on queue:DispatchQueue) -> Subsequence {
            let _ = webReq.observe(on: queue)
            return self
        }
        
        public func catchError(closure: @escaping (Error?)->Void) -> Subsequence {
            let _ = webReq.catchError(closure: closure)
            return self
        }
    }
}
