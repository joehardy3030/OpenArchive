//
//  DownloadsViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/17/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import FirebaseAuthUI

@available(iOS 13.0, *)
class DownloadsViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var showListTableView: UITableView!
    var shows: [ShowMetadataModel]?
    let fileManager = FileManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showListTableView.delegate = self
        self.showListTableView.dataSource = self
        self.showListTableView.rowHeight = 135.0
        //self.listFiles()
        self.getDownloadedShows()
        print("DownloadsViewController")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign out", style: .plain, target: self, action: #selector(signOutTapped))

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DownloadsViewController")
        
        self.getDownloadedShows()
        
        // Check if a user is not logged in before showing the authVC
        if Auth.auth().currentUser == nil {
            authUI = FUIAuth.defaultAuthUI()
            if let authVC = self.authUI?.authViewController() {
                print("authVC presented for logged out user")
                self.present(authVC, animated: true, completion: nil)
            }
        } else {
            print("User is already logged in")
        }
    }

    /*
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DownloadsViewController")
        self.getDownloadedShows()
        if let authVC = self.authUI?.authViewController() {
            authUI = FUIAuth.defaultAuthUI()
            if let authVC = self.authUI?.authViewController() {
                print("authVC")
                self.present(authVC, animated: true, completion: nil)
                // self.show(authVC, sender: self)
            }
            else {
                print("User is already logged in")
            }
        }
        
      //\  self.title = DeepLinkManager.shared.deepLinkURL?.absoluteString
    }
    */
    
    
    @objc func signOutTapped() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            // After sign out, perhaps return to the login screen or perform other appropriate actions
            print("User signed out successfully")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    func listFiles() {
        do {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let files = try fileManager.contentsOfDirectory(atPath: urls[0].path)
            print(files)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }
    
    func checkTracksAndRemove(show: ShowMetadataModel) -> Bool {
        guard let mp3s = show.mp3Array else { return false }
        for song in mp3s {
            if let trackURL = self.player.trackURLfromName(name: song.name) {
                do {
                    let _ = try trackURL.checkResourceIsReachable()
                    //print(available)
                }
                catch {
                    print(error)
                    return false
                }
            }
        }
        return true
    }


    func getDownloadedShows() {
        network.getAllDownloadDocs(decade: nil) {
            (response: [ShowMetadataModel]?) -> Void in
            DispatchQueue.main.async{
                if let r = response {
                    self.shows = r
                    if let ss = self.shows {
                        for s in ss {
                            if !self.checkTracksAndRemove(show: s) {
                                self.network.removeDownloadDataDoc(docID: s.metadata?.identifier) // use callback
                            }
                        }
                        self.shows = ss.sorted(by: { self.utils.getDateFromDateString(datetime: $0.metadata?.date!)! < self.utils.getDateFromDateString(datetime: $1.metadata?.date!)! })
                    }
                }
                self.showListTableView.reloadData()
            }
        }
    }

    func deleteSongs(row: Int) {
        guard let mp3s = self.shows?[row].mp3Array else { return }
        for mp3 in mp3s {
            if let localURL = self.player.trackURLfromName(name: mp3.name) {
                if fileManager.fileExists(atPath: localURL.path) {
                    do {
                        try fileManager.removeItem(atPath: localURL.path)
                        print("Deleted \(localURL.path)")
                    }
                    catch {
                        print("Can't delete")
                    }
                }
            }
        }
    }

    func deleteShow(row: Int) {
        guard let _ = self.shows else { return }
        deleteSongs(row: row)
        self.network.removeDownloadDataDoc(docID: self.shows?[row].metadata?.identifier)
        self.shows?.remove(at: row)
        self.getDownloadedShows()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let s = self.shows {
            return s.count
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = showListTableView.dequeueReusableCell(withIdentifier: "ShowListCell", for: indexPath) as! ShowsListTableViewCell

        if let showMDs = self.shows {
            cell.dateLabel.text = showMDs[indexPath.row].metadata?.date
            
            if let v = showMDs[indexPath.row].metadata?.venue, let c = showMDs[indexPath.row].metadata?.coverage {
                cell.venueLabel.text = v + ", " + c
            }
            else {
                cell.venueLabel.text = showMDs[indexPath.row].metadata?.venue
            }
            cell.transfererLabel.text = showMDs[indexPath.row].metadata?.transferer
            cell.sourceLabel.text = showMDs[indexPath.row].metadata?.source
            //print(showMDs[indexPath.row].metadata!)
            if let s = showMDs[indexPath.row].metadata!.avg_rating {
                print("Passed this test")
                var starRating = String(s)
                starRating = starRating + " stars " + String(showMDs[indexPath.row].metadata!.num_reviews!) + " ratings"
                cell.starsLabel.text = starRating
            }
            else {
                cell.starsLabel.text = ""
            }

        }
        else {
            cell.venueLabel.text = "No show"
        }
        
        return cell
  }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteShow(row: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let mp = segue.destination as? MiniPlayerViewController {
            self.miniPlayer = mp
            print("Set the miniplayer")
            //if let p = self.player {
                mp.player = self.player // There needs to be a player already for this to work. Need to inject it.
            //}
        }
        
        guard let indexPath = showListTableView.indexPathForSelectedRow else { return }
        if let target = segue.destination as? ShowViewController, let showMDs = self.shows {
            //target.identifier = showMDs[indexPath.row].metadata?.identifier
            //target.showDate = showMDs[indexPath.row].metadata?.date
            target.showMetadata = showMDs[indexPath.row].metadata
            target.showMetadataModel = showMDs[indexPath.row]
            target.showType = .downloaded
            // target.player = player
            target.prevController = self
            target.db = db
        }
        
        else {
            print("Nope")
        }
        
    }
}

