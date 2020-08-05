//
//  EventFormatter.swift
//  Calm
//
//  Created by Remi Santos on 12/04/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation
import UIKit

private extension UIFont {
    func getLineSpacing(with percentage: CGFloat = 1) -> CGFloat {
        let lineSpacing: CGFloat = (self.lineHeight - self.pointSize)

        return lineSpacing * percentage
    }
}

private extension NSAttributedString {
    func capitalized() -> NSAttributedString {

        let result = NSMutableAttributedString(attributedString: self)
        result.enumerateAttributes(in: NSRange(location: 0, length: 1), options: []) {_, range, _ in
            result.replaceCharacters(in: range, with: (string as NSString).substring(with: range).uppercased())
        }
        return result
    }
}

class TextFormatter {
    
    static let shared = TextFormatter(fontSize: 16, color: nil)
    private var fontSize: CGFloat = 16
    private var color: UIColor = AppColor.textColor()
    private let defaultAttributes: [NSAttributedString.Key: Any]
    
    init(fontSize: CGFloat, color: UIColor?) {
        self.fontSize = fontSize
        if let color = color {
            self.color = color
        }
        let font = UIFont.systemFont(ofSize: self.fontSize, weight: .medium)
        let ps = NSMutableParagraphStyle()
        ps.lineSpacing = font.getLineSpacing(with: 1.4)
        self.defaultAttributes = [
            .font: font,
            .foregroundColor: self.color,
            .paragraphStyle: ps
        ]
    }
    
    func formattedString(fromString: String) -> NSAttributedString  {
        return NSAttributedString(string: fromString, attributes: defaultAttributes)
    }

    func summaryForNoEvent() -> NSAttributedString {
        return summaryForNoEvent(isCurrentUser: false)
    }
    
    func summaryForNoEvent(isCurrentUser: Bool) -> NSAttributedString {
        var summary = "nothing plannet yet"
        if (isCurrentUser) {
            summary = "you have " + summary
        }
        return self.formattedString(fromString: summary).capitalized()
    }
    
    func summaryForEvent(_ event: Event) -> NSAttributedString {
        return summaryForEvent(event, isCurrentUser: false)
    }

    func summaryForEvent(_ event: Event, isCurrentUser: Bool) -> NSAttributedString {
        return summaryForEvent(event, nextEvent: nil, isCurrentUser: isCurrentUser)
    }
    
    func summaryForEvent(_ event: Event, nextEvent: Event?, isCurrentUser: Bool) -> NSAttributedString {

        let result = self.attributedStringForEvent(event, isNextEvent: false, isCurrentUser: isCurrentUser)
        
        if let nextEvent = nextEvent {
            result.append(self.formattedString(fromString: ".\n"))
            let daysBetweenEvents = event.daysUntilEvent(nextEvent)
            let isNextEvent = daysBetweenEvents >= 0 && daysBetweenEvents < 2
            let nextEventSummary = self.attributedStringForEvent(nextEvent, isNextEvent: isNextEvent, isCurrentUser: false)
            result.append(nextEventSummary.capitalized())
        }

        return result.capitalized()
    }

    private func attributedStringForEvent(_ event: Event, isNextEvent: Bool, isCurrentUser: Bool) -> NSMutableAttributedString {
        let result = NSMutableAttributedString(string: "", attributes: defaultAttributes)
        let importantInfoAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: self.fontSize, weight: .bold), .underlineStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: self.color]

        let eventIsNow = event.eventIsNow()
        let eventIsPassed = event.eventIsPassed()
        
        // Location info
        if let location = event.location {
            var prefix = ""
            if (isCurrentUser) {
                let timeWord = (eventIsPassed ? "were" : "will be")
                prefix = eventIsNow ? "you're currently" : "you \(timeWord)"
            } else {
                prefix = eventIsNow ? "currently" : (eventIsPassed ? "was" : "will be")
            }
            prefix += " in "
            let locationInfo = NSMutableAttributedString(string: prefix, attributes: defaultAttributes)
            let place = NSAttributedString(string: location, attributes: importantInfoAttributes)
            
            locationInfo.append(place)
            result.append(locationInfo)
        }
        
        // Date Info
        if (isNextEvent) {
            let dateAttrString = NSMutableAttributedString(string: " after that", attributes: defaultAttributes)
            result.append(dateAttrString)
        } else {
            var dateInfo: String? = nil
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            var datePrefix = ""
            if let endDate = event.endDate, eventIsNow || eventIsPassed {
                let endDateString = formatter.string(from: endDate)
                datePrefix = " until "
                dateInfo = endDateString
            } else if let startDate = event.startDate {
                let startDateString = formatter.string(from: startDate)
                datePrefix = eventIsNow ? " since " : " on "
                dateInfo = startDateString
            }
            if let dateInfo = dateInfo {
                let dateAttrString = NSMutableAttributedString(string: datePrefix, attributes: defaultAttributes)
                let dateInfoAttr = NSAttributedString(string: dateInfo, attributes: importantInfoAttributes)
                dateAttrString.append(dateInfoAttr)
                result.append(dateAttrString)
            }
        }
    
        return result
    }
}
