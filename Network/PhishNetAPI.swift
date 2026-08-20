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
        if let path = Bundle.main.path(forResource: "PhishNetAPIKeys", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["APIKey"] as? String {
            self.apiKey = key
        } else {
            print("[PhishNetAPI] WARNING: PhishNetAPIKeys.plist not found or missing APIKey. Phish.net features disabled.")
            self.apiKey = ""
        }
    }

    /// Whether the API is configured with a valid key
    var isConfigured: Bool { !apiKey.isEmpty }

    // MARK: - Setlists

    /// Fetch the setlist for a given show date (format: "YYYY-MM-DD").
    /// Cache-first: the completion can fire twice (cached, then network-if-changed).
    func fetchSetlist(date: String, completion: @escaping (PhishNetSetlistResponse?, Error?) -> Void) {
        guard isConfigured else { completion(nil, nil); return }
        let url = baseURL + "setlists/showdate/\(date).json?apikey=\(apiKey)"
        MetadataCache.shared.fetchDecodable(url: url) { (setlistResponse: PhishNetSetlistResponse?, error: Error?) in
            if let error = error {
                print("[PhishNetAPI] Setlist error for \(date): \(error.localizedDescription)")
            }
            completion(setlistResponse, error)
        }
    }

    // MARK: - Shows

    /// Fetch show details for a given date.
    /// Cache-first: the completion can fire twice (cached, then network-if-changed).
    func fetchShow(date: String, completion: @escaping (PhishNetShowResponse?, Error?) -> Void) {
        guard isConfigured else { completion(nil, nil); return }
        let url = baseURL + "shows/showdate/\(date).json?apikey=\(apiKey)"
        MetadataCache.shared.fetchDecodable(url: url) { (showResponse: PhishNetShowResponse?, error: Error?) in
            if let error = error {
                print("[PhishNetAPI] Show error for \(date): \(error.localizedDescription)")
            }
            completion(showResponse, error)
        }
    }
}

// MARK: - Response Models

struct PhishNetSetlistResponse: Codable {
    let error: Bool?
    let error_message: String?
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
    let reviews: Int?
    let tourname: String?
}

struct PhishNetShowResponse: Codable {
    let error: Bool?
    let error_message: String?
    let data: [PhishNetShowEntry]?
}

struct PhishNetShowEntry: Codable {
    let showid: Int?
    let showdate: String?
    let venue: String?
    let city: String?
    let state: String?
    let country: String?
    let tour_name: String?
    let setlist_notes: String?
}
