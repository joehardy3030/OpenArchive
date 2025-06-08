//
//  ArchiveAPI.swift
//  Breaze
//
//  Created by Joe Hardy on 6/25/20.
//  Copyright 2020 Carquinez. All rights reserved.
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
        
        // Check if this is a creator-based search
        if CollectionConfig.isCreatorBased(collection: collection) {
                url += "q=creator%3A%22" + collection + "%22"
        } else {
            // Original collection-based search
            if sbdOnly {
                url += "q=collection%3A%28" + collection + "%20AND%20stream_only%29"
            } else {
                url += "q=collection%3A%28" + collection + "%29"
            }
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
        print(url)
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
        
        // Check if this is a creator-based search
        if CollectionConfig.isCreatorBased(collection: collection) {
                url += "q=creator%3A%22" + collection + "%22"
        } else {
            // Original collection-based search
            if sbdOnly {
                url += "q=collection%3A%28" + collection + "%20AND%20stream_only%29"
            } else {
                url += "q=collection%3A%28" + collection + "%29"
            }
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

    func yearRangeTotalURL(year: Int, sbdOnly: Bool, collection: String = "GratefulDead") -> String {

        let firstDayMonth = "01-01"
        let lastDayMonth = "12-31"
        let andString = "%20AND%20"
        let dateString = "date%3A%5B"
        let toString = "%20TO%20"
        var url = baseURLString
                
        url += "advancedsearch.php?"
        //url += "fields=identifier,date,venue,transferer,source,coverage,stars,avg_rating,num_reviews,collection,creator&"
        
        // Check if this is a creator-based search
        if CollectionConfig.isCreatorBased(collection: collection) {
                url += "q=creator%3A%22" + collection + "%22"
        } else {
            // Original collection-based search
            if sbdOnly {
                url += "q=collection%3A%28" + collection + "%20AND%20stream_only%29"
            } else {
                url += "q=collection%3A%28" + collection + "%29"
            }
        }
        
        url += andString
        url += dateString
        url += String(year) + "-" + firstDayMonth
        url += toString
        url += String(year) + "-" + lastDayMonth
        url += "%5D"
        url += "&output=json&rows=0"
        
        print(url)
        return url
    }

    
    func searchTermURL(searchTerm: String?, venue: String?, minRating: String?, startYear: String?, endYear: String?, sbdOnly: Bool?, collection: String = "GratefulDead") -> String {
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
        
        // Check if this is a creator-based search
        if CollectionConfig.isCreatorBased(collection: collection) {
            if let _ = sbdOnly {
                query += "creator:\"" + collection + "\" AND collection:stream_only"
            } else {
                query += "creator:\"" + collection + "\""
            }
        } else {
            // Original collection-based search
            if let _ = sbdOnly {
                query += "collection:(" + collection + "%20AND%20stream_only)"
            } else {
                query += "collection:" + collection
            }
        }
        
        if let st = searchTerm, !st.isEmpty {
            let stPlus = st.replacingOccurrences(of: " ", with: "+")
            query += " AND \(stPlus)"
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

    
    func getIARequestItemsDecodable(url: String, completion: @escaping (ShowMetadatas?, Error?) -> Void) {
        AF.request(url).responseDecodable(of: ShowMetadatas.self) { response in
            switch response.result {
            case .success(let showMetadatas):
                completion(showMetadatas, nil)
            case .failure(let error):
                print(error)
                completion(nil, error)
            }
        }
    }
    
    @discardableResult
    func getIARequestTotal(url: String, completion: @escaping (YearsTotalResponse?) -> Void) -> DataRequest {
        let request = AF.request(url).responseDecodable(of: YearsTotalResponse.self) { response in
            // print(response) // Remove or comment out for cleaner logs
            switch response.result {
            case .success(let yearsTotalResponse):
                completion(yearsTotalResponse)
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                completion(nil)
            }
        }
        return request
    }
    
    func getIADownload(url: URL?,
                       progressHandler: ((_ progress: Double) -> Void)? = nil,
                       completion: @escaping (_ localFileURL: URL?, _ error: Error?) -> Void) {
        //https://github.com/Alamofire/Alamofire/blob/master/Documentation/Usage.md#downloading-data-to-a-file
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory) // Consider a more specific directory based on show/track
        guard let downloadURL = url else {
            completion(nil, NSError(domain: "ArchiveAPIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download URL was nil"]))
            return
        }
        self.sessionManager.download(downloadURL, to: destination)
            .downloadProgress { (progressObject) in // Renamed 'progress' to 'progressObject' to avoid conflict
                // print("Progress: \(progressObject.fractionCompleted)") // Original print statement
                progressHandler?(progressObject.fractionCompleted)
            }
            .response { response in
                if let error = response.error {
                    print("Download failed with error: \(error.localizedDescription) for URL: \(downloadURL)")
                    completion(nil, error)
                } else if let fileURL = response.fileURL {
                    print("Download finished. File saved to: \(fileURL.path) for URL: \(downloadURL)")
                    completion(fileURL, nil)
                } else {
                    // This case should ideally not be reached if Alamofire's API guarantees either fileURL or error.
                    print("Download completed with no file URL and no error for URL: \(downloadURL)")
                    completion(nil, NSError(domain: "ArchiveAPIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Download finished with an unknown state."]))
                }
            }
    }
}


    
    
