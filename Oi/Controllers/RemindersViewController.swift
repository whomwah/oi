//
//  RemindersViewController.swift
//  Oi
//
//  Created by Duncan Robertson on 28/02/2019.
//  Copyright © 2019 Duncan Robertson. All rights reserved.
//

import Cocoa

class RemindersViewController: NSViewController {
  @IBOutlet var reminderAC: RemindersArrayController!
  
  var rsObservers: [AnyObject] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    let mainQueue = OperationQueue.main
    let center = NotificationCenter.default

    let reminders = OiRemindersStore.shared
    reminders.requestAccess { granted in
      if granted {
        reminders.fetchAndPopulate(arrayController: self.reminderAC)
      }
    }
    
    let refreshData = center.addObserver(
      forName: NSNotification.Name(OiRefreshDataNotification),
      object: reminders,
      queue: mainQueue
    ) {[weak self] note in
      self?.handleOiRefreshDataNotification(note)
    }
    
    let latestCalendarIDs = center.addObserver(
      forName: NSNotification.Name(OiActiveCalenderIDsNotification),
      object: reminders,
      queue: mainQueue
    ) {[weak self] note in
      self?.handleOiActiveCalenderIDsNotification(note)
    }
    
    self.rsObservers = [refreshData, latestCalendarIDs]
  }
  
  deinit {
    // Unregister for all observers saved in rsObservers
    for anObserver in self.rsObservers {
      NotificationCenter.default.removeObserver(anObserver)
    }
  }
}

// MARK: Notification handlers

extension RemindersViewController {
  private func handleOiRefreshDataNotification(_ notification: Notification) {
    reminderAC.content = nil
    OiRemindersStore.shared.fetchAndPopulate(arrayController: reminderAC)
  }
  
  private func handleOiActiveCalenderIDsNotification(_ notification: Notification) {
    reminderAC.syncStoredCalendarIDs()
  }
}

// MARK: Actions

extension RemindersViewController {
  @IBAction func openMenu(_ sender: NSButton) {
    if let event = NSApplication.shared.currentEvent {
      let menu = NSMenu()
      menu.addItem(NSMenuItem(title: "Show Message", action: #selector(AppDelegate.showMessage(_:)), keyEquivalent: "P"))
      menu.addItem(NSMenuItem.separator())
      menu.addItem(NSMenuItem(title: "Quit Oi", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
      
      NSMenu.popUpContextMenu(menu, with: event, for: sender)
    }
  }
  
  @IBAction func reminderClicked(_ sender: NSButton) {
    for reminder in reminderAC!.arrangedObjects as! [Reminder] {
      if reminder.calendarItemIdentifier == sender.title {
        if (sender.state == NSControl.StateValue.on) {
          reminderAC.addReminder(reminder.calendarItemIdentifier)
        } else {
          reminderAC.removeReminder(reminder.calendarItemIdentifier)
        }
      }
    }
  }
}

// MARK: Storyboard instantiation

extension RemindersViewController {
  static func freshController() -> RemindersViewController {
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    let identifier = NSStoryboard.SceneIdentifier("RemindersViewController")

    guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? RemindersViewController else {
      fatalError("Why cant i find RemindersViewController? - Check Main.storyboard")
    }
    return viewcontroller
  }
}
