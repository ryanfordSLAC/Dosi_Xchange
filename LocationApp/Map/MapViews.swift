//
//  MapViews.swift
//  LocationApp
//
//  Created by Ford, Ryan M. on 1/9/19.
//  Copyright © 2019 Ford, Ryan M. All rights reserved.
//

import Foundation
import MapKit
//import Contacts


class ArtworkMarkerView: MKMarkerAnnotationView {
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let artwork = newValue as? Artwork else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: 0, y: 0)
            markerTintColor = artwork.markerTintColor
            //displayPriority = .required
 
            rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
        }
    }
    
    
}

//class ArtworkView: MKAnnotationView {
//
//    override var annotation: MKAnnotation? {
//        willSet {
//            guard let artwork = newValue as? Artwork else {return}
//
//            canShowCallout = true
//            calloutOffset = CGPoint(x: -5, y: 5)
//            let mapsButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 30, height: 30)))
//            mapsButton.setBackgroundImage(UIImage(named: "Maps-icon"), for: UIControl.State())
//            rightCalloutAccessoryView = mapsButton
//            //      rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
//
//            if let imageName = artwork.imageName {
//                image = UIImage(named: imageName)
//            } else {
//                image = nil
//            }
//
//            let detailLabel = UILabel()
//            detailLabel.numberOfLines = 3
//            detailLabel.font = detailLabel.font.withSize(12)
//            detailLabel.lineBreakMode = .byWordWrapping
//            detailLabel.text = artwork.subtitle
//
//            detailCalloutAccessoryView = detailLabel
//
//
//
//        }
//    }
//
//}

