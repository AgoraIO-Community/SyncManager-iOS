//
//  SyncManagerTests.swift
//  SyncManagerTests
//
//  Created by xianing on 2021/12/11.
//

import XCTest
import AgoraSyncManager
import AgoraRtmKit

class SyncManagerTests: XCTestCase, AgoraRtmChannelDelegate {
    var manager1: AgoraSyncManager?
    var manager2: AgoraSyncManager?
    var syncRef1: SceneReference?
    var syncRef2: SceneReference?
    let appId = Config.appId
    let channelName = "testScene"
    var promise: XCTestExpectation!
    var rtm: AgoraRtmKit!
    var channel: AgoraRtmChannel!
    
    override func setUpWithError() throws {}
    
    override func tearDownWithError() throws {
        promise = nil
        manager1 = nil
        manager2 = nil
        syncRef1 = nil
        syncRef2 = nil
    }
    
    func testExample() throws { /** 2个用户加入到同一个房间，其中一个用户主动更新房间信息，另一个用户接收到更新的信息。可能有时候网络导致会不成功，多试几次 **/
        joinScene()
        subscribe()
        update()
    }
    
    func joinScene() {
        let promise1 = expectation(description: "init check 1")
        let promise2 = expectation(description: "init check 2")
        let promise3 = expectation(description: "join check 1")
        let promise4 = expectation(description: "join check 2")
        
        /// 1. init
        let config = AgoraSyncManager.RtmConfig(appId: appId,
                                                channelName: channelName)
        manager1 = AgoraSyncManager(config: config) { code in
            promise1.fulfill()
        }
        
        manager2 = AgoraSyncManager(config: config) { code in
            promise2.fulfill()
        }
        
        wait(for: [promise1, promise2], timeout: 5)
        
        /// 2. join
        let scene1 = Scene(id: "room1", userId: "user1", property: [:])
        syncRef1 = manager1?.joinScene(scene: scene1,
                                       success: { (objs) in
            let strs = objs.compactMap({ $0.toJson() })
            print(strs)
            promise3.fulfill()
        })
        
        let scene2 = Scene(id: "room1", userId: "user2", property: [:])
        syncRef2 = manager2?.joinScene(scene: scene2,
                                       success: { (objs) in
            let strs = objs.compactMap({ $0.toJson() })
            print(strs)
            promise4.fulfill()
        })
        
        wait(for: [promise3, promise4], timeout: 5)
    }
    
    func subscribe() {
        syncRef1?.subscribe(key: "test",
                            onCreated: nil,
                            onUpdated: { [weak self](obj) in
                                print("onUpdated \(obj.toJson() ?? "")")
                                self?.promise.fulfill()
                            },
                            onDeleted: nil,
                            onSubscribed: nil,
                            fail: nil)
    }
    
    func update() {
        promise = expectation(description: "update data check")
        syncRef2?.update(key: "test",
                         data: ["testdata" : "testdata \(Int.random(in: 0...100))"],
                         success: { objs in
        }, fail: { error in
            XCTFail("update error \(error.description)")
        })
        
        wait(for: [promise], timeout: 5)
    }
}
