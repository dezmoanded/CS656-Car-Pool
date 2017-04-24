//
//  ListTableViewCell.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 4/17/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ListTableViewCell: UITableViewCell {
    var labelFormat = ""
    var name = ""
    
    @IBOutlet weak var label: UILabel!
    
    var ref: FIRDatabaseReference!
    
    let dateFormatter = DateFormatter()
    
    func set(labelFormat: String, name: String){
        dateFormatter.dateStyle = DateFormatter.Style.none
        dateFormatter.timeStyle = DateFormatter.Style.short
        
        self.labelFormat = labelFormat
        self.name = name
        
        ref = ProfileViewController.ref.child("trips/\(name)")
        label.text = String.init(format: labelFormat, "(no trip)")
        
        ref.observe(FIRDataEventType.value, with: { (snapshot) in
            if let isOn = snapshot.childSnapshot(forPath: "on").value as? Bool,
                isOn {
                self.label.isEnabled = true
                self.setPickupTime(trip: snapshot)
            } else {
                self.label.isEnabled = false
            }
        })
    }
    
    func setPickupTime(trip: FIRDataSnapshot) {
        if let driver = trip.childSnapshot(forPath: "driver").value as? String ?? ProfileViewController.ref?.key {
            FIRDatabase.database().reference().child("users/\(driver)").observe(FIRDataEventType.value, with: { (snapshot) in
                if let stops = snapshot.childSnapshot(forPath: "/trips/\(self.name)/stops").value as? [String] {
                    for i in 0 ... stops.count - 1 {
                        if stops[i] == ProfileViewController.ref.key + "/pickup" {
                            FIRDatabase.database().reference().child("distanceMatrix").observeSingleEvent(of: FIRDataEventType.value, with: { (dmSnapshot) in
                                FIRDatabase.database().reference().child("usersForMatrix").observeSingleEvent(of: FIRDataEventType.value, with: { (matrixUsers) in
                                    let time = MapViewController.totalTripTime(stops: Array(stops.suffix(from: i)),
                                                                               matrix: dmSnapshot,
                                                                               matrixUsers: matrixUsers)
                                    if let driverDropoffTime = snapshot
                                        .childSnapshot(forPath: "/trips/\(self.name)/earliestDropoffTime")
                                        .value as? String {
                                        if let userPickupTime = self.dateFormatter.date(from: driverDropoffTime)?
                                            .addingTimeInterval(-(Double)(time)),
                                            let isDriver = snapshot.childSnapshot(forPath: "currentTrip/canDrive").value as? Bool{
                                            self.label.text = String.init(format: self.labelFormat,
                                                                          "\(isDriver ? "Leave" : "Pickup") at \(self.dateFormatter.string(from: userPickupTime))")
                                        }
                                    }
                                })
                            })
                        }
                    }
                }
            })
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
