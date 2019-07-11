//
//  MapViewController.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 11/24/18.
//  Copyright © 2018 Ford, Ryan M. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CloudKit
//import Contacts


class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate  {
    
    @IBOutlet weak var MapView: MKMapView!

    
    var locationmanager = CLLocationManager()
    let database = CKContainer.default().publicCloudDatabase
    var dosimeter:String = ""
    var createdDate:Date?
    var fullTitle:String = ""
    var cycleDate = recordsUpdate()
    

    
    override func viewDidLoad() {
        
        self.locationmanager.delegate = self
        locationmanager.requestAlwaysAuthorization()
        locationmanager.startUpdatingLocation()
        let latitude = locationmanager.location?.coordinate.latitude
        let longitude = locationmanager.location?.coordinate.longitude
        self.MapView.delegate = self
        //register the ArtworkMarkerView class to reusable annotation view.
        
        MapView.register(ArtworkMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        //set initial map properties

        //let initialLocation = CLLocationCoordinate2D(latitude: 37.4203033, longitude: -122.2026842) SLAC Coordinates
        let initialLocation = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        let region = MKCoordinateRegion(center: initialLocation, latitudinalMeters: 150, longitudinalMeters: 150)
        //let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        //let region = MKCoordinateRegion(center: initialLocation, span: span)
        
        //only query records with collectedFlag = 0 (1 = collected)
        queryCurrentCycle()
        queryPriorCycle()  //cloudkit doesn't support OR queries, so two are necessary, 1 for each cycle.
        
        
        self.MapView.setRegion(region, animated: true)
        self.MapView.mapType = MKMapType.standard
        self.MapView.showsUserLocation = true
        self.MapView.tintColor = UIColor.blue  //showing user location with blue dot.
        
        DispatchQueue.main.async {
            self.locationmanager.startUpdatingLocation()
        }
        
    }  //end view did load
	
    //tells delegate that new location data is available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    //implement failure methods as part of the delegate
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        print(Error.self)
    }
    
    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        print(Error.self)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(Error.self)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print(Error.self)
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print(Error.self)
    }
    
    //runs when "i" key is pressed to the right of the pin info bubble
    //delegate method
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "Scanner") as? ScannerViewController
        self.present(newViewController!, animated: true, completion: nil)
        
    } //end mapView
    
    func queryCurrentCycle() {  //red pin flags
        
        let flag = 0
        let cycleDate = self.cycleDate.generateCycleDate()
        let p1 = NSPredicate(format: "collectedFlag == %d", flag)
        let p2 = NSPredicate(format: "cycleDate == %@", cycleDate)
        let p3 = NSPredicate(format: "active == %d", 1)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2, p3])
        //  Query fields in Location to set up the artwork on the drop pins
        let query = CKQuery(recordType: "Location", predicate: predicate)
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }
            DispatchQueue.main.async { //run whole thing on main thread to prevent "let artwork" line from producing error
                
                for entry in records {
                    let latitude = entry["latitude"] as? String
                    let longitude = entry["longitude"] as? String
                    let description = entry["locdescription"] as? String
                    let dosimeter = entry["dosinumber"] as? String
                    let QRCode = entry["QRCode"] as? String
                    let cycleDate = entry["cycleDate"] as? String
                    let fullTitle = "\(dosimeter ?? "Dosi Nil")\n\(QRCode ?? "QR Nil")"
                    let createdDate = entry.creationDate
                    self.fullTitle = fullTitle
                    self.createdDate = createdDate  //pass created date out
                    self.dosimeter = dosimeter!  //pass dosimeter number out
                    let dosiLocations = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude!)!, longitude: CLLocationDegrees(longitude!)!)
                    let artwork = Artwork(title: self.fullTitle, locationName: description!, discipline: self.fullTitle, coordinate: dosiLocations, createdDate: createdDate!, cycleDate: cycleDate!) //this has a location manager and needs main thread.
                    
                    self.MapView.addAnnotation(artwork)
                    
                }  //end for loop
                
            } //end dispatch queue
            
        } //end perform query
    
    } //end func
    
    
    func queryPriorCycle() { //green pin flags
        
        let flag = 0
        let cycleDate = self.cycleDate.generateCycleDate()
        let priorCycleDate = self.cycleDate.generatePriorCycleDate(cycleDate: cycleDate)
        let p1 = NSPredicate(format: "cycleDate == %@", priorCycleDate)
        let p2 = NSPredicate(format: "collectedFlag == %d", flag)
        let p3 = NSPredicate(format: "active == %d", 1)
        //where the cycle is the prior cycle, and hasn't been collected yet
        //in order to suppress the ones that have been collected from the map view.
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2, p3])
        
        //  Query fields in Location to set up the artwork on the drop pins
        let query = CKQuery(recordType: "Location", predicate: predicate)
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }
            //print(records)
            DispatchQueue.main.async { //run whole thing on main thread to prevent "let artwork" line from producing error
                
                for entry in records {
                    let latitude = entry["latitude"] as? String
                    let longitude = entry["longitude"] as? String
                    let description = entry["locdescription"] as? String
                    let dosimeter = entry["dosinumber"] as? String
                    let QRCode = entry["QRCode"] as? String
                    let cycleDate = entry["cycleDate"] as? String
                    let fullTitle = "\(dosimeter ?? "Dosi Nil")\n\(QRCode ?? "QR Nil")"
                    let createdDate = entry.creationDate
                    self.fullTitle = fullTitle
                    self.createdDate = createdDate  //pass created date out
                    self.dosimeter = dosimeter!  //pass dosimeter number out
                    let dosiLocations = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude!)!, longitude: CLLocationDegrees(longitude!)!)
                    let artwork = Artwork(title: self.fullTitle, locationName: description!, discipline: dosimeter!, coordinate: dosiLocations, createdDate: createdDate!, cycleDate: cycleDate!) //this has a location manager and needs main thread.
                    
                    self.MapView.addAnnotation(artwork)
                    
                }  //end for loop
                
            } //end dispatch queue
            
        } //end perform query
        
    } //end func
    
} //end class





