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

var recordsupdate = recordsUpdate()
var queryOutput = Queries()


class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var counter:Int64 = 0
    let dispatchGroup = DispatchGroup()
    var beepSound: AVAudioPlayer?
    var records = [CKRecord]()
    var locationManager = CLLocationManager()
    let database = CKContainer.default().publicCloudDatabase

    @IBOutlet weak var innerView: UIView!
    
    struct variables {  //key variables needed in other classes
        
        static var dosiNumber:String? = ""
        static var QRCode:String? = ""
        static var codeType:String? = ""
        static var dosiLocation:String? = ""
        static var mismatch:Int64? = 0
        static var latitude:String? = ""
        static var longitude:String? = ""
        static var cycle:String? = ""

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

extension ScannerViewController {  //methods
    //add a delay function.
    

    
    func scannerLogic(code: String) {  //see Other Assets Scanner Logic diagrams


        
        switch self.counter {
            
        case 0: //first scan
            variables.dosiNumber = nil
            variables.QRCode = nil
            variables.dosiLocation = nil

            switch variables.codeType {
                
            case "QRCode":

                variables.QRCode = code  //store the QR Code
                queryForQRFound()  //use the QR Code to look up record and store if there

                dispatchGroup.notify(queue: .main) {
                    print("Dispatch QR Code Notify")
                    //print(self.records)
                    
                if self.records != [] {
                    
                    self.beep()
                    self.alert3()  //exchange collect cancel alert
                    } //end if
                    
                else if self.records == [] {
                    self.beep()
                    self.alert2() //Record Not Found! deploy alert

                    }//end else if
                } //end dispatch group

            case "Code128":

                variables.dosiNumber = code //store the dosi number
                queryForDosiFound()  //use the dosi number to look up record and store if there

                dispatchGroup.notify(queue: .main){
                    print("Dispatch Code 128 Notify")
                    //print(self.records)
                    if self.records != [] {
                        self.beep()
                        self.alert3()
                        
                    } //end if
                        
                    else if self.records == [] {
                        self.beep()
                        self.alert1()
                        
                    } //end else if
                    
                }//end dispatch group

            default:
                
                print("Invalid Code")  //exhaustive
                alert9()
                self.captureSession.startRunning()
                
            } //end switch
            
        case 1:         //second scan logic

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
                    self.captureSession.startRunning()
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
                    self.captureSession.startRunning()
                    alert6()
                    
                }
                
            default:
                print("Invalid Code")
                alert9()
                self.captureSession.startRunning()
                
            }
            
        default:
            print("Invalid Scan")
            counter = 0
            self.captureSession.startRunning()
        }

    } //end func
    
    func collect(flag: Int64, dosiNumber: String, mismatch: Int64) {
        
        
        let predicate = NSPredicate(format: "dosinumber = %@", dosiNumber)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }
            
            for record in records {
                //save the new flag only
                record.setValue(flag, forKey: "collectedFlag")
                record.setValue(mismatch, forKey: "mismatch")
                self.database.save(record) { (record, error) in
                    guard record != nil else { return }
                }  //end database save
            } //end for
        }//end query
        
        
    } //end collect
    
    func deploy() {
        if self.counter == 0 {  //self.counter is either 0 or 1 at this point
            self.counter += 1   //if 0 then add 1 to advance to second scan
        } //end if
        else {
            self.counter = 1    //else if 1 then leave it alone.
        } //end else
        
    } //end deploy
    
    func clearData() {
        
        variables.codeType = nil
        variables.dosiLocation = nil
        variables.dosiNumber = nil
        variables.latitude = nil
        variables.longitude = nil
        variables.mismatch = 0
        variables.QRCode = nil
        counter = 0
        
    }  //end clear data
    
    
    func getCoordinates() {
        
        locationManager.requestAlwaysAuthorization()
        var currentLocation = CLLocation()
        if( CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() ==  .authorizedAlways){
            
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
        } catch {
            print(error.localizedDescription)
        } //end catch
        
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
            
        } catch {
            
            print(error.localizedDescription)
            
        } //end catch
        
    }//end beep()
    
    
}  //end extension methods
/*
 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 
 */

extension ScannerViewController {  //queries
    
    func queryForDosiFound() {
        dispatchGroup.enter()
        //let flag = 0
        //let p1 = NSPredicate(format: "collectedFlag == %d", flag)
        //print(variables.dosiNumber!)
        let predicate = NSPredicate(format: "dosinumber == %@", variables.dosiNumber!)
        //let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        //print(predicate)
        let query = CKQuery(recordType: "Location", predicate: predicate)
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }

            for record in records {
                variables.dosiNumber = record["dosinumber"] as? String
                variables.dosiLocation = record["locdescription"] as? String
                variables.QRCode = record["QRCode"] as? String
                
            } //end for
            
            self.records = records
            
        }   //end perform query
        
        run(after: 1) {
            
         self.dispatchGroup.leave()
            
        }
        
    } //end queryforDosiFound
    
    func queryForQRFound() {
        dispatchGroup.enter()
        let flag = 0
        let p1 = NSPredicate(format: "collectedFlag == %d", flag)
        let p2 = NSPredicate(format: "QRCode == %@", variables.QRCode!)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        let query = CKQuery(recordType: "Location", predicate: predicate)
        database.perform(query, inZoneWith: nil) { (records, _) in
            guard let records = records else { return }

                for record in records {
                    variables.QRCode = record["QRCode"] as? String
                    variables.dosiLocation = record["locdescription"] as? String
                    variables.dosiNumber = record["dosinumber"] as? String
                    
            } //end for
            
          self.records = records
            
        }   //end perform query
        
        run(after: 1) {
            
            self.dispatchGroup.leave()
            
        }
        
    }  //queryForQRFound

}//end extension queries
    
/*
 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 
 */


extension ScannerViewController {  //alerts

        
    func alert1(){
        let alertPrompt = UIAlertController(title: "Record Not Found:\n\(variables.dosiNumber!)", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handler)
        let deployDosimeter = UIAlertAction(title: "Deploy", style: .default) { (_) in
            self.deploy()
            self.alert4()
        }  //end let
        alertPrompt.addAction(deployDosimeter)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async {   //UIAlerts need to be shown on the main thread.
            
            self.present(alertPrompt, animated: true, completion: nil)
            
        }   //end dispatch queue
        
        
    } //end alert1
    
    func alert2(){
        let alertPrompt = UIAlertController(title: "Record Not Found:\n\(variables.QRCode!)", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handler)
        let deployDosimeter = UIAlertAction(title: "Deploy", style: .default) { (_) in
            self.deploy()
            self.alert5()
        }  //end let
        alertPrompt.addAction(deployDosimeter)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async {   //UIAlerts need to be shown on the main thread.
            
            self.present(alertPrompt, animated: true, completion: nil)
            
        }   //end dispatch queue
        
    }//end alert2
    
    func alert3(){ //alert if dosi and qr are found
        //print("3-Counter: \(counter)")
        //print("3-Dosi Number: \(variables.dosiNumber ?? "Nil Dosi")")
        //print("3-QR Code: \(variables.QRCode ?? "Nil QR")")
        let alertPrompt = UIAlertController(title: "Manage Dosimeter: \(String(describing: variables.dosiNumber ?? "Next scan")) \n\n Location:\n\(String(describing: variables.QRCode ?? "Next scan"))", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handler)
        let ExchangeDosimeter = UIAlertAction(title: "Exchange", style: .default) { (_) in
            self.collect(flag: 1, dosiNumber: variables.dosiNumber!, mismatch: variables.mismatch!)
            self.deploy()
            variables.dosiNumber = nil
            self.alert3a()
        }  //end let

        let collectDosimeter = UIAlertAction(title: "Collect", style: .default) { (_) in
            self.collect(flag: 1, dosiNumber: variables.dosiNumber!, mismatch: variables.mismatch!)
            //self.counter += 1
            self.captureSession.startRunning()
            self.alert11()
        }  //end let
        let mismatch = UIAlertAction(title: "Mismatch", style: .default) { (_) in
            self.alert3()                               //spaces above provide offset to prevent touching "Mismatch"
            //touching "Mismatch" reopens the alert.
        }
        let btnImage    = UIImage(named: "Unchecked.png")!
        let imageButton : UIButton = UIButton(frame: CGRect(x: 25, y: 153, width: 35, height: 35))
        imageButton.setBackgroundImage(btnImage, for: UIControl.State())
        imageButton.addTarget(self, action: #selector(checkBoxAction(_:)), for: .touchUpInside)
        alertPrompt.view.addSubview(imageButton)
        alertPrompt.addAction(mismatch)

        alertPrompt.addAction(ExchangeDosimeter)
        alertPrompt.addAction(collectDosimeter)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async {   //UIAlerts need to be shown on the main thread.
            
            self.present(alertPrompt, animated: true, completion: nil)
            
        }   //end dispatch queue
        
        
    } //end alert3
  
    func alert3a() {
        
        let picture = Bundle.main.path(forResource: "Inlight", ofType: "jpg")!
        let message = "Please scan the new dosimeter for location \(String(describing: variables.QRCode ?? "Nil Dosi")).\n\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 75, y: 90, width: 120, height: 80))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        
        let alert = UIAlertController.init(title: "Replace Dosimeter", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handler)
        //let Cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handler)
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        // alert.addAction(Cancel)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
        
        
    } //end alert 3a
    
    func alert4(){
        let picture = Bundle.main.path(forResource: "QRCodeImage", ofType: "png")!
        let message = "Dosimeter barcode accepted \(String(describing: variables.dosiNumber ?? "Nil Dosi")).  Please scan the corresponding location code.\n\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 90, y: 90, width: 100, height: 100))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        
        let alert = UIAlertController.init(title: "Scan Accepted", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handler)
        //let Cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: handler)
        alert.view.addSubview(imageView)
        alert.addAction(OK)
       // alert.addAction(Cancel)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }  //end alert4
    
    func alert5(){
        
        let picture = Bundle.main.path(forResource: "Inlight", ofType: "jpg")!
        let message = "Location barcode accepted \(String(describing: variables.QRCode ?? "Nil QR")).  Please scan the corresponding dosimeter.\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 75, y: 100, width: 120, height: 80))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Scan Accepted", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handler)
        //let Cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        //alert.addAction(Cancel)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }//end alert5
    
    func alert6(){
        
        let picture = Bundle.main.path(forResource: "QRCodeImage", ofType: "png")!
        let message = "Try again...Please scan the corresponding location code.\n\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 90, y: 90, width: 100, height: 100))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Error", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
        
    } //end alert6
    
    func alert7(){
        
        let picture = Bundle.main.path(forResource: "Inlight", ofType: "jpg")!
        let message = "Try again...Please scan the corresponding dosimeter.\n\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 75, y: 90, width: 120, height: 80))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Error", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
        
    } //end alert7
    
    func alert8(){

        getCoordinates()
        let cycle = recordsupdate.generateCycleDate()
        variables.cycle = cycle
        let alertPrompt = UIAlertController(title: "Manage Dosimeter: \(String(describing: variables.dosiNumber ?? "Nil Dosi")) at location \(String(describing: variables.QRCode ?? "Nil QR"))", message: nil, preferredStyle: .alert)
        
        let saveRecord = UIAlertAction(title: "Save", style: .default) { (_) in
            
            recordsupdate.saveRecord(latitude: variables.latitude ?? "Nil Latitude", longitude: variables.longitude ?? "Nil Longitude", dosiNumber: variables.dosiNumber ?? "Nil dosinumber", text: alertPrompt.textFields?.first?.text ?? "Nil location", flag: 0, cycle: cycle, QRCode: variables.QRCode ?? "Nil QRCode", mismatch: variables.mismatch ?? 3)
            
            variables.dosiLocation = alertPrompt.textFields?.first?.text
            self.counter = 0 //
            self.alert10() //Success
            
        }  //end let
        let discardAndStartOver = UIAlertAction(title: "Discard & Start Over", style: .default) { (_) in
            self.captureSession.startRunning()
            self.clearData()
            
        }  //end let
        alertPrompt.addTextField { (textfield) in
            
            if variables.dosiLocation != nil {
            textfield.text = variables.dosiLocation //assign self.description with the textfield information
            }
            else {
            textfield.placeholder = "Type or dictate location details" //assign self.description with the textfield information
                
            }
        }
        
        alertPrompt.addAction(discardAndStartOver)
        alertPrompt.addAction(saveRecord)
        
        DispatchQueue.main.async {   //UIAlerts need to be shown on the main thread.
            
            self.present(alertPrompt, animated: true, completion: nil)
            
        }   //end dispatch queue
        
        
            
            
        }  //end alert8
    
    
    func alert9(){  //invalid barcode type

        let message = "Please scan either a dosimeter or a location barcode."
      
        //set up alert
        
        let alert = UIAlertController.init(title: "Invalid Barcode Type", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default) { (_) in
            
            self.clearData()
            self.captureSession.startRunning()
        }

        alert.addAction(OK)

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }  //end alert9
    
    func alert10(){  //Success!
        
        let message = "Data was saved: \nQR Code: \(variables.QRCode ?? "Nil QRCode")\nDosimeter: \(variables.dosiNumber ?? "Nil Dosimeter")\nLocation: \(variables.dosiLocation ?? "Nil location")\nFlag (Depl'y = 0, Collected = 1): 0\nLatitude: \(variables.latitude ?? "Nil Latitude")\nLongitude: \(variables.longitude ?? "Nil Longitude")\nWear Date: \(variables.cycle ?? "Nil cycle")\nMismatch (No = 0 Yes = 1): \(variables.mismatch ?? 3)"
        
        print("10-Location: \(variables.dosiLocation ?? "Nil Location")")
        //set up alert
        
        let alert = UIAlertController.init(title: "Save Successful", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handler)
        
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }  //end alert10
    
    func alert11(){  //Success!
        

        let message = "Data Saved:\nQR Code: \(variables.QRCode ?? "Nil QRCode")\nDosimeter: \(variables.dosiNumber ?? "Nil Dosimeter")\nLocation: \(variables.dosiLocation ?? "Nil location")\nFlag (Depl'y = 0, Collected = 1): 1 \nMismatch (No = 0 Yes = 1): \(variables.mismatch ?? 3)"
        //print("10-Location: \(variables.dosiLocation ?? "Nil Location")")
        //set up alert
        
        let alert = UIAlertController.init(title: "Collection Successful", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .default, handler: handler)
        
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }  //end alert10
        
    @objc func checkBoxAction(_ sender: UIButton) {  //animates the check box on Alert #3, sets flag.
        if sender.isSelected {
            sender.isSelected = false
            let path = Bundle.main.path(forResource: "Checked", ofType: "png")
            let btnImage    = UIImage(named: path!)
            sender.setBackgroundImage(btnImage, for: UIControl.State())
            variables.mismatch = 1
            
        }//end if
        else {
            sender.isSelected = true
            let path = Bundle.main.path(forResource: "Unchecked", ofType: "png")
            let btnImage    = UIImage(named: path!)
            sender.setBackgroundImage(btnImage, for: UIControl.State())
            variables.mismatch = 0
            
        }//end else
    } //end func
    
    
}//end extension alerts

/*
 
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 
 */

extension ScannerViewController {  //handlers
    
    func handler(alert: UIAlertAction!){  //used for OK in the alert prompt.
        
        self.captureSession.startRunning()
        
    } //end handler
    
} //end extension
