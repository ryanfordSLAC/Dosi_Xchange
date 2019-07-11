//
//  NearestDosimeters.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 2/22/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//  Working from branch

import Foundation
import UIKit
import CloudKit
import CoreLocation

class NearestLocations:  UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {

    let sections = ["Sorted by Distance from Current Location"]
    let dispatchGroup = DispatchGroup()
    let recordsupdate = recordsUpdate()
    var count = Int()
    var records = [CKRecord]()
    var locationManager:CLLocationManager = CLLocationManager()
    var startLocation: CLLocation!
    var latitude:String = ""
    var longitude:String = ""
    var distance:Int = 0
    var loc:String = ""
    var QRCode:String = ""
    var dosimeter:String = ""
//***
    //var problemText:String? = ""
    
    var arrayString:String = ""
    var line = [String]()
    var preSortedRecords = [(Int, String, String, String)]()
    var sortedRecords = [(Int, String, String, String)]()
    let database = CKContainer.default().publicCloudDatabase
    
    @IBOutlet weak var nearestTableView: UITableView!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        nearestTableView.delegate = self
        nearestTableView.dataSource = self
        
        //get data

        queryAscendLocations()
        dispatchGroup.notify(queue: .main){  //need to slow this down to return a value > 0
            self.nearestTableView.reloadData()
            
        }//end dispatch
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh Locations")
        //this query will populate the tableView when the table is pulled.
        refreshControl.addTarget(self, action: #selector(queryAscendLocations), for: .valueChanged)
        refreshControl.beginRefreshing()
        self.nearestTableView.refreshControl = refreshControl
        
        //Core Location
        locationManager.delegate = self
        startLocation = nil
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        
    } //end view did load

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        dispatchGroup.enter()
        queryAscendLocations()
        
        run(after: 1) {
            self.dispatchGroup.leave()
           //self.problemReportMessage(indexPath: indexPath)
        }

    } //end Table View
    
    //location manager stubs
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //start location is needed to compute distance
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        if startLocation == nil {
            startLocation = latestLocation
        }
        
    }//end func
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(Error.self)
    }//end func
    
    //tableView protocol stubs
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //"sorted by distance from current location"
        return sections[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //counts the number of CK records
        return self.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "PlainCell", for: indexPath)

        nearestTableView.numberOfRows(inSection: self.count)
        nearestTableView.rowHeight = 80  //accomodate 4 lines of data
        
        // Depending on the section, fill the textLabel with the relevant text
        
        dispatchGroup.notify(queue: .main){ //wait for the query results
            
            //unpack
            let distance = "\(self.sortedRecords[indexPath.row].0)"
            let QRCode =  "\(self.sortedRecords[indexPath.row].1)"
            let dosimeter = "\(self.sortedRecords[indexPath.row].2)"
            let location = "\(self.sortedRecords[indexPath.row].3)"
            //recombine the string
            let row = ("\(distance) meters\n\(QRCode), \(dosimeter)\n\(location)")
            cell.textLabel!.font = UIFont(name: "Arial", size: 16)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
            cell.textLabel?.text = row
            
        }//end dispatch group
        
        return cell
        
    } //end function
    
}  //end class

extension NearestLocations {
    
    @objc func queryAscendLocations() {
        
        //clear out buffer
        self.preSortedRecords = [(Int, String, String, String)]()
        self.sortedRecords = [(Int, String, String, String)]()
        
        dispatchGroup.enter()
        let cycleDate = self.recordsupdate.generateCycleDate()
        let priorCycleDate = self.recordsupdate.generatePriorCycleDate(cycleDate: cycleDate)
        let flag = 0
        let p1 = NSPredicate(format: "collectedFlag == %d", flag)
        let p2 = NSPredicate(format: "cycleDate == %@", priorCycleDate)
        let p3 = NSPredicate(format: "active == %d", 1)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2, p3])
        let query = CKQuery(recordType: "Location", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1000
        
        operation.recordFetchedBlock = { (record: CKRecord) in
            
            if record["latitude"] != nil {self.latitude = record["latitude"]!}
            if record["longitude"] != nil {self.longitude = record["longitude"]!}
            if record["QRCode"] != nil {self.QRCode = record["QRCode"]!}
            if record["dosinumber"] != nil {self.dosimeter = record["dosinumber"]!}
            if record["locdescription"] != nil {self.loc = record["locdescription"]!}
            
            //compute distance between start location and the point
            let rowCoordinates1 = CLLocation(latitude: Double(self.latitude)!, longitude: Double(self.longitude)!)
            let distanceBetween: CLLocationDistance = self.startLocation.distance(from: rowCoordinates1)
            let distanceBetweenFormatted = String(format: "%.0f", distanceBetween)
            self.distance = Int(distanceBetweenFormatted)!
            //use the getLine function below to create a tuple with multiple types
            //in order to be able to sort by distance as an integer (not a string).
            let line = self.getLine(distance: self.distance, QRCode: self.QRCode, dosimeter: self.dosimeter, detail: self.loc)
            //build the array
            self.preSortedRecords.append(line)
            
        }
        
        operation.queryCompletionBlock = { (cursor: CKQueryOperation.Cursor?, error: Error?) in
            
            self.count = self.preSortedRecords.count
            //sort the completed array by integer, which is first element in the tuple
            self.sortedRecords = self.preSortedRecords.sorted { $0.0 < $1.0 }
            
            DispatchQueue.main.async {
                if self.nearestTableView != nil {  //key to fast refresh without delays.
                    self.nearestTableView.refreshControl?.endRefreshing()
                    self.nearestTableView.reloadData()
                } //end if
            }  //end async
        }
        
        database.add(operation)
        
        self.run(after: 2) {
            self.dispatchGroup.leave()
        }

    } //end func

    //supply a line with the correct data types.  Distance must be an integer for correct sorting.
    func getLine(distance: Int, QRCode: String, dosimeter: String, detail: String) -> (distance: Int, QRCode: String, dosimeter: String, detail: String) {
        
        let distance = self.distance
        let QRCode = self.QRCode
        let dosimeter = self.dosimeter
        let detail = self.loc
        //let problemText = self.problemText
        
        return (distance, QRCode, dosimeter, detail)//, problemText ?? "None")
    }
    
    func run(after seconds: Int, completion: @escaping () -> Void) {  //delay function when we need to wait for query output
        let deadline = DispatchTime.now() + .seconds(seconds)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            completion()
            
        }//end let
        
    }//end func
    
} //end extension
    
//*** UNUSED CODE ***

//    func saveProblemReport(dosiNumber: String){
//        //use the properties of the class and save into the database.
//        //save data to database
//        //need a second saveRecord method to save the QR Code.
//
//
//            let predicate = NSPredicate(format: "dosinumber = %@", dosiNumber)
//            let query = CKQuery(recordType: "Location", predicate: predicate)
//            database.perform(query, inZoneWith: nil) { (records, _) in
//                guard let records = records else { return }
//
//                for record in records {
//                    //save the problemText only
//                    print("Saving this value: \(String(describing: self.problemText))")
//                    record.setValue(self.problemText, forKey: "problemText")
//                    self.database.save(record) { (record, error) in
//                        guard record != nil else { return }
//                    }  //end database save
//                } //end for
//            }//end query
//    }  //end saveProblemReport

    
//    func problemReportMessage(indexPath: IndexPath) {
//        dispatchGroup.enter()
//        let dosiNumber = self.sortedRecords[indexPath.row].2
//        let dosimeter = "Create Problem Report\n\(dosiNumber)"
//        let problemText = self.problemText
//        let title = "Missing dosimeter\nMissing QR Code\nExtra Dosimeter\nDamaged Dosimeter\nOther"
//        let alert = UIAlertController(title: dosimeter, message: title, preferredStyle: .alert)
//            let OK = UIAlertAction(title: "OK", style: .default) { (_) in
//                //print("Alert: \(String(describing: alert.textFields?.first?.text))")
//                //self.problemText = alert.textFields?.first?.text
//                print("OK/Alert:\(String(describing: problemText))")
//                self.saveProblemReport(dosiNumber: dosiNumber)
//            }
//        alert.setValue(NSAttributedString(string: alert.title!, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium), NSAttributedString.Key.foregroundColor : UIColor.white]), forKey: "attributedTitle")
//        alert.setValue(NSAttributedString(string: alert.message!, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.light), NSAttributedString.Key.foregroundColor : UIColor.white]), forKey: "attributedMessage")
//            alert.addTextField { (textfield) in
//                print("alert.addTextField \(String(describing: self.problemText))")
//                if problemText != "" || (problemText != nil) {
//
//                    textfield.text = problemText //assign self.description with the textfield information
//
//                } //end if
//
//                else {
//
//                     //assign self.description with the textfield information
//                    textfield.placeholder = "Type or dictate location details"
//                } //end else
//
//            }//end addTextField
//
//        alert.addAction(OK)
//        alert.view.tintColor = UIColor.white
//        self.present(alert, animated: true)
//        let subview = (alert.view.subviews.first?.subviews.first?.subviews.first!)! as UIView
//        subview.layer.cornerRadius = 1
//        subview.backgroundColor = UIColor(red: (163/255.0), green: (1/255.0), blue: (1/255.0), alpha: 1.0)
//        //subview.backgroundColor = UIColor(ciColor: .magenta)
//
//        let selectedCell:UITableViewCell = nearestTableView.cellForRow(at: indexPath)!
//
//        if selectedCell.accessoryType == .checkmark {
//        selectedCell.accessoryType = .none
//        }
//
//        else
//        {
//        selectedCell.accessoryType = .checkmark
//        }
//
//            run(after: 1){
//                self.dispatchGroup.leave()
//
//            }
//
//
//    }//end problemReportMessage

//*** UNUSED CODE ***
