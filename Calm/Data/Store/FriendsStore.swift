//
//  FriendsStore.swift
//  Calm
//
//  Created by Remi Santos on 05/04/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation
import FirebaseFirestore

class FriendsStore {
    class func getFriendshipsForUser(_ user: AppUser, completionHandler:@escaping (_ friendships: [Friendship]?, _ error: Error?) -> Void) {
        
        Firestore.firestore().collection("friendships")
            .whereField("userIds", arrayContains: user.id!)
            .whereField("status", in: ["requested", "accepted"])
            .order(by: "createdAt", descending: true)
            .getDocuments { (snapshot, error) in
                guard let documents = snapshot?.documents else {
                    completionHandler([], error)
                    return
                }
                
                self.findFriendshipUsers(fromDocuments:documents, forUser: user) { (users) in
                    
                    var friendships: [Friendship] = []
                    if let users = users {
                        friendships = self.buildFriendship(fromDocuments: documents, withFriends: users, forUser: user)
                    }
                    
                    completionHandler(friendships, error)
                    
                }
        }
    }
    
    class func getFriendsForUser(_ user: AppUser, completionHandler:@escaping (_ friends: [Friendship]?, _ friendRequests: [Friendship]?, _ error: Error?) -> Void) {
        // TODO: make this a cloud function
        self.getFriendshipsForUser(user) { (friendships, error) in
            var friends: [Friendship] = []
            var requests: [Friendship] = []
            if let friendships = friendships {
                friendships.forEach { (friendship) in
                    if friendship.status == "requested" {
                        if (friendship.initiatedBy.id != user.id) {
                            requests.append(friendship)
                        }
                    } else {
                        friends.append(friendship)
                    }
                }
            }
            
            if (friends.count == 0) {
                return completionHandler(friends, requests, error)
            }
            var friendsWithEvent: [Friendship] = []
            friends.forEach { (friendship) in
                EventsStore.getEvents(forUserId: friendship.friend.id!) { (events, error) in
                    var friendshipWithEvent = friendship
                    friendshipWithEvent.friend.currentEvent = events?.first
                    if let events = events, events.count > 1 {
                        friendshipWithEvent.friend.upcomingEvents = Array(events[1...])
                    }
                    friendsWithEvent.append(friendshipWithEvent)
                    if (friendsWithEvent.count == friends.count) {
                        completionHandler(friendsWithEvent, requests, error)
                    }
                }
            }
        }
    }
    
    class func initiateFriendship(fromUser: AppUser, toUsername: String, completionHandler:@escaping (_ success: Bool, _ error: Error?) -> Void) {
    
        // TODO: check if not friend already, or requested already (in both ways)
        UserStore.getUser(forUsername: toUsername) { (user, error) in
            if let user = user {
                
                self.friendshipExistsWithUser(user.id!, fromUserId:fromUser.id!) { (exists, error) in
                    if (exists) {
                        return completionHandler(false, NSError(domain: "You've already requested this user", code: 1, userInfo: nil))
                    }
                    let data : [String: Any] = [
                        "status": "requested",
                        "userIds": [user.id!, fromUser.id!],
                        "initiatedByUserId": fromUser.id!,
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    Firestore.firestore().collection("friendships").addDocument(data: data) { (error) in
                        completionHandler(error == nil, error)
                    }
                        
                }
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    private class func friendshipExistsWithUser(_ friendId:String, fromUserId: String, completionHandler:@escaping (_ exists: Bool, _ error: Error?) -> Void) {
        
        Firestore.firestore().collection("friendships")
            .whereField("userIds", arrayContains:friendId)
            .whereField("initiatedByUserId", isEqualTo:fromUserId)
            .getDocuments { (snapshot, error) in
                guard let documents = snapshot?.documents else {
                    completionHandler(false, error)
                    return
                }
                completionHandler(documents.count > 0, error)
        }
    }
    
    private class func updateFriendshipStatus(_ friendship: Friendship, status: String, completionHandler:@escaping (_ success: Bool, _ error: Error?) -> Void) {
    
        Firestore.firestore().collection("friendships")
            .whereField("userIds", arrayContains:friendship.friend.id!)
            .whereField("initiatedByUserId", isEqualTo:friendship.initiatedBy.id!)
            .getDocuments { (snapshot, error) in
                guard let documents = snapshot?.documents else {
                    completionHandler(false, error)
                    return
                }
                let batch = Firestore.firestore().batch()
                documents.forEach { (document) in
                    if status == "declined" {
                        batch.deleteDocument(document.reference)
                    } else {
                        batch.updateData([
                            "status": status
                        ], forDocument: document.reference)
                    }
                }
                batch.commit { (error) in
                    completionHandler(error == nil, error)
                }
        }
    }
    class func declineFriendship(_ friendship: Friendship, completionHandler:@escaping (_ success: Bool, _ error: Error?) -> Void) {
    
        self.updateFriendshipStatus(friendship, status: "declined", completionHandler: completionHandler)
    }
    
    class func acceptFriendship(_ friendship: Friendship, completionHandler:@escaping (_ success: Bool, _ error: Error?) -> Void) {
        self.updateFriendshipStatus(friendship, status: "accepted", completionHandler: completionHandler)
    }
    
    private class func buildFriendship(fromDocuments documents: [QueryDocumentSnapshot], withFriends friends: [AppUser], forUser user: AppUser) -> [Friendship] {
        var friendships: [Friendship] = []
        for document in documents {
            let data = document.data()
            var friend: AppUser? = nil
            let users = (data["userIds"] as! [String]).map { (userId) -> AppUser in
                if (userId == user.id) { return user }
                return friends.first { (appUser) -> Bool in
                    friend = appUser
                    return appUser.id == userId
                }!
            }
            let status = data["status"] as! String
            let initiadByUserId = data["initiatedByUserId"] as! String
            let initiatedBy = users.first { (appUser) -> Bool in
                return appUser.id == initiadByUserId
            }!
            let friendship = Friendship(withFriend: friend!, status: status, initiatedBy:initiatedBy)
            friendships.append(friendship)
        }
        return friendships
    }
    
    private class func findFriendshipUsers(fromDocuments documents: [QueryDocumentSnapshot], forUser user: AppUser, completionHandler:@escaping (_ users: [AppUser]?) -> Void) {
        var friendsIds :[String] = []
        for document in documents {
            let data = document.data()
            let userIds = (data["userIds"] as! [String]).filter { (userId) -> Bool in
                return userId != user.id
            }
            friendsIds.append(contentsOf: userIds)
        }
        if friendsIds.count > 0 {
            UserStore.getUsers(forUserIds: friendsIds) { (users, error) in
                completionHandler(users)
            }
        } else {
            completionHandler([])
        }
    }
}
