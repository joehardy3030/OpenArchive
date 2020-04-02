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

protocol ModalDelegate {
    func changeStation(station: BARTStationCodable, direction: String)
}

enum BARTDirection: String {
    case north = "n"
    case south = "s"
}

class BARTViewController: UITableViewController  {
    
    let locationManager =  CLLocationManager()
    var refresher = UIRefreshControl()
    let utils = Utils()
    var store = BARTStore()
    var BARTReadingArray = [BARTReading]()
    var currentStation = BARTStationCodable()
    var currentDirection = BARTDirection.south
    @IBOutlet var inOutControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refresher.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        self.refresher.tintColor = UIColor.gray
        self.refreshControl = refresher
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.handleLocationGetEtd()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func handleLocationGetEtd() {
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.startUpdatingLocation()
        }
        else {
            self.currentStation = BARTAPI.findStationWithAbbr(abbr: "BERK")
            updateStationData()
        }
    }

    func updateStationData() {
        self.updateBARTData(station: self.currentStation, direction: self.currentDirection, parameters: nil)
        setNavTitle()
    }
    
    @IBAction func SettingsButton(_ sender: UIBarButtonItem) {
        let modalViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BARTModal") as! BARTModal

        let navigationController = UINavigationController(rootViewController: modalViewController)
        modalViewController.delegate = self
        self.present(navigationController, animated: true, completion: nil)
    }

    @IBAction func inOutChanged(_ sender: Any) {
        setDirection()
        updateStationData()
    }
    
    func setNavTitle() {
        navigationItem.title = currentStation.abbr
    }
    
    func setDirection() {
        switch inOutControl.selectedSegmentIndex
        {
        case 0:
            self.currentDirection = .south
        case 1:
            self.currentDirection = .north
        default:
            break
        }
    }
    
    func updateBARTData(station: BARTStationCodable, direction: BARTDirection, parameters: [String:String]?) {
        store.fetchBARTResult(location: parameters,
                              station: station,
                              direction: direction.rawValue){
            (BARTResult) -> Void in
            switch BARTResult {
            case let .success(finalBARTReading):
                self.BARTReadingArray = finalBARTReading
                print("count BARTs \(self.BARTReadingArray.count)")
                DispatchQueue.main.async{
                    self.tableView.reloadData()
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BARTCell", for: indexPath) as! BARTCell
        let BARTCellData = self.BARTReadingArray[indexPath.row]
        
        cell.numCarsLabel?.text = BARTCellData.numCars + " cars"
        cell.minToArrivalLabel?.text = BARTCellData.minToArrival + " min"
        cell.lineColorLabel?.text = BARTCellData.lineColor
        cell.destinationLabel?.text = BARTCellData.destination
        cell.lineColorView.backgroundColor = getLineColor(color: BARTCellData.lineColor)
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
        updateStationData()
        refreshControl.endRefreshing()
    }

}

extension BARTViewController: ModalDelegate {
    func changeStation(station: BARTStationCodable, direction: String) {
        // This function is executed when returning from the station selection modal
        self.currentStation = station
        setDirection()
        updateStationData()
    }
}

extension BARTViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location error")
        self.locationManager.stopUpdatingLocation()
        if let location = LocationsStorage.shared.locations.last {
            self.currentStation = BARTAPI.findClosestStation(currentLocation: location.clLocation)
        }
        else {
            self.currentStation = BARTAPI.findStationWithAbbr(abbr: "PLZA")
        }
        updateStationData()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        guard let location: CLLocation = manager.location else { return }
        let station = BARTAPI.findClosestStation(currentLocation: location)
        self.currentStation = station
        updateStationData()
    }
    
}
