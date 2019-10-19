//
//  Subsequence.swift
//  FunAsync
//
//  Created by Alex Lin on 2019/10/19.
//  Copyright © 2019 Fisheep. All rights reserved.
//

import UIKit

public class Subsequence<REQ,SRC,DST> : SubsequenceProtocol {
    var mapClosure: (SRC)->DST?
    let request: REQ
    
    var nextSequence: SubsequenceProtocol?
    
    public init(req: REQ, closure: @escaping (SRC)->DST?) {
        self.request = req
        self.mapClosure = closure
    }
    
    public func map<T>(clousre: @escaping (DST)->T?) -> Subsequence<REQ,DST,T> {
        let wrss = Subsequence<REQ,DST,T>(req: request, closure: clousre)
        nextSequence = wrss
        return wrss
    }
    
    public func process(data: Any) -> Any? {
        guard let srcData = data as? SRC else { return nil }
        let result = mapClosure(srcData)
        if let nextSequence = nextSequence, let result = result {
            return nextSequence.process(data: result)
        }
        return result
    }
    
}
