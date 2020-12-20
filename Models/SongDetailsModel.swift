//
//  SongDetailsModel.swift
//  Breaze
//
//  Created by Joseph Hardy on 12/20/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit

class SongDetailsModel: Codable {
    var name: String?
    var date: String?
    var venue: String?
    var track: Int?
    
    ///grabs the relevant song info given row and showMetaDataModel
    public func songDetailsFromMetadata(row: Int?, showModel: ShowMetadataModel?) {
        guard let r = row, let sm = showModel else { return }

        if let c = sm.mp3Array?.count {
            if c > 0 {
                if let songName = sm.mp3Array?[r].title {
                    self.name = songName
                }
                self.date = sm.metadata?.date
                self.venue = sm.metadata?.venue
                self.track = r + 1
            }
        }
    }
}
