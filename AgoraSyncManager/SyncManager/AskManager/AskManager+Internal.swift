//
//  AskManager+Internal.swift
//  AgoraSyncManager
//
//  Created by ZYP on 2022/2/7.
//

import Foundation
import AgoraRtmKit /// will not use it
import AgoraSyncKit

extension AskManager {
    func addSceneInfoInListIfNeed(scene: Scene,
                                  sceneRef: SceneReference,
                                  success: SuccessBlockObjSceneRef?,
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
                    assertionFailure("snapshots must not nil")
                    return
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
                error = SyncError(message: "joinScene fail", code: errorCode)
                semp.signal()
            }
        }
        
        semp.wait()
        
        if let e = error { /** get scene list has error **/
            fail?(e)
            return
        }
        
        if !shouldAddRoomInfoInList {
            success?(sceneRef)
            return
        }
        
        /** add room in list **/
        let roomJson = AgoraJson()
        let roomString = scene.toJson()
        roomJson.setString(roomString)
        roomsCollection?.add(roomJson, completion: { [weak self](errorCode, document) in
            if errorCode == 0 {
                self?.roomDocument = document
                success?(sceneRef)
                return
            }
            else {
                Log.errorText(text: "roomsCollection add \(errorCode)", tag: "AskManager.addSceneInfoInListIfNeed")
                let error = SyncError(message: "joinScene fail", code: errorCode)
                fail?(error)
                return
            }
        })
    }
}
