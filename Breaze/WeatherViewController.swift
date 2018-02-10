//
//  FirstViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class WeatherViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        <#code#>
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    
    var store = WeatherStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        store.fetchSimpleForecast {
            (SimpleForecastResult) -> Void in
            
            switch SimpleForecastResult {
            case let .success(simpleForecast):
                for simpleForecastDay in simpleForecast {
                        print("Successfully found \(simpleForecastDay.high)")
                }
                
            case let .failure(error):
                print("Error fetching simple forecast: \(error)")
            }
        }
        //store.fetchHourlyForecast()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

