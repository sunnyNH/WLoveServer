//
//  ReportController.swift
//  NHServer
//
//  Created by niuhui on 2017/8/5.
//
//

import Vapor
import HTTP
import Foundation

class ReportController {
    
    
    func registeredRouting() {
        token.post("report","around", handler: self.postReportAround)
        token.get("report","around", handler: self.getReportAround)
    }
    
    func postReportAround(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        guard let around_id = request.data["around_id"]?.int  else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        if let reportAround = try ReportAround.makeQuery().filter("around_id", around_id).first() {
            if let report_id =  reportAround.id?.int,
               let _ = try ReportAroundUser.makeQuery().filter("reportAround_id",report_id).filter("uuid",user.uuid).first() {
                return try JSON(node: [code: 0,msg: "success",])
            }
            reportAround.last_at = Int(Date().timeIntervalSince1970)
            try reportAround.save()
            reportAround.rcount += 1
            let reportUser = ReportAroundUser(reportAround_id: reportAround.id?.int, uuid: user.uuid)
            try reportUser.save()
            return try JSON(node: [code: 0,msg: "success",])
        }
        let reportAround = ReportAround(around_id: around_id)
        try reportAround.save()
        let reportUser = ReportAroundUser(reportAround_id: reportAround.id?.int, uuid: user.uuid)
        try reportUser.save()
        return try JSON(node: [code: 0,msg: "success"])
    }
    func getReportAround(_ request: Request) throws -> ResponseRepresentable {
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        if user.phone != "18513989391" {
            return try JSON(node: [code: 1,msg : "您没有权限查看"])
        }
        var arounds = [ReportAround]()
        let query = try ReportAround.makeQuery().sort("rcount", .descending)
        if var page = request.data["pagenum"]?.int  {
            if page == 0 {
                page = 1
            }
            arounds = try query.limit(20, offset: 20*(page - 1)).all()
        } else {
            arounds = try query.limit(20, offset: 0).all()
        }
        return try JSON(node: [code: 0,msg: "success","arounds": arounds.map{try $0.makeJSON(.user)}])
    }
}
