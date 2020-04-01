//
//  MapViewController.swift
//  Breaze
//
//  Created by Joe Hardy on 4/1/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.userTrackingMode = .follow
        // Do any additional setup after loading the view.
    }
    

    @IBAction func addItem(_ sender: Any) {
        guard let currentLocation = mapView.userLocation.location else {
            print("can't set current location")
            return
        }
        LocationsStorage.shared.saveCLLocationToDisk(currentLocation)
        print(currentLocation.coordinate)
        print("pressed")
    }
    
    
}
