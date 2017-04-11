//
//  TimePickerViewController.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 4/11/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit

class TimePickerViewController: UIViewController {
    static var name : String = ""
    static var time : String = ""
    
    @IBOutlet weak var timePicker: UIDatePicker!
    
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = DateFormatter.Style.none
        dateFormatter.timeStyle = DateFormatter.Style.short
        
        if let timeDate = dateFormatter.date(from: TimePickerViewController.time) {
            self.timePicker.setDate(timeDate, animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func set(name: String, time: String) {
        TimePickerViewController.name = name
        TimePickerViewController.time = time
    }
    
    @IBAction func clickDone(_ sender: Any) {
        MapViewController.ref.child(TimePickerViewController.name).setValue(dateFormatter.string(from: self.timePicker.date))
        self.dismiss(animated: true)
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
