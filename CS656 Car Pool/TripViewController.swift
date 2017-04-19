//
//  TripViewController.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 4/19/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit
import FirebaseDatabase

class TripViewController: UIViewController, UITableViewDelegate {

    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    var driver = ""
    var passengers : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
    }
    
    func setupMap(trip: FIRDataSnapshot) {
        if let driver = trip.childSnapshot(forPath: "driver").value as? String ?? ProfileViewController.ref?.key {
            self.driver = driver
            FIRDatabase.database().reference().child("users/\(driver)").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                FIRDatabase.database().reference().child("distanceMatrix").observeSingleEvent(of: FIRDataEventType.value, with: { (matrix) in
                    FIRDatabase.database().reference().child("usersForMatrix").observeSingleEvent(of: FIRDataEventType.value, with: { (matrixUsers) in
                        if let stops = snapshot.childSnapshot(forPath: "/trips/\(trip.key)/stops").value as? [String] {
                            self.setupDirections(stops: stops, matrix: matrix, matrixUsers: matrixUsers)
                        }
                    })
                })
            })
        }
    }
    
    func setupDirections(stops: [String], matrix: FIRDataSnapshot, matrixUsers: FIRDataSnapshot) {
        if let origin = getAddress(stop: stops.first, matrix: matrix, matrixUsers: matrixUsers),
            let destination = getAddress(stop: stops.last, matrix: matrix, matrixUsers: matrixUsers) {
            var url = "https://maps.googleapis.com/maps/api/directions/json?origin="
                + origin + "&destination=" + destination
            
            if stops.count > 2 {
                url += "&waypoints="
                passengers = []
                for stop in stops[1 ... stops.count - 2] {
                    if let waypoint = getAddress(stop: stop, matrix: matrix, matrixUsers: matrixUsers) {
                        url += waypoint + "|"
                    }
                    
                    if stop.contains("pickup") {
                        let stopUser = stop.replacingOccurrences(of: "/pickup", with: "")
                        passengers.append(stopUser)
                    }
                }
            }
            
            callGoogleDirections(url: url)
        }
    }
    
    func getAddress(stop: String!, matrix: FIRDataSnapshot, matrixUsers: FIRDataSnapshot) -> String? {
        if let index = matrixUsers.childSnapshot(forPath: stop).value as? NSNumber {
            return matrix.childSnapshot(forPath: "destination_addresses/\(index)").value as? String
        }
        return nil
    }
    
    func callGoogleDirections(url: String) {
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
                    
                } catch let e {
                    print(e)
                }
            }
        }
        
        task.resume()
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
