//
//  Friend.swift
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

final class Friend: Model
{
    static let entity = "Friends"
    let storage = Storage()
    //自己的uuid
    var m_uuid      :   String  = ""
    //好友的uuid
    var f_uuid      :   String  = ""
    var create_at   :   Int     = 0
    // 0待确认， 1 好友，2 拉黑，3 被拉黑 4 被删除
    var state       :   Int     = 0
    init(row: Row) throws {
        m_uuid      =   try row.get("m_uuid")
        f_uuid      =   try row.get("f_uuid")
        create_at   =   try row.get("create_at")
        state       =   try row.get("state")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(m_uuid: String,f_uuid: String) {
        self.m_uuid     = m_uuid
        self.f_uuid     = f_uuid
        self.create_at  = Int(Date().timeIntervalSince1970)
    }
}
extension Friend: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.string("m_uuid")
            users.string("f_uuid")
            users.int("state")
            users.int("create_at")
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
extension Friend {
    func makeJSON(_ type : JsonType) throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("state", state)
        try json.set("create_at", create_at)
        if type == .user {
            try json.set("user", self.f_user()?.makeJSON(.user))
        } else {
            try json.set("m_uuid", m_uuid)
            try json.set("f_uuid", f_uuid)
        }
        return json
    }
}
extension Friend {
    func f_user() throws -> User? {
        return try RedisTool.getUser(f_uuid)
    }
}
