//
//  MapViewController.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 3/28/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps
import GooglePlacePicker
import FirebaseDatabase

class MapViewController: UIViewController {

    var placesClient: GMSPlacesClient!
    
    @IBOutlet var NameLabel: UILabel!
    @IBOutlet var AddressLabel: UILabel!
    
    static var ref: FIRDatabaseReference!
    
    static func setCurrentTrip(currentTrip: String){
        MapViewController.ref = FIRDatabase.database().reference().child("trips").child(currentTrip)
    }
    
    override func viewDidLoad() {
        if MapViewController.ref == nil {
            MapViewController.ref = FIRDatabase.database().reference().child("trips")
            MapViewController.ref = MapViewController.ref.childByAutoId()
            ProfileViewController.ref.child("currentTrip").setValue(MapViewController.ref.key)
        }
    }
   
    @IBAction func CurrentLocation(_ sender: UIButton) {
        let center = CLLocationCoordinate2D(latitude: 37.788204, longitude: -122.411937)
        let northEast = CLLocationCoordinate2D(latitude: center.latitude + 0.001, longitude: center.longitude + 0.001)
        let southWest = CLLocationCoordinate2D(latitude: center.latitude - 0.001, longitude: center.longitude - 0.001)
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let config = GMSPlacePickerConfig(viewport: viewport)
        let placePicker = GMSPlacePicker(config: config)
        
        placePicker.pickPlace(callback: {(place, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let place = place {
                self.NameLabel.text = place.name
                self.AddressLabel.text = place.formattedAddress?.components(separatedBy: ", ")
                    .joined(separator: "\n")
                let pickup = MapViewController.ref.child("pickup")
                pickup.child("name").setValue(place.name)
                pickup.child("coordinate/latitude").setValue(place.coordinate.latitude)
                pickup.child("coordinate/longitude").setValue(place.coordinate.longitude)
                pickup.child("formattedAddress").setValue(place.formattedAddress)
            } else {
                self.NameLabel.text = "No place selected"
                self.AddressLabel.text = ""
            }
        })
    }
}
