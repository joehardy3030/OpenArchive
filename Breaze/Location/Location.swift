//
//  Location.swift
//  Breaze
//
//  Created by Joe Hardy on 3/29/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import Foundation
import CoreLocation

class Location: Codable {
  static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    return formatter
  }()
  
  var coordinates: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
  
  let latitude: Double
  let longitude: Double
  let date: Date
  let dateString: String
  let description: String
  
  init(_ location: CLLocationCoordinate2D, date: Date, descriptionString: String) {
    self.latitude =  location.latitude
    self.longitude =  location.longitude
    self.date = date
    self.dateString = Location.dateFormatter.string(from: date)
    self.description = descriptionString
  }
  
  convenience init(visit: CLVisit, descriptionString: String) {
    self.init(visit.coordinate, date: visit.arrivalDate, descriptionString: descriptionString)
  }
}
