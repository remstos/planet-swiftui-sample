//
//  StoryboardInstantiable.swift
//  Calm
//
//  Created by Remi Santos on 05/04/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import UIKit

protocol StoryboardInstantiable {
    
}

extension StoryboardInstantiable where Self:UIViewController {
    static func createFromStoryboard(embedInNavigation: Bool) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let className = String(describing: Self.self)
        let controller = storyboard.instantiateViewController(identifier: className)
        if (embedInNavigation) {
            return UINavigationController(rootViewController: controller)
        }
        return controller
    }
}


