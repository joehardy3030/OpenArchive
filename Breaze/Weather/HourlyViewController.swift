//
//  HourlyViewController.swift
//  Breaze
//
//  Created by Joe Hardy on 5/8/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit

class HourlyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var store = WeatherStore()
//    var simpleForecastArray = [SimpleForecastDay]()
    var hourlyForecastArray = [HourlyForecastHour]()
    @IBOutlet weak var HourlyForecastTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.HourlyForecastTable.dataSource = self;
        
        store.fetchHourlyForecast {
            (HourlyForecastResult) -> Void in
            
            switch HourlyForecastResult {
            case let .success(hourlyForecast):
                self.hourlyForecastArray = hourlyForecast
                print("count hourly \(self.hourlyForecastArray.count)")
                DispatchQueue.main.async{
                    self.HourlyForecastTable.reloadData()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.hourlyForecastArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "HourlyForecastCell", for: indexPath) as! HourlyForecastCell
        
        // Set the text on the cell with the description of the item
        // that s the nth index of items, where n = row this cell
        // will appear in the tableview
        let weatherCellData = self.hourlyForecastArray[indexPath.row]
        
        cell.tempLabel?.text = weatherCellData.temp + " F"
        cell.humidityLabel?.text = weatherCellData.humidity + "%"
        cell.timeLabel?.text = weatherCellData.civil
       // cell.windDirectionLabel?.text = weatherCellData.dir
        cell.windSpeedLabel?.text = weatherCellData.dir + "  " + weatherCellData.wspd + " MPH"
       // cell.conditionsLabel?.text = weatherCellData.wx
        
        
        var iconImage = UIImage(named: "clear")
        switch weatherCellData.icon {
        case "clear":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.conditionsLabel?.text = "Clear"
        case "rain":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.conditionsLabel?.text = "Rain"
        case "chancerain":
            iconImage = UIImage(named: "rain")!
            cell.conditionsLabel?.text = "Chance of Rain"
        case "tstorms":
            iconImage = UIImage(named: "rain")!
            cell.conditionsLabel?.text = "Thunder Storms"
        case "mostlycloudy":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.conditionsLabel?.text = "Mostly Cloudy"
        case "partlycloudy":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.conditionsLabel?.text = "Partly Cloudy"
        case "cloudy":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.conditionsLabel?.text = "Cloudy"
        case "fog":
            iconImage = UIImage(named: weatherCellData.icon)!
            cell.conditionsLabel?.text = "Fog"
        default:
            iconImage = UIImage(named: "cloudy")!
            cell.conditionsLabel?.text = weatherCellData.icon
        }
        cell.iconImage?.image = iconImage
        
        return cell
    }
    
}


