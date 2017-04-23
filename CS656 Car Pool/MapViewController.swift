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
    
    let dateFormatter = DateFormatter()
    
    var dayOnImage : UIImage!
    override func viewDidLoad() {
        dayOnImage = sundayButton.currentBackgroundImage
        
        dateFormatter.dateStyle = DateFormatter.Style.none
        dateFormatter.timeStyle = DateFormatter.Style.short
        
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
            
            self.setButtonBackground(name: "sunday", button: self.sundayButton, snapshot: snapshot)
            self.setButtonBackground(name: "monday", button: self.mondayButton, snapshot: snapshot)
            self.setButtonBackground(name: "tuesday", button: self.tuesdayButton, snapshot: snapshot)
            self.setButtonBackground(name: "wednesday", button: self.wednesdayButton, snapshot: snapshot)
            self.setButtonBackground(name: "thursday", button: self.thursdayButton, snapshot: snapshot)
            self.setButtonBackground(name: "friday", button: self.fridayButton, snapshot: snapshot)
            self.setButtonBackground(name: "saturday", button: self.saturdayButton, snapshot: snapshot)
            
            if let canDrive = snapshot.childSnapshot(forPath: "canDrive").value as? Bool {
                self.canDriveSwitch.isOn = canDrive
            }
            
            self.addToDmList()
        })
        
        MapViewController.ref.child("pickup").observe(FIRDataEventType.value, with: { (snapshot) in
            self.updateDistanceMatrix()
        })
        MapViewController.ref.child("dropoff").observe(FIRDataEventType.value, with: { (snapshot) in
            self.updateDistanceMatrix()
        })
        
        ProfileViewController.ref.child("trips").observe(FIRDataEventType.value, with: { (snapshot) in
            self.addToDmList()
        })
        
        var canDriveHandle : UInt = 0
        let distanceMatrixUpdatedByRef = FIRDatabase.database().reference().child("distanceMatrixUpdatedBy")
        MapViewController.ref.child("canDrive").observe(FIRDataEventType.value, with: { (snapshot) in
            if let canDrive = snapshot.value as? Bool {
                if canDrive {
                    canDriveHandle = distanceMatrixUpdatedByRef.observe(FIRDataEventType.value, with: { (lastUpdateSnapshot) in
                        ProfileViewController.ref.observeSingleEvent(of: FIRDataEventType.value, with: { (driverSnapshot) in
                            var lastUpdateTime = 0
                            if let lut = driverSnapshot.childSnapshot(forPath: "lastProcessedUpdate").value as? Int {
                                lastUpdateTime = lut
                            }
                            FIRDatabase.database().reference().child("distanceMatrix").observeSingleEvent(of: FIRDataEventType.value, with: { (matrixSnapshot) in
                                FIRDatabase.database().reference().child("usersForMatrix").observeSingleEvent(of: FIRDataEventType.value, with: { (matrixUsersSnapshot) in
                                    for dmUpdate in lastUpdateSnapshot.children.allObjects as! [FIRDataSnapshot] {
                                        if Int(dmUpdate.key)! > lastUpdateTime {
                                            self.processTrips(driver: driverSnapshot,
                                                              user: dmUpdate.value as! String,
                                                              matrix: matrixSnapshot,
                                                              matrixUsers: matrixUsersSnapshot)
                                        }
                                    }
                                    if let newUpdateTime = lastUpdateSnapshot.children.allObjects.first as? FIRDataSnapshot {
                                        ProfileViewController.ref.child("lastProcessedUpdate").setValue(newUpdateTime.key)
                                    }
                                })
                            })
                        })
                    })
                } else {
                    distanceMatrixUpdatedByRef.removeObserver(withHandle: canDriveHandle)
                }
            }
        })
    }
    
    func updateDistanceMatrix() {
        FIRDatabase.database().reference().child("users").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            var locations = ""
            FIRDatabase.database().reference().child("usersForMatrix").removeValue()
            var i = 0
            for user in snapshot.children.allObjects as! [FIRDataSnapshot] {
                if let pickup = user.childSnapshot(forPath: "currentTrip/pickup/placeID").value as? String,
                    let dropoff = user.childSnapshot(forPath: "currentTrip/dropoff/placeID").value as? String{
                    locations += String.init(format: "place_id:%@|place_id:%@|", pickup, dropoff)
                    FIRDatabase.database().reference().child("usersForMatrix")
                        .child(user.key).child("pickup").setValue(i)
                    i += 1
                    FIRDatabase.database().reference().child("usersForMatrix")
                        .child(user.key).child("dropoff").setValue(i)
                    i += 1
                }
            }
            self.callDistanceMatrix(origins: locations, destinations: locations, name: "distanceMatrix")
        })
    }
    
    func processTrips(driver: FIRDataSnapshot, user: String, matrix: FIRDataSnapshot, matrixUsers: FIRDataSnapshot){
        FIRDatabase.database().reference().child("users/\(user)").observeSingleEvent(of: FIRDataEventType.value, with: { (userSnapshot) in
            for driverTrip in driver.childSnapshot(forPath: "trips").children.allObjects as! [FIRDataSnapshot] {
                if let doDriverTrip = driverTrip.childSnapshot(forPath: "on").value as? Bool,
                    doDriverTrip,
                    let userTrip = userSnapshot.childSnapshot(forPath: "trips/\(driverTrip.key)") as? FIRDataSnapshot,
                    let doTrip = userTrip.childSnapshot(forPath: "on").value as? Bool,
                    doTrip,
                    self.timesMakeSense(driverTrip: driverTrip, userTrip: userTrip) {
                    
                    if driverTrip.childSnapshot(forPath: "deleted/" + user).value as? Bool ?? false {
                        continue
                    }
                    
                    var stops = driverTrip.childSnapshot(forPath: "stops").value as? [String]
                    
                    if stops == nil {
                        stops = [driver.key + "/pickup", driver.key + "/dropoff"]
                    }
                    
                    var bestTime = Int.max
                    if userTrip.hasChild("bestTime") {
                        bestTime = userTrip.childSnapshot(forPath: "bestTime").value as! Int
                    }
                    
                    for i in 1 ... stops!.count - 1 {
                        for j in i ... stops!.count - 1 {
                            var tempStops = stops!
                            tempStops.insert("\(user)/pickup", at: i)
                            tempStops.insert("\(user)/dropoff", at: j + 1)
                            var tripTime = MapViewController.totalTripTime(stops: tempStops,
                                                                           matrix: matrix,
                                                                           matrixUsers: matrixUsers)
                            
                            if let earliestDropoff = driverTrip.childSnapshot(forPath: "earliestDropoffTime")
                                .value as? String
                                ?? driverTrip.childSnapshot(forPath: "dropoffTime").value as? String,
                                let earliestDropoffTime = self.dateFormatter.date(from: earliestDropoff),
                                let userDropoff = userTrip.childSnapshot(forPath: "dropoffTime").value as? String,
                                let userDropoffTime = self.dateFormatter.date(from: userDropoff){
                                
                                if userDropoffTime < earliestDropoffTime {
                                    tripTime += Int(earliestDropoffTime.timeIntervalSince(userDropoffTime))
                                    ProfileViewController.ref.child("trips/\(driverTrip.key)/earliestDropoffTime")
                                        .setValue(self.dateFormatter.string(from: userDropoffTime))
                                }
                            }
                            
                            if tripTime < bestTime{
                                if let oldDriver = userTrip.childSnapshot(forPath: "driver").value as? String,
                                    oldDriver != driver.key {
                                    self.removeStopFromOldDriversTrip(driver: oldDriver,
                                                                      trip: driverTrip.key,
                                                                      stop: user)
                                }
                                
                                self.addToTrip(user: user, driver: driver.key, trip: driverTrip.key, stops: tempStops)
                                FIRDatabase.database().reference()
                                    .child("users/\(user)/trips/\(driverTrip.key)/bestTime")
                                    .setValue(tripTime)
                            }
                        }
                    }
                }
            }
        })
    }
    
    static func totalTripTime(stops: [String], matrix: FIRDataSnapshot, matrixUsers: FIRDataSnapshot) -> Int{
        var totalTime = 0
        for i in 0 ... stops.count - 2 {
            let origin = matrixUsers.childSnapshot(forPath: stops[i]).value as! NSNumber
            let destination = matrixUsers.childSnapshot(forPath: stops[i + 1]).value as! NSNumber
            totalTime += matrix.childSnapshot(forPath: "rows/\(origin)/elements/\(destination)/duration/value").value as! Int
        }
        return totalTime
    }
    
    func timesMakeSense(driverTrip: FIRDataSnapshot, userTrip: FIRDataSnapshot) -> Bool {
        if let driverTimeString = driverTrip.childSnapshot(forPath: "dropoffTime").value as? String,
            let userTimeString = userTrip.childSnapshot(forPath: "dropoffTime").value as? String {
            
            let driverTime = dateFormatter.date(from: driverTimeString)
            let userTime = dateFormatter.date(from: userTimeString)
            return userTime! < driverTime!
        } else {
            return false
        }
    }
    
    func addToTrip(user: String, driver: String, trip: String, stops: [String]){
        let users = FIRDatabase.database().reference().child("users")
        users.child("\(user)/trips/\(trip)/driver").setValue(driver)
        users.child("\(driver)/trips/\(trip)/stops").setValue(stops)
    }
    
    func removeStopFromOldDriversTrip(driver: String, trip: String, stop: String){
        let ref = FIRDatabase.database().reference().child("users/\(driver)/trips/\(trip)/stops")
        ref.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            var stops = snapshot.value as! [String]
            for i in 0 ... stops.count - 1 {
                if stops[i].contains(stop) {
                    stops.remove(at: i)
                }
            }
            ref.setValue(stops)
        })
    }
    
    func callDistanceMatrix(origins: String, destinations: String, name: String) {
        let url = "https://maps.googleapis.com/maps/api/distancematrix/json?origins="
            + origins
            + "&destinations="
            + destinations
            + "&key=AIzaSyAqf9BYIrF31Pa9r75D9s7sGMfEItcdN2c"
        print(url)
        let requestURL = URL(string: url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL!)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            //let httpResponse = response as! HTTPURLResponse
            //let statusCode = httpResponse.statusCode
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! Dictionary<String, Any>
                    FIRDatabase.database().reference().child(name).setValue(json)
                } catch let e {
                    print(e)
                }
            }
        }
        
        task.resume()
    }
    
    func addToDmList(){
        let ref = FIRDatabase.database().reference().child("distanceMatrixUpdatedBy")
        ref.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            for entry in snapshot.children.allObjects as! [FIRDataSnapshot] {
                if let entryVal = entry.value as? String,
                    entryVal == ProfileViewController.ref.key {
                    ref.child(entry.key).removeValue()
                }
            }
            ref.child(String.init(format: "%d", Int(Date.init().timeIntervalSince1970)))
                .setValue(ProfileViewController.ref.key)
        })
        
        ProfileViewController.ref.child("trips").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            for trip in snapshot.children.allObjects as! [FIRDataSnapshot] {
                ProfileViewController.ref.child("trips/\(trip.key)/bestTime").removeValue()
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
            ProfileViewController.ref.child("trips/\(name)/on").setValue(doDay)
        } else {
            MapViewController.ref.child(name).setValue(false)
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
        MapViewController.ref.child("sunday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickMonday(_ sender: UIButton) {
        MapViewController.ref.child("monday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickTuesday(_ sender: UIButton) {
        MapViewController.ref.child("tuesday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickWednesday(_ sender: UIButton) {
        MapViewController.ref.child("wednesday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickThursday(_ sender: UIButton) {
        MapViewController.ref.child("thursday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickFriday(_ sender: UIButton) {
        MapViewController.ref.child("friday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    @IBAction func clickSaturday(_ sender: UIButton) {
        MapViewController.ref.child("saturday").setValue(sender.currentBackgroundImage != dayOnImage)
    }
    
    @IBAction func didChangeCanDrive(_ sender: UISwitch) {
        MapViewController.ref.child("canDrive").setValue(sender.isOn)
    }
}
