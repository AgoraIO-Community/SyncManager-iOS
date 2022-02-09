//
//  AskManager+Internal.swift
//  AgoraSyncManager
//
//  Created by ZYP on 2022/2/7.
//

import Foundation
import AgoraRtmKit /// will not use it
import AgoraSyncKit

extension AskSyncManager {
    func createSceneSync(scene: Scene,
                         success: SuccessBlockVoid?,
                         fail: FailBlock?) {
        /** read room list **/
        var shouldAddRoomInfoInList = true
        let semp = DispatchSemaphore(value: 0)
        var error: SyncError?
        Log.info(text: "start get scene list", tag: "AskManager.addSceneInfoInListIfNeed")
        roomsCollection.getRemote { errorCode, snapshots in
            Log.info(text: "get scene list block invoke", tag: "AskManager.addSceneInfoInListIfNeed")
            if errorCode == 0 {
                guard let list = snapshots else { /** can not get list **/
                    fatalError("snapshots must not nil")
                }
                let jsonStrings = list.compactMap({ $0.data() }).map({ $0.getJsonString() })
                guard !jsonStrings.isEmpty else { /** list is empty **/
                    semp.signal()
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
                            Log.errorText(text: "decode error \(error.localizedDescription)", tag: "AskManager.addSceneInfoInListIfNeed")
                        }
                    }
                }
                
                /// check isContainRoom
                if !currentRooms.isEmpty {
                    let isContainRoom = currentRooms.map({ $0.id }).contains(scene.id)
                    if isContainRoom {
                        shouldAddRoomInfoInList = false
                    }
                }
                semp.signal()
            }
            else {
                error = SyncError.ask(message: "getRemote fail ", code: errorCode)
                semp.signal()
            }
        }
        
        semp.wait()
        
        if let e = error { /** get scene list has error **/
            DispatchQueue.main.async {
                fail?(e)
            }
            return
        }
        
        if !shouldAddRoomInfoInList {
            DispatchQueue.main.async {
                success?()
            }
            return
        }
        
        /** add room in list **/
        let roomJson = AgoraJson()
        let roomString = scene.toJson()
        let json = AgoraJson()
        json.setString(roomString)
        roomJson.setField(scene.id, agoraJson: json)
        roomsCollection?.add(roomJson, completion: { [weak self](errorCode, document) in
            if errorCode == 0 {
                self?.roomDocument = document
                DispatchQueue.main.async {
                    success?()
                }
            }
            else {
                Log.errorText(text: "roomsCollection add \(errorCode)", tag: "AskManager.addSceneInfoInListIfNeed")
                let e = SyncError.ask(message: "add json in collection fail ", code: errorCode)
                DispatchQueue.main.async {
                    fail?(e)
                }
            }
        })
    }
    
    func joinSceneSync(sceneId: String,
                       manager: AgoraSyncManager,
                       success: SuccessBlockObjSceneRef?,
                       fail: FailBlock?) {
        guard let sceneDocument = roomDocument else {
            let e = SyncError.ask(message: "can not find roomDocument", code: -1)
            DispatchQueue.main.async {
                fail?(e)
            }
            return
        }
        let sceneRef = SceneReference(manager: manager,
                                      document: sceneDocument,
                                      id: sceneId)
        DispatchQueue.main.async {
            success?(sceneRef)
        }
    }
    
    func getScenesSync(success: SuccessBlock?, fail: FailBlock?) {
        roomsCollection.getRemote { errorCode, snapshots in
            if errorCode == 0 {
                guard let list = snapshots else { /** can not get list **/
                    fatalError("snapshots must not nil")
                }
                
                let jsonStrings = list.compactMap({ $0.data() }).map({ $0.getJsonString() })
                guard !jsonStrings.isEmpty else { /** list is empty **/
                    DispatchQueue.main.async {
                        success?([])
                    }
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
                DispatchQueue.main.async {
                    success?(results)
                }
                return
            }
            else {
                let e = SyncError.ask(message: "joinScene fail", code: errorCode)
                DispatchQueue.main.async {
                    fail?(e)
                }
            }
        }
    }
    
    func getSync(documentRef: DocumentReference,
                 key: String?,
                 success: SuccessBlockObjOptional?,
                 fail: FailBlock?) {
        let field = key ?? ""
        documentRef.internalDocument.getRemote(field) { errorCode, json in
            if errorCode == 0 {
                guard let result = json else {
                    Log.info(text: "json is nil", tag: "AskManager.get(documentRef)")
                    
                    DispatchQueue.main.async {
                        success?(nil)
                    }
                    return
                }
                
                let string = result.getJsonString()
                let attr = Attribute(key: field, value: string)
                DispatchQueue.main.async {
                    success?(attr)
                }
            }
            else {
                let e = SyncError.ask(message: "get(documentRef) fail", code: errorCode)
                DispatchQueue.main.async {
                    fail?(e)
                }
            }
        }
    }
    
    func getSync(collectionRef: CollectionReference,
                 success: SuccessBlock?,
                 fail: FailBlock?) {
        collectionRef.internalCollection.getRemote { errorCode, snapshots in
            if errorCode == 0 {
                guard let list = snapshots else {
                    fatalError("snapshots should not nil when errorCode equal 0")
                }
                let strings = list.compactMap({ $0.data() }).map({ $0.getJsonString() })
                let attrs = strings.map({ Attribute(key: "", value: $0) })
                DispatchQueue.main.async {
                    success?(attrs)
                }
            }
            else {
                let e = SyncError.ask(message: "get(collectionRef) fail", code: errorCode)
                DispatchQueue.main.async {
                    fail?(e)
                }
            }
        }
    }
    
    func addSync(reference: CollectionReference,
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
                DispatchQueue.main.async {
                    success?(attr)
                }
            }
            else {
                let e = SyncError.ask(message: "get(collectionRef) fail", code: errorCode)
                DispatchQueue.main.async {
                    fail?(e)
                }
            }
        }
    }
    
    func updateSync(reference: DocumentReference,
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
                DispatchQueue.main.async {
                    success?([attr])
                }
            }
            else {
                let e = SyncError.ask(message: "update(reference) fail", code: errorCode)
                DispatchQueue.main.async {
                    fail?(e)
                }
            }
        }
    }
    
    func deleteSync(documentRef: DocumentReference,
                    success: SuccessBlock?,
                    fail: FailBlock?) {
        documentRef.internalDocument.set("", json: AgoraJson()) { errorCode in
            if errorCode == 0 {
                DispatchQueue.main.async {
                    success?([])
                }
            }
            else {
                let e = SyncError.ask(message: "delete(documentRef) fail", code: errorCode)
                DispatchQueue.main.async {
                    fail?(e)
                }
            }
        }
    }
    
    func deleteSync(collectionRef: CollectionReference,
                    success: SuccessBlock?,
                    fail: FailBlock?) {
        collectionRef.internalCollection.remove { errorCode in
            if errorCode == 0 {
                DispatchQueue.main.async {
                    success?([])
                }
            }
            else {
                let e = SyncError.ask(message: "delete(collectionRef) fail", code: errorCode)
                DispatchQueue.main.async {
                    fail?(e)
                }
            }
        }
    }
}
