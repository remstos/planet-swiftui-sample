//
//  UIViewController+PlanetNavigationBar.swift
//  Calm
//
//  Created by Remi Santos on 07/05/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func personalizeNavigationBar(withColor color: UIColor?, tintColor: UIColor?, animated: Bool) {
        UIView.animate(withDuration: animated ? 1:0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: .beginFromCurrentState, animations: {
            self.navigationController?.navigationBar.tintColor = tintColor
            self.navigationController?.navigationBar.layer.cornerRadius = 10
            self.navigationController?.navigationBar.layer.masksToBounds = true
    
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
            self.navigationItem.standardAppearance = appearance
            self.navigationItem.scrollEdgeAppearance = appearance
            self.navigationItem.compactAppearance = appearance
        }, completion: nil)
    }
    
    func clearPersonalizedNavigationBar(animated: Bool) {
        UIView.animate(withDuration: animated ? 1:0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: .beginFromCurrentState, animations: {
            self.navigationController?.navigationBar.layer.cornerRadius = 0
        }, completion: { (finished) in
            self.navigationController?.navigationBar.tintColor = nil
            self.navigationController?.navigationBar.layer.masksToBounds = false
        })
    }
}
