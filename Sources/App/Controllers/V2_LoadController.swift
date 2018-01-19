//
//  V2_LoadController.swift
//  App
//
//  Created by 牛辉 on 2017/12/3.
//

import Vapor
import HTTP
import Crypto
import Foundation

class V2_LoadController {

    func registeredRouting() {
        //需要登录验证的
        token_v2.post("upload", handler: self.uploadImage)
        token_v2.post("upload","video", handler: self.uploadVideo)
    }
    func uploadImage(_ request: Request) throws -> ResponseRepresentable {

        guard let image = request.formData?["file"]?.part.body else{
            return try JSON(node: [
                code: 1,
                msg : "缺少图片"
                ])
        }
        guard let type = request.formData?["type"]?.int else {
            return try JSON(node: [
                code: 1,
                msg : "缺少文件类型"
                ])
        }
        if type != 1 && type != 2 {
            return try JSON(node: [ code: 1, msg : "文件类型错误"])
        }
        //设定路径
        let result = try Hash.make(.md5, image)
        let name  =  result.hexString + (type == 1 ? ".png" : ".gif");
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
                let file = File(url: "\(BaseUrl)/download/image/\(name)", type: type)
                if let content = request.formData?["content"]?.string {
                    file.content = content;
                }
                try file.save()
                return try JSON(node: [
                    code: 0,
                    msg : "success",
                    "url" : "\(BaseUrl)/download/image/\(name)",
                    "file_id" : file.id?.int ?? 0
                    ])
            }else {
                let file = File(url: "http://test.walkinglove.com/download/image/\(name)", type: type)
                if let content = request.formData?["content"]?.string {
                    file.content = content;
                }
                try file.save()
                return try JSON(node: [
                    code: 0,
                    msg : "success",
                    "url" : "http://test.walkinglove.com/download/image/\(name)",
                    "file_id" : file.id?.int ?? 0
                    ])
            }
        } else {
            return try JSON(node: [code: 1,msg : "上传失败"])
        }
    }
    func uploadVideo(_  request: Request) throws -> ResponseRepresentable {
        print(request.query ?? "没有参数")
        guard let video = request.formData?["file"]?.part.body else{
            return try JSON(node: [
                code: 1,
                msg : "缺少视频"
                ])
        }
        guard let type = request.formData?["type"]?.int,type == 3 else {
            return try JSON(node: [
                code: 1,
                msg : "缺少文件类型"
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
                let file = File(url: "\(BaseUrl)/download/video/\(name)", type: type)
                if let content = request.formData?["content"]?.string {
                    file.content = content;
                }
                try file.save()
                return try JSON(node: [
                    code: 0,
                    msg : "success",
                    "url" : "\(BaseUrl)/download/video/\(name)",
                    "file_id" : file.id?.int ?? 0
                    ])
            }else {
                let file = File(url: "http://test.walkinglove.com/download/video/\(name)", type: type)
                if let content = request.formData?["content"]?.string {
                    file.content = content;
                }
                try file.save()
                return try JSON(node: [
                    code: 0,
                    msg : "success",
                    "url" : "http://test.walkinglove.com/download/video/\(name)",
                    "file_id" : file.id?.int ?? 0
                    ])
            }
        } else {
            return try JSON(node: [code: 1,msg : "上传失败"])
        }
    }
}
