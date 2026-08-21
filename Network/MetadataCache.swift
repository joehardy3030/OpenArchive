//
//  MetadataCache.swift
//  Breaze
//
//  Disk cache for API metadata responses with stale-while-revalidate reads:
//  callers get the cached copy immediately (no spinner, no lag), the network
//  is hit in the background, and the completion fires a second time only when
//  the payload actually changed. Entries live in Caches (purgeable by iOS),
//  keyed by request URL, stored in canonical (sorted-keys) encoded form so
//  volatile response fields the models don't capture (archive.org's server
//  rotation and uniq nonce) never register as diffs.
//

import Foundation
import CryptoKit
import Alamofire

final class MetadataCache {
    static let shared = MetadataCache()

    /// Cached copies younger than this skip background revalidation entirely,
    /// so rapid back-and-forth navigation doesn't hammer archive.org.
    static let revalidationInterval: TimeInterval = 10 * 60

    private let directory: URL
    private let queue = DispatchQueue(label: "com.chateauarchive.metadatacache", qos: .utility)

    /// Interactive metadata session. Timeout/retry tuning is deliberate:
    /// creator-based scrape queries legitimately take 20s+ when archive.org's
    /// query cache is cold (a 20s cap made them fail outright), and the server
    /// keeps computing after a client disconnect — so retries are spaced out
    /// (3s, 6s) to land on the warmed cache. The whole cycle runs behind
    /// non-blocking UI (month skeleton + toolbar spinner), so a slow fetch
    /// costs patience, not usability.
    private let session: Session = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 35
        let retry = RetryPolicy(retryLimit: 2, exponentialBackoffBase: 2, exponentialBackoffScale: 3)
        return Session(configuration: config, interceptor: retry)
    }()

    init(directoryName: String = "MetadataCache") {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent(directoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    // MARK: - Canonical encoding

    /// Deterministic encoding used both for storage and for diffing.
    static func canonical<T: Encodable>(_ value: T) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try? encoder.encode(value)
    }

    // MARK: - Disk store

    private func fileURL(for key: String) -> URL {
        let digest = SHA256.hash(data: Data(key.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(name).appendingPathExtension("json")
    }

    /// Loads a cached entry; completion fires on main with the data and the
    /// time it was saved (nil, nil on a miss).
    func load(key: String, completion: @escaping (Data?, Date?) -> Void) {
        queue.async {
            let url = self.fileURL(for: key)
            let data = try? Data(contentsOf: url)
            let savedAt = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
            DispatchQueue.main.async { completion(data, savedAt) }
        }
    }

    func save(key: String, data: Data) {
        queue.async {
            try? data.write(to: self.fileURL(for: key), options: .atomic)
        }
    }

    // MARK: - Stale-while-revalidate fetch

    /// Fetches a Codable endpoint with cache-first semantics. The completion can
    /// fire twice: immediately with the cached copy (if any), and again with the
    /// network result only when it differs — so callers must be idempotent.
    /// Network errors are surfaced only when there is no cached copy to serve.
    func fetchDecodable<T: Codable>(url: String,
                                    headers: HTTPHeaders? = nil,
                                    completion: @escaping (T?, Error?) -> Void) {
        load(key: url) { cachedData, savedAt in
            var cachedCanonical: Data? = nil
            if let cachedData = cachedData,
               let decoded = try? JSONDecoder().decode(T.self, from: cachedData) {
                cachedCanonical = cachedData
                completion(decoded, nil)
                if let savedAt = savedAt,
                   Date().timeIntervalSince(savedAt) < Self.revalidationInterval {
                    return
                }
            }
            // validate() makes HTTP errors (archive.org load-shedding 503s serve
            // an HTML error page) fail cleanly instead of reaching the decoder,
            // and guarantees RetryPolicy sees them as retryable.
            self.session.request(url, headers: headers).validate().responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let fresh):
                    guard let canonical = Self.canonical(fresh) else { return }
                    // Always rewrite so the timestamp refreshes and revalidation
                    // stays throttled; only re-publish when content changed.
                    self.save(key: url, data: canonical)
                    if canonical != cachedCanonical {
                        completion(fresh, nil)
                    }
                case .failure(let error):
                    if cachedCanonical == nil {
                        completion(nil, error)
                    }
                }
            }
        }
    }
}
