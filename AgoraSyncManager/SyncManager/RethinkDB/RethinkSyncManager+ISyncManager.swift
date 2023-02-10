//
//  RethinkSyncManager+ISyncManager.swift
//  AgoraSyncManager
//
//  Created by zhaoyongqiang on 2022/7/5.
//

import UIKit

extension RethinkSyncManager: ISyncManager {
    func subscribeConnectState(state: @escaping (SocketConnectState) -> Void) {
        connectStateBlock = state
    }
    
    func createScene(scene: Scene, success: SuccessBlockVoid?, fail: FailBlock?) {
        /** add room in list **/
        
        let attr = Attribute(key: scene.id, value: scene.toJson())
        isOwner = scene.isOwner
        rooms.append(scene.id)
        if isOwner {
            write(channelName: scene.id,
                  data: attr.toDict(),
                  roomId: scene.id,
                  objectId: scene.id,
                  objType: "room")
            success?()
            return
        }
        queryRoom(channelName: scene.id, roomId: scene.id, objType: "room") { [weak self] object in
            guard let self = self else { return }
            if object == nil {
                let error = SyncError(message: "房间不存在", code: -1)
                fail?(error)
                return
            }
            self.queryRoomCompletion = nil
            
            self.write(channelName: scene.id,
                  data: attr.toDict(),
                  roomId: scene.id,
                  objectId: scene.id,
                  objType: "room")
            success?()
        }
    }

    func joinScene(sceneId: String,
                   manager: AgoraSyncManager,
                   success: SuccessBlockObjSceneRef?,
                   fail: FailBlock?) {
        let sceneRef = SceneReference(manager: manager,
                                      id: sceneId)
        success?(sceneRef)
    }
    
    public func leaveScene(roomId: String) {
        rooms.removeAll(where: { $0 == roomId })
    }

    func get(documentRef: DocumentReference,
             key: String,
             success: SuccessBlockObjOptional?,
             fail: FailBlock?) {
        let roomId = (documentRef.parent == nil ? documentRef.className : documentRef.parent?.parent.className) ?? ""
        onSuccessBlockObjOptional[documentRef.className + key] = success
        onFailBlock[documentRef.className + key] = fail
        query(channelName: documentRef.className + key,
              roomId: roomId,
              objType: documentRef.className + key)
    }

    func update(reference: DocumentReference,
                key: String,
                data: [String: Any?],
                success: SuccessBlock?,
                fail: FailBlock?) {
        let roomId = (reference.parent == nil ? reference.className : reference.parent?.parent.className) ?? ""
        let className = rooms.contains(where: { $0 == reference.className + key }) ? "room" : reference.className + key
        onSuccessBlock[className] = success
        onFailBlock[className] = fail
        write(channelName: key,
              data: data,
              roomId: roomId,
              objectId: data["objectId"] as? String,
              objType: className)
    }

    func subscribe(reference: DocumentReference,
                   key: String,
                   onCreated: OnSubscribeBlock?,
                   onUpdated: OnSubscribeBlock?,
                   onDeleted: OnSubscribeBlock?,
                   onSubscribed: OnSubscribeBlockVoid?,
                   fail: FailBlock?) {
        let roomId = (reference.parent == nil ? reference.className : reference.parent?.parent.className) ?? ""
        let className = rooms.contains(where: { $0 == reference.className + key }) ? "room" : reference.className + key
        onCreateBlocks[className] = onCreated
        onUpdatedBlocks[className] = onUpdated
        onDeletedBlocks[className] = onDeleted
        subscribe(channelName: key,
                  roomId: roomId,
                  objType: className)
        onSubscribed?()
    }

    func unsubscribe(reference: DocumentReference, key: String) {
        let roomId = (reference.parent == nil ? reference.className : reference.parent?.parent.className) ?? ""
        let className = rooms.contains(where: { $0 == reference.className + key }) ? "room" : reference.className + key
        unsubscribe(channelName: key,
                    roomId: roomId,
                    objType: className)
        onCreateBlocks.removeValue(forKey: className)
        onUpdatedBlocks.removeValue(forKey: className)
        onDeletedBlocks.removeValue(forKey: className)
    }

    func subscribeScene(reference: SceneReference,
                        onUpdated: OnSubscribeBlock?,
                        onDeleted: OnSubscribeBlock?,
                        fail: FailBlock?) {
        let roomId = reference.className
        onFailBlock[roomId] = fail
        onUpdatedBlocks[roomId] = onUpdated
        onDeletedBlocks[roomId] = onDeleted
        subscribe(channelName: sceneName,
                  roomId: roomId,
                  objType: "room")
    }

    func unsubscribeScene(reference: SceneReference, fail: FailBlock?) {
        let roomId = reference.className
        onDeletedBlocks.removeValue(forKey: roomId)
        onFailBlock.removeValue(forKey: roomId)
        unsubscribe(channelName: sceneName,
                    roomId: roomId,
                    objType: "room")
    }

    func getScenes(success: SuccessBlock?, fail: FailBlock?) {
        onSuccessBlock[sceneName] = success
        onFailBlock[sceneName] = fail
        getRoomList(channelName: sceneName)
    }

    func deleteScenes(sceneIds: [String],
                      success: SuccessBlockObjOptional?,
                      fail: FailBlock?) {
        let roomId = rooms.first ?? ""
        onDeleteBlockObjOptional[roomId] = success
        onFailBlock[roomId] = fail
        deleteRoom()
    }

    func get(collectionRef: CollectionReference, success: SuccessBlock?, fail: FailBlock?) {
        let roomId = collectionRef.parent.className
        onSuccessBlock[collectionRef.className] = success
        onFailBlock[collectionRef.className] = fail
        query(channelName: collectionRef.className,
              roomId: roomId,
              objType: collectionRef.className)
    }

    func add(reference: CollectionReference,
             data: [String: Any?],
             success: SuccessBlockObj?,
             fail: FailBlock?) {
        let roomId = reference.parent.className
        let className = reference.className.replacingOccurrences(of: roomId, with: "")
        onSuccessBlockObj[reference.className] = success
        onFailBlock[reference.className] = fail
        let objectId = UUID().uuid16string()
        var parasm = data
        parasm["objectId"] = objectId
        write(channelName: className,
              data: parasm,
              roomId: roomId,
              objectId: objectId,
              objType: reference.className,
              isAdd: true)
    }

    func update(reference: CollectionReference,
                id: String,
                data: [String: Any?],
                success: SuccessBlockVoid?,
                fail: FailBlock?) {
        let roomId = reference.parent.className
        let className = rooms.contains(where: { $0 == reference.className }) ? "room" : reference.className
        onSuccessBlockVoid[className] = success
        onFailBlock[className] = fail
        write(channelName: reference.className,
              data: data,
              roomId: roomId,
              objectId: id,
              objType: className,
              isUpdate: true)
    }

    func delete(reference: CollectionReference,
                id: String,
                success: SuccessBlockObjOptional?,
                fail: FailBlock?) {
        let roomId = reference.parent.className
        let className = rooms.contains(where: { $0 == reference.className }) ? "room" : reference.className
        onDeleteBlockObjOptional[className] = success
        onFailBlock[className] = fail
        if className == "room" {
            deleteRoom()
            return
        }
        delete(channelName: className, roomId: roomId, data: ["objectId": id])
    }

    func delete(documentRef: DocumentReference, success: SuccessBlock?, fail: FailBlock?) {
        let keys = documentRef.id.isEmpty ? nil : [documentRef.id]
        let roomId = (documentRef.parent == nil ? documentRef.className : documentRef.parent?.parent.className) ?? ""
        let className = rooms.contains(where: { $0 == documentRef.className }) ? "room" : documentRef.className
        onSuccessBlock[className] = success
        onFailBlock[className] = fail
        if className == "room" {
            deleteRoom()
            return
        }
        if let keys = keys {
            let params = keys.map({ ["objectId": $0] })
            delete(channelName: className, roomId: roomId, data: params)
        }
    }

    func delete(collectionRef: CollectionReference, success: SuccessBlock?, fail: FailBlock?) {
        let roomId = collectionRef.parent.className
        let className = rooms.contains(where: { $0 == collectionRef.className }) ? "room" : collectionRef.className
        onSuccessBlock[className] = success
        onFailBlock[className] = fail
        delete(channelName: className, roomId: roomId, data: [])
    }
}
