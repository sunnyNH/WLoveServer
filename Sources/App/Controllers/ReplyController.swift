//
//  ReplyController.swift
//  NHServer
//
//  Created by niuhui on 2017/6/13.
//
//

import Vapor
import HTTP
import Foundation

class ReplyController {
    func registeredRouting() {
        let tokenAround = token.grouped("around")
        tokenAround.post("comment","reply", handler: self.postCommentPeply)
        tokenAround.get("comment","reply", handler: self.getCommentPeply)
    }
    //MARK: 回复评论
    func postCommentPeply(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        guard let com_id = request.data["com_id"]?.int,let message = request.data["message"]?.string  else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        guard let com = try AroundComment.makeQuery().filter("id", com_id).first() else {
            return try JSON(node: [code: 1,msg : "评论不存在"])
        }
        let reply = CommentReply(user: user, com_id: com_id, msg: message)
        try reply.save()
        com.rep_count += 1
        try com.save()
        return try JSON(node: [code: 0,msg: "success","id": reply.id?.int ?? 0,])
    }
    //MARK: 获取评论回复
    func getCommentPeply(_ request: Request) throws -> ResponseRepresentable {
        guard let com_id = request.data["com_id"]?.int else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        guard (try AroundComment.makeQuery().filter("id", com_id).first()) != nil else {
            return try JSON(node: [code: 1,msg : "评论不存在"])
        }
        var replys = [CommentReply]()
        let replyQuery = try CommentReply.makeQuery().filter("com_id", .contains,com_id).sort("create_at", .descending)
        if var page = request.data["pagenum"]?.int  {
            if page == 0 { page = 1}
            replys = try replyQuery.limit(20, offset: 20*(page - 1)).all()
        } else {
            replys = try replyQuery.limit(20, offset: 0).all()
        }
        return try JSON(node: [code: 0,msg: "success","replys": replys.map{try $0.makeJSON(.user)}])
    }
}
