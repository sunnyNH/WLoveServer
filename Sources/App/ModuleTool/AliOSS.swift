//
//  AliOSS.swift
//  NHServer
//
//  Created by niuhui on 2017/7/30.
//
//
import Vapor
import Foundation
import Crypto
import HTTP

struct AliOSS {
    
    static let accessKeyId      : String = ""
    static let accessKeySecret  : String = ""
    static let AliOSSUel        : String = ""
    static func upload(_ image: Data,fileName: String) -> Bool {
        do {
            let date = self.getDate()
            let key =  accessKeySecret.makeBytes()
            let h =  "PUT\n\nimage/png\n\(date)\n/这个是oss路径/image/\(fileName)".makeBytes()
            let beyts = try CryptoHasher(method: .keyed(.sha1, key: key), encoding: .plain).make(h)
            let str     =  beyts.base64Encoded.makeString()
            let Header : [HeaderKey : String] = [
                "Authorization" :"OSS \(accessKeyId):\(str)",
                "Date"          :date,
                "Content-Type"  :"image/png"
            ]
            let url = "\(AliOSSUel)/image/\(fileName)"
            let req = try drop.client.put(url, query: [:], Header, Body(image.makeBytes()))
            print(req)
            if req.status.statusCode == 200 {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    static func down(_ fileName: String) throws -> Response {
        let date = self.getDate()
        let key = accessKeySecret.makeBytes()
        let h = "GET\n\nimage/png\n\(date)\n/这个是oss路径/image/\(fileName)".makeBytes()
        let beyts = try CryptoHasher(method: .keyed(.sha1, key: key), encoding: .plain).make(h)
        let str     = beyts.base64Encoded.makeString()
        let Header : [HeaderKey : String] = [
            "Authorization" :"OSS \(accessKeyId):\(str)",
            "Date"          :date,
            "Content-Type"  :"image/png"
        ]
        let url = "\(AliOSSUel)/image/\(fileName)"
        let req = try drop.client.get(url, Header)
        req.headers["Content-Type"] = "image/png"
        return req
    }
    static func getDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        dateFormatter.locale = Locale(identifier: "en_US")
        return dateFormatter.string(from: Date())

    }
    
    //MARK: 视频
    static func uploadVideo(_ videl: Data,fileName: String) -> Bool {
        do {
            let date = self.getDate()
            let key =  accessKeySecret.makeBytes()
            let h =  "PUT\n\nvideo/mp4\n\(date)\n/这个是oss路径/video/\(fileName)".makeBytes()
            let beyts = try CryptoHasher(method: .keyed(.sha1, key: key), encoding: .plain).make(h)
            let str     = beyts.base64Encoded.makeString()
            let Header : [HeaderKey : String] = [
                "Authorization" :"OSS \(accessKeyId):\(str)",
                "Date"          :date,
                "Content-Type"  :"video/mp4"
            ]
            let url = "\(AliOSSUel)/video/\(fileName)"
            let req = try drop.client.put(url,Header,Body(videl.makeBytes()))
            print(req)
            if req.status.statusCode == 200 {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    static func downVideo(_ fileName: String,header:[HeaderKey : String]) throws -> Response {
        let date = self.getDate()
        let key = accessKeySecret.makeBytes()
        let h = "GET\n\nvideo/mp4\n\(date)\n/这个是oss路径/video/\(fileName)".makeBytes()
        let beyts = try CryptoHasher(method: .keyed(.sha1, key: key), encoding: .plain).make(h)
        let str     =  beyts.base64Encoded.makeString()
        var Header : [HeaderKey : String] = [
            "Authorization" :"OSS \(accessKeyId):\(str)",
            "Date"          :date,
            "Content-Type"  :"video/mp4"
        ]
        Header.merge(header)
        let url = "\(AliOSSUel)/video/\(fileName)"
        let req = try drop.client.get(url,Header)
        return req
    }
}
