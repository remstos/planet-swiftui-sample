//
//  String+Extension.swift
//  Calm
//
//  Created by Remi Santos on 04/05/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation

extension String{
    static func randomEmoji()->String{
        let range = [UInt32](0x1F601...0x1F64F)
        let ascii = range[Int(drand48() * (Double(range.count)))]
        let emoji = UnicodeScalar(ascii)?.description
        return emoji!
    }
}
