//
//  FriendNotice.swift
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

final class FriendNotice: Model
{
    static let entity = "FriendNotices"
    let storage = Storage()
    //自己的uuid
    var m_uuid      :   String  = ""
    //好友的uuid
    var f_uuid      :   String  = ""
    var m_delete    :   Bool    = false
    var f_delete    :   Bool    = false
    var create_at   :   Int     = 0
    var message     :   String  = ""
    // 0 待确定，1 好友，2拒绝
    var state       :   Int     = 0
    init(row: Row) throws {
        m_uuid      =   try row.get("m_uuid")
        f_uuid      =   try row.get("f_uuid")
        create_at   =   try row.get("create_at")
        state       =   try row.get("state")
        m_delete    =   try row.get("m_delete")
        f_delete    =   try row.get("f_delete")
        message     =   try row.get("message")
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
extension FriendNotice: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.string("m_uuid")
            users.string("f_uuid")
            users.bool("m_delete")
            users.bool("f_delete")
            users.string("message")
            users.int("state")
            users.int("create_at")
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
extension FriendNotice {
    func makeJSON(_ type : JsonType , uuid: String?) throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("state", state)
        try json.set("create_at", create_at)
        try json.set("message", message)
        if let temp_uuid = uuid {
            if temp_uuid == self.m_uuid  {
                try json.set("is_me", true)
                try json.set("user" , self.f_user()?.makeJSON(.user))
            } else {
                try json.set("is_me", false)
                try json.set("user" , self.m_user()?.makeJSON(.user))
            }
        } else {
            try json.set("m_delete", m_delete)
            try json.set("f_delete", f_delete)
            try json.set("m_uuid", m_uuid)
            try json.set("f_uuid", f_uuid)
        }
        return json
    }
}
extension FriendNotice {
    func f_user() throws -> User? {
        return try RedisTool.getUser(f_uuid)
    }
    func m_user() throws -> User? {
        return try RedisTool.getUser(m_uuid)
    }
}
