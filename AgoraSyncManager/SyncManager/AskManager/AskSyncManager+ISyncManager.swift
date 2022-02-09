//
//  AskManager+ISyncManager.swift
//  AgoraSyncManager
//
//  Created by ZYP on 2022/2/7.
//

import Foundation
import AgoraSyncKit
import AgoraRtmKit /// will not use it

extension AskSyncManager: ISyncManager {
    
    func createScene(scene: Scene,
                     success: SuccessBlockVoid?,
                     fail: FailBlock?) {
        queue.async { [weak self] in
            self?.createSceneSync(scene: scene,
                                  success: success,
                                  fail: fail)
        }
    }
    
    func joinScene(sceneId: String,
                   manager: AgoraSyncManager,
                   success: SuccessBlockObjSceneRef?,
                   fail: FailBlock?) {
        queue.async { [weak self] in
            self?.joinSceneSync(sceneId: sceneId,
                                manager: manager,
                                success: success,
                                fail: fail)
        }
    }
    
    func getScenes(success: SuccessBlock?, fail: FailBlock?) {
        queue.async { [weak self] in
            self?.getScenes(success: success, fail: fail)
        }
    }
    
    func deleteScenes(sceneIds: [String],
                      success: SuccessBlockVoid?,
                      fail: FailBlock?) {
        assertionFailure("deleteScenes not implete")
    }
    
    func get(documentRef: DocumentReference,
             key: String?,
             success: SuccessBlockObjOptional?,
             fail: FailBlock?) {
        queue.async { [weak self] in
            self?.getSync(documentRef: documentRef,
                          key: key,
                          success: success,
                          fail: fail)
        }
    }
    
    func get(collectionRef: CollectionReference,
             success: SuccessBlock?,
             fail: FailBlock?) {
        collectionRef.internalCollection.getRemote { errorCode, snapshots in
            if errorCode == 0 {
                guard let list = snapshots else {
                    assertionFailure("snapshots should not nil when errorCode equal 0")
                    return
                }
                let strings = list.compactMap({ $0.data() }).map({ $0.getJsonString() })
                let attrs = strings.map({ Attribute(key: "", value: $0) })
                success?(attrs)
            }
            else {
                let error = SyncError(message: "get(collectionRef) fail", code: errorCode)
                fail?(error)
            }
        }
    }
    
    func add(reference: CollectionReference,
             data: [String : Any?],
             success: SuccessBlockObj?,
             fail: FailBlock?) {
        let value = Utils.getJson(dict: data as NSDictionary)
        let json = AgoraJson()
        json.setString(value)
        reference.internalCollection.add(json) { [weak self](errorCode, document) in
            if errorCode == 0 {
                guard let doc = document else {
                    assertionFailure("document should not nil when errorCode equal 0")
                    return
                }
                
                let uid = UUID().uuid16string()
                let attr = Attribute(key: uid, value: value)
                self?.documentDict[uid] = doc
                success?(attr)
            }
            else {
                let error = SyncError(message: "get(collectionRef) fail", code: errorCode)
                fail?(error)
            }
        }
    }
    
    func update(reference: CollectionReference,
                id: String,
                data: [String : Any?],
                success: SuccessBlockVoid?,
                fail: FailBlock?) {
        
    }
    
    func delete(reference: CollectionReference,
                id: String,
                success: SuccessBlockVoid?,
                fail: FailBlock?) {
        
    }
    
    func update(reference: DocumentReference,
                key: String?,
                data: [String : Any?],
                success: SuccessBlock?,
                fail: FailBlock?) {
        let field = key ?? ""
        let json = AgoraJson()
        let value = Utils.getJson(dict: data as NSDictionary)
        json.setString(value)
        reference.internalDocument.set(field, json: json) { errorCode in
            if errorCode == 0 {
                let attr = Attribute(key: "", value: value)
                success?([attr])
            }
            else {
                let error = SyncError(message: "update(reference) fail", code: errorCode)
                fail?(error)
            }
        }
    }
    
    func delete(documentRef: DocumentReference,
                success: SuccessBlock?,
                fail: FailBlock?) {
        documentRef.internalDocument.set("", json: AgoraJson()) { errorCode in
            if errorCode == 0 {
                success?([])
            }
            else {
                let error = SyncError(message: "delete(documentRef) fail", code: errorCode)
                fail?(error)
            }
        }
    }
    
    func delete(collectionRef: CollectionReference,
                success: SuccessBlock?,
                fail: FailBlock?) {
        collectionRef.internalCollection.remove { errorCode in
            if errorCode == 0 {
                success?([])
            }
            else {
                let error = SyncError(message: "delete(collectionRef) fail", code: errorCode)
                fail?(error)
            }
        }
    }
    
    func subscribe(reference: DocumentReference,
                   key: String?,
                   onCreated: OnSubscribeBlock?,
                   onUpdated: OnSubscribeBlock?,
                   onDeleted: OnSubscribeBlock?,
                   onSubscribed: OnSubscribeBlockVoid?,
                   fail: FailBlock?) {
        reference.internalDocument.subscribe { errorCode in
            
        } eventCompletion: { type, snapshots, detail in
            
        }
    }
    
    func unsubscribe(reference: DocumentReference, key: String?) {
        
    }
}
