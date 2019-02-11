//
//  BARTStore.swift
//  Breaze
//
//  Created by Joe Hardy on 2/9/19.
//  Copyright © 2019 Carquinez. All rights reserved.
//

import UIKit

enum BARTResult {
    case success([BARTResult])
    // case success([SmogReading])
    case failure(Error)
}

class BARTStore {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
/*    private func processBARTResult(data: Data?, error: Error?) -> BARTResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return BARTAPI.BARTTiming(fromJSON: jsonData)
    }
  */
/*    func fetchBARTResult(location: [String:String]?, completion: @escaping (BARTResult) -> Void) {
        
        let url = BARTAPI.BARTURL(location: location)
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) -> Void in
            let result = self.processBARTResult(data: data, error: error)
            completion(result)
            print(result)
        }
        task.resume()
    }
  */
}
