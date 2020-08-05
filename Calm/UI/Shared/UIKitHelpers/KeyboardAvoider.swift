//
//  KeyboardAvoider.swift
//  Calm
//
//  Created by Remi Santos on 09/05/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import UIKit

protocol KeyboardAvoider : AnyObject {
    var bottomConstraint : NSLayoutConstraint? { get set }
    
    var keyboardWillShowObserver : Any? { get set }
    var keyboardWillHideObserver : Any?  { get set }
}

extension KeyboardAvoider where Self: UIViewController {
    
    func startListeningToKeyboardNotifications(withConstraint: NSLayoutConstraint) {
        self.bottomConstraint = withConstraint
        self.keyboardWillShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] (notification) in
            self?.keyboardWillShowNotification(notification: notification as NSNotification)
        }
        
        self.keyboardWillHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] (notification) in
            self?.keyboardWillHideNotification(notification: notification as NSNotification)
        }
    }
    func stopListeningToKeyboardNotifications() {
        self.bottomConstraint = nil
        if let showObserver = self.keyboardWillShowObserver, let hideObserver = self.keyboardWillHideObserver {
        NotificationCenter.default.removeObserver(showObserver)
        NotificationCenter.default.removeObserver(hideObserver)
        }
    }
    
    private func keyboardWillShowNotification(notification: NSNotification) {
        updateBottomLayoutConstraintWithNotification(notification: notification)
    }
    
    private  func keyboardWillHideNotification(notification: NSNotification) {
        updateBottomLayoutConstraintWithNotification(notification: notification)
    }
    
    private func updateBottomLayoutConstraintWithNotification(notification: NSNotification) {
        let userInfo = notification.userInfo!
        
        let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let keyboardEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)
        let rawAnimationCurve = (notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue << 16
        let animationCurve = UIView.AnimationOptions(rawValue: UInt(rawAnimationCurve))
        
        self.bottomConstraint?.constant = view.bounds.maxY - convertedKeyboardEndFrame.minY
        
        UIView.animate(withDuration: animationDuration, delay: 0.0, options: [UIView.AnimationOptions.beginFromCurrentState, animationCurve], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}


