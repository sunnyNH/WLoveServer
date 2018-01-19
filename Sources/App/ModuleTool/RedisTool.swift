//
//  RedisTool.swift
//  App
//
//  Created by 牛辉 on 2018/1/18.
//

import Vapor
import Foundation
import FluentProvider

struct RedisTool {
    
    static func save(_ user: User?) throws {
        if let user = user {
            try drop.cache.set(user.uuid, user.redisJson(), expiration: nil)
        }
    }
    static func save(_ session: Session?) throws {
        if let session = session {
            try drop.cache.set(session.token, session.redisJson(), expiration: nil)
        }
    }
    static func deleteUser(_ user: String?) throws {
        if let user = user {
            try drop.cache.delete(user)
        }
    }
    static func deleteSession(_ session_token: String?) throws {
        if let session_token = session_token {
            try drop.cache.delete(session_token)
        }
    }
    static func getUser(_ uuid: String) throws -> User? {
        if let node = try drop.cache.get(uuid) {
            if let user = try? User(row: Row(node)) {
                return user
            }
        }
        guard let user = try User.makeQuery().filter("uuid", uuid).first() else {
            return nil;
        }
        try save(user)
        return user
    }
    static func getSession(_ token: String) throws -> Session? {
        if let node = try drop.cache.get(token) {
            if let sesion = try? Session(row: Row(node)) {
                return sesion
            }
        }
        guard let session = try Session.makeQuery().filter("token", token).first() else {
            return nil;
        }
        try save(session)
        return session
    }
}
