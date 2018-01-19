//
//  ReportAround.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/6.
//
//

import Vapor
import FluentProvider
import Foundation
import HTTP

final class ReportAround: Model {
    static let entity = "ReportArounds"
    let storage = Storage()
    var rcount          : Int       = 0
    var around_id       : Int       = 0
    var last_at         : Int       = 0
    init(row: Row) throws {
        rcount = try row.get("rcount")
        around_id = try row.get("around_id")
        last_at = try row.get("last_at")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(around_id: Int) {
        self.last_at = Int(Date().timeIntervalSince1970)
        self.around_id = around_id
        self.rcount = 1
    }
}
extension ReportAround {
    func around() throws -> AroundMsg? {
        if let around = try AroundMsg.makeQuery().filter("id", around_id).first() {
            return around
        } else {
            return nil
        }
    }
}
extension ReportAround {
    func makeJSON(_ type : JsonType) throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("around", around()?.makeJSON(.user))
        try json.set("last_at", last_at)
        try json.set("rcount", rcount)
        return json
    }
}
extension ReportAround: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.int("rcount")
            users.int("around_id")
            users.int("last_at")
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
