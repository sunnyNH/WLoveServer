import Vapor
/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    
    token.get("niuhui") { (req) in
        return "Hello, world!"
    }
    router.get("ff") { (req) in
        return "Hello, world!"
    }
}
