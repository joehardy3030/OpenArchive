//
//  BARTStationCodable.swift
//  Breaze
//
//  Created by Joe Hardy on 3/26/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class BARTStationCodable: Codable {
    let address: String?
    let city: String?
    let zipcode: Int?
    let abbr: String?
    let name: String?
    let gtfs_latitude: Double?
    let gtfs_longitude: Double?
    
    init() {
        self.address = nil
        self.city = nil
        self.zipcode = nil
        self.abbr = nil
        self.name = nil
        self.gtfs_latitude = nil
        self.gtfs_longitude = nil
    }
    
    init(address: String?,
         city: String?,
         zipcode: Int?,
         abbr: String?,
         name: String?,
         gtfs_latitude: Double?,
         gtfs_longitude: Double?) {
        
        self.address = address
        self.city = city
        self.zipcode = zipcode
        self.abbr = abbr
        self.name = name
        self.gtfs_latitude = gtfs_latitude
        self.gtfs_longitude = gtfs_longitude
    }
}
