//
//  AroundMsgUp.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/6.
//
//

import Vapor
import FluentProvider
import Foundation
import HTTP

final class AroundMsgUp: Model {
    static let entity = "AroundMsgUps"
    let storage = Storage()
    /// 用户id
    var uuid      : String = ""
    /// 动态id
    var around_id : Int    = 0
    /// 点赞时间
    var create_at : Int    = 0

    init(row: Row) throws {
        uuid = try row.get("uuid")
        around_id = try row.get("around_id")
        create_at = try row.get("create_at")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(user: User,around_id : Int) {
        self.uuid = user.uuid
        self.create_at = Int(Date().timeIntervalSince1970)
        self.around_id = around_id
    }
}
extension AroundMsgUp: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.int("around_id")
            users.string("uuid")
            users.int("create_at")
        }
        try database.index("uuid", for: self)
        try database.index("create_at", for: self)
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
extension AroundMsgUp {
    func makeJSON(_ type : JsonType) throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("user", user()?.makeJSON(.user))
        try json.set("around_id", around_id)
        try json.set("create_at", create_at)
        return json
    }
}
extension AroundMsgUp {
    func user() throws -> User? {
        return try RedisTool.getUser(uuid)
    }
}
