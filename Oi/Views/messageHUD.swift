//
//  messageHUD.swift
//  Oi
//
//  Created by Duncan Robertson on 20/02/2019.
//  Copyright © 2019 Duncan Robertson. All rights reserved.
//

import AppKit

typealias ProgressHUDDismissCompletion = () -> Void

class ProgressHUD: NSView {
  
  static let shared = ProgressHUD()

  private var containerView: NSView?
  private var font = NSFont.boldSystemFont(ofSize: 100)
  private var opacity: CGFloat = 0.9
  private var margin: CGFloat = 28.0
  private var padding: CGFloat = 4.0
  private var cornerRadius: CGFloat = 15.0
  private var foregroundColor: NSColor = .init(white: 0.95, alpha: 1)
  private var backgroundColor: NSColor = .init(white: 0.25, alpha: 1)
  
  private override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    
    autoresizingMask = [.maxXMargin, .minXMargin, .maxYMargin, .minYMargin]
    alphaValue = 0.0
    isHidden = true
    
    // setup status message label
    statusLabel.font = font
    statusLabel.isEditable = false
    statusLabel.isSelectable = false
    statusLabel.alignment = .center
    statusLabel.backgroundColor = .clear
    addSubview(statusLabel)
    
    // setup window into which to display the HUD
    let screen = NSScreen.screens[0]
    let window = NSWindow(
      contentRect: screen.frame,
      styleMask: .borderless,
      backing: .buffered,
      defer: true,
      screen: screen
    )
    window.level = .floating
    window.backgroundColor = .clear
    windowController = NSWindowController(window: window)
  }
  
  required init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  class func showInfoWithStatus(_ status: String) {
    ProgressHUD.shared.show(withStatus: status)
  }
  
  // MARK: - Private Properties
  
  private var indicator: NSView?
  private var size: CGSize = .zero
  private let statusLabel = NSText(frame: .zero)
  private var completionHandler: ProgressHUDDismissCompletion?
  private var yOffset: CGFloat = 0
  private var hudView: NSView? {
    if let view = containerView {
      windowController?.close()
      return view
    }
    windowController?.showWindow(self)
    return windowController?.window?.contentView
  }
  private var windowController: NSWindowController?
  
  // MARK: - Private Show & Hide methods
  
  private func show(withStatus status: String) {
    guard let view = hudView else { return }
    if isHidden {
      frame = view.frame
      view.addSubview(self)
    }
    setStatus(status)
    show()
  }
  
  private func show() {
    NotificationCenter.default.post(name: ProgressHUD.willAppear, object: self)
    needsDisplay = true
    isHidden = false

    // Fade in
    NSAnimationContext.beginGrouping()
    NSAnimationContext.current.duration = 0.20
    NSAnimationContext.current.completionHandler = {
      NotificationCenter.default.post(name: ProgressHUD.didAppear, object: self)
    }
    animator().alphaValue = 1.0
    NSAnimationContext.endGrouping()
  }
  
  private func hide() {
    NotificationCenter.default.post(name: ProgressHUD.willDisappear, object: self)
    NSObject.cancelPreviousPerformRequests(withTarget: self)

    // Fade out
    NSAnimationContext.beginGrouping()
    NSAnimationContext.current.duration = 0.20
    NSAnimationContext.current.completionHandler = {
      self.done()
    }
    animator().alphaValue = 0
    NSAnimationContext.endGrouping()
  }
  
  private func done() {
    alphaValue = 0.0
    isHidden = true
    removeFromSuperview()
    completionHandler?()
    indicator?.removeFromSuperview()
    indicator = nil
    statusLabel.string = ""
    windowController?.close()
    NotificationCenter.default.post(name: ProgressHUD.didDisappear, object: self)
  }
  
  private func setStatus(_ status: String) {
    statusLabel.textColor = foregroundColor
    statusLabel.font = font
    statusLabel.string = status
    statusLabel.sizeToFit()
  }
  
  override func mouseDown(with theEvent: NSEvent) {
    NotificationCenter.default.post(name: ProgressHUD.didReceiveMouseDownEvent, object: self)
    
    DispatchQueue.main.async {
      self.hide()
    }
  }
  
  // MARK: - Layout & Drawing
  
  func layoutSubviews() {
    
    // Entirely cover the parent view
    frame = superview?.bounds ?? .zero
    
    // Determine the total width and height needed
    let maxWidth = bounds.size.width - margin * 4
    var totalSize = CGSize.zero
    var statusLabelSize: CGSize = statusLabel.string.count > 0 ? statusLabel.string.size(withAttributes: [NSAttributedString.Key.font: statusLabel.font!]) : CGSize.zero
    if statusLabelSize.width > 0.0 {
      statusLabelSize.width += 10.0
    }
    statusLabelSize.width = min(statusLabelSize.width, maxWidth)
    totalSize.width = max(totalSize.width, statusLabelSize.width)
    totalSize.height += statusLabelSize.height
    totalSize.width += margin * 2
    totalSize.height += margin * 2
    
    // Position elements
    let yPos = round((bounds.size.height - totalSize.height) / 2) + margin - yOffset
    let xPos: CGFloat = 0
    
    var statusLabelFrame = CGRect.zero
    statusLabelFrame.origin.y = yPos
    statusLabelFrame.origin.x = round((bounds.size.width - statusLabelSize.width) / 2) + xPos
    statusLabelFrame.size = statusLabelSize
    statusLabel.frame = statusLabelFrame
    
    size = totalSize
  }
  
  override func draw(_ rect: NSRect) {
    layoutSubviews()
    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    
    context.setFillColor(NSColor.black.withAlphaComponent(0.6).cgColor)
    rect.fill()
    
    // Set background rect color
    context.setFillColor(backgroundColor.withAlphaComponent(opacity).cgColor)
    
    // Center HUD
    let allRect = bounds
    
    // Draw rounded HUD backgroud rect
    let boxRect = CGRect(x: round((allRect.size.width - size.width) / 2),
                         y: round((allRect.size.height - size.height) / 2) - yOffset,
                         width: size.width, height: size.height)
    let radius = cornerRadius
    context.beginPath()
    context.move(to: CGPoint(x: boxRect.minX + radius, y: boxRect.minY))
    context.addArc(center: CGPoint(x: boxRect.maxX - radius, y: boxRect.minY + radius), radius: radius, startAngle: .pi * 3 / 2, endAngle: 0, clockwise: false)
    context.addArc(center: CGPoint(x: boxRect.maxX - radius, y: boxRect.maxY - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
    context.addArc(center: CGPoint(x: boxRect.minX + radius, y: boxRect.maxY - radius), radius: radius, startAngle: .pi / 2, endAngle: .pi, clockwise: false)
    context.addArc(center: CGPoint(x: boxRect.minX + radius, y: boxRect.minY + radius), radius: radius, startAngle: .pi, endAngle: .pi * 3 / 2, clockwise: false)
    context.closePath()
    context.fillPath()
    
    NSGraphicsContext.restoreGraphicsState()
  }
  
  static let didReceiveMouseDownEvent = Notification.Name("ProgressHUD.didReceiveMouseDownEvent")
  static let willDisappear = Notification.Name("ProgressHUD.willDisappear")
  static let didDisappear = Notification.Name("ProgressHUD.didDisappear")
  static let willAppear = Notification.Name("ProgressHUD.willAppear")
  static let didAppear = Notification.Name("ProgressHUD.didAppear")
}
