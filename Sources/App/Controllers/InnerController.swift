//
//  InnerController.swift
//  App
//
//  Created by 牛辉 on 2017/12/10.
//

import Vapor
import HTTP
import Crypto
import Foundation

class InnerController {
    
    
    let eModel = EModel.share
    func registeredRouting() {
        v1.post("inner","signup", handler: self.signup)
        v1.post("inner","signin", handler: self.signin)
        v1.post("inner","accesstoken",handler: self.accessToekn)
    }
    func accessToekn(_ request: Request) throws -> ResponseRepresentable {
        if request.ip == "0.0.0.0" {
            guard let token = request.data["token"]?.string else{ return try JSON(node: [code: 1,msg: "缺少token"])}
            guard let session = try Session.makeQuery().filter("token", token).first() else{ return try JSON(node: [code: 1,msg: "校验失败"])}
            return try JSON(node: [code: 0,
                                   msg: "success",
                                   "user_id":session.uuid
                                ]
            )
        } else {
            return try JSON(node: [code: 1,msg : "限制访问"])
        }
    }
    func signup(_ request: Request) throws -> ResponseRepresentable {
        guard let phone = request.data["phone"]?.string else{ return try JSON(node: [code: 1,msg: "缺少phone"])}
        let temp = try User.makeQuery().filter("phone", phone).first()
        guard temp == nil else{ return try JSON(node: [code: 1,msg: "此电话号码已被注册"])}
        guard let pw = request.data["pw"]?.string else{return try JSON(node: [code: 1,msg: "缺少密码"])}
        if pw.isPassWord == false { return try JSON(node: [code: 1,msg : "请输入6-20位数组或字母的密码"])}
        let user = User(phone: phone, pw: pw)
        try user.save()
        //是否成功注册环信
        user.isERegister = try eModel.registerUser(user.uuid, passWord: user.password)
        let session = Session(user:user)
        if let jpush_id = request.data["jpush_id"]?.string {
            session.jpush_id = jpush_id
        }
        if let push_token = request.data["push_token"]?.string {
            session.push_token = push_token
        }
        try session.save()
        try user.save()
        try RedisTool.save(user)
        try RedisTool.save(session)
        return try JSON(node: [
            code: 0,
            "token": session.token,
            "uuid" : user.uuid,
            "expire_at" : session.expire_at,
            "em_pw"     : user.password,
            msg : "success"
            ])
    }
    func signin(_ request: Request) throws -> ResponseRepresentable {
        guard let phone = request.data["phone"]?.string else{
            return try JSON(node: [code: 1,msg : "缺少phone"])
        }
        guard let user =  try User.makeQuery().filter("phone", phone).first() else {
            return try JSON(node: [code: 1,msg : "未注册"])
        }
        guard let pw = request.data["pw"]?.string else{
            return try JSON(node: [code: 1,msg : "缺少密码"])
        }
        if pw.isPassWord == false {
            return try JSON(node: [code: 1,msg : "请输入6-20位数组或字母的密码"])
        }
        guard user.password == pw.md5 else {
            return try JSON(node: [code: 1,msg : "密码错误"])
        }
        if user.isERegister == false {
            user.isERegister = try eModel.registerUser(user.uuid, passWord: user.password)
            try user.save()
        }
        let session = Session.session(user: user)
        if let jpush_id = request.data["jpush_id"]?.string {
            session.jpush_id = jpush_id
        }
        if let push_token = request.data["push_token"]?.string {
            session.push_token = push_token
        }
        try session.save()
        try RedisTool.save(user)
        try RedisTool.save(session)
        return try JSON(node: [
            code: 0,
            "uuid" : user.uuid,
            "expire_at" : session.expire_at,
            "token": session.token,
            "em_pw"     : user.password,
            msg : "success"
            ])
    }
}
