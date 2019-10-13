//
//  protocol.swift
//  FunAsync
//
//  Created by Alex Lin on 2019/10/13.
//  Copyright © 2019 Fisheep. All rights reserved.
//

import Foundation

public protocol FunAsyncBaseProtocol {
    func subscribe(closure: @escaping (Any?)->Void)
    func catchError(closure: @escaping (Error?)->Void) ->FunAsyncBaseProtocol
    func observe(on queue:DispatchQueue) -> FunAsyncBaseProtocol
}

public protocol SubsequenceProtocol {
    func process(data: Any) -> Any?
}

