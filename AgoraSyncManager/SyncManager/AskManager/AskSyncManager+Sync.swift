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
        self.sceneId = sceneId
        DispatchQueue.main.async {
            success?(sceneRef)
        }
    }
    
    func getScenesSync(success: SuccessBlock?, fail: FailBlock?) {
        guard let field = sceneId else {
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
                let strings = list.compactMap({ $0.data() }).map({ $0.getJsonString(field: "") })
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
