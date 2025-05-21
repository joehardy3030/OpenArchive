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
    
    func dateRangeURL(year: Int, month: Int, sbdOnly: Bool, collection: String = "GratefulDead") -> String {
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
        url += "fields=identifier,date,venue,transferer,source,coverage,stars,avg_rating,num_reviews,collection,creator&"
        if sbdOnly {
            url += "q=collection%3A%28" + collection + "%20AND%20stream_only%29"
        }
        else {
            url += "q=collection%3A%28" + collection + "%29"
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

    func dateRangeYearURL(year: Int, sbdOnly: Bool, collection: String = "GratefulDead") -> String {

        let firstDayMonth = "01-01"
        let lastDayMonth = "12-31"
        let andString = "%20AND%20"
        let dateString = "date%3A%5B"
        let toString = "%20TO%20"
        var url = baseURLString
                
        url += "services/search/v1/scrape?"
        url += "fields=identifier,date,venue,transferer,source,coverage,stars,avg_rating,num_reviews,collection,creator&"
        if sbdOnly {
            url += "q=collection%3A%28" + collection + "%20AND%20stream_only%29"
        }
        else {
            url += "q=collection%3A%28" + collection + "%29"
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

    
    func searchTermURL(searchTerm: String?, venue: String?, minRating: String?, startYear: String?, endYear: String?, collection: String?) -> String {
        print("searchTermURL")
        let startMonthDay = "01-01"
        let endMonthDay = "12-31"
        
        var components = URLComponents(string: baseURLString)
        components?.path = "/services/search/v1/scrape"

        var queryItems = [URLQueryItem]()

        // Fields
        let fields = "identifier,date,venue,transferer,source,coverage,stars,avg_rating,num_reviews,collection,creator"
        queryItems.append(URLQueryItem(name: "fields", value: fields))

        // Query
        var query = ""
        if let col = collection {
            print(col)
            if col == "GratefulDead" {
                query += "collection:(" + col + " AND stream_only)"
            }
            else if col == "" {
                query += "mediatype:audio  AND "
            }
            else
            {
                query += "collection:" + col
            }
        }
        
        if let st = searchTerm, !st.isEmpty {
            let stPlus = st.replacingOccurrences(of: " ", with: "+")
            if collection == "" {
                query += stPlus
            }
            else {
                query += " AND \(stPlus)"
            }
        }

        if let sy = startYear, !sy.isEmpty {
            query += " AND date:[\(sy)-\(startMonthDay) "
        }
        else {
            query += " AND date:[1965-\(startMonthDay) "
        }
        if let ey = endYear, !ey.isEmpty {
            query += "TO \(ey)-\(endMonthDay)]"
        }
        else {
            query += "TO 2025-\(endMonthDay)]"
        }
 
        if let mr = minRating, !mr.isEmpty {
            query += " AND (avg_rating:[\(mr) TO 5.0])"
        }
        if let vu = venue, !vu.isEmpty {
            let vuPlus = vu.replacingOccurrences(of: " ", with: "+")
            query += " AND (venue:\(vuPlus))"
        }
        queryItems.append(URLQueryItem(name: "q", value: query))

        components?.queryItems = queryItems

        guard let url = components?.url else { return "" }
        print(url.absoluteString)
        return url.absoluteString
    }
     
    
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
            .response { response in
                completion(response.fileURL)
            }
    }
}


    
    

