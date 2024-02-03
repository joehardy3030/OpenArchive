//
//  ChateauGPTModel.swift
//  Breaze
//
//  Created by Joseph Hardy on 12/3/23.
//  Copyright © 2023 Carquinez. All rights reserved.
//

import Foundation

struct ChateauGPTModel: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message?
    }

    let choices: [Choice]?
}

struct ChateauGPTRequest: Codable {
    var model: [String:String]
    var messages: [[String:String]]
    var stream: [String:Bool]
    var temperature: [String:Float]
}

struct ChateauGPTParameters: Encodable {
    var model: String
    var messages: [ChateauGPTMessage]
    var temperature: Double
    var stream: Bool
}

struct ChateauGPTMessage: Codable {
    var role: String
    var content: String
}

struct ChateauGPTStreamCompletionResponse: Decodable {
    let id: String
    let choices: [ChateauGPTStreamChoice]
}

struct ChateauGPTStreamChoice: Decodable {
    let delta: ChateauGPTStreamContent
}

struct ChateauGPTStreamContent: Decodable {
    let content: String
}
