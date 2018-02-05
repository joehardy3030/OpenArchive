//
//  FirstViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class WeatherViewController: UIViewController {
    var store = WeatherStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        store.fetchSimpleForecast()
        store.fetchHourlyForecast()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

