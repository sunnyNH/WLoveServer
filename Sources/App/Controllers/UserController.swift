//
//  UserController.swift
//  NHServer
//
//  Created by niuhui on 2017/5/9.
//
//
import Vapor
import HTTP

class UserController {
    func registeredRouting() {
        let user = token.grouped("user")
        user.get("profile", handler: self.getProfile)
        user.put("profile", handler: self.putProfile)
    }
    func getProfile(_ request: Request) throws -> ResponseRepresentable {
        
        if let uuid =  request.data["uuid"]?.string {
            if let user = try User.makeQuery().filter("uuid", uuid).first() {
                if let t = request.data["t"]?.string,t == "friend" {
                    var json = try user.makeJSON(.user)
                    if let friend = try Friend.makeQuery().filter("m_uuid", (request.user()?.uuid)!).filter("f_uuid", uuid).first() {
                        json["is_friend"] = true
                        try json.set("friend_state", friend.state)
                    } else {
                        json["is_friend"] = false
                        if let notice = try FriendNotice.makeQuery()
                            .filter("m_uuid", uuid)
                            .filter("f_uuid", (request.user()?.uuid)!)
                            .first()
                            ,notice.state == 0
                        {
                            json["is_combo"] = true
                        }
                    }
                    return JSON([code: 0,msg: "success","user": json])
                }
                return try JSON([code: 0,msg: "success","user": user.makeJSON(.user)])
            } else {
                return JSON([code: 1,msg: "用户不存在"])
            }
        } else {
            guard let user = try request.user() else { return try JSON(node: [code: 1,msg : "用户不存在"]) }
            return try JSON([code: 0,msg: "success","user": user.makeJSON(.me)])
        }
    }
    func putProfile(_ request: Request) throws -> ResponseRepresentable {
        let user = try request.user()
        if let age = request.data["age"]?.int               {user?.age = age}
        if let name = request.data["name"]?.string          {user?.name = name}
        if let overview = request.data["overview"]?.string  {user?.overview = overview;}
        if let gender = request.data["gender"]?.int         {user?.gender = gender}
        if let address = request.data["address"]?.string    {user?.address = address}
        if let avatar = request.data["avatar"]?.string      {user?.avatar = avatar}
        try user?.save()
        try RedisTool.save(user)
        return try JSON(node: [code: 0,msg: "success"])
    }
}
