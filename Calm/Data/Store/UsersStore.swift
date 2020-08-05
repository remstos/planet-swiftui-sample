//
//  UserStore.swift
//  Calm
//
//  Created by Remi Santos on 05/04/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension AppUser {
    init(withDocument:QueryDocumentSnapshot) {
        let userData = withDocument.data()
        self.init(withDocumentData: userData, uid: withDocument.documentID)
    }

    init(withDocumentData documentData:[String: Any], uid: String) {
        let username = documentData["username"] as! String
        let email = documentData["email"] as! String
        let color = PaletteColor.paletteColorFromCode(documentData["color"] as! String)
        let emoji = documentData["emoji"] as! String
        self.init(withUsername: username, email: email, color: color, emoji:emoji, uid: uid)
    }
}

class UserStore {
    class func getAppUser(forAuthId authId: String, completion:@escaping (_ appUser: AppUser?, _ error: Error?) -> Void) {
        
        Firestore.firestore().collection("users")
            .whereField("authId", isEqualTo: authId)
            .getDocuments { (snapshot, error) in
            var appUser: AppUser? = nil
            if let documents = snapshot?.documents, let document = documents.first {
                appUser = AppUser(withDocument: document)
                EventsStore.getEvents(forUserId: appUser!.id!) { (events, error) in
                    appUser!.currentEvent = events?.first
                    if let events = events, events.count > 1 {
                        appUser!.upcomingEvents = Array(events[1...])
                    }
                    completion(appUser, error)
                }
            } else {
                completion(appUser, error)
            }
        }
    }
    
    class func getUsers(forUserIds userIds: [String], completion:@escaping (_ users: [AppUser]?, _ error: Error?) -> Void) {
        
        Firestore.firestore().collection("users")
            .whereField(FieldPath.documentID(), in:userIds)
            .getDocuments { (snapshot, error) in
            var users: [AppUser] = []
            if let documents = snapshot?.documents {
                for document in documents {
                    users.append(AppUser(withDocument: document))
                }
            }
            completion(users, error)
        }
    }
    
    class func getUser(forUsername username: String, completion:@escaping (_ users: AppUser?, _ error: Error?) -> Void) {
        
        Firestore.firestore().collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments { (snapshot, error) in
                var user: AppUser?
                if let documents = snapshot?.documents, let document = documents.first {
                    user = AppUser(withDocument: document)
                }
                completion(user, error)
        }
    }

    class func createUser(withAuthId: String, username: String, email: String, color: String, emoji: String, completion:@escaping (_ users: AppUser?, _ error: Error?) -> Void) {
        let userData = [
            "authId": withAuthId,
            "username": username,
            "email": email,
            "color": color,
            "emoji": emoji,
            "createdAt": FieldValue.serverTimestamp()
            ] as [String : Any]
        var ref: DocumentReference? = nil
        ref = Firestore.firestore().collection("users").addDocument(data: userData) { (error) in
            var appUser :AppUser? = nil
            if let userReference = ref {
                appUser = AppUser.init(withDocumentData: userData, uid: userReference.documentID)
            }
            completion(appUser, error)
        }
    }

    
}
