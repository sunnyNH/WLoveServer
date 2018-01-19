//
//  File.swift
//  App
//
//  Created by 牛辉 on 2017/12/3.
//

import Vapor
import FluentProvider
import Foundation
import HTTP


final class File: Model {
    static let entity = "Files"
    let storage = Storage()
    //1.图片 2.gif 3.视频
    var type            : Int       = 0
    /**
     //图片地址 http://www.walkinglove.com/download/image/15ddfa3903200e1ce8b7995857c6c0b3.png
     //gif地址 http://www.walkinglove.com/download/image/15ddfa3903200e1ce8b7995857c6c0b3.gif
     //视频地址 http://www.walkinglove.com/download/image/15ddfa3903200e1ce8b7995857c6c0b3.mp4
     */
    var url             : String    = ""
    /**
     //图片 {"width": 100,"height": 100}
     //gif {"width": 100,"height": 100}
     //视频 {"width": 100,"height": 100,"duration":40,"url":""}
     */
    var content         : String    = ""
    var create_at       : Int       = 0
    init(row: Row) throws {
        type = try row.get("type")
        url = try row.get("url")
        content = try row.get("content")
        create_at = try row.get("create_at")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
    init(url: String,content: String,type:Int) {
        self.url        = url
        self.create_at  = Int(Date().timeIntervalSince1970)
        self.content    = content
        self.type       = type;
    }
    init(url: String,type:Int) {
        self.url        = url
        self.create_at  = Int(Date().timeIntervalSince1970)
        self.type       = type;
    }
}
extension File {
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("type", type)
        try json.set("url", url)
        try json.set("content", content)
        try json.set("create_at", create_at)
        return json
    }
}
extension File: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.string("url")
            users.string("content",length: 500)
            users.int("type")
            users.int("create_at")
        }
    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
