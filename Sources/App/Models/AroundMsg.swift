//
//  AroundMsg.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/5.
//
//

import Vapor
import FluentProvider
import Foundation
import HTTP


final class AroundMsg: Model {
    static let entity = "Arounds"
    let storage = Storage()
    /// 用户id
    var uuid      : String = ""
    /// 地铁id
    var subway_id : Int = 0
    /// 创建时间
    var create_at : Int = 0
    /// message
    var message   : String = ""
    /// images ,分割
    var images    : String = ""
    /// 地址
    var address   : String = ""
    /// 点赞数
    var ups_count : Int  = 0
    /// 评论数
    var com_count : Int  = 0
    var is_up     : Bool = false
    var device    : String = ""
    /// 状态（0：正常，1：仅好友可见，2：仅自己可见，3：被删除，4：被举报）
    var state     : Int     = 0
    var video     : String = ""
    //文件类型 0图文动态，1是视频动态
    var file_type : Int = 0
    var files       : String = ""
    init(uuid: String) {
        self.uuid = uuid
    }
    init(row: Row) throws {
        uuid = try row.get("uuid")
        subway_id = try row.get("subway_id")
        create_at = try row.get("create_at")
        message = try row.get("message")
        images = try row.get("images")
        address = try row.get("address")
        ups_count = try row.get("ups_count")
        com_count = try row.get("com_count")
        is_up = try row.get("is_up")
        device = try row.get("device")
        state = try row.get("state")
        video = try row.get("video")
        file_type = try row.get("file_type")
        files = try row.get("files")
    }
    func makeRow() throws -> Row {
        return try wildcardRow()
    }
}
extension AroundMsg {
    func makeJSON(_ type : JsonType) throws -> JSON {
        
        let hMirror = Mirror(reflecting: self)
        var json = JSON()
        
        let filesModels = try filesJson()
        // 适配老用户,因为新用户文件开始用file，老用户还在用iamges和video 所有要带上
        if filesModels.count == 1 && video.count == 0 && file_type == 1 {
            let file = filesModels[0]
            video = file.url
        }
        if filesModels.count != 0 && images.count == 0 && file_type == 0 {
            images = filesModels.map{$0.url}.joined(separator: ",")
        }
        if video.count > 0 {
            file_type = 1;
        }
        for case let (label?, value) in hMirror.children {
            switch label {
            case "storage":
                try json.set("id", id)
            case "uuid":
                try json.set("user", user()?.makeJSON(.user))
            case "files":
                try json.set("files",filesModels.map{try $0.makeJSON()})
            default:
                try json.set(label, value)
            }
        }
        return json
    }
}
extension AroundMsg {
    func user() throws -> User? {
        return try RedisTool.getUser(uuid)
    }
    func filesJson() throws -> [File] {
        let fileArr = self.files.components(separatedBy: ",")
        if fileArr.count == 0 || fileArr == [""] {
            return []
        }
        let files = try File.makeQuery().filter("id", in: fileArr).all()
        var outs = [File]()
        for fileId in fileArr {
            let temps = files.filter { $0.id?.string == fileId }
            if let file = temps.first {
                outs.append(file)
            }
        }
        return outs
    }
}
extension AroundMsg: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { users in
            users.id()
            users.string("uuid")
            users.int("subway_id")
            users.int("create_at")
            users.string("message", length: 500)
            users.string("images", length: 1000)
            users.string("address")
            users.int("ups_count")
            users.int("com_count")
            users.bool("is_up")
            users.string("device")
            users.int("state")
            users.string("video")
        }
        try database.index("uuid", for: self)
        try database.index("create_at", for: self)

    }
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
struct addAroundFileType: Preparation {
    static func revert(_ database: Database) throws {}
    static func prepare(_ database: Database) throws {
        try database.modify(AroundMsg.self, closure: { (bar) in
            bar.int("file_type")
            bar.string("files")
        })
        let _  = try AroundMsg.all().map {
            if $0.video.count > 0 {
                $0.file_type = 1
                try $0.save()
            }
        }
    }
}
