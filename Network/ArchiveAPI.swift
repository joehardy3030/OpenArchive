//
//  ArchiveAPI.swift
//  Breaze
//
//  Created by Joe Hardy on 6/25/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

enum iaQueryType {
    case openDownload
    case session
}

class ArchiveAPI: NSObject {

    
    let baseURLString = "https://archive.org/"

    func metadataURL(identifier: String) -> String {
        var url = baseURLString
        url += "metadata/"
        url += identifier
        return url
    }
    
    func downloadURL(identifier: String?,
                     filename: String?) -> String {
        //https://archive.org/download/<identifier>/<filename>
        
        var url = baseURLString
        url += "download/"
        if let id = identifier {
            url += id
        }
        if let f = filename {
            url += "/"
            url += f
        }
        return url
    }
    
    func dateRangeURL(year: Int, month: Int) -> String {
        // Search in date range
        //https://archive.org/services/search/v1/scrape?q=collection%3A%28GratefulDead%29%20AND%20date%3A%5B1987-03-01%20TO%201987-03-31%5D

        let andString = "%20AND%20"
        let dateString = "date%3A%5B"
        let toString = "%20TO%20"
        var url = baseURLString
        var monthString: String
                
        url += "services/search/v1/scrape?"
        url += "fields=date,venue,transferer,source&"
        url += "q=collection%3A%28GratefulDead%29"
        url += andString
        url += dateString
        if month <= 9 {
            monthString = "0" + String(month)
        }
        else {
            monthString = String(month)
        }
        url += String(year) + "-" + monthString + "-01"
        url += toString
        url += String(year) + "-" + monthString + "-31"
        url += "%5D"
        
        return url
    }
    
    func getIARequestMetadata(url: String, completion: @escaping (ShowMetadataModel) -> Void) {
        Alamofire.request(url).responseJSON { response in
            if let json = response.result.value {
                let j = JSON(json)
                let showMetadataModel = self.deserializeMetadataModel(json: j)
                completion(showMetadataModel)
              }
        }
    }
    
    func deserializeMetadataModel(json: JSON) -> ShowMetadataModel {
        let files_count = json["files_count"].int
        let created = json["created"].int
        let item_size = json["item_size"].int
        let dir = json["dir"].string
        let md = json["metadata"]
        let metadata = deserializeMetadata(json: md)
        let fl = json["files"]
        let files = deserializeFiles(json:fl)
        return ShowMetadataModel(metadata: metadata, files: files, files_count: files_count, created: created, item_size: item_size, dir: dir)
    }
    
    func deserializeFiles(json: JSON) -> [ShowFile] {
        var fileArray = [ShowFile]()
        for f in json {
            let name = f.1["name"].string
            let source = f.1["source"].string
            let creator = f.1["creator"].string
            let title = f.1["title"].string
            let track = f.1["track"].string
            let album = f.1["album"].string
            let bitrate = f.1["bitrate"].string
            let length = f.1["length"].string
            let format = f.1["format"].string
            let original = f.1["orginal"].string
            let mtime = f.1["mtime"].string
            let size = f.1["size"].string
            let md5 = f.1["md5"].string
            let crc32 = f.1["crc32"].string
            let sha1 = f.1["sha1"].string
            
            let sf = ShowFile(name: name, source: source, creator: creator, title: title, track: track, album: album, bitrate: bitrate, length: length, format: format, original: original, mtime: mtime, size: size, md5: md5, crc32: crc32, sha1: sha1)
            fileArray.append(sf)
        }
        return fileArray
    }
    
    func deserializeMetadata(json: JSON) -> ShowMetadata {

        let identifier = json["identifier"].string
        let title = json["title"].string
        let creator = json["creator"].string
        let mediatype = json["mediatype"].string
        let collection = json["collection"].string
        let type = json["type"].string
        let description = json["description"].string
        let date = json["date"].string
        let year = json["year"].string
        let venue = json["venue"].string
        let transferer = json["transferer"].string
        let source = json["source"].string
        
        return ShowMetadata(identifier: identifier, title: title, creator: creator, mediatype: mediatype, collection: collection, type: type, description: description, date: date, year: year, venue: venue, transferer: transferer, source: source)
    }
    
    func getIARequestItems(url: String, completion: @escaping ([ShowMetadata]?) -> Void) {
        Alamofire.request(url).responseJSON { response in

            if let json = response.result.value {
                let j = JSON(json)
                let items = j["items"]
                var itemArray = [String]()
                var showMetadatas = [ShowMetadata]()
                
                for i in items {
                    var showMD = ShowMetadata()
                    if let id_string = i.1["identifier"].string {
                        itemArray.append(id_string)
                        showMD.identifier = id_string
                    }
                    if let venue_string = i.1["venue"].string {
                        showMD.venue = venue_string
                    }
                    if let date_string = i.1["date"].string {
                        showMD.date = date_string
                    }
                    if let transferer_string = i.1["transferer"].string {
                        showMD.transferer = transferer_string
                    }
                    if let source_string = i.1["source"].string {
                        showMD.source = source_string
                    }

                    showMetadatas.append(showMD)
                }
                completion(showMetadatas)
              }
        }
    }

    func getIADownload(url: String, completion: @escaping (URL?) -> Void) {
        //https://github.com/Alamofire/Alamofire/blob/master/Documentation/Usage.md#downloading-data-to-a-file
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        //debugPrint(destination)
        Alamofire.download(url, to: destination)
            // .downloadProgress { (progress) in
               //         print((String)(progress.fractionCompleted*100)+"%")
             //     }
                 .responseJSON { response in
                                 completion(response.destinationURL)
        }
    }
}


    
    

