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
    @IBOutlet weak var returnTimeButton: UIButton!
    static var ref: FIRDatabaseReference!
    @IBOutlet weak var returnTimeLabel: UILabel!
    @IBOutlet weak var returnSwitch: UISwitch!
    @IBOutlet weak var sundayButton: UIButton!
    @IBOutlet weak var mondayButton: UIButton!
    @IBOutlet weak var tuesdayButton: UIButton!
    @IBOutlet weak var wednesdayButton: UIButton!
    @IBOutlet weak var thursdayButton: UIButton!
    @IBOutlet weak var fridayButton: UIButton!
    @IBOutlet weak var saturdayButton: UIButton!
    @IBOutlet weak var canDriveSwitch: UISwitch!
    
    var dayOnImage : UIImage!
    override func viewDidLoad() {
        dayOnImage = sundayButton.currentBackgroundImage
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
            
            if let returnTime = snapshot.childSnapshot(forPath: "returnTime").value {
                self.setButtonValue(button: self.returnTimeButton, value: returnTime)
            }
            
            if let doReturn = snapshot.childSnapshot(forPath: "doReturn").value as? Bool {
                self.returnSwitch.isOn = doReturn
                if doReturn {
                    self.returnTimeLabel.alpha = 1
                    self.returnTimeButton.isEnabled = true
                } else {
                    self.returnTimeLabel.alpha = 0.5
                    self.returnTimeButton.isEnabled = false
                }
            }
            
            self.setButtonBackground(name: "doSunday", button: self.sundayButton, snapshot: snapshot)
            self.setButtonBackground(name: "doMonday", button: self.mondayButton, snapshot: snapshot)
            self.setButtonBackground(name: "doTuesday", button: self.tuesdayButton, snapshot: snapshot)
            self.setButtonBackground(name: "doWednesday", button: self.wednesdayButton, snapshot: snapshot)
            self.setButtonBackground(name: "doThursday", button: self.thursdayButton, snapshot: snapshot)
            self.setButtonBackground(name: "doFriday", button: self.fridayButton, snapshot: snapshot)
            self.setButtonBackground(name: "doSaturday", button: self.saturdayButton, snapshot: snapshot)
            
            if let canDrive = snapshot.childSnapshot(forPath: "canDrive").value as? Bool {
                self.canDriveSwitch.isOn = canDrive
            }
        })
    }
    
    func setButtonBackground(name: String, button: UIButton, snapshot: FIRDataSnapshot){
        if let doDay = snapshot.childSnapshot(forPath: name).value as? Bool {
            if doDay {
                button.setBackgroundImage(self.dayOnImage, for: UIControlState.normal)
                button.setTitleColor(UIColor.white, for: UIControlState.normal)
            } else {
                button.setBackgroundImage(nil, for: UIControlState.normal)
                button.setTitleColor(UIColor.black, for: UIControlState.normal)
            }
        } else {
            MapViewController.ref.child(name).setValue(true)
        }
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
    @IBAction func didChangeReturnSwitch(_ sender: UISwitch) {
        MapViewController.ref.child("doReturn").setValue(sender.isOn)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "pickupTime":
            if let time = self.pickupTimeButton.titleLabel?.text {
                TimePickerViewController.set(name: "pickupTime", time: time)
            }
            break
            
        case "returnTime":
            if let time = self.returnTimeButton.titleLabel?.text {
                TimePickerViewController.set(name: "returnTime", time: time)
            }
            break
            
        default:
            break
        }
        
        return true
    }
    @IBAction func clickSunday(_ sender: UIButton) {
        MapViewController.ref.child("doSunday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickMonday(_ sender: UIButton) {
        MapViewController.ref.child("doMonday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickTuesday(_ sender: UIButton) {
        MapViewController.ref.child("doTuesday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickWednesday(_ sender: UIButton) {
        MapViewController.ref.child("doWednesday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickThursday(_ sender: UIButton) {
        MapViewController.ref.child("doThursday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickFriday(_ sender: UIButton) {
        MapViewController.ref.child("doFriday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickSaturday(_ sender: UIButton) {
        MapViewController.ref.child("doSaturday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func didChangeCanDrive(_ sender: UISwitch) {
        MapViewController.ref.child("canDrive").setValue(sender.isOn)
    }
}
