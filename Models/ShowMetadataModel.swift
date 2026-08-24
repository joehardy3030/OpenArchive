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
        // creator can be a string or an array (multi-artist billings); a strict
        // String decode here poisoned entire year responses — one array-creator
        // item fails the whole ShowMetadatas decode. Take the primary artist.
        if let creatorString = try? container.decodeIfPresent(String.self, forKey: .creator) {
            creator = creatorString
        } else if let creatorArray = try? container.decodeIfPresent([String].self, forKey: .creator) {
            creator = creatorArray.first
        } else {
            creator = nil
        }
        mediatype = try container.decodeIfPresent(String.self, forKey: .mediatype)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        // Handle description field that could be either a string or array
        if let descString = try? container.decodeIfPresent(String.self, forKey: .description) {
            description = descString
        } else if let descArray = try? container.decodeIfPresent([String].self, forKey: .description) {
            description = descArray.joined(separator: "\n")
        } else {
            description = nil
        }
        date = try container.decodeIfPresent(String.self, forKey: .date)
        // year is usually a string but occasionally a bare number
        if let yearString = try? container.decodeIfPresent(String.self, forKey: .year) {
            year = yearString
        } else if let yearInt = try? container.decodeIfPresent(Int.self, forKey: .year) {
            year = String(yearInt)
        } else {
            year = nil
        }
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

    /// Venue-and-location parsed from archive.org's conventional item title,
    /// e.g. "Jerry Garcia live at Keystone, Berkeley, CA on 1974-01-17".
    /// Multi-artist collections like taperssection often have no venue/coverage
    /// fields at all — the title is the only structured place this info lives.
    var titleVenueLocation: String? {
        guard let title = title else { return nil }
        // Non-greedy up to an " on <date>" suffix, so venues containing " on "
        // ("House of Blues on Sunset") don't get truncated.
        if let regex = try? NSRegularExpression(pattern: "(?i)\\blive at (.+?) on \\d{4}-\\d{2}-\\d{2}"),
           let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
           let r = Range(match.range(at: 1), in: title) {
            let venue = title[r].trimmingCharacters(in: .whitespaces)
            return venue.isEmpty ? nil : venue
        }
        // No trailing date — take everything after "live at"
        if let range = title.range(of: " live at ", options: .caseInsensitive) {
            let venue = title[range.upperBound...].trimmingCharacters(in: .whitespaces)
            return venue.isEmpty ? nil : venue
        }
        return nil
    }

    /// One-line venue + location for list rows, falling back to the title parse
    /// when the item has no venue/coverage fields.
    var displayVenueLine: String? {
        if let venue = venue {
            return [venue, coverage].compactMap { $0 }.joined(separator: ", ")
        }
        return titleVenueLocation
    }

    /// Band-code tokens from taper identifier conventions → the actual
    /// performing band. The Jerry Garcia creator entry phrase-matches many of
    /// Jerry's bands whose index-level creator is just "Jerry Garcia"; the
    /// identifier encodes who actually played. Codes verified against token
    /// frequencies across the full creator:"Jerry Garcia" catalog.
    private static let bandCodes: [String: String] = [
        "jgb": "Jerry Garcia Band",
        "jgab": "Jerry Garcia Acoustic Band",
        "jgms": "Jerry Garcia & Merl Saunders",
        "jgjk": "Jerry Garcia & John Kahn",
        "jgdg": "Jerry Garcia & David Grisman",
        "oaitw": "Old & In the Way",
        "lom": "Legion of Mary",
        "recon": "Reconstruction",
        "nrps": "New Riders of the Purple Sage",
        "gasb": "Great American String Band",
        "jgf": "Jerry Garcia & Friends",
    ]

    /// Creator refined by the identifier's band-code token — used everywhere a
    /// band name is displayed (rows, detail, players, Now Playing). Grouping
    /// under the "Jerry Garcia" band entry is unaffected (query-level).
    var displayCreator: String? {
        if let id = identifier {
            for token in id.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
                if let band = Self.bandCodes[String(token)] {
                    return band
                }
            }
        }
        return creator
    }

    /// Recording type ("SBD"/"AUD"/"MTX"/"FM") sniffed from taper naming
    /// conventions in the identifier (dot-separated tokens like
    /// "jg85-10-11.030623.jgjk.set1.sbd.jjoops"), with the source field as a
    /// fallback. Zero network cost — powers the row badges, which matters for
    /// collections whose items have no source field in the search index.
    var recordingType: String? {
        func sniff(_ tokens: [String]) -> String? {
            if tokens.contains("mtx") || tokens.contains("matrix") || tokens.contains("ultramatrix") { return "MTX" }
            if tokens.contains("sbd") || tokens.contains("dsbd") || tokens.contains("soundboard") { return "SBD" }
            if tokens.contains("fm") || tokens.contains("prefm") { return "FM" }
            // "fob" = front-of-board: an audience-mic placement convention
            if tokens.contains("aud") || tokens.contains("audience") || tokens.contains("fob") { return "AUD" }
            return nil
        }
        func tokenize(_ s: String) -> [String] {
            s.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        }
        if let id = identifier, let type = sniff(tokenize(id)) { return type }
        if let src = source?.joined(separator: " "), let type = sniff(tokenize(src)) { return type }
        return nil
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
