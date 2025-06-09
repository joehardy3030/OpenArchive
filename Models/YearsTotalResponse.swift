//
//  YearsTotalResponse.swift
//  Breaze
//
//  Created by Joseph Hardy on 6/7/25.
//  Copyright © 2025 Carquinez. All rights reserved.
//

struct YearsTotalResponse: Decodable {
    let responseHeader: ResponseHeader
    let response: Response
    
    struct ResponseHeader: Decodable {
        let status: Int
        let qTime: Int
        
        enum CodingKeys: String, CodingKey {
            case status
            case qTime = "QTime"
        }
    }
    
    struct Response: Decodable {
        let numFound: Int
        let start: Int
        let docs: [Document]
    }
    
    // Generic document structure - customize based on what fields you request
    struct Document: Decodable {
        let identifier: String?
        let title: String?
        let mediatype: String?
        let collection: [String]?
        // Add other fields as needed
    }
}

// Convenience computed property to get the count
extension YearsTotalResponse {
    var totalCount: Int {
        return response.numFound
    }
}
