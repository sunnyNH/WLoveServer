//
//  AroundComment.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/5.
//
//

import Vapor
import FluentProvider
import Foundation
import HTTP

final class AroundComment: Model {
    static let entity = "AroundComments"
    let storage = Storage()
    var around_id       : Int       = 0
    var uuid            : String    = ""
    var com_uuid        : String    = ""
    var message         : String    = ""
    var create_at       : Int       = 0
    var ups_count       : Int       = 0
    var rep_count       : Int       = 0
    var is_up           : Bool      = false
    init(user: User,around_id : Int,msg: String) {
        self.uuid       = user.uuid
        self.create_at  = Int(Date().timeIntervalSince1970)
        self.around_id  = around_id
        self.message    = msg
    }
    init(row: Row) throws {
        uuid = try row.get("uuid")
        around_id = try row.get("around_id")
        create_at = try row.get("create_at")
        message = try row.get("message")
        com_uuid = try row.get("com_uuid")
        ups_count = try row.get("ups_count")
    }
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("uuid", uuid)
        try row.set("around_id", around_id)
        try row.set("create_at", create_at)
        try row.set("message", message)
        try row.set("com_uuid", com_uuid)
        try row.set("ups_count", ups_count)
        return row
    }
}
extension AroundComment: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.int("around_id")
            users.string("uuid")
            users.string("com_uuid")
            users.int("create_at")
            users.string("message")
            users.int("ups_count")
        }
        try database.index("uuid", for: self)
        try database.index("create_at", for: self)
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
extension AroundComment {
    func makeJSON(_ type : JsonType) throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("user", user()?.makeJSON(.user))
        try json.set("around_id", around_id)
        try json.set("create_at", create_at)
        try json.set("message", message)
        try json.set("com_user", comUser()?.makeJSON(.user))
        try json.set("ups_count", ups_count)
        try json.set("is_up", is_up)
        return json
    }
}
extension AroundComment {
    func user() throws -> User? {
        return try RedisTool.getUser(uuid)
    }
    func comUser() throws -> User? {
        return try RedisTool.getUser(com_uuid)
    }
}

