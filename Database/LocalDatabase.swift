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
        let fm = FileManager.default
        do {
            let supportURL = try fm.url(for: .applicationSupportDirectory,
                                         in: .userDomainMask,
                                         appropriateFor: nil,
                                         create: true)
            let dbURL = supportURL.appendingPathComponent("breaze.sqlite")

            // On first launch, copy the seed database from the app bundle.
            if !fm.fileExists(atPath: dbURL.path) {
                if let seedURL = Bundle.main.url(forResource: "seed", withExtension: "sqlite") {
                    try fm.copyItem(at: seedURL, to: dbURL)
                    print("Database seeded successfully.")
                } else {
                    print("Seed database not found in bundle.")
                }
            }
            
            // Create/open the database
            dbQueue = try DatabaseQueue(path: dbURL.path)
            
            // Run migrations (idempotent)
            try migrator.migrate(dbQueue)

        } catch {
            // All errors here are fatal.
            fatalError("Database initialization failed: \(error)")
        }
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
        return migrator
    }
} 