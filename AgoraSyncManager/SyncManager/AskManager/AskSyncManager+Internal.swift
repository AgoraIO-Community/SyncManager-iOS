//
//  AskSyncManager+Internal.swift
//  AgoraSyncManager
//
//  Created by ZYP on 2022/2/10.
//

import Foundation
import AgoraSyncKit

extension AskSyncManager {
    /// fetchRoomSnapshot in remote
    /// - Returns: will retuen `nil` when remote has no this field in collection
    func fetchSceneSnapshot(with filed: String, in collection: AgoraSyncCollection) -> Result<AgoraDocumentSnapshot, SyncError>? {
        /** 1. get room list **/
        let semp = DispatchSemaphore(value: 0)
        var error: SyncError?
        var snapshots = [AgoraDocumentSnapshot]()
        roomsCollection.getRemote { errorCode, datas in
            Log.info(text: "get scene list block invoke", tag: "AskManager.fetchRoomSnapshot")
            if errorCode == .codeNoError {
                guard let list = datas else { /** can not get list **/
                    fatalError("snapshots must not nil")
                }
                snapshots = list
                semp.signal()
            }
            else {
                error = SyncError.ask(message: "getRemote fail ", code: errorCode.rawValue)
                semp.signal()
            }
        }
        
        semp.wait()
        
        if let e = error { /** get room list error **/
            return .failure(e)
        }
        
        /** 2. check room has include, and set roomDocument **/
        let decoder = JSONDecoder()
        for snapshot in snapshots {
            guard let string = snapshot.data()?.getJsonString(field: filed),
                  let data = string.data(using: .utf8) else {
                      Log.errorText(text: "not valid string",
                                    tag: "AskSyncManager.fetchRoomSnapshot")
                      continue
                  }
            
            do {
                let sceneObj = try decoder.decode(Scene.self, from: data)
                
                if sceneObj.id == filed {
                    return .success(snapshot)
                }
                
            } catch let error {
                Log.errorText(text: "decode error \(error.localizedDescription)", tag: "AskManager.fetchRoomSnapshot")
            }
        }
        
        return nil /// can not find a typical snapshot
    }
    
    /// add room item in room list
    /// - Parameters:
    ///   - id: scene id
    ///   - data: scene data
    /// - Returns: result
    func addScene(id: String, data: String) -> Result<AgoraSyncDocument, SyncError> {
        let roomString = data
        let json = AgoraJson()
        json.setString(roomString)
        let roomJson = AgoraJson()
        roomJson.setObject()
        roomJson.setField(id, agoraJson: json)
        let semp = DispatchSemaphore(value: 0)
        var targetDocument: AgoraSyncDocument?
        var error: SyncError?
        targetDocument = roomsCollection.createDocument(withName: id)
        targetDocument?.set("", json: roomJson, completion: { errorCode in
            if errorCode == .codeNoError {
                semp.signal()
            }
            else {
                let e = SyncError.ask(message: "addRoom fail ", code: errorCode.rawValue)
                error = e
                semp.signal()
            }
        })
        
        semp.wait()
        
        if let e = error {
            Log.errorText(text: e.description, tag: "AskSyncManager.addRoom")
            return .failure(e)
        }
        
        guard let document = targetDocument else {
            fatalError("never call this")
        }
        
        return .success(document)
    }
    
    /// add room item in room list
    /// - Parameters:
    ///   - id: scene id
    ///   - data: scene data
    /// - Returns: result
//    func addScene(id: String, data: String) -> Result<AgoraSyncDocument, SyncError> {
//        let roomString = data
//        let json = AgoraJson()
//        json.setString(roomString)
//        let roomJson = AgoraJson()
//        roomJson.setObject()
//        roomJson.setField(id, agoraJson: json)
//        let semp = DispatchSemaphore(value: 0)
//        var targetDocument: AgoraSyncDocument?
//        var error: SyncError?
//        roomsCollection.add(roomJson, completion: { (errorCode, document) in
//            if errorCode == .codeNoError {
//                targetDocument = document
//                semp.signal()
//            }
//            else {
//                let e = SyncError.ask(message: "addRoom fail ", code: errorCode.rawValue)
//                error = e
//                semp.signal()
//            }
//        })
//
//        semp.wait()
//
//        if let e = error {
//            Log.errorText(text: e.description, tag: "AskSyncManager.addRoom")
//            return .failure(e)
//        }
//
//        guard let document = targetDocument else {
//            fatalError("never call this")
//        }
//
//        return .success(document)
//    }
}
