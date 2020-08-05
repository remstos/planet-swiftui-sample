//
//  EventsStore.swift
//  Calm
//
//  Created by Remi Santos on 05/04/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation
import FirebaseFirestore

private extension Event {
    init(withFirestoreDocument document:QueryDocumentSnapshot) {
        let data = document.data()
        
        let description = data["description"] as? String
        let location = data["location"] as? String
        let startDate = (data["startDate"] as? Timestamp)?.dateValue()
        let endDate = (data["endDate"] as? Timestamp)?.dateValue()

        self.init(withDescription: description, location: location, startDate: startDate, endDate: endDate, documentId: document.documentID)
        self.current = self.eventIsNow()
    }
    
    func convertToFirestoreData(forUser appUser:AppUser) -> [String:Any] {
        var data : [String: Any] = [
            "userId": appUser.id!
        ]
        if let desc = self.description {
            data["description"] = desc
        }
        if let loc = self.location {
            data["location"] = loc
        }
        if let startDate = self.startDate {
            data["startDate"] = Timestamp(date: startDate)
        }
        if let endDate = self.endDate {
            data["endDate"] = Timestamp(date: endDate)
        }
        data["createdAt"] = FieldValue.serverTimestamp()
        return data
    }
}
class EventsStore {
    class func getEvents(forUserId userId: String, completionHandler:@escaping (_ events: [Event]?, _ error: Error?) -> Void) {
        
        Firestore.firestore().collection("events")
            .whereField("userId", isEqualTo: userId)
            .order(by: "startDate")
            .getDocuments { (snapshot, error) in
            var events: [Event]? = []
            if let documents = snapshot?.documents {
                for document in documents {
                    let event = Event(withFirestoreDocument: document)
                    events?.append(event)
                }
            }
            completionHandler(events, error)
        }
    }
    
    class func deleteEvent(event: Event, completionHandler:@escaping (_ error: Error?) -> Void) {
        Firestore.firestore().collection("events").document(event.documentId).delete { (error) in
            print("Deleted event '\(String(describing: event.description))")
            completionHandler(error)
        }
    }
    
    class func createEvent(event: Event, forUser appUser: AppUser, completionHandler:@escaping (_ error: Error?) -> Void) {
        let data = event.convertToFirestoreData(forUser: appUser)
        Firestore.firestore().collection("events").addDocument(data: data) { (error) in
            print("Created event '\(String(describing: event.description))")
            completionHandler(error)
        }
    }
}
