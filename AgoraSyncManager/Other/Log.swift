//
//  LogProvider.swift
//  AgoraSyncManager
//
//  Created by ZYP on 2021/5/28.
//

import Foundation
import UIKit

class Log {
    fileprivate static let provider = LogProvider(domainName: "AgoraSyncManager")
    
    static func errorText(text: String,
                          tag: String? = nil) {
        provider.errorText(text: text, tag: tag)
    }
    
    static func error(error: CustomStringConvertible,
                      tag: String? = nil) {
        provider.errorText(text: error.description, tag: tag)
    }
    
    static func info(text: String,
                     tag: String? = nil) {
        provider.info(text: text, tag: tag)
    }
    
    static func debug(text: String,
                      tag: String? = nil) {
        provider.debug(text: text, tag: tag)
    }
    
    static func warning(text: String,
                        tag: String? = nil) {
        provider.warning(text: text, tag: tag)
    }
}

class LogProvider {
    private let domainName: String
    private let folderPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!.appending("/Logs")
    private let logger: LogUtil
    
    fileprivate init(domainName: String) {
        self.domainName = domainName
        logger = LogUtil(domainName: domainName)
    }
    
    fileprivate func error(error: Error?,
                           tag: String?,
                           domainName: String) {
        guard let e = error else {
            return
        }
        var text = "<can not get error info>"
        if e.localizedDescription.count > 1 {
            text = e.localizedDescription
        }
        
        let err = e as CustomStringConvertible
        if err.description.count > 1 {
            text = err.description
        }
        
        errorText(text: text,
                  tag: tag)
    }
    
    fileprivate func errorText(text: String,
                               tag: String?) {
        log(type: .error,
            text: text,
            tag: tag)
    }
    
    fileprivate func info(text: String,
                          tag: String?) {
        log(type: .info,
            text: text,
            tag: tag)
    }
    
    fileprivate func warning(text: String,
                             tag: String?) {
        log(type: .warning,
            text: text,
            tag: tag)
    }
    
    fileprivate func debug(text: String,
                           tag: String?) {
        log(type: .debug,
            text: text,
            tag: tag)
    }
    
    fileprivate func log(type: AgoraLogType,
                         text: String,
                         tag: String?) {
        let levelName = type.name
        let string = getString(text: text,
                               tag: tag,
                               levelName: levelName)
        logger.log(message: string)
    }
    
    private func getString(text: String,
                           tag: String?,
                           levelName: String) -> String {
        if let `tag` = tag {
            return "[\(domainName)][\(levelName)][\(tag)]: " + text
        }
        return "[\(domainName)][\(levelName)]: " + text
    }
}

extension LogProvider {
    enum AgoraLogType {
        case debug, info, warning, error
        fileprivate var name: String {
            switch self {
            case .debug:
                return "Debug"
            case .info:
                return "Info"
            case .error:
                return "Error"
            case .warning:
                return "Warning"
            }
        }
    }
}

class LogUtil {
    private var logs = SafeArray<LogItem>()
    private let logFolder: String
    private var appLogPath: String
    
    init(domainName: String) {
        self.logFolder = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/logs"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let time = formatter.string(from: Date())
        self.appLogPath = logFolder + "/\(domainName)-\(time).log"
        try? FileManager.default.createDirectory(atPath: logFolder, withIntermediateDirectories: true, attributes: nil)
    }
    
    func log(message: String) {
        #if DEBUG
        let item = LogItem(message: message, dateTime: Date())
        logs.append(item)
        print(item.description)
        writeAppLogsToDisk()
        #endif
    }
    
    func removeAll() {
        logs.removeAll()
    }
    
    func writeAppLogsToDisk() {
        if let outputStream = OutputStream(url: URL(fileURLWithPath: appLogPath), append: true) {
            outputStream.open()
            for log in logs.getAll() {
                let msg = log.description + "\n"
                let bytesWritten = outputStream.write(msg, maxLength: msg.count)
                if bytesWritten < 0 { print("write failure") }
            }
            outputStream.close()
            removeAll()
        } else {
            print("Unable to open file")
        }
    }
    
    func cleanUp() {
        let url = URL(fileURLWithPath: logFolder, isDirectory: true)
        try? FileManager.default.removeItem(at: url)
    }
}

class SafeArray<T> {
    private var array: [T]
    private let queue = DispatchQueue(label: "com.example.queue.safeArray", attributes: .concurrent)
    
    init() {
        array = [T]()
    }
    
    func append(_ element: T) {
        queue.async(flags: .barrier) {
            self.array.append(element)
        }
    }
    
    func getAll() -> [T] {
        var result: [T]?
        queue.sync(flags: .barrier) {
            result = self.array
        }
        return result ?? []
    }
    
    func removeLast() -> T? {
        var result: T?
        queue.sync(flags: .barrier) {
            result = self.array.popLast()
        }
        return result
    }
    func removeAll() {
        queue.sync(flags: .barrier) {
            self.array.removeAll()
        }
    }

    subscript(index: Int) -> T? {
        set {
            queue.async(flags: .barrier) {
                if let newValue = newValue, self.array.indices.contains(index) {
                    self.array[index] = newValue
                }
            }
        }
        get {
            var result: T?
            queue.async {
                if self.array.indices.contains(index) {
                    result = self.array[index]
                }
            }
            return result
        }
    }
}

extension LogUtil {
    struct LogItem: CustomStringConvertible {
        var message: String
        var dateTime: Date
        private let formatter = DateFormatter()
        
        init(message: String, dateTime: Date) {
            self.message = message
            self.dateTime = dateTime
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }
        
        var description: String {
            let time = formatter.string(from: dateTime)
            let msg = "\(time) \(message)"
            return msg
        }
    }
}
