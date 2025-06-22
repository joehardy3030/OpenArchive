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
class CarPlayTemplateManager: NSObject, CPInterfaceControllerDelegate {

    let interfaceController: CPInterfaceController?
    var player: AudioPlayerArchive?
    var network: NetworkUtility!
    let utils = Utils()
    let decades = ["1960s", "1970s", "1980s", "1990s", "2000s", "2010s", "2020s"]
    let years = ["0","1","2","3","4","5","6","7","8","9"]
    let commandCenter = MPRemoteCommandCenter.shared()
    
    init(interfaceController: CPInterfaceController?) {
        self.interfaceController = interfaceController
        super.init()
        if interfaceController == nil {
            print("WARNING: interfaceController is nil!")
        } else {
            print("interfaceController initialized successfully")
        }
        self.interfaceController?.delegate = self
        self.player = AudioPlayerArchive.shared
        self.network = NetworkUtility()
        self.createTabbedInterface()
    }
    
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        return 0
    }
    
    private func createTabbedInterface() {
        // Create the Bands tab (decades/years)
        let bandsTemplate = createBandsTabTemplate()
        
        // Create the My Tapes tab (downloaded shows)
        let myTapesTemplate = createMyTapesTabTemplate()
        
        // Create the tab bar template
        let tabBarTemplate = CPTabBarTemplate(templates: [bandsTemplate, myTapesTemplate])
        
        // Set as root template
        self.interfaceController?.setRootTemplate(tabBarTemplate, animated: true) { success, error in
            print("Set root template success: \(success)")
            if let error = error {
                print("Set root template error: \(error)")
            }
        }
    }
    
    private func createBandsTabTemplate() -> CPListTemplate {
        var items = [CPListItem]()
        
        for d in decades {
            let item = CPListItem(text: d, detailText: "")
            item.handler = { [weak self] item, completion in
                if let self = self {
                    print("Selected decade: \(String(describing: item.text))")
                    let yearsTemplate = self.yearsCPListTemplate(decade: item.text)
                    print("Created years template for decade: \(String(describing: item.text))")
                    print("About to push years template")
                    self.interfaceController?.pushTemplate(yearsTemplate, animated: true) { success, error in
                        print("Push template success: \(success)")
                        if let error = error {
                            print("Push template error: \(error)")
                        }
                    }
                }
                completion()
            }
            items.append(item)
        }
                
        let section = CPListSection(items: items)
        let bandsTemplate = CPListTemplate(title: "Bands", sections: [section])
        bandsTemplate.tabBarItem = CPTabBarItem(title: "Bands", image: UIImage(systemName: "music.note"))
        return bandsTemplate
    }
    
    private func createMyTapesTabTemplate() -> CPListTemplate {
        // Create a placeholder section that will be populated when the tab is selected
        let placeholderItem = CPListItem(text: "Loading...", detailText: "")
        let placeholderSection = CPListSection(items: [placeholderItem])
        let myTapesTemplate = CPListTemplate(title: "My Tapes", sections: [placeholderSection])
        
        // Add a handler to load the actual downloaded shows when this tab is selected
        myTapesTemplate.tabBarItem = CPTabBarItem(title: "My Tapes", image: UIImage(systemName: "music.note.list"))
        
        return myTapesTemplate
    }
    
    private func yearsCPListTemplate(decade: String?) -> CPListTemplate {
        var items = [CPListItem]()
        var yearPrefix: String
        
        if let t = decade {
            print("Creating years template for decade: \(t)")
            switch t {
            case "1960s":
                yearPrefix = "196"
            case "1970s":
                yearPrefix = "197"
            case "1980s":
                yearPrefix = "198"
            case "1990s":
                yearPrefix = "199"
            case "2000s":
                yearPrefix = "200"
            case "2010s":
                yearPrefix = "201"
            case "2020s":
                yearPrefix = "202"
            default:
                yearPrefix = "200"
            }
        }
        else {
            yearPrefix = "202"
        }
        
        for y in years {
            let yearText = yearPrefix + y
            let item = CPListItem(text: yearText, detailText: "")
            item.handler = { [weak self] item, completion in
                if let self = self {
                    print("Selected year: \(String(describing: item.text))")
                    // Here we'll create a new template for shows in the selected year
                    _ = CarPlayDownloadsTemplate(interfaceController: self.interfaceController, decade: decade, year: item.text)
                }
                completion()
            }
            items.append(item)
        }
        
        let section = CPListSection(items: items)
        let yearsTemplate = CPListTemplate(title: decade ?? "Years", sections: [section])
        print("Created years template with \(items.count) items")
        
        return yearsTemplate
    }
    
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        // Check if this is the My Tapes template and load downloaded shows
        if let listTemplate = aTemplate as? CPListTemplate, listTemplate.title == "My Tapes" {
            loadDownloadedShowsForMyTapes()
        }
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
    }
    
    private func loadDownloadedShowsForMyTapes() {
        network.getAllDownloadDocs(decade: nil) { [weak self] (response: [ShowMetadataModel]?) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let shows = response {
                    // Filter out shows with missing tracks
                    let validShows = shows.filter { show in
                        return self.checkTracksAndRemove(show: show)
                    }
                    
                    // Sort by date
                    let sortedShows = validShows.sorted { (show1, show2) -> Bool in
                        guard let date1Str = show1.metadata?.date,
                              let date1 = self.utils.getDateFromDateString(datetime: date1Str) else {
                            return false
                        }
                        
                        guard let date2Str = show2.metadata?.date,
                              let date2 = self.utils.getDateFromDateString(datetime: date2Str) else {
                            return true
                        }
                        
                        return date1 < date2
                    }
                    
                    // Create list items for the shows
                    var items = [CPListItem]()
                    for show in sortedShows {
                        let item = CPListItem(text: show.metadata?.date, detailText: show.metadata?.coverage)
                        item.handler = { [weak self] (item, completion: () -> Void) in
                            guard let self = self else {
                                completion()
                                return
                            }
                            print(item.description)
                            // Create a CarPlayDownloadsTemplate to handle playing this show
                            _ = CarPlayDownloadsTemplate(interfaceController: self.interfaceController, decade: nil, year: nil, selectedShow: show)
                            completion()
                        }
                        items.append(item)
                    }
                    
                    // Update the My Tapes template
                    let section = CPListSection(items: items)
                    let myTapesTemplate = CPListTemplate(title: "My Tapes", sections: [section])
                    
                    // Find the current tab bar template and update the My Tapes tab
                    if let currentTemplate = self.interfaceController?.rootTemplate as? CPTabBarTemplate {
                        let updatedTemplates = currentTemplate.templates.map { template in
                            if let listTemplate = template as? CPListTemplate, listTemplate.title == "My Tapes" {
                                return myTapesTemplate
                            }
                            return template
                        }
                        let updatedTabBarTemplate = CPTabBarTemplate(templates: updatedTemplates)
                        self.interfaceController?.setRootTemplate(updatedTabBarTemplate, animated: true)
                    }
                }
            }
        }
    }
    
    private func checkTracksAndRemove(show: ShowMetadataModel) -> Bool {
        guard let mp3s = show.mp3Array else { return false }
        for song in mp3s {
            if let trackURL = utils.trackURLfromName(name: song.name) {
                do {
                    let _ = try trackURL.checkResourceIsReachable()
                }
                catch {
                    print(error)
                    return false
                }
            }
        }
        return true
    }
}

/*
@available(iOS 14.0, *)
extension CarPlayTemplateManager: CPInterfaceControllerDelegate {
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
    }
}
*/

@available(iOS 14.0, *)
extension CarPlayTemplateManager: CPSessionConfigurationDelegate {
    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration,
                              limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) {
    }
}
