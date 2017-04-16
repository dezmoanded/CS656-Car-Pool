//
//  BestMatchViewController.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 4/15/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit
import FirebaseDatabase

class BestMatchViewController: UIViewController {
    static var ref: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        MapViewController.ref.observe(FIRDataEventType.value, with: { (snapshot) in
            FIRDatabase.database().reference().child("users").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                var pickups = ""
                var dropoffs = ""
                for user in snapshot.children.allObjects as! [FIRDataSnapshot] {
                    if let pickupLat = user.childSnapshot(forPath: "currentTrip/pickup/coordinate/latitude").value as? Float,
                        let pickupLon = user.childSnapshot(forPath: "currentTrip/pickup/coordinate/longitude").value as? Float,
                        let dropoffLat = user.childSnapshot(forPath: "currentTrip/dropoff/coordinate/latitude").value as? Float,
                        let dropoffLon = user.childSnapshot(forPath: "currentTrip/dropoff/coordinate/longitude").value as? Float{
                        pickups += String.init(format: "%f,%f|", pickupLat, pickupLon)
                        dropoffs += String.init(format: "%f,%f|", dropoffLat, dropoffLon)
                    }
                }
                self.callDistanceMatrix(origins: pickups, destinations: pickups, name: "pickupDistanceMatrix")
                self.callDistanceMatrix(origins: dropoffs, destinations: dropoffs, name: "dropoffDistanceMatrix")
            })
        })
    }
    
    func callDistanceMatrix(origins: String, destinations: String, name: String) {
        var url = "https://maps.googleapis.com/maps/api/distancematrix/json?origins="
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
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
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
