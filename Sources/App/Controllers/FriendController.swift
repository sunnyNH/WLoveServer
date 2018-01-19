//
//  FriendController.swift
//  NHServer
//
//  Created by niuhui on 2017/7/2.
//
//

import Vapor
import HTTP
import Foundation
class FriendController {
    func registeredRouting() {
        let friend = token.grouped("friend")
        friend.get(handler: self.getMyFriends)
        //待确定的
        friend.get("combo", handler: self.getMyComboFriends)
        //添加好友请求
        friend.post("add", handler: self.postAddFriend)
        //同意好友请求
        friend.post("agree", handler: self.postAgreeFriend)
        //拒绝好友请求
        friend.post("refuse", handler: self.postRefuseFriend)
        //获取好友的around
        friend.get("around", handler: self.getMyFriendAounds)
        friend.get("combo","count", handler: self.getMyComboCount)
    }
    func getMyFriends(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        let friends = try Friend.makeQuery().filter("m_uuid", user.uuid).filter("state", .notEquals, 0).all()
        return try JSON(node: [code: 0,msg : "success","friends" : friends.map{try $0.makeJSON(.user)}])
    }
    func postAddFriend(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"])  }
        guard let uuid = request.data["uuid"]?.string  else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        guard let f_user = try User.makeQuery().filter("uuid", uuid).first() else {
            return try JSON(node: [code: 1,msg : "用户不存在"])
        }
        if let m_friend = try Friend.makeQuery().filter("m_uuid", user.uuid).filter("f_uuid", f_user.uuid).first() {
            if m_friend.state == 1 {
                return try JSON(node: [code: 1,msg: "已经是好友了",])
            } else if m_friend.state == 4 || m_friend.state == 0 {
                if let friendNotice = try FriendNotice.makeQuery().filter("m_uuid", user.uuid).filter("f_uuid", f_user.uuid).first() {
                    friendNotice.create_at = Int(Date().timeIntervalSince1970)
                    friendNotice.state = 0
                    friendNotice.f_delete = false
                    friendNotice.m_delete = false
                    if let message = request.data["message"]?.string {
                        friendNotice.message = message
                    }
                    try friendNotice.save()
                    if let not_id = friendNotice.id?.int  {
                        if (try FriendNoticeCount.makeQuery().filter("uuid", f_user.uuid).filter("f_not_id", not_id).first()) == nil {
                            let f_not_count =  FriendNoticeCount(uuid: f_user.uuid, f_not: friendNotice)
                            try f_not_count.save()
                        }
                    }
                    JPushTool.addFriendPush(user, f_user: f_user)
                    return try JSON(node: [code: 0,msg: "success",])
                }
                let friendNotice = FriendNotice(m_uuid: user.uuid, f_uuid: f_user.uuid)
                if let message = request.data["message"]?.string {
                    friendNotice.message = message
                }
                try friendNotice.save()
                let f_not_count =  FriendNoticeCount(uuid: f_user.uuid, f_not: friendNotice)
                try f_not_count.save()
                JPushTool.addFriendPush(user, f_user: f_user)
                return try JSON(node: [code: 0,msg: "success",])
            } else if m_friend.state == 2 {
                return try JSON(node: [code: 1,msg: "请到黑名单，移除对方",])
            } else {
                return try JSON(node: [code: 1, msg: "被对方拉黑了",])
            }
        } else {
            if let friendNotice = try FriendNotice.makeQuery().filter("m_uuid", user.uuid).filter("f_uuid", f_user.uuid).first() {
                friendNotice.create_at = Int(Date().timeIntervalSince1970)
                friendNotice.state = 0
                friendNotice.f_delete = false
                friendNotice.m_delete = false
                if let message = request.data["message"]?.string {
                    friendNotice.message = message
                }
                try friendNotice.save()
                if let not_id = friendNotice.id?.int  {
                    if (try FriendNoticeCount.makeQuery().filter("uuid", f_user.uuid).filter("f_not_id", not_id).first()) == nil {
                        let f_not_count =  FriendNoticeCount(uuid: f_user.uuid, f_not: friendNotice)
                        try f_not_count.save()
                    }
                }
                JPushTool.addFriendPush(user, f_user: f_user)
                return try JSON(node: [code: 0,msg: "success",])
            }
            let friendNotice = FriendNotice(m_uuid: user.uuid, f_uuid: f_user.uuid)
            if let message = request.data["message"]?.string {
                friendNotice.message = message
            }
            try friendNotice.save()
            let f_not_count =  FriendNoticeCount(uuid: f_user.uuid, f_not: friendNotice)
            try f_not_count.save()
            JPushTool.addFriendPush(user, f_user: f_user)
            return try JSON(node: [code: 0, msg: "success"])
        }
    }
    func postAgreeFriend(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        guard let f_uuid = request.data["user_id"]?.string else {
            return try JSON(node: [ code: 1, msg : "缺少参数"])
        }
        guard let f_user = try User.makeQuery().filter("uuid", f_uuid).first() else {
            return try JSON(node: [code: 1,msg : "用户不存在"])
        }
        if let friendNotice = try FriendNotice.makeQuery().filter("m_uuid", f_user.uuid).filter("f_uuid", user.uuid).first() {
            friendNotice.state = 1
            try friendNotice.save()
        }
        if let m_friend = try Friend.makeQuery().filter("m_uuid", user.uuid).filter("f_uuid", f_user.uuid).first()  {
            m_friend.state = 1
            try m_friend.save()
        } else {
            let m_friend = Friend(m_uuid: user.uuid, f_uuid: f_user.uuid)
            m_friend.state = 1
            try m_friend.save()
        }
        if let f_friend = try Friend.makeQuery().filter("m_uuid", f_user.uuid).filter("f_uuid", user.uuid).first() {
            f_friend.state = 1
            try f_friend.save()
        } else {
            let f_friend = Friend(m_uuid: f_user.uuid, f_uuid: user.uuid)
            f_friend.state = 1
            try f_friend.save()
        }
        JPushTool.agreeFriendPush(user, f_user: f_user)
        return try JSON(node: [code: 0,msg : "success",])
    }
    func postRefuseFriend(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"])  }
        guard let f_uuid = request.data["user_id"]?.string else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        guard let f_user = try User.makeQuery().filter("uuid", f_uuid).first() else {
            return try JSON(node: [code: 1,msg : "用户不存在"])
        }
        guard let friendNotice = try FriendNotice.makeQuery().filter("m_uuid", f_user.uuid).filter("f_uuid", user.uuid).first() else {
            return try JSON(node: [code: 1,msg : "好友请求不存在"])
        }
        JPushTool.refuseFriendPush(user, f_user: f_user)
        friendNotice.state = 2
        try friendNotice.save()
        return try JSON(node: [code: 0, msg : "success",])
    }
    func getMyComboFriends(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        let friends = try FriendNotice.makeQuery().or({ (orQuery) in
            try orQuery.and({ andQuery in
                try andQuery.filter("m_uuid", user.uuid)
                try andQuery.filter("m_delete", false)
            })
            try orQuery.and({ andQuery in
                try andQuery.filter("f_uuid", user.uuid)
                try andQuery.filter("f_delete", false)
            })
        }).sort("state", .ascending).sort("create_at", .ascending).all()
        try FriendNoticeCount.makeQuery().filter("uuid", user.uuid).delete()
        return try JSON(node: [code: 0,msg : "success","notices" : friends.map{try $0.makeJSON(.user, uuid: user.uuid)}])
    }
    func getMyComboCount(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        return try JSON(node: [code: 0,msg : "success","count" : FriendNoticeCount.makeQuery().filter("uuid", user.uuid).count()])
    }
    func getMyFriendAounds(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        let friends = try Friend.makeQuery().filter("m_uuid", user.uuid).filter("state", .notEquals, 0).all()
        let f_uuids = friends.map{$0.f_uuid}
        var arounds = [AroundMsg]()
        if f_uuids.count == 0 {
            return try JSON(node: [code: 0,msg: "success","arounds": arounds.map{try $0.makeJSON(.user)}])
        }
        var aroundQuery = try AroundMsg.makeQuery().filter("uuid", in: f_uuids).filter("state", 0).sort("create_at", .descending)
        if let subway_id = request.data["subway_id"]?.int {
            aroundQuery = try aroundQuery.filter("subway_id", subway_id)
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
                }
            }
        }
        return try JSON(node: [ code: 0,msg: "success","arounds": arounds.map{try $0.makeJSON(.user)}])
    }    
}
