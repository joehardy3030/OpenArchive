import Foundation
import GRDB

/// Shared GRDB database stack
///
/// Creates (or opens) the `breaze.sqlite` file inside the app's
/// Application Support directory and sets-up the minimal schema the
/// app currently needs: downloads and share tables.
final class LocalDatabase {
    static let shared = LocalDatabase()
    let dbQueue: DatabaseQueue

    private init() {
        // Resolve a writable URL inside Application Support
        let fm = FileManager.default
        let supportURL = try! fm.url(for: .applicationSupportDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: true)
        let dbURL = supportURL.appendingPathComponent("breaze.sqlite")

        // Create/open the database
        dbQueue = try! DatabaseQueue(path: dbURL.path)

        // Run migrations (idempotent)
        try! migrator.migrate(dbQueue)
    }

    /// Database schema migrator.
    /// Add further migrations here when the schema evolves.
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createTables") { db in
            // Downloads table – stores one row per show, JSON-encoded.
            try db.create(table: "downloads", ifNotExists: true) { t in
                t.column("identifier", .text).primaryKey(onConflict: .replace)
                t.column("data", .text).notNull()
            }
            // Share table – only one logical row (id = 'shareShow').
            try db.create(table: "share", ifNotExists: true) { t in
                t.column("id", .text).primaryKey(onConflict: .replace)
                t.column("data", .text)
            }
        }
        migrator.registerMigration("addFavorites") { db in
            // Favorites table – stores one row per favorited show, JSON-encoded.
            try db.create(table: "favorites", ifNotExists: true) { t in
                t.column("identifier", .text).primaryKey(onConflict: .replace)
                t.column("data", .text).notNull()
                t.column("showType", .text).notNull()
                t.column("created_at", .datetime).defaults(sql: "CURRENT_TIMESTAMP")
            }
        }
        return migrator
    }
} 