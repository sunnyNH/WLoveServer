//
//  TokenMiddleware.swift
//  NHServer
//
//  Created by niuhui on 2017/5/9.
//
//

import Vapor
import HTTP
import Foundation

final class TokenMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        guard let token = request.data["access_token"]?.string else{
            return try JSON([code: 1,msg : "未登录"]).makeResponse()
        }
        guard let session = try RedisTool.getSession(token) else {
            return try JSON([code: 1,msg : "未登录"]).makeResponse()
        }
        guard session.expire_at >= Int(Date().timeIntervalSince1970) else {
            try session.delete()
            try RedisTool.deleteSession(token)
            return try JSON([code: 1,msg : "登录过期"]).makeResponse()
        }
        guard let _ = try RedisTool.getUser(session.uuid) else {
            try session.delete()
            try RedisTool.deleteSession(token)
            return try JSON([code: 1,msg : "登录过期"]).makeResponse()
        }
        return try next.respond(to: request)
    }
}
