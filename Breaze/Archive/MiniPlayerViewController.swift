//
//  MiniPlayerViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 7/20/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class MiniPlayerViewController: UIViewController {

    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var songLabel: UILabel!
    var showModel: ShowMetadataModel?
    var player: AudioPlayerArchive?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let d = showModel?.metadata?.date {
            songLabel.text = d
        }

        // Do any additional setup after loading the view.
    }
    
    @IBAction func playButton(_ sender: Any) {
    }
    
    @IBAction func forwardButton(_ sender: Any) {
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
