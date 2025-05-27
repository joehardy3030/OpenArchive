import Foundation

struct CollectionConfig {
    static let collectionsText = ["Grateful Dead", "Phil Lesh and Friends", "The Other Ones", "Further", "Dead And Company", "Billy Strings", "Goose", "The Radiators", "Phish"]
    static let collections = ["GratefulDead", "PhilLeshandFriends", "TheOtherOnes", "Furthur", "DeadAndCompany", "BillyStrings", "GooseBand", "Radiators", "Phish"]
    
    // Collections that use creator field instead of collection field for searching
    static let creatorBasedCollections = ["Phish"]
    
    static func getCollection(for displayName: String) -> String? {
        guard let index = collectionsText.firstIndex(of: displayName) else { return nil }
        return collections[index]
    }
    
    static func getDisplayName(for collection: String) -> String? {
        guard let index = collections.firstIndex(of: collection) else { return nil }
        return collectionsText[index]
    }
    
    static func isCreatorBased(collection: String) -> Bool {
        return creatorBasedCollections.contains(collection)
    }
} 
