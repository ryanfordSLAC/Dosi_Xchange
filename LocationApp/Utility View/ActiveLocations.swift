//
//  ActiveLocationsViewController.swift
//  LocationApp
//
//  Created by Choi, Helen B on 7/1/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import UIKit
import CloudKit


class ActiveLocations: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    let database = CKContainer.default().publicCloudDatabase
    let dispatchGroup = DispatchGroup()
    
    var segment:Int = 0
    var displayInfo = [[(CKRecord, String, String)]]()
    var checkQR = ""
    var searches = [[(CKRecord, String, String)]]()
    var searching = false
    
    @IBOutlet weak var activesTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        activesTableView.delegate = self
        activesTableView.dataSource = self
        searchBar.delegate = self
        segment = 0
        
        // Table View SetUp

        // this query will populate the tableView when the view loads.
        queryDatabase()
        
        // wait for query to finish
        dispatchGroup.notify(queue: .main) {
            self.activesTableView.reloadData()
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh Locations")
        // this query will populate the table when the table is pulled.
        refreshControl.addTarget(self, action: #selector(queryDatabase), for: .valueChanged)
        self.activesTableView.refreshControl = refreshControl
        
    } // end viewDidLoad
    
    
    @IBAction func tableSwitch(_ sender: UISegmentedControl) {
        segment = sender.selectedSegmentIndex
        activesTableView.reloadData()
    }
    
    // table functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searching ? searches[segment].count : displayInfo[segment].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        dispatchGroup.wait()
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "QRCell", for: indexPath)
        
        activesTableView.estimatedRowHeight = 60
        activesTableView.rowHeight = UITableView.automaticDimension
        
        let QRCode = searching ? searches[segment][indexPath.row].1 : displayInfo[segment][indexPath.row].1
        let locdescription = searching ? searches[segment][indexPath.row].2 : displayInfo[segment][indexPath.row].2
        
        // format cell title
        cell.textLabel?.font = UIFont(name: "Arial", size: 16)
        cell.textLabel?.text = "\(QRCode)"
        // format cell subtitle
        cell.detailTextLabel?.font = UIFont(name: "Arial", size: 12)
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.detailTextLabel?.text = "\(locdescription)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "LocationDetails") as! LocationDetails
        vc.record = displayInfo[segment][indexPath.row].0
        self.present(vc, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let segment0 = displayInfo[0].filter({$0.1.lowercased().prefix(searchText.count) == searchText.lowercased()})
        let segment1 = displayInfo[1].filter({$0.1.lowercased().prefix(searchText.count) == searchText.lowercased()})
        searches = [segment0, segment1]
        
        searching = true
        activesTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchBar.text = ""
        searchBar.endEditing(true)
        activesTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
}

// query and helper functions
extension ActiveLocations {
    
    @objc func queryDatabase() {
        
        dispatchGroup.enter()
        // reset array
        displayInfo = [[(CKRecord, String, String)]]()
        displayInfo.append([(CKRecord, String, String)]())
        displayInfo.append([(CKRecord, String, String)]())
        
        let predicate = NSPredicate(value: true)
        let sort1 = NSSortDescriptor(key: "QRCode", ascending: true)
        let sort2 = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort1, sort2]
        let operation = CKQueryOperation(query: query)
        addOperation(operation: operation)

    } // end function
    
    
    // add query operation
    func addOperation(operation: CKQueryOperation) {
        operation.resultsLimit = 200 // max 400; 200 to be safe
        operation.recordFetchedBlock = self.recordFetchedBlock // to be executed for each fetched record
        operation.queryCompletionBlock = self.queryCompletionBlock // to be executed after each query (query fetches 200 records at a time)
        
        database.add(operation)
    } // end func
    
    
    // to be executed after each query (query fetches 200 records at a time)
    func queryCompletionBlock(cursor: CKQueryOperation.Cursor?, error: Error?) {
        if let error = error {
            print(error)
            return
        }
        if let cursor = cursor {
            let operation = CKQueryOperation(cursor: cursor)
            addOperation(operation: operation)
            return
        }

        DispatchQueue.main.async {
            if self.activesTableView != nil {
                self.activesTableView.refreshControl?.endRefreshing()
                self.activesTableView.reloadData()
            }
        }
        dispatchGroup.leave()
    } // end func
    
    
    // to be executed for each fetched record
    func recordFetchedBlock(record: CKRecord) {
        
        // if record is active ("active" = 1), record is appended to the first array (flag = 0)
        // else record is appended to the second array (flag = 1)
        let flag = record["active"]! == 1 ? 0 : 1
        
        // fetch QRCode and locdescription
        let currentQR:String = record["QRCode"]!
        let currentLoc:String = record["locdescription"]!
        
        // if QRCode is not the same as previous record
        if currentQR != self.checkQR {
            // append (QRCode, locdescription) tuple displayInfo
            displayInfo[flag].append((record, currentQR, currentLoc))
        }
        
        self.checkQR = currentQR
        
        
    } // end func
    
}
