//
//  TimePickerViewController.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 4/11/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit
import FirebaseDatabase

class TimePickerViewController: UIViewController {
    static var name : String = ""
    static var time : String = ""
    
    @IBOutlet var times: [UIButton]!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = DateFormatter.Style.none
        dateFormatter.timeStyle = DateFormatter.Style.short
        
        if let timeDate = dateFormatter.date(from: TimePickerViewController.time) {
            self.timePicker.setDate(timeDate, animated: false)
        }
        
        for i in 0 ... times.count - 1 {
            times[i].tag = i
        }
        
        ProfileViewController.ref.child("trips").observe(FIRDataEventType.value, with: { (snapshot) in
            for trip in snapshot.children.allObjects as! [FIRDataSnapshot] {
                for i in 0 ... ListTableViewController.names.count - 1 {
                    if trip.key == ListTableViewController.names[i] {
                        if let dropoffTime = trip.childSnapshot(forPath: "dropoffTime").value as? String {
                            self.currentButton?.setTitle(dropoffTime, for: UIControlState.normal)
                        }
                    }
                }
            }
        })
    }

    var currentButton : UIButton? = nil
    @IBAction func touchTimes(_ sender: UIButton) {
        let fontSize = sender.titleLabel!.font.pointSize
        currentButton?.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        currentButton = times[sender.tag]
        currentButton?.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize)
        TimePickerViewController.name = ListTableViewController.names[sender.tag]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func set(name: String, time: String) {
        TimePickerViewController.name = name
        TimePickerViewController.time = time
    }
    
    @IBAction func timePickerChanged(_ sender: Any) {
        let time = dateFormatter.string(from: self.timePicker.date)
        ProfileViewController.ref.child("trips")
            .child(TimePickerViewController.name).child("dropoffTime").setValue(time)
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
