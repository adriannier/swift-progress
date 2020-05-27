//
//  Scripting.swift
//  swift-progress
//
//  Created by Adrian Nier on 2020-05-27.
//  Copyright © 2020 Adrian Nier. All rights reserved.
//

import Cocoa

extension AppDelegate {
    
    func application(_ sender: NSApplication, delegateHandlesKey key: String) -> Bool {
        return key == "indicators"
    }
    
    func insertValue(_ object: Indicator, inIndicatorsAt index: Int) {
        
        indicators.append(object)
        
        if let indicator = indicators.last {
            indicator.show()
        }
        
    }
    
    func removeObjectFromIndicatorsAtIndex(_ index: Int) {
        indicators.remove(at: index)
    }
    
    
}

extension Indicator {
    
    override var objectSpecifier: NSScriptObjectSpecifier {
        
        let appDescription = NSApplication.shared.classDescription as! NSScriptClassDescription
        
        let specifier = NSUniqueIDSpecifier(
            containerClassDescription: appDescription,
            containerSpecifier: nil,
            key: "indicators",
            uniqueID: id
        )
        
        return specifier
        
    }
    
    @objc override var scriptingProperties: [String : Any]? {
        
        // This happens when properties are read or set as a whole
        
        get { return currentState.asDict() }
        set { update(newValue) }
        
    }
    
    @objc func show(_ command: NSScriptCommand?) {
        
        update(IndicatorState(isVisible: true))
        
    }

    @objc func hide(_ command: NSScriptCommand?) {
        
        update(IndicatorState(isVisible: false))
        
    }
    
    @objc func close(_ command: NSScriptCommand?) {
        
        stopCancelTimer()
        update(IndicatorState(isVisible: false))
        appDelegate.removeIndicator(self)
    }
    
    @objc func complete(_ command: NSScriptCommand?) {
        
        if command != nil && canceled {
            
            command!.scriptErrorNumber = -128
            command!.scriptErrorString = "User canceled."
            
        } else {
            
            update(IndicatorState(completed: true))
            
        }
        
    }
    
    @objc func abort(_ command: NSScriptCommand?) {
        
        if command != nil && canceled {
            command!.scriptErrorNumber = -128
            command!.scriptErrorString = "User canceled."
        } else {
            update(IndicatorState(aborted: true))
        }
        
    }
    
    @objc func cancel(_ command: NSScriptCommand?) {
        
        cancelButtonAction()
        
    }

    
}
