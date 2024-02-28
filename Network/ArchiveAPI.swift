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
    var configuration: URLSessionConfiguration
    var sessionManager: Alamofire.Session
    
    override init() {
        configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10000
        sessionManager = Alamofire.Session(configuration: configuration)
        super.init()
    }
    
    let baseURLString = "https://archive.org/"

    func metadataURL(identifier: String) -> String {
        var url = baseURLString
        url += "metadata/"
        url += identifier
        return url
    }
    
    func downloadURL(identifier: String?,
                     filename: String?) -> URL? {
        //https://archive.org/download/<identifier>/<filename>
        
        var urlString = baseURLString
        urlString += "download/"
        if let id = identifier {
            urlString += id
        }
        if let f = filename {
            urlString += "/"
            urlString += f
        }
        let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: encodedString)
        return url
    }
    
    func dateRangeURL(year: Int, month: Int, sbdOnly: Bool) -> String {
        // Search in date range
        //https://archive.org/services/search/v1/scrape?q=collection%3A%28GratefulDead%29%20AND%20date%3A%5B1987-03-01%20TO%201987-03-31%5D
        //https://archive.org/services/search/v1/scrape?fields=date,venue,transferer,source,collection&q=collection%3A%28GratefulDead%20AND%20stream_only%29%20AND%20date%3A%5B1992-05-01%20TO%201992-05-31%5D
        //let sbdOnly = true
        let andString = "%20AND%20"
        let dateString = "date%3A%5B"
        let toString = "%20TO%20"
        var url = baseURLString
        var monthString: String
                
        url += "services/search/v1/scrape?"
        url += "fields=date,venue,transferer,source,coverage,stars,avg_rating,num_reviews&"
        if sbdOnly {
            url += "q=collection%3A%28GratefulDead%20AND%20stream_only%29"
        }
        else {
            url += "q=collection%3A%28GratefulDead%29"
        }
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
        switch month {
        case 1,3,5,7,8,10,12:
            url += String(year) + "-" + monthString + "-31"
        case 4,6,9,11:
            url += String(year) + "-" + monthString + "-30"
        case 2:
            url += String(year) + "-" + monthString + "-28"
        default:
            url += String(year) + "-" + monthString + "-30"
        }
        
        url += String(year) + "-" + monthString + "-31"
        url += "%5D"
        
        return url
    }

    func dateRangeYearURL(year: Int, sbdOnly: Bool) -> String {
        // Search in date range
        //https://archive.org/services/search/v1/scrape?q=collection%3A%28GratefulDead%29%20AND%20date%3A%5B1987-01-01%20TO%201987-12-31%5D
        //https://archive.org/services/search/v1/scrape?fields=date,venue,transferer,source,collection&q=collection%3A%28GratefulDead%20AND%20stream_only%29%20AND%20date%3A%5B1992-05-01%20TO%201992-05-31%5D
        //let sbdOnly = true
        let firstDayMonth = "01-01"
        let lastDayMonth = "12-31"
        let andString = "%20AND%20"
        let dateString = "date%3A%5B"
        let toString = "%20TO%20"
        var url = baseURLString
                
        url += "services/search/v1/scrape?"
        url += "fields=date,venue,transferer,source,coverage,stars,avg_rating,num_reviews&"
        if sbdOnly {
            url += "q=collection%3A%28GratefulDead%20AND%20stream_only%29"
        }
        else {
            url += "q=collection%3A%28GratefulDead%29"
        }
        url += andString
        url += dateString
        url += String(year) + "-" + firstDayMonth
        url += toString
        url += String(year) + "-" + lastDayMonth
        url += "%5D"
        print(url)
        return url
    }

    /*
    func getIARequestMetadata(url: String, completion: @escaping (ShowMetadataModel) -> Void) {
        AF.request(url).responseJSON { response in
            if let json = response.value {
                let j = JSON(json)
                print(j)
                let showMetadataModel = self.deserializeMetadataModel(json: j)
                completion(showMetadataModel)
            }
        }
    }
    */
    
    func getIARequestMetadataDecodable(url: String, completion: @escaping (ShowMetadataModel) -> Void) {
        AF.request(url).responseDecodable(of: ShowMetadataModel.self) { response in
            print(response)
            switch response.result {
            case .success(let showMetadataModel):
                completion(showMetadataModel)
            case .failure(let error):
                print(error)
            }
        }
    }

    /*
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
     */
    
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
    
    /*
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
        let coverage = json["coverage"].string
        let avg_rating = json["avg_rating"].float
        let num_reviews = json["num_reviews"].int
        
        return ShowMetadata(identifier: identifier, title: title, creator: creator, mediatype: mediatype, collection: collection, type: type, description: description, date: date, year: year, venue: venue, transferer: transferer, source: source, coverage: coverage, avg_rating: avg_rating, num_reviews: num_reviews)
    }
    */

    
    /*
    func getIARequestItems(url: String, completion: @escaping ([ShowMetadata]?) -> Void) {
        
        AF.request(url).responseJSON { response in
            switch response.result {
            case .success(let value):
                let j = JSON(value)
                let items = j["items"]
                var showMetadatas = [ShowMetadata]()
                for i in items {
                    let showMD = self.deserializeMetadata(json: i.1)
                    showMetadatas.append(showMD)
                }
                completion(showMetadatas)
            case .failure(let error):
                print(error)
                completion(nil)
            }
        }
    }
    */
    
    func getIARequestItemsDecodable(url: String, completion: @escaping (ShowMetadatas?) -> Void) {
        AF.request(url).responseDecodable(of: ShowMetadatas.self) { response in
            switch response.result {
            case .success(let showMetadatas):
                completion(showMetadatas)
            case .failure(let error):
                print(error)
                completion(nil)
            }
        }
    }
     
    
    func getIADownload(url: URL?, completion: @escaping (URL?) -> Void) {
        //https://github.com/Alamofire/Alamofire/blob/master/Documentation/Usage.md#downloading-data-to-a-file
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        guard let url = url else { return }
        self.sessionManager.download(url, to: destination)
            .downloadProgress { (progress) in
                print("Progress: \(progress.fractionCompleted)")
            }
            .responseJSON { response in
                completion(response.fileURL)
            }
    }
}


    
    

