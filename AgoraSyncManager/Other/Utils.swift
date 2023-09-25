//
//  Utils.swift
//  RtmSyncManager
//
//  Created by xianing on 2021/9/25.
//

import Foundation

class Utils {
    static func getJson(dict:NSDictionary?) -> String {
        let data = try? JSONSerialization.data(withJSONObject: dict!, options: JSONSerialization.WritingOptions.init(rawValue: 0))
        let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        return jsonStr! as String
    }

    static func getDict(text: String) -> [String:AnyObject]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.init(rawValue: 0)]) as? [String:AnyObject]
            } catch let error as NSError {
                 print(error)
            }
        }
        return nil
    }
    /// JSON字符串转字典
    static func toDictionary(jsonString: String) -> [String: Any] {
        guard let jsonData = jsonString.data(using: .utf8) else { return [:] }
        guard let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers), let result = dict as? [String: Any] else { return [:] }
        return result
    }
    
    /// 字典转JSON字符串
    static func toJsonString(dict: [String: Any]?) -> String? {
        guard let dict = dict else { return nil }
        if (!JSONSerialization.isValidJSONObject(dict)) {
            print("字符串格式错误！")
            return nil
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else { return nil }
        guard let jsonString = String(data: data, encoding: .utf8) else { return nil }
        return jsonString
    }
}

class GroceryProduct: Decodable{
    var name: String
    var points: Int
    var description: String
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

class SafeDictionary<Key: Hashable, Value> {
    private var dictionary: [Key: Value] = [:]
    private let concurrentQueue = DispatchQueue(label: "com.example.threadSafeDictionary", attributes: .concurrent)
    
    subscript(key: Key) -> Value? {
        get {
            var result: Value?
            concurrentQueue.sync {
                result = dictionary[key]
            }
            return result
        }
        set(newValue) {
            concurrentQueue.async(flags: .barrier) {
                self.dictionary[key] = newValue
            }
        }
    }
    
    var count: Int {
        var count = 0
        concurrentQueue.sync {
            count = dictionary.count
        }
        return count
    }
    
    var keys: Dictionary<Key, Value>.Keys? {
        var results: Dictionary<Key, Value>.Keys?
        concurrentQueue.sync {
            results = dictionary.keys
        }
        return results
    }
    
    var isEmpty: Bool {
        var result: Bool = true
        concurrentQueue.sync {
            result = dictionary.isEmpty
        }
        return result
    }
    
    func removeValue(forKey key: Key) {
        concurrentQueue.async(flags: .barrier) {
            self.dictionary.removeValue(forKey: key)
        }
    }
    
    func removeAll() {
        concurrentQueue.async(flags: .barrier) {
            self.dictionary.removeAll()
        }
    }
}
