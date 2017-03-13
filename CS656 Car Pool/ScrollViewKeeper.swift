//
//  ScrollViewKeeper.swift
//  CS656 Car Pool
//
//  Created by Paul Lorenz on 3/12/17.
//  Copyright © 2017 Rasheed Azeez, Paul Lorenz, Benjamin Nichols, Somsai Veerareddy, Steven Dong. All rights reserved.
//

import UIKit

class ScrollViewKeeper : NSObject {
    var constraint: NSLayoutConstraint!
    var view: UIView!
    
    override init(){
        super.init()
    }
    
    init(view: UIView, constraint: NSLayoutConstraint) {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame),
                                               name: .UIKeyboardWillChangeFrame,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
        self.view = view
        self.constraint = constraint
    }
    
    func keyboardWillChangeFrame(notification: NSNotification) {
        if let value = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let rect = value.cgRectValue
            self.constraint.constant = rect.height
            self.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.constraint.constant = 0
        self.view.layoutIfNeeded()
    }
}
