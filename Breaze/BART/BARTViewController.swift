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
    func changeStation(station: BARTStationCodable, direction: String)
}

class BARTViewController: UITableViewController, ModalDelegate {

    var refresher: UIRefreshControl!
    var store = BARTStore()
    var BARTReadingArray = [BARTReading]()
    var BARTStations = [BARTStationCodable]()
    //var currentStation = BARTStation(abbreviation: "DELN", direction: "s")
    var currentStation = BARTStationCodable()
    var currentDirection = "s"
    @IBOutlet var inOutControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavTitle()
        let refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        refresher.tintColor = UIColor.gray
        self.refreshControl = refresher
        self.BARTStations = BARTAPI.readBARTstnsJSON()
        self.currentStation = findStationWithAbbr(abbr: "DELN")
        self.updateBARTData(station: self.currentStation, direction: currentDirection, parameters: nil)
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
    
    func changeStation(station: BARTStationCodable, direction: String) {
        // This function is executed when returning from the station selection modal
        self.currentStation = station
        setDirection()
        print(self.currentStation.abbr as Any)
        setNavTitle()
        self.updateBARTData(station: currentStation, direction: direction, parameters: nil)
    }
    
    @IBAction func inOutChanged(_ sender: Any) {
        // this function is executed when the UISegmentedControl is toggled
        //setNavTitle()
        setDirection()
        self.updateBARTData(station: currentStation, direction: currentDirection, parameters: nil)
    }
    
    func setNavTitle() {
        navigationItem.title = currentStation.abbr
    }
    
    func setDirection() {
        switch inOutControl.selectedSegmentIndex
        {
        case 0:
            self.currentDirection = "s"
        case 1:
            self.currentDirection = "n"
        default:
            break
        }
    }

    
    func updateBARTData(station: BARTStationCodable, direction: String, parameters: [String:String]?) {
        store.fetchBARTResult(location: parameters,
                              station: station,
                              direction: direction){
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
    
        self.updateBARTData(station: currentStation, direction: currentDirection, parameters: nil)
        refreshControl.endRefreshing()
    }


}



