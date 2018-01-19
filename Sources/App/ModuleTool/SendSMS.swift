//
//  SendSMS.swift
//  NHServer
//
//  Created by niuhui on 2017/7/26.
//
//
import Vapor
import HTTP
import Foundation

struct SendSMS {
    static func sendSMS(_ code: VerifyCode) -> Bool {
        do {
            let req = try drop.client.get(try smsSign(code))
            print(req)
            if req.status.statusCode == 200 {
                return true
            } else {
                return false;
            }
        } catch {
            return false
        }
    }
    static func smsSign(_ code: VerifyCode) throws -> String {
        var out: [String:String] = [:]
        //系统参数
        out["AccessKeyId"]      = AliOSS.accessKeyId
        out["Timestamp"]        = getDate()
        out["Format"]           = "JSON"
        out["SignName"]         = ""
        out["SignatureMethod"]  = ""
        out["SignatureVersion"] = "1.0"
        out["SignatureNonce"]   = UUID().uuidString.md5
        //业务参数
        out["Action"]           = "SendSms"
        out["Version"]          = "2017-05-25"
        out["RegionId"]         = "cn-hangzhou"
        out["PhoneNumbers"]     = code.phone
        out["TemplateCode"]     = ""
        out["TemplateParam"]    = "{\"code\":\"\(code.code)\"}"
        //1.排序
        let temp:[String] = ["AccessKeyId", "Action", "Format", "PhoneNumbers", "RegionId", "SignName", "SignatureMethod", "SignatureNonce", "SignatureVersion", "TemplateCode", "TemplateParam", "Timestamp", "Version"]
        //2.请求参数
        var outStr = ""
        for key in temp {
            if let value = out[key] {
                if outStr == "" {
                    outStr += "\(strUTF(key))=\(strUTF(value))"
                } else {
                    outStr += "&\(strUTF(key))=\(strUTF(value))"
                }
            }
        }
        //3.签名
        let signStr = "GET&\(strPathUTF("/"))&\(strChangeUTF(outStr))"
        print(signStr)
        let key     = "\(AliOSS.accessKeySecret)&".makeBytes()
        let h       = signStr.makeBytes()
        let beyts   = try CryptoHasher(method: .keyed(.sha1, key: key), encoding: .plain).make(h)
        let str     = beyts.base64Encoded.makeString()
        return "http://dysmsapi.aliyuncs.com/?Signature=\(strPathUTF(str))&\(outStr)"
    }
}

fileprivate func getDate() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    dateFormatter.locale = Locale(identifier: "en_US")
    return dateFormatter.string(from: Date())
}
fileprivate func strUTF(_ str: String) -> String {
    if let temp = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
        return temp.replacingOccurrences(of: "+", with: "%20").replacingOccurrences(of: "*", with: "%2A").replacingOccurrences(of: "%7E", with: "~")
    } else {
        return str
    }
}
fileprivate func strChangeUTF(_ str: String) -> String {
    if let temp = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
        return temp.replacingOccurrences(of: "+", with: "%20").replacingOccurrences(of: "*", with: "%2A").replacingOccurrences(of: "%7E", with: "~").replacingOccurrences(of: "=", with: "%3D").replacingOccurrences(of: "&", with: "%26").replacingOccurrences(of: ":", with: "%253A")
    } else {
        return str
    }
}
fileprivate func strPathUTF(_ str: String) -> String {
    if let temp = str.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
        return temp.replacingOccurrences(of: "+", with: "%20").replacingOccurrences(of: "*", with: "%2A").replacingOccurrences(of: "%7E", with: "~")
    } else {
        return str
    }
}
