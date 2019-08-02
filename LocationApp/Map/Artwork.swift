//
//  Artwork.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 1/9/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import MapKit
import Contacts

//Artwork class contains properties and methods for displaying the pin color & info.

class Artwork: NSObject, MKAnnotation {
    
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let cycleDate: String?
    let active: Int64
    let collected: Int64?
    let getcycleDate = recordsUpdate()
    
    
    init(title: String, locDescription: String, coordinate: CLLocationCoordinate2D, cycleDate: String, active: Int64, collected: Int64) {
        self.title = title
        self.subtitle = locDescription
        self.coordinate = coordinate
        self.cycleDate = cycleDate
        self.active = active
        self.collected = collected
        super.init()
    }
    
    
    var markerTintColor: UIColor {
        //change to cycledate
        let cycle = getcycleDate.generateCycleDate() //fetch the current cycle
        
        switch self.cycleDate { //self.cycleDate is taken from the recordsUpdate class
            
        case cycle:
            return .red  //current cycle appears as red "stop"
            
        default:
            return .green //any other cycle appears as green "go exchange it"
        
        } //end switch
        
    } //end markerTintColor
    
//    var imageName: String? { //not needed
//        if discipline == "Sculpture" { return "Statue" }
//        return "Flag"
//    }
//
//    //Annotation right callout accessory opens this mapItem in Maps app
//
//    func mapItem() -> MKMapItem {
//        let addressDict = [CNPostalAddressStreetKey: subtitle!]
//        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
//        let mapItem = MKMapItem(placemark: placemark)
//        mapItem.name = title
//        return mapItem
//    }
    
}
