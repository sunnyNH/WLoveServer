//
//  InterfaceDefine.swift
//  NHServer
//
//  Created by niuhui on 2017/5/10.
//
//
import Vapor

let code : String = "code"
let msg  : String = "message"
func callFail(_ m: String) -> JSON {
    return JSON([code: 1,msg : JSON(m)])
}
extension JSON {
    func success() throws -> JSON {
        var temp = JSON([code: 0,msg : "success"]).object
        if let dic = self.object{
            for (key,value) in dic {
                temp?[key] = value
            }
        }
        return try JSON(temp.makeNode(in: nil))
    }
}
