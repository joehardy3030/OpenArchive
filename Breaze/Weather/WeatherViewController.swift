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
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            case let .failure(error):
                print("Error fetching simple forecast: \(error)")
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.weatherArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create an instance of UITableViewCell
       // let cell = UITableViewCell(style: .value1, reuseIdentifier: "UITableViewCell")
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "SimpleForecastCell", for: indexPath) as! WeatherCell
        
        // Set the text on the cell with the description of the item
        // that s the nth index of items, where n = row this cell
        // will appear in the tableview
        let weatherDay = self.weatherArray[indexPath.row]

        cell.highTempLabel?.text = weatherDay.high
        cell.lowTempLabel?.text = weatherDay.low
        cell.dayLabel?.text = weatherDay.weekday_short
        
        var iconImage = UIImage(named: "clear")
        switch weatherDay.icon {
        case "clear":
            iconImage = UIImage(named: weatherDay.icon)!
            cell.iconLabel?.text = "Clear"
        case "rain":
            iconImage = UIImage(named: weatherDay.icon)!
            cell.iconLabel?.text = "Rain"
        case "chancerain":
            iconImage = UIImage(named: "rain")!
            cell.iconLabel?.text = "Chance of Rain"
        case "tstorms":
            iconImage = UIImage(named: "rain")!
            cell.iconLabel?.text = "Thunder Storm"
        case "mostlycloudy":
            iconImage = UIImage(named: weatherDay.icon)!
            cell.iconLabel?.text = "Mostly Cloudy"
        case "partlycloudy":
            iconImage = UIImage(named: weatherDay.icon)!
            cell.iconLabel?.text = "Partly Cloudy"
        case "cloudy":
            iconImage = UIImage(named: weatherDay.icon)!
            cell.iconLabel?.text = "Cloudy"
        case "fog":
            iconImage = UIImage(named: weatherDay.icon)!
            cell.iconLabel?.text = "Fog"
        default:
            iconImage = UIImage(named: "clear")!
            cell.iconLabel?.text = weatherDay.icon
        }
        cell.iconImage?.image = iconImage
       
        return cell
    }

}

