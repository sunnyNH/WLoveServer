import FluentMySQL
import Redis
import Vapor

/// Called before your application initializes.
///
/// https://docs.vapor.codes/3.0/getting-started/structure/#configureswift
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
    ) throws {
    /// Register providers first
    try services.register(FluentMySQLProvider())
    
    /// Register routes to the router
    
    try routes(defRouter)
    services.register(defRouter, as: Router.self)
    
    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    // Configure a SQLite database
    /// Register custom MySQL Config 123123niuhui
    let mysqlConfig = MySQLDatabaseConfig(hostname: "127.0.0.1", port: 3306, username: "root",password:"123123niuhui", database:"vapor3.0")
    services.register(mysqlConfig)
    
    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .mysql)
    services.register(migrations)
    
}
