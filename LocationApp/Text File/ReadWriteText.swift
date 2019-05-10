//
//  ReadWriteText.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 11/24/18.
//  Copyright © 2018 Ford, Ryan M. All rights reserved.
//

import Foundation
import UIKit


class readWriteText {
    
    var data:String = ""
    var messageURL:URL!
    
    func readText() {
        
        let file = "Dosi_Data" //this is the file. we will write to and read from it
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file).appendingPathExtension("csv")
            //print(fileURL)
            self.messageURL = fileURL
            do {
                
                let data = try String(contentsOf: fileURL, encoding: .utf8)
                self.data = data
                //print("from readText \(data)")
                //print(fileURL)
                
            }
                
            catch { print(error) }
            
            }
        //print("read data, \(self.data)")
        }  //end readText
    
    func writeText(someText:String) {
        
        let file = "Dosi_Data" //this is the file. we will write to and read from it
        let text = someText //pass in the text
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(file).appendingPathExtension("csv")
            self.messageURL = fileURL
            //write
                do {
                    
                    try text.write(to: fileURL, atomically: false, encoding: .utf8)
                    //print("2, Write Successful: \(text)")
                }
                    
                catch { print(error) }
            

            //read
            do {
                

                //print("fileURL: \(fileURL)")
                let data = try String(contentsOf: fileURL, encoding: .utf8)
                self.data = data
                //print("2.5 Read Successful: \(data)")
                
            } //end do
                
            catch { print(error) }
            
        }//end if let dir

        }//end write text

        
    }  //end class
    

