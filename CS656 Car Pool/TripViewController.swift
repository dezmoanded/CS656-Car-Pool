//
//  TripViewController.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 4/19/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit
import FirebaseDatabase
import GoogleMaps

class TripTableViewController: UITableViewController {
    var driver = ""
    var passengers : [String] = []
    var trip : FIRDataSnapshot? = nil
    var tvc : TripViewController? = nil
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Driver" : "Passengers"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : passengers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "passengerCell")!
        cell.textLabel?.text = indexPath.section == 0 ? driver : passengers[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete),
            let tripKey = trip?.key {
            let passenger = passengers[indexPath.row]
            FIRDatabase.database().reference().child("users/\(passenger)/trips/\(tripKey)/driver").removeValue()
                
            let tripRef = FIRDatabase.database().reference().child("users/\(driver)/trips/\(tripKey)")
            let stops = tripRef.child("stops")
            stops.observeSingleEvent(of: FIRDataEventType.value, with: { (stopsSnapshot) in
                for stop in stopsSnapshot.children.allObjects as! [FIRDataSnapshot] {
                    if let p = stop.value as? String {
                        if p.contains(passenger) {
                            stops.child(stop.key).removeValue() /////// Keys don't change!!!
                        }
                    }
                }
            })
        }
    }
}

class TripViewController: UIViewController, GMSMapViewDelegate {

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    let ttvc = TripTableViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = ttvc
        ttvc.tableView = tableView
        ttvc.tvc = self
        
        self.mapView.isMyLocationEnabled = true;
        self.mapView.mapType = GMSMapViewType.normal;
        //self.mapView.settings.compassButton = true;
        //self.mapView.settings.myLocationButton = true;
        self.mapView.delegate = self;
    }
    
    func setupMap(trip: FIRDataSnapshot) {
        ttvc.trip = trip
        if let driver = trip.childSnapshot(forPath: "driver").value as? String ?? ProfileViewController.ref?.key {
            ttvc.driver = driver
            FIRDatabase.database().reference().child("users/\(driver)").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                FIRDatabase.database().reference().child("distanceMatrix").observeSingleEvent(of: FIRDataEventType.value, with: { (matrix) in
                    FIRDatabase.database().reference().child("usersForMatrix").observeSingleEvent(of: FIRDataEventType.value, with: { (matrixUsers) in
                        if let stops = snapshot.childSnapshot(forPath: "/trips/\(trip.key)/stops").value as? [String] {
                            self.setupDirections(stops: stops, matrix: matrix, matrixUsers: matrixUsers)
                        }
                    })
                })
            })
            
            let tripRef = FIRDatabase.database().reference().child("users/\(driver)/trips/\(trip.key)")
            tripRef.observe(FIRDataEventType.childChanged, with: { (snapshot) in
                self.setupMap(trip: snapshot)
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
                ttvc.passengers = []
                for stop in stops[1 ... stops.count - 2] {
                    if let waypoint = getAddress(stop: stop, matrix: matrix, matrixUsers: matrixUsers) {
                        url += waypoint + "|"
                    }
                    
                    if stop.contains("pickup") {
                        let stopUser = stop.replacingOccurrences(of: "/pickup", with: "")
                        ttvc.passengers.append(stopUser)
                    }
                }
            }
            
            url += "&key=AIzaSyAqf9BYIrF31Pa9r75D9s7sGMfEItcdN2c"
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
                    
                    var bounds = GMSCoordinateBounds()
                    if let route = (json["routes"] as? [Dictionary<String, Any>])?.first {
                        var didFirstMarker = false
                        for leg in route["legs"] as! [Dictionary<String, Any>] {
                            if !didFirstMarker {
                                self.putMarker(location: leg["start_location"])
                                didFirstMarker = true
                            }
                            
                            self.putMarker(location: leg["end_location"])
                            
                            
                            for step in leg["steps"] as! [Dictionary<String, Any>] {
                                if let polyline = step["polyline"] as? Dictionary<String, String>,
                                    let points = polyline["points"],
                                    let path = GMSPath.init(fromEncodedPath: points) {
                                    
                                    bounds = bounds.includingPath(path)
                                    DispatchQueue.main.async {
                                        let pl = GMSPolyline.init(path: path)
                                        pl.map = self.mapView
                                    }
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.mapView.moveCamera(GMSCameraUpdate.fit(bounds))
                        self.tableView.reloadData()
                    }
                } catch let e {
                    print(e)
                }
            }
        }
        
        task.resume()
    }
    
    func putMarker(location: Any ) {
        if let ggg = location as? Dictionary<String, NSNumber>,
            let lat = ggg["lat"],
            let lng = ggg["lng"] {
            
            DispatchQueue.main.async {
                let marker = GMSMarker.init(position: CLLocationCoordinate2D.init(latitude: CLLocationDegrees(lat),
                                                                                  longitude: CLLocationDegrees(lng)))
                marker.map = self.mapView
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
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
