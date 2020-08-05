//
//  LabelAnimator.swift
//  Calm
//
//  Created by Remi Santos on 26/04/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation
import UIKit

class LabelAnimator {
    
    private var label: UILabel!
    init(withLabel: UILabel) {
        label = withLabel
    }

    func transitionToText(_ text: String) {
        let duration = 0.5
        UIView.transition(with: self.label, duration: duration, options: .transitionCrossDissolve, animations: {
            self.label.text = text
        }, completion: nil)
    }
}
