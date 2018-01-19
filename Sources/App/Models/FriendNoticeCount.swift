//
//  FriendNoticeCount.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/6.
//
//

import Vapor
import Validation
import Crypto
import FluentProvider
import HTTP

final class FriendNoticeCount: Model {
    static let entity = "FriendNoticeCounts"
    let storage = Storage()
    var uuid        :   String  = ""
    var create_at   :   Int     = 0
    var f_not_id    :   Int     = 0
    init(row: Row) throws {
        uuid      =   try row.get("uuid")
        create_at      =   try row.get("create_at")
        f_not_id   =   try row.get("f_not_id")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(uuid: String,f_not: FriendNotice) {
        self.uuid           = uuid
        if let id = f_not.id?.int {
            self.f_not_id   = id
        }
        self.create_at      = Int(Date().timeIntervalSince1970)
    }
}
extension FriendNoticeCount {
    func makeJSON(_ type : JsonType , uuid: String?) throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("uuid", uuid)
        try json.set("f_not_id", f_not_id)
        try json.set("create_at", create_at)
        return json
    }
}
extension FriendNoticeCount: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.string("uuid")
            users.int("create_at")
            users.int("f_not_id")
        }
        try database.index("uuid", for: self)
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
