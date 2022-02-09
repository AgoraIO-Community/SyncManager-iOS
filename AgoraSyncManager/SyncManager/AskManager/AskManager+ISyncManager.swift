//
//  AskManager+ISyncManager.swift
//  AgoraSyncManager
//
//  Created by ZYP on 2022/2/7.
//

import Foundation
import AgoraSyncKit
import AgoraRtmKit /// will not use it

extension AskManager: ISyncManager {
    
    /// TODO: SceneReference通过block传递出去
    func joinScene(scene: Scene,
                   manager: AgoraSyncManager,
                   success: SuccessBlockObjSceneRef?,
                   fail: FailBlock?) {
        roomsCollection = askContext.createSlice(withName: defaultChannelName)?.createCollection(withName: roomListKey)
        let sceneDocument = roomsCollection.createDocument(withName: scene.id)
        let queue = DispatchQueue(label: "AskManager.queue", attributes: .concurrent)
        let sceneRef = SceneReference(manager: manager,
                                      document: sceneDocument!)
        queue.async { [weak self] in
            self?.addSceneInfoInListIfNeed(scene: scene,
                                           sceneRef: sceneRef,
                                           success: success,
                                           fail: fail)
        }
    }
    
    func getScenes(success: SuccessBlock?, fail: FailBlock?) {
        roomsCollection.getRemote { errorCode, snapshots in
            if errorCode == 0 {
                guard let list = snapshots else { /** can not get list **/
                    assertionFailure("snapshots must not nil")
                    return
                }
                
                let jsonStrings = list.compactMap({ $0.data() }).map({ $0.getJsonString() })
                guard !jsonStrings.isEmpty else { /** list is empty **/
                    success?([])
                    return
                }
                
                /// decode scene
                let decoder = JSONDecoder()
                var currentRooms = [Scene]()
                for str in jsonStrings {
                    if let data = str.data(using: .utf8) {
                        do {
                            let sceneObj = try decoder.decode(Scene.self, from: data)
                            currentRooms.append(sceneObj)
                        } catch let error {
                            Log.errorText(text: "decode error \(error.localizedDescription)", tag: "AskManager.joinScene")
                        }
                    }
                }
                
                let results = currentRooms.map({ Attribute(key: $0.id, value: $0.toJson()) })
                success?(results)
                return
            }
            else {
                let error = SyncError(message: "joinScene fail", code: errorCode)
                fail?(error)
            }
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
        let field = key ?? ""
        documentRef.internalDocument.getRemote(field) { errorCode, json in
            if errorCode == 0 {
                guard let result = json else {
                    Log.info(text: "json is nil", tag: "AskManager.get(documentRef)")
                    success?(nil)
                    return
                }
                
                let string = result.getJsonString()
                let attr = Attribute(key: field, value: string)
                success?(attr)
            }
            else {
                let error = SyncError(message: "get(documentRef) fail", code: errorCode)
                fail?(error)
            }
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
