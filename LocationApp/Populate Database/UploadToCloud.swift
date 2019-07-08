//
//  UploadToCloud.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 1/26/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit
import UIKit


class Save {

    let database = CKContainer.default().publicCloudDatabase
    
/*  this class takes data which can be pasted into the blank file ("Populate Database")
    and writes it into an array
    The array is then parsed and pushed up into the CloudKit as CKRecords
     
    The function can be run by revising the "btnlogdata" outlet temporarily
*/
    
    
    
    func uploadToCloud() -> Array<Any> {  //probably doesn't need to return anything.
        
        var array:[[String]] = [[""]] //initialize the array
        
        do {
            let fileName = "DosiData" //change depending on which file
            let path = Bundle.main.path(forResource: fileName, ofType: "csv")  //blank file no extension
            let data = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            let rows = data.components(separatedBy: "\n")

            for row in rows {
                
                let values = row.components(separatedBy: ",")
                array.append(values)
                
            } //end for
            
        } //end do
            
        catch {
            
            print(Error.self)
            
        } //end catch

        //write to database
        
        //print(array)
        var j = 1  //first row [0] contains ""
        
        while j < array.count - 1 { //don't go too far or get fatal error, so subtract 1
            
            let newrecord = CKRecord(recordType: "Location")
            
            //csv data populated fields
            newrecord.setValue(String(array[j][0]), forKey: "QRCode") //first column, index 0
            newrecord.setValue(String(array[j][1]), forKey: "dosinumber")
            newrecord.setValue(String(array[j][2]), forKey: "latitude")
            newrecord.setValue(String(array[j][3]), forKey: "longitude")
            newrecord.setValue(String(array[j][4]), forKey: "locdescription")
            newrecord.setValue(Int64(array[j][5]), forKey: "active")
            newrecord.setValue(Int64(array[j][6]), forKey: "moderator") // seventh column, index 6
            
            //manually populated fields
            newrecord.setValue(String("1-1-2019"), forKey: "cycleDate")
            newrecord.setValue(String(""), forKey: "problemText")
            newrecord.setValue(Int64(0), forKey: "collectedFlag")
            newrecord.setValue(Int64(0), forKey: "mismatch")
            
            database.save(newrecord) { (record, error) in guard record != nil else { return }
     
            } //end database save

            
            j += 1
            
        }  //end while
    
    return array

    }//end func
    
}//end class
