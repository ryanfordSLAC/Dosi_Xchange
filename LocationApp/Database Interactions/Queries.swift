//
//  Queries.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 1/30/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit


//Potentially a place to move all queries and consolidate/shrink
//some queries in their respective view controllers.

class Queries {
    var qrCode:String = ""
    var dosiNumber:String = ""
    var count = Int()
    var countA = Int()
    var countB = Int()
    let recordsupdate = recordsUpdate()
    let dispatchGroup = DispatchGroup()
    var records = [CKRecord]()
    let database = CKContainer.default().publicCloudDatabase
    
    func run(after seconds: Int, completion: @escaping () -> Void) {  //delay function when we need to wait for query output
        let deadline = DispatchTime.now() + .seconds(seconds)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            completion()
            
        }//end let
        
    }//end func
    
    func getPriorCycleCountCFNo() {
        //get current Cycle Date
        dispatchGroup.enter()
        let cycleDate = self.recordsupdate.generateCycleDate()
        let priorCycleDate = self.recordsupdate.generatePriorCycleDate(cycleDate: cycleDate)
        let flag = 0
        let p1 = NSPredicate(format: "collectedFlag == %d", flag)
        let p2 = NSPredicate(format: "cycleDate == %@", priorCycleDate)
        let p3 = NSPredicate(format: "active == %d", 1)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2, p3])

        //  Query fields in Location to set up the artwork on the drop pins
        let query = CKQuery(recordType: "Location", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1000
        
        operation.recordFetchedBlock = { (record: CKRecord) in
            self.records.append(record)
        }
        
        operation.queryCompletionBlock = { (cursor: CKQueryOperation.Cursor?, error: Error?) in
            self.countA = self.records.count
        }
        
        database.add(operation)
        
        run(after: 1) {
            //need to slow it down while it queries.
            self.dispatchGroup.leave()
        }

    } //end func
    
    func getPriorCycleCountCFYes() {
        //get current Cycle Date
        dispatchGroup.enter()
        let cycleDate = self.recordsupdate.generateCycleDate()
        let priorCycleDate = self.recordsupdate.generatePriorCycleDate(cycleDate: cycleDate)
        let flag = 1
        let p1 = NSPredicate(format: "collectedFlag == %d", flag)
        let p2 = NSPredicate(format: "cycleDate == %@", priorCycleDate)
        let p3 = NSPredicate(format: "active == %d", 1)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2, p3])
        
        //  Query fields in Location to set up the artwork on the drop pins
        let query = CKQuery(recordType: "Location", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1000
        
        operation.recordFetchedBlock = { (record: CKRecord) in
            self.records.append(record)
        }
        
        operation.queryCompletionBlock = { (cursor: CKQueryOperation.Cursor?, error: Error?) in
            self.countB = self.records.count
        }
        
        database.add(operation)
     
        run(after: 1) {
            //need to slow it down while it queries.
            self.dispatchGroup.leave()
        }
        
    } //end func
    
} //end class

