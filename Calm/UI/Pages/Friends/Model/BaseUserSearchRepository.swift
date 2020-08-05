//
//  BaseUserSearchRepository.swift
//  Calm
//
//  Created by Remi Santos on 09/05/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Combine

class BaseUserSearchRepository {
    @Published var users = [AppUser]()
}

protocol UserSearchRepository: BaseUserSearchRepository {
    func searchUsers(_ username: String) -> Future<Bool, Error>
    func addUserAsFriend(_ user: AppUser) -> Future<Bool, Error>
    func clearUsers()
}

class TestDataUserSearchRepository: BaseUserSearchRepository, UserSearchRepository, ObservableObject {
    override init() {
        super.init()
        self.users = testUserList
    }
    
    func searchUsers(_ username: String) -> Future<Bool, Error> {
        self.users = testUserList.filter { (user) -> Bool in
            return user.username.lowercased().contains(username.lowercased())
        }
        return Future<Bool, Error> { promise in
            promise(.success(true))
        }
    }

    func addUserAsFriend(_ user: AppUser) -> Future<Bool, Error> {
        return Future<Bool, Error> { promise in
            promise(.success(true))
        }
    }

    func clearUsers() {
        self.users = testUserList
    }
}

class FirestoreUserSearchRepository: BaseUserSearchRepository, UserSearchRepository, ObservableObject {
    
    var db = Firestore.firestore()
    private var lastSearchedUsername = ""
    override init() {
        super.init()
    }
    
    func searchUsers(_ username: String) -> Future<Bool, Error> {
        self.lastSearchedUsername = username
        return Future<Bool, Error> { promise in
            UserStore.getUser(forUsername: username) { (user, error) in
                
                let finishedLastSearch = self.lastSearchedUsername == username
                if let user = user, finishedLastSearch {
                    self.users = [user]
                } else {
                    self.users = []
                }
                promise(.success(finishedLastSearch))
            }
        }
    }
    
    func addUserAsFriend(_ user: AppUser) -> Future<Bool, Error> {
         return Future<Bool, Error> { promise in
            FriendsStore.initiateFriendship(fromUser: AppUserManager.shared.currentUser!, toUsername: user.username) { (success, error) in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(success))
                }
            }
         }
     }

    func clearUsers() {
        self.users.removeAll()
    }
}




//#if DEBUG
let testUserList = [
  AppUser(withUsername: "johndoe", email: "idk", color: PaletteColor.paletteColorA(), emoji: "🦆", uid: "1"),
//  AppUser(withUsername: "renardo", email: "idk", color: PaletteColor.paletteColorC(), emoji: "🦊", uid: "2"),
]
//#endif
