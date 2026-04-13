//
//  BreazeTests.swift
//  BreazeTests
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import XCTest
@testable import Breaze

class BreazeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testDateRangeURLUsesCorrectMonthEndDate() {
        let archiveAPI = ArchiveAPI()

        let februaryURL = archiveAPI.dateRangeURL(year: 1987, month: 2, sbdOnly: false)
        XCTAssertTrue(februaryURL.contains("1987-02-01%20TO%201987-02-28"))
        XCTAssertFalse(februaryURL.contains("1987-02-31"))

        let aprilURL = archiveAPI.dateRangeURL(year: 1987, month: 4, sbdOnly: false)
        XCTAssertTrue(aprilURL.contains("1987-04-01%20TO%201987-04-30"))
        XCTAssertFalse(aprilURL.contains("1987-04-31"))
    }

    func testNormalizedStartIndexClampsToValidBounds() {
        XCTAssertNil(AudioPlayerArchive.normalizedStartIndex(0, count: 0))
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(-5, count: 3), 0)
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(1, count: 3), 1)
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(3, count: 3), 2)
        XCTAssertEqual(AudioPlayerArchive.normalizedStartIndex(10, count: 3), 2)
    }
    
}
