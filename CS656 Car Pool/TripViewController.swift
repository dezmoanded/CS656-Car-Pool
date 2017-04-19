//
//  TripViewController.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 4/19/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit
import FirebaseDatabase

class TripViewController: UITableViewController {

    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var _tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView = _tableView
        //self.tableView.delegate = self
    }
    
    func setupMap(trip: FIRDataSnapshot) {
        if let driver = trip.childSnapshot(forPath: "driver").value as? String ?? ProfileViewController.ref?.key {
            FIRDatabase.database().reference().child("users/\(driver)").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                FIRDatabase.database().reference().child("distanceMatrix").observeSingleEvent(of: FIRDataEventType.value, with: { (dmSnapshot) in
                    FIRDatabase.database().reference().child("usersForMatrix").observeSingleEvent(of: FIRDataEventType.value, with: { (matrixUsers) in
                        for stop in snapshot.childSnapshot(forPath: "/trips/\(trip.key)/stops").children.allObjects as! [String] {
                            if stop.contains("pickup") {
                                stop.replacingOccurrences(of: "/pickup", with: "")
                            }
                        }
                    })
                })
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
