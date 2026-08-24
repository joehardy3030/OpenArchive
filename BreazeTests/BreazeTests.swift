//
//  BreazeTests.swift
//  BreazeTests
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import XCTest
@testable import Chateau

class BreazeTests: XCTestCase {

    // MARK: - ArchiveAPI URL Construction

    func testMetadataURL() {
        let api = ArchiveAPI()
        let url = api.metadataURL(identifier: "gd1977-05-08.sbd")
        XCTAssertEqual(url, "https://archive.org/metadata/gd1977-05-08.sbd")
    }

    func testDownloadURL() {
        let api = ArchiveAPI()
        let url = api.downloadURL(identifier: "gd1977-05-08", filename: "track01.mp3")
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("download/gd1977-05-08/track01.mp3"))
    }

    func testDownloadURLNilIdentifier() {
        let api = ArchiveAPI()
        let url = api.downloadURL(identifier: nil, filename: nil)
        XCTAssertNotNil(url)
        XCTAssertEqual(url!.absoluteString, "https://archive.org/download/")
    }

    func testDateRangeURLMonthEndDays() {
        let api = ArchiveAPI()

        // 31-day months
        for month in [1, 3, 5, 7, 8, 10, 12] {
            let url = api.dateRangeURL(year: 1987, month: month, sbdOnly: false)
            let monthStr = month < 10 ? "0\(month)" : "\(month)"
            XCTAssertTrue(url.contains("1987-\(monthStr)-31"), "Month \(month) should end on 31")
        }

        // 30-day months
        for month in [4, 6, 9, 11] {
            let url = api.dateRangeURL(year: 1987, month: month, sbdOnly: false)
            let monthStr = month < 10 ? "0\(month)" : "\(month)"
            XCTAssertTrue(url.contains("1987-\(monthStr)-30"), "Month \(month) should end on 30")
        }

        // February non-leap
        let febURL = api.dateRangeURL(year: 1987, month: 2, sbdOnly: false)
        XCTAssertTrue(febURL.contains("1987-02-01%20TO%201987-02-28"))
        XCTAssertFalse(febURL.contains("1987-02-31"))
    }

    func testDateRangeURLLeapYear() {
        let api = ArchiveAPI()

        // Standard leap year
        let leap = api.dateRangeURL(year: 2024, month: 2, sbdOnly: false)
        XCTAssertTrue(leap.contains("2024-02-01%20TO%202024-02-29"))

        // Non-leap year
        let nonLeap = api.dateRangeURL(year: 2023, month: 2, sbdOnly: false)
        XCTAssertTrue(nonLeap.contains("2023-02-01%20TO%202023-02-28"))

        // Century non-leap (divisible by 100 but not 400)
        let century = api.dateRangeURL(year: 1900, month: 2, sbdOnly: false)
        XCTAssertTrue(century.contains("1900-02-28"))

        // Century leap (divisible by 400)
        let century400 = api.dateRangeURL(year: 2000, month: 2, sbdOnly: false)
        XCTAssertTrue(century400.contains("2000-02-29"))
    }

    func testDateRangeURLSBDOnlyFlag() {
        let api = ArchiveAPI()

        let sbdURL = api.dateRangeURL(year: 1977, month: 5, sbdOnly: true)
        XCTAssertTrue(sbdURL.contains("stream_only"))

        let allURL = api.dateRangeURL(year: 1977, month: 5, sbdOnly: false)
        XCTAssertFalse(allURL.contains("stream_only"))
    }

    func testDateRangeURLCreatorBased() {
        let api = ArchiveAPI()
        let url = api.dateRangeURL(year: 2023, month: 7, sbdOnly: false, collection: "Phish")
        XCTAssertTrue(url.contains("creator"))
        XCTAssertFalse(url.contains("collection%3A"))
    }

    func testEncodeQueryValue() {
        XCTAssertEqual(ArchiveAPI.encodeQueryValue("Phish"), "Phish")
        XCTAssertEqual(ArchiveAPI.encodeQueryValue("Pearl Jam"), "Pearl%20Jam")
        XCTAssertEqual(ArchiveAPI.encodeQueryValue("Medeski Martin & Wood"),
                       "Medeski%20Martin%20%26%20Wood")
    }

    func testDateRangeURLCreatorWithSpaces() {
        // Creator-based band whose name needs percent-encoding (taperssection adds)
        let defaults = UserDefaults.standard
        let key = "creatorBasedCollectionsExtra"
        let saved = defaults.stringArray(forKey: key)
        defaults.set((saved ?? []) + ["Pearl Jam"], forKey: key)
        defer { defaults.set(saved, forKey: key) }

        let api = ArchiveAPI()
        let url = api.dateRangeURL(year: 1992, month: 2, sbdOnly: false, collection: "Pearl Jam")
        XCTAssertTrue(url.contains("creator%3A%22Pearl%20Jam%22"))
        XCTAssertNotNil(URL(string: url), "URL with encoded creator must be valid")
    }

    func testDateRangeURLCollectionBased() {
        let api = ArchiveAPI()
        let url = api.dateRangeURL(year: 1977, month: 5, sbdOnly: false, collection: "GratefulDead")
        XCTAssertTrue(url.contains("collection%3A"))
        XCTAssertTrue(url.contains("GratefulDead"))
    }

    func testDateRangeURLMonthPadding() {
        let api = ArchiveAPI()

        // Single digit month should be zero-padded
        let url = api.dateRangeURL(year: 1977, month: 3, sbdOnly: false)
        XCTAssertTrue(url.contains("1977-03-01"))

        // Double digit month should not be padded
        let url2 = api.dateRangeURL(year: 1977, month: 11, sbdOnly: false)
        XCTAssertTrue(url2.contains("1977-11-01"))
    }

    func testDateRangeYearURL() {
        let api = ArchiveAPI()
        let url = api.dateRangeYearURL(year: 1977, sbdOnly: false)
        XCTAssertTrue(url.contains("1977-01-01"))
        XCTAssertTrue(url.contains("1977-12-31"))
    }

    func testYearRangeTotalURL() {
        let api = ArchiveAPI()
        let url = api.yearRangeTotalURL(year: 1977, sbdOnly: true)
        XCTAssertTrue(url.contains("advancedsearch.php"))
        XCTAssertTrue(url.contains("1977-01-01"))
        XCTAssertTrue(url.contains("1977-12-31"))
        XCTAssertTrue(url.contains("rows=0"))
    }

    func testSearchTermURLBasic() {
        let api = ArchiveAPI()
        let url = api.searchTermURL(searchTerm: "Sugaree", venue: nil, minRating: nil, startYear: nil, endYear: nil, sbdOnly: nil)
        XCTAssertTrue(url.contains("Sugaree"))
        XCTAssertTrue(url.contains("collection"))
    }

    func testSearchTermURLWithAllParameters() {
        let api = ArchiveAPI()
        let url = api.searchTermURL(searchTerm: "Scarlet", venue: "MSG", minRating: "4.0", startYear: "1977", endYear: "1978", sbdOnly: true)
        XCTAssertTrue(url.contains("Scarlet"))
        XCTAssertTrue(url.contains("MSG"))
        XCTAssertTrue(url.contains("4.0"))
        XCTAssertTrue(url.contains("1977"))
        XCTAssertTrue(url.contains("1978"))
        XCTAssertTrue(url.contains("stream_only"))
    }

    func testSearchTermURLCreatorBased() {
        let api = ArchiveAPI()
        let url = api.searchTermURL(searchTerm: "Tweezer", venue: nil, minRating: nil, startYear: nil, endYear: nil, sbdOnly: nil, collection: "Phish")
        XCTAssertTrue(url.contains("creator"))
        XCTAssertTrue(url.contains("Phish"))
    }

    // MARK: - AudioPlayerArchive.normalizedStartIndex

    func testNormalizedStartIndexEmptyCollection() {
        XCTAssertNil(AudioPlayerArchive.normalizedStartIndex(0, count: 0))
        XCTAssertNil(AudioPlayerArchive.normalizedStartIndex(5, count: 0))
    }

    func testNormalizedStartIndexNegativeIndex() {
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(-1, count: 5), 0)
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(-100, count: 3), 0)
    }

    func testNormalizedStartIndexValidIndex() {
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(0, count: 5), 0)
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(2, count: 5), 2)
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(4, count: 5), 4)
    }

    func testNormalizedStartIndexOverflow() {
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(5, count: 5), 4)
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(100, count: 3), 2)
    }

    func testNormalizedStartIndexSingleElement() {
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(0, count: 1), 0)
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(5, count: 1), 0)
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(-1, count: 1), 0)
    }

    // MARK: - MetadataCache

    func testMetadataCacheCanonicalEncodingIsDeterministic() {
        var a = ShowMetadata(identifier: "x")
        a.venue = "Winterland"
        var b = ShowMetadata(identifier: "x")
        b.venue = "Winterland"
        XCTAssertNotNil(MetadataCache.canonical(a))
        XCTAssertEqual(MetadataCache.canonical(a), MetadataCache.canonical(b))

        b.venue = "Fillmore"
        XCTAssertNotEqual(MetadataCache.canonical(a), MetadataCache.canonical(b))
    }

    func testMetadataCacheSaveLoadRoundTrip() {
        let cache = MetadataCache(directoryName: "MetadataCacheTests-\(UUID().uuidString)")
        let payload = Data("hello".utf8)
        cache.save(key: "https://example.org/some?query=1", data: payload)

        let exp = expectation(description: "load")
        cache.load(key: "https://example.org/some?query=1") { data, savedAt in
            XCTAssertEqual(data, payload)
            XCTAssertNotNil(savedAt)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }

    func testMetadataCacheMissReturnsNil() {
        let cache = MetadataCache(directoryName: "MetadataCacheTests-\(UUID().uuidString)")
        let exp = expectation(description: "miss")
        cache.load(key: "never-saved") { data, savedAt in
            XCTAssertNil(data)
            XCTAssertNil(savedAt)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }

    // MARK: - AudioPlayerArchive.seekTime

    func testSeekTimeRejectsNaNAndInfiniteDurations() {
        // AVPlayerItem.duration is NaN/indefinite while loading or after a
        // failure; converting it to Int64 crashes without the guard.
        XCTAssertNil(AudioPlayerArchive.seekTime(fraction: 0.5, totalSeconds: Double.nan))
        XCTAssertNil(AudioPlayerArchive.seekTime(fraction: 0.5, totalSeconds: Double.infinity))
        XCTAssertNil(AudioPlayerArchive.seekTime(fraction: 0.5, totalSeconds: 0))
        XCTAssertNil(AudioPlayerArchive.seekTime(fraction: 0.5, totalSeconds: -10))
    }

    func testSeekTimeComputesAndClamps() {
        XCTAssertEqual(AudioPlayerArchive.seekTime(fraction: 0.5, totalSeconds: 100)?.seconds, 50)
        XCTAssertEqual(AudioPlayerArchive.seekTime(fraction: 0, totalSeconds: 100)?.seconds, 0)
        XCTAssertEqual(AudioPlayerArchive.seekTime(fraction: 1.5, totalSeconds: 100)?.seconds, 100)
        XCTAssertEqual(AudioPlayerArchive.seekTime(fraction: -0.5, totalSeconds: 100)?.seconds, 0)
    }

    // MARK: - CollectionConfig

    func testCollectionConfigGetCollection() {
        XCTAssertEqual(CollectionConfig.getCollection(for: "Grateful Dead"), "GratefulDead")
        XCTAssertEqual(CollectionConfig.getCollection(for: "Phish"), "Phish")
        XCTAssertEqual(CollectionConfig.getCollection(for: "Billy Strings"), "BillyStrings")
        XCTAssertNil(CollectionConfig.getCollection(for: "Nonexistent Band"))
    }

    func testCollectionConfigGetDisplayName() {
        XCTAssertEqual(CollectionConfig.getDisplayName(for: "GratefulDead"), "Grateful Dead")
        XCTAssertEqual(CollectionConfig.getDisplayName(for: "Phish"), "Phish")
        XCTAssertEqual(CollectionConfig.getDisplayName(for: "GooseBand"), "Goose")
        XCTAssertNil(CollectionConfig.getDisplayName(for: "NotACollection"))
    }

    func testCollectionConfigRoundTrip() {
        // Every display name should round-trip through getCollection -> getDisplayName
        for name in CollectionConfig.collectionsText {
            let id = CollectionConfig.getCollection(for: name)
            XCTAssertNotNil(id, "No collection ID for \(name)")
            if let id = id {
                let back = CollectionConfig.getDisplayName(for: id)
                XCTAssertEqual(back, name, "Round-trip failed for \(name)")
            }
        }
    }

    func testCollectionConfigArraysAligned() {
        // collectionsText and collections arrays must be the same length
        XCTAssertEqual(CollectionConfig.collectionsText.count, CollectionConfig.collections.count)
    }

    func testCreatorBasedCollections() {
        XCTAssertTrue(CollectionConfig.isCreatorBased(collection: "Phish"))
        XCTAssertTrue(CollectionConfig.isCreatorBased(collection: "Jerry Garcia"))
        XCTAssertFalse(CollectionConfig.isCreatorBased(collection: "GratefulDead"))
        XCTAssertFalse(CollectionConfig.isCreatorBased(collection: "BillyStrings"))
    }

    func testSBDCapableCollections() {
        XCTAssertTrue(CollectionConfig.supportsSBDFilter(collection: "GratefulDead"))
        XCTAssertTrue(CollectionConfig.supportsSBDFilter(collection: "Furthur"))
        XCTAssertTrue(CollectionConfig.supportsSBDFilter(collection: "TheOtherOnes"))
        XCTAssertFalse(CollectionConfig.supportsSBDFilter(collection: "Phish"))
        XCTAssertFalse(CollectionConfig.supportsSBDFilter(collection: "BillyStrings"))
        XCTAssertFalse(CollectionConfig.supportsSBDFilter(collection: "taperssection"))
    }

    // MARK: - YearListViewModel year ranges

    func testCuratedYearRangeBeatsStoredInference() {
        // A stored years_<id> range (inferred at add time, possibly skewed by
        // phrase-matched strays) must not override a curated band's range.
        let defaults = UserDefaults.standard
        let key = "years_Jerry Garcia"
        let saved = defaults.array(forKey: key)
        defaults.set([1963, 2026], forKey: key)
        defer {
            if let saved { defaults.set(saved, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }

        let vm = YearListViewModel(collection: "Jerry Garcia")
        XCTAssertEqual(vm.years.first, 1963)
        XCTAssertEqual(vm.years.last, 1995)
    }

    func testStoredYearRangeUsedForUnknownBands() {
        let defaults = UserDefaults.standard
        let key = "years_SomeTestBand"
        defaults.set([2001, 2003], forKey: key)
        defer { defaults.removeObject(forKey: key) }

        let vm = YearListViewModel(collection: "SomeTestBand")
        XCTAssertEqual(vm.years, [2001, 2002, 2003])
    }

    // MARK: - ShowMetadata

    func testShowMetadataMonth() {
        var meta = ShowMetadata(identifier: "test")
        meta.date = "1977-05-08T00:00:00Z"
        XCTAssertEqual(meta.month, "1977-05")

        meta.date = "1972-11-18"
        XCTAssertEqual(meta.month, "1972-11")
    }

    func testShowMetadataMonthNilDate() {
        let meta = ShowMetadata(identifier: "test")
        XCTAssertNil(meta.month)
    }

    func testShowMetadataMonthShortDate() {
        var meta = ShowMetadata(identifier: "test")
        meta.date = "1977"
        XCTAssertNil(meta.month) // date.count < 7
    }

    func testShowMetadataDecodingStringDescription() throws {
        let json = """
        {"identifier":"test-show","description":"A great show"}
        """.data(using: .utf8)!
        let meta = try JSONDecoder().decode(ShowMetadata.self, from: json)
        XCTAssertEqual(meta.identifier, "test-show")
        XCTAssertEqual(meta.description, "A great show")
    }

    func testShowMetadataDecodingArrayDescription() throws {
        let json = """
        {"identifier":"test-show","description":["Line 1","Line 2"]}
        """.data(using: .utf8)!
        let meta = try JSONDecoder().decode(ShowMetadata.self, from: json)
        XCTAssertEqual(meta.description, "Line 1\nLine 2")
    }

    func testShowMetadataDecodingStringCollection() throws {
        let json = """
        {"identifier":"test","collection":"GratefulDead"}
        """.data(using: .utf8)!
        let meta = try JSONDecoder().decode(ShowMetadata.self, from: json)
        XCTAssertEqual(meta.collection, ["GratefulDead"])
    }

    func testShowMetadataDecodingArrayCollection() throws {
        let json = """
        {"identifier":"test","collection":["GratefulDead","etree"]}
        """.data(using: .utf8)!
        let meta = try JSONDecoder().decode(ShowMetadata.self, from: json)
        XCTAssertEqual(meta.collection, ["GratefulDead", "etree"])
    }

    func testShowMetadataDecodingStringSource() throws {
        let json = """
        {"identifier":"test","source":"SBD > DAT"}
        """.data(using: .utf8)!
        let meta = try JSONDecoder().decode(ShowMetadata.self, from: json)
        XCTAssertEqual(meta.source, ["SBD > DAT"])
    }

    func testShowMetadataDecodingArraySource() throws {
        let json = """
        {"identifier":"test","source":["SBD","AUD"]}
        """.data(using: .utf8)!
        let meta = try JSONDecoder().decode(ShowMetadata.self, from: json)
        XCTAssertEqual(meta.source, ["SBD", "AUD"])
    }

    func testShowMetadataDecodingArrayCreator() throws {
        // The real 1991 poison pill: one item with an array creator failed the
        // decode of the entire year's response.
        let json = """
        {"identifier": "1991.11.12-jgb-philly", "creator": ["Jerry Garcia Band", "Playboy", "WAGA", "Love & War"]}
        """
        let md = try JSONDecoder().decode(ShowMetadata.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(md.creator, "Jerry Garcia Band")
    }

    func testShowMetadataDecodingArrayCreatorDoesNotPoisonList() throws {
        let json = """
        {"items": [
            {"identifier": "a", "creator": "Jerry Garcia"},
            {"identifier": "b", "creator": ["Jerry Garcia Band", "WAGA"]},
            {"identifier": "c", "creator": "Jerry Garcia"}
        ]}
        """
        let list = try JSONDecoder().decode(ShowMetadatas.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(list.items?.count, 3)
        XCTAssertEqual(list.items?[1].creator, "Jerry Garcia Band")
    }

    func testShowMetadataDecodingNumericYear() throws {
        let json = """
        {"identifier": "x", "year": 1991}
        """
        let md = try JSONDecoder().decode(ShowMetadata.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(md.year, "1991")
    }

    func testShowMetadataDecodingRatings() throws {
        let json = """
        {"identifier":"test","avg_rating":4.75,"num_reviews":42}
        """.data(using: .utf8)!
        let meta = try JSONDecoder().decode(ShowMetadata.self, from: json)
        XCTAssertEqual(meta.avg_rating!, 4.75, accuracy: 0.01)
        XCTAssertEqual(meta.num_reviews, 42)
    }

    func testShowMetadataModelCodable() throws {
        let json = """
        {"metadata":{"identifier":"gd1977-05-08"},"files_count":25}
        """.data(using: .utf8)!
        let model = try JSONDecoder().decode(ShowMetadataModel.self, from: json)
        XCTAssertEqual(model.metadata?.identifier, "gd1977-05-08")
        XCTAssertEqual(model.files_count, 25)
    }

    // MARK: - PlaybackState

    func testPlaybackStateShowType() {
        let model = ShowMetadataModel()
        let archive = PlaybackState(showMetadataModel: model, trackIndex: 0, playbackPosition: 0, isStreaming: false, savedAt: Date(), showTypeRaw: "archive")
        XCTAssertEqual(archive.showType, .archive)

        let phish = PlaybackState(showMetadataModel: model, trackIndex: 0, playbackPosition: 0, isStreaming: true, savedAt: Date(), showTypeRaw: "phishIn")
        XCTAssertEqual(phish.showType, .phishIn)

        let downloaded = PlaybackState(showMetadataModel: model, trackIndex: 0, playbackPosition: 0, isStreaming: false, savedAt: Date(), showTypeRaw: "downloaded")
        XCTAssertEqual(downloaded.showType, .downloaded)

        let unknown = PlaybackState(showMetadataModel: model, trackIndex: 0, playbackPosition: 0, isStreaming: false, savedAt: Date(), showTypeRaw: "something")
        XCTAssertEqual(unknown.showType, .archive) // defaults to archive

        let nilType = PlaybackState(showMetadataModel: model, trackIndex: 0, playbackPosition: 0, isStreaming: false, savedAt: Date(), showTypeRaw: nil)
        XCTAssertEqual(nilType.showType, .archive)
    }

    func testPlaybackStateIsStale() {
        let model = ShowMetadataModel()

        let fresh = PlaybackState(showMetadataModel: model, trackIndex: 0, playbackPosition: 0, isStreaming: false, savedAt: Date(), showTypeRaw: nil)
        XCTAssertFalse(fresh.isStale)

        let eightDaysAgo = Date().addingTimeInterval(-8 * 24 * 60 * 60)
        let stale = PlaybackState(showMetadataModel: model, trackIndex: 0, playbackPosition: 0, isStreaming: false, savedAt: eightDaysAgo, showTypeRaw: nil)
        XCTAssertTrue(stale.isStale)

        let sixDaysAgo = Date().addingTimeInterval(-6 * 24 * 60 * 60)
        let notStale = PlaybackState(showMetadataModel: model, trackIndex: 0, playbackPosition: 0, isStreaming: false, savedAt: sixDaysAgo, showTypeRaw: nil)
        XCTAssertFalse(notStale.isStale)
    }

    func testPlaybackStateCodable() throws {
        let model = ShowMetadataModel(metadata: ShowMetadata(identifier: "test-show"))
        let state = PlaybackState(showMetadataModel: model, trackIndex: 3, playbackPosition: 125.5, isStreaming: true, savedAt: Date(), showTypeRaw: "phishIn")

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(PlaybackState.self, from: data)

        XCTAssertEqual(decoded.trackIndex, 3)
        XCTAssertEqual(decoded.playbackPosition, 125.5, accuracy: 0.01)
        XCTAssertTrue(decoded.isStreaming)
        XCTAssertEqual(decoded.showTypeRaw, "phishIn")
        XCTAssertEqual(decoded.showType, .phishIn)
        XCTAssertEqual(decoded.showMetadataModel.metadata?.identifier, "test-show")
    }

    // MARK: - SongDetailsModel

    func testSongDetailsFromMetadata() {
        let songDetails = SongDetailsModel()
        let track = ShowMP3(identifier: "gd1977-05-08", name: "track01.mp3", title: "Scarlet Begonias", track: "1")
        var model = ShowMetadataModel()
        model.mp3Array = [track]
        model.metadata = ShowMetadata(identifier: "gd1977-05-08")
        model.metadata?.date = "1977-05-08"
        model.metadata?.venue = "Barton Hall"

        songDetails.songDetailsFromMetadata(row: 0, showModel: model)

        XCTAssertEqual(songDetails.name, "Scarlet Begonias")
        XCTAssertEqual(songDetails.date, "1977-05-08")
        XCTAssertEqual(songDetails.venue, "Barton Hall")
        XCTAssertEqual(songDetails.track, 1)
    }

    func testSongDetailsFromMetadataFallsBackToName() {
        let songDetails = SongDetailsModel()
        let track = ShowMP3(identifier: "test", name: "gd77-05-08d1t01.mp3", title: nil, track: "1")
        var model = ShowMetadataModel()
        model.mp3Array = [track]
        model.metadata = ShowMetadata(identifier: "test")

        songDetails.songDetailsFromMetadata(row: 0, showModel: model)

        XCTAssertEqual(songDetails.name, "gd77-05-08d1t01.mp3")
    }

    func testSongDetailsFromMetadataNilInputs() {
        let songDetails = SongDetailsModel()
        songDetails.songDetailsFromMetadata(row: nil, showModel: nil)
        XCTAssertNil(songDetails.name)
        XCTAssertNil(songDetails.date)
    }

    func testSongDetailsFromMetadataEmptyArray() {
        let songDetails = SongDetailsModel()
        var model = ShowMetadataModel()
        model.mp3Array = []
        songDetails.songDetailsFromMetadata(row: 0, showModel: model)
        XCTAssertNil(songDetails.name) // count is 0, guard fails
    }

    // MARK: - Utils

    func testTimerStringSeconds() {
        let utils = Utils()
        XCTAssertEqual(utils.getTimerStringSeconds(seconds: 65.0), "05")
        XCTAssertEqual(utils.getTimerStringSeconds(seconds: 0.0), "00")
        XCTAssertEqual(utils.getTimerStringSeconds(seconds: 59.9), "59")
        XCTAssertEqual(utils.getTimerStringSeconds(seconds: 120.0), "00")
        XCTAssertEqual(utils.getTimerStringSeconds(seconds: nil), "00")
        XCTAssertEqual(utils.getTimerStringSeconds(seconds: Double.nan), "00")
        XCTAssertEqual(utils.getTimerStringSeconds(seconds: Double.infinity), "00")
    }

    func testTimerStringMinutes() {
        let utils = Utils()
        XCTAssertEqual(utils.getTimerStringMinutes(seconds: 65.0), "01")
        XCTAssertEqual(utils.getTimerStringMinutes(seconds: 0.0), "00")
        XCTAssertEqual(utils.getTimerStringMinutes(seconds: 600.0), "10")
        XCTAssertEqual(utils.getTimerStringMinutes(seconds: nil), "00")
        XCTAssertEqual(utils.getTimerStringMinutes(seconds: Double.nan), "00")
    }

    func testTimerStringCombined() {
        let utils = Utils()
        XCTAssertEqual(utils.getTimerString(seconds: 0.0), "00:00")
        XCTAssertEqual(utils.getTimerString(seconds: 65.0), "01:05")
        XCTAssertEqual(utils.getTimerString(seconds: 3661.0), "61:01")
    }

    func testConvertKelvinToFahrenheit() {
        let utils = Utils()
        // Boiling point of water: 373.15K = 212F
        let boiling = utils.convertKtoF(kelvin: 373.15)
        XCTAssertNotNil(boiling)
        XCTAssertEqual(boiling!, 212.0, accuracy: 0.1)

        // Freezing point: 273.15K = 32F
        let freezing = utils.convertKtoF(kelvin: 273.15)
        XCTAssertNotNil(freezing)
        XCTAssertEqual(freezing!, 32.0, accuracy: 0.1)

        XCTAssertNil(utils.convertKtoF(kelvin: nil))
    }

    func testWindDirName() {
        XCTAssertEqual(Utils.windDirName(num: 0), "N")
        XCTAssertEqual(Utils.windDirName(num: 44), "N")
        XCTAssertEqual(Utils.windDirName(num: 45), "E")
        XCTAssertEqual(Utils.windDirName(num: 90), "E")
        XCTAssertEqual(Utils.windDirName(num: 135), "S")
        XCTAssertEqual(Utils.windDirName(num: 180), "S")
        XCTAssertEqual(Utils.windDirName(num: 225), "W")
        XCTAssertEqual(Utils.windDirName(num: 270), "W")
        XCTAssertEqual(Utils.windDirName(num: 305), "N")
        XCTAssertEqual(Utils.windDirName(num: 360), "N")
        XCTAssertNil(Utils.windDirName(num: nil))
        XCTAssertNil(Utils.windDirName(num: -1))
        XCTAssertNil(Utils.windDirName(num: 361))
    }

    func testGetDateFromDateTimeString() {
        let utils = Utils()
        let result = utils.getDateFromDateTimeString(datetime: "2024-03-15T14:30:00+0000")
        XCTAssertEqual(result, "03-15-2024")
    }

    func testGetDateFromDateTimeStringNil() {
        let utils = Utils()
        XCTAssertEqual(utils.getDateFromDateTimeString(datetime: nil), "")
    }

    func testGetDateFromDateString() {
        let utils = Utils()
        let date = utils.getDateFromDateString(datetime: "1977-05-08")
        XCTAssertNotNil(date)

        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date!)
        XCTAssertEqual(components.year, 1977)
        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day, 8)
    }

    func testGetDateFromDateStringNil() {
        let utils = Utils()
        XCTAssertNil(utils.getDateFromDateString(datetime: nil))
    }

    func testTrackStreamingURL() {
        let utils = Utils()
        let url = utils.trackStreamingURLfromNameAndIdentifier(identifier: "gd1977-05-08", name: "track01.mp3")
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("archive.org/download/gd1977-05-08/track01.mp3"))
    }

    func testTrackStreamingURLNilInputs() {
        let utils = Utils()
        XCTAssertNil(utils.trackStreamingURLfromNameAndIdentifier(identifier: nil, name: "track.mp3"))
        XCTAssertNil(utils.trackStreamingURLfromNameAndIdentifier(identifier: "id", name: nil))
        XCTAssertNil(utils.trackStreamingURLfromNameAndIdentifier(identifier: nil, name: nil))
    }

    func testTrackNameFromAnyURL() {
        let utils = Utils()
        let url = URL(string: "https://archive.org/download/gd1977-05-08/track01.mp3")
        XCTAssertEqual(utils.trackNameFromAnyURL(url: url), "track01.mp3")
        XCTAssertNil(utils.trackNameFromAnyURL(url: nil))
    }

    func testURLFromIdentifier() {
        let utils = Utils()
        let url = utils.urlFromIdentifier(identifier: "gd1977-05-08")
        XCTAssertEqual(url.absoluteString, "chateauarchive://gd1977-05-08")
    }

    func testURLFromIdentifierNil() {
        let utils = Utils()
        let url = utils.urlFromIdentifier(identifier: nil)
        // Falls back to default
        XCTAssertTrue(url.absoluteString.hasPrefix("chateauarchive://"))
    }

    func testTrackURLfromNameRejectsTraversal() {
        let utils = Utils()
        let url = utils.trackURLfromName(name: "../../../etc/passwd")
        XCTAssertNil(url)
    }

    func testTrackURLfromNameNil() {
        let utils = Utils()
        XCTAssertNil(utils.trackURLfromName(name: nil))
    }

    func testTrackURLfromNameEmpty() {
        let utils = Utils()
        XCTAssertNil(utils.trackURLfromName(name: ""))
    }

    func testTrackURLfromNameValid() {
        let utils = Utils()
        let url = utils.trackURLfromName(name: "gd1977-05-08/track01.mp3")
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.path.hasSuffix("gd1977-05-08/track01.mp3"))
    }

    // MARK: - MonthListViewModel month skeleton

    func testMonthRowsSkeletonRendersAllTwelveMonthsWithoutData() {
        // The month list must be tappable before any network data arrives.
        let vm = MonthListViewModel(year: 1977, collection: "GratefulDead")
        vm.rebuildMonthRows()
        XCTAssertEqual(vm.monthRows.count, 12)
        XCTAssertTrue(vm.monthRows.allSatisfy { $0.count == 0 })
        XCTAssertEqual(vm.monthRows.first?.name, "Jan")
        XCTAssertEqual(vm.monthRows.last?.name, "Dec")
    }

    // MARK: - Joe's Picks (MonthListViewModel.applyJoesPicks)

    func testJoesPicksBasicFiltering() {
        // Shows below threshold are excluded
        let shows = [
            makeShow(date: "1977-05-08", rating: 4.6, reviews: 15),
            makeShow(date: "1977-05-09", rating: 4.4, reviews: 20), // below 4.5 threshold
            makeShow(date: "1977-05-10", rating: 4.8, reviews: 1),  // below 2 reviews threshold
        ]
        let picks = MonthListViewModel.applyJoesPicks(shows)
        XCTAssertEqual(picks.count, 1)
        XCTAssertEqual(picks.first?.date, "1977-05-08")
    }

    func testJoesPicksOnePerDate() {
        // Multiple shows on same date: pick the highest rated
        let shows = [
            makeShow(date: "1977-05-08", rating: 4.6, reviews: 15, identifier: "show-a"),
            makeShow(date: "1977-05-08", rating: 4.9, reviews: 12, identifier: "show-b"),
            makeShow(date: "1977-05-08", rating: 4.7, reviews: 20, identifier: "show-c"),
        ]
        let picks = MonthListViewModel.applyJoesPicks(shows)
        XCTAssertEqual(picks.count, 1)
        XCTAssertEqual(picks.first?.identifier, "show-b")
    }

    func testJoesPicksPrefersTenPlusReviews() {
        // Show with fewer reviews but higher rating should lose to 10+ review pool
        let shows = [
            makeShow(date: "1977-05-08", rating: 5.0, reviews: 3, identifier: "few-reviews"),
            makeShow(date: "1977-05-08", rating: 4.6, reviews: 15, identifier: "many-reviews"),
        ]
        let picks = MonthListViewModel.applyJoesPicks(shows)
        XCTAssertEqual(picks.count, 1)
        XCTAssertEqual(picks.first?.identifier, "many-reviews")
    }

    func testJoesPicksFallsBackWhenNoTenPlus() {
        // When no shows have 10+ reviews, fall back to all qualifying shows
        let shows = [
            makeShow(date: "1977-05-08", rating: 4.8, reviews: 5, identifier: "a"),
            makeShow(date: "1977-05-08", rating: 4.6, reviews: 3, identifier: "b"),
        ]
        let picks = MonthListViewModel.applyJoesPicks(shows)
        XCTAssertEqual(picks.count, 1)
        XCTAssertEqual(picks.first?.identifier, "a")
    }

    func testJoesPicksTiebreaker() {
        // Same rating: should pick the one with more reviews
        let shows = [
            makeShow(date: "1977-05-08", rating: 4.8, reviews: 15, identifier: "fewer"),
            makeShow(date: "1977-05-08", rating: 4.8, reviews: 30, identifier: "more"),
        ]
        let picks = MonthListViewModel.applyJoesPicks(shows)
        XCTAssertEqual(picks.count, 1)
        XCTAssertEqual(picks.first?.identifier, "more")
    }

    func testJoesPicksSortedByDate() {
        let shows = [
            makeShow(date: "1977-05-10", rating: 4.8, reviews: 15),
            makeShow(date: "1977-05-01", rating: 4.9, reviews: 12),
            makeShow(date: "1977-05-08", rating: 4.6, reviews: 20),
        ]
        let picks = MonthListViewModel.applyJoesPicks(shows)
        XCTAssertEqual(picks.count, 3)
        XCTAssertEqual(picks[0].date, "1977-05-01")
        XCTAssertEqual(picks[1].date, "1977-05-08")
        XCTAssertEqual(picks[2].date, "1977-05-10")
    }

    func testJoesPicksEmpty() {
        let picks = MonthListViewModel.applyJoesPicks([])
        XCTAssertTrue(picks.isEmpty)
    }

    func testJoesPicksNilRatings() {
        let shows = [
            makeShow(date: "1977-05-08", rating: nil, reviews: nil),
        ]
        let picks = MonthListViewModel.applyJoesPicks(shows)
        XCTAssertTrue(picks.isEmpty)
    }

    // MARK: - ShowDetailViewModel.buildMP3Array

    private func decodeShowFiles(_ json: String) throws -> [ShowFile] {
        try JSONDecoder().decode([ShowFile].self, from: json.data(using: .utf8)!)
    }

    func testBuildMP3ArrayInheritsTitlesFromUntaggedDerivatives() throws {
        // Mirrors goose2026-08-18: VBR MP3 derivatives carry no title/track;
        // the tags live only on the 24bit Flac originals.
        let files = try decodeShowFiles("""
        [
            {"name": "goose2026-08-18s1t01.flac", "format": "24bit Flac", "title": "Intro", "track": "01"},
            {"name": "goose2026-08-18s1t02.flac", "format": "24bit Flac", "title": "Yeti", "track": "02"},
            {"name": "goose2026-08-18s1t01.mp3", "format": "VBR MP3"},
            {"name": "goose2026-08-18s1t02.mp3", "format": "VBR MP3"},
            {"name": "goose2026-08-18s1t01.png", "format": "Spectrogram"}
        ]
        """)
        let mp3s = ShowDetailViewModel.buildMP3Array(from: files, identifier: "goose2026-08-18")
        XCTAssertEqual(mp3s.count, 2)
        XCTAssertEqual(mp3s[0].title, "Intro")
        XCTAssertEqual(mp3s[0].track, "01")
        XCTAssertEqual(mp3s[1].title, "Yeti")
        XCTAssertEqual(mp3s[1].track, "02")
        XCTAssertEqual(mp3s[0].identifier, "goose2026-08-18")
    }

    func testBuildMP3ArrayKeepsOwnTitleWhenTagged() throws {
        let files = try decodeShowFiles("""
        [
            {"name": "gd77-05-08d1t01.flac", "format": "Flac", "title": "Flac Title"},
            {"name": "gd77-05-08d1t01.mp3", "format": "VBR MP3", "title": "MP3 Title", "track": "01"}
        ]
        """)
        let mp3s = ShowDetailViewModel.buildMP3Array(from: files, identifier: "gd77-05-08")
        XCTAssertEqual(mp3s.count, 1)
        XCTAssertEqual(mp3s[0].title, "MP3 Title")
        XCTAssertEqual(mp3s[0].track, "01")
    }

    func testBuildMP3ArrayLeavesTitleNilWithoutSibling() throws {
        let files = try decodeShowFiles("""
        [
            {"name": "showd1t01.mp3", "format": "VBR MP3"}
        ]
        """)
        let mp3s = ShowDetailViewModel.buildMP3Array(from: files, identifier: "show")
        XCTAssertEqual(mp3s.count, 1)
        XCTAssertNil(mp3s[0].title)
    }

    func testBuildMP3ArraySortsAcrossSets() throws {
        // s2 tracks must follow s1 regardless of file-list order
        let files = try decodeShowFiles("""
        [
            {"name": "goose2026-08-18s2t01.mp3", "format": "VBR MP3"},
            {"name": "goose2026-08-18s1t02.mp3", "format": "VBR MP3"},
            {"name": "goose2026-08-18s1t01.mp3", "format": "VBR MP3"}
        ]
        """)
        let mp3s = ShowDetailViewModel.buildMP3Array(from: files, identifier: "goose2026-08-18")
        XCTAssertEqual(mp3s.map { $0.name }, [
            "goose2026-08-18s1t01.mp3",
            "goose2026-08-18s1t02.mp3",
            "goose2026-08-18s2t01.mp3"
        ])
    }

    // MARK: - Track destination reconciliation

    func testReconcileDestinationsFillsFromDisk() throws {
        // A track whose file exists on disk gets its destination filled in
        // (the repair flow downloads files without updating the saved model)
        let utils = Utils()
        let name = "reconcile-test-\(UUID().uuidString).mp3"
        let url = try XCTUnwrap(utils.trackURLfromName(name: name))
        try Data("ID3fake".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let tracks = [
            ShowMP3(identifier: "x", name: name, title: "On Disk", track: "1", destination: nil),
            ShowMP3(identifier: "x", name: "reconcile-missing-\(UUID().uuidString).mp3",
                    title: "Not On Disk", track: "2", destination: nil)
        ]
        let updated = ShowDetailViewModel.reconcileDestinations(tracks)
        XCTAssertNotNil(updated[0].destination)
        XCTAssertNil(updated[1].destination)
    }

    // MARK: - Title venue parsing & metadata backfill

    func testTitleVenueLocationStandardConvention() {
        var md = ShowMetadata(identifier: "x")
        md.title = "Jerry Garcia live at Keystone, Berkeley, CA on 1974-01-17"
        XCTAssertEqual(md.titleVenueLocation, "Keystone, Berkeley, CA")
    }

    func testTitleVenueLocationVenueContainingOn() {
        var md = ShowMetadata(identifier: "x")
        md.title = "Some Band live at House of Blues on Sunset on 1995-03-04"
        XCTAssertEqual(md.titleVenueLocation, "House of Blues on Sunset")
    }

    func testTitleVenueLocationNoDateFallback() {
        var md = ShowMetadata(identifier: "x")
        md.title = "Some Band Live At The Fillmore"
        XCTAssertEqual(md.titleVenueLocation, "The Fillmore")
    }

    func testTitleVenueLocationNoConvention() {
        var md = ShowMetadata(identifier: "x")
        md.title = "A random album title"
        XCTAssertNil(md.titleVenueLocation)
        md.title = nil
        XCTAssertNil(md.titleVenueLocation)
    }

    func testDisplayCreatorRefinesJerryGarciaBandCodes() {
        var md = ShowMetadata(identifier: "jg85-10-16.078849.jgjk.mtx.tobin.t-flac16")
        md.creator = "Jerry Garcia"
        XCTAssertEqual(md.displayCreator, "Jerry Garcia & John Kahn")

        md = ShowMetadata(identifier: "jg89-09-05.083466.jgb.sbd.patched.tetzeli.sbeok.t-flac16")
        md.creator = "Jerry Garcia"
        XCTAssertEqual(md.displayCreator, "Jerry Garcia Band")

        md = ShowMetadata(identifier: "jg73-11-04.085027.oaitw.sbd.tamarkin.sbeok.t-flac16")
        md.creator = "Jerry Garcia"
        XCTAssertEqual(md.displayCreator, "Old & In the Way")
    }

    func testDisplayCreatorFallsBackToCreator() {
        // No band code in the identifier → the creator field stands
        var md = ShowMetadata(identifier: "gd77-05-08.sbd.hicks.4982.sbeok.shnf")
        md.creator = "Grateful Dead"
        XCTAssertEqual(md.displayCreator, "Grateful Dead")

        md = ShowMetadata(identifier: "phishin-1994-10-31")
        md.creator = "Phish"
        XCTAssertEqual(md.displayCreator, "Phish")
    }

    func testRecordingTypeSniffsIdentifierTokens() {
        var md = ShowMetadata(identifier: "jg85-10-11.030623.jgjk.set1.sbd.jjoops.sbeok.t-flac16")
        XCTAssertEqual(md.recordingType, "SBD")

        md = ShowMetadata(identifier: "jg81-01-23.097205.jgb.aud.latvala.knudsen-df.t-flac16")
        XCTAssertEqual(md.recordingType, "AUD")

        md = ShowMetadata(identifier: "gd77-05-08.mtx.seamons.32106.flac16")
        XCTAssertEqual(md.recordingType, "MTX")

        md = ShowMetadata(identifier: "gd89-08-04.fm.wagner.12345.flac16")
        XCTAssertEqual(md.recordingType, "FM")
    }

    func testRecordingTypeNoFalsePositives() {
        // "sbeok" must not match "sbd"; a plain identifier yields nil
        var md = ShowMetadata(identifier: "gd77-05-08.hicks.4982.sbeok.shnf")
        XCTAssertNil(md.recordingType)

        md = ShowMetadata(identifier: "phishin-1994-10-31")
        XCTAssertNil(md.recordingType)
    }

    func testRecordingTypeFallsBackToSourceField() {
        var md = ShowMetadata(identifier: "gd77-05-08.hicks.4982.sbeok.shnf")
        md.source = ["Soundboard > Master Reel > DAT"]
        XCTAssertEqual(md.recordingType, "SBD")

        md.source = ["Audience: Nakamichi 300s > cassette"]
        XCTAssertEqual(md.recordingType, "AUD")
    }

    func testRecordingTypePrefersMatrixOverComponents() {
        // A matrix identifier can also mention sbd/aud sources
        let md = ShowMetadata(identifier: "gd90-03-29.mtx.sbd.aud.hanno.flac16")
        XCTAssertEqual(md.recordingType, "MTX")
    }

    func testDisplayVenueLinePrefersRealFields() {
        var md = ShowMetadata(identifier: "x")
        md.venue = "Winterland"
        md.coverage = "San Francisco, CA"
        md.title = "X live at Somewhere Else on 1977-01-01"
        XCTAssertEqual(md.displayVenueLine, "Winterland, San Francisco, CA")
    }

    func testDisplayVenueLineFallsBackToTitle() {
        var md = ShowMetadata(identifier: "x")
        md.title = "Jerry Garcia live at Keystone, Berkeley, CA on 1974-01-17"
        XCTAssertEqual(md.displayVenueLine, "Keystone, Berkeley, CA")
    }

    func testBackfillFromTitleAndDescription() {
        var md = ShowMetadata(identifier: "jg74-01-17")
        md.title = "Jerry Garcia live at Keystone, Berkeley, CA on 1974-01-17"
        md.description = "Jerry Garcia and Merl Saunders\nSet II\n\nSource: Soundboard > Master Reel > DAT (48k)\n\n01 tuning"
        var model = ShowMetadataModel()
        model.metadata = md

        ShowDetailViewModel.backfillMissingMetadata(&model)
        XCTAssertEqual(model.metadata?.venue, "Keystone")
        XCTAssertEqual(model.metadata?.coverage, "Berkeley, CA")
        XCTAssertEqual(model.metadata?.source, ["Soundboard > Master Reel > DAT (48k)"])
    }

    func testBackfillFromFileAlbumTag() throws {
        var md = ShowMetadata(identifier: "x")
        md.title = "A random album title"  // unparseable
        var model = ShowMetadataModel()
        model.metadata = md
        model.files = try decodeShowFiles("""
        [
            {"name": "t01.mp3", "format": "VBR MP3", "album": "The Keystone, Berkley, CA 01/17/1974 Set II"}
        ]
        """)

        ShowDetailViewModel.backfillMissingMetadata(&model)
        XCTAssertEqual(model.metadata?.venue, "The Keystone, Berkley, CA 01/17/1974 Set II")
    }

    func testSourceLineageFromUnlabeledGearChain() {
        // The real jg91-11-19 description: lineage present but no "Source:" label
        let desc = """
        Jerry Garcia Band
        11/19/1991

        Providence Civic Center
        Providence RI

        master recording by Captain Joe LeClair
        DAT transfer and shn mastering by Tony Masiello

        Schoeps CMC54 (hand held 4th row)--> Peter Grace power supply 12V--> DAT--> ZA2 (48/44.1)--> CEP--> SHN

        Set 1

        1. How Sweet It Is
        """
        XCTAssertEqual(ShowDetailViewModel.sourceLineage(fromDescription: desc),
                       "Schoeps CMC54 (hand held 4th row)--> Peter Grace power supply 12V--> DAT--> ZA2 (48/44.1)--> CEP--> SHN")
    }

    func testSourceLineagePrefersLabeledSourceLine() {
        let desc = "Jerry Garcia Band\nSource:  DSBD>D>CM>CD\n\ndisc 1:\nHow Sweet It Is"
        XCTAssertEqual(ShowDetailViewModel.sourceLineage(fromDescription: desc), "DSBD>D>CM>CD")
    }

    func testSourceLineageIgnoresSetlistSegues() {
        // Arrow-heavy segue lines must not be mistaken for gear chains
        let desc = "Set 2:\nHelp on the Way > Slipknot! > Franklin's Tower\nEyes of the World > Drums > Space"
        XCTAssertNil(ShowDetailViewModel.sourceLineage(fromDescription: desc))
    }

    func testRecordingTypeFOBAndDSBD() {
        var md = ShowMetadata(identifier: "jg91-11-19.011858.jgb.fob-schoepsCMC54.leclair.masiello.sbeok.t-flac16")
        XCTAssertEqual(md.recordingType, "AUD")

        md = ShowMetadata(identifier: "gd90-03-29.dsbd.miller.12345.flac16")
        XCTAssertEqual(md.recordingType, "SBD")
    }


    func testBackfillRealJG91FullDescription() throws {
        // The complete real description of jg91-11-19 (base64 to preserve it
        // byte-for-byte), whose lineage line is unlabeled taper freeform.
        let descB64 = "VGhpcyBpcyBhIGZsYWMgZW5jb2RlZCAmIHRhZ2dlZCB2ZXJzaW9uIG9mIHNobmlkOiAxMTg1OAoKSmVycnkgR2FyY2lhIEJhbmQKMTEvMTkvMTk5MQoKUHJvdmlkZW5jZSBDaXZpYyBDZW50ZXIKUHJvdmlkZW5jZSBSSQoKbWFzdGVyIHJlY29yZGluZyBieSBDYXB0YWluIEpvZSBMZUNsYWlyCkRBVCB0cmFuc2ZlciBhbmQgc2huIG1hc3RlcmluZyBieSBUb255IE1hc2llbGxvCgpTY2hvZXBzIENNQzU0IChoYW5kIGhlbGQgNHRoIHJvdyktLT4gUGV0ZXIgR3JhY2UgcG93ZXIgc3VwcGx5IDEyVi0tPiBEQVQtLT4gWkEyICg0OC80NC4xKS0tPiBDRVAtLT4gU0hOCgpTZXQgMQoKMS4gSG93IFN3ZWV0IEl0IElzIAoyLiBIZSBBaW4ndCBHaXZlIFlvdSBOb25lIAozLiBUaGF0J3MgV2hhdCBMb3ZlIFdpbGwgTWFrZSBZb3UgRG8gCjQuIEFuZCBJdCBTdG9uZWQgTWUgCjUuIERlYXIgUHJ1ZGVuY2UgCjYuIFJ1biBGb3IgVGhlIFJvc2VzIAo3LiBTZW5vciAKOC4gRGVhbAoKU2V0IDIKCjEuIExheSBEb3duIFNhbGx5IAoyLiBTaGluaW5nIFN0YXIgCjMuIFdhaXRpbmcgRm9yIEEgTWlyYWNsZSAKNC4gQWluJ3QgTm8gQnJlYWQgSW4gVGhlIEJyZWFkYm94IAo1LiBUb3JlIFVwIE92ZXIgWW91IAo2LiBEb24ndCBMZXQgR28gCjcuIFRoYXQgTHVja3kgT2xkIFN1biAKOC4gTWlkbmlnaHQgTW9vbmxpZ2h0CgpTZXQgMiBjYW4gcHJvYmFibHkgYmUgYnVybmVkIG9uIGFuIDgwIG1pbiBjZCAoODA6MzYpLiBPdGhlcndpc2UgdGhlIHNob3cgd2lsbCByZXF1aXJlIDMgY2RzLiBJZiB0aGVyZSBpcyBhIGJldHRlciBhdWQgcmVjb3JkaW5nIG1hZGUgaW4gYSBob2NrZXkgcmluaywgSSd2ZSB5ZXQgdG8gaGVhciBpdCEgVGhpcyByZWNvcmRpbmcgaXMgc28gd2FybSBpdCBjYW4gbWV0IGNob2NvbGF0ZSEKCkNvbW1lbnQ6Ck5vbmUgb2YgdGhlIHRyYWNrcyB3ZXJlIGN1dCBvbiBzZWN0b3IgYm91bmRyaWVzIHNvIHNobnRvb2wgd2FzIHVzZWQgdG8gY29ycmVjdCB0aGlzLiBDRHdhdiB3YXMgdXNlZCB0byByZW1vdmUgYSAwLjA5IHNlY29uZCBnbGl0Y2ggYXQgdGhlIGVuZCBvZiBkMXQwMy4gCldoaWxlIEkgd2FzIGF0IGl0IEkgcmVtb3ZlZCAzNiBzZWNvbmRzIG9mIGNyb3dkIG5vaXNlIGZyb20gdGhlIGJlZ2lubmluZyBhbmQgZW5kIG9mIGQyIHNvIHRoZSBzaG93IHdpbGwgZml0IG9uIDIgZGlzY3Mgd2l0aG91dCB0aGUgbmVlZCB0byBvdmVyYnVybi4KCkNvcnJlY3RlZCAwOS0wNi0yMDAyIGJ5IGdseWRlQG1hc29uc2NoaWxkcmVuLm9yZwoKRmxhYyBlbmNvZGluZyBub3RlczoKQWxsIHByb2Nlc3Npbmcgd2l0aCBUcmFkZXIncyBMaXR0bGUgSGVscGVyClNobiAtIHN0NSBnZW5lcmF0ZWQKU2huID4gRmxhYyAoIGxldmVsIDggKQpGbGFjIC0gc3Q1IGdlbmVyYXRlZCBhbmQgbWF0Y2hlZCB0byBTaG4gc3Q1CgpUYWdnaW5nIG5vdGVzOgpTaG93IGluZm9ybWF0aW9uIGlzIGVtYmVkZGVkIHdpdGhpbiB0aGUgaGVhZGVyCm9mIGVhY2ggZmxhYyBmaWxlLiBJdCB3aWxsIGRpc3BsYXkgb24gYW55IHBsYXllciAKY2FwYWJsZSBvZiBkaXJlY3RseSBwbGF5aW5nIGZsYWMgZmlsZXMuIApJZiBjb252ZXJ0ZWQgdG8gd2F2IGR1cmluZyBwcm9jZXNzaW5nLCBhbGwgdGFncyAKd2lsbCBiZSBzdHJpcHBlZCwgaG93ZXZlciBhdWRpbyBkYXRhIHdpbGwgcmVtYWluIAp1bmFmZmVjdGVkLiBJZiB5b3UgbXVzdCB0cmFuc2NvZGUgdG8gYSBsb3NzeSBmb3JtYXQsIApkbyBzbyBkaXJlY3RseSBGbGFjID4gTG9zc3kuClVzZSBzdDUgdG8gdmFsaWRhdGUgYXVkaW8gaW50ZWdyaXR5LgpNZDUgdmFsdWVzIHdpbGwgY2hhbmdlIGlmIHRhZ2dpbmcgaXMgYWx0ZXJlZC4KQSBNaWxscyAyLzE2LzE1Cgo7IHNobnRvb2wgbWQ1IGZpbmdlcnByaW50IGZpbGUKMGQwM2ZhNTAxODZkNGY3MTU5MzVlOTY4MDQxODBhNzYgIFtzaG50b29sXSAgamdiMTk5MS0xMS0xOWQxdDAxLnNobgo0NGNkY2U3NDNjYmQ1MzQ4OTIwZTVkYmViNWJmYTRiMiAgW3NobnRvb2xdICBqZ2IxOTkxLTExLTE5ZDF0MDIuc2huCjAwZWNjYTU2OGYzNTY5YmRlMTMzMWYzNDAzMGIxZWYwICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMXQwMy5zaG4KNDFmYjUwYmU5YTIyNDBlMTE0ZGY1OWMyZDIxYmMxZGEgIFtzaG50b29sXSAgamdiMTk5MS0xMS0xOWQxdDA0LnNobgphOWQ4MjA1MjAwOTFjMzMxYzgzMjg1OWZhOTFjY2Q2NiAgW3NobnRvb2xdICBqZ2IxOTkxLTExLTE5ZDF0MDUuc2huCjdmZmU3NTUyOTg2ZjhkYjY1NGViOWM1ZjZjMTQ3M2NlICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMXQwNi5zaG4KYmU3M2U3NzBmMDFhOTk2NjU0ZDM5MDIzNDMwNzE5MzMgIFtzaG50b29sXSAgamdiMTk5MS0xMS0xOWQxdDA3LnNobgpkMGRjODY4YTliZWZhMmYwODQ2OTUxMzY2ZDJiODdlYiAgW3NobnRvb2xdICBqZ2IxOTkxLTExLTE5ZDF0MDguc2huCmY2NmIwZTRmMDk5YzJjZTJmN2Y0MTY5M2ZkNjgyODczICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMnQwMS5zaG4KZjRkNTY0OTI0MmM3NmUwNWVkMWI3NjFhNmVjMTBlMGUgIFtzaG50b29sXSAgamdiMTk5MS0xMS0xOWQydDAyLnNobgo3NGZjYzY5MDVmYjUxMjdiOGEzODVlNmZmZWVlMTk4MCAgW3NobnRvb2xdICBqZ2IxOTkxLTExLTE5ZDJ0MDMuc2huCjNjMmE0ODMzY2M3ODBhNDBkMjViN2I4NjI0OTkxYzc1ICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMnQwNC5zaG4KNTFkYTMzOWFlMTViNGE2ZDY3MmZjZWY1OTM0YWUxZGQgIFtzaG50b29sXSAgamdiMTk5MS0xMS0xOWQydDA1LnNobgo4M2EwYWZmMGFlNTk3Y2I5YTI0ZjJhZDcxODNkZTFjYSAgW3NobnRvb2xdICBqZ2IxOTkxLTExLTE5ZDJ0MDYuc2huCjM5Mjc3MTgyZDkwMGIzMDU4YjJjN2IxZjcyNzgzMTU2ICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMnQwNy5zaG4KMzc1ODY1MDJhMTJhMTIzOTNjMDg0MDA3OTQ3ZGZhZWYgIFtzaG50b29sXSAgamdiMTk5MS0xMS0xOWQydDA4LnNobgoKOyBzaG50b29sIG1kNSBmaW5nZXJwcmludCBmaWxlCjBkMDNmYTUwMTg2ZDRmNzE1OTM1ZTk2ODA0MTgwYTc2ICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMXQwMS5mbGFjCjQ0Y2RjZTc0M2NiZDUzNDg5MjBlNWRiZWI1YmZhNGIyICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMXQwMi5mbGFjCjAwZWNjYTU2OGYzNTY5YmRlMTMzMWYzNDAzMGIxZWYwICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMXQwMy5mbGFjCjQxZmI1MGJlOWEyMjQwZTExNGRmNTljMmQyMWJjMWRhICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMXQwNC5mbGFjCmE5ZDgyMDUyMDA5MWMzMzFjODMyODU5ZmE5MWNjZDY2ICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMXQwNS5mbGFjCjdmZmU3NTUyOTg2ZjhkYjY1NGViOWM1ZjZjMTQ3M2NlICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMXQwNi5mbGFjCmJlNzNlNzcwZjAxYTk5NjY1NGQzOTAyMzQzMDcxOTMzICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMXQwNy5mbGFjCmQwZGM4NjhhOWJlZmEyZjA4NDY5NTEzNjZkMmI4N2ViICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMXQwOC5mbGFjCmY2NmIwZTRmMDk5YzJjZTJmN2Y0MTY5M2ZkNjgyODczICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMnQwMS5mbGFjCmY0ZDU2NDkyNDJjNzZlMDVlZDFiNzYxYTZlYzEwZTBlICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMnQwMi5mbGFjCjc0ZmNjNjkwNWZiNTEyN2I4YTM4NWU2ZmZlZWUxOTgwICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMnQwMy5mbGFjCjNjMmE0ODMzY2M3ODBhNDBkMjViN2I4NjI0OTkxYzc1ICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMnQwNC5mbGFjCjUxZGEzMzlhZTE1YjRhNmQ2NzJmY2VmNTkzNGFlMWRkICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMnQwNS5mbGFjCjgzYTBhZmYwYWU1OTdjYjlhMjRmMmFkNzE4M2RlMWNhICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMnQwNi5mbGFjCjM5Mjc3MTgyZDkwMGIzMDU4YjJjN2IxZjcyNzgzMTU2ICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMnQwNy5mbGFjCjM3NTg2NTAyYTEyYTEyMzkzYzA4NDAwNzk0N2RmYWVmICBbc2hudG9vbF0gIGpnYjE5OTEtMTEtMTlkMnQwOC5mbGFj"
        let desc = String(data: Data(base64Encoded: descB64)!, encoding: .utf8)!

        var md = ShowMetadata(identifier: "jg91-11-19.011858.jgb.fob-schoepsCMC54.leclair.masiello.sbeok.t-flac16")
        md.title = "Jerry Garcia live at Providence Civic Center, Providence, RI on 1991-11-19"
        md.description = desc
        var model = ShowMetadataModel()
        model.metadata = md

        ShowDetailViewModel.backfillMissingMetadata(&model)
        XCTAssertEqual(model.metadata?.source?.first,
                       "Schoeps CMC54 (hand held 4th row)--> Peter Grace power supply 12V--> DAT--> ZA2 (48/44.1)--> CEP--> SHN")
        XCTAssertEqual(model.metadata?.venue, "Providence Civic Center")
        XCTAssertEqual(model.metadata?.coverage, "Providence, RI")
    }

    func testBackfillDoesNotOverwriteExistingFields() {
        var md = ShowMetadata(identifier: "x")
        md.venue = "Winterland"
        md.source = ["SBD master"]
        md.title = "X live at Somewhere Else on 1977-01-01"
        md.description = "Source: something worse"
        var model = ShowMetadataModel()
        model.metadata = md

        ShowDetailViewModel.backfillMissingMetadata(&model)
        XCTAssertEqual(model.metadata?.venue, "Winterland")
        XCTAssertEqual(model.metadata?.source, ["SBD master"])
    }

    // MARK: - Search recording-type filter

    func testSearchFilteredResultsByRecordingType() {
        let vm = SearchViewModel()
        vm.results = [
            ShowMetadata(identifier: "gd77-05-08.sbd.hicks.flac16"),
            ShowMetadata(identifier: "gd77-05-08.aud.taper.flac16"),
            ShowMetadata(identifier: "gd77-05-08.mtx.seamons.flac16")
        ]

        vm.recordingTypeFilter = ""
        XCTAssertEqual(vm.filteredResults.count, 3)

        vm.recordingTypeFilter = "SBD"
        XCTAssertEqual(vm.filteredResults.map { $0.identifier }, ["gd77-05-08.sbd.hicks.flac16"])

        vm.recordingTypeFilter = "AUD"
        XCTAssertEqual(vm.filteredResults.map { $0.identifier }, ["gd77-05-08.aud.taper.flac16"])

        vm.recordingTypeFilter = "FM"
        XCTAssertTrue(vm.filteredResults.isEmpty)

        vm.results = nil
        XCTAssertTrue(vm.filteredResults.isEmpty)
    }

    // MARK: - DeepLinkRouter

    func testDeepLinkRouterHandleURL() {
        let router = DeepLinkRouter()
        let url = URL(string: "chateauarchive://gd1977-05-08")!
        router.handle(url: url)
        XCTAssertEqual(router.pendingShow?.identifier, "gd1977-05-08")
        XCTAssertEqual(router.pendingShowType, .archive)
    }

    func testDeepLinkRouterHandleEmptyHost() {
        let router = DeepLinkRouter()
        let url = URL(string: "chateauarchive://")!
        router.handle(url: url)
        XCTAssertNil(router.pendingShow)
    }

    func testDeepLinkRouterConsume() {
        let router = DeepLinkRouter()
        let url = URL(string: "chateauarchive://gd1977-05-08")!
        router.handle(url: url)

        let result = router.consume()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0.identifier, "gd1977-05-08")

        // After consume, pending should be cleared
        XCTAssertNil(router.pendingShow)
        let result2 = router.consume()
        XCTAssertNil(result2)
    }

    func testDeepLinkRouterNavigate() {
        let router = DeepLinkRouter()
        let meta = ShowMetadata(identifier: "phish-2023-07-14")
        let model = ShowMetadataModel(metadata: meta)
        router.navigate(to: meta, showType: .phishIn, model: model)

        XCTAssertEqual(router.pendingShow?.identifier, "phish-2023-07-14")
        XCTAssertEqual(router.pendingShowType, .phishIn)
        XCTAssertNotNil(router.pendingModel)
    }

    // MARK: - ShowMetadatas (collection wrapper)

    func testShowMetadatasDecoding() throws {
        let json = """
        {"items":[{"identifier":"show1"},{"identifier":"show2"}]}
        """.data(using: .utf8)!
        let result = try JSONDecoder().decode(ShowMetadatas.self, from: json)
        XCTAssertEqual(result.items?.count, 2)
        XCTAssertEqual(result.items?.first?.identifier, "show1")
    }

    // MARK: - YearsTotalResponse

    func testYearsTotalResponseDecoding() throws {
        let json = """
        {"responseHeader":{"status":0,"QTime":5},"response":{"numFound":1742,"start":0,"docs":[]}}
        """.data(using: .utf8)!
        let result = try JSONDecoder().decode(YearsTotalResponse.self, from: json)
        XCTAssertEqual(result.totalCount, 1742)
        XCTAssertEqual(result.responseHeader.status, 0)
        XCTAssertEqual(result.responseHeader.qTime, 5)
    }

    // MARK: - ShowFilter enum

    func testShowFilterCases() {
        XCTAssertEqual(ShowFilter.all.rawValue, 0)
        XCTAssertEqual(ShowFilter.sbd.rawValue, 1)
        XCTAssertEqual(ShowFilter.joesPicks.rawValue, 2)
        XCTAssertEqual(ShowFilter.allCases.count, 3)
    }

    // MARK: - Helpers

    private func makeShow(date: String, rating: Float?, reviews: Int?, identifier: String = UUID().uuidString) -> ShowMetadata {
        var show = ShowMetadata(identifier: identifier)
        show.date = date
        show.avg_rating = rating
        show.num_reviews = reviews
        return show
    }
}
