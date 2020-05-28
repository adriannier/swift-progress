//
//  CommandLine.swift
//  swift-progress
//
//  Created by Adrian Nier on 2020-05-27.
//  Copyright © 2020 Adrian Nier. All rights reserved.
//

import Cocoa

extension AppDelegate {
        
    func initalizeArguments() {
        
        if CommandLine.arguments.count > 1 {
            
            // At least one command line argument
            
            let specifiedInfoPath = NSString(string: CommandLine.arguments[1]).expandingTildeInPath
            
            if specifiedInfoPath != "-NSDocumentRevisionsDebugMode" {
                
                
                if fileExists(at: specifiedInfoPath) {
                    if isReadable(at: specifiedInfoPath) {
                        jsonPath = specifiedInfoPath
                    } else {
                        errorLog("The JSON file is not readable at \(specifiedInfoPath)")
                    }
                } else {
                    errorLog("The JSON file is missing at \(specifiedInfoPath)")
                }
                
                if jsonPath != nil && CommandLine.arguments.count > 2 {
                    
                    // At least two command line arguments
                    
                    let specifiedCancelPath = NSString(string: CommandLine.arguments[2]).expandingTildeInPath
                    
                    if !fileExists(at: specifiedCancelPath) || isWritable(at: specifiedCancelPath) {
                        
                        let parent = parentDirectory(at: specifiedCancelPath)
                        
                        if isWritable(at: parent) {
                            
                            let fm = FileManager.default
                            
                            if fm.isDeletableFile(atPath: specifiedCancelPath) {
                                
                                jsonCancelPath = specifiedCancelPath
                                
                                if fileExists(at: jsonCancelPath!) {
                                    
                                    do {
                                        try fm.removeItem(atPath: jsonCancelPath!)
                                    } catch {
                                        debugLog("Could not delete cancel file at \(jsonCancelPath!): \(error)")
                                    }
                                    
                                }
                                
                            } else {
                                
                                debugLog("The cancel file is not deletable at \(specifiedInfoPath)")
                                
                            }
                            
                        } else {
                            debugLog("The directory for the cancel file is not writable at \(parent)")
                        }
                        
                    } else {
                        
                        debugLog("The cancel file is missing at \(specifiedInfoPath)")
                        
                    }
                    
                }
                
            }
            
        } else {
            debugLog("No .json file specified")
        }
        
    }
    
}
