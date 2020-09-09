//
//  ArchiveSuperViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/24/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class ArchiveSuperViewController: UIViewController, FUIAuthDelegate {
    var network: NetworkUtility!
    let utils = Utils()
    let archiveAPI = ArchiveAPI()
    var prevController: ArchiveSuperViewController?
    var miniPlayer: MiniPlayerViewController?
    var player: AudioPlayerArchive?
    var isPlaying = false
    var auth: Auth?
    var authUI: FUIAuth?
    var db: Firestore!
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        if db != nil {
            network = NetworkUtility(db: db)
        }
        authUI?.delegate = self
        navigationController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (self.authStateListenerHandle == nil) {
            self.authStateListenerHandle = self.auth?.addStateDidChangeListener { (auth, user) in
                guard user != nil else {
                    if let authVC = self.authUI?.authViewController() {
                        self.show(authVC, sender: self)
                    }
                    
                    return
                }
                if let user = user {
                    print("User has changed to \(user.uid)")
                }
            }
        }
    }

    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        print(user as Any)
   }

}


extension ArchiveSuperViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let _ = viewController as? ArchiveSuperViewController {
        }
    }
}
