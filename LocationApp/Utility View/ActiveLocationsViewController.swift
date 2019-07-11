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
    
    var recents = [CKRecord]()
    var locdescription = ""
    var QRCode = ""
    var collected:Int = 0
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        
        //Table View SetUp
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh Locations")
        //this query will populate the tableView when the table is pulled.
        refreshControl.addTarget(self, action: #selector(queryDatabase), for: .valueChanged)
        self.tableView.refreshControl = refreshControl

        //populate the table view after querying into newest to oldest data.
        queryDatabase()  //this query will populate the tableView when the view loads.
        
        self.tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "QRCell", for: indexPath)
        tableView.numberOfRows(inSection: recents.count)
        tableView.rowHeight = 60
        
        if recents[indexPath.row].value(forKey: "QRCode") as? String != nil {
            self.QRCode = recents[indexPath.row].value(forKey: "QRCode") as! String
        }
        
        if recents[indexPath.row].value(forKey: "locdescription") as? String != nil {
            self.locdescription = recents[indexPath.row].value(forKey: "locdescription") as! String
        }
        
        cell.textLabel?.text = "\(self.QRCode)\n\(locdescription)"
        cell.textLabel?.numberOfLines = 0
        
        self.QRCode = ""
        self.locdescription = ""
        self.collected = 0
        
        return cell
    }
    
    @objc func queryDatabase() {
        
        var records = [CKRecord]()
        let flag = 1
        let predicate = NSPredicate(format: "active = %d", flag)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1000
        
        operation.recordFetchedBlock = { (record: CKRecord) in
            records.append(record)
        }
        
        operation.queryCompletionBlock = { (cursor: CKQueryOperation.Cursor?, error: Error?) in
            self.recents = records
            DispatchQueue.main.async {
                if self.tableView != nil {
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
            } //end async
        }
        
        database.add(operation)

    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
