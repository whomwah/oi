//
//  AppDelegate.swift
//  Oi
//
//  Created by Duncan Robertson on 15/02/2019.
//  Copyright © 2019 Duncan Robertson. All rights reserved.
//

import Cocoa
import EventKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
  let popover = NSPopover()
  let reminders = Reminders()
  var enablePopupButton = false
  var eventMonitor: EventMonitor?
  
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    constructStatusBarButton()
    popover.contentViewController = RemindersViewController.freshController()
    
    eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
      if let strongSelf = self, strongSelf.popover.isShown {
        strongSelf.closePopover(sender: event)
      }
    }
    
    reminders.requestAccess { granted in
      if granted {
        self.enablePopupButton = true
        print("You have reminders access")
      } else {
        print("You need to grant reminders access")
      }
    }
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  func constructStatusBarButton() {
    if let button = statusItem.button {
      button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
      button.action = #selector(togglePopover(_:))
    }
  }
  
  func showPopover(sender: Any?) {
    if enablePopupButton {
      if let button = statusItem.button {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
      }
      eventMonitor?.start()
    }
  }
  
  func closePopover(sender: Any?) {
    popover.performClose(sender)
    eventMonitor?.stop()
  }
  
  @objc func showMessage(_ sender: Any?) {
    ProgressHUD.showInfoWithStatus("You need to do something right now!")
  }
  
  @objc func togglePopover(_ sender: Any?) {
    if popover.isShown {
      closePopover(sender: sender)
    } else {
      showPopover(sender: sender)
    }
  }
}

