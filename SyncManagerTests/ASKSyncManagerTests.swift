//
//  ASKSyncManagerTests.swift
//  SyncManagerTests
//
//  Created by ZYP on 2022/2/22.
//

import XCTest
import AgoraSyncManager

class ASKSyncManagerTests: XCTestCase {
    var manager1: AgoraSyncManager?
    var manager2: AgoraSyncManager?
    var syncRef1: SceneReference?
    var syncRef2: SceneReference?
    let appId = Config.appId
    let channelName = "testScene"
    var promise: XCTestExpectation?
    
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
        let promise5 = expectation(description: "create check")
        
        /// 1. init
        let config = AgoraSyncManager.AskConfig(appId: appId,
                                                channelName: channelName)
        manager1 = AgoraSyncManager(askConfig: config) { code in
            promise1.fulfill()
        }
        
        manager2 = AgoraSyncManager(askConfig: config) { code in
            promise2.fulfill()
        }
        
        wait(for: [promise1, promise2], timeout: 5)
        
        /// 2. create
        let scene1 = Scene(id: "room1", userId: "user1", property: [:])
        manager1?.createScene(scene: scene1, success: {
            promise5.fulfill()
        }, fail: { error in
            
        })
        wait(for: [promise5], timeout: 5)
        
        /// 3. join
        manager1?.joinScene(sceneId: "room1", success: { [weak self](ref) in
            self?.syncRef1 = ref
            promise3.fulfill()
        }, fail: nil)
        
        manager2?.joinScene(sceneId: "room1",
                            success: { [weak self](ref) in
            self?.syncRef2 = ref
            promise4.fulfill()
        }, fail: nil)
        
        wait(for: [promise3, promise4], timeout: 5)
    }
    
    func subscribe() {
        syncRef2?.update(key: "test",
                         data: ["testdata" : "testdata \(Int.random(in: 0...100))"],
                         success:nil,
                         fail: nil)
        
        syncRef1?.subscribe(key: "test",
                            onCreated: nil,
                            onUpdated: { [weak self](obj) in
            print("onUpdated \(obj.toJson() ?? "")")
            self?.promise?.fulfill()
        },
                            onDeleted: nil,
                            onSubscribed: nil,
                            fail: nil)
    }
    
    func update() {
        promise = expectation(description: "update data check")
        wait(for: [promise!], timeout: 5)
        syncRef2?.update(key: "test",
                         data: ["testdata" : "testdata \(Int.random(in: 0...100))"],
                         success: { objs in
        }, fail: { error in
            XCTFail("update error \(error.description)")
        })
        
        
    }

}
