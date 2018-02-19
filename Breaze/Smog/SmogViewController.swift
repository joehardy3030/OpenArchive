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
    var smogArray = [SmogReading]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        store.fetchSmogForecast {
            (SmogForecastResult) -> Void in
            
            switch SmogForecastResult {
            case let .success(smogForecast):
                self.smogArray = smogForecast
                print("count \(self.smogArray.count)")
                for smogForecastReading in smogForecast {
                    print("Successfully found \(smogForecastReading.AQI)")
                }
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            case let .failure(error):
                print("Error fetching simple forecast: \(error)")
            }
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.smogArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create an instance of UITableViewCell
       //  let cell = UITableViewCell(style: .value1, reuseIdentifier: "UITableViewCell")
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "SmogForecastCell", for: indexPath) as! SmogCell
        
        // Set the text on the cell with the description of the item
        // that s the nth index of items, where n = row this cell
        // will appear in the tableview
        let smogReading = self.smogArray[indexPath.row]
        
        cell.parameterLabel?.text = smogReading.parameter
        cell.siteNameLabel?.text = smogReading.siteName
        cell.AQILabel?.text = String(smogReading.AQI)
        
        return cell
    }


}

