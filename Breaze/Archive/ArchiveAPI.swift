//
//  ArchiveAPI.swift
//  Breaze
//
//  Created by Joe Hardy on 6/25/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

enum iaQueryType {
    case openDownload
    case session
}

class ArchiveAPI: NSObject {

    //https://archive.org/download/<identifier>/<filename>
    //identifier=gd1990-03-30.sbd.barbella.8366.sbeok.shnf
    //filename=gd90-03-30d1t01multi.mp3
    
    //let utils = Utils()
    // let apiKey = "263e9f27a9c219e9d7db30993b91c33b"
    let baseURLString = "https://archive.org/"
    //struct lastLocation {
    //    var latitude: String?
    //    var longitude: String?
    // }
    
    func buildURL(queryType: iaQueryType,
                  identifier: String,
                  filename: String?) -> String {
                        
        switch queryType {
        case .openDownload:
            var url = baseURLString
            url += "download/"
            url += identifier
            if let f = filename {
                url += "/"
                url += f
            }
            return url
        case .session:
            var url = baseURLString
            url += "download/"
            url += identifier
            if let f = filename {
                url += "/"
                url += f
            }
            return url
        }
    }
    
    func getAIFile(url: String, completion: @escaping (Any?) -> Void) {
        Alamofire.request(url).response { response in
            //debugPrint(response)
            //let weatherModel = self.deserializeCurrent(fromJSON: json)
            completion(response)
        }
    }
}
    
    

