//
//  ProfileViewController.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 3/12/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ProfileViewController: UIViewController {
    @IBOutlet weak var stackViewWidth: NSLayoutConstraint!
    @IBOutlet weak var keyboardHeight: NSLayoutConstraint!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordConfirmTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var passwordConfirmView: UIView!
    @IBOutlet weak var doneButton: UIButton!
    
    var scrollViewKeeper : ScrollViewKeeper = ScrollViewKeeper()
    static var ref: FIRDatabaseReference!
    static var user: FIRUser!
    var observeRef: FIRDatabaseReference!
    
    static func setUser (user: FIRUser!) {
        ProfileViewController.user = user
        ProfileViewController.ref = FIRDatabase.database().reference().child("users").child((user?.uid)!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        stackViewWidth.constant = LoginViewController.widthReference
        scrollViewKeeper = ScrollViewKeeper(view: self.view, constraint: keyboardHeight)
        
        if (ProfileViewController.ref != nil) {
            self.signUpButton.isHidden = true
            self.emailTextField.isEnabled = false
            self.passwordView.isHidden = true
            self.passwordConfirmView.isHidden = true
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardWillShow),
                                                   name: .UIKeyboardWillShow,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardWillHide),
                                                   name: .UIKeyboardWillHide,
                                                   object: nil)
            
            if (ProfileViewController.user != nil) {
                self.emailTextField.text = ProfileViewController.user.email
            }
            
            ProfileViewController.ref.observe(FIRDataEventType.value, with: { (snapshot) in
                let postDict = snapshot.value as? [String : String] ?? [:]
                self.firstNameTextField.text = postDict["firstName"]
                self.lastNameTextField.text = postDict["lastName"]
                self.phoneNumberTextField.text = postDict["phoneNumber"]
            })
        }
    }
    
    @IBAction func didEditTextField(_ sender: UITextField) {
        updateUser()
    }
    
    func updateUser() {
        if (ProfileViewController.ref != nil) {
            ProfileViewController.ref.child("firstName").setValue(self.firstNameTextField.text)
            ProfileViewController.ref.child("lastName").setValue(self.lastNameTextField.text)
            ProfileViewController.ref.child("phoneNumber").setValue(self.phoneNumberTextField.text)
        }
    }
    
    @IBAction func clickDone(_ sender: Any) {
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        doneButton.isHidden = false
    }
    
    func keyboardWillHide(notification: NSNotification) {
        doneButton.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (!(ProfileViewController.ref != nil)) {
            self.navigationController?.isNavigationBarHidden = false
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        var valid = true
        if (emailTextField.text?.isEmpty)! {
            emailTextField.layer.borderColor = UIColor.red.cgColor
            emailTextField.layer.borderWidth = 1
            valid = false
        }
        if (passwordTextField.text?.isEmpty)! {
            passwordTextField.layer.borderColor = UIColor.red.cgColor
            passwordTextField.layer.borderWidth = 1
            valid = false
        }
        if passwordConfirmTextField.text != passwordTextField.text {
            passwordConfirmTextField.layer.borderColor = UIColor.red.cgColor
            passwordConfirmTextField.layer.borderWidth = 1
            valid = false
        }
        if (firstNameTextField.text?.isEmpty)! {
            firstNameTextField.layer.borderColor = UIColor.red.cgColor
            firstNameTextField.layer.borderWidth = 1
            valid = false
        }
        if (lastNameTextField.text?.isEmpty)! {
            lastNameTextField.layer.borderColor = UIColor.red.cgColor
            lastNameTextField.layer.borderWidth = 1
            valid = false
        }
        if valid {
            FIRAuth.auth()?.createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                if error != nil {
                    let alert = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                ProfileViewController.setUser(user: user)
                self.updateUser()
                self.performSegue(withIdentifier: "next", sender: nil)
            }
        }
        return false
    }
}
