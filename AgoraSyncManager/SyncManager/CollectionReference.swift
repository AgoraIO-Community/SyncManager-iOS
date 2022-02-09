//
//  CollectionReference.swift
//  SyncManager
//
//  Created by ZYP on 2021/12/16.
//

import Foundation
import AgoraSyncKit

public class CollectionReference {
    private let manager: AgoraSyncManager
    public let className: String
    public let parent: SceneReference
    let internalCollection: AgoraSyncCollection
    
    public init(manager: AgoraSyncManager,
                parent: SceneReference,
                className: String) {
        self.manager = manager
        self.className = parent.id + className
        self.parent = parent
        self.internalCollection = AgoraSyncCollection()
    }
    
    init(manager: AgoraSyncManager,
                parent: SceneReference,
                collection: AgoraSyncCollection) {
        self.manager = manager
        self.className = ""
        self.parent = parent
        self.internalCollection = collection
    }
    
    public func document(id: String = "") -> DocumentReference {
        return DocumentReference(manager: manager, parent: self, id: id)
    }
    
    public func add(data: [String: Any?],
                    success: SuccessBlockObj?,
                    fail: FailBlock?) {
        manager.add(reference: self,
                    data: data,
                    success: success,
                    fail: fail)
    }
    
    public func get(success: SuccessBlock?,
                    fail: FailBlock?) {
        manager.get(collectionRef: self,
                    success: success,
                    fail: fail)
    }
    
    public func delete(success: SuccessBlock?,
                       fail: FailBlock?) {
        manager.delete(collectionRef: self,
                       success: success,
                       fail: fail)
    }
}
