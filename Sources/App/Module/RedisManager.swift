//
//  RedisManager.swift
//  App
//
//  Created by niuhui on 2018/6/21.
//

import Vapor
import Redis
struct RedisManager {
    
    static let share: RedisManager = RedisManager()
    
    static func save(_ user: User?, request: Request) throws {
        if let user = user {

        
        }
    }

}
