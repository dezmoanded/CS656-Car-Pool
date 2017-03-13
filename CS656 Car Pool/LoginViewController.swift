//
//  LoginViewController.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 3/12/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var keyboardHeight: NSLayoutConstraint!
    @IBOutlet weak var insideViewHeight: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    
    var scrollViewKeeper : ScrollViewKeeper = ScrollViewKeeper()
    
    static var widthReference: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        insideViewHeight.constant = -UIApplication.shared.statusBarFrame.height
        scrollViewKeeper = ScrollViewKeeper(view: self.view, constraint: keyboardHeight)
        LoginViewController.widthReference = titleLabel.frame.width
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "Main" {
            FIRAuth.auth()?.signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                if error != nil {
                    let alert = UIAlertController(title: "Error", message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                self.performSegue(withIdentifier: "Main", sender: nil)
            }
            return false
        }
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
}
