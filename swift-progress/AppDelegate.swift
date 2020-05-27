//
//  AppDelegate.swift
//  swift-progress
//
//  Created by Adrian Nier on 2020-05-25.
//  Copyright © 2020 Adrian Nier. All rights reserved.
//

import Cocoa

@NSApplicationMain
@objcMembers
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var removedIndicators: [Indicator] = []
    @objc var indicators: [Indicator] = []
    
    var exitTimer = Timer()
    
    // MARK: -
    // MARK: JSON
    // Properties that deal with the fact that a JSON file has been specified as command line argument
    
    var jsonIndicator: Indicator?
    var jsonPath: String?
    var jsonCancelPath: String?
    
    var jsonTimer = Timer()
    let jsonFileUpdateFrequency = 1.0
    
    var jsonCancelTime: Date?
    let jsonCancelTimeout = 15.0

    // MARK: -
    // MARK: Application
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        initalizeArguments()
        
        if jsonPath != nil {
            
            json_cancelTimer()
            
            if let state = json_stateFromFile() {
                
                jsonIndicator = Indicator(state: state)
                
                if jsonIndicator!.completed {
                    
                    infoLog("Timer already complete when the JSON file was loaded")
                    
                    removeIndicator(jsonIndicator!)
                    
                } else {
                    
                    jsonIndicator!.update(IndicatorState(isVisible: true))
                    
                    jsonTimer = Timer.scheduledTimer(
                        timeInterval: jsonFileUpdateFrequency,
                        target: self,
                        selector: #selector(self.json_performScheduledStateUpdate),
                        userInfo: nil,
                        repeats: true
                    )
                    
                }
                
            } else {
                
                errorLog("Could not instantiate indicator based on file information")
                terminateWithNoIndicators()
                
            }
            
        }
        
    }
    
    func terminateWithNoIndicators() {
        
        if self.indicators.count == 0 && self.jsonIndicator == nil {
            
            infoLog("Will exit in 10 seconds if there are still no indicators left")
            
            exitTimer = Timer.scheduledTimer(
                timeInterval: 10,
                target: self,
                selector: #selector(self.performScheduledExit),
                userInfo: nil,
                repeats: true
            )
            
        }

    }

    func cancelExitTimer() {
        
        exitTimer.invalidate()
        
    }
    
    @objc func performScheduledExit() {
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            if self.indicators.count == 0 && self.jsonIndicator == nil {
                
                DispatchQueue.main.async {
                    
                    debugLog("Exiting with no indicators found")
                    NSApplication.shared.terminate(self)
                    
                }
                
            } else {
                
                DispatchQueue.main.async {
                    
                    debugLog("Canceling exit as there are still indicators")
                    self.cancelExitTimer()
                    
                }
                
            }
            
        }
        
    }
    
    // MARK: -
    // MARK: Manage indicators
    
    func removeIndicator(_ indicator: Indicator) {
        
        // FIXME: Why does the application crash if we don't keep a reference to the indicator?
        removedIndicators.append(indicator)
        
        indicator.window.delegate = nil
        indicator.window.isReleasedWhenClosed = true
        indicator.window.close()
        
        if jsonIndicator != nil && indicator.id == jsonIndicator!.id {
            
            jsonIndicator = nil
            
        } else {
            
            for (index, thisIndicator) in indicators.enumerated() {
                
                if thisIndicator.id == indicator.id {
                    indicators.remove(at: index)
                    break
                }
                
            }
            
        }
        
        terminateWithNoIndicators()
        
    }
    
    // MARK: -
    // MARK: JSON file
  
    func json_cancelTimer() {
        
        jsonTimer.invalidate()
        
    }
    
    @objc func json_performScheduledStateUpdate() {
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            if let newInfo = self.json_stateFromFile() {
                
                DispatchQueue.main.async {
                    
                    if let indicator = self.jsonIndicator {
                        
                        if !indicator.canceled {
                            
                            indicator.update(newInfo)
                            
                            if indicator.completed {
                                
                                self.json_cancelTimer()
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    @objc func json_performScheduledCancelUpdate() {
        
        if self.jsonIndicator != nil {
            
            infoLog("Waiting for cancel file to disappear")
            
            DispatchQueue.global(qos: .userInteractive).async {
                
                if self.jsonCancelPath != nil {
                    
                    if (self.jsonCancelTime != nil) {
                        
                        if self.jsonCancelTime!.timeIntervalSinceNow * -1 >= self.jsonCancelTimeout {
                            
                            infoLog("Cancel timeout reached")
                            
                            do {
                                try FileManager.default.removeItem(atPath: self.jsonCancelPath!)
                            } catch {
                                errorLog("Could not delete cancel file at \(self.jsonCancelPath!): \(error)")
                            }
                            
                            DispatchQueue.main.async {
                                
                                self.json_cancelTimer()
                                
                                if let indicator = self.jsonIndicator {
                                    indicator.performScheduledPostCancelCleanup()
                                }
                            }
                            
                        }
                    }
                    
                    
                    if !fileExists(at: self.jsonCancelPath!) {
                        
                        DispatchQueue.main.async {
                            
                            self.json_cancelTimer()
                            
                            if let indicator = self.jsonIndicator {
                                indicator.performScheduledPostCancelCleanup()
                            }
                        }
                        
                    }
                    
                } else {
                    
                    debugLog("Cancel file path not set")
                    
                }
                
            }
            
        }
        
    }
    
   func json_stateFromFile() -> IndicatorState? {
        
        do {
            
            if jsonPath != nil {
                if let jsonData = try json_readStateFile(jsonPath!) {
                    if let info = try json_parseStateData(jsonData) {
                        return info
                    }
                }
            }
            
        } catch {
            
            debugLog("\(error)")
            
        }
        
        return nil
        
    }
    
    func json_readStateFile(_ path: String) throws -> Data? {
        
        if let jsonData = try String(contentsOfFile: path).data(using: .utf8) {
            return jsonData
        }
        
        return nil
    }
    
    func json_parseStateData(_ jsonData: Data) throws -> IndicatorState? {
        
        return try JSONDecoder().decode(IndicatorState.self, from: jsonData)
        
    }
    
    func json_writeCancelFile() -> Bool {
        
        if jsonCancelPath != nil {
            
            json_cancelTimer()
            
            jsonCancelTime = Date()
            
            do {
                
                let jsonData = try JSONEncoder().encode(["cancelation_time": jsonCancelTime])
                
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    
                    try jsonString.write(toFile: jsonCancelPath!, atomically: true, encoding: .utf8)
                    
                    return true
                }
                
            } catch {
                
                errorLog("Failed to write cancelation file: \(error)")
                
            }
            
        }
        
        return false
    }
    
    func json_startCancelFileTimer() {
        
        if jsonIndicator != nil {
            
            if jsonCancelPath != nil {
                
                if (jsonCancelTime != nil) {
                    
                    json_cancelTimer()
                    
                    jsonTimer = Timer.scheduledTimer(
                        timeInterval: jsonFileUpdateFrequency,
                        target: self,
                        selector: #selector(self.json_performScheduledCancelUpdate),
                        userInfo: nil,
                        repeats: true
                    )
                    
                }
                
            }
            
        }
        
    }
    
}
