//
//  TokenMiddleware.swift
//  App
//
//  Created by niuhui on 2018/6/21.
//

import Vapor

struct TokenMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        
        guard let token = try? request.query.get(String.self, at: "access_token") else {
            return  try ResponseJSON<[String:String]>(state: .auth, message: "未登录", data:[:]).encode(for: request)
        }
        print(token)
        return try next.respond(to: request)
    }
    
}
