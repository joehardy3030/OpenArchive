//
//  LocationStorage.swift
//  Breaze
//
//  Created by Joe Hardy on 4/1/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//
import Foundation
import CoreLocation

class LocationsStorage {
    static let shared = LocationsStorage()
    
    private(set) var locations: [Location]
    private let fileManager: FileManager
    private let documentsURL: URL
    
    init() {
        let fileManager = FileManager.default
        documentsURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        self.fileManager = fileManager
        self.locations = []
    }
    
    func saveLocationOnDisk(_ location: Location) {
      // 1
      let encoder = JSONEncoder()
      let timestamp = location.date.timeIntervalSince1970

      // 2
      let fileURL = documentsURL.appendingPathComponent("\(timestamp)")

      // 3
      let data = try! encoder.encode(location)

      // 4
      try! data.write(to: fileURL)

      // 5
      locations.append(location)
    }
}
