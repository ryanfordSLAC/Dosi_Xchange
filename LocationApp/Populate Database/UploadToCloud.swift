//
//  UploadToCloud.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 1/26/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import CloudKit



class Save {

    let database = CKContainer.default().publicCloudDatabase
    
/*  this class takes data which can be pasted into the blank file ("Populate Database")
    and writes it into an array
    The array is then parsed and pushed up into the CloudKit as CKRecords
     
    The function can be run by revising the "btnlogdata" outlet temporarily
*/
    
    
func createArrayFromCSV() -> Array<Any> {  //probably doesn't need to return anything.
    
    var array:[[String]] = [[""]] //initialize the array
    
    do {
        let fileName = "File" //change depending on which file
        let path = Bundle.main.path(forResource: fileName, ofType: nil)  //blank file no extension
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
    
    var j = 1  //first row [0] contains ""
    
    while j < array.count - 1 { //don't go too far or get fatal error, so subtract 1

        //print("Array: \(String(array[j][1]))")
        //print("Array: \(String(array[j][0])), \(String(array[j][1])), \(String(array[j][2])), \(String(describing: Int64(array[j][3]))), \(String(array[j][4]))")
        
        let newrecord = CKRecord(recordType: "QRCodeData")  // this table was deleted...change to Locations
        newrecord.setValue((String(array[j][0])), forKey: "oldCode") //first column, index 0
        newrecord.setValue((String(array[j][1])), forKey: "regionName")
        newrecord.setValue((String(array[j][2])), forKey: "facilityName")
        newrecord.setValue((Int64(array[j][3])), forKey: "facilitySequence")
        newrecord.setValue((String(array[j][4])), forKey: "QRCode") //fifth column, index 4
        
        database.save(newrecord) { (record, error) in
            guard record != nil else { return }
 
        } //end database save

        //print("Array: \(String(array[j][0])), \(String(array[j][1])), \(String(array[j][2]))")
        
        j += 1
        
    }  //end while
    
    return array

    }//end func
    
}//end class
