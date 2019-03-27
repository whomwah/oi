//
//  Reminder.swift
//  Oi
//
//  Created by Duncan Robertson on 05/03/2019.
//  Copyright © 2019 Duncan Robertson. All rights reserved.
//

import Foundation

class Reminder: NSObject {
  @objc var enabled: Bool
  @objc var title: String
  @objc var dueDate: DateComponents
  @objc var calendarItemIdentifier: String
  
  init(enabled: Bool, title: String, dueDate: DateComponents, calendarItemIdentifier: String) {
    self.enabled = enabled
    self.title = title
    self.calendarItemIdentifier = calendarItemIdentifier
    self.dueDate = dueDate
  }
  
  @objc func dueDateAsString() -> String {
    let calendar = Calendar.current
    let dateObj = calendar.date(from: self.dueDate)!
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    formatter.doesRelativeDateFormatting = true
  
    return formatter.string(from: dateObj)
  }
}
