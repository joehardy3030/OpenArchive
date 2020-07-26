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
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let center = UNUserNotificationCenter.current()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in }
        do {
              //options: AVAudioSession.CategoryOptions.mixWithOthers
              try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
              try AVAudioSession.sharedInstance().setActive(true)
          }
          catch {
              print("nope")
          }
        FirebaseApp.configure()
        
        // Dependency injection is fun! Remind me again what's so bad about singeltons?
        if let tbc = window?.rootViewController as? UITabBarController {
            if let rvc = tbc.viewControllers?[0] as? DownloadsNavigationController {
                if let vc = rvc.topViewController as? DownloadsViewController {
                    vc.player = AudioPlayerArchive()
                }
            }
        }

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
      //  self.saveContext()
    }
    
}

