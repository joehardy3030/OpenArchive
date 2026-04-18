import Foundation
import GRDB

/// Manages the favorites table in the local GRDB database.
/// Favorites store show metadata + show type so they can be browsed
/// independently of downloads.
final class FavoritesStore {
    static let shared = FavoritesStore()

    private let dbQueue: DatabaseQueue

    private init() {
        self.dbQueue = LocalDatabase.shared.dbQueue
    }

    // MARK: - Public API

    func addFavorite(show: ShowMetadataModel, showType: ShowType) {
        guard let identifier = show.metadata?.identifier else { return }
        do {
            let jsonData = try JSONEncoder().encode(show)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let typeString = showTypeToString(showType)
            try dbQueue.write { db in
                try db.execute(
                    sql: "INSERT OR REPLACE INTO favorites (identifier, data, showType) VALUES (?, ?, ?)",
                    arguments: [identifier, jsonString, typeString]
                )
            }
        } catch {
            print("FavoritesStore write error: \(error)")
        }
    }

    func removeFavorite(identifier: String) {
        do {
            try dbQueue.write { db in
                try db.execute(sql: "DELETE FROM favorites WHERE identifier = ?", arguments: [identifier])
            }
        } catch {
            print("FavoritesStore delete error: \(error)")
        }
    }

    func isFavorite(identifier: String?) -> Bool {
        guard let identifier else { return false }
        do {
            return try dbQueue.read { db in
                let count = try Int.fetchOne(db,
                    sql: "SELECT COUNT(*) FROM favorites WHERE identifier = ?",
                    arguments: [identifier])
                return (count ?? 0) > 0
            }
        } catch {
            print("FavoritesStore read error: \(error)")
            return false
        }
    }

    func getAllFavorites(completion: @escaping ([(show: ShowMetadataModel, showType: ShowType)]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var results: [(show: ShowMetadataModel, showType: ShowType)] = []
                try self.dbQueue.read { db in
                    let rows = try Row.fetchAll(db,
                        sql: "SELECT data, showType FROM favorites")
                    for row in rows {
                        if let jsonString: String = row["data"],
                           let data = jsonString.data(using: .utf8),
                           let show = try? JSONDecoder().decode(ShowMetadataModel.self, from: data) {
                            let typeString: String = row["showType"] ?? "archive"
                            let showType = self.stringToShowType(typeString)
                            results.append((show: show, showType: showType))
                        }
                    }
                }
                results.sort { ($0.show.metadata?.date ?? "") < ($1.show.metadata?.date ?? "") }
                completion(results)
            } catch {
                print("FavoritesStore read all error: \(error)")
                completion([])
            }
        }
    }

    // MARK: - Helpers

    private func showTypeToString(_ type: ShowType) -> String {
        switch type {
        case .archive: return "archive"
        case .downloaded: return "downloaded"
        case .phishIn: return "phishIn"
        }
    }

    private func stringToShowType(_ string: String) -> ShowType {
        switch string {
        case "phishIn": return .phishIn
        case "downloaded": return .downloaded
        default: return .archive
        }
    }
}
