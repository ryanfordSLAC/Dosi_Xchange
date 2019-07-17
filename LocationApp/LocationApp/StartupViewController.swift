//
//  Location.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 11/23/18.
//  Copyright © 2018 Ford, Ryan M. All rights reserved.
//

import Foundation
import UIKit
import MessageUI
import CloudKit
import CoreLocation

class StartupViewController: UIViewController, MFMailComposeViewControllerDelegate, CLLocationManagerDelegate {
    
    let reachability = Reachability()!
    let location = CLLocationManager()
    let query = Queries()

    @IBOutlet weak var Tools: UIImageView!

    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        
        //turn on the location manager
        self.location.delegate = self
        location.requestAlwaysAuthorization()
        //location.startUpdatingLocation()    
        //end location manager setup
        
        //progress view
        progressView.setProgress(0, animated: true)
        setProgress()


        let singleTap = UITapGestureRecognizer(target: self, action: #selector(StartupViewController.imageTapped))
        Tools.isUserInteractionEnabled = true
        Tools.addGestureRecognizer(singleTap)

        // Do any additional setup after loading the view, typically from a nib.
        // Detect Wifi:
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            }
            else {
                print("Reachable via Cellular")
            }
        }
        
        reachability.whenUnreachable = { _ in
            print("Not reachable")
            let alert = UIAlertController(title: "WiFi Connection Error", message: "Must be connected to WiFi to identify position and save data to cloud", preferredStyle: .alert)
            let OK = UIAlertAction(title: "OK", style: .default) { (_) in return }
            alert.addAction(OK)
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            } //async end
        
        }//end when unreachable
        
        do {
            try reachability.startNotifier()
        }
        catch {
            print("Unable to start notifier")
        }  //end catch
        //end Detect Wifi...
        
    } //end viewDidLoad
    
    @objc func imageTapped() {
        performSegue(withIdentifier: "segueToTools", sender: "")
    } //end imageTapped
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error")
    } //end location manager fail.
    
    func setProgress() {
        
        //start activityIndicator
        self.activityIndicator.isHidden = false
        activityIndicator.startAnimating()

        //start the queries
        query.getPriorCycleCountCFYes()
        query.getPriorCycleCountCFNo()
        
        query.dispatchGroup.notify(queue: .main) {
            let numberCompleted:Float = Float(self.query.countCFYes)
            let numberRemaining:Float = Float(self.query.countCFNo)
            let numberDeployed:Float = numberCompleted + numberRemaining
            let progress = (numberCompleted / numberDeployed)
            
            switch progress {
                
                case 0:
                    self.statusLabel.text = "Ready to begin collection of \(Int(numberRemaining)) dosimeters!"
                
                case 1:
                    self.statusLabel.text = "All dosimeters from the prior period have been collected!"
                    print("Completed: \(numberCompleted)")
                    print("Deployed: \(numberDeployed)")
                    print("Progress \(progress)")
                
                default:
                    self.statusLabel.text = "Green Pins: \(Int(numberRemaining)) remaining out of \(Int(numberDeployed)) are ready for collection"
                
            } //end switch
            
            self.progressView.progress = progress
        }
        
        run(after: 1) {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }
        
    }// end setProgress
    
    //delay function.
    func run(after seconds: Int, completion: @escaping () -> Void) {
        let deadline = DispatchTime.now() + .seconds(seconds)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            completion()
        }//end dispatch queue 123
    } //end run
    
} // end class
