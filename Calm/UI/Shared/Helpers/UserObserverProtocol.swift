//
//  UserObserverProtocol.swift
//  Calm
//
//  Created by Remi Santos on 09/05/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol UserObserverProtocol : AnyObject {
    var subscription : Disposable? { get set }
    func currentUserHasBeenUpdated()
}

extension UserObserverProtocol {
    func startObservingCurrentUser() {
        self.subscription = AppUserManager.shared.rx.observeWeakly(Bool.self, "hasUser").subscribe { (event) in
            self.currentUserHasBeenUpdated()
        }
    }
    func stopObservingCurrentUser() {
        self.subscription?.dispose()
    }
}
