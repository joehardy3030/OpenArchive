//
//  ArchiveViewController.swift
//  Breaze
//
//  Created by Joe Hardy on 6/24/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class ArchiveViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate {

    @IBOutlet weak var yearTableView: UITableView!
  //  var avAudioPlayer: AVAudioPlayer?
  //  var avPlayer: AVPlayer?
    let utils = Utils()
    //let sqlite = SQLiteManager()
    var archiveAPI = ArchiveAPI()
    var years: [Int] = []
    var identifier = "gd1990-03-30.sbd.barbella.8366.sbeok.shnf"
    var filename = "gd90-03-30d1t03multi.mp3"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.yearTableView.delegate = self
        self.yearTableView.dataSource = self
        self.years += 1965...1995
        //utils.getMemory()
    }
    
    // https://www.raywenderlich.com/6620276-sqlite-with-swift-tutorial-getting-started
    func getIARequest() {
        let url = archiveAPI.downloadURL(identifier: identifier,
                                      filename: filename)
        print("Download items \(url)")

        archiveAPI.getIARequestItems(url: url) {
            (response: Any?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                    debugPrint(r as Any)
                }
            }
        }
    }
    
    func getIADownload() {
        let url = archiveAPI.downloadURL(identifier: identifier,
                                      filename: filename)
        print("Download from \(url)")

        archiveAPI.getIADownload(url: url) {
            (response: Any?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                    debugPrint(r as Any)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.years.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = yearTableView.dequeueReusableCell(withIdentifier: "ArchiveCell", for: indexPath) as! ArchiveCell
        let year = self.years[indexPath.row]
        cell.titleLabel?.text = String(year)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var url = utils.getDocumentsDirectory()
        url?.appendPathComponent(filename)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = yearTableView.indexPathForSelectedRow else { return }
        if let target = segue.destination as? MonthViewController {
            let year = self.years[indexPath.row]
            target.year = year
        }
    }
    
    /*
    func playAudioFile(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            print("Play \(url)")
            self.avAudioPlayer = try AVAudioPlayer(contentsOf: url)
            self.avAudioPlayer?.delegate = self
            self.avAudioPlayer?.play()
        }
        catch {
            print("nope")
        }
    }
    
    func playAudioFileController(url: URL)
    {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            self.avPlayer = AVPlayer(url: url)            
            let playerViewController = AVPlayerViewController()
            playerViewController.player = self.avPlayer
            self.present(playerViewController, animated: true) {
                if let avp = self.avPlayer {
                    avp.play()
                }
            }
        }
        catch{
            print("nope")
        }
    }
    */
    
}
    
