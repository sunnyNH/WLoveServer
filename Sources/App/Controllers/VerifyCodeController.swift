//
//  VerifyCodeController.swift
//  NHServer
//
//  Created by niuhui on 2017/7/26.
//
//
import Vapor
import HTTP
import Foundation
class VerifyCodeController {

    func registeredRouting() {
        v1.post("verifycode", handler: self.postVerifyCode)
    }
    func postVerifyCode(_ request: Request) throws -> ResponseRepresentable {
        guard let phone = request.data["phone"]?.string else {return try JSON(node: [code: 1,msg : "缺少phone"])}
        if phone.isPhone == false {return try JSON(node: [code: 1,msg : "请输入正确的手机号"])}
        guard let vtype = request.data["vtype"]?.string else {return try JSON(node: [code: 1,msg : "缺少参数"])}
        if vtype != "register" && vtype != "forget" {return try JSON(node: [code: 1,msg : "参数错误"])}
        var vcode : VerifyCode!
        if let v_code = try VerifyCode.makeQuery().filter("phone", phone).filter("type", vtype).first() {
            if Int(Date().timeIntervalSince1970) - v_code.create_at < 60  {
                return try JSON(node: [code: 1,msg : "验证码获取频繁"])
            }
            v_code.create_at = Int(Date().timeIntervalSince1970)
            v_code.is_used = false
            v_code.vcount  = 0
            v_code.verify_at = 0
            vcode = v_code
        } else {
            vcode = VerifyCode(phone: phone, type: vtype)
        }
        if !ip_verify(request.ip) {return try JSON(node: [code: 1,msg : "您的ip获取频繁"])}
        if drop.config.environment != .production {
            vcode.code = 111111;
        } else {
            let temp = Int.random(min: 100000, max: 900000)
            vcode.code = temp
        }
        try vcode.save()
        if drop.config.environment != .production {
            return try JSON(node: [code: 0,msg : "success"])
        } else {
            if SendSMS.sendSMS(vcode) {
                return try JSON(node: [code: 0,msg : "success"])
            } else {
                return try JSON(node: [code: 1,msg : "请稍后重试"])
            }
        }
    }
    //MARK: 监测ip
    func ip_verify(_ ip: String) -> Bool
    {
        do {
            if let sms_ip = try SMSIP.makeQuery().filter("ip", ip).first() {
                if sms_ip.last_at.is_toDay_Hour {
                    sms_ip.used_count += 1
                    try sms_ip.save()
                    if sms_ip.used_count > sms_ip.max_count {
                        return false
                    } else {
                        return true
                    }
                } else {
                    sms_ip.last_at = Int(Date().timeIntervalSince1970)
                    sms_ip.max_count = 10
                    sms_ip.used_count = 1
                    try sms_ip.save()
                    return true
                }
            } else {
                let sms_ip = SMSIP(ip: ip)
                try sms_ip.save()
                return true
            }
        } catch {
            return false
        }
    }
    //MARK: 校验  验证码
    class func verify_code(_ phone: String, vcode: Int, type: String) throws -> ResponseRepresentable {
        guard let vCode = try VerifyCode.makeQuery().filter("phone", phone).filter("type", type).first() else {
            return try JSON(node: [code: 1,msg : "验证码不存在"])
        }
        vCode.vcount += 1
        if vCode.vcount >= 3 {
            return try JSON(node: [code: 1,msg : "验证超过3次，请重新获取"])
        }
        if vCode.code != vcode {
            try vCode.save()
            return try JSON(node: [code: 1,msg : "验证码错误"])
        }
        if Int(Date().timeIntervalSince1970) - vCode.create_at > 60*15 {
            return try JSON(node: [code: 1,msg : "验证码已过期"])
        }
        if vCode.is_used {
            return try JSON(node: [code: 1,msg : "验证码已使用"])
        }
        vCode.is_used   = true
        vCode.verify_at = Int(Date().timeIntervalSince1970)
        try vCode.save()
        return try JSON(node: [code: 0,msg : "success"])
    }
}
extension Request {
    //MARK: 获取请求的ip地址
    var ip : String {
        if let ip = self.peerHostname{
            if ip.contains(":") {
            let ips = ip.components(separatedBy: ":")
                return ips[0]
            } else {
                return ip
            }
        } else {
            return ""
        }
    }
}
