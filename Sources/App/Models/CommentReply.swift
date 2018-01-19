//
//  CommentReply.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/6.
//
//

import Vapor
import FluentProvider
import Foundation
import HTTP

final class CommentReply: Model {
    let storage = Storage()
    static let entity = "CommentReplys"
    var com_id          : Int       = 0
    var uuid            : String    = ""
    var message         : String    = ""
    var create_at       : Int       = 0
    init(row: Row) throws {
        com_id = try row.get("com_id")
        uuid = try row.get("uuid")
        message = try row.get("message")
        create_at = try row.get("create_at")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(user: User,com_id : Int,msg: String) {
        self.uuid       = user.uuid
        self.create_at  = Int(Date().timeIntervalSince1970)
        self.com_id     = com_id
        self.message    = msg
    }
}
extension CommentReply {
    func makeJSON(_ type : JsonType) throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("user", user()?.makeJSON(.user))
        try json.set("create_at", create_at)
        try json.set("message", message)
        try json.set("com_id", com_id)
        return json
    }
}
extension CommentReply {
    func user() throws -> User? {
        return try RedisTool.getUser(uuid)
    }
}
extension CommentReply: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.int("com_id")
            users.string("uuid")
            users.int("create_at")
            users.string("message")
        }
        
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
