//
//  SMSIP.swift
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

final class SMSIP: Model
{
    static let entity = "SMSIPs"
    let storage = Storage()
    var ip              : String    = ""
    var max_count       : Int       = 0
    var used_count      : Int       = 0
    var last_at         : Int       = 0

    init(row: Row) throws {
        ip              =   try row.get("ip")
        max_count       =   try row.get("max_count")
        used_count      =   try row.get("used_count")
        last_at         =   try row.get("last_at")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(ip: String) {
        self.ip      = ip
        self.last_at = Int(Date().timeIntervalSince1970)
        self.used_count = 1
        self.max_count = 10
    }
}
extension SMSIP: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.string("ip")
            users.int("max_count")
            users.int("used_count")
            users.int("last_at")
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
