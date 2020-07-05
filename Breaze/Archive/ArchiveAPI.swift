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

    
    let baseURLString = "https://archive.org/"
    
    func metadataURL(identifier: String) -> String {
        var url = baseURLString
        url += "metadata/"
        url += identifier
        return url
    }
    
    func downloadURL(identifier: String,
                     filename: String?) -> String {
        //https://archive.org/download/<identifier>/<filename>
        //identifier=gd1990-03-30.sbd.barbella.8366.sbeok.shnf
        //filename=gd90-03-30d1t01multi.mp3
        
        var url = baseURLString
        url += "download/"
        url += identifier
        if let f = filename {
            url += "/"
            url += f
        }
        return url
    }
    
    func searchURL(identifier: String,
                  searchParams: [String:String]?) -> String {
                        
        var url = baseURLString
        return url
    }
    
    func dateRangeURL(year: Int, month: Int) -> String {
        let andString = "%20AND%20"
        let dateString = "date%3A%5B"
        let toString = "%20TO%20"
        var url = baseURLString
        var monthString: String
        
        
        url += "services/search/v1/scrape?q=collection%3A%28GratefulDead%29"
        url += andString
        url += dateString
        if month <= 9 {
            monthString = "0" + String(month)
        }
        else {
            monthString = String(month)
        }
        url += String(year) + "-" + monthString + "-01"
        url += toString
        url += String(year) + "-" + monthString + "-31"
        url += "%5D"
        // Search in date range
        //https://archive.org/services/search/v1/scrape?q=collection%3A%28GratefulDead%29%20AND%20date%3A%5B1987-03-01%20TO%201987-03-31%5D
        
        return url
    }
    
    func getIARequestMetadata(url: String, completion: @escaping (ShowMetadataModel) -> Void) {
        Alamofire.request(url).responseJSON { response in
            //debugPrint(response)
            //let weatherModel = self.deserializeCurrent(fromJSON: json)
            if let json = response.result.value {
                let j = JSON(json)
                print(j)
                let showMetadataModel = ShowMetadataModel(metadata: nil, files: nil)
                completion(showMetadataModel)
              }
        }
    }
    
    func getIARequestItems(url: String, completion: @escaping ([String]?) -> Void) {
        Alamofire.request(url).responseJSON { response in
            //debugPrint(response)
            //let weatherModel = self.deserializeCurrent(fromJSON: json)
            if let json = response.result.value {
                let j = JSON(json)
                let items = j["items"]
                var itemArray = [String]()
                
                for i in items {
                    if let id_string = i.1["identifier"].string {
                        itemArray.append(id_string)
                    }
                }
                completion(itemArray)
              }
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
    
    func readCSV() {
        guard let csvPath = Bundle.main.path(forResource: "meta_gd_trim", ofType: "csv") 
        //guard let csvPath = Bundle.main.url(forResource: "meta_gd_trim", withExtension: "csv")
            else {
            print("nope")
            return
            
        }

        //        guard let csvPath = Bundle.main.path(forResource: "mostlycloudy", ofType: "png") else { return }

        print("before do")

        do {
            let csvData = try String(contentsOfFile: csvPath, encoding: String.Encoding.utf8)
            //let csv = csvData.csvRows()
            print("before loop")
            //for row in csvData {
             //   print(csvData)
           //5 }
        } catch{
            print(error)
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

    
    

