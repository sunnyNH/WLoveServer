//
//  User.swift
//  App
//
//  Created by 牛辉 on 2018/4/21.
//

import Vapor
import FluentMySQL

final class User: MySQLModel {
    
    var id: Int?
    //uuid
    var uuid    : String = ""
    /// 电话
    var phone   : String = ""
    /// 密码
    var password: String = ""
    /// 名字
    var name    : String = ""
    /// 头像
    var avatar  : String = ""
    /// 年龄
    var age     : Int    = 0
    /// 性别
    var gender  : Int    = 0
    /// 简介
    var overview: String = ""
    /// 地址
    var address   : String = ""
    //注册时间
    var create_at        = 0
}
extension User: Migration {
    public static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.uuid)
        }
    }
}
extension User: Content { }
extension User: Parameter { }
