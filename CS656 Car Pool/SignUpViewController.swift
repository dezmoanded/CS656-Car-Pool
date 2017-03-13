//
//  SignUpViewController.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 3/12/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {
    @IBOutlet weak var stackViewWidth: NSLayoutConstraint!
    @IBOutlet weak var keyboardHeight: NSLayoutConstraint!
    var scrollViewKeeper : ScrollViewKeeper = ScrollViewKeeper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        stackViewWidth.constant = LoginViewController.widthReference
        scrollViewKeeper = ScrollViewKeeper(view: self.view, constraint: keyboardHeight)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
}
