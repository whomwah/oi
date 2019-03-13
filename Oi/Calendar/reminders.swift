//
//  reminders.swift
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

private let Store = EKEventStore()

final class Reminders {
  func requestAccess(completion: @escaping (_ granted: Bool) -> Void) {
    Store.requestAccess(to: .reminder) { granted, _ in
      DispatchQueue.main.async {
        completion(granted)
      }
    }
  }
  
  func fetchAndPopulate(arrayController: NSArrayController) {
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
  
  func listenForChanges() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(Reminders.onDidReceiveData(_:)),
      name: .EKEventStoreChanged,
      object: Store
    )
  }
  
  @objc func onDidReceiveData(_ notification: Notification) {
    print("An reminder has changed!")
  }
  
  // MARK: - Private functions
  
  private func reminders(onCalendar calendar: EKCalendar,
                         completion: @escaping (_ reminders: [EKReminder]) -> Void)
  {
    let predicate = Store.predicateForReminders(in: [calendar])
    Store.fetchReminders(matching: predicate) { reminders in
      let reminders = reminders?
        .filter { !$0.isCompleted }
        .filter { ($0.dueDateComponents != nil) }
        .sorted { ($0.creationDate ?? Date.distantPast) < ($1.creationDate ?? Date.distantPast) }
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
    return Store.calendars(for: .reminder)
      .filter { $0.allowsContentModifications }
  }
}
