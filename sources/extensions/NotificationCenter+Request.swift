//
//  NotificationCenter+Request.swift
//  FunAsync
//
//  Created by Alex Lin on 2019/10/19.
//  Copyright © 2019 Fisheep. All rights reserved.
//

import Foundation

public extension NotificationCenter {
    func requestNotification(notification2Receive: String) -> NotificationCenterRequest {
        return NotificationCenterRequest(notificationCenter: self, notification2Receive: notification2Receive)
    }
}
