//
//  Utils.swift
//  Breaze
//
//  Created by Joe Hardy on 5/20/18.
//  Copyright © 2018 Carquinez. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class Utils {

    func switchConditionsText(icon: String) -> String {
        var conditions: String
        switch icon {
        case "clear":
            conditions = "Clear"
        case "rain":
            conditions = "Rain"
        case "chancerain":
            conditions = "Chance of Rain"
        case "tstorms":
            conditions = "Thunder Storms"
        case "mostlycloudy":
            conditions = "Mostly Cloudy"
        case "partlycloudy":
            conditions = "Partly Cloudy"
        case "cloudy":
            conditions = "Cloudy"
        case "fog":
            conditions = "Fog"
        default:
            conditions = icon
        }
     return conditions
    }
    
    func switchConditionsImage(icon: String) -> UIImage {
        var iconImage: UIImage
        switch icon {
        case "clear":
            iconImage = UIImage(named: icon)!
        case "rain":
            iconImage = UIImage(named: icon)!
        case "chancerain":
            iconImage = UIImage(named: "rain")!
        case "tstorms":
            iconImage = UIImage(named: "rain")!
        case "mostlycloudy":
            iconImage = UIImage(named: icon)!
        case "partlycloudy":
            iconImage = UIImage(named: icon)!
        case "cloudy":
            iconImage = UIImage(named: icon)!
        case "fog":
            iconImage = UIImage(named: icon)!
        default:
            iconImage = UIImage(named: "cloudy")!
        }
        return iconImage
    }
    
    func convertKtoF(kelvin: Double?) -> Double? {
        var farenheight: Double? = nil
        if let k = kelvin {
            farenheight = (k - 273.15) * (9.0/5.0) + 32.0
        }
        return farenheight
    }
    
    func getDayOfWeek() -> String? {
        let today = Date()
        let myCalendar = Calendar(identifier: .gregorian)
        let numDay = myCalendar.component(.weekday, from: today)
        switch numDay {
        case 1:
            return "Sunday"
        case 2:
            return "Monday"
        case 3:
            return "Tuesday"
        case 4:
            return "Wednesday"
        case 5:
            return "Thursday"
        case 6:
            return "Friday"
        case 7:
            return "Saturday"
        default:
            return "Today"
        }
    }

    static func windDirName(num: Double?) -> String? {
        if let num = num {
            switch num {
            case 0..<45:
                return "N"
            case 45..<135:
                return "E"
            case 135..<225:
                return "S"
            case 225..<305:
                return "W"
            case 305..<361:
                return "N"
            default:
                return nil
            }
        }
        else {return nil}
    }
    
    func convertTimeTimezone(utcTime: Int?, timezone: Int?) -> Double? {
        if let utcTime = utcTime, let timezone = timezone {
            let localTimeInt = utcTime + timezone;
            print("Local time integer \(localTimeInt)");
            return Double(localTimeInt)
        }
        else { return 0 }
    }
    
    func getDateFromDateTimeString(datetime: String?) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale.init(identifier: "en_US")
        
        if let d = datetime {
            if var dateObj = dateFormatter.date(from: d) {
                var dayComponent  = DateComponents()
                dayComponent.day = 1 // For removing one day (yesterday): -1
                dateObj = Calendar.current.date(byAdding: dayComponent, to: dateObj)!
                dateFormatter.dateFormat = "MM-dd-yyyy"
                let newDate = dateFormatter.string(from: dateObj)
                return newDate
            }
            else {
                return "" as String?
            }
        }
        
        return "" as String?
    }

    func getDateFromDateString(datetime: String?) -> Date? {
         let dateFormatter = DateFormatter()
        var date: Date?
        //dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale.init(identifier: "en_US")
        
        if let d = datetime {
            date = dateFormatter.date(from: d)
        }
        
        return date
    }

    
    func getTimerStringSeconds(seconds: Double?) -> String {
        var secondsString: String
        if let s = seconds, !s.isNaN, !s.isInfinite {
            secondsString = String(format: "%02d", Int(s) % 60)
        }
        else {
            secondsString = "00"
        }
        return secondsString
    }

    func getTimerStringMinutes(seconds: Double?) -> String {
        var minutesString: String
        if let s = seconds, !s.isNaN, !s.isInfinite {
            minutesString = String(format: "%02d", Int(s) / 60)
        }
        //let minutesString = String(format: "%02d", Int(seconds ?? 0) / 60)
        else {
            minutesString = "00"
        }
        return minutesString
    }
    
    func getTimerString(seconds: Double?) -> String {
        let secondsText = getTimerStringSeconds(seconds: seconds)
        let minutesText = getTimerStringMinutes(seconds: seconds)
        let text = "\(minutesText):\(secondsText)"
        return text
    }
    
    func getDocumentsDirectory() -> URL? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func trackURLfromName(name: String?) -> URL? {
        guard let d = getDocumentsDirectory(), let n = name else { return nil }
        let url = d.appendingPathComponent(n)
        return url
    }
    
    func getMemory() {
        var pagesize: vm_size_t = 0

        let host_port: mach_port_t = mach_host_self()
        var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        host_page_size(host_port, &pagesize)

        var vm_stat: vm_statistics = vm_statistics_data_t()
        withUnsafeMutablePointer(to: &vm_stat) { (vmStatPointer) -> Void in
            vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
                if (host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS) {
                    NSLog("Error: Failed to fetch vm statistics")
                }
            }
        }

        /* Stats in bytes */
        let mem_used: Int64 = Int64(vm_stat.active_count +
                vm_stat.inactive_count +
                vm_stat.wire_count) * Int64(pagesize)
        let mem_free: Int64 = Int64(vm_stat.free_count) * Int64(pagesize)
        print(mem_free)
        print(mem_used)
    }
    
    func getAllTheMP3s() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for f in fileURLs {
                print(f)
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }
    
    /*
    @available(iOS 13.0, *)
    func getMiniPlayerController() -> MiniPlayerViewController? {
        guard let sceneDelegate = UIApplication.shared.delegate as? SceneDelegate else { return nil }
        
        //guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        //if let vcs = appDelegate.window?.rootViewController?.children
        
        if let vcs = sceneDelegate.window?.rootViewController?.children
        {
            for vc in vcs {
                if let mp = vc as? MiniPlayerViewController {
                    return mp
                }
            }
        }
        return nil
    }
    */

}
