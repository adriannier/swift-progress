//
//  utilities.swift
//

import Foundation

func debugLog(_ msg: String) {
   
    if debugMode { print(msg) }
    
}

func errorLog(_ msg: String) {
    
    print("Error: \(msg)")
    
}

func infoLog(_ msg: String) {
    
    print(msg)
    
}

func parentDirectory(at: URL) -> URL {

    return at.deletingLastPathComponent()

}

func parentDirectory(at: String) -> String {
    
    return parentDirectory(at: URL(fileURLWithPath: at)).path

}

func fileExists(at: URL) -> Bool {
    return fileExists(at: at.path)
}

func fileExists(at: String) -> Bool {
    
    var isDirectory: ObjCBool = false
    if !FileManager.default.fileExists(atPath: at, isDirectory: &isDirectory) || isDirectory.boolValue {
        return false
    } else {
        return true
    }
    
}

func directoryExists(at: URL) -> Bool {
    return directoryExists(at: at.path)
}

func directoryExists(at: String) -> Bool {
    
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: at, isDirectory: &isDirectory) && isDirectory.boolValue {
        return true
    } else {
        return false
    }
    
}

func isReadable(at: URL) -> Bool {
    return isReadable(at: at.path)
}

func isReadable(at: String) -> Bool {
    return FileManager.default.isReadableFile(atPath: at)
}

func isWritable(at: URL) -> Bool {
    return isWritable(at: at.path)
}

func isWritable(at: String) -> Bool {
    return FileManager.default.isWritableFile(atPath: at)
}
