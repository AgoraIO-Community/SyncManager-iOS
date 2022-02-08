//
//  AskManager.swift
//  AgoraSyncManager
//
//  Created by ZYP on 2022/2/7.
//

import Foundation
import AgoraSyncKit

class AskManager: NSObject {
    var defaultChannelName: String!
    var askKit: AgoraSyncKit!
    var askContext: AgoraSyncContext!
    var roomsCollection: AgoraSyncCollection!
    var membersCollection: AgoraSyncCollection!
    let roomListKey = "rooms"
    let memberListKey = "members"
    /// init
    /// - Parameters:
    ///   - config: config
    init(config: Config,
         complete: SuccessBlockInt?) {
        super.init()
        self.defaultChannelName = config.channelName
        askKit = AgoraSyncKit(appId: config.appId)
        askContext = askKit.createContext()
    }
}
