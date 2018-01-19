//
//  FeedBackController.swift
//  NHServer
//
//  Created by niuhui on 2017/7/24.
//
//

import Vapor
import HTTP
import Foundation
class FeedBackController {

    func registeredRouting() {
        token.post("feedback", handler: self.postFeedBack)
        token.get("feedback", handler: self.getFeedBacks)
    }
    func postFeedBack(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        
        guard let message = request.data["message"]?.string  else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        let feedBack = FeedBack(user: user, msg: message);
        try feedBack.save()
        return try JSON(node: [code: 0,msg: "success","id": feedBack.id?.int ?? 0,])
    }
    func getFeedBacks(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        if user.phone != "" {
            return try JSON(node: [code: 1,msg : "您没有权限查看"])
        }
        var feedBacks = [FeedBack]()
        let feedQuery = try FeedBack.makeQuery().sort("create_at", .descending)
        if var page = request.data["pagenum"]?.int  {
            if page == 0 {
                page = 1
            }
            feedBacks = try feedQuery.limit(20, offset: 20*(page - 1)).all()
        } else {
            feedBacks = try feedQuery.limit(20, offset: 0).all()
        }
        return try JSON(node: [code: 0,msg: "success","arounds": feedBacks.map{try $0.makeJSON(.user)},])
    }
}
