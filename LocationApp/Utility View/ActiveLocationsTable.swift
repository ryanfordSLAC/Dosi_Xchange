//
//  ActiveLocationsViewController.swift
//  LocationApp
//
//  Created by Choi, Helen B on 7/1/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import UIKit
import CloudKit


class ActiveLocationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let database = CKContainer.default().publicCloudDatabase
    let dispatchGroup = DispatchGroup()
    
    var segment:Int = 0
    var recents = [[CKRecord]]()
    var locdescription = ""
    var QRCode = ""
    var collected:Int = 0
    
    @IBOutlet weak var activesTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        activesTableView.delegate = self
        activesTableView.dataSource = self
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
        // this query will populate the tablea when the table is pulled.
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
        return recents[segment].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        dispatchGroup.wait()
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "QRCell", for: indexPath)
        
        activesTableView.numberOfRows(inSection: recents[segment].count)
        activesTableView.rowHeight = 60
        
        
        if recents[segment][indexPath.row].value(forKey: "QRCode") as? String != nil {
            self.QRCode = recents[segment][indexPath.row].value(forKey: "QRCode") as! String
        }
        
        if recents[segment][indexPath.row].value(forKey: "locdescription") as? String != nil {
            self.locdescription = recents[segment][indexPath.row].value(forKey: "locdescription") as! String
        }
        
        cell.textLabel!.font = UIFont(name: "Arial", size: 16)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textLabel?.text = "\(self.QRCode)\n\(locdescription)"
        
        self.QRCode = ""
        self.locdescription = ""
        self.collected = 0
        
        return cell
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//        performSegue(withIdentifier: "manageSegue", sender: self)
//    }
    
}

// query and helper functions
extension ActiveLocationsViewController {
    
    @objc func queryDatabase() {
        
        dispatchGroup.enter()
        recents = [[CKRecord]]()
        recents.append([CKRecord]())
        recents.append([CKRecord]())

        let predicate = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "QRCode", ascending: true)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort]
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
        
        let activeFlag:Int = record["active"]!
        var flag = 0
        if activeFlag == 0 { flag = 1 }
        recents[flag].append(record)
        
    } // end func
    
}
