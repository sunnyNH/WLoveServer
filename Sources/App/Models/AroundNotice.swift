//
//  AroundNotice.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/6.
//
//

import Vapor
import FluentProvider
import Foundation
import HTTP

final class AroundNotice: Model  {
    static let entity = "AroundNotices"
    let storage = Storage()
    /// 用户id
    var uuid        : String    = ""
    var com_uuid    : String    = ""
    /// 动态id
    var around_id   : Int       = 0
    /// 评论id
    var com_id      : Int       = 0
    /// 评论时间
    var create_at   : Int       = 0
    
    init(row: Row) throws {
        uuid = try row.get("uuid")
        com_uuid = try row.get("com_uuid")
        around_id = try row.get("around_id")
        com_id = try row.get("com_id")
        create_at = try row.get("create_at")
    }
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("uuid", uuid)
        try row.set("com_uuid", com_uuid)
        try row.set("around_id", around_id)
        try row.set("com_id", com_id)
        try row.set("create_at", create_at)
        return row
    }
    init(user: User,around : AroundMsg,comt: AroundComment) {
        self.uuid = around.uuid
        self.com_uuid   = user.uuid
        self.create_at  = comt.create_at
        self.around_id  = around.id!.int!
        self.com_id     = (comt.id?.int)!
    }
    init(around: AroundMsg,comt: AroundComment) {
        self.uuid       = comt.com_uuid
        self.com_uuid   = comt.uuid
        self.create_at  = comt.create_at
        self.around_id  = around.id!.int!
        self.com_id     = (comt.id?.int)!
    }
}
extension AroundNotice {
    func makeJSON(_ type : JsonType) throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("user", user()?.makeJSON(.user))
        try json.set("around_id", around_id)
        try json.set("comment", comment()?.makeJSON(.user))
        try json.set("create_at", create_at)
        return json
    }
}
extension AroundNotice: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.int("com_id")
            users.int("around_id")
            users.string("com_uuid")
            users.string("uuid")
            users.int("create_at")
        }
        try database.index("around_id", for: self)
        try database.index("com_uuid", for: self)
        try database.index("uuid", for: self)
        try database.index("create_at", for: self)
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
extension AroundNotice {
    func user() throws -> User? {
        return try RedisTool.getUser(com_uuid)
    }
    func comment() throws -> AroundComment? {
        if let com = try AroundComment.makeQuery().filter("id", com_id).first() {
            return com
        } else {
            return nil
        }
    }
}
