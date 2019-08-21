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

class NearestLocations: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {

    let sections = ["Sorted by Distance from Current Location"]
    let dispatchGroup = DispatchGroup()
    let recordsupdate = recordsUpdate()

    var locationManager:CLLocationManager = CLLocationManager()
    var startLocation: CLLocation!
    
    var latitude:String = ""
    var longitude:String = ""
    var distance:Int = 0
    var loc:String = ""
    var QRCode:String = ""
    var dosimeter:String = ""
    var mod:Int = 0
    
    var preSortedRecords = [(Int, String, String)]()
    var sortedRecords = [(Int, String, String)]()
    let database = CKContainer.default().publicCloudDatabase
    
    @IBOutlet weak var nearestTableView: UITableView!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        nearestTableView.delegate = self
        nearestTableView.dataSource = self
        
        //Core Location
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        startLocation = locationManager.location
        
        //get data
        queryAscendLocations()
        
        //wait for query to finish
        dispatchGroup.wait()
        self.nearestTableView.reloadData()

        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh Locations")
        //this query will populate the tableView when the table is pulled.
        refreshControl.addTarget(self, action: #selector(queryAscendLocations), for: .valueChanged)
        refreshControl.beginRefreshing()
        self.nearestTableView.refreshControl = refreshControl

    } //end viewDidLoad
    
    
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
    } //end func
    
    
    @IBAction func dismissNearest(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //tableView protocol stubs
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //"sorted by distance from current location"
        return sections[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedRecords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "PlainCell", for: indexPath)
        
        //dynamic cell height sizing
        nearestTableView.estimatedRowHeight = 90
        nearestTableView.rowHeight = UITableView.automaticDimension
        
        //wait for query to finish
        dispatchGroup.wait()
        
        //fill the textLabel with the relevant text
        let distance = "\(self.sortedRecords[indexPath.row].0)"
        let QRCode =  "\(self.sortedRecords[indexPath.row].1)"
        let details = "\(self.sortedRecords[indexPath.row].2)"
        
        //configure the cell
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = "\(QRCode) (\(distance) meters)"
        
        cell.detailTextLabel?.font = UIFont(name: "Arial", size: 15)
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.detailTextLabel?.text = "\(details)"
        
        return cell
        
    } //end function
    
} //end class


// query and helper functions
extension NearestLocations {
    
    @objc func queryAscendLocations() {
        
        dispatchGroup.enter()
        
        //clear out buffer
        self.preSortedRecords = [(Int, String, String)]()
        self.sortedRecords = [(Int, String, String)]()
        
        let cycleDate = self.recordsupdate.generateCycleDate()
        let priorCycleDate = self.recordsupdate.generatePriorCycleDate(cycleDate: cycleDate)
        let flag = 0
        let p1 = NSPredicate(format: "collectedFlag == %d", flag)
        let p2 = NSPredicate(format: "cycleDate == %@", priorCycleDate)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        let query = CKQuery(recordType: "Location", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        addOperation(operation: operation)
    
    } //end func
    
    
    //add operation
    func addOperation(operation: CKQueryOperation) {
        operation.resultsLimit = 200 // max 400; 200 to be safe
        operation.recordFetchedBlock = self.recordFetchedBlock // to be executed for each fetched record
        operation.queryCompletionBlock = self.queryCompletionBlock // to be executed after each query (query fetches 200 records at a time)
        
        database.add(operation)
    }
    
    
    //to be executed after each query (query fetches 200 records at a time)
    func queryCompletionBlock(cursor: CKQueryOperation.Cursor?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        if let cursor = cursor {
            let operation = CKQueryOperation(cursor: cursor)
            addOperation(operation: operation)
            return
        }
        
        self.sortedRecords = self.preSortedRecords.sorted { $0.0 < $1.0 }
        
        //refresh table
        DispatchQueue.main.async {
            if self.nearestTableView != nil {
                self.nearestTableView.refreshControl?.endRefreshing()
                self.nearestTableView.reloadData()
            }
        }
        
        dispatchGroup.leave()
    }
    
    
    //to be executed for each fetched record
    func recordFetchedBlock(record: CKRecord) {
        
        if record["QRCode"] != nil {self.QRCode = record["QRCode"]!}
        if record["latitude"] != nil {self.latitude = record["latitude"]!}
        if record["longitude"] != nil {self.longitude = record["longitude"]!}
        if record["dosinumber"] != nil {self.dosimeter = record["dosinumber"]!}
        if record["locdescription"] != nil {self.loc = record["locdescription"]!}
        if record["moderator"] != nil {self.mod = record["moderator"]!}
        
        //compute distance between start location and the point
        let rowCoordinates = CLLocation(latitude: Double(self.latitude)!, longitude: Double(self.longitude)!)
        let distanceBetween:CLLocationDistance = self.startLocation.distance(from: rowCoordinates)
        let distanceBetweenFormatted = String(format: "%.0f", distanceBetween)
        self.distance = Int(distanceBetweenFormatted)!
        
        let details = "Dosimeter: \(self.dosimeter)\nModerator: \(self.mod == 1 ? "Yes" : "No")\n\(self.loc)"
        
        //in order to be able to sort by distance as an integer (not a string).
        //let line = self.getLine(distance: self.distance, QRCode: self.QRCode, dosimeter: self.dosimeter, detail: details)
        //build the array
        self.preSortedRecords.append((distance: self.distance, QRCode: self.QRCode, detail: details))
        
    }
    
} //end extension

