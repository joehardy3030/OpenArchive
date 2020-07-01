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

class ArchiveViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var yearTableView: UITableView!
    var avAudioPlayer: AVAudioPlayer?
    var avPlayer: AVPlayer?
    let utils = Utils()
    var archiveAPI = ArchiveAPI()
    var identifier = "gd1990-03-30.sbd.barbella.8366.sbeok.shnf"
    var filename = "gd90-03-30d1t01multi.mp3"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.yearTableView.delegate = self
        self.yearTableView.dataSource = self
        //self.getIARequest()
        self.getIADownload()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func playTrack(_ sender: Any) {
        var url = utils.getDocumentsDirectory()
        url.appendPathComponent(filename)
        playAudioFileController(url: url)
    }
    //identifier=gd1990-03-30.sbd.barbella.8366.sbeok.shnf
     //filename=gd90-03-30d1t01multi.mp3
    
    // https://www.raywenderlich.com/6620276-sqlite-with-swift-tutorial-getting-started
    func getIARequest() {
        let url = archiveAPI.buildURL(queryType: .openDownload,
                                      identifier: identifier,
                                      filename: filename)
        print(url)

        archiveAPI.getIARequest(url: url) {
            (response: Any?) -> Void in
            
            DispatchQueue.main.async{
                if let r = response {
                    debugPrint(r as Any)
                }
            }
        }
    }
    
    func getIADownload() {
        let url = archiveAPI.buildURL(queryType: .openDownload,
                                      identifier: identifier,
                                      filename: filename)
        print(url)

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
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //return UITableViewCell()
        let cell = yearTableView.dequeueReusableCell(withIdentifier: "ArchiveCell", for: indexPath) as! ArchiveCell
        //let BARTCellData = self.BARTReadingArray[indexPath.row]
         
        cell.titleLabel?.text = "1970"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //if let cell = yearTableView.cellForRow(at: indexPath as IndexPath) {
        var url = utils.getDocumentsDirectory()
        url.appendPathComponent(filename)
        playAudioFile(url: url)
    }
        
    func playAudioFile(url: URL) {
        do {
            self.avAudioPlayer = try AVAudioPlayer(contentsOf: url)
            self.avAudioPlayer?.play()
        }
        catch {
            print("nope")
        }
    }
    
    func playAudioFileController(url: URL) {
        self.avPlayer = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = self.avPlayer
        self.present(playerViewController, animated: true) {
            if let avp = self.avPlayer {
                avp.play()
            }
        }
    }
    
}
    
