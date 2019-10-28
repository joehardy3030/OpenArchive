//
//  CityModel.swift
//
//  Created by Joe Hardy on 10/27/19.
//

import UIKit

struct CityModel: Codable {
    
    let name: String?
    let country: String?
    let coordinates: [String:Double?]?
    let population: Double?
    let timezone: Double?
    let sunrise: Double?
    let sunset: Double?
    
    var dictionary: [String : Any]? {
        return ["name": name as Any,
                "country": country as Any,
                "coordinates": coordinates as Any,
                "population": population as Any,
                "timezone": timezone as Any,
                "sunrise": sunrise as Any,
                "sunset": sunset as Any]
    }
    
    init(name: String?,
         country: String?,
         coordinates: [String:Double?]?,
         population: Double?,
         timezone: Double?,
         sunrise: Double?,
         sunset: Double?)
        
    {
        self.name = name
        self.country = country
        self.coordinates = coordinates
        self.population = population
        self.timezone = timezone
        self.sunrise = sunrise
        self.sunset = sunset
    }
    
}
