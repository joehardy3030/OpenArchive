//
//  ShowMetadataModel.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/5/20.
//  Copyright 2020 Carquinez. All rights reserved.
//

import UIKit

struct ShareMetadataModel: Codable {
    var showMetadataModel: ShowMetadataModel?
    var isPlaying: Bool?
}

struct ShowMetadataModel: Codable {
    var metadata: ShowMetadata?
    var files: [ShowFile]?
    var mp3Array: [ShowMP3]?
    var files_count: Int?
    var created: Int?
    var item_size: Int?
    var dir: String?
}

struct ShowMetadata: Codable {
    var identifier: String?
    var title: String?
    var creator: String?
    var mediatype: String?
    var collection: [String]?
    var type: String?
    var description: String?
    var date: String?
    var year: String?
    var venue: String?
    var transferer: String?
    var source: [String]?
    var coverage: String?
    var avg_rating: Float?
    var num_reviews: Int?
    
    init(identifier: String) {
        self.identifier = identifier
    }
    
    enum CodingKeys: String, CodingKey {
        case identifier, title, creator, mediatype, collection, type, description
        case date, year, venue, transferer, source, coverage, avg_rating, num_reviews
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decodeIfPresent(String.self, forKey: .identifier)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        creator = try container.decodeIfPresent(String.self, forKey: .creator)
        mediatype = try container.decodeIfPresent(String.self, forKey: .mediatype)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        year = try container.decodeIfPresent(String.self, forKey: .year)
        venue = try container.decodeIfPresent(String.self, forKey: .venue)
        transferer = try container.decodeIfPresent(String.self, forKey: .transferer)
        coverage = try container.decodeIfPresent(String.self, forKey: .coverage)
        avg_rating = try container.decodeIfPresent(Float.self, forKey: .avg_rating)
        num_reviews = try container.decodeIfPresent(Int.self, forKey: .num_reviews)
        
        // Handle collection field that could be either a string or array
        if let collectionArray = try? container.decodeIfPresent([String].self, forKey: .collection) {
            collection = collectionArray
        } else if let collectionString = try? container.decodeIfPresent(String.self, forKey: .collection) {
            collection = [collectionString]
        } else {
            collection = nil
        }

        // Handle source field that could be either a string or array
        if let sourceArray = try? container.decodeIfPresent([String].self, forKey: .source) {
            source = sourceArray
        } else if let sourceString = try? container.decodeIfPresent(String.self, forKey: .source) {
            source = [sourceString]
        } else {
            source = nil
        }
    }
}

extension ShowMetadata {
    var month: String? {
        guard let date = self.date, date.count >= 7 else { return nil }
        let index = date.index(date.startIndex, offsetBy: 7)
        return String(date[..<index]) // Extracts the "yyyy-MM" part
    }
}

struct ShowMetadatas:Codable {
    var items: [ShowMetadata]?
}

struct ShowFile: Codable {
    var name: String?
    var source: String?
    var creator: String?
    var title: String?
    var track: String?
    var album: String?
    var bitrate: String?
    var length: String?
    var format: String?
    // var original: String?
    var mtime: String?
    var size: String?
    var md5: String?
    var crc32: String?
    var sha1: String?
}

struct ShowMP3: Codable {
    let identifier: String?
    let name: String?
    let title: String?
    let track: String?
    var destination: URL?	
}
