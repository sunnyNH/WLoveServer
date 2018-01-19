//
//  VerifyCode.swift
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

final class VerifyCode: Model
{
    static let entity = "VerifyCodes"
    let storage = Storage()
    var phone           : String    = ""
    var code            : Int       = 0
    var create_at       : Int       = 0
    var verify_at       : Int       = 0
    var vcount          : Int       = 0
    var type            : String    = ""
    var is_used         : Bool      = false
    init(row: Row) throws {
        phone       =   try row.get("phone")
        code        =   try row.get("code")
        create_at   =   try row.get("create_at")
        verify_at   =   try row.get("verify_at")
        vcount      =   try row.get("vcount")
        type        =   try row.get("type")
        is_used     =   try row.get("is_used")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(phone: String,type: String) {
        self.phone      = phone
        self.create_at  = Int(Date().timeIntervalSince1970)
        self.type       = type
        if drop.config.environment != .production {
            self.code = 111111;
        } else {
            let temp = Int.random(min: 100000, max: 999999)
            self.code = temp
        }
    }
}
extension VerifyCode: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.string("phone")
            users.int("code")
            users.int("create_at")
            users.int("verify_at")
            users.int("vcount")
            users.string("type")
            users.bool("is_used")
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
