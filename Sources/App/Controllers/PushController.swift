//
//  PushController.swift
//  NHServer
//
//  Created by niuhui on 2017/6/23.
//
//

import Vapor
import HTTP
import Foundation

class PushController: NSObject {

    func registeredRouting() {
        token.post("push", handler: self.push)
    }
    func push(_ request: Request) throws -> ResponseRepresentable {
        return try JSON(node: [code: 0,msg : "success"])
    }
}
