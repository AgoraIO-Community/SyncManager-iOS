//
//  RethinkSyncManager+ISyncManager.swift
//  AgoraSyncManager
//
//  Created by zhaoyongqiang on 2022/7/5.
//

import UIKit

extension RethinkSyncManager: ISyncManager {
    func createScene(scene: Scene, success: SuccessBlockVoid?, fail: FailBlock?) {
        /** add room in list **/
        let attr = Attribute(key: scene.id, value: scene.toJson())
        roomId = scene.id
        write(channelName: roomId,
              data: attr.toDict(),
              roomId: roomId,
              objectId: sceneName,
              objType: "room")
        success?()
    }

    func joinScene(sceneId: String,
                   manager: AgoraSyncManager,
                   success: SuccessBlockObjSceneRef?,
                   fail: FailBlock?) {
        let sceneRef = SceneReference(manager: manager,
                                      id: sceneId)
        success?(sceneRef)
    }

    func get(documentRef: DocumentReference,
             key: String,
             success: SuccessBlockObjOptional?,
             fail: FailBlock?) {
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
        let className = (reference.className + key) == roomId ? sceneName : reference.className + key
        onSuccessBlock[className] = success
        onFailBlock[className] = fail
        write(channelName: key,
              data: data,
              roomId: reference.className,
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
        let className = (reference.className + key) == roomId ? sceneName : reference.className + key
        print("className == \(className)")
        onCreateBlocks[className] = onCreated
        onUpdatedBlocks[className] = onUpdated
        onDeletedBlocks[className] = onDeleted
        subscribe(channelName: key,
                  roomId: reference.className,
                  objType: className)
        onSubscribed?()
    }

    func unsubscribe(reference: DocumentReference, key: String) {
        let className = (reference.className + key) == roomId ? sceneName : reference.className + key
        unsubscribe(channelName: key,
                    roomId: reference.className,
                    objType: className)
        onCreateBlocks.removeValue(forKey: className)
        onUpdatedBlocks.removeValue(forKey: className)
        onDeletedBlocks.removeValue(forKey: className)
    }

    func subscribeScene(reference: SceneReference,
                        onUpdated: OnSubscribeBlock?,
                        onDeleted: OnSubscribeBlock?,
                        fail: FailBlock?) {
        onFailBlock[roomId] = fail
        onUpdatedBlocks[roomId] = onUpdated
        onDeletedBlocks[roomId] = onDeleted
        subscribe(channelName: sceneName,
                  roomId: roomId,
                  objType: "room")
    }

    func unsubscribeScene(reference: SceneReference, fail: FailBlock?) {
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
        onDeleteBlockObjOptional[roomId] = success
        onFailBlock[roomId] = fail
        deleteRoom()
    }

    func get(collectionRef: CollectionReference, success: SuccessBlock?, fail: FailBlock?) {
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
        let className = reference.className == roomId ? sceneName : reference.className
        onSuccessBlockVoid[className] = success
        onFailBlock[className] = fail
        write(channelName: reference.className,
              data: data,
              roomId: roomId,
              objectId: id,
              objType: className)
    }

    func delete(reference: CollectionReference,
                id: String,
                success: SuccessBlockObjOptional?,
                fail: FailBlock?) {
        let className = reference.className == roomId ? sceneName : reference.className
        onDeleteBlockObjOptional[className] = success
        onFailBlock[className] = fail
        delete(channelName: className, data: ["objectId": id])
    }

    func delete(documentRef: DocumentReference, success: SuccessBlock?, fail: FailBlock?) {
        let keys = documentRef.id.isEmpty ? nil : [documentRef.id]
        let className = documentRef.className == roomId ? sceneName : documentRef.className
        onSuccessBlock[className] = success
        onFailBlock[className] = fail
        if let keys = keys {
            let params = keys.map({ ["objectId": $0] })
            delete(channelName: className, data: params)
        }
    }

    func delete(collectionRef: CollectionReference, success: SuccessBlock?, fail: FailBlock?) {
        let className = collectionRef.className == roomId ? sceneName : collectionRef.className
        onSuccessBlock[className] = success
        onFailBlock[className] = fail
        delete(channelName: className, data: [])
    }
}
