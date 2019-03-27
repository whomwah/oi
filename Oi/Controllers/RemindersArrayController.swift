//
//  RemindersArrayController.swift
//  Oi
//
//  Created by Duncan Robertson on 22/03/2019.
//  Copyright © 2019 Duncan Robertson. All rights reserved.
//

import Cocoa

class RemindersArrayController: NSArrayController {
  func calendarIDs() -> Array<String> {
    return (arrangedObjects as! Array<Reminder>).map {rem in rem.calendarItemIdentifier}
  }
  
  func findByCalendarID(_ calendarID: String) -> Reminder? {
    if let reminder = (arrangedObjects as! Array<Reminder>).find(where: { $0.calendarItemIdentifier == calendarID }) {
      return reminder
    } else {
      return nil;
    }
  }
}

// MARK: Reminder persistence

extension RemindersArrayController {
  func addReminder(_ calendarID: String) {
    let reminder = findByCalendarID(calendarID)
    
    if (reminder != nil && !storedCalendarIDExists(calendarID)) {
      var list = storedCalendarIDs()
      list.append(calendarID)
      
      UserDefaults.standard.set(list, forKey: OiUserDefaultsStorageKey)
      syncStoredCalendarIDs()
      
//      let timer = Timer.init(
//        fireAt: reminder?.dueDate.date,
//        interval: 0,
//        target: self,
//        selector: #selector(logMe(_:)),
//        userInfo: calendarID,
//        repeats: false
//      )
//      RunLoop.main.add(timer, forMode: .common)
      //timer.invalidate()
    }
  }
  
//  @objc func logMe(_ sender: Timer) {
//    print("Timer finished! \(sender.userInfo)")
//  }
  
  func removeReminder(_ calendarID: String) {
    var list = storedCalendarIDs()
    list.removeAll { $0 == calendarID }
    
    UserDefaults.standard.set(list, forKey: OiUserDefaultsStorageKey)
    syncStoredCalendarIDs()
  }
  
  func storedCalendarIDs() -> [String] {
    if ((UserDefaults.standard.array(forKey: OiUserDefaultsStorageKey)) != nil){
      return (UserDefaults.standard.array(forKey: OiUserDefaultsStorageKey) as? [String])!
    } else {
      return []
    }
  }
  
  func storedCalendarIDExists(_ calendarID: String) -> Bool {
    return storedCalendarIDs().contains(calendarID)
  }
  
  func syncStoredCalendarIDs() {
    pruneExtrasStored()
    
    print("Current IDS: \(calendarIDs())")
    print("Stored  IDS: \(storedCalendarIDs())")
    print("===================================")
  }
  
  private func pruneExtrasStored() {
    let calendarIDsSet = Set(calendarIDs())
    let storedCalendarIDsSet = Set(storedCalendarIDs())
    
    for calendarID in storedCalendarIDsSet.subtracting(calendarIDsSet) {
      removeReminder(calendarID)
    }
  }
}
