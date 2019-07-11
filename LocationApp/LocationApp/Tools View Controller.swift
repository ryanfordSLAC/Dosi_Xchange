//
//  Tools View Controller.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 2/18/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class ToolsViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    let readwrite = readWriteText()  //make external class available locally
    let data = LocationViewController()
    let startup = StartupViewController()
    let svController = ScannerViewController()


    var alertCounter:Int = 0
    
    
    //connect to "Upload Data" button on tools view controller (main.storyboard)
    //button currently disabled (deleted)
    @IBOutlet weak var uploadDataButton: UIButton!
    @IBAction func uploadData(_ sender: Any) {
        
        //run uploadToCloud() function in Save class (UploadToCloud.swift)
        _ = Save().uploadToCloud()
    }
    
    
    @IBOutlet weak var toggleAlerts: UIButton!
    @IBAction func toggleAlertsGo(_ sender: Any) {
        
        switch self.alertCounter {
        
        case 0:
            self.alertCounter += 1
            alert1()
            //showAlertController()
        case 1:
            self.alertCounter += 1
            alert2()
        case 2:
            self.alertCounter += 1
            alert3()
        case 3:
            self.alertCounter += 1
            alert4()
        case 4:
            self.alertCounter += 1
            alert5()
        case 5:
            self.alertCounter += 1
            alert6()
        case 6:
            self.alertCounter += 1
            alert7()
        case 7:
            self.alertCounter += 1
            alert8()
        case 8:
            self.alertCounter = 0
            showAlertController()
            //alert1()
        default:
            print(self.alertCounter)
        
        }//end switch
        
    } //end func
    
    @IBAction func emailTouchDown(_ sender: Any) {
        data.queryDatabaseForCSV()
        readwrite.readText()
        
        startup.run(after: 2) {  //wait for 2 seconds before sending mail, to allow prior tasks to finish.
            
            self.sendEmail()
            
        } //end run
    }
    
    func sendEmail() {
        
        let URL =  readwrite.messageURL
        
        //print("URL from sendEmail: \(URL!)")
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["ryanford@slac.stanford.edu"])
            mail.setSubject("Area Dosimeter Data")
            mail.setMessageBody("The dosimeter data is attached to this e-mail.", isHTML: true)
            if let fileAttachment = NSData(contentsOf: URL!) {
                mail.addAttachmentData(fileAttachment as Data, mimeType: "text/csv", fileName: "Dosi_Data.csv")
                //print("4, File attachment: \(fileAttachment)")
            } // end if let fileAttachment
            
            present(mail, animated: true)
            
        }
        else {
            // show failure alert
            
        } //end else
        
    } //end sendEmail
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true)
        
    } //end mailComposeController
    
} //end class

extension ToolsViewController {  //alerts for test screen
    
    func alert1() {
        let alertPrompt = UIAlertController(title: "Manage Dosimeter:", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deployDosimeter = UIAlertAction(title: "Deploy", style: .default) { (_) in }
        alertPrompt.addAction(deployDosimeter)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async {   //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        } //end dispatch queue
        
    } //end alert1
    
    func alert2() {
        let alertPrompt = UIAlertController(title: "Manage Location:", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deployDosimeter = UIAlertAction(title: "Deploy", style: .default) { (_) in }
        alertPrompt.addAction(deployDosimeter)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async {   //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        } //end dispatch queue
        
    } //end alert2
    
    func alert3() {
        
        let alertPrompt = UIAlertController(title: "Manage Dosimeter:\n\n\n\n\n", message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let ExchangeDosimeter = UIAlertAction(title: "Exchange", style: .default) { (_) in }
        let deployDosimeter = UIAlertAction(title: "Deploy", style: .default) { (_) in }
        let collectDosimeter = UIAlertAction(title: "Collect", style: .default) { (_) in }
        let mismatch = UIAlertAction(title: "                Mismatch", style: .default) { (_) in self.alert3() }                       //spaces above provide offset to prevent touching "Mismatch"
            //touching "Mismatch" reopens the alert.

        let btnImage    = UIImage(named: "Unchecked.png")!
        let imageButton : UIButton = UIButton(frame: CGRect(x: 25, y: 160, width: 35, height: 35))
        imageButton.setBackgroundImage(btnImage, for: UIControl.State())
        imageButton.addTarget(self, action: #selector(checkBoxAction(_:)), for: .touchUpInside)
        alertPrompt.view.addSubview(imageButton)
        alertPrompt.addAction(mismatch)
        alertPrompt.addAction(deployDosimeter)
        alertPrompt.addAction(ExchangeDosimeter)
        alertPrompt.addAction(collectDosimeter)
        alertPrompt.addAction(cancel)
        
        DispatchQueue.main.async {   //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        } //end dispatch queue
        
    } //end alert3
    
    func alert4() {
        let picture = Bundle.main.path(forResource: "QRCodeImage", ofType: "png")!
        let message = "Dosimeter barcode accepted.  Please scan the corresponding location code.\n\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 90, y: 90, width: 100, height: 100))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Scan Accepted", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
    } //end alert4
    
    func alert5() {
        
        let picture = Bundle.main.path(forResource: "Inlight", ofType: "jpg")!
        let message = "Location barcode accepted.  Please scan the corresponding dosimeter.\n\n\n\n\n\n\n"
        let imageView = UIImageView(frame: CGRect(x: 75, y: 90, width: 120, height: 80))
        let image = UIImage(named: picture)
        imageView.image = image
        
        //set up alert
        let alert = UIAlertController.init(title: "Scan Accepted", message: message, preferredStyle: .alert)
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
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
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
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
        let OK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.view.addSubview(imageView)
        alert.addAction(OK)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
        
    } //end alert7
    
    func alert8() {
        
        let alertPrompt = UIAlertController(title: "Manage Dosimeter:", message: nil, preferredStyle: .alert)
        
        let saveRecord = UIAlertAction(title: "Save", style: .default) { (_) in }
        let discardAndStartOver = UIAlertAction(title: "Discard & Start Over", style: .default) { (_) in }
        alertPrompt.addTextField { (textfield) in
            textfield.placeholder = "Please add location details" //assign self.description with the textfield information
        }

        alertPrompt.addAction(discardAndStartOver)
        alertPrompt.addAction(saveRecord)
        
        DispatchQueue.main.async {   //UIAlerts need to be shown on the main thread.
            self.present(alertPrompt, animated: true, completion: nil)
        } //end dispatch queue
        
    }  //end alert8
    
}//end extension alerts

extension ToolsViewController {  //handlers
    
    func handler(alert: UIAlertAction!) {  //used for OK in the alert prompt.
        
    } //end handler
    
} //end extension

extension ToolsViewController {
    
    func showAlertController() {
        //simple alert dialog

        let alertController = UIAlertController(title: "Scan Accepted\n", message: "text1", preferredStyle: UIAlertController.Style.alert)

        let btnImage    = UIImage(named: "Unchecked.png")!
        let imageButton : UIButton = UIButton(frame: CGRect(x: 25, y:85, width: 35, height: 35))
        imageButton.setBackgroundImage(btnImage, for: UIControl.State())
        imageButton.addTarget(self, action: #selector(checkBoxAction(_:)), for: .touchUpInside)
        alertController.view.addSubview(imageButton)
        // Add Action
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let mismatch = UIAlertAction(title: "Mismatch", style: .default) { (_) in
            self.showAlertController()
        }
        let test1 = UIAlertAction(title: "Test 1", style: .default, handler: nil)
        alertController.addAction(mismatch)
        alertController.addAction(test1)
        alertController.addAction(cancel)
        DispatchQueue.main.async {
            self.present(alertController, animated: false, completion: { () -> Void in })
        } //end DQ
        
    }  //end func
    
    
    @objc func checkBoxAction(_ sender: UIButton) {  //animates the check box on Alert #3, sets flag.
        if sender.isSelected {
            sender.isSelected = false
            let path = Bundle.main.path(forResource: "Checked", ofType: "png")
            let btnImage    = UIImage(named: path!)
            sender.setBackgroundImage(btnImage, for: UIControl.State())
            //self.mismatchFlag = 0
            
        }//end if
        else {
            sender.isSelected = true
            let path = Bundle.main.path(forResource: "Unchecked", ofType: "png")
            let btnImage    = UIImage(named: path!)
            sender.setBackgroundImage(btnImage, for: UIControl.State())
            //self.mismatchFlag = 1

        }//end else
    } //end func
    
    
}  //end extension
