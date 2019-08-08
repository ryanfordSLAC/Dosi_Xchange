//
//  LocationDetails.swift
//  LocationApp
//
//  Created by Choi, Helen B on 7/16/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import UIKit
import CloudKit


class LocationDetails: UIViewController {
    
    var record = CKRecord(recordType: "Location")
    var QRCode = ""
    var loc = ""
    var lat = ""
    var long = ""
    var mod = ""
    var active = 0
    var trigger = 0
    
    var records = [CKRecord]()
    var details = [(String, String, String, Int, Int)]()
    
    let dispatchGroup = DispatchGroup()
    let database = CKContainer.default().publicCloudDatabase
    
    @IBOutlet weak var QRLabel: UILabel!
    @IBOutlet weak var locDescription: UILabel!
    @IBOutlet weak var fields: UILabel!
    @IBOutlet weak var activeSwitch: UISwitch!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var qrTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        showDetails()
        
        qrTable.delegate = self
        qrTable.dataSource = self
        
        queryLocationTable()
        
        // wait for query to finish
        dispatchGroup.notify(queue: .main) {
            self.qrTable.reloadData()
            self.activityIndicator.stopAnimating()
        }

    }
    
    func showDetails() {
        
        // get location details from record
        QRCode = record.value(forKey: "QRCode") as! String
        loc = record.value(forKey: "locdescription") as! String
        lat = record.value(forKey: "latitude") as! String
        long = record.value(forKey: "longitude") as! String
        mod = record.value(forKey: "moderator") as! Int64 == 1 ? "Yes" : "No"
        active = record.value(forKey: "active") as! Int
        
        // set QRCode and Location Description text
        QRLabel.text = QRCode
        locDescription.text = loc
        
        // format details fields
        let font = UIFont(name: "ArialMT", size: 16.0)!
        let fontBold = UIFont(name: "Arial-BoldMT", size: 16.0)!
        let attributedStr = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font: font])
        
        attributedStr.append(NSAttributedString(string: "Latitude: ", attributes: [NSAttributedString.Key.font: fontBold]))
        attributedStr.append(NSAttributedString(string: lat, attributes: [NSAttributedString.Key.font: font]))
        attributedStr.append(NSAttributedString(string: "\nLongitude: ", attributes: [NSAttributedString.Key.font: fontBold]))
        attributedStr.append(NSAttributedString(string: long, attributes: [NSAttributedString.Key.font: font]))
        attributedStr.append(NSAttributedString(string: "\n\nActive: ", attributes: [NSAttributedString.Key.font: fontBold]))
        
        // set details text
        fields.attributedText = attributedStr
        
        // set active switch
        activeSwitch.isOn = active == 1 ? true : false
        
    }
    
}


// active switch controls
extension LocationDetails {
    
    @IBAction func activeSwitched(_ sender: Any) {
        let activeTemp = activeSwitch.isOn ? 1 : 0
        saveActiveAlert(activeTemp: activeTemp)
    }
    
    func saveActiveAlert(activeTemp: Int) {
        
        let title = activeTemp == 1 ? "Set Location to Active?" : "Set Location to Inactive?"
        
        let alertPrompt = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let yes = UIAlertAction(title: "Yes", style: .default) { (_) in
            self.active = activeTemp
            self.saveActiveStatus()
            
            // wait for records to save
            self.run(after: 1) {
                // refresh and show Active Locations TableView
                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let newViewController = mainStoryboard.instantiateViewController(withIdentifier: "ActiveLocations") as! ActiveLocations
                self.show(newViewController, sender: self)
            }
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.activeSwitch.isOn = self.active == 1 ? true : false
        }
        
        alertPrompt.addAction(yes)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        }
    } // end saveActiveAlert
    
    func saveActiveStatus() {
        
        // set active flag for all records in current location
        for record in records {
            record.setValue(active, forKey: "active")
            self.database.save(record) { (record, error) in
                guard record != nil else { return }
            }
            //print("RECORD SAVED:\n\(record)")
        }
    } // end saveActiveStatus
    
}


// table view functions and helpers
extension LocationDetails: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return details.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return details[section].0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        
        qrTable.rowHeight = 80
        
        // fetch record details
        let dosimeter = details[indexPath.section].1
        let cycleDate = details[indexPath.section].2
        let modFlagStr:String
        let collectedFlagStr:String
        
        switch details[indexPath.section].3 {
        case 0:
            modFlagStr = "No"
        case 1:
            modFlagStr = "Yes"
        default:
            modFlagStr = "n/a"
        }
        
        switch details[indexPath.section].4 {
        case 0:
            collectedFlagStr = "No"
        case 1:
            collectedFlagStr = "Yes"
        default:
            collectedFlagStr = "n/a"
        }
        
        // set cell text
        cell.textLabel?.text = "Dosimeter:\nWear Period:\nModerator:\nCollected:"
        cell.detailTextLabel?.text = "\(dosimeter)\n\(cycleDate)\n\(modFlagStr)\n\(collectedFlagStr)"
        
        return cell
        
    }
    
    func queryLocationTable() {
        dispatchGroup.enter()
        
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "MM/dd/yyyy, hh:mm a"
        dateFormatter.dateFormat = "MM/dd/yyyy"
        records = [CKRecord]()
        details = [(String, String, String, Int, Int)]()
        
        let predicate = NSPredicate(format: "QRCode == %@", QRCode)
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort]
        
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }
            
            for record in records {
                
                let modDate = "Record Created: \(dateFormatter.string(from: record.creationDate!))"
                let dosimeter = record["dosinumber"] != "" ? String(describing: record["dosinumber"]!) : "n/a"
                let wearperiod = record["cycleDate"] != nil ? String(describing: record["cycleDate"]!) : "n/a"
                let collectedFlag = record["collectedFlag"] != nil ? record["collectedFlag"]! as Int : 2
                let modFlag = record["moderator"] != nil ? record["moderator"]! as Int : 2
                
                self.details.append((modDate, dosimeter, wearperiod, modFlag, collectedFlag))
                self.records.append(record)
            }
            
        }// end perform query
        
        run(after: 1) {
            self.dispatchGroup.leave()
        }
    }
    
    
    func run(after seconds: Int, completion: @escaping () -> Void) {
        let deadline = DispatchTime.now() + .seconds(seconds)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            completion()
        }
    }// end run
    
    @IBAction func dismissDetails(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
}
