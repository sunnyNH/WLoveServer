//
//  LoadController.swift
//  NHServer
//
//  Created by niuhui on 2017/5/11.
//
//
import Vapor
import HTTP
import Crypto
import Foundation
class LoadController {
    func registeredRouting() {
        //需要登录验证的
        token.post("upload", handler: self.upload)
        token.post("upload","video", handler: self.uploadVideo)
        
        drop.get("download", String.parameter, handler: self.download)
        
        drop.get("download","image", String.parameter, handler: self.v2download)
        
        drop.get("download","video", String.parameter, handler: self.downloadVideo)
    }
    
    /// 上传图片接口
    func upload(_ request: Request) throws -> ResponseRepresentable {
        guard let image = request.formData?["file"]?.part.body else{
            return try JSON(node: [
                code: 1,
                msg : "缺少图片"
                ])
        }
        //设定路径
        let result = try Hash.make(.md5, image)
        let name  =  result.hexString + ".png";
        let data = Data(bytes: image)
        if data.count == 0 {
            return try JSON(node: [
                code: 1,
                msg : "上传失败"
                ])
        }
        let is_success = AliOSS.upload(data, fileName: name)
        if is_success {
            if let BaseUrl = drop.config["app","BaseUrl"]?.string {
                return try JSON(node: [
                    code: 0,
                    msg : "success",
                    "url" : "\(BaseUrl)/download/image/\(name)"
                    ])
            }else {
                return try JSON(node: [
                    code: 0,
                    msg : "success",
                    "url" : "http://test.walkinglove.com/download/image/\(name)"
                    ])
            }
        } else {
            return try JSON(node: [code: 1,msg : "上传失败"])
        }
    }
    func uploadVideo(_  request: Request) throws -> ResponseRepresentable {
        guard let video = request.formData?["file"]?.part.body else{
            return try JSON(node: [
                code: 1,
                msg : "缺少视频"
                ])
        }
        //设定路径
        let result = try Hash.make(.md5, video)
        let name  =  result.hexString + ".MP4";
        let data = Data(bytes: video)
        if data.count == 0 {
            return try JSON(node: [
                code: 1,
                msg : "上传失败"
                ])
        }
        let is_success = AliOSS.uploadVideo(data, fileName: name)
        if is_success {
            if let BaseUrl = drop.config["app","BaseUrl"]?.string {
                return try JSON(node: [
                    code: 0,
                    msg : "success",
                    "url" : "\(BaseUrl)/download/video/\(name)"
                    ])
            }else {
                return try JSON(node: [
                    code: 0,
                    msg : "success",
                    "url" : "http://test.walkinglove.com/download/video/\(name)"
                    ])
            }
        } else {
            return try JSON(node: [code: 1,msg : "上传失败"])
        }
    }
    func v2download(_ request: Request) throws -> ResponseRepresentable {
        let iamgeName = try request.parameters.next(String.self)
        return try AliOSS.down(iamgeName)
    }
    func downloadVideo(_ request: Request) throws -> ResponseRepresentable {
        let iamgeName = try request.parameters.next(String.self)
        return try AliOSS.downVideo(iamgeName,header: request.headers)
    }
    func download(_ request: Request) throws -> ResponseRepresentable {
        let iamgeName = try request.parameters.next(String.self)
        if let BaseUrl = drop.config["app","BaseUrl"]?.string {
            return Response(redirect: "\(BaseUrl)/images/file/\(iamgeName)")
        } else {
            return Response(redirect: "http://test.walkinglove.com/images/file/\(iamgeName)")
        }
    }
}
