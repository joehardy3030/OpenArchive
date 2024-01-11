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
