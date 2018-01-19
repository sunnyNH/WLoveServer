//
//  NoticeController.swift
//  NHServer
//
//  Created by niuhui on 2017/6/25.
//
//

import Vapor
import HTTP
import Foundation

class NoticeController {

    func registeredRouting() {
        let tokenAround = token.grouped("around")
        tokenAround.get("notice", handler: self.getNotice)
        tokenAround.get("notice","count", handler: self.getNoticeCount)
    }
    func getNotice(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        let notes = try AroundNotice.makeQuery().filter("uuid", user.uuid).sort("create_at", .descending).all()
        try AroundNotice.makeQuery().filter("uuid", user.uuid).delete()
        return try JSON(node: [
            code: 0,
            msg: "success",
            "notes": notes.map{try $0.makeJSON(.user)}
            ])
    }
    func getNoticeCount(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        let noteCount = try AroundNotice.makeQuery().filter("uuid", user.uuid).count()
        return try JSON(node: [
            code: 0,
            msg: "success",
            "count": noteCount
            ])
    }
}
