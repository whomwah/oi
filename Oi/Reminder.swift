//
//  Reminder.swift
//  Oi
//
//  Created by Duncan Robertson on 05/03/2019.
//  Copyright © 2019 Duncan Robertson. All rights reserved.
//

import Foundation

class Reminder: NSObject {
  @objc var title: String
  @objc var dueDate: String
  
  init(title: String, dueDate: DateComponents) {
    self.title = title
    self.dueDate = Reminder.formatDate(dueDate)
  }
  
  class func formatDate(_ date: DateComponents) -> String {
    let calendar = Calendar.current
    let dateObj = calendar.date(from: date)!
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM dd, yyyy 'at' hh:mm:ss a 'UTC'Z"
    formatter.timeZone = TimeZone(abbreviation: "IST")
  
    return formatter.string(from: dateObj)
  }
}
