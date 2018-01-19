//
//  CommentController.swift
//  NHServer
//
//  Created by niuhui on 2017/6/13.
//
//

import Vapor
import HTTP
import Foundation
class CommentController {
    
    func registeredRouting() {
        let tokenAround = token.grouped("around")
        tokenAround.post("message","comment", handler: self.postAroundComment)
        tokenAround.get("message","comment", handler: self.getAroundCommtent)
        tokenAround.get("message","comment","up", handler: self.getAroundComUp)
        tokenAround.delete("message","comment", handler: self.deleteAroundCom)
    }
    //MARK: 评论动态
    func postAroundComment(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        guard let around_id = request.data["around_id"]?.int,let message = request.data["message"]?.string  else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        guard let around = try AroundMsg.makeQuery().filter("id", around_id).first() else {
            return try JSON(node: [code: 1,msg : "动态不存在"])
        }
        if let com_uuid = request.data["com_uuid"]?.string {
            guard let com_user = try User.makeQuery().filter("uuid", com_uuid).first() else {
                return try JSON(node: [code: 1,msg : "回复的用户不存在"])
            }
            let commnet = AroundComment(user: user, around_id: around_id, msg: message)
            commnet.com_uuid = com_user.uuid
            try commnet.save()
            around.com_count += 1
            try around.save()
            if commnet.uuid != commnet.com_uuid {
                JPushTool.commentAroundPush(user, around: around,commemt: commnet)
                let note = AroundNotice(around: around, comt: commnet)
                try note.save()
            }
            return try JSON(node: [code: 0,msg: "success","id": commnet.id?.int ?? 0,])
        }
        let commnet = AroundComment(user: user, around_id: around_id, msg: message)
        try commnet.save()
        around.com_count += 1
        try around.save()
        if around.uuid != user.uuid {
            JPushTool.commentAroundPush(user, around: around,commemt: commnet)
            let note = AroundNotice(user: user, around: around, comt: commnet)
            try note.save()
        }
        return try JSON(node: [code: 0,msg: "success","id": commnet.id?.int ?? 0,])
    }
    //MARK: 获取动态评论
    func getAroundCommtent(_ request: Request) throws -> ResponseRepresentable {
        guard let around_id = request.data["around_id"]?.int else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        guard (try AroundMsg.makeQuery().filter("id", around_id).first()) != nil else {
            return try JSON(node: [code: 1,msg : "动态不存在"])
        }
        var comments = [AroundComment]()
        let aroundQuery = try AroundComment.makeQuery().filter("around_id",around_id).sort("create_at", .descending)
        if var page = request.data["pagenum"]?.int  {
            if page == 0 {
                page = 1
            }
            comments = try aroundQuery.limit(20, offset: 20*(page - 1)).all()
        } else {
            comments = try aroundQuery.limit(20, offset: 0).all()
        }
        if let user = try request.user() {
            for com in comments {
                if let _ = try AroundComUp.makeQuery().filter("uuid", user.uuid).filter("com_id", com.id!).first() {
                    com.is_up = true
                } else {
                    
                }
            }
        }
        return try JSON(node: [code: 0,msg: "success","comments": comments.map{try $0.makeJSON(.user)},])
    }
    //MARK: 点赞，取消点赞
    func getAroundComUp(_ request: Request) throws -> ResponseRepresentable {
        
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        guard let com_id = request.data["com_id"]?.int  else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        guard let com = try AroundComment.makeQuery().filter("id", com_id).first() else {
            return try JSON(node: [code: 1,msg : "评论不存在"])
        }
        if let com_up = try AroundComUp.makeQuery().filter("uuid", user.uuid).filter("com_id", com_id).first() {
            try com_up.delete()
            com.ups_count -= 1
            try com.save()
            return try JSON(node: [code: 0,msg : "success","is_up": false,])
        } else {
            let com_up = AroundComUp(user: user, com_id: com_id)
            try com_up.save()
            com.ups_count += 1
            try com.save()
            return try JSON(node: [code: 0,msg : "success","is_up": true,])
        }
        
    }
    func deleteAroundCom(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        guard let com_id = request.data["com_id"]?.int  else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        guard let com = try AroundComment.makeQuery().filter("id", com_id).first() else {
            return try JSON(node: [code: 1,msg : "评论不存在"])
        }
        if user.uuid == com.uuid {
            guard let around = try AroundMsg.makeQuery().filter("id", com.around_id).first() else {
                return try JSON(node: [code: 1,msg : "动态不存在"])
            }
            try AroundComUp.makeQuery().filter("com_id", com_id).delete()
            around.com_count -= 1;
            try around.save()
            try com.delete()
            return try JSON(node: [code: 0,msg : "success"])
        } else {
            return try JSON(node: [code: 1,msg : "不能删除他人的评论"])
        }
    }
}
