//
//  Friendship.swift
//  Calm
//
//  Created by Remi Santos on 05/04/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation

struct Friendship {
    var friend : AppUser
    var initiatedBy : AppUser
    var status : String
    init(withFriend: AppUser, status: String, initiatedBy: AppUser) {
        self.friend = withFriend
        self.status = status
        self.initiatedBy = initiatedBy
    }
}
