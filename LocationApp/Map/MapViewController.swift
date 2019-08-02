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
    var cycleDate = recordsUpdate()
    var records = [CKRecord]()

    
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
        let initialLocation = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        let region = MKCoordinateRegion(center: initialLocation, latitudinalMeters: 150, longitudinalMeters: 150)
        
        //only query records with collectedFlag = 0 (1 = collected)
        queryActives()
        
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
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let newViewController = mainStoryboard.instantiateViewController(withIdentifier: "Scanner") as! ScannerViewController
        self.show(newViewController, sender: self)
        
        
    } //end mapView
    
    
    //query active locations
    func queryActives() {
        
        records = [CKRecord]()
        //let cycleDate = self.cycleDate.generateCycleDate()
        let p1 = NSPredicate(format: "collectedFlag == %d", 0)
        let p2 = NSPredicate(format: "active == %d", 1)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        let sort1 = NSSortDescriptor(key: "QRCode", ascending: true)
        let sort2 = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort1, sort2]
        let operation = CKQueryOperation(query: query)
        addOperation(operation: operation)
    
    } //end func
    
    
    //add query operation
    func addOperation(operation: CKQueryOperation) {
        operation.resultsLimit = 200 // max 400; 200 to be safe
        operation.recordFetchedBlock = self.recordFetchedBlock // to be executed for each fetched record
        operation.queryCompletionBlock = self.queryCompletionBlock // to be executed after each query (query fetches 200 records at a time)
        
        database.add(operation)
    } //end func
    
    
    //to be executed after each query (query fetches 200 records at a time)
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
    } //end func
    
    
    //to be executed for each fetched record
    func recordFetchedBlock(record: CKRecord) {
        
        //run whole thing on main thread to prevent "let artwork" line from producing error
        DispatchQueue.main.async {
            
            let QRCode = record["QRCode"] as? String
            let active = record["active"] as? Int64
            let latitude = record["latitude"] as? String
            let longitude = record["longitude"] as? String
            let description = record["locdescription"] as? String
            
            let dosimeter = record["dosinumber"] as? String
            let cycleDate = record["cycleDate"] as? String
            let collected = record["collectedFlag"] as? Int64
            
            let fullTitle = "\(QRCode ?? "QR Nil")\n\(dosimeter ?? "Dosi Nil")"
            let dosiLocations = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude!)!, longitude: CLLocationDegrees(longitude!)!)
            let artwork = Artwork(title: fullTitle, locDescription: description!, coordinate: dosiLocations, cycleDate: cycleDate!, active: active!, collected: collected!) //this has a location manager and needs main thread.
            self.MapView.addAnnotation(artwork)

        }
    }
}


