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
    
    // Pagination properties for My Tapes
    private var allDownloadedShows: [ShowMetadataModel] = []
    private var currentPage = 0
    private let itemsPerPage = 10 // Show 10 items + 1 "See more" + 1 "Show previous" = 12 total
    private var myTapesRootTemplate: CPListTemplate?
    
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
        /*
        // Create the Bands tab (decades/years)
        let bandsTemplate = createBandsTabTemplate()
        bandsTemplate.tabImage = UIImage(systemName: "music.note")
        bandsTemplate.tabTitle = "Bands"
        */
        
        // Create the My Tapes tab (downloaded shows) - load content immediately
        let myTapesTemplate = createMyTapesTabTemplate()
        myTapesTemplate.tabImage = UIImage(systemName: "icloud.and.arrow.down")
        myTapesTemplate.tabTitle = "My Tapes"
        loadDownloadedShowsForTemplate(myTapesTemplate)
        
        /*
        // Create the tab bar template
        let tabBarTemplate = CPTabBarTemplate(templates: [myTapesTemplate, bandsTemplate])
        
        // Set as root template
        self.interfaceController?.setRootTemplate(tabBarTemplate, animated: true) { success, error in
            print("Set root template success: \(success)")
            if let error = error {
                print("Set root template error: \(error)")
            }
        }
        */
        
        // Set MyTapes as the root template directly (without tabs)
        self.myTapesRootTemplate = myTapesTemplate
        Task {
            try? await self.interfaceController?.setRootTemplate(myTapesTemplate, animated: true)
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
        return bandsTemplate
    }
    
    private func createMyTapesTabTemplate() -> CPListTemplate {
        // Create empty template - will be populated by loadDownloadedShowsForTemplate
        let myTapesTemplate = CPListTemplate(title: "My Tapes", sections: [])
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
        // No longer needed since we load content immediately
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
    }
    
    private func loadDownloadedShowsForTemplate(_ template: CPListTemplate) {
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
                    
                    // Store all shows and reset pagination
                    self.allDownloadedShows = sortedShows
                    self.currentPage = 0
                    
                    // Create the first page
                    self.createMyTapesPage()
                } else {
                    // No shows available
                    self.allDownloadedShows = []
                    self.currentPage = 0
                    self.createMyTapesPage()
                }
            }
        }
    }
    
    private func createMyTapesPage() {
        var items = [CPListItem]()
        
        if allDownloadedShows.isEmpty {
            let noShowsItem = CPListItem(text: "No Downloaded Shows", detailText: "Download shows from the app to see them here")
            items.append(noShowsItem)
        } else {
            let startIndex = currentPage * itemsPerPage
            let endIndex = min(startIndex + itemsPerPage, allDownloadedShows.count)
            
            // Add shows for current page
            for i in startIndex..<endIndex {
                let show = allDownloadedShows[i]
                
                // Get band name following the same pattern as CarPlayDownloadsTemplate
                var bandName = ""
                if let creator = show.metadata?.creator {
                    bandName = creator
                } else if let collections = show.metadata?.collection, !collections.isEmpty {
                    bandName = collections[0]
                }
                else {
                    bandName = "Unknown Band"
                }
                
                // Use band name as main text, date and coverage as detail text
                let mainText = "\(bandName), \(show.metadata?.date ?? "Unknown Date")"
                
                // Format the detail text to include date and coverage
                var detailText = ""
                if let coverage = show.metadata?.coverage, !coverage.isEmpty {
                    detailText = "\(coverage)"
                }
                
                let item = CPListItem(text: mainText, detailText: detailText)
                item.handler = { [weak self] (item, completion: () -> Void) in
                    guard let self = self else {
                        completion()
                        return
                    }
                    print("Selected show: \(item.text ?? "Unknown")")
                    // Create a CarPlayDownloadsTemplate to handle playing this show
                    _ = CarPlayDownloadsTemplate(interfaceController: self.interfaceController, decade: nil, year: nil, selectedShow: show)
                    completion()
                }
                items.append(item)
            }
            
            // Add "See more" item if there are more shows
            if endIndex < allDownloadedShows.count {
                let remainingCount = allDownloadedShows.count - endIndex
                let seeMoreItem = CPListItem(text: "See more", detailText: "\(remainingCount) more shows")
                seeMoreItem.handler = { [weak self] (item, completion: () -> Void) in
                    guard let self = self else {
                        completion()
                        return
                    }
                    self.currentPage += 1
                    self.createMyTapesPage()
                    completion()
                }
                items.append(seeMoreItem)
            }
            
            // Add "Show previous" item if we're not on the first page
            if currentPage > 0 {
                let showPreviousItem = CPListItem(text: "Show previous", detailText: "Go back to previous shows")
                showPreviousItem.handler = { [weak self] (item, completion: () -> Void) in
                    guard let self = self else {
                        completion()
                        return
                    }
                    self.currentPage -= 1
                    self.createMyTapesPage()
                    completion()
                }
                // Insert at the beginning
                items.insert(showPreviousItem, at: 0)
            }
        }
        
        // Update the existing template's sections in place
        let section = CPListSection(items: items)
        myTapesRootTemplate?.updateSections([section])
        
        /* 
        // Original tab bar update code
        if let currentTemplate = self.interfaceController?.rootTemplate as? CPTabBarTemplate {
            var updatedTemplates: [CPTemplate] = []
            for existingTemplate in currentTemplate.templates {
                if let listTemplate = existingTemplate as? CPListTemplate, listTemplate.title == "My Tapes" {
                    updatedTemplates.append(updatedTemplate)
                } else {
                    updatedTemplates.append(existingTemplate)
                }
            }
            let updatedTabBarTemplate = CPTabBarTemplate(templates: updatedTemplates)
            self.interfaceController?.setRootTemplate(updatedTabBarTemplate, animated: false)
        }
        */
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
    
    private func loadDownloadedShowsForMyTapes() {
        // This method is no longer used but keeping for compatibility
        /* Original code for tabs
        if let currentTemplate = self.interfaceController?.rootTemplate as? CPTabBarTemplate {
            for template in currentTemplate.templates {
                if let listTemplate = template as? CPListTemplate, listTemplate.title == "My Tapes" {
                    loadDownloadedShowsForTemplate(listTemplate)
                    break
                }
            }
        }
        */
        
        // Modified version for direct template (no tabs)
        if let listTemplate = self.interfaceController?.rootTemplate as? CPListTemplate, 
           listTemplate.title == "My Tapes" {
            loadDownloadedShowsForTemplate(listTemplate)
        }
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
