//
//  BackgroundDownloadManager.swift
//  Breaze
//
//  Hybrid downloader: uses a default URLSession while the app is foreground
//  (near-native speed) and a background URLSession when the app has been
//  suspended (slower but survives indefinitely). Background-session callbacks
//  also work after the OS relaunches the app to deliver pending events.
//

import Foundation
import UIKit

final class BackgroundDownloadManager: NSObject {
    static let shared = BackgroundDownloadManager()

    static let sessionIdentifier = "com.chateauarchive.backgrounddownload"

    private struct Job {
        let sourceURL: URL
        let progress: (Double) -> Void
        let completion: (URL?, Error?) -> Void
    }

    /// Key disambiguates tasks across the two sessions; each session has its own
    /// taskIdentifier space and they can collide.
    private struct JobKey: Hashable {
        let isBackground: Bool
        let taskID: Int
    }

    private var jobs: [JobKey: Job] = [:]
    private let jobsLock = NSLock()

    private var backgroundCompletionHandler: (() -> Void)?

    /// Tracked via app-state notifications so we can read it from any thread.
    /// Defaults to true since the app is foreground at first launch.
    private var isAppActive: Bool = true

    private lazy var foregroundSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpMaximumConnectionsPerHost = 4
        let s = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        print("BackgroundDownloadManager: foreground session created")
        return s
    }()

    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
        config.isDiscretionary = false             // user-initiated; don't defer
        config.sessionSendsLaunchEvents = true     // relaunch app on completion
        config.timeoutIntervalForRequest = 60      // idle timeout per chunk
        let s = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        print("BackgroundDownloadManager: background session created (id=\(Self.sessionIdentifier))")
        return s
    }()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.isAppActive = true
            print("BackgroundDownloadManager: app became active (foreground session enabled)")
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.isAppActive = false
            print("BackgroundDownloadManager: app resigning active (background session enabled)")
        }
    }

    /// Instantiates both sessions and cancels any stale tasks left in the
    /// background session from a previous launch (we have no completion handler
    /// to deliver them to, and they tend to interfere with new tasks for the same URL).
    func prepare() {
        _ = foregroundSession
        _ = backgroundSession
        backgroundSession.getAllTasks { tasks in
            print("BackgroundDownloadManager: prepare() — \(tasks.count) stale background task(s)")
            for t in tasks {
                print("  task \(t.taskIdentifier) state=\(t.state.rawValue) url=\(t.originalRequest?.url?.absoluteString ?? "?")")
                t.cancel()
            }
        }
    }

    /// Starts a download. Routes to the foreground session if the app is active
    /// (fast), or the background session if the app is suspended (slower but
    /// resilient). `progress` (0.0–1.0) and `completion` both fire on main.
    func download(from sourceURL: URL,
                  progress: @escaping (Double) -> Void = { _ in },
                  completion: @escaping (URL?, Error?) -> Void) {
        let useBackground = !isAppActive
        let session = useBackground ? backgroundSession : foregroundSession
        let task = session.downloadTask(with: sourceURL)
        let key = JobKey(isBackground: useBackground, taskID: task.taskIdentifier)
        jobsLock.lock()
        jobs[key] = Job(sourceURL: sourceURL, progress: progress, completion: completion)
        jobsLock.unlock()
        task.resume()
        print("BackgroundDownloadManager: enqueued task \(task.taskIdentifier) on \(useBackground ? "background" : "foreground") session url=\(sourceURL.absoluteString)")
    }

    /// Called by AppDelegate's `application(_:handleEventsForBackgroundURLSession:completionHandler:)`.
    /// We stash the handler and invoke it after all queued delegate events have been delivered.
    func handleEventsForBackgroundURLSession(identifier: String, completionHandler: @escaping () -> Void) {
        guard identifier == Self.sessionIdentifier else {
            completionHandler()
            return
        }
        _ = backgroundSession  // ensure the session exists to receive callbacks
        backgroundCompletionHandler = completionHandler
    }

    /// Derives the on-disk destination for a download URL. Mirrors the path logic
    /// used by the previous Alamofire-based downloader so existing files line up.
    static func destinationURL(forSourceURL sourceURL: URL, suggestedFilename: String?) -> URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let pathComponents = sourceURL.path.split(separator: "/").map(String.init)
        var relativePath: String
        if let downloadIndex = pathComponents.firstIndex(of: "download"),
           pathComponents.count > downloadIndex + 2 {
            relativePath = pathComponents.suffix(from: downloadIndex + 2).joined(separator: "/")
        } else {
            relativePath = suggestedFilename ?? sourceURL.lastPathComponent
        }

        let sanitized = relativePath
            .replacingOccurrences(of: "\\", with: "/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = sanitized.split(separator: "/").map(String.init)
        if sanitized.isEmpty || components.contains("..") {
            return docs.appendingPathComponent(suggestedFilename ?? sourceURL.lastPathComponent)
        }

        var destination = docs
        for component in components {
            destination.appendPathComponent(component)
        }
        return destination
    }

    private func popJob(taskID: Int, session: URLSession) -> Job? {
        let key = JobKey(isBackground: session === backgroundSession, taskID: taskID)
        jobsLock.lock()
        let job = jobs.removeValue(forKey: key)
        jobsLock.unlock()
        return job
    }

    private func peekJob(taskID: Int, session: URLSession) -> Job? {
        let key = JobKey(isBackground: session === backgroundSession, taskID: taskID)
        jobsLock.lock()
        let job = jobs[key]
        jobsLock.unlock()
        return job
    }

    private func finish(taskID: Int, session: URLSession, with url: URL?, error: Error?) {
        guard let job = popJob(taskID: taskID, session: session) else { return }
        DispatchQueue.main.async { job.completion(url, error) }
    }
}

extension BackgroundDownloadManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        // Throttle logging: only log once per ~1MB so the console isn't flooded.
        let lastLogged = (downloadTask.taskDescription as NSString?)?.longLongValue ?? 0
        let megabytesWritten = totalBytesWritten / 1_000_000
        if megabytesWritten > lastLogged {
            downloadTask.taskDescription = "\(megabytesWritten)"
            let totalMB = totalBytesExpectedToWrite > 0 ? "\(totalBytesExpectedToWrite / 1_000_000)MB" : "?MB"
            print("BackgroundDownloadManager: task \(downloadTask.taskIdentifier) progress \(megabytesWritten)MB/\(totalMB)")
        }

        // Forward fractional progress to the job's caller.
        guard totalBytesExpectedToWrite > 0 else { return }
        let fraction = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        if let progress = peekJob(taskID: downloadTask.taskIdentifier, session: session)?.progress {
            DispatchQueue.main.async { progress(fraction) }
        }
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("BackgroundDownloadManager: session became invalid: \(error?.localizedDescription ?? "no error")")
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let taskID = downloadTask.taskIdentifier
        guard let sourceURL = downloadTask.originalRequest?.url ?? downloadTask.currentRequest?.url else {
            print("BackgroundDownloadManager: download finished with no source URL")
            return
        }

        // Validate HTTP status
        let httpResponse = downloadTask.response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0
        if !(200..<300).contains(statusCode) {
            let err = NSError(domain: "BackgroundDownload", code: statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "HTTP \(statusCode) for \(sourceURL.absoluteString)"])
            print("BackgroundDownloadManager: bad HTTP status \(statusCode) for \(sourceURL)")
            finish(taskID: taskID, session: session, with: nil, error: err)
            return
        }

        // Derive destination and move from temp
        guard let destination = Self.destinationURL(forSourceURL: sourceURL,
                                                    suggestedFilename: httpResponse?.suggestedFilename) else {
            let err = NSError(domain: "BackgroundDownload", code: 200,
                              userInfo: [NSLocalizedDescriptionKey: "Could not derive destination for \(sourceURL.absoluteString)"])
            print("BackgroundDownloadManager: \(err.localizedDescription)")
            finish(taskID: taskID, session: session, with: nil, error: err)
            return
        }

        let fm = FileManager.default
        do {
            try fm.createDirectory(at: destination.deletingLastPathComponent(),
                                   withIntermediateDirectories: true)
            if fm.fileExists(atPath: destination.path) {
                try fm.removeItem(at: destination)
            }
            try fm.moveItem(at: location, to: destination)
        } catch {
            print("BackgroundDownloadManager: failed to move temp file to \(destination.path): \(error.localizedDescription)")
            finish(taskID: taskID, session: session, with: nil, error: error)
            return
        }

        // Validate the on-disk file (size, magic bytes, optional Content-Length match)
        let expectedSize = httpResponse?.expectedContentLength ?? -1
        if let validationError = ArchiveAPI.validateDownloadedMP3(at: destination, expectedSize: expectedSize) {
            print("BackgroundDownloadManager: validation failed for \(destination.path): \(validationError.localizedDescription)")
            try? fm.removeItem(at: destination)
            finish(taskID: taskID, session: session, with: nil, error: validationError)
            return
        }

        print("BackgroundDownloadManager: download finished, saved to: \(destination.path)")
        finish(taskID: taskID, session: session, with: destination, error: nil)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        // didFinishDownloadingTo handles the success path. We only need to act here
        // on real transport errors, and only if the job hasn't already been resolved.
        guard let error = error else { return }
        let sourceURL = task.originalRequest?.url?.absoluteString ?? "?"
        print("BackgroundDownloadManager: task failed for \(sourceURL): \(error.localizedDescription)")
        finish(taskID: task.taskIdentifier, session: session, with: nil, error: error)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}
