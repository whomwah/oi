//
//  OiRemindersStore.swift
//  Oi
//
//  Created by Duncan Robertson on 22/02/2019.
//  Copyright © 2019 Duncan Robertson. All rights reserved.
//

import EventKit

final class OiRemindersStore: NSObject {
  var eventStore: EKEventStore
    
  static let shared = OiRemindersStore()
  
  private override init() {
    eventStore = EKEventStore()
    super.init()
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(OiRemindersStore.onDidReceiveData(_:)),
      name: NSNotification.Name.EKEventStoreChanged,
      object: eventStore
    )
  }
  
    
  func requestAccess(completion: @escaping (_ granted: Bool) -> Void) {
    self.eventStore.requestAccess(to: .reminder) { granted, _ in
      DispatchQueue.main.async {
        completion(granted)
      }
    }
  }
  
  func fetchAndPopulate(arrayController: RemindersArrayController) {    
    let Reminderlists = getRemindLists()
    let semaphore = DispatchSemaphore(value: 0)
    
    for reminderList in Reminderlists {
      let calendar = self.calendar(withName: reminderList.title)
      
      self.reminders(onCalendar: calendar) { reminders in        
        for (_, reminder) in reminders.enumerated() {
          let rem = Reminder(
            enabled: arrayController.storedCalendarIDExists(reminder.calendarItemIdentifier) ? true : false,
            title: reminder.title,
            dueDate: reminder.dueDateComponents!,
            calendarItemIdentifier: reminder.calendarItemIdentifier
          )
          
          arrayController.addObject(rem)
        }
        semaphore.signal()
      }
      
      semaphore.wait()
    }
    
    DispatchQueue.main.async {
      NotificationCenter.default.post(
        name: Notification.Name(OiActiveCalenderIDsNotification),
        object: self
      )
    }
  }
  
  @objc func onDidReceiveData(_ notification: Notification) {
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: Notification.Name(OiRefreshDataNotification), object: self)
    }
  }
  
  // MARK: - Private functions
  
  private func reminders(onCalendar calendar: EKCalendar,
                         completion: @escaping (_ reminders: [EKReminder]) -> Void)
  {
    let predicate = eventStore.predicateForIncompleteReminders(
      withDueDateStarting: Date(),
      ending: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
      calendars: [calendar]
    )
    
    eventStore.fetchReminders(matching: predicate) {reminders in
      completion(reminders ?? [])
    }
  }
  
  private func calendar(withName name: String) -> EKCalendar {
    if let calendar = getRemindLists().find(where: { $0.title.lowercased() == name.lowercased() }) {
      return calendar
    } else {
      print("No reminders list matching \(name)")
      exit(1)
    }
  }
  
  private func getRemindLists() -> [EKCalendar] {
    return eventStore.calendars(for: .reminder).filter { $0.allowsContentModifications }
  }
}
