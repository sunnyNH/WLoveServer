//
//  ResponseJSON.swift
//  App
//
//  Created by niuhui on 2018/6/21.
//

import Vapor

enum ResponseState: Int {
    case ok
    case error
    case auth
}

struct ResponseJSON<T: Content>: Content {
    
    var state: Int      = 0
    var message: String = "success"
    var data: T?
    
    init(state: ResponseState = .ok, message: String = "success", data: T? = nil) {
        self.state = state.rawValue
        self.message = message
        self.data = data
    }
    
}
