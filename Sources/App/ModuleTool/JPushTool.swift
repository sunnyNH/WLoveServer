//
//  JPushTool.swift
//  NHServer
//
//  Created by niuhui on 2017/6/22.
//
//

import Vapor
import HTTP
import Foundation
import Crypto
let jUrl : String = "https://api.jpush.cn/v3/push"
struct JPushTool {
    private static func pushMsg(_ regus_ids: [String] , msg: String) {
        do {
            var apns_production: JSON = false
            if drop.config.environment != .production {
                apns_production = false
            } else {
                apns_production = true
            }
            let pushMsg : JSON = try [
                "platform":"ios",
                "audience":[
                    "registration_id":JSON(regus_ids.makeNode(in: nil))
                ],
                "notification":[
                    "ios":[
                        "alert":JSON(msg),
                        "sound":"default",
                        "badge":"1"
                    ]
                ],
                "options":[
                    "apns_production":apns_production
                ]
            ]
            if let jkey = drop.config["app","JPushKey"]?.string {
                let jHeader : [HeaderKey : String] = ["Authorization":jkey]
                let req = try drop.client.post(jUrl, jHeader, pushMsg.makeBody())
                print(req)
            }
        } catch {
            
        }
    }
    static func sendAroundPush(_ user : User?,around: AroundMsg) {
        background {
            do {
                if let user = user {
                    if let friends = try? Friend.makeQuery().filter("m_uuid", user.uuid).filter("state", .notEquals, 0).all() {
                        if friends.count == 0 {
                            print("没有好友")
                        }
                        let uuids = friends.map{$0.f_uuid}
                        if uuids.count == 0 {
                            print("没有uuids")
                        }
                        let sessions = try Session.makeQuery().filter("expire_at",.notEquals,0).filter("jpush_id", .notEquals, "").filter("uuid", in: uuids).all()
                        var temp = ""
                        if around.message.count <= 40 {
                            temp = around.message
                        } else {
                            let index = around.message.index(around.message.startIndex, offsetBy: 40)
                            temp = around.message.substring(to: index)
                        }
                        if around.message.isEmpty && !around.images.isEmpty {
                            temp = "图片动态"
                        }
                        temp = "【\(user.name)的动态】\(temp)"
                        let ids = sessions.map{$0.jpush_id}
                        if ids.count == 0 {
                            print("没有 jpush_ids")
                        } else {
                            pushMsg(ids, msg: temp)
                        }
                    } else {
                        print("没有好友")
                    }
                }
            } catch {
                
            }
        }
    }
    static func commentAroundPush(_ user: User, around: AroundMsg,commemt: AroundComment) {
        background {
            do {
                if let com_user_session = try Session.makeQuery().filter("uuid", commemt.com_uuid).filter("expire_at",.notEquals,0).filter("jpush_id", .notEquals, "").first() {
                    var temp = ""
                    if commemt.message.count <= 40 {
                        temp = commemt.message
                    } else {
                        let index = commemt.message.index(commemt.message.startIndex, offsetBy: 40)
                        temp = commemt.message.substring(to: index)
                    }
                    temp = "【\(user.name)回复了你的评论】\(temp)"
                    pushMsg([com_user_session.jpush_id], msg: temp)
                } else {
                    if let session = try Session.makeQuery().filter("uuid", around.uuid).filter("expire_at",.notEquals,0).filter("jpush_id", .notEquals, "").first() {
                        var temp = ""
                        if commemt.message.count <= 40 {
                            temp = commemt.message
                        } else {
                            let index = commemt.message.index(commemt.message.startIndex, offsetBy: 40)
                            temp = commemt.message.substring(to: index)
                        }
                        temp = "【\(user.name)的评论】\(temp)"
                        pushMsg([session.jpush_id], msg: temp)
                    }
                }
            } catch {
                
            }
            
        }
    }
    static func addFriendPush(_ user: User, f_user: User) {
        background {
            do {
                if let session = try Session.makeQuery().filter("uuid", f_user.uuid).filter("expire_at",.notEquals,0).filter("jpush_id", .notEquals, "").first() {
                    pushMsg([session.jpush_id], msg: "【\(user.name)】请求添加好友，快去看看吧！")
                }
            } catch {
                
            }
        }
    }
    static func refuseFriendPush(_ user: User, f_user: User) {
        background {
            do {
                if let session = try Session.makeQuery().filter("uuid", f_user.uuid).filter("expire_at",.notEquals,0).filter("jpush_id", .notEquals, "").first() {
                    pushMsg([session.jpush_id], msg: "【\(user.name)】拒绝了你的好友请求，快去看看吧！")
                }
            } catch {
                
            }
        }
    }
    static func agreeFriendPush(_ user: User, f_user: User) {
        background {
            do {
                if let session = try Session.makeQuery().filter("uuid", f_user.uuid).filter("expire_at",.notEquals,0).filter("jpush_id", .notEquals, "").first() {
                    pushMsg([session.jpush_id], msg: "【\(user.name)】同意你的好友请求，成为好友！")
                }
            } catch {
                
            }
        }
    }
}
