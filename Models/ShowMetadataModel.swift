//
//  ShowMetadataModel.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/5/20.
//  Copyright © 2020 Carquinez. All rights reserved.
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
    var creator: StringOrArray?
    var mediatype: String?
    var collection: [String]?
    var type: String?
    var description: String?
    var date: String?
    var year: String?
    var venue: String?
    var transferer: String?
    var source: String?
    var coverage: String?
    var avg_rating: Float?
    var num_reviews: Int?
}

// Custom type to handle both String and [String] for creator field
enum StringOrArray: Codable {
    case string(String)
    case array([String])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(StringOrArray.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or [String]"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        }
    }
    
    var stringValue: String {
        switch self {
        case .string(let string):
            return string
        case .array(let array):
            return array.joined(separator: ", ")
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
