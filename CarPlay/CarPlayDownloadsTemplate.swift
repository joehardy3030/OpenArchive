//
//  CarPlayDownloadsTemplate.swift
//  Breaze
//
//  Created by Joseph Hardy on 1/13/21.
//  Copyright © 2021 Carquinez. All rights reserved.
//

import UIKit
import AVFoundation
import CarPlay
import MediaPlayer

@available(iOS 14.0, *)
class CarPlayDownloadsTemplate: NSObject, CPInterfaceControllerDelegate {

    // Thin "select → engine → Now Playing" adapter. Remote commands, Now Playing
    // info and playback state are all owned by AudioPlayerArchive.
    let interfaceController: CPInterfaceController
    var shows: [ShowMetadataModel]?
    var selectedShow: ShowMetadataModel?
    let network = NetworkUtility()
    let utils = Utils()
    let player = AudioPlayerArchive.shared
    
    // Keep a strong reference to self while active
    private var selfRetainer: CarPlayDownloadsTemplate?
    
    init(interfaceController: CPInterfaceController, decade: String?, year: String?, selectedShow: ShowMetadataModel? = nil) {
        self.interfaceController = interfaceController
        super.init()
        self.selfRetainer = self // Retain self while active
        self.interfaceController.delegate = self
        
        // If a show is pre-selected, play it directly
        if let show = selectedShow {
            self.selectedShow = show
            self.playShow()
        } else {
            // Otherwise, load shows by decade/year as before
            self.getDownloadedShows(decade: decade, year: year)
        }
    }
    
    func getDownloadedShows(decade: String?, year: String?) {
        network.getAllDownloadDocs(decade: decade) {
            (response: [ShowMetadataModel]?) -> Void in
            DispatchQueue.main.async{
                if let r = response {
                    // Filter by year if specified
                    if let year = year {
                        self.shows = r.filter { show in
                            if let dateString = show.metadata?.date {
                                let date = self.utils.getDateFromDateString(datetime: dateString)
                                let calendar = Calendar.current
                                let showYear = calendar.component(.year, from: date ?? Date())
                                return String(showYear) == year
                            }
                            return false
                        }
                    } else {
                    self.shows = r
                    }
                    if let ss = self.shows {
                        for s in ss {
                            if !self.checkTracksAndRemove(show: s) {
                                self.network.removeDownloadDataDoc(docID: s.metadata?.identifier) // use callback
                                print(s)
                            }
                        }
                        self.shows = ss.sorted(by: { self.utils.getDateFromDateString(datetime: $0.metadata?.date!)! < self.utils.getDateFromDateString(datetime: $1.metadata?.date!)! })
                    }
                }
                self.createDownloadsCPList()
            }
        }
    }
    
    func checkTracksAndRemove(show: ShowMetadataModel) -> Bool {
        guard let mp3s = show.mp3Array else { return false }
        for song in mp3s {
            if let trackURL = utils.trackURLfromName(name: song.name) {
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
    
    func createDownloadsCPList() {
        var items = [CPListItem]()
        guard let shows = self.shows else { return }
        
        for s in shows {
            let item = CPListItem(text: s.metadata?.date, detailText: s.metadata?.coverage)
            item.handler = { [weak self] (item, completion: () -> Void) in
                guard let self = self else {
                    completion()
                    return
                }
                print(item.description)
                self.selectedShow = s
                self.playShow()
                completion()
            }
            items.append(item)
        }
                
        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: "My Tapes", sections: [section])
        Task {
            try? await self.interfaceController.pushTemplate(listTemplate, animated: true)
        }
    }
    
    func playShow() {
        guard let show = selectedShow else {
            print("No show selected")
            return
        }
        // Tapping the show that's already loaded resumes where it left off
        // instead of restarting from track one; otherwise load it fresh.
        let alreadyLoaded = player.showMetadataModel?.metadata?.identifier == show.metadata?.identifier
            && player.playerQueue != nil
        if !alreadyLoaded {
            guard let mp3s = show.mp3Array, !mp3s.isEmpty else {
                print("Show has no tracks")
                return
            }
            let hasAccessibleTrack = mp3s.contains { song in
                guard let url = utils.trackURLfromName(name: song.name) else { return false }
                return (try? url.checkResourceIsReachable()) == true
            }
            guard hasAccessibleTrack else {
                print("No accessible tracks found")
                return
            }
            player.pause(persist: false)
            player.showMetadataModel = show
            player.currentShowType = .downloaded
            // Sync state to PlayerViewModel so the phone UI is in sync
            DispatchQueue.main.async {
                PlayerViewModel.shared.currentShow = show
                PlayerViewModel.shared.currentShowType = .downloaded
                PlayerViewModel.shared.isStreaming = false
            }
            player.loadQueuePlayer(tracks: mp3s)   // cleanQueue() drops the old queue
        }
        interfaceController.pushNowPlaying()
        player.play()
    }
}
