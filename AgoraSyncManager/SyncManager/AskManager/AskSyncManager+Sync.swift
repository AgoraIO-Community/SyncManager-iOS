//
//  AskManager+Internal.swift
//  AgoraSyncManager
//
//  Created by ZYP on 2022/2/7.
//

import Foundation
import AgoraSyncKit

extension AskSyncManager {
    func createSceneSync(scene: Scene,
                         success: SuccessBlockVoid?,
                         fail: FailBlock?) {
        /// fetch and find a special one with scene.id
        let result = fetchRoomSnapshot(with: scene.id, in: roomsCollection)
        if let result = result { /** result is not nil **/
            switch result {
            case .failure(let error): /** get room list error **/
                DispatchQueue.main.async {
                    fail?(error)
                }
                return
            case .success(let snapshot): /** has this room **/
                roomDocument = snapshot.createDocument()
                DispatchQueue.main.async {
                    success?()
                }
                return
            }
        }
        
        ///  add room
        let ret = addRoom(id: scene.id, data: scene.toJson())
        switch ret {
        case .success(let document):
            roomDocument = document
            DispatchQueue.main.async {
                success?()
            }
            break
        case .failure(let error):
            DispatchQueue.main.async {
                fail?(error)
            }
            break
        }
    }
    
    func joinSceneSync(sceneId: String,
                       manager: AgoraSyncManager,
                       success: SuccessBlockObjSceneRef?,
                       fail: FailBlock?) {
        if roomDocument == nil { /** get current room info while role is not a host **/
            let result = fetchRoomSnapshot(with: sceneId, in: roomsCollection)
            
            guard let result = result else {
                fatalError("should have a room item")
            }
            
            switch result {
            case .success(let snapshot):
                roomDocument = snapshot.createDocument()
                break
            case .failure(let error):
                DispatchQueue.main.async {
                    fail?(error)
                }
                return
            }
        }
        
        guard let sceneDocument = roomDocument else {
            fatalError("never call this")
        }
        
        let sceneRef = SceneReference(manager: manager,
                                      document: sceneDocument,
                                      id: sceneId)
        self.sceneName = sceneId
        DispatchQueue.main.async {
            success?(sceneRef)
        }
    }
    
    func getScenesSync(success: SuccessBlock?, fail: FailBlock?) {
        guard let field = sceneName else {
            fatalError("must call joinSceneSync method")
        }
        
        roomsCollection.getRemote { errorCode, snapshots in
            if errorCode == 0 {
                guard let list = snapshots else { /** can not get list **/
                    fatalError("snapshots must not nil")
                }
                
                let jsonStrings = list.compactMap({ $0.data() }).map({ $0.getJsonString(field: field) })
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
                            Log.errorText(text: "decode error \(error.localizedDescription)", tag: "AskManager.getScenesSync")
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
                let e = SyncError.ask(message: "getScenesSync fail", code: errorCode)
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
                
                let string = result.getJsonString(field: "")
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
                let jsonDecoder = JSONDecoder()
                let strings = list.compactMap({ $0.data() }).map({ $0.getJsonString(field: "") })
                let attrs = strings.map({ str -> Attribute? in
                    guard let id = CollectionItem.getObjId(jsonString:str, decoder:jsonDecoder) else {
                        return nil
                    }
                    return Attribute(key: id, value: str)
                }).compactMap({ $0 })
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
        let uid = UUID().uuid16string()
        var temp = data
        temp["objectId"] = uid
        let value = Utils.getJson(dict: temp as NSDictionary)
        let json = AgoraJson()
        json.setField("", agoraJson: AgoraJson())
        json.setString(value)
        reference.internalCollection.add(json) { [weak self](errorCode, document) in
            if errorCode == 0 {
                guard let doc = document else {
                    assertionFailure("document should not nil when errorCode equal 0")
                    return
                }
                
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
    
    func updateSync(reference: CollectionReference,
                    id: String,
                    data: [String : Any?],
                    success: SuccessBlockVoid?,
                    fail: FailBlock?) {
        guard let document = documentDict[id] else {
            let e = SyncError.ask(message: "id not found in local, it is add by remote?", code: -1)
            fail?(e)
            return
        }
        var temp = data
        temp["objectId"] = id
        let value = Utils.getJson(dict: temp as NSDictionary)
        let json = AgoraJson()
        json.setField("", agoraJson: AgoraJson())
        json.setString(value)
        document.set("", json: json) { errorCode in
            if errorCode == 0 {
                success?()
            }
            else {
                let e = SyncError.ask(message: "updateSync(reference: CollectionReference) fail", code: errorCode)
                fail?(e)
            }
        }
    }
    
    func deleteSync(reference: CollectionReference,
                    id: String,
                    success: SuccessBlockVoid?,
                    fail: FailBlock?) {
        guard let document = documentDict[id] else {
            let e = SyncError.ask(message: "id not found in local, it is add by remote?", code: -1)
            fail?(e)
            return
        }
        document.set("",
                     json: AgoraJson(),
                     completion: { errorCode in
            if errorCode == 0 {
                DispatchQueue.main.async {
                    success?()
                }
            }
            else {
                let e = SyncError.ask(message: "delete(collectionRef) fail", code: errorCode)
                DispatchQueue.main.async {
                    fail?(e)
                }
            }
        })
    }
    
    // TODO: -- key不允许为nil?
    func updateSync(reference: DocumentReference,
                    key: String?,
                    data: [String : Any?],
                    success: SuccessBlock?,
                    fail: FailBlock?) {
        let field = key ?? ""
        if field == "" { fatalError("key must not empty") }
        let json = AgoraJson()
        let value = Utils.getJson(dict: data as NSDictionary)
        json.setField("", agoraJson: AgoraJson())
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
        
        /// delete collection
        for collection in collections.values {
            collection.remove { errorCode in
                Log.info(text: "delete collection ret \(errorCode)", tag: "AskSyncManager.deleteSync")
            }
        }
        collections.removeAll()
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
    
    func subscribeSync(reference: DocumentReference,
                       key: String?,
                       onCreated: OnSubscribeBlock?,
                       onUpdated: OnSubscribeBlock?,
                       onDeleted: OnSubscribeBlock?,
                       onSubscribed: OnSubscribeBlockVoid?,
                       fail: FailBlock?) {
        let key = key ?? ""
        let name = reference.className + key
        
        if name == sceneName, let sceneDocument = roomDocument { /** 监听sceneRef 事件 **/
            sceneDocument.subscribe({ errorCode in
                if errorCode != 0 {
                    let e = SyncError.ask(message: "subscribe scene \(name) fail", code: errorCode)
                    fail?(e)
                    return
                }
                onSubscribed?()
            }, eventCompletion: { (eventType, snapshot, details) in
                guard let value = snapshot?.data()?.getJsonString(field: name) else {
                    Log.errorText(text: "get snapshot data fail", tag: "AskSyncManager.subscribe")
                    return
                }
                let attr = Attribute(key: name, value: value)
                switch eventType {
                case .addDocumentEvent:
                    break
                case .modifyDocumentEvent:
                    onUpdated?(attr)
                    break
                case .removeDocumentEvent:
                    onDeleted?(attr)
                    break
                @unknown default:
                    fatalError("never call this")
                }
            })
            return
        }
        
        
        /** 监听 collection 事件 **/
        guard let collection = collections[name] else {
            let e = SyncError.ask(message: "subscribe collection \(name) not find", code: -1)
            fail?(e)
            return
        }
        
        collection.subscribe { errorCode, _ in
            if errorCode != 0 {
                let e = SyncError.ask(message: "subscribe collection \(name) fail", code: errorCode)
                fail?(e)
                return
            }
            onSubscribed?()
        } eventCompletion: { (eventType, snapshot, details) in
            guard let value = snapshot?.data()?.getJsonString(field: name) else {
                Log.errorText(text: "get snapshot data fail", tag: "AskSyncManager.subscribe")
                return
            }
            let attr = Attribute(key: name, value: value)
            switch eventType {
            case .addDocumentEvent:
                onCreated?(attr)
                break
            case .modifyDocumentEvent:
                onUpdated?(attr)
                break
            case .removeDocumentEvent:
                onDeleted?(attr)
                break
            @unknown default:
                fatalError("never call this")
            }
        }
    }
    
    func unsubscribeSync(reference: DocumentReference, key: String?) {
        let key = key ?? ""
        let name = reference.className + key
        
        if name == sceneName, let sceneDocument = roomDocument { /** 取消监听sceneRef 事件 **/
            sceneDocument.unsubscribe { errorCode in
                Log.errorText(text: "unsubscribeSync scene \(name) errorCode: \(errorCode)", tag: "AskSyncManager.unsubscribeSync")
            }
            return
        }
        
        /** 监听 collection 事件 **/
        guard let collection = collections[name] else {
            Log.errorText(text: "subscribe collection \(name) not find", tag: "AskSyncManager.unsubscribeSync")
            return
        }
        
        collection.unsubscribe { errorCode in
            Log.errorText(text: "unsubscribeSync collection \(name) errorCode: \(errorCode)", tag: "AskSyncManager.unsubscribeSync")
        }
    }
}
