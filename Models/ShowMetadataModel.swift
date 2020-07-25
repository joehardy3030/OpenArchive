//
//  ShowMetadataModel.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/5/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

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
    var collection: String?
    var type: String?
    var description: String?
    var date: String?
    var year: String?
    var venue: String?
    var transferer: String?
    var source: String?
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
    var original: String?
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
