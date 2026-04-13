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
        let endDay: String
        switch month {
        case 1,3,5,7,8,10,12:
            endDay = "31"
        case 4,6,9,11:
            endDay = "30"
        case 2:
            endDay = "28"
        default:
            endDay = "30"
        }

        url += String(year) + "-" + monthString + "-" + endDay
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
            query += "TO 2026-\(endMonthDay)]"
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
    
    func getIARequestMetadataDecodable(url: String, completion: @escaping (ShowMetadataModel?, Error?) -> Void) {
        let startTime = Date()
        print("[ArchiveAPI] Requesting metadata from URL: \(url) at \(timestamp())")

        AF.request(url).responseDecodable(of: ShowMetadataModel.self) { response in
            let duration = Date().timeIntervalSince(startTime)
            
            // Log detailed metrics
            if let metrics = response.metrics {
                print("[ArchiveAPI] Metrics for \(url):")
                print("  - Total Duration: \(String(format: "%.3f", metrics.taskInterval.duration))s")
                
                // Correctly access remoteAddress from the last transaction metric
                if #available(iOS 13.0, *), let lastTransaction = metrics.transactionMetrics.last, let remoteAddress = lastTransaction.remoteAddress {
                     print("  - Remote Address: \(remoteAddress)")
                }
                
                // Correctly calculate Time to First Byte from the first transaction's response start date
                if let firstResponseDate = metrics.transactionMetrics.first?.responseStartDate {
                    let timeToFirstByte = firstResponseDate.timeIntervalSince(metrics.taskInterval.start)
                    print("  - Time to First Byte: \(String(format: "%.3f", timeToFirstByte))s")
                }

                print("  - Serialization Duration: \(String(format: "%.3f", response.serializationDuration))s")
            } else {
                print("[ArchiveAPI] No metrics available.")
            }

            print("[ArchiveAPI] getIARequestMetadataDecodable for URL: \(url) took \(String(format: "%.3f", duration)) seconds.")
            
            switch response.result {
            case .success(let showMetadataModel):
                completion(showMetadataModel, nil)
            case .failure(let error):
                print("[ArchiveAPI] Error for URL \(url): \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    
    func getIARequestItemsDecodable(url: String, completion: @escaping (ShowMetadatas?, Error?) -> Void) {
        let startTime = Date()
        AF.request(url).responseDecodable(of: ShowMetadatas.self) { response in
            let duration = Date().timeIntervalSince(startTime)
            print("[ArchiveAPI] getIARequestItemsDecodable for URL: \(url) took \(String(format: "%.3f", duration)) seconds.")
            switch response.result {
            case .success(let showMetadatas):
                completion(showMetadatas, nil)
            case .failure(let error):
                print("[ArchiveAPI] Error for URL \(url): \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    
    @discardableResult
    func getIARequestTotal(url: String, completion: @escaping (YearsTotalResponse?) -> Void) -> DataRequest {
        let request = AF.request(url).responseDecodable(of: YearsTotalResponse.self) { response in
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
        guard let downloadURL = url else {
            completion(nil, NSError(domain: "ArchiveAPIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Download URL was nil"]))
            return
        }

        // Custom destination that supports nested paths present in some collections
        let destination: DownloadRequest.Destination = { _, response in
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            // Try to extract the relative path after /download/<identifier>/ from the request URL
            var relativePath: String
            let pathComponents = downloadURL.path.split(separator: "/").map(String.init)
            if let downloadIndex = pathComponents.firstIndex(of: "download"), pathComponents.count > downloadIndex + 2 {
                let remainder = pathComponents.suffix(from: downloadIndex + 2)
                relativePath = remainder.joined(separator: "/")
            } else {
                relativePath = response.suggestedFilename ?? downloadURL.lastPathComponent
            }

            // Sanitize and normalize the relative path to prevent path traversal
            let sanitized = relativePath
                .replacingOccurrences(of: "\\", with: "/")
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

            let components = sanitized.split(separator: "/").map(String.init)
            if sanitized.isEmpty || components.contains("..") {
                // Fallback to a flat filename if unsafe
                let fallback = documentsDirectory.appendingPathComponent(response.suggestedFilename ?? downloadURL.lastPathComponent)
                return (fallback, [.removePreviousFile, .createIntermediateDirectories])
            }

            // Build destination URL with intermediate directories
            var destinationURL = documentsDirectory
            for component in components {
                destinationURL.appendPathComponent(component)
            }

            return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        self.sessionManager.download(downloadURL, to: destination)
            .downloadProgress { (progressObject) in
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
                    print("Download completed with no file URL and no error for URL: \(downloadURL)")
                    completion(nil, NSError(domain: "ArchiveAPIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Download finished with an unknown state."]))
                }
            }
    }
    
    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }

    // MARK: - Collections Discovery

    struct ArchiveCollection: Codable {
        let identifier: String?
        let title: String?
    }

    private struct AdvancedSearchDoc: Codable {
        let identifier: String?
        let title: String?
        let date: String?
    }

    private struct AdvancedSearchResponse: Codable {
        struct Inner: Codable {
            let numFound: Int?
            let docs: [AdvancedSearchDoc]?
        }
        let response: Inner?
    }

    func fetchEtreeCollections(completion: @escaping ([ArchiveCollection]?, Error?) -> Void) {
        // List child collections under the Live Music Archive (etree)
        // advancedsearch: q=collection:etree AND mediatype:collection
        let q = "collection%3Aetree%20AND%20mediatype%3Acollection"
        let url = baseURLString + "advancedsearch.php?q=" + q + "&fl%5B%5D=identifier&fl%5B%5D=title&rows=50000&output=json"
        AF.request(url).responseDecodable(of: AdvancedSearchResponse.self) { response in
            switch response.result {
            case .success(let resp):
                let collections = (resp.response?.docs ?? []).map { ArchiveCollection(identifier: $0.identifier, title: $0.title) }
                completion(collections, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    func detectCreatorBased(collectionOrCreator id: String, completion: @escaping (Bool) -> Void) {
        // Heuristic: if collection:id has 0 results but creator:"id" has >0, treat as creator-based
        let qCollection = "collection%3A%28" + id + "%29"
        let urlCollection = baseURLString + "advancedsearch.php?q=" + qCollection + "&rows=0&output=json"
        AF.request(urlCollection).responseDecodable(of: AdvancedSearchResponse.self) { [weak self] response in
            guard let self = self else { return }
            let collectionCount = response.value?.response?.numFound ?? 0
            if collectionCount > 0 {
                completion(false)
                return
            }
            let qCreator = "creator%3A%22" + id + "%22"
            let urlCreator = self.baseURLString + "advancedsearch.php?q=" + qCreator + "&rows=0&output=json"
            AF.request(urlCreator).responseDecodable(of: AdvancedSearchResponse.self) { resp2 in
                let creatorCount = resp2.value?.response?.numFound ?? 0
                completion(creatorCount > 0)
            }
        }
    }

    func fetchCollectionYearRange(identifier: String, isCreatorBased: Bool, completion: @escaping ((Int, Int)?) -> Void) {
        // Query earliest and latest dates
        let fieldQuery: String
        if isCreatorBased {
            fieldQuery = "creator%3A%22" + identifier + "%22"
        } else {
            fieldQuery = "collection%3A%28" + identifier + "%29"
        }
        let dateQuery = "date%3A%5B0000-01-01%20TO%209999-12-31%5D"

        func makeURL(sort: String) -> String {
            return baseURLString + "advancedsearch.php?q=" + fieldQuery + "%20AND%20" + dateQuery + "&fl%5B%5D=date&sort%5B%5D=date+" + sort + "&rows=1&output=json"
        }

        AF.request(makeURL(sort: "asc")).responseDecodable(of: AdvancedSearchResponse.self) { responseAsc in
            let minYear: Int? = {
                guard let date = responseAsc.value?.response?.docs?.first?.date else { return nil }
                return ArchiveAPI.extractYear(from: date)
            }()
            AF.request(makeURL(sort: "desc")).responseDecodable(of: AdvancedSearchResponse.self) { responseDesc in
                let maxYear: Int? = {
                    guard let date = responseDesc.value?.response?.docs?.first?.date else { return nil }
                    return ArchiveAPI.extractYear(from: date)
                }()
                if let minY = minYear, let maxY = maxYear, minY <= maxY {
                    completion((minY, maxY))
                } else {
                    completion(nil)
                }
            }
        }
    }

    private static func extractYear(from dateString: String) -> Int? {
        // Accept YYYY, YYYY-MM, or YYYY-MM-DD
        if dateString.count >= 4 {
            let prefix = String(dateString.prefix(4))
            return Int(prefix)
        }
        return nil
    }
}


    
    
