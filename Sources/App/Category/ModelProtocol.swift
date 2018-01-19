//
//  ModelP.swift
//  walkingLoveServer
//
//  Created by 牛辉 on 2017/9/8.
//
//
import Vapor
import FluentProvider

//protocol ModelProtocol {
//    func wildcardRow() throws -> Row
//}
extension Model {
    func wildcardRow() throws -> Row {
        var row = Row()
        let hMirror = Mirror(reflecting: self)
        for case let (label?, value) in hMirror.children {
            switch label {
            case "storage"  : break
            default         : try row.set(label, value)
            }
        }
        return row
    }
}
