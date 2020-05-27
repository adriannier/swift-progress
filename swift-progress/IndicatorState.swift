//
//  ProgressInfo.swift
//  swift-progress
//
//  Created by Adrian Nier on 2020-05-25.
//  Copyright © 2020 Adrian Nier. All rights reserved.
//

import Foundation

func defaultIndicatorState() -> IndicatorState {
    
    return IndicatorState(
        title: "",
        message: "",
        percentage: -2.0,
        icon: "",
        completed: false,
        aborted: false,
        canceled: false,
        isVisible: false
    )
    
}

func modifiedIndicatorState(currentState: IndicatorState, newState: IndicatorState) -> IndicatorState {
    
    var modifiedState = currentState
    
    if newState.title != nil { modifiedState.setValueForKey("title", value: newState.title) }
    if newState.message != nil { modifiedState.setValueForKey("message", value: newState.message) }
    if newState.percentage != nil { modifiedState.setValueForKey("percentage", value: newState.percentage) }
    if newState.icon != nil { modifiedState.setValueForKey("icon", value: newState.icon) }
    if newState.completed != nil { modifiedState.setValueForKey("completed", value: newState.completed) }
    if newState.aborted != nil { modifiedState.setValueForKey("aborted", value: newState.aborted) }
    if newState.canceled != nil { modifiedState.setValueForKey("canceled", value: newState.canceled) }
    if newState.isVisible != nil { modifiedState.setValueForKey("isVisible", value: newState.isVisible) }
    
    return modifiedState
    
}

struct IndicatorState: Codable {
    
    var title: String?
    var message: String?
    var percentage: Double?
    var icon: String?
    var completed: Bool?
    var aborted: Bool?
    var canceled: Bool?
    var isVisible: Bool?
    
    mutating func setValueForKey(_ key: String, value: Any??) {
        
        if value != nil {
            
            switch key {
                
                case "title": title = value as? String
                case "message":  message = value as? String
                case "percentage":  percentage = value as? Double
                case "icon": icon = value as? String
                case "completed": completed = value as? Bool
                case "aborted": aborted = value as? Bool
                case "canceled": canceled = value as? Bool
                case "isVisible": isVisible = value as? Bool
                
            default:
                debugLog("IndicatorState: Unknown key \"\(key)\".")
                
            }
    
        }
    
    }
    
    func asDict() -> [String: Any] {
        
        let defaultState = defaultIndicatorState()
        
        var dict: [String: Any] = [:]
        
        dict["title"] = title ?? defaultState.title
        dict["message"] = message ?? defaultState.message
        dict["percentage"] = percentage ?? defaultState.percentage
        dict["icon"] = icon ?? defaultState.icon
        dict["completed"] = completed ?? defaultState.completed
        dict["aborted"] = aborted ?? defaultState.aborted
        dict["canceled"] = canceled ?? defaultState.canceled
        dict["isVisible"] = isVisible ?? defaultState.isVisible
        
        return dict
        
    }
    
    func valueForKey(_ key: String) -> Any {
        
        if let value = asDict()[key] {
            return value
        } else {
            debugLog("IndicatorState: Unknown key \"\(key)\".")
            return ""
        }
        
    }
    
}
