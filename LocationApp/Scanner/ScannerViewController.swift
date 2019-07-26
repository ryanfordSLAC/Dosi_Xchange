//
//  Barcode.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 11/23/18.
//  Copyright © 2018 Ford, Ryan M. All rights reserved.
//

import AVFoundation
import UIKit
import CloudKit
import CoreLocation


class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var recordsupdate = recordsUpdate()
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var counter:Int64 = 0
    let dispatchGroup = DispatchGroup()
    var beepSound: AVAudioPlayer?
    var records = [CKRecord]()
    var itemRecord:CKRecord?
    var locationManager = CLLocationManager()
    let database = CKContainer.default().publicCloudDatabase

    @IBOutlet weak var innerView: UIView!
    
    struct variables {  //key variables needed in other classes
        
        static var dosiNumber:String?
        static var QRCode:String?
        static var codeType:String?
        static var dosiLocation:String?
        static var collected:Int64?
        static var mismatch:Int64?
        static var active:Int64?
        static var cycle:String?
        static var latitude:String?
        static var longitude:String?
        static var moderator:Int64?

    } //end struct
    
    func run(after seconds: Int, completion: @escaping () -> Void) {
        let deadline = DispatchTime.now() + .seconds(seconds)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            completion()
        }//end dispatch queue 123
        
        
    } //end run
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        }
        catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        }
        else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            //Location barcode is a QR Code (.qr)
            //Dosimeter barcoce is a CODE 128 barcode (.code128)
            metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.code128]
        }
        
        else {
            failed()
            return
        }//end else
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        self.previewLayer.frame.size = self.innerView.frame.size
        previewLayer.videoGravity = .resizeAspectFill
        self.innerView.layer.addSublayer(previewLayer)
        captureSession.startRunning()
        
    }//end viewDidLoad()
    
    func failed() {
        
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
        
    }//end failed
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        self.previewLayer.frame.size = self.innerView.frame.size
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
        
    }//end viewWillAppear
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
        
    }//end viewWillDisappear
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        if let metadataObject = metadataObjects.first {
            
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            switch readableObject.type {
                
            case .qr:

                variables.codeType = "QRCode"
                
            case .code128:

                variables.codeType = "Code128"
            
            default:
                print("Code not found")
                
            }//end switch
            
            scannerLogic(code: stringValue)
            
        }//end if let

    }//end function meetadataOutput
    

    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
        
    } //end supportedInterfaceOrientations
    
}   //end class

/*
 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 All methods, alerts, handlers and queries needed to
 implement the scanner logic (see figures under "other assets")
 by Ryan M. Ford 2019
 */

extension ScannerViewController {
    
    func scannerLogic(code: String) { //see Other Assets Scanner Logic diagrams
        
        switch self.counter {
            
            case 0: //first scan
                variables.QRCode = nil
                variables.dosiNumber = nil

                switch variables.codeType {
                    
                    case "QRCode":

                        variables.QRCode = code //store the QRCode
                        queryForQRFound() //use the QRCode to look up record & store values

                        dispatchGroup.notify(queue: .main) {
                            print("Dispatch QR Code Notify")
                            
                            //record found
                            if self.itemRecord != nil {
                                self.beep()
                                
                                if variables.collected == 0 {
                                    if variables.active == 1 { self.alert3() } //Exchange Dosimeter (active location)
                                    else { self.alert3i() } //Collect Dosimeter (inactive location)
                                }
                                else {
                                    if variables.active == 1 { self.alert2() } //Location Found [cancel/deploy]
                                    else { self.alert2a() } //Inactive Location (activate to deploy)
                                }
                            }
                            
                            //no record found
                            else {
                                self.beep()
                                self.alert2() //New Location [cancel/deploy]
                            }
                            
                        } //end dispatch group

                    case "Code128":
                        
                        variables.dosiNumber = code //store the dosi number
                        queryForDosiFound() //use the dosiNumber to look up record & store values

                        dispatchGroup.notify(queue: .main){
                            print("Dispatch Code 128 Notify")
                            
                            //record found
                            if self.itemRecord != nil {
                                self.beep()
                                if variables.active == 1 { self.alert3() } //Exchange Dosimeter (active location)
                                else { self.alert3i() } //Collect Dosimeter (inactive location)
                            }
                            
                            //no record found
                            else {
                                self.beep()
                                self.alert1() //Dosimeter Not Found [cancel/deploy]
                            }
                            
                        } //end dispatch group

                    default:
                        
                        print("Invalid Code") //exhaustive
                        alert9()
                        self.captureSession.startRunning()
                    
                } //end switch
            
            case 1: //second scan logic

                self.captureSession.startRunning()
                
                switch variables.codeType {
                    
                    case "QRCode":
                        
                        if variables.QRCode == nil {
                            beep()
                            variables.QRCode = code
                            alert8()
                        }
                        
                        else if variables.QRCode != nil {
                            beepFail()
                            self.captureSession.stopRunning()
                            alert7()
                        }
                    
                    case "Code128":
                        
                        if variables.dosiNumber == nil {
                            beep()
                            variables.dosiNumber = code
                            alert8()
                        }
                        
                        else if variables.dosiNumber != nil {
                            beepFail()
                            self.captureSession.stopRunning()
                            alert6()
                        }
                    
                    default:
                        print("Invalid Code")
                        alert9()
                }
            
            default:
                print("Invalid Scan")
                counter = 0
                self.captureSession.startRunning()
        }
    } //end func
    
    
    func collect(collected: Int64, mismatch: Int64) {
        
        itemRecord!.setValue(collected, forKey: "collectedFlag")
        itemRecord!.setValue(mismatch, forKey: "mismatch")
            
        self.run(after: 1) {
            self.database.save(self.itemRecord!) { (record, error) in
                guard record != nil else { return }
            } //end database save
            //print("RECORD SAVED:\n\(itemRecord!)")
        }
    } //end collect
    
    
    func deploy() {
        
        self.counter = 1
        
    } //end deploy
    
    
    func clearData() {
        
        variables.codeType = nil
        variables.dosiNumber = nil
        variables.QRCode = nil
        variables.latitude = nil
        variables.longitude = nil
        variables.dosiLocation = nil
        variables.collected = nil
        variables.mismatch = nil
        variables.active = nil
        variables.moderator = nil
        variables.cycle = nil
        itemRecord = nil
        counter = 0
        
    }  //end clear data
    
    
    func getCoordinates() {
        
        locationManager.requestAlwaysAuthorization()
        var currentLocation = CLLocation()
        if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() ==  .authorizedAlways) {
            
            currentLocation = locationManager.location!
            
        }  //end if
        
        let latitude = String(format: "%.8f", currentLocation.coordinate.latitude)
        let longitude = String(format: "%.8f", currentLocation.coordinate.longitude)
        
        variables.latitude = latitude
        variables.longitude = longitude
        
    }
    
    
    @objc func beepFail() {
        
        //"Buzz!"
        guard let path = Bundle.main.path(forResource: "beep-5", ofType: "wav") else {
            print("URL Not Found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            self.beepSound = try AVAudioPlayer(contentsOf: url)
            self.beepSound?.play()
        }
        catch {
            print(error.localizedDescription)
        }
    } //end beep fail
    
    
    @objc func beep() {
        
        //"Beep!"
        guard let path = Bundle.main.path(forResource: "scannerbeep", ofType: "mp3") else {
            print("URL Not Found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            self.beepSound = try AVAudioPlayer(contentsOf: url)
            self.beepSound?.play()
        }
        catch {
            print(error.localizedDescription)
        }
    } //end beep()
    
} //end extension methods
/*
 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 
 */

extension ScannerViewController {  //queries
    
    func queryForDosiFound() {
        dispatchGroup.enter()
        let p1 = NSPredicate(format: "dosinumber == %@", variables.dosiNumber!)
        let p2 = NSPredicate(format: "collectedFlag == %d", 0)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort]
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }
            
            if records != [] {
                variables.active = records[0]["active"] as? Int64
                variables.collected = records[0]["collectedFlag"] as? Int64
                variables.QRCode = records[0]["QRCode"] as? String
                variables.dosiLocation = records[0]["locdescription"] as? String
                if records[0]["moderator"] != nil { variables.moderator = records[0]["moderator"] as? Int64 }
                if records[0]["mismatch"] != nil { variables.mismatch = records[0]["mismatch"] as? Int64 }
                
                self.itemRecord = records[0]
            }
            
            self.records = records
            
        } //end perform query
        
        run(after: 1) {
            self.dispatchGroup.leave()
        }
        
    } //end queryforDosiFound
    
    func queryForQRFound() {
        dispatchGroup.enter()
        let predicate = NSPredicate(format: "QRCode == %@", variables.QRCode!)
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        query.sortDescriptors = [sort]
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }
            
            if records != [] {
                variables.active = records[0]["active"] as? Int64
                variables.dosiLocation = records[0]["locdescription"] as? String
                if records[0]["collectedFlag"] != nil {variables.collected = records[0]["collectedFlag"] as? Int64}
                if records[0]["dosinumber"] != nil { variables.dosiNumber = records[0]["dosinumber"] as? String }
                if records[0]["moderator"] != nil { variables.moderator = records[0]["moderator"] as? Int64 }
                if records[0]["mismatch"] != nil { variables.mismatch = records[0]["mismatch"] as? Int64 }
                
                self.itemRecord = records[0]
            }
            
            self.records = records
            
        }  //end perform query
        
        run(after: 1) {
            self.dispatchGroup.leave()
        }
        
    } //end queryForQRFound

} //end extension queries
    
/*
 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 
 */


extension ScannerViewController {  //alerts

        
    func alert1() {
        
        let alertPrompt = UIAlertController(title: "Dosimeter Not Found:\n\(variables.dosiNumber ?? "Nil Dosi")", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handlerCancel)
        
        let deployDosimeter = UIAlertAction(title: "Deploy", style: .default) { (_) in
            variables.QRCode = nil
            self.deploy()
            self.alert4()
        } //end let
        
        alertPrompt.addAction(deployDosimeter)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        }
    } //end alert1
    
    
    func alert2() {
        
        let title = itemRecord != nil ? "Location Found:\n\(variables.QRCode ?? "Nil QRCode")" : "New Location:\n\(variables.QRCode ?? "Nil QRCode")"
        
        let alertPrompt = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handlerCancel)
        
        let deployDosimeter = UIAlertAction(title: "Deploy", style: .default) { (_) in
            variables.dosiNumber = nil
            self.deploy()
            self.alert5()
        } //end let
        
        alertPrompt.addAction(deployDosimeter)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        }
    } //end alert2
    
    
    func alert2a() {
        
        let message = "Please activate this location to deploy a dosimeter."
        
        //set up alert
        let alert = UIAlertController.init(title: "Inactive Location:\n\(variables.QRCode ?? "Nil QRCode")", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerCancel)
        
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func alert3() {
        
        let alertPrompt = UIAlertController(title: "Exchange Dosimeter:\n\(variables.dosiNumber ?? "Nil Dosi")\n\nLocation:\n\(variables.QRCode ?? "Nil QRCode")", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handlerCancel)
        
        let ExchangeDosimeter = UIAlertAction(title: "Exchange", style: .default) { (_) in
            self.collect(collected: 1, mismatch: variables.mismatch ?? 0)
            self.deploy()
            variables.mismatch = 0
            variables.dosiNumber = nil
            self.alert3a()
        }

        let mismatch = UIAlertAction(title: "Mismatch", style: .default) { (_) in
            self.alert3()
        }
        
        alertPrompt.addAction(mismatch)
        alertPrompt.view.addSubview(mismatchSwitch())
        alertPrompt.addAction(ExchangeDosimeter)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        }
    } //end alert3
    
    
    func alert3i() {
        
        let alertPrompt = UIAlertController(title: "Collect Dosimeter:\n\(variables.dosiNumber ?? "Nil Dosi")\n\nLocation:\n\(variables.QRCode ?? "Nil QRCode")", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handlerCancel)
        
        let collectDosimeter = UIAlertAction(title: "Collect", style: .default) { (_) in
            self.collect(collected: 1, mismatch: variables.mismatch ?? 0)
            self.captureSession.startRunning()
            self.alert11()
        }
        
        let mismatch = UIAlertAction(title: "Mismatch", style: .default) { (_) in
            self.alert3i() //reopen alert
        }
        
        alertPrompt.addAction(mismatch)
        alertPrompt.view.addSubview(mismatchSwitch())
        alertPrompt.addAction(collectDosimeter)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async { //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        }
        
    } //end alert3i
    
    
    func alert3a() {
        
        let picture = Bundle.main.path(forResource: "Inlight", ofType: "jpg")!
        let message = "Please scan the new dosimeter for location \(variables.QRCode ?? "Nil Dosi").\n\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 75, y: 90, width: 120, height: 80))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Replace Dosimeter", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerOK)
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert3a
    
    
    func alert4() {
        
        let picture = Bundle.main.path(forResource: "QRCodeImage", ofType: "png")!
        let message = "Dosimeter barcode accepted \(variables.dosiNumber ?? "Nil Dosi").  Please scan the corresponding location code.\n\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 90, y: 90, width: 100, height: 100))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Scan Accepted", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerOK)
        
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert4
    
    
    func alert5() {
        
        let picture = Bundle.main.path(forResource: "Inlight", ofType: "jpg")!
        let message = "Location barcode accepted \(variables.QRCode ?? "Nil QR").  Please scan the corresponding dosimeter.\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 75, y: 100, width: 120, height: 80))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Scan Accepted", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerOK)
        
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }//end alert5
    
    
    func alert6() {
        
        let picture = Bundle.main.path(forResource: "QRCodeImage", ofType: "png")!
        let message = "Try again...Please scan the corresponding location code.\n\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 90, y: 90, width: 100, height: 100))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Error", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: handlerOK)
        
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert6
    
    
    func alert7() {
        
        let picture = Bundle.main.path(forResource: "Inlight", ofType: "jpg")!
        let message = "Try again...Please scan the corresponding dosimeter.\n\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 75, y: 90, width: 120, height: 80))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Error", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: handlerOK)
        
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    } //end alert7
    
    func alert8() {

        let cycle = recordsupdate.generateCycleDate()
        variables.cycle = cycle
        getCoordinates()
        
        let alertPrompt = UIAlertController(title: "Deploy Dosimeter:\n\(variables.dosiNumber ?? "Nil Dosi")\n\nLocation:\n\(variables.QRCode ?? "Nil QRCode")", message: nil, preferredStyle: .alert)
        
        let saveRecord = UIAlertAction(title: "Save", style: .default) { (_) in
            var text = alertPrompt.textFields?.first?.text
            text = text?.replacingOccurrences(of: ",", with: "-")
            
            self.recordsupdate.saveRecord(latitude: variables.latitude ?? "Nil Latitude", longitude: variables.longitude ?? "Nil Longitude", dosiNumber: variables.dosiNumber ?? "Nil Dosi", text: text ?? "Nil location", flag: 0, cycle: cycle, QRCode: variables.QRCode ?? "Nil QRCode", mismatch: variables.mismatch ?? 0, moderator: variables.moderator ?? 0, active: 1)
            
            variables.dosiLocation = text
            self.counter = 0
            self.alert10() //Success
        }  //end let
        
        let discardAndStartOver = UIAlertAction(title: "Discard & Start Over", style: .default, handler: handlerCancel)
        
        alertPrompt.addTextField { (textfield) in
            if variables.dosiLocation != nil {
                textfield.text = variables.dosiLocation // assign self.description with the textfield information
            }
            else {
                textfield.placeholder = "Type or dictate location details" //assign self.description with the textfield information
            }
        } // end addTextField
        
        alertPrompt.addAction(discardAndStartOver)
        alertPrompt.addAction(saveRecord)
        
        DispatchQueue.main.async {   //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        }
    }  //end alert8
    
    
    func alert9() {  //invalid barcode type

        let message = "Please scan either a dosimeter or a location barcode."
      
        //set up alert
        let alert = UIAlertController.init(title: "Invalid Barcode Type", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerCancel)

        alert.addAction(OK)

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }  //end alert9
    
    
    func alert10(){  //Success!
        
        //let message = "Data saved: \nQR Code: \(variables.QRCode ?? "Nil QRCode")\nDosimeter: \(variables.dosiNumber ?? "Nil Dosi")\nLocation: \(variables.dosiLocation ?? "Nil location")\nFlag (Depl'y = 0, Collected = 1): 0\nLatitude: \(variables.latitude ?? "Nil Latitude")\nLongitude: \(variables.longitude ?? "Nil Longitude")\nWear Date: \(variables.cycle ?? "Nil cycle")\nMismatch (No = 0 Yes = 1): \(variables.mismatch ?? 0)\nModerator (No = 0 Yes = 1): \(variables.moderator ?? 0)"
        
        //set up alert
        let alert = UIAlertController.init(title: "Save Successful!", message: nil, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerCancel)
        
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }  //end alert10
    
    
    func alert11() {  //Success!
        
        //let message = "Data Saved:\nQR Code: \(variables.QRCode ?? "Nil QRCode")\nDosimeter: \(variables.dosiNumber ?? "Nil Dosi")\nLocation: \(variables.dosiLocation ?? "Nil location")\nFlag (Depl'y = 0, Collected = 1): 1 \nMismatch (No = 0 Yes = 1): \(variables.mismatch ?? 0)"
        
        //set up alert
        let alert = UIAlertController.init(title: "Collection Successful!", message: nil, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handlerCancel)
        
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }  //end alert10
    
    
    // mismatch switch
    func mismatchSwitch() -> UISwitch {
        let switchControl = UISwitch(frame: CGRect(x: 200, y: 155, width: 0, height: 0))
        switchControl.tintColor = UIColor.gray
        switchControl.setOn(variables.mismatch == 1, animated: false)
        switchControl.addTarget(self, action: #selector(switchValueDidChange(_:)), for: .valueChanged)
        return switchControl
    }
    
    @objc func switchValueDidChange(_ sender: UISwitch!) {
        
        variables.mismatch = sender.isOn ? 1 : 0

    }
    
    
}//end extension alerts

/*
 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 
 */

extension ScannerViewController {  //handlers
    
    func handlerOK(alert: UIAlertAction!) {  //used for OK in the alert prompt.
        
        self.captureSession.startRunning()
        
    } //end handler
    
    func handlerCancel(alert: UIAlertAction!) {
        
        self.clearData()
        self.captureSession.startRunning()
    }
    
} //end extension
