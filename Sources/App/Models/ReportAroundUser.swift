//
//  ReportAroundUser.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/6.
//
//

import Vapor
import FluentProvider
import Foundation
import HTTP

final class ReportAroundUser: Model {
    static let entity = "ReportAroundUsers"
    let storage = Storage()
    var reportAround_id     : Int       = 0
    var create_at           : Int       = 0
    var uuid                : String    = ""
    init(row: Row) throws {
        reportAround_id = try row.get("reportAround_id")
        create_at = try row.get("create_at")
        uuid = try row.get("uuid")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(reportAround_id: Int?,uuid: String) {
        self.create_at              = Int(Date().timeIntervalSince1970)
        if let report_id            = reportAround_id {
            self.reportAround_id    = report_id
        }
        self.uuid                   = uuid
    }
}
extension ReportAroundUser: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.int("create_at")
            users.int("reportAround_id")
            users.string("uuid")
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
