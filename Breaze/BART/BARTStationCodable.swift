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
}
