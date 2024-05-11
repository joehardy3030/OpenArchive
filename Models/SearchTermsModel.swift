//
//  SearchTermsModel.swift
//  Breaze
//
//  Created by Joseph Hardy on 3/5/24.
//  Copyright © 2024 Carquinez. All rights reserved.
//

import Foundation

struct SearchTermsModel: Codable {
    var searchTerm: String?
    var venue: String?
    var startYear: String?
    var endYear: String?
    var minRating: String?
    var sbdOnly: Bool?
}

