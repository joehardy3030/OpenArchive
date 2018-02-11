//
//  SecondViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class SmogViewController: UITableViewController {

    var store = SmogStore()
    var smogArray = [SmogHour]()

    override func viewDidLoad() {
        super.viewDidLoad()
        store.fetchSmogForecast()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

