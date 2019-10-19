//
//  FunasyncWebRequest.swift
//  FunAsync
//
//  Created by Alex Lin on 2019/10/13.
//  Copyright © 2019 Fisheep. All rights reserved.
//

import UIKit

public class WebRequest: NSObject {
    var data: Data?
    var statusCode: Int = 0
    var error: Error?
    let urlSession: URLSession
    
    var nextSequence: SubsequenceProtocol?
    var subscribCloure: ((Any?)->Void)?
    var catchClosure: ((Error)->Void)?
    
    var queue: DispatchQueue?
    
    public init(urlSession: URLSession = URLSession.shared, urlString:String, parameters params:[String:Any] = [:], timeoutList:[Int] = [3, 6, 10, 30], method:RequestMethod = .post) {
        self.urlSession = urlSession
        super.init()
        self.doHttpRequest(urlString: urlString, parameters: params, timeoutList: timeoutList, method: method)
    }
    
    public func map<T>(closure: @escaping (Data)->T?) -> Subsequence<WebRequest,Data,T> {
        let wrss = Subsequence(req: self, closure: closure)
        nextSequence = wrss
        return wrss
    }
    
    public func jsonResponse() -> Subsequence<WebRequest,Data,Any> {
        let wrss = Subsequence<WebRequest,Data,Any>(req: self) { (data) -> Any? in
            return try? JSONSerialization.jsonObject(with: data, options: [])
        }
        nextSequence = wrss
        return wrss
    }
    
    public func decode<T>(type:T.Type) -> Subsequence<WebRequest,Data,T> where T : Decodable {
        let wrss = Subsequence<WebRequest,Data,T>(req: self) { (data) -> T? in
            return try? JSONDecoder().decode(type, from: data)
        }
        nextSequence = wrss
        return wrss
    }
    
    public func subscribe<T>(closure: @escaping (T?)->Void) {
        subscribCloure = {
            closure($0 as? T)
        }
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
        if let subscribedData = subscribedData as? T {
            if let queue = queue {
                queue.async { [weak self] in
                    guard let _ = self else { return }
                    closure(subscribedData)
                }
            }
            else {
                closure(subscribedData)
            }
        }
        else {
            let doCatch = { [weak self] in
                guard let self = self else { return }
                if let closure = self.catchClosure {
                    let error = NSError(domain: "funasync.webrequest.dataerror", code: -1, userInfo: nil)
                    closure(error)
                }
            }
            if let queue = queue {
                queue.async(execute: doCatch)
            }
            else {
                doCatch()
            }
        }
    }
    
    public func catchError(closure: @escaping (Error?) -> Void) -> WebRequest {
        catchClosure = closure
        
        if let error = error {
            closure(error)
        }
        return self
    }
    
    public func observe(on queue: DispatchQueue) ->WebRequest {
        self.queue = queue
        return self
    }

    private func doHttpRequest(urlString:String, parameters params:[String:Any], timeoutList:[Int], method:RequestMethod)
    {
        HttpClient.shared.request(urlSession: urlSession, urlString: urlString, parameters: params, timeoutList: timeoutList, method: method, reqObj: self) { [weak self] (data, statusCode, error) in
            guard let self = self else { return }
            self.data = data
            self.statusCode = statusCode
            self.error = error ?? NSError(domain: NSURLErrorDomain, code: statusCode, userInfo: nil)
            
            if let closure = self.subscribCloure {
                self.subscribe(closure: closure)
            }
        }
    }
}


public extension Subsequence where REQ:WebRequest {
    func subscribe(closure: @escaping (DST?)->Void) {
        let _ = request.subscribe(closure: closure)
    }
    
    func observe(on queue:DispatchQueue) -> Subsequence {
        let _ = request.observe(on: queue)
        return self
    }
    
    func catchError(closure: @escaping (Error?)->Void) -> Subsequence {
        let _ = request.catchError(closure: closure)
        return self
    }
}
