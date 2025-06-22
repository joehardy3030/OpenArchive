import Foundation

struct Review: Codable {
    let id: String
    let showIdentifier: String
    let rating: Float
    let reviewText: String?
    let reviewer: String?
    let date: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case showIdentifier = "show_identifier"
        case rating
        case reviewText = "review_text"
        case reviewer
        case date
    }
}

struct ReviewResponse: Codable {
    let reviews: [Review]
    let total: Int
    let page: Int
    let pageSize: Int
    
    enum CodingKeys: String, CodingKey {
        case reviews
        case total
        case page
        case pageSize = "page_size"
    }
} 