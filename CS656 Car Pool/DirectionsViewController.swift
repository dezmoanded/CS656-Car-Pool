//
//  DirectionsViewController.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 4/22/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit

class DirectionsViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    var html = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Directions"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        webView.loadHTMLString(html, baseURL: nil)
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
