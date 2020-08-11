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
    let network = NetworkUtility()
    let utils = Utils()
    let archiveAPI = ArchiveAPI()
    var prevController: ArchiveSuperViewController?
    var miniPlayer: MiniPlayerViewController?
    var player: AudioPlayerArchive?
    var isPlaying = false
    var auth: Auth?
    var authUI: FUIAuth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
      //  self.auth = Auth.auth()
        authUI?.delegate = self
        navigationController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (self.authStateListenerHandle == nil) {
              self.authStateListenerHandle = self.auth?.addStateDidChangeListener { (auth, user) in
                  guard user != nil else {
                      //FirebaseUI
                    //self.navigationManager.navigateToLoginVC()
                    if let authVC = self.authUI?.authViewController() {
                        self.show(authVC, sender: self)
                    }

//                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                     let secondVC = storyboard.instantiateViewController(identifier: "SecondViewController")

                    //authVC?.show(self, sender: Any?.self)
                      return
                  }
                  if let user = user {
                      print("User has changed to \(user.uid)")
                  }
              }
          }
    }
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
     // handle user and error as necessary
   }

    /*
    func setupFirebaseAuth() {
        //FirebaseApp.configure()
        guard let authUI = FUIAuth.defaultAuthUI() else { return }
        // You need to adopt a FUIAuthDelegate protocol to receive callback
        authUI.delegate = self
        let providers: [FUIAuthProvider] = [
          FUIPhoneAuth(authUI:authUI)
        ]
        authUI.providers = providers
    }
    */
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if let mp = segue.destination as? MiniPlayerViewController {
                self.miniPlayer = mp
                print("Set the miniplayer")
                if let p = player {
                    mp.player = p // There needs to be a player already for this to work. Need to inject it.
                }
            }
    }
    */

}


extension ArchiveSuperViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
       // print("called this")
        if let _ = viewController as? ArchiveSuperViewController {
            // vc.miniPlayer?.player = player
            //  vc.prevController = self
        }
    }
}
