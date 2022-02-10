//
//  AskManager.swift
//  AgoraSyncManager
//
//  Created by ZYP on 2022/2/7.
//

import Foundation
import AgoraSyncKit

class AskSyncManager: NSObject {
    var defaultChannelName: String!
    var sceneId: String!
    var askKit: AgoraSyncKit!
    var askContext: AgoraSyncContext!
    var roomsCollection: AgoraSyncCollection!
    var membersCollection: AgoraSyncCollection!
    var roomDocument: AgoraSyncDocument?
    let roomListKey = "rooms"
    let memberListKey = "members"
    var documentDict = [String : AgoraSyncDocument]()
    let queue = DispatchQueue(label: "AskManager.queue")
    
    var onCreateBlocks = [AgoraSyncDocument : OnSubscribeBlock]()
    var onUpdatedBlocks = [AgoraSyncDocument : OnSubscribeBlock]()
    var onDeletedBlocks = [AgoraSyncDocument : OnSubscribeBlock]()
    
    /// init
    /// - Parameters:
    ///   - config: config
    init(config: Config,
         complete: SuccessBlockInt?) {
        super.init()
        self.defaultChannelName = config.channelName
        askKit = AgoraSyncKit(appId: config.appId)
        askContext = askKit.createContext()
        roomsCollection = askContext.createSlice(withName: defaultChannelName)?.createCollection(withName: roomListKey)
        Log.info(text: "defaultChannelName = \(config.channelName)", tag: "AskSyncManager.init")
    }
}
