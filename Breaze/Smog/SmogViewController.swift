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
    //var smogArray = [SmogReading]()
    var smogArray = [SmogDay]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        store.fetchSmogForecast {
            (SmogForecastResult) -> Void in
            
            switch SmogForecastResult {
            case let .success(smogForecast):
                self.smogArray = smogForecast
              //  print("count \(self.smogArray.count)")
              //  for smogForecastReading in smogForecast {
              //      print("Successfully found \(smogForecastReading.AQI)")
              //  }
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
        
        cell.siteNameLabel?.text = smogReading.siteName

        cell.PM25Label?.text = String(smogReading.PM25)
        cell.PM25Label?.textColor = getTextColor(AQI: smogReading.PM25)
        
        cell.ozoneLabel?.text = String(smogReading.ozone)
        cell.ozoneLabel?.textColor = getTextColor(AQI: smogReading.ozone)
 //       cell.SO2Label?.text = String(smogReading.SO2)
        
        cell.NO2Label?.text = String(smogReading.NO2)
        cell.NO2Label?.textColor = getTextColor(AQI: smogReading.NO2)

        return cell
    }
    
    private func getTextColor(AQI: Int) -> UIColor {
        let textColor: UIColor
        switch AQI {
        case 0...49:
            textColor = UIColor.green
        case 50...99:
            textColor = UIColor.yellow
        case 100...149:
            textColor = UIColor.orange
        case 150...1000:
            textColor = UIColor.red
        default:
            textColor = UIColor.black
        }
        return textColor
    }


}

