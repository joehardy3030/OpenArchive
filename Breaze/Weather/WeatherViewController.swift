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
    var simpleForecastArray = [SimpleForecastDay]()
    var hourlyForecastArray = [HourlyForecastHour]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        store.fetchSimpleForecast {
            (SimpleForecastResult) -> Void in
            
            switch SimpleForecastResult {
            case let .success(simpleForecast):
                self.simpleForecastArray = simpleForecast
                print("count simple \(self.simpleForecastArray.count)")
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
            case let .failure(error):
                print("Error fetching simple forecast: \(error)")
            }
            
        }

        store.fetchHourlyForecast {
            (HourlyForecastResult) -> Void in
            
            switch HourlyForecastResult {
            case let .success(hourlyForecast):
                self.hourlyForecastArray = hourlyForecast
                print("count hourly \(self.hourlyForecastArray.count)")
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
        return self.simpleForecastArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "SimpleForecastCell", for: indexPath) as! WeatherCell
        
        // Set the text on the cell with the description of the item
        // that s the nth index of items, where n = row this cell
        // will appear in the tableview
        let weatherCellData = self.simpleForecastArray[indexPath.row]
        
        cell.highTempLabel?.text = weatherCellData.high + " F"
        cell.lowTempLabel?.text = weatherCellData.low + " F"
        cell.dayLabel?.text = weatherCellData.weekday_short
        
        var iconImage = UIImage(named: "clear")
        switch weatherCellData.icon {
        case "clear":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Clear"
        case "rain":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Rain"
        case "chancerain":
            iconImage = UIImage(named: "rain")!
            cell.iconLabel?.text = "Chance of Rain"
        case "tstorms":
            iconImage = UIImage(named: "rain")!
            cell.iconLabel?.text = "Thunder Storms"
        case "mostlycloudy":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Mostly Cloudy"
        case "partlycloudy":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Partly Cloudy"
        case "cloudy":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Cloudy"
        case "fog":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Fog"
        default:
            iconImage = UIImage(named: "cloudy")!
            cell.iconLabel?.text = weatherCellData.icon
        }
        cell.iconImage?.image = iconImage
       
        return cell
    }
    
 /*   private func selectIconImage(icon_name: String) {
        switch icon_name {
        case "clear":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Clear"
        case "rain":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Rain"
        case "chancerain":
            iconImage = UIImage(named: "rain")!
            cell.iconLabel?.text = "Chance of Rain"
        case "tstorms":
            iconImage = UIImage(named: "rain")!
            cell.iconLabel?.text = "Thunder Storms"
        case "mostlycloudy":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Mostly Cloudy"
        case "partlycloudy":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Partly Cloudy"
        case "cloudy":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Cloudy"
        case "fog":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.iconLabel?.text = "Fog"
        default:
            iconImage = UIImage(named: "cloudy")!
            cell.iconLabel?.text = weatherCellData.icon
        }
    } */

}

