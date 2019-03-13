//
//  OiRemindersStore.swift
//  Oi
//
//  Created by Duncan Robertson on 22/02/2019.
//  Copyright © 2019 Duncan Robertson. All rights reserved.
//

import EventKit

extension Collection {
  func find(where predicate: (Iterator.Element) throws -> Bool) rethrows -> Iterator.Element? {
    return try self.index(where: predicate).flatMap { self[$0] }
  }
}

extension Collection where Index == Int {
  subscript(safe index: Int) -> Iterator.Element? {
    return index < self.count && index >= 0 ? self[index] : nil
  }
}

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
  
  func fetchAndPopulate(arrayController: NSArrayController) {
    arrayController.content = nil // nuke everything !!!
    
    let Reminderlists = self.getRemindLists()
    
    for reminderList in Reminderlists {
      let semaphore = DispatchSemaphore(value: 0)
      let calendar = self.calendar(withName: reminderList.title)

      self.reminders(onCalendar: calendar) { reminders in
        for (i, reminder) in reminders.enumerated() {
          
          let rem = Reminder(
            title: reminder.title,
            dueDate: reminder.dueDateComponents!,
            calendarItemIdentifier: reminder.calendarItemIdentifier
          )
          
          print(i, rem.title)
          arrayController.addObject(rem)
        }
        semaphore.signal()
      }
      
      semaphore.wait()
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
    let predicate = self.eventStore.predicateForIncompleteReminders(
      withDueDateStarting: Date(),
      ending: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
      calendars: [calendar]
    )
    
    self.eventStore.fetchReminders(matching: predicate) {reminders in
      completion(reminders ?? [])
    }
  }
  
  private func calendar(withName name: String) -> EKCalendar {
    if let calendar = self.getRemindLists().find(where: { $0.title.lowercased() == name.lowercased() }) {
      return calendar
    } else {
      print("No reminders list matching \(name)")
      exit(1)
    }
  }
  
  private func getRemindLists() -> [EKCalendar] {
    return self.eventStore.calendars(for: .reminder)
      .filter { $0.allowsContentModifications }
  }
}
