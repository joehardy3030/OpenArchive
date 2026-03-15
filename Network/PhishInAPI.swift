//
//  PhishInAPI.swift
//  Breaze
//
//  Phish audio streams provided by Phish.in (https://phish.in).
//  Phish.in is a free, community-driven archive of Phish audience recordings.
//  No API key required. See https://phish.in/api-docs for API documentation.
//

import Foundation
import Alamofire

/// Client for the Phish.in API v2.
/// Provides Phish audience recordings with direct MP3 streaming URLs.
final class PhishInAPI {

    static let shared = PhishInAPI()

    private let baseURL = "https://phish.in/api/v2/"

    private init() {}

    // MARK: - Shows

    /// Fetch a show by date (format: "YYYY-MM-DD"). Returns tracks with MP3 URLs.
    func fetchShow(date: String, completion: @escaping (PhishInShow?, Error?) -> Void) {
        let url = baseURL + "shows/\(date)"
        print("[PhishInAPI] Fetching show for \(date)")
        AF.request(url, headers: ["Accept": "application/json"])
            .responseDecodable(of: PhishInShow.self) { response in
            switch response.result {
            case .success(let show):
                let trackCount = show.tracks?.count ?? 0
                print("[PhishInAPI] Show response for \(date): \(trackCount) tracks")
                completion(show, nil)
            case .failure(let error):
                print("[PhishInAPI] Show error for \(date): \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }

    /// Fetch shows for a given year. Returns show summaries (without tracks).
    func fetchShows(year: Int, completion: @escaping ([PhishInShowSummary]?, Error?) -> Void) {
        let url = baseURL + "shows?year=\(year)&per_page=200"
        print("[PhishInAPI] Fetching shows for year \(year)")
        AF.request(url, headers: ["Accept": "application/json"])
            .responseDecodable(of: PhishInYearResponse.self) { response in
            switch response.result {
            case .success(let yearResponse):
                let shows = yearResponse.shows ?? []
                print("[PhishInAPI] Year \(year): \(shows.count) shows")
                completion(shows, nil)
            case .failure(let error):
                print("[PhishInAPI] Year error for \(year): \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
}

// MARK: - Response Models

struct PhishInShow: Codable {
    let id: Int?
    let date: String?
    let venue_name: String?
    let tour_name: String?
    let taper_notes: String?
    let likes_count: Int?
    let duration: Int?
    let venue: PhishInVenue?
    let tracks: [PhishInTrack]?
    let cover_art_urls: PhishInCoverArt?
}

struct PhishInVenue: Codable {
    let name: String?
    let city: String?
    let state: String?
    let country: String?
    let location: String?
}

struct PhishInTrack: Codable {
    let id: Int?
    let title: String?
    let position: Int?
    let duration: Int?
    let set_name: String?
    let mp3_url: String?
    let likes_count: Int?
    let slug: String?
}

struct PhishInCoverArt: Codable {
    let large: String?
    let medium: String?
    let small: String?
}

struct PhishInShowSummary: Codable {
    let id: Int?
    let date: String?
    let venue_name: String?
    let tour_name: String?
    let likes_count: Int?
    let duration: Int?
    let venue: PhishInVenue?
}

struct PhishInYearResponse: Codable {
    let shows: [PhishInShowSummary]?
}
