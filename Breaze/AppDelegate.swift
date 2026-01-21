//
//  AppDelegate.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/31/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import UserNotifications
import ARKit
import CarPlay


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let center = UNUserNotificationCenter.current()
    let archiveAPI = ArchiveAPI()

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("application did finish")
        // Firebase authentication removed; local database used instead
        _ = sharedSetup()
        return true
 
    }
    

    func sharedSetup() -> Bool {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            print("AV session")
          }
          catch {
              print("nope")
          }
        return true
    }
    
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        // Save playback state for resume on next launch
        AudioPlayerArchive.shared.savePlaybackState()
    }
}

