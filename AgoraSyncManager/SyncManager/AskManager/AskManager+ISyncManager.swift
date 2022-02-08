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
    
    func joinScene(scene: Scene,
                   manager: AgoraSyncManager,
                   success: SuccessBlockObj?,
                   fail: FailBlock?) -> SceneReference {
        let sceneRef = SceneReference(manager: manager,
                                      id: scene.id)
        
        roomsCollection = askContext.createSlice(withName: defaultChannelName)?.createCollection(withName: roomListKey)
        membersCollection = roomsCollection.createDocument(withName: scene.id)?.createCollection(withName: memberListKey)
        
        let queue = DispatchQueue(label: "AskManager.queue", attributes: .concurrent)
        queue.async { [weak self] in
            self?.addSceneInfoInListIfNeed(scene: scene,
                                           success: success,
                                           fail: fail)
        }
        return sceneRef
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
        
    }
    
    func get(documentRef: DocumentReference,
             key: String?,
             success: SuccessBlockObjOptional?,
             fail: FailBlock?) {
        
    }
    
    func get(collectionRef: CollectionReference,
             success: SuccessBlock?,
             fail: FailBlock?) {
        
    }
    
    func add(reference: CollectionReference,
             data: [String : Any?],
             success: SuccessBlockObj?,
             fail: FailBlock?) {
        
    }
    
    func update(reference: DocumentReference,
                key: String?,
                data: [String : Any?],
                success: SuccessBlock?,
                fail: FailBlock?) {
        
    }
    
    func delete(documentRef: DocumentReference,
                success: SuccessBlock?,
                fail: FailBlock?) {
        
    }
    
    func delete(collectionRef: CollectionReference,
                success: SuccessBlock?,
                fail: FailBlock?) {
        
    }
    
    func subscribe(reference: DocumentReference,
                   key: String?,
                   onCreated: OnSubscribeBlock?,
                   onUpdated: OnSubscribeBlock?,
                   onDeleted: OnSubscribeBlock?,
                   onSubscribed: OnSubscribeBlockVoid?,
                   fail: FailBlock?) {
        
    }
    
    func unsubscribe(reference: DocumentReference, key: String?) {
        
    }
}
