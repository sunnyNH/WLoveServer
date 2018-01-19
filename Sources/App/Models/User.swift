//
//  User.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/1.
//
//

import Vapor
import Validation
import Crypto
import FluentProvider
import HTTP

enum JsonType {
    case me
    case user
    case all
}
final class User: Model
{
    static let entity = "Users"
    let storage = Storage()
    //uuid
    var uuid    : String = ""
    /// 电话
    var phone   : String = ""
    /// 密码
    var password: String = ""
    /// 名字
    var name    : String = ""
    /// 头像
    var avatar  : String = ""
    /// 年龄
    var age     : Int    = 0
    /// 性别
    var gender  : Int    = 0
    /// 简介
    var overview: String = ""
    /// 地址
    var address   : String = ""
    ///是否注册环信
    var isERegister : Bool  = false
    //注册时间
    var create_at        = 0
    init(row: Row) throws {
        id          =   try row.get("id")
        exists      =   try row.get("exists")
        uuid = try row.get("uuid")
        phone = try row.get("phone")
        password = try row.get("password")
        avatar = try row.get("avatar")
        name   = try row.get("name")
        age = try row.get("age")
        gender = try row.get("gender")
        overview = try row.get("overview")
        address = try row.get("address")
        isERegister = try row.get("isERegister")
        create_at = try row.get("create_at")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(phone:String, pw:String) {
        self.phone = phone;
        self.password = pw.md5;
        self.uuid  = UUID().uuidString.md5
        self.create_at = Int(Date().timeIntervalSince1970)
    }
}
extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.string("phone", unique: true)
            users.string("password")
            users.string("name")
            users.string("avatar")
            users.string("uuid",unique: true)
            users.string("overview")
            users.string("address")
            users.int("age")
            users.int("gender")
            users.int("create_at")
            users.bool("isERegister")
        }

    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
extension User {
    func makeJSON(_ type : JsonType) throws -> JSON {
        var json = JSON()
        try json.set("uuid", uuid)
        try json.set("name", name)
        try json.set("avatar", avatar)
        try json.set("age", age)
        try json.set("gender", gender)
        try json.set("overview", overview)
        try json.set("address", address)
        try json.set("isERegister", isERegister)
        try json.set("create_at", create_at)
        if type == .me {
            try json.set("phone", phone)
        } else if type == .user {

        } else {
            try json.set("id", id)
            try json.set("exists", exists)
            try json.set("password", password)
            try json.set("phone", phone)
        }
        return json
    }
    func redisJson() throws -> JSON {
        return try makeJSON(.all)
    }
}
extension Request {
    func user() throws -> User? {
        guard let token = self.data["access_token"]?.string else{return nil}
        guard let session = try RedisTool.getSession(token) else { return nil }
        return try RedisTool.getUser(session.uuid)
    }
}

