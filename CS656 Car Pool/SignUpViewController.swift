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
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordConfirmTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let valid = true
        if (emailTextField.text?.isEmpty) {
            emailTextField.layer.borderColor = UIColor.red.cgColor
            valid = false
        }
        if passwordTextField.text?.isEmpty {
            passwordTextField.layer.borderColor = UIColor.red.cgColor
            valid = false
        }
        if passwordConfirmTextField.text != passwordTextField.text {
            passwordConfirmTextField.layer.borderColor = UIColor.red.cgColor
            valid = false
        }
        if firstNameTextField.text?.isEmpty {
            firstNameTextField.layer.borderColor = UIColor.red.cgColor
            valid = false
        }
        if lastNameTextField.text?.isEmpty {
            lastNameTextField.layer.borderColor = UIColor.red.cgColor
            valid = false
        }
        if valid {
            return true
        }
        return false
    }
}
