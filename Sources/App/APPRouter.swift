//
//  APPRouter.swift
//  App
//
//  Created by 牛辉 on 2018/6/20.
//

import Vapor

let router = EngineRouter.default()
let api      : Router = router.grouped("api")
let v1       : Router = api.grouped("v1")
//let token    : Router = v1.grouped(TokenMiddleware())
