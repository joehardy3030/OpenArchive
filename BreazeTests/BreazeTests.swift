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
