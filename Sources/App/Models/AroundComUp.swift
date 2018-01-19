//
//  AroundComUp.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/6.
//
//

import Vapor
import FluentProvider
import Foundation
import HTTP

final class AroundComUp: Model {
    static let entity = "AroundComUps"
    let storage = Storage()
    /// 用户id
    var uuid      : String = ""
    /// 动态id
    var com_id    : Int    = 0
    /// 点赞时间
    var create_at : Int    = 0
    init(row: Row) throws {
        uuid = try row.get("uuid")
        com_id = try row.get("com_id")
        create_at = try row.get("create_at")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(user: User,com_id : Int) {
        self.uuid = user.uuid
        self.create_at = Int(Date().timeIntervalSince1970)
        self.com_id = com_id
    }
}
extension AroundComUp {
    func makeJSON(_ type : JsonType) throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("uuid", uuid)
        try json.set("com_id", com_id)
        try json.set("create_at", create_at)
        return json
    }
}
extension AroundComUp: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.int("com_id")
            users.string("uuid")
            users.int("create_at")
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
