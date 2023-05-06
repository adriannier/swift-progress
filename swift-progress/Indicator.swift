//
//  Indicator.swift
//  swift-progress
//
//  Created by Adrian Nier on 2020-05-26.
//  Copyright © 2020 Adrian Nier. All rights reserved.
//

import Cocoa

@objc(Indicator) class Indicator: NSObject, NSWindowDelegate {
    
    // MARK: -
    // MARK: Support
    
    let appDelegate: AppDelegate
    var cancelTimer = Timer()
    var cancelTime: Date?
    let cancelTimeout = 15.0
    
    var indeterminateTimer = Timer()
    let indeterminateTimeout = 15.0
    
    // MARK: -
    // MARK: Properties
    
    @objc let id: String
    
    @objc var title: String {
        get {
            return currentState.valueForKey("title") as! String
        }
        set {
            update(["title": newValue])
        }
    }
    @objc var message: String {
        get {
            return currentState.valueForKey("message") as! String
        }
        set {
            update(["message": newValue])
        }
    }
    @objc var percentage: Double {
        get {
            return currentState.valueForKey("percentage") as! Double
        }
        set {
            update(["percentage": newValue])
        }
    }
    @objc var icon: String {
        get {
            return currentState.valueForKey("icon") as! String
        }
        set {
            update(["icon": newValue])
        }
    }
    @objc var completed: Bool {
        get {
            return currentState.valueForKey("completed") as! Bool
        }
        set {
            update(["completed": newValue])
        }
    }
    @objc var aborted: Bool {
        get {
            return currentState.valueForKey("aborted") as! Bool
        }
        set {
            update(["aborted": newValue])
        }
    }
    @objc var canceled: Bool {
        get {
            return currentState.valueForKey("canceled") as! Bool
        }
        set {
            update(["canceled": newValue])
        }
    }
    
    @objc var isVisible: Bool {
        get {
            return currentState.valueForKey("isVisible") as! Bool
        }
        set {
            update(["isVisible": newValue])
        }
    }
    
    // MARK: -
    // MARK: User interface
    
    let window = NSWindow()
    let titleField = NSTextField()
    let messageField = NSTextField()
    let progressBar = NSProgressIndicator()
    let iconView = NSImageView()
    let cautionView = NSImageView()
    let cancelButton = NSButton()
    
    // MARK: -
    // MARK: Geometry
    
    let progressBarWidthShort = 358
    let progressBarWidthLong = 378
    
    let windowWidthWithIcon = 480
    let windowWidthWithoutIcon = 416
    let windowHeight = 91
    
    let verticalMargin = 8
    
    // MARK: -
    // MARK: State

    var showingForFirstTime = true
    var currentState = IndicatorState()

    // MARK: -
    // MARK: Initializers
    
    convenience init(state: IndicatorState) {
        
        self.init()
        update(state)
        
    }
    
    override init() {
        
        self.id = UUID().uuidString
        self.appDelegate = NSApp.delegate as! AppDelegate
        
        super.init()
        
        initalizeUserInterface()
        setupUserInterfaceGeometry()
        
        update(defaultIndicatorState())
        
        startIndeterminateTimer()
        
        debugLog("Indicator[\(id)] Created indicator \(self.id)")
        
    }
    
    func update(_ state: IndicatorState) {
         
        var newTitle: String?
        if let title = state.title, title != self.title { newTitle = title }
        
        var newMessage: String?
        if let message = state.message, message != self.message { newMessage = message }
        
        var newPercentage: Double?
        if let percentage = state.percentage, percentage != self.percentage { newPercentage = percentage }
        
        var newIcon: String?
        if let icon = state.icon, icon != self.icon { newIcon = icon }
        
        var newCompleted: Bool?
        if let completed = state.completed, completed == true { newCompleted = true }
        
        var newAborted: Bool?
        if let aborted = state.aborted, aborted == true { newAborted = true }
        
        var newCanceled: Bool?
        if let canceled = state.canceled, canceled == true { newCanceled = true }
        
        var newVisible: Bool?
        if let isVisible = state.isVisible, isVisible != self.isVisible { newVisible = isVisible }
        
        if newTitle != nil {
            infoLog("Indicator[\(id)] Changing title to \"\(newTitle!)\"")
            updateTitle(newTitle!)
            currentState = modifiedIndicatorState(currentState: currentState, newState: IndicatorState(title: newTitle))
        }
        if newMessage != nil {
            debugLog("Indicator[\(id)] Changing message to \"\(newMessage!)\"")
            updateMessage(newMessage!)
            currentState = modifiedIndicatorState(currentState: currentState, newState: IndicatorState(message: newMessage))
        }
        
        // isVisible
        if newVisible != nil {
            
            if newVisible! {
                infoLog("Indicator[\(id)] Showing")
                show()
            } else {
                infoLog("Indicator[\(id)] Hiding")
                hide()
            }
            
            currentState = modifiedIndicatorState(currentState: currentState, newState: IndicatorState(isVisible: newVisible))
        
        }
        
        // Icon
        if newIcon != nil {
            infoLog("Indicator[\(id)] Changing icon to \(newIcon!)")
            setIcon(newIcon!)
            currentState = modifiedIndicatorState(currentState: currentState, newState: IndicatorState(icon: newIcon))
        }
        
        if ( newPercentage != nil ) ||
            ( newCompleted != nil && newCompleted! == true ) ||
            ( newAborted != nil && newAborted! == true ) ||
            ( newCanceled != nil && newCanceled! == true ) {
            
            if canceled && newPercentage != -1 {
                
                debugLog("Indicator[\(id)] Cannot modify a canceled indicator")
                
                NSScriptCommand.current()?.scriptErrorNumber = -128
                NSScriptCommand.current()?.scriptErrorString = "User canceled."
                
            } else if aborted {
                
                debugLog("Indicator[\(id)] Cannot modify an aborted indicator")
                
                NSScriptCommand.current()?.scriptErrorNumber = 1
                NSScriptCommand.current()?.scriptErrorString = "Cannot modify an aborted indicator."
                
            } else if completed {
                
                debugLog("Indicator[\(id)] Cannot modify a completed indicator")
                
                NSScriptCommand.current()?.scriptErrorNumber = 1
                NSScriptCommand.current()?.scriptErrorString = "Cannot modify a completed indicator."
                
            } else {
                
                if newPercentage != nil {
                    
                    if newPercentage! > 0.0 {
                        
                        debugLog("Indicator[\(id)] Changing percentage to \(newPercentage!)")
                        
                        stopIndeterminateTimer()
                        
                        showProgressBar(withCancelButton: true)
                        progressBar.isIndeterminate = false
                        progressBar.doubleValue = newPercentage!
                        
                        currentState = modifiedIndicatorState(currentState: currentState, newState: IndicatorState(percentage: newPercentage!))
                        
                        if (Float(newPercentage!) == 100.0) {
                            update(["completed": true])
                        }
                        
                        
                        
                    } else {
                        
                        infoLog("Indicator[\(id)] Displaying progress bar as indeterminate")
                        
                        if newCanceled == nil {
                            startIndeterminateTimer()
                            showProgressBar(withCancelButton: false)
                        } else {
                            showProgressBar(withCancelButton: true)
                        }
                       
                        progressBar.doubleValue = newPercentage!
                        progressBar.isIndeterminate = true
                        progressBar.startAnimation(nil)
                        
                        currentState = modifiedIndicatorState(currentState: currentState, newState: IndicatorState(percentage: newPercentage!))
                        
                    }
                    
                }
                
                // Completed
                if newCompleted != nil && newCompleted! == true {
                    
                    infoLog("Indicator[\(id)] Marking as completed")
                    
                    if let visible = currentState.isVisible, !visible {
                        update(IndicatorState(isVisible: true))
                    }
                    
                    updateMessage("")
                    hideProgressBar()
                    stopCancelTimer()
                    stopIndeterminateTimer()
                    window.standardWindowButton(.closeButton)?.isEnabled = true
                    
                    currentState = modifiedIndicatorState(currentState: currentState, newState: IndicatorState(completed: true))
                    
                    // NSApp.activate(ignoringOtherApps: true)
                    
                }
                
                // Aborted
                if newAborted != nil && newAborted! == true {
                    
                    infoLog("Indicator[\(id)] Marking as aborted")
                    
                    if let visible = currentState.isVisible, !visible {
                        update(IndicatorState(isVisible: true))
                    }
                    
                    hideProgressBar()
                    stopCancelTimer()
                    stopIndeterminateTimer()
                    
                    if window.isVisible {
                        cautionView.animator().alphaValue = 1.0
                    } else {
                        cautionView.alphaValue = 1.0
                    }
                    
                    window.standardWindowButton(.closeButton)?.isEnabled = true
                    
                    currentState = modifiedIndicatorState(currentState: currentState, newState: IndicatorState(aborted: true))
                    
                    // NSApp.activate(ignoringOtherApps: true)
                    
                }
                
                // Canceled
                if newCanceled != nil && newCanceled! == true {
                    
                    infoLog("Indicator[\(id)] Marking as canceled")
                    
                    if let visible = currentState.isVisible, !visible {
                        update(IndicatorState(isVisible: true))
                    }
                    
                    if appDelegate.isJsonBasedIndicator(self) {
                        
                        if appDelegate.json_writeCancelFile() {
                            startCancelTimer()
                        }
                        
                    } else {
                        
                        startCancelTimer()
                        
                    }
                    
                    currentState = modifiedIndicatorState(currentState: currentState, newState: IndicatorState(canceled: true))
                    
                    // NSApp.activate(ignoringOtherApps: true)
                    
                }
                
            }

        }

        if progressBar.isIndeterminate {
            restartIndeterminateTimer()
        }
        
    }
    
    func update(_ dict: Dictionary<String, Any?>?) {
        
        if dict != nil {
            
            var state = IndicatorState()
            
            if let dictKeys = dict?.keys {
                for valueName in dictKeys {
                    state.setValueForKey(valueName, value: dict![valueName])
                }
            }
            
            update(state)
            
        }
        
    }
    
    private func updateTitle(_ str: String) {
        
        if str.isEmpty {
        
            debugLog("Indicator[\(id)] Clearing title")
            titleField.stringValue = str
            titleField.isHidden = true
        
        } else {
        
            debugLog("Indicator[\(id)] Setting title to \(str)")
            titleField.stringValue = str
            titleField.sizeToFit()
            titleField.isHidden = false
        
        }
        
    }
    
    private func updateMessage(_ str: String) {
    
        if str.isEmpty {
        
            debugLog("Indicator[\(id)] Clearing message")
            messageField.isHidden = true
            messageField.toolTip = str
            messageField.stringValue = str
        
        } else {
         
            debugLog("Indicator[\(id)] Setting message to \(str)")
            messageField.toolTip = str
            messageField.stringValue = str
            messageField.isHidden = false
            messageField.sizeToFit()
            
        }
    }
    
    // MARK: -
    // MARK: Canceling
    
    @objc func cancelButtonAction() {
        
        update(IndicatorState(canceled: true))
        
    }
    
    func startCancelTimer() {
           
        infoLog("Indicator[\(id)] Starting cancel timer")
        
        stopCancelTimer()
        
        cancelTime = Date()
        
        cancelButton.isEnabled = false
        cancelButton.animator().alphaValue = 0.3
        
        debugLog("Icon: \(icon)")
        
        cancelTimer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(self.performScheduledCancelCheck),
            userInfo: nil,
            repeats: true
        )
        
    }
    
    func stopCancelTimer() {
        
        if cancelTimer.isValid {
            
            debugLog("Indicator[\(id)] Stopping cancel timer")
            cancelTimer.invalidate()
            
        }
        
    }
    
    @objc func performScheduledCancelCheck() {
        
        if cancelButton.alphaValue < 1.0 {
            cancelButton.animator().alphaValue = 1.0
        } else {
            cancelButton.animator().alphaValue = 0.3
        }
        
        if self.cancelTime == nil {
         
            self.stopCancelTimer()
    
        } else if appDelegate.isJsonBasedIndicator(self) {
            
           DispatchQueue.global(qos: .userInteractive).async {
                
                if let cancelFilePath = self.appDelegate.jsonCancelPath {
                    
                    if !fileExists(at: cancelFilePath) {
                        
                        DispatchQueue.main.async {
                            
                            self.performCancelAction(isTimeout: false)
                            
                        }
                        
                    } else if self.cancelTime!.timeIntervalSinceNow * -1.0 >= self.cancelTimeout {
                        
                        do {
                            try FileManager.default.removeItem(atPath: cancelFilePath)
                        } catch {
                            errorLog("Could not delete cancel file at \(cancelFilePath): \(error)")
                        }
                        
                        DispatchQueue.main.async {
                            
                            self.performCancelAction(isTimeout: true)
                            
                        }
                        
                    }
                    
                } else {
                    
                    debugLog("Cancel file path not set")
                    
                }
                
            }
            
        } else if self.cancelTime!.timeIntervalSinceNow * -1.0 >= self.cancelTimeout {
            
            self.performCancelAction(isTimeout: true)
     
        }
        
        // appDelegate.removeIndicator(self)
        
    }
    
    func performCancelAction(isTimeout: Bool) {
        
        if isTimeout {
            infoLog("Indicator[\(id)] Cancel timeout reached")
        } else {
            infoLog("Indicator[\(id)] Canceling")
        }
            
        if appDelegate.isJsonBasedIndicator(self) {
            appDelegate.cancelJsonTimer()
        }
        
        stopCancelTimer()
        hideProgressBar()
        window.standardWindowButton(.closeButton)?.isEnabled = true
        
        if icon != "" {
            cautionView.image = NSImage(named: NSImage.Name("NSStopProgressFreestandingTemplate"))
            cautionView.frame = NSRect(x: 50, y: 10, width: 16, height: 16)
            cautionView.contentTintColor = .red
            cautionView.animator().alphaValue = 1.0
        }
        
    }
    
    func stopIndeterminateTimer() {
        
        if indeterminateTimer.isValid {
            
            infoLog("Indicator[\(id)] Stopping indeterminate timer")
            indeterminateTimer.invalidate()
            
        }
        
    }
    
    func startIndeterminateTimer() {
        
        infoLog("Indicator[\(id)] Starting indeterminate timer")
        
        if indeterminateTimer.isValid {
            indeterminateTimer.invalidate()
        }
        
        _startIndeterminateTimer()
                    
        
        
    }
    
    func restartIndeterminateTimer() {
        
        if indeterminateTimer.isValid {
            
            debugLog("Indicator[\(id)] Restarting indeterminate timer")
            indeterminateTimer.invalidate()
            
            _startIndeterminateTimer()
            
        }
        
    }
    
    func _startIndeterminateTimer() {
        
        indeterminateTimer = Timer.scheduledTimer(
            timeInterval: indeterminateTimeout,
            target: self,
            selector: #selector(self.performScheduledPostIndeterminateCleanup),
            userInfo: nil,
            repeats: true
        )
        
    }
    
    @objc func performScheduledPostIndeterminateCleanup() {
     
        infoLog("Indicator[\(id)] Indeterminate timeout reached")
        stopIndeterminateTimer()
        showCancelButton()
    }
    
    // MARK: -
    // MARK: Events
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        
        appDelegate.removeIndicator(self)
        return false
        
    }
    
    // MARK: -
    // MARK: Indicator user interface
    
    func initalizeUserInterface() {
        
        window.delegate = self
        window.backingType = .buffered
        window.styleMask = [.titled, .miniaturizable, .closable]
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.level = .floating
        window.standardWindowButton(.closeButton)?.isEnabled = false
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        
        titleField.isBezeled = false
        titleField.isEditable = false
        titleField.drawsBackground = false
        titleField.isSelectable = true
        titleField.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        
        messageField.isBezeled = false
        messageField.isEditable = false
        messageField.drawsBackground = false
        messageField.isSelectable = true
        messageField.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        messageField.textColor = NSColor.secondaryLabelColor
        
        progressBar.usesThreadedAnimation = true
        progressBar.startAnimation(nil)
        
        iconView.alphaValue = 0.0
        cautionView.alphaValue = 0.0
        cautionView.image = NSImage(named: NSImage.Name("NSCaution"))
        
        cancelButton.isBordered = false
        cancelButton.title = ""
        cancelButton.image = NSImage(named: NSImage.Name("NSStopProgressFreestandingTemplate"))
        cancelButton.isEnabled = true
        cancelButton.setButtonType(.momentaryPushIn)
        
        cancelButton.target = self
        cancelButton.action = #selector(Indicator.cancelButtonAction)
        cancelButton.alphaValue = 0.0
        cancelButton.isEnabled = false
        
        window.contentView?.addSubview(titleField)
        window.contentView?.addSubview(progressBar)
        window.contentView?.addSubview(messageField)
        window.contentView?.addSubview(cancelButton)
        window.contentView?.addSubview(iconView)
        window.contentView?.addSubview(cautionView)
        
    }
    
    func setupUserInterfaceGeometry() {
        
        debugLog("Indicator[\(id)] Setting up interface geometry")
        
        window.setFrame(
            NSRect(x: 0, y: 0, width: windowWidthWithoutIcon, height: windowHeight),
            display: false
        )
        
        titleField.frame = NSRect(x: 15, y: 45, width: 354, height: 16)
        titleField.autoresizingMask = [.minXMargin]
        
        messageField.frame = NSRect(x: 15, y: 11, width: 354, height: 16)
        messageField.autoresizingMask = [.minXMargin]
        
        progressBar.frame = NSRect(x: 16, y: 26, width: 378, height: 20)
        progressBar.autoresizingMask = [.minXMargin]
        
        iconView.frame = NSRect(x: -47, y: 12, width: 48, height: 48)
        iconView.autoresizingMask = [.minXMargin]
        iconView.imageScaling = .scaleProportionallyUpOrDown
        
        cautionView.frame = NSRect(x: -21, y: 13, width: 25, height: 25)
        cautionView.autoresizingMask = [.minXMargin]
        cautionView.imageScaling = .scaleProportionallyUpOrDown
        
        cancelButton.frame = NSRect(x: 379, y: 25, width: 21, height: 21)
        cancelButton.autoresizingMask = [.minXMargin]
        
    }

    func show() {
        
        if showingForFirstTime {
            
            debugLog("Indicator[\(id)] Showing indicator for first time")
            
            if let point = pointAfterPreviousIndicator() {
                
                
                
                if point.y < 0, let screen = NSScreen.main {
                    
                    window.setFrameOrigin(
                        NSPoint(
                            x: point.x,
                            y: screen.frame.size.height - CGFloat(24 + windowHeight)
                        )
                    )
                    
                } else {
                    
                    window.setFrameOrigin(point)
                    
                }
                
            } else {
                
                window.center()
                
                
                
                
                
            }
            
            NSApp.activate(ignoringOtherApps: true)
            
            showingForFirstTime = false
            
        } else {
            
            debugLog("Indicator[\(id)] Showing indicator")
            
        }
        
        window.orderFrontRegardless()
        window.makeKey()
        
    }
    
    func hide() {
        
        debugLog("Indicator[\(id)] Hiding indicator")
        
        window.orderOut(nil)
        
    }
    
    func pointAfterPreviousIndicator() -> NSPoint? {
        
        let indicatorCount = appDelegate.indicators.count
        
        if indicatorCount > 0 {
            
            var previousIndicator: Indicator?
            
            for index in stride(from: (indicatorCount - 1), through: 0, by: -1) {
                
                let thisIndicator = appDelegate.indicators[index]
                
                if thisIndicator.window.isVisible && thisIndicator.id != id {
                    
                    previousIndicator = thisIndicator
                    break
                    
                }
                
            }
            
            if previousIndicator == nil && appDelegate.jsonIndicator != nil {
                previousIndicator = appDelegate.jsonIndicator
            }
            
            if previousIndicator != nil {
                
                debugLog("Indicator[\(id)] There is another indicator")
                
                let origin: NSPoint
                
                if previousIndicator!.iconView.alphaValue == iconView.alphaValue {
                    
                    // Both indicators do not show icons
                    origin = NSPoint(
                        x: previousIndicator!.window.frame.origin.x,
                        y: previousIndicator!.window.frame.origin.y - CGFloat(windowHeight + verticalMargin)
                    )
                    
                    
                } else if iconView.alphaValue != 0.0 {
                    
                    // Only this new indicator shows icon
                    origin = NSPoint(
                        x: previousIndicator!.window.frame.origin.x + CGFloat(windowWidthWithIcon - windowWidthWithoutIcon),
                        y: previousIndicator!.window.frame.origin.y - CGFloat(windowHeight + verticalMargin)
                    )
                    
                } else {
                    
                    // The other indicator's icon is shown
                    origin = NSPoint(
                        x: previousIndicator!.window.frame.origin.x + CGFloat(windowWidthWithIcon - windowWidthWithoutIcon) / 2,
                        y: previousIndicator!.window.frame.origin.y - CGFloat(windowHeight + verticalMargin)
                    )
                }
                
                return origin
                
            }
            
        }
        
        return nil
        
    }
    
    // MARK: -
    // MARK: Progress bar
    
    func showProgressBar(withCancelButton: Bool) {
        
        if progressBar.alphaValue == 0.0 {
            
            debugLog("Indicator[\(id)] Showing progress bar")
            
            let titlePoint = NSMakePoint(
                titleField.frame.origin.x,
                titleField.frame.origin.y + CGFloat(8.0)
            )
            
            let messagePoint = NSMakePoint(
                messageField.frame.origin.x,
                messageField.frame.origin.y + CGFloat(-6.0)
            )
            
            if window.isVisible {
                
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 0.2
                
                titleField.animator().setFrameOrigin(titlePoint)
                messageField.animator().setFrameOrigin(messagePoint)
                
                NSAnimationContext.endGrouping()
                
                progressBar.alphaValue = 0.0
                progressBar.isHidden = false
                
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 0.5
                NSAnimationContext.current.completionHandler = {
                    self.progressBar.startAnimation(nil)
                }
                progressBar.animator().alphaValue = 1.0
                
                NSAnimationContext.endGrouping()
                
            } else {
                
                titleField.setFrameOrigin(titlePoint)
                messageField.setFrameOrigin(messagePoint)
                progressBar.alphaValue = 1.0
                progressBar.isHidden = false
                progressBar.startAnimation(nil)
                
            }
            
            window.standardWindowButton(.closeButton)?.isEnabled = false
            
        } else {
            
            debugLog("Indicator[\(id)] Progress bar is already visible")
            
        }
        
        if withCancelButton {
            showCancelButton()
        } else {
            hideCancelButton()
        }
        
    }
    
    func hideProgressBar() {
        
        if progressBar.alphaValue != 0.0 {
            
            debugLog("Indicator[\(id)] Hiding progress bar")
            
            let titlePoint = NSMakePoint(
                titleField.frame.origin.x,
                titleField.frame.origin.y + CGFloat(-8.0)
            )
            
            let messagePoint = NSMakePoint(
                messageField.frame.origin.x,
                messageField.frame.origin.y + CGFloat(8.0)
            )
            
            // Set font
            titleField.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
            messageField.textColor = NSColor.labelColor
            
            if window.isVisible {
                
                progressBar.stopAnimation(nil)
                
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 0.2
                NSAnimationContext.current.completionHandler = {
                    self.progressBar.isHidden = true
                }
                
                progressBar.animator().alphaValue = 0.0
                cancelButton.animator().alphaValue = 0.0
                cancelButton.isEnabled = false
                
                NSAnimationContext.endGrouping()
                
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 0.5
                
                titleField.animator().setFrameOrigin(titlePoint)
                
                messageField.animator().setFrameOrigin(messagePoint)
                
                NSAnimationContext.endGrouping()
            
            } else {
                
                titleField.setFrameOrigin(titlePoint)
                messageField.setFrameOrigin(messagePoint)
                cancelButton.alphaValue = 0.0
                cancelButton.isEnabled = false
                progressBar.alphaValue = 0.0
                progressBar.isHidden = true
                progressBar.stopAnimation(nil)
                
            }
            
        } else {
            
            debugLog("Indicator[\(id)] Progress bar is already hidden")
            
        }
        
    }
    
    // MARK: -
    // MARK: Cancel button
    
    func showCancelButton() {
        
        if cancelButton.alphaValue == 0.0 {
            
            debugLog("Indicator[\(id)] Showing cancel button")
            
            cancelButton.isEnabled = true
            
            if window.isVisible {
                cancelButton.animator().alphaValue = 1.0
                progressBar.animator().setFrameSize(NSMakeSize(CGFloat(progressBarWidthShort), progressBar.frame.size.height))
            } else {
                cancelButton.alphaValue = 1.0
                progressBar.setFrameSize(NSMakeSize(CGFloat(progressBarWidthShort), progressBar.frame.size.height))
            }
            
        } else {
            
            debugLog("Indicator[\(id)] Cancel button is already visible")
            
        }
        
    }
    
    func hideCancelButton() {
        
        if cancelButton.alphaValue != 0.0 {
            
            debugLog("Indicator[\(id)] Hiding cancel button")
            
            cancelButton.isEnabled = false
            
            if window.isVisible {
                cancelButton.animator().alphaValue = 0.0
                progressBar.animator().setFrameSize(NSMakeSize(CGFloat(progressBarWidthLong), progressBar.frame.size.height))
            } else {
                cancelButton.alphaValue = 0.0
                progressBar.setFrameSize(NSMakeSize(CGFloat(progressBarWidthLong), progressBar.frame.size.height))
            }
            
        } else {
            
            debugLog("Indicator[\(id)] Cancel button is already hidden")
            
        }
        
    }
    
    // MARK: -
    // MARK: Icon
    
    func setIcon(_ path: String) {
        
        if !path.isEmpty {
            
            let url = URL(fileURLWithPath: NSString(string: path).expandingTildeInPath)
            
            if fileExists(at: url) {
                do {
                    let imageData = try Data(contentsOf: url)
                    iconView.image = NSImage(data: imageData)
                    
                    showIcon()
                    return
                    
                } catch {
                    debugLog("Indicator[\(id)] Error loading image : \(error)")
                }
            } else {
                debugLog("Indicator[\(id)] Image file not found at \"\(url)\"")
            }
            
        }
        
        hideIcon()
        
    }
    
    func showIcon() {
        
        if iconView.alphaValue == 0.0 {
            
            debugLog("Indicator[\(id)] Showing icon")
            
            let frame = window.frame
            
            let widthDeltaHalf = ( CGFloat(windowWidthWithIcon) - frame.size.width ) / 2
            
            let newFrame = NSMakeRect(
                frame.origin.x - widthDeltaHalf,
                frame.origin.y,
                CGFloat(windowWidthWithIcon),
                frame.size.height
            )
            
            if window.isVisible {
                window.setFrame(newFrame, display: true, animate: true)
                iconView.animator().alphaValue = 1.0
            } else {
                window.setFrame(newFrame, display: false, animate: false)
                iconView.alphaValue = 1.0
            }
            
        } else {
            
            debugLog("Indicator[\(id)] Icon already shown")
            
        }
    }
    
    func hideIcon() {
        
        if iconView.alphaValue != 0.0 {
            
            debugLog("Indicator[\(id)] Hiding icon")
            
            let frame = window.frame
            
            let widthDeltaHalf = (frame.size.width - CGFloat(windowWidthWithoutIcon)) / 2
            
            let newFrame = NSMakeRect(
                frame.origin.x + widthDeltaHalf,
                frame.origin.y,
                CGFloat(windowWidthWithoutIcon),
                frame.size.height
            )
            
            if window.isVisible {
                window.setFrame(newFrame, display: true, animate: true)
                iconView.animator().alphaValue = 0.0
            } else {
                window.setFrame(newFrame, display: true, animate: true)
                iconView.alphaValue = 0.0
            }
            
        } else {
            
            debugLog("Indicator[\(id)] Icon already hidden")
            
        }
        
    }
    
}
