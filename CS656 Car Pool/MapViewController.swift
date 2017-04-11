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
    
    @IBOutlet weak var pickupButton: UIButton!
    @IBOutlet weak var dropoffButton: UIButton!
    @IBOutlet weak var pickupTimeButton: UIButton!
    @IBOutlet weak var dropoffTimeButton: UIButton!
    static var ref: FIRDatabaseReference!
    
    override func viewDidLoad() {
        resetCurrentTrip()
    }
    
    func resetCurrentTrip() {
        MapViewController.ref = ProfileViewController.ref.child("currentTrip")
        MapViewController.ref.child("userID").setValue(ProfileViewController.ref.key)
        MapViewController.ref.observe(FIRDataEventType.value, with: { (snapshot) in
            let pickup = snapshot.childSnapshot(forPath: "pickup")
            if let formattedAddress = pickup.childSnapshot(forPath: "formattedAddress").value {
                self.setButtonValue(button: self.pickupButton, value: formattedAddress)
            }
            
            let dropoff = snapshot.childSnapshot(forPath: "dropoff")
            if let formattedAddress = dropoff.childSnapshot(forPath: "formattedAddress").value {
                self.setButtonValue(button: self.dropoffButton, value: formattedAddress)
            }
            
            if let pickupTime = snapshot.childSnapshot(forPath: "pickupTime").value {
                self.setButtonValue(button: self.pickupTimeButton, value: pickupTime)
            }
            
            if let dropoffTime = snapshot.childSnapshot(forPath: "dropoffTime").value {
                self.setButtonValue(button: self.dropoffTimeButton, value: dropoffTime)
            }
        })
    }
    
    func setButtonValue(button: UIButton, value: Any){
        if let valueString = value as? String {
            if valueString.characters.count > 0 {
                button.setTitle(valueString, for: UIControlState.normal)
            }
        }
    }
   
    @IBAction func clickPickup(_ sender: Any) {
        pickLocation(name: "pickup")
    }
    
    @IBAction func clickDropoff(_ sender: Any) {
        pickLocation(name: "dropoff")
    }
    
    func pickLocation(name: String!){
        let config = GMSPlacePickerConfig(viewport: nil)
        let placePicker = GMSPlacePicker(config: config)
        
        placePicker.pickPlace(callback: {(place, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let place = place {
                let address = MapViewController.ref.child(name)
                address.child("placeID").setValue(place.placeID)
                address.child("name").setValue(place.name)
                address.child("coordinate/latitude").setValue(place.coordinate.latitude)
                address.child("coordinate/longitude").setValue(place.coordinate.longitude)
                address.child("formattedAddress").setValue(place.formattedAddress)
            }
        })
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "pickupTime":
            if let time = self.pickupTimeButton.titleLabel?.text {
                TimePickerViewController.set(name: "pickupTime", time: time)
            }
            break
            
        case "dropoffTime":
            if let time = self.dropoffTimeButton.titleLabel?.text {
                TimePickerViewController.set(name: "dropoffTime", time: time)
            }
            break
            
        default:
            break
        }
        
        return true
    }
}
