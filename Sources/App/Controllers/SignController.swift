//
//  SignController.swift
//  NHServer
//
//  Created by niuhui on 2017/5/10.
//
//

import Vapor
import HTTP
import Foundation
class SignController {
    
    let eModel = EModel.share
    func registeredRouting() {
        v1.post("signup", handler: self.signup)
        v1.post("signin", handler: self.signin)
        v1.post("signup","validate", handler: self.signupValidate)
        v1.post("password","reset", handler: self.resetPassWord)
        token.post("password","change", handler: self.changePassWord)
        //需要登录验证的
        token.get("signout", handler: self.signout)
    }
    func signup(_ request: Request) throws -> ResponseRepresentable {
        guard let phone = request.data["phone"]?.string else{ return try JSON(node: [code: 1,msg: "缺少phone"])}
        if phone.isPhone == false { return try JSON(node: [code: 1,msg: "请输入正确的手机号"])}
        let temp = try User.makeQuery().filter("phone", phone).first()
        guard temp == nil else { return try JSON(node: [code: 1,msg: "此电话号码已被注册"])}
        guard let pw = request.data["pw"]?.string else{return try JSON(node: [code: 1,msg: "缺少密码"])}
        if pw.isPassWord == false { return try JSON(node: [code: 1,msg : "请输入6-20位数组或字母的密码"])}
        guard let vcode = request.data["vcode"]?.int else {return try JSON(node: [code: 1,msg : "缺少验证码"])}
        let req = try VerifyCodeController.verify_code(phone, vcode: vcode, type: "register")
        if let code = try req.makeResponse().json?["code"]?.int,code != 0 {
            return req
        }
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
        print(request.query ?? "没有参数")
        guard let phone = request.data["phone"]?.string else{
            return try JSON(node: [code: 1,msg : "缺少phone"])
        }
        if  phone.isPhone == false {
            return try JSON(node: [code: 1,msg : "请输入正确的手机号"])
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
    func signout(_ request: Request) throws -> ResponseRepresentable {
        let session = try request.userSession()
        try RedisTool.deleteSession(session?.token)
        session?.expire_at = 0
        session?.jpush_id = ""
        session?.push_token = ""
        session?.token = ""
        try session?.save()
        return try JSON(node: [code: 0,msg : "success"])
    }
    func signupValidate(_ request: Request) throws -> ResponseRepresentable {
        print(request.query ?? "没有参数")
        guard let phone = request.data["phone"]?.string else{
            return try JSON(node: [code: 1,msg : "缺少phone"])
        }
        if  phone.isPhone == false {
            return try JSON(node: [code: 1,msg : "请输入正确的手机号"])
        }
        let temp = try User.makeQuery().filter("phone", phone).first()
        guard temp == nil else{
            return try JSON(node: [code: 0,msg : "success","is_signup": true])
        }
        return try JSON(node: [code: 0,msg : "success","is_signup": false])
    }
    func resetPassWord(_ request: Request) throws -> ResponseRepresentable {
        print(request.query ?? "没有参数")
        guard let phone = request.data["phone"]?.string else{
            return try JSON(node: [code: 1,msg: "缺少phone"])
        }
        if phone.isPhone == false {
            return try JSON(node: [code: 1,msg: "请输入正确的手机号"])
        }
        guard let user =  try User.makeQuery().filter("phone", phone).first() else {
            return try JSON(node: [code: 1,msg: "未注册"])
        }
        guard let pw = request.data["pw"]?.string else{
            return try JSON(node: [code: 1,msg : "缺少密码"])
        }
        if pw.isPassWord == false {
            return try JSON(node: [code: 1,msg : "请输入6-20位数组或字母的密码"])
        }
        guard let vcode = request.data["vcode"]?.int else {
            return try JSON(node: [code: 1,msg : "缺少验证码"])
        }
        let req = try VerifyCodeController.verify_code(phone, vcode: vcode, type: "forget")
        if let code = try req.makeResponse().json?["code"]?.int,code != 0 {
            return req
        }
        if user.isERegister {
            if try eModel.changePassWord(user.uuid, passWord: pw.md5) {
                user.password = pw.md5
                try user.save()
                return JSON([code: 0,msg : "success"])
            } else {
                return callFail("修改失败")
            }
        } else {
            user.password = pw.md5
            try user.save()
            return try JSON(node: [code: 0,msg : "success"])
        }
    }
    func changePassWord(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        guard let pw = request.data["pw"]?.string,let pw_lod = request.data["pw_old"]?.string else{
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        if user.password != pw_lod.md5 {
            return try JSON(node: [code: 1,msg : "原密码不正确"])
        }
        if user.isERegister {
            if try eModel.changePassWord(user.uuid, passWord: pw.md5) {
                user.password = pw.md5
                try user.save()
                return try JSON(node: [code: 0,msg : "success"])
            } else {
                return try JSON(node: [code: 1,msg : "修改失败"])
            }
        } else {
            user.password = pw.md5
            try user.save()
            return try JSON(node: [code: 0,msg : "success"])
        }
    }
}
