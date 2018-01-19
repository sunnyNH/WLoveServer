//
//  NearbyController.swift
//  NHServer
//
//  Created by niuhui on 2017/7/9.
//
//

import Vapor
import HTTP
import Foundation
class NearbyController {
    func registeredRouting() {
        let nearbToken = token.grouped("nearby")
        nearbToken.get("user", handler: self.getNearbyUsers)
    }
    func getNearbyUsers(_ request: Request) throws -> ResponseRepresentable {
        guard let lng = request.data["lng"]?.double,let lat = request.data["lat"]?.double else {
            return try JSON(node: [code: 1,msg : "缺少参数"])
        }
        guard let user = try request.user() else { return try JSON(node: [code: 1,msg: "未登录"]) }
        if let nearby = try Nearby.makeQuery().filter("uuid", user.uuid).first() {
            nearby.lng = lng
            nearby.lat = lat
            nearby.update_at = Int(Date().timeIntervalSince1970)
            try nearby.save()
        } else {
            let nearby = Nearby(user: user, lng: lng, lat: lat)
            try nearby.save()
        }
        var nearbys : [Nearby] = []
        if let temps = try Nearby.database?.raw("SELECT id,lng,lat,uuid,update_at, ROUND(6378.138*2*ASIN(SQRT(POW(SIN((\(lat)*PI()/180-lat*PI()/180)/2),2)+COS(\(lat)*PI()/180)*COS(lat*PI()/180)*POW(SIN((\(lng)*PI()/180-lng*PI()/180)/2),2)))*1000) AS distance FROM Nearbys where uuid != '\(user.uuid)' ORDER BY distance asc LIMIT 20").array {
            nearbys = try temps.map{ try Nearby(node: $0)}
        }
        return try JSON(node: [
            code: 0,
            msg: "success",
            "users": nearbys.map{try $0.makeJSON(.user)}
            ])
    }
}
