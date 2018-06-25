//
//  AppDelegate.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit
import CoreLocation

//let carquinezNotificationKey = "com.carquinez.notificationKey"
extension Notification.Name {
    static let alocation = Notification.Name("location")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestLocation()
        //self.locationManager.startUpdatingLocation()

        // let weatherViewController = WeatherViewController()
        // weatherViewController.store = WeatherStore()

        return true
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("error")
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]){
        
        self.currentLocation = locations.last
        DispatchQueue.main.async{
            NotificationCenter.default.post(name: .alocation, object: nil)
            print("location Updated")
        }
//        DispatchQueue.main.async{
//            let parameters = [
//                "latitude": String(self.currentLocation.coordinate.latitude),
 //               "longitude": String(self.currentLocation.coordinate.longitude)
 //           ]
 //           print(parameters["latitude"])
 //           print(parameters["longitude"])
 //       }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

