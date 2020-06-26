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
    
    func getIARequest(url: String, completion: @escaping (Any?) -> Void) {
        Alamofire.request(url).responseData { response in
            //debugPrint(response)
            //let weatherModel = self.deserializeCurrent(fromJSON: json)
            completion(response)
        }
    }
    
    func getIADownload(url: String, completion: @escaping (Any?) -> Void) {
        //https://github.com/Alamofire/Alamofire/blob/master/Documentation/Usage.md#downloading-data-to-a-file
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        debugPrint(destination)
        Alamofire.download(url, to: destination).responseData { response in
            completion(response)
            }
        }

    }
/*
    let destination: DownloadRequest.destination = { _, _ in
        let documentsURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("image.png")
        return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
    }

    Alamofire.download("https://httpbin.org/image/png", to: self.destination).response { response in
        debugPrint(response)
        if response.error == nil, let imagePath = response.fileURL?.path {
            let image = UIImage(contentsOfFile: imagePath)
        }
    }
*/

    
    

