//
//  URLSession+WebRequest.swift
//  FunAsync
//
//  Created by Alex Lin on 2019/10/15.
//  Copyright © 2019 Fisheep. All rights reserved.
//

import Foundation

public extension URLSession {
    func dataTask(urlString:String, params:[String:Any] = [:], timeoutList:[Int] = [3, 6, 10, 30], method:RequestMethod = .post) -> WebRequest {
        return WebRequest(urlSession: self, urlString: urlString, parameters: params, timeoutList: timeoutList, method: method)
    }
}
