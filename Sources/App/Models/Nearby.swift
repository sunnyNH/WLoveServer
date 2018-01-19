//
//  Nearby.swift
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

final class Nearby: Model {
    static let entity = "Nearbys"
    let storage = Storage()
    /// 用户id
    var uuid      : String = ""
    //维度
    var lat       : Double = 0.0
    //经度
    var lng       : Double = 0.0
    /// 更新时间
    var update_at : Int    = 0
    var distance      : Double = 0.0
    init(row: Row) throws {
        uuid = try row.get("uuid")
        lat = try row.get("lat")
        lng = try row.get("lng")
        update_at = try row.get("update_at")
        distance = try row.get("distance")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(user: User,lng : Double,lat :  Double) {
        self.uuid   = user.uuid
        self.lng    = lng
        self.lat    = lat
        self.update_at = Int(Date().timeIntervalSince1970)
    }
    required init(node: Node) throws {
        id          = try node.get("id")
        uuid        = try node.get("uuid")
        lat         = try node.get("lat")
        lng         = try node.get("lng")
        update_at   = try node.get("update_at")
        distance    = try node.get("distance")
    }
}
extension Nearby {
    func makeJSON(_ type : JsonType) throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("user", user()?.makeJSON(.user))
        try json.set("lat", lat)
        try json.set("lng", lng)
        try json.set("update_at", update_at)
        try json.set("distance", distance)
        return json
    }
}
extension Nearby {
    func user() throws -> User? {
        return try RedisTool.getUser(uuid)
    }
}
extension Nearby: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.string("uuid",unique:true)
            users.double("lng")
            users.double("lat")
            users.double("distance")
            users.int("update_at")
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
