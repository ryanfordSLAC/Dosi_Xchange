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
    var active = 0
    
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
    
    //popup outlets
    @IBOutlet weak var popupConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundButton: UIButton!
    @IBOutlet weak var editRecordPopup: UIView!
    
    @IBOutlet weak var dateCreated: UILabel!
    @IBOutlet weak var dateModified: UILabel!
    
    @IBOutlet weak var pQRCode: UILabel!
    @IBOutlet weak var pDescription: UITextField!
    @IBOutlet weak var pLatitude: UITextField!
    @IBOutlet weak var pLongitude: UITextField!
    @IBOutlet weak var pDosimeter: UITextField!
    @IBOutlet weak var pCycleDate: UITextField!
    
    @IBOutlet weak var pModerator: UISwitch!
    @IBOutlet weak var pCollected: UISwitch!
    @IBOutlet weak var pMismatch: UISwitch!
    
    var popupRecord = CKRecord(recordType: "Location")
    var moderator = 0
    var collected = 0
    var mismatch = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //Do any additional setup after loading the view.
        
        qrTable.delegate = self
        qrTable.dataSource = self
        
        showDetails()
        
        //pre-popup set up
        backgroundButton.alpha = 0
        editRecordPopup.layer.cornerRadius = 10
        popupConstraint.constant = 600
        pModerator.addTarget(self, action: #selector(moderatorSwitch), for: .valueChanged)
        pCollected.addTarget(self, action: #selector(collectedSwitch), for: .valueChanged)
        pMismatch.addTarget(self, action: #selector(mismatchSwitch), for: .valueChanged)
        
        pDescription.delegate = self
        pLatitude.delegate = self
        pLongitude.delegate = self
        pDosimeter.delegate = self
        pCycleDate.delegate = self
        
    }
    
    func showDetails() {
        
        //get location details from record
        QRCode = record.value(forKey: "QRCode") as! String
        loc = record.value(forKey: "locdescription") as! String
        lat = record.value(forKey: "latitude") as! String
        long = record.value(forKey: "longitude") as! String
        active = record.value(forKey: "active") as! Int
        
        //set QRCode and Location Description text
        QRLabel.text = QRCode
        locDescription.text = loc
        
        //format details fields
        let font = UIFont(name: "ArialMT", size: 16.0)!
        let fontBold = UIFont(name: "Arial-BoldMT", size: 16.0)!
        let attributedStr = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font: font])
        
        attributedStr.append(NSAttributedString(string: "Latitude: ", attributes: [NSAttributedString.Key.font: fontBold]))
        attributedStr.append(NSAttributedString(string: lat, attributes: [NSAttributedString.Key.font: font]))
        attributedStr.append(NSAttributedString(string: "\nLongitude: ", attributes: [NSAttributedString.Key.font: fontBold]))
        attributedStr.append(NSAttributedString(string: long, attributes: [NSAttributedString.Key.font: font]))
        attributedStr.append(NSAttributedString(string: "\n\nActive: ", attributes: [NSAttributedString.Key.font: fontBold]))
        
        //set details text
        fields.attributedText = attributedStr
        
        //set active switch
        activeSwitch.isOn = active == 1 ? true : false
        
        queryLocationTable()
        
        //wait for query to finish
        dispatchGroup.notify(queue: .main) {
            if self.qrTable != nil {
                self.qrTable.refreshControl?.endRefreshing()
                self.qrTable.reloadData()
            }
        }
        
    }
    
}


//active switch controls
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
            
            //wait for records to save
            self.dispatchGroup.wait()

            //refresh and show Active Locations TableView
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "ActiveLocations") as! ActiveLocations
            vc.segment = self.active == 1 ? 0 : 1
            self.show(vc, sender: self)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.activeSwitch.isOn = self.active == 1 ? true : false
        }
        
        alertPrompt.addAction(yes)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        }
    } //end saveActiveAlert
    
    func saveActiveStatus() {
        
        dispatchGroup.enter()
        
        //set active flag for all records in current location
        for record in records {
            record.setValue(active, forKey: "active")
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        
        operation.perRecordCompletionBlock = { (record, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            //print("RECORD SAVED:\n\(record)")
        }
        
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            self.dispatchGroup.leave()
        }
        
        database.add(operation)
        
        
    } //end saveActiveStatus
    
}


//table view functions and helpers
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
        
        //fetch record details
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
        
        //set cell text
        cell.textLabel?.text = "Dosimeter:\nWear Period:\nModerator:\nCollected:"
        cell.detailTextLabel?.text = "\(dosimeter)\n\(cycleDate)\n\(modFlagStr)\n\(collectedFlagStr)"
        
        return cell
        
    }
    
    //popup pop up
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        setPopupDetails(record: records[indexPath.section])
        self.popupConstraint.constant = 0
        
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.backgroundButton.alpha = 0.5
        })
    }
    
    //query for location records table
    func queryLocationTable() {
        dispatchGroup.enter()
        
        records = [CKRecord]()
        details = [(String, String, String, Int, Int)]()
        
        let predicate = NSPredicate(format: "QRCode == %@", QRCode)
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 100 //assume less than 100 records
        operation.recordFetchedBlock = self.recordFetchedBlock //to be executed for each fetched record
        operation.queryCompletionBlock = self.queryCompletionBlock //to be executed after each the query
        
        database.add(operation)
    } //end func
    
    
    //to be executed after each query (query fetches 100 records)
    func queryCompletionBlock(cursor: CKQueryOperation.Cursor?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        DispatchQueue.main.async {
            if self.qrTable != nil {
                self.qrTable.refreshControl?.endRefreshing()
                self.qrTable.reloadData()
            }
        }
        dispatchGroup.leave()
    } //end func
    
    
    //to be executed for each fetched record
    func recordFetchedBlock(record: CKRecord) {
        
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "MM/dd/yyyy, hh:mm a"
        dateFormatter.dateFormat = "M/d/yyyy"
        
        let creationDate = "Record Created: \(dateFormatter.string(from: record.creationDate!))"
        let dosimeter = record["dosinumber"] != "" ? String(describing: record["dosinumber"]!) : "n/a"
        let wearperiod = record["cycleDate"] != nil ? String(describing: record["cycleDate"]!) : "n/a"
        let collectedFlag = record["collectedFlag"] != nil ? record["collectedFlag"]! as Int : 2
        let modFlag = record["moderator"] != nil ? record["moderator"]! as Int : 2
        
        self.details.append((creationDate, dosimeter, wearperiod, modFlag, collectedFlag))
        self.records.append(record)
        
    }
    
    
    @IBAction func dismissDetails(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
}


//edit record pop-up controls
extension LocationDetails: UITextFieldDelegate {
    
    
    @IBAction func popupCancel(_ sender: Any) {
        
        popupConstraint.constant = 600
        
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.backgroundButton.alpha = 0
        })
    }
    
    @IBAction func popupSave(_ sender: Any) {
        
        savePopupRecord()
        dispatchGroup.wait()
        
        //refresh and show Active Locations TableView
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "ActiveLocations") as! ActiveLocations
        vc.segment = active == 1 ? 0 : 1
        self.show(vc, sender: self)
        
    }
    
    func savePopupRecord() {
        
        dispatchGroup.enter()
        
        //set new record information
        popupRecord.setValue(pDescription.text, forKey: "locdescription")
        popupRecord.setValue(pLatitude.text, forKey: "latitude")
        popupRecord.setValue(pLongitude.text, forKey: "longitude")
        popupRecord.setValue(pDosimeter.text, forKey: "dosinumber")
        popupRecord.setValue(pCycleDate.text, forKey: "cycleDate")
        popupRecord.setValue(moderator, forKey: "moderator")
        popupRecord.setValue(collected, forKey: "collectedFlag")
        popupRecord.setValue(mismatch, forKey: "mismatch")
        
        let operation = CKModifyRecordsOperation(recordsToSave: [popupRecord], recordIDsToDelete: nil)
        
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            //print("RECORD SAVED:\n\(records![0])")
            self.dispatchGroup.leave()
        }
        
        database.add(operation)
        
        
    } //end saveActiveStatus
    
    func setPopupDetails(record: CKRecord) {
        
        popupRecord = record
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy, h:mm a"
        //dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let creationDate = dateFormatter.string(from: record.creationDate!)
        let modifiedDate = dateFormatter.string(from: record.modificationDate!)
        dateCreated.text = "Date Created: \(creationDate)"
        dateModified.text = "Date Last Modified: \(modifiedDate)"
        
        pQRCode.text = record.value(forKey: "QRCode") as? String
        pDescription.text = record.value(forKey: "locdescription") as? String
        pLatitude.text = record.value(forKey: "latitude") as? String
        pLongitude.text = record.value(forKey: "longitude") as? String
        
        pDosimeter.text = record["dosinumber"] != "" ? String(describing: record["dosinumber"]!) : ""
        pCycleDate.text = record["cycleDate"] != nil ? String(describing: record["cycleDate"]!) : nil
        
        moderator = record["moderator"] != nil ? record["moderator"]! as Int : 0
        collected = record["collectedFlag"] != nil ? record["collectedFlag"]! as Int : 0
        mismatch = record["mismatch"] != nil ? record["mismatch"]! as Int : 0
        
        pModerator.isOn = moderator == 1 ? true : false
        pCollected.isOn = collected == 1 ? true : false
        pMismatch.isOn = mismatch == 1 ? true : false
        
    }
    
    @objc func moderatorSwitch(_ sender: UISwitch!) {
        moderator = sender.isOn ? 1 : 0
    }
    
    @objc func collectedSwitch(_ sender: UISwitch!) {
        collected = sender.isOn ? 1 : 0
    }
    
    @objc func mismatchSwitch(_ sender: UISwitch!) {
        mismatch = sender.isOn ? 1 : 0
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
}
