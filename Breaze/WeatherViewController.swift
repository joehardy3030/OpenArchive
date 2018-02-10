//
//  FirstViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class WeatherViewController: UITableViewController {
    
    var store = WeatherStore()
    var weatherArray = [SimpleForecastDay]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        store.fetchSimpleForecast {
            (SimpleForecastResult) -> Void in
            
            switch SimpleForecastResult {
            case let .success(simpleForecast):
                self.weatherArray = simpleForecast
                print("count \(self.weatherArray.count)")
                for simpleForecastDay in simpleForecast {
                        print("Successfully found \(simpleForecastDay.high)")
                }
         //       DispatchQueue.main.async{
          //          self.tableView.reloadData()
           //     }
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.weatherArray.count
    }

}

