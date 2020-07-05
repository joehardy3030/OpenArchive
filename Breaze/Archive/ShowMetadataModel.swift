//
//  ShowMetadataModel.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/5/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

struct ShowFile: Codable {
    let name: String?
    let source: String?
    let creator: String?
    let title: String?
    let track: String?
    let album: String?
    let bitrate: String?
    let length: String?
    let format: String?
    let original: String?
    let mtime: String?
    let size: String?
    let md5: String?
    let crc32: String?
    let sha1: String?
}

struct ShowMetadata: Codable {
    let identifier: String?
    let title: String?
    let creator: String?
    let mediatype: String?
    let collection: String?
    let type: String?
    let description: String?
    let date: String?
    let year: String?
    let venue: String?
    let transferer: String?
    let source: String?
}

struct ShowMetadataModel: Codable {
    let metadata: ShowMetadata?
    let files: [ShowFile]?
    let files_count: Int?
    let created: Int?
    let item_size: Int?
    let dir: String?
}
