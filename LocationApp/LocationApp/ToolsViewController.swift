//
//  ToolsViewController.swift
//  LocationApp
//
//  Created by Choi, Helen B on 7/12/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import UIKit
import MessageUI
import CloudKit

class ToolsViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    let readwrite = readWriteText()  //make external class available locally
    let startup = StartupViewController()
    let database = CKContainer.default().publicCloudDatabase  //establish database
    
    var QRCode:String = ""
    var latitude:String = ""
    var longitude:String = ""
    var loc:String = ""
    var active:Int64 = 0
    var dosimeter:String = ""
    var collectedFlag:Int64?
    var cycle:String = ""
    var mismatch:Int64?
    

    @IBAction func emailTouchDown(_ sender: Any) {
        
        queryDatabaseForCSV() // takes up to 5 seconds
        //readwrite.readText()
        
        startup.run(after: 5) {  //wait for  seconds before sending mail, to allow prior tasks to finish.
            self.sendEmail()
        } //end run
        
    } // end func emailTouchDown
    
    
    func sendEmail() {
        
        let URL =  readwrite.messageURL
        
        //print("URL from sendEmail: \(URL!)")
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["ryanford@slac.stanford.edu", "hbchoi@slac.stanford.edu"])
            mail.setSubject("Area Dosimeter Data")
            mail.setMessageBody("The dosimeter data is attached to this e-mail.", isHTML: true)
            
            if let fileAttachment = NSData(contentsOf: URL!) {
                mail.addAttachmentData(fileAttachment as Data, mimeType: "text/csv", fileName: "Dosi_Data.csv")
            } // end if let
            
            present(mail, animated: true)
        }
            
        else {
            // show failure alert
        }
        
    } //end func sendEmail
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true)
        
    } //end func mailComposeController
    
    
    func queryDatabaseForCSV() {
        //set first line of text file
        //should separate text file from query
        var csvText = "LocationID (QRCode),Latitude,Longitude,Description,Active (0/1),Dosimeter,Collected Flag (nil/0/1),Wear Period,Date Deployed,Date Collected,Mismatch (nil/0/1)\n"
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1000 // change according to max number of records
        
        operation.recordFetchedBlock = { (record: CKRecord) in
            //Careful use of optionals to prevent crashes.
            if (record["QRCode"] as? String) != nil {self.QRCode = record["QRCode"]!}
            if (record["latitude"] as? String) != nil {self.latitude = record["latitude"]!}
            if (record["longitude"] as? String) != nil {self.longitude = record["longitude"]!}
            if (record["locdescription"] as? String) != nil {self.loc = record["locdescription"]!}
            if (record["active"] as? Int64) != nil {self.active = record["active"]!}
            if (record["dosinumber"] as? String) != nil {self.dosimeter = record["dosinumber"]!}
            if (record["collectedFlag"] as? Int64) != nil {self.collectedFlag = record["collectedFlag"]!}
            if (record["cycleDate"] as? String) != nil {self.cycle = record["cycleDate"]!}
            if (record["mismatch"] as? Int64) != nil {self.mismatch = record["mismatch"]!}
            
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .none
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let date = Date(timeInterval: 0, since: record.creationDate!)
            let formattedDate = dateFormatter.string(from: date)
            let dateModified = Date(timeInterval: 0, since: record.modificationDate!)
            let formattedDateModified = dateFormatter.string(from: dateModified)
            let newline = "\(self.QRCode),\(self.latitude),\(self.longitude),\(self.loc),\(self.active),\(self.dosimeter),\(String(describing: self.collectedFlag ?? nil)),\(self.cycle),\(formattedDate),\(formattedDateModified),\(String(describing: self.mismatch ?? nil))\n"
            csvText.append(contentsOf: newline)
            self.clear()
        }
        
        operation.queryCompletionBlock = { (cursor: CKQueryOperation.Cursor?, error: Error?) in
            csvText.append("End of File\n")
            self.readwrite.writeText(someText: "\(csvText)")
        }
        
        database.add(operation)
        
    } //end function
    
    func clear() {
        QRCode = ""
        latitude = ""
        longitude = ""
        loc = ""
        active = 0
        dosimeter = ""
        collectedFlag = nil
        cycle = ""
        mismatch = nil
    }
    
} //end class
