//
//  BARTViewController.swift
//  Breaze
//
//  Created by Joe Hardy on 2/8/19.
//  Copyright © 2019 Carquinez. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
//import Alamofire

protocol ModalDelegate {
    func changeStation(station: BARTStation)
}

class BARTViewController: UITableViewController, ModalDelegate {

    var refresher: UIRefreshControl!
    var currentStation = BARTStation(abbreviation: "DELN", direction: "s")
    var store = BARTStore()
    var BARTReadingArray = [BARTReading]()
    var BARTStations = [BARTStationCodable]()
    var testValue: String = ""
    @IBOutlet var inOutControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavTitle()
        let refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        refresher.tintColor = UIColor.gray
        self.refreshControl = refresher
        BARTStations = BARTAPI.readBARTstnsJSON()
        let currentStationC = findStationWithAbbr(abbr: "DELN")
        self.updateBARTData(station: currentStation, parameters: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func SettingsButton(_ sender: UIBarButtonItem) {
        print("Settings")
        //let modalViewController = BARTModal()
        let modalViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BARTModal") as! BARTModal

        let navigationController = UINavigationController(rootViewController: modalViewController)
        modalViewController.delegate = self
        self.present(navigationController, animated: true, completion: nil)
        //self.present(modalViewController, animated: true, completion: nil)
    }
    
    func findStationWithAbbr(abbr: String?) -> BARTStationCodable {
        let abbrs = BARTStations.map { $0.abbr }
        if let i = abbrs.firstIndex(of: abbr) {
            return BARTStations[i]
        }
        else { return BARTStationCodable() }
    }
    
    func changeStation(station: BARTStation) {
        // This function is executed when returning from the station selection modal
        currentStation = station
        setDirection()
        print(currentStation.abbreviation)
        setNavTitle()
        self.updateBARTData(station: currentStation, parameters: nil)
    }
    
    @IBAction func inOutChanged(_ sender: Any) {
        // this function is executed when the UISegmentedControl is toggled
        //setNavTitle()
        setDirection()
        self.updateBARTData(station: currentStation, parameters: nil)
    }
    
    func setNavTitle() {
        navigationItem.title = currentStation.abbreviation
    }
    
    func setDirection() {
        switch inOutControl.selectedSegmentIndex
        {
        case 0:
            currentStation.direction = "s"
        case 1:
            currentStation.direction = "n"
        default:
            break
        }
    }
    
    /*
    @objc func receivedLocationNotification(notification: NSNotification){
        print("received notification")
        var parameters: [String:String]?
        self.currentLocation = appDelegate.currentLocation
        
        DispatchQueue.main.async{
            parameters = self.setParameters()
            print(parameters)
            /*   let parameters = [
             "latitude": String(self.currentLocation.coordinate.latitude),
             "longitude": String(self.currentLocation.coordinate.longitude)
             ] */
        //    self.updateSimpleForecastData(parameters: parameters)
            print(self.currentLocation?.coordinate.latitude as Any)
            print(self.currentLocation?.coordinate.longitude as Any)
        }
        
    }
 
 */
 /*
    func fetchLastLocation() -> lastLocation {
        
        var location = lastLocation()
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LastLocation")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "longitude") as! String)
                location.longitude = data.value(forKey: "longitude") as? String
                location.latitude = data.value(forKey: "latitude") as? String
            }
            
        } catch {
            print("Failed")
        }
        return location
    }
 
 */
    
    
    
 
    
    func updateBARTData(station: BARTStation, parameters: [String:String]?) {
        // Grab the BART data
        
  /*      switch inOutControl.selectedSegmentIndex
        {
        case 0:
            let station = inboundStation
        case 1:
            let station = outboundStation
        default:
            break
        }
    */
        store.fetchBARTResult(location: parameters,
                              station: station){
            (BARTResult) -> Void in
            switch BARTResult {
            case let .success(finalBARTReading):
                self.BARTReadingArray = finalBARTReading
                print("count BARTs \(self.BARTReadingArray.count)")
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                 //   self.locationLabel.text = displayCity
                }
            case let .failure(error):
                print("Error fetching BART Result: \(error)")
            }
        }
    }
 
  

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.BARTReadingArray.count
    }
 
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "BARTCell", for: indexPath) as! BARTCell
        
        // Set the text on the cell with the description of the item
        // that s the nth index of items, where n = row this cell
        // will appear in the tableview
        let BARTCellData = self.BARTReadingArray[indexPath.row]
        
        cell.numCarsLabel?.text = BARTCellData.numCars + " cars"
        cell.minToArrivalLabel?.text = BARTCellData.minToArrival + " min"
        cell.lineColorLabel?.text = BARTCellData.lineColor
        cell.destinationLabel?.text = BARTCellData.destination
        cell.lineColorView.backgroundColor = getLineColor(color: BARTCellData.lineColor)
        
        //cell.lineColorView.backgroundColor = UIColor .red

      //  cell.dayLabel?.text = weatherCellData.weekday_short
        
       // cell.iconLabel?.text = utils.switchConditionsText(icon: weatherCellData.icon)
       // cell.iconImage?.image = utils.switchConditionsImage(icon: weatherCellData.icon) */
        return cell
    }

    private func getLineColor(color: String) -> UIColor {
        var lineColor: UIColor
        
        switch color {
        case "RED":
            lineColor = UIColor.red
        case "ORANGE":
            lineColor = UIColor.orange
        case "BLUE":
            lineColor = UIColor.blue
        case "YELLOW":
            lineColor = UIColor.yellow
        case "GREEN":
            lineColor = UIColor.green

        default:
            lineColor = UIColor.black
        }
        return lineColor
    }

    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
    
        // Do some reloading of data and update the table view's data source
        // Fetch more objects from a web service, for example...
    
        /*
        var parameters: [String:String]?
        parameters = setParameters()
        if (parameters != nil) {
//            self.updateSimpleForecastData(parameters: parameters)
            print("Location not nil")
        }
        else {
  //          self.updateSimpleForecastData(parameters: nil)
            print("Location nil")
        }
 */
        self.updateBARTData(station: currentStation, parameters: nil)
        refreshControl.endRefreshing()
        
    }


    /*
    func setParameters() -> [String:String]? {
        // when currentLocation is nil, this barfs
        var parameters: [String:String]?
        if (self.currentLocation?.coordinate.latitude) != nil {
            parameters = [
                "latitude": String(self.currentLocation.coordinate.latitude),
                "longitude": String(self.currentLocation.coordinate.longitude)
            ]
        }
        return parameters
    }
 */
    
}



