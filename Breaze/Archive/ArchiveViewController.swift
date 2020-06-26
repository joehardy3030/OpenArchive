//
//  ArchiveViewController.swift
//  Breaze
//
//  Created by Joe Hardy on 6/24/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class ArchiveViewController: UIViewController {

    var archiveAPI = ArchiveAPI()
    var identifier = "gd1990-03-30.sbd.barbella.8366.sbeok.shnf"
    var filename = "gd90-03-30d1t01multi.mp3"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.getIARequest()
        self.getIADownload()
        // Do any additional setup after loading the view.
    }
    
    //identifier=gd1990-03-30.sbd.barbella.8366.sbeok.shnf
     //filename=gd90-03-30d1t01multi.mp3
     
    func getIARequest() {
        let url = archiveAPI.buildURL(queryType: .openDownload,
                                      identifier: identifier,
                                      filename: filename)
        print(url)

        archiveAPI.getIARequest(url: url) {
            (response: Any?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                    debugPrint(r as Any)
                }
            }
        }
    }
    
    func getIADownload() {
        let url = archiveAPI.buildURL(queryType: .openDownload,
                                      identifier: identifier,
                                      filename: filename)
        print(url)

        archiveAPI.getIADownload(url: url) {
            (response: Any?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                    debugPrint(r as Any)
                }
            }
        }
    }

}
    
