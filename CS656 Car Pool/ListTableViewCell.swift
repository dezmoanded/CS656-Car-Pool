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
    @IBOutlet weak var button: UIButton!
    
    var ref: FIRDatabaseReference!
    
    func set(labelFormat: String, name: String){
        self.labelFormat = labelFormat
        self.name = name
        
        ref = ProfileViewController.ref.child("trips/(name)")
        label.text = String.init(format: labelFormat, "...")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
