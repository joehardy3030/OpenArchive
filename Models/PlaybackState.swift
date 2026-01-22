//
//  PlaybackState.swift
//  Breaze
//
//  Stores the playback state for resuming after app restart
//

import Foundation

struct PlaybackState: Codable {
    let showMetadataModel: ShowMetadataModel
    let trackIndex: Int
    let playbackPosition: Double  // Seconds into the track
    let isStreaming: Bool
    let savedAt: Date
    
    // Check if state is stale (older than 7 days)
    var isStale: Bool {
        let staleDays: TimeInterval = 7 * 24 * 60 * 60
        return Date().timeIntervalSince(savedAt) > staleDays
    }
}

// MARK: - Persistence via UserDefaults
extension PlaybackState {
    private static let storageKey = "lastPlaybackState"
    
    static func save(_ state: PlaybackState) {
        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("PlaybackState: Saved state for track \(state.trackIndex) at position \(state.playbackPosition)")
        } catch {
            print("PlaybackState: Failed to save - \(error.localizedDescription)")
        }
    }
    
    static func load() -> PlaybackState? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("PlaybackState: No saved state found")
            return nil
        }
        do {
            let state = try JSONDecoder().decode(PlaybackState.self, from: data)
            if state.isStale {
                print("PlaybackState: State is stale, clearing")
                clear()
                return nil
            }
            print("PlaybackState: Loaded state for track \(state.trackIndex)")
            return state
        } catch {
            print("PlaybackState: Failed to load - \(error.localizedDescription)")
            return nil
        }
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("PlaybackState: Cleared saved state")
    }
}
