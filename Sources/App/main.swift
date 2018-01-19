import Vapor

let config = try Config()
try config.setup()
let drop = try Droplet(config)

/// 基础api
let api   = drop.grouped("api")
let v1    = api.grouped("v1")
let v2    = api.grouped("v2")
let token = v1.grouped(TokenMiddleware())
let token_v2 = v2.grouped(TokenMiddleware())


drop.get{ (request) -> ResponseRepresentable in
    return try drop.view.make("index.html")
}
/// 路由
RouteTool.setUp()
try drop.run()

