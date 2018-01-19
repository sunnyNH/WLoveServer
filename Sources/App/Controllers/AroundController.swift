//
//  AroundController.swift
//  NHServer
//
//  Created by niuhui on 2017/5/14.
//
//

import Vapor
import HTTP
import Foundation
class AroundController {
    
    func registeredRouting() {
        let tokenAround = token.grouped("around")
        let around      = v1.grouped("around")
        around.get("message", handler: self.getAroundMsgs)
        tokenAround.post("message", handler: self.postAroundMsgs)
        tokenAround.get("message","up", handler: self.getAroundMsgUp)
        tokenAround.get("user","message", handler: self.getUserAroundMsgs)
        tokenAround.get("message","detail", handler:self.getAroundDetail)
        tokenAround.delete("message", handler: self.deleteAround)
        tokenAround.get("message","up","user", handler: self.getAroundMsgUpUser)
    }
    //MARK: 获取所有动态
    func getAroundMsgs(_ request: Request) throws -> ResponseRepresentable {
        print(request.query ?? "没有参数")
        var arounds = [AroundMsg]()
        var aroundQuery = try AroundMsg.makeQuery().filter("state", 0).sort("create_at", .descending)
        if let subway_id = request.data["subway_id"]?.int {
            aroundQuery = try aroundQuery.filter("subway_id", subway_id)
        }
        if let key = request.data["key"]?.string {
            aroundQuery = try aroundQuery.filter("message", .contains, key)
        }
        if let file_type = request.data["file_type"]?.int {
            if file_type == 1 {
                aroundQuery = try aroundQuery.or({ (orQuery) in
                    try orQuery.filter("file_type", file_type)
                    try orQuery.filter("video", .notEquals, "")
                })
            } else {
                aroundQuery = try aroundQuery.filter("file_type", file_type)
            }
        }
        if var page = request.data["pagenum"]?.int  {
            if page == 0 {
                page = 1
            }
            arounds = try aroundQuery.limit(20, offset: 20*(page - 1)).all()
        } else {
            arounds = try aroundQuery.limit(20, offset: 0).all()
        }
        if let user = try request.user() {
            
            for around in arounds {
                if let _ = try AroundMsgUp.makeQuery().filter("uuid", user.uuid).filter("around_id", around.id!).first() {
                    around.is_up = true
                } else {
                    around.is_up = false
                }
            }
        }
        return try JSON(node: [
            "arounds": arounds.map{try $0.makeJSON(.user)}
            ]).success()
    }
    //MARK: 获取user的动态
    func getUserAroundMsgs(_ request: Request) throws -> ResponseRepresentable {
        var arounds = [AroundMsg]()

        let user = try request.user()!
        var aroundQuery = try AroundMsg.makeQuery()
        if let uuid = request.data["uuid"]?.string {
            aroundQuery = try aroundQuery.filter("uuid", uuid).filter("state", 0).sort("create_at", .descending)
        } else {
            aroundQuery = try aroundQuery.filter("uuid", user.uuid).filter("state",.notEquals, 3).sort("create_at", .descending)
        }
        var pageSize : Int = 20
        if let size = request.data["pagesize"]?.int,size != 0 {
            pageSize = size
        }
        if var page = request.data["pagenum"]?.int  {
            if page == 0 {
                page = 1
            }
            arounds = try aroundQuery.limit(pageSize, offset: pageSize*(page - 1)).all()
        } else {
            arounds = try aroundQuery.limit(pageSize, offset: 0).all()
        }
        return try JSON(node: [ code: 0,msg: "success","arounds": arounds.map{try $0.makeJSON(.user)}])
    }
    ///MARK: 单个获取around
    func getAroundDetail(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        guard let around_id = request.data["around_id"]?.int else {
            return try JSON(node: [ code: 1,msg : "缺少参数"])
        }
        guard let around = try AroundMsg.makeQuery().filter("id", around_id).first() else {
            return try JSON(node: [ code: 1,  msg : "动态不存在"])
        }
        if around.state == 3 {
            return try JSON(node: [code: 1,msg : "原动态已被作者删除"])
        }
        if around.state == 2 && around.uuid != user.uuid {
            return try JSON(node: [code: 1, msg : "原动态已被作者私有"])
        }
        if around.state == 4 && around.uuid != user.uuid {
            return try JSON(node: [ code: 1,msg : "原动态已被举报" ])
        }
        return try JSON(node: [code: 0, msg: "success","around": around.makeJSON(.user)])
    }
    //MARK: 发布动态
    func postAroundMsgs(_ request: Request) throws -> ResponseRepresentable {
        let user = try request.user()
        let around = AroundMsg(uuid: (user?.uuid)!)
        if let message = request.data["message"]?.string {
            around.message = message
        }
        if let images = request.data["images"]?.string {
            around.images = images
        }
        if let address = request.data["address"]?.string {
            around.address = address;
        }
        if let subway_id = request.data["subway_id"]?.int {
            around.subway_id = subway_id;
        }
        if let device = request.data["device"]?.string {
            around.device = device;
        }
        if let video = request.data["video"]?.string {
            around.video = video;
        }
        if let file_type = request.data["file_type"]?.int {
            around.file_type = file_type;
        }
        if let files = request.data["files"]?.string {
            around.files = files;
        }
        around.create_at = Int(Date().timeIntervalSince1970)
        try around.save()
        JPushTool.sendAroundPush(user, around: around)
        return try JSON(node: [code: 0,msg: "success", "id": around.id?.int ?? 0,
            ])
    }
    //MARK: 点赞，取消点赞
    func getAroundMsgUp(_ request: Request) throws -> ResponseRepresentable {
        
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        guard let around_id = request.data["around_id"]?.int  else {
            return try JSON(node: [ code: 1, msg : "缺少参数"])
        }
        guard let around = try AroundMsg.makeQuery().filter("id", around_id).first() else {
            return try JSON(node: [ code: 1,msg : "动态不存在"])
        }
        if let around_up = try AroundMsgUp.makeQuery().filter("uuid", user.uuid).filter("around_id", around_id).first() {
            try around_up.delete()
            around.ups_count -= 1
            try around.save()
            return try JSON(node: [code: 0,msg : "success","is_up": false,])
        } else {
            let around_up = AroundMsgUp(user: user, around_id: around_id)
            try around_up.save()
            around.ups_count += 1
            try around.save()
            return try JSON(node: [code: 0,msg : "success","is_up": true,])
        }
        
    }
    //MARK: 获取点赞的列表
    func getAroundMsgUpUser(_ request: Request) throws -> ResponseRepresentable {
        guard let around_id = request.data["around_id"]?.int  else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        guard (try AroundMsg.makeQuery().filter("id", around_id).first()) != nil else {
            return try JSON(node: [code: 1,msg : "动态不存在"])
        }
        var ups = [AroundMsgUp]()
        let upQuery = try AroundMsgUp.makeQuery().filter("around_id", around_id).sort("create_at", .descending)
        var pageSize : Int = 20
        if let size = request.data["pagesize"]?.int,size != 0 {
            pageSize = size
        }
        if var page = request.data["pagenum"]?.int  {
            if page == 0 {
                page = 1
            }
            ups = try upQuery.limit(pageSize, offset: pageSize*(page - 1)).all()
        } else {
            ups = try upQuery.limit(pageSize, offset: 0).all()
        }
        return try JSON(node: [code: 0,msg : "success","ups": ups.map{try $0.makeJSON(.user)}
            ])
    }
    func deleteAround(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        guard let around_id = request.data["around_id"]?.int  else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        guard let around = try AroundMsg.makeQuery().filter("id", around_id).first() else {
            return try JSON(node: [code: 1,msg : "动态不存在"])
        }
        if user.uuid == around.uuid {
            around.state = 3;
            try around.save()
            return try JSON(node: [code: 0,msg : "success"])
        } else {
            return try JSON(node: [code: 1,msg : "不能删除他人的动态"])
        }
    }
}
