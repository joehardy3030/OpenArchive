//
//  StartViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/26/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import Firebase
//import FirebaseUI

class StartViewController: ArchiveSuperViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ArchiveTabBarController {
           // if let p = player {
           //     vc.player = p // There needs to be a player already for this to work. Need to inject it.
           // }
            if let db = db {
                vc.db = db
            }
        }
        
        if let mp = segue.destination as? MiniPlayerViewController {
//            if let p = player {
                mp.player = player // There needs to be a player already for this to work. Need to inject it.
            
        }
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
