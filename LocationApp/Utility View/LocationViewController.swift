//
//  ViewController.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 10/3/18.
//  Copyright © 2018 Ford, Ryan M. All rights reserved.
//

import UIKit
import CoreLocation 
import CloudKit

let readWrite = readWriteText()
let save = Save()

// The LocationViewController class provides a view of the current GPS coordinates as well
// as a table view showing the data in the Location table of the CloudKit public database.

//The log data button will create a new record with the current location and a drop pin which describes
// the location.

class LocationViewController: UIViewController, CLLocationManagerDelegate {
    
    //reference to table view under Location View
    //@IBOutlet weak var tableView: UITableView!
    
    //declare variables
    var startLocation: CLLocation! //Optional handles nils; lat long course info class
    var locationManager: CLLocationManager = CLLocationManager() //start&stop delivery of events
    var latitude:String = ""
    var longitude:String = ""
    var loc:String = ""
    var QRCode:String = ""
    var collectedFlag = Int64()
    var cycle:String = ""
    var dateDeployed = Date()
    var dateCollected = Date()
    var records = [CKRecord]()
    var tvLocations = [CKRecord]()
    var tvLocation1:String = ""
    var tvLocation2:String = ""
    var tvLocation3:String = ""
    var dosimeter:String = ""
    var dosiNumber = ScannerViewController.variables.dosiNumber
    
    @IBOutlet weak var Latitude: UILabel!
    @IBOutlet weak var Longitude: UILabel!
    @IBOutlet weak var hAccuracy: UILabel!
    @IBOutlet weak var Altitude: UILabel!
    @IBOutlet weak var vAccuracy: UILabel!
    @IBOutlet weak var Distance: UILabel!
    @IBOutlet weak var btnDist: UIButton!

    let database = CKContainer.default().publicCloudDatabase  //establish database

    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.Distance.text = String(0)
        //Location Manager Setup
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self //establish view controller as delegate
        startLocation = nil
        
/*** DELETED TABLE VIEW ***
        //Table View SetUp
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh Locations")
        //this query will populate the tableView when the table is pulled.
        refreshControl.addTarget(self, action: #selector(queryDatabase), for: .valueChanged)
        self.tableView.refreshControl = refreshControl
        
        
        //populate the table view after querying into newest to oldest data.
        queryDatabase()  //this query will populate the tableView when the view loads.
        self.tableView.reloadData()
  *** DELETED TABLE VIEW ***/
        
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

    } //end view did load
    
    @IBAction func resetDistance(_ sender: Any) {
        //Sets distance label to zero
        startLocation = nil
        
    } //end reset Distance

    
    //didupdatelocations:  (protocol stub) tells the delegate that new location data is available.
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        Latitude.text = String(format: "%.4f", latestLocation.coordinate.latitude)
        Latitude.font = UIFont(name: "courier", size: 17)
        Longitude.text = String(format: "%.4f", latestLocation.coordinate.longitude)
        Longitude.font = UIFont(name: "courier", size: 17)
        hAccuracy.text = String(format: "%.1f", latestLocation.horizontalAccuracy)
        hAccuracy.font = UIFont(name: "courier", size: 17)
        Altitude.text = String(format: "%.1f", latestLocation.altitude)
        Altitude.font = UIFont(name: "courier", size: 17)
        vAccuracy.text = String(format: "%.1f", latestLocation.verticalAccuracy)
        vAccuracy.font = UIFont(name: "courier", size: 17)
        

        if startLocation == nil {
            startLocation = latestLocation
        } //end if
    
        let distanceBetween: CLLocationDistance = latestLocation.distance(from: startLocation)
        let distanceBetweenFormatted = String(format: "%.2f", distanceBetween)
        Distance.text = "\(distanceBetweenFormatted) m from last reset"

        
    }  //end locationManager
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    
    } //end didFailWithError

/*** UNUSED FUNCTION
    func alert() {

        let alert = UIAlertController(title: "Type a Description", message: nil, preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.placeholder = "Describe this Location"
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let OK = UIAlertAction(title: "OK", style: .default) { (_) in
            guard let text = alert.textFields?.first?.text else { return }
            self.loc = text
            //print("Location Label text: \(text)")
            self.saveToCloud(Location: self.loc)
        }
        
        alert.addAction(OK)
        alert.addAction(cancel)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
    } //end alert
*** UNUSED FUNCTION ***/
    
} //end class

extension LocationViewController {

    @objc func queryDatabaseForCSV() {
        //set first line of text file
        //should separate text file from query
        var csvText = "Latitude, Longitude, Description, Number, QRCode, Collected Flag, Date Deployed, Date Collected, Wear Period\n"
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1000
        
        operation.recordFetchedBlock = { (record: CKRecord) in
            //Careful use of optionals to prevent crashes.
            if (record["latitude"] as? String) != nil {self.latitude = record["latitude"]!}
            if (record["longitude"] as? String) != nil {self.longitude = record["longitude"]!}
            if (record["locdescription"] as? String) != nil {self.loc = record["locdescription"]!}
            if (record["dosinumber"] as? String) != nil {self.dosimeter = record["dosinumber"]!}
            if (record["collectedFlag"] as? Int64) != nil {self.collectedFlag = record["collectedFlag"]!}
            if (record["cycleDate"] as? String) != nil {self.cycle = record["cycleDate"]!}
            if (record["QRCode"] as? String) != nil {self.QRCode = record["QRCode"]!}
            
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .none
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let date = Date(timeInterval: 0, since: record.creationDate!)
            let formattedDate = dateFormatter.string(from: date)
            let dateModified = Date(timeInterval: 0, since: record.modificationDate!)
            let formattedDateModified = dateFormatter.string(from: dateModified)
            let newline = "\(self.latitude),\(self.longitude),\(self.loc),\(self.dosimeter),\(self.QRCode),\(String(describing: self.collectedFlag)),\(formattedDate),\(String(describing: formattedDateModified)),\(self.cycle)\n"
            csvText.append(contentsOf: newline)
        }
        
        operation.queryCompletionBlock = { (cursor: CKQueryOperation.Cursor?, error: Error?) in
            csvText.append("End of File\n")
            readWrite.writeText(someText: "\(csvText)")
        }
        
        database.add(operation)
        
    } //end function
    
} //end extension


//Extension #1
/*** DELETED TABLE VIEW ***
 
extension LocationViewController: UITableViewDataSource {
    //protocol stubs
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
        
    } //end numberOfSections
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return tvLocations.count
        
    } //end tableView
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Fill the tableview with data
        
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecentCell", for: indexPath) //prototype cell = RecentCell
            tableView.numberOfRows(inSection: tvLocations.count)
            tableView.rowHeight = 50
            if tvLocations[indexPath.row].value(forKey: "QRCode") as? String != nil {
                self.tvLocation1 = tvLocations[indexPath.row].value(forKey: "QRCode") as! String
            }
            if tvLocations[indexPath.row].value(forKey: "locdescription") as? String != nil {
                self.tvLocation2 = tvLocations[indexPath.row].value(forKey: "locdescription") as! String
            }
            if tvLocations[indexPath.row].value(forKey: "dosinumber") as? String != nil {
                self.tvLocation3 = tvLocations[indexPath.row].value(forKey: "dosinumber") as! String
            }
            cell.textLabel?.text = "\(tvLocation1), \(tvLocation3), \(tvLocation2)"
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping  //word wrap the tableview data
            self.tvLocation1 = ""
            self.tvLocation2 = ""
            self.tvLocation3 = ""
            return cell
        
    } //End tableView
    
} //End Extension
 
*** DELETED TABLE VIEW ***/


/*** UNUSED FUNCTION ***

    func saveToCloud(Location: String) {

        let newRecord = CKRecord(recordType: "Location")
        //set values
        newRecord.setValue(self.Latitude.text, forKey: "latitude")
        newRecord.setValue(self.Longitude.text, forKey: "longitude")
        newRecord.setValue(self.loc, forKey: "locdescription")
        newRecord.setValue(0, forKey: "collectedFlag")

        //Check if scanner was used to capture a barcode
        if dosiNumber != "" {
            newRecord.setValue(dosiNumber!, forKey: "dosinumber")
        }
        else {
            newRecord.setValue("XXXXXXX", forKey: "dosinumber")
            
        }  //end else
        
        //save values
        database.save(newRecord) { (record, error) in
            guard record != nil else { return }
            
        } //end database Save
 
    } //end saveToCloud
 
*** UNUSED FUNCTION ***/
 
 /*** UNUSED QUERY ***
    @objc func queryDatabase() {
        
        let flag = 0
        let p1 = NSPredicate(format: "collectedFlag == %d", flag)
        let p2 = NSPredicate(format: "active == %d", 1)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        let query = CKQuery(recordType: "Location", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1000
        
        operation.recordFetchedBlock = { (record: CKRecord) in
            self.records.append(record)
        }
        
        operation.queryCompletionBlock = { (cursor: CKQueryOperation.Cursor?, error: Error?) in
            let sortedRecords = self.records.sorted(by: { $0.modificationDate! < $1.modificationDate! })
            self.tvLocations = sortedRecords
            self.records = [CKRecord]()
            
            DispatchQueue.main.async {
                if self.tableView != nil {
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
            } //end async
        }
        
        database.add(operation)

    } //end function
*** UNUSED QUERY ***/
