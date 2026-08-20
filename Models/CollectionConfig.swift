import Foundation

struct CollectionConfig {
    static let collectionsText = ["Grateful Dead", "Phish", "Phil Lesh and Friends", "The Other Ones", "Further", "Dead And Company", "Billy Strings", "Goose", "The Radiators"]
    static let collections = ["GratefulDead", "Phish", "PhilLeshandFriends", "TheOtherOnes", "Furthur", "DeadAndCompany", "BillyStrings", "GooseBand", "Radiators"]

    // Collections whose archive.org items mark soundboards with the stream_only
    // flag (the Dead-family streaming policy). Only these get the All/SBD filter;
    // other bands' SBDs exist but aren't flagged stream_only, so the filter
    // would silently return nothing.
    static let sbdCapableCollections = ["GratefulDead", "Furthur", "TheOtherOnes"]

    static func supportsSBDFilter(collection: String) -> Bool {
        return sbdCapableCollections.contains(collection)
    }

    // Collections that use creator field instead of collection field for searching
    // Phish metadata (setlists, ratings, venues) courtesy of Phish.net / The Mockingbird Foundation.
    // Audio streaming for Phish sourced from Phish.in. See Network/PhishNetAPI.swift for API details.
    static let creatorBasedCollections = ["Phish"]

    // Expandable: allow runtime-added creator-based identifiers via UserDefaults key
    static func isCreatorBased(collection: String) -> Bool {
        let defaults = UserDefaults.standard
        let extra = defaults.stringArray(forKey: "creatorBasedCollectionsExtra") ?? []
        return creatorBasedCollections.contains(collection) || extra.contains(collection)
    }
    
    static func getCollection(for displayName: String) -> String? {
        guard let index = collectionsText.firstIndex(of: displayName) else { return nil }
        return collections[index]
    }
    
    static func getDisplayName(for collection: String) -> String? {
        guard let index = collections.firstIndex(of: collection) else { return nil }
        return collectionsText[index]
    }
    
} 

// Persisted and default collection management
struct CollectionEntry {
    let displayName: String
    let identifier: String
    let isDefault: Bool
}

class CollectionStore {
    private let userDefaults = UserDefaults.standard
    private let addedTextKey = "userCollectionsText"
    private let addedIdsKey = "userCollections"
    private let hiddenIdsKey = "hiddenDefaultCollections"

    // Defaults from CollectionConfig
    private var defaultDisplayNames: [String] { CollectionConfig.collectionsText }
    private var defaultIdentifiers: [String] { CollectionConfig.collections }

    func getEntries() -> [CollectionEntry] {
        let added = getAdded()
        let hiddenDefaults = getHiddenDefaultIds()

        var entries: [CollectionEntry] = []
        for (index, id) in defaultIdentifiers.enumerated() {
            if hiddenDefaults.contains(id) { continue }
            let displayName = index < defaultDisplayNames.count ? defaultDisplayNames[index] : id
            entries.append(CollectionEntry(displayName: displayName, identifier: id, isDefault: true))
        }
        for (name, id) in added {
            // Avoid duplicates with defaults
            if entries.contains(where: { $0.identifier.caseInsensitiveCompare(id) == .orderedSame }) { continue }
            entries.append(CollectionEntry(displayName: name, identifier: id, isDefault: false))
        }
        return entries
    }

    func addCollection(displayName: String, identifier: String) {
        var (names, ids) = getAddedArrays()
        if !ids.contains(where: { $0.caseInsensitiveCompare(identifier) == .orderedSame }) {
            names.append(displayName)
            ids.append(identifier)
            userDefaults.set(names, forKey: addedTextKey)
            userDefaults.set(ids, forKey: addedIdsKey)
        }
        // If previously hidden default, unhide it
        var hidden = getHiddenDefaultIds()
        if let idx = hidden.firstIndex(of: identifier) {
            hidden.remove(at: idx)
            userDefaults.set(hidden, forKey: hiddenIdsKey)
        }
    }

    func removeCollection(_ entry: CollectionEntry) {
        if entry.isDefault {
            // Mark default as hidden
            var hidden = getHiddenDefaultIds()
            if !hidden.contains(entry.identifier) {
                hidden.append(entry.identifier)
                userDefaults.set(hidden, forKey: hiddenIdsKey)
            }
        } else {
            // Remove from added lists
            var (names, ids) = getAddedArrays()
            if let idx = ids.firstIndex(where: { $0.caseInsensitiveCompare(entry.identifier) == .orderedSame }) {
                ids.remove(at: idx)
                if idx < names.count { names.remove(at: idx) }
                userDefaults.set(names, forKey: addedTextKey)
                userDefaults.set(ids, forKey: addedIdsKey)
            }
        }
    }

    // MARK: - Helpers
    private func getAdded() -> [(String, String)] {
        let (names, ids) = getAddedArrays()
        return Array(zip(names, ids))
    }

    private func getAddedArrays() -> ([String], [String]) {
        let names = userDefaults.stringArray(forKey: addedTextKey) ?? []
        let ids = userDefaults.stringArray(forKey: addedIdsKey) ?? []
        return (names, ids)
    }

    private func getHiddenDefaultIds() -> [String] {
        return userDefaults.stringArray(forKey: hiddenIdsKey) ?? []
    }
}

