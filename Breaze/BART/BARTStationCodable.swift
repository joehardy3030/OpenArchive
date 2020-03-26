//
//  BARTStationCodable.swift
//  Breaze
//
//  Created by Joe Hardy on 3/26/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class BARTStationCodable: Codable {
    var address: String?
    var city: String?
    var zipcode: Int?
    var abbr: String?
    var name: String?
    var gtfs_latitude: Float?
    var gtfs_longitude: Float?

    var direction: String?
    
    /*
    var address: String?
    var city: String?
    var zipcode: Int?
    var abbr: String?
    var name: String?
    var gtfs_latitude: Float?
    var gtfs_longitude: Float?

    var direction: String?
    
    init(address: String?, city: String?, zipcode: Int?,
         abbr: String?, name: String?,
         gtfs_latitude: Float?, gtfs_longitude: Float?,
         direction: String?) {
        
        self.address = address
        self.city = city
        self.zipcode = zipcode
        self.abbr = abbr
        self.name = name
        self.gtfs_latitude = gtfs_latitude
        self.gtfs_longitude = gtfs_longitude
        
        self.direction = direction
    }
 */
}
