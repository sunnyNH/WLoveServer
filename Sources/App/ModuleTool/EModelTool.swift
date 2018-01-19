//
//  EModelTool.swift
//  NHServer
//
//  Created by niuhui on 2017/5/12.
//
//
import Vapor
import HTTP
import Foundation
import Crypto
class EModel {
    static let share : EModel = EModel()
    var access_token: String    = ""
    var expires_in  : Int       = 0
    var application : String    = ""
    func registerToken() throws -> Bool {
        if expires_in != 0 || (expires_in - 48*60*60) <= Int(Date().timeIntervalSince1970) {
            return true
        }
        if let grant_type = drop.config["app","EModel","grant_type"]?.string,
            let client_id = drop.config["app","EModel","client_id"]?.string,
            let client_secret = drop.config["app","EModel","client_secret"]?.string,
            let eUrl = drop.config["app","EModel","eUrl"]?.string
        {
            let json = try JSON(node: [
                "grant_type": grant_type,
                "client_id" : client_id,
                "client_secret": client_secret
                ])
            let req = try drop.client.post(eUrl+"token",[:],json.makeBody())
            if req.status.hashValue == 200 {
                print("e-token-200")
                access_token = (req.data["access_token"]?.string)!
                expires_in   = (req.data["expires_in"]?.int)! + Int(Date().timeIntervalSince1970)
                application  = (req.data["application"]?.string)!
                return true
            } else {
                return false
            }
        }
        return false
    }
    func changePassWord(_ userName: String,passWord: String)throws -> Bool {
        if try !registerToken() {
            return false
        }
        let userpass = try JSON(node: [
            "newpassword": passWord,
            ])
        if  let eUrl = drop.config["app","EModel","eUrl"]?.string {
            let url = eUrl + "users/\(userName)/password"
            print(url)
            let req = try drop.client.put(url,["Authorization":"Bearer \(access_token)"],userpass.makeBody())
            print(req)
            if req.status.hashValue == 200 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    func registerUser(_ userName: String,passWord: String)throws -> Bool {
        
        if try !registerToken() {
            return false
        }
        let json = try JSON(node: [
            "username": userName,
            "password" : passWord
            ])
        let users = try [json].makeJSON()
        if  let eUrl = drop.config["app","EModel","eUrl"]?.string {
            let req = try drop.client.post(eUrl+"users",["Authorization":"Bearer \(access_token)"],users.makeBody())
            if req.status.hashValue == 200 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
}
