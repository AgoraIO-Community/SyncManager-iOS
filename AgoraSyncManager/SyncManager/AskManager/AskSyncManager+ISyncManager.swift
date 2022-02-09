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
        queue.async { [weak self] in
            self?.getSync(collectionRef: collectionRef,
                          success: success,
                          fail: fail)
        }
    }
    
    func add(reference: CollectionReference,
             data: [String : Any?],
             success: SuccessBlockObj?,
             fail: FailBlock?) {
        queue.async { [weak self] in
            self?.addSync(reference: reference,
                          data: data,
                          success: success,
                          fail: fail)
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
        queue.async { [weak self] in
            self?.updateSync(reference: reference,
                             key: key,
                             data: data,
                             success: success,
                             fail: fail)
        }
    }
    
    func delete(documentRef: DocumentReference,
                success: SuccessBlock?,
                fail: FailBlock?) {
        queue.async { [weak self] in
            self?.deleteSync(documentRef: documentRef,
                             success: success,
                             fail: fail)
        }
    }
    
    func delete(collectionRef: CollectionReference,
                success: SuccessBlock?,
                fail: FailBlock?) {
        queue.async { [weak self] in
            self?.deleteSync(collectionRef: collectionRef,
                             success: success,
                             fail: fail)
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
