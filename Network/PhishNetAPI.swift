//
//  PhishNetAPI.swift
//  Breaze
//
//  Phish show metadata (setlists, ratings, venues, etc.) is provided by Phish.net,
//  a project of the non-profit Mockingbird Foundation (https://phish.net).
//  Data courtesy of Phish.net / The Mockingbird Foundation.
//
//  Used under the Phish.net API v5 General License for non-commercial applications.
//  See https://api.phish.net/keys/ for API Terms of Service.
//
//  Application: "Chateau"
//  API keys stored locally in PhishNetAPIKeys.plist (not committed to source control).
//

import Foundation
import Alamofire

/// Client for the Phish.net API v5.
/// Provides Phish show metadata: setlists, ratings, venues, and jam notes.
final class PhishNetAPI {

    static let shared = PhishNetAPI()

    private let baseURL = "https://api.phish.net/v5/"
    private let apiKey: String

    private init() {
        // Load API key from the gitignored plist
        guard let path = Bundle.main.path(forResource: "PhishNetAPIKeys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["APIKey"] as? String else {
            fatalError("PhishNetAPIKeys.plist not found or missing APIKey. See Network/PhishNetAPI.swift for setup instructions.")
        }
        self.apiKey = key
    }

    // MARK: - Setlists

    /// Fetch the setlist for a given show date (format: "YYYY-MM-DD").
    func fetchSetlist(date: String, completion: @escaping (PhishNetSetlistResponse?, Error?) -> Void) {
        let url = baseURL + "setlists/showdate/\(date).json?apikey=\(apiKey)"
        AF.request(url).responseDecodable(of: PhishNetSetlistResponse.self) { response in
            switch response.result {
            case .success(let setlistResponse):
                completion(setlistResponse, nil)
            case .failure(let error):
                print("[PhishNetAPI] Setlist error for \(date): \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }

    // MARK: - Shows

    /// Fetch show details for a given date.
    func fetchShow(date: String, completion: @escaping (PhishNetShowResponse?, Error?) -> Void) {
        let url = baseURL + "shows/showdate/\(date).json?apikey=\(apiKey)"
        AF.request(url).responseDecodable(of: PhishNetShowResponse.self) { response in
            switch response.result {
            case .success(let showResponse):
                completion(showResponse, nil)
            case .failure(let error):
                print("[PhishNetAPI] Show error for \(date): \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
}

// MARK: - Response Models

struct PhishNetSetlistResponse: Codable {
    let error_code: Int?
    let data: [PhishNetSetlistEntry]?
}

struct PhishNetSetlistEntry: Codable {
    let showid: Int?
    let showdate: String?
    let venue: String?
    let city: String?
    let state: String?
    let country: String?
    let setlistnotes: String?
    let song: String?
    let position: Int?
    let set: String?
    let isjamchart: Int?
    let jamchart_description: String?
}

struct PhishNetShowResponse: Codable {
    let error_code: Int?
    let data: [PhishNetShowEntry]?
}

struct PhishNetShowEntry: Codable {
    let showid: Int?
    let showdate: String?
    let venue: String?
    let city: String?
    let state: String?
    let country: String?
    let rating: String?
}
