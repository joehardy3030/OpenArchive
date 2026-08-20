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
        // Idle timeout: detect stalled transfers (no bytes for N seconds) so we can retry
        // rather than hanging indefinitely. Total resource time stays unlimited.
        configuration.timeoutIntervalForRequest = 60
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
                url += "q=creator%3A%22" + Self.encodeQueryValue(collection) + "%22"
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
            endDay = (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? "29" : "28"
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
                url += "q=creator%3A%22" + Self.encodeQueryValue(collection) + "%22"
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
                url += "q=creator%3A%22" + Self.encodeQueryValue(collection) + "%22"
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
            .validate(statusCode: 200..<300)
            .downloadProgress { (progressObject) in
                progressHandler?(progressObject.fractionCompleted)
            }
            .response { response in
                if let error = response.error {
                    print("Download failed with error: \(error.localizedDescription) for URL: \(downloadURL)")
                    completion(nil, error)
                } else if let fileURL = response.fileURL {
                    let expectedSize = response.response?.expectedContentLength ?? -1
                    if let validationError = ArchiveAPI.validateDownloadedMP3(at: fileURL, expectedSize: expectedSize) {
                        print("Download validation failed for \(fileURL.path): \(validationError.localizedDescription)")
                        try? FileManager.default.removeItem(at: fileURL)
                        completion(nil, validationError)
                    } else {
                        print("Download finished. File saved to: \(fileURL.path) for URL: \(downloadURL)")
                        completion(fileURL, nil)
                    }
                } else {
                    print("Download completed with no file URL and no error for URL: \(downloadURL)")
                    completion(nil, NSError(domain: "ArchiveAPIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Download finished with an unknown state."]))
                }
            }
    }

    /// Validates a freshly downloaded MP3 file. Catches HTML error pages saved as .mp3,
    /// truncated downloads, and other corruption that the network layer didn't flag.
    /// Returns an error describing the problem, or nil if the file looks valid.
    static func validateDownloadedMP3(at url: URL, expectedSize: Int64) -> NSError? {
        func err(_ code: Int, _ message: String) -> NSError {
            NSError(domain: "ArchiveAPIDownloadValidation", code: code, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let attrs: [FileAttributeKey: Any]
        do {
            attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        } catch {
            return err(100, "Could not read attributes of downloaded file")
        }
        guard let actualSize = (attrs[.size] as? NSNumber)?.int64Value else {
            return err(101, "Downloaded file has no size attribute")
        }

        // Concert MP3 tracks are at minimum hundreds of KB. Anything under 10KB is
        // almost certainly an HTML error page or a truncated start.
        if actualSize < 10_000 {
            return err(102, "Downloaded file is suspiciously small (\(actualSize) bytes)")
        }

        // If the server told us the size, the file should match. Allow a small slack
        // for the off chance the server reports differently than what was written.
        if expectedSize > 0 && llabs(actualSize - expectedSize) > 1024 {
            return err(103, "Size mismatch — expected \(expectedSize) bytes, got \(actualSize)")
        }

        // Magic bytes: MP3 files start with either an "ID3" tag or an MPEG frame sync
        // (0xFF followed by a byte whose top 3 bits are set).
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return err(104, "Could not open downloaded file for header check")
        }
        defer { try? handle.close() }
        let header = handle.readData(ofLength: 3)
        guard header.count == 3 else {
            return err(105, "Downloaded file is too short to contain a valid MP3 header")
        }
        let b0 = header[0], b1 = header[1], b2 = header[2]
        let isID3 = (b0 == 0x49 && b1 == 0x44 && b2 == 0x33)        // "ID3"
        let isFrameSync = (b0 == 0xFF && (b1 & 0xE0) == 0xE0)        // MPEG sync
        if !isID3 && !isFrameSync {
            return err(106, "Downloaded file does not start with a valid MP3 header (got \(String(format: "%02X %02X %02X", b0, b1, b2)))")
        }

        return nil
    }
    
    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }

    // MARK: - Collections Discovery

    /// Percent-encodes a value for the manually assembled query URLs above.
    /// Creator names can contain spaces, ampersands, and quotes ("Pearl Jam",
    /// "Medeski Martin & Wood") which would otherwise produce invalid URLs.
    static func encodeQueryValue(_ value: String) -> String {
        return value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
    }

    struct ArchiveCollection: Codable {
        let identifier: String?
        let title: String?
    }

    struct ArchiveCreator: Codable {
        let name: String
        let count: Int
    }

    private struct ScrapeCreatorsResponse: Codable {
        struct Item: Codable {
            let creator: [String]?

            enum CodingKeys: String, CodingKey { case creator }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                // creator can be a string or an array, like other archive.org fields
                if let array = try? container.decodeIfPresent([String].self, forKey: .creator) {
                    creator = array
                } else if let single = try? container.decodeIfPresent(String.self, forKey: .creator) {
                    creator = [single]
                } else {
                    creator = nil
                }
            }
        }
        let items: [Item]?
        let cursor: String?
    }

    /// Enumerates the distinct artists (creator field) inside an archive.org
    /// collection by paging the scrape API, with per-artist tape counts.
    /// Used to browse multi-artist collections like taperssection per band;
    /// selected artists are then added as creator-based entries (the Phish
    /// pattern), which finds their tapes across all collections.
    func fetchCreators(inCollection collection: String,
                       completion: @escaping ([ArchiveCreator]?, Error?) -> Void) {
        var counts = [String: Int]()

        func fetchPage(cursor: String?) {
            var url = baseURLString + "services/search/v1/scrape?fields=creator&count=10000"
            url += "&q=collection%3A%28" + Self.encodeQueryValue(collection) + "%29"
            if let cursor = cursor {
                url += "&cursor=" + Self.encodeQueryValue(cursor)
            }
            AF.request(url).responseDecodable(of: ScrapeCreatorsResponse.self) { response in
                switch response.result {
                case .success(let resp):
                    for item in resp.items ?? [] {
                        if let name = item.creator?.first?.trimmingCharacters(in: .whitespaces),
                           !name.isEmpty {
                            counts[name, default: 0] += 1
                        }
                    }
                    if let next = resp.cursor {
                        fetchPage(cursor: next)
                    } else {
                        let creators = counts
                            .map { ArchiveCreator(name: $0.key, count: $0.value) }
                            .sorted {
                                if $0.count != $1.count { return $0.count > $1.count }
                                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                            }
                        completion(creators, nil)
                    }
                case .failure(let error):
                    completion(nil, error)
                }
            }
        }
        fetchPage(cursor: nil)
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
        let qCollection = "collection%3A%28" + Self.encodeQueryValue(id) + "%29"
        let urlCollection = baseURLString + "advancedsearch.php?q=" + qCollection + "&rows=0&output=json"
        AF.request(urlCollection).responseDecodable(of: AdvancedSearchResponse.self) { [weak self] response in
            guard let self = self else { return }
            let collectionCount = response.value?.response?.numFound ?? 0
            if collectionCount > 0 {
                completion(false)
                return
            }
            let qCreator = "creator%3A%22" + Self.encodeQueryValue(id) + "%22"
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
            fieldQuery = "creator%3A%22" + Self.encodeQueryValue(identifier) + "%22"
        } else {
            fieldQuery = "collection%3A%28" + Self.encodeQueryValue(identifier) + "%29"
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


    
    
