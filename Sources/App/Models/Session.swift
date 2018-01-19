//
//  Session.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/4.
//
//

import Vapor
import Validation
import Crypto
import FluentProvider
import HTTP

final class Session: Model
{
    static let entity = "Sessions"
    let storage = Storage()
    /// 用户id
    var user_id   : Identifier    = 0
    var uuid      : String = ""
    /// token
    var token     : String = ""
    /// 过期时间
    var expire_at : Int    = 0
    /// 推送token
    var push_token: String = ""
    /// 极光推送id
    var jpush_id  : String = ""
    init(row: Row) throws {
        id          =   try row.get("id")
        exists      =   try row.get("exists")
        user_id     =   try row.get("user_id")
        uuid        =   try row.get("uuid")
        token       =   try row.get("token")
        expire_at   =   try row.get("expire_at")
        push_token  =   try row.get("push_token")
        jpush_id    =   try row.get("jpush_id")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    class func session(user: User) -> Session {
        do {
            guard let session = try Session.makeQuery().filter("user_id", user.id!).first() else {
                return Session(user:user)
            }
            if session.token.count > 0 {
                try RedisTool.deleteSession(session.token)
            }
            session.expire_at = Int(Date().timeIntervalSince1970) + 30 * 24 * 60 * 60
            session.token = session.generateSignInToken(user.id!.int!)
            return session
        } catch {
            return Session(user:user)
        }
    }
    init(user: User) {
        self.user_id = user.id!
        self.expire_at = Int(Date().timeIntervalSince1970) + 30 * 24 * 60 * 60
        self.token = generateSignInToken(user.id!.int!)
        self.uuid    = user.uuid
    }
    func generateSignInToken(_ userID: Int) -> String {
        do {
            let id = userID + Int(Date().timeIntervalSince1970)
            let userBye =  "\(id)".makeBytes()
            let result = try Hash.make(.md5, userBye)
            let byes =  result.hexString.makeBytes()
            return byes.base64Encoded.makeString().replacingOccurrences(of: "=", with: "")
        } catch let error {
            print(error)
        }
        return ""
    }
}
extension Session {
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("uuid", uuid)
        try json.set("user_id", user_id)
        try json.set("token", token)
        try json.set("push_token", push_token)
        try json.set("expire_at", expire_at)
        try json.set("jpush_id", jpush_id)
        return json
    }
    func redisJson() throws -> JSON {
        var json = try makeJSON()
        try json.set("id", id)
        try json.set("exists", exists)
        return json
    }
}
extension Session: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.int("user_id",unique:true)
            users.string("token",unique:true)
            users.int("expire_at")
            users.string("push_token")
            users.string("uuid",unique:true)
            users.string("jpush_id")
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
extension Request {
    func userSession() throws -> Session? {
        guard let token = self.data["access_token"]?.string else{
            return nil
        }
        return try RedisTool.getSession(token)
    }
}
