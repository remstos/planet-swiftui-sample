//
//  UITextViewFixed.swift
//  Calm
//
//  Created by Remi Santos on 12/04/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import UIKit

@IBDesignable class UITextViewFixed: UITextView {
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    func setup() {
        textContainerInset = UIEdgeInsets.zero
        textContainer.lineFragmentPadding = 0
    }
}
