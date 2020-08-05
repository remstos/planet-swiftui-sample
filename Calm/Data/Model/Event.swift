//
//  Event.swift
//  Calm
//
//  Created by Remi Santos on 05/04/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation

struct Event {

    var documentId: String!
    var description: String?
    var location: String?
    var startDate: Date?
    var endDate: Date?
    var current: Bool = false
    
    init(withDescription description:String?, location:String?, startDateString:String?, endDateString:String?, documentId: String!) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let startDate = startDateString != nil ? dateFormatter.date(from:startDateString!) : nil
        let endDate = endDateString != nil ? dateFormatter.date(from:endDateString!) : nil
        self.init(withDescription: description, location:location, startDate: startDate, endDate: endDate, documentId: documentId)
    }
    
    init(withDescription desc:String?, location loc:String?, startDate sDate:Date?, endDate eDate:Date?, documentId ID: String) {
        description = desc
        location = loc
        startDate = sDate
        endDate = eDate
        documentId = ID
    }
    
    func eventIsPassed() -> Bool {
        if let endDate = self.endDate {
            let endDatePassed = endDate.timeIntervalSinceNow < 0
            return endDatePassed
        }
        return false
    }
    
    func eventIsNow() -> Bool {
        if let startDate = self.startDate, let endDate = self.endDate {
            let startDatePassed = startDate.timeIntervalSinceNow < 0
            let endDatePassed = endDate.timeIntervalSinceNow < 0
            return startDatePassed && !endDatePassed
        }
        return false
    }
    
    func daysUntilEvent(_ otherEvent:Event) -> Int {
        guard let otherStartDate = otherEvent.startDate, let endDate = self.endDate else {
            return -1
        }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: otherStartDate)
        let end = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: end, to: start)
        return components.day ?? -1
    }
}
