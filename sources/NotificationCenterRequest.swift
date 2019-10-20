//
//  NotificationCenterRequest.swift
//  FunAsync
//
//  Created by Alex Lin on 2019/10/19.
//  Copyright © 2019 Fisheep. All rights reserved.
//

import UIKit

public class NotificationCenterRequest {
    private let notificationCenter: NotificationCenter
    private let notification2Receive: String
    private var lastNotification: Notification?
    
    var nextSequence: SubsequenceProtocol?
    var subscribCloure: ((Any?)->Void)?
    var catchClosure: ((Error)->Void)?

    var queue: DispatchQueue?

    public init(notificationCenter: NotificationCenter, notification2Receive: String) {
        self.notificationCenter = notificationCenter
        self.notification2Receive = notification2Receive
        notificationCenter.addObserver(forName: NSNotification.Name(notification2Receive), object: nil, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            self.lastNotification = notification
            if let closure = self.subscribCloure {
                self._subscribe(closure: closure)
            }
        }
    }
    
    public func map<T>(closure: @escaping (Notification)->T?) -> Subsequence<NotificationCenterRequest,Notification,T> {
        let wrss = Subsequence(req: self, closure: closure)
        nextSequence = wrss
        return wrss
    }
    
    public func subscribe(closure: @escaping (Notification?)->Void) {
        _subscribe(closure: closure)
    }

    func _subscribe<T>(closure: @escaping (T?)->Void) {
        subscribCloure = {
            closure($0 as? T)
        }
        guard let notification = lastNotification else { return }
        
        var subscribedData: Any?
        if let processor = nextSequence {
            subscribedData = processor.process(data: notification)
        }
        else {
            subscribedData = notification
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
                    let error = NSError(domain: "funasync.notificationcenterrequest.dataerror", code: -1, userInfo: nil)
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

    public func catchError(closure: @escaping (Error?) -> Void) -> NotificationCenterRequest {
        catchClosure = closure
        return self
    }
    
    public func observe(on queue: DispatchQueue) ->NotificationCenterRequest {
        self.queue = queue
        return self
    }
}

public extension Subsequence where REQ:NotificationCenterRequest {
    func subscribe(closure: @escaping (DST?)->Void) {
        let _ = request._subscribe(closure: closure)
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
